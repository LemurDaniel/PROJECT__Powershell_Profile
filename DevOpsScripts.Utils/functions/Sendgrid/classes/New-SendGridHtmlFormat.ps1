class SendGridHTMLFormat {
    
    # For Each Execution of FormatSendGrid another CSS-Head for those Elements is appended.
    [System.String[]]$CSSHeads = @()
    [System.String[]]$BodyDivs = @()

    [SendGridHTMLFormat] AddElement($CSSFileName, $DivContent, $ContentInsert) {
        $randomString = -join ((97..122) | Get-Random -Count 14 | ForEach-Object { [char]$_ })
        $DivContent = $ContentInsert -replace '\$1', $DivContent
        $Div = "<div id='$randomString'>$DivContent</div>"
        $Css = (New-Stylesheet)::GetCSSContentTargetedToId($CSSFileName, $randomString)

        $this.CSSHeads += $Css
        $this.BodyDivs += $Div

        return $this
    }

    [System.String]toHTMLString() {
        return "<!DOCTYPE html PUBLIC `"-//W3C//DTD XHTML 1.0 Strict//EN`" `"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd`">
            <html xmlns=`"http://www.w3.org/1999/xhtml`">
            <style>$($this.CSSHeads -join '')</style>
            <body>$($this.BodyDivs -join '')</body>
            </html>"
        
    }

}


function New-SendGridHtmlFormat {

    [CmdletBinding()]
    param ()

    return [SendGridHTMLFormat]::new()
    
}