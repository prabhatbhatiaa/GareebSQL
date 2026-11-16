USE gareeb_sql;

-- View 1: Customer total balance summary
CREATE OR REPLACE VIEW customer_balance_summary AS
SELECT c.customer_id, c.full_name, c.city,
    COUNT(a.account_id) AS total_accounts,
    COALESCE(SUM(a.balance), 0.00) AS total_balance
FROM customers c
LEFT JOIN accounts a ON c.customer_id = a.customer_id
GROUP BY c.customer_id, c.full_name, c.city;

-- View 2: Loan portfolio and repayment summary
CREATE OR REPLACE VIEW loan_portfolio_summary AS
SELECT l.loan_id, c.full_name, l.loan_type, l.principal_amount, l.status,
    COALESCE(SUM(lp.amount_paid), 0.00) AS total_paid,
    (l.principal_amount - COALESCE(SUM(lp.amount_paid), 0.00)) AS remaining_principal
FROM loans l
JOIN customers c ON l.customer_id = c.customer_id
LEFT JOIN loan_payments lp ON l.loan_id = lp.loan_id
GROUP BY l.loan_id, c.full_name, l.loan_type, l.principal_amount, l.status;

SELECT * FROM customer_balance_summary;
SELECT * FROM loan_portfolio_summary;

-- Indexing: Speed up statement lookups and loan queries
CREATE INDEX idx_txn_account_date ON transactions(account_id, txn_date);
CREATE INDEX idx_loan_customer ON loans(customer_id);

EXPLAIN SELECT * FROM transactions
WHERE account_id = 1 AND txn_date >= '2026-01-01';

-- DCL: Create users and manage privileges
DROP USER IF EXISTS 'bank_teller'@'localhost';
DROP USER IF EXISTS 'auditor_readonly'@'localhost';

CREATE USER 'bank_teller'@'localhost' IDENTIFIED BY 'Teller@123';
CREATE USER 'auditor_readonly'@'localhost' IDENTIFIED BY 'Audit@123';

GRANT SELECT, INSERT, UPDATE ON gareeb_sql.accounts TO 'bank_teller'@'localhost';
GRANT SELECT, INSERT ON gareeb_sql.transactions TO 'bank_teller'@'localhost';
GRANT SELECT ON gareeb_sql.* TO 'auditor_readonly'@'localhost';

REVOKE UPDATE ON gareeb_sql.accounts FROM 'bank_teller'@'localhost';
FLUSH PRIVILEGES;

SHOW GRANTS FOR 'bank_teller'@'localhost';
SHOW GRANTS FOR 'auditor_readonly'@'localhost';

-- TCL: Atomic fund transfer with COMMIT and SAVEPOINT rollback
START TRANSACTION;

UPDATE accounts SET balance = balance - 5000.00 WHERE account_number = 'ACC1001';
UPDATE accounts SET balance = balance + 5000.00 WHERE account_number = 'ACC1003';
INSERT INTO transactions (account_id, related_account_id, type, amount, remarks)
VALUES (1, 3, 'Transfer_Out', 5000.00, 'Verified transfer');

SAVEPOINT after_valid_transfer;

-- Simulate an accidental duplicate deduction and roll it back
UPDATE accounts SET balance = balance - 2000.00 WHERE account_number = 'ACC1001';
ROLLBACK TO SAVEPOINT after_valid_transfer;

COMMIT;
SELECT account_number, balance FROM accounts WHERE account_number IN ('ACC1001', 'ACC1003');