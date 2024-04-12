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


%ifidni TEST_NAME,alu_timing
global alu_timing
alu_timing:
.start:
    single_op { inc al }
    single_op { inc ax }

    single_op { add cx, 0x01 }
    single_op { add cx, 0x0101 }
    single_op { add cx, [bx] }
    single_op { add cx, [bx+0x02] }
    single_op { add cx, ss:[bx+0x02] }
    single_op { add [bx], cx }
    single_op { add [bx+0x02], cx }
    single_op { add ss:[bx+0x02], cx }

    single_op { daa }
    single_op { das }
    single_op { aaa }
    single_op { aas }

    single_op { cmp cx, 0x0101 }
    single_op { cmp cx, [bx] }
    single_op { cmp cx, [bx+0x02] }
    single_op { cmp cx, ss:[bx+0x02] }

    mov dx, 0xdead
    out dx, al
    jmp .start
%endif

%ifidni TEST_NAME,block_timing
global block_timing
block_timing:
.start:

    single_op { stosb }
    single_op { stosw }
    single_op { lodsb }
    single_op { lodsw }
    single_op { movsb }
    single_op { movsw }
    single_op { cmpsb }
    single_op { cmpsw }
    single_op { db 0x0f, 0x20 } ; add4s
    single_op { db 0x0f, 0x22 } ; sub4s
    single_op { db 0x0f, 0x26 } ; cmp4s

    block_op { stosb }
    block_op { stosw }
    block_op { lodsb }
    block_op { lodsw }
    block_op { movsb }
    block_op { movsw }
    block_op { cmpsb }
    block_op { cmpsw }
    block_op { db 0x0f, 0x20 } ; add4s
    block_op { db 0x0f, 0x22 } ; sub4s
    block_op { db 0x0f, 0x26 } ; cmp4s

    mov dx, 0xdead
    out dx, al
    jmp .start
%endif


%ifidni TEST_NAME,stack_timing
global stack_timing
stack_timing:
.start:

    single_op { push ax }
    single_op { pop ax }
    single_op { pusha }
    single_op { popa }

    mov dx, 0xdead
    out dx, al
    jmp .start
%endif


%ifidni TEST_NAME,mov_timing
global mov_timing
mov_timing:
.start:

    single_op { mov cx, bx }
    single_op { mov cx, 0x01 }
    single_op { mov cx, 0x0101 }
    single_op { mov cx, [bx] }
    single_op { mov cx, [bx+0x02] }
    single_op { mov cx, ss:[bx+0x02] }
    single_op { mov [bx], cx }
    single_op { mov [bx+0x02], cx }
    single_op { mov ss:[bx+0x02], cx }
    single_op { xchg ax, cx }
    single_op { xchg cx, [bx] }
    single_op { xchg [bx], di }

    single_op { lea ax, [bx] }
    single_op { lea ax, [bx+0x400] }

    mov dx, 0xdead
    out dx, al
    jmp .start
%endif

%ifidni TEST_NAME,shift_timing
global shift_timing
shift_timing:
.start:

    single_op { ror ax, 1 }
    single_op { ror ax, 2 }
    single_op { ror ax, 9 }
    single_op { ror ax, 20 }

    multi_op_begin
    mov cl, 1
    %rep 64
    ror ax, cl
    %endrep
    multi_op_end

    multi_op_begin
    mov cl, 2
    %rep 64
    ror ax, cl
    %endrep
    multi_op_end

    multi_op_begin
    mov cl, 9
    %rep 64
    ror ax, cl
    %endrep
    multi_op_end

    multi_op_begin
    mov cl, 20
    %rep 64
    ror ax, cl
    %endrep
    multi_op_end

    single_op { ror word [bx], 9 }

    mov dx, 0xdead
    out dx, al
    jmp .start
%endif

%ifidni TEST_NAME,misc_timing
global misc_timing
misc_timing:
.start:

    single_op { nop }
    single_op { aam }
    single_op { aad }
    single_op { cbw }
    single_op { cwd }

    mov dx, 0xdead
    out dx, al
    jmp .start
%endif

%ifidni TEST_NAME,mul_timing
global mul_timing
mul_timing:
.start:

    single_op { mul al }
    single_op { mul ax }
    single_op { mul byte [bx] }
    single_op { mul word [bx] }

    single_op { imul al }
    single_op { imul ax }
    single_op { imul byte [bx] }
    single_op { imul word [bx] }

    single_op { imul ax, 0x71 }
    single_op { imul ax, 0x0171 }

    single_op { imul ax, word [bx], 0x03 }
    single_op { imul ax, word [bx], 0x0171 }

    mov dx, 0xdead
    out dx, al
    jmp .start
%endif

%ifidni TEST_NAME,div_timing
global div_timing
div_timing:
.start:
    multi_op_begin
    mov cl, 0x2
    %rep 64
    mov ax, 0x0040
    div cl
    %endrep
    multi_op_end

    multi_op_begin
    mov byte [bx], 0x2
    %rep 64
    mov ax, 0x0040
    div byte [bx]
    %endrep
    multi_op_end

    multi_op_begin
    mov cx, 0x2
    %rep 64
    mov dx, 0x0000
    mov ax, 0x4000
    div cx
    %endrep
    multi_op_end

    multi_op_begin
    mov word [bx], 0x2
    %rep 64
    mov dx, 0x0000
    mov ax, 0x4000
    div word [bx]
    %endrep
    multi_op_end

    multi_op_begin
    mov cl, 0x2
    %rep 64
    mov ax, 0x0040
    idiv cl
    %endrep
    multi_op_end

    multi_op_begin
    mov byte [bx], 0x2
    %rep 64
    mov ax, 0x0040
    idiv byte [bx]
    %endrep
    multi_op_end

    multi_op_begin
    mov cx, 0x2
    %rep 64
    mov dx, 0x0000
    mov ax, 0x4000
    idiv cx
    %endrep
    multi_op_end

    multi_op_begin
    mov word [bx], 0x2
    %rep 64
    mov dx, 0x0000
    mov ax, 0x4000
    idiv word [bx]
    %endrep
    multi_op_end

    mov dx, 0xdead
    out dx, al
    jmp .start
%endif
