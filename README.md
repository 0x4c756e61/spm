# Tornado
The official package manager of the Swirl programming language.

## Compiling
### Requirement
 - A working [NIM](https://nim-lang.org/install.html) installation
 - At least one brain cell

### Process
 1) clone (or download the zip and extract): `git clone https://github.com/SwirlLang/tornado.git`
 2) change directory: `cd tornado`
 3) compile: `nim -d:release -d:danger -d:strip --opt:speed -d:ssl c tornado.nim`
 4) get help: `./tornado --help`

## Usage
- Getting help: `./tornado --help`
- Install packages: `./tornado install PACKAGE_NAME1 PACKAGE_NAME2`
- Uninstall packages : `./tornado remove PACKAGE_NAME1 PACKAGE_NAME2`
- Search for packages: `./tornado query PACKAGE_NAME1 PACKAGE_NAME2`
- Create a package: `./tornado init`

## License
This software comes under the GPLv3 and later license. See [license.md](https://github.com/SwirlLang/tornado/blob/main/license.md) for more info.

## Warning
Software comes as is, without any guarantee.
