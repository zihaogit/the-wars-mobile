<#
.SYNOPSIS
Captures operator-verified checkpoints while testing The War custom map.

.EXAMPLE
powershell -ExecutionPolicy Bypass -File .\scripts\test-warcraft-map.ps1
#>
param(
    [string]$OutputDirectory = (Join-Path $env:TEMP 'the-wars-map-smoke-test')
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class WarcraftMapTestNative {
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr handle);

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr handle, int command);

    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll")]
    public static extern bool SetCursorPos(int x, int y);

    [DllImport("user32.dll")]
    public static extern void mouse_event(uint flags, uint dx, uint dy, uint data, UIntPtr extraInfo);

    [StructLayout(LayoutKind.Sequential)]
    public struct RECT {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }

    [DllImport("user32.dll")]
    public static extern bool GetWindowRect(IntPtr handle, out RECT rect);
}
'@

$process = Get-Process -Name 'war3' -ErrorAction SilentlyContinue |
    Where-Object { $_.MainWindowHandle -ne [IntPtr]::Zero } |
    Select-Object -First 1

if (-not $process) {
    throw 'Warcraft III is not running with a visible game window. Start The War map, then run this script again.'
}
if (-not $process.Responding) {
    throw 'The Warcraft III window is not responding.'
}

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$OutputDirectory = [System.IO.Path]::GetFullPath($OutputDirectory)
$logPath = Join-Path $OutputDirectory 'results.jsonl'

[void][WarcraftMapTestNative]::ShowWindow($process.MainWindowHandle, 9)
[void][WarcraftMapTestNative]::SetForegroundWindow($process.MainWindowHandle)
Start-Sleep -Milliseconds 500

$windowRect = New-Object WarcraftMapTestNative+RECT
if (-not [WarcraftMapTestNative]::GetWindowRect($process.MainWindowHandle, [ref]$windowRect)) {
    throw 'Could not read the Warcraft III window bounds.'
}
$windowBounds = [System.Drawing.Rectangle]::FromLTRB(
    $windowRect.Left,
    $windowRect.Top,
    $windowRect.Right,
    $windowRect.Bottom
)

function Move-ToWhiteBase {
    $x = $windowBounds.Left + [int]($windowBounds.Width * 0.059)
    $y = $windowBounds.Top + [int]($windowBounds.Height * 0.958)

    [void][WarcraftMapTestNative]::SetForegroundWindow($process.MainWindowHandle)
    Start-Sleep -Milliseconds 300
    if ([WarcraftMapTestNative]::GetForegroundWindow() -ne $process.MainWindowHandle) {
        throw 'Could not focus Warcraft III to navigate to the white base.'
    }

    [void][WarcraftMapTestNative]::SetCursorPos($x, $y)
    [WarcraftMapTestNative]::mouse_event(0x0002, 0, 0, 0, [UIntPtr]::Zero)
    [WarcraftMapTestNative]::mouse_event(0x0004, 0, 0, 0, [UIntPtr]::Zero)
    Start-Sleep -Milliseconds 500
}

function Save-Checkpoint {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Instruction
    )

    Write-Host ''
    Write-Host $Instruction
    $observation = Read-Host 'Complete the step, then enter what you observed (or Q to stop)'
    if ($observation -eq 'Q') {
        throw 'Test stopped by the operator.'
    }

    [void][WarcraftMapTestNative]::SetForegroundWindow($process.MainWindowHandle)
    Start-Sleep -Milliseconds 500
    $bitmap = New-Object System.Drawing.Bitmap($windowBounds.Width, $windowBounds.Height)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    try {
        $graphics.CopyFromScreen(
            $windowBounds.Location,
            [System.Drawing.Point]::Empty,
            $windowBounds.Size
        )
        $imagePath = Join-Path $OutputDirectory ($Name + '.png')
        $bitmap.Save($imagePath, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally {
        $graphics.Dispose()
        $bitmap.Dispose()
    }

    $record = [ordered]@{
        checkpoint = $Name
        capturedAt = (Get-Date).ToString('o')
        observation = $observation
        screenshot = $imagePath
        resolution = "$($windowBounds.Width)x$($windowBounds.Height)"
    } | ConvertTo-Json -Compress
    [System.IO.File]::AppendAllText($logPath, $record + [Environment]::NewLine)
    Write-Host "Saved $imagePath"
}

Write-Host "Attached to $($process.MainWindowTitle) ($($windowBounds.Width)x$($windowBounds.Height))."
Write-Host "Evidence directory: $OutputDirectory"
Write-Host 'The script navigates to the white base. Verify each building and perform upgrades yourself.'

Move-ToWhiteBase
Save-Checkpoint -Name '01-white-base' -Instruction 'Confirm the camera is at your white base in the bottom-left of the minimap.'
Save-Checkpoint -Name '02-goblin-selected' -Instruction 'Select your Goblin building and verify its name, level, and upgrade command.'
Save-Checkpoint -Name '03-goblin-max-verified' -Instruction 'Upgrade the Goblin building until max level, confirming each level and resource change.'
Save-Checkpoint -Name '04-ranged-selected' -Instruction 'Select your ranged building and verify its name, level, and upgrade command.'
Save-Checkpoint -Name '05-ranged-max-verified' -Instruction 'Upgrade the ranged building until max level, confirming each level and resource change.'

Write-Host ''
Write-Host "Test checkpoints complete. Review screenshots and observations in $OutputDirectory."
