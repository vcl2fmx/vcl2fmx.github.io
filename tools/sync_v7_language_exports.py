"""Copy an already validated DATBatch export into the V7 canonical folders."""
import json,pathlib,shutil,sys
root=pathlib.Path(__file__).resolve().parents[1]
exports=pathlib.Path(sys.argv[1])
catalogs=pathlib.Path(sys.argv[2])
codes=[p.stem for p in (root/'Localization/Languages').glob('*.json')]
for code in codes:
    pack=json.loads((exports/f'{code}.json').read_text(encoding='utf-8-sig'))
    assert pack['language']['code']==code
    assert pack['applicationId']=='VCL2FMXConverter'
for code in codes:
    for suffix,dest in [('.json','Languages'),('.layout-proposal.json','Layout')]:
        target=root/f'Localization/{dest}/{code}{suffix}'
        temporary=target.with_name(target.name+'.sync-tmp')
        shutil.copy2(exports/f'{code}{suffix}',temporary)
        temporary.replace(target)
    name=f'VCL2FMXConverter.{code}.translation-project.json'
    c=json.loads((catalogs/name).read_text(encoding='utf-8-sig'))
    c['entries']=[e for e in c['entries'] if e['status']!='obsolete']
    for entry in c['entries']:
        source_name=pathlib.PureWindowsPath(entry.get('sourceFileName','')).name
        if source_name and (root/source_name).is_file():
            entry['sourceFileName']=source_name
    target=root/'Localization/Development'/name
    temporary=target.with_name(target.name+'.sync-tmp')
    temporary.write_text(json.dumps(c,ensure_ascii=False,indent=2),encoding='utf-8')
    temporary.replace(target)
print(f'Synchronized {len(codes)} validated catalogs, packs and layout proposals.')
