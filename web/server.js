const express = require('express');
const path = require('path');
const fs = require('fs');
const { exec } = require('child_process');
const bodyParser = require('body-parser');

const app = express();
const port = 3000;

const logFilePath = path.resolve(__dirname, '../logs/overvaagning_log.csv');
const lastRunPath = path.resolve(__dirname, 'last_run.txt'); //  ny fil til tidspunkt

app.use(express.static(path.join(__dirname, '../public')));
app.use(bodyParser.text());

// GET log file
app.get('/log', (req, res) => {
  res.sendFile(logFilePath);
});

// POST: Save edited log file
app.post('/save-log', (req, res) => {
  fs.writeFile(logFilePath, req.body, 'utf8', (err) => {
    if (err) {
      console.error(' Error saving log file:', err);
      return res.status(500).send(' Could not save log file.');
    }
    res.send(' Log file saved successfully!');
  });
});

// GET: Run PowerShell script
app.get('/koertest', (req, res) => {
  const scriptPath = path.resolve(__dirname, '../script/overvaagning.ps1');

  exec(`powershell -ExecutionPolicy Bypass -File "${scriptPath}"`, (error, stdout, stderr) => {
    if (error) {
      console.error(` PowerShell error: ${error.message}`);
      return res.status(500).send(` PowerShell error: ${error.message}`);
    }
    if (stderr) {
      console.error(` PowerShell stderr: ${stderr}`);
      return res.status(500).send(` PowerShell stderr: ${stderr}`);
    }

    //  Gem tidspunkt for seneste kørsel
    const now = new Date().toISOString();
    fs.writeFileSync(lastRunPath, now, 'utf8');

    res.send(` PowerShell output:\n\n${stdout}`);
  });
});

//  NYT: Send tidspunkt for sidste kørsel
app.get('/last-run', (req, res) => {
  if (fs.existsSync(lastRunPath)) {
    const timestamp = fs.readFileSync(lastRunPath, 'utf8');
    res.send(timestamp);
  } else {
    res.send('Ingen kørsel registreret endnu.');
  }
});

// Start server
app.listen(port, () => {
  console.log(` Webapp running at http://localhost:${port}`);
});
