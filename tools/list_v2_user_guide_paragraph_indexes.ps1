Continue = 'Stop'
. (Join-Path $PSScriptRoot 'doc_paths.ps1')

function Clean-WordText {
  param([string])
  return ((( -replace "[]", ' ') -replace '\s+', ' ').Trim())
}

 = 

try {
   = New-Object -ComObject Word.Application
  .Visible = False
  .DisplayAlerts = 0

   = .Documents.Open(, False, True)

  try {
    for ( = 1;  -le .Paragraphs.Count; ++) {
       = Clean-WordText .Paragraphs.Item().Range.Text
      if ( -match '4\. Building and Launching the Converter|5\. Main Window and Control-by-Control Walkthrough|8\. Running a Conversion|9\. Reading the Log and the Conversion Report|10\. Understanding the Output Folder and Files|Open the migrated project|The main window is intentionally simple|Set recursion and backup options|Every conversion run should be reviewed|Keep zipped milestone backups out of the live converter workspace') {
        '{0,4}: {1}' -f , 
      }
    }
  }
  finally {
    .Close()
  }
}
finally {
  if ( -ne ) {
    .Quit()
  }
}
