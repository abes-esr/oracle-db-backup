#!/bin/bash
# script to remove the old backup file 
# example, remove 7 days older files

ORACLE_DB_CLEANUP_DATE_LIMIT=$(date -d "$ORACLE_DB_BACKUP_CLEANUP_TIME days ago" +%Y-%m-%d)
touch --date "$ORACLE_DB_CLEANUP_DATE_LIMIT" /tmp/oracle-db-cleanup-ref
FILES_TO_RM=$(find /backup/ -not -newer /tmp/oracle-db-cleanup-ref -type f)
if [ "$FILES_TO_RM" == "" ]; then
    echo "-> No backup files to remove older than $ORACLE_DB_BACKUP_CLEANUP_TIME days, here is the (not to cleanup yet) files:"
    find /backup/ -type f
else
    NB_TO_DELETE=$(find /backup/ -not -newer /tmp/oracle-db-cleanup-ref -type f | wc -l)
    echo "-> Following backup files are going to be deleted ($NB_TO_DELETE files will be deleted because older than $ORACLE_DB_BACKUP_CLEANUP_TIME days):"
    # show what will be deleted
    find /backup/ -not -newer /tmp/oracle-db-cleanup-ref -type f
    # really delete it
    find /backup/ -not -newer /tmp/oracle-db-cleanup-ref -type f -exec rm -f {} \;
    echo "-> Cleanup backup finished: $NB_TO_DELETE files were deleted"
fi 


