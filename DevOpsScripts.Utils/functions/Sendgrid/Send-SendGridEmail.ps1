<#
.Synopsis
    Send an Email with the SendGrid API
 
.DESCRIPTION
    This function sends an email using SendGrid REST API with optional attachments being compressed into Zip-files.
 
.EXAMPLE

    Send text email via send grid:

    PS> Send-SendGridEmail -FromEmail "from@mail"  -ToEmail "to@mail" -Body "text" -Subject "subject" -ApiKey "APIKEY" 

.EXAMPLE

   Send text email via send grid with file attachments:
 
   PS> Get-Childitem -Path "path" | Send-SendGridEmail -FromEmail "from@mail"  -ToEmail "to@mail" -Body "text" -Subject "subject" -ApiKey "APIKEY" 

#>

function Send-SendGridEmail {

    Param
    (
        # Sender Email
        [Parameter(Mandatory = $true)]
        [System.String] $FromEmail,

        # Name of sender Email
        [Parameter()]
        [System.String] $FromName = $null,
 
        # Receiver Emails
        [Parameter(Mandatory = $true)]
        [System.String[]] $ToEmail,

        # Names of Receiver Emails
        [Parameter()]
        [System.String[]] $ToName = [System.Collections.ArrayList]::new(),
 
        # Subject
        [Parameter(Mandatory = $true)]
        [System.String] $Subject,
 
        # Textbody of email
        [Parameter(Mandatory = $true)]
        [System.String] $Body = '',

        [Parameter()] 
        [System.String] $Type = 'text/plain',
    

        # Apikey for SendGrid
        [Parameter(Mandatory = $true)]
        [System.String] $ApiKey,

        # Attachments are compressed into a zip file. Name of that zip file.
        [parameter()]
        [System.String] $attachmentName = 'attachments.zip',

        # Files to be compressed and send as attachments.
        [parameter(ValueFromPipeline = $True)]
        [System.IO.FileInfo[]] $attachments
    )
 
    BEGIN {}
    PROCESS {
        if ($attachments) {
            foreach ($attachment in $attachments) {
                $temporaryAttachmentPath = Join-Path $attachment.Directory.FullName 'attachment.zip'
                Compress-Archive -Path $attachments -DestinationPath $temporaryAttachmentPath -Update
            }    
        }
    }

    END {

        If ($FromName -eq $null) {
            $FromName = $FromEmail
        }

        $headers = @{
            'Authorization' = "Bearer $apiKey"  
            'Content-Type'  = 'application/json'
        }

        $recipientList = [System.Collections.ArrayList]::new()
        for ($i = 0; $i -lt $ToEmail.length; $i++) { 
            $recipientList.Add(@{
                    email = $ToEmail[$i]
                    name  = $ToEmail[$i]
                })
        }
    
        $jsonBody = @{
            personalizations = @(
                @{
                    to      = $recipientList
                    subject = $Subject
                }
            )
            from             =
            @{
                email = $FromEmail
                name  = $FromName
            }
            content          = @(
                @{
                    type  = $Type
                    value = $Body
                } 
            )
        }

        # Add attachment if provided
        if ($attachments) {
            $file = Get-Item -Path $temporaryAttachmentPath
            $encodedFile = [Convert]::ToBase64String([IO.File]::ReadAllBytes($file))
     
            $jsonBody.Add('attachments', @(
                    @{
                        content     = $encodedFile
                        filename    = $attachmentName
                        type        = 'application/zip'
                        disposition = 'attachment'
                    }
                )
            )
    
            Remove-Item -Path $temporaryAttachmentPath
        }


        try {
            Write-Host $Body
            $jsonBody = ConvertTo-Json -InputObject $jsonBody -Depth 4
            Invoke-RestMethod -Uri 'https://api.sendgrid.com/v3/mail/send' -Method Post -Headers $headers -Body $jsonBody 
            Write-Host -ForegroundColor Green "Succesfully send Email to '$toEmail'"
        }
        catch {
            throw $_
        }
    }
}