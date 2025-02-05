### Start of Function to check the Logins###
Function Login-check
{
    try
    {
        Get-MgContext -ErrorAction Continue
    } catch
    {
        Write-Error "Not connected to Microsoft Graph. Attempting to connect..."
        Import-Module Microsoft.Graph.Beta.Applications
        Connect-MgGraph -Scopes "Application.Read.All", "Directory.Read.All" -NoWelcome
    }
    Write-Host -ForegroundColor Cyan "User logged into Microsoft Graph"
}

### Start of core Script###
Login-check
$Apps = Get-MgBetaApplication -Filter "onPremisesPublishing ne null" -Select "DisplayName, Id, OnPremisesPublishing"
$i = 1
$Appproxy_List = @()
$count = $Apps.count
Foreach ($app in $Apps)
{
    Write-Progress -Activity "Getting $($app.DisplayName) App-proxy information" -Status "$i of $count" -PercentComplete ($i/$count*100)
    try
    {
        $result = [PSCustomObject]@{
            DisplayName = $app.DisplayName
            ObjectId = $app.Id
            InternalUrl = $app.OnPremisesPublishing.InternalUrl 
            ExternalUrl = $app.OnPremisesPublishing.ExternalUrl 
        }
        $Appproxy_List += $result
    } catch
    {
        $Problem = $_.Exception.Message
        Write-Error "Error processing $($app.DisplayName): $Problem"
    }
    $i++
}

### Output ###
if ($Appproxy_List.Count -gt 0)
{
    $Appproxy_List | Format-Table
    $Filepath = Join-Path (Get-Location) ("App-proxy_Application_List_" + (Get-Date -Format "dd-MM-yyyy_HH.mm.ss") + ".csv")
    $Appproxy_List | Export-Csv -Path $Filepath -NoTypeInformation
    Write-Host "Output saved to $($FilePath)"
} else
{
    Write-Host "No Application Proxy applications with URLs found."
}

