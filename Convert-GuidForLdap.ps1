Function Convert-GuidForLdap {
   #Requires -Version 2.0
   <#
    .SYNOPSIS
        Converts a GUID to a usable string for LDAP queries.
        
    .DESCRIPTION
        A globally unique identifier (GUID) is a 128-bit integer (16 bytes) that can be used across all computers and networks wherever a unique identifier is required. Such an identifier has a very low probability of being duplicated.
        
        For LDAP queries, a GUID must be converted to a hexadecimal byte array.  The GUID {b95f3990-b59a-4a1b-9e96-86c66cb18d99} is equivalent to the hex representation "90395fb99ab51b4a9e9686c66cb18d99", where the first 8 bytes are reversed.  Each byte must be escaped for use in a query.

    .PARAMETER Guid
        Specifies the GUID or GUIDs to convert for use in an LDAP query.

    .INPUTS
        System.Guid

    .OUTPUTS
        System.String

    .NOTES
        Author: Peter Hewson

    .EXAMPLE
        Convert-GuidForLdap "b95f3990-b59a-4a1b-9e96-86c66cb18d99"

        \90\39\5f\b9\9a\b5\1b\4a\9e\96\86\c6\6c\b1\8d\99

    .EXAMPLE
        Convert-GuidForLdap -Guid "{b95f3990-b59a-4a1b-9e96-86c66cb18d99}"

        \90\39\5f\b9\9a\b5\1b\4a\9e\96\86\c6\6c\b1\8d\99

    .EXAMPLE
        "b95f3990-b59a-4a1b-9e96-86c66cb18d99" | Convert-GuidForLdap

        \90\39\5f\b9\9a\b5\1b\4a\9e\96\86\c6\6c\b1\8d\99

    .EXAMPLE
        Convert-GuidForLdap "b95f3990-b59a-4a1b-9e96-86c66cb18d99", "bc0ac240-79a9-11d0-9020-00c04fc2d4cf" -Verbose

        VERBOSE: Formatting GUID 'b95f3990-b59a-4a1b-9e96-86c66cb18d99' for use in LDAP query
        \90\39\5f\b9\9a\b5\1b\4a\9e\96\86\c6\6c\b1\8d\99
        VERBOSE: Formatting GUID 'bc0ac240-79a9-11d0-9020-00c04fc2d4cf' for use in LDAP query
        \40\c2\0a\bc\a9\79\d0\11\90\20\00\c0\4f\c2\d4\cf
   
    .LINK
        https://social.technet.microsoft.com/wiki/contents/articles/5392.active-directory-ldap-syntax-filters.aspx

    .LINK
        http://support.microsoft.com/kb/899663

    #>
    [CmdletBinding(
        HelpURI="https://github.com/Cowmonaut/PowerShell",
        PositionalBinding=$true
    )]
    Param (
        [Parameter(
            Mandatory=$true,
            ValueFromPipeline=$true,
            Position=0
        )]
        [ValidateNotNullOrEmpty()]
        [System.Guid[]]
        $Guid
    )
    Begin {
        Set-StrictMode -Version 2.0
    }
    Process {
        ForEach ($Guid in $Guid) {
            Write-Verbose -Message "Formatting GUID '$Guid' for use in LDAP query"
            $Output = [System.BitConverter]::ToString(($Guid.ToByteArray()).Clone()).Replace('-','\')
            $Output = "\" + $Output
            Write-Output $Output
        }
    }
}
