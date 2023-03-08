function Invoke-DalleRequest() {
    <#
    .SYNOPSIS
      Leverages the API of OpenAI to generate a dall-e algorythm based image
    .DESCRIPTION
      Uses the openai.com API definition for image generation documented here:
      https://platform.openai.com/docs/api-reference/images
      If you just call the dall-e function it will generate a small picture wit the keywords
      "cute otter holding a ball"
    .NOTES
      All calls to the endpoint will consume your API Quota - so proceed with care.
      This function is written by for the API on 31.01.2023.
      Author: Tim Krehan
      Date  : 31.01.2023
      Copyright: Tim Krehan
    .LINK
          https://platform.openai.com/docs/api-reference/images
    .EXAMPLE
      dall-e t-rex in a shopping mall
      https://oaidalleapiprodscus.blob.core.windows.net/private/org-BBORa1jmmy7ecatmxg9uaEWC/user-pZQ6nJiLCAQsqAuSRyt1Wlmp/img-EW4SBtGihQ0drnjE3Kth5Xz6.png?st=2023-01-31T08%3A03%3A24Z&se=2023-01-31T10%3A03%3A24Z&sp=r&sv=2021-08-06&sr=b&rscd=inline&rsct=image/png&skoid=6aaadede-4fb3-4698-a8f6-684d7786b067&sktid=a48cca56-e6da-484e-a814-9c849652bcb3&skt=2023-01-30T22%3A18%3A07Z&ske=2023-01-31T22%3A18%3A07Z&sks=b&skv=2021-08-06&sig=jk/YrE8ZLywb8DiMMWme6KuJzfA34hGvTrm6Thc32yA%3D
  
      This will generate a small image (256x256) based on the Text "t-rex in a shopping mall" and dump the link to the host.
    .EXAMPLE
      dall-e running banana -Size 512x512 -Count 2
      https://oaidalleapiprodscus.blob.core.windows.net/private/org-BBORa1jmmy7ecatmxg9uaEWC/user-pZQ6nJiLCAQsqAuSRyt1Wlmp/img-UhKYkfa8SkLdzqn0DkWbLPIp.png?st=2023-01-31T08%3A06%3A51Z&se=2023-01-31T10%3A06%3A51Z&sp=r&sv=2021-08-06&sr=b&rscd=inline&rsct=image/png&skoid=6aaadede-4fb3-4698-a8f6-684d7786b067&sktid=a48cca56-e6da-484e-a814-9c849652bcb3&skt=2023-01-30T22%3A17%3A59Z&ske=2023-01-31T22%3A17%3A59Z&sks=b&skv=2021-08-06&sig=Unh0jwQLd3T8Qsy9Tab7Iq1nnonVmRY42b5%2BA3XKBuc%3D
      https://oaidalleapiprodscus.blob.core.windows.net/private/org-BBORa1jmmy7ecatmxg9uaEWC/user-pZQ6nJiLCAQsqAuSRyt1Wlmp/img-81aSGbflW7oHffs78Qd4kPMn.png?st=2023-01-31T08%3A06%3A51Z&se=2023-01-31T10%3A06%3A51Z&sp=r&sv=2021-08-06&sr=b&rscd=inline&rsct=image/png&skoid=6aaadede-4fb3-4698-a8f6-684d7786b067&sktid=a48cca56-e6da-484e-a814-9c849652bcb3&skt=2023-01-30T22%3A17%3A59Z&ske=2023-01-31T22%3A17%3A59Z&sks=b&skv=2021-08-06&sig=sipJieYosHS6wEWSC9C5q4BIz2xurzO/dfJoE2Tl290%3D
      
      This will generate multiple images with the given size 512x512
    .EXAMPLE
      dall-e bionic man with bears for arms -outFolder C:\temp
      FullName                                            Length LastWriteTime       URL
      --------                                            ------ -------------       ---
      C:\temp\bionic man with bears for arms-0.png 197109 31.01.2023 10:09:14 https://oaidalleapiprodscus.blob.core.windows.net/private/org-BBORa1jmmy7ecatmxg9uaEWC/user-pZQ6nJiLCAQsqA…
  
      This will download the generated image after completion in the given path, named like the text input appended by an iterator (for multiple image downloads)
  
    #>
    [CMDLetBinding(PositionalBinding = $false)]
    [Alias("dall-e")]
    param(
      [parameter(ValueFromRemainingArguments = $true, Position = 0)]
      [string]$Text = "cute otter holding a ball",
      [parameter()]
      [ValidateRange(1, 10)]
      [int]$Count = 1,
      [parameter()]
      [ValidateSet("256x256", "512x512", "1024x1024")]
      [string]$Size = "256x256",
      [parameter()]
      $OutFolder = $null
    )
    begin {
      function Get-FileCredentials {
        [CMDLetBinding(DefaultParameterSetName = "default", PositionalBinding = $false)]
        [Alias("cred")]
        param(
          [parameter(Mandatory = $true, ParameterSetName = "default", Position = 0)][string]$userName,
          [parameter( ParameterSetName = "default", Position = 1)][string]$userDomain = "baugruppe.de",
          [parameter( ParameterSetName = "default", Position = 2)][string]$message = "Passwort eingeben",
          [parameter( ParameterSetName = "default")][switch]$delete,
          [parameter( ParameterSetName = "list")][switch]$list
        )
        begin {
          $credentialFolder = "$env:USERPROFILE\.cred"
          $credentialPath = "$credentialFolder\$username@$userDomain.credentials"
          if (!(Test-Path $credentialFolder)) {
            New-Item -ItemType Directory -Path $credentialFolder -Force | Out-Null
          }
        }
        process {
          if ($list) { Get-ChildItem -Path $credentialFolder; return }
          if ($delete -and (Test-Path $credentialPath)) { Remove-Item -Path $credentialPath }
          if ($delete) { return }
          if (!(Test-Path $credentialPath)) {
            $Credentials = Get-Credential -UserName "$userName@$userDomain" -Message $message
            $secureString = ConvertFrom-SecureString $Credentials.Password
            Out-File -FilePath "$credentialPath" -InputObject $secureString -Encoding UTF8 -Force
          }
          $secureString = Get-Content -Path $credentialPath -Encoding UTF8
          $Credentials = [pscredential]::new("$userName@$userDomain", (ConvertTo-SecureString -String $secureString))
        }
        end {
          return $Credentials
        }
      }
      $openAIOrg = Get-FileCredentials -userName OpenAI-Organization -userDomain openai.com -message "OpenAI Organization ID"
      $openAIAPIKey = Get-FileCredentials -userName OpenAI-APIKey -userDomain openai.com -message "OpenAI API Key"
      $url = "https://api.openai.com/v1/images/generations"
      $headers = @{
        'OpenAI-Organization' = $openAIOrg.GetNetworkCredential().Password
        'Authorization'       = "Bearer $($openAIAPIKey.GetNetworkCredential().Password)"
      }
      $method = "POST"
    }
    process {
      $oldProgressPreference = $ProgressPreference
      $ProgressPreference = 'SilentlyContinue'
      $returnObject = @()
      if ($PSBoundParameters.ContainsKey("outFolder")) {
        if (Test-Path -Path $outFolder -PathType Container) { }
        else {
          throw "Path must be a existing folder."
        }
      }
      $body = @{
        prompt          = $text
        n               = $count
        size            = $size
      }
      if($PSBoundParameters.ContainsKey("outFolder")){
        $body.response_format = "b64_json"
      }
      else{
        $body.response_format = "url"
      }
      $jsonBody = $body| ConvertTo-Json
  
      $Encoding = [System.Text.Encoding]::UTF8
      [byte[]]$bodyBytes = $Encoding.GetBytes($jsonBody)
  
      $contentType = "application/json"
      try {
        $response = Invoke-RestMethod -Method $method -Uri $url -Headers $headers -ContentType $contentType -Body $bodyBytes
        if ($PSBoundParameters.ContainsKey("outFolder")) {
          $FileName = ([char[]]$text | ForEach-Object -Process {
              if ($_ -in [System.IO.Path]::GetInvalidFileNameChars()) { return "_" }
              else { return $_ }
            }) -join ""
            
            ($response.data.b64_json) | 
            ForEach-Object -Begin {
              $i = 0
            } -Process {
              $img = [Drawing.Bitmap]::FromStream([IO.MemoryStream][Convert]::FromBase64String($_))
              $extension = $img.RawFormat.ToString().ToLower()
              do {
                $currentFileName = "$FileName-$i.$extension"
                $outFilePath = (Join-Path -Path $outFolder -ChildPath $currentFileName)
                $i++
              }
              while (Test-Path $outFilePath)
              $img.Save($outFilePath)
              $returnObject += Get-Item -Path $outFilePath
            }
        }
        else {
          $returnObject = $response.data.url
        }
      }
      catch {
        if ($_.categoryinfo.reason -eq "HttpResponseException") {
          $dalleError = $_.errordetails.message | ConvertFrom-Json
          if ([string]::isnullorempty($dalleError.error)) {
            $dalleError
          }
          else {
            $dalleError.error
          }
        }
        else {
          throw $_
        }
      }
    }
    end {
      $ProgressPreference = $oldProgressPreference
      return $returnObject
    }
  }