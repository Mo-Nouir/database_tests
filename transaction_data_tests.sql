/*****************************************************************************************
 File: transaction_data_integrity_tests.sql
 Purpose: Validate ACID compliance, data integrity, performance, and migration accuracy
 System: Transaction Processing System
 Author: QA Data Integrity Suite
******************************************************************************************/

/*****************************************************************************************
 SECTION 1: DATA INTEGRITY TESTS
******************************************************************************************/

/*****************************************************************************************
 TC-DI-01: Atomicity Test – Ensure full rollback on failure

 Scenario:
 - Deduct balance from sender
 - Simulate failure before credit
 - Rollback transaction
 Expected:
 - No balance change
 - No transaction inserted
******************************************************************************************/

BEGIN;

-- Step 1: Deduct 500 from sender
UPDATE accounts
SET balance = balance - 500
WHERE account_id = 'ACC100';

-- Step 2: Force failure (duplicate primary key simulation)
-- Assumes transaction_id already exists
INSERT INTO transactions (transaction_id)
VALUES ('EXISTING_TXN_ID');

-- If error occurs, rollback entire transaction
ROLLBACK;

-- Validation: Balance should remain unchanged
SELECT account_id, balance
FROM accounts
WHERE account_id = 'ACC100';


/*****************************************************************************************
 TC-DI-02: Consistency Test – No Negative Balances Allowed

 Rule:
 Account balances must never be negative
******************************************************************************************/

SELECT account_id, balance
FROM accounts
WHERE balance < 0;

-- Expected Result:
-- 0 rows returned


/*****************************************************************************************
 TC-DI-03: Referential Integrity – No Orphan Transactions

 Rule:
 Every transaction must reference valid accounts
******************************************************************************************/

SELECT transaction_id
FROM transactions
WHERE from_account NOT IN (SELECT account_id FROM accounts)
   OR to_account NOT IN (SELECT account_id FROM accounts);

-- Expected Result:
-- 0 rows returned


/*****************************************************************************************
 TC-DI-04: Currency Consistency Check

 Rule:
 Transaction currency must match account currency (for non-FX transfers)
******************************************************************************************/

SELECT t.transaction_id
FROM transactions t
JOIN accounts a ON t.from_account = a.account_id
WHERE t.currency != a.currency
AND t.exchange_rate = 1;

-- Expected Result:
-- 0 rows


/*****************************************************************************************
 TC-DI-05: Timestamp Logical Validation

 Rule:
 completed_at must not be earlier than created_at
******************************************************************************************/

SELECT transaction_id, created_at, completed_at
FROM transactions
WHERE completed_at IS NOT NULL
AND completed_at < created_at;

-- Expected Result:
-- 0 rows


/*****************************************************************************************
 SECTION 2: ISOLATION & CONCURRENCY TESTING
******************************************************************************************/

/*****************************************************************************************
 TC-DI-06: Row Locking Test (Run in Two Separate Sessions)

 Session 1:
******************************************************************************************/

-- SESSION 1
BEGIN;

UPDATE accounts
SET balance = balance - 1000
WHERE account_id = 'ACC100';

-- Do NOT commit yet
-- This should lock the row


/*
 SESSION 2 (Run separately)

BEGIN;

UPDATE accounts
SET balance = balance - 1000
WHERE account_id = 'ACC100';

COMMIT;

Expected:
- Session 2 waits until Session 1 commits or rollbacks
- No lost update
*/


/*****************************************************************************************
 SECTION 3: PERFORMANCE TESTING
******************************************************************************************/

/*****************************************************************************************
 TC-PERF-01: Index Creation (If Not Exists)
******************************************************************************************/

CREATE INDEX IF NOT EXISTS idx_transactions_from_account
ON transactions(from_account);

CREATE INDEX IF NOT EXISTS idx_transactions_to_account
ON transactions(to_account);

CREATE INDEX IF NOT EXISTS idx_transactions_created_at
ON transactions(created_at);


/*****************************************************************************************
 TC-PERF-02: Transaction Lookup Performance

 Benchmark:
 - Execution time < 100ms
 - Must use Index Scan
******************************************************************************************/

EXPLAIN ANALYZE
SELECT *
FROM transactions
WHERE from_account = 'ACC100'
ORDER BY created_at DESC
LIMIT 100;


/*****************************************************************************************
 TC-PERF-03: Balance Lookup Performance

 Benchmark:
 - Execution time < 5ms
 - Should use Primary Key Index
******************************************************************************************/

EXPLAIN ANALYZE
SELECT balance
FROM accounts
WHERE account_id = 'ACC100';


/*****************************************************************************************
 TC-PERF-04: Aggregation Over Large Dataset

 Benchmark:
 - < 300ms for ~1M rows
******************************************************************************************/

EXPLAIN ANALYZE
SELECT SUM(amount)
FROM transactions
WHERE created_at > NOW() - INTERVAL '30 days';


/*****************************************************************************************
 SECTION 4: DATA MIGRATION VALIDATION
******************************************************************************************/

/*****************************************************************************************
 TC-MIG-01: Row Count Validation

 Ensure migrated transaction count matches legacy system
******************************************************************************************/

SELECT COUNT(*) AS legacy_count FROM legacy_transactions;
SELECT COUNT(*) AS new_count FROM transactions;

-- Expected:
-- Counts must match exactly


/*****************************************************************************************
 TC-MIG-02: Duplicate Transaction Detection
******************************************************************************************/

SELECT transaction_id, COUNT(*)
FROM transactions
GROUP BY transaction_id
HAVING COUNT(*) > 1;

-- Expected:
-- 0 rows


/*****************************************************************************************
 TC-MIG-03: Balance Reconciliation Validation

 Recalculate balance from transactions and compare to stored balance
******************************************************************************************/

WITH calculated_balances AS (
    SELECT
        a.account_id,
        COALESCE(SUM(
            CASE
                WHEN t.from_account = a.account_id THEN -t.amount
                WHEN t.to_account = a.account_id THEN t.amount
                ELSE 0
            END
        ), 0) AS computed_balance
    FROM accounts a
    LEFT JOIN transactions t
        ON t.from_account = a.account_id
        OR t.to_account = a.account_id
    GROUP BY a.account_id
)

SELECT a.account_id,
       a.balance AS stored_balance,
       cb.computed_balance
FROM accounts a
JOIN calculated_balances cb
ON a.account_id = cb.account_id
WHERE a.balance <> cb.computed_balance;

-- Expected:
-- 0 rows (balances must match)


/*****************************************************************************************
 TC-MIG-04: Missing Exchange Rate Validation (For FX Transfers)

 Rule:
 If currency differs from account currency, exchange_rate must not be NULL
******************************************************************************************/

SELECT transaction_id
FROM transactions t
JOIN accounts a ON t.from_account = a.account_id
WHERE t.currency != a.currency
AND t.exchange_rate IS NULL;

-- Expected:
-- 0 rows


/*****************************************************************************************
 SECTION 5: DURABILITY TEST (Manual Verification)

 Steps:
 1. Perform a committed transaction
 2. Restart database server
 3. Verify transaction still exists

 Validation Query:
******************************************************************************************/

SELECT *
FROM transactions
WHERE transaction_id = 'TEST_DURABILITY_TXN';

-- Expected:
-- Transaction persists after restart


/*****************************************************************************************
 END OF TEST SUITE
******************************************************************************************/
