Using module './classes/AstNodeType.psm1'
Using module './classes/Parser.psm1'


# Not finishied. Very Very basic attempt at a parser.
function Start-TFVarsParser {
    param (
        [Parameter(Mandatory = $false)]
        [System.String]
        $test = @'
## sdsdcs Comment
/****
 * 
 * Multiline Comment
 * 
 * */
 ## Comment gets ignored

abc = 2

abc = {
    property1 = 123
    # property2 = 123
    property3 = {
        property1 = 123
        # property2 = 123
    }
}
'@
    )
    
    $Configuration = @(

        [AstNodeType]::new('WHITESPACE', '^\s+', $true),
        [AstNodeType]::new('COMMENT', @('^#[^\n]+', '^\/\*[\s\S]*?\*\/'), $true),
        [AstNodeType]::new('IGNORE', @('^;'), $true),

        [AstNodeType]::new('SEPERATOR', '^\n+')

        [AstNodeType]::new('BLOCK_END', '^}'),
        [AstNodeType]::new('BLOCK_START', '^{'),


        [AstNodeType]::new('STRING', "^`"[^`"]*`"|^'[^']*'"),
        [AstNodeType]::new('NUMBER', '^\d+')

        [AstNodeType]::new('VARIABLE', '^[A-Za-z_0-9]{1}[A-Za-z_0-9]*')

        [AstNodeType]::new('ASSIGNMENT', '^=')
    )

    return [Parser]::new($Configuration).parse($test) | ConvertTo-Json -Depth 99
}

Start-TFVarsParser