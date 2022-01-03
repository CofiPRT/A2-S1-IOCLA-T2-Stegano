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

section .bss
    task:           resd 1
    img:            resd 1
    img_width:      resd 1
    img_height:     resd 1

section .rodata
        searched_word db "revient", 0
        my_message db "C'est un proverbe francais.", 0
        morse_A db ".-", 0
        morse_B db "-...", 0
        morse_C db "-.-.", 0
        morse_D db "-..", 0
        morse_E db ".", 0
        morse_F db "..-.", 0
        morse_G db "--.", 0
        morse_H db "....", 0
        morse_I db "..", 0
        morse_J db ".---", 0
        morse_K db "-.-", 0
        morse_L db ".-..", 0
        morse_M db "--", 0
        morse_N db "-.", 0
        morse_O db "---", 0
        morse_P db ".--.", 0
        morse_Q db "--.-", 0
        morse_R db ".-.", 0
        morse_S db "...", 0
        morse_T db "-", 0
        morse_U db "..-", 0
        morse_V db "...-", 0
        morse_W db ".--", 0
        morse_X db "-..-", 0
        morse_Y db "-.--", 0
        morse_Z db "--..", 0
        morse_comma db "--..--", 0
        morse_space db " ", 0

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
    push DWORD [eax + 8]
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

apply_key:
    push ebp
    mov ebp, esp

    mov eax, DWORD [img_height]
    mul DWORD [img_width]   ; height * width =
                            ; (height - 1)*width + width = max_byte
                            ; not actually touched

    push eax ; max_byte
    xor ecx, ecx ; current byte_id = 0

    mov eax, [ebp + 8] ; the image
    mov ebx, [ebp + 12] ; the key

    mov edi, [eax]

apply_key_on_byte:
    cmp ecx, DWORD [ebp - 4] ; byte_id < max_byte
    je apply_key_on_byte_end

    xor BYTE [eax + ecx*4], bl ; apply key and save on image

    inc ecx
    jmp apply_key_on_byte

apply_key_on_byte_end:
    leave
    ret

find_word:
    push ebp
    mov ebp, esp

    push DWORD 0 ; index through the word
    push DWORD 0 ; line index
    push DWORD 0 ; column index

    mov ebx, [ebp + 8] ; the image
    mov esi, [ebp + 12] ; the message

find_word_loop:
    mov eax, DWORD [ebp - 8] ; line index
    mul DWORD [img_width] ; line * img_width
    add eax, DWORD [ebp - 12] ; column index
    mov cl, BYTE [ebx + eax*4] ; img[line][column]

    mov eax, DWORD [ebp - 4] ; index through the word

    cmp cl, BYTE [esi + eax] ; word[index]
    jne find_word_not_equal

    inc DWORD [ebp - 4] ; next char in the word

    mov eax, DWORD [ebp - 4]
    cmp BYTE [esi + eax], 0 ; the end of the word, it has been found
    jne find_word_next_column

    mov eax, DWORD [ebp - 8] ; save line index
    jmp find_word_exit

find_word_not_equal:
    mov DWORD [ebp - 4], 0 ; char not found, reset the word index

find_word_next_column:
    inc DWORD [ebp - 12] ; next column
    mov eax, DWORD [ebp - 12]
    cmp eax, DWORD [img_width] ; max column
    jl find_word_loop

    ; next line
    mov DWORD [ebp - 12], 0 ; reset column index
    inc DWORD [ebp - 8] ; next line
    mov eax, DWORD [ebp - 8]
    cmp eax, DWORD [img_height] ; max line
    jl find_word_loop

mov eax, -1 ; if it hasn't been found, return -1

find_word_exit:
    leave
    ret

bruteforce_singlebyte_xor:
    push ebp
    mov ebp, esp

    push DWORD 0 ; key

bruteforce_loop:
    ; apply key on map
    push DWORD [ebp - 4] ; the key
    push DWORD [ebp + 8] ; the image
    call apply_key
    add esp, 8

    ; find word on decoded map
    push searched_word
    push DWORD [ebp + 8] ; the image
    call find_word
    add esp, 8

    push eax ; the result of find_word, used later

    ; restore map by applying the same key again
    push DWORD [ebp - 4] ; the key
    push DWORD [ebp + 8] ; the image
    call apply_key
    add esp, 8

    pop eax ; restore the result of find_word
    cmp eax, -1
    jne bruteforce_exit ; -1 only if it hasn't been found

    inc DWORD [ebp - 4] ; increment the key and try again
    cmp DWORD [ebp - 4], 128
    jl bruteforce_loop

bruteforce_exit:
    ; line already saved in eax
    mov ebx, DWORD [ebp - 4] ; the key
    shl ebx, 16
    or eax, ebx ; save the key in the upper half of eax
                ; the lower half of eax holds the line

    leave
    ret

print_line:
    push ebp
    mov ebp, esp

    mov ebx, [ebp + 8] ; the image
    mov eax, [ebp + 12] ; the line

    mul DWORD [img_width] ; line * img_width

    ; eax is now pointint to the start of the line

print_line_loop:
    mov cl, BYTE [ebx + eax*4]
    cmp cl, 0 ; if it's null, don't print and end
    je print_line_exit

    PRINT_CHAR cl

    inc eax ; if not, repeat
    jmp print_line_loop

print_line_exit:
    NEWLINE

    leave
    ret

solve_task1:
    push DWORD [img]
    call bruteforce_singlebyte_xor
    add esp, 4

    movzx ebx, ax   ; the line
    push ebx        ; save it

    mov ebx, eax
    shr ebx, 16     ; the key
    push ebx        ; save it

    ; decode the image
    push DWORD [ebp - 8] ; the key
    push DWORD [img]
    call apply_key
    add esp, 8

    ; print the line that we found the word on
    push DWORD [ebp - 4] ; the line
    push DWORD [img]
    call print_line
    add esp, 8

    ; re-encode the image
    push DWORD [ebp - 8] ; the key
    push DWORD [img]
    call apply_key
    add esp, 8

    pop eax ; the key
    PRINT_UDEC 4, eax
    NEWLINE

    pop eax ; the line
    PRINT_UDEC 4, eax
    NEWLINE

    jmp done

write_message:
    push ebp
    mov ebp, esp

    mov ebx, [ebp + 8] ; the image
    mov edx, [ebp + 12] ; the message
    mov eax, [ebp + 16] ; the starting pixel

    xor esi, esi ; index through the message

write_message_loop:
    mov cl, BYTE [edx + esi] ; char from message
    cmp cl, 0 ; if null
    jne write_message_not_null

    ; decide whether or not null shall be printed
    cmp DWORD [ebp + 20], 0 ; anything else - write null, 0 don't write null
    je write_message_dont_print_null

write_message_not_null:
    mov BYTE [ebx + eax*4], cl ; write to img

    inc eax ; next pixel

write_message_dont_print_null:
    inc esi ; next char

    cmp BYTE [edx + esi - 1], 0 ; null was reached, end
    jne write_message_loop

    ; eax - return next unmodified pixel for different purposes
    leave
    ret

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

solve_task2:
   push DWORD [img]
    call bruteforce_singlebyte_xor
    add esp, 4

    movzx ebx, ax   ; the line
    push ebx        ; save it

    mov ebx, eax
    shr ebx, 16     ; the key
    push ebx        ; save it

    ; decode the image
    push DWORD [ebp - 8] ; the key
    push DWORD [img]
    call apply_key
    add esp, 8

    ; write our message on the next line
    mov eax, DWORD [ebp - 4] ; the line
    inc eax ; next line
    mul DWORD [img_width] ; (line + 1) * img_width

    push DWORD 1 ; write null
    push eax
    push my_message
    push DWORD [img]
    call write_message
    add esp, 16

    ; calculate new key
    push DWORD [ebp - 8] ; the key
    call calculate_key
    add esp, 4

    ; eax now holds the new key, apply it
    push eax
    push DWORD [img]
    call apply_key
    add esp, 8

    ; print the image
    push DWORD [img_height]
    push DWORD [img_width]
    push DWORD [img]
    call print_image
    add esp, 12

    jmp done

translate:
    push ebp
    mov ebp, esp

    mov ebx, DWORD [ebp + 8] ; the char

    cmp bl, 'A'
    mov eax, morse_A
    je translate_exit
    cmp bl, 'B'
    mov eax, morse_B
    je translate_exit
    cmp bl, 'C'
    mov eax, morse_C
    je translate_exit
    cmp bl, 'D'
    mov eax, morse_D
    je translate_exit
    cmp bl, 'E'
    mov eax, morse_E
    je translate_exit
    cmp bl, 'F'
    mov eax, morse_F
    je translate_exit
    cmp bl, 'G'
    mov eax, morse_G
    je translate_exit
    cmp bl, 'H'
    mov eax, morse_H
    je translate_exit
    cmp bl, 'I'
    mov eax, morse_I
    je translate_exit
    cmp bl, 'J'
    mov eax, morse_J
    je translate_exit
    cmp bl, 'K'
    mov eax, morse_K
    je translate_exit
    cmp bl, 'L'
    mov eax, morse_L
    je translate_exit
    cmp bl, 'M'
    mov eax, morse_M
    je translate_exit
    cmp bl, 'N'
    mov eax, morse_N
    je translate_exit
    cmp bl, 'O'
    mov eax, morse_O
    je translate_exit
    cmp bl, 'P'
    mov eax, morse_P
    je translate_exit
    cmp bl, 'O'
    mov eax, morse_Q
    je translate_exit
    cmp bl, 'R'
    mov eax, morse_R
    je translate_exit
    cmp bl, 'S'
    mov eax, morse_S
    je translate_exit
    cmp bl, 'T'
    mov eax, morse_T
    je translate_exit
    cmp bl, 'U'
    mov eax, morse_U
    je translate_exit
    cmp bl, 'V'
    mov eax, morse_V
    je translate_exit
    cmp bl, 'W'
    mov eax, morse_W
    je translate_exit
    cmp bl, 'X'
    mov eax, morse_X
    je translate_exit
    cmp bl, 'Y'
    mov eax, morse_Y
    je translate_exit
    cmp bl, 'Z'
    mov eax, morse_Z
    je translate_exit
    cmp bl, ','
    mov eax, morse_comma
    je translate_exit

translate_exit:
    ; message address already in eax
    leave
    ret

morse_encrypt:
    push ebp
    mov ebp, esp

    push DWORD 0 ; will be set to 1 after the first letter is printed
    push DWORD 0 ; index through the message

morse_encrypt_loop:
    cmp DWORD [ebp - 4], 0 ; equal to 0 if no letter has been printed yet
    je morse_encrypt_no_space

    push DWORD 0 ; don't print null
    push DWORD [ebp + 16] ; the byte index
    push morse_space
    push DWORD [ebp + 8] ; the image
    call write_message
    add esp, 16
    mov DWORD [ebp + 16], eax ; update the byte index

morse_encrypt_no_space:
    mov eax, DWORD [ebp - 8] ; index through the message
    mov esi, DWORD [ebp + 12] ; the message
    movzx edx, BYTE [esi + eax]
    push edx ; current character
    call translate
    add esp, 4

    push DWORD 0 ; don't print null
    push DWORD [ebp + 16] ; the byte index
    push eax ; the address of the message returned by translate
    push DWORD [ebp + 8] ; the image
    call write_message
    add esp, 16
    mov DWORD [ebp + 16], eax ; update the byte index

    mov DWORD [ebp - 4], 1 ; a letter has been written

    inc DWORD [ebp - 8] ; next character from message
    mov eax, DWORD [ebp - 8]
    mov esi, DWORD [ebp + 12] ; the message
    cmp BYTE [esi + eax], 0 ; if not null, continue
    jne morse_encrypt_loop

    mov eax, DWORD [ebp + 16] ; the byte index
    mov ebx, DWORD [ebp + 8] ; the image
    mov BYTE [ebx + eax*4], 0 ; null terminated

    leave
    ret

solve_task3:
    mov eax, DWORD [ebp + 12] ; argv[]
    push DWORD [eax + 16] ; argv[4] = the byte_id "string"
    call atoi
    add esp, 4

    push eax ; byte_id

    mov eax, DWORD [ebp + 12] ; argv[]
    push DWORD [eax + 12] ; argv[3] = the message

    push DWORD [img]
    call morse_encrypt
    add esp, 12

    ; print the image
    push DWORD [img_height]
    push DWORD [img_width]
    push DWORD [img]
    call print_image
    add esp, 12

    jmp done

lsb_encode:
    push ebp
    mov ebp, esp

    mov ebx, DWORD [ebp + 8] ; the image
    mov esi, DWORD [ebp + 12] ; the message

    push DWORD 0 ; index through the message
    push DWORD 0 ; index through the bits of a byte

lsb_encode_loop:
    mov eax, DWORD [ebp - 4] ; message index
    mov dl, BYTE [esi + eax] ; current char

    mov DWORD [ebp - 8], 0 ; bit index

lsb_encode_bit_loop:
    mov eax, DWORD [ebp + 16] ; byte_id

    shl dl, 1 ; CF will hold the shifted bit
    jnc lsb_encode_cf_not_set

    or BYTE [ebx + eax*4], 1 ; set the LSB of this pixel
    jmp lsb_encode_next_bit

lsb_encode_cf_not_set:
    mov cl, 1
    not cl

    and BYTE [ebx + eax*4], cl ; reset the LSB of this pixel

lsb_encode_next_bit:
    inc DWORD [ebp + 16] ; next pixel
    inc DWORD [ebp - 8] ; next bit
    cmp DWORD [ebp - 8], 8
    jl lsb_encode_bit_loop

    ; next letter
    inc DWORD [ebp - 4] ; message index
    mov eax, DWORD [ebp - 4]
    cmp BYTE [esi + eax - 1], 0
    jne lsb_encode_loop ; if null was printed, stop

    leave
    ret

solve_task4:
    mov eax, DWORD [ebp + 12] ; argv[]
    push DWORD [eax + 16] ; argv[4] = the byte_id "string"
    call atoi
    add esp, 4

    dec eax ; byte index = byte_id - 1 for some reason
    push eax ; byte_id

    mov eax, DWORD [ebp + 12] ; argv[]
    push DWORD [eax + 12] ; argv[3] = the message

    push DWORD [img]
    call lsb_encode
    add esp, 12

    ; print the image
    push DWORD [img_height]
    push DWORD [img_width]
    push DWORD [img]
    call print_image
    add esp, 12

    jmp done

lsb_decode:
    push ebp
    mov ebp, esp

    mov ebx, DWORD [ebp + 8] ; the image

    push DWORD 0 ; index through the bits of a byte
    xor edx, edx ; build a character into edx (dl to be precise)

lsb_decode_loop:
    mov eax, DWORD [ebp + 12] ; byte_id
    mov cl, BYTE [ebx + eax*4] ; get the pixel

    shl dl, 1 ; make space for another bit
    shr cl, 1 ; CF will hold the shifted LSB
    adc dl, 0 ; add with carry (ONLY carry)

    ; next bit
    inc DWORD [ebp + 12] ; next pixel
    inc DWORD [ebp - 4] ; bit index
    cmp DWORD [ebp - 4], 8
    jl lsb_decode_loop

    cmp dl, 0 ; if null, end
    je lsb_decode_end

    ; the character is now build into dl
    PRINT_CHAR dl

    ; continue
    xor edx, edx ; prepare for new character
    mov DWORD [ebp - 4], 0 ; reset bit index
    jmp lsb_decode_loop

lsb_decode_end:
    NEWLINE

    leave
    ret

solve_task5:
    mov eax, DWORD [ebp + 12] ; argv[]
    push DWORD [eax + 12] ; argv[3] = the byte_id "string"
    call atoi
    add esp, 4

    dec eax ; byte index = byte_id - 1 for some reason
    push eax ; byte_id

    push DWORD [img]
    call lsb_decode
    add esp, 8

    jmp done

calculate_avg:
    push ebp
    mov ebp, esp

    mov ebx, DWORD [ebp + 8] ; the image

    xor ecx, ecx ; save the sum here

    mov eax, DWORD [ebp + 12] ; line index
    mul DWORD [img_width] ; line * width
    add eax, DWORD [ebp + 16] ; column index

    movzx ecx, BYTE [ebx + eax*4] ; center byte

    movzx edx, BYTE [ebx + eax*4 - 4] ; left byte
    add ecx, edx
    movzx edx, BYTE [ebx + eax*4 + 4] ; right byte
    add ecx, edx

    sub eax, DWORD [img_width] ; top line
    movzx edx, BYTE [ebx + eax*4] ; top byte
    add ecx, edx

    add eax, DWORD [img_width] ; back to the center
    add eax, DWORD [img_width] ; bottom line
    movzx edx, BYTE [ebx + eax*4] ; bottom byte
    add ecx, edx

    mov eax, ecx ; prepare for div
    mov ecx, 5
    xor edx, edx
    div ecx

    ; the result is in eax
    leave
    ret

blur:
    push ebp
    mov ebp, esp

    mov ebx, DWORD [ebp + 8] ; the image

    push DWORD 1 ; line index
    push DWORD 1 ; column index

    ; start from 1 and end on size - 1 to avoid borders
blur_push_loop:
    push DWORD [ebp - 8] ; column index
    push DWORD [ebp - 4] ; line index
    push DWORd [ebp + 8] ; the image
    call calculate_avg
    add esp, 12

    push eax ; save this average on stack

    ; next column
    inc DWORD [ebp - 8] ; column index
    mov eax, DWORD [ebp - 8]
    inc eax
    cmp eax, DWORD [img_width] ; column < width - 1
    jl blur_push_loop

    ; next line
    mov DWORD [ebp - 8], 1 ; reset column index
    inc DWORD [ebp - 4] ; line index
    mov eax, DWORD [ebp - 4]
    inc eax
    cmp eax, DWORD [img_height] ; line < height - 1
    jl blur_push_loop

    ; traverse the image in reverse order
    mov eax, DWORD [img_height]
    sub eax, 2
    mov DWORD [ebp - 4], eax ; start line index

    mov eax, DWORD [img_width]
    sub eax, 2
    mov DWORD [ebp - 8], eax ; start column index

blur_pop_loop:
    ; calculate index
    mov eax, DWORD [ebp - 4] ; line index
    mul DWORD [img_width] ; line * width
    add eax, DWORD [ebp - 8] ; column index

    pop edx ; pop average
    mov BYTE [ebx + eax*4], dl ; move it into the image

    ; next column
    dec DWORD [ebp - 8] ; column index
    cmp DWORD [ebp - 8], 0 ; column > 0
    jg blur_pop_loop

    ; next line
    mov eax, DWORD [img_width]
    sub eax, 2
    mov DWORD [ebp - 8], eax ; reset column index
    dec DWORD [ebp - 4] ; line index
    cmp DWORD [ebp - 4], 0 ; line > 0
    jg blur_pop_loop

    leave
    ret

solve_task6:
    push DWORD [img]
    call blur
    add esp, 4

    push DWORD [img_height]
    push DWORD [img_width]
    push DWORD [img]
    call print_image
    add esp, 12

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
    
