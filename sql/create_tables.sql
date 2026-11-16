DROP DATABASE IF EXISTS gareeb_sql;
CREATE DATABASE gareeb_sql;
USE gareeb_sql;

CREATE TABLE branches (
    branch_id INT AUTO_INCREMENT PRIMARY KEY,
    branch_name VARCHAR(100) NOT NULL,
    city VARCHAR(60) NOT NULL,
    ifsc_code VARCHAR(15) NOT NULL UNIQUE
);

CREATE TABLE customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(120) NOT NULL UNIQUE,
    phone VARCHAR(15) NOT NULL UNIQUE,
    city VARCHAR(60) NOT NULL,
    referred_by INT NULL,
    joined_date DATE NOT NULL,
    FOREIGN KEY (referred_by) REFERENCES customers(customer_id) ON DELETE SET NULL,
    CHECK (email LIKE '%_@__%.__%')
);

CREATE TABLE accounts (
    account_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    branch_id INT NOT NULL,
    account_number VARCHAR(20) NOT NULL UNIQUE,
    account_type ENUM('Savings', 'Current') NOT NULL DEFAULT 'Savings',
    balance DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    status ENUM('Active', 'Frozen', 'Closed') NOT NULL DEFAULT 'Active',
    opened_date DATE NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE RESTRICT,
    FOREIGN KEY (branch_id) REFERENCES branches(branch_id) ON DELETE RESTRICT,
    CHECK (balance >= 0.00)
);

CREATE TABLE transactions (
    transaction_id INT AUTO_INCREMENT PRIMARY KEY,
    account_id INT NOT NULL,
    related_account_id INT NULL,
    type ENUM('Deposit', 'Withdrawal', 'Transfer_Out', 'Transfer_In') NOT NULL,
    amount DECIMAL(12, 2) NOT NULL,
    txn_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    remarks VARCHAR(255) NULL,
    FOREIGN KEY (account_id) REFERENCES accounts(account_id) ON DELETE RESTRICT,
    FOREIGN KEY (related_account_id) REFERENCES accounts(account_id) ON DELETE SET NULL,
    CHECK (amount > 0.00)
);

CREATE TABLE loans (
    loan_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    branch_id INT NOT NULL,
    loan_type ENUM('Home', 'Personal', 'Education', 'Vehicle') NOT NULL,
    principal_amount DECIMAL(12, 2) NOT NULL,
    interest_rate DECIMAL(5, 2) NOT NULL,
    status ENUM('Pending', 'Active', 'Closed', 'Rejected') NOT NULL DEFAULT 'Pending',
    issued_date DATE NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE RESTRICT,
    FOREIGN KEY (branch_id) REFERENCES branches(branch_id) ON DELETE RESTRICT,
    CHECK (principal_amount > 0.00),
    CHECK (interest_rate > 0.00 AND interest_rate <= 30.00)
);

CREATE TABLE loan_payments (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    loan_id INT NOT NULL,
    amount_paid DECIMAL(12, 2) NOT NULL,
    payment_date DATE NOT NULL,
    FOREIGN KEY (loan_id) REFERENCES loans(loan_id) ON DELETE RESTRICT,
    CHECK (amount_paid > 0.00)
);