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

Write-Host "Remove Solr service"
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

Write-Host "Delete JKS file"
$jreVal = [Environment]::GetEnvironmentVariable("JAVA_HOME", [EnvironmentVariableTarget]::Machine)
$path = $jreVal + '\bin\keytool.exe'
$keytool = (Get-Command $path).Source
& $keytool -delete -alias "solr-ssl" -storetype JKS -keystore $KeystoreFile -storepass $keystoreSecret

if((Test-Path $KeystoreFile)) {
	Remove-Item $KeystoreFile
}

Write-Host "Delete P12 file"
$P12Path = [IO.Path]::ChangeExtension($KeystoreFile, 'p12')
if((Test-Path $P12Path)) {
	Remove-Item $P12Path
}

Write-Host "Remove Solr root folder"
If((Test-Path $solrRoot)) {
    Remove-Item -Path $solrRoot -Force -Recurse
} 

Write-Host "Remove Solr SSL Certificate"
Get-ChildItem -Path "Cert:\LocalMachine\Root" | Where-Object -Property FriendlyName -eq "solr-ssl" | Remove-Item