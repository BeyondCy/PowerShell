Invoke-WmiExecute
====================

Synopsis
-------------------
Leverages WMI to execute remote commands and retrieve their output in a manner compatible with Windows PowerShell 2.0 and newer.

Description
-------------------
WMI can give an alternative means of remotely executing code when WinRM/PSRemoting is not available.

After remotely creating a custom WMI Class, we convert a string or file to a byte array and convert it to a Base64 encoded string.  We can then push the command to a remote machine by writing the string to a property of our custom WMI Class.

Using the Create method of the Win32_Process WMI Class we can then use PowerShell on the remote machine to execute the command we stored in our custom property.

If so desired, we can capture any string returned by our command within another property of our custom WMI class.  We can then use WMI to pull this data from the remote machine without establishing any network shares.

This script was possible thanks to the prior work of some smart folks like Matt Graeber, Christopher Glyer, and Devon Kerr (to name just a few).

Links
-------------------
- [Setting up a Remote WMI Connection][] 
- [Securing a Remote WMI Connection][] 
- [Connecting to WMI Remotely with PowerShell][] 
- [WINMGMT Service][] 
- [Abusing Windows Management Instrumentation WMI To Build A Persistent Asynchronous And Fileless Backdoor][] by Matt Graeber
- [Theres Something about WMI][] by Christopher Glyer and Devon Kerr

[Setting up a Remote WMI Connection]: https://msdn.microsoft.com/en-us/library/aa822854.aspx
[Securing a Remote WMI Connection]: https://msdn.microsoft.com/en-us/library/aa393266.aspx
[Connecting to WMI Remotely with PowerShell]: https://msdn.microsoft.com/en-us/library/ee309377.aspx
[WINMGMT Service]: https://msdn.microsoft.com/en-us/library/aa394525.aspx
[Abusing Windows Management Instrumentation WMI To Build A Persistent Asynchronous And Fileless Backdoor]: https://www.blackhat.com/docs/us-15/materials/us-15-Graeber-Abusing-Windows-Management-Instrumentation-WMI-To-Build-A-Persistent%20Asynchronous-And-Fileless-Backdoor-wp.pdf
[Theres Something about WMI]: http://files.sans.org/summit/dfir-prague-summit-2015/PDFs/Theres-Something-about-WMI-Christopher-Glyer-and-Devon-Kerr.pdf

TODO
-------------------
- Convert from Advanced Function to Cmdlet
- Add support for confirmation requests
- Add support for force parameter 
