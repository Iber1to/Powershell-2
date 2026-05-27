#Requires -Version 5.1

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Test-PathUnderRoot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Root
    )

    $normalizedPath = ([string]$Path).TrimEnd('\').ToUpperInvariant()
    $normalizedRoot = ([string]$Root).TrimEnd('\').ToUpperInvariant()

    return ($normalizedPath -eq $normalizedRoot -or $normalizedPath.StartsWith($normalizedRoot + '\'))
}

function Get-WorldShipFolder {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string[]]$DriveRoots = @('C:\')
    )

    $excludedRoots = @(
        'C:\Windows',
        'C:\Users',
        'C:\ProgramData',
        'C:\Documents and Settings'
    ) | Where-Object {
        Test-Path -LiteralPath $_ -PathType Container
    }

    $foundFolders = New-Object System.Collections.Generic.List[string]

    foreach ($driveRoot in ($DriveRoots | Select-Object -Unique)) {
        if (-not (Test-Path -LiteralPath $driveRoot -PathType Container)) {
            continue
        }

        $pendingPaths = New-Object 'System.Collections.Generic.Queue[string]'
        $pendingPaths.Enqueue($driveRoot)

        while ($pendingPaths.Count -gt 0) {
            $currentPath = $pendingPaths.Dequeue()

            $skipCurrentPath = $false
            foreach ($excludedRoot in $excludedRoots) {
                if (Test-PathUnderRoot -Path $currentPath -Root $excludedRoot) {
                    $skipCurrentPath = $true
                    break
                }
            }

            if ($skipCurrentPath) {
                continue
            }

            try {
                $childDirectories = @(
                    Get-ChildItem -LiteralPath $currentPath -Directory -Force -ErrorAction Stop
                )
            }
            catch {
                continue
            }

            foreach ($childDirectory in $childDirectories) {
                $childFullName = $childDirectory.FullName

                if (($childDirectory.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                    continue
                }

                $skipChildPath = $false
                foreach ($excludedRoot in $excludedRoots) {
                    if (Test-PathUnderRoot -Path $childFullName -Root $excludedRoot) {
                        $skipChildPath = $true
                        break
                    }
                }

                if ($skipChildPath) {
                    continue
                }

                if ($childDirectory.Name -like '*WorldShip*') {
                    $foundFolders.Add($childFullName) | Out-Null
                }

                $pendingPaths.Enqueue($childFullName)
            }
        }
    }

    return @($foundFolders | Sort-Object -Unique)
}

try {
    $worldShipFolders = @(Get-WorldShipFolder)

    if ($worldShipFolders.Count -gt 0) {
        [pscustomobject]@{
            Check  = 'WorldShipFolder'
            Status = 'Success'
            Path   = $worldShipFolders[0]
            Count  = $worldShipFolders.Count
        } | ConvertTo-Json -Compress

        exit 0
    }

    [pscustomobject]@{
        Check  = 'WorldShipFolder'
        Status = 'Fail'
        Path   = $null
        Count  = 0
    } | ConvertTo-Json -Compress

    exit 1
}
catch {
    [pscustomobject]@{
        Check  = 'WorldShipFolder'
        Status = 'Fail'
        Path   = $null
        Count  = 0
    } | ConvertTo-Json -Compress

    exit 1
}