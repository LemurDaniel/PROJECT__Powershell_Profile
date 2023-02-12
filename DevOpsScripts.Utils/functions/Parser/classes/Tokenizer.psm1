Using module './AstNodeType.psm1'
Using module './AstNode.psm1'

class Tokenizer {

    [AstNodeType[]] $Configuration

    [System.String] $content
    [AstNode] $current

    Tokenizer($Configuration) {
        $this.Configuration = $Configuration
        $this.content = ''
    }

    [Tokenizer] set($content) {
        $this.content = $content
        return $this
    }
    [AstNode] advanceNextToken() {
        $this.current = $this._advance()
        return $this.current
    }


    [AstNode] _advance() {
        if ($this.content.Length -le 0) {
            return $null
        }

        foreach ($config in $this.CONFIGURATION) {

            $match = [regex]::Match($this.content, $Config.regex)

            if ($match.Success) {
                $this.content = $this.content.Substring($match.Value.length)

                if ($Config.Skip) {
                    return $this.advanceNextToken()
                }
                else {
                    return [AstNode]::new($Config.Type, $match.Value.Trim())
                }
            }
        }

        throw "Unexpected Token '$($this.content[0])' at '$($this.position())'"
    }

    [System.String] position() {
        return $this.content.Substring(0, [System.Math]::Max(0, [System.Math]::Min(30, $this.content.Length - 1)))
    }
    
}