FROM postgres:10

ENV POSTGRES_USER postgres
ENV POSTGRES_PASSWORD <insert a password>
ENV POSTGRES_DB crowndb

COPY globals_crown.sql /docker-entrypoint-initdb.d/
COPY snapshot_crown.sql /docker-entrypoint-initdb.d/

