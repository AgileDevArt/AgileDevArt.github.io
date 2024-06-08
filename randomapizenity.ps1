# Define global variables
$global:COUNT = 0
$global:ROW = $null

function Get-About {
$path = $PSCommandPath.Replace("\", "/")
$message = (Invoke-RestMethod -Uri 'https://random-data-api.com/api/hipster/random_hipster_stuff').sentence
$shortMessage = $message.Substring(0, [Math]::Min($message.Length, 80)).PadRight(80)
"Zenity:       $(zenity --version)
Platform:    $([System.Environment]::OSVersion.VersionString)
Path:          $path

Message:   $shortMessage"
}

function Get-UserCount {
    $count = zenity --entry --title="Random API Example" --text="$(Get-About)`n`nPlease enter a number of users greater than 1:"
    if ($count -eq $null) {
        exit 1
	} elseif ($count -match '^[0-9]+$' -and [int]$count -gt 1) {
        $global:COUNT = [int]$count
    } else {
		Write-Output $count
        zenity --error --title="Error" --text="Invalid input `"$count`". Please enter a number of users greater than 1." --width=400 --height=80
        Get-UserCount # Prompt again recursively
    }
}

function Get-Progress-Dialog {
	$startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = "zenity"
    $startInfo.Arguments = "--progress --title=Initializing --percentage=0 --auto-close --width=500"
    $startInfo.RedirectStandardInput = $true
    $startInfo.UseShellExecute = $false
	
    $progress = New-Object System.Diagnostics.Process
    $progress.StartInfo = $startInfo
    $progress.Start() | Out-Null
	$progress
}

function Get-UserRow {
	$runspaces = @()	
	$response = Invoke-RestMethod -Uri "https://random-data-api.com/api/v2/users?size=$global:COUNT"
    if ($response -eq $null -or $response -eq "") {
        zenity --error --title="Error" --text="Could not get server response." --width=400 --height=80
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
	
    $completed = 0
    $total = $runspaces.Count
    
    $progress = Get-Progress-Dialog
    $progressInput = $progress.StandardInput

    # Wait for all runspaces to complete and collect results
    $user = $runspaces | ForEach-Object {
        $user = $_.Pipe.EndInvoke($_.Status)
        $_.Pipe.Dispose()	
        Write-Output $user.Icon $user.Id $user.Name $user.Phone $user.Email
        $completed++  
		$fileName = Split-Path -Path $user.Icon -Leaf
        Write-Output "# $fileName $completed / $total" | ForEach-Object {
			$completionPercentage = ($completed / $total) * 100
			$progressInput.WriteLine($_)
			$progressInput.WriteLine($completionPercentage)
			if ($completionPercentage -eq 100) {
			    $progressInput.Close()
			}
			if ($progress.HasExited -and $process.ExitCode -ne 0) {
				exit 1
			}
        }
    } | zenity --list --title="Users" `
        --ok-label=OK `
        --cancel-label=Close `
        --column="Icon" `
        --column="Id" `
        --column="Name" `
        --column="Phone" `
        --column="Email" `
        --hide-column=4,5 `
        --imagelist `
        --print-column="ALL" `
		--mid-search `
        --width=300 `
        --height=400
	
    $progressInput.Close()
    $progress.WaitForExit()

	if ($user -eq $null -or $user -eq "") {
        exit 1
    } else {
		$properties = $user.Split('|')
        $global:ROW = [PSCustomObject]@{
            Icon  = $properties[0]
            Id    = $properties[1]
            Name  = $properties[2]
            Phone = $properties[3]
            Email = $properties[4]
        }
    }
}

function Show-UserDetail {
    $avatarPath = $global:ROW.Icon
    [void](Invoke-WebRequest -Uri "https://robohash.org/$($avatarPath -split '/' | Select-Object -Last 1)?size=200x200" -OutFile $avatarPath)
    
    $detail = Start-Job -ScriptBlock {
        param($id, $name, $email, $phone)
"ID:      $id
Name:    $name
Email:   $email
Phone:   $phone" | zenity --text-info --title="User Detail" `
        --font="courier" `
        --width=420 `
        --height=160 
    } -ArgumentList $global:ROW.Id, $global:ROW.Name, $global:ROW.Email, $global:ROW.Phone
    
    $avatar = Start-Job -ScriptBlock {
        param($icon)
        $icon | zenity --list --title="Avatar" `
            --ok-label=OK `
            --cancel-label=Close `
            --column="Icon" `
            --hide-header `
            --imagelist `
            --print-column="ALL" `
            --width=300 `
            --height=300
    } -ArgumentList $global:ROW.Icon
    
    Receive-Job -Job $detail -Wait | Out-Null 
    Receive-Job -Job $avatar -Wait | Out-Null
}

# Main script execution
Get-UserCount
Get-UserRow
Show-UserDetail
