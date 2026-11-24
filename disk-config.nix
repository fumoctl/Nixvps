{ lib
, ...
}:

{
  disko.devices = {
    disk.main = {
      device = lib.mkDefault "/dev/sda";
      type = "disk";

      content = {
        type = "gpt";

        partitions = {
          boot = {
            priority = 1;
            size = "1M";
            type = "EF02";
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