# Makai-specific: Create Resources Utils

NOTE: I didn't run these scripts, I performed these steps manually.

Utilities to easily create resources, permissions amd credentials on Fly.io, AWS and Postgres.

All scripts here do not require parameters and guide you through the process of creating the resources.

## Requirements

These dependencies must be present on the system 

- jq
- aws-cli version 2
- aws (authenticated with buckets and IAM management permissions)
- flyctl (authenticated)

## Create AWS resources

`./create-aws-resources.sh`

1. Creates and configure bucket for the backups.
2. Creates a IAM user with write permissions for the backup bucket.

Output:

```
AWS_ACCESS_KEY_ID=aws_access_key_id
AWS_SECRET_ACCESS_KEY=aws_secret_access_key

BACKUP_CONFIGURATION_NAMES=STAGING,PRODUCTION
STAGING_S3_DESTINATION=s3://example-bucket/project-name-db-backup-staging.tar.gz
PRODUCTION_S3_DESTINATION=s3://example-bucket/project-name-db-backup-production.tar.gz
```

Makai - Dev Example:
```
AWS_ACCESS_KEY_ID=aws_access_key_id
AWS_SECRET_ACCESS_KEY=aws_secret_access_key
S3_DESTINATION=s3://rowboat-db-backups-dev/rowboat_dev
```

## Create database user and grant permissions

`./grant-db-permissions.sh`

1. Creates backup-worker-user
2. Grant permissions to the backup-worker-user in all schemas for all tables and sequences

Output:

```
[ENV]_DATABASE_URL=postgres://username:password@top2.nearest.of.example-db.internal:5432/database_name
```

Makai - Manual setup:
```
CREATE USER db_backup_worker WITH PASSWORD 'secure_password' LOGIN IN ROLE pg_read_all_data;

-- Combines:
CREATE USER db_backup_worker WITH PASSWORD 'secure_password';
ALTER ROLE db_backup_worker WITH LOGIN;
GRANT pg_read_all_data TO db_backup_worker;
```

## Create Fly.io backup worker

Only used in the **Method 2**, where a backup work app is needed.
If you are using the simple method backing up directly from GitHub, skip this step.

`./create-fly-backup-worker.sh`

or, manually

```
# Makai Dev example
fly apps create --machines --name db-backup-worker --org fathom-information-design-dev
```

1. Creates database backup worker app on fly.io
2. Creates volume for worker app

After, you need will to import the secrets to the worker app and deploy it using:

```
fly -a db-backup-worker secrets import < .env
fly -a db-backup-worker deploy --remote-only
```

Makai - Dev Example (from this directory):
```
fly apps create --machines --name "db-backup-worker" --org "fathom-information-design-dev"

# env vars (set as secrets?)
AWS_ACCESS_KEY_ID=aws_access_key_id
AWS_SECRET_ACCESS_KEY=aws_secret_access_key
S3_DESTINATION=s3://rowboat-db-backups-dev/rowboat_dev
DATABASE_URL=postgres://db_backup_worker:password@rowboat-db-dev.flycast:5432/rowboat_dev?sslmode=disable
```
