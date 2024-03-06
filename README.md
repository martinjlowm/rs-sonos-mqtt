# Getting Started

This repository contains a Flakelight-based Nix environment to build a bootable
image with Sonos client that's communicated with over MQTT through AWS IoT Core.

Install Nix and build a flashable image with

```bash
nix build .#image
```

Flash the image with

```bash
sudo zstd -vdcfT6 result/sd-image/nixos-sd-image-<...>-armv7l-linux.img.zst | sudo dd of=/dev/rdiskX status=progress bs=4M
```
