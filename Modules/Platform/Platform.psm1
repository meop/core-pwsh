function Edit-TrimForwardSlashes ($path) {
    $path.Trim('/')
}

function Edit-TrimLeadingForwardSlashes ($path) {
    $path.TrimStart('/')
}

function Edit-TrimTrailingForwardSlashes ($path) {
    $path.TrimEnd('/')
}

function ConvertTo-BackwardSlashes ($path) {
    $path.Replace('/','\')
}

function ConvertTo-ForwardSlashes ($path) {
    $path.Replace('\','/')
}

function ConvertTo-CrossPlatformPathFormat ($path) {
    ConvertTo-ForwardSlashes $path
}

function ConvertTo-ExpandedDirectoryPathFormat ($path) {
    ConvertTo-CrossPlatformPathFormat $path.Replace(':','')
}
