# Database Normalization (1NF to BCNF)

## Starting Point: Unnormalized Form (UNF)

Imagine a bank starts off storing all customer, branch, account, transaction, and loan records inside one giant, messy spreadsheet:

| customer_id | full_name | branch_name | ifsc_code | account_number | balance | txn_ids | txn_amounts | loan_id | principal_amount | payment_ids |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 101 | Aarav Sharma | Connaught Place | GRBS0001 | ACC1001 | 50000 | T1, T2 | 5000, 2000 | L501 | 200000 | P1, P2 |

### Why this single table fails in real life:

* **Messy lists in single cells:** Columns like `txn_ids` and `payment_ids` cram multiple values into one cell, making SQL searches and math nearly impossible.
* **Can't add a new branch easily (Insertion Anomaly):** You can't record a brand-new bank branch unless at least one customer opens an account there first.
* **Repeated edits everywhere (Update Anomaly):** If the Connaught Place branch changes its name or IFSC code, you have to update thousands of customer rows.
* **Accidental data loss (Deletion Anomaly):** If a customer closes their only account and you delete that row, you accidentally wipe out the branch and loan details tied to it.

---

## Step 1: First Normal Form (1NF)

**The Rule:** No lists or repeating groups in a single cell. Every column must hold a single, atomic value, and every row needs a clear primary key.

**How we fix it:** We split the repeating transaction lists and loan payment lists out of the main sheet so every row represents just one event.

| Table Name | Columns | Primary Key | What Changed |
| :--- | :--- | :--- | :--- |
| **`CustomerAccounts`** | `customer_id`, `full_name`, `email`, `phone`, `branch_id`, `branch_name`, `ifsc_code`, `account_number`, `account_type`, `balance` | `account_number` | Removed multi-valued transaction and payment lists |
| **`Transactions`** | `transaction_id`, `account_number`, `related_account_number`, `type`, `amount`, `txn_date`, `remarks` | `transaction_id` | Each deposit, withdrawal, or transfer gets its own clean row |
| **`CustomerLoans`** | `loan_id`, `payment_id`, `customer_id`, `branch_id`, `loan_type`, `principal_amount`, `interest_rate`, `amount_paid`, `payment_date` | `(loan_id, payment_id)` | Each installment payment gets its own row |

---

## Step 2: Second Normal Form (2NF)

**The Rule:** Must already be in 1NF, and every column must depend on the **entire** primary key—not just half of it. (This matters whenever a table uses a composite key made of two columns.)

**What's wrong in `CustomerLoans`:**

The primary key is `(loan_id, payment_id)`. However:

* `amount_paid` and `payment_date` depend on **both** `loan_id` and `payment_id`.
* `customer_id`, `branch_id`, `loan_type`, `principal_amount`, and `interest_rate` depend **only on `loan_id`**. Every time a customer pays an EMI, we end up repeating the entire loan's principal amount and interest rate.

**How we fix it:** Split the loan details from the individual installment payments.

| Table Name | Columns | Primary Key | Foreign Key |
| :--- | :--- | :--- | :--- |
| **`Loans`** | `loan_id`, `customer_id`, `branch_id`, `loan_type`, `principal_amount`, `interest_rate`, `status`, `issued_date` | `loan_id` | — |
| **`LoanPayments`** | `payment_id`, `loan_id`, `amount_paid`, `payment_date` | `payment_id` | `loan_id` → `Loans` |

---

## Step 3: Third Normal Form (3NF)

**The Rule:** Must already be in 2NF, and non-key columns shouldn't depend on other non-key columns (no indirect/transitive chains).

**What's wrong in `CustomerAccounts`:**

`account_number` is the primary key, but look at the hidden chains inside this table:

* `account_number` → `customer_id` → `full_name`, `email`, `phone`, `city`, `referred_by`
* `account_number` → `branch_id` → `branch_name`, `city`, `ifsc_code`

Because a customer's phone number belongs to the *customer* (not the account), and the IFSC code belongs to the *branch* (not the account), storing them inside `CustomerAccounts` causes massive duplication whenever a customer opens a second account.

**How we fix it:** Give customers, branches, and accounts their own dedicated tables.

| Table Name | Columns | Primary Key | Foreign Keys |
| :--- | :--- | :--- | :--- |
| **`Customers`** | `customer_id`, `full_name`, `email`, `phone`, `city`, `referred_by`, `joined_date` | `customer_id` | `referred_by` → `Customers` |
| **`Branches`** | `branch_id`, `branch_name`, `city`, `ifsc_code` | `branch_id` | — |
| **`Accounts`** | `account_id`, `customer_id`, `branch_id`, `account_number`, `account_type`, `balance`, `status`, `opened_date` | `account_id` | `customer_id` → `Customers`; `branch_id` → `Branches` |

---

## Step 4: Boyce-Codd Normal Form (BCNF)

**The Rule:** A stricter version of 3NF—every column (or set of columns) that uniquely determines another column **must be a candidate key** (a superkey).

**Checking all 6 final tables in `GareebSQL`:**

| Final Table | What Determines What? | Are All Determinants Candidate Keys? | BCNF Status |
| :--- | :--- | :--- | :--- |
| **`branches`** | `branch_id` → all columns; `ifsc_code` → all columns | Yes (`branch_id` is PK, `ifsc_code` is UNIQUE) | **Passed** |
| **`customers`** | `customer_id` → all columns; `email` → all columns; `phone` → all columns | Yes (`customer_id` is PK; `email` & `phone` are UNIQUE) | **Passed** |
| **`accounts`** | `account_id` → all columns; `account_number` → all columns | Yes (`account_id` is PK, `account_number` is UNIQUE) | **Passed** |
| **`transactions`** | `transaction_id` → all columns | Yes (`transaction_id` is PK) | **Passed** |
| **`loans`** | `loan_id` → all columns | Yes (`loan_id` is PK) | **Passed** |
| **`loan_payments`** | `payment_id` → all columns | Yes (`payment_id` is PK) | **Passed** |
