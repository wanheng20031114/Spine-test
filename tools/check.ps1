param([string]$Godot = 'C:\Program Files\Godot\Godot.exe')
$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$testDirectory = Join-Path $projectRoot '.local'
New-Item -ItemType Directory -Force -Path $testDirectory | Out-Null
function Invoke-GodotCheck([string[]]$ExtraArguments, [string]$LogName, [string]$ExpectedMarker) {
    $logPath = Join-Path $testDirectory $LogName
    $arguments = @('--headless', '--path', ('"' + $projectRoot + '"')) + $ExtraArguments + @('--log-file', ('"' + $logPath + '"'))
    $testProcess = Start-Process -FilePath $Godot -ArgumentList $arguments -Environment @{APPDATA=(Join-Path $testDirectory 'test-appdata')} -WindowStyle Hidden -PassThru
    try {
        if (-not $testProcess.WaitForExit(30000)) { throw 'Godot check exceeded 30 seconds.' }
        $log = Get-Content -LiteralPath $logPath -Encoding UTF8 -Raw
        Write-Output $log
        if ($testProcess.ExitCode -ne 0 -or $log -match '(?m)^(SCRIPT ERROR|ERROR):' -or ($ExpectedMarker -and $log -notmatch $ExpectedMarker)) {
            throw "Godot check failed. See .local/$LogName."
        }
    } finally {
        if (-not $testProcess.HasExited) {
            Stop-Process -Id $testProcess.Id
            $testProcess.WaitForExit()
        }
    }
}
Invoke-GodotCheck @('--editor', '--quit') 'import-check.log' ''
Invoke-GodotCheck @('res://tests/gameplay_test.tscn') 'gameplay-test.log' 'GAMEPLAY_TEST_OK'
