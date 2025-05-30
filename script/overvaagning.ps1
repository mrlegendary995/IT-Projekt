# Script: monitoring.ps1

# === File paths ===
$configPath = "C:\IT-Projekt\config\config.json"
$statePath  = "C:\IT-Projekt\config\state.json"
$logPath    = "C:\IT-Projekt\logs\overvaagning_log.csv"

# === Email settings ===
$gmailUser     = "latifcaliskan0701@gmail.com"
$gmailPass     = ConvertTo-SecureString "borw fklh mhgv bcqu" -AsPlainText -Force
$cred          = New-Object System.Management.Automation.PSCredential ($gmailUser, $gmailPass)
$smtpServer    = "smtp.gmail.com"
$smtpPort      = 587
$smtpUseSsl    = $true

# === Helper: write to console and output ===
function Write-Both {
    param([string]$text)
    Write-Output $text
    Write-Host   $text
}

# === Load JSON from file ===
function Load-JsonFile {
    param ($path)
    if (Test-Path $path) {
        return Get-Content $path | ConvertFrom-Json
    } else {
        return @()
    }
}

# === Log result to file ===
function Log-Result {
    param ($task, $status, $details, $error)
    $line = "$($task.id),$((Get-Date).ToString("s")),$($task.type),$($task.address),$status,""$details"",""$error"""
    Add-Content -Path $logPath -Value $line
}

# === Send error email ===
function Send-ErrorMail {
    param ($task, $details, $error)

    $body = @"
Task: $($task.id)
Type: $($task.type)
Address: $($task.address)
Timestamp: $(Get-Date)
Result: $details
Error: $error
"@

    try {
        Send-MailMessage -To $task.alertEmail -From $gmailUser `
            -Subject "Monitoring task failed: $($task.id)" `
            -Body $body `
            -SmtpServer $smtpServer `
            -Port $smtpPort `
            -UseSsl:$smtpUseSsl `
            -Credential $cred
        Write-Both "✅ Email sent to $($task.alertEmail)"
    } catch {
        Write-Both "❌ Email sending failed: $($_.Exception.Message)"
    }
}

# === Ping test ===
function Run-PingTest {
    param ($task)
    $address = $task.address
    $successCount = 0

    for ($i = 1; $i -le 10; $i++) {
        if (Test-Connection -ComputerName $address -Count 1 -Quiet -ErrorAction SilentlyContinue) {
            $successCount++
        }
    }

    $summary = "$successCount/10 OK"
    $status = if ($successCount -eq 10) { "success" } else { "fail" }

    Write-Both "Ping result for ${address}: $summary"
    Log-Result -task $task -status $status -details $summary -error ""

    if ($status -eq "fail") {
        Send-ErrorMail -task $task -details $summary -error "No response to ping"
    }
}

# === HTTP(S) test ===
function Run-HttpTest {
    param ($task)
    $address = $task.address
    $protocol = if ($address.StartsWith("https")) { "HTTPS" } else { "HTTP" }

    try {
        $response = Invoke-WebRequest -Uri $address -UseBasicParsing -TimeoutSec 5
        $statusCode = $response.StatusCode

        if ($statusCode -ge 200 -and $statusCode -lt 300) {
            Write-Both "$protocol result for ${address}: $statusCode OK"
            Log-Result -task $task -status "success" -details "$statusCode OK" -error ""
        } else {
            Write-Both "$protocol error for ${address}: $statusCode"
            Log-Result -task $task -status "fail" -details "$statusCode Error" -error "HTTP status not in 200-299"
            Send-ErrorMail -task $task -details "$statusCode Error" -error "HTTP status not in 200-299"
        }

    } catch {
        Write-Both "$protocol error for ${address}: $_"
        Log-Result -task $task -status "fail" -details "Request failed" -error $_.Exception.Message
        Send-ErrorMail -task $task -details "Request failed" -error $_.Exception.Message
    }
}

# === Load config and state ===
$config = Load-JsonFile $configPath
$state = @{}

if (Test-Path $statePath) {
    $rawState = Get-Content $statePath -Raw | ConvertFrom-Json
    foreach ($entry in $rawState.PSObject.Properties) {
        $state[$entry.Name] = $entry.Value
    }
}

# === Current time ===
$now = Get-Date

# === Process each task ===
foreach ($task in $config) {
    $taskId = $task.id
    $lastRun = if ($state[$taskId]) { Get-Date $state[$taskId] } else { [datetime]::MinValue }
    $minutesSinceLast = ($now - $lastRun).TotalMinutes

    if ($minutesSinceLast -ge $task.intervalMinutes) {
        Write-Both "`n▶ Running task: $($task.id)"

        if ($task.type -eq "ping") {
            Run-PingTest -task $task
        } elseif ($task.type -eq "http" -or $task.type -eq "https") {
            Run-HttpTest -task $task
        }

        $state[$taskId] = $now.ToString("o")
    } else {
        Write-Both "⏭ Skipping $($task.id) (only $([math]::Round($minutesSinceLast)) min since last run)"
    }
}

# === Save updated state ===
$state | ConvertTo-Json | Set-Content $statePath
