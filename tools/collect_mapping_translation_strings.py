"""Expose shipped mapping prose to the Delphi Translation App catalog extractor."""
import hashlib
import json
import pathlib

ROOT = pathlib.Path(__file__).resolve().parents[1]


def mapping_phrases():
    phrases = set()

    def visit(value):
        if isinstance(value, dict):
            for key, child in value.items():
                if key.lower() in ('notes', 'description') and isinstance(child, str) and child.strip():
                    phrases.add(child.strip())
                visit(child)
        elif isinstance(value, list):
            for child in value:
                visit(child)

    for path in sorted((ROOT / 'mapping_packs').glob('*.json')):
        visit(json.loads(path.read_text(encoding='utf-8-sig')))
    return sorted(phrases)


if __name__ == '__main__':
    lines = ['unit Converter.Mapping.Strings;', '', 'interface', '',
             '// Catalog-only resources for bundled mapping descriptions. Keep code identifiers unchanged.',
             'resourcestring']
    for phrase in mapping_phrases():
        key = hashlib.sha256(phrase.encode()).hexdigest()[:12]
        lines.append("  SDisplayMapping%s = '%s';" % (key, phrase.replace("'", "''")))
    lines += ['', 'implementation', '', 'end.', '']
    (ROOT / 'Converter.Mapping.Strings.pas').write_text('\n'.join(lines), encoding='utf-8')
    print(f'Registered {len(mapping_phrases())} bundled mapping descriptions.')
