function ConvertTo-ExpandedPropsArray (
    [Parameter(Mandatory = $true)] [hashtable] $Props
    , [Parameter(Mandatory = $true)] [string] $NewPropName
    , [Parameter(Mandatory = $true)] [object[]] $NewPropValues
) {
    $propsArray = @()
    foreach ($newPropValue in $NewPropValues) {
        $copyProps = $Props.Clone()
        $copyProps.$NewPropName = $newPropValue
        $propsArray += $copyProps
    }

    $propsArray
}

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

function Invoke-RestBatch (
    [Parameter(Mandatory = $true)] [string[]] $Hostnames
    , [Parameter(Mandatory = $true)] [string] $Method
    , [Parameter(Mandatory = $true)] [string] $Route
    , [Parameter(Mandatory = $false)] [string] $Cookies
    , [Parameter(Mandatory = $false)] [object] $Body = $null
    , [Parameter(Mandatory = $false)] [bool] $UseHttps = $false
    , [Parameter(Mandatory = $false)] [int] $Port = $null
) {
    $props = @{
        Method   = $Method
        Route    = $Route
        Body     = $Body
        Cookies  = $Cookies
        UseHttps = $UseHttps
        Port     = $Port
    }

    $expandedPropsArray = ConvertTo-ExpandedPropsArray `
        -Props $props `
        -NewPropName "Hostname" `
        -NewPropValues $Hostnames

    $results = @()
    foreach ($expandedProps in $expandedPropsArray) {
        $results += Invoke-Rest @expandedProps
    }

    $results
}