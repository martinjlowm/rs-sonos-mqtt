# Getting Started

This repository contains a Flakelight-based Nix environment to build a bootable
image (for [ODROID XU4](https://wiki.odroid.com/odroid-xu4/odroid-xu4)) with a
Sonos client that is communicated with over MQTT through AWS IoT Core.

Install Nix and build a flashable image with

```bash
nix build .#image
```

Flash the image with

```bash
sudo zstd -vdcfT6 result/sd-image/nixos-sd-image-<...>-armv7l-linux.img.zst | sudo dd of=/dev/rdiskX status=progress bs=4M
```
