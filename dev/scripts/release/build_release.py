"""Build one release ZIP containing both script editions without Git operations."""
from argparse import ArgumentParser
from pathlib import Path
import re
import zipfile
import sys

ROOT = Path(__file__).resolve().parents[3]
EDITIONS = ('SSV2', 'SSV2-enhanced')
EXCLUDED_DIRS = {'.git', '__pycache__', 'tests', 'audit'}
EXCLUDED_SUFFIXES = {'.json', '.md', '.py', '.pyc', '.pyo', '.txt', '.ps1', '.bak', '.cfg'}
EXCLUDED_NAMES = {'.editorconfig', '.gitignore'}


def release_files(root=ROOT):
    root = Path(root)
    result = []
    for edition in EDITIONS:
        folder = root / edition
        if not folder.is_dir() or not any(folder.glob('*.lua')):
            raise FileNotFoundError(f'Missing script edition or launcher: {edition}')
        for path in sorted(folder.rglob('*')):
            relative = path.relative_to(root)
            if (not path.is_file() or EXCLUDED_DIRS.intersection(relative.parts)
                    or path.suffix.lower() in EXCLUDED_SUFFIXES or path.name in EXCLUDED_NAMES):
                continue
            result.append((path, relative.as_posix()))
    license_file = root / 'LICENSE'
    if not license_file.is_file():
        raise FileNotFoundError('Repository LICENSE is required in the release.')
    return [(license_file, 'LICENSE')] + result


def build_release(output, root=ROOT):
    output = Path(output)
    files = release_files(root)
    output.parent.mkdir(parents=True, exist_ok=True)
    temporary = output.with_name(output.name + '.tmp')
    with zipfile.ZipFile(temporary, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for path, name in files:
            info = zipfile.ZipInfo(name, date_time=(1980, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            archive.writestr(info, path.read_bytes())
    with zipfile.ZipFile(temporary) as archive:
        if archive.testzip() is not None:
            raise ValueError('Release ZIP integrity check failed.')
    temporary.replace(output)
    return len(files)


def main():
    parser = ArgumentParser(description=__doc__)
    parser.add_argument('--version', help='Release tag, such as v2.0.2 (used for the default filename).')
    parser.add_argument('--output', type=Path, help='Override the archive destination.')
    args = parser.parse_args()
    if args.version and not re.fullmatch(r'v?\d+\.\d+\.\d+(?:[-+][\w.-]+)?', args.version):
        parser.error('Invalid release version.')
    if not args.output and not args.version:
        parser.error('Pass --version or --output.')
    output = args.output or ROOT / f'Samurais_Scripts_{args.version}.zip'
    sys.path.insert(0, str(ROOT / 'dev/scripts/enhanced'))
    from sync_enhanced import sync_shared_data
    sync_shared_data(ROOT)
    count = build_release(output)
    print(f'Created {output}: {count} files, both script editions.')


if __name__ == '__main__':
    main()
