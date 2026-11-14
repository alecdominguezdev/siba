param([string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot))
$ErrorActionPreference = 'Stop'
$sourceRoot = Split-Path -Parent $PSScriptRoot
$ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
$manifestPath = Join-Path $ProjectRoot 'android\app\src\main\AndroidManifest.xml'
$iosTarget = Join-Path $ProjectRoot 'ios\Runner\Assets.xcassets'
$hasAndroid = Test-Path -LiteralPath $manifestPath
$hasIos = Test-Path -LiteralPath $iosTarget
if (-not $hasAndroid -and -not $hasIos) { throw 'Indica la raiz de tu proyecto Flutter con -ProjectRoot. Debe contener android o ios.' }
$backupRoot = Join-Path $ProjectRoot ('respaldo_iconos_siba\' + (Get-Date -Format 'yyyyMMdd_HHmmss_fff'))
function Backup-File([string]$path, [string]$relative) {
    if (Test-Path -LiteralPath $path) {
        $backup = Join-Path $backupRoot $relative
        New-Item -ItemType Directory -Path (Split-Path -Parent $backup) -Force | Out-Null
        Copy-Item -LiteralPath $path -Destination $backup -Force
    }
}
function Copy-IconTree([string]$source, [string]$relativeTarget) {
    $source = (Resolve-Path -LiteralPath $source).Path.TrimEnd([char[]]'\/')
    Get-ChildItem -LiteralPath $source -File -Recurse | ForEach-Object {
        $relative = $_.FullName.Substring($source.Length).TrimStart([char[]]'\/')
        $targetRelative = Join-Path $relativeTarget $relative
        $target = Join-Path $ProjectRoot $targetRelative
        Backup-File $target $targetRelative
        New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force | Out-Null
        Copy-Item -LiteralPath $_.FullName -Destination $target -Force
    }
}
if ($hasAndroid) {
    $manifest = New-Object System.Xml.XmlDocument
    $manifest.PreserveWhitespace = $true
    $manifest.XmlResolver = $null
    $manifest.LoadXml((Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8))
    $application = $manifest.SelectSingleNode('/manifest/application')
    if ($null -eq $application) { throw 'No se encontro application en AndroidManifest.xml.' }
    $namespace = 'http://schemas.android.com/apk/res/android'
    Backup-File $manifestPath 'android\app\src\main\AndroidManifest.xml'
    Copy-IconTree (Join-Path $sourceRoot 'platform_icons\android\app\src\main\res') 'android\app\src\main\res'
    foreach ($name in @('icon', 'roundIcon')) {
        $attribute = $application.GetAttributeNode($name, $namespace)
        if ($null -eq $attribute) {
            $attribute = $manifest.CreateAttribute('android', $name, $namespace)
            $null = $application.Attributes.Append($attribute)
        }
        $attribute.Value = if ($name -eq 'icon') { '@mipmap/ic_launcher' } else { '@mipmap/ic_launcher_round' }
    }
    $notice = $application.SelectNodes('meta-data') | Where-Object { $_.GetAttribute('name', $namespace) -eq 'com.google.firebase.messaging.default_notification_icon' } | Select-Object -First 1
    if ($null -eq $notice) { $notice = $manifest.CreateElement('meta-data'); $null = $application.AppendChild($notice) }
    foreach ($item in @(@('name', 'com.google.firebase.messaging.default_notification_icon'), @('resource', '@drawable/siba_notification_icon'))) {
        $attribute = $notice.GetAttributeNode($item[0], $namespace)
        if ($null -eq $attribute) { $attribute = $manifest.CreateAttribute('android', $item[0], $namespace); $null = $notice.Attributes.Append($attribute) }
        $attribute.Value = $item[1]
    }
    $manifest.Save($manifestPath)
    Write-Host 'Iconos Android y notificaciones instalados.'
}
if ($hasIos) {
    Copy-IconTree (Join-Path $sourceRoot 'platform_icons\ios\Runner\Assets.xcassets\AppIcon.appiconset') 'ios\Runner\Assets.xcassets\AppIcon.appiconset'
    Write-Host 'AppIcon de iOS instalado.'
}
Write-Host ('Respaldo de iconos anteriores: ' + $backupRoot)
Write-Host 'Listo. Compila y actualiza la app para ver el nuevo icono.'
