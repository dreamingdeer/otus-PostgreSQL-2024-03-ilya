#!/bin/sh
qemu-system-x86_64 \
-machine accel=kvm:tcg \
-cpu host \
-smp 2 \
-m 4g \
-nographic \
-device virtio-scsi-pci,id=scsi \
-device scsi-hd,drive=hd \
-drive if=none,id=hd,file=noble.img \
-netdev user,id=net0,hostfwd=tcp::10023-:22 \
-device e1000,netdev=net0 \
-smbios type=1,serial=ds='nocloud;s=http://10.0.2.2:8000/'
