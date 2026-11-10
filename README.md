# Firmware open-source kits

A closed, free firmware for an espresso machine links three libraries under the
**GNU Lesser General Public License**: the Arduino core for the ESP32, AsyncTCP
and ESPAsyncWebServer. This repository publishes its **relink kits**: those
libraries' complete source and the rest of the firmware as object files, so that
you can rebuild the published image, and link it against your own versions of
those libraries. The firmware's own source is not published here, and is not
covered by those libraries' licences.

> [!WARNING]
> **Modifying this firmware carries real risk.** It controls the heaters and the
> pump of a machine that is plugged into the mains, and much of it is there to
> keep that safe. The LGPL libraries run in the same program, so a small change
> to one of them can quietly break that protection and damage the machine, or
> leave it unable to install firmware again. There is no USB port or other
> connector on the outside of the machine to reflash it from.
>
> **A modified image is your own.** An image built with changed or replaced
> components, one built with a kit from here included, is not ours, and we do
> not support it. Use it at your own risk.
>
> Our images come only from our own download page and the machine's own
> **Software update**. Each is identified by its SHA-256, which the release of
> its version here carries in its kit's `SHA256SUMS`. An image from anywhere
> else is not ours, whatever it says about itself.

## Releases

Each release is named after a firmware version and carries two files: the
relink kit, `relink-kit-<version>.tar.gz`, and `THIRD_PARTY_NOTICES.txt`, every
component in that version with its licence and notices. Before it is published,
each kit is checked to relink to that version's image byte for byte, with its
LGPL libraries built from its source.

## Relinking

You need bash, Python 3 with pyserial (PlatformIO's own interpreter has it) and
three [PlatformIO](https://platformio.org) packages; the kit's `README.txt`
names their versions and the commands that install them. Then, in an unpacked
kit:

```sh
./relink.sh            # out/firmware.bin: from an unchanged kit, the published image
```

Kits after v0.13.1 carry the LGPL libraries as source only, and `relink.sh`
builds them on its first run; the v0.13.0 and v0.13.1 kits carry them built as
well.

To use a changed library, edit its source under `lgpl/src/`, then:

```sh
lgpl/build.sh          # rebuilds lgpl/lib/ from lgpl/src/
./relink.sh
```

[`tools/`](tools) holds the same two scripts, to read without downloading a
kit; they run only from inside one.

## Installing an image

A relinked image installs like a published one, through the machine's update
page: follow "Go back to the original firmware" in the installation guide that
comes with the firmware, but select `out/firmware.bin` instead of the updater,
and leave **Erase all our data** unticked.

Activation does not stand in the way. Installed with **Erase all our data**
unticked, a relinked image keeps the machine's activation, and the update page
installs any image without checking where it came from.

## Licence

This README and the scripts in [`tools/`](tools) are under the
[MIT licence](LICENSE). Each kit's libraries are under the licences its
`THIRD_PARTY_NOTICES.txt` names, whose texts are in [`LICENSES/`](LICENSES).

The firmware's own code, which each kit carries among the object files in
`app/`, is Copyright (c) 2026 Oliver Mesieh. It is not open source, and no
licence to it is granted here beyond what the LGPL requires: you may relink it
with modified versions of the LGPL libraries for your own use, and reverse
engineer it to debug such modifications. The other components in `app/`, the
Kario typeface among them, are under the licences `THIRD_PARTY_NOTICES.txt`
names.
