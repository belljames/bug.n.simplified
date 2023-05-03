/*
:title:     bug.n X/app/desktop-manager
:copyright: (c) 2019-2020 by joten <https://github.com/joten>
:license:   GNU General Public License version 3

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
*/

class TrayIcon
{
    setTrayIcon(desktop)
    {
        ;; set the tray icon to the active desktop number
        icoFile := A_ScriptDir . "\assets\" . desktop . ".ico"
        Menu, Tray, Icon , %icoFile%
    }
}
