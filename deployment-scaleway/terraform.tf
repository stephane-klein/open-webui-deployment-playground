terraform {
    required_providers {
        scaleway = {
            source = "scaleway/scaleway"
            version = "2.53.0" # See last version on this url https://github.com/scaleway/terraform-provider-scaleway/releases
        }
    }
    backend "s3" {
        bucket                      = "openwebux-terraform-poc"
        key                         = "openwebux-terraform-poc"
        region                      = "fr-par"
        skip_credentials_validation = true
        skip_region_validation      = true
        skip_requesting_account_id  = true
        use_path_style              = true
        endpoints = {
            s3 = "https://s3.fr-par.scw.cloud"
        }
    }
}

provider "scaleway" {
    zone   = "fr-par-1"
    region = "fr-par"
}

variable "openwebui_project_id" {
    type    = string
    /* set by TF_VAR_openwebui_project_id variable env */
}

/* public ssh key used in Virtual Instances */
resource "scaleway_account_ssh_key" "stephane-klein-public-ssh-key-dev" {
    name        = "stephane-klein-public-ssh-key"
    project_id  = var.openwebui_project_id
    public_key  = file("${path.module}/ssh-keys/stephane-klein.pub")
}

/* Begin section: create server1 (Virtual Instance) */

resource "scaleway_instance_ip" "server1_public_ip" {
    project_id  = var.openwebui_project_id
    type = "routed_ipv4"
}

resource "scaleway_instance_ip" "server1_public_ipv6" {
    project_id  = var.openwebui_project_id
    type = "routed_ipv6"
}

resource "scaleway_instance_server" "server1" {
    project_id  = var.openwebui_project_id
    name = "server1"
    type  = "DEV1-M"
    image = "ubuntu_noble" # Last Ubuntu LTS version 24.04
                           # Execute "scw marketplace image list" to comsult the list of images proposed by Scaleway

    ip_ids = [
        scaleway_instance_ip.server1_public_ip.id,
        scaleway_instance_ip.server1_public_ipv6.id
    ]
    root_volume {
        size_in_gb = 20
    }
}

output "server1_id" {
    value = split("/", scaleway_instance_server.server1.id)[1]
}

output "server1_public_dns" {
    value = format("%s.pub.instances.scw.cloud", split("/", scaleway_instance_server.server1.id)[1])
}

/* End section: create server1 (Virtual Instance) */

/* Begin section: Object Storage sklein-openwebui-poc-data */
resource "scaleway_object_bucket" "sklein_openwebui_poc_data" {
    name = "sklein-openwebui-poc-data"
    project_id  = var.openwebui_project_id
    region = "fr-par"

    versioning {
        enabled = false
    }
}

resource "scaleway_iam_application" "sklein_openwebui_poc_data" {
    name = "sklein_openwebui_poc_data"
}

resource "scaleway_iam_policy" "sklein_openwebui_poc_data_policy" {
    name = "sklein_openwebui_poc_data_policy"
    application_id = scaleway_iam_application.sklein_openwebui_poc_data.id
    rule {
        project_ids = [var.openwebui_project_id]
        permission_set_names = [
            "ObjectStorageFullAccess"
        ]
    }
}

resource "scaleway_iam_api_key" "sklein_openwebui_poc_data" {
    application_id = scaleway_iam_application.sklein_openwebui_poc_data.id
    default_project_id = var.openwebui_project_id
}

output "sklein_openwebui_poc_data_app_id" {
    value = scaleway_iam_application.sklein_openwebui_poc_data.id
}

output "sklein_openwebui_poc_data_api_access_key" {
    value = scaleway_iam_api_key.sklein_openwebui_poc_data.access_key
}

output "sklein_openwebui_poc_data_api_secret_key" {
    value = scaleway_iam_api_key.sklein_openwebui_poc_data.secret_key
    sensitive = true
}

/* End section: Object Storage sklein-openwebui-poc-data */
