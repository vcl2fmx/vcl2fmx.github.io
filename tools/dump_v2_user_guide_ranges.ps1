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
    foreach ( in @(115, 126, 146, 216, 248)) {
       =  + 20
      "RANGE -"
      for ( = ;  -le  -and  -le .Paragraphs.Count; ++) {
        '{0,4}: {1}' -f , (Clean-WordText .Paragraphs.Item().Range.Text)
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
