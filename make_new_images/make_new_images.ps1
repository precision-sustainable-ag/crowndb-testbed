$POSTGRES_11_PATH = "<path to postgres 11>\bin"
$SHADOW_CON_STRING = "host=postgres-dbs.postgres.database.azure.com port=5432 dbname=shadowdb user=<insert your username> password=<insert your password> sslmode=require"
$PROD_CON_STRING = "host=postgres-dbs.postgres.database.azure.com port=5432 dbname=crowndb user=<insert your username> password=<insert your password> sslmode=require"
$CROWN_TESTBED_PATH = "<path to where you cloned this repo>"

# printenv
Set-Location $POSTGRES_11_PATH
# ls
./pg_dump.exe --dbname=$PROD_CON_STRING --file=snapshot_crown.sql
./pg_dumpall.exe --dbname=$PROD_CON_STRING --globals-only --file=globals_crown.sql
# Set-Location $POSTGRES_11_PATH
# ls
./pg_dump.exe --dbname=$SHADOW_CON_STRING --file=snapshot_shadow.sql
./pg_dumpall.exe --dbname=$SHADOW_CON_STRING --globals-only --file=globals_shadow.sql

Remove-Item "${CROWN_TESTBED_PATH}/crown_testbed/snapshot_crown.sql"
Copy-Item "${POSTGRES_11_PATH}/snapshot_crown.sql" "${CROWN_TESTBED_PATH}/crown_testbed"
Remove-Item "${CROWN_TESTBED_PATH}/crown_testbed/globals_crown.sql"
Copy-Item "${POSTGRES_11_PATH}/globals_crown.sql" "${CROWN_TESTBED_PATH}/crown_testbed"
Remove-Item "${CROWN_TESTBED_PATH}/shadow_testbed/snapshot_shadow.sql"
Copy-Item "${POSTGRES_11_PATH}/snapshot_shadow.sql" "${CROWN_TESTBED_PATH}/shadow_testbed"
Remove-Item "${CROWN_TESTBED_PATH}/shadow_testbed/globals_shadow.sql"
Copy-Item "${POSTGRES_11_PATH}/globals_shadow.sql" "${CROWN_TESTBED_PATH}/shadow_testbed"

$date = Get-Date -UFormat '%m.%d.%Y'

# echo date

# service docker start

docker stop shadow_testbed
docker rm shadow_testbed
docker stop crown_testbed
docker rm crown_testbed
docker system prune

Set-Location "$CROWN_TESTBED_PATH/crown_testbed"
docker build -t psadbimgs.azurecr.us/crowndb-snapshot:$date .
docker run --name crown_testbed -d -p 1111:5432  psadbimgs.azurecr.us/crowndb-snapshot:$date

Set-Location "$CROWN_TESTBED_PATH/shadow_testbed"
docker build -t psadbimgs.azurecr.us/shadowdb-snapshot:$date .
docker run --name shadow_testbed -d -p 2222:5432  psadbimgs.azurecr.us/shadowdb-snapshot:$date
