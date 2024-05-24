BITS 16

%macro multi_op_init 0
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
%endmacro

%macro multi_op_start 0
    in al, 0xf2 ; 2
%endmacro

%macro multi_op_begin 0
    multi_op_init
    multi_op_start
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

%macro block_op 2
    multi_op_begin
    %rep 8
    mov cx, %1
    rep %2
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

    mov dx, 0x60
    single_op { insb }
    single_op { insw }
    single_op { outsb }
    single_op { outsw }



    block_op 253, { stosb }
    block_op 143, { stosw }
    block_op 253, { lodsb }
    block_op 143, { lodsw }
    block_op 253, { movsb }
    block_op 143, { movsw }
    block_op 253, { cmpsb }
    block_op 143, { cmpsw }

    mov dx, 0x60
    block_op 253, { insb }
    block_op 143, { insw }
    block_op 253, { outsb }
    block_op 143, { outsw }

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
    single_op { push word [bx] }
    single_op { pop word [bx] }
    single_op { push 0xf00d }
    single_op { pusha }
    single_op { popa }

    single_op { leave }
    single_op { enter 16, 0 }
    single_op { enter 16, 1 }
    single_op { enter 16, 2 }
    single_op { enter 16, 3 }
    single_op { enter 16, 4 }

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

    single_op { les ax, [bx] }
    single_op { lds ax, [bx+0x400] }

    single_op { xlatb }
    single_op { lahf }

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

    mov word [bx], 0x0000
    mov word [bx+2], 0x7fff
    single_op { bound bx, [bx] }

    mov dx, 0xdead
    out dx, al
    jmp .start
%endif

%ifidni TEST_NAME,nec_timing
global nec_timing
nec_timing:
.start:
    single_op { db 0x0f, 0x11, 0xc0 } ;       test1 al, cl
    single_op { db 0x0f, 0x11, 0x07 } ;       test1 [bx], cl

    single_op { db 0x0f, 0x13, 0xc0 } ;       clr1 al, cl
    single_op { db 0x0f, 0x13, 0x07 } ;       clr1 [bx], cl

    single_op { db 0x0f, 0x15, 0xc0 } ;       set1 al, cl
    single_op { db 0x0f, 0x15, 0x07 } ;       set1 [bx], cl

    single_op { db 0x0f, 0x17, 0xc0 } ;       not1 al, cl
    single_op { db 0x0f, 0x17, 0x07 } ;       not1 [bx], cl

    single_op { db 0x0f, 0x19, 0xc0, 0x03 } ; test1 al, 3
    single_op { db 0x0f, 0x19, 0x07, 0x03 } ; test1 [bx], 3

    single_op { db 0x0f, 0x1b, 0xc0, 0x03 } ; clr1 al, 3
    single_op { db 0x0f, 0x1b, 0x07, 0x03 } ; clr1 [bx], 3

    single_op { db 0x0f, 0x1d, 0xc0, 0x03 } ; set1 al, 3
    single_op { db 0x0f, 0x1d, 0x07, 0x03 } ; set1 [bx], 3

    single_op { db 0x0f, 0x1f, 0xc0, 0x03 } ; not1 al, 3
    single_op { db 0x0f, 0x1f, 0x07, 0x03 } ; not1 [bx], 3

    multi_op_begin
    mov cl, 8
    %rep 64
    db 0x0f, 0x20 ; add4s
    %endrep
    multi_op_end

    multi_op_begin
    mov cl, 18
    %rep 64
    db 0x0f, 0x20 ; add4s
    %endrep
    multi_op_end

    multi_op_begin
    mov cl, 8
    %rep 64
    db 0x0f, 0x26 ; cmp4s
    %endrep
    multi_op_end

    multi_op_begin
    mov cl, 18
    %rep 64
    db 0x0f, 0x26 ; cmp4s
    %endrep
    multi_op_end

    single_op { db 0x0f, 0x28, 0xc0 } ; rol4 al
    single_op { db 0x0f, 0x28, 0x07 } ; rol4 [bx]

    multi_op_begin
    mov ax, 0x1234
    mov word [di], 0x0000
    mov word [di+2], 0x0000
    mov word [di+4], 0x0000
    mov word [di+6], 0x0000

    db 0x0f, 0x39, 0xc3, 0x00 ; ins
    db 0x0f, 0x39, 0xc3, 0x03
    db 0x0f, 0x39, 0xc3, 0x06
    db 0x0f, 0x39, 0xc3, 0x0b
    db 0x0f, 0x39, 0xc3, 0x0d
    db 0x0f, 0x39, 0xc3, 0x0f
    multi_op_end

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

%ifidni TEST_NAME,branch_timing
global branch_timing
branch_timing:
.start:

    single_op { db 0x73, 0x00 } ; bnc
    single_op { db 0x72, 0x00 } ; bc
    single_op { db 0xe9, 0x00, 0x00 } ; br near-label
    single_op { db 0xeb, 0x00 } ; br short-label

    multi_op_begin
    %rep 64
    mov cx, 15
    db 0xe2, -2 ; loop/dbnz
    %endrep
    multi_op_end

    multi_op_begin
    mov cx, 256
    mov word [bx], .ind_dest
    .ind_loop:
    jmp [bx]
    .ind_dest:
    loop .ind_loop
    multi_op_end

    multi_op_begin
    mov cx, 256
    mov word [bx], .ind32_dest
    mov word [bx + 2], 0x0
    .ind32_loop:
    jmp far [bx]
    .ind32_dest:
    loop .ind32_loop
    multi_op_end

    multi_op_begin
    mov cx, 256
    .far_loop:
    jmp 0x0:.far_dest
    .far_dest:
    loop .far_loop
    multi_op_end

    multi_op_init
    push .ret_end
    %rep 64
    push .ret_loop
    %endrep
    multi_op_start
    .ret_loop:
    ret
    .ret_end:
    multi_op_end

    multi_op_init
    push cs
    push .retf_end
    %rep 64
    push cs
    push .retf_loop
    %endrep
    multi_op_start
    .retf_loop:
    retf
    .retf_end:
    multi_op_end

    multi_op_begin
    mov cx, 256
    .call_near_loop:
    call .call_near_dest
    .call_near_dest:
    loop .call_near_loop
    multi_op_end

    multi_op_begin
    mov cx, 256
    .call_far_loop:
    call 0x0:.call_far_dest
    .call_far_dest:
    loop .call_far_loop
    multi_op_end

    multi_op_begin
    mov cx, 256
    mov word bx, .call_reg_dest
    .call_reg_loop:
    call bx
    .call_reg_dest:
    loop .call_reg_loop
    multi_op_end

    multi_op_begin
    mov cx, 256
    mov word [bx], .call_ind_dest
    .call_ind_loop:
    call [bx]
    .call_ind_dest:
    loop .call_ind_loop
    multi_op_end

    multi_op_begin
    mov cx, 256
    mov word [bx], .call_ind32_dest
    mov word [bx + 2], 0x0
    .call_ind32_loop:
    call far [bx]
    .call_ind32_dest:
    loop .call_ind32_loop
    multi_op_end

    mov dx, 0xdead
    out dx, al
    jmp .start

%endif
