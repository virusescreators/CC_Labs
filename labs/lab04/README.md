# Lab 04 — DynamoDB & DocumentDB

## Objective

Create and explore NoSQL databases. Insert data, query using keys and indexes, enable streams, and compare services.

---

## AWS

### Tasks 2–4 — DynamoDB Table & Items

- Table `Lab4-Students` with `StudentID` (partition) + `CourseID` (sort) keys
- 4 student items inserted:

| StudentID | CourseID | Name | Department | GPA |
|-----------|----------|------|------------|-----|
| S001 | CS101 | Ali Khan | Computer Science | 3.8 |
| S002 | CS102 | Sara Ahmed | Computer Science | 3.5 |
| S003 | EE201 | Usman Tariq | Electrical Engineering | 3.2 |
| S004 | ME301 | Fatima Noor | Mechanical Engineering | 3.9 |

### Task 5 — Global Secondary Index

- GSI `DepartmentIndex` with `Department` as hash key

### Task 6 — DynamoDB Streams

- Streams enabled with `NEW_AND_OLD_IMAGES` view type

### Tasks 7–8 — DocumentDB Cluster

- Cluster `lab4-docdb-cluster` with `db.t3.medium` instance
- VPC + subnets + security group (port 27017)
- ⚠️ **Not Free Tier** — destroy after lab

### Tasks 9–11 — Manual (mongosh commands in `main.tf`)

```javascript
use lab4db
db.students.insertMany([...])
db.students.find({ department: "CS" })
db.students.createIndex({ department: 1 })
```

---

## Azure

### Tasks 2–6 — Cosmos DB Table API (DynamoDB Equivalent)

| Resource | Description |
|----------|-------------|
| `azurerm_cosmosdb_account` | Cosmos DB account with Table API + Free Tier enabled |
| `azurerm_cosmosdb_table` | Table `Lab4Students` |

- **Indexing**: Cosmos DB auto-indexes all properties (no explicit GSI needed)
- **Streams**: Change Feed is enabled by default (like DynamoDB Streams)
- **Insert items** via Azure Portal > Data Explorer using PartitionKey/RowKey

### Tasks 7–11 — Cosmos DB MongoDB API (DocumentDB Equivalent)

| Resource | Description |
|----------|-------------|
| `azurerm_cosmosdb_account` | Cosmos DB account with MongoDB API |
| `azurerm_cosmosdb_mongo_database` | Database `lab4db` |
| `azurerm_cosmosdb_mongo_collection` | Collection `students` with indexes on `department` and `gpa` |

- Connect via **MongoDB Compass** using the connection string from Azure Portal
- Insert documents and query the same way as AWS DocumentDB

### Task 12 — Comparison

| Feature | AWS DynamoDB | AWS DocumentDB | Azure Cosmos DB (Table) | Azure Cosmos DB (MongoDB) |
|---------|-------------|----------------|------------------------|--------------------------|
| Latency | Single-digit ms | Low ms | Single-digit ms | Low ms |
| Scalability | Auto-scales | Manual | Auto-scales | Auto-scales |
| Durability | Multi-AZ | Multi-AZ | Global distribution | Global distribution |
| Indexing | Explicit (GSI) | MongoDB indexes | Auto-indexed | Configurable |
| Pricing | Pay-per-request | Instance hours | RU/s based | RU/s based |

---

## Deployment

```
Actions → Deploy Labs → Lab 4 → aws/azure → apply
```
