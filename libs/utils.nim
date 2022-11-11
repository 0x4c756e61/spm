import tlib, strformat, strutils, os, httpclient, osproc, streams

# Custom color set, made using escape sequences
const
    red* = tlib.rgb(255,33,81)
    green* = tlib.rgb(37,255,100)
    yellow* = tlib.rgb(246,255,69)
    blue* = tlib.rgb(105,74,255)
    dft* = def()

# First part of our help menu, options will be added latter on with the register_help() procedure
var
    helpMenu* = &"""
{red}TORNADO{dft} version {blue}0.0.1{dft}
{red}Tornado{dft} is an unofficial package (called fragments) management tool for the {blue}Swirl{dft} programming language.

{red}USAGE{dft}:
    tornado [OPTIONS] [ARG]

{red}OPTIONS{dft}:"""
    webClient: HttpClient

proc initUtils*() =
    webClient = newHttpClient()

# Basic formating for errors
proc error*(str: string) =
    stdout.writeLine &"[{red}ERROR{dft}]      {str}"
    quit(1)

# Basic formating for informations
proc info*(str: string) =
    stdout.writeLine &"[{blue}INFO{dft}]       {str}"

# Basic formating for warnings
proc warn*(str: string) =
    stdout.writeLine &"[{yellow}WARN{dft}]       {str}"

# Basic formating for successes
proc success*(str: string) =
    stdout.writeLine &"[{green}SUCCESS{dft}]    {str}" 

# Auto format the options and append them to the help menu
proc registerHelp*(calls: array[0..1,string], desc:string) =
    ## calls: an array of 2 strings representing the option in the help menu
    ## desc : a description of the command

    let options = calls.join(", ")                  # Transform the array into a string for ease of use, joining them using a comma and a space
    let thing = &"\n    {blue}{options}{dft}"       # The actual text representing the commands and it's arg (if any) colored in blue
    let space = " " * (50-len(thing))               # Dynamically generated string of spaces to align all descriptions
    help_menu &= thing & space & desc               # Add the generated line to the help menu

# Creates a project structure with the given configuration
proc createProject*(configs: array[0..8,(string,string)], pathSeparator:char, configOut:string) = 
    ## configs       : An array of 8 string tuples containing key and value pairs
    ## pathSeparator : The character to use to separate paths ('/' on Unix-like and '\' on windows)
    ## configOut    : The stringified json version of the config (what will be written to the 'fragment.json' file)

    let dirname = configs[6][1].splitPath()[0]
    # Get the name of the source directory using the path of the main file (src/main.sw)
    # config[6] returns the 7th element of the configs array wich is the entry file tuple: ("Entry file","src/main.sw")
    # config[6][1] returns the value of the 7th tuple: "src/main.sw"

    os.createDir(configs[0][1])
    # configs[0][1] returns the value of the first config tuple: ("Display name","")
    # Creates a new directory in the working one (working directory) with the name of the project (display name) 

    info &"Created project directory {blue}{configs[0][1]}{dft}"

    os.createDir(configs[0][1] & pathSeparator & dirname)
    # configs[0][1] returns the value of the first config tuple: ("Display name","")
    # pathSeparator is the character to use to separate paths ('/' on Unix-like and '\' on windows)
    # dirname is the name of the source directory
    # Creates a new source directory in the project one (separated using the pathSeparator) with a name of dirname

    info &"Created directory {blue}{dirname}{dft}"

    writeFile(configs[0][1] & pathSeparator & "fragment.json", configOut)
    # configs[0][1] returns the value of the first config tuple: ("Display name","")
    # pathSeparator is the character to use to separate paths ('/' on Unix-like and '\' on windows)
    # configOut is the stringified json version of the config (what will be written to the 'fragment.json' file)
    # Writes the configOut to a file called fragment.json in the project's directory (configs[0][1]). Paths are separeted using the pathSeparator

    info &"Created metadata file {blue}fragment.json{dft}"

    writeFile(configs[0][1] & pathSeparator & configs[6][1], "func hello() {\nprint(\"Hello world!\")\n}")
    # configs[0][1] returns the value of the first config tuple: ("Display name","")
    # pathSeparator is the character to use to separate paths ('/' on Unix-like and '\' on windows)
    # config[6][1] returns the value of the 7th tuple: "src/main.sw"
    # Writes "func hello() {\nprint(\"Hello world!\")\n}" to the main file located in the project's source directory (configs[6][1] name is already appended by the user). Paths are separeted using the pathSeparator

    info &"Created entry file {blue}{configs[6][1]}{dft}"

    success "Done creating fragment. Have fun coding with Swirl!"

# Updates the local 'packages.files' file
proc updateDB*(installPath, file:string) =
    ## installPath is the directory where we should install the packages
    ## file is the file name and path to the 'packages.files' file

    if not os.dirExists(installPath): os.createDir(installPath)
    # Check if the directory where we install packages exists, creating it if it doesn't

    let fragmentsList = webClient.getContent("https://raw.githubusercontent.com/0x454d505459/tornado/fragments/packages.files")
    # Create a new web client and that will get the raw data from 'https://raw.githubusercontent.com/0x454d505459/tornado/fragments/packages.files'

    writeFile(file, fragmentsList)
    # Create or overwrite the file located at 'file' with the content of 'fragmentsList'

# Checks if a repo exists or not
proc repoExists*(link:string):bool =
    return webClient.get(link).status != "404"
    # Create a new web client that will make a request to 'link' and return the result of the logical operation 'status != "404"'

# Returns the raw json from the github repo
proc getMeta*(url:string):string =
    ## url : the url to the github repository
    let
        userName = url.split("/")[3]            # Parse the username of the owner from the link :  ["https:", "", "github.com", "0x454d505459", "tornado"]
        repoName = url.split("/")[4][0..^5]     # Get the name of the repository without the ".git"

    return webClient.getContent("https://raw.githubusercontent.com/" & userName & "/" & repoName & "/main/fragment.json")
    # Create a new web client that will get the raw content of the fragment's metadata file : "https://raw.githubusercontent.com/0x454d505459/tornado/main/fragment.json"

# Clones the git repos in the installation directory
proc installFragment*(installPath, fragmentUrl:string) =
    ## installPath : path to the fragment's directory
    ## fragmentUrl : the url to the git repo to clone

    let git = osproc.startProcess("git", installPath, ["clone", fragmentUrl, "--quiet"], options={poUsePath})
    # --quite is to fix git printing some string into the stderr. That way it only outputs errors
    # poUsePath tells the parent proccess (this program) to check for 'git' in it's parent's env
    # create a new 'git' child process working in the 'installPath' directory and clone the fragment's repo

    let gitOut = git.errorStream().readStr(200)
    # read the first 200 characters from the 'git' process's stderr
    
    if gitOut != "": error gitOut
    # Forward the errors (if any) to our stderr
