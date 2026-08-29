#!/usr/bin/env python3
"""Enmesh rebrand: ordered, context-aware token replacement over tracked files."""
import subprocess, sys, os

os.chdir(os.path.dirname(os.path.abspath(__file__)))
files = subprocess.check_output(['git', 'ls-files'], text=True).splitlines()

DOCS = {
    'README.md', 'README_en.md', 'AGENTS.md', 'CLAUDE.md', 'VERSION',
    'update-server/README.md',
} | {f for f in files if f.startswith('docs/')}

CHANGELOG = 'CHANGELOG.md'  # manual edit only — history is immutable

PROTECT = 'ldoubil/astral'
TOKEN = '\x00UPSTREAM_LDoubil_astral\x00'

CODE_RULES = [
    ('AstralNG', 'Enmesh'),
    ('Astral-ng', 'Enmesh'),
    ('AstralRust', 'EnmeshRust'),
    ('astralng', 'enmesh'),
    ('Astral', 'Enmesh'),
    ('astral', 'enmesh'),
    ('ASTRAL', 'ENMESH'),
]

DOCS_RULES = [
    ('AstralRust', 'EnmeshRust'),
    ('astralng', 'enmesh'),
    ('AstralNG', 'EasyTier Enmesh'),
    ('Astral-ng', 'EasyTier Enmesh'),
    ('Astral-NG', 'EasyTier Enmesh'),
    ('astral', 'enmesh'),
    ('ASTRAL', 'ENMESH'),
    ('Astral', 'EasyTier Enmesh'),
]

changed = []
for f in files:
    if f == CHANGELOG or not os.path.isfile(f):
        continue
    with open(f, encoding='utf-8', errors='surrogateescape') as fh:
        text = fh.read()
    if 'astral' not in text.lower():
        continue
    rules = DOCS_RULES if f in DOCS else CODE_RULES
    new = text.replace(PROTECT, TOKEN)
    for old, repl in rules:
        new = new.replace(old, repl)
    new = new.replace(TOKEN, PROTECT)
    if new != text:
        with open(f, 'w', encoding='utf-8', errors='surrogateescape') as fh:
            fh.write(new)
        changed.append(f)

print(f'{len(changed)} files modified')
