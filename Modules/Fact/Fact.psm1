Add-Type -AssemblyName System.Web

function Read-Fact ($Uri) {
    $rawJoke = Invoke-RestMethod -uri $Uri
    [System.Web.HttpUtility]::HtmlDecode($rawJoke.value.joke)
}
