#!/bin/bash
# Helpful to read output when debugging
set -x

# Load variables we defined
source "/etc/libvirt/hooks/kvm.conf"

# Stop display manager
systemctl stop sddm.service

# Stop audio drivers
pulse_pid=$(pgrep -u nico pulseaudio)
pipewire_pid=$(pgrep -u nico pipewire-media)
kill $pulse_pid
kill $pipewire_pid

# Unbind VTconsoles
echo 0 > /sys/class/vtconsole/vtcon0/bind
echo 0 > /sys/class/vtconsole/vtcon1/bind

# Unbind EFI-Framebuffer
#echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/unbind

# Avoid a Race condition by waiting a couple of seconds. This can be calibrated to be shorter or longer if required for your system
sleep 3

# Unload all Radeon drivers
modprobe -r amdgpu
#modprobe -r gpu_sched
#modprobe -r ttm
#modprobe -r drm_kms_helper
#modprobe -r i2c_algo_bit
#modprobe -r drm
#modprobe -r snd_hda_intel
# TODO: unload zenpower?

# Unbind the GPU from display driver
virsh nodedev-detach $VIRSH_GPU_VIDEO
virsh nodedev-detach $VIRSH_GPU_AUDIO

# Load VFIO Kernel Modules
modprobe vfio
modprobe vfio_pci
modprobe vfio_iommu_type1
