﻿$ErrorActionPreference = "Stop"
#$ErrorActionPreference = "inquire" # Used/Uncommented when troubleshooting

##############  Script Functions ############## 
function GetServiceStatus {
    param (
        $serviceList
    )

    foreach ($service in $serviceList) 
    {
        #TODO: Wrap this in a try/catch to avoid whole section failing
        try{
            Get-Service -ComputerName $service.Server -Include $service.Services
        }
        catch {
            #TODO: Add errors to an array for displaying out of the group
            $Global:errorList += [PSCustomObject]@{Server=$service.Server;Err=$_}
            $global:mailPriority = 'Normal'
        }
    }
}

function GetServiceStatusHtml {
    param (
        $title,
        $serviceList
    )

    try {
        '<h1>' + $title + '</h1>'
        GetServiceStatus -serviceList $serviceList |
            Sort-Object -Property Status, MachineName, DisplayName |
            ConvertTo-Html -Fragment -As Table -Property MachineName, DisplayName, Status, StartType
    }
    catch {
        # If there is an error getting any of the server info, display the error and mark email as high priority
        $_
        $global:mailPriority = 'High'
    }
}

##############  Script Variables ############## 
#Note: We search Service names, not display names

$cmpServiceList = @(
    [PSCustomObject]@{Server='ONGMSCMPIF01';Services=@('*Infogenesis*','Bally Schedule Engine','BallyBICMService','BallyCumminsGatewayProcessService','BallyGatewayImportUtility','BallyPOSGatewayProcessService','BallyRecoveryGatewayProcessService','BallyTagGatewayProcessService')}
    [PSCustomObject]@{Server='ONGMSCMPAP01';Services=@('Bally CMP Application Server','Bally Local Pre-Commitment Service')}
    [PSCustomObject]@{Server='ONGMSCMPAP02';Services=@('Bally CMP Application Server','Bally Local Pre-Commitment Service')}
    [PSCustomObject]@{Server='CMPAccumPromo';Services='Bally CMPAccumPromotion'}
    [PSCustomObject]@{Server='SDSGateway';Services='Bally SDSGateway'}
    [PSCustomObject]@{Server='ONGMSCMPDB01';Services=@('MSSQLSERVER','SQLSERVERAGENT')}
    [PSCustomObject]@{Server='ONGMSCMPDB02';Services=@('MSSQLSERVER','SQLSERVERAGENT')}
    [PSCustomObject]@{Server='ONGMSSSRS01';Services=@('MSSQLSERVER','SQLSERVERAGENT','ReportServer')}
)

$sdsServiceList = @(
    [PSCustomObject]@{Server='ONGMSSDSIF01';Services=@('STCJBoss','FileZilla Server')}
    [PSCustomObject]@{Server='ONGMSSDSAP01';Services=@('SDSFloorJBoss','SDSUIJBoss')}
    [PSCustomObject]@{Server='ONGMSSDSAP02';Services=@('SDSFloorJBoss','SDSUIJBoss')}
    [PSCustomObject]@{Server='ONGMSSDSDB01';Services=@('MSSQLSERVER','SQLSERVERAGENT')}
    [PSCustomObject]@{Server='ONGMSSDSDB02';Services=@('MSSQLSERVER','SQLSERVERAGENT')}
)

$agServiceList = @(
    [PSCustomObject]@{Server='ONGMSAGDAP01';Services='Bally*'}
    [PSCustomObject]@{Server='ONGMSAGDAP02';Services='Bally*'}
)

$bccServiceList = @(
    [PSCustomObject]@{Server='ONGMSBCCAP01';Services='Bally*'}
    [PSCustomObject]@{Server='ONBELBCC01';Services='Bally*'}
    [PSCustomObject]@{Server='ONPETBCC01';Services='Bally*'}
    [PSCustomObject]@{Server='ONTICBCC01';Services='Bally*'}
    [PSCustomObject]@{Server='ONKAWBCCAP01';Services='Bally*'}
)

$chsServiceList = @(
    [PSCustomObject]@{Server='ONGMSCHS01';Services='CHS_*'}
)

$ebsServiceList = @(
    [PSCustomObject]@{Server='ONGMSEBSAP01';Services='*ServicesBootstrap*'}
    [PSCustomObject]@{Server='ONGMSEBSDB01';Services=@('MSSQLSERVER','SQLSERVERAGENT')}
    [PSCustomObject]@{Server='ONGMSEBSGW01';Services='W3SVC'}
    [PSCustomObject]@{Server='ONGMSEBSGW02';Services='W3SVC'}
    
)

$lfvServiceList = @(
    [PSCustomObject]@{Server='ONGMSLFVAP01';Services=@('iLFVBizService','LFV Table Service','LiveFloorViewServer','MapEditorService','W3SVC')}
    [PSCustomObject]@{Server='ONGMSLFVDB01';Services=@('MSSQLSERVER','SQLSERVERAGENT')}    
)

$umxServiceList = @(
    [PSCustomObject]@{Server='ONGMSUMXAP01';Services='Bally User Matrix Server 15.0'}
    [PSCustomObject]@{Server='ONGMSUMXAP02';Services='Bally User Matrix Server 15.0'}
)

$mailServer = "mail.gcgc.services"
$mailFrom = "Service Reporter <ogelp.servicereporter@gcgaming.com>"
$mailTo = "speacock@shorelinescasinos.com"
#$mailTo = "administrator@srvapp01.necrosoft.ca"
$mailSubject = "Service Status Report - " + @(Get-Date)

$mailStyle = "<style>"
$mailStyle += "body {font-family: 'Segoe UI', Arial;}"
$mailStyle += "table {background-color: white; border: thin solid black; width: 100%;}"
#$mailStyle += "h1 {font-size: 12pt;}"
$mailStyle += "th {background-color: gray;color: white;}"
#$mailStyle += "tr:nth-child(odd) {background-color: silver;}"
#$mailStyle += "td:first-child {font-weight: bold; text-align: center;}"
$mailStyle += "</style>"


##############  Script Logic ############## 
$errorList = $null
$errorList = @()

$mailBody = $null
$mailBody = @()
$mailPriority = 'Low'
Clear-Host
Write-Host $mailSubject

$mailBody += '<p>Please review the report and if any services are not in a RUNNING state, then escalate to GMS Team with high priority immediately</p>'

Write-Host 'Getting CMP Servers services'
$mailBody += GetServiceStatusHtml -title 'CMP Servers' -serviceList $cmpServiceList

Write-Host 'Getting SDS Servers services'
$mailBody += GetServiceStatusHtml -title 'SDS Servers' -serviceList $sdsServiceList

Write-Host 'Getting Alert Grid Servers services'
$mailBody += GetServiceStatusHtml -title 'Alert Grid Servers' -serviceList $agServiceList

Write-Host 'Getting BCC Servers services'
$mailBody += GetServiceStatusHtml -title 'Bally Command Center Servers' -serviceList $bccServiceList

Write-Host 'Getting CHS Servers services'
$mailBody += GetServiceStatusHtml -title 'CHS BackOffice Servers' -serviceList $chsServiceList

Write-Host 'Getting EBS Servers services'
$mailBody += GetServiceStatusHtml -title 'Elite Bonusing Servers' -serviceList $ebsServiceList

Write-Host 'Getting LFV Servers services'
$mailBody += GetServiceStatusHtml -title 'Live Floor View Servers' -serviceList $lfvServiceList

Write-Host 'Getting UMX Servers services'
$mailBody += GetServiceStatusHtml -title 'User Matrix Servers' -serviceList $umxServiceList


$mailBody += ConvertTo-Html -Fragment -As Table -PreContent 'Error Listing' -InputObject $errorList

Write-Host '!! Errors found !!'
foreach ($err in $errorList) {
    Write-Host $err
}


##### Send email report
try {
    Write-Host 'Sending Email'
    $mailContent = ConvertTo-Html -Title $mailSubject -Head $mailStyle -Body $mailBody | Out-String
    Send-MailMessage -BodyAsHtml -SmtpServer $mailServer -From $mailFrom -To $mailTo -Subject $mailSubject -Body $mailContent -Priority $mailPriority
    Write-Host 'Email Sent'
}
catch {
    Write-Host "!*!*!*!*! Something really messed up !*!*!*!*!"
    Write-Host $_
    # Write-EventLog -logname Application -EventId 0 -Source ServiceChecker -EntryType Error -Message $_
}