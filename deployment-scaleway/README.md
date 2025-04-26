# Open WebUI deployment playground on Scaleway instance

This folder contains a deployment script to deploy [Scaleway Virtual Instances](https://www.scaleway.com/en/virtual-instances/) running [Open WebUI](https://github.com/open-webui/open-webui) connected to [Scaleway Generative APIs](https://www.scaleway.com/fr/generative-apis/), based on `docker-compose.yml` method.

Although this is not necessary for a minimalist deployment, I chose here to configure the following options:

- connect *Open WebUI* to a *PostgreSQL* database instead of *SQLite* ([resource about this](https://docs.openwebui.com/getting-started/env-configuration/#database-pool))
- connect *Open WebUI* to a [Scaleway Object Storage](https://www.scaleway.com/en/object-storage/) instead of local file system storage ([resource about this](https://docs.openwebui.com/tutorials/s3-storage/))
- connect *Open WebUI* to a *Redis* instance ([resource about this](https://docs.openwebui.com/tutorials/integrations/redis/))

I made these choices because [I want to later deploy *Open WebUI* on a Kubernetes cluster](https://notes.sklein.xyz/Projet%2029/).

## Préparation

Install [Mise](https://mise.jdx.dev/)

```sh
$ cp .secret.skel .secret
```

Then fill in the `.secret` file with a [Scaleway](https://scaleway.com) API Key that has access permission to `GenerativeApisModelAccess, InferenceReadOnly, InstancesFullAccess, KeyManagerFullAccess, ObjectStorageBucketPolicyFullAccess, ObjectStorageBucketsDelete, ObjectStorageBucketsRead, ObjectStorageBucketsWrite, ObjectStorageFullAccess, ObjectStorageObjectsDelete, ObjectStorageObjectsRead, ObjectStorageObjectsWrite, ObjectStorageReadOnly, SSHKeysFullAccess`.

## Getting started

```sh
$ mise install
```

If needed, you can force the environment variables loading with this command:

```sh
$ source .envrc
```

Create Object Storage bucket to store Terraform states:

```sh
$ scw object bucket create openwebux-terraform-poc
```

Initialize terraform:

```sh
$ terraform init --upgrade
```

```sh
$ terraform apply
```

```sh
$ ./scripts/install_basic_server_configuration.sh
$ ./scripts/deploy_openwebui.sh
...

Go to https://.....pub.instances.scw.cloud

email: ....
password: ...
```

## Teardown

```sh
$ terraform destroy -f
```
