import datetime, json, pathlib
if Document.getCurrentDocument().backgroundProcessActive():
    print('REA query deferred: Hopper background analysis is still active')
else:
    root = pathlib.Path('/private/tmp/rekordbox-hopper-evidence')
    root.mkdir(exist_ok=True)
    targets = {
        'detect': '0x102327c80',
        'high-precision': '0x102327e50',
        'learned-analyze': '0x102307f8c',
        'observation-likelihoods': '0x10231725c',
        'bpm-summary': '0x102306b34',
        'bpm-focus': '0x1011820d4',
        'peak-bpm-fit': '0x10113c028',
        'low-band-integral': '0x10113d760',
        'all-band-integral': '0x10113d9ac',
        'downbeat-tracking': '0x102300d6c',
        'observation-state-space': '0x102316950',
        'beat-list': '0x102305908',
    }
    for name, address in targets.items():
        destination = root / (name + '.json')
        if destination.exists():
            print('Retained:', name)
            continue
        record = {
            'evidence_id': 'local-hopper-' + name,
            'provider': 'Hopper public API through installed REA adapter',
            'target': '/Applications/rekordbox 7/rekordbox.app/Contents/MacOS/rekordbox',
            'sha256': '07dcecbaf304f777e435539c83c7dcc02e41de1eaf2e0a75e8a9852e4411a244',
            'architecture': 'arm64',
            'observed_at': datetime.datetime.now(datetime.timezone.utc).isoformat(),
            'address': address,
            'limitations': ['Static decompilation; not original source.', 'Direct REA adapter invocation; not an MCP Evidence envelope.', 'No runtime audio experiment.'],
        }
        for method in ['procedure_info', 'procedure_pseudo_code', 'procedure_callees']:
            try:
                record[method] = rea['_dispatch'](method, {'procedure': address})
            except Exception as error:
                record[method] = {'error': str(error)}
        destination.write_text(json.dumps(record, indent=2))
        print('Saved:', name)
    print('REA evidence query finished')
