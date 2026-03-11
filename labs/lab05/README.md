# Lab 05 — RDS & Aurora Databases

## Objective

Create and manage relational databases using Amazon RDS (MySQL) and explore Aurora architecture. Set up parameter groups, snapshots, automated backups, and read replicas.

---

## AWS

### Task 1 — RDS MySQL Instance

- Instance `lab5-rds-mysql`: `db.t3.micro` (Free Tier), MySQL 8.0, 20 GB gp2
- Database `lab5db` with public access enabled
- VPC + 2 subnets (multi-AZ) + security group (port 3306)

### Task 2 — Connect to RDS

Connect using MySQL CLI, Python, Node.js, or a GUI client (MySQL Workbench / DBeaver):

```bash
mysql -h <rds_endpoint> -P 3306 -u lab5admin -p lab5db
```

### Task 3 — Create and Manage Tables

```sql
CREATE TABLE students (
    student_id VARCHAR(10) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    department VARCHAR(100),
    gpa DECIMAL(3,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO students VALUES
    ('S001', 'Ali Khan', 'Computer Science', 3.80, NOW()),
    ('S002', 'Sara Ahmed', 'Computer Science', 3.50, NOW()),
    ('S003', 'Usman Tariq', 'Electrical Engineering', 3.20, NOW()),
    ('S004', 'Fatima Noor', 'Mechanical Engineering', 3.90, NOW());
```

### Task 4 — Custom Parameter Group

- Parameter group `lab5-mysql-params` (family `mysql8.0`)
- Modified: `max_connections=100`, `slow_query_log=1`, `long_query_time=2`, `character_set_server=utf8mb4`

### Task 5 — Manual Snapshot & Restore

- Snapshot `lab5-rds-manual-snapshot` created from the primary instance
- To restore: RDS Console > Snapshots > Restore (creates a new instance)

### Task 6 — Automated Backups & Read Replica

- Backups: 7-day retention, daily window `03:00-04:00 UTC`
- Read replica: `lab5-rds-read-replica` (`db.t3.micro`)

### Task 7 — Migrate Local MySQL to RDS

```bash
# Export
mysqldump -u root -p local_database > local_backup.sql
# Import
mysql -h <rds_endpoint> -P 3306 -u lab5admin -p lab5db < local_backup.sql
```

---

## Azure

### Tasks 1–3 — MySQL Flexible Server

| Resource | Description |
|----------|-------------|
| `azurerm_mysql_flexible_server` | MySQL 8.0, Burstable B1ms, 20 GB storage |
| `azurerm_mysql_flexible_database` | Database `lab5db` (utf8mb4) |
| `azurerm_mysql_flexible_server_firewall_rule` | Allow all IPs (lab only) |

Connect the same way as AWS — use the server FQDN from outputs.

### Task 4 — Server Configurations (Parameter Groups)

| Parameter | Value |
|-----------|-------|
| `max_connections` | 100 |
| `slow_query_log` | ON |
| `long_query_time` | 2 |
| `character_set_server` | utf8mb4 |

### Task 5 — Backup & Restore

- 7-day automated backup retention
- Restore via Azure Portal > MySQL Flexible Server > Backup and Restore > Point-in-time restore

### Task 6 — Read Replica

- Replica `lab5-mysql-replica-xxx` linked to primary via `source_server_id` + `create_mode = "Replica"`

### Task 7 — Migration

Same `mysqldump` export/import approach, or use **Azure Database Migration Service (DMS)**.

---

## Comparison

| Feature | AWS RDS MySQL | Azure MySQL Flexible Server |
|---------|--------------|----------------------------|
| Engine | MySQL 8.0 | MySQL 8.0 |
| HA | Multi-AZ standby | Zone-redundant HA |
| Read Replicas | Up to 5 | Up to 10 |
| Backups | Automated + manual snapshots | Automated + point-in-time restore |
| Parameters | DB Parameter Groups | Server Configurations |
| Pricing | Instance hours + storage | vCore + storage |
| Free Tier | db.t3.micro (750 hrs/mo) | B1ms (750 hrs/mo, 12 months) |

---

## Aurora (Reference)

Amazon Aurora is **not Free Tier eligible** but offers significant advantages:

- **Cluster-based**: 1 writer + up to 15 read replicas sharing distributed storage
- **Storage**: auto-scales 10 GB → 128 TB, replicated 6× across 3 AZs
- **Failover**: < 30 seconds with automatic replica promotion
- **Serverless v2**: auto-scales compute based on demand

---

## Deployment

```
Actions → Deploy Labs → Lab 5 → aws/azure → apply
```
