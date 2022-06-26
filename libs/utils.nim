import tlib, strformat, strutils, os, httpclient

const
    red* = tlib.rgb(255,33,81)
    green* = tlib.rgb(37,255,100)
    yellow* = tlib.rgb(246,255,69)
    blue* = tlib.rgb(105,74,255)
    dft* = def()

var
    help_menu* = &"""
{red}TORNADO{dft} version {blue}0.0.1{dft}
{red}Tornado{dft} is an unofficial package (called fragments) management tool for the {blue}Swirl{dft} programming language.

{red}USAGE{dft}:
    tornado [OPTIONS] [ARG]

{red}OPTIONS{dft}:"""

proc error*(str: string) =
    stdout.writeLine &"[{red}ERROR{dft}]      {str}"
    quit(1)

proc info*(str: string) =
    stdout.writeLine &"[{blue}INFO{dft}]       {str}"

proc warn*(str: string) =
    stdout.writeLine &"[{yellow}WARN{dft}]       {str}"

proc success*(str: string) =
    stdout.writeLine &"[{green}SUCCESS{dft}]    {str}" 

proc register_help*(calls: array[0..1,string], desc:string) =
    let options = calls.join(", ")
    let thing = &"\n    {blue}{options}{dft}"
    let space = " " * (50-len(thing))
    help_menu &= thing & space & desc

proc createProject*(configs: array[0..8,(string,string)], pathSeparator:char, config_out:string) = 
    let dirname = configs[6][1].splitPath()[0]
    os.createDir(configs[0][1])
    info &"Created project directory {blue}{configs[0][1]}{dft}"
    os.createDir(configs[0][1] & pathSeparator & dirname)
    info &"Created directory {blue}{dirname}{dft}"
    writeFile(configs[0][1] & pathSeparator & "fragment.yaml", config_out)
    info &"Created metadata file {blue}fragment.yaml{dft}"

    writeFile(configs[0][1] & pathSeparator & configs[6][1], "func hello() {\nprint(\"Hello world!\")\n}")
    info &"Created entry file {blue}{configs[6][1]}{dft}"

    success "Done creating fragment. Have fun coding with Swirl!"

proc updateDB*(installPath, file:string) =
    if not os.dirExists(installPath): os.createDir(installPath)
    if (not os.fileExists(file)) or readFile(file) == "":
        let fragmentsList = newHttpClient().getContent("https://raw.githubusercontent.com/0x454d505459/tornado/fragments/packages.files")
        writeFile(file, fragmentsList)