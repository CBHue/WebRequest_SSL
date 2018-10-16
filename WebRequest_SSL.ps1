####################################################################################
# 
# sslWebRequest.ps1 
#
# Description: 
# SSL Web request using powershell
#
# Example: 
# .\sslWebRequest.ps1 -proxy http://127.0.0.1:8080 -hostHeader localhost.localdomain.com -masqueradeHost 127.0.0.1
#
#
# Author: 
# Hue B. Solutions LLC, CBHue
#
####################################################################################

[CmdletBinding()]
Param (
    [Parameter(Mandatory=$true)]
    [String] $uri,
    [Parameter(Mandatory=$false)]
    [String] $proxy,
    [String] $hostHeader, 
    [String] $masqueradeHost, 
    [String] $OutputDelimiter = "`n"
)

#
# Setup SSL
#
function Set-SSL {
    add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
    $AllProtocols = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
    [System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols
    [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
}

function Get-Headers($hostIP) {
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    if ($hostHeader){
        $headers.Add('Host',"$hostHeader")
    }
    if ($masqueradeHost){
        $headers.Add('Via',"HTTP/1.1 $hostIP")
        $headers.Add('Origin',"http://$hostIP")
        $headers.Add('X-WAP-Profile',"http://$hostIP/test")
        $headers.Add('X-Real-IP',"$hostIP")
        $headers.Add('X-ProxyUser-Ip',"$hostIP")
        $headers.Add('X-Forwarded-Host',"$hostIP")
        $headers.Add('X-Forwarded-For', "$hostIP")
        $headers.Add('True-Client-IP',"$hostIP")
        $headers.Add('Forwarded',"for=$hostIP")
        #$headers.Add('X-Forwarded-Port','443')
        #$headers.Add('X-Forwarded-Ssl','on')
        #$headers.Add('X-Url-Scheme','https')
        #$headers.Add('X-SSL-ENABLE','1')
        #$headers.Add('X-Forwarded-Proto','https')
    }
    Write-Host "Headers:"
    $headers.GetEnumerator() | % { Write-Host "$($_.key) : $($_.value)" }
    Write-Host ""
    return $headers
}

#
# Main 
#
Set-SSL

#
# Build the CMD
#
$cmd = "Invoke-WebRequest -Uri $uri -Method GET -TimeoutSec 20 "

#
# Add Proxy
#
if ($proxy) {
    $cmd = $cmd + "-Proxy $proxy "
}

#
# Add Headers
#

if (($masqueradeHost) -or ($hostHeader)){
    Get-Headers($masqueradeHost)
    $cmd = $cmd + '-Headers $h'
}

$result = "NO DATA"
write-host "Trying Web Request:"
write-host "$cmd"

#
# Try the web request
#
try   { 
    $result = Invoke-Expression $cmd 
    Write-Host -Foreground Green -Background Black $result
}

#
# Catch Exceptions
#
Catch {
    $fields = 
            $_.ErrorDetails.Message,
            $_.CategoryInfo.ToString(),
            $_.FullyQualifiedErrorId
    Write-Host $result.headers
    Write-Host -Foreground Red -Background Black "$fields" 
}

