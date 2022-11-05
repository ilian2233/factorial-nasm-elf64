global main

extern printf, scanf

section .rodata
   request_input:       db "Enter a number: ",                    10, 0
   invalid_input_msg:   db "Number must be 0<n<24!",              10, 0
   result_msg:          db "The factorial of your number is: %f", 10, 0
   input_format:        db "%f",                                  0

section .data
   limit:   dd 24.0
   input:   dd  0.0
   next:    dd  0.0
   result:  dd 1.0

section .text
main:
   sub   rsp, 8       ; align the stack to a 16B boundary before function calls

factorial_setup:
   mov   rdi,  request_input      ; sets the printf message
   xor   eax,  eax      ; no xmm registers
   call  printf       ; calls printf

   lea   rdi,  [input_format] ; 1st arg = format
   lea   rsi,  [input] ; 2nd arg = address of buffer
   xor   eax,  eax      ; no xmm registers
   call  scanf        ; stores input in input

   finit
   fld   dword[input]
   fld   dword[input]

   fld   dword[limit]
   fcomp st0,  st1               ;compare st0 with st1
   fstsw ax                     ;ax := fpu status register
   and   eax,  0100011100000000B ;take only condition code flags
   cmp   eax,  0000000100000000B ;is limit < input ?
   je    invalid_input

   fld1
   fcomp st0,  st1               ;compare st0 with st1
   fstsw ax                     ;ax := fpu status register
   and   eax,  0100011100000000B ;take only condition code flags
   cmp   eax,  0100000000000000B ;is st0 = source ?
   je    print_result
   cmp   eax,  0000000000000000B ;is st0 > source ?
   je    invalid_input

factorial_loop:

   ;decrease value by 1
   fld1
   fsubp st1,  st0

   ;stores the decreased value as counter
   fst   dword[next]

   fmul
   fld   dword[next]

   fld1
   fcomp st0,  st1               ;compare st0 with st1
   fstsw ax                     ;ax := fpu status register
   and   eax,  0100011100000000B ;take only condition code flags
   cmp   eax,  0100000000000000B ;is st0 = 1 ?
   jne   factorial_loop

   fincstp  ;pops the 1 left from iteration
   fstp  qword[result] ;writes and pops the result

print_result:
   movq  xmm0, qword[result]
   mov   rdi,  result_msg
   mov   rax,  1
   call  printf

   add   rsp,  8      ; restore the stack
   ret

invalid_input:
   mov   rdi,  invalid_input_msg      ; sets the printf message
   xor   eax,  eax      ; no xmm registers
   call  printf       ; calls printf
   jmp   factorial_setup