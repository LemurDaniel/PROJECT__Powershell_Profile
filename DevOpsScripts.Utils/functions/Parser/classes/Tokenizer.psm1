Using module './AstNodeType.psm1'
Using module './AstNode.psm1'

class Tokenizer {

    [AstNodeType[]] $Configuration

    [System.String] $content
    [System.int32] $pointer
    [AstNode] $current

    Tokenizer($Configuration) {
        $this.Configuration = $Configuration
        $this.content = ""
        $this.pointer = 0
    }

    [Tokenizer] set($content) {
        $this.content = $content
        $this.pointer = 0
        return $this
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

        foreach ($config in $this.CONFIGURATION) {

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