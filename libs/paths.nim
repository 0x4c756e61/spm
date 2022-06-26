import os

when defined(windows):
    const 
        pathSeparator* = '\\'
    let    
        installPath = os.getEnv("APPDATA") & "\\local\\tornado\\packages\\"

else:
    const 
        pathSeparator* = '/'
    let
        installPath* = os.getEnv("HOME") & "/.tornado/packages/"