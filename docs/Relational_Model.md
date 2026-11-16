# Relational Model & Schema Design

## 1. Relational Schema Notation
In the relational model, each entity from the ER diagram is mapped to a relation (table) with clearly defined **Primary Keys (PK)**, **Foreign Keys (FK)**, **Candidate Keys**, and **Domain Integrity Rules**.

* **`branches`**(`branch_id` **[PK]**, `branch_name`, `city`, `ifsc_code` **[UK]**)
* **`customers`**(`customer_id` **[PK]**, `full_name`, `email` **[UK]**, `phone` **[UK]**, `city`, `referred_by` **[FK $\rightarrow$ customers.customer_id]**, `joined_date`)
* **`accounts`**(`account_id` **[PK]**, `customer_id` **[FK $\rightarrow$ customers.customer_id]**, `branch_id` **[FK $\rightarrow$ branches.branch_id]**, `account_number` **[UK]**, `account_type`, `balance`, `status`, `opened_date`)
* **`transactions`**(`transaction_id` **[PK]**, `account_id` **[FK $\rightarrow$ accounts.account_id]**, `related_account_id` **[FK $\rightarrow$ accounts.account_id]**, `type`, `amount`, `txn_date`, `remarks`)
* **`loans`**(`loan_id` **[PK]**, `customer_id` **[FK $\rightarrow$ customers.customer_id]**, `branch_id` **[FK $\rightarrow$ branches.branch_id]**, `loan_type`, `principal_amount`, `interest_rate`, `status`, `issued_date`)
* **`loan_payments`**(`payment_id` **[PK]**, `loan_id` **[FK $\rightarrow$ loans.loan_id]**, `amount_paid`, `payment_date`)

---

## 2. Detailed Table-by-Table Key & Constraint Specification

### Table 1: `branches`
| Column Name | Data Type | Key Type | Constraints & Purpose |
| :--- | :--- | :--- | :--- |
| `branch_id` | `INT` | **Primary Key** | Auto-incrementing unique branch identifier |
| `branch_name` | `VARCHAR(100)` | — | `NOT NULL` — Human-readable branch name |
| `city` | `VARCHAR(60)` | — | `NOT NULL` — City where the branch operates |
| `ifsc_code` | `VARCHAR(15)` | **Candidate Key** | `NOT NULL`, `UNIQUE` — Official banking branch code |

### Table 2: `customers`
| Column Name | Data Type | Key Type | Constraints & Purpose |
| :--- | :--- | :--- | :--- |
| `customer_id` | `INT` | **Primary Key** | Auto-incrementing unique customer identifier |
| `full_name` | `VARCHAR(100)` | — | `NOT NULL` — Customer's legal full name |
| `email` | `VARCHAR(120)` | **Candidate Key** | `NOT NULL`, `UNIQUE`, `CHECK` valid email format |
| `phone` | `VARCHAR(15)` | **Candidate Key** | `NOT NULL`, `UNIQUE` — Registered mobile number |
| `city` | `VARCHAR(60)` | — | `NOT NULL` — Customer's residential city |
| `referred_by` | `INT` | **Foreign Key** | References `customers(customer_id)` (`ON DELETE SET NULL`) |
| `joined_date` | `DATE` | — | `NOT NULL` — Date customer onboarded |

### Table 3: `accounts`
| Column Name | Data Type | Key Type | Constraints & Purpose |
| :--- | :--- | :--- | :--- |
| `account_id` | `INT` | **Primary Key** | Auto-incrementing internal account ID |
| `customer_id` | `INT` | **Foreign Key** | `NOT NULL`, references `customers(customer_id)` (`ON DELETE RESTRICT`) |
| `branch_id` | `INT` | **Foreign Key** | `NOT NULL`, references `branches(branch_id)` (`ON DELETE RESTRICT`) |
| `account_number` | `VARCHAR(20)` | **Candidate Key** | `NOT NULL`, `UNIQUE` — Public-facing account number |
| `account_type` | `ENUM` | — | `'Savings'` or `'Current'` (`NOT NULL`) |
| `balance` | `DECIMAL(12,2)` | — | `NOT NULL`, `CHECK (balance >= 0.00)` — Prevents negative balances |
| `status` | `ENUM` | — | `'Active'`, `'Frozen'`, or `'Closed'` (`NOT NULL`) |
| `opened_date` | `DATE` | — | `NOT NULL` — Account creation date |

### Table 4: `transactions`
| Column Name | Data Type | Key Type | Constraints & Purpose |
| :--- | :--- | :--- | :--- |
| `transaction_id` | `INT` | **Primary Key** | Auto-incrementing transaction receipt ID |
| `account_id` | `INT` | **Foreign Key** | `NOT NULL`, references `accounts(account_id)` (`ON DELETE RESTRICT`) |
| `related_account_id` | `INT` | **Foreign Key** | `NULL`, references `accounts(account_id)` for peer-to-peer transfers |
| `type` | `ENUM` | — | `'Deposit'`, `'Withdrawal'`, `'Transfer_Out'`, `'Transfer_In'` |
| `amount` | `DECIMAL(12,2)` | — | `NOT NULL`, `CHECK (amount > 0.00)` — Prevents zero/negative transfers |
| `txn_date` | `DATETIME` | — | `NOT NULL`, defaults to `CURRENT_TIMESTAMP` |
| `remarks` | `VARCHAR(255)` | — | Optional transaction description |

### Table 5: `loans`
| Column Name | Data Type | Key Type | Constraints & Purpose |
| :--- | :--- | :--- | :--- |
| `loan_id` | `INT` | **Primary Key** | Auto-incrementing loan sanction ID |
| `customer_id` | `INT` | **Foreign Key** | `NOT NULL`, references `customers(customer_id)` (`ON DELETE RESTRICT`) |
| `branch_id` | `INT` | **Foreign Key** | `NOT NULL`, references `branches(branch_id)` (`ON DELETE RESTRICT`) |
| `loan_type` | `ENUM` | — | `'Home'`, `'Personal'`, `'Education'`, or `'Vehicle'` |
| `principal_amount` | `DECIMAL(12,2)` | — | `NOT NULL`, `CHECK (principal_amount > 0.00)` |
| `interest_rate` | `DECIMAL(5,2)` | — | `NOT NULL`, `CHECK (interest_rate > 0.00 AND interest_rate <= 30.00)` |
| `status` | `ENUM` | — | `'Pending'`, `'Active'`, `'Closed'`, or `'Rejected'` |
| `issued_date` | `DATE` | — | `NOT NULL` — Date loan was issued |

### Table 6: `loan_payments`
| Column Name | Data Type | Key Type | Constraints & Purpose |
| :--- | :--- | :--- | :--- |
| `payment_id` | `INT` | **Primary Key** | Auto-incrementing installment receipt ID |
| `loan_id` | `INT` | **Foreign Key** | `NOT NULL`, references `loans(loan_id)` (`ON DELETE RESTRICT`) |
| `amount_paid` | `DECIMAL(12,2)` | — | `NOT NULL`, `CHECK (amount_paid > 0.00)` |
| `payment_date` | `DATE` | — | `NOT NULL` — Date EMI was paid |

---

## 3. Referential Integrity Rules Summary
1. **`ON DELETE RESTRICT`** on `accounts`, `transactions`, `loans`, and `loan_payments`: Prevents deleting a customer, branch, account, or loan if financial history exists—preserving a tamper-proof audit trail.
2. **`ON DELETE SET NULL`** on `customers(referred_by)` and `transactions(related_account_id)`: Keeps customer and transaction records intact even if a referring user or counterparty reference is cleared.