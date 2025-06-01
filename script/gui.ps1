Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# === Indlæs config ===
$configPath = "C:\IT-Projekt\config\config.json"
$config = Get-Content $configPath -Encoding UTF8 | ConvertFrom-Json

# === Funktion: Log resultat ===
function Log-Result {
    param ($taskId, $type, $address, $status, $details, $error)

    $logPath = "C:\IT-Projekt\logs\overvaagning_log.csv"
    if (-not (Test-Path $logPath)) {
        "TaskId,Tidspunkt,Type,Adresse,Status,Detaljer,Fejl" | Out-File -FilePath $logPath -Encoding UTF8
    }
    $line = "$taskId,$((Get-Date).ToString("s")),$type,$address,$status,""$details"",""$error"""
    Add-Content -Path $logPath -Value $line
}

# === GUI Setup ===
$form = New-Object Windows.Forms.Form
$form.Text = "Netværks- og HTTP Overvågning"
$form.Size = New-Object Drawing.Size(600,500)
$form.Font = New-Object Drawing.Font("Segoe UI", 10)
$form.BackColor = [System.Drawing.Color]::WhiteSmoke

$welcomeLabel = New-Object Windows.Forms.Label
$welcomeLabel.Location = New-Object Drawing.Point(10,10)
$welcomeLabel.Size = New-Object Drawing.Size(560,30)
$welcomeLabel.Font = New-Object Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$welcomeLabel.ForeColor = [System.Drawing.Color]::DarkSlateBlue
$welcomeLabel.Text = ":) Velkommen til Overvågningsværktøj :)"
$form.Controls.Add($welcomeLabel)

# Gruppe: Opgaver
$groupTasks = New-Object Windows.Forms.GroupBox
$groupTasks.Location = New-Object Drawing.Point(10,50)
$groupTasks.Size = New-Object Drawing.Size(560,140)
$groupTasks.Text = "Overvågningsopgaver"
$form.Controls.Add($groupTasks)

$listbox = New-Object Windows.Forms.ListBox
$listbox.Location = New-Object Drawing.Point(10,20)
$listbox.Size = New-Object Drawing.Size(540,100)
$listbox.Font = New-Object Drawing.Font("Segoe UI", 10)
foreach ($task in $config) {
    $listbox.Items.Add($task.id + " (" + $task.type + ")")
}
$groupTasks.Controls.Add($listbox)

# Gruppe: Resultat
$groupResult = New-Object Windows.Forms.GroupBox
$groupResult.Location = New-Object Drawing.Point(10,200)
$groupResult.Size = New-Object Drawing.Size(560,120)
$groupResult.Text = "Resultater"
$form.Controls.Add($groupResult)

$resultBox = New-Object Windows.Forms.TextBox
$resultBox.Location = New-Object Drawing.Point(10,20)
$resultBox.Size = New-Object Drawing.Size(540,80)
$resultBox.Multiline = $true
$resultBox.Font = New-Object Drawing.Font("Segoe UI", 10)
$groupResult.Controls.Add($resultBox)

$statusLabel = New-Object Windows.Forms.Label
$statusLabel.Location = New-Object Drawing.Point(10,430)
$statusLabel.Size = New-Object Drawing.Size(570,20)
$statusLabel.Text = "Status: Klar"
$form.Controls.Add($statusLabel)

# Knapper
$button = New-Object Windows.Forms.Button
$button.Location = New-Object Drawing.Point(10,330)
$button.Size = New-Object Drawing.Size(150,40)
$button.Text = "▶ Start Test"
$button.BackColor = [System.Drawing.Color]::LightGreen
$form.Controls.Add($button)

$editButton = New-Object Windows.Forms.Button
$editButton.Location = New-Object Drawing.Point(170,330)
$editButton.Size = New-Object Drawing.Size(150,40)
$editButton.Text = "Rediger Log"
$editButton.BackColor = [System.Drawing.Color]::LightSkyBlue
$form.Controls.Add($editButton)

# === Rediger Log korrekt ===
$editButton.Add_Click({
    $logPath = "C:\IT-Projekt\logs\overvaagning_log.csv"

    if (-not (Test-Path $logPath)) {
        [System.Windows.Forms.MessageBox]::Show("Logfil ikke fundet.","Fejl","OK","Error")
        return
    }

    $logForm = New-Object Windows.Forms.Form
    $logForm.Text = "Rediger Log"
    $logForm.Size = New-Object Drawing.Size(800, 600)
    $logForm.StartPosition = "CenterScreen"

    $searchBox = New-Object Windows.Forms.TextBox
    $searchBox.Location = New-Object Drawing.Point(10,10)
    $searchBox.Size = New-Object Drawing.Size(500,20)
    $logForm.Controls.Add($searchBox)

    $searchButton = New-Object Windows.Forms.Button
    $searchButton.Text = "Søg"
    $searchButton.Location = New-Object Drawing.Point(520,8)
    $searchButton.Size = New-Object Drawing.Size(60,24)
    $logForm.Controls.Add($searchButton)

    $logTextbox = New-Object Windows.Forms.RichTextBox
    $logTextbox.Location = New-Object Drawing.Point(10,40)
    $logTextbox.Size = New-Object Drawing.Size(760,460)
    $logTextbox.Font = New-Object Drawing.Font("Consolas", 10)
    $logTextbox.WordWrap = $false
    $logForm.Controls.Add($logTextbox)

    $global:logData = @()

    try {
        $global:logData = Import-Csv $logPath
        if ($global:logData.Count -eq 0) {
            $logTextbox.Text = "Logfilen er tom."
        } else {
            $formatted = $global:logData | Format-Table TaskId, Tidspunkt, Type, Adresse, Status, Detaljer -AutoSize | Out-String
            $logTextbox.Text = $formatted
        }
    } catch {
        $logTextbox.Text = "Fejl ved indlæsning af logfil.`n$_"
    }

    $saveButton = New-Object Windows.Forms.Button
    $saveButton.Text = "Gem"
    $saveButton.Location = New-Object Drawing.Point(10,510)
    $saveButton.Size = New-Object Drawing.Size(100,30)
    $logForm.Controls.Add($saveButton)

    $clearButton = New-Object Windows.Forms.Button
    $clearButton.Text = "Ryd"
    $clearButton.Location = New-Object Drawing.Point(120,510)
    $clearButton.Size = New-Object Drawing.Size(100,30)
    $logForm.Controls.Add($clearButton)

    $exportButton = New-Object Windows.Forms.Button
    $exportButton.Text = "Gem en kopi"
    $exportButton.Location = New-Object Drawing.Point(230,510)
    $exportButton.Size = New-Object Drawing.Size(120,30)
    $logForm.Controls.Add($exportButton)

    $closeButton = New-Object Windows.Forms.Button
    $closeButton.Text = "Luk"
    $closeButton.Location = New-Object Drawing.Point(360,510)
    $closeButton.Size = New-Object Drawing.Size(100,30)
    $logForm.Controls.Add($closeButton)

    $searchButton.Add_Click({
        $searchTerm = $searchBox.Text
        if ($searchTerm -ne "") {
            $index = $logTextbox.Find($searchTerm)
            if ($index -ge 0) {
                $logTextbox.Select($index, $searchTerm.Length)
                $logTextbox.ScrollToCaret()
                $logTextbox.Focus()
            } else {
                [System.Windows.Forms.MessageBox]::Show("Intet fundet.","Søg","OK","Information")
            }
        }
    })

    $saveButton.Add_Click({
        try {
            $global:logData | Export-Csv -Path $logPath -Encoding UTF8 -NoTypeInformation
            [System.Windows.Forms.MessageBox]::Show("Logfil gemt korrekt som CSV.","Gem","OK","Information")
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Fejl ved gemning: $_","Fejl","OK","Error")
        }
    })

    $clearButton.Add_Click({
        "TaskId,Tidspunkt,Type,Adresse,Status,Detaljer,Fejl" | Out-File -FilePath $logPath -Encoding UTF8
        $logTextbox.Text = "Logfil ryddet – kun header bevaret."
        [System.Windows.Forms.MessageBox]::Show("Logfil er ryddet, og klar til ny test.","Ryd","OK","Information")
    })

    $exportButton.Add_Click({
        $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
        $saveDialog.Title = "Gem en kopi af logfilen"
        $saveDialog.Filter = "CSV-filer (*.csv)|*.csv"
        $saveDialog.FileName = "overvaagning_log_kopi.csv"

        if ($saveDialog.ShowDialog() -eq "OK") {
            try {
                Copy-Item -Path $logPath -Destination $saveDialog.FileName -Force
                [System.Windows.Forms.MessageBox]::Show("Kopi gemt: $($saveDialog.FileName)","Eksporteret","OK","Information")
            } catch {
                [System.Windows.Forms.MessageBox]::Show("Fejl ved kopiering: $_","Fejl","OK","Error")
            }
        }
    })

    $closeButton.Add_Click({ $logForm.Close() })

    [void]$logForm.ShowDialog()
})

# === Test funktion ===
$button.Add_Click({
    if ($listbox.SelectedItem -ne $null) {
        $resultBox.BackColor = [System.Drawing.Color]::White
        $resultBox.Text = "Tester... Vent venligst..."
        $statusLabel.Text = "Status: Tester..."

        $selectedTaskId = $listbox.SelectedItem.Split(" ")[0]
        $task = $config | Where-Object { $_.id -eq $selectedTaskId }

        if ($task.type -eq "ping") {
            $successCount = 0
            for ($i = 1; $i -le 10; $i++) {
                if (Test-Connection -ComputerName $task.address -Count 1 -Quiet -ErrorAction SilentlyContinue) {
                    $successCount++
                }
            }
            $summary = "$successCount/10 OK"
            $resultBox.Text = "Ping resultat: $summary`nTest færdig."

            if ($successCount -eq 10) {
                $resultBox.BackColor = [System.Drawing.Color]::LightGreen
            } else {
                $resultBox.BackColor = [System.Drawing.Color]::LightSalmon
            }

            Log-Result -taskId $task.id -type "ping" -address $task.address -status "success" -details $summary -error ""

        } elseif ($task.type -eq "http" -or $task.type -eq "https") {
            try {
                $response = Invoke-WebRequest -Uri $task.address -UseBasicParsing -TimeoutSec 5
                $statusCode = $response.StatusCode

                if ($statusCode -ge 200 -and $statusCode -lt 300) {
                    $resultBox.Text = "$($task.type.ToUpper()) resultat: $statusCode OK`nTest færdig."
                    $resultBox.BackColor = [System.Drawing.Color]::LightGreen
                    Log-Result -taskId $task.id -type $task.type -address $task.address -status "success" -details "$statusCode OK" -error ""
                } else {
                    $resultBox.Text = "$($task.type.ToUpper()) fejl: $statusCode`nTest færdig."
                    $resultBox.BackColor = [System.Drawing.Color]::LightSalmon
                    Log-Result -taskId $task.id -type $task.type -address $task.address -status "fail" -details "$statusCode fejl" -error "HTTP-status uden for 200-299"
                }

            } catch {
                $resultBox.Text = "Fejl ved $($task.type.ToUpper()) forespørgsel: $_`nTest færdig."
                $resultBox.BackColor = [System.Drawing.Color]::LightSalmon
                Log-Result -taskId $task.id -type $task.type -address $task.address -status "fail" -details "Fejl ved forespørgsel" -error $_.Exception.Message
            }
        }

        $statusLabel.Text = "Status: Færdig | Bruger: $env:USERNAME | Klokken: $(Get-Date -Format HH:mm:ss)"
    } else {
        $resultBox.Text = "Vælg en opgave fra listen først!"
    }
})

# === Vis GUI ===
[void]$form.ShowDialog()
