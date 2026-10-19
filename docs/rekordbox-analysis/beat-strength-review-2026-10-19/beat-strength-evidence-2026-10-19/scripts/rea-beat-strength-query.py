import runpy, pathlib, json
p='/Users/rterhaar/.npm/_npx/ad9a3fdbcad992c6/node_modules/rea-agents/bridge/hopper_bridge.py'
doc=Document.getCurrentDocument()
rea=runpy.run_path(p,init_globals={'Document':Document,'REA_TARGET_PATH':doc.getExecutableFilePath()})
if doc.backgroundProcessActive():
 print('REA query deferred: analysis active')
else:
 root=pathlib.Path('/private/tmp/rea-beat-strength-evidence');root.mkdir(exist_ok=True)
 targets={'threshold-activations':'0x102302f00','observation-likelihoods':'0x10231725c','observation-state-space':'0x102316950','bar-viterbi':'0x1023035c4'}
 for name,address in targets.items():
  rec={'provider':'Hopper public API through installed REA adapter','route':'Hopper Python console; not an MCP Evidence envelope','address':address,'database':doc.getDatabaseFilePath(),'target':doc.getExecutableFilePath(),'scope':'static native evidence'}
  for method in ['procedure_pseudo_code','procedure_assembly','procedure_info']:
   try:rec[method]=rea['_dispatch'](method,{'procedure':address})
   except Exception as e:rec[method]={'error':str(e)}
  (root/(name+'.json')).write_text(json.dumps(rec,indent=2))
  if isinstance(rec['procedure_pseudo_code'],str):(root/(name+'.c')).write_text(rec['procedure_pseudo_code'])
  print('REA saved:',name)
 print('REA strength queries complete')
