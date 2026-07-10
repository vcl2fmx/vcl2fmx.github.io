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
      if ( -match '5\.2 UI Responsibilities|MainForm is responsible|tabbed operator workspace|Converter\.Core\.Types\.pas is the vocabulary layer|Provide shared types|per-run flags for Critical Areas') {
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
