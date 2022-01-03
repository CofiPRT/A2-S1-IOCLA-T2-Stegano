%include "include/io.inc"

extern atoi
extern printf
extern exit

; Functions to read/free/print the image.
; The image is passed in argv[1].
extern read_image
extern free_image
; void print_image(int* image, int width, int height);
extern print_image

; Get image's width and height.
; Store them in img_[width, height] variables.
extern get_image_width
extern get_image_height

section .data
        use_str db "Use with ./tema2 <task_num> [opt_arg1] [opt_arg2]", 10, 0
        searched_word db "revient", 0
        my_message db "C'est un proverbe francais.", 0

section .bss
    task:           resd 1
    img:            resd 1
    img_width:      resd 1
    img_height:     resd 1

section .text
global main
main:
    ; Prologue
    ; Do not modify!
    push ebp
    mov ebp, esp

    mov eax, [ebp + 8]
    cmp eax, 1
    jne not_zero_param

    push use_str
    call printf
    add esp, 4

    push -1
    call exit

not_zero_param:
    ; We read the image. You can thank us later! :)
    ; You have it stored at img variable's address.
    mov eax, [ebp + 12]
    push DWORD[eax + 4]
    call read_image
    add esp, 4
    mov [img], eax

    ; We saved the image's dimensions in the variables below.
    call get_image_width
    mov [img_width], eax

    call get_image_height
    mov [img_height], eax

    ; Let's get the task number. It will be stored at task variable's address.
    mov eax, [ebp + 12]
    push DWORD[eax + 8]
    call atoi
    add esp, 4
    mov [task], eax
    
    
    ; There you go! Have fun! :D
    mov eax, [task]
    cmp eax, 1
    je solve_task1
    cmp eax, 2
    je solve_task2
    cmp eax, 3
    je solve_task3
    cmp eax, 4
    je solve_task4
    cmp eax, 5
    je solve_task5
    cmp eax, 6
    je solve_task6
    jmp done
    
print_decoded_string:
    push ebp
    mov ebp, esp
    
    mov edi, [ebp + 8] ; the image
    
    push DWORD 0 ; column index, start of the line

byte_by_byte_print:
    mov eax, DWORD [ebp + 12] ; line index, already on stack
    mul DWORD [img_width] ; line * img_width
    add eax, DWORD [esp] ; column index
    
    mov bl, BYTE [ebp + 16] ; key, already on stack
    xor bl, BYTE [edi + eax*4] ; decode the character
    
    cmp bl, 0
    je end_print_decoded_string
    
    PRINT_CHAR bl
    
    inc DWORD [esp]
    mov ecx, DWORD [img_width]
    cmp DWORD [esp], ecx
    jl byte_by_byte_print
    
end_print_decoded_string:
    NEWLINE
    
    leave
    ret

bruteforce_singlebyte_xor:
    push ebp
    mov ebp, esp

    push DWORD 0 ; index through the word "revient"
    push DWORD 0 ; key
    push DWORD 0 ; column index (character/pixel)
    push DWORD 0 ; line index
    
    xor ebx, ebx ; prepare
    
    mov edi, [ebp + 8] ; the image
    
byte_by_byte_search:
    mov eax, DWORD [esp] ; line index
    mul DWORD [img_width] ; line * img_width
    add eax, DWORD [esp + 4] ; column index
    
    mov bl, BYTE [esp + 8] ; key
    xor bl, BYTE [edi + eax*4] ; decode the character
    
    cmp bl, 0
    je task1_next_line ; null terminated
    
    ; find word
    mov esi, DWORD [esp + 12] ; "revient" index
    
    cmp bl, BYTE [searched_word + esi]
    jne find_word_set_zero
    inc DWORD [esp + 12] ; next character
    jmp after_find_word
    
find_word_set_zero:
    mov DWORD [esp + 12], 0 ; word not found, reset index
    
after_find_word:
    cmp DWORD [esp + 12], 7 ; has found all the characters
    je task1_found_word
    
    ; next byte
    inc DWORD [esp + 4] ; column index
    mov eax, DWORD [img_width]
    cmp DWORD [esp + 4], eax
    jl byte_by_byte_search ; next byte
    
task1_next_line:
    mov DWORD [esp + 12], 0 ; not found of this line, reset "revient" index
    mov DWORD [esp + 4], 0 ; beginning of next line
    inc DWORD [esp] ; line index
    mov eax, DWORD [img_height]
    cmp DWORD [esp], eax
    jl byte_by_byte_search ; next line
    
    ; next key
    mov DWORD [esp], 0 ; beginning of the image
    inc DWORD [esp + 8] ; key
    cmp DWORD [esp + 8], 128
    jl byte_by_byte_search ; repeat for next key
    
task1_found_word:
    ; store key and line in eax
    xor eax, eax
    mov al, BYTE [esp + 8] ; key
    shl eax, 16 ; make space for a WORD
    mov ax, WORD [esp] ; line index
    
    leave
    ret

solve_task1:
    push DWORD [img]
    call bruteforce_singlebyte_xor
    add esp, 4
    
    mov ebx, eax
    shr ebx, 16 ; the key
    
    movzx ecx, ax ; the line index
    
    push ebx
    push ecx
    push DWORD [img]
    call print_decoded_string
    add esp, 4 ; for restoring ebx and ecx
    
    pop ecx
    pop ebx
    
    ; print key and line
    PRINT_UDEC 1, bl ; key
    NEWLINE
    
    PRINT_UDEC 2, cx ; line index
    NEWLINE
    
    jmp done
    
calculate_key:
    push ebp
    mov ebp, esp
    
    mov eax, [ebp + 8] ; get the key
    
    ; calculate according to the task
    xor edx, edx
    
    mov ebx, 2
    mul ebx
    
    add eax, 3
    
    mov ebx, 5
    div ebx ; quotitent (floor) is saved in eax
    
    sub eax, 4
    
    ; result already saved in eax
    leave
    ret
    
write_message:
    push ebp
    mov ebp, esp
        
    mov edi, [ebp + 8] ; the image
    mov edx, [ebp + 12] ; the message
    xor esi, esi ; index through the message
    
byte_by_byte_write:
    mov edx, [ebp + 12] ; the message
    mov bl, BYTE [edx + esi] ; current character 
        
    mov eax, DWORD [ebp + 16] ; line
    mul DWORD [img_width] ; line * img_width
    add eax, DWORD esi ; column index (same as "my_message" index)
    
    mov BYTE [edi + eax*4], bl ; write to img
    
    inc esi ; next index
    
    cmp bl, 0 ; write until null terminator
    jne byte_by_byte_write
    
    leave
    ret
    
apply_key_on_image:
    push ebp
    mov ebp, esp
    
    mov edi, [ebp + 8] ; image
    mov ebx, DWORD [ebp + 12] ; the key
    
    push DWORD 0 ; line index
    push DWORD 0 ; column index
    
byte_by_byte_apply:
    mov eax, DWORD [esp + 4] ; line index
    mul DWORD [img_width] ; line * img_width
    add eax, DWORD [esp] ; column index
    
    xor BYTE [edi + eax*4], bl ; apply key and save in image
    
    ; next column
    inc DWORD [esp] ; column index
    mov ecx, DWORD [img_width]
    cmp DWORD [esp], ecx
    jl byte_by_byte_apply
    
    ; next line
    inc DWORD [esp + 4] ; line index
    mov ecx, DWORD [img_height]
    cmp DWORD [esp + 4], ecx
    jl byte_by_byte_apply
    
    leave
    ret
    
solve_task2:
    push DWORD [img]
    call bruteforce_singlebyte_xor
    add esp, 4
    
    ; extract line and key from eax and save them on stack
    movzx ebx, ax ; the line
    push ebx
    
    mov ebx, eax
    shr ebx, 16 ; the key
    push ebx
    
    push DWORD [esp] ; the key
    push DWORD [img]
    call apply_key_on_image
    add esp, 4
    
    mov eax, DWORD [esp + 4] ; the line
    inc eax ; next line
    push eax
    push my_message
    push DWORD [img]
    call write_message
    add esp, 12
    
    push DWORD [esp] ; the key
    call calculate_key
    add esp, 4
    
    
    push eax ; calculated key
    push DWORD [img]
    call apply_key_on_image
    add esp, 8
    
    push DWORD [img_height]
    push DWORD [img_width]
    push DWORD [img]
    call print_image
    add esp, 12
    
    add esp, 8 ; the pushed key and line
       
    jmp done
solve_task3:
    ; TODO Task3
    jmp done
solve_task4:
    ; TODO Task4
    jmp done
solve_task5:
    ; TODO Task5
    jmp done
solve_task6:
    ; TODO Task6
    jmp done

    ; Free the memory allocated for the image.
done:
    push DWORD[img]
    call free_image
    add esp, 4

    ; Epilogue
    ; Do not modify!
    xor eax, eax
    leave
    ret
    
