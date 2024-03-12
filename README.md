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
flash /dev/rdiskX
```
