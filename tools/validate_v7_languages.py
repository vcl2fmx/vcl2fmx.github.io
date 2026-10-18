"""Validate V7's shipped text coverage and designer card boundaries."""
import collections
import json
import pathlib
import re
import sys
from collect_mapping_translation_strings import mapping_phrases

ROOT = pathlib.Path(__file__).resolve().parents[1]
PACKS = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / 'Localization/Languages'
load = lambda path: json.loads(path.read_text(encoding='utf-8-sig'))
english = load(PACKS / 'en-US.json')
bundled_phrases = set(mapping_phrases())
mapping_identifiers = re.compile(r'\b(?:T[A-Z][A-Za-z0-9_]*|VCL|FMX|RTTI|JSON|HTML|DPI|WinAPI|JVCL|LMD|TMS|Skia|DevExpress|Raize|FireDAC|LiveBindings|DataSource|DataField|FieldName|IsChecked|FontColor|OnClick|OnChange)\b')
source = (ROOT / 'MainForm.pas').read_text(encoding='utf-8-sig')
protected_identity = {english['strings'][key] for key in
                      ('frmMain.Caption', 'frmMain.lblHeader.Text',
                       'frmMain.lblVersion.Text', 'frmMain.HeroAtlasGhost.Text')}
phrases = [s.replace("''", "'") for s in re.findall(r"SReference\w+\s*=\s*'((?:''|[^'])*)';", source)]
display_phrases = []
for unit in ROOT.glob('*.pas'):
    display_phrases.extend(v.replace("''", "'") for v in re.findall(r"SDisplay\w+\s*=\s*'((?:''|[^'])*)';", unit.read_text(encoding='utf-8-sig')))
failures = []
review = collections.defaultdict(list)
normalize = lambda s: re.sub(r'\s+', ' ', re.sub('[\u00ad\u200b]', '', s)).strip().casefold()
valid_identical = {('nl-NL', '%d min %d sec'), ('ro-RO', '%d min %d sec')}
placeholder = lambda s: collections.Counter(re.findall(r'%[-+0-9.:]*[sdfuxXegnp]', s))
cards = {'DashboardStatusCard': (12, 618), 'DashboardModulesCard': (652, 638),
         'ProjectCard': (12, 816), 'ProjectActionCard': (850, 440)}
for path in sorted(PACKS.glob('*.json')):
    if path.name.endswith('layout-proposal.json'):
        continue
    pack = load(path)
    if 'language' not in pack:
        continue
    code = pack['language']['code']
    rule_names = [normalize(pack['strings']['frmMain.' + control + '.Text']) for control in
                  ('chkCritical', 'chkDataAware', 'chkThirdParty', 'chkWinAPI', 'chkDryRunPreview')]
    for original, translated in pack['sourceTemplates'].items():
        if original.startswith('Critical Areas') and original.count('%s') == 5:
            separator = ' = ' if ' = ' in original else ': '
            expected = '\n'.join(name + separator + '%s' for name in rule_names)
            if normalize(translated) != normalize(expected):
                failures.append(f'{code}: rule summary names differ from checkbox labels')
    # Runtime contracts validate compatible source subsets: retained terminology
    # can legitimately give a pack a different source-catalog checksum.
    for field in ('applicationId', 'applicationVersion', 'framework', 'sourceLanguage'):
        if pack.get(field) != english.get(field):
            failures.append(f'{code}: incompatible {field}')
    text = {**pack['sourceStrings'], **pack['sourceTemplates']}
    if set(pack['strings']) != set(english['strings']):
        failures.append(f'{code}: designer/static key mismatch')
    for phrase in sorted(set(phrases + display_phrases) | bundled_phrases):
        if not text.get(phrase):
            failures.append(f'{code}: missing reference phrase: {phrase}')
    for original, translated in text.items():
        if original in bundled_phrases:
            for identifier in set(mapping_identifiers.findall(original)):
                if identifier not in translated:
                    failures.append(f'{code}: changed mapping identifier {identifier}: {original}')
        if '\u00ad' in translated:
            failures.append(f'{code}: inserted soft hyphen: {original}')
        if not translated.strip():
            failures.append(f'{code}: empty translation: {original}')
        if placeholder(original) != placeholder(translated):
            failures.append(f'{code}: changed placeholders: {original}')
        if original.count('\n') != translated.count('\n'):
            failures.append(f'{code}: changed line breaks: {original}')
        if any(token in original for token in ('\\s', '\\w', '(?=', '(?:')):
            failures.append(f'{code}: regex harvested: {original}')
        if code != 'en-US' and original not in protected_identity and (code, original) not in valid_identical and normalize(original) == normalize(translated):
            if original in phrases or len(original.split()) > 8 or (original in display_phrases and len(re.findall('[A-Za-z]{3,}', original)) >= 2):
                failures.append(f'{code}: unchanged prose: {original}')
            elif original not in ('ATLAS',) and re.search('[A-Za-z]', original):
                review[original].append(code)
    bounds = {name: list(values) for name, values in cards.items()}
    for rule in pack['layout']:
        name, prop = rule['componentName'], rule['propertyName']
        # Rules cards now use native dock alignment, checked by the FMX viewport matrix.
        if name in ('RulesCard', 'RulesSummaryCard', 'RulesScrollBox', 'RulesSummaryScrollBox', 'DashboardNextCard') or name.endswith('SheetBackground') or name in ('DashboardScrollBox', 'ProjectScanScrollBox', 'ComponentMapScrollBox', 'PropertyMapScrollBox', 'EventMapScrollBox', 'IssuesScrollBox'):
            failures.append(f'{code}: language pack overrides designer page geometry: {name}.{prop}')
        if name in bounds and prop in ('Width', 'Position.X'):
            bounds[name][1 if prop == 'Width' else 0] = float(rule['translatedValue'])
    for left, right, gap in [('ProjectCard', 'ProjectActionCard', 22),
                             ('DashboardStatusCard', 'DashboardModulesCard', 22)]:
        actual = bounds[right][0] - sum(bounds[left])
        if actual < gap - 0.1:
            failures.append(f'{code}: {left} gap {actual}, expected at least {gap}')
    print(f'{code}: checked {len(text)} source phrases and {len(phrases)} reference phrases')
print('\nUnchanged short terms for contextual review:')
for text, codes in sorted(review.items()):
    print(f'{text!r}: {", ".join(codes)}')
for failure in failures:
    print('FAIL:', failure)
print(f'Failures: {len(failures)}')
sys.exit(bool(failures))
