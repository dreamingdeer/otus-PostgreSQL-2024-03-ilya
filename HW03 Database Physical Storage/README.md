## Установка и настройка PostgreSQL

Исходное [домашнее задание](./HW03.md "Дз 03")

создайте виртуальную машину c Ubuntu 20.04/22.04 LTS в GCE/ЯО/Virtual Box/докере
поставьте на нее PostgreSQL 15 через sudo apt

Создадим и установим PostgreSQL 15 способом с помощью terraform и [cloud-init](./terraform/pg-meta.yml)

```sh
terraform init
terraform plan -var-file ../../terraform.tfvars
set -x TF_VAR_iam_token $(yc iam create-token)
terraform apply  -var-file ../../terraform.tfvars


Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
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
      + filename             = "/home/ilyaz/.ssh/config.d/pg.conf"
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
      + source_family   = "ubuntu-2204-lts"
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
          + "user-data" = (sensitive value)
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
      + folder_id                 = (sensitive value)
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
      + folder_id      = (sensitive value)
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
      + source_family   = "ubuntu-2204-lts"
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
          + "user-data" = (sensitive value)
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
          + cores         = 2
          + memory        = 4
        }

      + scheduling_policy {
          + preemptible = true
        }
    }

  # module.pg01-diskmig.yandex_compute_image.ubuntu will be created
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
      + source_family   = "ubuntu-2204-lts"
      + source_image    = (known after apply)
      + source_snapshot = (known after apply)
      + source_url      = (known after apply)
      + status          = (known after apply)
    }

  # module.pg01-diskmig.yandex_compute_instance.vm_ubuntu_lts[0] will be created
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
          + "user-data" = (sensitive value)
        }
      + name                      = "pgbpk-0"
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
          + cores         = 2
          + memory        = 4
        }

      + scheduling_policy {
          + preemptible = true
        }
    }

Plan: 11 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + base_image_id        = (known after apply)
  + external_ips_bastion = [
      + (known after apply),
    ]
  + internal_ips_bastion = [
      + (known after apply),
    ]
  + pg_bkp               = [
      + (known after apply),
    ]
  + pg_main              = [
      + (known after apply),
    ]

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes     

module.local-nat.yandex_vpc_gateway.nat_gateway: Creating...
module.local-nat.yandex_vpc_network.default: Creating...
module.local-nat.yandex_vpc_gateway.nat_gateway: Creation complete after 1s [id=enpkq10ke8fj2nbb3kbp]
module.local-nat.yandex_vpc_network.default: Creation complete after 3s [id=enppjg17bp859up3a0fj]
module.local-nat.yandex_vpc_route_table.rt: Creating...
module.local-nat.yandex_vpc_route_table.rt: Creation complete after 1s [id=enpalov7ier1p94fm86f]
module.local-nat.yandex_vpc_subnet.pg-subnet: Creating...
module.local-nat.yandex_vpc_subnet.pg-subnet: Creation complete after 1s [id=fl87i8o0i6hat31htn7t]
module.bastion.yandex_compute_image.ubuntu: Creating...
module.bastion.yandex_compute_image.ubuntu: Still creating... [10s elapsed]
module.bastion.yandex_compute_image.ubuntu: Creation complete after 13s [id=fd8q49jf23c969a2lg9f]
module.bastion.yandex_compute_instance.vm_ubuntu_lts[0]: Creating...
module.bastion.yandex_compute_instance.vm_ubuntu_lts[0]: Still creating... [10s elapsed]
module.bastion.yandex_compute_instance.vm_ubuntu_lts[0]: Still creating... [20s elapsed]
module.bastion.yandex_compute_instance.vm_ubuntu_lts[0]: Still creating... [30s elapsed]
module.bastion.yandex_compute_instance.vm_ubuntu_lts[0]: Still creating... [40s elapsed]
module.bastion.yandex_compute_instance.vm_ubuntu_lts[0]: Still creating... [50s elapsed]
module.bastion.yandex_compute_instance.vm_ubuntu_lts[0]: Still creating... [1m0s elapsed]
module.bastion.yandex_compute_instance.vm_ubuntu_lts[0]: Still creating... [1m10s elapsed]
module.bastion.yandex_compute_instance.vm_ubuntu_lts[0]: Still creating... [1m20s elapsed]
module.bastion.yandex_compute_instance.vm_ubuntu_lts[0]: Creation complete after 1m25s [id=fv4h1nd9foe7cr5b1m9f]
module.pg01-diskmig.yandex_compute_image.ubuntu: Creating...
module.pg01.yandex_compute_image.ubuntu: Creating...
local_file.ssh_configs: Creating...
local_file.ssh_configs: Creation complete after 0s [id=39babe64205fa1fb989b94508f80286c97247e63]
module.pg01.yandex_compute_image.ubuntu: Still creating... [10s elapsed]
module.pg01-diskmig.yandex_compute_image.ubuntu: Still creating... [10s elapsed]
module.pg01-diskmig.yandex_compute_image.ubuntu: Creation complete after 13s [id=fd8j331206cru69qjnll]
module.pg01.yandex_compute_image.ubuntu: Creation complete after 13s [id=fd8tfl5o81rk7c7cletf]
module.pg01.yandex_compute_instance.vm_ubuntu_lts[0]: Creating...
module.pg01-diskmig.yandex_compute_instance.vm_ubuntu_lts[0]: Creating...
module.pg01.yandex_compute_instance.vm_ubuntu_lts[0]: Still creating... [10s elapsed]
module.pg01-diskmig.yandex_compute_instance.vm_ubuntu_lts[0]: Still creating... [10s elapsed]
module.pg01-diskmig.yandex_compute_instance.vm_ubuntu_lts[0]: Still creating... [20s elapsed]
module.pg01.yandex_compute_instance.vm_ubuntu_lts[0]: Still creating... [20s elapsed]
module.pg01.yandex_compute_instance.vm_ubuntu_lts[0]: Still creating... [30s elapsed]
module.pg01-diskmig.yandex_compute_instance.vm_ubuntu_lts[0]: Still creating... [30s elapsed]
module.pg01.yandex_compute_instance.vm_ubuntu_lts[0]: Still creating... [40s elapsed]
module.pg01-diskmig.yandex_compute_instance.vm_ubuntu_lts[0]: Still creating... [40s elapsed]
module.pg01.yandex_compute_instance.vm_ubuntu_lts[0]: Still creating... [50s elapsed]
module.pg01-diskmig.yandex_compute_instance.vm_ubuntu_lts[0]: Still creating... [50s elapsed]
module.pg01.yandex_compute_instance.vm_ubuntu_lts[0]: Still creating... [1m0s elapsed]
module.pg01-diskmig.yandex_compute_instance.vm_ubuntu_lts[0]: Still creating... [1m0s elapsed]
module.pg01.yandex_compute_instance.vm_ubuntu_lts[0]: Still creating... [1m10s elapsed]
module.pg01-diskmig.yandex_compute_instance.vm_ubuntu_lts[0]: Still creating... [1m10s elapsed]
module.pg01-diskmig.yandex_compute_instance.vm_ubuntu_lts[0]: Creation complete after 1m13s [id=fv41r4lde4cj544m8ibu]
module.pg01.yandex_compute_instance.vm_ubuntu_lts[0]: Creation complete after 1m18s [id=fv4ehmdgtvnmjugvvpg4]

Apply complete! Resources: 11 added, 0 changed, 0 destroyed.

Outputs:

base_image_id = "fd8tfl5o81rk7c7cletf"
external_ips_bastion = [
  "158.160.171.12",
]
internal_ips_bastion = [
  "10.128.0.21",
]
pg_bkp = [
  "10.128.0.20",
]
pg_main = [
  "10.128.0.11",
]
```
проверьте что кластер запущен через sudo -u postgres pg_lsclusters

```sh
sudo -i -u postgres pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
15  main    5432 online postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log
```

зайдите из под пользователя postgres в psql и сделайте произвольную таблицу с произвольным содержимым

```sh
ssh 10.128.0.11
Warning: Permanently added '158.160.171.12' (ED25519) to the list of known hosts.
Warning: Permanently added '10.128.0.11' (ED25519) to the list of known hosts.
Welcome to Ubuntu 22.04.4 LTS (GNU/Linux 5.15.0-107-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

 System information as of Wed Jun  5 07:51:39 AM UTC 2024

  System load:  0.1                Processes:             138
  Usage of /:   14.5% of 29.44GB   Users logged in:       0
  Memory usage: 6%                 IPv4 address for eth0: 10.128.0.11
  Swap usage:   0%


Expanded Security Maintenance for Applications is not enabled.

1 update can be applied immediately.
1 of these updates is a standard security update.
To see these additional updates run: apt list --upgradable

Enable ESM Apps to receive additional future security updates.
See https://ubuntu.com/esm or run: sudo pro status



The programs included with the Ubuntu system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Ubuntu comes with ABSOLUTELY NO WARRANTY, to the extent permitted by
applicable law.

To run a command as administrator (user "root"), use "sudo <command>".
See "man sudo_root" for details.
```

```sh
sudo -i -u postgres psql
psql (15.7 (Ubuntu 15.7-1.pgdg22.04+1))
Type "help" for help.

postgres=# 
```
postgres=# create table test(c1 text);
```sql
postgres=# create table test(c1 text);
CREATE TABLE
postgres=# 
```
postgres=# insert into test values('1'); - сделаем немного по интереснее  
\q

```sql
postgres=# insert into test(c1) select i::text from generate_series(100, 105) AS t(i) RETURNING c1;
 c1  
-----
 100
 101
 102
 103
 104
 105
(6 rows)

INSERT 0 6
postgres=# \q
```
остановите postgres например через sudo -u postgres pg_ctlcluster 15 main stop
```sh
> sudo -i -u postgres pg_ctlcluster 15 main stop
Warning: stopping the cluster using pg_ctlcluster will mark the systemd unit as failed. Consider using systemctl:
  sudo systemctl stop postgresql@15-main

> sudo -i -u postgres pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
15  main    5432 down   postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log
```
создайте новый диск к ВМ размером 10GB
```sh
> yc compute disk create --size 10 
done (11s)
id: x
folder_id: x
created_at: "2024-06-05T08:20:32Z"
type_id: network-hdd
zone_id: ru-central1-d
size: "10737418240"
block_size: "4096"
status: READY
disk_placement_policy: {}
```

добавьте свеже-созданный диск к виртуальной машине - надо зайти в режим ее редактирования и дальше выбрать пункт attach existing disk
проинициализируйте диск согласно инструкции и подмонтировать файловую систему, только не забывайте менять имя диска на актуальное, в вашем случае это скорее всего будет /dev/sdb - https://www.digitalocean.com/community/tutorials/how-to-partition-and-format-storage-devices-in-linux
перезагрузите инстанс и убедитесь, что диск остается примонтированным (если не так смотрим в сторону fstab)

Созданый диск:
![created disk](./hdddistk.png)

Подключенный к виртуалке
![created disk](./attached_hdd.png)

```sh
> sudo dmesg | grep vdb
[ 2654.683851] virtio_blk virtio3: [vdb] 20971520 512-byte logical blocks (10.7 GB/10.0 GiB)

> lsblk -tfip
NAME        ALIGNMENT MIN-IO OPT-IO PHY-SEC LOG-SEC ROTA SCHED RQ-SIZE  RA WSAME FSTYPE   FSVER LABEL UUID                                 FSAVAIL FSUSE% MOUNTPOINTS
/dev/loop0          0    512      0     512     512    1 none      128 128    0B squashfs 4.0                                                    0   100% /snap/core20/1822
/dev/loop1          0    512      0     512     512    1 none      128 128    0B squashfs 4.0                                                    0   100% /snap/core20/2318
/dev/loop2          0    512      0     512     512    1 none      128 128    0B squashfs 4.0                                                    0   100% /snap/lxd/24322
/dev/loop3          0    512      0     512     512    1 none      128 128    0B squashfs 4.0                                                    0   100% /snap/snapd/18357
/dev/loop4          0    512      0     512     512    1 none      128 128    0B squashfs 4.0                                                    0   100% /snap/snapd/21759
/dev/loop5          0    512      0     512     512    1 none      128 128    0B squashfs 4.0                                                    0   100% /snap/lxd/28373
/dev/vda            0   4096      0    4096     512    1 none      128 128    0B                                                                          
|-/dev/vda1         0   4096      0    4096     512    1 none      128 128    0B                                                                          
`-/dev/vda2         0   4096      0    4096     512    1 none      128 128    0B ext4     1.0         ed465c6e-049a-41c6-8e0b-c8da348a3577   23.9G    14% /
/dev/vdb            0   4096      0    4096     512    1 none      128 128    0B                                                                          

> sudo mkfs.xfs -L data /dev/vdb 
meta-data=/dev/vdb               isize=512    agcount=4, agsize=655360 blks
         =                       sectsz=4096  attr=2, projid32bit=1
         =                       crc=1        finobt=1, sparse=1, rmapbt=0
         =                       reflink=1    bigtime=0 inobtcount=0
data     =                       bsize=4096   blocks=2621440, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0, ftype=1
log      =internal log           bsize=4096   blocks=2560, version=2
         =                       sectsz=4096  sunit=1 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0

> sudo blkid /dev/vdb
/dev/vdb: LABEL="data" UUID="32a18862-bc34-41b5-b846-e64e28a9bba1" BLOCK_SIZE="4096" TYPE="xfs"
> sudo mkdir /mnt/data
echo "/dev/disk/by-uuid/32a18862-bc34-41b5-b846-e64e28a9bba1 /mnt/data xfs defaults 0 1" | sudo tee -a /etc/fstab
> sudo mount -a
> df -h /mnt/data/
Filesystem      Size  Used Avail Use% Mounted on
/dev/vdb         10G  104M  9.9G   2% /mnt/data
> sudo reboot
Connection to 10.128.0.11 closed by remote host.
Connection to 10.128.0.11 closed.
```
Проверим что диск на месте:
```sh
> ssh 10.128.0.11
Warning: Permanently added '158.160.171.12' (ED25519) to the list of known hosts.
Warning: Permanently added '10.128.0.11' (ED25519) to the list of known hosts.
Welcome to Ubuntu 22.04.4 LTS (GNU/Linux 5.15.0-107-generic x86_64)
<--- CUT --->
df -h /mnt/data/
Filesystem      Size  Used Avail Use% Mounted on
/dev/vdb         10G  104M  9.9G   2% /mnt/data
```

сделайте пользователя postgres владельцем /mnt/data - chown -R postgres:postgres /mnt/data/
```sh
> sudo chown -R postgres. /mnt/data
> ls -lh /mnt/
total 0
drwxr-xr-x 2 postgres postgres 6 Jun  5 08:48 data
```

перенесите содержимое /var/lib/postgres/15 в /mnt/data - mv /var/lib/postgresql/15/mnt/data
попытайтесь запустить кластер - sudo -u postgres pg_ctlcluster 15 main start

```sh
> pg_lsclusters 
Ver Cluster Port Status Owner    Data directory              Log file
15  main    5432 online postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log
> sudo systemctl status postgresql@15-main.service 
● postgresql@15-main.service - PostgreSQL Cluster 15-main
     Loaded: loaded (/lib/systemd/system/postgresql@.service; enabled-runtime; vendor preset: enabled)
     Active: active (running) since Wed 2024-06-05 09:55:47 UTC; 7min ago
    Process: 727 ExecStart=/usr/bin/pg_ctlcluster --skip-systemctl-redirect 15-main start (code=exited, status=0/SUCCESS)
   Main PID: 835 (postgres)
      Tasks: 6 (limit: 4556)
     Memory: 37.3M
        CPU: 232ms
     CGroup: /system.slice/system-postgresql.slice/postgresql@15-main.service
             ├─835 /usr/lib/postgresql/15/bin/postgres -D /var/lib/postgresql/15/main -c config_file=/etc/postgresql/15/main/postgresql.conf
             ├─836 "postgres: 15/main: checkpointer 
             ├─837 "postgres: 15/main: background writer 
             ├─839 "postgres: 15/main: walwriter 
             ├─840 "postgres: 15/main: autovacuum launcher 
             └─841 "postgres: 15/main: logical replication launcher 

Jun 05 09:55:42 fv4ehmdgtvnmjugvvpg4 systemd[1]: Starting PostgreSQL Cluster 15-main...
Jun 05 09:55:47 fv4ehmdgtvnmjugvvpg4 systemd[1]: Started PostgreSQL Cluster 15-main.
> sudo systemctl stop postgresql@15-main.service
> pg_lsclusters 
Ver Cluster Port Status Owner    Data directory              Log file
15  main    5432 down   postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log
> sudo mv /var/lib/postgresql/15/main /mnt/data
sudo systemctl start postgresql@15-main.service
Job for postgresql@15-main.service failed because the service did not take the steps required by its unit configuration.
See "systemctl status postgresql@15-main.service" and "journalctl -xeu postgresql@15-main.service" for details.

> sudo systemctl status postgresql@15-main.service
× postgresql@15-main.service - PostgreSQL Cluster 15-main
     Loaded: loaded (/lib/systemd/system/postgresql@.service; enabled-runtime; vendor preset: enabled)
     Active: failed (Result: protocol) since Wed 2024-06-05 10:06:48 UTC; 28s ago
    Process: 1528 ExecStart=/usr/bin/pg_ctlcluster --skip-systemctl-redirect 15-main start (code=exited, status=1/FAILURE)
        CPU: 39ms

Jun 05 10:06:48 fv4ehmdgtvnmjugvvpg4 systemd[1]: Starting PostgreSQL Cluster 15-main...
Jun 05 10:06:48 fv4ehmdgtvnmjugvvpg4 postgresql@15-main[1528]: Error: /var/lib/postgresql/15/main is not accessible or does not exist
Jun 05 10:06:48 fv4ehmdgtvnmjugvvpg4 systemd[1]: postgresql@15-main.service: Can't open PID file /run/postgresql/15-main.pid (yet?) after start: Operation not permitted
Jun 05 10:06:48 fv4ehmdgtvnmjugvvpg4 systemd[1]: postgresql@15-main.service: Failed with result 'protocol'.
Jun 05 10:06:48 fv4ehmdgtvnmjugvvpg4 systemd[1]: Failed to start PostgreSQL Cluster 15-main.
```
напишите получилось или нет и почему
```
Конечно не получилось :) Потому как данные кластера были перенесены в другое место
```
задание: найти конфигурационный параметр в файлах раположенных в /etc/postgresql/15/main который надо поменять и поменяйте его
```sh
Неправильно ты, дядя Федор бутерброд ешь
> pg_conftool 15 main show all
pg_conftool 15 main show all
cluster_name = '15/main'
data_directory = '/var/lib/postgresql/15/main'
datestyle = 'iso, mdy'
default_text_search_config = 'pg_catalog.english'
dynamic_shared_memory_type = posix
external_pid_file = '/var/run/postgresql/15-main.pid'
hba_file = '/etc/postgresql/15/main/pg_hba.conf'
ident_file = '/etc/postgresql/15/main/pg_ident.conf'
lc_messages = 'en_US.UTF-8'
lc_monetary = 'en_US.UTF-8'
lc_numeric = 'en_US.UTF-8'
lc_time = 'en_US.UTF-8'
log_line_prefix = '%m [%p] %q%u@%d '
log_timezone = 'Etc/UTC'
max_connections = 100
max_wal_size = 1GB
min_wal_size = 80MB
port = 5432
shared_buffers = 128MB
ssl = on
ssl_cert_file = '/etc/ssl/certs/ssl-cert-snakeoil.pem'
ssl_key_file = '/etc/ssl/private/ssl-cert-snakeoil.key'
timezone = 'Etc/UTC'
unix_socket_directories = '/var/run/postgresql'

> sudo -i -u postgres pg_conftool 15 main set data_directory /mnt/data/main
> sudo -i -u postgres pg_conftool 15 main show data_directory
data_directory = '/mnt/data/main'
```

напишите что и почему поменяли
попытайтесь запустить кластер - sudo -u postgres pg_ctlcluster 15 main start

```
так как данные перемещены нужно поменять data_directory который располагается на диске /mnt/data
```

```sh
> sudo systemctl start postgresql@15-main.service
> pg_lsclusters 
Ver Cluster Port Status Owner    Data directory Log file
15  main    5432 online postgres /mnt/data/main /var/log/postgresql/postgresql-15-main.log
> sudo -i -u postgres psql
psql (15.7 (Ubuntu 15.7-1.pgdg22.04+1))
Type "help" for help.

postgres=# 
```
напишите получилось или нет и почему
```
Успешный успех! -) потому как данные доступны по новому пути и постгресс счастив
```
зайдите через через psql и проверьте содержимое ранее созданной таблицы
```sh
> sudo -i -u postgres psql -c "select * from test;"
 c1  
-----
 100
 101
 102
 103
 104
 105
(6 rows)
```
задание со звездочкой *: не удаляя существующий инстанс ВМ сделайте новый, поставьте на его PostgreSQL, удалите файлы с данными из /var/lib/postgres, перемонтируйте внешний диск который сделали ранее от первой виртуальной машины ко второй и запустите PostgreSQL на второй машине так чтобы он работал с данными на внешнем диске, расскажите как вы это сделали и что в итоге получилось.

```sh
> yc compute instance list
+----------------------+------------------+---------------+---------+----------------+-------------+
|          ID          |       NAME       |    ZONE ID    | STATUS  |  EXTERNAL IP   | INTERNAL IP |
+----------------------+------------------+---------------+---------+----------------+-------------+
| fv41r4lde4cj544m8ibu | pgbpk-0          | ru-central1-d | RUNNING |                | 10.128.0.20 |
| fv4ehmdgtvnmjugvvpg4 | pg-0             | ru-central1-d | RUNNING |                | 10.128.0.11 |
| fv4h1nd9foe7cr5b1m9f | bastion-for-pg-0 | ru-central1-d | RUNNING | 158.160.171.12 | 10.128.0.21 |
+----------------------+------------------+---------------+---------+----------------+-------------+
> yc compute instance stop pg-0
done (23s)
> yc compute instance get pg-0
id: fv4ehmdgtvnmjugvvpg4
folder_id: 
created_at: "2024-06-05T07:43:07Z"
name: pg-0
zone_id: ru-central1-d
platform_id: standard-v3
resources:
  memory: "4294967296"
  cores: "2"
  core_fraction: "20"
status: STOPPED
metadata_options:
  gce_http_endpoint: ENABLED
  aws_v1_http_endpoint: ENABLED
  gce_http_token: ENABLED
  aws_v1_http_token: DISABLED
boot_disk:
  mode: READ_WRITE
  device_name: fv4pjtibqb2p7eaveuh7
  auto_delete: true
  disk_id: fv4pjtibqb2p7eaveuh7
secondary_disks:
  - mode: READ_WRITE
    device_name: hddb
    disk_id: fv4t363lpes0u97u7ju3
network_interfaces:
  - index: "0"
    mac_address: d0:0d:e8:d9:b0:ef
    subnet_id: fl87i8o0i6hat31htn7t
    primary_v4_address:
      address: 10.128.0.11
serial_port_settings:
  ssh_authorization: INSTANCE_METADATA
gpu_settings: {}
fqdn: fv4ehmdgtvnmjugvvpg4.auto.internal
scheduling_policy:
  preemptible: true
network_settings:
  type: STANDARD
placement_policy: {}

> yc  compute instance detach-disk pg-0 --disk-id fv4t363lpes0u97u7ju3
done (3s)
id: fv4ehmdgtvnmjugvvpg4
folder_id: 
created_at: "2024-06-05T07:43:07Z"
name: pg-0
zone_id: ru-central1-d
platform_id: standard-v3
resources:
  memory: "4294967296"
  cores: "2"
  core_fraction: "20"
status: STOPPED
metadata_options:
  gce_http_endpoint: ENABLED
  aws_v1_http_endpoint: ENABLED
  gce_http_token: ENABLED
  aws_v1_http_token: DISABLED
boot_disk:
  mode: READ_WRITE
  device_name: fv4pjtibqb2p7eaveuh7
  auto_delete: true
  disk_id: fv4pjtibqb2p7eaveuh7
network_interfaces:
  - index: "0"
    mac_address: d0:0d:e8:d9:b0:ef
    subnet_id: fl87i8o0i6hat31htn7t
    primary_v4_address:
      address: 10.128.0.11
serial_port_settings:
  ssh_authorization: INSTANCE_METADATA
gpu_settings: {}
fqdn: fv4ehmdgtvnmjugvvpg4.auto.internal
scheduling_policy:
  preemptible: true
network_settings:
  type: STANDARD
placement_policy: {}


> yc compute instance attach-disk pgbpk-0 --disk-id fv4t363lpes0u97u7ju3
done (12s)
id: fv41r4lde4cj544m8ibu
folder_id: b1glpcbkgqacq817e2k1
created_at: "2024-06-05T07:43:06Z"
name: pgbpk-0
zone_id: ru-central1-d
platform_id: standard-v3
resources:
  memory: "4294967296"
  cores: "2"
  core_fraction: "20"
status: RUNNING
metadata_options:
  gce_http_endpoint: ENABLED
  aws_v1_http_endpoint: ENABLED
  gce_http_token: ENABLED
  aws_v1_http_token: DISABLED
boot_disk:
  mode: READ_WRITE
  device_name: fv4r60jnj18714dq5h0j
  auto_delete: true
  disk_id: fv4r60jnj18714dq5h0j
secondary_disks:
  - mode: READ_WRITE
    device_name: fv4t363lpes0u97u7ju3
    disk_id: fv4t363lpes0u97u7ju3
network_interfaces:
  - index: "0"
    mac_address: d0:0d:1d:92:ad:71
    subnet_id: fl87i8o0i6hat31htn7t
    primary_v4_address:
      address: 10.128.0.20
serial_port_settings:
  ssh_authorization: INSTANCE_METADATA
gpu_settings: {}
fqdn: fv41r4lde4cj544m8ibu.auto.internal
scheduling_policy:
  preemptible: true
network_settings:
  type: STANDARD
placement_policy: {}

> yc compute instance list
+----------------------+------------------+---------------+---------+----------------+-------------+
|          ID          |       NAME       |    ZONE ID    | STATUS  |  EXTERNAL IP   | INTERNAL IP |
+----------------------+------------------+---------------+---------+----------------+-------------+
| fv41r4lde4cj544m8ibu | pgbpk-0          | ru-central1-d | RUNNING |                | 10.128.0.20 |
| fv4ehmdgtvnmjugvvpg4 | pg-0             | ru-central1-d | STOPPED |                | 10.128.0.11 |
| fv4h1nd9foe7cr5b1m9f | bastion-for-pg-0 | ru-central1-d | RUNNING | 158.160.171.12 | 10.128.0.21 |
+----------------------+------------------+---------------+---------+----------------+-------------+

> ssh 10.128.0.20
Warning: Permanently added '158.160.171.12' (ED25519) to the list of known hosts.
Warning: Permanently added '10.128.0.20' (ED25519) to the list of known hosts.
> pg_lsclusters 
Ver Cluster Port Status Owner    Data directory              Log file
15  main    5432 online postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log

> sudo blkid 
/dev/vda2: UUID="ed465c6e-049a-41c6-8e0b-c8da348a3577" BLOCK_SIZE="4096" TYPE="ext4" PARTUUID="8c548af8-0682-43e1-9da4-2db0a9f4935b"
/dev/loop1: TYPE="squashfs"
/dev/vdb: LABEL="data" UUID="32a18862-bc34-41b5-b846-e64e28a9bba1" BLOCK_SIZE="4096" TYPE="xfs"
/dev/loop4: TYPE="squashfs"
/dev/loop2: TYPE="squashfs"
/dev/loop0: TYPE="squashfs"
/dev/loop5: TYPE="squashfs"
/dev/vda1: PARTUUID="c66f751c-f027-41a2-ba00-3342a74eb0cb"
/dev/loop3: TYPE="squashfs"

> echo "/dev/disk/by-uuid/32a18862-bc34-41b5-b846-e64e28a9bba1 /mnt/data xfs defaults 0 1" | sudo tee -a /etc/fstab
/dev/disk/by-uuid/32a18862-bc34-41b5-b846-e64e28a9bba1 /mnt/data xfs defaults 0 1
> sudo mkdir /mnt/data
> sudo chown -R postgres. /mnt/data
> sudo mount -a
>  df -h /mnt/data
Filesystem      Size  Used Avail Use% Mounted on
/dev/vdb         10G  143M  9.9G   2% /mnt/data
> ls -l /mnt/data
total 4
drwx------ 19 postgres postgres 4096 Jun  5 10:38 main
> sudo -i -u postgres pg_conftool 15 main show data_directory
data_directory = '/var/lib/postgresql/15/main'
> sudo -i -u postgres psql -c "select * from test;"
ERROR:  relation "test" does not exist
LINE 1: select * from test;
                      ^

> sudo systemctl stop postgresql@15-main.service
> sudo -i -u postgres pg_conftool 15 main set data_directory /mnt/data/main
> sudo systemctl start postgresql@15-main.service
> pg_lsclusters 
Ver Cluster Port Status Owner    Data directory Log file
15  main    5432 online postgres /mnt/data/main /var/log/postgresql/postgresql-15-main.log
> sudo -i -u postgres psql -c "select * from test;"
 c1  
-----
 100
 101
 102
 103
 104
 105
(6 rows)
```
Изи все данные на месте ) Преберем за собой
> terraform destroy -var-file ../../terraform.tfvars
