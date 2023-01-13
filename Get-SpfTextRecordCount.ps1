function Get-SPFTxtRecordCount {
    param (
        [string] $DomainName,
		[bool] $Loud = $false
    )

	if($Loud) {Write-Host "Finding record count for domain $DomainName"}

	$count = 0;

	$txtRecords = Resolve-DnsName -Type TXT -Name $DomainName -Server "8.8.8.8"
	foreach($txt in $txtRecords) {
		if($($txt.Strings) -like "v=spf1*") {
			foreach ($SpfEntry in $($txt.Strings.Split(" ").Trim())) {
				if($SpfEntry -like "ip4:*") {
					if($Loud) {Write-Host "Finding record count for subnet $SpfEntry for $DomainName"}

					if($SpfEntry -like "*/*") {
						$EntryCount = [Math]::Pow(2, 32 - ($SpfEntry.Substring(([int] $SpfEntry.IndexOf("/")) + 1).Trim()))

						if($Loud) {Write-Host "Found $EntryCount records for subnet $SpfEntry for $DomainName"}
						$count += $EntryCount
					}
					else {
						if($Loud) {Write-Host "Found 1 record for subnet $SpfEntry for $DomainName"}
						$count += 1
					}
				}
				if($SpfEntry -like "include:*") {
					$domain = $SpfEntry.Substring(([int] $SpfEntry.IndexOf(":")) + 1).Trim()
					$count += Get-SPFTxtRecordCount $domain
				}
			}
		}
	}

	if($Loud) {Write-Host "Found $count records for domain $DomainName"}

	return $count
}
