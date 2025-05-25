[BITS 16]        ; Set the code to 16-bit mode
[ORG 0x7c00]     ; Set the origin (starting address) to 0x7c00, typical for boot loaders


CODE_OFFSET equ 0x8
DATA_OFFSET equ 0x10

KERNEL_LOAD_SEG equ 0x1000
KERNEL_START_ADDR equ 0x100000



start:
    cli           ; Clear interrupts, disabling all maskable interrupts
    mov ax, 0x00  ; Load immediate value 0x00 into register AX
    mov ds, ax    ; Set data segment (DS) to 0x00
    mov es, ax    ; Set extra segment (ES) to 0x00
    mov ss, ax    ; Set stack segment (SS) to 0x00
    mov sp, 0x7c00; Set stack pointer (SP) to 0x7c00, top of the bootloader segment
    sti           ; Enable interrupts, allowing them to occur again

    ; set video mode, al 03h is a text mode, this also clears the screen
    mov AH, 00h
    mov AL, 03h
    int 0x10
    

;Load kernel
mov bx, KERNEL_LOAD_SEG ; Load segment
mov es, bx
mov bx, 0x0000 ; Load offset (SEG*16 + OFFSET)
mov dh, 0x00
mov dl, 0x80
mov cl, 0x02
mov ch, 0x00
mov ah, 0x02
mov al, 8
int 0x13

jc disk_read_error


load_PM:
    cli
    lgdt[gdt_descriptor]
    mov eax, cr0
    or al, 1
    mov cr0, eax
    jmp CODE_OFFSET:PModeMain


disk_read_error:
    hlt

;GDT Implemetation

gdt_start:
    dd 0x0
    dd 0x0

    ; Code segment descriptor
    dw 0xFFFF       ; Limte
    dw 0x0000       ; Base
    db 0x00         ; Base
    db 10011010b    ; Access byte
    db 11001111b    ; Flags
    db 0x00         ; Base

    ; Data segment descriptor
    dw 0xFFFF       ; Limte
    dw 0x0000       ; Base
    db 0x00         ; Base
    db 10010010b    ; Access byte
    db 11001111b    ; Flags
    db 0x00         ; Base

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1 ; Size of GDT -1
    dd gdt_start 


[BITS 32]
PModeMain:
    mov ax, DATA_OFFSET
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov ss, ax
    mov gs, ax
    mov ebp, 0x9C00
    mov esp, ebp

    in al, 0x92
    or al, 2
    out 0x92, al

    ; Copy kernel from 0x10000 to 0x100000, where we jump to, as protected mode can access past 1MB now
    mov esi, 0x10000  ; Source
    mov edi, KERNEL_START_ADDR ; Destination
    mov ecx, 4096     ; num sectors * 512 bytes
    cld
    rep movsb

    jmp CODE_OFFSET:KERNEL_START_ADDR




times 510 - ($ - $$) db 0   ; Fill the rest of the boot sector with zeros up to 510 bytes

dw 0xAA55   ; Boot sector signature, required to make the disk bootable



