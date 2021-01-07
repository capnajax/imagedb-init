#!/bin/bash

PGPASSWORD=$(cat /mnt/creds/pgpassword)

echo imagedb:5432:postgres:postgres:${PGPASSWORD} > ~/.pgpass
echo imagedb:5432:imagedb:postgres:${PGPASSWORD} >> ~/.pgpass
chmod 0600 ~/.pgpass

psql -h imagedb -p 5432 -d imagedb -U postgres -w -l 2&> /dev/null
if [ $? != 0 ]; then
  echo CREATING DATABASE
  createdb -h imagedb -p 5432 -U postgres -w imagedb
fi

set -e

#for f in sql/*.sql ; do psql --host=imagedb --port=5432 -U postgres -f $f -w; done
for f in sql/*.sql ; do psql postgresql://imagedb:${PGPASSWORD}@imagedb:5432/imagedb -f $f -w; done
