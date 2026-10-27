# Firmware open-source kits

A closed, free firmware for an espresso machine links three libraries under the
**GNU Lesser General Public License**: the Arduino core for the ESP32, AsyncTCP
and ESPAsyncWebServer. This repository publishes its **relink kits**: those
libraries' complete source and the rest of the firmware as object files, so that
you can rebuild the published image, and link it against your own versions of
those libraries. The firmware's own source is not published here, and is not
covered by those libraries' licences.

## Releases

Each release is named after a firmware version and carries two files: the
relink kit, `relink-kit-<version>.tar.gz`, and `THIRD_PARTY_NOTICES.txt`, every
component in that version with its licence and notices. Before it is published,
each kit is checked to relink to that version's image byte for byte, as it is
and with its LGPL libraries rebuilt from its source.

## Relinking

You need bash, Python 3 with pyserial (PlatformIO's own interpreter has it) and
three [PlatformIO](https://platformio.org) packages; the kit's `README.txt`
names their versions and the commands that install them. Then, in an unpacked
kit:

```sh
./relink.sh            # out/firmware.bin: from an unchanged kit, the published image
```

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

## Licence

This README and the scripts in [`tools/`](tools) are under the
[MIT licence](LICENSE). Each kit's libraries are under the licences its
`THIRD_PARTY_NOTICES.txt` names, whose texts are in [`LICENSES/`](LICENSES).
