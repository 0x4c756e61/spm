# TORNADO
Tornado is an unofficial package (called fragments) management tool for the Swirl programming language.

## Compiling
### Requirement
 - A working [NIM](https://nim-lang.org/install.html) installation
 - At least one brain cell

### Process
 1) clone (or download zip and extract): `git clone https://github.com/0x454d505459/tornado.git`
 2) change directory: `cd tornado`
 3) compile: `nim -d:release -d:danger -d:strip --opt:size c tornado.nim`
 4) get help: `./tornado --help`

## Usage
- Getting help: `./tornado --help`
- installing fragments (packages): `./tornado install PACKAGE_NAME1 PACKAGE_NAME2`
- uninstall fragments : `./tornado remove PACKAGE_NAME1 PACKAGE_NAME2`
- search packages: `./tornado query PACKAGE_NAME1 PACKAGE_NAME2`
- create a package: `./tornado init`

## License
This software comes under the GPLv3 and later license. See [license.md](https://github.com/0x454d505459/tornado/blob/main/license.md) for more info.

## Warning
Software comes as is, without any guarantee.