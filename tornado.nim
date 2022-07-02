import std/[os,strformat, strutils, osproc, streams, json], libs/[tlib, utils, paths]


proc proccess_args() =
    var discard_next = false
    for i in 1..os.paramCount():
        if discard_next: discard_next = false; continue
        let arg = os.paramStr(i)
        case arg
            of "-h", "--help", "help":
                register_help(["-h", "--help"], "Show this page and quits")
                register_help(["i", "install  [ARGS]"], "Install the following fragment.s")
                register_help(["U", "updateDB"], "Updates local fragments list")
                register_help(["u", "update   [ARGS]"], "Updates local fragments")
                register_help(["r", "remove   [ARGS]"], "Remove the following fragment.s")
                register_help(["l", "list"], "Lists all installed fragments and their versions")
                register_help(["q", "query    [ARGS]"], "Look through the database for fragment.s matching the name")
                register_help(["I", "init"], "Starts the interactive fragment creation tool")
                echo help_menu
                quit(0)
            
            of "i", "install":
                # warn "Feature not implemented yet!"
                # quit(0)

                if paramCount() < i+1:
                    error "No package(s) provided" 
                
                let file = installPath & pathSeparator & "packages.files"

                if (not os.fileExists(file)) or readFile(file) == "":
                    updateDB(installPath, file)

                let fragmentsJson = readFile(file).parseJson()
                for i in (i+1)..paramCount():
                    let fragment = paramStr(i)
                    let fragmentUrl = fragmentsJson{fragment}.getStr()
                    if fragmentUrl == "": error &"Fragment {fragment} not found in local fragments list, maybe try to update the fragments list"

                    if not repoExists(fragmentUrl): error "Repo doesn't exists"

                    let git = osproc.startProcess("git", installPath, ["clone", fragmentUrl], options={poUsePath})
                    let gitOut = git.errorStream().readStr(200)
                    
                    if gitOut != "": error gitOut
                    success &"Fragment {fragment} installed"
                    
                quit(0)
            
            of "u", "update":
                warn "Feature not implemented yet!"
                quit(0)
                         
            of "r", "remove":
                if paramCount() < i+1:
                    error "No package(s) provided"
                
                var installedFragments:seq[string]
                for dir in walkDirs(installPath & "*"): installedFragments &= dir.split(pathSeparator)[^1]
                for i in (i+1)..paramCount():
                    let query = paramStr(i)
                    if not (query in installedFragments): warn &"Fragment {query} not installed! Skipping it..."; continue
                    os.removeDir(installPath & query)
                    success &"Fragment {query} uninstalled"
                
                quit(0)
            
            of "l", "list":
                for dir in walkDirs(installPath & "*"):
                    let metadata = readFile(dir & "/fragment.json").parseJson()
                    info green & metadata["base"]{"name"}.getStr() & dft & " version " & green & metadata["base"]{"version"}.getStr() & dft & " is installed at " & red & dir & dft
            
            of "U", "updateDB":
                updateDB(installPath, installPath & pathSeparator & "packages.files")
                success "Local fragments list was updated"
            
            of "q", "query":
                if paramCount() < i+1:
                    error "No package(s) provided"

                let file = installPath & pathSeparator & "packages.files"

                if (not os.fileExists(file)) or readFile(file) == "":
                    updateDB(installPath, file)
                
                let fragmentsJson = readFile(file).parseJson()
                for i in (i+1)..paramCount():
                    let query = paramStr(i)
                    var found = false
                    for elem in fragmentsJson.getElems():
                        var frgt_name = $elem
                        frgt_name = frgt_name.split(':')[0][2..^2]

                        if query in frgt_name:
                            found = true
                            let fragmentUrl = elem[frgt_name].getStr()
                            let metadata =  getMeta(fragmentUrl).parseJson()
                            let
                                author = metadata["base"]["author"].getStr()
                                name = metadata["base"]["name"].getStr()
                                version = metadata["base"]["version"].getStr()
                                description = metadata["base"]["description"].getStr()

                            echo &"""
{blue}{author}{dft}/{red}{name}{dft} {green}{version}{dft}
    {description}"""

                    if not found: warn &"No packages found for query {query}"

                quit(0)

            of "I", "init":                
                var configs = [("Display name",""),
                                ("Fragment name (id)",""),
                                ("Description",""),
                                ("Upstream URL",""),
                                ("Author",""),
                                ("Version","0.0.1"),
                                ("Entry file","src/main.sw"),
                                ("Dependencies (comma separeted)",""),
                                ("Conflicts (comma separeted)","")]
               
                for config in configs:
                    let
                        key = config[0]
                        value = config[1]
                    
                    echo dft & key & " : " & value
                    if value == "":
                        moveCursorUp 1
                        configs[configs.find(config)][1] = read(dft & key & " : ")
                    else:
                        let toEdit = read "Would you like to edit this value ? (y/n) : "
                        moveCursorUp 1
                        rmline()
                        if toEdit.toLower() == "y":
                            moveCursorUp 2
                            rmline()
                            moveCursorUp 1
                            configs[configs.find(config)][1] = read(dft & key & " : " & blue)
                        else:
                            moveCursorUp 1
                
                let config_json = %* {
                                "base": {
                                    "display-name":  configs[0][1],
                                    "name": configs[1][1],
                                    "description": configs[2][1],
                                    "author": configs[4][1],
                                    "upstream": configs[3][1],
                                    "version": configs[5][1],
                                    "entry-file": configs[6][1]
                                },
                                "dependencies":{
                                    "requires":configs[7][1].split(','),
                                    "conflics":configs[8][1].split(',')
                                    }
                                }

                echo config_json
                createProject(configs, pathSeparator, pretty(config_json, 4))
                                
            else:
                error &"Unknow option: {arg}"


when isMainModule:
    try:
        if os.paramCount() < 1:
            error "No argument provided, please check the help using 'tornado --help'" 
        proccess_args()
    except EKeyboardInterrupt:
        quit(0)