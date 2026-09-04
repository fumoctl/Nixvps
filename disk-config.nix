{ lib, ... }: {
  disko.devices = {
    disk.main = {
      device = lib.mkDefault "/dev/sda";
      type = "disk";
      content = {
        type = "gpt"; # Keeps your exact disklabel type
        partitions = {
          boot = {
            size = "1M";
            type = "EF02"; # Standard GUID for a BIOS boot partition
          };
          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };
  };
}