# Define the IP address or hostname of the ESXi host
$esxiHost = "10.0.1.10"

# Prompt for user credentials
$cred = Get-Credential

# Import the CSV file which contains details for Port Groups
$csv = Import-Csv -Path "pg_input.csv"

# Connect to the ESXi host using the credentials
try {
    Connect-VIServer -Server $esxiHost -Credential $cred -Force | Out-Null
    Write-Host "Connected to ESXi host:" $esxiHost -ForegroundColor Green

    # Check if the vSwitch exists before processing Port Groups
    foreach ($config in $csv) {
        $vSwitchName = $config.vSwitchName
        $checkSwitch = Get-VMHost -Name $esxiHost | Get-VirtualSwitch -Name $vSwitchName

        if (!$checkSwitch) {
            Write-Host "vSwitch" $vSwitchName "not found on host" $esxiHost -ForegroundColor Red
            continue
        }

        # Process each Port Group from the CSV
        $portGroupName = $config.PortGroupName
        $vlanID = [int]$config.VLANID

        # Check if the Port Group exists
        $checkPortGroup = Get-VMHost -Name $esxiHost | Get-VirtualSwitch -Name $vSwitchName | Get-VirtualPortGroup | Where-Object { $_.Name -eq $portGroupName }

        if (!$checkPortGroup) {
            # If the port groups doesn't exist - create it
            try {
                Get-VMHost -Name $esxiHost | Get-VirtualSwitch -Name $vSwitchName | New-VirtualPortGroup -Name $portGroupName -VLanId $vlanID | Out-Null
                Write-Host "Creating Port Group" $portGroupName "with VLAN ID" $vlanID "on vSwitch" $vSwitchName -ForegroundColor Green
                Write-Host "Port Group" $portGroupName "created successfully." -ForegroundColor Green
            } catch {
                Write-Host "Error creating Port Group" $portGroupName "on vSwitch" $vSwitchName "Error Message: $_" -ForegroundColor Red
            }
        } else {
            Write-Host "Port Group" $portGroupName "already exists on vSwitch" $vSwitchName "of host" $esxiHost -ForegroundColor Cyan
        }
    }

} catch {
    Write-Host "Failed to connect or process ESXi host:" $esxiHost -ForegroundColor Red
} finally {
    # Disconnect from the ESXi host
    Disconnect-VIServer -Server $esxiHost -Confirm:$false | Out-Null
    Write-Host "Disconnected from ESXi host:" $esxiHost -ForegroundColor Yellow
}

Write-Host "Script execution completed." -ForegroundColor Green
