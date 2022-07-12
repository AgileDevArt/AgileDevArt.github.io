###################
# .NET Framework
###################
Add-Type -AssemblyName PresentationFramework | Out-Null
Add-Type -AssemblyName System.Windows.Forms | Out-Null

###################
# Constants
###################
$xamlFile = "https://agiledevart.github.io/MainWindow.xaml"
$urlBase = "https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=100&sparkline=false&page={0}"

###################
# DataSource
###################
function Load-Page {
    $url = $urlBase -f $viewModel.page
    $response = Invoke-RestMethod -Uri $url -Method Get -Headers $headers –UseDefaultCredentials 
    $viewModel.source = $response
}

function Refresh-View {
    $coinGrid.ItemsSource = $viewModel.source
    $lblPage.Content="Page: " + $viewModel.page
}

###################
# View Model
###################
$viewModel = @{ 
    'page' = 1;
    'working' = $false; 
    'reset'= $false;
    'source' = $null;
}

###################
# initial request
###################
$headers = @{ 'accept' = 'application/json' }
Load-Page

do{
    $viewModel.reset = $false
    ###################
    # WPF form
    ###################
    [xml]$xaml = (New-Object System.Net.WebClient).DownloadString($xamlFile) -replace 'x:Name','Name'
    $xaml.Window.RemoveAttribute('x:Class')
    $xaml.Window.RemoveAttribute('mc:Ignorable')
    $xaml.SelectNodes("//*") | ForEach-Object {
        $_.RemoveAttribute('d:LayoutOverrides')
    }

    $reader=(New-Object System.Xml.XmlNodeReader $xaml) 
    try {
        $Form=[Windows.Markup.XamlReader]::Load( $reader )
        $xaml.SelectNodes("//*[@Name]") | ForEach-Object {Set-Variable -Name ($_.Name) -Value $Form.FindName($_.Name)}
    }
    catch {
        Write-Host "Unable to load Windows.Markup.XamlReader"; 
        exit
    }

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

    $btnAbout.add_click({
        $bitness = ("32-bit","64-bit")[[System.IntPtr]::Size -eq 8]
        $framework = [System.Runtime.InteropServices.RuntimeInformation, mscorlib]::FrameworkDescription
        $about = [String]::Join([System.Environment]::NewLine,
           "WPF Powershell Example",
           [String]::Empty,
           "Author:    AgileDevArt",
           "Process:   " + $bitness,
           "Platform:  " + $framework)

        [System.Windows.Forms.MessageBox]::Show($about, "About", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    })

    $coinGrid.Add_KeyDown({
        Write-Host $_.Key
        if ($viewModel.working -eq $false -And $_.Key -eq 'F12'){
            $viewModel.reset = $true
            $Form.Close()
        }
        elseif ($viewModel.working -eq $false -And $_.Key -eq 'Escape'){
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
