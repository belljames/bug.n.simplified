/*
:title:     bug.n X/app/main
:copyright: (c) 2019-2020 by joten <https://github.com/joten>
:license:   GNU General Public License version 3

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
*/

;; script settings
#NoEnv ;; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn ;; Enable warnings to assist with detecting common errors.
SendMode Input ;; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir% ;; Ensures a consistent starting directory.
#Persistent
#SingleInstance Force
#WinActivateForce
DetectHiddenText, Off
DetectHiddenWindows, Off
OnExit("exitApp")
SetBatchLines, -1
SetControlDelay, 0
SetMouseDelay, 0
SetTitleMatchMode, 3 ;; `TitleMatchMode` may be set to `RegEx` to enable a wider search, but should be reset afterwards.
SetWinDelay, 0 ;; `WinDelay` may be set to a different value e.g. 10, if necessary to prevent timing issues, but should be reset afterwards.

;; pseudo main function
logger := New Logging() ;; Primarily the cache will be written to a web interface
;; allowing text formatting with HTML tags: bold = <b>text</b>
;; , highlight = <mark>text</mark>, italic = <i>text</i>
;; , strikethrough = <s>text</s>, underline = <u>text</u>
const := New Constants()
app := New Application("bug.n X", "0.0.4")

cfg := New Configuration()
custom := New Customizations()
custom._init()

mgr := New GeneralManager()
logger.log(app.name . " started.")

eventHookAdr1 := RegisterCallback( "_onWinMinRestore", "F" )
hWinEventHook1 := SetWinEventHook( 0x16, 0x17, 0, eventHookAdr1, 0, 0, 0 )

eventHookAdr2 := RegisterCallback( "_onWinMax", "F" )
hWinEventHook2 := SetWinEventHook( 0x800B, 0x800B, 0, eventHookAdr2, 0, 0, 0 )

tray := New TrayIcon()

Return

;; end of the auto-execute section

;; function, label & object definitions
class Application {
  __New(name, version) {
    Global logger

    this.name := name
    this.version := version
    ;this.logo := A_ScriptDir . "\assets\logo.ico"
    ;Menu, Tray, NoIcon
    ;this.uifaces := []

    this.processId := DllCall("GetCurrentProcessId", "UInt")
    DetectHiddenWindows, On
    this.windowId := Format("0x{:x}", WinExist("ahk_pid " . this.processId))
    DetectHiddenWindows, Off
    logger.info("Window with id <mark>" . this.windowId . "</mark> identified as the one of " . this.name . "'s process.", "Application.__New")
  }
}

exitApp() {
  Global app, cfg, logger, mgr, hWinEventHook1, hWinEventHook2

  ;; Reset the main objects triggering their __Delete function.
  cfg := ""
  mgr := ""

  nCheck := DllCall( "UnhookWinEvent", Ptr,hWinEventHook1 )
  DllCall( "CoUninitialize" )

  nCheck := DllCall( "UnhookWinEvent", Ptr,hWinEventHook2 )
  DllCall( "CoUninitialize" )

  logger.warning("Exiting " . app.name . ".", "exitApp")

}

SetWinEventHook(eventMin, eventMax, hmodWinEventProc, lpfnWinEventProc, idProcess, idThread, dwFlags)
{
  DllCall("CoInitialize", Uint, 0)
  return DllCall("SetWinEventHook"
    , Uint,eventMin
    , Uint,eventMax
    , Uint,hmodWinEventProc
    , Uint,lpfnWinEventProc
    , Uint,idProcess
    , Uint,idThread
    , Uint,dwFlags)
}

_onWinMinRestore( hWinEventHook, Event, hWnd, idObject, idChild, dwEventThread, dwmsEventTime )
{
  global mgr
  Event += 0, hWnd += 0, idObject += 0, idChild += 0

  if (hWnd != 0){

    if ( Event = 0x0016 )
    {
      Message = EVENT_SYSTEM_MINIMIZESTART
    }
    else if ( Event = 0x0017 )
    {
      Message = EVENT_SYSTEM_MINIMIZEEND
    }

    if ( Message == "" ) {
      return
    }

    Sleep, 50 ; give a little time for WinGetTitle/WinGetActiveTitle functions, otherwise they return blank

    wnd := mgr.getWindow(hWnd)
    mgr.setWindowFloating(wnd, wnd.minMax != 0)
    If (IsObject(wnd.workArea))
    {
      wnd.workArea.arrange()
    }
  }
  ;; debugging
  ;;mgr.showWindowInformation(hWnd)
}

_onWinMax( hWinEventHook, Event, hWnd, idObject, idChild, dwEventThread, dwmsEventTime )
{
  global mgr
  Event += 0, hWnd += 0, idObject += 0, idChild += 0

  if (hWnd != 0){

    WinGet, v_minmax, MinMax, hWnd

    if ( Event = 0x800B && v_minmax == 1 )
    {
      Message = EVENT_OBJECT_LOCATIONCHANGE
    }
    Else
    {
      return
    }

    Sleep, 50 ; give a little time for WinGetTitle/WinGetActiveTitle functions, otherwise they return blank

    wnd := mgr.getWindow(hWnd)
    mgr.setWindowFloating(wnd, wnd.minMax != 0)
    If (IsObject(wnd.workArea))
    {
      wnd.workArea.arrange()
    }
  }
  ;; debugging
  ;;mgr.showWindowInformation(hWnd)
}

#Include, %A_ScriptDir%\constants.ahk
#Include, %A_ScriptDir%\desktop-manager.ahk
#Include, %A_ScriptDir%\general-manager.ahk
#Include, %A_ScriptDir%\logging.ahk
#Include, %A_ScriptDir%\monitor-manager.ahk
#Include, %A_ScriptDir%\window.ahk
#Include, %A_ScriptDir%\work-area.ahk
#Include, %A_ScriptDir%\..\etc\custom.ahk
#Include, %A_ScriptDir%\keybindings.ahk
#Include, %A_ScriptDir%\tray-icon.ahk