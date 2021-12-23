/*
:title:     bug.n X/app/modules/layouts/dwm-tile-layout
:copyright: (c) 2019-2020 by joten <https://github.com/joten>
:license:   GNU General Public License version 3

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
*/

class DwmTileLayout {
  __New(index) {
    this.index := index
    this.name := "DwmTileLayout"
    this.symbol := "[]="
    this.mfact := 0.55
    this.nmaster := 1
  }
  
  arrange(gap, x, y, w, h, windows) {
    ;; Arrange windows in master area.
    m := windows.Length() <= this.nmaster ? windows.Length() : this.nmaster
    ; wndX := x
    ; wndY := y
    ; wndW := (windows.Length() <= this.nmaster ? 1 : this.mfact) * w
    ; wndH := Round(h / m)
    wndX := x + gap
    wndY := y + gap
    wndW := ((windows.Length() <= this.nmaster ? 1 : this.mfact) * w ) - ( 2 * gap )
    wndH := ( Round(h / m) ) - ( 2 * gap )

    Loop, % m {
      windows[A_Index].move(wndX, wndY, wndW, wndH)
      windows[A_Index].runCommand("top")
      wndY += wndH
    }
    ;; Arrange windows in stack area.
    n := windows.Length() - m
    If (n > 0) {
      ; wndX := x + (this.mfact * w)
      ; wndY := y
      ; wndW := (1 - this.mfact) * w
      ; wndH := Round(h / n)

      wndX := (x + (this.mfact * w)) ;+ gap
      wndY := y + gap
      wndW := ((1 - this.mfact) * w) - ( gap)
      wndH := (Round(h / n)) - (2 * gap)

      Loop, % n {
        i := m + A_Index
        windows[i].move(wndX, wndY, wndW, wndH)
        windows[i].runCommand("top")
        wndY += wndH + gap
      }
    }
  }
  
  setMfact(mfact := 0, delta := 0) {
    Global logger
    
    mfact := (mfact == 0 ? this.mfact : mfact) + delta
    If (mfact > 0 && mfact < 1) {
      this.mfact := mfact
    } Else {
      logger.warning("Value <mark>" . mfact . "</mark> out of range.", "DwmTileLayout.setMfact")
    }
  }
  
  setNmaster(nmaster := 0, delta := 0) {
    Global logger
    
    nmaster := (nmaster == 0 ? this.nmaster : nmaster) + delta
    If (nmaster > 0 && Mod(nmaster, 1) == 0) {
      this.nmaster := nmaster
    } Else {
      logger.warning("Value <mark>" . nmaster . "</mark> out of range.", "DwmTileLayout.setNmaster")
    }
  }
}
