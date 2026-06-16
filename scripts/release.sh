#!/usr/bin/env bash
set -euo pipefail

# Publish firmware to a GitHub Release as INDIVIDUAL files (NO zip), in the same
# format used for the AP-RTK dual release: per board, upload
#   <prefix>.apj           - app, OTA update (Mission Planner / DroneCAN)
#   <prefix>.bin           - app, raw binary OTA
#   <prefix>_with_bl.hex   - bootloader + app, SWD / DFU full-chip flash
#   <prefix>-betaflight.hex- betaflight, flash via BF Configurator (FC boards)
# where <prefix> is the tag itself for a board-scoped tag (e.g.
# AP-RTK_dual-v0.1.0), otherwise "<board>-<tag>" so files stay distinguishable.
#
# Uses the GitHub REST API with GITHUB_ACCESS_TOKEN from .env (no `gh` needed).
#
# Usage:
#   scripts/release.sh <tag> [board ...]
#     scripts/release.sh AP-RTK_dual-v0.1.0 AP-RTK_dual   # one board, board-scoped tag
#     scripts/release.sh v0.2.0                           # all boards in releases/
#   DRY_RUN=1 scripts/release.sh <tag> [board ...]        # show plan, touch nothing
#
# Build artifacts first (scripts/build_ap.sh / build_bf.sh) so that
# releases/<board>/<platform>/ holds the per-platform files.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TAG="${1:?Usage: release.sh <tag> [board ...]}"
shift || true

cd "${ROOT_DIR}"
TAG="${TAG}" BOARDS="${*}" DRY_RUN="${DRY_RUN:-}" python3 - <<'PYEOF'
import json, os, sys, urllib.request, urllib.error

REPO   = 'novaX-ALUX/flight_controller'
TAG    = os.environ['TAG']
BOARDS = os.environ.get('BOARDS', '').split()
DRY    = bool(os.environ.get('DRY_RUN'))
REL    = 'releases'

PURPOSE = {
    'apj':          'app - OTA update (Mission Planner / DroneCAN)',
    'bin':          'app - raw binary OTA',
    '_with_bl.hex': 'bootloader + app - SWD / DFU full-chip flash',
    'betaflight':   'betaflight - flash via Betaflight Configurator',
}

def get_token():
    for line in open('.env'):
        if line.startswith('GITHUB_ACCESS_TOKEN='):
            return line.split('=', 1)[1].strip().strip('"').strip("'")
    sys.exit('GITHUB_ACCESS_TOKEN not found in .env')

def api(url, data=None, method='GET', ctype='application/json'):
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header('Authorization', 'token ' + TOKEN)
    req.add_header('Accept', 'application/vnd.github+json')
    if data is not None:
        req.add_header('Content-Type', ctype)
    try:
        with urllib.request.urlopen(req) as r:
            return r.status, json.load(r)
    except urllib.error.HTTPError as e:
        try:
            return e.code, json.loads(e.read().decode())
        except Exception:
            return e.code, {}

if not BOARDS:
    BOARDS = sorted(d for d in os.listdir(REL) if os.path.isdir(os.path.join(REL, d)))
if not BOARDS:
    sys.exit('No release artifacts in releases/. Build first.')

assets = []                       # (asset_name, src_path, suffix_key)
notes  = ['## Firmware Release %s' % TAG, '']

for board in BOARDS:
    bdir = os.path.join(REL, board)
    if not os.path.isdir(bdir):
        print('warn: no releases for %s, skipping' % board, file=sys.stderr)
        continue
    # tag-scoped name doubling guard: AP-RTK_dual-v0.1.0 + board AP-RTK_dual
    prefix = TAG if TAG.startswith(board) else ('%s-%s' % (board, TAG))
    section, any_file = ['### %s' % board, '', '| File | Purpose |', '|------|---------|'], False

    ap = os.path.join(bdir, 'ardupilot')
    if os.path.isdir(ap):
        files  = os.listdir(ap)
        apj    = next((f for f in files if f.endswith('.apj')), None)
        withbl = next((f for f in files if f.endswith('_with_bl.hex')), None)
        binf   = (apj[:-4] + '.bin') if apj else None
        plan = [('apj', apj, prefix + '.apj'),
                ('bin', binf, prefix + '.bin'),
                ('_with_bl.hex', withbl, prefix + '_with_bl.hex')]
        for key, fname, aname in plan:
            if fname and os.path.isfile(os.path.join(ap, fname)):
                assets.append((aname, os.path.join(ap, fname), key))
                section.append('| `%s` | %s |' % (aname, PURPOSE[key]))
                any_file = True
        commit = '-'
        man = os.path.join(ap, 'manifest.txt')
        if os.path.isfile(man):
            for l in open(man):
                if l.startswith('ap_commit='):
                    commit = l.split('=', 1)[1].strip()
        section += ['', 'ArduPilot commit: `%s`' % commit]

    bf = os.path.join(bdir, 'betaflight')
    if os.path.isdir(bf):
        hexf = next((f for f in os.listdir(bf) if f.endswith('.hex')), None)
        if hexf:
            aname = prefix + '-betaflight.hex'
            assets.append((aname, os.path.join(bf, hexf), 'betaflight'))
            section.append('| `%s` | %s |' % (aname, PURPOSE['betaflight']))
            any_file = True

    if any_file:
        notes += section + ['']

if not assets:
    sys.exit('No individual files found to upload (build first).')
notes_txt = '\n'.join(notes)

print('Release tag : %s' % TAG)
print('Assets (%d):' % len(assets))
for name, path, _ in assets:
    print('  %-34s <- %s (%d B)' % (name, path, os.path.getsize(path)))

if DRY:
    print('\n[DRY_RUN] nothing published. Notes preview:\n')
    print(notes_txt)
    sys.exit(0)

TOKEN = get_token()
st, rel = api('https://api.github.com/repos/%s/releases/tags/%s' % (REPO, TAG))
if st == 200:
    rid = rel['id']
    api('https://api.github.com/repos/%s/releases/%d' % (REPO, rid),
        data=json.dumps({'name': TAG, 'body': notes_txt}).encode(), method='PATCH')
    existing = {a['name']: a['id'] for a in rel.get('assets', [])}
    print('reusing release:', rel['html_url'])
else:
    payload = json.dumps({'tag_name': TAG, 'target_commitish': 'main', 'name': TAG,
                          'body': notes_txt, 'draft': False, 'prerelease': False}).encode()
    st, rel = api('https://api.github.com/repos/%s/releases' % REPO, data=payload, method='POST')
    if st not in (200, 201):
        sys.exit('create release FAILED %s %s' % (st, rel.get('message')))
    rid, existing = rel['id'], {}
    print('created release:', rel['html_url'])

for name, path, _ in assets:
    if name in existing:
        api('https://api.github.com/repos/%s/releases/assets/%d' % (REPO, existing[name]), method='DELETE')
    data = open(path, 'rb').read()
    st, r = api('https://uploads.github.com/repos/%s/releases/%d/assets?name=%s' % (REPO, rid, name),
                data=data, method='POST', ctype='application/octet-stream')
    print(('  uploaded ' if st in (200, 201) else '  FAILED %s ' % st) + name)

print('DONE:', rel['html_url'])
PYEOF
