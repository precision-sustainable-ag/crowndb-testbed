FROM postgres:10

ENV POSTGRES_USER postgres
ENV POSTGRES_PASSWORD <insert a password>
ENV POSTGRES_DB shadowdb

COPY globals_shadow.sql /docker-entrypoint-initdb.d/
COPY snapshot_shadow.sql /docker-entrypoint-initdb.d/

