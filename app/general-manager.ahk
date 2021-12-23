/*
:title:     bug.n X/app/general-manager
:copyright: (c) 2019-2020 by joten <https://github.com/joten>
:license:   GNU General Public License version 3

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
*/

class GeneralManager {
  __New() {
    Global logger
    
    this.desktops := []
    this.desktopA := []   ;; TODO: Track the active desktop, or simply use `this.dMgr.getCurrentDesktopIndex`, when the information is needed?
    this.primaryUserInterface := ""
    this.windows := {}
    this.workGroups := []
    
    ;; Initialize monitors.
    this.mMgr := New MonitorManager(ObjBindMethod(this, "_onDisplayChange"))
    this.detectTaskbars()
    
    ;; Initialize desktops and work areas.
    this.dMgr := New DesktopManager(ObjBindMethod(this, "_onTaskbarCreated"), ObjBindMethod(this, "_onDesktopChange"))
    A := this.dMgr.getCurrentDesktopIndex()
    this._init("desktops")
    this.desktopA.push(this.desktops[A])
    this.dMgr.switchToDesktop(A)
    
    ;; bug.n x.min: Initialize work groups.
    ; Loop, % this.dMgr.getDesktopCount() {
    For i, dsk in this.desktops {
      this.workGroups[i] := []
      For j, rect in dsk.workAreas {
        this.workGroups[i][j] := New WorkGroup(j, rect)
        logger.debug("Work group ``" . j . "`` added to desktop ``" . i . "``.", "GeneralManager.__New")
      }
    }
    
    this.detectWindows()
    
    this._init("user interfaces")
    
    For i, item in this.desktopA[1].workAreas {
      item.arrange()
    }
    
    this._init("shell events")
  }
  
  __Delete() {
    Global app
    this.dMgr := ""
    DllCall("DeregisterShellHookWindow", "UInt", app.windowId)
  }
  
  _init(part) {
    Global app, cfg, logger
    
    
    ;; Desktops.
    If (part == "desktops") {
      m := 0
      n := this.dMgr.getDesktopCount()
      For i, item in cfg.desktops {
        this.desktops[i] := New Desktop(i, item.label)
        If (i > n) {
          this.dMgr.createDesktop()
          m += 1
        }
        If (item.HasKey("workAreas")) {
          For j, wa in item.workAreas {
            this.desktops[i].workAreas.push(New WorkArea(i, j, wa.rect))
            ;; Only the first work area marked as `primary` will be set; later ones will be discarded.
            If (this.desktops[i].primaryWorkArea == "" && wa.isPrimary) {
              this.desktops[i].workAreas[j].isPrimary := True
              this.desktops[i].primaryWorkArea := this.desktops[i].workAreas[j]
            }
          }
        } Else {
          ;; If no custom work areas are defined, they are derived from the detected monitors per desktop.
          For j, item in this.mMgr.monitors {
            this.desktops[i].workAreas.push(New WorkArea(i, j, item.monitorWorkArea))
          }
          this.desktops[i].workAreas[this.mMgr.primaryMonitor].isPrimary := True
          this.desktops[i].primaryWorkArea := this.desktops[i].workAreas[this.mMgr.primaryMonitor]
        }
        this.desktops[i].workAreaA.push(this.desktops[i].primaryWorkArea)
      }
      logger.info(m . " additional desktop" . (n == 1 ? "" : "s") . " created.", "GeneralManager._init")
      
      
    ;; Shell Events.
    } Else If (part == "shell events") {
      this.shellEventCache := []
      DllCall("RegisterShellHookWindow", "UInt", app.windowId)
      msgNum := DllCall("RegisterWindowMessage", "Str", "SHELLHOOK")
      OnMessage(msgNum, ObjBindMethod(this, "_onShellEvent"))
      this.shellEvents := { 1: "WINDOWCREATED"
                      ,     2: "WINDOWDESTROYED"
                      ,     4: "WINDOWACTIVATED"
                      ,     6: "REDRAW"
                      ,    10: "ENDTASK"
                      ,    13: "WINDOWREPLACED"
                      ,    14: "WINDOWREPLACING"
                      ,    16: "MONITORCHANGED"
                      , 32772: "RUDEAPPACTIVATED"
                      , 32774: "FLASH"}
      logger.info("ShellHook registered to window with id <mark>" . app.windowId . "</mark>.", "GeneralManager._init")
      ;; SKAN: How to Hook on to Shell to receive its messages? (http://www.autohotkey.com/forum/viewtopic.php?p=123323#123323)
      
      
    ;; User Interfaces
    } Else If (part == "user interfaces") {
      For i, item in cfg.userInterfaces {
        name := item.name
        this.uifaces[i] := New %name%(i)
        this.uifaces[i]["appCallFuncObject"] := ObjBindMethod(this, "_onAppCall")
        For key, value in this.uifaces[i] {
          If (item.HasKey(key)) {
            this.uifaces[i][key] := item[key]
          }
        }
        this.uifaces[i]._init()
      }
      
      ; For i, item in this.mMgr.monitors {
      ;   k := this.uifaces.Length() + 1

        ; this.uifaces[k] := New WorkAreaUserInterface(k)
        ; this.uifaces[k]["appCallFuncObject"] := ObjBindMethod(this, "_onAppCall")
        
        ; If (item.isPrimary) {
        ;   For key, index in cfg.defaultSystemStatusBarItems {
        ;     this.uiface[k].items.bar[key] := index
        ;   }
        ;   this.uifaces[k].includeAppIface := True
        ;   this.primaryUserInterface := this.uifaces[k]
        ; } Else {
        ;   this.uifaces[k].items.content := {"work-areas": "06", "windows": "07", "layouts": "08"}
        ;   this.uifaces[k].updateIntervals := {}
        ; }
        
        ; this.uifaces[k].x := item.monitorWorkArea.x
        ; this.uifaces[k].y := item.monitorWorkArea.y
        ; this.uifaces[k].w := item.monitorWorkArea.w ;/ item.scaleX
        ; this.uifaces[k].h := item.monitorWorkArea.h ;/ item.scaleY
        
        ; this.uifaces[k]._init()
        ; this.uifaces[k].fitContent(56)
      ; }
      
      ; ;; "<tr><th>Index</th><th>Label</th></tr>"
      ; data := []
      ; For i, item in this.desktops {
      ;   data.push([item.index, item.label])
      ; }
      ; this.primaryUserInterface.insertContentItems(this.primaryUserInterface.items.content["desktops"], data)
      
      ; ;; "<tr><th>Index</th><th>Name</th><th>x-Coordinate</th><th>y-Coordinate</th><th>Width</th><th>Height</th><th>Scale x</th><th>Scale y</th></tr>"
      ; data := []
      ; For i, item in this.mMgr.monitors {
      ;   data.push([item.index, item.name, item.x, item.y, item.w, item.h, Format("{:i}%", item.scaleX * 100), Format("{:i}%", item.scaleY * 100)])
      ; }
      ; this.primaryUserInterface.insertContentItems(this.primaryUserInterface.items.content["monitors"], data)
      
      ; ;; "<tr><th>Desktop</th><th>Index</th><th>x-Coordinate</th><th>y-Coordinate</th><th>Width</th><th>Height</th></tr>"
      ; data := []
      ; For i, item in this.desktops {
      ;   For j, wa in item.workAreas {
      ;     data.push([item.label, wa.index, wa.x, wa.y, wa.w, wa.h])
      ;   }
      ; }
      ; this.primaryUserInterface.insertContentItems(this.primaryUserInterface.items.content["work-areas"], data)
      
      ; data := []
      ; For id, item in this.windows {
      ;   data.push(this.primaryUserInterface.getContentItem("windows", item))
      ; }
      ; this.primaryUserInterface.insertContentItems(this.primaryUserInterface.items.content["windows"], data)
      
      ; this.updateBarItems(True)
    }
  }
  
  _onAppCall(uri) {
  }
  
  _onDesktopChange(wParam, lParam, msg, winId) {
    Global cfg, logger
    
    ;; Detect changes:
    ;; current monitor/ desktop/ window, different windows on desktop
    Sleep, % cfg.onMessageDelay.desktopChange
    A := this.dMgr.getCurrentDesktopIndex()
    logger.info("Desktop changed from <i>" . this.desktopA[2].index . "</i> to <b>" . A . "</b>.", "GeneralManager._onDesktopChange")
    desktopA := updateActive(this.desktopA, this.desktops[A])
      
    changes := this.detectWindows()

    ; data := []
    ; For i, wnd in changes.windows {
    ;   data.push(this.primaryUserInterface.getContentItem("windows", wnd))
    ; }
    ; this.primaryUserInterface.insertContentItems(this.primaryUserInterface.items.content["windows"], data)
    
    For id, wa in changes.workAreas {
      wa.arrange()
    }
    desktopA.workAreaA[1].activate()
    ;this.updateBarItems()
  }
  
  _onDisplayChange(wParam, lParam) {
    ;; Detect changes:
    ;; monitor added/ removed, position/ resolution/ scaling changed
  }
  
  _onShellEvent(wParam, lParam) {
    Global cfg, logger
    
    If (this.shellEvents.HasKey(wParam)) {
      ;; Detect changes:
      ;; current monitor/ desktop/ window, window opened/ closed/ moved
      Sleep, % cfg.onMessageDelay.shellEvent
      
      winId := Format("0x{:x}", lParam)
      logger.debug("Shell message received with message number '" . wParam . "' and window id '" . winId . "'.", "GeneralManager._onShellEvent")
      WinGetClass, winClass, % "ahk_id " . winId
      WinGetTitle, winTitle, % "ahk_id " . winId
      data := {timestamp: logger.getTimestamp(), msg: this.shellEvents[wParam], num: wParam, winId: winId, winClass: winClass, winTitle: winTitle}
      this.shellEventCache.push(this.primaryUserInterface.getContentItem("messages", data))
      
      changes := this.detectWindows()
      
      ;data := []
      ;For i, wnd in changes.windows {
      ;  data.push(this.primaryUserInterface.getContentItem("windows", wnd))
      ;}
      ;this.primaryUserInterface.insertContentItems(this.primaryUserInterface.items.content["windows"], data)
      
      For id, wa in changes.workAreas {
        wa.arrange()
      }
      
      ;this.updateBarItems()
    }
  }
  
  _onTaskbarCreated(wParam, lParam, msg, winId) {
    Global logger
    
    ;; Restart the virtual desktop accessor, when Explorer.exe crashes or restarts (e.g. when coming from a fullscreen game).
    result := this.dMgr.restartVirtualDesktopAccessor()
    If (result > 0) {
      logger.error("Restarting <i>virtual desktop accessor</i> after a crash or restart of Explorer.exe failed.", "GeneralManager._onTaskbarCreated")
    } Else {
      logger.warning("<i>virtual desktop accessor</i> restarted due to a crash or restart of Explorer.exe.", "GeneralManager._onTaskbarCreated")
    }
  }
  
  activateWindowAtIndex(winId := 0, index := 0, delta := 0, matchFloating := False) {
    desktopA := updateActive(this.desktopA, this.desktops[this.dMgr.getCurrentDesktopIndex()])
    wnd := this.getWindow(winId)
    desktopA.workAreaA[1].activateWindowAtIndex(wnd, index, delta, matchFloating)
  }
  
  activateWindowsTaskbar() {
    desktopA := updateActive(this.desktopA, this.desktops[this.dMgr.getCurrentDesktopIndex()])
    For i, item in this.mMgr.monitors {
      If (item.match(desktopA.workAreaA[1])) {
        If (IsObject(item.trayWnd)) {
          item.trayWnd.runCommand("activate")
        }
        Break
      }
    }
  }
  
  applyWindowManagementRules(wnd) {
    Global cfg
    
    For i, rule in cfg.windowManagementRules {
      propertiesMatched := True
      If (rule.HasKey("windowProperties")) {
        For key, value in rule.windowProperties {
          If (key == "desktop") {
            propertiesMatched := (this.dMgr.getWindowDesktopIndex(wnd.id) == value) && propertiesMatched
          } Else {
            propertiesMatched := (RegExMatch(wnd[key], value) > 0) && propertiesMatched
          }
        }
      }
      testsPassed := True
      If (rule.HasKey("tests")) {
        For j, test in rule.tests {
          funcObject := ObjBindMethod(test.object, test.method, test.parameters)
          testsPassed := %funcObject%() && testsPassed
        }
      }
      
      If (propertiesMatched && testsPassed) {
        If (rule.HasKey("commands")) {
          For j, command in rule.commands {
            wnd.runCommand(command)
          }
        }
        If (rule.HasKey("functions")) {
          ;; `setWindowWorkArea`, `setWindowFloating`, `goToDesktop`, `switchToWorkArea` and `switchToLayout`
          For function, value in rule.functions {
            If (InStr(function, "Window") > 0) {
              funcObject := ObjBindMethod(this, function, wnd)
            } Else If (function == "goToDesktop") {
              funcObject := ObjBindMethod(this.dMgr, function)
            } Else {
              funcObject := ObjBindMethod(this, function)
            }
            %funcObject%(value)
          }
        }
        If (rule.HasKey("break") && rule.break) {
          Break
        }
      }
    }
  }
  
  ;; bug.n x.min
  closeWindow(winId := 0) {
    wnd := this.getWindow(winId)
    If (IsObject(wnd.workGroup)) {
      grp := wnd.workGroup
      grp.removeWindow(wnd)
      grp.arrange()
    }
    wnd.runCommand("close")
  }
  
  detectTaskbars() {
    SetTitleMatchMode, RegEx
    WinGet, winId_, List, ahk_class Shell_.*TrayWnd
    SetTitleMatchMode, 3
    Loop, % winId_ {
      winId := Format("0x{:x}", winId_%A_Index%)
      wnd := this.getWindow(winId)
      For i, item in this.mMgr.monitors {
        If (item.match(wnd, False, True)) {
          item.trayWnd := wnd
          Break
        }
      }
    }
  }
  
  detectWindows() {
    Global logger
    
    changes := {windows: [], workAreas: {}}
    windows := {}
    desktopA := updateActive(this.desktopA, this.desktops[this.dMgr.getCurrentDesktopIndex()])
    
    ;; Windows currently found.
    WinGet, winId_, List,,,
    Loop, % winId_ {
      winId := Format("0x{:x}", winId_%A_Index%)
      If (!this.windows.HasKey(winId)) {
        ;; Unknown/ new window. Apply rules initializing the window!
        wnd := this.getWindow(winId)
        wnd.desktop := this.dMgr.getWindowDesktopIndex(wnd.id)
        If (this.dMgr.getWindowDesktopIndex(wnd.id) == desktopA.index) {
          windows[wnd.id] := wnd
        }
        this.applyWindowManagementRules(wnd)
        changes.windows.push(wnd)
        If (wnd.workArea.dIndex == desktopA.index && !wnd.isFloating) {
          changes.workAreas[wnd.workArea.id] := wnd.workArea
        }
      } Else {
        ;; Known window. What happened?
        wnd := this.getWindow(winId)
        If (wnd.workArea != "") {
        ;; Else: Ignore the window.
          If (this.dMgr.getWindowDesktopIndex(wnd.id) == desktopA.index) {
            ;; Only work on the active/ visible desktop.
            windows[wnd.id] := wnd
            
            wa := desktopA.getWorkArea(, wnd)
            logger.debug("Window from work area <i>" . wnd.workArea.id . "</i> found on work area <b>" . wa.id . "</b>.", "GeneralManager.detectWindows")
            If (wa != wnd.workArea) {
              ;; The window moved between work areas or desktops.
              wnd.workArea.removeWindow(wnd)
              wa.addWindow(wnd)
              If (!wnd.isFloating) {
                ;; Mark work areas for rearrangement.
                If (wnd.workArea.dIndex == desktopA.index) {
                  changes.workAreas[wnd.workArea.id] := wnd.workArea
                }
                changes.workAreas[wa.id] := wa
              }
              wnd.workArea := wa
            }
          }
        }
      }
    }
    
    ;; Windows, which should have been found.
    For i, wa in desktopA.workAreas {
      For j, wnd in wa.windows {
        If (!windows.HasKey(wnd.id)) {
          ;; Window was removed from work area.
          If (IsObject(wnd.workArea)) {
            wnd.workArea.removeWindow(wnd)
            If (wnd.workArea.dIndex == desktopA.index) {
              changes.workAreas[wnd.workArea.id] := wnd.workArea
            }
          }
          ;; Window could not be detected by `WinExist` on different desktop, even with `DetectHiddenWindows, On` (?).
          If (this.dMgr.getWindowDesktopIndex(wnd.id) = 0) {
            ;; Window was removed entirely.
            this.primaryUserInterface.removeContentItems(this.primaryUserInterface.items.content["windows"], [wnd.id])
            wnd.workArea := ""
            this.windows[wnd.id] := ""
          }
          ;; Else: Adding the window to the new desktop work area will be done later.
        }
      }
    }
    
    wnd := this.getWindow()
    If (IsObject(wnd.workArea)) {
      workAreaA := updateActive(this.desktopA[1].workAreaA, wnd.workArea)
      windowA := updateActive(this.desktopA[1].workAreaA[1].windowA, wnd)
    }
    
    Return, changes
  }
  
  getWindow(winId := 0) {
    winId := Format("0x{:x}", (winId == 0 ? WinExist("A") : winId))
    wnd := ""
    If (this.windows.HasKey(winId)) {
      wnd := this.windows[winId]
      wnd.update()
    } Else {
      wnd := New Window(winId)
      this.windows[wnd.id] := wnd
    }
    Return, wnd
  }
  
  moveWindowToDesktop(winId := 0, index := 0, delta := 0, loop := False) {
    desktopA := updateActive(this.desktopA, this.desktops[this.dMgr.getCurrentDesktopIndex()])
    wnd := this.getWindow(winId)
    If (delta != 0) {
      index := index == 0 ? desktopA.index : index
      index := getIndex(index, delta, this.desktops.Length(), loop)
    }
    If (index == 0 || index != desktopA.index) {
      this.setWindowDesktop(wnd, index)
    }
  }
  
  moveWindowToPosition(winId := 0, index := 0, delta := 0) {
    ;; matchFloating := False
    desktopA := updateActive(this.desktopA, this.desktops[this.dMgr.getCurrentDesktopIndex()])
    wnd := this.getWindow(winId)
    If (IsObject(wnd.workArea)) {
      wa := wnd.workArea
    } Else {
      wa := desktopA.workAreaA[1]
      wnd.workArea := wa
      wa.addWindow(wnd)
    }
    wnd.isFloating := False
    wa.moveWindowToPosition(wnd, index, delta)
    wa.arrange()
  }
  
  moveWindowToWorkArea(winId := 0, index := 0, delta := 0, loop := False) {
    desktopA := updateActive(this.desktopA, this.desktops[this.dMgr.getCurrentDesktopIndex()])
    wnd := this.getWindow(winId)
    index := index == 0 ? desktopA.workAreaA[1].index : index
    index := getIndex(index, delta, desktopA.workAreas.Length(), loop)
    this.setWindowWorkArea(wnd, desktopA.index . "-" . index)
    If (!wnd.isFloating) {
      desktopA.workAreas[index].arrange()
    }
  }
  
  setLayoutProperty(key, value := 0, delta := 0) {
    desktopA := updateActive(this.desktopA, this.desktops[this.dMgr.getCurrentDesktopIndex()])
    workAreaA := updateActive(desktopA.workAreaA, desktopA.getWorkArea(, this.getWindow()))
    workAreaA.setLayoutProperty(key, value, delta)
    workAreaA.arrange()
  }
  
  setWindowDesktop(wnd, index) {
    If (index == 0) {
      this.dMgr.pinWindow(wnd.id)
    } Else If (index > 0 && index <= this.desktops.Length()) {
      If (this.dMgr.isPinnedWindow(wnd.id) == 1) {
        this.dMgr.unPinWindow(wnd.id)
      }
      this.dMgr.moveWindowToDesktop(wnd.id, index)
    }
  }
  
  setWindowFloating(wnd, value) {
    wnd.isFloating := value
  }
  
  setWindowWorkArea(wnd, id) {
    Global logger
    
    k := InStr(id, "-")
    If (k == 0) {
      i := this.dMgr.getCurrentDesktopIndex()
      j := id
    } Else {
      i := SubStr(id, 1, k - 1)
      j := SubStr(id, k + 1)
    }
    If (i > 0 && i <= this.desktops.Length() && j > 0 && j <= this.desktops[i].workAreas.Length()) {
      this.setWindowDesktop(wnd, i)
      wa := this.desktops[i].workAreas[j]
      If (IsObject(wnd.workArea)) {
        wnd.workArea.removeWindow(wnd)
        If (!wnd.isFloating && wnd.workArea.index != wa.index) {
          wnd.workArea.arrange()
        }
      }
      wnd.workArea := wa
      wa.addWindow(wnd)
    } Else {
      logger.error("Work area at index <mark>" . j . "</mark> on desktop <mark>" . i . "</mark> not found.", "GeneralManager.setWindowWorkArea")
    }
  }
  
  showWindowInformation(winId := 0) {
    Global app
    
    wnd := this.getWindow(winId)
    MsgBox, 3, % app.name . ": Window Information", % wnd.information . "`n`nCopy window information to clipboard?"
    IfMsgBox Yes
      Clipboard := wnd.information
  }
  
  switchToDesktop(index := 0, delta := 0, loop := False) {
    desktopA := updateActive(this.desktopA, this.desktops[this.dMgr.getCurrentDesktopIndex()])
    If (index == 0) {
      index := desktopA.index
    } Else If (index == -1) {
      index := this.desktopA[2].index
    }
    index := getIndex(index, delta, this.desktops.Length(), loop)
    If (index != desktopA.index) {
      this.dMgr.goToDesktop(index)
      desktopA := updateActive(this.desktopA, this.desktops[this.dMgr.getCurrentDesktopIndex()])
      desktopA.switchToWorkArea()
    }
  }
  
  switchToLayout(index := 0, delta := 0) {
    desktopA := updateActive(this.desktopA, this.desktops[this.dMgr.getCurrentDesktopIndex()])
    desktopA.workAreaA[1].switchToLayout(index, delta)
    desktopA.workAreaA[1].arrange()
    this.updateBarItems()
  }
  
  switchToWorkArea(index := 0, delta := 0, loop := False) {
    desktopA := updateActive(this.desktopA, this.desktops[this.dMgr.getCurrentDesktopIndex()])
    desktopA.switchToWorkArea(index, delta, loop)
    this.updateBarItems()
  }
  
  toggleUserInterfaceBar() {
    desktopA := updateActive(this.desktopA, this.desktops[this.dMgr.getCurrentDesktopIndex()])
    desktopA.workAreaA[1].showBar := !desktopA.workAreaA[1].showBar
    desktopA.workAreaA[1].arrange()
  }
  
  toggleWindowHasCaption(winId := 0) {
    wnd := this.getWindow(winId)
    wnd.runCommand("toggleCaption")
    If (IsObject(wnd.workArea) && !wnd.isFloating) {
      wnd.workArea.arrange()
    }
    ;; bug.n x.min
    If (IsObject(wnd.workGroup)) {
      wnd.workGroup.arrange()
    }
  }
  
  toggleWindowIsFloating(winId := 0) {
    wnd := this.getWindow(winId)
    this.setWindowFloating(wnd, !wnd.isFloating)
    If (IsObject(wnd.workArea)) {
      wnd.workArea.arrange()
    }
    this.updateBarItems()
  }
  
  updateBarItems(init := False) {
    Global cfg, app

    ;; {"desktops": "01", "layout": "02", "monitor": "03", "window": "04"}
    winTitle := ""
    wa := this.desktopA[1].workAreaA[1]

    if (desktopA.workAreaA[1].showBar = False) {
      Return
    }

    If (IsObject(wa.windowA[1])) {
      wa.windowA[1].getProperties()
      winTitle := (wa.windowA[1].isFloating ? "~ " : "") . wa.windowA[1].title
    }
    indices := []
    values := []
    classNames := []
    iconNames := []
    If (cfg.showAllDesktops) {
      ;; Desktops
      For i, item in this.desktops {
        indices.push((i < 10 ? "0" : "") . i)
        values.push(item.label)
        classNames.push(item.index == this.desktopA[1].index ? ["", "app-bar-item-active"] : ["app-bar-item-active", ""])
        iconNames.push("")
      }
      iconNames[1] := init ? ["", ""] : ""
      ;; Work Area
      indices.push((i < 10 ? "0" : "") . indices.Length() + 1)
      values.push(wa.index)
      classNames.push("")
      iconNames.push(init ? ["", "object-group"] : "")
      ;; Layout
      indices.push((i < 10 ? "0" : "") . indices.Length() + 1)
      values.push(wa.layoutA[1].symbol)
      classNames.push(init ? ["", "app-bar-item-active"] : "")
      iconNames.push("")
      ;; Window
      indices.push((i < 10 ? "0" : "") . indices.Length() + 1)
      values.push(winTitle)
      classNames.push("")
      iconNames.push(init ? ["", "window-restore"] : "")
    } Else {
      indices := ["01", "02", "03", "04"]
      values := [this.desktopA[1].label, wa.layoutA[1].symbol, wa.index, winTitle]
      classNames := init ? ["", ["", "app-bar-item-active"], "", ""] : ["", "", "", ""]
      iconNames := init ? [["", "layer-group"], "", ["", "desktop"], ["", "window-restore"]] : ["", "", "", ""]
    }
    this.primaryUserInterface.setBarItems(indices, values, classNames, iconNames)
  }
}

class Desktop {
  __New(index, label) {
    this.index := index
    this.label := label
    this.workAreas := []
    this.workAreaA := []
    this.primaryWorkArea := ""
  }
  
  getWorkArea(index := 0, rect := "") {
    wa := this.workAreaA[1]
    If (index > 0 && index <= this.workAreas.Length()) {
      wa := this.workAreas[index]
    } Else If (IsObject(rect)) {
      For i, item in this.workAreas {
        If (item.match(rect, False, True)) {
          wa := item
          Break
        }
      }
    }
    Return, wa
  }
  
  switchToWorkArea(index, delta, loop) {
    index := index == 0 ? this.workAreaA[1].index : index
    index := getIndex(index, delta, this.workAreas.Length(), loop)
    If (index != this.workAreaA[1].index || delta == 0) {
      workAreaA := updateActive(this.workAreaA, this.workAreas[index])
      workAreaA.activate()
    }
  }
}

class Rectangle {
  ;; A rectangle must have the following properties: x (x-coordinate), y (y-coordinate), w (width), h (height)
  __New(xCoordinate, yCoordinate, width := 0, height := 0) {
    this.x := xCoordinate
    this.y := yCoordinate
    this.w := width
    this.h := height
  }
  
  match(rect, dimensions := False, exhaustively := False, variation := 2) {
    ;; If `exactness == 0`, this function tests if the center of `rect` is inside `Rectangle`,
    ;; else it tests if `rect` has the position and size as `Rectangle` in the limits of `exactness`.
    ;; `exactness` should therefor be equal or greater than 0.
    Global logger
    
    result := False
    If (dimensions) {
      result := Abs(this.x - rect.x) < variation && Abs(this.y - rect.y) < variation && Abs(this.w - rect.w) < variation && Abs(this.h - rect.h) < variation
    } Else {
      coordinates := [[rect.x + rect.w / 2, rect.y + rect.h / 2]]
      If (exhaustively) {
        coordinates.push({x: rect.x + variation,          y: rect.y + variation})
        coordinates.push({x: rect.x + rect.w - variation, y: rect.y + rect.h - variation})
        coordinates.push({x: rect.x + variation,          y: rect.y + rect.h - variation})
        coordinates.push({x: rect.x + rect.w - variation, y: rect.y + variation})
      }
      For i, coord in coordinates {
        If (result := coord.x >= this.x && coord.y >= this.y && coord.x <= this.x + this.w && coord.y <= this.y + this.h) {
          logger.debug("Rectangle " . (this.HasKey("id") ? "with id " . this.id . " " : "") . "(" . this.x . ", " . this.y . ", " . this.w . ", " . this.h
                                                       . ") matches coordinates (" . i . ": " . coord.x . ", " . coord.y . ", " . coord.w . ", " . coord.h . ")"
                                                       . (this.HasKey("id") ? " from " . this.id : "") . ".", "Rectangle.match")
          Break
        }
      }
    }
    Return, result
  }
}

getIndex(curIndex, delta, maxIndex, loop := True) {
  ;; Return a valid index, i.e. between 1 and maxIndex,
  ;; either not exceeding the lower or upper bound, or looping if `loop := True`,
  ;; i.e. resetting it to the lower or upper bound respectively by delta.
  
  index := curIndex
  
  If (loop) {
    ;; upper bound = n, lower bound = 1
    lowerBoundBasedIndex := Mod(index - 1 + delta, maxIndex)
    If (lowerBoundBasedIndex < 0) {
      lowerBoundBasedIndex += maxIndex
    }
    index := 1 + lowerBoundBasedIndex
  } Else {
    index += delta
  }
  
  index := Min(Max(index, 1), maxIndex)
  
  Return, index
}

updateActive(ByRef array, item, count := 2) {
  If (array[1] != item) {
    array.InsertAt(1, item)
  }
  n := array.Length() - count
  Loop, % n {
    array.Pop()
  }
  Return, array[1]
}

;; bug.n x.min
  ;getIndex(curIndex, delta, maxIndex, sequence := "closed") {
    ; Return a valid index, i.e. between 1 and maxIndex, starting at `curIndex`, in- or decreasing by `delta`,
    ; either not exceeding the lower or upper bound (sequence == "closed"),
    ; circling, i.e. resetting it to the lower or upper bound respectively by delta (sequence == "circle")
    ; or exceeding the upper bound (sequence == "half-open").
    ;Global logger
    ;
    ;index := curIndex
    ;If (sequence == "circle") {
      ; upper bound = maxIndex, lower bound = 1
      ;lowerBoundBasedIndex := Mod(index - 1 + delta, maxIndex)
      ;If (lowerBoundBasedIndex < 0) {
        ;lowerBoundBasedIndex += maxIndex
      ;}
      ;index := 1 + lowerBoundBasedIndex
    ;} Else {
      ;index += delta
    ;}
    ;index := Min(Max(index, 1), maxIndex + (sequence == "half-open" ? 1 : 0))
    ;logger.debug(curIndex . " +(" . delta . ") < " . maxIndex . " = " . index . " (" . sequence . ")", "GeneralManager.getIndex")
    ;
    ;Return, index
  ;}
  ;
  ;getIndices(objectType, wnd, index, delta, sequence) {
    ;Global cfg, logger
    ;
    ;d := this.dMgr.getCurrentDesktopIndex()
    ;g := (wnd != "" && wnd.workGroup != "") ? wnd.workGroup.index : 1 ;; this.getWorkGroup("empty", d)
    ;If (objectType == "desktop") {
      ;A := d
      ;n := this.dMgr.getDesktopCount()
    ;} Else If (objectType == "position") {
      ;A := 0
      ;n := cfg.positions.Length()
    ;} Else If (objectType == "window") {
      ;A := this.workGroups[d][g].getWindowIndex(wnd)
      ;n := this.workGroups[d][g].windows.Length()
    ;} Else If (objectType == "workGroup") {
      ;A := g
      ;n := this.workGroups[d].Length()
    ;} Else If (objectType == "workArea") {
      ;A := this.getCurrentWorkAreaIndex(wnd)
      ;n := this.mMgr.monitors.Length()
    ;}
    ;i := this.getIndex((index == 0) ? A : index, delta, n, sequence)
    ;logger.debug(objectType . " [" . d . ", " . g . "] " . index . " =0? | " . A . " +(" . delta . ") < " . n . " = " . i . " (" . sequence . ")", "GeneralManager.getIndices")
    ;
    ;Return, {cur: A, new: i, max: (i == n + 1 ? i : n), dsk: d, grp: g}
  ;}
  ;
  ;getCurrentWorkAreaIndex(wnd) {
    ;index := 0
    ;For i, rect in this.workAreas {
      ;If (rect.match(wnd)) {
        ;index := i
        ;Break
      ;}
    ;}
    ;Return, index
  ;}
  ;
  ;getWorkGroup(condition, desktopIndex, sequence := "half-open") {
    ;index := 0
    ;If (condition == "empty") {
      ;For i, grp in this.workGroups[desktopIndex] {
        ;If (grp.windows.Length() == 0) {
          ;index := i
          ;Break
        ;}
      ;}
      ;If (index == 0 && sequence == "half-open") {
        ;index := this.workGroups[desktopIndex].Length() + 1
        ;this.workGroups[desktopIndex][index] := New WorkGroup(index, this.workAreas[1])
      ;}
    ;}
    ;Return, index
  ;}
  ;
  ;pinWindowToDesktops(winId := 0, withWorkGroup := False) {
    ;wnd := this.getWindow(winId)
    ;windows := (withWorkGroup && IsObject(wnd.workGroup)) ? wnd.workGroup.windows : [wnd]
    ;For i, wnd in windows {
      ;this.dMgr.pinWindow(wnd.id)
    ;}
  ;}
  ;
  ;switch(objectType, index := 0, delta := 0, sequence := "") {
    ;wnd := (objectType == "desktop") ? "" : this.getWindow()
    ;sequence := sequence == "" ? (objectType == "desktop" ? "closed" : "circle") : sequence
    ;idx := this.getIndices(objectType, wnd, index, delta, sequence)
    ;If (idx.new != idx.cur && idx.new > 0 && idx.new <= idx.max) {
      ;If (objectType == "desktop") {
        ;this.dMgr.goToDesktop(idx.new)
      ;} Else If (objectType == "window") {
        ;this.workGroups[idx.dsk][idx.grp].activateWindow(idx.new)
      ;} Else If (objectType == "workGroup") {
        ;n := this.workGroups[idx.dsk][idx.new].windows.Length()
        ;For i in this.workGroups[idx.dsk][idx.new].windows {
          ;this.workGroups[idx.dsk][idx.new].activateWindow(n - i + 1)
        ;}
      ;}
    ;}
  ;}
  ;
  ; Move objects.
  ;moveWindowToDesktop(winId := 0, index := 0, delta := 0, sequence := "half-open", withWorkGroup := False) {
    ;wnd := this.getWindow(winId)
    ;idx := this.getIndices("desktop", wnd, index, delta, sequence)
    ;If (idx.new > this.dMgr.getDesktopCount()) {
      ;this.dMgr.createDesktop()
    ;}
    ; (wnd.workGroup == "" && !withWorkGroup) ? no need to remove the window from a work group, ...
    ; (wnd.workGroup == "" &&  withWorkGroup) ? ... just move the window to the new desktop
    ; (wnd.workGroup != "" && !withWorkGroup) ? remove the window from the current work group, but do not add it to a new one
    ; (wnd.workGroup != "" &&  withWorkGroup) ? move all windows from the group by removing the window from the current and adding it to a new, empty one
    ;If ((idx.new != idx.cur || winId != 0) && wnd.workGroup != "" && withWorkGroup) {
      ;g := this.getWorkGroup("empty", idx.new)
      ;this.workGroups[idx.new][g].workArea := this.workAreas[this.getCurrentWorkAreaIndex(wnd)]
    ;}
    ;windows := (wnd.workGroup != "" && withWorkGroup) ? wnd.workGroup.windows : [wnd]
    ;For i, wnd in windows {
      ;If (this.dMgr.isPinnedWindow(wnd.id) == 1) {
        ;this.dMgr.unPinWindow(wnd.id)
      ;}
      ;grp := wnd.workGroup
      ;If ((idx.new != idx.cur || winId != 0) && grp != "") {
        ;grp.removeWindow(wnd)
        ;If (!withWorkGroup) {
          ;grp.arrange()
        ;} Else If (g > 0) {
          ;this.workGroups[idx.new][g].setWindowIndex(wnd)
        ;}
      ;}
      ;this.dMgr.moveWindowToDesktop(wnd.id, idx.new)
    ;}
    ;If (wnd.workGroup != "" && withWorkGroup && g > 0) {
      ;this.workGroups[idx.new][g].arrange()
    ;}
  ;}
  ;
  ;moveWindowToPosition(winId := 0, index := 0, delta := 0, sequence := "closed") {
    ; The current position is not defined, therefor `delta` is not really implemented!
    ;Global cfg, logger
    ;
    ;wnd := this.getWindow(winId)
    ;idx := this.getIndices("position", wnd, index, delta, sequence)
    ;logger.debug("Moving window with id ``" . wnd.id . "`` to position ``" . idx.new . "`` (``"
      ;. cfg.positions[idx.new][1] . "-" . cfg.positions[idx.new][2] . "-"
      ;. cfg.positions[idx.new][3] . "-" . cfg.positions[idx.new][4] . "``).", "GeneralManager.moveWindowToPosition")
    ;this.workGroups[idx.dsk][idx.grp].moveWindowToPosition(wnd, cfg.positions[idx.new])
    ;this.workGroups[idx.dsk][idx.grp].setWindowIndex(wnd, 1)
    ;this.workGroups[idx.dsk][idx.grp].arrange()
  ;}
  ;
  ;moveWindowInWorkGroup(winId := 0, index := 0, delta := 0, sequence := "circle") {
    ;Global logger
    ;
    ;wnd := this.getWindow(winId)
    ;sequence := (sequence == "half-open") ? "circle" : sequence
    ;idx := this.getIndices("window", wnd, index, delta, sequence)
    ;If (idx.new != idx.cur) {
      ;logger.debug("Moving window with id ``" . wnd.id . "`` from index ``" . idx.cur . "`` to ``" . idx.new . "``.", "GeneralManager.moveWindowInWorkGroup")
      ;If (idx.new == 1) {
        ;rect := this.workGroups[idx.dsk][idx.grp].windows[1]
        ;wnd.move(rect.x, rect.y, rect.w, rect.h)
      ;} Else If (idx.cur == 1) {
        ;this.workGroups[idx.dsk][idx.grp].windows[2].move(wnd.x, wnd.y, wnd.w, wnd.h)
      ;}
      ;this.workGroups[idx.dsk][idx.grp].setWindowIndex(wnd, idx.new)
      ;this.workGroups[idx.dsk][idx.grp].arrange()
    ;}
  ;}
  ;
  ;moveWindowToWorkGroup(winId := 0, index := 0, delta := 0, sequence := "half-open", withWorkGroup := False) {
    ;Global logger
    ;
    ;wnd := this.getWindow(winId)
    ;idx := this.getIndices("workGroup", wnd, index, delta, sequence)
    ;If (idx.new > this.workGroups[idx.dsk].Length()) {
      ;If (wnd.workGroup != "" && wnd.workGroup.windows.Length() == 1) {
        ;idx.new := wnd.workGroup.index
      ;} Else {
        ;this.workGroups[idx.dsk][idx.new] := New WorkGroup(idx.new, this.mMgr.monitors[this.getCurrentWorkAreaIndex(wnd)])
        ;logger.debug("Work group ``" . idx.new . "`` added to desktop ``" . idx.dsk . "`` and work area ``" . this.getCurrentWorkAreaIndex(wnd) . "``.", "GeneralManager.moveWindowToWorkGroup")
      ;}
    ;}
    ;windows := (wnd.workGroup != "" && withWorkGroup) ? wnd.workGroup.windows : [wnd]
    ;logger.debug("Moving " . windows.Length() . " window" . (windows.Length() == 1 ? "" : "s") . " to work group ``" . idx.new . "`` on desktop ``" . idx.dsk . "``.", "GeneralManager.moveWindowToWorkGroup")
    ;For i, wnd in windows {
      ;If (wnd.workGroup != "") {
        ;grp := wnd.workGroup
        ;grp.removeWindow(wnd)
        ;If (!withWorkGroup) {
          ;grp.arrange()
        ;}
      ;}
      ;this.workGroups[idx.dsk][idx.new].setWindowIndex(wnd)
    ;}
    ;this.workGroups[idx.dsk][idx.new].arrange()
  ;}
  ;
  ;moveWindowToWorkArea(winId := 0, index := 0, delta := 0, sequence := "closed", withWorkGroup := False, posIndex := 0) {
    ;Global cfg, logger
    ;
    ;wnd := this.getWindow(winId)
    ;idx := this.getIndices("workArea", wnd, index, delta, sequence)
    ;If (idx.new != idx.cur || winId != 0) {
      ;logger.debug("Moving window with id ``" . wnd.id . "`` to work area ``" . idx.new
        ;. "``, position ``" . (posIndex > 0 && posIndex <= cfg.positions.Length() ? posIndex : 1) . "``.", "GeneralManager.moveWindowToWorkArea")
      ;pos := (posIndex > 0 && posIndex <= cfg.positions.Length()) ? cfg.positions[posIndex] : cfg.positions[1]
      ; (wnd.workGroup == "" && !withWorkGroup) ? no need to remove the window from a work group, ...
      ; (wnd.workGroup == "" &&  withWorkGroup) ? ... but add it to a new or empty work group in any case in order to have a work area associated
      ; (wnd.workGroup != "" && !withWorkGroup) ? remove the window from the current work group and add it to a new one
      ; (wnd.workGroup != "" &&  withWorkGroup) ? move the whole group, no need to remove the window from it or find a new one
      ;If (wnd.workGroup == "" || !withWorkGroup) {
        ;g := this.getWorkGroup("empty", idx.dsk)
        ;this.workGroups[idx.dsk][g].workArea := this.workAreas[idx.new]
      ;} ;; Else If (wnd.workGroup != "" &&  withWorkGroup) g is the index of wnd.workGroup
      ;windows := (wnd.workGroup != "" && withWorkGroup) ? wnd.workGroup.windows : [wnd]
      ;For i, wnd in windows {
        ;grp := wnd.workGroup
        ;If (grp != "" && !withWorkGroup) {
          ;grp.removeWindow(wnd)
          ;grp.arrange()
        ;}
        ;If (grp == "" || !withWorkGroup) {
          ;this.workGroups[g].setWindowIndex(wnd)
          ;this.workGroups[g].moveWindowToPosition(wnd, pos)
          ;this.workGroups[g].arrange()
        ;} Else {  ;; If (wnd.workGroup != "" &&  withWorkGroup)
          ;grp.workArea := this.workAreas[idx.new]
          ;grp.moveWindowToPosition(wnd, pos)
          ;grp.setWindowIndex(wnd, 1)
          ;grp.arrange()
        ;}
      ;}
    ;}
  ;}
