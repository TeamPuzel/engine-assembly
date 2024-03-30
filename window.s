
// My favorite way of learning programming languages
// is to write a simple SDL based software renderer.
// This time I decided to learn how to do it without a language :)

.text

// Apparently macOS is looking for this, if not present the window
// will have a light mode title bar, presumably with other such compatibility changes.
.build_version macos, 14, 0 sdk_version 14, 4

.global _start
.align 4

_start:
    bl _main
    mov x0, #0
    bl _exit

// SDL Defines
.equ INIT_VIDEO, 0x20
.equ WINDOW_HIDPI, 0x2000
.equ WINDOW_CENTERED, 0x2fff0000
.equ QUIT_EVENT, 0x100
.equ RENDERER_ACCEL_AND_VSYNC, 0x6
.equ TEXTUREACCESS_STREAMING, 1

// Variables:
// x19 return ptr
// x20 window ptr
// x21 renderer ptr
// x22 event ptr
// x23 rect ptr
// x24 display ptr
// x25 texture ptr
_main:
    mov x19, lr
    
    // Begin
    mov x0, INIT_VIDEO
    bl _SDL_Init
    
    adrp x0, window_title@PAGE
    add x0, x0, window_title@PAGEOFF
    mov x1, WINDOW_CENTERED
    mov x2, WINDOW_CENTERED
    mov x3, #512
    mov x4, #512
    mov x5, WINDOW_HIDPI
    bl _SDL_CreateWindow
    mov x20, x0
    
    // arg0 window ptr is already in x0
    mov x1, #-1
    mov x2, RENDERER_ACCEL_AND_VSYNC
    bl _SDL_CreateRenderer
    mov x21, x0
    
    // Get pointers to data
    adrp x22, event@PAGE
    add x22, x22, event@PAGEOFF
    
    adrp x23, rect@PAGE
    add x23, x23, rect@PAGEOFF
    
    adrp x24, display@PAGE
    add x24, x24, display@PAGEOFF
    
    // Initialize display to 0
    mov x0, x24
    mov x1, #0
    mov x2, #128 * 128 * 3
    bl _memset
    
    // Create texture
    mov x0, x21
    mov x1, #6147           // TODO - Figure out why this define is so weird to use
    movk x1, #5904, lsl #16 // END TODO
    mov x2, TEXTUREACCESS_STREAMING
    mov x3, #128
    mov x4, #128
    bl _SDL_CreateTexture
    mov x25, x0
    cbz x0, panic
    
    // arg0 texture ptr is already in x0
    mov x1, #0x0
    mov x2, x24
    mov x3, #128 * 3
    bl _SDL_UpdateTexture
    cbnz x0, panic
    
    // Poll events until quit
loop:
    mov x0, x22
    bl _SDL_PollEvent
    cbz x0, loop // if no events then loop
    
    ldr w9, [x22]
    cmp w9, QUIT_EVENT
    b.eq end // if quit then end
    
    mov x0, x19
    bl _SDL_RenderClear
    
    // --- Frame start ---
    
    mov x0, #1
    mov x1, #1
    mov x2, #0xff
    mov x3, #0x00
    mov x4, #0x00
    bl _pset
    
    // --- Frame end ---
    
    mov x0, x25
    mov x1, #0x0
    mov x2, x24
    mov x3, #128 * 3
    bl _SDL_UpdateTexture
    
    mov x0, x21
    mov x1, x25
    mov x2, #0x0
    mov x3, x23
    bl _SDL_RenderCopy
    
    mov x0, x21
    bl _SDL_RenderPresent
    
    b loop
end:
    // Free all SDL resources
    mov x0, x25
    bl _SDL_DestroyTexture
    
    mov x0, x21
    bl _SDL_DestroyRenderer
    
    mov x0, x20
    bl _SDL_DestroyWindow
    
    bl _SDL_Quit
    
    // Return
    mov lr, x19
    ret

panic:
    bl _SDL_GetError
    bl _printf
    bl _exit

// Arguments:
// x0 x
// x1 y
// x2 r
// x3 g
// x4 b
// Variables:
// x9 pixel offset
_pset:
    mov x10, #128
    mul x9, x1, x10
    add x9, x9, x0
    mov x10, #3
    mul x9, x9, x10
    str x2, [x24, x9]
    add x9, x9, #1
    str x3, [x24, x9]
    add x9, x9, #1
    str x4, [x24, x9]
    ret

.data
window_title: .ascii "Hello Assembly\n"
event: .space 56
rect: .word 0, 0, 1024, 1024
display: .space 128 * 128 * 3
