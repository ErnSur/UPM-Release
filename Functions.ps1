Set-Alias "ex" Invoke-Utility

function Update-GitCreds {
    $committerName = ex git log -1 --pretty=format:'%an'
    $committerEmail = ex git log -1 --pretty=format:'%ae'
    ex git config --global user.name "$committerName"
    ex git config --global user.email "$committerEmail"
    Write-Host "Update Git credentials to: $committerName : $committerEmail"
}

function Remove-AllExceptPackage([Parameter(Mandatory)] $PackageDirectory) {
    $filesToRemove = Get-FilesToDelete $PackageDirectory
    $filesToRemove | Remove-Item -Recurse -Force
    ex git mv "$PackageDirectory/*" "./"
    Remove-Item -Path "$PackageDirectory" -Recurse -Force
    ex git add .
}

function Get-FilesToDelete([Parameter(Mandatory)] $PackageDirectory) {
    return Get-ChildItem -Force | 
    Where-Object Name -notin '.git', '.github' |
    Where-Object { $PackageDirectory -notlike "$($_.Name)*" } |
    Select-Object -ExpandProperty FullName |
    Sort-Object Length -Descending
}

function Update-SamplesDirectory([Parameter(Mandatory)] $PackageDirectory) {
    $samplesDir = Join-Path $PackageDirectory "Samples"
    if (Test-Path "$samplesDir") {
        ex git mv "$samplesDir" "${samplesDir}~"
        ex git rm -f "${samplesDir}.meta"
    }
}

function New-CommitWithVersionTag {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string] $BranchName,
        [Parameter(Mandatory)]
        [string] $PackageVersion
    )
    ex git branch -f $BranchName
    ex git checkout $BranchName
    ex git commit -m "UPM package $PackageVersion"
    ex git tag -f $PackageVersion
    ex git push -f --set-upstream origin $BranchName
    ex git push origin $PackageVersion -f
}

function Get-PackageVersion([Parameter(Mandatory)] $PackageDirectory) {
    Get-Content "$PackageDirectory/package.json" | 
    Out-String | 
    ConvertFrom-Json | 
    Select-Object -ExpandProperty version
}

function Invoke-Utility {
    <#
    .SYNOPSIS
    Invokes an external utility, ensuring successful execution.
    
    .DESCRIPTION
    Invokes an external utility (program) and, if the utility indicates failure by 
    way of a nonzero exit code, throws a script-terminating error.
    
    * Pass the command the way you would execute the command directly.
    * Do NOT use & as the first argument if the executable name is not a literal.
    
    .EXAMPLE
    Invoke-Utility git push
    
    Executes `git push` and throws a script-terminating error if the exit code
    is nonzero.
    #>
    $exe, $argsForExe = $Args
    # Workaround: Prevents 2> redirections applied to calls to this function
    #             from accidentally triggering a terminating error.
    #             See bug report at https://github.com/PowerShell/PowerShell/issues/4002
    $ErrorActionPreference = 'Continue'
    try { & $exe $argsForExe } catch { Throw } # catch is triggered ONLY if $exe can't be found, never for errors reported by $exe itself
    if ($LASTEXITCODE) { Throw "$exe indicated failure (exit code $LASTEXITCODE; full command: $Args)." }
}
