import yaml

placeholders = {
    'MD': {
        'signal': 'ea_mod',
    },
    'MEM': {
        'signal': 'ea_mem',
    },
    'GP0': {
        'signal': 'reg0',
    },
    'GP1': {
        'signal': 'reg1',
    },
    'SR': {
        'signal': 'sreg'
    }
}

def is_ambiguous(case1, case2):
    for a, b in zip(case1, case2):
        if a == 'x' or b == 'x':
            continue
        if a != b:
            return False
    return True

def assign_src_dst(op_desc, assignments):
    def is_mem_type(x):
        return x in [ 'MEM8', 'MEM16', 'MEM32', 'DMEM8', 'DMEM16' ]
    src = op_desc.get('src')
    src0 = op_desc.get('src0', 'NONE')
    src1 = op_desc.get('src1', 'NONE')
    dst = op_desc.get('dst', 'NONE')

    if src:
        src0 = src
        src1 = 'NONE'

    mapping = { 'dest': dst, 'source0': src0, 'source1': src1 }

    found = {}
    for o in mapping.values():
        if is_mem_type(o):
            found[o] = True
    
    if len(found) > 1:
        raise "Conflicting memory operands"

    if len(found) == 1:
        mem_type = list(found.keys())[0]
        assignments.append( f"d.calc_ea = 1")

        if mem_type == 'DMEM8':
            assignments.append( "d.ea_mem = 3'b110" )
            assignments.append( "d.ea_mod = 2'b11" )
            mem_type = 'MEM8'
        elif mem_type == 'DMEM16':
            assignments.append( "d.ea_mem = 3'b110" )
            assignments.append( "d.ea_mod = 2'b11" )
            mem_type = 'MEM16'
        
        for k in list(mapping.keys()):
            if is_mem_type(mapping[k]):
                mapping[k] = mem_type
        
    else:
        assignments.append( f"d.calc_ea = 0")

    for k, v in mapping.items():
        assignments.append( f"d.{k} = OPERAND_{v}" )
    
    return assignments


def to_entry(k: str, op_desc: dict):
    if not k.startswith('b'):
        return None
    
    assignments = []

    opcode = op_desc.get('name')
    assignments.append( f"d.opcode = OP_{opcode}" )

    alu_op = op_desc.get('alu', 'NONE')
    assignments.append( f"d.alu_operation = ALU_OP_{alu_op}" )
    
    sreg = op_desc.get('sreg')
    if sreg:
        assignments.append( f"d.sreg = {sreg}")

    assignments = assign_src_dst(op_desc, assignments)

    k = k[1:]
    k = k.replace('_', '')

    for pid, desc in placeholders.items():
        idx = k.find(pid)
        if idx != -1:
            start = 23 - idx
            end = 24 - (idx + len(pid))
            if start == end:
                assignments.append( f"d.{desc['signal']} = q[{start}]" )
            else:
                assignments.append( f"d.{desc['signal']} = q[{start}:{end}]" )
            k = k.replace(pid, 'x' * len(pid))
    
    
    pre_size = (len(k) + 7) // 8
    assignments.append( f"d.pre_size = {pre_size}" )
    assignments.append( f"valid_op <= 1" )

    k = k + 'x' * (24 - len(k))

    return {
        'match': k,
        'assignments': assignments,
        'name': opcode,
        'vagueness': k.count('x'),
    }

opcode_desc = yaml.safe_load(open('docs/opcodes.yaml', 'r'))

cases = []
for k, v in opcode_desc.items():
    cases.append(to_entry(k, v))

cases.sort(key=lambda x: x['vagueness'])

for c in cases:
    assigns = '; '.join(c['assignments'])
    name = c['name']
    match = c['match']
    print( f"24'b{match}: begin {assigns}; end" )


for idx1 in range(len(cases)):
    for idx2 in range(idx1 + 1, len(cases)):
        if cases[idx1]['vagueness'] == cases[idx2]['vagueness'] and is_ambiguous(cases[idx1]['match'], cases[idx2]['match']):
            print(f"Ambiguous: {cases[idx1]['match']}  {cases[idx2]['match']}")

