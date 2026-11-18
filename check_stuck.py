import sqlite3, sys
db = r"C:\Users\jedey\Documents\villahermosa_inventory.db"
con = sqlite3.connect(db)
for t, cols in [("products","id, name, sync_status"),
                ("stock_movements","id, reason, reference_id, sync_status"),
                ("payments","id, payment_id, order_code, sync_status")]:
    rows = con.execute(f"select {cols} from {t} where sync_status='error'").fetchall()
    print(f"\n== {t}: {len(rows)} stuck ==")
    for r in rows:
        print(" ", r)
if "--reset" in sys.argv:
    for t in ("products","stock_movements","payments"):
        n = con.execute(f"update {t} set sync_status='pending' where sync_status='error'").rowcount
        print(f"reset {n} rows in {t}")
    con.commit()
con.close()