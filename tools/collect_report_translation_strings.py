"""Maintain the catalog-only resource unit for built-in report presentation."""
import pathlib, re, hashlib
ROOT = pathlib.Path(__file__).resolve().parents[1]
quoted = r"'((?:''|[^'])*)'"
phrases = set()

def collect(block):
    # Join adjacent Pascal string literals before collecting their visible text.
    while re.search(r"'\s*\+\s*'", block):
        block = re.sub(r"'\s*\+\s*'", '', block)
    for match in re.finditer(quoted, block):
        value = match[1].replace("''", "'")
        if '<' in value or '>' in value:
            pieces = re.split(r'<[^>]*>', value)
        else:
            pieces = [value]
        for text in pieces:
            if re.search(r'<[A-Za-z]|\b(?:lang|dir)=|^object %|^yyyy-mm-dd', text): continue
            if not re.search(r'[A-Za-z]{3}', text): continue
            if any(x in text for x in ('{', '}', ':=', '\\', '(?', ';', 'font-', 'padding:', 'margin:', '.pas', '.dfm', '.fmx')): continue
            if re.search(r'\b(?:begin|procedure|function|class|var)\b', text) and text.count(' ') < 3: continue
            if ' ' not in text.strip() and text.strip() not in {'Yes','No','Information','Warning','Error','Critical','Direct','Compatible','Preserved','Researched','Substitute','Unmapped','Renamed','Transformed'}: continue
            if len(text.strip()) < 3 or len(text) > 2500: continue
            phrases.add(text)

for path in sorted(ROOT.glob('Converter.*.pas')):
    if path.name == 'Converter.Reporting.Strings.pas': continue
    source = path.read_text(encoding='utf-8-sig')
    if path.name in ('Converter.Reporting.Html.pas', 'Converter.Reporting.Text.pas'):
        collect(source)
    if path.name == 'Converter.Core.Engine.pas':
        collect(source[source.index('procedure TConverterEngine.GenerateReport;'):])
    for start in re.finditer(r'\b(?:AddIssue|AddManualReview)\s*\(', source):
        pos = start.end(); depth = 1; in_quote = False
        while pos < len(source) and depth:
            char = source[pos]
            if char == "'":
                if in_quote and pos + 1 < len(source) and source[pos+1] == "'": pos += 2; continue
                in_quote = not in_quote
            elif not in_quote:
                if char == '(': depth += 1
                elif char == ')': depth -= 1
            pos += 1
        collect(source[start.end():pos-1])

lines = ['unit Converter.Reporting.Strings;', '', 'interface', '',
         '// Catalog-only resources: presentation is localized after the canonical report model is built.', 'resourcestring']
for index, phrase in enumerate(sorted(phrases), 1):
    lines.append("  SDisplayReport%s = '%s';" % (hashlib.sha256(phrase.encode()).hexdigest()[:12], phrase.replace("'", "''")))
lines += ['', 'implementation', '', 'end.', '']
(ROOT / 'Converter.Reporting.Strings.pas').write_text('\n'.join(lines), encoding='utf-8')
print(f'Registered {len(phrases)} built-in report phrases.')
