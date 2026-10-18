# Reapply after exporting the English manual from Help Doc Creator.
$ErrorActionPreference = 'Stop'
$helpRoot = Join-Path (Split-Path $PSScriptRoot -Parent) 'docs\Help'
$utf8 = [Text.UTF8Encoding]::new($false)
$project = Get-Content -Raw -Encoding UTF8 (Join-Path (Split-Path $PSScriptRoot -Parent) 'docs\guides\VCL2FMX User Help.hdc.json') | ConvertFrom-Json
$shellPath = Join-Path $helpRoot 'index.html'
$shell = [IO.File]::ReadAllText($shellPath)
$shell = [regex]::Replace($shell, ',\s*"owner"\s*:\s*"[^"]*"', '')
foreach ($metadataName in @('toc.json','search-index.json')) {
    $metadataPath = Join-Path $helpRoot $metadataName
    if (Test-Path -LiteralPath $metadataPath) {
        $metadata = [regex]::Replace([IO.File]::ReadAllText($metadataPath), ',\s*"owner"\s*:\s*"[^"]*"', '')
        [IO.File]::WriteAllText($metadataPath, $metadata, $utf8)
    }
}
$shell = $shell.Replace('<input id="searchBox" placeholder="Search help"', '<label for="searchBox">Search help</label><input id="searchBox"')
$searchFunction = @'
function runSearch(){var q=document.getElementById("searchBox").value.toLocaleLowerCase();var r=document.getElementById("searchResults");r.textContent="";if(!q){return;}var count=0;searchItems.forEach(function(x){if(count>=20){return;}var links=document.querySelectorAll("nav a[data-topic-url]");var title=x.title;for(var i=0;i<links.length;i++){if(cleanTopicUrl(links[i].getAttribute("data-topic-url"))===cleanTopicUrl(x.url)){title=links[i].textContent;break;}}if((title+" "+x.title+" "+x.tags+" "+x.helpId).toLocaleLowerCase().indexOf(q)<0){return;}var a=document.createElement("a");a.target="topicFrame";a.href=x.url;a.textContent=title;r.appendChild(a);count++;});if(!count){var empty=document.createElement("span");empty.textContent="No matches";r.appendChild(empty);}}
'@
$shell = [regex]::Replace($shell, 'function runSearch\(\).*?(?=document.querySelectorAll\("nav a\[data-topic-url\]"\)\.forEach)', [Text.RegularExpressions.MatchEvaluator]{param($m) $searchFunction}, [Text.RegularExpressions.RegexOptions]::Singleline)
[IO.File]::WriteAllText($shellPath, $shell, $utf8)
$topicLinks = [regex]::Matches($shell, '<a href="(topics/[^"]+)"[^>]*data-topic-url="[^"]+"[^>]*>(.*?)</a>')
if ($topicLinks.Count -lt 20) { throw 'Help navigation is incomplete; refusing to regenerate print view and index.' }
$glossary = '<!doctype html><html lang="en"><head><meta charset="utf-8"><title>Glossary</title><link rel="stylesheet" href="style.css"></head><body><main><h1>Glossary</h1><dl>'
foreach ($entry in $project.glossary) {
    $glossary += '<dt>' + [Net.WebUtility]::HtmlEncode($entry.key) + '</dt><dd>' + [Net.WebUtility]::HtmlEncode($entry.value) + '</dd>'
}
$glossary += '</dl></main></body></html>'
[IO.File]::WriteAllText((Join-Path $helpRoot 'glossary.html'), $glossary, $utf8)
$index = '<!doctype html><html lang="en"><head><meta charset="utf-8"><title>Help index</title><link rel="stylesheet" href="style.css"></head><body><main><h1>Help index</h1><ul>'
foreach ($link in ($topicLinks | Sort-Object { $_.Groups[2].Value })) {
    $index += '<li><a href="' + $link.Groups[1].Value + '">' + $link.Groups[2].Value + '</a></li>'
}
$index += '</ul></main></body></html>'
[IO.File]::WriteAllText((Join-Path $helpRoot 'keyword-index.html'), $index, $utf8)
$print = '<!doctype html><html lang="en"><head><meta charset="utf-8"><title>Atlas User Guide - Print view</title><link rel="stylesheet" href="style.css"></head><body><main>'
foreach ($link in $topicLinks) {
    $topic = [IO.File]::ReadAllText((Join-Path $helpRoot $link.Groups[1].Value))
    $body = [regex]::Match($topic, '(?s)<main>(.*?)</main>').Groups[1].Value
    $body = [regex]::Replace($body, '(?s)<div class="page-nav">.*?</div>', '')
    $body = [regex]::Replace($body, '(href|src)="(?![a-z]+:|/|#)([^"]+)"', [Text.RegularExpressions.MatchEvaluator]{
        param($m)
        $url = $m.Groups[2].Value
        if ($url.StartsWith('../')) { $url = $url.Substring(3) } else { $url = 'topics/' + $url }
        $m.Groups[1].Value + '="' + $url + '"'
    })
    $print += '<section>' + $body + '</section>'
}
$print += '</main></body></html>'
[IO.File]::WriteAllText((Join-Path $helpRoot 'manual-print.html'), $print, $utf8)
Get-ChildItem $helpRoot -Recurse -Filter '*.html' | ForEach-Object {
    $html = [IO.File]::ReadAllText($_.FullName)
    if ($html -notmatch '<script\b[^>]*\bsrc=["''][^"'']*assets/help-translation\.js["'']') {
        $scriptPath = if ($_.Directory.Name -eq 'topics') {'../assets/help-translation.js'} else {'assets/help-translation.js'}
        $html = $html.Replace('</body>', '<script src="' + $scriptPath + '"></script></body>')
        [IO.File]::WriteAllText($_.FullName, $html, $utf8)
    }
}
