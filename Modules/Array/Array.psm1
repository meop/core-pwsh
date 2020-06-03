# https://stackoverflow.com/questions/13888253/powershell-break-a-long-array-into-a-array-of-array-with-length-of-n-in-one-line
function Invoke-ArrayGroupIntoSubArrays($array, $bucketSize) {
    $counter = [PSCustomObject] @{ Value = 0 }

    $array | Group-Object -Property { [math]::Floor($counter.Value++ / $bucketSize) }
}

function Invoke-ArraySequenceCompare($array1, $array2) {
    $result = $true
    $array1Length = $array1.Length
    $array2Length = $array2.Length

    if ($array1Length -ne $array2Length) {
        $result = $false
    } else {
        for ($i = 0; $i -lt $array2Length; ++$i) {
            if ($array1[$i] -ne $array2[$i]) {
                $result = $false
            }
        }
    }

    $result
}