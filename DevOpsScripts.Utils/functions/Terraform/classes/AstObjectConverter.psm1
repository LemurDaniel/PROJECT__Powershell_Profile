
class AstObjectConverter {

    static [System.Object] Convert($parsed) {
        return [AstObjectConverter]::new().ConvertParsedBlockStatement($parsed)
    }

    # Blocks only expect Assignment Expressions
    [System.Object] ConvertParsedBlockStatement($parsed) {

        $object = [pscustomobject]::new()
        foreach ($expression in $parsed.Value) {
            switch ($expression.Type) {
                AssignmentExpression {
                    $Variable = $expression.Value[0]
                    $Assigne = $expression.Value[1]
                    $ExpressionValue = $this.ConvertParsedExpression($Assigne)
                    $object | Add-Member -MemberType NoteProperty -Name $Variable.Value -Value $ExpressionValue
                }
                Default {
                    throw "Expected 'Assignment Expression', got '$($expression.Type)'"
                }
            }
        }

        return $object
    }

    [System.Object] ConvertParsedArray($parsed) {
        
        $array = @()
        foreach ($expression in $parsed.Value) {
            $array += $this.ConvertParsedExpression($expression)
        }
        return $array
    }

    
    [System.Object] ConvertParsedExpression($parsed) {
        
        switch ($parsed.Type) {
            StringLiteral { 
                return $parsed.Value
            }
            FloatingPointLiteral {
                return $parsed.Value
            }
            NumericLiteral { 
                return $parsed.Value
            }
            Boolean { 
                return $parsed.Value
            }
            Null { 
                return $parsed.Value
            }
            BlockStatement { 
                return $this.ConvertParsedBlockStatement($parsed)
            }
            Array { 
                return $this.ConvertParsedArray($parsed)
            }
            Default {
                throw "Expected on of 'Boolean', 'StringLiteral', 'NumericLiteral', 'BlockStatement', 'Array', got '$($parsed.Type)'"
            }
        }

        return $null
    }

}