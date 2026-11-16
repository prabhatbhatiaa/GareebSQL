# Entity-Relationship Model & Relational Schema (`GareebSQL`)

## 1. Entities & Business Rules
- **Branches (`branches`)**: Stores bank branch details (`branch_id`, `branch_name`, `city`, `ifsc_code`). One branch manages many accounts and issues many loans.
- **Customers (`customers`)**: Stores customer profiles (`customer_id`, `full_name`, `email`, `phone`, `city`, `referred_by`, `joined_date`). Includes a self-referencing foreign key `referred_by` to track customer referral chains.
- **Accounts (`accounts`)**: Tracks customer savings and current accounts (`account_id`, `customer_id`, `branch_id`, `account_number`, `account_type`, `balance`, `status`, `opened_date`). Enforces `balance >= 0`.
- **Transactions (`transactions`)**: Logs every deposit, withdrawal, and fund transfer (`transaction_id`, `account_id`, `related_account_id`, `type`, `amount`, `txn_date`, `remarks`). Uses `related_account_id` to link sender and receiver accounts during transfers.
- **Loans (`loans`)**: Manages approved customer loans (`loan_id`, `customer_id`, `branch_id`, `loan_type`, `principal_amount`, `interest_rate`, `status`, `issued_date`).
- **Loan Payments (`loan_payments`)**: Records installment repayments against specific loans (`payment_id`, `loan_id`, `amount_paid`, `payment_date`).

## 2. ER Diagram (Mermaid)

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