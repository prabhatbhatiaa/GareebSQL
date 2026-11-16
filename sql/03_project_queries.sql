USE gareeb_sql;

-- Inner Join: Full account statement
SELECT c.full_name, a.account_number, b.branch_name, t.type, t.amount, t.txn_date
FROM transactions t
JOIN accounts a ON t.account_id = a.account_id
JOIN customers c ON a.customer_id = c.customer_id
JOIN branches b ON a.branch_id = b.branch_id
ORDER BY t.txn_date DESC;

-- Left Outer Join: Customers without any loans
SELECT c.customer_id, c.full_name, c.city
FROM customers c
LEFT JOIN loans l ON c.customer_id = l.customer_id
WHERE l.loan_id IS NULL;

-- Self Join: Who referred whom
SELECT c.full_name AS customer, r.full_name AS referred_by
FROM customers c
LEFT JOIN customers r ON c.referred_by = r.customer_id;

-- Self Join: Sender to receiver transfer log
SELECT t.transaction_id, s.account_number AS from_acc, r.account_number AS to_acc, t.amount
FROM transactions t
JOIN accounts s ON t.account_id = s.account_id
JOIN accounts r ON t.related_account_id = r.account_id
WHERE t.type = 'Transfer_Out';

-- Nested Subquery: Customers with active loans over 2.5L
SELECT full_name, email, city
FROM customers
WHERE customer_id IN (
    SELECT customer_id FROM loans
    WHERE status = 'Active' AND principal_amount > 250000
);

-- Correlated Subquery: Accounts above their branch average balance
SELECT a.account_number, a.branch_id, a.balance
FROM accounts a
WHERE a.balance > (
    SELECT AVG(a2.balance) FROM accounts a2
    WHERE a2.branch_id = a.branch_id
);

-- Set Operations: UNION, INTERSECT, EXCEPT
SELECT customer_id FROM accounts WHERE account_type = 'Current'
UNION
SELECT customer_id FROM loans WHERE status = 'Active';

SELECT customer_id FROM accounts WHERE account_type = 'Savings'
INTERSECT
SELECT customer_id FROM loans;

SELECT account_id FROM transactions WHERE type = 'Deposit'
EXCEPT
SELECT account_id FROM transactions WHERE type = 'Withdrawal';

-- Window Function: Running balance per account
SELECT a.account_number, t.txn_date, t.type, t.amount,
    SUM(CASE WHEN t.type IN ('Deposit', 'Transfer_In') THEN t.amount ELSE -t.amount END)
    OVER (PARTITION BY t.account_id ORDER BY t.txn_date) AS running_balance
FROM transactions t
JOIN accounts a ON t.account_id = a.account_id;

-- Window Function: Rank customers by total balance
SELECT c.full_name, SUM(a.balance) AS total_balance,
    DENSE_RANK() OVER (ORDER BY SUM(a.balance) DESC) AS balance_rank
FROM customers c
JOIN accounts a ON c.customer_id = a.customer_id
GROUP BY c.customer_id, c.full_name;

-- CTE: Monthly net cash flow
WITH monthly_flow AS (
    SELECT DATE_FORMAT(txn_date, '%Y-%m') AS month,
        SUM(CASE WHEN type IN ('Deposit', 'Transfer_In') THEN amount ELSE 0 END) AS inflow,
        SUM(CASE WHEN type IN ('Withdrawal', 'Transfer_Out') THEN amount ELSE 0 END) AS outflow
    FROM transactions
    GROUP BY month
)
SELECT month, inflow, outflow, (inflow - outflow) AS net_flow
FROM monthly_flow
ORDER BY month;