{
  config,
  lib,
  nixpkgs,
  pkgs,
  ...
}: let
  bootloader = pkgs.odroid-xu3-bootloader;
in {
  sdImage.populateFirmwareCommands = "";

  hardware.deviceTree.name = "exynos5422-odroidxu4.dtb";

  boot.kernelPackages = lib.mkForce (pkgs.linuxPackagesFor (pkgs.linux_6_1.override {
    argsOverride = rec {
      version = "6.1.y";
      modDirVersion = builtins.replaceStrings ["y"] ["77"] version;
      src = pkgs.fetchurl {
        # The upstream kernel assumes to be built at the project url
        rootnix = "https://github.com/martinjlowm/linux/archive/90fd9b34277c137e4141f10b9d32cf82babed825.tar.gz";
        sha256 = "sha256-jEmJuWmktU5dFcXgR9xG+6ECUw2GnyyOGvI17ct4URc=";
      };

      defconfig = "odroidxu4_defconfig";
    };
  }));

  # Fuse the bootloader onto the image
  sdImage.postBuildCommands = ''
    dd conv=notrunc bs=512 seek=1    of=$img if=${bootloader}/lib/sd_fuse-xu3/bl1.bin.hardkernel
    dd conv=notrunc bs=512 seek=31   of=$img if=${bootloader}/lib/sd_fuse-xu3/bl2.bin.hardkernel.1mb_uboot
    dd conv=notrunc bs=512 seek=63   of=$img if=${bootloader}/lib/sd_fuse-xu3/u-boot-dtb.bin
    dd conv=notrunc bs=512 seek=2111 of=$img if=${bootloader}/lib/sd_fuse-xu3/tzsw.bin.hardkernel
  '';

  # This will be replaced by the second line soon in unstable
  boot.zfs.enableUnstable = false;
  # boot.zfs.package = pkgs.zfsStable;

  # nixpkgs.overlays = [
  #   # https://github.com/NixOS/nixpkgs/issues/126755#issuecomment-869149243
  #   (final: super: {
  #     makeModulesClosure = x:
  #       super.makeModulesClosure (x // {allowMissing = true;});
  #   })
  # ];

  system.stateVersion = "23.10";
  networking.hostName = "wololo";

  # Determine what we need :)
  # environment.systemPackages = with pkgs; [];

  services.openssh.enable = true;

  nix.settings.experimental-features = ["nix-command" "flakes"];

  users.users.alice = {
    isNormalUser = true;
    extraGroups = ["wheel"];

    password = "blabla";
  };

  users.mutableUsers = false;

  systemd.services.sonos = {
    after = ["network.target" "systemd-user-sessions.service" "network-online.target"];

    serviceConfig = {
      Type = "forking";
      ExecStart = "${pkgs.hello}";
      TimeoutSec = 30;
      Restart = "on-failure";
      RestartSec = 30;
      StartLimitInterval = 350;
      StartLimitBurst = 10;
    };

    wantedBy = ["multi-user.target"];
  };
}
