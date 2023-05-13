/*
:title:     bug.n X/etc/custom
:copyright: (c) 2019-2020 by joten <https://github.com/joten>
:license:   GNU General Public License version 3

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

This file should include (`#Include`)

* one of the modules\configuration\*.ahk files
* selected modules\layouts\*-layout.ahk files
* selected modules\user-interfaces\*-user-interface.ahk files

and any additional custom code (functions or modules). This file itself is included at the end of
the main script and after the auto-execute section. The class `Customizations` is instantiated
after the class `Configuration` given by `#Include, %A_ScriptDir%\modules\configuration\*.ahk`,
which allows overwriting configuration variables by putting them in `__New`. The function `_init`
is called at the end of the auto-execute section, therewith commands can be executed after bug.n
started by putting them in there.
*/

#Include, %A_ScriptDir%\modules\configuration\default.ahk

#Include, %A_ScriptDir%\modules\layouts\dwm-bottom-stack-layout.ahk
#Include, %A_ScriptDir%\modules\layouts\dwm-monocle-layout.ahk
#Include, %A_ScriptDir%\modules\layouts\dwm-tile-layout.ahk
#Include, %A_ScriptDir%\modules\layouts\floating-layout.ahk

;; Custom code.
class Customizations {
  __New() {
    Global cfg, logger

    cfg.layoutGap := 2

    ;; Overwrite cfg.* variables.
    ;; The rules in `windowManagementRules` are processed in the order of the array.
    ;; A `windowManagementRules` array item should be an object, which may contain the following keys:
    ;;    `windowProperties`, `tests`, `commands`, `functions` and `break`.
    ;; `windowProperties` should be an object, which may contain the following keys:
    ;;    `title`, `class`, `style`, `exStyle`, `pId`, `pName`, `pPath`,
    ;;    `hasCaption`, `isAppWindow`, `isChild`, `isCloaked`, `isElevated`, `isGhost`, `isPopup` and `minMax`.
    ;; `tests` should be an array of objects containing the following keys:
    ;;    `object`: A object name.
    ;;    `method`: A metheod of the given object.
    ;;    `parameters`: An array of parameters passed to the object method.
    ;;    The method takes a window object as its first argument additional to the parameters given by the rule.
    ;;    The method will return `True` or `False`.
    ;; All `windowProperties` and `assertions` are concatenated by ´logical and´s.
    ;; `commands` should be an array, which may contain one or more of the following window related commands:
    ;;    `activate`, `close`, `hide`, `maximize`, `minimize`, `restore`, `setCaption`, `show`, `unsetCaption`
    ;;    `bottom`, `setAlwaysOnTop`, `toggleAlwaysOnTop` and `top`
    ;; `functions` should be an object, which may contain the following keys:
    ;;    `setWindowWorkArea`, `setWindowFloating`, `goToDesktop`, `switchToWorkArea` and `switchToLayout`.
    ;; If `break` is set to `True`, the processing is stopped after evaluating the current rule.

    cfg.windowManagementRules := [{windowProperties: {desktop: 0}, break: True} ;; Exclude hidden (?) windows.
      ;;      , {windowProperties: {isPopup: True}, break: True} ;; Exclude pop-up windows.
      , {windowProperties: {class: "#32770", isPopup: True}, break: True} ;; Exclude pop-up windows.
      , {windowProperties: {pName: "EXCEL\.EXE", isPopup: True}, break: True} ;; Excel pop-up windows.
      , {windowProperties: {class: "WorkerW", pName: "Explorer\.EXE"}, break: True} ;; Exclude pop-up windows.
      , {windowProperties: {class: "DialogBox Container Class", pName: "saplogon\.exe"}, break: True} ;; Exclude pop-up windows.
      , {windowProperties: {class: "ApplicationFrameWindow", title: "Calculator"}, break: True }

      ;;
      , {windowProperties: {pName: "Greenshot\.exe"}, break: True}
      , {windowProperties: {pName: "ncpmon\.exe"}, break: True}
      , {windowProperties: {pName: "SWGVC\.exe"}, break: True}
      , {windowProperties: {pName: "f5vpn\.exe"}, break: True}
      , {windowProperties: {pName: "xampp-control\.exe"}, break: True}
      , {windowProperties: {pName: "KeePass\.exe"}, break: True}
      , {windowProperties: {class: "Notepad++"}, break: True}

      , {windowProperties: {pName: "TogglTrack\.exe"}, break: True}

      , {windowProperties: {pName: "Teams\.exe"}, break: True}
      , {windowProperties: {class: "CabinetWClass", pName: "Explorer\.EXE"}, break: True}
      , {windowProperties: {class: "TaskManagerWindow"}, break: True}

      ;; float outlook meeting, message windows while tiling others
      , {windowProperties: {class: "rctrl_renwnd32", pName: "OUTLOOK\.EXE", title: ".* Message *"}, break: True}
      , {windowProperties: {class: "rctrl_renwnd32", pName: "OUTLOOK\.EXE", title: ".* Meeting *"}, break: True}
      , {windowProperties: {class: "rctrl_renwnd32", pName: "OUTLOOK\.EXE", title: ".* Appointment *"}, break: True}
      , {windowProperties: {class: "rctrl_renwnd32", pName: "OUTLOOK\.EXE", title: ".* Event *"}, break: True}

      ;; float minimized, maximized windows
      , {windowProperties: {minMax: -1}, break: True}
      , {windowProperties: {minMax: 1}, break: True}

      ;; //////////////////////////////////////////////////////////////////////
      ;; Above this line are exclusions, i.e. no `functions`, but `break: True`.
      ;; //////////////////////////////////////////////////////////////////////

      , {functions: {setWindowFloating: False}} ;; Set windows non-floating, if not already excluded.

      ;; //////////////////////////////////////////////////////////////////////
      ;; Specific window functions
      ;; //////////////////////////////////////////////////////////////////////

      ;, {windowProperties: {pName: "firefox\.exe"}, functions: {setWindowWorkArea: "1-1"}, break: True}
      ;, {windowProperties: {pName: "Spotify\.exe"}, functions: {setWindowWorkArea: "1-1"}, break: True}
      ;, {windowProperties: {title: "D:\\development\\bug.n\\_git*"}, functions: {setWindowWorkArea: "2-1"}, break: True}
      , {functions: {setWindowWorkArea: "1"}}] ;; Set windows to work area 1, if no `break: True` was set previously.

    cfg.positions[11] := [ 0, 0, 70, 100]	;; left 0.70

    cfg.onMessageDelay := {shellEvent: 200, desktopChange: 200}

    logger.info("<b>Custom</b> configuration loaded.", "Customizations.__New")

  }

  _init() {

    ;; Overwrite hotkeys.
    ;; funcObject := ObjBindMethod(mgr, <function name> [, <function arguments>])
    ;; Hotkey, <key name>, %funcObject%

  }
}
