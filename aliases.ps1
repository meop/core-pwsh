# Libraries

Set-Alias -Name dockerLaunch -Value Invoke-Docker

Set-Alias -Name gitRebaseWithRetries -Value Invoke-GitRebaseWithRetries
Set-Alias -Name gitRebaseWithRetriesGroup -Value Invoke-GitRebaseWithRetriesGroup
Set-Alias -Name gitUpdateReposCacheFile -Value Update-GitReposCacheFile

Set-Alias -Name gtfsCloneConcurrent -Value Invoke-GitTfsCloneConcurrent
Set-Alias -Name gtfsCloneBatch -Value Invoke-GitTfsCloneBatch
Set-Alias -Name gtfsFetchBatch -Value Invoke-GitTfsFetchBatch
Set-Alias -Name gtfsFetchGroup -Value Invoke-GitTfsFetchGroup

Set-Alias -Name hostnames -Value Get-Hostnames

Set-Alias -Name msbuildLaunch -Value Invoke-MsBuild
Set-Alias -Name msbuildBatch -Value Invoke-MsBuildBatch
Set-Alias -Name msbuildGroup -Value Invoke-MsBuildGroup
Set-Alias -Name msbuildUpdateProjectsCacheFile -Value Update-MsBuildProjectsCacheFile

Set-Alias -Name nugetRestoreConcurrent -Value Invoke-NugetRestoreConcurrent
Set-Alias -Name nugetRestoreBatch -Value Invoke-NugetRestoreBatch
Set-Alias -Name nugetRestoreGroup -Value Invoke-NugetRestoreGroup

Set-Alias -Name qemuLaunch -Value Invoke-Qemu
Set-Alias -Name qumuCheckLaunch -Value Invoke-QemuCheck

Set-Alias -Name vagrantLaunch -Value Invoke-Vagrant

# Modules

Set-Alias -Name fact -Value Invoke-Fact

Set-Alias -Name rcloneGroup -Value Invoke-RcloneGroup
Set-Alias -Name symlinkGroup -Value Invoke-SymlinkGroup