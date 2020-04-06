format ELF64 executable 3
entry start

macro stdcall proc, [arg]
{  reverse push arg
   common call proc 
}

segment readable executable
start:
        stdcall         printf, msg, lovestr, 3802, 100, '!', 127, -15

        mov     rax, 1
        xor     rbx, rbx
        int     80h

;========================================================
;printf
;Exit:
;rax - 0 
;Destr:
;rcx, rdx, rbx, rsi, rdi, r8, r9, r10, r15
;========================================================
printf: 
        push    rbp
        mov     rbp, rsp
        
        mov     rsi, [rbp + 16]     ;string to write
        mov     r8, rbp
        add     r8, 24              ;ptr to first arg

@@printLoop:
        mov     rcx, rsi
        mov     ah, '%'
        call    strchr

        mov     rdx, rsi 
        sub     rdx, rcx
        dec     rdx
        mov     rax, 4
        mov     rbx, 1
        int     80h 

        mov     al, [rsi]
        call    determineType

        
        mov     rax, 4
        mov     rbx, 1
        mov     rcx, r9
        mov     rdx, r10
        int     80h 

        add     r8, 8
        inc     rsi
        mov     al, [rsi]
        cmp     al, 0
        jne     @@printLoop

        xor     rax, rax
        mov     rsp, rbp
        pop     rbp
        ret

;========================================================
;determine type of arg
;entry:
;al - identificator
;r8 - pointer to arg
;exit:
;r9 - pointer to argStr
;r10 - argStr len
;destr:
;ax, rbx
;========================================================
determineType:
        cmp     al, 'x'
        ja      defaultDet

        jmp     qword [determineTable + eax*8 - '%'*8]
        
char:
        mov     al, [r8]
        mov     [argStr], al
        
        mov     r9, argStr
        mov     r10, 1
        ret

procent:
        mov     [argStr], '%'
        
        sub     r8, 8
        mov     r9, argStr
        mov     r10, 1
        ret

string:
        mov     rdi, [r8]
        call    strlen
        
        mov     r9, [r8]
        mov     r10, rbx
        ret

hex:
        mov     rbx, [r8]
        mov     rcx, 16
        call    itoa
        
        ret

bin:  
        mov     rbx, [r8]
        mov     rcx, 2
        call    itoa
        
        ret
oct:
        mov     rbx, [r8]
        mov     rcx, 8
        call    itoa
        
        ret

decimal:
        mov     ah, 'd'
        cmp     ah, al

        mov     rbx, [r8]
        mov     rcx, 10
        call    itoa
        
        ret

defaultDet:
        xor r9, r9
        xor r10, r10

        ret

;========================================================
;Strchr func from C
;
;Entry:
;rsi - pointer to string
;ah - char to find
;
;Exit:
;rsi - pointer to char
;Destr:
;di, al
;========================================================
strchr:
        mov     bl, 0
        cld

@@find:     
        lodsb
        cmp     bl, al
        je      @@NotFound
        cmp     ah, al
        jne     @@find
        ret

@@NotFound: 
        mov     rsi, 0
        ret

;========================================================
;Strlen func from C
;
;Entry:
;rdi - pointer to string
;
;Exit:
;rbx - buffer len
;Destr:
;rcx, rsi, al
;========================================================
strlen:
        xor     rcx, rcx
        dec     rcx
        mov     rbx, rcx
        xor     al, al
        cld
        repne scasb
        sub     rbx, rcx

        ret

;========================================================
;itoa
;entry:
;rbx - number
;rcx - numSys
;Exit:
;r9 - pointer to outStr
;r10 - outStr len
;Destr:
;rax, rcx
;========================================================
itoa:
        xor     r10, r10
        xor     r15, r15 

@@itoa16:
        cmp     cl, 16
        jne     @@itoa2 

        add     r15, 0xf    ;mask 16
        shr     cl, 2

        jmp     @@loopBin

@@itoa2:
        cmp     cl, 2
        jne     @@itoa8 
   
        inc     r15         ;mask 2
        shr     cl, 1

        jmp     @@loopBin

@@itoa8:
        cmp     cl, 8
        jne     @@itoa10 
 
        add     r15, 7       ;mask 8
        mov     cl, 3

@@loopBin:
        mov     rax, rbx
        and     rax, r15
        add     rax, numbers
        mov     rax, [rax]
        push    rax
        shr     rbx, cl
        inc     r10

        cmp     rbx, 0
        jne     @@loopBin
        
        jmp     @@forward

@@itoa10:
        mov     rax, rbx
        cmp     cl, 10 
        jne     @@notNum

        xor     r15, r15            ;mask for negative numbers
        inc     r15
        shl     r15, 16*4 - 1
        
        and     rax, r15
        cmp     rax, r15
        jne     @@notNeg
        mov     rax, rbx
        mov     r15, 1
        neg     rax

        jmp     @@loop10
        
@@notNeg:
        mov     rax, rbx
        xor     r15, r15

@@loop10:
        xor     rdx, rdx
        div     rcx
        add     rdx, numbers
        mov     rdx, [rdx]
        push    rdx
        inc     r10

        cmp     rax, 0
        jne     @@loop10

@@forward10:
        mov     rax, argStr
        mov     rcx, r10

        cmp     r15, 1
        jne     @@forwLoop
        mov     [argStr], '-'
        inc     rax
        inc     r10

        jmp     @@forwLoop

@@forward:
        mov     rax, argStr
        mov     rcx, r10

@@forwLoop:
        pop     rbx
        mov     [rax], rbx
        inc     rax
        loop    @@forwLoop

        mov     r9, argStr
        ret

@@notNum:
        xor     r9, r9
        xor     r10, r10
        ret




segment readable writeable
argStr  db      256 dup(0)
numbers db      "0123456789abcdef", 0
determineTable:
dq      procent
dq      60 dup (defaultDet)
dq      bin
dq      char
dq      decimal
dq      10 dup (defaultDet)
dq      oct
dq      3 dup (defaultDet)
dq      string
dq      4 dup (defaultDet)
dq      hex  


msg     db      "I %s %x %d%%%c%b %d", 0
lovestr db      "love", 0
