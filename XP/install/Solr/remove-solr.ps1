Param(
    [string]$solrVersion = "6.6.2",
    [string]$installFolder = "c:\solr",
    [bool]$solrSSL = $TRUE,
    [string]$nssmVersion = "2.24",
	[string]$keystoreSecret = "secret",
	[string]$KeystoreFile = 'solr-ssl.keystore.jks'
)


$solrName = "solr-$solrVersion"
$solrRoot = "$installFolder\$solrName"
$nssmRoot = "$installFolder\nssm-$nssmVersion"

$ErrorActionPreference = 'Stop'

Write-Host "Remove Solr service: $($solrName)" -ForegroundColor Green
$svc = Get-Service "$solrName" -ErrorAction SilentlyContinue
if($svc)
{
    $nssmTool = "$installFolder\nssm-$nssmVersion\win64\nssm.exe"
    if ($svc.Status -eq "Running")
    {
        &"$nssmTool" stop "$solrName"
    }
    &"$nssmTool" remove "$solrName" confirm
}


if((Test-Path $KeystoreFile)) {
    Write-Host "Delete JKS file: $($KeystoreFile)" -ForegroundColor Green
    $jreVal = [Environment]::GetEnvironmentVariable("JAVA_HOME", [EnvironmentVariableTarget]::Machine)
    $path = $jreVal + '\bin\keytool.exe'

    $keytool = (Get-Command $path).Source
    & $keytool -delete -alias "solr-ssl" -storetype JKS -keystore $KeystoreFile -storepass $keystoreSecret

    Remove-Item $KeystoreFile
    
    
    $P12Path = [IO.Path]::ChangeExtension($KeystoreFile, 'p12')
    Write-Host "Delete P12 file: $($P12Path)" -ForegroundColor Green
    if((Test-Path $P12Path)) {
        Remove-Item $P12Path
    }
}


Write-Host "Remove Solr root folder: $($solrRoot)" -ForegroundColor Green
If((Test-Path $solrRoot)) {
    Remove-Item -Path $solrRoot -Force -Recurse
} 

Write-Host "Remove Solr SSL Certificate" -ForegroundColor Green
Get-ChildItem -Path "Cert:\LocalMachine\Root" | Where-Object -Property FriendlyName -eq "solr-ssl" | Remove-Item