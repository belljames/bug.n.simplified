/*
:title:     bug.n X/app/modules/layouts/dwm-monocle-layout
:copyright: (c) 2019-2020 by joten <https://github.com/joten>
:license:   GNU General Public License version 3

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
*/

class DwmMonocleLayout {
  __New(index) {
    this.index := index
    this.name := "DwmMonocleLayout"
    this.symbol := "[M]"
  }
  
  arrange(gap, x, y, w, h, windows) {

    wndX := x + gap
    wndY := y + gap
    wndW := w - (2 * gap)
    wndH := h - (2 * gap)

    For i, wnd in windows {
      wnd.move(wndX, wndY, wndW, wndH)
    }
    this.symbol := "[" . windows.Length() . "]"
  }
}
