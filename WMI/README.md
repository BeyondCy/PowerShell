# WMI PowerShell Module
Windows PowerShell 5.0 still has limited options for interacting with WMI.  Several folks have tried to shore up these deficiencies with various scripts and script modules, but there are drawbacks to most solutions I've come across.  This project's goal is to create an all-encompassing PowerShell module with Cmdlets to cover all possible WMI interactions.

## Cmdlets

### Invoke-WmiExecute

#### Synopsis
Leverages WMI to execute remote commands and retrieve their output in a manner compatible with Windows PowerShell 2.0 and newer.

#### TODO
- Convert from Advanced Function to Cmdlet
- Add support for confirmation requests
- Add support for force parameter 

## Resource Links
### Windows Management Interface
- [Setting up a Remote WMI Connection](https://msdn.microsoft.com/en-us/library/aa822854.aspx)
- [Securing a Remote WMI Connection](https://msdn.microsoft.com/en-us/library/aa393266.aspx)
- [Connecting to WMI Remotely with PowerShell](https://msdn.microsoft.com/en-us/library/ee309377.aspx)
- [WINMGMT Service](https://msdn.microsoft.com/en-us/library/aa394525.aspx)
- [WMI Providers](https://msdn.microsoft.com/en-us/library/aa394570.aspx)
- [Managed Reference for WMI Windows PowerShell Command Classes](https://msdn.microsoft.com/en-us/library/ee309379.aspx)

### PowerShell Development Guidelines
- [Required Development Guidelines](https://msdn.microsoft.com/en-us/library/dd878270.aspx)
- [Strongly Encouraged Development Guidelines](https://msdn.microsoft.com/en-us/library/dd878270.aspx)
- [Advisory Development Guidelines](https://msdn.microsoft.com/en-us/library/dd878291.aspx)

### Cmdlets
- [Writing a Windows PowerShell Cmdlet](https://msdn.microsoft.com/en-us/library/dd878294.aspx)

### Modules
- [Understanding a Windows PowerShell Module](https://msdn.microsoft.com/en-us/library/dd878324.aspx)
- [How to Write a PowerShell Script Module](https://msdn.microsoft.com/en-us/library/dd878340.aspx)
- [How to Write a PowerShell Binary Module](https://msdn.microsoft.com/en-us/library/dd878342.aspx)
- [How to Write a PowerShell Module Manifest](https://msdn.microsoft.com/en-us/library/dd878337.aspx)
- [Writing Help for Windows PowerShell Modules](https://msdn.microsoft.com/en-us/library/dd878343.aspx)
