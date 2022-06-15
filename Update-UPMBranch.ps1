param (
    [Parameter(Mandatory)]
    [string] $BranchName,
    [Parameter(Mandatory)]
    [string] $PackageDirectory
)

$ErrorActionPreference = "Stop"
. $PSScriptRoot/Functions.ps1

$packageVersion = Get-PackageVersion $packageDirectory
Update-GitCreds
Remove-AllExceptPackage $PackageDirectory
Update-SamplesDirectory (Get-Location)
New-CommitWithVersionTag $BranchName $packageVersion