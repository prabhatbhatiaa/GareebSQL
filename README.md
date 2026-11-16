<h1 align="center">GareebSQL</h1> 

<p align="center">
  <img src="https://img.shields.io/badge/MySQL-8.0-4479A1?style=flat-square&logo=mysql&logoColor=white" alt="MySQL 8.0">
  <img src="https://img.shields.io/badge/FastAPI-0.115+-009688?style=flat-square&logo=fastapi&logoColor=white" alt="FastAPI">
  <img src="https://img.shields.io/badge/Normal_Form-BCNF-18181b?style=flat-square" alt="BCNF">
  <img src="https://img.shields.io/badge/Capstone-DBMS_Project-0f766e?style=flat-square" alt="DBMS Project">
</p>

**GareebSQL** is a relational banking and financial transaction management system built on **MySQL 8.0 (InnoDB)**, **Python FastAPI**, and an **HTML/CSS/JS frontend**. 

It eliminates ORM abstractions in favor of transparent, auditable raw SQL—demonstrating full normalization from **UNF to BCNF**, strict referential integrity, advanced analytical queries, role-based access control, and **ACID-compliant** fund transfers.

---

## Problem Statement & Scope
Traditional flat-file ledgers suffer from data redundancy, update anomalies, and race conditions during concurrent balance updates. **GareebSQL** solves these issues across core retail banking workflows:

- **Multi-Branch Customer & Account Management:** Supports Savings and Current accounts across multiple bank branches with domain-level `CHECK` and `UNIQUE` constraints.
- **Tamper-Proof Audit Trail:** Enforces `ON DELETE RESTRICT` across accounts, transactions, and loans so historical financial records cannot be orphaned.
- **Atomic Peer-to-Peer Transfers:** Uses row-level pessimistic locking (`SELECT ... FOR UPDATE`) inside explicit transaction blocks (`START TRANSACTION` / `COMMIT` / `ROLLBACK`) to prevent double-spending and negative balances.
- **Real-Time Financial Analytics:** Computes running account balances, customer wealth rankings, and monthly net cash flows directly inside MySQL using Window Functions and Common Table Expressions (CTEs).

---

## System Architecture & Data Flow

```mermaid
flowchart LR
    UI["Interactive Ledger<br/>(HTML / CSS / JS)<br/>Light & Dark Theme"] <-->|REST JSON| API["FastAPI REST Bridge<br/>(backend/app.py)<br/>Parameterized Raw SQL"]
    API <-->|ACID / FOR UPDATE| DB[("MySQL 8.0 InnoDB<br/>6 BCNF Tables · Views<br/>Indexes · DCL · TCL")]
```

1. **Schema Layer (`sql/01_create_tables.sql`):** Defines 6 normalized relations with primary keys, foreign keys, `ENUM` domains, and `CHECK` constraints.
2. **Database Engine (`MySQL 8.0`):** Executes composite B-Tree indexes, read-only summary views, DCL user roles, window functions, CTEs, and ACID transactions.
3. **API Bridge (`backend/app.py`):** Exposes clean REST endpoints (`/api/dashboard`, `/api/statements`, `/api/analytics`, `/api/transfer`) executing raw SQL without an ORM.
4. **Client Interface (`frontend/`):** Minimalist dual-theme (Light/Dark) financial dashboard featuring live ledger views, running statements, and interactive transfer testing.

---

## Entity-Relationship Diagram

The conceptual model captures 6 core banking entities, including recursive customer referral tracking (`referred_by`) and dual account linkages (`account_id`, `related_account_id`) for peer-to-peer transfers.

**Full Entity & Cardinality Specification:** [`docs/ER_Diagram.md`](docs/ER_Diagram.md)

```mermaid
erDiagram
    BRANCHES ||--o{ ACCOUNTS : "manages"
    BRANCHES ||--o{ LOANS : "sanctions"
    CUSTOMERS ||--o{ ACCOUNTS : "holds"
    CUSTOMERS ||--o{ LOANS : "borrows"
    CUSTOMERS ||--o{ CUSTOMERS : "refers"
    ACCOUNTS ||--o{ TRANSACTIONS : "records"
    ACCOUNTS ||--o{ TRANSACTIONS : "receives_transfer"
    LOANS ||--o{ LOAN_PAYMENTS : "repaid_via"

    BRANCHES {
        int branch_id PK
        varchar branch_name
        varchar city
        varchar ifsc_code UK
    }

    CUSTOMERS {
        int customer_id PK
        varchar full_name
        varchar email UK
        varchar phone UK
        varchar city
        int referred_by FK
        date joined_date
    }

    ACCOUNTS {
        int account_id PK
        int customer_id FK
        int branch_id FK
        varchar account_number UK
        enum account_type
        decimal balance
        enum status
        date opened_date
    }

    TRANSACTIONS {
        int transaction_id PK
        int account_id FK
        int related_account_id FK
        enum type
        decimal amount
        datetime txn_date
        varchar remarks
    }

    LOANS {
        int loan_id PK
        int customer_id FK
        int branch_id FK
        enum loan_type
        decimal principal_amount
        decimal interest_rate
        enum status
        date issued_date
    }

    LOAN_PAYMENTS {
        int payment_id PK
        int loan_id FK
        decimal amount_paid
        date payment_date
    }
```

---

## Relational Design
The conceptual ER model translates into 6 relational tables enforced with **Primary Keys (`PK`)**, **Foreign Keys (`FK`)**, **Candidate Keys (`UK`)**, and **Domain `CHECK` Constraints** (`balance >= 0.00`, `amount > 0.00`) alongside `ON DELETE RESTRICT` referential rules to protect financial history.

**Detailed Table Schemas, Keys & Integrity Rules:** [`docs/Relational_Model.md`](docs/Relational_Model.md)

```mermaid
flowchart TB
    B["<b>branches</b><br/><u>branch_id (PK)</u> | branch_name | city | ifsc_code (UK)"]
    C["<b>customers</b><br/><u>customer_id (PK)</u> | full_name | email (UK) | phone (UK) | city | referred_by (FK) | joined_date"]
    A["<b>accounts</b><br/><u>account_id (PK)</u> | customer_id (FK) | branch_id (FK) | account_number (UK) | account_type | balance | status | opened_date"]
    T["<b>transactions</b><br/><u>transaction_id (PK)</u> | account_id (FK) | related_account_id (FK) | type | amount | txn_date | remarks"]
    L["<b>loans</b><br/><u>loan_id (PK)</u> | customer_id (FK) | branch_id (FK) | loan_type | principal_amount | interest_rate | status | issued_date"]
    LP["<b>loan_payments</b><br/><u>payment_id (PK)</u> | loan_id (FK) | amount_paid | payment_date"]

    C -->|referred_by| C
    C -->|customer_id| A
    B -->|branch_id| A
    A -->|account_id / related_account_id| T
    C -->|customer_id| L
    B -->|branch_id| L
    L -->|loan_id| LP
```

---

## Normalization
To eliminate insertion, update, and deletion anomalies, the database was systematically decomposed from a single Unnormalized Form (UNF) flat ledger up to **Boyce-Codd Normal Form (BCNF)**:

- **1NF (Atomic Values):** Flattened multi-valued transaction and EMI payment lists into separate atomic rows.
- **2NF (No Partial Dependencies):** Separated `loan_payments` from `loans` so loan metadata depends solely on `loan_id` rather than a composite `(loan_id, payment_id)` key.
- **3NF (No Transitive Dependencies):** Extracted `customers` and `branches` out of `accounts` so customer contact details and branch IFSC codes are stored once without duplication.
- **BCNF (Superkey Determinants):** Verified across all 6 relations (`branches`, `customers`, `accounts`, `transactions`, `loans`, `loan_payments`) that every non-trivial functional dependency determinant is a candidate key.

**Step-by-Step 1NF → 2NF → 3NF → BCNF Decomposition Proof:** [`docs/Normalization.md`](docs/Normalization.md)

---

## Topics Coverage

| Syllabus Component | Expected Implementation | Location in `GareebSQL` |
| :--- | :--- | :--- |
| **ER Model** | ER diagram with entities & relationships | [`docs/ER_Diagram.md`](docs/ER_Diagram.md) |
| **Relational Model** | Schema design with PKs & FKs | [`docs/Relational_Model.md`](docs/Relational_Model.md) |
| **Normalization** | Step-by-step 1NF, 2NF, 3NF & BCNF proof | [`docs/Normalization.md`](docs/Normalization.md) |
| **SQL Fundamentals** | DDL, DML, DCL & TCL | [`01_create_tables.sql`](sql/01_create_tables.sql), [`02_insert_data.sql`](sql/02_insert_data.sql), [`04_views_and_security.sql`](sql/04_views_and_security.sql) |
| **Complex Queries** | Inner, Outer & Self Joins | [`03_project_queries.sql`](sql/03_project_queries.sql) |
| **Subqueries** | Nested & Correlated subqueries | [`03_project_queries.sql`](sql/03_project_queries.sql) |
| **Set Operations** | `UNION`, `INTERSECT` & `EXCEPT` | [`03_project_queries.sql`](sql/03_project_queries.sql) |
| **Views & Indexing** | 2+ Views & Composite Indexes + `EXPLAIN` | [`04_views_and_security.sql`](sql/04_views_and_security.sql) |
| **Advanced SQL** | Window Functions (`SUM() OVER`, `DENSE_RANK()`) & CTEs | [`03_project_queries.sql`](sql/03_project_queries.sql) |

---

## Repository Structure

```text
GareebSQL/
├── docs/
│   ├── ER_Diagram.md              # Mermaid ER diagram & cardinality rules
│   ├── Relational_Model.md        # PK, FK, Candidate Key & domain constraints
│   └── Normalization.md           # Step-by-step 1NF → 2NF → 3NF → BCNF proof
├── sql/
│   ├── screenshots/               # Verified terminal output screenshots
│   ├── 01_create_tables.sql       # DDL: Schema, keys & CHECK constraints
│   ├── 02_insert_data.sql         # DML: Sample data, UPDATE & DELETE
│   ├── 03_project_queries.sql     # Joins, Subqueries, Set Ops, Window Functions & CTEs
│   ├── 04_views_and_security.sql  # Views, Indexes + EXPLAIN, DCL & TCL
│   └── README.md                  # Sequential SQL execution & screenshot log
├── backend/
│   ├── app.py                     # FastAPI REST API executing raw SQL
│   └── requirements.txt           # Python dependencies
├── frontend/
│   ├── index.html                 # 5-tab interactive ledger interface
│   ├── style.css                  # Dual-theme (Light/Dark) Swiss-ledger styles
│   └── app.js                     # Live API bindings & theme persistence
└── README.md
```

---

## Local Setup & Execution Guide

### 1. Initialize the MySQL 8.0 Database
Run all four SQL scripts sequentially from the repository root (see [`sql/README.md`](sql/README.md) for terminal output proofs):

```powershell
mysql -u root -p < sql/01_create_tables.sql
mysql -u root -p < sql/02_insert_data.sql
mysql -u root -p -t < sql/03_project_queries.sql
mysql -u root -p -t < sql/04_views_and_security.sql
```

### 2. Configure Environment & Python Virtual Environment
Create a `.env` file in the root `GareebSQL/` folder:

```env
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_mysql_password
DB_NAME=gareeb_sql
```

Set up the isolated virtual environment inside `backend/`:

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install --only-binary=:all: -r requirements.txt
cd ..
```

### 3. Launch the Application
From the root `GareebSQL/` directory:

```powershell
uvicorn backend.app:app --reload
```

Open **`http://127.0.0.1:8000`** in your browser (Swagger API docs available at `http://127.0.0.1:8000/docs`).

---

Made by Prabhat Bhatia | DBMS Capstone Project