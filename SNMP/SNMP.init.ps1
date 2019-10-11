#######################################################################################################################
# File:             SNMP.psm1		      			                      		  	                                  #
# Author:           Ben McElroy                                                                                       #
# Publisher:        Gloucester Research Ltd                                                                           #
# Copyright:        © 2017 Gloucester Research Ltd. All rights reserved.                                              #
# Documentation:    Inbuilt																							  #
#######################################################################################################################
#region Environment setup
#[System.String]$DefaultNamingContext = Get-ADRootDSE | Select-Object -ExpandProperty defaultNamingContext
#[System.String]$DNSDomainName = (Get-ADObject -Identity $DefaultNamingContext -Properties canonicalName).canonicalName.TrimEnd('/')
#[System.String]$LocalSite = [System.DirectoryServices.ActiveDirectory.ActiveDirectorySite]::GetComputerSite().Name
#[System.String]$LocalDC = "dc.$LocalSite.sites.$DNSDomainName"
Import-Module -Name "$PSScriptRoot\Lib\SharpSnmpLib.Full.dll" -Force -Scope Global # Tried sticking this in the psd, no luck
#endregion
