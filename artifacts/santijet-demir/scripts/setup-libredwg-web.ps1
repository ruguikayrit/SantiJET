$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$Target = Join-Path $Root "web\dwg"
$Tmp = Join-Path $env:TEMP ("santijet-libredwg-" + [Guid]::NewGuid().ToString("N"))

New-Item -ItemType Directory -Force -Path $Tmp | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $Target "wasm") | Out-Null

try {
    Push-Location $Tmp
    npm pack @mlightcad/libredwg-web | Out-Null
    $tgz = Get-ChildItem "mlightcad-libredwg-web-*.tgz" | Select-Object -First 1
    tar -xzf $tgz.FullName

    Copy-Item "package\dist\libredwg-web.js" (Join-Path $Target "libredwg-web.js") -Force
    Copy-Item "package\wasm\libredwg-web.js" (Join-Path $Target "wasm\") -Force
    Copy-Item "package\wasm\libredwg-web.wasm" (Join-Path $Target "wasm\") -Force

    $jsPath = Join-Path $Target "libredwg-web.js"
    $content = Get-Content $jsPath -Raw
    $content = $content -replace 'from "../wasm/', 'from "./wasm/'
    Set-Content $jsPath $content -NoNewline

    Write-Host "LibreDWG web assets installed under $Target"
}
finally {
    Pop-Location
    Remove-Item -Recurse -Force $Tmp -ErrorAction SilentlyContinue
}
