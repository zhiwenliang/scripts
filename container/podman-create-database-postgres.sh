#!/usr/bin/bash

podman run -d --name postgres-alpha -p 5432:5432 -e POSTGRES_PASSWORD=postgres -v /home/alpha/sdk/database/postgres-alpha/data:/var/lib/postgresql -v /home/alpha/sdk/database/postgres-alpha/conf:/etc/postgresql postgres:14
