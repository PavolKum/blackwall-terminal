<#
.SYNOPSIS
    Print a little sample output in the Blackwall colours, for screenshots: a prompt, a log, the 16-colour palette.
.EXAMPLE
    pwsh -File tools/demo.ps1
#>
$e = [char]27
function Say([string]$text) { [Console]::Out.Write($text + "`n") }

Clear-Host
Say "$e[90mPS$e[0m $e[37mC:\code\blackwall-terminal$e[0m$e[91m>$e[0m git log --oneline -6"
Say "$e[33m3f9c2a1$e[0m shaders: dots fade on a fixed threshold, so the wall never sparkles"
Say "$e[33m8d41e07$e[0m shaders: a band of light sweeps across, the bottom edge glows"
Say "$e[33mc72b9e4$e[0m shaders: every 14 s something magenta swells behind the wall"
Say "$e[33m15ae6d0$e[0m install: a Terminal fragment - settings.json is never touched"
Say "$e[33m9b03f55$e[0m scheme: Blackwall, rose-black ground and barrier red"
Say "$e[33m0e7714c$e[0m first light"
Say ""
Say "$e[90mPS$e[0m $e[37mC:\code\blackwall-terminal$e[0m$e[91m>$e[0m Get-Palette"
# Colours 1-7 and their bright versions (0, black, is the ground's own neighbour and would not show).
$names = 'red', 'green', 'yellow', 'blue', 'purple', 'cyan', 'white'
$row1 = ''
$row2 = ''
for ($i = 1; $i -le 7; $i++) {
    $row1 += "$e[$(30 + $i)m" + $names[$i - 1].PadRight(9) + "$e[0m"
    $row2 += "$e[$(90 + $i)m" + $names[$i - 1].ToUpper().PadRight(9) + "$e[0m"
}
Say $row1
Say $row2
Say ""

# The prompt the window keeps after this script (run with -NoExit): the same neutral path as above.
function global:prompt { "$e[90mPS$e[0m $e[37mC:\code\blackwall-terminal$e[0m$e[91m>$e[0m " }
