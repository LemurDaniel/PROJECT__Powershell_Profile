
Using module './AstNodeType.psm1'
Using module './AstNode.psm1'
Using module './Tokenizer.psm1'

class Parser {

    [Tokenizer] $tokenizer

    Parser($Configuration) {
        $this.tokenizer = [Tokenizer]::new($Configuration)
    }

    # Intialize parse
    [AstNode] parse($content) {
        $this.tokenizer.set($content)
        $null = $this.tokenizer.advanceNextToken()

        return [AstNode]::new(
            'File',
            $this.StatementList()
        )
    }


    [AstNode[]] StatementList() {
        return $this.StatementList($null)
    }
    [AstNode[]] StatementList($stopLookahead) {
        return $this.StatementList($stopLookahead, 'Statement')
    }
    [AstNode[]] StatementList($stopLookahead, $StatementMethod) {
        $statementList = @()

        while ($stopLookahead -ne $this.tokenizer.current.Type) {
            $statement = $this.$StatementMethod()
            if ($null -ne $statement) {
                $statementList += $statement
            }
        }

        return $statementList
    }


    # Expectes either seperators or an Assignment.
    [AstNode] Statement() {
        switch ($this.tokenizer.current.Type) {
            SEPERATOR {
                $this.eat($this.Seperator.Type)
                return $null
            }
        }

        return $this.AssignmentExpression()
    }

    # Expect either Blocks, Array or Literals.
    [AstNode] BasicStatement() {
        switch ($this.tokenizer.current.Type) {
            BLOCK_START {
                $this.eat('BLOCK_START')
                $body = $this.tokenizer.current.Type -eq 'BLOCK_END' ? @() : $this.StatementList('BLOCK_END')
                $this.eat('BLOCK_END')
                return [AstNode]::new(
                    'BlockStatement',
                    $body
                )
            }
            ARRAY_START {
                $this.eat('ARRAY_START')
                $body = $this.tokenizer.current.Type -eq 'ARRAY_END' ? @() : $this.StatementList('ARRAY_END', 'ArrayExpression')
                $this.eat('ARRAY_END')
                return [AstNode]::new(
                    'Array',
                    $body
                )
            }
            HEREDOC_STRING_START {
                $this.eat('HEREDOC_STRING_START')
                $body = $this.tokenizer.current.Type -eq 'ARRAY_END' ? @() : $this.StatementList('ARRAY_END', 'ArrayExpression')
                $this.eat('ARRAY_END')
                return [AstNode]::new(
                    'Array',
                    $body
                )
            }
        }
        return $this.Literal()
    }

    # Expectes Elements and ArrayEnd or ArraySeperators
    [AstNode] ArrayExpression() {
        $element = $this.BasicStatement()
        if ($this.tokenizer.current.type -ne 'ARRAY_END') {
            $this.eat('ARRAY_SEPERATOR')
        }
        return $element
    }

    # Assignment Expressions expect a Variable identifier and a following BasicStatement
    [AstNode] AssignmentExpression() {

        $variable = $null
        switch ($this.tokenizer.current.Type) {
            VARIABLE {
                $variable = $this.eat('VARIABLE')
            }
            STRING {
                $variable = $this.Literal()
            }

            Default {
                throw "Unexpected Token '$($this.tokenizer.current.Type)', expected one of 'VARIABLE', 'STRING'; at '$($this.tokenizer.current.Value)'"
            }
        }

        $this.eat('ASSIGNMENT')
        $assigne = $this.BasicStatement()

        # Terraform allows for Commas after Assignment Expressions
        if ($this.tokenizer.current.Type -eq 'ARRAY_SEPERATOR') {
            $this.eat('ARRAY_SEPERATOR')
        }

        return [AstNode]::new(
            'AssignmentExpression',
            @(
                $variable,
                $assigne 
            )
        )
    }


    # Literals expect NumberLiterals or StringLiterals
    [AstNode] Literal() {

        switch ($this.tokenizer.current.Type) {
            NUMBER { 
                $token = $this.eat('NUMBER')
                try {
                    return [AstNode]::new(
                        'NumericLiteral', 
                        [System.int32]::Parse($token.Value)
                    )
                }
                catch {
                    Write-Host ($token | ConvertTo-Json)
                    throw $_
                }
            }

            STRING { 
                $token = $this.eat('STRING')
                return [AstNode]::new(
                    'StringLiteral', 
                    $token.Value.Substring(1, $token.Value.length - 2) # Strip away Quotations
                )
            }

            HEREDOC_STRING { 
                $token = $this.eat('HEREDOC_STRING')
                $content = $token.Value -split '\n'
                return [AstNode]::new(
                    'StringLiteral', 
                    $content[1..($content.length - 2)] -join '\n'
                )
            }

            BOOLEAN { 
                $token = $this.eat('BOOLEAN')
                try {
                    return [AstNode]::new(
                        'Boolean', 
                        [Boolean]::Parse($token.Value)
                    )
                }
                catch {
                    Write-Host ($token | ConvertTo-Json)
                    throw $_
                }
            }

            NULL {
                $token = $this.eat('NULL')
                return [AstNode]::new(
                    'Null', 
                    $null
                )
            }

            $null {
                return $null
            }

            Default {
                throw "Unexpected Literal '$($this.tokenizer.current.Type)' at '$($this.tokenizer.current.Value)'"
            }
        }

        return $null
    }


    # Consumes and advances to the next token.
    [AstNode] eat($tokenType) {
        return $this.eat($tokenType, $false)
    }
    [AstNode] eat($tokenType, $optional) {
        $token = $this.tokenizer.current

        if ($null -eq $token) {
            throw "unexpected EOF, expected: '$tokenType' at '$($token.Value)'"
        }

        if ($token.type -ne $tokenType) {
            throw "unexpected token: '$($token.type)', expected '$tokenType' at '$($token.Value)'"
        }

        $null = $this.tokenizer.advanceNextToken()

        return $token
    }
}