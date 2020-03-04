#Keep tenant id, client id, client secret in info.json file run the script 
#this script will take the input from current folder and create output in current folder  (keep the info.json file in same folder where you are running the script)
#this script will take the input as objectid

#creating token id
$input = get-content info.json | ConvertFrom-Json
$Client_Secret = $input.Client_Secret
$client_Id = $input.client_Id
$Tenantid = $input.Tenantid

#Grant Adminconsent 
$Grant= 'https://login.microsoftonline.com/common/adminconsent?client_id='
$admin = '&state=12345&redirect_uri=https://localhost:1234'
$Grantadmin = $Grant + $client_Id + $admin

start $Grantadmin
write-host "login with your tenant login detials to proceed further"

$proceed = Read-host " Press Y to continue "
if ($proceed -eq 'Y')
{
    write-host "Creating Access_Token"          
              $ReqTokenBody = @{
         Grant_Type    =  "client_credentials"
        client_Id     = "$client_Id"
        Client_Secret = "$Client_Secret"
        Scope         = "https://graph.microsoft.com/.default"
    } 

    $loginurl = "https://login.microsoftonline.com/" + "$Tenantid" + "/oauth2/v2.0/token"
    $Token = Invoke-RestMethod -Uri "$loginurl" -Method POST -Body $ReqTokenBody -ContentType "application/x-www-form-urlencoded"

    $Header = @{
        Authorization = "$($token.token_type) $($token.access_token)"
    }
    
    $TeamsList = Import-Csv "input.csv"
    foreach($Teams in $TeamsList)
    {
    
        $groupuri = "https://graph.microsoft.com/v1.0/teams/" + $Teams.objectId
        $result = Invoke-RestMethod -Headers $Header -Uri $groupuri  -Method Get
        $id = $result.id
                
        if ($id -eq $Teams.objectId){
                    write-host "getting details for"  $Teams.objectId 
                    $teamuri = "https://graph.microsoft.com/v1.0/groups/" + $Teams.objectId
                    $Teamdetails = Invoke-RestMethod -Headers $Header -Uri $teamuri -Method Get -ContentType 'application/json'
                     
                    $channeluri = "https://graph.microsoft.com/v1.0/teams/" + $Teamdetails.id + "/channels"
                    $channel = Invoke-RestMethod -Headers $Header -Uri $channeluri  -Method Get 
                    $channelvalue = $channel.value
                    $ChanneldisplayName = $channelvalue.displayName
                    $Channels = [string]::Join(", ",$ChanneldisplayName)

                    $owneruri = "https://graph.microsoft.com/v1.0/Groups/" + $Teamdetails.id + "/owners"
                    $Owner = Invoke-RestMethod -Headers $Header -Uri $owneruri -Method Get 
                    $Teamownervalues = $Owner.value 
                    $OwneruserPrincipalName = $Teamownervalues.userPrincipalName
                    $owners = [string]::Join(", ",$OwneruserPrincipalName)
                    
                    $memberuri = "https://graph.microsoft.com/v1.0/Groups/" + $Teamdetails.id + "/Members"
                    $Member = Invoke-RestMethod -Headers $Header -Uri $memberuri -Method Get 
                    $Membersvalues = $Member.value 
                    $MemberuserPrincipalName = $Membersvalues.userPrincipalName
                    $Members = [string]::Join(", ",$MemberuserPrincipalName)


                    $file = New-Object psobject
                    $file | add-member -MemberType NoteProperty -Name TeamsName $Teamdetails.displayname
                    $file | add-member -MemberType NoteProperty -Name TeamType $Teamdetails.visibility
                    $file | add-member -MemberType NoteProperty -Name CreatedDateTime $Teamdetails.createdDateTime 
                    $file | add-member -MemberType NoteProperty -Name ChannelCount $channel.value.id.count
                    $file | add-member -MemberType NoteProperty -Name Channels $Channels
                    $file | add-member -MemberType NoteProperty -Name Owners $Owners 
                    $file | add-member -MemberType NoteProperty -Name MembersCount $MemberuserPrincipalName.count
                    $file | add-member -MemberType NoteProperty -Name Members $Members
                    $file | export-csv output.csv -NoTypeInformation -Append
                }
                        else{
                write-host "this Group is not a team"
                }
                } 
        }
 
 else 
{
    write-host "You need to login admin consent in order to continue... " 
}