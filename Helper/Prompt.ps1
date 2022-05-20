

function prompt {

	if( (Get-Location | Split-Path -NoQualifier).Equals("\") ) { return $loc } # Edgecase if current folder is a drive
  
  $maxlenFolder = 25
  $maxlenParent = 40

  $loc = Get-Location
  $Drive = ($loc | Split-Path -Qualifier) 	# Like C: or F:
  $Parent = ($loc | Split-Path -Parent)		# Parent Path like C:/users/Daniel Notebool (includes drive!!!)
  $Leaf = ($loc | Split-Path -Leaf)			# Current Folder
  
  $Leaf = shorten_path -InputString $Leaf -SplitChar ' ' -maxlen $maxlenFolder -Cut_On_Letter_Level $true
  $Parent = shorten_path -InputString $Parent -SplitChar '\' -maxlen $maxlenParent -Cut_On_Letter_Level $false
  
  # debug return $Parent.substring(3, $Parent.length-3)
  
  # Assemble final Path
  $path = $Drive + "\" # Start with drive
  $path += $Parent.substring(3, $Parent.length-3) + "\"
  $path += $Leaf # append foldername
  
  return "$path> "
}

function shorten_path  {
	param (
        [string]$InputString,
		[char]$SplitChar,
		[int]$MaxLen,
		[bool]$Cut_On_Letter_Level
    )
	if ($InputString.length+1 -lt $MaxLen) { return $InputString }
	
	# Section 1 Code shortens the Current Foldername if too long 
	$WordArray = $InputString.split($SplitChar)  # Turn Foldername in Array of Words (if multiple Words in Name)
	$CutPath = ""	# New Current Foldername
  
	for($i = 0; $i -lt $WordArray.Length; $i++){
		if($maxlen - ($CutPath.Length + $WordArray[$i].Length) -gt 0) {	# if word fits in new name
			$CutPath += $WordArray[$i]+$SplitChar	# add it back to new name
		} elseif($Cut_On_Letter_Level) {
			if($CutPath.Length -eq 0) { $CutPath = $WordArray[0].substring(0, $maxlen-3)+"... " } # if foldername is one large word shorten it to maxlen and end it  with ... ( = foldernameblablablaba... )
			else { $CutPath += "... " } # if foldername consist of words and they exced maxlen, append ...
			break; # if maxlen reached then break loop
		} else {
			$CutPath += "..."
			break; # if maxlen reached then break loop
		}
	}
	
	return $CutPath
}