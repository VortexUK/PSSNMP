<#
	.SYNOPSIS
		Invokes a single Get command over SNMP to return a single item
	
	.DESCRIPTION
		Uses SNMP to retrieve data from a device. Currently the only functionality that has been implemented is SNMPv2 Walk. Library contains methods for SNMP3 gets, sets and all sorts however.
	
	.PARAMETER IP
		IP of the device
	
	.PARAMETER OID
		The 'Identity' string the function uses to find the data requested
	
	.PARAMETER CommunityString
		A description of the CommunityString parameter.
	
	.PARAMETER UDPport
		If using a non standard UDP port, specify here
	
	.PARAMETER TimeOut
		A description of the TimeOut parameter. TimeOut is in msec, 0 or -1 for infinite
	
	.PARAMETER HexOutput
		By default, the 'Sharp' library will interpret Hex data as a n ASCII string. If you are actually supposed to get Hex back, use this option to force it.
	
	.PARAMETER Version
		Version of SNMP to use. Default is V2
	
	.PARAMETER Walk
		Determines whether it will walk the subtree or not. Currently the default functionality is not implmented so the function will error if you try to set this to false
	
	.EXAMPLE

		C:\> Get-SNMPData -IP '172.19.32.6' -OID '1.3.6.1.2.1.2.2.1.2' -CommunityString 'dpfmro' -Walk $false -ErrorAction SilentlyContinue

	.NOTES
		Additional information about the function.
#>
function Get-SNMPData
{
	[CmdletBinding(PositionalBinding = $true,
				   SupportsPaging = $true,
				   SupportsShouldProcess = $true)]
	[OutputType([SNMPObject])]
	PARAM
	(
		[Parameter(Mandatory = $true,
				   Position = 0)]
		[System.Net.IPAddress]$IP,
		[Parameter(Mandatory = $true,
				   Position = 1)]
		[System.String]$OID,
		[Parameter(Position = 2)]
		[System.String]$CommunityString = "public",
		[Parameter(Position = 3)]
		[System.Int16]$UDPport = 161,
		[Parameter(Position = 4)]
		[System.Int32]$TimeOut = 90000,
		[Parameter(Position = 5)]
		[System.Management.Automation.SwitchParameter]$HexOutput,
		[Parameter(Position = 6)]
		[Lextm.SharpSnmpLib.VersionCode]$Version = [Lextm.SharpSnmpLib.VersionCode]::V2,
		[Parameter(DontShow = $true,
				   Position = 7)]
		[System.Boolean]$Walk = $true
	)
	BEGIN
	{
		# Use SNMP v2 and walk mode WithinSubTree (as opposed to Default)
		[System.Boolean]$WalkModeOK = $true
		if ($Walk -eq $true)
		{
			$walkMode = [Lextm.SharpSnmpLib.Messaging.WalkMode]::WithinSubtree
		}
		else
		{
			$walkMode = [Lextm.SharpSnmpLib.Messaging.WalkMode]::Default
			# At the moment of writing, there is no support for SNMPv2 for a non-walk based query :( so error and exit
			Write-Error -Message "Walk parameter set to false, unfortunately this is not allowed as the library does not support it"
			$WalkModeOK = $false
		}
		[Lextm.SharpSnmpLib.Security.DefaultPrivacyProvider]$Privacy = [Lextm.SharpSnmpLib.Security.DefaultPrivacyProvider]::DefaultPair
		[Lextm.SharpSnmpLib.Messaging.Discovery]$Discovery = [Lextm.SharpSnmpLib.Messaging.Messenger]::GetNextDiscovery([Lextm.SharpSnmpLib.SnmpType]::GetRequestPdu)
		[System.Int32]$MaxRepetitions = 10
	}
	PROCESS
	{
		if ($WalkModeOK -eq $true)
		{
			# Set up the variables:
			[System.Net.IpEndPoint]$Endpoint = New-Object -TypeName System.Net.IpEndPoint($IP, $UDPPort)
			[Lextm.SharpSnmpLib.ObjectIdentifier]$OIDObject = [Lextm.SharpSnmpLib.ObjectIdentifier]::new($OID)
			[Lextm.SharpSnmpLib.OctetString]$CommunityStringOctet = [Lextm.SharpSnmpLib.OctetString]::new($CommunityString)
			# Test response of endpoint and collect the data
			try
			{
				if ($PSCmdlet.ShouldProcess($IP, "SNMPWalk"))
				{
					$SNMPResult = New-Object -TypeName 'System.Collections.Generic.List[Lextm.SharpSnmpLib.Variable]'
					[Lextm.SharpSnmpLib.Messaging.ReportMessage]$Report = $Discovery.GetResponse($timeout, $Endpoint)
					$null = [Lextm.SharpSnmpLib.Messaging.Messenger]::BulkWalk($Version, $EndPoint, $CommunityStringOctet, $OIDObject, $SNMPResult, $timeout, $MaxRepetitions, $walkMode, $Privacy, $Report)
				}
			}
			catch
			{
				Write-Error -Message $_.Exception.Message
				return $null
			}
			$DataScriptBlock = { $_.Data.ToString() }
			# Ever got data back from SNMP that looks like a bunch of weird characters? That's because your SNMP interpreter is seeing hex and assuming it needs to convert it. You have to manually force it to return hex
			if ($HexOutput -eq $true)
			{
				$DataScriptBlock = { $_.Data.ToHexString() }
			}
			[SNMPObject[]]($SNMPResult | Select-Object -Property @{ Label = 'OID'; Expression = { $_.ID } }, @{ Label = 'Data'; Expression = $DataScriptBlock }) | Write-Output
		}
		else
		{
			return $null
		}
	}
	END { }
}
