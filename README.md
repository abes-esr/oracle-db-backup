# oracle-db-backup

[![Docker Pulls](https://img.shields.io/docker/pulls/abesesr/oracle-db-backup.svg)](https://hub.docker.com/r/abesesr/oracle-db-backup/)
[![oracle-db-backup ci](https://github.com/abes-esr/oracle-db-backup/actions/workflows/build-test-pubtodockerhub.yml/badge.svg)](https://github.com/abes-esr/oracle-db-backup/actions/workflows/build-test-pubtodockerhub.yml)

Scripts used to periodically backup an oracle database schema thanks to the `expdb` oracle command (packaged in a docker 🐳 image).

## How it works

It will periodically run `expdb` to backup an oracle database since the container is alive. A cleanup script will remove old backup files.

## Usage

Here is a basic usecase:
- you have an oracle database running is a container, its name is `my-oracle-database` and it contains a `MYAPPLI` schema
- you want to backup each nights all the `MYAPPLI` oracle schema in a local folder on the host server: `/opt/my-backups/`

You will have to run your oracle database this way (volume is important):
```yaml
  my-oracle-database:
    image: container-registry.oracle.com/database/free:23.2.0.0
    container_name: my-oracle-database
    restart: unless-stopped
    environment:
      ORACLE_PWD: "oracle sys pwd ****secret****"
    volumes:
      # Warning: this line MUST be the same as in my-oracle-database-dumper container
      - /opt/my-backups/:/backup/
```

And you will have to run (in the same `docker-compose.yml` for example), the backup container this way:
```yaml
  my-oracle-database-dumper:
    image: abesesr/oracle-db-backup:free-23.2.0.3
    container_name: my-oracle-database-dumper
    restart: unless-stopped
    environment:
      ORACLE_DB_DUMPER_HOST: "my-oracle-database"
      ORACLE_DB_DUMPER_PORT: 1521
      ORACLE_DB_DUMPER_ORACLE_PWD: "oracle sys pwd ****secret****"
      ORACLE_DB_DUMPER_ORACLE_SCHEMA_TO_BACKUP: "MYAPPLI"
      ORACLE_DB_DUMPER_DUMPNAME_PATTERN: "myappli-db-$(date +'%Y-%m-%d')"
      ORACLE_DB_BACKUP_CLEANUP_TIME: "7"
      ORACLE_DB_BACKUP_CRON: "20 3 * * *"
      ORACLE_DB_BACKUP_AT_STARTUP: "1"
    volumes:
      # Warning: this line MUST be the same as in my-oracle-database container
      - /opt/my-backups/:/backup/
```

With a such configuration, `/opt/my-backups/` on the hosting server will have everydays at 3h20 a new fresh backup of the `MYAPPLI` oracle schema. Two files will be genrated each days, for example: ``myappli-db-2023-09-06.dmp`` and ``myappli-db-2023-09-06.log``. Older files than 7 days will be automaticaly removed.


To manually force a backup, you can use this command:
```bash
docker exec -it my-oracle-database /scripts/oracle-db-backup.sh
```

## Configuration

These parameters are environements variables you can give when creating the container:
- `ORACLE_DB_DUMPER_HOST`: hostname or ip where oracle database server is located
- `ORACLE_DB_DUMPER_PORT`: listening port of the oracle database (`1521` is default)
- `ORACLE_DB_DUMPER_ORACLE_PWD`: password of "system" or "sys" oracle database user (the admin)
- `ORACLE_DB_DUMPER_ORACLE_SCHEMA_TO_BACKUP`: name of the oracle schema to backup
- `ORACLE_DB_DUMPER_DUMPNAME_PATTERN`: name of the backup filename, it can be a pattern (`"db-$(date +'%Y-%m-%d')"` by default)
- `ORACLE_DB_BACKUP_CLEANUP_TIME`: number of days of backup files to keep (`"7"` by default - means 7 days)
- `ORACLE_DB_BACKUP_CRON`: crontab config when backup should be done (`"50 4 * * *"` by default)
- `ORACLE_DB_BACKUP_AT_STARTUP`: "1" or "0" to backup or not backup when this container starts (`"1"` by default)

You also have to share the `/backup/` folder with the container where your oracle database is running because when running `expdp` command it is the oracle database that will write the backup files! See "usage" section for an example.


## Developements

This image is based on the free oracle image.  
See https://container-registry.oracle.com/ -> Database -> free 

If you want to create a new version, use the `create-release.yml` github action and choose a version number starting by oracle database image version.
For example: ``free-23.2.0.0``

And just increase the last number so that it's easy to know what is the used base image.
For example a next version would be: ``free-23.2.0.1``
