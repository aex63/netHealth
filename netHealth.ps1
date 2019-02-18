# Enterprise Network Health Check

$hostnameIn = Read-Host -Prompt "Which server do you want to check?"
$hostnameIP = Resolve-DnsName $hostnameIn -Type A -ErrorAction SilentlyContinue| Select -ExpandProperty IpAddress

# https://www.bgreco.net/powershell/format-color/
function Format-Color([hashtable] $Colors = @{}, [switch] $SimpleMatch) {
	$lines = ($input | Out-String) -replace "`r", "" -split "`n"
	foreach($line in $lines) {
		$color = ''
		foreach($pattern in $Colors.Keys){
			if(!$SimpleMatch -and $line -match $pattern) { $color = $Colors[$pattern] }
			elseif ($SimpleMatch -and $line -like $pattern) { $color = $Colors[$pattern] }
		}
		if($color) {
			Write-Host -ForegroundColor $color $line
		} else {
			Write-Host $line
		}
	}
}

# Network IP Config Examples. Change according to your own needs
if($hostnameIP -as [ipaddress])
{
    $a = $hostnameIn # Domain
    $b = $hostnameIP # Main Server
    $c = $hostnameIP -replace '\d{1,3}\.\d{1,3}$','8.7'   # Example server 1
    $d = $hostnameIP -replace '\d{1,3}\.\d{1,3}$','0.1'   # Example server 2
    $e = $hostnameIP -replace '\d{1,3}\.\d{1,3}$','68.25' # Example server 3
    
    # Example servers = Enterprise equipment. CPE, Switch, Printer, Firewall, RAC etc. Edit after your own needs.
    # TODO: Config file for this.

    $Network = @(
        @([pscustomobject]@{name=$a;type="Server";ip=$b}),
        @([pscustomobject]@{name=$a;type="Switch";ip=$c}),
        @([pscustomobject]@{name=$a;type="Firewall";ip=$d}),
        @([pscustomobject]@{name=$a;type="RAC";ip=$e})   
    )
    
    for ($i=0; $i -lt $Network.length; $i++) {
        $PingRequest = Test-Connection $Network[$i].ip -Count 1 -Quiet
        if ($PingRequest -eq $true)
        {
            $Network[$i] = $Network[$i] | add-member -passthru NoteProperty "status" "UP"
            Write-Host "[+] " $Network[$i].type " - Response: Yes" -ForegroundColor black -BackgroundColor green
        }
        else
        {
            $Network[$i] = $Network[$i] | add-member -passthru NoteProperty "status" "DOWN"
            Write-Host "[+] " $Network[$i].type " - Response: No" -ForegroundColor white -BackgroundColor red
        }
    }
    Start-Sleep -s 3
    [System.Console]::Clear();
    $(Get-Date -Format G)
    $Network[0..3] | Format-Color @{'DOWN' = 'Red'; 'UP' = 'Green'}
    
    # Print out HTML report
    $date = Get-Date -Format "dd.MM.yyyy, HH:mm"
    $dateSimple = Get-Date -Format "dd.MM.yyyy_HH.mm"
    $Network[0..3] | ConvertTo-Html -Title "Network Health" -PreContent "<h1>NetReport by $env:USERNAME on $date</h1>" -CSSUri "HtmlReport.css" | Set-Content "NetHealth$dateSimple.html"
	Start-Sleep -s 2
    Write-Host "HTML Report [+] 100% Done"
    Read-Host -Prompt "Press any key to exit"
}
else
{
    Write-Host "Error: Invalid IP"
}
