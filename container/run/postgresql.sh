podman run -itd --name postgres-demo -p 5432:5432 -e POSTGRES_PASSWORD=postgres -v /home/alpha/source/db/postgres/data:/var/lib/postgresql/data postgres
