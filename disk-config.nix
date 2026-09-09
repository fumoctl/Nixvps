{ lib
, ...
}:

{
  # ============================================================================
  # DECLARATIVE DISK PARTITIONING & FILESYSTEM CONFIGURATION (DISKO)
  # ============================================================================
  # Defines the block device partitioning scheme and filesystem mounts for the VPS.
  # Using Disko allows automated, reproducible provisioning via nixos-anywhere.
  disko.devices = {
    disk.main = {
      # Target Drive: Defaults to standard virtual SCSI/SATA disk (/dev/sda)
      # Can be overridden per host if the cloud provider uses /dev/vda or /dev/nvme0n1
      device = lib.mkDefault "/dev/sda";
      type = "disk";

      content = {
        # GPT (GUID Partition Table) layout for modern partitioning flexibility
        type = "gpt";

        partitions = {
          # --------------------------------------------------------------------
          # 1. BIOS Boot Partition (GRUB core.img embedding)
          # --------------------------------------------------------------------
          # Type EF02 is required when booting a GPT-partitioned disk under legacy
          # BIOS / non-UEFI cloud hypervisors (e.g. standard VPS instances).
          # GRUB embeds its second-stage bootloader into this unformatted 1MB slice.
          boot = {
            size = "1M";
            type = "EF02";
          };

          # --------------------------------------------------------------------
          # 2. Root Filesystem Partition
          # --------------------------------------------------------------------
          # Consumes the remainder of the drive (100%) and formats it with ext4.
          # ext4 provides rock-solid stability and low memory footprint on VPS nodes.
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