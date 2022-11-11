import std/[os,strformat, strutils, json], libs/[tlib, utils, paths]

var 
    file:string
    installed: seq[string]
    fragmentsJson: JsonNode
    configs = [("Display name",""),
                ("Fragment name (id)",""),
                ("Description",""),
                ("Upstream URL",""),
                ("Author",""),
                ("Version","0.0.1"),
                ("Entry file","src/main.sw"),
                ("Dependencies (comma separeted)",""),
                ("Conflicts (comma separeted)","")]

proc updateInstalled() =
    installed = @[]
    for dir in walkDirs(installPath & "*"): installed.add(dir.split(pathSeparator)[^1])

proc initSelf() =
    registerHelp(["-h", "--help"], "Show this page and quits")
    registerHelp(["i", "install  [ARGS]"], "Install the following fragment.s")
    registerHelp(["U", "update"], "Updates local fragments list")
    registerHelp(["u", "upgrade"], "Updates local fragments")
    registerHelp(["r", "remove   [ARGS]"], "Remove the following fragment.s")
    registerHelp(["l", "list"], "Lists all installed fragments and their versions")
    registerHelp(["q", "query    [ARGS]"], "Look through the database for fragment.s matching the name")
    registerHelp(["I", "init"], "Starts the interactive fragment creation tool")
    file = installPath & "packages.files"
    fragmentsJson = readFile(file).parseJson()
    updateInstalled()
    if (not os.fileExists(file)) or readFile(file) == "": updateDB(installPath, file)

proc processArgs() =
    var discardNext = false
    for i in 1..os.paramCount():
        if discardNext: discardNext = false; continue
        let arg = os.paramStr(i)
        case arg
            of "-h", "--help", "help":
                echo helpMenu
                quit(0)
            
            of "i", "install":

                if paramCount() < i+1:
                    error "No package(s) provided" 
                
                # let file = installPath & pathSeparator & "packages.files"

                if (not os.fileExists(file)) or readFile(file) == "":
                    updateDB(installPath, file)

                # let fragmentsJson = readFile(file).parseJson()
                # var installed: seq[string]
                # for dir in walkDirs(installPath & "*"): installed.add(dir)
                for i in (i+1)..paramCount():
                    let fragment = paramStr(i)
                    let fragmentUrl = fragmentsJson{fragment}.getStr()
                    if fragmentUrl == "": error &"Fragment '{fragment}' not found in local fragments list, maybe try to update the fragments list"

                    if not repoExists(fragmentUrl): error "Repo doesn't exists"
                    info "Installing fragment using git"
                    installFragment(installPath, fragmentUrl)
                    updateInstalled()
                    success &"Fragment {fragment} installed"
                    info "Processing dependencies and conflics..."
                    proc recurse(fragment:string) =
                        let metadata = readFile(installPath & fragment & "/fragment.json").parseJson()
                        let deps = metadata["dependencies"]["requires"].getElems()
                        # let conflics = metadata["dependencies"]["conflics"].getElems()
                        for dep in deps:
                            let dependency = dep.getStr()
                            let fragmentUrl = fragmentsJson{dependency}.getStr()
                            if dependency in installed : info &"Dependency '{dependency}' already installed, skipping...";continue
                            if fragmentUrl == "": warn &"Dependency '{dependency}' not found in local fragments list, you might need to install it manually"; continue
                            installFragment(installPath, fragmentUrl)
                            updateInstalled()
                            success &"Fragment {dependency} installed"
                            recurse(dependency)
                    
                    recurse(fragment)
                    info "Done processing dependencies and conflics"

                    
                quit(0)
            
            of "u", "upgrade":
                for dir in walkDirs(installPath & "*"):
                    let localMeta = readFile(dir & "/fragment.json").parseJson()
                    let remoteMeta = getMeta(localMeta["base"]["upstream"].getStr()).parseJson()
                    
                    let
                        localVer = localMeta["base"]["version"].getStr()
                        remoteVer = remoteMeta["base"]["version"].getStr()
                        upstream = localMeta["base"]["upstream"].getStr()
                        name =  localMeta["base"]["name"].getStr()

                    if localVer != remoteVer:
                        os.removeDir(dir)
                        installFragment(installPath, upstream)
                        updateInstalled()
                        success "Updated " & blue & name & dft & " from version " & red & localVer & dft & " to " & green & remoteVer & dft
                    
                    else:
                        info green & name & dft & " is up to date, skipping"
                
                quit(0)
                         
            of "r", "remove":
                if paramCount() < i+1:
                    error "No package(s) provided"
                
                # var installedFragments:seq[string]
                # for dir in walkDirs(installPath & "*"): installedFragments &= dir.split(pathSeparator)[^1]
                for i in (i+1)..paramCount():
                    let query = paramStr(i)
                    if not (query in installed): warn &"Fragment {query} not installed! Skipping it..."; continue
                    os.removeDir(installPath & query)
                    updateInstalled()
                    success &"Fragment {query} uninstalled"
                
                quit(0)
            
            of "l", "list":
                for dir in walkDirs(installPath & "*"):
                    let metadata = readFile(dir & "/fragment.json").parseJson()
                    info green & metadata["base"]{"name"}.getStr() & dft & " version " & green & metadata["base"]{"version"}.getStr() & dft & " is installed at " & red & dir & dft
            
            of "U", "update":
                updateDB(installPath, installPath & pathSeparator & "packages.files")
                success "Local fragments list was updated"
            
            of "q", "query":
                if paramCount() < i+1:
                    error "No package(s) provided"

                # let file = installPath & pathSeparator & "packages.files"

                if (not os.fileExists(file)) or readFile(file) == "":
                    updateDB(installPath, file)
                
                let fragmentsJson = readFile(file).parseJson()
                for i in (i+1)..paramCount():
                    let query = paramStr(i)
                    var found = false

                    for name in fragmentsJson.keys:
                        if query in name:
                            found = true
                            let fragmentUrl = fragmentsJson[name].getStr()
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
                # var configs = [("Display name",""),
                #                 ("Fragment name (id)",""),
                #                 ("Description",""),
                #                 ("Upstream URL",""),
                #                 ("Author",""),
                #                 ("Version","0.0.1"),
                #                 ("Entry file","src/main.sw"),
                #                 ("Dependencies (comma separeted)",""),
                #                 ("Conflicts (comma separeted)","")]
               
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
                
                let configJson = %* {
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

                echo configJson
                createProject(configs, pathSeparator, pretty(configJson, 4))
                                
            else:
                error &"Unknow option: {arg}"

when isMainModule:
    try:
        if os.paramCount() < 1:
            error "No argument provided, please check the help using 'tornado --help'" 
        
        initUtils()
        initSelf()
        processArgs()
    except EKeyboardInterrupt:
        quit(0)
