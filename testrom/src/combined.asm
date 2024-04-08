BITS 16

%macro single_op 1
    align 2
    mov cl, 11 ; 2
    ror ax, cl ; 2
    in al, 0xf2 ; 2
    %rep 64
    %1
    %endrep
    in al, 0xf4
%endmacro


global combined_timing
combined_timing:
    enter 4096, 0
    mov ax, ss
    mov es, ax
    mov si, sp
    mov di, sp

    mov ax, 0xb000
    mov ds, ax
    xor bx, bx

.start:

    single_op { nop }
    single_op { inc al }
    single_op { inc ax }

    single_op { mov cx, 0x01 }
    single_op { mov cx, 0x0101 }
    single_op { mov cx, [bx] }
    single_op { mov cx, [bx+0x02] }
    single_op { mov cx, ss:[bx+0x02] }
    single_op { mov [bx], cx }
    single_op { mov [bx+0x02], cx }
    single_op { mov ss:[bx+0x02], cx }

    single_op { add cx, 0x01 }
    single_op { add cx, 0x0101 }
    single_op { add cx, [bx] }
    single_op { add cx, [bx+0x02] }
    single_op { add cx, ss:[bx+0x02] }
    single_op { add [bx], cx }
    single_op { add [bx+0x02], cx }
    single_op { add ss:[bx+0x02], cx }

    single_op { push ax }
    single_op { pop ax }
    single_op { pusha }
    single_op { popa }

    single_op { daa }
    single_op { das }
    single_op { aad }
    single_op { aas }

    single_op { cmp cx, 0x0101 }
    single_op { cmp cx, [bx] }
    single_op { cmp cx, [bx+0x02] }
    single_op { cmp cx, ss:[bx+0x02] }

    mov dx, 0xdead
    out dx, al
    jmp .start
