# Telefon Safari/Chrome — ayni Wi-Fi aginda web onizleme.
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

if (-not (Test-Path "build\web\index.html")) {
    Write-Host "Web build yok — olusturuluyor..."
    flutter pub get
    flutter build web --release
}

$Port = if ($env:PORT) { [int]$env:PORT } else { 8080 }
$Ip = (
    Get-NetIPAddress -AddressFamily IPv4 |
    Where-Object {
        $_.IPAddress -notlike "127.*" -and
        $_.PrefixOrigin -ne "WellKnown"
    } |
    Sort-Object InterfaceMetric |
    Select-Object -First 1 -ExpandProperty IPAddress
)

Write-Host ""
Write-Host "SantiJET DEMIR web sunucusu"
Write-Host "  Bilgisayar: http://127.0.0.1:$Port"
if ($Ip) {
    Write-Host "  Telefon:    http://${Ip}:$Port"
    Write-Host "  -> Telefon ve bilgisayar ayni Wi-Fi / hotspot aginda olmali"
}
Write-Host ""

Set-Location build\web

$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) {
    $python = Get-Command py -ErrorAction SilentlyContinue
    if ($python) {
        py -m http.server $Port --bind 0.0.0.0
        exit $LASTEXITCODE
    }
    Write-Host "Python bulunamadi. Sunucuyu baslatmak icin:"
    Write-Host "  flutter run -d web-server --release --web-hostname 0.0.0.0 --web-port $Port"
    exit 1
}

python -m http.server $Port --bind 0.0.0.0
