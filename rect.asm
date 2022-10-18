program segment 'code'
        assume cs: program, ds: data

updateColors proc
updateInnerColor:
    inc innerColor
    cmp innerColor, 0
    je updateInnerColor 
    
updateOuterColor:
    inc outerColor
    cmp outerColor, 0
    je updateOuterColor
    
    ret
updateColors endp
        
drawLine proc
    mov ah, 0ch
    mov al, currentColor
    
    push si
    push dx
    push cx
    
line:
    push cx
    
    mov cx, si
    int 10h
    
    cmp di, 0
    je lineX
    jmp lineY
    
lineX:
    inc si
    jmp nextLinePixel
    
lineY:
    inc dx
    jmp nextLinePixel

nextLinePixel:
    
    pop cx
    
    loop line
    
    pop cx
    pop dx
    pop si
    
    ret
drawLine endp
        
horizontal proc 
    mov di, 0
    call drawLine
    
    ret
horizontal endp

vertical proc 
    mov di, 1
    call drawLine
    
    ret
vertical endp

drawTiltedLine proc
    mov ah, 0ch
    mov al, currentColor
    
    push si
    push dx
    push cx
    
tiltedLine:
    push cx
    
    mov cx, si
    int 10h
    
    inc si
    
    cmp di, 1
    je tiltedYLine
    jmp tiltedXLine
   
tiltedXLine:
    inc dx
    jmp tiltedNextPixel

tiltedYLine:
    dec dx
    jmp tiltedNextPixel

tiltedNextPixel:
    pop cx
    
    loop tiltedLine
    
    pop cx
    pop dx
    pop si
    
    ret
drawTiltedLine endp

tiltedRight proc
    mov di, 0
    call drawTiltedLine
    
    ret
tiltedRight endp

tiltedLeft proc
    mov di, 1
    call drawTiltedLine
    
    ret
tiltedLeft endp

rect proc    
    call horizontal
    call vertical
        
    add dx, cx
    
    call horizontal

    sub dx, cx
    add si, cx
        
    call vertical
    
    ret
rect endp     

innerRect proc    
    call tiltedRight
    
    add dx, cx
    add dx, cx
    
    call tiltedLeft
    
    sub dx, cx
    sub si, cx
    
    call tiltedRight
    call tiltedLeft
    
    ret
innerRect endp

drawBoth proc
    push cx
    push si
    push dx
    
    mov currentColor, al
    call rect
    mov currentColor, bl
    
    pop dx
    pop si
    pop cx
    
    push cx
    push si
    push dx
    
    mov ax, cx
    mov bl, 2
    div bl
    
    mov cx, ax
    add si, cx

    call innerRect
    
    pop dx
    pop si
    pop cx
    
    ret
drawBoth endp

clear proc
    push ax
    push bx

    mov bh, 0    

    mov al, bgColor
    mov bl, bgColor   

    call drawBoth
    
    pop bx
    pop ax
    
    ret
clear endp

draw proc
    push ax
    push bx

    mov bh, 0
    
    mov al, innerColor
    mov bl, outerColor
    
    call drawBoth
    
    pop bx
    pop ax
    
    ret
draw endp

setTimer proc
    push ax   
    push cx
    push dx
    push di
    
    mov ah, 00h
    int 1ah
    
    mov cx, dx
    sub dx, lastCheckAt
    
    cmp dx, checkPeriod
    
    jae updateTimer
    jmp ignoreUpdateTimer
    
updateTimer:
    mov lastCheckAt, cx
    call updateColors

ignoreUpdateTimer:
    pop di
    pop dx
    pop cx
    pop ax    

    ret
setTimer endp

updateLastKeyPressAt proc
    push ax
    push cx
    push dx
    
    mov ah, 00h
    int 1ah
    mov lastKeyPressAt, dx
    
    pop dx
    pop cx
    pop ax

    ret
updateLastKeyPressAt endp

startup:
    mov ax, data
    mov ds, ax
    
    mov ax, 0010h
    int 10h
    
    mov ah, 0h
    int 1ah
    mov lastCheckAt, dx
    
    mov cx, rectSize
    mov si, positionX
    mov dx, positionY 

mainLoop:
    call setTimer

    
    push dx
    mov ah, 06h          
    mov dl, 0ffh         
    int 21h
    pop dx
    
    cmp al, 0
    je redraw
    jmp ignoreRedraw
    
redraw:
    call draw    

ignoreRedraw:
    jnz analyzeInput            
    jmp mainLoop

analyzeInput:
    call updateLastKeyPressAt

    cmp al, 3bh; Exit on f1 pressed
    je cleanup
    
    cmp al, 4bh
    je moveLeft
    
    cmp al, 4dh
    je moveRight
    
    cmp al, 48h
    je moveUp
    
    cmp al, 50h
    je moveDown
    
    jmp mainLoop

moveLeft:
    cmp si, 2
    jbe mainLoop
    
    call clear
    
    sub si, speed
    jmp mainLoop
    
moveRight:
    mov di, cx
    add di, si
    
    cmp di, windowWidth
    jae mainLoop
    
    call clear

    add si, speed
    jmp mainLoop
    
moveUp:
    cmp dx, 2
    jbe mainLoop
    
    call clear

    sub dx, speed
    jmp mainLoop
    
moveDown:
    mov di, rectSize
    add di, dx
    
    cmp di, windowHeight
    jae mainLoop
    call clear
    
    add dx, speed
    jmp mainLoop

cleanup:
    mov ah, 08h
    int 21h
    
    mov ax, 4c00h
    
    int 21h
   
program ends

data segment
    currentColor db 0
    bgColor db 0
    outerColor db 10
    innerColor db 7
    
    speed dw 5
    rectSize dw 80
    
    windowWidth dw 635
    windowHeight dw 345
    
    positionX dw 40
    positionY dw 25
    
    lastKeyPressAt dw 0
    lastCheckAt dw 0
    checkPeriod dw 18
    
    pauseColorUpdatesIn dw 180
data ends

stk segment 'stack'
    dw 128
stk ends

end startup
