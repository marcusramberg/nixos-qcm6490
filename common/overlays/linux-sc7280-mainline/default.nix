{
  buildLinux,
  fetchFromGitHub,
  ...
}:
buildLinux rec {
  modDirVersion = "7.0.8";
  version = modDirVersion;
  src = fetchFromGitHub {
    owner = "sc7280-mainline";
    repo = "linux";
    rev = "v${modDirVersion}-sc7280";
    hash = "sha256-dU+UeCr8aVIg226ZnqryPlLuOPsKkKgR/KN/LkvHDGo=";
  };
  extraMeta = {
    platforms = [ "aarch64-linux" ];
  };
}
