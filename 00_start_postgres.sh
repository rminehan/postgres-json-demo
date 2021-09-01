#!/bin/bash

# Starts an instance of a postgres db for Zij and Rohan's postgres json talk
# Uses port 6677
# Currently we're pinning this script to postgres 11.8-alpine to keep things reproducible.

# Usage
#  ./00_start_postgres.sh

docker run \
  --rm \
  --name postgres-json-demo \
  -e POSTGRES_PASSWORD=boban_jones \
  -p 6677:5432 \
  -v $PWD/postgres-docker-volume:/var/lib/postgresql/data \
  --shm-size=2g \
  -d \
  postgres:11.8-alpine
