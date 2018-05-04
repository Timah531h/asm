.model tiny
.code
.386
org 80h
cmd_size                                db  ?
org 82h
cmd_text                                db  ?
org 100h

start:
    jmp main

old_handler dd 0

fseekBack MACRO numOfSymbols
    push ax                  
	push cx                     
	push dx
	push bx

    
    mov bx, sourceID
	
	mov ah, 42h                               ; ���������� � AH ��� 42h - �-��� DOS ��������� ��������� �����
	mov al, 1                                 ; 1 - ����������� ��������� �� ������� �������
	mov cx, -1                                ; ������� � CX -1, ��� �������� � �������� ������� �.�. ��������� ���� CX:DX !!!
	mov dx, numOfSymbols                      ; ������� � DX, ���-�� �������� �� ������� ������������  
	int 21h                                   ; �������� ���������� DOS ��� ���������� �������   
 
    pop bx                            
	pop dx                      
	pop cx                      
	pop ax
ENDM                   

fseekStart MACRO setPos
    push ax                  
	push cx                     
	push dx
	push bx

    
    mov bx, sourceID
	
	mov ah, 42h                               ; ���������� � AH ��� 42h - �-��� DOS ��������� ��������� �����
	mov al, 0                                 ; 0 - ����������� ��������� �� ������ �����
	mov cx, 0                                 ; �������� CX 
	mov dx, setPos	                          ; ������� � DX, ���-�� �������� �� ������� ������������
	int 21h                                   ; �������� ���������� DOS ��� ���������� �������   
 
    pop bx                            
	pop dx                      
	pop cx                      
	pop ax               
ENDM

fseekCurrent MACRO settingPos
    push ax                  
	push cx                     
	push dx
	push bx

    
    mov bx, sourceID
	
	mov ah, 42h                               ; ���������� � AH ��� 42h - �-��� DOS ��������� ��������� �����
	mov al, 1                                 ; 1 - ����������� ��������� �� ������� �������
	mov cx, 0                                 ; �������� CX 
	mov dx, settingPos	                      ; ������� � DX, ���-�� �������� �� ������� ������������ 
	int 21h                                   ; �������� ���������� DOS ��� ���������� �������   
 
    pop bx                            
	pop dx                      
	pop cx                      
	pop ax               
ENDM

checkNextSymbolOnCRET MACRO
    mov bl, buf                               ; ���������� 80-�� ������
    
    call readSymbolFromFile                   ; ��������� 81-�� ������
    cmp [buf], returnSymbol                   ; ���� CRET => ������ ����������� 
    jne endCheckCRET                          ; ���� �� CRET => ��������� 81-�� ������ ��� ��� ������, �� �.�. ��� �� ������ � ������� ���� ������� �� ����� ������ � �����������
    
    mov es:[di], bl                           ; ���������� ������ � ����������
    inc numOfPrintedSymbols                   
    add di, 2                                 ; ��������� �� ������ ����. ������� (� ������ ������ ����� ������ � �������)

    jmp endOfString                           ; ������� � endOfString
    
endCheckCRET:
    fseekBack -2                              ; ��������� �� -2, �.�. �� 80-�� ������, �.�. � endOfString �� ��������� �� 81-�� 
    mov es:[di], bl                           ; ���������� ������ � ����������
    inc numOfPrintedSymbols
    add di, 2                                 ; ��������� �� ������ ����. ������� (� ������ ������ ����� ������ � �������)
    
    jmp endOfString                           ; ������� � endOfString
    
ENDM

strcpy MACRO destination, source, count       ;������, ��������������� ��� ����������� �� source � destination �������� ���������� ��������
    push cx
    push di
    push si
    
    xor cx, cx
    
    mov cl, count
    lea si, source
    lea di, destination
    
    rep movsb
    
    pop si
    pop di
    pop cx
ENDM

println MACRO info      
	push ax                
	push dx                
                        
	mov ah, 09h                          ; ������� ������ 
	mov dx, offset info                  ; �������� � dx �������� ���������� ���������
	int 21h                              ; ����� ����������� ��� ���������� ������

	pop dx                 
	pop ax                 
ENDM  

new_handler proc far
    
    pushf                                ; ��������� �������� ������
    call cs:old_handler                  ; �������� ������ ����������
        
    pusha                                ; ��������� ��������    
    push ds                              
    push es
    push cs
    pop ds

    cmp openFileFlag, 0                  ; ���������, ��������� �� �� ����
    jne checkTypedButton                 ; ���� ��, �� ������� � checkTypedButton, ����� ��������� ���� � ������������� ��������������� ���� 
    mov openFileFlag, 1                  ; ������������� ���� �������� �����
    call openFile                        ; ��������� ����
    
checkTypedButton:        
    xor ah, ah                           
    int 16h                              ; ��������� ����� ����������
    
    cmp ah, 49h                          ; ��������� ������� �������, 49h - ����-��� PageUP
    jne notPageUP                        ; ���� �� ���� ������ PageUp, �� ������� � notPageUP 
    mov endFileFlag, 0                   ; ������������� ���� ����� ����� � 0
    fseekStart 0                         ; ��������� � ������ �����
    call printFilePage                   ; ������� �������� ���������
    jmp notNeedKey                       ; ����� ������ �������� ������� � notNeedKey
    
notPageUP:    
   cmp ah, 51h                           ; ���������, �� ���� �� ������ ������� PageDown - ����-��� 51h
   jne notNeedKey                        ; ���� ���, ��������� ��������� �����������
   cmp endFileFlag, 0                    ; ���������, �� ��� �� ��������� ����� �����
   jne notNeedKey                        ; ���� ��������� �����, �� ������� � notNeedKey
   call printFilePage                    ; ������� ��������� ��������
    
notNeedKey:                              ; ��������������� �������� ���������
    pop es
    pop ds
    popa    
    iret
    
new_handler endp

main:
    call parseCMD                        ; ������ ��������� ��������� ������
    cmp ax, 0
	jne endMain
	
	call openFile                        ; �������� ���������, ������� ��������� ����, ���������� ����� ��������� ������	
	cmp ax, 0               
	jne endMain
	
	jmp install_handler                  ; ������������� ����������
	
endMain:                    
	                            
	mov ah, 4Ch                          ; ��������� � AH ��� ������� ���������� ������
	int 21h  
    ret

openFile PROC               
	push bx                     
	push dx                                
	push si                                     
                                 
	mov ah, 3Dh			                 ; ������� 3Dh - ������� ������������ ����
	mov al, 02h			                 ; ����� �������� ����� - ������
	lea dx, sourcePath                   ; ��������� � dx �������� ��������� ����� 
	int 21h                     
                         
	jb badOpenSource	                 ; ���� ���� �� ��������, �� ������� � badOpenSource
              
	mov sourceID, ax	                 ; ��������� � sourceId �������� �� ax, ���������� ��� �������� �����
                                
	mov ax, 0			                 ; ��������� � AX 0, �.�. ������ �� ����� ���������� ��������� �� ��������    
	jmp endOpenProc		                 ; ������� � endOpenProc � ��������� ������� �� ���������
                                
badOpenSource:                  
	println badSourceText                ; ������� �������������� ���������
	
	cmp ax, 02h                          ; ���������� AX � 02h
	jne errorFound                       ; ���� AX != 02h file error, ������� � errorFound
                                
	println fileNotFoundText             ; ������� ��������� � ���, ��� ���� �� ������  
                                
	jmp errorFound                       ; ������� � errorFound
                               
errorFound:                     
	mov ax, 1
	                   
endOpenProc:
    pop si               
	pop dx                                                     
	pop bx                  
	ret                     
ENDP

parseCMD proc
    xor ax, ax
    xor cx, cx
    
    dec cmd_size

    cmp cmd_size, 0                      ; ���� �������� �� ��� �������, �� ��������� � notFound 
    je notFound
    
    mov cl, cmd_size
    
    xor ah, ah
    lea di, cmd_text
    mov al, cmd_size
    add di, ax
    dec di
    
findPoint:                               ; ���� ����� ������� � ����� �����
    mov al, '.'
    mov bl, [di]
    cmp al, bl
    je pointFound
    dec di
    loop findPoint
    
notFound:                                ; ���� ����� �� ������� ������� badCMDArgsMessage � ��������� ���������
    println badCMDArgsMessage    
    mov ah, 0
    int 16h

    mov ax, 1
    ret
    
pointFound:                              ; ���������� �������� ������ ���� ����� 3, �.�. "txt", ���� ������� �� ����� => ���� �� ��������        
    mov al, cmd_size
    sub ax, cx
    cmp ax, 3                            ; ���� ����� ����� 3 ������� => ���������� ��������
    jne notFound
    
    xor ax, ax
    mov di, offset cmd_text
    mov si, offset extension             
    ;add si, 2                           ; � ��������� ������-�� ����� ������� ��� �������� NULL � ��� lea ��� ��������� �� ������ NULL
    add di, cx
    
    mov cx, 3
    
    repe cmpsb                           ; ���������� �� ������� Extension ���������� �����, ���� �� ������� - �������� ����� ����� � sourcePath 
    jne notFound
    
    strcpy sourcePath, cmd_text, cmd_size
    
    mov ax, 0
    ret         
endp

printFilePage proc
    mov ax, 3                            ; ����������� ������� 
    int 10h

    mov ax, 1003h
    mov bx, 0
    int 10h
    
    call clearWindow                     ; ������� �������
    
    mov tempSentences, 0                 ; �������� tempSentences 
    
    push es                              ; ��������� �������� ES
    mov ax, 0b800h                       ; ������������� ES �� ������ ����������� 
    mov es, ax
    
    xor di, di
	cld
	
nextSentence:
	xor ax, ax
	mov numOfPrintedSymbols, 0           ; �������� numOfReadSymbolsOfSentence � numOfPrintedSymbols
    mov numOfReadSymbolsOfSentence, 0     

getAndCheckSymbol:    
    call readSymbolFromFile              ; ��������� ������ � �����

    inc numOfReadSymbolsOfSentence 
    
    
    cmp ax, 0                            ; ���� ������ �� ������� => ����� �����
    je endOfFile
    cmp [buf], 0                         ; ���� ������� NULL => ����� �����
    je endOfFile
    
    
    cmp [buf], returnSymbol              ; ��������� �� ����� ������: CRET
    je  endOfString                      ; ���� ����� ������� � endOfString
    cmp numOfReadSymbolsOfSentence, 80   ; ���������, �� ������� �� �� 80-�� ������ ������ 
    jne printSymbol                      ; ���� �� 80-�� => �� ������ � ������� � printSymbol
    
    checkNextSymbolOnCRET                ; ��������� 81-�� ������, �.�. ��� ����� ���� CRET 
    
printSymbol:    
    mov al, buf                          ; ������� ������ � AL
    xor ah, ah
    
    mov es:[di], al                      ; ���������� ������ � ����������
    add di, 2                            ; ��������� �� ������ ���������� �������
    inc numOfPrintedSymbols              
    jmp getAndCheckSymbol                ; ��������� � ���������� �������
    
endOfString:
    inc tempSentences                    ; ����������� ���-�� ������������ �����
 
    fseekCurrent 1                       ; ������������� ������ �������� �� ����� ������
    
    cmp tempSentences, dosHeigth         ; ���� ��������� ������� �� ������, �� ������� � endPage
    je endPage  
    
    mov ax, dosWidth                     ; ������� ������ ������� � AX
    sub al, numOfPrintedSymbols          ; �������� �� AX ���������� ������������ �������� 
    cmp ax, 0                            ; ���������� � 0. ���� ����� 0 => ��������� ��� ������ ������� (80 ��������)                                          
    je nextSentence                      ; ��������� �� ��������� �����������, ���� ��������� ��� ������ �������,
                                         ; ����� - ���� ������������ �� ��������� ������ � �������
    mul two                              ; �������� �� ��� �.�. ���������� ������������ �� 2 �����
    add di, ax                           ; ��������� �� ��������� ������ � �����������
        
    jmp nextSentence                     ; ��������� �� ��������� �����������    

endPage:     
    pop es    
    ret 
    
endOfFile:
	mov endFileFlag, 1                   ; ������������� ���� ����� �����
    pop es                               
    ret   
endp

readSymbolFromFile proc
    push bx
    push dx
    
    mov ah, 3Fh                          ; ��������� � ah ��� 3Fh - ��� �-��� ������ �� �����
	mov bx, sourceID                     ; � bx ��������� ID �����, �� �������� ���������� ���������
	mov cx, 1                            ; � cx ��������� ���������� ����������� ��������
	lea dx, buf                          ; � dx ��������� �������� �������, � ������� ����� ��������� ������ �� �����
	int 21h                              ; �������� ���������� ��� ���������� �-���
	
	jnb successfullyRead                 ; ���� ������ �� ����� ������ �� ��������� - ������� � successfullyRead
	
	println errorReadSourceText          ; ����� ������� ��������� �� ������ ������ �� �����                       
	    
successfullyRead:                              
	pop dx                               
	pop bx
	                                
	ret    	   
endp                                     

clearWindow proc
    push ax                              ; ��������� �������� ���������
    push es
    push di
    
    cld                                  ; ����������� �������
    mov ax, 3h
    int 10h
    
    xor di, di
    mov ax, 0b800h
    mov es, ax                           ; ��������� �� ����������
    
    mov cx, numOfDosWindowSymbols        ; numOfDosWindowSymbols = 2000 - ���-�� ��������, ������� �������� ������� �� ������� 
     
fillSymbol:
    mov byte ptr es:[di], ' '            ; ��������� ������� ��������� � ������������� ��������
    inc di
    mov byte ptr es:[di], textColor
    inc di
    loop fillSymbol 
                                         ; ���������� ����������� �������� � ��������
    pop di
    pop es
    pop ax
    ret
endp
;============================================================DATA==================================================================    
numOfReadSymbolsOfSentence              dw 0
tempSentences                           db 0
numOfPrintedSymbols                     db 0

dosWidth                                equ 80
dosHeigth                               equ 25
numOfDosWindowSymbols                   equ 2000

textColor                               equ 01110000b   ; black(0000) on white backround(0111)

two                                     db 2

maxCMDSize                              equ 127
sourcePath                              db  129 dup (0) 

extension             db "txt"       

buf                   db  0                      
sourceID              dw  0                                             
                            
newLineSymbol         equ 0Ah
returnSymbol          equ 0Dh                           
                     
badCMDArgsMessage     db  "Bad command-line arguments.",                                      0Dh,0Ah,'$'
badSourceText         db  "Open error",                                                       0Dh,0Ah,'$'    
fileNotFoundText      db  "File not found",                                                   0Dh,0Ah,'$'         
errorReadSourceText   db  "Error reading from source file",                                   0Dh,0Ah,'$'

pageUpFlag            db 0
endFileFlag           db 0
openFileFlag          db 0
;==================================================================================================================================
install_handler:
    
    cli
    mov ah, 35h                       ; ������� ��������� ������ ����������� ����������
	mov al, 09h                       ; ����������, ���������� �������� ���������� �������� (09 - ���������� �� ����������)
	int 21h
	
	                                 ; ��������� ������ ����������
	mov word ptr old_handler, bx     ; ��������
	mov word ptr old_handler + 2, es ; �������
	
	push ds
	pop es
	
	mov ah, 25h                       ; ������� ������ ����������� ����������
	mov al, 09h                       ; ����������, ��������� �������� ����� �������
	mov dx, offset new_handler        ; ��������� � dx �������� ������ ����������� ����������, ������� ����� ���������� �� ����� ������� ����������� 
	int 21h
    sti
    
    mov ah, 31h                       ; ������ ��������� �����������
    mov al, 0
    mov dx, (install_handler - start + 100h) / 16 + 1
    int 21h
    
    ret
end start