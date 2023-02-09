Using module './classes/AstNodeType.psm1'
Using module "./classes/Parser.psm1"


# Not finishied. Attempt at custom parser. 
function Start-TFVarsParser {
    param (
       [System.String]
        $test = @'
/// sdsdcs Comment
/****
 * 
 * Multiline Comment
 * 
 * */

 "hello";
 // Comment
 1234;
 
 {  }

 {
    'Nested Block Follows';
    {
    2443222;
    'test test test';
    } 
  }
'@
    )
    
    $Configuration = @(
        [AstNodeType]::new('WHITESPACE', '^\s+', $true),

        [AstNodeType]::new('COMMENT', @('^\/\/[^\n]+', '^\/\*[\s\S]*?\*\/'), $true),

        [AstNodeType]::new('StatementSeperator', '^\n|^;+'),

        [AstNodeType]::new('STRING', "^`"[^`"]*`"|^'[^']*'"),
        [AstNodeType]::new('NUMBER', '^\d+')


        [AstNodeType]::new('{'),
        [AstNodeType]::new('}')
    )

    return [Parser]::new($Configuration).parse($test) | ConvertTo-Json -Depth 16
}
