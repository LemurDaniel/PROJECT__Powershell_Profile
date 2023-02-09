Using module "./classes/Parser.psm1"


# Not finishied. Attempt at custom parser. 
function New-Parser {
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
    
    return [Parser]::new().parse($test) | ConvertTo-Json -Depth 16
}
