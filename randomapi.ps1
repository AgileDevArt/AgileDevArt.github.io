# Define global variables
$global:COUNT = 0
$global:ROW = $null

function Get-About {
    Write-Host "Random API Example"
    Write-Host ""
    Write-Host "Platform:  $([System.Environment]::OSVersion.VersionString)"
    Write-Host "Path:      $PSCommandPath"
    Write-Host ""
    
    $message = (Invoke-RestMethod -Uri 'https://random-data-api.com/api/hipster/random_hipster_stuff').sentence
    $shortMessage = $message.Substring(0, [Math]::Min($message.Length, 50))
    Write-Host "Message:   $shortMessage"
    Write-Host ""
}

function Get-UserCount {
    param (
        [string]$Prompt = "Please enter a number of users greater than 1"
    )
    
    $count = Read-Host $Prompt
    if ($count -match '^[0-9]+$' -and [int]$count -gt 1) {
        $global:COUNT = [int]$count
    } else {
        Get-UserCount -Prompt "Invalid input `"$count`". Please enter a number of users greater than 1" # Prompt again recursively
    }
}

function Get-UserRow {
	$runspaces = @()	
	$response = Invoke-RestMethod -Uri "https://random-data-api.com/api/v2/users?size=$global:COUNT"
    if ($response -eq $null -or $response -eq "") {
        Write-Host -NoNewline "`nCould not get server response.`n"
        exit 1
    }
    
    foreach ($user in $response) {
        $runspace = [powershell]::Create().AddScript({
            param($id, $name, $phone, $email, $avatar)
            $url = $avatar + "?size=32x32"
            $outputFile = "R:\$(Split-Path -Leaf $avatar)"
            [void](Invoke-WebRequest -Uri $url -OutFile $outputFile)
            [PSCustomObject]@{
                Icon  = $outputFile
                Id    = $id
                Name  = $name
                Phone = $phone
                Email = $email
            }
        })
        [void]($runspace.AddArgument($user.id))
        [void]($runspace.AddArgument("$($user.first_name) $($user.last_name)"))
        [void]($runspace.AddArgument($user.phone_number))
        [void]($runspace.AddArgument($user.email))
        [void]($runspace.AddArgument($user.avatar.Split('?')[0]))
        $runspaces += [PSCustomObject]@{ 
            Pipe = $runspace; 
            Status = $runspace.BeginInvoke() 
        }
    }
	
    $completedRunspaces = 0
    $totalRunspaces = $runspaces.Count
	
    # Wait for all runspaces to complete and collect results
    $userRows = foreach ($runspace in $runspaces) {
        $result = $runspace.Pipe.EndInvoke($runspace.Status)
        $runspace.Pipe.Dispose()
        $result
        $completedRunspaces++  
        Write-Host -NoNewline "`rLoading users: $completedRunspaces / $totalRunspaces"
    }
    
    $tableHeader = "{0,6}  {1,-50} {2,-10} {3,-25}" -f "", "Icon", "Id", "Name"
	Write-Host -NoNewline "`n`n$tableHeader`n"
    
    $userRows | ForEach-Object {
        $index = [array]::IndexOf($userRows, $_) + 1
        $tableRow = "{0,6}  {1,-50} {2,-10} {3,-25}" -f $index, $_.Icon, $_.Id, $_.Name
        Write-Host $tableRow
    }
    Write-Host ""

    $prompt = "Please enter a row number between 1 and $global:COUNT"
    while ($true) {
        $row = Read-Host $prompt
        if ($row -match '^[0-9]+$' -and [int]$row -ge 1 -and [int]$row -le $global:COUNT) {
            $global:ROW = $userRows[[int]$row - 1]
            break
        } else {
            $prompt = "Invalid input `"$row`". Please enter a row number between 1 and $global:COUNT"
        }
    }
}

function Show-UserDetail {
    $avatarPath = $global:ROW.Icon
    [void](Invoke-WebRequest -Uri "https://robohash.org/$($avatarPath -split '/' | Select-Object -Last 1)?size=200x200" -OutFile $avatarPath)
    
    Write-Host "
    User Detail:
    ------------
    Icon:    $($global:ROW.Icon)
    ID:      $($global:ROW.Id)
    Name:    $($global:ROW.Name)
    Email:   $($global:ROW.Email)
    Phone:   $($global:ROW.Phone)
    "
}

# Main script execution
Get-About
Get-UserCount
Get-UserRow
Show-UserDetail
