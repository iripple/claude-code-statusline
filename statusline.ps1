# claude-code-statusline (Windows / PowerShell)
# Reads Claude Code's status JSON on stdin, prints one status line.
$ErrorActionPreference = 'SilentlyContinue'
$reader = New-Object IO.StreamReader([Console]::OpenStandardInput(), [Text.Encoding]::UTF8)
$raw = $reader.ReadToEnd()
$j = $null; try { $j = $raw | ConvertFrom-Json } catch {}
$esc = [char]27
$sep = ' '
$ti = (Get-Culture).TextInfo
function Col($n, $t) { "${esc}[38;5;${n}m$t${esc}[0m" }
$parts = @()

# Claude account email (auto-updates on account switch)
$cj = Join-Path $HOME '.claude.json'
if (Test-Path $cj) {
    $txt = [IO.File]::ReadAllText($cj, [Text.Encoding]::UTF8)
    if ($txt -match '"emailAddress"\s*:\s*"([^"]*)"') { $parts += Col 141 "[$($matches[1])]" }
}

# model
if ($j.model.display_name) { $parts += Col 67 "[$($j.model.display_name)]" }

# current folder
$dir = $j.workspace.current_dir; if (-not $dir) { $dir = $j.cwd }
if ($dir) { $parts += Col 110 "[$(Split-Path $dir -Leaf)]" }

# git branch (+ * if dirty), [] when not a repo
$br = ''; $dirty = ''
if ($dir) {
    Push-Location $dir
    $br = git rev-parse --abbrev-ref HEAD 2>$null
    if ($br) { $dirty = if (git status --porcelain 2>$null) { '*' } else { '' } }
    Pop-Location
}
if ($br) { $parts += Col 179 "[$br$dirty]" } else { $parts += Col 179 "[]" }

# active skill badges: any <config>/.<name>-active flag file
$cdir = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $HOME '.claude' }
foreach ($f in Get-ChildItem -Path $cdir -Filter '*-active' -File -Force) {
    $name = $ti.ToTitleCase((($f.Name -replace '^\.', '') -replace '-active$', '').ToLower())
    $mode = (Get-Content $f.FullName | Select-Object -First 1)
    if ($mode) { $mode = $mode.Trim() }
    $label = if ($mode -and $mode -ne 'full') { "${name}:" + $ti.ToTitleCase($mode.ToLower()) } else { $name }
    $parts += Col 108 "[$label]"
}

$line = $parts -join (Col 240 $sep)
$o = [Console]::OpenStandardOutput()
$b = [Text.Encoding]::UTF8.GetBytes($line)
$o.Write($b, 0, $b.Length); $o.Flush()
