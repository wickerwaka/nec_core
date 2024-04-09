BITS 16

%macro multi_op_begin 0
    mov ax, ss
    mov es, ax
    mov ds, ax
    mov ax, 0x8000
    mov sp, ax
    mov bp, ax
    mov si, ax
    mov di, ax
    xor bx, bx

    align 2
    mov cl, 11 ; 2
    ror ax, cl ; 2
    in al, 0xf2 ; 2
%endmacro

%macro multi_op_end 0
    in al, 0xf4
%endmacro

%macro single_op 1
    multi_op_begin
    %rep 64
    %1
    %endrep
    multi_op_end
%endmacro

%macro block_op 1
    multi_op_begin
    %rep 8
    mov cx, 256
    rep %1
    %endrep
    multi_op_end
%endmacro



global combined_timing
combined_timing:
    enter 4096, 0

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

    single_op { stosb }
    single_op { stosw }
    single_op { lodsb }
    single_op { lodsw }
    single_op { movsb }
    single_op { movsw }
    single_op { cmpsb }
    single_op { cmpsw }

    block_op { stosb }
    block_op { stosw }
    block_op { lodsb }
    block_op { lodsw }
    block_op { movsb }
    block_op { movsw }
    block_op { cmpsb }
    block_op { cmpsw }

    mov dx, 0xdead
    out dx, al
    jmp .start
