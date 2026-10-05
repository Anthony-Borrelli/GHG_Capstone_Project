# Loading the raw data

All raw tables are created by `sql/01_create_raw_tables.sql`, with every column as TEXT.
The CSVs are then loaded without changes, in one of two ways.

## 1. Standard files (DBeaver import wizard)

For every file in `data/raw_2025/` except the EnergyHub export:

1. Right-click the matching `raw_` table, then choose Import Data > CSV.
2. Select the file.
3. On the mapping screen, confirm every column shows "existing".
4. Check the row count with `SELECT COUNT(*) FROM raw_<table>;`

## 2. EnergyHub export (sqlite3 command-line tool)

`energyhub_consumption_export.csv` has 4 report lines above its header, and the
DBeaver wizard can't skip them. It's loaded with the sqlite3 command-line tool
(sqlite-tools, from sqlite.org) instead.

1. Close DBeaver.
2. Open a terminal in the repo folder.
3. Start sqlite3 with the database:

```
   sqlite3 db/ghg_capstone_project.db
```
If lost, you need to 'copy as path' sqlite3.exe and 'copy as path' ghg_capstone_project.db's locations. Include '&' and a space between the two paths, both paths in quotations as copied. These paths will be specific to your situation.

```
    & "sqlite3.exe_path" "ghg_capstone_project.db_path"
```

4. At the `sqlite>` prompt:

```
   DELETE FROM raw_energyhub_consumption_export;
   .import --csv --skip 5 data/raw_2025/utilities/energyhub_consumption_export.csv raw_energyhub_consumption_export
   SELECT COUNT(*) FROM raw_energyhub_consumption_export;
   .quit
```

   `--skip 5` skips the 4 report lines plus the header row. The table already has the column names.

## Expected row counts

| Table | Rows |
| --- | --- |
| raw_energyhub_consumption_export | 94 |
| ... | ... |