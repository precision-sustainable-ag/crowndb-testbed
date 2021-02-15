# Snapshot service for `crowndb`

> **TL;DR: If you're just looking for which commands to run and you're already set up, you want steps 2-4 in [Section: Use locally](#use-locally).**

This repository contains the documentation and makefiles for creating snapshots of the `crowndb` PostgreSQL database in Docker. 

The purpose of this service is to be a test environment. That is, to be able to run code that writes to the DB (`INSERT` / `UPDATE` / `ALTER` / `DELETE`), see the results, and edit your code before running it on the production environment.

You do not need to build a fresh image to use this service; snapshots at various timepoints exist in our private Azure Container Registry: `psadbimgs.azurecr.us`.

### Installation prerequisites
This service has been tested on Docker running on MacOS ~~and an Ubuntu VM running in Azure~~. 

 - To build an image, you need: 
   - `libpq` or another Postgres client installed ([here](https://www.postgresql.org/download/) or via `homebrew`)
   - `docker` ([here](https://docs.docker.com/get-docker/) or via `homebrew`)
   - `azure-cli` ([Docs: Install the Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli))
 - For deploying a snapshot locally, you only need to have `docker` and `azure-cli` installed.
 - For using in the cloud, you only need to be able to SSH into a VM.

### Environment prerequisites
Before any of the steps below, make sure you log in to your Azure account from the command line. If you've never done this before, you need to activate the federal cloud instead of the standard consumer one:

    az cloud set --name AzureUSGovernment

Then you can log in:

    az login

Finally connect your Azure account to our container registry:

    az acr login --name psadbimgs

> Note: If this step doesn't work, let Brian know (or another PSA Azure admin). Also you will have to repeat this line before pulling a new image every time ([Docs: Individual login with Azure AD](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-authentication#individual-login-with-azure-ad)).

---

## Build a snapshot

To build an image, you need to have `docker` installed on your local machine. 

1. Clone this repository so that you have the `Dockerfile-example` used for building.

2. Edit the `ENV` lines in the example dockerfile to be a new password, then save that copy as `Dockerfile`. You shouldn't need this password again (but you do have to provide one); it's the admin user for the whole PostgreSQL install on your new image. The usernames and passwords for the original DB will migrate over in a later step.

3. Fetch a new snapshot to build an image from. To do this, you need to get the `conninfo` string of the database. It looks like this: 
    
       "host=crown***.postgres.database.***.net port=5432 dbname=crowndb user=***@domain password=*** sslmode=require"
   > Note: this is the same string that you use to open the DB from the command line: `psql "CONNINFO_STRING"`. Don't forget to include the quotes in the command.

   The command you run to take your snapshot depends on what you want it to include. In any case, you want to execute it from a shell in the folder of this repository. For the "light" version (~a few MB, excludes sensor and weather data), use:

       pg_dump --dbname="CONNINFO_STRING" --exclude-table=ambient_sensor_data --exclude-table=rainfall --exclude-table='water_*_data' --exclude-table=wsensor_data_ignore --exclude-table=ssurgo --exclude-table=weather --file=snapshot.sql

    The full snapshot (much larger) can be pulled by not excluding those tables:

       pg_dump --dbname="CONNINFO_STRING" --file=snapshot.sql

    An in-between size includes sensor data but not weather:

       pg_dump --dbname="CONNINFO_STRING" --exclude-table=rainfall --exclude-table=ssurgo --exclude-table=weather --file=snapshot.sql

4. Now that you have an image, you should check that the correct filename is in the `COPY` statement of the dockerfile. If you didn't change it in the commands in Step 2, they should match. The `snapshot.sql` file should be in the same folder as `Dockerfile`.

5. In addition to the schema and data stored in the actual DB, you need a file that makes the users and their permissions to access. Run this command:

       pg_dumpall --dbname="CONNINFO_STRING" --globals-only --file=globals.sql

   This file won't change from snapshot to snapshot unless users are changed. Make sure you use the same filename as the `COPY` statement in the dockerfile, just like above.

6. Now you can build an image from these SQL statements and the Dockerfile. Run this command from this folder:

       docker build -t psadbimgs.azurecr.us/crowndb-snapshot:2021.02.01 .
       
    > Note the period at the end of the command! That's the path to the current folder. Also make sure to update the version tag with the date of your snapshot, in the `YYYY.MM.DD` format.

7. You can now run your image locally (see below). You should also upload it to our container registry.

       docker push psadbimgs.azurecr.us/crowndb-snapshot:2021.02.01

    > Remember to update the version tag with the date of your snapshot, in the `YYYY.MM.DD` format.

---

## Use locally

1. Pull an image from the repo, assuming you're already logged in to Azure via the command line:

       docker pull psadbimgs.azurecr.us/crowndb-snapshot:2021.02.01

2. You can now see this in your local Docker desktop client dashboard, but I don't recommend starting it using the GUI. Instead, you should use the command line so that you can make sure to forward ports correctly.

       docker run --name A_MEMORABLE_NAME -d -p 2345:5432 psadbimgs.azurecr.us/crowndb-snapshot:2021.02.01

    > NOTE: You are mapping your local port `2345` to the container's `5432`. Also make sure to assign a short memorable name in `"snake_case"` or `"kebab-case"`, because you'll use it later (can be something simple like `test` or `my_testbed`).

    > Warning: The `-d` flag is "detached mode", which means it won't spawn a new terminal window, and you can only see the container through the port or with `docker ps` or the desktop dashboard. If you need to touch the command line inside the container that's running the DB (***you shouldn't!***) you can SSH in or use the desktop client to spawn one.

3. Now you can use your usual methods of connecting to the DB and sending SQL statements, whether from an environment like `node.js`, or a GUI like DBeaver, or the command line via `psql`. You need to replace the remote host in the production `conninfo` string with `localhost`, the port with `2345`, remove the `@domain` part of the username, and turn off the SSL requirement:

       "host=localhost port=2345 dbname=crowndb user=*** password=***"

4. Once you have run a set of statements that constitute a test, you can now rewind to the untouched snapshot of the DB by stopping and removing the container:

       docker stop A_MEMORABLE_NAME
       docker rm A_MEMORABLE_NAME

5. To run more tests, you can now **repeat steps 2-4**, even reusing the memorable container name you gave, since now the old one is gone. If you don't remember to stop and delete the container before trying to make a new one, you'll receive an error about port 2345 already being mapped and it will fail.


# Using remotely

This section is a work in progress, where we will provision a VM to be preloaded with Docker and images that you can just start and stop, but you'll replace `localhost` with an IP.