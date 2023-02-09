
Using module './AstNodeType.psm1'
Using module './AstNode.psm1'
Using module './Tokenizer.psm1'

class Parser {

    [Tokenizer] $tokenizer

    Parser($Configuration) {
        $this.tokenizer = [Tokenizer]::new($Configuration)
    }

    [AstNode] parse($content) {
        $this.tokenizer.set($content)
        $null = $this.tokenizer.advanceNextToken()

        return [AstNode]::new(
            'File',
            $this.StatementList()
        )
    }

    ##################
    [AstNode[]] StatementList() {
        return $this.StatementList($null)
    }
    [AstNode[]] StatementList($stopLookahead) {
        $statementList = @($this.Statement())

        while ($stopLookahead -ne $this.tokenizer.current.Type) {
            $statementList += $this.Statement()
        }

        return $statementList
    }

    ##################
    [AstNode] Statement() {
        switch ($this.tokenizer.current.Type) {
            '{' {
                $this.eat('{')
                $body = $this.tokenizer.current.Type -eq '}' ? @() : $this.StatementList('}')
                $this.eat('}')
                return [AstNode]::new(
                    'BlockStatement',
                    $body
                )
            }
        }
        return $this.ExpressionStatement()
    }

    [AstNode] ExpressionStatement() {
        $expression = $this.Expression()
        $this.eat('StatementSeperator')
        return [AstNode]::new(
            'ExpressionStatement',
            $expression
        )
    }



    ##################
    [AstNode] Expression() {
        return $this.Literal()
    }

    ##################
    [AstNode] Literal() {

        switch ($this.tokenizer.current.Type) {
            NUMBER { 
                $token = $this.eat('NUMBER')
                return [AstNode]::new(
                    'NumericLiteral', 
                    [System.int32]::Parse($token.Value)
                )
            }

            STRING { 
                $token = $this.eat('STRING')
                return [AstNode]::new(
                    'StringLiteral', 
                    $token.Value.Substring(1, $token.Value.length - 2) # Strip away Quotations
                )
            }

            Default {
                throw "Unexpected Literal $($this.tokenizer.current.Type)"
            }
        }

        return $null
    }



    [AstNode] eat($tokenType) {
        $token = $this.tokenizer.current

        if ($null -eq $token) {
            throw "unexpected EOF, expected: '$tokenType'"
        }

        if ($token.type -ne $tokenType) {
            throw "unexpected token: '$($token.type)', expected '$tokenType'"
        }

        $null = $this.tokenizer.advanceNextToken()

        return $token
    }
}