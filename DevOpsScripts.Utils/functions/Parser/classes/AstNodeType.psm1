class AstNodeType {

    [System.String] $Type
    [System.String] $Regex
    [System.Boolean] $Skip

    # No Constructor Chaining in Powershell
    AstNodeType($Type, $Regex) {
        $this.Type = $Type
        $this.Regex = $Regex
        $this.Skip = $false
    }

    AstNodeType($Type, $Regex, $Skip) {
        $this.Type = $Type
        $this.Regex = $Regex
        $this.Skip = $Skip
    }

}
