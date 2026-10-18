"""Static SavedModel inspection; never loads or executes proprietary weights."""
import hashlib
import json
import math
import subprocess
from pathlib import Path
from tensorflow.core.protobuf import saved_model_pb2
from tensorflow.python.framework import tensor_util
ROOT = Path('/Applications/rekordbox 7/rekordbox.app/Contents/Resources/models/detect_beat')
for model in ('model7', 'model8'):
    p = ROOT / model
    sm = saved_model_pb2.SavedModel()
    sm.ParseFromString((p / 'saved_model.pb').read_bytes())
    mg = sm.meta_graphs[0]
    print('\nMODEL', model)
    for rel in ('saved_model.pb', 'keras_metadata.pb', 'variables/variables.data-00000-of-00001', 'variables/variables.index'):
        print('SHA256', rel, hashlib.sha256((p / rel).read_bytes()).hexdigest())
    print('SERVING_SIGNATURE', mg.signature_def['serving_default'])
    variables = [n for n in mg.graph_def.node if n.op == 'VarHandleOp']
    print('PARAMETER_COUNT', sum(math.prod(d.size for d in n.attr['shape'].shape.dim) for n in variables))
    for n in variables:
        print('VARIABLE', n.name, [d.size for d in n.attr['shape'].shape.dim])
    functions = {f.signature.name: f for f in mg.graph_def.library.function}
    serving = next(n.attr['f'].func.name for n in mg.graph_def.node if n.name == 'StatefulPartitionedCall')
    wrapper = functions[serving]
    wrapped = next(n.attr['f'].func.name for n in wrapper.node_def if n.op == 'StatefulPartitionedCall')
    f = functions[wrapped]
    print('ENTRY_GRAPH', serving, '->', wrapped, 'RETURNS', dict(f.ret))
    for n in f.node_def:
        if n.op == 'Const':
            a = tensor_util.MakeNdarray(n.attr['value'].tensor)
            print('NODE', n.name, n.op, 'SHAPE', a.shape, 'VALUE', a.tolist() if a.size < 20 else '(omitted)')
        else:
            print('NODE', n.name, n.op, list(n.input))
        if n.op in ('If', 'StatelessIf'):
            for key in ('then_branch', 'else_branch'):
                name = n.attr[key].func.name
                branch = functions[name]
                print('BRANCH', key, name, 'RETURNS', dict(branch.ret))
                for bn in branch.node_def:
                    print(' BRANCH_NODE', bn.name, bn.op, list(bn.input))
    metadata = subprocess.check_output(['strings', str(p / 'keras_metadata.pb')], text=True)
    for line in metadata.splitlines():
        if line.startswith('{'):
            d, _ = json.JSONDecoder().raw_decode(line)
            print('KERAS_LAYER', d['class_name'], d.get('config'), 'INPUT', d.get('build_input_shape'))
