{
  nixpkgs.overlays = [
    (self: super: {
      stevia = super.callPackage ./stevia.nix { };
      # iio-sensor-proxy 3.9 has SSC support upstream, no patches needed.
      # If AF_QIPCRTR restrict is still missing in upstream service file, add back:
      #   ../patches/iio-sensor-proxy/0007-data-iio-sensor-proxy.service.in-add-AF_QIPCRTR.patch
      mdm = super.callPackage ./mdm.nix { };
      firmware-shift-otter = super.callPackage ./firmware-shift-otter { };
      firmware-fairphone-fp5 = super.callPackage ./firmware-fairphone-fp5 { };
      linuxPackages_sc7280-mainline = super.linuxPackagesFor (
        super.callPackage ./linux-sc7280-mainline { }
      );
      pil-squasher = super.callPackage ./pil-squasher { };
      #hexagonrpc = super.callPackage ./hexagonrpc.nix {};
      #qrtr = super.callPackage ./qrtr/qrtr.nix {};
      #qmic = super.callPackage ./qrtr/qmic.nix {};
      #rmtfs = super.callPackage ./qrtr/rmtfs.nix {};
      #tqftpserv = super.callPackage ./qrtr/tqftpserv.nix {};
      #pd-mapper = super.callPackage ./qrtr/pd-mapper.nix {};
    })
  ];
}
