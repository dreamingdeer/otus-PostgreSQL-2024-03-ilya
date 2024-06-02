## Домашнее задание 02

Исходное задание: [HW02](./HW02.md "дз 02" )

Деплоить VM в yandex облако, это просто! yc - консоль это конечно хорошо, но ребят это не серьезно. А вот terraform это гениально!

Получение образа ubuntu-2204-lts из публичного облака образов в ya cloud. К сожалению 2404 нет :(

```sh
yc compute image get-latest-from-family ubuntu-2204-lts --folder-id standard-images
id: fd8dpupkt886ut5m0j2o
folder_id: standard-images
created_at: "2024-05-27T10:59:06Z"
name: ubuntu-22-04-lts-v20240527
description: ubuntu 22.04 lts
family: ubuntu-2204-lts
storage_size: "8086618112"
min_disk_size: "8589934592"
product_ids:
  - f2eoi98fpm57j2cssv4g
status: READY
os:
  type: LINUX
pooled: true
```

> Сгенерируем ключь доступа
```sh
ssh-keygen -t ed25519 -C "dreamingdeer@pgtest" -f accesskey
```
Напишем [terraform](./terraform) для деплоя. Будем делать безопасно не будем светить нашу базенку в интернет :) Тем более давать подключения из под суперпользователя через интернет.

И так развернем наш postgres

```sh 
cd terraform 
terraform init
```
```sh
Initializing the backend...
Initializing modules...

Initializing provider plugins...
- Finding yandex-cloud/yandex versions matching ">= 0.61.0"...
- Finding latest version of hashicorp/local...
- Installing yandex-cloud/yandex v0.119.0...
- Installed yandex-cloud/yandex v0.119.0 (unauthenticated)
- Installing hashicorp/local v2.5.1...
- Installed hashicorp/local v2.5.1 (unauthenticated)

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

╷
│ Warning: Incomplete lock file information for providers
│ 
│ Due to your customized provider installation methods, Terraform was forced to calculate lock file checksums locally for the following providers:
│   - hashicorp/local
│   - yandex-cloud/yandex
│ 
│ The current .terraform.lock.hcl file only includes checksums for linux_amd64, so Terraform running on another platform will fail to install these providers.
│ 
│ To calculate additional checksums for another platform, run:
│   terraform providers lock -platform=linux_amd64
│ (where linux_amd64 is the platform to generate)
╵

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
ilyaz@inoteR7 ~/d/o/H/terraform (main)> terraform init
```
Установим токен для доступа
> set -x TF_VAR_iam_token $(yc iam create-token)

terraform plan
```sh
terraform plan

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the
following symbols:
  + create

Terraform will perform the following actions:

  # local_file.ssh_configs will be created
  + resource "local_file" "ssh_configs" {
      + content              = (known after apply)
      + content_base64sha256 = (known after apply)
      + content_base64sha512 = (known after apply)
      + content_md5          = (known after apply)
      + content_sha1         = (known after apply)
      + content_sha256       = (known after apply)
      + content_sha512       = (known after apply)
      + directory_permission = "0777"
      + file_permission      = "600"
      + filename             = "xxxx/.ssh/config.d/pg.conf"
      + id                   = (known after apply)
    }

  # module.bastion.yandex_compute_image.ubuntu will be created
  + resource "yandex_compute_image" "ubuntu" {
      + created_at      = (known after apply)
      + folder_id       = (known after apply)
      + id              = (known after apply)
      + min_disk_size   = (known after apply)
      + os_type         = (known after apply)
      + pooled          = (known after apply)
      + product_ids     = (known after apply)
      + size            = (known after apply)
      + source_disk     = (known after apply)
      + source_family   = "ubuntu-2004-lts"
      + source_image    = (known after apply)
      + source_snapshot = (known after apply)
      + source_url      = (known after apply)
      + status          = (known after apply)
    }

  # module.bastion.yandex_compute_instance.vm_ubuntu_lts[0] will be created
  + resource "yandex_compute_instance" "vm_ubuntu_lts" {
      + allow_stopping_for_update = true
      + created_at                = (known after apply)
      + folder_id                 = (known after apply)
      + fqdn                      = (known after apply)
      + gpu_cluster_id            = (known after apply)
      + hostname                  = (known after apply)
      + id                        = (known after apply)
      + maintenance_grace_period  = (known after apply)
      + maintenance_policy        = (known after apply)
      + metadata                  = {
          + "user-data" = <<-EOT
                #cloud-config
                version: v1
                packages_update: true
                packages_upgrade: true
                
                users:
                  - name: dreamingdeer
                    gecos: AnsibleAutomation
                    groups: sudo
                    shell: /bin/bash
                    sudo: ALL=(ALL) NOPASSWD:ALL
                    lock_passwd: true
                    ssh_authorized_keys:
                      - xxxx
            EOT
        }
      + name                      = "bastion-for-pg-0"
      + network_acceleration_type = "standard"
      + platform_id               = "standard-v3"
      + service_account_id        = (known after apply)
      + status                    = (known after apply)
      + zone                      = "ru-central1-d"

      + boot_disk {
          + auto_delete = true
          + device_name = (known after apply)
          + disk_id     = (known after apply)
          + mode        = (known after apply)

          + initialize_params {
              + block_size  = (known after apply)
              + description = (known after apply)
              + image_id    = (known after apply)
              + name        = (known after apply)
              + size        = 15
              + snapshot_id = (known after apply)
              + type        = "network-hdd"
            }
        }

      + network_interface {
          + index              = (known after apply)
          + ip_address         = (known after apply)
          + ipv4               = true
          + ipv6               = (known after apply)
          + ipv6_address       = (known after apply)
          + mac_address        = (known after apply)
          + nat                = true
          + nat_ip_address     = (known after apply)
          + nat_ip_version     = (known after apply)
          + security_group_ids = (known after apply)
          + subnet_id          = (known after apply)
        }

      + resources {
          + core_fraction = 20
          + cores         = 2
          + memory        = 2
        }

      + scheduling_policy {
          + preemptible = true
        }
    }

  # module.local-nat.yandex_vpc_gateway.nat_gateway will be created
  + resource "yandex_vpc_gateway" "nat_gateway" {
      + created_at = (known after apply)
      + folder_id  = (known after apply)
      + id         = (known after apply)
      + labels     = (known after apply)
      + name       = "pg-gateway"

      + shared_egress_gateway {}
    }

  # module.local-nat.yandex_vpc_network.default will be created
  + resource "yandex_vpc_network" "default" {
      + created_at                = (known after apply)
      + default_security_group_id = (known after apply)
      + description               = "Мегасеть! голой ж давить ежей"
      + folder_id                 = "b1glpcbkgqacq817e2k1"
      + id                        = (known after apply)
      + labels                    = {
          + "empty-label" = ""
          + "tf-label"    = "tf-label-value"
        }
      + name                      = "default"
      + subnet_ids                = (known after apply)
    }

  # module.local-nat.yandex_vpc_route_table.rt will be created
  + resource "yandex_vpc_route_table" "rt" {
      + created_at = (known after apply)
      + folder_id  = (known after apply)
      + id         = (known after apply)
      + labels     = (known after apply)
      + name       = "pg-net-route-table"
      + network_id = (known after apply)

      + static_route {
          + destination_prefix = "0.0.0.0/0"
          + gateway_id         = (known after apply)
        }
    }

  # module.local-nat.yandex_vpc_subnet.pg-subnet will be created
  + resource "yandex_vpc_subnet" "pg-subnet" {
      + created_at     = (known after apply)
      + description    = "for k3s cluster in ru-central1-d"
      + folder_id      = "b1glpcbkgqacq817e2k1"
      + id             = (known after apply)
      + labels         = (known after apply)
      + name           = "pg zone d"
      + network_id     = (known after apply)
      + route_table_id = (known after apply)
      + v4_cidr_blocks = [
          + "10.128.0.0/24",
        ]
      + v6_cidr_blocks = (known after apply)
      + zone           = "ru-central1-d"
    }

  # module.pg01.yandex_compute_image.ubuntu will be created
  + resource "yandex_compute_image" "ubuntu" {
      + created_at      = (known after apply)
      + folder_id       = (known after apply)
      + id              = (known after apply)
      + min_disk_size   = (known after apply)
      + os_type         = (known after apply)
      + pooled          = (known after apply)
      + product_ids     = (known after apply)
      + size            = (known after apply)
      + source_disk     = (known after apply)
      + source_family   = "ubuntu-2004-lts"
      + source_image    = (known after apply)
      + source_snapshot = (known after apply)
      + source_url      = (known after apply)
      + status          = (known after apply)
    }

  # module.pg01.yandex_compute_instance.vm_ubuntu_lts[0] will be created
  + resource "yandex_compute_instance" "vm_ubuntu_lts" {
      + allow_stopping_for_update = true
      + created_at                = (known after apply)
      + folder_id                 = (known after apply)
      + fqdn                      = (known after apply)
      + gpu_cluster_id            = (known after apply)
      + hostname                  = (known after apply)
      + id                        = (known after apply)
      + maintenance_grace_period  = (known after apply)
      + maintenance_policy        = (known after apply)
      + metadata                  = {
          + "user-data" = <<-EOT
                #cloud-config
                version: v1
                packages_update: true
                packages_upgrade: true
                
                users:
                  - name: dreamingdeer
                    gecos: AnsibleAutomation
                    groups: sudo
                    shell: /bin/bash
                    sudo: ALL=(ALL) NOPASSWD:ALL
                    lock_passwd: true
                    ssh_authorized_keys:
                      - xxx
                
                apt:
                  sources:
                    postgres.list:
                      source: "deb https://apt.postgresql.org/pub/repos/apt $RELEASE-pgdg main"
                      key: |
                        -----BEGIN PGP PUBLIC KEY BLOCK-----
                
                        mQINBE6XR8IBEACVdDKT2HEH1IyHzXkb4nIWAY7echjRxo7MTcj4vbXAyBKOfjja
                        UrBEJWHN6fjKJXOYWXHLIYg0hOGeW9qcSiaa1/rYIbOzjfGfhE4x0Y+NJHS1db0V
                        G6GUj3qXaeyqIJGS2z7m0Thy4Lgr/LpZlZ78Nf1fliSzBlMo1sV7PpP/7zUO+aA4
                        bKa8Rio3weMXQOZgclzgeSdqtwKnyKTQdXY5MkH1QXyFIk1nTfWwyqpJjHlgtwMi
                        c2cxjqG5nnV9rIYlTTjYG6RBglq0SmzF/raBnF4Lwjxq4qRqvRllBXdFu5+2pMfC
                        IZ10HPRdqDCTN60DUix+BTzBUT30NzaLhZbOMT5RvQtvTVgWpeIn20i2NrPWNCUh
                        hj490dKDLpK/v+A5/i8zPvN4c6MkDHi1FZfaoz3863dylUBR3Ip26oM0hHXf4/2U
                        A/oA4pCl2W0hc4aNtozjKHkVjRx5Q8/hVYu+39csFWxo6YSB/KgIEw+0W8DiTII3
                        RQj/OlD68ZDmGLyQPiJvaEtY9fDrcSpI0Esm0i4sjkNbuuh0Cvwwwqo5EF1zfkVj
                        Tqz2REYQGMJGc5LUbIpk5sMHo1HWV038TWxlDRwtOdzw08zQA6BeWe9FOokRPeR2
                        AqhyaJJwOZJodKZ76S+LDwFkTLzEKnYPCzkoRwLrEdNt1M7wQBThnC5z6wARAQAB
                        tBxQb3N0Z3JlU1FMIERlYmlhbiBSZXBvc2l0b3J5iQJOBBMBCAA4AhsDBQsJCAcD
                        BRUKCQgLBRYCAwEAAh4BAheAFiEEuXsK/KoaR/BE8kSgf8x9RqzMTPgFAlhtCD8A
                        CgkQf8x9RqzMTPgECxAAk8uL+dwveTv6eH21tIHcltt8U3Ofajdo+D/ayO53LiYO
                        xi27kdHD0zvFMUWXLGxQtWyeqqDRvDagfWglHucIcaLxoxNwL8+e+9hVFIEskQAY
                        kVToBCKMXTQDLarz8/J030Pmcv3ihbwB+jhnykMuyyNmht4kq0CNgnlcMCdVz0d3
                        z/09puryIHJrD+A8y3TD4RM74snQuwc9u5bsckvRtRJKbP3GX5JaFZAqUyZNRJRJ
                        Tn2OQRBhCpxhlZ2afkAPFIq2aVnEt/Ie6tmeRCzsW3lOxEH2K7MQSfSu/kRz7ELf
                        Cz3NJHj7rMzC+76Rhsas60t9CjmvMuGONEpctijDWONLCuch3Pdj6XpC+MVxpgBy
                        2VUdkunb48YhXNW0jgFGM/BFRj+dMQOUbY8PjJjsmVV0joDruWATQG/M4C7O8iU0
                        B7o6yVv4m8LDEN9CiR6r7H17m4xZseT3f+0QpMe7iQjz6XxTUFRQxXqzmNnloA1T
                        7VjwPqIIzkj/u0V8nICG/ktLzp1OsCFatWXh7LbU+hwYl6gsFH/mFDqVxJ3+DKQi
                        vyf1NatzEwl62foVjGUSpvh3ymtmtUQ4JUkNDsXiRBWczaiGSuzD9Qi0ONdkAX3b
                        ewqmN4TfE+XIpCPxxHXwGq9Rv1IFjOdCX0iG436GHyTLC1tTUIKF5xV4Y0+cXIOI
                        RgQQEQgABgUCTpdI7gAKCRDFr3dKWFELWqaPAKD1TtT5c3sZz92Fj97KYmqbNQZP
                        +ACfSC6+hfvlj4GxmUjp1aepoVTo3weJAhwEEAEIAAYFAk6XSQsACgkQTFprqxLS
                        p64F8Q//cCcutwrH50UoRFejg0EIZav6LUKejC6kpLeubbEtuaIH3r2zMblPGc4i
                        +eMQKo/PqyQrceRXeNNlqO6/exHozYi2meudxa6IudhwJIOn1MQykJbNMSC2sGUp
                        1W5M1N5EYgt4hy+qhlfnD66LR4G+9t5FscTJSy84SdiOuqgCOpQmPkVRm1HX5X1+
                        dmnzMOCk5LHHQuiacV0qeGO7JcBCVEIDr+uhU1H2u5GPFNHm5u15n25tOxVivb94
                        xg6NDjouECBH7cCVuW79YcExH/0X3/9G45rjdHlKPH1OIUJiiX47OTxdG3dAbB4Q
                        fnViRJhjehFscFvYWSqXo3pgWqUsEvv9qJac2ZEMSz9x2mj0ekWxuM6/hGWxJdB+
                        +985rIelPmc7VRAXOjIxWknrXnPCZAMlPlDLu6+vZ5BhFX0Be3y38f7GNCxFkJzl
                        hWZ4Cj3WojMj+0DaC1eKTj3rJ7OJlt9S9xnO7OOPEUTGyzgNIDAyCiu8F4huLPaT
                        ape6RupxOMHZeoCVlqx3ouWctelB2oNXcxxiQ/8y+21aHfD4n/CiIFwDvIQjl7dg
                        mT3u5Lr6yxuosR3QJx1P6rP5ZrDTP9khT30t+HZCbvs5Pq+v/9m6XDmi+NlU7Zuh
                        Ehy97tL3uBDgoL4b/5BpFL5U9nruPlQzGq1P9jj40dxAaDAX/WKJAj0EEwEIACcC
                        GwMFCwkIBwMFFQoJCAsFFgIDAQACHgECF4AFAlB5KywFCQPDFt8ACgkQf8x9RqzM
                        TPhuCQ//QAjRSAOCQ02qmUAikT+mTB6baOAakkYq6uHbEO7qPZkv4E/M+HPIJ4wd
                        nBNeSQjfvdNcZBA/x0hr5EMcBneKKPDj4hJ0panOIRQmNSTThQw9OU351gm3YQct
                        AMPRUu1fTJAL/AuZUQf9ESmhyVtWNlH/56HBfYjE4iVeaRkkNLJyX3vkWdJSMwC/
                        LO3Lw/0M3R8itDsm74F8w4xOdSQ52nSRFRh7PunFtREl+QzQ3EA/WB4AIj3VohIG
                        kWDfPFCzV3cyZQiEnjAe9gG5pHsXHUWQsDFZ12t784JgkGyO5wT26pzTiuApWM3k
                        /9V+o3HJSgH5hn7wuTi3TelEFwP1fNzI5iUUtZdtxbFOfWMnZAypEhaLmXNkg4zD
                        kH44r0ss9fR0DAgUav1a25UnbOn4PgIEQy2fgHKHwRpCy20d6oCSlmgyWsR40EPP
                        YvtGq49A2aK6ibXmdvvFT+Ts8Z+q2SkFpoYFX20mR2nsF0fbt1lfH65P64dukxeR
                        GteWIeNakDD40bAAOH8+OaoTGVBJ2ACJfLVNM53PEoftavAwUYMrR910qvwYfd/4
                        6rh46g1Frr9SFMKYE9uvIJIgDsQB3QBp71houU4H55M5GD8XURYs+bfiQpJG1p7e
                        B8e5jZx1SagNWc4XwL2FzQ9svrkbg1Y+359buUiP7T6QXX2zY++JAj0EEwEIACcC
                        GwMFCwkIBwMFFQoJCAsFFgIDAQACHgECF4AFAlEqbZUFCQg2wEEACgkQf8x9RqzM
                        TPhFMQ//WxAfKMdpSIA9oIC/yPD/dJpY/+DyouOljpE6MucMy/ArBECjFTBwi/j9
                        NYM4ynAk34IkhuNexc1i9/05f5RM6+riLCLgAOsADDbHD4miZzoSxiVr6GQ3YXMb
                        OGld9kV9Sy6mGNjcUov7iFcf5Hy5w3AjPfKuR9zXswyfzIU1YXObiiZT38l55pp/
                        BSgvGVQsvbNjsff5CbEKXS7q3xW+WzN0QWF6YsfNVhFjRGj8hKtHvwKcA02wwjLe
                        LXVTm6915ZUKhZXUFc0vM4Pj4EgNswH8Ojw9AJaKWJIZmLyW+aP+wpu6YwVCicxB
                        Y59CzBO2pPJDfKFQzUtrErk9irXeuCCLesDyirxJhv8o0JAvmnMAKOLhNFUrSQ2m
                        +3EnF7zhfz70gHW+EG8X8mL/EN3/dUM09j6TVrjtw43RLxBzwMDeariFF9yC+5bL
                        tnGgxjsB9Ik6GV5v34/NEEGf1qBiAzFmDVFRZlrNDkq6gmpvGnA5hUWNr+y0i01L
                        jGyaLSWHYjgw2UEQOqcUtTFK9MNzbZze4mVaHMEz9/aMfX25R6qbiNqCChveIm8m
                        Yr5Ds2zdZx+G5bAKdzX7nx2IUAxFQJEE94VLSp3npAaTWv3sHr7dR8tSyUJ9poDw
                        gw4W9BIcnAM7zvFYbLF5FNggg/26njHCCN70sHt8zGxKQINMc6SJAj0EEwEIACcC
                        GwMFCwkIBwMFFQoJCAsFFgIDAQACHgECF4AFAlLpFRkFCQ6EJy0ACgkQf8x9RqzM
                        TPjOZA//Zp0e25pcvle7cLc0YuFr9pBv2JIkLzPm83nkcwKmxaWayUIG4Sv6pH6h
                        m8+S/CHQij/yFCX+o3ngMw2J9HBUvafZ4bnbI0RGJ70GsAwraQ0VlkIfg7GUw3Tz
                        voGYO42rZTru9S0K/6nFP6D1HUu+U+AsJONLeb6oypQgInfXQExPZyliUnHdipei
                        4WR1YFW6sjSkZT/5C3J1wkAvPl5lvOVthI9Zs6bZlJLZwusKxU0UM4Btgu1Sf3nn
                        JcHmzisixwS9PMHE+AgPWIGSec/N27a0KmTTvImV6K6nEjXJey0K2+EYJuIBsYUN
                        orOGBwDFIhfRk9qGlpgt0KRyguV+AP5qvgry95IrYtrOuE7307SidEbSnvO5ezNe
                        mE7gT9Z1tM7IMPfmoKph4BfpNoH7aXiQh1Wo+ChdP92hZUtQrY2Nm13cmkxYjQ4Z
                        gMWfYMC+DA/GooSgZM5i6hYqyyfAuUD9kwRN6BqTbuAUAp+hCWYeN4D88sLYpFh3
                        paDYNKJ+Gf7Yyi6gThcV956RUFDH3ys5Dk0vDL9NiWwdebWfRFbzoRM3dyGP889a
                        OyLzS3mh6nHzZrNGhW73kslSQek8tjKrB+56hXOnb4HaElTZGDvD5wmrrhN94kby
                        Gtz3cydIohvNO9d90+29h0eGEDYti7j7maHkBKUAwlcPvMg5m3Y=
                        =DA1T
                        -----END PGP PUBLIC KEY BLOCK-----
                
                packages:
                  - docker-ce
                  - postgresql-12
                  - postgresql-14
            EOT
        }
      + name                      = "pg-0"
      + network_acceleration_type = "standard"
      + platform_id               = "standard-v3"
      + service_account_id        = (known after apply)
      + status                    = (known after apply)
      + zone                      = "ru-central1-d"

      + boot_disk {
          + auto_delete = true
          + device_name = (known after apply)
          + disk_id     = (known after apply)
          + mode        = (known after apply)

          + initialize_params {
              + block_size  = (known after apply)
              + description = (known after apply)
              + image_id    = (known after apply)
              + name        = (known after apply)
              + size        = 30
              + snapshot_id = (known after apply)
              + type        = "network-hdd"
            }
        }

      + network_interface {
          + index              = (known after apply)
          + ip_address         = (known after apply)
          + ipv4               = true
          + ipv6               = (known after apply)
          + ipv6_address       = (known after apply)
          + mac_address        = (known after apply)
          + nat                = false
          + nat_ip_address     = (known after apply)
          + nat_ip_version     = (known after apply)
          + security_group_ids = (known after apply)
          + subnet_id          = (known after apply)
        }

      + resources {
          + core_fraction = 20
          + cores         = 4
          + memory        = 4
        }

      + scheduling_policy {
          + preemptible = true
        }
    }

Plan: 9 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + base_image_id        = (known after apply)
  + external_ips_bastion = [
      + (known after apply),
    ]
  + internal_ips_bastion = [
      + (known after apply),
    ]
  + master_internal_ips  = [
      + (known after apply),
    ]
  + node_internal_ips    = [
      + (known after apply),
    ]
```

> terraform apply
```sh
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

module.local-nat.yandex_vpc_network.default: Creating...
module.local-nat.yandex_vpc_gateway.nat_gateway: Creating...
module.local-nat.yandex_vpc_gateway.nat_gateway: Creation complete after 1s [id=]
module.local-nat.yandex_vpc_network.default: Creation complete after 3s [id=]
module.local-nat.yandex_vpc_route_table.rt: Creating...
module.local-nat.yandex_vpc_route_table.rt: Creation complete after 1s [id=]
module.local-nat.yandex_vpc_subnet.pg-subnet: Creating...
module.local-nat.yandex_vpc_subnet.pg-subnet: Creation complete after 1s [id=]
module.bastion.yandex_compute_image.ubuntu: Creating...
module.bastion.yandex_compute_image.ubuntu: Creation complete after 10s [id=]
module.bastion.yandex_compute_instance.vm_ubuntu_lts[0]: Creating...
module.bastion.yandex_compute_instance.vm_ubuntu_lts[0]: Still creating... [10s elapsed]
module.bastion.yandex_compute_instance.vm_ubuntu_lts[0]: Still creating... [20s elapsed]
module.bastion.yandex_compute_instance.vm_ubuntu_lts[0]: Still creating... [30s elapsed]
module.bastion.yandex_compute_instance.vm_ubuntu_lts[0]: Still creating... [40s elapsed]
module.bastion.yandex_compute_instance.vm_ubuntu_lts[0]: Still creating... [50s elapsed]
module.bastion.yandex_compute_instance.vm_ubuntu_lts[0]: Still creating... [1m0s elapsed]
module.bastion.yandex_compute_instance.vm_ubuntu_lts[0]: Creation complete after 1m7s [id=]
module.pg01.yandex_compute_image.ubuntu: Creating...
local_file.ssh_configs: Creating...
local_file.ssh_configs: Creation complete after 0s [id=]
module.pg01.yandex_compute_image.ubuntu: Creation complete after 5s [id=]
module.pg01.yandex_compute_instance.vm_ubuntu_lts[0]: Creating...
module.pg01.yandex_compute_instance.vm_ubuntu_lts[0]: Still creating... [10s elapsed]
module.pg01.yandex_compute_instance.vm_ubuntu_lts[0]: Still creating... [20s elapsed]
module.pg01.yandex_compute_instance.vm_ubuntu_lts[0]: Still creating... [30s elapsed]
module.pg01.yandex_compute_instance.vm_ubuntu_lts[0]: Still creating... [40s elapsed]
module.pg01.yandex_compute_instance.vm_ubuntu_lts[0]: Still creating... [50s elapsed]
module.pg01.yandex_compute_instance.vm_ubuntu_lts[0]: Still creating... [1m0s elapsed]
module.pg01.yandex_compute_instance.vm_ubuntu_lts[0]: Creation complete after 1m2s [id=]

Apply complete! Resources: 9 added, 0 changed, 0 destroyed.

Outputs:

base_image_id = "fd832b18s2kd9e08vsdb"
external_ips_bastion = [
  "158.160.141.118",
]
internal_ips_bastion = [
  "10.128.0.15",
]
master_internal_ips = [
  "10.128.0.25",
]
```

```sh
eval ssh-agent
```

```sh
ssh-add ../../accesskey
Identity added: ../../accesskey (xxx@pgtest)
```

Подключимся к созданной VM
```sh
ssh 10.128.0.25
Warning: Permanently added '158.160.141.118' (ED25519) to the list of known hosts.
Warning: Permanently added '10.128.0.25' (ED25519) to the list of known hosts.
Welcome to Ubuntu 22.04.4 LTS (GNU/Linux 5.15.0-107-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

  System information as of Thu May 23 11:50:53 PM UTC 2024

  System load:  1.861328125       Processes:             139
  Usage of /:   37.6% of 7.79GB   Users logged in:       0
  Memory usage: 6%                IPv4 address for eth0: 10.0.12.4
  Swap usage:   0%


Expanded Security Maintenance for Applications is not enabled.

0 updates can be applied immediately.

Enable ESM Apps to receive additional future security updates.
See https://ubuntu.com/esm or run: sudo pro status


The list of available updates is more than a week old.
To check for new updates run: sudo apt update


The programs included with the Ubuntu system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Ubuntu comes with ABSOLUTELY NO WARRANTY, to the extent permitted by
applicable law.

To run a command as administrator (user "root"), use "sudo <command>".
See "man sudo_root" for details.
```

Дождемтся полной инициализации cloud-init
```sh
> cloud-init status -w
............................................................................................................................................................................................................
status: done
```

Так как наш cloud-init содержит инструкции для установки несколько версий postgres и докера

```yaml
packages:
  - docker-ce
  - postgresql-12
  - postgresql-14
```

```
> pg_lsclusters 
Ver Cluster Port Status Owner    Data directory              Log file
12  main    5432 online postgres /var/lib/postgresql/12/main /var/log/postgresql/postgresql-12-main.log
14  main    5433 online postgres /var/lib/postgresql/14/main /var/log/postgresql/postgresql-14-main.log
```

```sh
> sudo -i -u postgres   psql -p 5432
psql (14.12 (Ubuntu 14.12-1.pgdg22.04+1), server 12.19 (Ubuntu 12.19-1.pgdg22.04+1))
Type "help" for help.

postgres=# 
\q
> sudo -i -u postgres   psql -p 5433 
psql (14.12 (Ubuntu 14.12-1.pgdg22.04+1))
Type "help" for help.
```

Проверим что докер установлен
```
> docker version
Client: Docker Engine - Community
 Version:           26.1.3
 API version:       1.45
 Go version:        go1.21.10
 Git commit:        b72abbb
 Built:             Thu May 16 08:33:29 2024
 OS/Arch:           linux/amd64
 Context:           default

Server: Docker Engine - Community
 Engine:
  Version:          26.1.3
  API version:      1.45 (minimum version 1.24)
  Go version:       go1.21.10
  Git commit:       8e96db1
  Built:            Thu May 16 08:33:29 2024
  OS/Arch:          linux/amd64
  Experimental:     false
 containerd:
  Version:          1.6.32
  GitCommit:        8b3b7ca2e5ce38e8f31a34f35b2b68ceb8470d89
 runc:
  Version:          1.1.12
  GitCommit:        v1.1.12-0-g51d5e94
 docker-init:
  Version:          0.19.0
  GitCommit:        de40ad0
```

Создадим файл с кредами для postgres контейнера
```sh
sudo chown -R dreamingdeer:dreamingdeer /opt/pg
cd /opt/pg/
cat <<EOF > .env
PG_USER=cooluser
PG_PASS=оченьбезопаснонебезопасно
PG_DB=otus-pg
EOF
```
Запустим контейнер
```sh
docker compose up -d
WARN[0000] /opt/pg/docker-compose.yaml: `version` is obsolete 
[+] Running 15/15
 ✔ db Pulled                                                                                                                                                8.5s 
   ✔ c57ee5000d61 Pull complete                                                                                                                             2.0s 
   ✔ 81b575116500 Pull complete                                                                                                                             2.1s 
   ✔ e12fff61d996 Pull complete                                                                                                                             2.3s 
   ✔ 50a849db7317 Pull complete                                                                                                                             2.3s 
   ✔ 432dd17f42df Pull complete                                                                                                                             2.6s 
   ✔ a1f5bcbba6b6 Pull complete                                                                                                                             2.7s 
   ✔ 6e501216828b Pull complete                                                                                                                             2.8s 
   ✔ ea24c7671c3d Pull complete                                                                                                                             2.8s 
   ✔ b7a5cd7c9b9a Pull complete                                                                                                                             5.7s 
   ✔ db7d78d9f46e Pull complete                                                                                                                             5.8s 
   ✔ 8c786fbf8634 Pull complete                                                                                                                             5.8s 
   ✔ 2831031f2a0e Pull complete                                                                                                                             5.9s 
   ✔ 75c5b068b243 Pull complete                                                                                                                             6.0s 
   ✔ 9590d9e20e85 Pull complete                                                                                                                             6.0s 
[+] Running 2/2
 ✔ Network pg      Created                                                                                                                                  0.1s 
 ✔ Container pgdb  Started                                                                                                                                  4.1s
 ```

Подключимся к нашей базе данных
```sh
docker run --rm -it --network postgres mirror.gcr.io/postgres:14 psql -h pgdb -U cooluser otus-pg
Password for user cooluser: 
psql (14.12 (Debian 14.12-1.pgdg120+1))
Type "help" for help.

otus-pg=#
\q
```

Проверим наш контейнер
```sh
docker ps
CONTAINER ID   IMAGE                         COMMAND                  CREATED         STATUS         PORTS                                       NAMES
5c9ef6d52327   mirror.gcr.io/postgres:14   "docker-entrypoint.s…"   5 seconds ago   Up 4 seconds   0.0.0.0:5000->5432/tcp, :::5000->5432/tcp   pgdb
```

Подключение с хоста
```sh
psql -h 127.0.0.1 -p 5000 -U cooluser otus-pg
Password for user cooluser: 
psql (14.12 (Ubuntu 14.12-1.pgdg22.04+1), server 16.1 (Debian 16.1-1.pgdg120+1))
WARNING: psql major version 14, server major version 16.
         Some psql features might not work.
Type "help" for help.
```

Подключатся будем через SSH туннель + на ноутбуке у меня podman
```sh
> ssh 10.128.0.12 -L 5000:127.0.0.1:5000
> podman run --rm -it --network host postgres:14 psql -h 127.0.0.1 -p 5000 -U cooluser otus-pg
Password for user cooluser: 
psql (14.12 (Debian 14.12-1.pgdg120+1))
Type "help" for help.

otus-pg=# create table persons(id serial, first_name text, second_name text); insert into persons(first_name, second_name) values('ivan', 'ivanov'); insert into persons(first_name, second_name) values('petr', 'petrov'); commit;
CREATE TABLE
INSERT 0 1
INSERT 0 1
WARNING:  there is no transaction in progress
COMMIT
otus-pg=# select * fro

otus-pg=# select * from persons;
 id | first_name | second_name 
----+------------+-------------
  1 | ivan       | ivanov
  2 | petr       | petrov
(2 rows)
```
Удалим контейнер на удаленном сервере 
```sh
docker compose down
[+] Running 2/2
 ✔ Container pgdb    Removed                                                                                       0.3s 
 ✔ Network postgres  Removed                                                                                       0.2s 
```
Убедимся что контейнеров нет
```sh
docker ps -a
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```
Запустим обратно

```sh
docker compose up -d
[+] Running 2/2
 ✔ Network postgres  Created                                                                                       0.1s 
 ✔ Container pgdb    Started                                                                                       0.3s 
```
Убедимся что все данные на месте
```sh
psql -h 127.0.0.1 -p 5000 -U cooluser otus-pg
Password for user cooluser: 
psql (14.12 (Ubuntu 14.12-1.pgdg22.04+1))
Type "help" for help.

otus-pg=# \d persons
                               Table "public.persons"
   Column    |  Type   | Collation | Nullable |               Default               
-------------+---------+-----------+----------+-------------------------------------
 id          | integer |           | not null | nextval('persons_id_seq'::regclass)
 first_name  | text    |           |          | 
 second_name | text    |           |          | 

otus-pg=# select * from persons;
 id | first_name | second_name 
----+------------+-------------
  1 | ivan       | ivanov
  2 | petr       | petrov
(2 rows)
```
Попытамся обновить версию постгреса в композ файле и запустить
```sh
> docker compose up -d
[+] Running 15/15
 ✔ db Pulled                                                                                                       6.8s 
   ✔ 09f376ebb190 Already exists                                                                                   0.0s 
   ✔ 119215dfb3e3 Pull complete                                                                                    0.5s 
   ✔ 94fccb772ad3 Pull complete                                                                                    0.8s 
   ✔ 0fc3acb16548 Pull complete                                                                                    0.8s 
   ✔ d7dba7d03fe8 Pull complete                                                                                    1.4s 
   ✔ 898ae395a1ca Pull complete                                                                                    1.5s 
   ✔ 088e651df7e9 Pull complete                                                                                    1.5s 
   ✔ ed155773e5e0 Pull complete                                                                                    1.6s 
   ✔ 52df7d12fb73 Pull complete                                                                                    5.0s 
   ✔ bab1ecc22dc9 Pull complete                                                                                    5.0s 
   ✔ 1655a257a5b5 Pull complete                                                                                    5.1s 
   ✔ 978f02dfc247 Pull complete                                                                                    5.2s 
   ✔ d715d7d9aee0 Pull complete                                                                                    5.2s 
   ✔ b2e9251b2f8d Pull complete                                                                                    5.3s 
[+] Running 2/2
 ✔ Network postgres  Created                                                                                       0.1s 
 ✔ Container pgdb    Started                                                                                       3.3
> psql -h 127.0.0.1 -p 5000 -U cooluser otus-pg
psql: error: connection to server at "127.0.0.1", port 5000 failed: Connection refused
	Is the server running on that host and accepting TCP/IP connections?
> docker compose logs -f
pgdb  | 
pgdb  | PostgreSQL Database directory appears to contain a database; Skipping initialization
pgdb  | 
pgdb  | 2024-06-02 14:56:49.609 UTC [1] FATAL:  database files are incompatible with server
pgdb  | 2024-06-02 14:56:49.609 UTC [1] DETAIL:  The data directory was initialized by PostgreSQL version 14, which is not compatible with this version 15.7 (Debian 15.7-1.pgdg120+1).
```
О боже нет! мы все сломали ) Нам нужно немного черной магии!

```sh
> docker compose down
[+] Running 2/2
 ✔ Container pgdb    Removed                                                                                       0.0s 
 ✔ Network postgres  Removed                                                                                       0.2s 

> docker run --rm -it  -v ./data:/var/lib/postgresql/data  mirror.gcr.io/postgres:15 bash
> apt-cache search postgresql-14
> apt-get update
Get:1 http://deb.debian.org/debian bookworm InRelease [151 kB]
Get:2 http://apt.postgresql.org/pub/repos/apt bookworm-pgdg InRelease [123 kB]
Get:3 http://deb.debian.org/debian bookworm-updates InRelease [55.4 kB]
Get:4 http://deb.debian.org/debian-security bookworm-security InRelease [48.0 kB]
Get:5 http://deb.debian.org/debian bookworm/main amd64 Packages [8,786 kB]
Get:6 http://apt.postgresql.org/pub/repos/apt bookworm-pgdg/15 amd64 Packages [2,592 B]
Get:7 http://apt.postgresql.org/pub/repos/apt bookworm-pgdg/main amd64 Packages [337 kB]
Get:8 http://deb.debian.org/debian bookworm-updates/main amd64 Packages [13.8 kB]
Get:9 http://deb.debian.org/debian-security bookworm-security/main amd64 Packages [157 kB]
Fetched 9,674 kB in 2s (5,890 kB/s)                                                      
Reading package lists... Done
> apt-get install postgresql-14
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following additional packages will be installed:
  dbus dbus-bin dbus-daemon dbus-session-bus-common dbus-system-bus-common dmsetup libapparmor1 libargon2-1
  libcryptsetup12 libdbus-1-3 libdevmapper1.02.1 libexpat1 libfdisk1 libip4tc2 libjson-c5 libkmod2 libsensors-config
  libsensors5 libsystemd-shared postgresql-client-14 sysstat systemd systemd-timesyncd
Suggested packages:
  default-dbus-session-bus | dbus-session-bus lm-sensors postgresql-doc-14 isag systemd-container systemd-homed
  systemd-userdbd systemd-boot systemd-resolved libfido2-1 libqrencode4 libtss2-esys-3.0.2-0 libtss2-mu0 libtss2-rc0
  polkitd | policykit-1
The following NEW packages will be installed:
  dbus dbus-bin dbus-daemon dbus-session-bus-common dbus-system-bus-common dmsetup libapparmor1 libargon2-1
  libcryptsetup12 libdbus-1-3 libdevmapper1.02.1 libexpat1 libfdisk1 libip4tc2 libjson-c5 libkmod2 libsensors-config
  libsensors5 libsystemd-shared postgresql-14 postgresql-client-14 sysstat systemd systemd-timesyncd
0 upgraded, 24 newly installed, 0 to remove and 0 not upgraded.
Need to get 24.8 MB of archives.
After this operation, 80.4 MB of additional disk space will be used.
Do you want to continue? [Y/n] y
Get:1 http://deb.debian.org/debian bookworm/main amd64 libargon2-1 amd64 0~20171227-0.3+deb12u1 [19.4 kB]
Get:2 http://deb.debian.org/debian bookworm/main amd64 dmsetup amd64 2:1.02.185-2 [82.0 kB]
Get:3 http://deb.debian.org/debian bookworm/main amd64 libdevmapper1.02.1 amd64 2:1.02.185-2 [133 kB]
Get:4 http://deb.debian.org/debian bookworm/main amd64 libjson-c5 amd64 0.16-2 [44.1 kB]
Get:5 http://deb.debian.org/debian bookworm/main amd64 libcryptsetup12 amd64 2:2.6.1-4~deb12u2 [223 kB]
Get:6 http://apt.postgresql.org/pub/repos/apt bookworm-pgdg/main amd64 postgresql-client-14 amd64 14.12-1.pgdg120+1 [1,635 kB]
Get:7 http://deb.debian.org/debian-security bookworm-security/main amd64 libfdisk1 amd64 2.38.1-5+deb12u1 [193 kB]
Get:8 http://deb.debian.org/debian bookworm/main amd64 libkmod2 amd64 30+20221128-1 [57.9 kB]
Get:9 http://deb.debian.org/debian bookworm/main amd64 libapparmor1 amd64 3.0.8-3 [41.2 kB]
Get:10 http://deb.debian.org/debian bookworm/main amd64 libip4tc2 amd64 1.8.9-2 [19.0 kB]
Get:11 http://deb.debian.org/debian bookworm/main amd64 libsystemd-shared amd64 252.22-1~deb12u1 [1,691 kB]
Get:12 http://deb.debian.org/debian bookworm/main amd64 systemd amd64 252.22-1~deb12u1 [3,032 kB]
Get:13 http://deb.debian.org/debian bookworm/main amd64 libdbus-1-3 amd64 1.14.10-1~deb12u1 [201 kB]
Get:14 http://deb.debian.org/debian bookworm/main amd64 dbus-bin amd64 1.14.10-1~deb12u1 [105 kB]
Get:15 http://deb.debian.org/debian bookworm/main amd64 dbus-session-bus-common all 1.14.10-1~deb12u1 [78.2 kB]
Get:16 http://deb.debian.org/debian bookworm/main amd64 libexpat1 amd64 2.5.0-1 [99.3 kB]        
Get:17 http://deb.debian.org/debian bookworm/main amd64 dbus-daemon amd64 1.14.10-1~deb12u1 [184 kB]
Get:18 http://deb.debian.org/debian bookworm/main amd64 dbus-system-bus-common all 1.14.10-1~deb12u1 [79.3 kB]
Get:19 http://deb.debian.org/debian bookworm/main amd64 dbus amd64 1.14.10-1~deb12u1 [97.4 kB]  
Get:20 http://deb.debian.org/debian bookworm/main amd64 systemd-timesyncd amd64 252.22-1~deb12u1 [63.1 kB]
Get:21 http://deb.debian.org/debian bookworm/main amd64 libsensors-config all 1:3.6.0-7.1 [14.3 kB]
Get:22 http://deb.debian.org/debian bookworm/main amd64 libsensors5 amd64 1:3.6.0-7.1 [34.2 kB]
Get:23 http://deb.debian.org/debian bookworm/main amd64 sysstat amd64 12.6.1-1 [596 kB]
Get:24 http://apt.postgresql.org/pub/repos/apt bookworm-pgdg/main amd64 postgresql-14 amd64 14.12-1.pgdg120+1 [16.1 MB]
Fetched 24.8 MB in 2s (11.2 MB/s)         
debconf: delaying package configuration, since apt-utils is not installed
Selecting previously unselected package libargon2-1:amd64.
(Reading database ... 12018 files and directories currently installed.)
Preparing to unpack .../00-libargon2-1_0~20171227-0.3+deb12u1_amd64.deb ...
Unpacking libargon2-1:amd64 (0~20171227-0.3+deb12u1) ...
Selecting previously unselected package dmsetup.
Preparing to unpack .../01-dmsetup_2%3a1.02.185-2_amd64.deb ...
Unpacking dmsetup (2:1.02.185-2) ...
Selecting previously unselected package libdevmapper1.02.1:amd64.
Preparing to unpack .../02-libdevmapper1.02.1_2%3a1.02.185-2_amd64.deb ...
Unpacking libdevmapper1.02.1:amd64 (2:1.02.185-2) ...
Selecting previously unselected package libjson-c5:amd64.
Preparing to unpack .../03-libjson-c5_0.16-2_amd64.deb ...
Unpacking libjson-c5:amd64 (0.16-2) ...
Selecting previously unselected package libcryptsetup12:amd64.
Preparing to unpack .../04-libcryptsetup12_2%3a2.6.1-4~deb12u2_amd64.deb ...
Unpacking libcryptsetup12:amd64 (2:2.6.1-4~deb12u2) ...
Selecting previously unselected package libfdisk1:amd64.
Preparing to unpack .../05-libfdisk1_2.38.1-5+deb12u1_amd64.deb ...
Unpacking libfdisk1:amd64 (2.38.1-5+deb12u1) ...
Selecting previously unselected package libkmod2:amd64.
Preparing to unpack .../06-libkmod2_30+20221128-1_amd64.deb ...
Unpacking libkmod2:amd64 (30+20221128-1) ...
Selecting previously unselected package libapparmor1:amd64.
Preparing to unpack .../07-libapparmor1_3.0.8-3_amd64.deb ...
Unpacking libapparmor1:amd64 (3.0.8-3) ...
Selecting previously unselected package libip4tc2:amd64.
Preparing to unpack .../08-libip4tc2_1.8.9-2_amd64.deb ...
Unpacking libip4tc2:amd64 (1.8.9-2) ...
Selecting previously unselected package libsystemd-shared:amd64.
Preparing to unpack .../09-libsystemd-shared_252.22-1~deb12u1_amd64.deb ...
Unpacking libsystemd-shared:amd64 (252.22-1~deb12u1) ...
Selecting previously unselected package systemd.
Preparing to unpack .../10-systemd_252.22-1~deb12u1_amd64.deb ...
Unpacking systemd (252.22-1~deb12u1) ...
Selecting previously unselected package libdbus-1-3:amd64.
Preparing to unpack .../11-libdbus-1-3_1.14.10-1~deb12u1_amd64.deb ...
Unpacking libdbus-1-3:amd64 (1.14.10-1~deb12u1) ...
Selecting previously unselected package dbus-bin.
Preparing to unpack .../12-dbus-bin_1.14.10-1~deb12u1_amd64.deb ...
Unpacking dbus-bin (1.14.10-1~deb12u1) ...
Selecting previously unselected package dbus-session-bus-common.
Preparing to unpack .../13-dbus-session-bus-common_1.14.10-1~deb12u1_all.deb ...
Unpacking dbus-session-bus-common (1.14.10-1~deb12u1) ...
Selecting previously unselected package libexpat1:amd64.
Preparing to unpack .../14-libexpat1_2.5.0-1_amd64.deb ...
Unpacking libexpat1:amd64 (2.5.0-1) ...
Selecting previously unselected package dbus-daemon.
Preparing to unpack .../15-dbus-daemon_1.14.10-1~deb12u1_amd64.deb ...
Unpacking dbus-daemon (1.14.10-1~deb12u1) ...
Selecting previously unselected package dbus-system-bus-common.
Preparing to unpack .../16-dbus-system-bus-common_1.14.10-1~deb12u1_all.deb ...
Unpacking dbus-system-bus-common (1.14.10-1~deb12u1) ...
Selecting previously unselected package dbus.
Preparing to unpack .../17-dbus_1.14.10-1~deb12u1_amd64.deb ...
Unpacking dbus (1.14.10-1~deb12u1) ...
Selecting previously unselected package systemd-timesyncd.
Preparing to unpack .../18-systemd-timesyncd_252.22-1~deb12u1_amd64.deb ...
Unpacking systemd-timesyncd (252.22-1~deb12u1) ...
Selecting previously unselected package libsensors-config.
Preparing to unpack .../19-libsensors-config_1%3a3.6.0-7.1_all.deb ...
Unpacking libsensors-config (1:3.6.0-7.1) ...
Selecting previously unselected package libsensors5:amd64.
Preparing to unpack .../20-libsensors5_1%3a3.6.0-7.1_amd64.deb ...
Unpacking libsensors5:amd64 (1:3.6.0-7.1) ...
Selecting previously unselected package postgresql-client-14.
Preparing to unpack .../21-postgresql-client-14_14.12-1.pgdg120+1_amd64.deb ...
Unpacking postgresql-client-14 (14.12-1.pgdg120+1) ...
Selecting previously unselected package postgresql-14.
Preparing to unpack .../22-postgresql-14_14.12-1.pgdg120+1_amd64.deb ...
Unpacking postgresql-14 (14.12-1.pgdg120+1) ...
Selecting previously unselected package sysstat.
Preparing to unpack .../23-sysstat_12.6.1-1_amd64.deb ...
Unpacking sysstat (12.6.1-1) ...
Setting up libip4tc2:amd64 (1.8.9-2) ...
Setting up libexpat1:amd64 (2.5.0-1) ...
Setting up libapparmor1:amd64 (3.0.8-3) ...
Setting up libargon2-1:amd64 (0~20171227-0.3+deb12u1) ...
Setting up libsensors-config (1:3.6.0-7.1) ...
Setting up postgresql-client-14 (14.12-1.pgdg120+1) ...
Setting up libdbus-1-3:amd64 (1.14.10-1~deb12u1) ...
Setting up libsensors5:amd64 (1:3.6.0-7.1) ...
Setting up libfdisk1:amd64 (2.38.1-5+deb12u1) ...
Setting up dbus-session-bus-common (1.14.10-1~deb12u1) ...
Setting up dbus-system-bus-common (1.14.10-1~deb12u1) ...
Setting up libjson-c5:amd64 (0.16-2) ...
Setting up sysstat (12.6.1-1) ...
debconf: unable to initialize frontend: Dialog
debconf: (No usable dialog-like program is installed, so the dialog based frontend cannot be used. at /usr/share/perl5/Debconf/FrontEnd/Dialog.pm line 78.)
debconf: falling back to frontend: Readline

Creating config file /etc/default/sysstat with new version
update-alternatives: using /usr/bin/sar.sysstat to provide /usr/bin/sar (sar) in auto mode
update-alternatives: warning: skip creation of /usr/share/man/man1/sar.1.gz because associated file /usr/share/man/man1/sar.sysstat.1.gz (of link group sar) doesn't exist
Created symlink /etc/systemd/system/sysstat.service.wants/sysstat-collect.timer → /lib/systemd/system/sysstat-collect.timer.
Created symlink /etc/systemd/system/sysstat.service.wants/sysstat-summary.timer → /lib/systemd/system/sysstat-summary.timer.
Created symlink /etc/systemd/system/multi-user.target.wants/sysstat.service → /lib/systemd/system/sysstat.service.
Setting up dbus-bin (1.14.10-1~deb12u1) ...
Setting up libkmod2:amd64 (30+20221128-1) ...
Setting up postgresql-14 (14.12-1.pgdg120+1) ...
debconf: unable to initialize frontend: Dialog
debconf: (No usable dialog-like program is installed, so the dialog based frontend cannot be used. at /usr/share/perl5/Debconf/FrontEnd/Dialog.pm line 78.)
debconf: falling back to frontend: Readline
invoke-rc.d: could not determine current runlevel
invoke-rc.d: policy-rc.d denied execution of start.
Setting up dbus-daemon (1.14.10-1~deb12u1) ...
Setting up dbus (1.14.10-1~deb12u1) ...
invoke-rc.d: could not determine current runlevel
invoke-rc.d: policy-rc.d denied execution of start.
Setting up libsystemd-shared:amd64 (252.22-1~deb12u1) ...
Setting up libdevmapper1.02.1:amd64 (2:1.02.185-2) ...
Setting up dmsetup (2:1.02.185-2) ...
Setting up libcryptsetup12:amd64 (2:2.6.1-4~deb12u2) ...
Setting up systemd (252.22-1~deb12u1) ...
Created symlink /etc/systemd/system/getty.target.wants/getty@tty1.service → /lib/systemd/system/getty@.service.
Created symlink /etc/systemd/system/multi-user.target.wants/remote-fs.target → /lib/systemd/system/remote-fs.target.
Created symlink /etc/systemd/system/sysinit.target.wants/systemd-pstore.service → /lib/systemd/system/systemd-pstore.service.
Initializing machine ID from D-Bus machine ID.
Creating group 'systemd-journal' with GID 998.
Creating group 'systemd-network' with GID 997.
Creating user 'systemd-network' (systemd Network Management) with UID 997 and GID 997.
Setting up systemd-timesyncd (252.22-1~deb12u1) ...
Creating group 'systemd-timesync' with GID 996.
Creating user 'systemd-timesync' (systemd Time Synchronization) with UID 996 and GID 996.
Created symlink /etc/systemd/system/dbus-org.freedesktop.timesync1.service → /lib/systemd/system/systemd-timesyncd.service.
Created symlink /etc/systemd/system/sysinit.target.wants/systemd-timesyncd.service → /lib/systemd/system/systemd-timesyncd.service.
Processing triggers for libc-bin (2.36-9+deb12u7) ...
Processing triggers for postgresql-common (260.pgdg120+1) ...
debconf: unable to initialize frontend: Dialog
debconf: (No usable dialog-like program is installed, so the dialog based frontend cannot be used. at /usr/share/perl5/Debconf/FrontEnd/Dialog.pm line 78.)
debconf: falling back to frontend: Readline
Building PostgreSQL dictionaries from installed myspell/hunspell packages...
Removing obsolete dictionary files:

> stype pg_upgrade
pg_upgrade is /usr/lib/postgresql/15/bin/pg_upgrade
> /usr/lib/postgresql/15/bin/initdb -U cooluser --locale=en_US.utf8 --encoding=UTF-8 -D /var/lib/postgresql/data15
The files belonging to this database system will be owned by user "postgres".
This user must also own the server process.

The database cluster will be initialized with locale "en_US.utf8".
The default text search configuration will be set to "english".

Data page checksums are disabled.

creating directory /var/lib/postgresql/data15 ... ok
creating subdirectories ... ok
selecting dynamic shared memory implementation ... posix
selecting default max_connections ... 100
selecting default shared_buffers ... 128MB
selecting default time zone ... Etc/UTC
creating configuration files ... ok
running bootstrap script ... ok
performing post-bootstrap initialization ... ok
syncing data to disk ... ok

initdb: warning: enabling "trust" authentication for local connections
initdb: hint: You can change this by editing pg_hba.conf or using the option -A, or --auth-local and --auth-host, the next time you run initdb.

Success. You can now start the database server using:

    /usr/lib/postgresql/15/bin/pg_ctl -D /var/lib/postgresql/data15 -l logfile start



> /usr/lib/postgresql/15/bin/pg_upgrade -d /var/lib/postgresql/data -D /var/lib/postgresql/data15 -b /usr/lib/postgresql/14/bin/ -B /usr/lib/postgresql/15/bin -U cooluser
Performing Consistency Checks
-----------------------------
Checking cluster versions                                   ok
Checking database user is the install user                  ok
Checking database connection settings                       ok
Checking for prepared transactions                          ok
Checking for system-defined composite types in user tables  ok
Checking for reg* data types in user tables                 ok
Checking for contrib/isn with bigint-passing mismatch       ok
Creating dump of global objects                             ok
Creating dump of database schemas                           
                                                            ok
Checking for presence of required libraries                 ok
Checking database user is the install user                  ok
Checking for prepared transactions                          ok
Checking for new cluster tablespace directories             ok

If pg_upgrade fails after this point, you must re-initdb the
new cluster before continuing.

Performing Upgrade
Analyzing all rows in the new cluster                       ok
Freezing all rows in the new cluster                        ok
Deleting files from new pg_xact                             ok
Copying old pg_xact to new server                           ok
Setting oldest XID for new cluster                          ok
Setting next transaction ID and epoch for new cluster       ok
Deleting files from new pg_multixact/offsets                ok
Copying old pg_multixact/offsets to new server              ok
Deleting files from new pg_multixact/members                ok
Copying old pg_multixact/members to new server              ok
Setting next multixact ID and offset for new cluster        ok
Resetting WAL archives                                      ok
Setting frozenxid and minmxid counters in new cluster       ok
Restoring global objects in the new cluster                 ok
Restoring database schemas in the new cluster               
                                                            ok
Copying user relation files                                 
                                                            ok
Setting next OID for new cluster                            ok
Sync data directory to disk                                 ok
Creating script to delete old cluster                       ok
Checking for extension updates                              ok

Upgrade Complete
----------------
Optimizer statistics are not transferred by pg_upgrade.
Once you start the new server, consider running:
    /usr/lib/postgresql/15/bin/vacuumdb -U cooluser --all --analyze-in-stages

Running this script will delete the old cluster's data files:
    ./delete_old_cluster.sh

> cd /var/lib/postgresql/
> rm -rf ../data/*
> cp -rf * ../data/

> docker compose up -d
[+] Running 2/2
 ✔ Network postgres  Created                                                                                       0.1s 
 ✔ Container pgdb    Started                                                                                       0.3s 
> docker exec -it pgdb bash
> su - postgres 
> /usr/lib/postgresql/15/bin/vacuumdb -U cooluser --all --analyze-in-stages 
vacuumdb: processing database "otus-pg": Generating minimal optimizer statistics (1 target)
vacuumdb: processing database "postgres": Generating minimal optimizer statistics (1 target)
vacuumdb: processing database "template1": Generating minimal optimizer statistics (1 target)
vacuumdb: processing database "otus-pg": Generating medium optimizer statistics (10 targets)
vacuumdb: processing database "postgres": Generating medium optimizer statistics (10 targets)
vacuumdb: processing database "template1": Generating medium optimizer statistics (10 targets)
vacuumdb: processing database "otus-pg": Generating default (full) optimizer statistics
vacuumdb: processing database "postgres": Generating default (full) optimizer statistics
vacuumdb: processing database "template1": Generating default (full) optimizer statistics

> psql -h 127.0.0.1 -p 5000 -U cooluser otus-pg
Password for user cooluser: 
psql (14.12 (Ubuntu 14.12-1.pgdg22.04+1), server 15.7 (Debian 15.7-1.pgdg120+1))
WARNING: psql major version 14, server major version 15.
         Some psql features might not work.
Type "help" for help.

persons         persons_id_seq  pg_catalog.     pg_toast.       public.         
otus-pg=# select * from persons;
 id | first_name | second_name 
----+------------+-------------
  1 | ivan       | ivanov
  2 | petr       | petrov
(2 rows)

Алилуя теперь у нас 15 postgres. Мы немного попортили тонкий слой контейнера. Вернем все обратно и проверим что все работает
```sh
> docker compose down 
[+] Running 2/2
 ✔ Container pgdb    Removed                                                                                       0.3s 
 ✔ Network postgres  Removed                                                                                       0.3s 
> docker compose up -d
[+] Running 2/2
 ✔ Network postgres  Created                                                                                       0.1s 
 ✔ Container pgdb    Started                                                                                       0.3s 
> psql -h 127.0.0.1 -p 5000 -U cooluser otus-pg
Password for user cooluser: 
psql (14.12 (Ubuntu 14.12-1.pgdg22.04+1), server 15.7 (Debian 15.7-1.pgdg120+1))
WARNING: psql major version 14, server major version 15.
         Some psql features might not work.
Type "help" for help.
```
```sql
otus-pg=# select * from persons;
 id | first_name | second_name 
----+------------+-------------
  1 | ivan       | ivanov
  2 | petr       | petrov
(2 rows)
```
Все на месте )
