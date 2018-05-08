#!/usr/bin/env bash
PGPASSWORD=password psql -h localhost -p 5432 -U postgres $@
