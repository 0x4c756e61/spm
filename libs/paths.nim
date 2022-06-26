import os

when defined(windows):
    const 
        pathSeparator* = '\\'
    let    
        installPath = os.getEnv("APPDATA") & "\\local\\lpm\\packages\\"

else:
    const 
        pathSeparator* = '/'
    let
        installPath* = os.getEnv("HOME") & "/.lpm/packages/"