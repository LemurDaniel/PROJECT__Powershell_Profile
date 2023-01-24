
<#
# CREDITS: Tim Krehan idea
#>
function Get-ScrambledText {

    param(
        [Parameter()]
        [System.String]
        $text = (Get-Clipboard)
    )

    $newText = [System.Collections.ArrayList]::new()

    foreach ($word in ($text -split ' ')) {
        $word = $word.trim()

        $startLetter = ($word -split '')[1]
        $endLetter = ($word -split '')[-2]

        if ($word.length -le 3) {
            $null = $newText.Add($word)
        }
        else {
            $letters = ($word -split '')[2..($word.length - 1)]
      
            $count = Get-Random -Minimum 2 -Maximum 5
            for ($i = 0; $i -lt $count; $i++) {
                $rand = Get-Random -Minimum 0 -Maximum ($letters.Length - 1)
                $rand2 = Get-Random -Minimum 0 -Maximum ($letters.Length - 1)
                $temp = $letters[$rand]
                $letters[$rand] = $letters[$rand2]
                $letters[$rand2] = $temp
            }

            $letters = $letters -join ''

            $null = $newText.Add("$startLetter" + "$letters" + "$endLetter")
        }
    }

    Set-Clipboard -Value ($newText -join ' ')
    return ($newText -join ' ')

}