"""Generate the native Enhanced port's shared data from the maintained SSV2 data.
"""
from argparse import ArgumentParser
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[3]
DATA = Path('SSV2-enhanced/includes/ssv2/data')
GROUPS = {
    'offsets': {'data/globals_locals.lua': 'globals_locals.lua'},
    'translations': {
        'lib/translations/__locales.lua': 'locale_codes.lua',
        'lib/translations/__gxt_labels.lua': 'gxt_labels.lua',
    },
    'game-data': {
        **{f'data/{name}.lua': f'{name}.lua' for name in (
            'vehicles', 'peds', 'weapon_data', 'objects', 'vehicle_hashmap',
            'custom_paints', 'imp_exp_vehicles', 'sv23_data',
        )},
        **{f'data/enums/{name}.lua': f'{name}.lua' for name in (
            'ped_type', 'vehicle_classes', 'vehicle_advanced_flags',
            'vehicle_handling_flags', 'vehicle_model_flags', 'vehicle_model_info_flags',
        )},
        **{f'data/actions/{name}.lua': f'actions/{name}.lua' for name in (
            'animations', 'movement_clipsets', 'scenarios', 'synchronized_scenes',
        )},
    },
    'version': {'version.lua': 'version.lua'},
}
LITERALS = re.compile(
    r'--\[(=*)\[.*?\]\1\]|--[^\n]*|\[(=*)\[.*?\]\2\]|"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'',
    re.S,
)


def code_only(source):
    return LITERALS.sub(lambda match: ' ' * len(match.group()), source)


def luajit_data(source, filename):
    """Remove declaration attributes, preserving comments and string contents."""
    masked = code_only(source)
    matches = list(re.finditer(r'\b(?:local\s+\w+)\s+(<const>)(?=\s*=)', masked))
    for match in reversed(matches):
        start, end = match.span(1)
        source = source[:start].rstrip() + source[end:]
    masked = code_only(source)
    if re.search(r'\b(?:require|function|Enums)\b|<\s*(?:const|close)\s*>|<<|>>|[&|~]', masked):
        raise ValueError(f'{filename}: shared data now contains unsupported executable/Lua 5.4 syntax; port it explicitly.')
    return source


def generated_files(root=ROOT, groups=None):
    root = Path(root)
    selected = set(groups) if groups else set(GROUPS)
    unknown = selected - GROUPS.keys()
    if unknown:
        raise ValueError(f'Unknown data groups: {sorted(unknown)}')
    source = root / 'SSV2/includes'
    files = {}
    for group in sorted(selected):
        for original, destination in GROUPS[group].items():
            path = source / original
            files[root / DATA / destination] = luajit_data(path.read_text(encoding='utf-8-sig'), path)
    if 'translations' in selected:
        locales_source = source / 'lib/translations/__locales.lua'
        # Locale codes in the return table are validated against their real files.
        source_text = locales_source.read_text(encoding='utf-8-sig')
        source_text = LITERALS.sub(lambda m: ' ' * len(m.group()) if m.group().startswith('--') else m.group(), source_text)
        codes = re.findall(r'''["']([a-z]{2}-[A-Z]{2})["']''', source_text)
        if not codes or len(codes) != len(set(codes)):
            raise ValueError('Locale list is empty or contains duplicate locale codes.')
        if 'en-US' not in codes:
            raise ValueError('The English fallback locale en-US is required.')
        for code in codes:
            path = source / 'lib/translations' / (code + '.lua')
            files[root / DATA / 'locales' / path.name] = luajit_data(path.read_text(encoding='utf-8-sig'), path)
    return files


def sync_shared_data(root=ROOT, groups=None, check=False):
    root = Path(root)
    if not (root / 'SSV2-enhanced/samurais_v2.lua').is_file():
        raise FileNotFoundError('The Enhanced native port must be installed before generating its data.')
    changed = []
    # Construct every output first: a malformed input must not leave half an update.
    for path, content in generated_files(root, groups).items():
        if path.is_file() and path.read_text(encoding='utf-8') == content:
            continue
        changed.append(path.relative_to(root).as_posix())
        if not check:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content, encoding='utf-8', newline='\n')
    return changed


def main():
    parser = ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true', help='Report stale generated files without writing.')
    parser.add_argument('--group', action='append', choices=tuple(GROUPS), help='Sync only this group (repeatable).')
    args = parser.parse_args()
    changed = sync_shared_data(groups=args.group, check=args.check)
    print(('Stale' if args.check else 'Updated') + f' Enhanced data files: {len(changed)}')
    for name in changed:
        print(name)
    if args.check and changed:
        raise SystemExit(1)


if __name__ == '__main__':
    main()
