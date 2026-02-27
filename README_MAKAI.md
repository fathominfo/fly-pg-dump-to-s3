# Makai-specific: Fly pg_dump to AWS S3
- We're using the 2nd option (from the [README.md](./README.md))
  - This is a backup via a worker machine that is spun up on Fly
  - It is triggered by a GitHub worker that starts the machine
  - We're NOT using option 1, which handles the entire backup via GitHub worker on GitHub servers.
- This is a fork of [github.com/significa/fly-pg-dump-to-s3](https://github.com/significa/fly-pg-dump-to-s3) (tag: 3)
  - Forked so we have control of the code
  - Specifically security, but also so we can adjust the S3 key naming

## Setup (modified from Method 2: Worker Instantiation, [README.md](./README.md))

Create your resources, credentials and permissions following the
[create resources utils documentation](./create-resources-utils).
- See: [README_MAKAI.md](./create-resources-utils/README_MAKAI.md)

### Method 2: Worker installation

1. Launch your database backup worker with `fly apps create`

2. Set the required fly secrets (env vars). Example:

   ```env
   AWS_ACCESS_KEY_ID=XXXX
   AWS_SECRET_ACCESS_KEY=XXXX
   DATABASE_URL=postgresql://username:password@my-fly-db-instance.internal:5432/my_database
   S3_DESTINATION=s3://your-s3-bucket/backup_name_no_ext

   # DEV Example S3_DESTINATION (note we leave off the file extension)
   S3_DESTINATION=s3://rowboat-db-backups-dev/rowboat_dev
   ```

3. Automate the Call the reusable GitHub Actions workflow found in
   `.github/workflows/trigger-backup.yaml`. Example workflow definition:

   ```yaml
   name: Backup databases
   on:
     workflow_dispatch:
     schedule:
       # Runs Every day at 5:00am UTC
       - cron: "00 5 * * *"

   jobs:
     backup-databases:
       name: Backup databases
       uses: significa/fly-pg-dump-to-s3/.github/workflows/trigger-backup.yaml@v3
       with:
         fly-app: my-db-backup-worker
         volume-size: 3
         machine-size: shared-cpu-4x
         region: ewr
       secrets:
         FLY_API_TOKEN: ${{ secrets.FLY_API_TOKEN }}
   ```
   
You can also trigger a manual backup without GitHub actions with `./trigger-backup.sh`:

   - `FLY_APP`: (Required) Your fly application.
   - `FLY_API_TOKEN`: (Required) Fly token (PAT or Deploy token).
   - `FLY_REGION`: the region of the volume and consequently the region where the worker will run.
     Choose one close to the db and the AWS bucket region. Defaults to `cdg`.
   - `FLY_MACHINE_SIZE`: the fly machine size, list available in
     [Fly's pricing page](https://fly.io/docs/about/pricing/#machines). Defaults to `shared-cpu-4x`
   - `FLY_VOLUME_SIZE`: the size of the temporary disk where the ephemeral files live during the
     backup, set it accordingly to the size of the db. Defaults to `3`.
   - `DOCKER_IMAGE`:
     Option to override the default docker image `ghcr.io/mudphone/fly-pg-dump-to-s3:makai_v1`
   - `ERROR_ON_DANGLING_VOLUMES`: After the backup completes, checks if there are any volumes still
     available, and crashes if so. This might be useful to alert that there are dangling volumes
     (that you might want to be paying for). Defaults to `true`.
   - `DELETE_ALL_VOLUMES`: True to delete all volumes in the backup worker instead of the one used
      in the machine. Fly has been very inconsistent with what volume does the machine start.
      This solves the problem but prevents having multiple backup workers running in the same app.
      Default to `true`.

## Environment variables reference (backup worker)

- `DATABASE_URL`: Postgres database URL.
  For example: `postgresql://username:password@test:5432/my_database`
- `S3_DESTINATION`: AWS S3 fill file destination Postgres database URL.
- `BACKUP_CONFIGURATION_NAMES`: Optional: Configuration names/prefixes for `DATABASE_URL` and
  `S3_DESTINATION`.
- `BACKUPS_TEMP_DIR`: Optional: Where the temp files should go. Defaults to: `/tmp/db-backups`
- `THREAD_COUNT`: Optional: The number of threads to use for backup and compression.
  Defaults to `4`.
- `PG_DUMP_ARGS`: Optional: Override the default `pg_dump` args:
  `--no-owner --clean --no-privileges --jobs=4 --format=directory --compress=0`.
  The `--jobs` parameter defaults to `$THREAD_COUNT`.
- `COMPRESSION_THREAD_COUNT`: Optional: The number of threads to use for compression.
  Defaults to `$THREAD_COUNT`.