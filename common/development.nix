# This file is in the gitignore, changes will be ignored. It exists so changes
# can be tested but not committed accidentally.
{
  pkgs,
  lib,
  config,
  modulesPath,
  ...
}:
{
  imports = [
    "${modulesPath}/profiles/minimal.nix"
  ];
  boot = {
    kernelParams = [
      "iommu=soft"
      "clk_ignore_unused"
      "pd_ignore_unused"
      "arm64.nopauth"
    ];
    loader.systemd-boot.enable = true;
  };
  networking = {
    networkmanager.enable = true;
    networkmanager.wifi.backend = "iwd";
  };
  nixpkgs.config.allowUnfree = true;
  users.mutableUsers = false;

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 90;
  };
  nix = {
    settings = {
      trusted-users = [
        "@wheel"
        "root"
      ];
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
  };
  networking.firewall.enable = false;
  hardware = {
    bluetooth.package =
      (builtins.getFlake "github:nixos/nixpkgs/fc756aa6f5d3e2e5666efcf865d190701fef150a")
      .legacyPackages.aarch64-linux.bluez;
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        vulkan-loader
        vulkan-validation-layers
        vulkan-extension-layer
      ];
    };
  };
  programs.feedbackd.enable = true;
  programs.calls.enable = true;
  hardware.sensor.iio.enable = true;
  environment.systemPackages = with pkgs; [
    hexagonrpc
    snapshot
    snapshot
    epiphany # Web browser
    gnome-console # Terminal

    qrtr
    rmtfs
    qmic
    tqftpserv
  ];
  systemd.services = {
    iio-sensor-proxy = {
      serviceConfig.RestrictAddressFamilies = [
        "AF_QIPCRTR"
        "AF_LOCAL"
      ];
      overrideStrategy = "asDropin";
    };

    hexagonrpcd-adsp-sensorspd = {
      description = "Daemon to support Qualcomm Hexagon ADSP virtual filesystem for SensorPD";
      wantedBy = [ "multi-user.target" ];
      before = [ "suspend.target" ];
      conflicts = [ "suspend.target" ];

      serviceConfig = {
        ExecStart = "${pkgs.hexagonrpc}/bin/hexagonrpcd -f /dev/fastrpc-adsp -d adsp -s";
        Restart = "on-failure";
        # This service shouldn't be run on devices with an SDSP
        ConditionPathExists = [
          "!/dev/fastrpc-sdsp"
          "/dev/fastrpc-adsp"
        ];
        RestartSec = "3s";
        # maybe use dynamicuser
        User = "root";
        Group = "root";
      };
    };

    tqftpserv = {
      description = "Qualcomm QRTR TFTP services (tqftpserv)";
      wantedBy = [ "multi-user.target" ];
      before = [ "network.target" ];

      serviceConfig = {
        ExecStart = "${pkgs.tqftpserv}/bin/tqftpserv";
        Restart = "on-failure";
        RestartSec = "2s";
        # maybe use dynamicuser
        User = "root";
        Group = "root";
      };
    };
    rmtfs = {
      description = "Qualcomm Remote Filesystem Daemon (rmtfs)";
      wantedBy = [ "multi-user.target" ];
      before = [ "network.target" ];

      serviceConfig = {
        ExecStart = "${pkgs.rmtfs}/bin/rmtfs -r -P -s";
        Restart = "on-failure";
        RestartSec = "2s";
        # maybe use dynamicuser
        User = "root";
        Group = "root";
      };
    };
    qca-bluetooth =
      let
        script = pkgs.writeShellScript "qca-bluetooth.sh" ''
          set -x
          trap 'sleep 1' DEBUG # Sleep 1 second before every command execution
          export PATH="${
            lib.makeBinPath (
              with pkgs;
              [
                config.hardware.bluetooth.package
                coreutils-full
                gawk
                unixtools.script
              ]
            )
          }:$PATH"

          SERIAL=$(grep -o "serialno.*" /proc/cmdline | cut -d" " -f1)
          BT_MAC=$(echo "$SERIAL-BT" | sha256sum | awk -v prefix=0200 '{printf("%s%010s\n", prefix, $1)}')
          BT_MAC=$(echo "$BT_MAC" | cut -c1-12 | sed 's/\(..\)/\1:/g' | sed '$s/:$//')

          script -qc "btmgmt --timeout 3 -i hci0 power off"
          script -qc "btmgmt --timeout 3 -i hci0 public-addr \"$BT_MAC\""
        '';
      in
      {
        description = "Setup the bluetooth interface";
        wantedBy = [
          "multi-user.target"
          "bluetooth.service"
        ];
        script = toString script;
        serviceConfig = {
          User = "root";
          Type = "oneshot";
          RemainAfterExit = true;
        };
      };
  };
  # Maybe not needed because it's in kernel now
  #systemd.services.pd-mapper = {
  #  description = "Qualcomm Protection Domain Mapper (pd-mapper)";
  #  wantedBy = [ "multi-user.target" ];
  #  after = [ "network.target" ];

  #  serviceConfig = {
  #    ExecStart = "${pkgs.pd-mapper}/bin/pd-mapper";
  #    Restart = "on-failure";
  #    RestartSec = "2s";
  #    # maybe use dynamicuser
  #    User = "root";
  #    Group = "root";
  #  };
  #};
  networking.modemmanager.enable = true;
  services = {
    udev.extraRules = ''
      # iio-sensor-proxy with libssc: accelerometer mount matrix
      SUBSYSTEM=="misc", KERNEL=="fastrpc-*", ENV{ACCEL_MOUNT_MATRIX}+="-1, 0, 0; 0, -1, 0; 0, 0, -1"
    '';
  };
  xdg.portal.enable = true;
  boot.loader.systemd-boot.configurationLimit = 5;

}
