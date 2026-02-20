# 💳 Transaction Data Integrity & ACID Compliance Test Suite


---

## 📌 Overview

This project provides a comprehensive SQL test suite to validate:

- Financial data integrity  
- ACID compliance  
- Concurrency handling  
- Performance under load  
- Data migration accuracy  

Designed for:

- QA Engineers  
- Backend Engineers  
- Data Engineers  
- FinTech Teams  
- Database Administrators  

---

## 🏗 System Schema

### Accounts Table

```sql
CREATE TABLE accounts (
    account_id VARCHAR(20) PRIMARY KEY,
    user_id INT,
    balance DECIMAL(15,2),
    currency VARCHAR(3),
    status VARCHAR(20),
    created_at TIMESTAMP
);
```

### Transactions Table

```sql
CREATE TABLE transactions (
    transaction_id VARCHAR(30) PRIMARY KEY,
    from_account VARCHAR(20),
    to_account VARCHAR(20),
    amount DECIMAL(15,2),
    currency VARCHAR(3),
    exchange_rate DECIMAL(10,6),
    status VARCHAR(20),
    created_at TIMESTAMP,
    completed_at TIMESTAMP
);
```

---

## 🔐 ACID Validation Strategy

| Property    | Validation Method |
|-------------|-------------------|
| Atomicity   | Forced rollback simulation |
| Consistency | Logical + constraint validation |
| Isolation   | Multi-session concurrency test |
| Durability  | Commit + restart verification |

---

## 🧪 Test Coverage

### 1️⃣ Data Integrity

- Negative balance detection
- Orphan transaction validation
- Currency mismatch checks
- Timestamp validation
- Duplicate transaction detection
- Balance reconciliation validation

### 2️⃣ Concurrency & Isolation

- Row-level locking validation
- Lost update prevention
- Double spending simulation

### 3️⃣ Performance Testing

- Indexed lookup validation
- Large dataset aggregation benchmarks
- Execution plan analysis

### 4️⃣ Data Migration Validation

- Row count comparison
- Balance recalculation
- Duplicate detection
- Exchange rate validation

