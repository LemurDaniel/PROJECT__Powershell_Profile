class AstNode {

    [System.String] $Type
    [System.Object] $Value

    AstNode($Type, $Value) {
        $this.Type = $Type
        $this.Value = $Value
    }

}
