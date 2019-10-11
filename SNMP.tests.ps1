$ModuleName = 'SNMP'
Import-Module -Name "$PSScriptRoot\$ModuleName\Lib\SharpSnmpLib.Full.dll" -Force -Scope Global
$null = Get-ChildItem -Path "$PSScriptRoot\$ModuleName" -Filter *.ps1 -recurse |
ForEach-Object -Process { . $_.FullName }
#region Unit Testing
Describe -Tags 'UNIT' -Name "Get-SNMPData Unit Tests" {
	Context -Name 'Call with valid IP' {
		$SNMPData = Get-SNMPData -IP '172.19.32.6' -OID '1.3.6.1.2.1.2.2.1.2' -CommunityString 'dpfmro'
		It 'should be of type SNMPObject' {
			$SNMPData[0].GetType().Name | Should Be 'SNMPObject'
		}
	}
	Context -Name 'Call with valid IP HexOutput' {
		$SNMPData = Get-SNMPData -IP '172.19.32.6' -OID '1.3.6.1.2.1.2.2.1.2' -CommunityString 'dpfmro' -HexOutput
		It 'should be of type SNMPObject' {
			$SNMPData[0].GetType().Name | Should Be 'SNMPObject'
		}
	}
	Context -Name 'Error getting data' {
		Mock -CommandName New-Object -MockWith {throw} -ParameterFilter {$TypeName -match "System.Collections.Generic.List"}
		$SNMPData = Get-SNMPData -IP '172.19.32.6' -OID '1.3.6.1.2.1.2.2.1.2' -CommunityString 'dpfmro' -ErrorAction SilentlyContinue
		It 'should return $null' {
			$SNMPData | Should Be $null
		}
		It 'should call New-Object 1 time' {
			Assert-MockCalled -CommandName New-Object -Times 1 -Exactly
		}
	}
	Context -Name 'Call with walk mode of default (not valid - returns null)' {
		$SNMPData = Get-SNMPData -IP '172.19.32.6' -OID '1.3.6.1.2.1.2.2.1.2' -CommunityString 'dpfmro' -Walk $false -ErrorAction SilentlyContinue
		It 'should return $null' {
			$SNMPData | Should Be $null
		}
	}
}
#endregion
#region Structural Tests
Describe -Tags 'STRUCT' -Name 'Structure Tests' {
	$FunctionFiles = "Private", "Public" | ForEach-Object -Process { if (Test-Path -Path "$PSScriptRoot\$ModuleName\$_\") { Get-ChildItem -Path "$PSScriptRoot\$ModuleName\$_\" -File } }
	[System.Collections.ArrayList]$Tests = Get-Content -Path "$PSScriptRoot\$ModuleName.tests.ps1"
	foreach ($Function in $FunctionFiles)
	{
		$FunctionName = $Function.Name -replace '\.ps1'
		$FunctionBody = Get-Content -Path $Function.FullName
		Context "$FunctionName Structure Tests"	{
			It 'Should have an associated Unit Test' {
				($Tests | Where-Object -FilterScript { $_ -match "Describe -Tags 'UNIT' -Name `"$FunctionName Unit Tests`" {" } | Measure-Object).Count | Should be 1
			}
			It 'Function Name should match file name' {
				($FunctionBody | Where-Object -FilterScript { $_ -match "function $FunctionName" } | Measure-Object).Count | Should be  1
			}
			It 'Should have a comment help block' {
				($FunctionBody | Where-Object -FilterScript { $_ -match "\.(SYNOPSIS|DESCRIPTION|EXAMPLE)" } | Measure-Object).Count | Should be  3
			}
			It 'Should have A CmdletBinding' {
				($FunctionBody | Where-Object -FilterScript { $_ -match "\[CmdletBinding\(.+" } | Measure-Object).Count | Should be  1
			}
			if ($Function.FullName -match '\\Public\\')
			{
				It 'Should have support for -whatif and -verbose' {
					($FunctionBody | Where-Object -FilterScript { $_ -match 'SupportsShouldProcess[^\r\n]+true' } | Measure-Object).Count | Should be  1
				}
			}
			foreach ($Block in '\tPARAM(?![eE])', '\tBEGIN', '\tPROCESS', '\tEND')
			{
				It "Should have  $Block block" {
					($FunctionBody | Where-Object -FilterScript { $_ -cmatch $Block } | Measure-Object).Count | Should be  1
				}
			}
		}
	}
}
#endregion

#region Integration Testing
Describe -Tags 'Integration' -Name 'Testing full module functions' {
	Context -Name 'Get Interfaces from Switch and return results' {
		$SNMPData = Get-SNMPData -IP '172.19.32.6' -OID '1.3.6.1.2.1.2.2.1.2' -CommunityString 'dpfmro'
		It "should return more than one result" {
			($SNMPData | Measure-Object).Count | Should BeGreaterThan 1
		}
	}
}
#endregion
