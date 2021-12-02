#!/bin/sh

POSTGRES_11_PATH="<insert path to postgres 11>"
POSTGRES_USERNAME="<insert postgres username>"
POSTGRES_PASSWORD="<insert postgres password>"
SHADOW_CON_STRING="host=postgres-dbs.postgres.database.azure.com port=5432 dbname=shadowdb user=$POSTGRES_USERNAME password=$POSTGRES_PASSWORD sslmode=require"
PROD_CON_STRING="host=postgres-dbs.postgres.database.azure.com port=5432 dbname=crowndb user=$POSTGRES_USERNAME password=$POSTGRES_PASSWORD sslmode=require"
CROWN_TESTBED_PATH="<insert path to where you cloned this repo>"

# printenv
cd $POSTGRES_11_PATH
# ls
sudo ./pg_dump.exe --dbname=$PROD_CON_STRING --file="$CROWN_TESTBED_PATH/crown_testbed/snapshot_crown.sql"
sudo ./pg_dumpall.exe --dbname=$PROD_CON_STRING --globals-only --file="$CROWN_TESTBED_PATH/crown_testbed/globals_crown.sql"

# ls
sudo ./pg_dump.exe --dbname=$SHADOW_CON_STRING --file="$CROWN_TESTBED_PATH/shadow_testbed/snapshot_shadow.sql"
sudo ./pg_dumpall.exe --dbname=$SHADOW_CON_STRING --globals-only --file="$CROWN_TESTBED_PATH/shadow_testbed/globals_shadow.sql"

rm "$CROWN_TESTBED_PATH/crown_tesbed/snapshot_crown.sql"
sudo mv "$CROWN_TESTBED_PATH/shadow_testbed/snapshot_shadow.sql" "$CROWN_TESTBED_PATH/crown_tesbed"
rm "$CROWN_TESTBED_PATH/crown_tesbed/globals_crown.sql"
sudo mv "$CROWN_TESTBED_PATH/crown_testbed/globals_crown.sql" "$CROWN_TESTBED_PATH/crown_tesbed"

rm "$CROWN_TESTBED_PATH/shadow_testbed/snapshot_shadow.sql"
sudo mv "$CROWN_TESTBED_PATH/shadow_testbed/snapshot_shadow.sql" "$CROWN_TESTBED_PATH/shadow_testbed"
rm "$CROWN_TESTBED_PATH/shadow_testbed/globals_shadow.sql"
sudo mv "$CROWN_TESTBED_PATH/shadow_testbed/globals_shadow.sql" "$CROWN_TESTBED_PATH/shadow_testbed"

date=$(date)+'%m/%d/%Y'

echo date

service docker start

docker stop shadow_testbed
docker rm shadow_testbed
docker stop crown_testbed
docker rm crown_testbed
# docker system prune

cd "$CROWN_TESTBED_PATH/crown_tesbed"
docker build -t psadbimgs.azurecr.us/crowndb-snapshot:$date .
docker run --name crown_testbed -d -p 1111:5432  psadbimgs.azurecr.us/crowndb-snapshot:$date

cd "$CROWN_TESTBED_PATH/shadow_testbed"
docker build -t psadbimgs.azurecr.us/shadowdb-snapshot:$date .
docker run --name shadow_testbed -d -p 2222:5432  psadbimgs.azurecr.us/shadowdb-snapshot:$date
