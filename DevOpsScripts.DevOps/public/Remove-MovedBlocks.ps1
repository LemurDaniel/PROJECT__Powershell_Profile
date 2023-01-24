function Remove-MovedBlocks {

  param ()

  # Remove Moved-Blocks from Terraform configuration.
  Edit-RegexOnFiles -regexQuery 'moved\s*{[a-zA-Z=_.\-\s]*}'
  
}