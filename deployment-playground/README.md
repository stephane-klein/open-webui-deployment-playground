# Open WebUI local deployment playground

This folder contains a local deployment playground for [Open WebUI](https://github.com/open-webui/open-webui) connected to [Scaleway Generative APIs](https://www.scaleway.com/fr/generative-apis/), based on `docker-compose.yml` method.

Although this is not necessary for a minimalist deployment, I chose here to configure the following options:

- connect *Open WebUI* to a *PostgreSQL* database instead of *SQLite* ([resource about this](https://docs.openwebui.com/getting-started/env-configuration/#database-pool))
- connect *Open WebUI* to a *Minio* instance instead of local file system storage ([resource about this](https://docs.openwebui.com/tutorials/s3-storage/))
- connect *Open WebUI* to a *Redis* instance ([resource about this](https://docs.openwebui.com/tutorials/integrations/redis/))

I made these choices because [I want to later deploy *Open WebUI* on a Kubernetes cluster](https://notes.sklein.xyz/Projet%2029/).

## Préparation

Install [Mise](https://mise.jdx.dev/)

```sh
$ cp .secret.skel .secret
```

Then fill in the `.secret` file with a [Scaleway](https://scaleway.com) API Key that has access permission to the [Scaleway Generative APIs](https://www.scaleway.com/fr/generative-apis/) service.


## Getting started

```sh
$ mise install
```

If needed, you can force the environment variables loading with this command:

```sh
$ source .envrc
```

```sh
$ ./scripts/create-minio-bucket.sh
$ docker compose up -d --wait
$ ./scripts/create-admin-user.sh
```

Open your browser on http://localhost:3000 (admin email: `admin@example.com`, password: `password`)

## Helper scripts

Helper script to directly enter into the PostgreSQL database:

```sh
$ ./sripts/enter-in-pg.sh
postgres=# \dt
              List of relations
 Schema |       Name       | Type  |  Owner
--------+------------------+-------+----------
 public | alembic_version  | table | postgres
 public | auth             | table | postgres
 public | channel          | table | postgres
 public | channel_member   | table | postgres
 public | chat             | table | postgres

...

 public | prompt           | table | postgres
 public | tag              | table | postgres
 public | tool             | table | postgres
 public | user             | table | postgres
(23 rows)

postgres=#
```

Helper script to explore Minio Object Storage:

```sh
$ ./scripts/aws-s3-local-minio.sh s3 ls openwebui --recursive
2025-04-26 12:36:39        682 openwebui/2b12371e-44b0-402e-985f-4cb736c12396_README.md
2025-04-26 12:38:04       2386 openwebui/6a86139c-83f9-4521-a99a-264ac260e11f_README.md
```

Helper script to explore Redis data:

```sh
$ ./scripts/enter-in-redis.sh
127.0.0.1:6379[1]> keys *
1) "open-webui:session_pool"
2) "open-webui:user_pool"
3) "usage_cleanup_lock"
```

## Teardown

```sh
$ docker compose down -v
```
