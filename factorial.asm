global main

extern printf, scanf

default rel            ; make [rel format] the default, you always want this.

section .rodata
   request_input: db "Enter a number: ", 10, 0
   invalid_input_msg: db "Number must be 0<n<24!", 10, 0
   result_msg: db "The factorial of your number is: %d", 13, 10, 0
   input_format: db "%d",0

section .data
   input: dd  0
   next: dd  0
   result: dd 1

section .text
main:
   sub  rsp, 8       ; align the stack to a 16B boundary before function calls

factorial_setup:
   mov rdi, request_input      ; sets the printf message
   xor eax, eax      ; no xmm registers
   call printf       ; calls printf

   lea rdi, [input_format] ; 1st arg = format
   lea rsi, [input] ; 2nd arg = address of buffer
   xor eax, eax      ; no xmm registers
   call scanf        ; stores input in input

   cmp byte [input], 24
   jg invalid_input          ; jump to l1
   cmp byte [input], 1
   je print_result          ; jump to l1
   cmp byte [input], 0
   jng invalid_input          ; jump to l1

   finit

   ;store initial value
   fild   dword [input]
   mov   r12, [input]   ; "%x" takes a 32-bit unsigned int

factorial_loop:

   ;decrease value by 1
   sub   r12,  1

   ;store decreased value
   mov [next], r12
   fild dword [next]

   ;multiply
   fmul

   cmp byte [next], 1
   jg factorial_loop

   ;extract final value
   fistp   dword [result]

print_result:
   mov   rsi, [result]
   lea   rdi, [rel result_msg]
   xor   eax, eax           ; AL=0  no FP args in XMM regs
   call  printf

   add   rsp, 8      ; restore the stack
   ret

invalid_input:
   mov rdi, invalid_input_msg      ; sets the printf message
   xor eax, eax      ; no xmm registers
   call printf       ; calls printf
   jmp factorial_setup

;TODO: Make work with 12<n<23