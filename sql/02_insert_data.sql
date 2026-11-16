USE gareeb_sql;

INSERT INTO branches (branch_name, city, ifsc_code) VALUES
('Main Branch', 'Delhi', 'GRBS0001'),
('City Center', 'Gurugram', 'GRBS0002'),
('South Branch', 'Mumbai', 'GRBS0003');

INSERT INTO customers (full_name, email, phone, city, referred_by, joined_date) VALUES
('Rahul Verma', 'rahul@gmail.com', '9800000001', 'Delhi', NULL, '2026-01-05'),
('Priya Sharma', 'priya@gmail.com', '9800000002', 'Delhi', 1, '2026-01-12'),
('Amit Kumar', 'amit@gmail.com', '9800000003', 'Gurugram', 1, '2026-01-20'),
('Neha Gupta', 'neha@gmail.com', '9800000004', 'Mumbai', 2, '2026-02-02'),
('Rohan Das', 'rohan@gmail.com', '9800000005', 'Gurugram', NULL, '2026-02-10');

INSERT INTO accounts (customer_id, branch_id, account_number, account_type, balance, status, opened_date) VALUES
(1, 1, 'ACC1001', 'Savings', 50000.00, 'Active', '2026-01-05'),
(1, 1, 'ACC1002', 'Current', 120000.00, 'Active', '2026-01-15'),
(2, 1, 'ACC1003', 'Savings', 35000.00, 'Active', '2026-01-12'),
(3, 2, 'ACC1004', 'Savings', 80000.00, 'Active', '2026-01-20'),
(4, 3, 'ACC1005', 'Savings', 25000.00, 'Active', '2026-02-02'),
(5, 2, 'ACC1006', 'Savings', 10000.00, 'Frozen', '2026-02-10');

INSERT INTO transactions (account_id, related_account_id, type, amount, txn_date, remarks) VALUES
(1, NULL, 'Deposit', 60000.00, '2026-01-10 10:00:00', 'Salary deposit'),
(1, 3, 'Transfer_Out', 10000.00, '2026-01-18 14:00:00', 'Sent to Priya'),
(3, 1, 'Transfer_In', 10000.00, '2026-01-18 14:00:00', 'Received from Rahul'),
(3, NULL, 'Deposit', 30000.00, '2026-01-14 11:30:00', 'Initial deposit'),
(3, NULL, 'Withdrawal', 5000.00, '2026-02-05 16:00:00', 'ATM withdrawal'),
(4, NULL, 'Deposit', 90000.00, '2026-01-25 12:00:00', 'Bonus deposit'),
(4, NULL, 'Withdrawal', 10000.00, '2026-02-12 17:15:00', 'Bill payment'),
(5, NULL, 'Deposit', 25000.00, '2026-02-03 09:45:00', 'Savings deposit'),
(6, NULL, 'Deposit', 10000.00, '2026-02-11 13:00:00', 'Opening balance');

INSERT INTO loans (customer_id, branch_id, loan_type, principal_amount, interest_rate, status, issued_date) VALUES
(1, 1, 'Home', 500000.00, 8.50, 'Active', '2026-01-20'),
(3, 2, 'Vehicle', 200000.00, 9.00, 'Active', '2026-02-01'),
(2, 1, 'Education', 100000.00, 7.50, 'Closed', '2026-01-15'),
(5, 2, 'Personal', 50000.00, 11.00, 'Pending', '2026-02-15');

INSERT INTO loan_payments (loan_id, amount_paid, payment_date) VALUES
(1, 15000.00, '2026-02-20'),
(1, 15000.00, '2026-03-20'),
(2, 10000.00, '2026-03-01'),
(3, 100000.00, '2026-02-10');

UPDATE accounts
SET status = 'Active'
WHERE account_number = 'ACC1006';

INSERT INTO loans (customer_id, branch_id, loan_type, principal_amount, interest_rate, status, issued_date)
VALUES (4, 3, 'Personal', 30000.00, 12.00, 'Rejected', '2026-02-20');

DELETE FROM loans
WHERE customer_id = 4 AND status = 'Rejected';