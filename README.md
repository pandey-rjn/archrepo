# Archlinux Repository for Heera OS

### Usage

Add following lines to your /etc/pacman.conf.

```
[heera]
SigLevel = Optional
Server = https://heera-os.github.io/archrepo/$arch/
```

> Then to use Heera DE, install all packages of group `heeraDE`, and run `startx /usr/bin/heera-session` (ie. if not using a window manager, like [gdm](https://wiki.archlinux.org/title/GDM))

These packages are built by Github Actions, and from the latest -git sources, hence may provide additional features as the heera os repositories are updated.

* All of these packages belong to the `heeraDE` group

Checkout the Heera OS repositories at https://github.com/heera-os
