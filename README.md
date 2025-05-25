# My NixOS Config

Feel free to take a look around 🌷✨

## Essential Resources

### Nix

[NixOS Manual](https://nixos.org/manual/nixos/stable/)

[Nixpkgs Manual](https://nixos.org/manual/nixpkgs/stable/)

[Nix Packages + Options Search](https://search.nixos.org)

[Nix Language Reference](https://noogle.dev)

https://nixos-and-flakes.thiscute.world

https://www.nixhub.io/

https://nixpk.gs/pr-tracker.html

https://lazamar.co.uk/nix-versions/

```
man configuration.nix
man home-configuration.nix
```

### Linux

https://docs.kernel.org/admin-guide/kernel-parameters.html

## Installing NixOS

### Old Apple Hardware

The official NixOS installers don't include the necessary Broadcom wifi drivers so I have to build the installer myself with the drivers included:

```
nix build .#nixosConfigurations.installer.config.formats.install-iso
nix build .#nixosConfigurations.installer.config.formats.install-iso-gnome
nix build .#nixosConfigurations.installer.config.formats.install-iso-plasma
```

Then write I image to media with `pkgs.gnome.gnome-disk-utility` with "Restore Image". The image selector won't display symlinks so copy the nix store path of the result iso and press Ctrl+L to bring up the location bar and paste the path in.

Spam Alt+R while it's booting up to get to the firmware boot menu.

## Calamares

Always enable "Allow Unfree" so installing proprietary drivers doesn't crash the installation process.

Afterwards mount the new root partition and clone your nixos configuration repo:
```
cd /run/media/<somepath>/home/stel
mkdir -p ~/.config/nixflake
git clone https://github.com/stelcodes/nixos-config ~/.config/nixflake
cd nixos-config
nixos-generate-config --show-hardware-config > hosts/<hostname>/hardware-configuration.nix
git add .
sudo nixos-rebuild switch --flake "$HOME/.config/nixflake#<hostname>"
```

Or you could croc the hardware configuration back to another computer:
```sh
ROOT="$1"
TEMPDIR="$(mktemp -d)"
if [ test -z "$ROOT" ]; then
  echo "Please provide a root path of the mounted NixOS installation."
  exit 1
fi
if ! [ test -d "$ROOT/etc/nixos" ]; then
  echo "The provided path doesn't seem to be the root of a NixOS installation"
fi
nixos-generate-config --root "$ROOT" --dir "$TEMPDIR"
croc "$TEMPDIR/hardware-configuration.nix"
```

## Writing Nix

### Avoiding having to pull in `flake-utils` in your flake
https://ayats.org/blog/no-flake-utils/
```nix
{
  outputs = {nixpkgs, ...}: let

    forAllSystems = function:
      nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
      ] (system: function nixpkgs.legacyPackages.${system});

  in {

    packages = forAllSystems (pkgs: {
      default = pkgs.callPackage ./package.nix {};
    });

    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {};
    overlays.default = final: prev: {};
  };
}
```


## Virtualisation

build vm image:
```
nixos-rebuild build-vm-with-bootloader --flake "$HOME/nixos-config#hostname"
```

test ssh:
```
QEMU_NET_OPTS='hostfwd=tcp::2222-:22' <vm_start_script>
```

ssh into virtual machine by getting ip address (ip a) and `ssh <user>@ip`.

build digital ocean droplet image:
```
nix build .#nixosConfigurations.hostname.config.formats.do
```

## Wayland

Use `QT_QPA_PLATFORM=xcb audacious` to see controls for adjusting plugin windows (Wayland QT issues)

## Music Production

### Wine + Yabridge

Run plugin installers with something like `wine plugin_installer.exe`.

Make sure yabridge knows about plugin paths:
```
# Common install locations
yabridge add ~/.wine/drive_c/Program Files/Common Files/VST3
yabridge sync
```

## Dconf

Values can be defined with Home Manager's `dconf.settings` option.

```
dconf dump /org/cinnamon/ | dconf2nix | nvim -R
pkgs.dconf-editor for GUI
```

## Messaging

My favorites:

```
XMPP: pkgs.gajim
Signal: pkgs.signal-desktop
```

## Obsidian

Might have to `rm -rf ~/.config/obsidian/GPUCache` after a major update.

## Phone tethering

For iphone hotspot tethering use `pkgs.libimobiledevice` and `services.usbmuxd.enable`.

## Gaming

### Standalone games

Probably going to run into openGL issues:
```
error while loading shared libraries: libGL.so.1: cannot open shared object file: No such file or directory
```

One solution is to use distrobox:
```
distrobox create -n gamebox -i registry.fedoraproject.org/fedora-toolbox:38
distrbox enter gamebox
sudo dnf install opengl-games-utils
./run-game.sh
```

Another might be to use https://github.com/nix-community/nixGL but there will probably still be missing other libraries like wayland related stuff.

## Hardware

### GPUS

#### AMD

https://en.wikipedia.org/wiki/List_of_AMD_graphics_processing_units#Features_overview

https://en.wikipedia.org/wiki/Video_Core_Next

I have one of these: https://en.wikipedia.org/wiki/Radeon_RX_5000_series

### Wireless Controllers

The Xbox One controllers models 1708 and 1797 are some of best wireless controllers for linux. The package that provides their firmware is called xpadneo.

https://en.wikipedia.org/wiki/Xbox_Wireless_Controller

https://xbox.fandom.com/wiki/List_of_Xbox_Wireless_Controller_variants#Third_Generation_(2016)

https://atar-axis.github.io/xpadneo/

### Emulators

https://emulation.gametechwiki.com/index.php/Main_Page

## Compatibility

`pkgs.appimage-run`

## Wallpapers

https://github.com/kitsunebishi/Wallpapers

https://imgur.com/upload

## Traditional Desktop Specialisations

```nix
{
  specialisation = {
    gnome.configuration = {
      environment.gnome.excludePackages = with pkgs; [
        gnome-tour
        gnome-user-docs
        orca
        baobab
        epiphany
        gnome.gnome-backgrounds
        gnome.gnome-color-manager
        gnome.gnome-themes-extra
        gnome.gnome-shell-extensions
        gnome.yelp
        gnome.cheese
        gnome.gnome-contacts
        gnome.gnome-music
        gnome.gnome-system-monitor
        gnome-text-editor
        gnome.gnome-clocks
        gnome.gnome-weather
        gnome.gnome-maps
        gnome.simple-scan
        gnome.gnome-characters
        gnome-connections
        gnome.gnome-logs
        gnome.totem
        gnome.geary
        gnome-photos
        gnome.gnome-calendar
      ];
      services.xserver = {
        autorun = true;
        desktopManager.gnome.enable = true;
      };
    };
    plasma.configuration = {
      environment.plasma5.excludePackages = [ ];
      home-manager.users.${username}.qt.enable = lib.mkForce false;
      services = {
        gnome.gnome-keyring.enable = lib.mkForce false;
        xserver = {
          autorun = true;
          desktopManager.plasma5 = {
            enable = true;
            # useQtScaling = true;
          };
        };
      };
    };
  };
}
```

## Theming

### Catppucin

https://github.com/xlce/wofi

## Hard Drives

### Btrfs RAID1 mirror

You need a btrfs volume and an unpartitioned disk to add to the volume. Mount the btrfs volume (let's say at `/mnt/archive`). The second disk should be unformatted (let's say it's `/dev/sdc`).

```sh
# Use the -f (force) flag if second disk has a partition table or partitions
# This will erase /dev/sda
sudo btrfs device add /dev/sda /mnt/archive
# Start converting the volume into a mirrored array for both the data and metadata
# This might take a LONG time depending on how much data is already present on the first disk
sudo btrfs balance start -mconvert=raid1 -dconvert=raid1 /mnt/archive
```

## Neovim

### Folding
Sometimes I forget how to fold in Vim. Here's the easiest way for me to remember:

- Fold: z prefix (the "z" looks like a folded piece of paper, if you look at it from the side)
- Fold MORE: zm, zM to fold everything
- Fold REDUCE: zr, zR to fold nothing

## Samba

Need to add user with `smbpasswd -a my_user` manually

## Other Links

https://librearts.org/

https://diskprices.com

https://modcase.com.au

https://frame.work

## Inspiration

https://github.com/Xe/nixos-configs

https://github.com/MatthiasBenaets/nixos-config

https://git.2li.ch/Nebucatnetzer/nixos

https://github.com/emmanuelrosa/erosanix

https://github.com/LongerHV/nixos-configuration

https://github.com/TLATER/dotfiles

https://git.eisfunke.com/config/nixos
