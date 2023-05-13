;; key bindings
;; =====================================

global mgr

!k::mgr.activateWindowAtIndex(,, -1)
!j::mgr.activateWindowAtIndex(,, +1)

#+Left::mgr.setLayoutProperty("nmaster",, +1)
#+Right::mgr.setLayoutProperty("nmaster",, -1)

!h::mgr.setLayoutProperty("mfact",, -0.05)
!l::mgr.setLayoutProperty("mfact",, +0.05)

!+k::mgr.moveWindowToPosition(,, -1)
!+j::mgr.moveWindowToPosition(,, +1)
!+Enter::mgr.moveWindowToPosition(, 1, 0)

!+p::mgr.runOrActivate("ahk_exe KeePass.exe", "C:\\Program Files\\KeePass Password Safe 2\\KeePass.exe")
!+n::mgr.runOrActivate("ahk_exe notepad++.exe", "C:\\Program Files\\Notepad++\\notepad++.exe")

!+u::mgr.floatingToTop()
!+i::mgr.floatingToBottom()

#+i::mgr.showWindowInformation()

!q::mgr.closeWindow()

#+t::mgr.switchToLayout(1)
#+m::mgr.switchToLayout(2)
#+b::mgr.switchToLayout(3)
#+f::mgr.switchToLayout(4)
#+Space::mgr.toggleWindowIsFloating()

!Backspace::mgr.switchToLayout(, +1)
!+Backspace::mgr.switchToLayout(-1)

!1::mgr.switchToDesktop(1)
!2::mgr.switchToDesktop(2)
!3::mgr.switchToDesktop(3)
!4::mgr.switchToDesktop(4)
!5::mgr.switchToDesktop(5)
!6::mgr.switchToDesktop(6)
!7::mgr.switchToDesktop(7)
!8::mgr.switchToDesktop(8)
!9::mgr.switchToDesktop(9)

;;!+Tab::mgr.switchToDesktop(-1)

#!Left::mgr.switchToDesktop(, -1, True)
#!Right::mgr.switchToDesktop(, +1, True)

!+0::mgr.moveWindowToDesktop(, 0)
!+1::mgr.moveWindowToDesktop(, 1)
!+2::mgr.moveWindowToDesktop(, 2)
!+3::mgr.moveWindowToDesktop(, 3)
!+4::mgr.moveWindowToDesktop(, 4)
!+5::mgr.moveWindowToDesktop(, 5)
!+6::mgr.moveWindowToDesktop(, 6)
!+7::mgr.moveWindowToDesktop(, 7)
!+8::mgr.moveWindowToDesktop(, 8)
!+9::mgr.moveWindowToDesktop(, 9)

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
#+l::logger.writeCacheToFile(A_WorkingDir . "bug.n-log.md")
#^q::ExitApp
#^r::Reload
