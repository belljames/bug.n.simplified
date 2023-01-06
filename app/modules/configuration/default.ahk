/*
:title:     bug.n X/app/modules/configuration/default
:copyright: (c) 2019-2020 by joten <https://github.com/joten>
:license:   GNU General Public License version 3

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
*/

class Configuration {
  __New() {
    Global app, logger
    
    this.name := "Default"
    
    this.desktopLabels := ["1", "2", "3", "4"]
    this.desktops := [{label: "1"}, {label: "2"}, {label: "3"}, {label: "4"}]
    this.defaultLayouts := [{symbol: "[]=", name: "DwmTileLayout", mfact: 0.55, nmaster: 1}
                          , {symbol: "[M]", name: "DwmMonocleLayout"}
                          , {symbol: "TTT", name: "DwmBottomStackLayout", mfact: 0.55, nmaster: 1}
                          , {symbol: "><>", name: "FloatingLayout"}]

    this.layoutGap := 0
    this.cursorFollowsFocus := True

    ;; The first item is set to be the initial layout of work areas.
    ;; Layout names are related to class names by "<Name>Layout".
    ;; bug.n x.min
    this.positions := [[  0,   0,  50,  50]    ;; top left
                     , [  0,   0, 100,  50]    ;; top half
                     , [ 50,   0,  50,  50]    ;; top right
                     , [  0,   0,  50, 100]    ;; left half
                     , [ 25,   0,  50, 100]    ;; centered half
                     , [ 50,   0,  50, 100]    ;; right half
                     , [  0,  50,  50,  50]    ;; bottom left
                     , [  0,  50, 100,  50]    ;; bottom half
                     , [ 50,  50,  50,  50]    ;; bottom right
                     , [  0,   0, 100, 100]]   ;; maximized

    this.showAllDesktops := True
    this.userInterfaces := [{name: "TrayIconUserInterface", tip: app.name, icon: app.logo}]
    this.onMessageDelay := {shellEvent: 0, desktopChange: 0}
    this.disabledFeatures := {shellHook: False, appCalls: False}


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
    this.windowManagementRules := [{windowProperties: {desktop: 0}, break: True}
      , {functions: {setWindowWorkArea: 1, setWindowFloating: False}}]
    
    logger.info("<b>" . this.name . "</b> configuration loaded.", "Configuration.__New")
  }
}

; #Up::mgr.activateWindowAtIndex(,, -1)
; #Down::mgr.activateWindowAtIndex(,, +1)
; #+Left::mgr.setLayoutProperty("nmaster",, +1)
; #+Right::mgr.setLayoutProperty("nmaster",, -1)
; #Left::mgr.setLayoutProperty("mfact",, -0.05)
; #Right::mgr.setLayoutProperty("mfact",, +0.05)
; #+Up::mgr.moveWindowToPosition(,, -1)
; #+Down::mgr.moveWindowToPosition(,, +1)
; #+Enter::mgr.moveWindowToPosition(, 1, 0)
; #^i::mgr.showWindowInformation()
; ; #+c::mgr.closeWindow()
; #t::mgr.switchToLayout(1)
; #m::mgr.switchToLayout(2)
; #b::mgr.switchToLayout(3)
; #f::mgr.switchToLayout(4)
; #Backspace::mgr.switchToLayout(, +1)
; #+Backspace::mgr.switchToLayout(-1)
; #Space::mgr.toggleWindowIsFloating()
; #1::mgr.switchToDesktop(1)
; #2::mgr.switchToDesktop(2)
; #3::mgr.switchToDesktop(3)
; #4::mgr.switchToDesktop(4)
; #+Tab::mgr.switchToDesktop(-1)
; #^Left::mgr.switchToDesktop(, -1, True)
; #^Right::mgr.switchToDesktop(, +1, True)
; #+0::mgr.moveWindowToDesktop(, 0)
; #+1::mgr.moveWindowToDesktop(, 1)
; #+2::mgr.moveWindowToDesktop(, 2)
; #+3::mgr.moveWindowToDesktop(, 3)
; #+4::mgr.moveWindowToDesktop(, 4)
; #^+Left::mgr.moveWindowToDesktop(,, -1)
; #^+Right::mgr.moveWindowToDesktop(,, +1)
; #,::mgr.switchToWorkArea(, -1)
; #.::mgr.switchToWorkArea(, +1)
; #Enter::mgr.moveWindowToWorkArea()
; #+,::mgr.moveWindowToWorkArea(,, -1)
; #+.::mgr.moveWindowToWorkArea(,, +1)

; ;; bug.n x.min
; ;#+q::mgr.moveWindowToPosition(, 1)
; ;#+w::mgr.moveWindowToPosition(, 2)
; ;#+e::mgr.moveWindowToPosition(, 3)
; ;#+a::mgr.moveWindowToPosition(, 4)
; ;#+s::mgr.moveWindowToPosition(, 5)
; ;#+d::mgr.moveWindowToPosition(, 6)
; ;#+y::mgr.moveWindowToPosition(, 7)
; ;#+x::mgr.moveWindowToPosition(, 8)
; ;#+c::mgr.moveWindowToPosition(, 9)

; #+b::mgr.toggleUserInterfaceBar()
; #+d::mgr.toggleWindowHasCaption()
; #+Space::mgr.activateWindowsTaskbar()

; #^l::logger.setLevel(, -1)
; #^+l::logger.setLevel(, +1)
; #+l::logger.writeCacheToFile(A_WorkingDir . "\..\..\bug.n-log.md")
; #^q::ExitApp
; #^r::Reload

