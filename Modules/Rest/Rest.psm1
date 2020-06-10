function Invoke-Rest (
    [Parameter(Mandatory = $true)] [string] $Hostname
    , [Parameter(Mandatory = $true)] [string] $Method
    , [Parameter(Mandatory = $true)] [string] $Route
    , [Parameter(Mandatory = $false)] [string] $Cookies
    , [Parameter(Mandatory = $false)] [object] $Body = $null
    , [Parameter(Mandatory = $false)] [bool] $UseHttps = $false
    , [Parameter(Mandatory = $false)] [int] $Port = $null
) {
    $protocol = $UseHttps ? 'https' : 'http'
    $port = $Port ? $Port : ($UseHttps ? 443 : 80)

    $uri = "$($protocol)://$($Hostname):$port/$Route"
    $webSession = New-Object Microsoft.PowerShell.Commands.WebRequestSession

    $webSession.Cookies.SetCookies($uri, $Cookies)

    $props = @{
        Method      = $Method
        Uri         = $uri
        ContentType = 'application/json'
        WebSession  = $webSession
    }

    if ($Body) {
        $props.Add('Body', ($Body | ConvertTo-Json -Depth 100))
    }

    Invoke-RestMethod @props
}