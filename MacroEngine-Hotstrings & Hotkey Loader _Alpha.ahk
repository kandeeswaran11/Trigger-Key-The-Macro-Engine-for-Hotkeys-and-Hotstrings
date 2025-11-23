;,vt,mt,tnkat,vk,srj,jsr
#Requires AutoHotkey v2.0
#SingleInstance Force 
Pause::Pause -1  ; The Pause/Break key.
#Requires AutoHotkey v2
#SingleInstance Force

filePath := A_ScriptDir "\hotstring.txt"
logFilePath := A_ScriptDir "\logfile.txt"

; Global counters for loaded macros
global hotstringCount := 0
global hotkeyCount := 0

;---------------------------
; LOAD ALL MACROS
;---------------------------
if !FileExist(filePath) {
    MsgBox "Error: hotstring.txt not found."
    ExitApp
}

; Initialize log file
;------------------------------------------------------------
FileDelete(logFilePath)
FileAppend("========================================`n", logFilePath, "UTF-8")
FileAppend("AutoHotkey Macro Loader - Log File`n", logFilePath, "UTF-8")
FileAppend("Started: " A_Now "`n", logFilePath, "UTF-8")
FileAppend("========================================`n`n", logFilePath, "UTF-8")

; Load initial file
;------------------------------------------------------------
LoadMacroFile(filePath)

; Show summary message
;------------------------------------------------------------
ShowLoadSummary()

; Setup hotkeys for loading additional files
;------------------------------------------------------------

Hotkey("^!l", (*) => LoadFileDialog())  ; Ctrl+Alt+L to open file picker

^!g::ToggleGuiVisibility ; Ctrl + Alt + G

; Start CreateDragDropGUI function
;------------------------------------------------------------

CreateDragDropGUI()

; FUNCTION: Toggle GUI (show/hide)
;------------------------------------------------------------
ToggleGuiVisibility() {
    ; Check if the window is currently visible or active
    ; WinExist(ddGui.Hwnd) checks if the window handle exists (it does if shown)
    if WinExist(ddGui.Hwnd) and WinActive(ddGui.Hwnd) {
        ddGui.Hide()
    } else {
        ddGui.Show()
    }
}

;---------------------------
; CREATE DRAG AND DROP GUI
;---------------------------
CreateDragDropGUI() {
    global ddGui := Gui("+AlwaysOnTop +ToolWindow", "Macro Loader")
    ddGui.BackColor := "0x2C3E50"
    ddGui.SetFont("s10 c0xECF0F1", "Segoe UI")
    
    ddGui.Add("Text", "x20 y10 w260 h30 Center", "Drag & Drop .txt files here")
    ddGui.Add("Text", "x20 y40 w260 h20 Center c0x3498DB", "or press Ctrl+Alt+L to browse")
    
    global statusText := ddGui.Add("Text", "x20 y70 w260 h60 Center c0x2ECC71", 
        "Hotstrings: " hotstringCount "`nHotkeys: " hotkeyCount "`nTotal: " (hotstringCount + hotkeyCount))
    
    btnLoad := ddGui.Add("Button", "x20 y140 w120 h30", "Browse File")
    btnLoad.OnEvent("Click", (*) => LoadFileDialog())
    
    btnReload := ddGui.Add("Button", "x160 y140 w120 h30", "Reload Main")
    btnReload.OnEvent("Click", (*) => ReloadMainFile())
    
    ddGui.Show("w300 h180 x900 yCenter")
	
	
    
    ; Enable drag and drop
	;ddGui.OnEvent("DropFiles", WM_DROPFILES)
/*DllCall("DragAcceptFiles", "Ptr", ddGui.Hwnd, "Int", 1)
OnMessage(0x233, WM_DROPFILES)
*/
DllCall("shell32\DragAcceptFiles", "Ptr", ddGui.Hwnd, "Int", 1)
OnMessage(0x233, WM_DROPFILES)
}

;---------------------------
; HANDLE DROPPED FILES
;---------------------------
WM_DROPFILES(wParam, lParam, msg, hwnd) {
    global ddGui
    
    if (hwnd != ddGui.Hwnd)
        return
    
    ; Get number of files dropped
    fileCount := DllCall("Shell32\DragQueryFile", "Ptr", wParam, "UInt", 0xFFFFFFFF, "Ptr", 0, "UInt", 0)
    
    Loop fileCount {
        ; Get file path
        bufferSize := 260
        VarSetStrCapacity(&filePath, bufferSize)
        DllCall("Shell32\DragQueryFile", "Ptr", wParam, "UInt", A_Index - 1, "Str", filePath, "UInt", bufferSize)
        
        ; Check if it's a .txt file
        if RegExMatch(filePath, "\.txt$", "i") {
            LoadMacroFile(filePath)
        } else {
            MsgBox("Only .txt files are supported!`n`nFile: " filePath, "Invalid File", "Icon! 48")
        }
    }
    
    ; Finish drag and drop
    DllCall("Shell32\DragFinish", "Ptr", wParam)
    
    ; Update status display
    UpdateStatusDisplay()
}

;---------------------------
; FILE PICKER DIALOG
;---------------------------
LoadFileDialog() {
    selectedFile := FileSelect(3, , "Select Macro File", "Text Files (*.txt)")
    
    if (selectedFile != "") {
        LoadMacroFile(selectedFile)
        UpdateStatusDisplay()
		ShowLoadSummary()
    }
}

;---------------------------
; RELOAD MAIN FILE
;---------------------------
ReloadMainFile() {
    result := MsgBox("This will reload the script and reset all macros.`n`nContinue?", 
        "Reload Script", "YesNo Icon? 32")
    
    if (result = "Yes") {
        Reload
    }
}

;---------------------------
; UPDATE STATUS DISPLAY
;---------------------------
UpdateStatusDisplay() {
    global statusText, hotstringCount, hotkeyCount
    statusText.Value := "Hotstrings: " hotstringCount "`nHotkeys: " hotkeyCount "`nTotal: " (hotstringCount + hotkeyCount)
}

;---------------------------
; SHOW LOAD SUMMARY
;---------------------------
ShowLoadSummary() {
    global hotstringCount, hotkeyCount, logFilePath
    
    totalMacros := hotstringCount + hotkeyCount
    summaryMsg := "Macro Loader - Initial Load Complete!`n`n"
    summaryMsg .= "✓ Hotstrings Loaded: " hotstringCount "`n"
    summaryMsg .= "✓ Hotkeys Loaded: " hotkeyCount "`n"
    summaryMsg .= "✓ Total Macros: " totalMacros "`n`n"
    summaryMsg .= "Press Ctrl+Alt+L to load more files`n"
    summaryMsg .= "Or drag & drop .txt files to the control panel`n`n"
    summaryMsg .= "Log file: " logFilePath
    
    MsgBox(summaryMsg, "Load Complete", "Iconi 64 T5")
}

;---------------------------
; LOAD MACRO FILE FUNCTION
;---------------------------
LoadMacroFile(targetFile) {
    global hotstringCount, hotkeyCount, logFilePath
    
    if !FileExist(targetFile) {
        MsgBox("File not found: " targetFile, "Error", "Icon! 16")
        return
    }
    
    fileContent1 := FileRead(targetFile, "UTF-8")
    OutputDebug("---- Loading File: " targetFile " ----")
    
    FileAppend("`n--- Loading: " targetFile " ---`n", logFilePath, "UTF-8")
    
    ; Parse using state machine
    lines := StrSplit(fileContent1, "`n", "`r")
    state := "IDLE"  ; IDLE, IN_TT, IN_KT, COLLECTING
    currentTrigger := ""
    currentType := ""
    commandLines := []
    
    for line in lines {
        line := Trim(line)
        
        ; Skip empty lines and comment lines
        if (line = "" || RegExMatch(line, "^;"))
            continue
        
        ; State: Looking for block start
        if (state = "IDLE") {
            if RegExMatch(line, "^<TT>(.*)$", &m) {
                currentType := "TT"
                currentTrigger := Trim(m[1])
                state := "IN_TT"
                OutputDebug("Found TT block: '" currentTrigger "'")
            }
            else if RegExMatch(line, "^<KT>(.*)$", &m) {
                currentType := "KT"
                currentTrigger := Trim(m[1])
                state := "IN_KT"
                OutputDebug("Found KT block: '" currentTrigger "'")
            }
            continue
        }
        
        ; State: Inside TT block, looking for <START>
        if (state = "IN_TT") {
            if (line = "<START>") {
                state := "COLLECTING"
                commandLines := []
            }
            continue
        }
        
        ; State: Inside KT block, looking for <START>
        if (state = "IN_KT") {
            if (line = "<START>") {
                state := "COLLECTING"
                commandLines := []
            }
            continue
        }
        
        ; State: Collecting command lines
        if (state = "COLLECTING") {
            if (line = "<END>") {
                ; Register the hotstring/hotkey
                if (currentTrigger != "" && commandLines.Length > 0) {
                    cmdText := ""
                    for cmdLine in commandLines {
                        if (cmdText != "")
                            cmdText .= "`n"
                        cmdText .= cmdLine
                    }
                    
                    if (currentType = "TT") {
                        ; Create wrapper function to capture value, not reference
                        RegisterHotstring(currentTrigger, cmdText)
                        hotstringCount++
                        OutputDebug("Registered TT: '" currentTrigger "' with " commandLines.Length " lines")
                        FileAppend("[" hotstringCount "] Hotstring: " currentTrigger "`n", logFilePath, "UTF-8")
                    }
                    else if (currentType = "KT") {
                        ; Create wrapper function to capture value, not reference
                        RegisterHotkey(currentTrigger, cmdText)
                        hotkeyCount++
                        OutputDebug("Registered KT: '" currentTrigger "' with " commandLines.Length " lines")
                        FileAppend("[" hotkeyCount "] Hotkey: " currentTrigger "`n", logFilePath, "UTF-8")
                    }
                }
                
                ; Reset to IDLE state
                state := "IDLE"
                currentTrigger := ""
                currentType := ""
                commandLines := []
            }
            else if (line != "") {
                ; Add non-empty lines to command collection
                commandLines.Push(line)
            }
            continue
        }
    }
    
    OutputDebug("---- File Load Complete: " targetFile " ----")
}

;---------------------------
; Helper functions to properly capture variables
;---------------------------
RegisterHotstring(trigger, commands) {
    ; This function creates a proper closure with value capture
    Hotstring(":*:" trigger, (*) => RunMacro(commands))
}

RegisterHotkey(key, commands) {
    ; This function creates a proper closure with value capture
    Hotkey(key, (*) => RunMacro(commands))
}

;---------------------------
; MACRO EXECUTION ENGINE
;---------------------------
RunMacro(scriptText) {
    OutputDebug("---- Executing Macro ----`n" scriptText "`n----")
    
    typingDelay := 10
    lines := StrSplit(scriptText, "`n", "`r")
    
    for rawLine in lines {
        line := Trim(rawLine)
        if (line = "")
            continue
        
        ; --- Check for commands that start with < first ---
        if RegExMatch(line, "^<DE\s+(\d+)>", &m) {
            typingDelay := Integer(m[1])
        }
        else if RegExMatch(line, "^<WAIT\s+(\d+)>", &m) {
            Sleep Integer(m[1])
        }
        else if RegExMatch(line, "^<LCLICK>\s+(\d+)\s+(\d+)(?:\s+(\d+))?", &m) {
            clicks := m[3] ? Integer(m[3]) : 1
            MouseClick("left", Integer(m[1]), Integer(m[2]), clicks)
        }
        else if RegExMatch(line, "^<RCLICK>\s+(\d+)\s+(\d+)(?:\s+(\d+))?", &m) {
            clicks := m[3] ? Integer(m[3]) : 1
            MouseClick("right", Integer(m[1]), Integer(m[2]), clicks)
        }
        else if RegExMatch(line, "^<MCLICK>\s+(\d+)\s+(\d+)(?:\s+(\d+))?", &m) {
            clicks := m[3] ? Integer(m[3]) : 1
            MouseClick("middle", Integer(m[1]), Integer(m[2]), clicks)
        }
        else if RegExMatch(line, "^<LAUNCH>(.+)", &m) {
            Run Trim(m[1])
        }
        else if RegExMatch(line, "^<WINACTIVATE>(.+)", &m) {
            WinActivate Trim(m[1])
        }
        else if RegExMatch(line, "^<MSGBOX>(.+)", &m) {
            MsgBox Trim(m[1])
        }
        else if RegExMatch(line, "^<SEND>(.+)", &m) {
            TypeText(Trim(m[1]), typingDelay)
        }
        else if (line = "<ENTER>") {
            Send("{Enter}")
        }
        else if (line = "<TAB>") {
            Send("{Tab}")
        }
		else if RegExMatch(line, "^<SL>(.+)", &m) {
            SL_TypeText(Trim(m[1]), typingDelay)			
        }
        else {
            ; Plain text line - type it and press Enter
            TypeText(line, typingDelay)
            Send("{Enter}")
        }
    }
    
    OutputDebug("---- Macro End ----")
}

;---------------------------
; Helper: literal text typing with optional delay
;---------------------------
TypeText(text, perCharDelay := 10) {
    if (perCharDelay > 0) {
        for ch in StrSplit(text) {
            Send("{Text}" . ch)
            Sleep perCharDelay
        }
    } else {
        Send("{Text}" . text)
    }
}
SL_TypeText(text, perCharDelay := 10) {
	   SetKeyDelay perCharDelay
       SendEvent(text)
	   SetKeyDelay 10
    
}
