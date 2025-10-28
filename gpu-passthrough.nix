{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.services.gpu-passthrough;
  
  # Hook scripts
  qemuHook = pkgs.writeShellScript "qemu-hook" ''
    #!/usr/bin/env bash
    
    OBJECT="$1"
    OPERATION="$2"
    
    if [[ $OBJECT == "${cfg.vmName}" ]]; then
      case "$OPERATION" in
        "prepare")
          systemctl start libvirt-nosleep@"$OBJECT" 2>&1 | tee -a /var/log/libvirt/custom_hooks.log
          ${startScript} 2>&1 | tee -a /var/tmp/vfio-start.log
          ;;
        "release")
          systemctl stop libvirt-nosleep@"$OBJECT" 2>&1 | tee -a /var/log/libvirt/custom_hooks.log
          ${stopScript} 2>&1 | tee -a /var/tmp/vfio-stop.log
          ;;
      esac
    fi
  '';

  startScript = pkgs.writeShellScript "vfio-start" ''
    #!/usr/bin/env bash
    set -x
    
    # Variables
    VIDEO_BUS="${cfg.gpuPciId}"
    AUDIO_BUS="${cfg.audioPciId}"
    VIDEO_ID="${builtins.elemAt cfg.gpuIommuIds 0}"
    AUDIO_ID="${builtins.elemAt cfg.gpuIommuIds 1}"
    
    # Kill all user sessions
    for user in $(ls /home); do
      echo "Killing sessions for $user"
      ${pkgs.systemd}/bin/loginctl terminate-user $user || true
    done
    
    # Stop display manager
    echo "Stopping display manager"
    ${pkgs.systemd}/bin/systemctl stop display-manager.service
    sleep 2
    
    # Unbind VT consoles
    echo "Unbinding VT consoles"
    for vtcon in /sys/class/vtconsole/*/bind; do
      echo 0 > "$vtcon" 2>/dev/null || true
    done
    
    # Unbind EFI framebuffer
    echo "Unbinding EFI framebuffer"
    echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/unbind 2>/dev/null || true
    
    # Sync and drop caches
    ${pkgs.coreutils}/bin/sync
    echo 1 > /proc/sys/vm/drop_caches
    
    sleep 2
    
    # Unbind GPU from amdgpu driver
    echo "Unbinding GPU: $VIDEO_BUS"
    echo "$VIDEO_BUS" > "/sys/bus/pci/devices/$VIDEO_BUS/driver/unbind" 2>/dev/null || true
    
    echo "Unbinding Audio: $AUDIO_BUS"
    echo "$AUDIO_BUS" > "/sys/bus/pci/devices/$AUDIO_BUS/driver/unbind" 2>/dev/null || true
    
    sleep 2
    
    # Wait for amdgpu to finish
    timeout=10
    count=0
    while ${pkgs.util-linux}/bin/dmesg | ${pkgs.gnugrep}/bin/grep "amdgpu.*$VIDEO_BUS" | ${pkgs.coreutils}/bin/tail -5 | ${pkgs.gnugrep}/bin/grep -q "finishing device"; do
      echo "Waiting for GPU to finish... ($count/$timeout)"
      if [ $count -ge $timeout ]; then
        echo "Timeout waiting for GPU"
        break
      fi
      sleep 1
      ((count++))
    done
    
    # Unload amdgpu module
    echo "Unloading amdgpu module"
    ${pkgs.kmod}/bin/modprobe -r amdgpu || true
    
    sleep 1
    
    # Verify module is unloaded
    timeout=10
    count=0
    while ${pkgs.kmod}/bin/lsmod | ${pkgs.gnugrep}/bin/grep -q amdgpu; do
      echo "Waiting for amdgpu module to unload... ($count/$timeout)"
      if [ $count -ge $timeout ]; then
        echo "Force removing amdgpu"
        ${pkgs.kmod}/bin/rmmod -f amdgpu 2>/dev/null || true
        break
      fi
      ${pkgs.kmod}/bin/modprobe -r amdgpu 2>/dev/null || true
      sleep 1
      ((count++))
    done
    
    # Load vfio-pci module
    echo "Loading vfio-pci module"
    ${pkgs.kmod}/bin/modprobe vfio-pci
    
    # Bind GPU to vfio-pci
    echo "Binding GPU to vfio-pci"
    echo "$VIDEO_ID" > /sys/bus/pci/drivers/vfio-pci/new_id 2>/dev/null || true
    echo "$AUDIO_ID" > /sys/bus/pci/drivers/vfio-pci/new_id 2>/dev/null || true
    
    # Sleep cycle to reset GPU
    echo "Performing sleep cycle to reset GPU"
    ${pkgs.util-linux}/bin/rtcwake -m mem --date +8sec || true
    
    echo "VFIO start complete"
  '';

  stopScript = pkgs.writeShellScript "vfio-stop" ''
    #!/usr/bin/env bash
    set -x
    
    VIDEO_BUS="${cfg.gpuPciId}"
    AUDIO_BUS="${cfg.audioPciId}"
    
    # Remove devices from PCI bus
    echo "Removing GPU from PCI bus"
    echo 1 > "/sys/bus/pci/devices/$AUDIO_BUS/remove" 2>/dev/null || true
    echo 1 > "/sys/bus/pci/devices/$VIDEO_BUS/remove" 2>/dev/null || true
    
    # Sleep cycle
    ${pkgs.util-linux}/bin/rtcwake -m mem --date +8sec || true
    
    sleep 3
    
    # Rescan PCI bus
    echo "Rescanning PCI bus"
    echo 1 > /sys/bus/pci/rescan
    
    sleep 2
    
    # Reload amdgpu
    echo "Loading amdgpu module"
    ${pkgs.kmod}/bin/modprobe amdgpu || true
    
    sleep 2
    
    # Restart display manager
    echo "Restarting display manager"
    ${pkgs.systemd}/bin/systemctl start display-manager.service
    
    echo "VFIO stop complete"
  '';

in {
  options.services.gpu-passthrough = {
    enable = mkEnableOption "GPU passthrough for single GPU VFIO";
    
    vmName = mkOption {
      type = types.str;
      default = "win10";
      description = "Name of the VM to attach hooks to";
    };
    
    gpuPciId = mkOption {
      type = types.str;
      example = "0000:07:00.0";
      description = "PCI ID of the GPU (format: 0000:xx:xx.x)";
    };
    
    audioPciId = mkOption {
      type = types.str;
      example = "0000:07:00.1";
      description = "PCI ID of the GPU audio device (format: 0000:xx:xx.x)";
    };
    
    gpuIommuIds = mkOption {
      type = types.listOf types.str;
      example = [ "1002:731f" "1002:ab38" ];
      description = "IOMMU device IDs for GPU and audio (vendor:device format)";
    };
    
    hugepages = mkOption {
      type = types.nullOr types.int;
      default = null;
      example = 12288;
      description = "Number of hugepages to allocate (2MB each). Set to null to disable.";
    };
  };

  config = mkIf cfg.enable {
    # Enable required kernel modules

    boot.kernelModules = [ "kvm-amd" "vfio" "vfio_iommu_type1" "vfio_pci" ];
    
    boot.kernelParams = [
      "amd_iommu=on"
      "iommu=pt"
    ] ++ (optionals (cfg.hugepages != null) [
      "hugepages=${toString cfg.hugepages}"
    ]);
    
    # DO NOT bind GPU at boot - let hooks handle it dynamically
    # This allows normal desktop use until VM starts
    boot.extraModprobeConfig = ''
      # Prevent vfio-pci from auto-binding to GPU at boot
      # The hooks will bind/unbind dynamically when VM starts/stops
      options vfio-pci disable_vga=1
      options kvm_intel nested=1
      options kvm_intel emulate_invalid_guest_state=0
      options kvm ignore_msrs=1
    '';

    # Install required packages
    environment.systemPackages = with pkgs; [
      virt-manager
      qemu_full
      libvirt
      swtpm
      OVMF
      dnsmasq
      nbd
      dmg2img
      nbd
    ];

    # Enable libvirtd
    virtualisation.libvirtd = {
      enable = true;
      onBoot = "ignore";
      onShutdown = "shutdown";
      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = true;
        swtpm.enable = true;
        ovmf = {
          enable = true;
          packages = [ pkgs.OVMF.fd ];
        };
      };
    };

    # Add user to libvirtd group
    users.groups.libvirtd = {};

    # Configure libvirt service with hooks
    systemd.services.libvirtd = {
      path = with pkgs; [
        bash
        kmod
        systemd
        coreutils
        util-linux
        gnugrep
      ];

      preStart = lib.mkAfter ''
        mkdir -p /var/lib/libvirt/hooks
        mkdir -p /var/lib/libvirt/hooks/qemu.d/${cfg.vmName}/prepare/begin
        mkdir -p /var/lib/libvirt/hooks/qemu.d/${cfg.vmName}/release/end
        
        # Install main qemu hook script
        cp ${qemuHook} /var/lib/libvirt/hooks/qemu
        chmod +x /var/lib/libvirt/hooks/qemu
        
        # Install start script to prepare/begin
        cp ${startScript} /var/lib/libvirt/hooks/qemu.d/${cfg.vmName}/prepare/begin/start.sh
        chmod +x /var/lib/libvirt/hooks/qemu.d/${cfg.vmName}/prepare/begin/start.sh
        
        # Install stop script to release/end
        cp ${stopScript} /var/lib/libvirt/hooks/qemu.d/${cfg.vmName}/release/end/stop.sh
        chmod +x /var/lib/libvirt/hooks/qemu.d/${cfg.vmName}/release/end/stop.sh
        
        # Ensure log directories exist
        mkdir -p /var/log/libvirt
        mkdir -p /var/tmp
      '';
    };

    # Nosleep service for libvirt
    systemd.services."libvirt-nosleep@" = {
      description = "Preventing sleep while libvirt domain %i is running";
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.systemd}/bin/systemd-inhibit --what=sleep --why='Libvirt domain %i is running' --mode=block sleep infinity";
      };
    };

    # Enable hardware virtualization
    virtualisation.kvmgt.enable = true;
    hardware.graphics.enable = true;
  };
}
