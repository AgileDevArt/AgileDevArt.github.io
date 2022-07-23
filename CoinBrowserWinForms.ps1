###################
# .NET Framework
###################
Add-Type -AssemblyName PresentationFramework | Out-Null
Add-Type -AssemblyName System.Windows.Forms | Out-Null

###################
# Constants
###################
$urlBase = "https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=100&sparkline=false&page={0}"

###################
# DataSource
###################
Class Coin
{
    [System.Drawing.Image]$Image
    [String]$Name
    [int]$Rank
    [double]$Price
    [double]$MarketCap
    [long]$CircSupply
}

function Load-Page {
    $url = $urlBase -f $viewModel.page
    $response = Invoke-RestMethod -Uri $url -Method Get -Headers $headers –UseDefaultCredentials 
    $viewModel.response = $response
}

function Refresh-View {
    $source = New-Object System.ComponentModel.BindingList[object]

    $viewModel.response | ForEach-Object{
        $coin = New-Object Coin
        $coin.Image = New-Object System.Drawing.Bitmap((New-Object System.Net.WebClient).OpenRead($_.image))
        $coin.Name = $_.name
        $coin.Rank = $_.market_cap_rank
        $coin.Price = $_.current_price
        $coin.MarketCap = $_.market_cap
        $coin.CircSupply = $_.circulating_supply
        $source.Add($coin)
    }

    $coinGrid.DataSource = $source
    $lblPage.Text="Page: " + $viewModel.page
}

###################
# View Model
###################
$viewModel = @{ 
    'back' = $null; 
    'page' = 1;
    'working' = $false; 
    'reset'= $false;
    'response' = $null;
}

###################
# initial request
###################
$headers = @{ 'accept' = 'application/json' }
Load-Page

do{
    $viewModel.reset = $false
    ###################
    # Winforms
    ###################
    #. $($PSScriptRoot +"\CoinBrowserForm.ps1")

    $Script = (New-Object System.Net.WebClient).DownloadString('https://agiledevart.github.io/CoinBrowserForm.ps1')
    $ScriptBlock = [Scriptblock]::Create($Script)
    Invoke-Command -ScriptBlock $ScriptBlock -NoNewScope

    ###################
    # events
    ###################
    $btnPrev.Add_Click({
        if ($viewModel.working -eq $false -And $viewModel.page -gt 1){
            $viewModel.working = $true

            $viewModel.page--
            Load-Page      
            Refresh-View
            $viewModel.working = $false
        }
    })

    $btnNext.Add_Click({
        if ($viewModel.working -eq $false -And $viewModel.page -lt 10){
            $viewModel.working = $true

            $viewModel.page++
            Load-Page
            Refresh-View
            $viewModel.working = $false
        }
    })

    $btnAbout.Add_click({
        $bitness = ("32-bit","64-bit")[[System.IntPtr]::Size -eq 8]
        $framework = [System.Runtime.InteropServices.RuntimeInformation, mscorlib]::FrameworkDescription
        $about = [String]::Join([System.Environment]::NewLine,
           "Winforms Powershell Example",
           [String]::Empty,
           "Author:    AgileDevArt",
           "Process:   " + $bitness,
           "Platform:  " + $framework)

        [System.Windows.Forms.MessageBox]::Show($about, "About", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    })

    $coinGrid.Add_KeyDown({
        Write-Host $_.KeyCode
        if ($viewModel.working -eq $false -And $_.KeyCode -eq [System.Windows.Forms.Keys]::F12){
            $viewModel.reset = $true
            $Form.Close()
        }
        elseif ($viewModel.working -eq $false -And $_.KeyCode -eq [System.Windows.Forms.Keys]::Escape){
            $viewModel.working = $true
        
            $viewModel.page = 1
            Load-Page
            Refresh-View
            $viewModel.working = $false
        }
    })

    Refresh-View
    ###################
    # show Form
    ###################
    $Form.ShowDialog() | Out-Null
}
while($viewModel.reset -eq $true)
