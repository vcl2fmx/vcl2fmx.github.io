"""Package only explicit V7 release inputs; no working-tree caches or credentials."""
import argparse,datetime,hashlib,json,pathlib,zipfile,subprocess,sys,re,struct
root=pathlib.Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser()
parser.add_argument('--output',default=str(root/'source distributions'))
parser.add_argument('--source-only',action='store_true')
args=parser.parse_args()
# Never package a candidate whose shipped language coverage is incomplete.
subprocess.run([sys.executable, '-B', str(root/'tools/validate_v7_languages.py')], check=True)
# Check native architecture before creating any archives; a wrong loader can
# otherwise silently select the legacy browser engine on the build machine.
for arch,machine in [('Win32',0x14c),('Win64',0x8664)]:
    inputs=[root/'dependencies/WebView2'/arch/'WebView2Loader.dll']
    if not args.source_only:inputs.append(root/arch/'Release/VCL2FMXConverter.exe')
    for path in inputs:
        data=path.read_bytes()
        assert data[:2]==b'MZ',f'Not a Windows executable: {path}'
        pe=struct.unpack_from('<I',data,60)[0]
        assert data[pe:pe+4]==b'PE\0\0' and struct.unpack_from('<H',data,pe+4)[0]==machine,f'Wrong {arch} architecture: {path}'
for name in ('LICENSE.txt','NOTICE.txt','README.txt'):
    assert (root/'dependencies/WebView2'/name).is_file(),f'Missing WebView2 redistribution file: {name}'
stamp=datetime.datetime.now().strftime('%Y-%m-%d_%H%M%S')
out=pathlib.Path(args.output);out.mkdir(parents=True,exist_ok=True)
def put(z,path,name):
    assert path.is_file(),f'Missing release input: {path}'
    release_name=str(name).replace('\\','/').lower()
    assert not release_name.startswith(('docs/notes/','export/','.git/','.codex/','.claude/')),f'Private working material is not a release input: {name}'
    assert path.suffix.lower() not in {'.md','.markdown'},f'Private Markdown is not a release input: {name}'
    data=path.read_bytes()
    for encoding in ('utf-8','utf-16le'):
        text=data.decode(encoding,errors='replace').replace('\\\\','\\').lower()
        assert str(root).lower() not in text,f'Build-machine path in release input: {name}'
        assert str(pathlib.Path.home()).lower() not in text,f'User-profile path in release input: {name}'
        assert not re.search(r'\b[a-z]:[\\/]+users[\\/]',text),f'User-profile path in release input: {name}'
        assert not re.search(r'\b[a-z]:[\\/]+new delphi projects[\\/]',text),f'Developer checkout path in release input: {name}'
        assert not re.search(r'\b[a-z]: drive\b',text),f'Machine-specific drive reference: {name}'
    z.write(path,str(name).replace('\\','/'))
def tree(z,folder,target,extensions=None):
    for p in sorted(folder.rglob('*')):
        private = any('output' in part.lower() or part.lower() in {'__pycache__','__history','__recovery'} for part in p.relative_to(folder).parts[:-1])
        if p.is_file() and not private and p.suffix.lower() not in {'.md','.markdown'} and (extensions is None or p.suffix.lower() in extensions):
            put(z,p,pathlib.PurePosixPath(target)/p.relative_to(folder).as_posix())
artifacts=[]
for arch in (() if args.source_only else ('Win32','Win64')):
    filename=f'VCL2FMXConverter_v7_0_Atlas_{arch}_{stamp}.zip'
    with zipfile.ZipFile(out/filename,'x',zipfile.ZIP_DEFLATED) as z:
        put(z,root/arch/'Release/VCL2FMXConverter.exe','VCL2FMXConverter.exe')
        put(z,root/'dependencies/WebView2'/arch/'WebView2Loader.dll','WebView2Loader.dll')
        for name in ('LICENSE.txt','NOTICE.txt','README.txt'):
            put(z,root/'dependencies/WebView2'/name,'licenses/WebView2/'+name)
        tree(z,root/'Localization/Languages','Localization/Languages',{'.json'})
        tree(z,root/'mapping_packs','mapping_packs',{'.json'})
        tree(z,root/'docs/Help','docs/Help')
        put(z,root/'LICENSE.txt','LICENSE.txt')
        put(z,root/'LICENSE','LICENSE')
        put(z,root/'dependencies/DelphiAppTranslation/LICENSE','licenses/DelphiAppTranslation-LICENSE.txt')
        put(z,root/'README.txt','README.txt')
    artifacts.append(filename)
filename=f'VCL2FMXConverter_v7_0_Atlas_Source_{stamp}.zip'
with zipfile.ZipFile(out/filename,'x',zipfile.ZIP_DEFLATED) as z:
    for pattern in ('*.pas','*.dpr','*.dproj','*.fmx','*.res','*.ico'):
        for p in sorted(root.glob(pattern)):put(z,p,p.name)
    for name in ('README.txt','LICENSE.txt','LICENSE','.gitignore','.gitattributes'):
        put(z,root/name,name)
    for arch in ('Win32','Win64'):
        put(z,root/'dependencies/WebView2'/arch/'WebView2Loader.dll','dependencies/WebView2/'+arch+'/WebView2Loader.dll')
    for name in ('LICENSE.txt','NOTICE.txt','README.txt'):
        put(z,root/'dependencies/WebView2'/name,'dependencies/WebView2/'+name)
    for folder,ext in [('dependencies',{'.pas','.inc','.dfm','.fmx','.dpk','.dproj','.res','.json',''}),
                       ('Localization',{'.json'}),('mapping_packs',{'.json'}),
                       ('contracts',None),
                       ('docs/schemas',{'.json'}),
                       ('docs/Help',None)]:
        tree(z,root/folder,folder,ext)
    for name in ('RunConversionEngine.dpr','V7FormLanguageContracts.dpr',
                 'V7ReleaseSafetyContracts.dpr','V7ReportLanguageContracts.dpr','V7TranslationContracts.dpr',
                 'run_acceptance_tests.ps1','run_conversion_contracts.ps1','run_regression_guards.ps1',
                 'run_release_readiness_audit.ps1','run_v7_language_contracts.ps1','validate_mapping_packs.ps1',
                 'validate_v7_languages.py','collect_report_translation_strings.py',
                 'collect_mapping_translation_strings.py','sync_v7_language_exports.py',
                 'build_source_distribution_zip.ps1','build_v7_release_packages.py',
                 'prepare_v7_help_translation.ps1','test_v7_help_translation.cjs',
                 'V7HelpServerContracts.dpr'):
        put(z,root/'tools'/name,'tools/'+name)
    for folder in ('encoding_samples','french_beta_regression','manual_review_spill','manual_verification','mapping_pack_schema','mapping_pack_smoke','windows_message_helpers','windows_message_loose_ends'):
        tree(z,root/'tests'/folder,'tests/'+folder,{'.pas','.dfm','.dpr','.dproj','.json','.inc','.ps1','.res','.xml'})
    put(z,root/'docs/guides/VCL2FMX User Help.hdc.json','docs/guides/VCL2FMX User Help.hdc.json')
    for size in ('44','150'):
        asset=pathlib.Path(f'Logos and Icons/Concept 04 - Faceted Cube Arrow/VCL2FMX_Concept04_FacetedCubeArrow_{size}.png')
        put(z,root/asset,asset.as_posix())
artifacts.append(filename)
manifest={'product':'VCL2FMXConverter v7.0 Atlas','version':'7.0.0.1','created':stamp,'artifacts':[]}
for name in artifacts:
    path=out/name
    manifest['artifacts'].append({'file':name,'bytes':path.stat().st_size,'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
    with zipfile.ZipFile(path) as z:
        assert z.testzip() is None
        names=z.namelist()
        assert {n for n in names if n.startswith('Localization/Languages/') and n.endswith('.json')} == {
            'Localization/Languages/' + p.name for p in (root/'Localization/Languages').glob('*.json')}
        assert len([n for n in names if n.startswith('mapping_packs/') and n.endswith('.json')])==22
        assert 'docs/Help/index.html' in names
        if '_Source_' in name:
            assert 'docs/schemas/vcl2fmx.mapping-pack.v1.schema.json' in names
            for arch in ('Win32','Win64'):
                assert 'dependencies/WebView2/'+arch+'/WebView2Loader.dll' in names
            project=z.read('VCL2FMXConverter.dpr').decode('utf-8-sig')
            for referenced in re.findall(r"\bin\s+'([^']+)'",project):
                assert referenced.replace('\\','/') in names,f'Missing project source: {referenced}'
        else:
            assert 'WebView2Loader.dll' in names
            assert 'licenses/WebView2/LICENSE.txt' in names
            assert 'licenses/WebView2/NOTICE.txt' in names
        assert not any(n.startswith(('.git/','export/','.codex/','.claude/')) for n in names)
        assert not any(pathlib.PurePosixPath(n).suffix.lower() in {'.md','.markdown'} or n.startswith('docs/notes/') for n in names)
manifest_path=out/f'V7_RELEASE_MANIFEST_{stamp}.json'
manifest_path.write_text(json.dumps(manifest,indent=2),encoding='utf-8')
print(manifest_path)
