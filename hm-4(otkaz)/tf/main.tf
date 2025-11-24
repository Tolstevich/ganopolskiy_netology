terraform {
required_providers {
    yandex = {
        source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.12"
}
provider "yandex" {
    cloud_id                 = var.cloud_id
    folder_id                = var.folder_id
    service_account_key_file = file("~/authorized_keys.json")
    zone                     = "ru-central1-a"
}


resource "yandex_vpc_network" "network-test" {
    name = "network-test"
}

resource "yandex_vpc_subnet" "subnet-test" {
    name           = "subnet-test"
    v4_cidr_blocks = ["192.168.0.0/24"]
    network_id     = yandex_vpc_network.network-test.id
}

data "yandex_compute_image" "ubuntu_2404_lts" {
  family = "ubuntu-2404-lts"
}

resource "yandex_compute_instance" "vm" {
    count = 2

    name        = "vm${count.index}"
    platform_id = "standard-v3"

    resources {
        cores         = 2
        memory        = 2
        core_fraction = 20
    }
    boot_disk {
        initialize_params {
            image_id = data.yandex_compute_image.ubuntu_2404_lts.image_id
            type     = "network-hdd"
            size     = 20
        }
    }
    network_interface {
        subnet_id = yandex_vpc_subnet.subnet-test.id
        nat       = true
    }
    metadata = {
        user-data = file("./cloud-init.yml")
    }
}

resource "yandex_lb_target_group" "group1" {
    name = "group1"

    dynamic "target" {
        for_each = yandex_compute_instance.vm
        content {
            subnet_id = yandex_vpc_subnet.subnet-test.id
            address   = target.value.network_interface.0.ip_address
        }
    }
}

resource "yandex_lb_network_load_balancer" "balancer1" {
    name                = "balancer1"
    deletion_protection = "false"
    listener {
        name = "listener1"
        port = 80
        external_address_spec {
            ip_version = "ipv4"
        }
    }

    attached_target_group {
        target_group_id = yandex_lb_target_group.group1.id
        healthcheck {
            name = "http"
            http_options {
                port = 80
                path = "/"
            }
        }
    }
}
resource "local_file" "inventory" {
    content = <<-XYZ
    [vmserv]
    %{ for ip in yandex_compute_instance.vm[*].network_interface.0.nat_ip_address ~}
    ${ip}
    %{ endfor ~}
    [vmserv:vars]
    ansible_user=ansible
    ansible_ssh_common_args='-o StrictHostKeyChecking=no'
    XYZ
    filename = "../ansible/inventory/hosts.ini"
    }