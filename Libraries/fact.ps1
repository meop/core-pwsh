function Get-Fact (
    [Parameter(Mandatory = $false)] $Config = (Get-ProfileConfig)
) {
    Read-Fact $Config['fact']['uri']
}