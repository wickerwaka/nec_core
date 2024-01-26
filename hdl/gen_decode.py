import yaml

placeholders = {
    's': {
        'signal': 'sign_extend',
    },
    'W': {
        'signal': 'wide',
    },
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
    }
}

def is_ambiguous(case1, case2):
    for a, b in zip(case1, case2):
        if a == 'x' or b == 'x':
            continue
        if a != b:
            return False
    return True

def to_entry(k: str, op_desc: dict):
    if not k.startswith('b'):
        return None
    
    assignments = []

    opcode = op_desc.get('name')
    assignments.append( f"opcode <= OP_{opcode}" )

    alu_op = op_desc.get('alu', 'NONE')
    assignments.append( f"alu_operation <= ALU_OP_{alu_op}" )
    src = op_desc.get('src')
    if src:
        src = src.replace('GP0', 'REG0').replace('GP1', 'REG1')
        assignments.append( f"op_source <= OP_SRC_{src}" )

    dst = op_desc.get('dst')
    if dst:
        dst = dst.replace('GP0', 'REG0').replace('GP1', 'REG1')
        assignments.append( f"op_dest <= OP_DST_{dst}" )

    k = k[1:]
    k = k.replace('_', '')

    for pid, desc in placeholders.items():
        idx = k.find(pid)
        if idx != -1:
            start = 23 - idx
            end = 24 - (idx + len(pid))
            if start == end:
                assignments.append( f"{desc['signal']} <= q[{start}]" )
            else:
                assignments.append( f"{desc['signal']} <= q[{start}:{end}]" )
            k = k.replace(pid, 'x' * len(pid))
    
    
    pre_size = (len(k) + 7) // 8
    assignments.append( f"pre_size <= {pre_size}" )
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

cases.sort(key=lambda x: x['vagueness'], reverse=True)

for c in cases:
    assigns = '; '.join(c['assignments'])
    name = c['name']
    match = c['match']
    print( f"24'b{match}: begin {assigns}; end" )


for idx1 in range(len(cases)):
    for idx2 in range(idx1 + 1, len(cases)):
        if is_ambiguous(cases[idx1]['match'], cases[idx2]['match']):
            print(f"Ambiguous: {cases[idx1]['match']}  {cases[idx2]['match']}")

