<#
.Synopsis
   Start or Stop VM
.DESCRIPTION
   This script starts or stops the VM depending on the state and parameters
.EXAMPLE
   StartStop-AzureVM -vmname 'vmname' -resourceGroupName 'vm resourcegroupname' -startVM:$true
.EXAMPLE
   StartStop-AzureVM -vmname 'vmname' -resourceGroupName 'vm resourcegroupname' -stopVM:$true
   GitHub test update
#>

param(
    [Parameter(Mandatory=$true)]
    [string]
    $vmname,

    [Parameter(Mandatory=$true)]
    [string]
    $resourceGroupName,
	
	[Parameter(Mandatory=$false)]
	[bool]
	$startVM,
	
	[Parameter(Mandatory=$false)]
	[bool]
	$stopVM
)
# Connect to Azure RM
$connectionName = "AzureRunAsConnection"
try
{
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         

    Write-Output "Logging in to Azure..."
    Add-AzureRmAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
}
catch {
    if (!$servicePrincipalConnection)
    {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}
Write-Output "Logged in to Azure"

#Get vm power status
$vmstatus = (Get-AzureRmVM -Name $vmname -ResourceGroupName $resourceGroupName -Status).Statuses | Where-Object {$_.Code -like "PowerState/*"}
Write-Output "VM Status $($vmstatus.DisplayStatus)"
if($vmstatus.DisplayStatus -eq "VM Deallocated" -and $startVM -eq $true)
{
    # VM is turned off
    Write-Output "starting vm $vmname"
	Start-AzureRmVM -Name $vmname -ResourceGroupName $resourceGroupName
    Write-Output "started vm $vmname"
}

if($vmstatus.DisplayStatus -eq "VM running" -and $stopVM -eq $true)
{
    # VM is turned on
	Write-Output "stopping vm $vmname"
    Stop-AzureRmVM -Name $vmname -ResourceGroupName $resourceGroupName -Force
    Write-Output "stopped vm $vmname"
}