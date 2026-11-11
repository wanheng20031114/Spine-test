param(
    [switch]$CheckOnly,
    [string]$Godot = 'C:\Program Files\Godot\Godot.exe'
)
$ErrorActionPreference = 'Stop'
# Run from the parent directory after exiting ChatGPT/Codex. This chat's
# tool processes keep working-directory handles open on the original folder.
$currentProject = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$projectParent = [IO.Directory]::GetParent($currentProject).FullName
$sourceDirectory = [IO.Path]::GetFullPath((Join-Path $projectParent 'Spain-test'))
$destinationDirectory = [IO.Path]::GetFullPath((Join-Path $projectParent 'Spine-test'))
if ($currentProject -ne $sourceDirectory -and $currentProject -ne $destinationDirectory) {
    throw 'Run this script only from Spain-test/tools or Spine-test/tools.'
}
if (-not (Test-Path -LiteralPath $Godot -PathType Leaf)) {
    throw 'Godot executable not found. Pass its path with -Godot.'
}
if ((Test-Path -LiteralPath $sourceDirectory) -and (Test-Path -LiteralPath $destinationDirectory)) {
    throw 'Both folders exist. Nothing was changed; no directory will be overwritten.'
}
$projectFile = Join-Path $currentProject 'project.godot'
if (-not (Test-Path -LiteralPath $projectFile -PathType Leaf)) {
    throw 'Expected Godot project is missing.'
}
Write-Output "Source: $sourceDirectory"
Write-Output "Destination: $destinationDirectory"
if ($CheckOnly) {
    Write-Output 'RENAME_PREFLIGHT_OK (no files moved)'
    exit 0
}
# The parent remains a valid working directory throughout the operation.
Set-Location -LiteralPath $projectParent
if (Test-Path -LiteralPath $sourceDirectory) {
    try {
        Rename-Item -LiteralPath $sourceDirectory -NewName 'Spine-test' -ErrorAction Stop
    } catch {
        Write-Error 'Folder is still in use. Exit ChatGPT/Codex and the old Godot editor, then run this script again. No files were deleted.'
        exit 1
    }
}
if (-not (Test-Path -LiteralPath (Join-Path $destinationDirectory 'project.godot'))) {
    throw 'Renamed project could not be verified.'
}
Write-Output 'RENAMED: Spine-test'
Start-Process -FilePath $Godot -ArgumentList @('--path', ('"' + $destinationDirectory + '"'), '--editor')
