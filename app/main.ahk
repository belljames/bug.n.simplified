/*
:title:     bug.n X/app/main
:copyright: (c) 2019-2020 by joten <https://github.com/joten>
:license:   GNU General Public License version 3

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
*/

;; script settings
#NoEnv                        ;; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn                         ;; Enable warnings to assist with detecting common errors.
SendMode Input                ;; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%   ;; Ensures a consistent starting directory.
#Persistent
#SingleInstance Force
#WinActivateForce
DetectHiddenText, Off
DetectHiddenWindows, Off
OnExit("exitApp")
SetBatchLines,    -1
SetControlDelay,   0
SetMouseDelay,     0
SetTitleMatchMode, 3          ;; `TitleMatchMode` may be set to `RegEx` to enable a wider search, but should be reset afterwards.
SetWinDelay,       0          ;; `WinDelay` may be set to a different value e.g. 10, if necessary to prevent timing issues, but should be reset afterwards.

;; pseudo main function
  logger := New Logging()     ;; Primarily the cache will be written to a web interface
                              ;; allowing text formatting with HTML tags: bold = <b>text</b>
                              ;; , highlight = <mark>text</mark>, italic = <i>text</i>
                              ;; , strikethrough = <s>text</s>, underline = <u>text</u>
  const := New Constants()
  app := New Application("bug.n X", "0.0.3")
  
  cfg := New Configuration()
  custom := New Customizations()
  custom._init()
  
  mgr := New GeneralManager()
  logger.log(app.name . " started.")


    !k::mgr.activateWindowAtIndex(,, -1)
    !j::mgr.activateWindowAtIndex(,, +1)

    #+Left::mgr.setLayoutProperty("nmaster",, +1)
    #+Right::mgr.setLayoutProperty("nmaster",, -1)

    !h::mgr.setLayoutProperty("mfact",, -0.05)
    !l::mgr.setLayoutProperty("mfact",, +0.05)

    !+k::mgr.moveWindowToPosition(,, -1)
    !+j::mgr.moveWindowToPosition(,, +1)
    !+Enter::mgr.moveWindowToPosition(, 1, 0)

    #^i::mgr.showWindowInformation()

    !q::mgr.closeWindow()

    #t::mgr.switchToLayout(1)
    #m::mgr.switchToLayout(2)
    #b::mgr.switchToLayout(3)
    #f::mgr.switchToLayout(4)

    !Backspace::mgr.switchToLayout(, +1)
    !+Backspace::mgr.switchToLayout(-1)
    #Space::mgr.toggleWindowIsFloating()

    !1::mgr.switchToDesktop(1)
    !2::mgr.switchToDesktop(2)
    !3::mgr.switchToDesktop(3)
    !4::mgr.switchToDesktop(4)

    ;;!+Tab::mgr.switchToDesktop(-1)

    #!Left::mgr.switchToDesktop(, -1, True)
    #!Right::mgr.switchToDesktop(, +1, True)

    !+0::mgr.moveWindowToDesktop(, 0)
    !+1::mgr.moveWindowToDesktop(, 1)
    !+2::mgr.moveWindowToDesktop(, 2)
    !+3::mgr.moveWindowToDesktop(, 3)
    !+4::mgr.moveWindowToDesktop(, 4)

    #^+Left::mgr.moveWindowToDesktop(,, -1)
    #^+Right::mgr.moveWindowToDesktop(,, +1)

    #,::mgr.switchToWorkArea(, -1)
    #.::mgr.switchToWorkArea(, +1)

    #Enter::mgr.moveWindowToWorkArea()
    #+,::mgr.moveWindowToWorkArea(,, -1)
    #+.::mgr.moveWindowToWorkArea(,, +1)

    ;; bug.n x.min
    ;#+q::mgr.moveWindowToPosition(, 1)
    ;#+w::mgr.moveWindowToPosition(, 2)
    ;#+e::mgr.moveWindowToPosition(, 3)
    ;#+a::mgr.moveWindowToPosition(, 4)
    ;#+s::mgr.moveWindowToPosition(, 5)
    ;#+d::mgr.moveWindowToPosition(, 6)
    ;#+y::mgr.moveWindowToPosition(, 7)
    ;#+x::mgr.moveWindowToPosition(, 8)
    ;#+c::mgr.moveWindowToPosition(, 9)

    #^l::logger.setLevel(, -1)
    #^+l::logger.setLevel(, +1)
    #+l::logger.writeCacheToFile(A_WorkingDir . "\..\..\bug.n-log.md")
    #^q::ExitApp
    #^r::Reload




;; end of the auto-execute section

;; function, label & object definitions
class Application {
  __New(name, version) {
    Global logger
    
    this.name := name
    this.version := version
    this.logo := A_ScriptDir . "\assets\logo.ico"
    Menu, Tray, NoIcon
    this.uifaces := []
    
    this.processId := DllCall("GetCurrentProcessId", "UInt")
    DetectHiddenWindows, On
    this.windowId  := Format("0x{:x}", WinExist("ahk_pid " . this.processId))
    DetectHiddenWindows, Off
    logger.info("Window with id <mark>" . this.windowId . "</mark> identified as the one of " . this.name . "'s process.", "Application.__New")
  }
}

exitApp() {
  Global app, cfg, logger, mgr
  
  ;; Reset the main objects triggering their __Delete function.
  cfg := ""
  mgr := ""
  
  logger.warning("Exiting " . app.name . ".", "exitApp")
}

#Include, %A_ScriptDir%\constants.ahk
#Include, %A_ScriptDir%\desktop-manager.ahk
#Include, %A_ScriptDir%\general-manager.ahk
#Include, %A_ScriptDir%\logging.ahk
#Include, %A_ScriptDir%\monitor-manager.ahk
#Include, %A_ScriptDir%\window.ahk
#Include, %A_ScriptDir%\work-area.ahk
#Include, %A_ScriptDir%\modules\user-interfaces\tray-icon-user-interface.ahk
#Include, %A_ScriptDir%\..\etc\custom.ahk


