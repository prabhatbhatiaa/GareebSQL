<h1 align="center">SQL Execution & Proof</h1>
<p align="center">Step-by-step execution of all SQL scripts in MySQL 8.0 with terminal screenshots.</p>

---

## 1. Create Tables (`01_create_tables.sql`)
**Run:**
```powershell
mysql -u root -p < sql/create_tables.sql
mysql -u root -p -e "USE gareeb_sql; SHOW TABLES;"
```
![Create Tables](screenshots/01_create_tables.png)

## 2. Insert Data (`02_insert_data.sql`)
**Run:**
```powershell
mysql -u root -p < sql/02_insert_data.sql
mysql -u root -p -e "USE gareeb_sql; SELECT * FROM customers; SELECT * FROM accounts;"
```
![Insert Data](screenshots/02_insert_data.png)

## 3. Core & Analytical Queries (`03_project_queries.sql`)
**Run:**
```powershell
mysql -u root -p -t < sql/03_project_queries.sql
```
<table>
  <tr>
    <td align="center">
      <img src="screenshots/03_project_queries_1.png" width="100%" alt="Core Queries Screenshot 1">
    </td>
    <td align="center">
      <img src="screenshots/03_project_queries_2.png" width="100%" alt="Core Queries Screenshot 2">
    </td>
  </tr>
</table>

## 4. Views and Security (`04_views_and_security.sql`)
**Run:**
```powershell
mysql -u root -p -t < sql/04_views_and_security.sql
```
![Views and Security](screenshots/04_views_and_security.png)