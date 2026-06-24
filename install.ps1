# install.ps1 - set up claude-code-statusline on Windows.
# Run from a clone:  .\install.ps1
# Or one-liner:      irm https://gitlab.com/spiegel/claude-code-statusline/-/raw/main/install.ps1 | iex
$ErrorActionPreference = 'Stop'

$cfg = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $HOME '.claude' }
New-Item -ItemType Directory -Force -Path $cfg | Out-Null
$dest = Join-Path $cfg 'statusline.ps1'

# Use the local script if running from a clone, otherwise download it.
$local = if ($PSScriptRoot) { Join-Path $PSScriptRoot 'statusline.ps1' } else { $null }
if ($local -and (Test-Path $local)) {
    Copy-Item $local $dest -Force
} else {
    $url = 'https://gitlab.com/spiegel/claude-code-statusline/-/raw/main/statusline.ps1'
    Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing
}

# Merge the statusLine entry into settings.json (keeping existing settings).
$settingsPath = Join-Path $cfg 'settings.json'
$settings = if (Test-Path $settingsPath) {
    [IO.File]::ReadAllText($settingsPath) | ConvertFrom-Json
} else {
    [pscustomobject]@{}
}
$cmd = "powershell -ExecutionPolicy Bypass -File `"$dest`""
$settings | Add-Member -NotePropertyName statusLine -NotePropertyValue ([pscustomobject]@{ type = 'command'; command = $cmd }) -Force
[IO.File]::WriteAllText($settingsPath, ($settings | ConvertTo-Json -Depth 20), (New-Object System.Text.UTF8Encoding($false)))

Write-Host "Installed -> $dest"
Write-Host "Restart Claude Code (or open a new session) to see the status line."
