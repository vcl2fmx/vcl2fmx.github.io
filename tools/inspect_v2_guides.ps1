Continue = 'Stop'
. (Join-Path $PSScriptRoot 'doc_paths.ps1')

 = @(
  ,
  
)

 = @(
  'backup',
  'Critical / DataAware / ThirdParty / WinAPI',
  'source path, target path',
  'written conversion report',
  'Main Window and Control-by-Control Walkthrough',
  'Building and Launching the Converter',
  'Run rules',
  'Open Report',
  'Print Report',
  'HTML'
)

 = 

try {
   = New-Object -ComObject Word.Application
  .Visible = False
  .DisplayAlerts = 0

  foreach ( in ) {
    Write-Output ('DOC=' + )
     = .Documents.Open(, False, True)
    try {
      foreach ( in .Paragraphs) {
         = .Range.Text.Trim()
        if ([string]::IsNullOrWhiteSpace()) {
          continue
        }

        foreach ( in ) {
          if ( -match ) {
            Write-Output 
            break
          }
        }
      }
    }
    finally {
      .Close()
    }
  }
}
finally {
  if ( -ne ) {
    .Quit()
  }
}
