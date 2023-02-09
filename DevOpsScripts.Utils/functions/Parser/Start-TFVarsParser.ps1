Using module './classes/AstNodeType.psm1'
Using module './classes/Parser.psm1'


# Not finishied. Attempt at custom parser. 
function Start-TFVarsParser {
    param (
        [Parameter(Mandatory = $false)]
        [System.String]
        $test = @'
/// sdsdcs Comment
/****
 * 
 * Multiline Comment
 * 
 * */

 "hello";
 // Comment gets ignored
 1234;
 
 {  }

 {
    'Nested Block Follows'
    {
    2443222
    'test test test'
    } 
  }
'@
    )
    
    $Configuration = @(

        [AstNodeType]::new('COMMENT', @('^\/\/[^\n]+', '^\/\*[\s\S]*?\*\/'), $true),
        [AstNodeType]::new('IGNORE', @('^;'), $true),

        [AstNodeType]::new('Seperator', '^\n+')
    )

    return [Parser]::new($Configuration).parse($test) | ConvertTo-Json -Depth 16
}

#Start-TFVarsParser