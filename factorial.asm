global main

extern printf, scanf

section .rodata
   request_input:       db "Enter a number: ",                    10, 0
   invalid_input_msg:   db "Number must be 0<n<24!",              10, 0
   result_msg:          db "The factorial of your number is: %f", 10, 0
   input_format:        db "%f",                                  0

section .data
   limit:   dd 24.0
   input:   dd 0.0
   next:    dd 0.0
   result:  dd 1.0

section .text
main:
   sub   rsp, 8 ; align the stack to a 16B boundary before function calls

factorial_setup:
   mov   rdi,  request_input    ; set printf message
   xor   eax,  eax              ; no xmm registers
   call  printf                 ; call printf

   lea   rdi,  [input_format]   ; set format
   lea   rsi,  [input]          ; set address of input buffer
   xor   eax,  eax              ; no xmm registers
   call  scanf                  ; call scanf

   finit                        ; initializes FPU (clears FPU registers when wrong input)
   fld   dword[input]           ; push input to FPU
   fld   dword[input]           ; push input to FPU (this one is used for validation)

   fld   dword[limit]            ; push limit to FPU
   fcomp st0,  st1               ; compare st0 with st1, pop st0 (limit with input)
   fstsw ax                      ; ax := fpu status register
   and   eax,  0100011100000000B ; take only condition code flags
   cmp   eax,  0000000100000000B ; is limit < input ?
   je    invalid_input           ; jump if ^ is true

   fld1                          ; push 1 to FPU
   fcomp st0,  st1               ; compare st0 with st1, pop st0 (1 with input)
   fstsw ax                      ; ax := fpu status register
   and   eax,  0100011100000000B ; take only condition code flags
   cmp   eax,  0100000000000000B ; is 1 = input ?
   je    print_result            ; jump if ^ is true
   cmp   eax,  0000000000000000B ; is 1 > input ?
   je    invalid_input           ; jump if ^ is true

factorial_loop:

   fld1             ; push 1 to FPU
   fsubp st1,  st0  ; subtract 1 from input

   fst   dword[next]    ; store decreased input as next

   fmul                 ; multiplies st0 with st1 (input with next)
   fld   dword[next]    ; push next to FPU

   fld1                             ; push 1 to FPU
   fcomp st0,  st1                  ; compare st0 with st1, pop st0 (1 with next)
   fstsw ax                         ; ax := fpu status register
   and   eax,  0100011100000000B    ; take only condition code flags
   cmp   eax,  0100000000000000B    ; is next = 1 ?
   jne   factorial_loop             ; jump if ^ is not true

   fincstp              ; pop the top of the stack
   fstp  qword[result]  ; write top of stack into variable result, pop st0

print_result:
   movq  xmm0, qword[result]    ; load second parameter of printf
   mov   rdi,  result_msg       ; load format for printf
   mov   rax,  1                ; indicate number of parameters (excluding format)
   call  printf                 ; call printf

   add   rsp,  8    ; restore the stack
   ret

invalid_input:
   mov   rdi,  invalid_input_msg    ; load format for printf
   xor   eax,  eax                  ; no xmm registers (no additional parameters needed)
   call  printf                     ; calls printf
   jmp   factorial_setup            ; unconditional return to start
