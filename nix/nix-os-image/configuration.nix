{
  lib,
  pkgs,
  ...
}: let
  bootloader = pkgs.odroid-xu3-bootloader;
  stateVersion = "23.11";
in {
  # Set DTB
  hardware.deviceTree.name = "exynos5422-odroidxu4.dtb";

  # Override the source for 6.1 with Hardkernel's fork for ODROID XU4
  boot.kernelPackages = lib.mkForce pkgs.linuxPackagesFor (pkgs.linux_6_1.override {
    argsOverride = rec {
      version = "6.1.y";
      modDirVersion = builtins.replaceStrings ["y"] ["77"] version;

      src = pkgs.fetchurl {
        # The upstream kernel assumes to be built at the project root
        # url = "https://github.com/hardkernel/linux/archive/odroidxu4-${version}.tar.gz";
        # sha256 = "sha256-9rel2TRSwdkEwQN+xj8B38B/f6/Zdetu1Yg2a2plA1A=";
        # Use a patched version instead
        url = "https://github.com/martinjlowm/linux/archive/afa3e7707f62602f97c499c7c357ce714ecc3b44.tar.gz";
        sha256 = "sha256-mIvN/8ZZ2gU1OWtbRZG0gFClnZZHYmvMUt9NvkpZVY4=";
      };

      defconfig = "odroidxu4_defconfig";
    };
  });

  # This will be replaced by the second line soon in unstable
  boot.zfs.enableUnstable = false;
  # boot.zfs.package = pkgs.zfsStable;

  # There's no reason to populate with Raspberry Pi files
  sdImage.populateFirmwareCommands = "";

  # Fuse the bootloader onto the image
  sdImage.postBuildCommands = ''
    dd conv=notrunc bs=512 seek=1    of=$img if=${bootloader}/lib/sd_fuse-xu3/bl1.bin.hardkernel
    dd conv=notrunc bs=512 seek=31   of=$img if=${bootloader}/lib/sd_fuse-xu3/bl2.bin.hardkernel.1mb_uboot
    dd conv=notrunc bs=512 seek=63   of=$img if=${bootloader}/lib/sd_fuse-xu3/u-boot-dtb.bin
    dd conv=notrunc bs=512 seek=2111 of=$img if=${bootloader}/lib/sd_fuse-xu3/tzsw.bin.hardkernel
  '';

  nixpkgs.overlays = [
    # https://github.com/NixOS/nixpkgs/issues/126755#issuecomment-869149243
    (final: super: {
      makeModulesClosure = x:
        super.makeModulesClosure (x // {allowMissing = true;});
    })
  ];

  system.stateVersion = stateVersion;
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

  environment.sessionVariables = {
    PRIVATE_KEY_PATH = "$HOME/key.pem";
    CERTIFICATE_PATH = "$HOME/cert.pem";
    ROOT_CERTIFICATE_PATH = "$HOME/AmazonRootCA1.pem";
    AWS_ENDPOINT = "aoe86ov002i0d-ats.iot.eu-west-1.amazonaws.com";
    CLIENT_ID = "sonos";
  };

  home-manager.useGlobalPkgs = true;
  home-manager.users.alice = {
    home.stateVersion = stateVersion;
    home.file = {
      "AmazonRootCA1.pem" = {
        source = ../../AmazonRootCA1.pem;
      };
      "key.pem" = {
        source = ../../d8cfa7474fa13770a7cf862563be03425957469e96ce221b42af933018b126d5-private.pem.key;
      };
      "cert.pem" = {
        source = ../../d8cfa7474fa13770a7cf862563be03425957469e96ce221b42af933018b126d5-certificate.pem.crt;
      };
    };
  };

  users.mutableUsers = false;

  systemd.services.sonos = {
    after = ["network.target" "systemd-user-sessions.service" "network-online.target"];

    serviceConfig = {
      Type = "forking";
      ExecStart = "${pkgs.pkgsHostTarget.sonos {
        craneExtraArgs = {
          nativeBuildInputs = [pkgs.pkgsBuildHost.autoPatchelfHook];
          cargoBuildCommand = "HOME=$(pwd) ${pkgs.pkgsBuildHost.cargo-zigbuild}/bin/cargo-zigbuild build --profile release --target armv7-unknown-linux-gnueabihf";
        };
      }}/bin/sonos";
      TimeoutSec = 30;
      Restart = "on-failure";
      # Would be cool to control the blue LED if errors occur: https://wiki.odroid.com/odroid-xu4/application_note/led_control
      # ExecStopPost = "/bin/sh -c 'if [ "$$EXIT_STATUS" = 2 ]; then rm /file/to/delete; fi'"
      RestartSec = 30;
      StartLimitBurst = 10;
    };

    wantedBy = ["multi-user.target"];
  };
}
