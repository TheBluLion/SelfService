param(
    [object]$webhookdata
)

#this flags sets debug messages to show in the test pane
$debug=$false

    #the http request body should include any parameters passed to the runbook in json format
    #best practice - a validation secret should also be included in the body to secure the request.
    $webhookpayload = convertfrom-json $webhookdata
    $upn=$webhookpayload.upn
    $validationSecret = $webhookpayload.validationsecret
    $MigrateMeetings=$true
    $Policy= $webhookdata.upgradepolicy

    if($debug){
        write-output "debug: webhook payload is $($webhookpayload.upn)"
    }


    #load values from Automation account variables
    #$tenantId = Get-AutomationVariable -Name tenantid

    #load credentials from automation account
    $SfBTeamsAdminCredential = Get-AutomationPSCredential -Name "Office 365 admin"

    if($debug){
        write-output "debug: SfBAdmin credential retrieved as $($SfbteamsAdmincredential.username)"
    }

    #initialize connections to cloud services

    #Connect to Microsoft Teams Powershell. Used for new-csbatchpolicyassignmentoperation
    $TeamsConnection=Connect-microsoftteams -Credential $SfBTeamsAdminCredential

    #This is the connection to SfB Online. Used for grant-csteamsupgradepolicy
    #we have to be specific about cmds imported because Automation Account runbooks have a hard limit on session size.
    $sfbSession = New-CsOnlineSession -Credential $sfbteamsadminCredential
    Import-PSSession $sfbSession -CommandName Grant-Csteamsupgradepolicy

    if($debug){
        write-output "Teams connection domain name should be here: $($TeamsConnection.tenantdomain)"
        write-output "sfb session name should be here: $($sfbSession.Name)"
    }
    #batch for friday runs This uses the MicrosoftTeams Connection. Uncomment the line below to enable
    #New-CsBatchPolicyAssignmentOperation -PolicyType TeamsUpgradePolicy -PolicyName $null -Identity $upn -OperationName "Batch assign null"

    #singleton for single runs - this uses Sfb session. Uncomment the line below to enable.
    #grant-csteamsupgradepolicy -PolicyName $Policy -MigrateMeetingsToTeams $MigrateMeetings -Identity $upn

    #clean up session
    remove-pssession $sfbSession

    #if no errors return success
    if ($error.count -lt 1){
        write-output "Success"
    }
    else{
        write-output "Failed"
        write-output $error
    }

#add logging here
#add user feedback here -trigger email or IM notification flow.

