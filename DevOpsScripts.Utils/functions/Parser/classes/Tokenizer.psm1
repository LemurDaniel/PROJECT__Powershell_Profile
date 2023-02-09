Using module './AstNodeType.psm1'
Using module './AstNode.psm1'

class Tokenizer {

    static [AstNodeType[]] $CONFIGURATION = @(
        [AstNodeType]::new('WHITESPACE', '^\s+', $true),

        [AstNodeType]::new('COMMENT', @('^\/\/[^\n]+', '^\/\*[\s\S]*?\*\/'), $true),

        [AstNodeType]::new('StatementSeperator', '^\n|^;+'),

        [AstNodeType]::new('STRING', "^`"[^`"]*`"|^'[^']*'"),
        [AstNodeType]::new('NUMBER', '^\d+')


        [AstNodeType]::new('{'),
        [AstNodeType]::new('}')
    )



    [System.String] $content
    [System.int32] $pointer
    [AstNode] $current

    Tokenizer($content) {
        $this.content = $content
        $this.pointer = 0
    }

    [AstNode] advanceNextToken() {
        $this.current = $this._advance()
        return $this.current
    }

    [AstNode] _advance() {
        if ($this.pointer -ge $this.content.length) {
            return $null
        }
  
        $substring = $this.content.Substring($this.pointer)

        foreach ($config in [Tokenizer]::CONFIGURATION) {

            foreach ($regex in $config.Regex) {
      
                $match = [regex]::Match($substring, $regex)
                if (!$match.Success) {
                    continue
                }

                $this.pointer += $match.Value.length

                if ($Config.Skip) {
                    return $this.advanceNextToken()
                }

                return [AstNode]::new($Config.Type, $match.Value)
            }

        }

        throw "Unexpected Token '$($substring[0])'"
    }
    
}