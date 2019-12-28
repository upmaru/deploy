variable "app_name" {
  type = string
}

terraform {
  backend "remote" {
    hostname = "app.terraform.io"

    workspaces {
      prefix = "${var.app_name}-"
    }
  }
}

provider "lxd" {}

variable "app_hostname" {
  type = string
}

variable "app_version" {
  type = string
}

variable "cpu" {
  type = map

  default = {
    "production" = 1
    "staging"    = 1
  }
}

variable "memory" {
  type = map

  default = {
    "production" = "1GB"
    "staging"    = "1GB"
  }
}

variable "nodes" {
  type = map

  default = {
    "production" = 1
  }
}

resource "lxd_container" "web" {
  count    = var.nodes[terraform.workspace]
  name     = "${var.app_hostname}-${terraform.workspace}-${count.index + 1}"
  image    = "images:alpine/3.11"
  profiles = ["default"]

  limits = {
    cpu    = var.cpu[terraform.workspace]
    memory = var.memory[terraform.workspace]
  }

  provisioner "local-exec" {
    command = <<EXEC
    lxc exec ${var.app_hostname}-${terraform.workspace}-${count.index + 1} -- sh -c 'echo "inside container"'
    EXEC
  }
}

resource "lxd_container_file" "public_key" {
  container_name = lxd_container.web.*.name[count.index]
  target_file    = "/etc/apk/keys/upmaru.rsa.pub"
  source         = "upmaru.rsa.pub"
}
