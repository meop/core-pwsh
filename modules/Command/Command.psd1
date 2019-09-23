@{
    ModuleVersion        = '1.0'
    CompatiblePSEditions = @(
        , 'Core'
    )
    ScriptsToProcess     = @(
        , 'Command.ps1'
    )
    NestedModules        = @(
        , 'Command.psm1'
        , 'Sudo.psm1'
    )
}