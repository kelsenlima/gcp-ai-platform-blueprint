# Runbook: restore the database from a backup

Backups are automatic and daily, 7 copies kept, no point-in-time recovery: you can only go back
to the moment of a backup.

```bash
P=<prefix>-stage; R=<region>; I=ai-pg-stage
gcloud sql backups list --filter=instance:$I --project=$P --format="table(id,name,backupInterval.startTime,state)"
```

| | **A. Restore to a new instance** | **B. Restore over the existing instance** |
|---|---|---|
| What happens | A new instance with the backup data; the original stays as is | **All current data is deleted** and replaced by the backup |
| Downtime | None | The database is down for the whole restore |
| Use it to | Test backups (semiannual review); recover a few rows or tables; inspect an old state | The whole database is lost or corrupted |
| Data loss | None | Everything written after the backup |

## A. Restore to a new instance

```bash
TMP=tmp-restore-<yyyymmdd>
BKP=<backup name from the list above>

# 1. Restore to a NEW instance, as small as possible, private IP only
gcloud sql backups restore $BKP --restore-instance=$TMP --project=$P \
  --tier=db-f1-micro --edition=enterprise --region=$R \
  --network=projects/$P/global/networks/ai-vpc --no-assign-ip \
  --storage-size=10 --storage-type=SSD --availability-type=zonal \
  --no-backup --no-deletion-protection --no-final-backup

# 2. Temporary instance only: IAM login and the Data API, to query without network access
gcloud sql instances patch $TMP --project=$P \
  --database-flags=cloudsql.iam_authentication=on --data-api-access=ALLOW_DATA_API
gcloud sql users create <your-email> --instance=$TMP --project=$P --type=cloud_iam_user

# 3. Inspect the copy
gcloud sql databases list --instance=$TMP --project=$P
gcloud sql instances execute-sql $TMP --project=$P --database=app --sql="
  SELECT n.nspname AS schema, count(c.oid) AS tables
  FROM pg_namespace n LEFT JOIN pg_class c ON c.relnamespace = n.oid AND c.relkind = 'r'
  WHERE n.nspname NOT LIKE 'pg_%' AND n.nspname <> 'information_schema'
  GROUP BY 1 ORDER BY 1;"

# 4. Delete the temporary instance, with a guard: only names starting with tmp-.
#    The copy inherits the source's deletion protection, hence the patch before delete.
case "$TMP" in
  tmp-*) gcloud sql instances patch "$TMP" --project=$P --no-deletion-protection --quiet
         gcloud sql instances delete "$TMP" --project=$P --quiet ;;
  *) echo "REFUSED: '$TMP' does not start with tmp-; nothing deleted." ;;
esac
```

- **Always name it `tmp-...`**: the guard in step 4 depends on it. A deleted instance name stays
  reserved for about a week.
- **Data API** lets you query a private-IP-only instance through the Google API, always with
  IAM login. Enable it only on the temporary instance, only while it exists.
- **To recover data**, export what you need (`execute-sql` or Console → Export) and write it back
  through the app or an admin. Apps keep pointing to the original instance.
- The temporary instance is outside Terraform and does not show up in plans.

## B. Restore over the existing instance

Only when the database is lost and the decision to go back to the last backup is recorded.

1. Announce the downtime.
2. Take an on-demand backup of the current state:
   `gcloud sql backups create --instance=$I --project=$P --description="before restore"`.
3. Restore (the gcloud command asks for confirmation; do not use `--quiet`):
   `gcloud sql backups restore <ID> --restore-instance=$I --backup-instance=$I --project=$P`.
4. Wait for `RUNNABLE`: `gcloud sql instances describe $I --project=$P --format="value(state)"`.
5. **App user password**: users live inside the data, so the backup brings back the password
   valid on that day. Because the password is write-only, the plan does not see the
   difference: increment `sql_password_version` and follow
   [rotate-db-password.md](rotate-db-password.md).
6. Force a new revision of every service that uses the database and test `/api/check/db`.
7. `terraform plan` in the environment: no changes expected.
