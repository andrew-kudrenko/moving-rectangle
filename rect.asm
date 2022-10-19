program segment 'code'
        assume cs: program, ds: data

updateColors proc
    inc innerColor
    inc outerColor
   
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
    inc elapsedTime
    
    mov di, pauseColorUpdatesIn
    cmp elapsedTime, di
    ja ignoreUpdateTimer

    call updateColors

ignoreUpdateTimer:
    pop di
    pop dx
    pop cx
    pop ax    

    ret
setTimer endp

getChar proc
    push dx
    mov ah, 06h          
    mov dl, 0ffh         
    int 21h
    pop dx
    
    ret
getChar endp

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
    
    call getChar
    
    cmp al, 0
    
    je redraw
    jmp afterRedraw
    
redraw:
    call draw    

afterRedraw:
    jnz analyzeInput            
    jmp mainLoop

analyzeInput:    
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
    mov elapsedTime, 0
    
    cmp si, 0
    jbe mainLoop
    
    call clear
    
    sub si, speed
    jmp mainLoop
    
moveRight:
    mov elapsedTime, 0
    
    mov di, cx
    add di, si
    
    cmp di, windowWidth
    jae mainLoop
    
    call clear

    add si, speed
    
    jmp mainLoop
    
moveUp:
    mov elapsedTime, 0
    
    cmp dx, 0
    jbe mainLoop
    
    call clear

    sub dx, speed
    jmp mainLoop
    
moveDown:
    mov elapsedTime, 0

    mov di, rectSize
    add di, dx
    
    cmp di, windowHeight
    jae mainLoop
    call clear
    
    add dx, speed
    jmp mainLoop

cleanup:
    mov ah, 09h
    mov dx, offset exitMessage
    int 21h

    mov ah, 08h
    int 21h
    
    mov ax, 4c00h
    
    int 21h
   
program ends

data segment
    exitMessage db 'Program has been down. Press any key to exit$'
    
    currentColor db 0
    bgColor db 0
    outerColor db 6
    innerColor db 9
    
    speed dw 5
    rectSize dw 80
    
    windowWidth dw 635
    windowHeight dw 345
    
    positionX dw 40
    positionY dw 25
    
    lastCheckAt dw 0
    checkPeriod dw 18; 18 ~ 1s
    
    elapsedTime dw 0
    pauseColorUpdatesIn dw 10; check periods before color changing pause
data ends

stk segment 'stack'
    dw 128
stk ends

end startup
