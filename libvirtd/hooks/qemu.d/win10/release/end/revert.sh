#!/bin/bash
# Helpful to read output when debugging
set -x

# Load variables we defined
source "/etc/libvirt/hooks/kvm.conf"

# Unload VFIO Kernel Modules
modprobe -r vfio_pci
modprobe -r vfio_iommu_type1
modprobe -r vfio

# Reattach the GPU
virsh nodedev-reattach $VIRSH_GPU_VIDEO
virsh nodedev-reattach $VIRSH_GPU_AUDIO

# Rebind VT consoles
echo 1 > /sys/class/vtconsole/vtcon0/bind
echo 1 > /sys/class/vtconsole/vtcon1/bind

# Bind EFI-Framebuffer
#echo "efi-framebuffer.0" > /sys/bus/platform/drivers/efi-framebuffer/bind

# Avoid a Race condition by waiting a couple of seconds. This can be calibrated to be shorter or longer if required for your system
sleep 3

# Load all Radeon drivers
modprobe amdgpu
#modprobe gpu_sched
#modprobe ttm
#modprobe drm_kms_helper
#modprobe i2c_algo_bit
#modprobe drm
modprobe snd_hda_intel

# Start Display Manager
systemctl start display-manager.service
