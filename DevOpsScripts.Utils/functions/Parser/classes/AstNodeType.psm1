class AstNodeType {

    static [System.Collections.Hashtable] $ALL = @{}

    [System.String] $Type
    [System.String[]] $Regex
    [System.Boolean] $Skip

    # No Constructor Chaining in Powershell
    AstNodeType($Type) {
        $this.Type = $Type
        $this.Regex = "^$Type"
        $this.Skip = $false

        [AstNodeType]::ALL.add($Type, $this)
    }

    AstNodeType($Type, $Regex) {
        $this.Type = $Type
        $this.Regex = $Regex
        $this.Skip = $false

        [AstNodeType]::ALL.add($Type, $this)
    }

    AstNodeType($Type, $Regex, $Skip) {
        $this.Type = $Type
        $this.Regex = $Regex
        $this.Skip = $Skip

        [AstNodeType]::ALL.add($Type, $this)
    }

}
