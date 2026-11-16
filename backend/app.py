import os
from pathlib import Path
from dotenv import load_dotenv
import mysql.connector
from mysql.connector import Error
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel, Field

load_dotenv()

app = FastAPI(title="GareebSQL Banking System by Prabhat and Team")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

def get_connection():
    try:
        return mysql.connector.connect(
            host=os.getenv("DB_HOST", "localhost"),
            port=int(os.getenv("DB_PORT", 3306)),
            user=os.getenv("DB_USER", "root"),
            password=os.getenv("DB_PASSWORD", ""),
            database=os.getenv("DB_NAME", "gareeb_sql"),
        )
    except Error as err:
        raise HTTPException(status_code=500, detail=f"Database connection failed: {err}")

class TransferRequest(BaseModel):
    from_account: str = Field(..., min_length=3)
    to_account: str = Field(..., min_length=3)
    amount: float = Field(..., gt=0)
    remarks: str = "Online fund transfer"


@app.get("/api/dashboard")
def get_dashboard():
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute("SELECT * FROM customer_balance_summary ORDER BY total_balance DESC")
        customers = cursor.fetchall()
        cursor.execute("SELECT * FROM loan_portfolio_summary ORDER BY loan_id")
        loans = cursor.fetchall()
        cursor.execute("""
            SELECT a.account_id, a.account_number, c.full_name, b.branch_name,
                   a.account_type, a.balance, a.status
            FROM accounts a
            JOIN customers c ON a.customer_id = c.customer_id
            JOIN branches b ON a.branch_id = b.branch_id
            ORDER BY a.account_id
        """)
        accounts = cursor.fetchall()

        return {"customers": customers, "loans": loans, "accounts": accounts}
    finally:
        cursor.close()
        conn.close()

@app.get("/")
def home():
    return {
        "message": "Welcome to GareebSQL FastAPI Backend",
        "status": "running",
        "random": "Hello World This is Prabhat Bhatia"
    }

@app.get("/api/statements")
def get_statements(account_number: str | None = None):
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        base_query = """
            SELECT t.transaction_id, a.account_number, c.full_name, t.type, t.amount,
                   t.txn_date, t.remarks,
                   SUM(CASE WHEN t.type IN ('Deposit', 'Transfer_In') THEN t.amount ELSE -t.amount END)
                   OVER (PARTITION BY t.account_id ORDER BY t.txn_date, t.transaction_id) AS running_balance
            FROM transactions t
            JOIN accounts a ON t.account_id = a.account_id
            JOIN customers c ON a.customer_id = c.customer_id
        """
        if account_number:
            cursor.execute(base_query + " WHERE a.account_number = %s ORDER BY t.txn_date DESC", (account_number,))
        else:
            cursor.execute(base_query + " ORDER BY t.txn_date DESC")

        return {"transactions": cursor.fetchall()}
    finally:
        cursor.close()
        conn.close()

@app.get("/api/analytics")
def get_analytics():
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        # Window Function: Rank customers by wealth
        cursor.execute("""
            SELECT c.full_name, SUM(a.balance) AS total_balance,
                   DENSE_RANK() OVER (ORDER BY SUM(a.balance) DESC) AS balance_rank
            FROM customers c
            JOIN accounts a ON c.customer_id = a.customer_id
            GROUP BY c.customer_id, c.full_name
        """)
        rankings = cursor.fetchall()

        # CTE: Monthly cash flow
        cursor.execute("""
            WITH monthly_flow AS (
                SELECT DATE_FORMAT(txn_date, '%Y-%m') AS month,
                       SUM(CASE WHEN type IN ('Deposit', 'Transfer_In') THEN amount ELSE 0 END) AS inflow,
                       SUM(CASE WHEN type IN ('Withdrawal', 'Transfer_Out') THEN amount ELSE 0 END) AS outflow
                FROM transactions
                GROUP BY month
            )
            SELECT month, inflow, outflow, (inflow - outflow) AS net_flow
            FROM monthly_flow
            ORDER BY month
        """)
        cash_flow = cursor.fetchall()

        # Left Outer Join: Customers without loans
        cursor.execute("""
            SELECT c.customer_id, c.full_name, c.city
            FROM customers c
            LEFT JOIN loans l ON c.customer_id = l.customer_id
            WHERE l.loan_id IS NULL
        """)
        debt_free = cursor.fetchall()

        # Self Join: Referral network
        cursor.execute("""
            SELECT c.full_name AS customer, COALESCE(r.full_name, 'Direct Join') AS referred_by
            FROM customers c
            LEFT JOIN customers r ON c.referred_by = r.customer_id
        """)
        referrals = cursor.fetchall()

        return {
            "rankings": rankings,
            "cash_flow": cash_flow,
            "debt_free": debt_free,
            "referrals": referrals,
        }
    finally:
        cursor.close()
        conn.close()

@app.post("/api/transfer")
def transfer_funds(req: TransferRequest):
    if req.from_account == req.to_account:
        raise HTTPException(status_code=400, detail="Source and destination accounts must differ")

    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        conn.start_transaction()

        cursor.execute(
            "SELECT account_id, balance, status FROM accounts WHERE account_number = %s FOR UPDATE",
            (req.from_account,),
        )
        sender = cursor.fetchone()

        cursor.execute(
            "SELECT account_id, status FROM accounts WHERE account_number = %s FOR UPDATE",
            (req.to_account,),
        )
        receiver = cursor.fetchone()

        if not sender or not receiver:
            conn.rollback()
            raise HTTPException(status_code=404, detail="One or both account numbers not found")

        if sender["status"] != "Active" or receiver["status"] != "Active":
            conn.rollback()
            raise HTTPException(status_code=400, detail="Both accounts must be Active")

        if float(sender["balance"]) < req.amount:
            conn.rollback()
            raise HTTPException(status_code=400, detail="Insufficient balance — transaction rolled back")

        cursor.execute(
            "UPDATE accounts SET balance = balance - %s WHERE account_id = %s",
            (req.amount, sender["account_id"]),
        )
        cursor.execute(
            "UPDATE accounts SET balance = balance + %s WHERE account_id = %s",
            (req.amount, receiver["account_id"]),
        )

        cursor.execute(
            """INSERT INTO transactions (account_id, related_account_id, type, amount, remarks)
               VALUES (%s, %s, 'Transfer_Out', %s, %s)""",
            (sender["account_id"], receiver["account_id"], req.amount, req.remarks),
        )
        cursor.execute(
            """INSERT INTO transactions (account_id, related_account_id, type, amount, remarks)
               VALUES (%s, %s, 'Transfer_In', %s, %s)""",
            (receiver["account_id"], sender["account_id"], req.amount, req.remarks),
        )

        conn.commit()
        return {"message": f"Transferred ₹{req.amount:,.2f} from {req.from_account} to {req.to_account}"}
    except HTTPException:
        raise
    except Error as err:
        conn.rollback()
        raise HTTPException(status_code=400, detail=f"Database constraint rejected transfer: {err}")
    finally:
        cursor.close()
        conn.close()

frontend_dir = Path(__file__).resolve().parent.parent / "frontend"
if frontend_dir.exists():
    app.mount("/", StaticFiles(directory=str(frontend_dir), html=True), name="frontend")