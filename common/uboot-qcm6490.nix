# https://docs.u-boot.org/en/latest/board/qualcomm/board.html
{
  buildUBoot,
  xxd,
  bison,
  flex,
  openssl,
  gnutls,
  android-tools,
  ...
}@args:
buildUBoot {
  version = "master";
  patches = [
    ./cd-gpio.patch # Required for making the SD Card work on shift-otter
  ];
  extraConfig = ''
    CONFIG_CMD_HASH=y
    CONFIG_CMD_BLKMAP=y
    CONFIG_BLKMAP=y
    CONFIG_CMD_UFETCH=y
    CONFIG_CMD_SELECT_FONT=y
    CONFIG_VIDEO_FONT_8X16=n
    CONFIG_VIDEO_FONT_16X32=y
    CONFIG_VIDEO_FONT_16X32_VGA=y
  '';
  prePatch = ''
    # For making SD Card discovery not time out in u-boot on shift-otter
    substituteInPlace drivers/mmc/sdhci.c --replace-fail 'udelay(10)' 'udelay(100)'
    substituteInPlace board/qualcomm/qcom-phone.env \
      --replace-fail 'preboot=scsi scan' \
      'preboot=scsi scan; part start scsi 0 userdata ustart; part size scsi 0 userdata usize; blkmap create root; blkmap map root 0 0x''${usize} linear scsi 0 0x''${ustart}'
    cat  board/qualcomm/qcom-phone.env
  '';
  inherit (args) filesToInstall extraMakeFlags src;
  defconfig = "qcom_defconfig qcom-phone.config";
  extraMeta.platforms = [ "aarch64-linux" ];
  nativeBuildInputs = [
    xxd
    bison
    flex
    openssl
    gnutls
    android-tools
  ];
}
