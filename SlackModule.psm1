# SlackModule.psm1

<#
.SYNOPSIS
Retrieves a list of Slack channels.
.DESCRIPTION
This function connects to the Slack API and retrieves a list of all available channels in the workspace.
.PARAMETER token
The OAuth token used to authenticate to the Slack API.
.EXAMPLE
$channels = Get-SlackChannel -token "your-oauth-token"
#>
function Get-SlackChannel {
    param(
        [string]$token
    )
    $url = "https://slack.com/api/conversations.list"
    $headers = @{
        Authorization = "Bearer $token"
    }
    $response = Invoke-RestMethod -Uri $url -Headers $headers -Method Get
    return $response.channels
}

<#
.SYNOPSIS
Creates a new Slack channel.
.DESCRIPTION
This function creates a new Slack channel with the specified name using the Slack API.
.PARAMETER token
The OAuth token used to authenticate to the Slack API.
.PARAMETER channelName
The name of the channel to create.
.EXAMPLE
New-SlackChannel -token "your-oauth-token" -channelName "new-channel"
#>
function New-SlackChannel {
    param(
        [string]$token,
        [string]$channelName
    )
    $url = "https://slack.com/api/conversations.create"
    $headers = @{
        Authorization = "Bearer $token"
    }
    $body = @{
        name = $channelName
    }

    try {
        $response = Invoke-RestMethod -Uri $url -Headers $headers -Method Post -Body ($body | ConvertTo-Json) -ContentType "application/json"

        if ($response.ok -eq $false) {
            Write-Host "Error: $($response.error)"
            return $response.error
        } else {
            Write-Host "Channel created successfully: $($response.channel.id)"
            return $response.channel
        }
    }
    catch {
        Write-Host "An error occurred: $_"
    }
}



<#
.SYNOPSIS
Archives an existing Slack channel.
.DESCRIPTION
This function archives an existing Slack channel specified by its ID.
.PARAMETER token
The OAuth token used to authenticate to the Slack API.
.PARAMETER channelId
The ID of the channel to archive.
.EXAMPLE
Remove-SlackChannel -token "your-oauth-token" -channelId "C12345678"
#>
function Remove-SlackChannel {
    param(
        [string]$token,
        [string]$channelId
    )
    $url = "https://slack.com/api/conversations.archive"
    $headers = @{
        Authorization = "Bearer $token"
    }
    $body = @{
        channel = $channelId
    }
    $response = Invoke-RestMethod -Uri $url -Headers $headers -Method Post -Body ($body | ConvertTo-Json)
    return $response
}

<#
.SYNOPSIS
Sends a message to a Slack channel.
.DESCRIPTION
This function sends a message to a specified Slack channel using the Slack API.
.PARAMETER token
The OAuth token used to authenticate to the Slack API.
.PARAMETER channelId
The ID of the channel where the message will be sent.
.PARAMETER message
The message text to send to the channel.
.EXAMPLE
Send-SlackMessage -token "your-oauth-token" -channelId "C12345678" -message "Hello, Slack!"
#>
function Send-SlackMessage {
    param(
        [string]$token,
        [string]$channelId,
        [string]$message
    )
    $url = "https://slack.com/api/chat.postMessage"
    $headers = @{
        Authorization = "Bearer $token"
    }
    $body = @{
        channel = $channelId
        text    = $message
    }

    try {
        $response = Invoke-RestMethod -Uri $url -Headers $headers -Method Post -Body ($body | ConvertTo-Json) -ContentType "application/json"

        if ($response.ok -eq $false) {
            Write-Host "Error: $($response.error)"
            return $response.error
        } else {
            Write-Host "Message sent successfully to channel: $($channelId)"
            return $response
        }
    }
    catch {
        Write-Host "An error occurred: $_"
    }
}


<#
.SYNOPSIS
Adds a user to a Slack channel.
.DESCRIPTION
This function adds a specified user to a Slack channel using the Slack API.
.PARAMETER token
The OAuth token used to authenticate to the Slack API.
.PARAMETER channelId
The ID of the channel where the user will be added.
.PARAMETER userId
The ID of the user to add to the channel.
.EXAMPLE
Add-SlackChannelMember -token "your-oauth-token" -channelId "C12345678" -userId "U12345678"
#>
function Add-SlackChannelMember {
    param(
        [string]$token,
        [string]$channelId,
        [string]$userId
    )
    $url = "https://slack.com/api/conversations.invite"
    $headers = @{
        Authorization = "Bearer $token"
    }
    $body = @{
        channel = $channelId
        users   = $userId  # 'users' expects a comma-separated string of user IDs
    }

    try {
        $response = Invoke-RestMethod -Uri $url -Headers $headers -Method Post -Body ($body | ConvertTo-Json) -ContentType "application/json"

        if ($response.ok -eq $false) {
            Write-Host "Error: $($response.error)"
            return $response.error
        } else {
            Write-Host "User(s) added successfully to the channel: $($channelId)"
            return $response
        }
    }
    catch {
        Write-Host "An error occurred: $_"
    }
}


<#
.SYNOPSIS
Removes a user from a Slack channel.
.DESCRIPTION
This function removes a specified user from a Slack channel using the Slack API.
.PARAMETER token
The OAuth token used to authenticate to the Slack API.
.PARAMETER channelId
The ID of the channel where the user will be removed.
.PARAMETER userId
The ID of the user to remove from the channel.
.EXAMPLE
Remove-SlackChannelMember -token "your-oauth-token" -channelId "C12345678" -userId "U12345678"
#>
function Remove-SlackChannelMember {
    param(
        [string]$token,
        [string]$channelId,
        [string]$userId
    )
    $url = "https://slack.com/api/conversations.kick"
    $headers = @{
        Authorization = "Bearer $token"
    }
    $body = @{
        channel = $channelId
        user    = $userId
    }
    $response = Invoke-RestMethod -Uri $url -Headers $headers -Method Post -Body ($body | ConvertTo-Json)
    return $response
}

<#
.SYNOPSIS
Gets the members of a Slack channel.
.DESCRIPTION
This function retrieves a list of member IDs for a specified Slack channel.
.PARAMETER token
The OAuth token used to authenticate to the Slack API.
.PARAMETER channelId
The ID of the channel whose members are to be retrieved.
.EXAMPLE
$members = Get-SlackChannelMembers -token "your-oauth-token" -channelId "C12345678"
#>
function Get-SlackChannelMembers {
    param(
        [string]$token,
        [string]$channelId
    )
    $url = "https://slack.com/api/conversations.members?channel=$channelId"
    $headers = @{
        Authorization = "Bearer $token"
    }

    try {
        $response = Invoke-RestMethod -Uri $url -Headers $headers -Method Get

        if ($response.ok -eq $false) {
            Write-Host "Error: $($response.error)"
            return $response.error
        } else {
            return $response.members
        }
    }
    catch {
        Write-Host "An error occurred: $_"
    }
}


<#
.SYNOPSIS
Retrieves all members in the Slack workspace.
.DESCRIPTION
This function retrieves a list of all users in the Slack workspace using the Slack API.
.PARAMETER token
The OAuth token used to authenticate to the Slack API.
.EXAMPLE
$allMembers = Get-AllSlackMembers -token "your-oauth-token"
#>
function Get-AllSlackMembers {
    param(
        [string]$token
    )
    $url = "https://slack.com/api/users.list"
    $headers = @{
        Authorization = "Bearer $token"
    }
    $response = Invoke-RestMethod -Uri $url -Headers $headers -Method Get
    return $response.members
}

<#
.SYNOPSIS
Gets the ID of a Slack channel by name.
.DESCRIPTION
This function retrieves the ID of a Slack channel by its name using the Slack API.
.PARAMETER token
The OAuth token used to authenticate to the Slack API.
.PARAMETER channelName
The name of the channel whose ID is to be retrieved.
.EXAMPLE
$channelId = Get-ChannelId -token "your-oauth-token" -channelName "general"
#>
function Get-SlackChannelId {
    param(
        [string]$token,
        [string]$channelName
    )
    $channels = Get-SlackChannel -token $token
    $channel = $channels | Where-Object { $_.name -eq $channelName }
    return $channel.id
}

<#
.SYNOPSIS
Gets the ID of a Slack user by name.
.DESCRIPTION
This function retrieves the ID of a Slack user by their username or real name using the Slack API.
.PARAMETER token
The OAuth token used to authenticate to the Slack API.
.PARAMETER userName
The username or real name of the user whose ID is to be retrieved.
.EXAMPLE
$userId = Get-UserId -token "your-oauth-token" -userName "john.doe"
#>
function Get-SlackUserId {
    param(
        [string]$token,
        [string]$userName
    )
    $users = Get-AllSlackMembers -token $token
    $user = $users | Where-Object { $_.name -eq $userName -or $_.real_name -eq $userName }
    return $user.id
}

<#
.SYNOPSIS
Resolves the name of a Slack channel using its ID.
.DESCRIPTION
This function takes a Slack channel ID and returns the corresponding channel name. 
It retrieves the list of channels using the Slack API and searches for the specified channel ID.
.PARAMETER token
The OAuth token used to authenticate to the Slack API.
.PARAMETER channelId
The ID of the channel to resolve.
.EXAMPLE
$channelName = Resolve-ChannelIdToName -token "your-oauth-token" -channelId "C12345678"
Write-Host "Channel name: $channelName"
.NOTES
This function requires that the OAuth token has the necessary permissions to read channel information.
#>
function Resolve-SlackChannelIdToName {
    param(
        [string]$token,
        [string]$channelId
    )
    $channels = Get-SlackChannel -token $token
    $channel = $channels | Where-Object { $_.id -eq $channelId }

    if ($null -eq $channel) {
        Write-Host "Channel with ID $channelId not found."
        return $null
    } else {
        return $channel.name
    }
}


<#
.SYNOPSIS
Resolves the name of a Slack user using their ID.
.DESCRIPTION
This function takes a Slack user ID and returns the corresponding user's real name. 
It retrieves the list of users using the Slack API and searches for the specified user ID.
.PARAMETER token
The OAuth token used to authenticate to the Slack API.
.PARAMETER userId
The ID of the user to resolve.
.EXAMPLE
$userName = Resolve-UserIdToName -token "your-oauth-token" -userId "U12345678"
Write-Host "User name: $userName"
.NOTES
This function requires that the OAuth token has the necessary permissions to read user information.
#>
function Resolve-SlackUserIdToName {
    param(
        [string]$token,
        [string]$userId
    )
    $users = Get-AllSlackMembers -token $token
    $user = $users | Where-Object { $_.id -eq $userId }

    if ($null -eq $user) {
        Write-Host "User with ID $userId not found."
        return $null
    } else {
        return $user.real_name  # Możesz użyć .name, jeśli chcesz uzyskać nazwę użytkownika (username)
    }
}



Export-ModuleMember -Function *-Slack*
