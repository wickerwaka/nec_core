import yaml
import sys

placeholders = {
    'MD': {
        'signal': 'mod',
    },
    'MEM': {
        'signal': 'rm',
    },
    'GP0': {
        'signal': 'reg0',
    },
    'GP1': {
        'signal': 'reg1',
    },
    'SR': {
        'signal': 'sreg',
    },
    'W': {
        'signal': 'width'
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
        return x in [ 'MODRM', 'DMEM' ]
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
        assignments.append( f"d.use_modrm = 1")

        if mem_type == 'DMEM':
            assignments.append( "d.rm = 3'b101" )
            assignments.append( "d.mod = 2'b00" )
            mem_type = 'MODRM'
        
        for k in list(mapping.keys()):
            if is_mem_type(mapping[k]):
                mapping[k] = mem_type
    else:
        assignments.append( f"d.use_modrm = 0")

    for k, v in mapping.items():
        assignments.append( f"d.{k} = OPERAND_{v}" )
    
    return assignments


def to_entry(k: str, op_desc: dict):
    if not k.startswith('b'):
        return None
    
    assignments = []

    opcode = op_desc.get('op')
    comment = op_desc.get('desc') or opcode
    assignments.append( f"d.opcode = OP_{opcode}" )

    alu_op = op_desc.get('alu', 'NONE')
    assignments.append( f"d.alu_operation = ALU_OP_{alu_op}" )
    
    sreg = op_desc.get('sreg')
    if sreg:
        assignments.append( f"d.sreg = {sreg}" )

    width = op_desc.get('width')
    if width:
        assignments.append( f"d.width = {width}" )

    assignments = assign_src_dst(op_desc, assignments)

    k = k[1:]
    k = k.replace('_', '')

    for pid, desc in placeholders.items():
        idx = k.find(pid)
        if idx != -1:
            start = 23 - idx
            end = 24 - (idx + len(pid))
            if start == end:
                if pid == 'W':
                    assignments.append( f"d.{desc['signal']} = q[{start}] ? WORD : BYTE" )
                else:
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
        'comment': comment,
        'vagueness': k.count('x'),
    }


input_name = 'docs/opcodes.yaml'
output_name = 'hdl/opcodes.svh'

opcode_desc = yaml.safe_load(open(input_name, 'r'))

cases = []
for k, v in opcode_desc.items():
    cases.append(to_entry(k, v))

cases.sort(key=lambda x: x['vagueness'])

with open(output_name, "wt") as fp:
    for c in cases:
        assigns = ';\n\t'.join(c['assignments'])
        comment = c['comment']
        match = c['match']
        fp.write( f"24'b{match}: begin /* {comment} */\n\t{assigns};\nend\n" )


for idx1 in range(len(cases)):
    for idx2 in range(idx1 + 1, len(cases)):
        if cases[idx1]['vagueness'] == cases[idx2]['vagueness'] and is_ambiguous(cases[idx1]['match'], cases[idx2]['match']):
            print(f"Ambiguous: {cases[idx1]['match']}  {cases[idx2]['match']}")

