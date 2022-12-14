.code16
.section .boot, "awx"
.global _start

// what we need to do
// 1: activate A20
// 2 load all other boot files
// 3: using BIOS to load in the conventional area
// 4: performing a rep movsd to place the data where it should go

// to find kernel
// fat12 floppy t ostore list of sectors used by the kernel file. 
// that way I wont need to rewrite the bootsector everytime I rewrite kernel

// restrictions
// 1:  real mode, can only use 1mb
// 2: first 512 bytes need to load the rest of my loader

// load bytes
    // have to use CHS addressing.


//A20 Line arc


_start:
    mov sp, 0x7c00 // Allocated 30kib of stack memory
    mov eax, offset .Lreset_cs
    push 0x00
    push eax
    retf
.Lreset_cs:

// check if A20 is enabled by bios
// the bootsector identifier(0xAA55) located at adress 0000 7DFE
// with the value 1Mib higher located at adress FFFF 7E0E
// if those 2 values are different, A20 is enabled

//important stuff(SEGMENT)
//SI and DI registers are used to point to the source and destination respectively

//instructions
//  MOVS- moves 1 Byte, Word, Doubleword.
//  LODS- loads from memory, 
//      (if byte, word, doubleword, it is loaded into the AL register, AX register, EAX register
//      respectively)
// STOS- stores data from register (AL, AX, EAX) to memory
// CMPS- compares two data items in memory
// SCAS- compares AL,AX or EAX with the contents of an item in memory

//      ES:DI points destination operands
//      DS:SI points source operand
//      where DI and SI registers contain valid offset addresses that refers to bytes in memory
//      where SI:DS(data segment)
//      where DI:ES(extra segment)

//  byte, word, doubleword respectively -SB, -SW, -SD 

//  Repetition Prefixes
        //REP MOVSB, causes repetition based on counter placed at CX register
        //DF(Direction Flag determines the direction of the operation)
            //CLD, left->right
            //STD, right->left

.macro mEnableA20 // calls all A20_enable_functions
    call check_20

    mSetA20BIOS
    call check_20
  
    mSetA20Keyboard
    call check_20
  
    mSetA20FastGate
    call CheckA20

    enable_A20_fail

.endm

.macro mSetA20BIOS // bios function to enable A20 line
    mov ax, 0x2401
.endm
// enabling A20 line through the 8042 keyboard controller
//  1: disable the keyboard
//  2: tell controller that we want to read input
//  3: read one byte of input
//  4: tell the controller that we want to write output
//  5: in the byte just read, enable bit #2 and write it to the controller
//  6: enable the keyboard

// what does instruction in/out do 
    // IN --> read from a port
    // OUT --> write to a port

.macroSetA20Keyboard
    
    cli // disable interrupts
    call wait_8042_command
    mov al,0xAD // disable keyboard
    out 0x64,al

    call wait_8042_command
    mov al,0xD0 // read from input
    out 0x64,al

    call wait_8042_data
    in al,0x60 // read from input
    push eax // saves input


    call wait_8042_command
    mov al,0xd1 // write to output
    out 0x64,al

    call wait_8042_command
    pop eax
    or al,2 // write input with bit #2 set
    out 0x60,al

    call wait_8042_command
    mov al,0xAE // enable keyboards
    out 0x64 al

    call wait_8042_command

    sti // enable commands
.endm
    
.func wait_8042_command
wait_8042_command: // wait for the keyboard to be ready for command
    in al,0x64
    test al,2
    jnz wait_8042_command
.endfunc

.func wait_8042_data
Wait_8042_data:
    in al,0x64
    test al,1
    jz wait_8042_data
    ret
.endfunc

check_20:
    pushf
    push ds
    push es
    push di
    push si 

    cli

    xor ax, ax // ax = 0
    mov es, ax
    not ax // ax = 0xFFFF
    mov ds, ax
    
    mov di, 0x0500
    mov si, 0x0510

    mov al, byte [es:di] // al = source operand
    push ax
    mov byte [es:di], 0x00 
    mov byte [ds:si] 0xff

    pop ax
    mov ax, 0
    je check_120_exit
check_120_exit:
    pop si
    pop di
    pop es
    pop ds
    popf
    jmp A20_enabled
    ret
loop:
    jmp loop
A20_enabled:

.org 510
.byte 0x55, 0xAA
