# Generate a token for a user with instance level "Adminster" permission and supply it to the $user variable
$user = 'TOKEN'
$pass = ''

$pair = "$($user):$($pass)"

$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))

$basicAuthValue = "Basic $encodedCreds"

$Headers = @{
    Authorization = $basicAuthValue
}

# Base URL of your SonarQube instance
$sonarQubeInstance = "http://localhost:9000"

# Existing identity provider, in this case "sonarqube" is used as the existing identity provider is LDAP
$currentExternalIdentityProvider = "sonarqube"

# Target identity provider, in this case "saml" is used as the existing identity provider is SAML
$targetExternalIdentityProvider = "saml"

## Get the first page of all users
$usersResponse = Invoke-RestMethod -Uri "$sonarQubeInstance/api/users/search?ps=500" -Headers $headers -Method GET
$users = $usersResponse.users

foreach($user in $users){

    $login = $user.login
    $isLocal = $user.local
    $email = $user.email
    $externalIdentity = $user.externalIdentity
    $externalProvider = $user.externalProvider

    # Assumes the external identity in SAML is the user's e-mail address
    $newExternalIdentity = $email

    # Prevents local users from being locked out of the SonarQube instance
    if($isLocal -eq $false){
        # Only migrate users of the exsiting identity provider
        if($externalProvider = $currentExternalIdentityProvider){
            Invoke-RestMethod -Uri "$sonarQubeInstance/api/users/update_identity_provider?login=$login&newExternalProvider=$targetExternalIdentityProvider&newExternalIdentity=$newExternalIdentity" -Headers $headers -Method POST
            Write-Output "Migrated user with login $login and external identity $externalIdentity from $currentExternalIdentityProvider to $targetExternalIdentityProvider with new external identity $newExternalIdentity"
        }
    }
}
