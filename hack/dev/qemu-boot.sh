#!/bin/bash

set -e

if [[ $# -ne 1 ]]; then
  echo 1>&2 "Usage: $0 <machine config URL>"
  exit 3
fi

case $(uname -s) in
  LINUX*)
    ACCEL=kvm
    ;;

  Darwin*)
    ACCEL=hvf
    ;;
  *)
    exit 1
    ;;
esac

KERNEL="build/vmlinuz"
INITRD="build/initramfs.xz"
IMAGE="/tmp/rootfs.qcow2"
MACHINE_CONFIG="${1}"

qemu-img create -f qcow2 ${IMAGE} 8G

qemu-system-x86_64 \
    -m 2048 \
    -accel ${ACCEL},thread=multi \
    -cpu max \
    -smp 2 \
    -hda ${IMAGE} \
    -netdev user,id=talos,ipv4=on,net=10.254.0.0/24,dhcpstart=10.254.0.10,hostfwd=tcp::50000-:50000,hostname=master-1 \
    -device virtio-net,netdev=talos \
    -nographic \
    -serial mon:stdio \
    -no-reboot \
    -append "talos.platform=metal page_poison=1 slab_nomerge pti=on random.trust_cpu=on printk.devkmsg=on earlyprintk=serial,tty0,keep console=tty0 talos.userdata=${MACHINE_CONFIG}" \
    -kernel ${KERNEL} \
    -initrd ${INITRD}
