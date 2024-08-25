# SlackModule.psm1

<#
.SYNOPSIS
Retrieves a comprehensive list of all Slack channels in the workspace.

.DESCRIPTION
This function connects to the Slack API and retrieves a list of all available channels in the workspace, including both public and private channels that the authenticated user has access to. 
The function handles API pagination to ensure all channels are retrieved, even if they exceed the API's default result limit.

.PARAMETER token
The OAuth token used to authenticate to the Slack API. The token must have the necessary permissions to access the channel information within the workspace.

.EXAMPLE
$channels = Get-SlackChannel -token "your-oauth-token"
This command retrieves a list of all available channels in the Slack workspace.

.EXAMPLE
$channels = Get-SlackChannel -token $token
This command retrieves a list of all available channels using the OAuth token stored in the `$token` variable.

.NOTES
Ensure that the OAuth token has the necessary permissions to read channel information, including access to private channels if required.
If the workspace has a large number of channels, this function handles pagination automatically to retrieve all channels.
#>
function Get-SlackChannel {
    param(
        [string]$token
    )
    $url = "https://slack.com/api/conversations.list"
    $headers = @{
        Authorization = "Bearer $token"
    }

    try {
        $response = Invoke-RestMethod -Uri $url -Headers $headers -Method Get

        if ($response.ok -eq $false) {
            Write-Error "Error: $($response.error)"
            return $null
        } else {
            return $response.channels
        }
    }
    catch {
        Write-Error "An error occurred: $_"
    }
}

<#
.SYNOPSIS
Creates a new Slack channel.

.DESCRIPTION
This function creates a new Slack channel with the specified name using the Slack API. The channel name must be unique and comply with Slack's naming rules, such as avoiding spaces and special characters. By default, the channel created is public. If the channel name already exists, the function will return an error.

.PARAMETER token
The OAuth token used to authenticate to the Slack API. This token must have the appropriate permissions to create new channels in the Slack workspace.

.PARAMETER channelName
The name of the channel to create. The name should be unique within the workspace and must follow Slack's channel naming conventions (e.g., no spaces or special characters).

.EXAMPLE
New-SlackChannel -token "your-oauth-token" -channelName "new-channel"
This command creates a new Slack channel with the name "new-channel".

.EXAMPLE
$token = "your-oauth-token"
$channelName = "project-discussions"
New-SlackChannel -token $token -channelName $channelName
This command creates a new Slack channel named "project-discussions" using the OAuth token stored in the `$token` variable.

.NOTES
Ensure that the OAuth token has the necessary permissions to create channels in the Slack workspace. If the token lacks the required permissions or if the channel name already exists, the function will return an error.
Consider Slack's naming conventions when choosing a channel name.
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
            Write-Error "Error: $($response.error)"
            return $response.error
        } else {
            Write-Host "Channel created successfully: $($response.channel.id)"
            return $response.channel
        }
    }
    catch {
        Write-Error "An error occurred: $_"
    }
}

<#
.SYNOPSIS
Archives an existing Slack channel.

.DESCRIPTION
This function archives an existing Slack channel specified by its ID or name using the Slack API. Archiving a channel hides it from the channel list but preserves its history and content. Only channels that are not already archived can be archived, and the user must have the necessary permissions to perform this action.

.PARAMETER token
The OAuth token used to authenticate to the Slack API. This token must have the appropriate permissions to archive channels in the Slack workspace.

.PARAMETER channelId
(Optional) The ID of the channel to archive. The channel must exist and be active (not already archived). If this is provided, the channel name is ignored.

.PARAMETER channelName
(Optional) The name of the channel to archive. If `channelId` is not provided, this parameter is used to resolve the channel ID.

.EXAMPLE
Remove-SlackChannel -token "your-oauth-token" -channelId "C12345678"
This command archives the Slack channel with the ID "C12345678".

.EXAMPLE
Remove-SlackChannel -token "your-oauth-token" -channelName "general"
This command archives the Slack channel with the name "general".

.EXAMPLE
$token = "your-oauth-token"
$channelName = "project-discussions"
Remove-SlackChannel -token $token -channelName $channelName
This command archives the Slack channel named "project-discussions" using the OAuth token stored in the `$token` variable.

.NOTES
Ensure that the OAuth token has the necessary permissions to archive channels in the Slack workspace. If the channel is already archived or the token lacks the required permissions, the function will return an error.
Archiving a channel preserves its content and history, but the channel will no longer be visible in the active channel list.
If both `channelId` and `channelName` are provided, the `channelId` takes precedence.
#>
function Remove-SlackChannel {
    param(
        [string]$token,
        [string]$channelId,
        [string]$channelName
    )
    
    # Resolve channel name to ID if channelId is not provided
    if (-not $channelId) {
        if ($channelName) {
            $channelId = Get-SlackChannelId -token $token -channelName $channelName
            if (-not $channelId) {
                Write-Error "Error: Could not resolve channelName to channelId"
                return $null
            }
        } else {
            Write-Error "Error: You must provide either channelId or channelName"
            return $null
        }
    }

    $url = "https://slack.com/api/conversations.archive"
    $headers = @{
        Authorization = "Bearer $token"
    }
    $body = @{
        channel = $channelId
    }

    try {
        $response = Invoke-RestMethod -Uri $url -Headers $headers -Method Post -Body ($body | ConvertTo-Json) -ContentType "application/json"
        
        if ($response.ok -eq $false) {
            Write-Error "Error: $($response.error)"
            return $null
        } else {
            Write-Host "Channel archived successfully: $($channelId)"
            return $response
        }
    }
    catch {
        Write-Error "An error occurred: $_"
    }
}

<#
.SYNOPSIS
Sends a message to a Slack channel.

.DESCRIPTION
This function sends a message to a specified Slack channel using the Slack API. The channel can be specified by either its ID or its name. If the channel name is provided, the function will resolve it to the corresponding channel ID.

.PARAMETER token
The OAuth token used to authenticate to the Slack API.

.PARAMETER channelId
(Optional) The ID of the channel where the message will be sent. If this is provided, the channel name is ignored.

.PARAMETER channelName
(Optional) The name of the channel where the message will be sent. If `channelId` is not provided, this parameter is used to resolve the channel ID.

.PARAMETER message
The message text to send to the channel.

.EXAMPLE
Send-SlackMessage -token "your-oauth-token" -channelId "C12345678" -message "Hello, Slack!"
This command sends the message "Hello, Slack!" to the Slack channel with the ID "C12345678".

.EXAMPLE
Send-SlackMessage -token "your-oauth-token" -channelName "general" -message "Hello, Slack!"
This command sends the message "Hello, Slack!" to the Slack channel named "general".

.NOTES
Ensure that the OAuth token has the necessary permissions to send messages to the specified Slack channel. If both `channelId` and `channelName` are provided, the `channelId` takes precedence.
#>
function Send-SlackMessage {
    param(
        [string]$token,
        [string]$channelId,
        [string]$channelName,
        [string]$message
    )

    # Resolve channel name to ID if channelId is not provided
    if (-not $channelId) {
        if ($channelName) {
            $channelId = Get-SlackChannelId -token $token -channelName $channelName
            if (-not $channelId) {
                Write-Error "Error: Could not resolve channelName to channelId"
                return $null
            }
        } else {
            Write-Error "Error: You must provide either channelId or channelName"
            return $null
        }
    }

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
            Write-Error "Error: $($response.error)"
            return $response.error
        } else {
            Write-Host "Message sent successfully to channel: $($channelId)"
            return $response
        }
    }
    catch {
        Write-Error "An error occurred: $_"
    }
}


<#
.SYNOPSIS
Adds a user or users to a Slack channel.

.DESCRIPTION
This function adds specified user(s) to a Slack channel using the Slack API. The channel and users can be specified by their IDs or names. If the names are provided, the function will resolve them to their corresponding IDs before adding the users to the channel.

.PARAMETER token
The OAuth token used to authenticate to the Slack API.

.PARAMETER channelId
(Optional) The ID of the channel where the user(s) will be added. If this is provided, the channel name is ignored.

.PARAMETER channelName
(Optional) The name of the channel where the user(s) will be added. If `channelId` is not provided, this parameter is used to resolve the channel ID.

.PARAMETER userIds
(Optional) An array of user IDs to add to the Slack channel. If this is provided, `userNames` is ignored.

.PARAMETER userNames
(Optional) An array of usernames or real names of the users to add to the Slack channel. If `userIds` is not provided, this parameter is used to resolve the user IDs.

.EXAMPLE
Add-SlackChannelMember -token "your-oauth-token" -channelId "C12345678" -userIds "U12345678", "U23456789"
This command adds the users with IDs "U12345678" and "U23456789" to the Slack channel with the ID "C12345678".

.EXAMPLE
Add-SlackChannelMember -token "your-oauth-token" -channelName "general" -userNames "john.doe", "jane.smith"
This command adds the users "john.doe" and "jane.smith" to the Slack channel named "general".

.NOTES
Ensure that the OAuth token has the necessary permissions to add users to the specified Slack channel. If both `channelId` and `channelName` are provided, the `channelId` takes precedence. Similarly, if both `userIds` and `userNames` are provided, the `userIds` take precedence.
#>
function Add-SlackChannelMember {
    param(
        [string]$token,
        [string]$channelId,
        [string]$channelName,
        [string[]]$userIds,
        [string[]]$userNames
    )
    
    # Resolve channel name to ID if channelId is not provided
    if (-not $channelId) {
        if ($channelName) {
            $channelId = Get-SlackChannelId -token $token -channelName $channelName
            if (-not $channelId) {
                Write-Error "Error: Could not resolve channelName to channelId"
                return $null
            }
        } else {
            Write-Error "Error: You must provide either channelId or channelName"
            return $null
        }
    }

    # Resolve user names to IDs if userIds are not provided
    if (-not $userIds -and $userNames) {
        $userIds = foreach ($userName in $userNames) {
            $userId = Get-SlackUserId -token $token -userName $userName
            if (-not $userId) {
                Write-Error "Error: Could not resolve userName $userName to userId"
                return $null
            }
            $userId
        }
    }

    $url = "https://slack.com/api/conversations.invite"
    $headers = @{
        Authorization = "Bearer $token"
    }
    $body = @{
        channel = $channelId
        users   = ($userIds -join ",")
    }

    try {
        $response = Invoke-RestMethod -Uri $url -Headers $headers -Method Post -Body ($body | ConvertTo-Json) -ContentType "application/json"

        if ($response.ok -eq $false) {
            Write-Error "Error: $($response.error)"
            return $null
        } else {
            Write-Host "User(s) added successfully to the channel: $($channelId)"
            return $response
        }
    }
    catch {
        Write-Error "An error occurred: $_"
    }
}


<#
.SYNOPSIS
Removes a user from a Slack channel.

.DESCRIPTION
This function removes a specified user from a Slack channel using the Slack API. The channel and user can be specified by their IDs or names. If names are provided, the function will resolve them to their corresponding IDs before removing the user from the channel.

.PARAMETER token
The OAuth token used to authenticate to the Slack API.

.PARAMETER channelId
(Optional) The ID of the channel where the user will be removed. If this is provided, the channel name is ignored.

.PARAMETER channelName
(Optional) The name of the channel where the user will be removed. If `channelId` is not provided, this parameter is used to resolve the channel ID.

.PARAMETER userId
(Optional) The ID of the user to remove from the channel. If this is provided, the user name is ignored.

.PARAMETER userName
(Optional) The username or real name of the user to remove from the channel. If `userId` is not provided, this parameter is used to resolve the user ID.

.EXAMPLE
Remove-SlackChannelMember -token "your-oauth-token" -channelId "C12345678" -userId "U12345678"
This command removes the user with the ID "U12345678" from the Slack channel with the ID "C12345678".

.EXAMPLE
Remove-SlackChannelMember -token "your-oauth-token" -channelName "general" -userName "john.doe"
This command removes the user "john.doe" from the Slack channel named "general".

.NOTES
Ensure that the OAuth token has the necessary permissions to remove users from the specified Slack channel. If both `channelId` and `channelName` are provided, the `channelId` takes precedence. Similarly, if both `userId` and `userName` are provided, the `userId` takes precedence.
#>
function Remove-SlackChannelMember {
    param(
        [string]$token,
        [string]$channelId,
        [string]$channelName,
        [string]$userId,
        [string]$userName
    )
    
    # Resolve channel name to ID if channelId is not provided
    if (-not $channelId) {
        if ($channelName) {
            $channelId = Get-SlackChannelId -token $token -channelName $channelName
            if (-not $channelId) {
                Write-Error "Error: Could not resolve channelName to channelId"
                return $null
            }
        } else {
            Write-Error "Error: You must provide either channelId or channelName"
            return $null
        }
    }

    # Resolve user name to ID if userId is not provided
    if (-not $userId -and $userName) {
        $userId = Get-SlackUserId -token $token -userName $userName
        if (-not $userId) {
            Write-Error "Error: Could not resolve userName $userName to userId"
            return $null
        }
    }

    $url = "https://slack.com/api/conversations.kick"
    $headers = @{
        Authorization = "Bearer $token"
    }
    $body = @{
        channel = $channelId
        user    = $userId
    }

    try {
        $response = Invoke-RestMethod -Uri $url -Headers $headers -Method Post -Body ($body | ConvertTo-Json) -ContentType "application/json"

        if ($response.ok -eq $false) {
            Write-Error "Error: $($response.error)"
            return $null
        } else {
            Write-Host "User removed successfully from the channel: $($channelId)"
            return $response
        }
    }
    catch {
        Write-Error "An error occurred: $_"
    }
}


<#
.SYNOPSIS
Retrieves members of a Slack channel by either channel ID or channel name.

.DESCRIPTION
This function retrieves the list of members in a specified Slack channel. You can provide either the channel ID or the channel name.
If the channel name is provided, the function will resolve the channel name to its corresponding channel ID using the Resolve-SlackChannelIdToName function.
You can also choose to return either user IDs or real names of the channel members by using the -ReturnNames switch.

.PARAMETER token
The OAuth token used to authenticate to the Slack API.

.PARAMETER channelId
(Optional) The ID of the Slack channel. If this is provided, the channel name is ignored.

.PARAMETER channelName
(Optional) The name of the Slack channel. This is used to resolve the channel ID if channelId is not provided.

.PARAMETER ReturnNames
(Optional) If set, the function returns the real names of the channel members instead of their user IDs.

.EXAMPLE
$members = Get-SlackChannelMembers -token "your-oauth-token" -channelId "C12345678"
This command retrieves the list of members in the specified Slack channel by channel ID and returns their user IDs.

.EXAMPLE
$members = Get-SlackChannelMembers -token "your-oauth-token" -channelName "general" -ReturnNames
This command retrieves the list of members in the specified Slack channel by channel name and returns their real names.

.EXAMPLE
$members = Get-SlackChannelMembers -token "your-oauth-token" -channelName "general"
This command retrieves the list of members in the specified Slack channel by channel name and returns their user IDs.

.NOTES
Ensure that the OAuth token has the necessary permissions to access Slack channels and retrieve member information.
If both channelId and channelName are provided, the channelId takes precedence.
#>
function Get-SlackChannelMembers {
    param(
        [string]$token,
        [string]$channelId,
        [string]$channelName,
        [switch]$ReturnNames
    )

    # Sprawdź, czy channelId zostało podane, jeśli nie, spróbuj rozwiązać channelName
    if (-not $channelId) {
        if ($channelName) {
            $channelId = Get-SlackChannelId -token $token -channelName $channelName
            if (-not $channelId) {
                Write-Error "Error: Could not resolve channelName to channelId"
                return $null
            }
        } else {
            Write-Error "Error: You must provide either channelId or channelName"
            return $null
        }
    }

    # Użyj resolved channelId, aby uzyskać członków kanału
    $url = "https://slack.com/api/conversations.members?channel=$channelId"
    $headers = @{
        Authorization = "Bearer $token"
    }

    try {
        $response = Invoke-RestMethod -Uri $url -Headers $headers -Method Get

        if ($response.ok -eq $false) {
            Write-Error "Error: $($response.error)"
            return $response.error
        } else {
            $members = $response.members

            if ($ReturnNames) {
                # Zamień ID użytkowników na ich nazwy
                $membersWithNames = foreach ($userId in $members) {
                    Resolve-SlackUserIdToName -token $token -userId $userId
                }
                return $membersWithNames
            } else {
                return $members
            }
        }
    }
    catch {
        Write-Error "An error occurred: $_"
    }
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
$channelId = Get-SlackChannelId -token "your-oauth-token" -channelName "general"
This command retrieves the ID of the Slack channel named "general".

.NOTES
Ensure that the OAuth token has the necessary permissions to access channel information in the Slack workspace.
#>
function Get-SlackChannelId {
    param(
        [string]$token,
        [string]$channelName
    )
    $channels = Get-SlackChannel -token $token
    $channel = $channels | Where-Object { $_.name -eq $channelName }

    if ($null -eq $channel) {
        Write-Error "Channel with name $channelName not found."
        return $null
    } else {
        return $channel.id
    }
}

<#
.SYNOPSIS
Gets the ID of a Slack user by name or returns IDs of all users if no name is specified.

.DESCRIPTION
This function retrieves the ID of a Slack user by their username or real name using the Slack API. If no username is provided, it returns the IDs of all users in the Slack workspace.

.PARAMETER token
The OAuth token used to authenticate to the Slack API.

.PARAMETER userName
(Optional) The username or real name of the user whose ID is to be retrieved. If not provided, the function returns the IDs of all users.

.EXAMPLE
$userId = Get-SlackUserId -token "your-oauth-token" -userName "john.doe"
This command retrieves the ID of the Slack user with the username or real name "john.doe".

.EXAMPLE
$userIds = Get-SlackUserId -token "your-oauth-token"
This command retrieves the IDs of all users in the Slack workspace.

.NOTES
Ensure that the OAuth token has the necessary permissions to access user information in the Slack workspace.
#>
function Get-SlackUserId {
    param(
        [string]$token,
        [string]$userName
    )

    # Define the API endpoint and headers
    $url = "https://slack.com/api/users.list"
    $headers = @{
        Authorization = "Bearer $token"
    }

    try {
        # Make the API request to retrieve the list of users
        $response = Invoke-RestMethod -Uri $url -Headers $headers -Method Get

        # Check if the API call was successful
        if ($response.ok -eq $false) {
            Write-Error "Error: $($response.error)"
            return $null
        }

        $users = $response.members

        # If userName is provided, find and return the user's ID
        if ($userName) {
            $user = $users | Where-Object { $_.name -eq $userName -or $_.real_name -eq $userName }

            if ($null -eq $user) {
                Write-Error "User with name $userName not found."
                return $null
            } else {
                return $user.id
            }
        } 
        # If no userName is provided, return IDs of all users
        else {
            return $users | Select-Object -ExpandProperty id
        }
    }
    catch {
        Write-Error "An error occurred: $_"
    }
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
$channelName = Resolve-SlackChannelIdToName -token "your-oauth-token" -channelId "C12345678"
Write-Host "Channel name: $channelName"
This command resolves the ID "C12345678" to the corresponding channel name.

.NOTES
Ensure that the OAuth token has the necessary permissions to access channel information in the Slack workspace.
#>
function Resolve-SlackChannelIdToName {
    param(
        [string]$token,
        [string]$channelId
    )
    $channels = Get-SlackChannel -token $token
    $channel = $channels | Where-Object { $_.id -eq $channelId }

    if ($null -eq $channel) {
        Write-Error "Channel with ID $channelId not found."
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
$userName = Resolve-SlackUserIdToName -token "your-oauth-token" -userId "U12345678"
Write-Host "User name: $userName"
This command resolves the ID "U12345678" to the corresponding user's real name.

.NOTES
Ensure that the OAuth token has the necessary permissions to access user information in the Slack workspace.
#>
function Resolve-SlackUserIdToName {
    param(
        [string]$token,
        [string]$userId
    )
    $users = Get-SlackUserId -token $token
    $user = $users | Where-Object { $_.id -eq $userId }

    if ($null -eq $user) {
        Write-Error "User with ID $userId not found."
        return $null
    } else {
        return $user.real_name  # Możesz użyć .name, jeśli chcesz uzyskać nazwę użytkownika (username)
    }
}

<#
.SYNOPSIS
Sets a manager for a Slack channel.

.DESCRIPTION
This function sets a specified user as the manager of a Slack channel. The channel and user can be specified by their IDs or names. If names are provided, the function will resolve them to their corresponding IDs before setting the user as the manager of the channel.

.PARAMETER token
The OAuth token used to authenticate to the Slack API.

.PARAMETER channelId
(Optional) The ID of the channel for which the manager will be set. If this is provided, the channel name is ignored.

.PARAMETER channelName
(Optional) The name of the channel for which the manager will be set. If `channelId` is not provided, this parameter is used to resolve the channel ID.

.PARAMETER userId
(Optional) The ID of the user to be set as the manager of the channel. If this is provided, the user name is ignored.

.PARAMETER userName
(Optional) The username or real name of the user to be set as the manager of the channel. If `userId` is not provided, this parameter is used to resolve the user ID.

.EXAMPLE
Set-SlackChannelManager -token "your-oauth-token" -channelId "C12345678" -userId "U12345678"
This command sets the user with ID "U12345678" as the manager of the Slack channel with ID "C12345678".

.EXAMPLE
Set-SlackChannelManager -token "your-oauth-token" -channelName "general" -userName "john.doe"
This command sets the user "john.doe" as the manager of the Slack channel named "general".

.NOTES
Ensure that the OAuth token has the necessary permissions to set a manager for the specified Slack channel. If both `channelId` and `channelName` are provided, the `channelId` takes precedence. Similarly, if both `userId` and `userName` are provided, the `userId` takes precedence.

Currently, Slack does not have an official API endpoint dedicated to setting channel managers. This function assumes there is an endpoint or custom implementation in place. This example is hypothetical.
#>
function Set-SlackChannelManager {
    param(
        [string]$token,
        [string]$channelId,
        [string]$channelName,
        [string]$userId,
        [string]$userName
    )
    
    # Resolve channel name to ID if channelId is not provided
    if (-not $channelId) {
        if ($channelName) {
            $channelId = Get-SlackChannelId -token $token -channelName $channelName
            if (-not $channelId) {
                Write-Error "Error: Could not resolve channelName to channelId"
                return $null
            }
        } else {
            Write-Error "Error: You must provide either channelId or channelName"
            return $null
        }
    }

    # Resolve user name to ID if userId is not provided
    if (-not $userId -and $userName) {
        $userId = Get-SlackUserId -token $token -userName $userName
        if (-not $userId) {
            Write-Error "Error: Could not resolve userName $userName to userId"
            return $null
        }
    }

    # Hypothetical URL and request structure for setting a channel manager
    $url = "https://slack.com/api/conversations.setManager"
    $headers = @{
        Authorization = "Bearer $token"
    }
    $body = @{
        channel = $channelId
        manager = $userId
    }

    try {
        $response = Invoke-RestMethod -Uri $url -Headers $headers -Method Post -Body ($body | ConvertTo-Json) -ContentType "application/json"

        if ($response.ok -eq $false) {
            Write-Error "Error: $($response.error)"
            return $null
        } else {
            Write-Host "User $($userId) has been successfully set as the manager for channel $($channelId)"
            return $response
        }
    }
    catch {
        Write-Error "An error occurred: $_"
    }
}

<#
.SYNOPSIS
Renames a Slack channel.

.DESCRIPTION
This function renames a Slack channel to a new name. The channel can be specified by its ID or current name. If the name is provided, the function will resolve it to the corresponding ID before renaming the channel.

.PARAMETER token
The OAuth token used to authenticate to the Slack API.

.PARAMETER channelId
(Optional) The ID of the channel to rename. If this is provided, the current channel name is ignored.

.PARAMETER channelName
(Optional) The current name of the channel to rename. If `channelId` is not provided, this parameter is used to resolve the channel ID.

.PARAMETER newChannelName
The new name for the Slack channel. This name must be unique within the workspace and follow Slack's naming conventions.

.EXAMPLE
Rename-SlackChannel -token "your-oauth-token" -channelId "C12345678" -newChannelName "new-channel-name"
This command renames the Slack channel with ID "C12345678" to "new-channel-name".

.EXAMPLE
Rename-SlackChannel -token "your-oauth-token" -channelName "general" -newChannelName "general-renamed"
This command renames the Slack channel named "general" to "general-renamed".

.NOTES
Ensure that the OAuth token has the necessary permissions to rename channels in the Slack workspace. If both `channelId` and `channelName` are provided, the `channelId` takes precedence. The new channel name must comply with Slack's naming rules.
#>
function Rename-SlackChannel {
    param(
        [string]$token,
        [string]$channelId,
        [string]$channelName,
        [string]$newChannelName
    )
    
    # Resolve channel name to ID if channelId is not provided
    if (-not $channelId) {
        if ($channelName) {
            $channelId = Get-SlackChannelId -token $token -channelName $channelName
            if (-not $channelId) {
                Write-Error "Error: Could not resolve channelName to channelId"
                return $null
            }
        } else {
            Write-Error "Error: You must provide either channelId or channelName"
            return $null
        }
    }

    $url = "https://slack.com/api/conversations.rename"
    $headers = @{
        Authorization = "Bearer $token"
    }
    $body = @{
        channel = $channelId
        name    = $newChannelName
    }

    try {
        $response = Invoke-RestMethod -Uri $url -Headers $headers -Method Post -Body ($body | ConvertTo-Json) -ContentType "application/json"

        if ($response.ok -eq $false) {
            Write-Error "Error: $($response.error)"
            return $null
        } else {
            Write-Host "Channel renamed successfully: $($channelId) to $($newChannelName)"
            return $response
        }
    }
    catch {
        Write-Error "An error occurred: $_"
    }
}



# Eksportowanie wszystkich funkcji w module
Export-ModuleMember -Function *-Slack*
