# My dotfiles

Welcome to my dotfiles. These _will_ change frequently, and no guarantees are made if you use these.
These are setup to allow me to move to a new device and very quickly set it up to my usual configuration.

I have not tested without decrypting the files, but it _should_ be theoretically possible. I'm happy to help if anyone actually cares.
Obviously, I'm not willing to share the decryption password, but the encrypted files should have little-to-no impact on the final product anyways.

These have been tested on Ubuntu and Arch Linux. They should work on either platform. They have also been _lightly_ tested for Debian and should work.
They would _probably_ work on other platforms, but no promises :wink:.

### Script ordering:

Distro dependent scripts run first, this is to ensure native packages which will likely be needed later are included.
These should be in 10-install/00-DISTO - Ubuntu is Debian bc it's similar enough.

10-install/10-_ is package managers, snap, flatpak, pnpm, etc.
10-install/20-_ is currently reserved for java, but other possible dependencies should be included here.
10-install/30-_ is for cli applications
10-install/40-_ is for graphical applications
10-install/50-\* is for fonts/icons/themes/etc

20-post-install/\* is also sorted, though not with as much thought as above.
ditto with 00-pre-install.
