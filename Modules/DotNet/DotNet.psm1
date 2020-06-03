function Format-AssemblyDependencies (
    $Path = $PWD
    , $Depth = 0
    , $Filter = $null
) {
    $files = Get-ChildItem -Path $Path -Recurse -Depth $Depth -Filter "*.dll"

    if ($Filter) {
        $filterMsg = " matching {$Filter}"
        $files = $files | Where-Object { $_.FullName | Select-String $Filter }
    }

    if (-not $files) {
        Write-Output "no files$filterMsg found at {$Path}"
        return
    }

    $files | ForEach-Object {
        $name = $_.Name
        $fileVersion = (Get-Item $_.FullName).VersionInfo.FileVersion
        $productVersion = (Get-Command $_.FullName).Version
        Write-Output "dll, file version, product version : $name, $fileVersion, $productVersion"

        [reflection.assembly]::LoadFile($_.FullName).GetReferencedAssemblies() | ForEach-Object {
            $name = $_.Name
            $asmVersion = $_.Version
            Write-Output "  dep, assembly, version : $name, $asmVersion"
        }
    }
}