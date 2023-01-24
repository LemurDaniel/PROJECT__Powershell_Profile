function prompt {

    if ( (Get-Location | Split-Path -NoQualifier).Equals('\') ) { return $loc } # Edgecase if current folder is a drive

    $Leaf = Get-ShortPath -InputString (Get-Location | Split-Path -Leaf) -SplitChar '' -maxlength 25
    $Parent = Get-ShortPath -InputString (Get-Location | Split-Path -Parent) -SplitChar '\' -maxlength 35
  
    $Edition = $PSVersionTable.PSEdition
    $PSVersion = $PSVersionTable.PSVersion.Major

    #return "PS $Edition $PSVersion || $Parent\$Leaf> "
    return "$Parent\$Leaf> "
}

function Get-ShortPath {
    param (
        [Parameter()]
        [System.String]
        $InputString,

        [Parameter()]
        [System.String]
        $SplitChar,

        [Parameter()]
        [System.int32]
        $MaxLength
    )

    if ($InputString.length + 1 -lt $MaxLength) { 
        return $InputString 
    }
	
    $WordArray = $InputString -split ($SplitChar -eq '\' ? '\\' : $SplitChar) |`
        Where-Object { $MaxLength -= $_.Length; $MaxLength -ge 0; }

    return @(($WordArray -join $SplitChar), '...') -join $SplitChar
}