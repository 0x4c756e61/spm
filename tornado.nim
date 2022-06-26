import std/[os,strformat, strutils, osproc, streams], libs/[tlib, utils, paths]


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
                register_help(["r", "remove   [ARGS]"], "Remove the following fragment.s")
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

                updateDB(installPath, file)
                
                let content = readFile(file)
                for i in (i+1)..paramCount():
                    let fragment = paramStr(i)
                    if not (fragment in content): 
                        error &"Fragment {fragment} not found in local fragments list, maybe try to update the fragments list"
                    
                    let git = osproc.startProcess("git", installPath, ["clone", fragment], options={poUsePath})
                    let gitOut = git.errorStream().readStr(200)
                    
                    if gitOut == "":
                         success &"Fragment {fragment} installed"
                    
                    error gitOut
                    

                quit(0)
                         
            of "r", "remove":
                warn "Feature not implemented yet!"
                quit(0)
            
            of "U", "updateDB":
                updateDB(installPath, installPath & pathSeparator & "packages.files")
                success "Local fragments list was updated"
            
            of "q", "query":
                warn "Feature not implemented yet!"
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
                
                let config_out = &"""
frgt-base:
  frgt-display-name: "{configs[0][1]}"
  frgt-name: "{configs[1][1]}"
  frgt-description: "{configs[2][1]}"
  frgt-upstream: "{configs[3][1]}"
  frgt-author: "{configs[4][1]}"
  frgt-ver: {configs[5][1]}
  frgt-entry-file: "{configs[6][1]}"

frgt-deps:
  requires: {($(configs[7][1].split(',')))[1..^1]}
  conflicts: {($(configs[8][1].split(',')))[1..^1]}
"""
                # echo config_out
                createProject(configs, pathSeparator, config_out)
                                
            else:
                error &"Unknow option: {arg}"


when isMainModule:
    try:
        if os.paramCount() < 1:
            error "No argument provided, please check the help using 'tornado --help'" 
        proccess_args()
    except EKeyboardInterrupt:
        quit(0)