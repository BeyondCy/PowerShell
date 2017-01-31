Function Invoke-WmiExecute {
    <#
    .SYNOPSIS
    Leverages WMI to execute remote commands and retrieve their output in a manner compatible with Windows PowerShell 2.0 and newer.

    .DESCRIPTION
    WMI can give an alternative means of remotely executing code when WinRM/PSRemoting is not available.

    After remotely creating a custom WMI Class, we convert a string or file to a byte array and convert it to a Base64 encoded string.  We can then push the command to a remote machine by writing the string to a property of our custom WMI Class.

    Using the Create method of the Win32_Process WMI Class we can then use PowerShell on the remote machine to execute the command we stored in our custom property.
         
    If so desired, we can capture any string returned by our command within another property of our custom WMI class.  We can then use WMI to pull this data from the remote machine without establishing any network shares.

    This script was possible thanks to the prior work of some smart folks like Matt Graeber, Christopher Glyer, and Devon Kerr (to name just a few).
         
    .PARAMETER ComputerName
    Specifies the target computer for remote code execution.  Enter a fully qualified domain name, a NetBIOS name, or an IP address.  When the remote computer is in a different domain than the local computer, the fully qualified domain name is required.

    .PARAMETER Credential
    Specifies a user account that has permission to perform this action.  The default is the current user.  Type a user name, such as "User01", "Domain01\User01", or User@Contoso.com.  Or, enter a PSCredential object, such as an object that is returned by the Get-Credential cmdlet.  When you type a user name, you are prompted for a password.

    .PARAMETER ScriptBlock
    Specifies the commands to run.  Enclose the commands in braces ( { } ) to create a script block.

    By default, any variables in the command are evaluated on the remote computer.

    .PARAMETER ScriptFile
    Runs the specified local script on the target remote computer.  Enter the path and file name of the script, or pipe a script path to Invoke-WmiExecute.  The script will be transfered via WMI for remote execution.

    .INPUTS
    System.String
    System.Management.Automation.PSCredential
    System.Management.Automation.ScriptBlock

    .OUTPUTS
    PSObject
    
    .NOTES
    Name: Invoke-WmiExecute
    Author: Peter Hewson
    Last Edit: January 30, 2017

    .EXAMPLE
    Invoke-WmiExecute -ComputerName "192.168.1.2" -ScriptBlock { Get-Process }

    This command will run Get-Process on remote computer with IP Address '192.168.1.2' using the local credentials

    .EXAMPLE
    $Credential = $Get-Credential
    Invoke-WmiExecute -ComputerName "Computer01" -Credential $Credential -ScriptFile "C:\Users\User01\Desktop\Script.ps1"

    This command will use the provided user credentials to run the contents of Script.ps1 on remote computer 'Computer01'

    .EXAMPLE
    Invoke-WmiExecute -ComputerName "Computer01.Domain01" -ScriptBlock { Get-Process } | Export-Csv -Path C:\Users\User01\Desktop\Processes.csv -NoTypeInformation

    This command will get the list of processes on remote computer 'Computer01.Domain01' and save them to a CSV file on the local machine
    
    .EXAMPLE
    $Computers = Computer01, Computer02 
    $Computers | Invoke-WmiExecute -ScriptBlock { Get-Process }
    
    This command will get the list of processes for remote computers 'Computer01' and 'Computer02'
    
    .LINK
    Export-Clixml
    Get-WmiObject
    Import-Clixml
    Invoke-WmiMethod
    Remove-WmiObject
    Set-WmiInstance
    Setting up a Remote WMI Connection: https://msdn.microsoft.com/en-us/library/aa822854.aspx
    Securing a Remote WMI Connection: https://msdn.microsoft.com/en-us/library/aa393266.aspx
    Connecting to WMI Remotely with PowerShell: https://msdn.microsoft.com/en-us/library/ee309377.aspx
    WINMGMT Service: https://msdn.microsoft.com/en-us/library/aa394525.aspx
    https://www.blackhat.com/docs/us-15/materials/us-15-Graeber-Abusing-Windows-Management-Instrumentation-WMI-To-Build-A-Persistent%20Asynchronous-And-Fileless-Backdoor-wp.pdf
    http://files.sans.org/summit/dfir-prague-summit-2015/PDFs/Theres-Something-about-WMI-Christopher-Glyer-and-Devon-Kerr.pdf
    #>
    [CmdletBinding(HelpURI='https://github.com/Cowmonaut/Invoke-WmiExecute', PositionalBinding=1)]
    [OutputType([PSObject], ParameterSetName="ScriptBlock")]
    [OutputType([PSObject], ParameterSetName="ScriptFile")]
    Param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=0, ParameterSetName='ScriptBlock')]
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=0, ParameterSetName='ScriptFile')]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            If (-not($_ -eq $env:COMPUTERNAME)) {
                $true
            }
            Else {
                Throw "The command can only be run against remote computers."
            }
        })]
        [Alias("CN","ServerName","IPAddress")]
        [String[]]
        $ComputerName,
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true, Position=1, ParameterSetName='ScriptBlock')]
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true, Position=1, ParameterSetName='ScriptFile')]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty,
        [Parameter(Mandatory=$true, ValueFromPipeline=$false, Position=2, ParameterSetName='ScriptBlock')]
        [ValidateNotNullOrEmpty()]
        [ScriptBlock]
        $ScriptBlock,
        [Parameter(Mandatory=$true, ValueFromPipeline=$false, Position=2, ParameterSetName='ScriptFile')]
        [ValidateScript({ 
            If (Test-Path -LiteralPath $_ -PathType Leaf -IsValid) {
                $true
            }
            Else {
                Throw "'$_' is not a valid file path."
            }
        })]
        [Alias("Path")]
        [String]
        $ScriptFile
    )
    Begin {
        Write-Verbose -Message "Preparing user-provided script for transfer"
        If ($ScriptBlock) { 
            Write-Debug "`$ScriptBlock == $ScriptBlock"
            $EncodedScript = [System.Convert]::ToBase64String([System.Text.Encoding]::Ascii.GetBytes($ScriptBlock))
        }
        If ($ScriptFile) {
            Write-Debug "`$ScriptFile == $ScriptFile"
            $EncodedScript = [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes($ScriptFile))
        }
        # On the remote machine we need to:
        #   1. Pull the user-provided script out of WMI and into a temporary file
        #   2. Execute the temporary file
        #   3. Encode the resulting output and save it in WMI
        #   4. Cleanup any artifacts left behind
        $WmiExecProcess = @'
$WmiExec = Get-WmiObject -Namespace root\default -Class WmiExec | Where-Object { $_.InvocationID -eq $InvocationID }
$Command = $WmiExec | Select-Object -ExpandProperty Command
$TempScript = [System.IO.Path]::GetTempFileName()
$TempXml = [System.IO.Path]::GetTempFileName()
[System.IO.File]::WriteAllBytes($TempScript,[System.Convert]::FromBase64String($Command))
Invoke-Expression -Command $([System.IO.File]::ReadAllText($TempScript)) | Export-Clixml -Path $TempXml
$EncodedOutput = [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes($TempXml))
$WmiExec | Set-WmiInstance -Arguments @{Output = $EncodedOutput}
Remove-Item $TempScript -Force
Remove-Item $TempXml -Force
'@
    }
    Process {
        # Splatting common arguments for use across multiple cmdlets
        $Common = @{
            ComputerName = $ComputerName
            Credential = $Credential
        }
        # Generate random ID incase multiple invocations are happening in parallel
        $InvocationID = Get-Random -Maximum 9999
        Write-Verbose -Message "[$ComputerName] Invocation ID for this execution is $InvocationID"
        # Creating string containing the variables we need to pass
        $WmiExecVars = "`$InvocationID = $InvocationID `n"
        # Creating final command string
        $CommandString = $WmiExecVars + $WmiExecProcess
        # Encoding command so we don't lose characters in the transfer
        $EncodedCommand = [System.Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($CommandString))
        # PowerShell command we'll be executing
        $PowerShell = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Unrestricted -EncodedCommand $EncodedCommand"
        Write-Verbose -Message "[$ComputerName] Establishing WMI connection"
        $ConnectionOptions = New-Object System.Management.ConnectionOptions
        Try {
            $ConnectionOptions.UserName = $Credential.GetNetworkCredential().UserName
            $ConnectionOptions.Password = $Credential.GetNetworkCredential().Password
            Write-Verbose -Message "[$ComputerName] Using provided user credentials to establish WMI connection"
        }
        Catch{
            Write-Verbose -Message "[$ComputerName] Using local user credentials to establish WMI connection"
        }
        $ConnectionOptions.EnablePrivileges = $true
        $ManagementScope = New-Object System.Management.ManagementScope
        $ManagementScope.Path = "\\$ComputerName\root\default"
        $ManagementScope.Options = $ConnectionOptions
        Try {
            $ManagementScope.Connect()
        }
        Catch {
            Throw $Error[0].Exception
        }
        # Create the WmiExec Class on the remote machine if it does not already exist
        If(-not(Get-WmiObject -Namespace root\default -Class WmiExec @Common -ErrorAction SilentlyContinue)) {
            Write-Verbose -Message "[$ComputerName] Creating WmiExec Class for command and output storage"
            $ManagementClass = New-Object System.Management.ManagementClass($ManagementScope, [String]::Empty, $null)
            $ManagementClass['__CLASS'] = 'WmiExec'
            #$ManagementClass.Qualifiers.Add('Static', $true) #Class instances will be stored in the WMI repository rather that provided dynamically by a WMI provider
            $ManagementClass.Properties.Add('InvocationID', [System.Management.CimType]::String, $false)
            $ManagementClass.Properties['InvocationID'].Qualifiers.Add('Key', $true)
            $ManagementClass.Properties['InvocationID'].Qualifiers.Add('Read', $true)
            $ManagementClass.Properties.Add('Command', [System.Management.CimType]::String, $false)
            $ManagementClass.Properties['Command'].Qualifiers.Add("Read", $true)
            $ManagementClass.Properties.Add('Output', [System.Management.CimType]::String, $false)
            $ManagementClass.Properties['Output'].Qualifiers.Add("Write", $true)
            $ManagementClass.Put() | Out-Null
        }
        Write-Verbose -Message "[$ComputerName] Creating WmiExec instance and delivering command"
        $WmiExecClass = New-Object System.Management.ManagementClass($ManagementScope, 'WmiExec', $null)
        $WmiExecInstance = $WmiExecClass.CreateInstance()
        $WmiExecInstance.InvocationID = $InvocationID
        $WmiExecInstance.Command = $EncodedScript
        $WmiExecInstance.Put() | Out-Null
        Write-Verbose -Message "[$ComputerName] Executing command"
        Invoke-WmiMethod -Path Win32_Process -Name Create -ArgumentList $PowerShell @Common | Out-Null
        Write-Verbose -Message "[$ComputerName] Retrieving encoded output"
        # We need to wait until the remote command is finished processing
        Function Worker-GetOutput {
            $RemoteOutput = Get-WmiObject -Namespace root\default -Class WmiExec @Common | Where-Object { $_.InvocationID -eq $InvocationID } | ForEach-Object { $_.Output } # Workaround for a bug in PowerShell 2.0 when using Select-Object to expand a property with a value of $null
            If (-not($RemoteOutput)) {
                Start-Sleep -Seconds 3
                Worker-GetOutput
            }
            Else {
                return $RemoteOutput
            }
        }
        $EncodedXml = Worker-GetOutput
        Write-Verbose -Message "[$ComputerName] Decoding results and importing object"
        $DecodedXml = [System.IO.Path]::GetTempFileName()
        [System.IO.File]::WriteAllBytes($DecodedXml,[System.Convert]::FromBase64String($EncodedXml))
        $Output = Import-Clixml -Path $DecodedXml
        Write-Verbose -Message "[$ComputerName] Performing cleanup of artifacts from the remote command invocation"
        Remove-Item -Path $DecodedXml -Force
        Remove-WmiObject -Namespace root\default -Class WmiExec @Common | Where-Object { $_.InvocationID -eq $InvocationID } | Out-Null
        $Output
    }
    End {
    }
}
