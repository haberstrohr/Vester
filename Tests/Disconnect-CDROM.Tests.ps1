#requires -Modules Pester
#requires -Modules VMware.VimAutomation.Core


[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true,Position = 0,HelpMessage = 'Remediation toggle')]
    [ValidateNotNullorEmpty()]
    [switch]$Remediate,
    [Parameter(Mandatory = $true,Position = 1,HelpMessage = 'Path to the configuration file')]
    [ValidateNotNullorEmpty()]
    [string]$Config
)

Process {
    # Variables
    Invoke-Expression -Command (Get-Item -Path $Config)
    [bool]$allowconnectedcdrom = $global:config.vm.allowconnectedcdrom

    # Tests
    If (-not $allowconnectedcdrom) {
        Describe -Name 'VM Configuration: CDROM connection state' -Fixture {
            foreach ($VM in (Get-VM -Name $global:config.scope.vm)) 
            {
                It -name "$($VM.name) has no CDROM connected" -test {
                    [array]$value = $VM | get-cddrive
                    try 
                    {
                        $value.ConnectionState.Connected  | Should Not Be $true
                    }
                    catch 
                    {
                        if ($Remediate) 
                        {
                            Write-Warning -Message $_
                            Write-Warning -Message "Remediating $VM"
                            $Value | Set-CDDrive -Connected $false -Confirm:$false
                        }
                        else 
                        {
                            throw $_
                        }
                    }
                }
            }
        }
    }
}