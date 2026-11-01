<#
.SYNOPSIS
    Add the Blackwall profile and colour scheme to Windows Terminal, as a fragment.
.DESCRIPTION
    Writes one folder, %LOCALAPPDATA%\Microsoft\Windows Terminal\Fragments\BlackwallTerminal, with:
      blackwall.json   the "Blackwall" colour scheme, and a "Blackwall" profile that uses it and the shader
      blackwall.hlsl   the pixel shader, copied there so the profile keeps working if this folder moves
    Your settings.json is never edited. Windows Terminal reads fragments when it starts: close every Terminal
    window, open it again, and pick "Blackwall" from the new-tab menu.
    -Uninstall removes exactly those two files, and the folder if it is then empty.
.EXAMPLE
    pwsh -File install.ps1
    pwsh -File install.ps1 -Shell 'C:\Windows\System32\cmd.exe'
    pwsh -File install.ps1 -Uninstall
#>
param(
    # The program the profile runs. Default: PowerShell 7 if installed, else Windows PowerShell.
    [string]$Shell = '',
    [switch]$Uninstall,
    # Where Windows Terminal reads user fragments. Overridable for tests.
    [string]$FragmentDir = (Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\Fragments\BlackwallTerminal')
)
$ErrorActionPreference = 'Stop'
$json = Join-Path $FragmentDir 'blackwall.json'
$shader = Join-Path $FragmentDir 'blackwall.hlsl'

if ($Uninstall) {
    foreach ($file in @($json, $shader)) {
        if (Test-Path -LiteralPath $file) { Remove-Item -LiteralPath $file }
    }
    if ((Test-Path -LiteralPath $FragmentDir) -and -not (Get-ChildItem -LiteralPath $FragmentDir -Force)) {
        Remove-Item -LiteralPath $FragmentDir
    }
    Write-Output 'Blackwall removed. Restart Windows Terminal.'
    return
}

if (-not $Shell) {
    $pwsh = Get-Command pwsh -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    $Shell = if ($pwsh) { $pwsh.Source } else { Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe' }
}
if (-not (Test-Path -LiteralPath $Shell)) { throw "No program at '$Shell'. Pass -Shell with a full path." }

$scheme = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'scheme\blackwall.json') -Raw | ConvertFrom-Json
New-Item -ItemType Directory -Force -Path $FragmentDir | Out-Null
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'shaders\blackwall.hlsl') -Destination $shader -Force

$fragment = [ordered]@{
    profiles = @([ordered]@{
            name                           = 'Blackwall'
            commandline                    = "`"$Shell`""
            colorScheme                    = 'Blackwall'
            'experimental.pixelShaderPath' = $shader
        })
    schemes  = @($scheme)
}
[IO.File]::WriteAllText($json, ($fragment | ConvertTo-Json -Depth 5), (New-Object Text.UTF8Encoding $false))
Write-Output "Installed: $FragmentDir"
Write-Output 'Close every Windows Terminal window, open it again, and pick "Blackwall" from the new-tab menu.'
