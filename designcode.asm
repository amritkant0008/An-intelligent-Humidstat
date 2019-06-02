#make_bin#

#LOAD_SEGMENT=FFFFh#
#LOAD_OFFSET=0000h#

#CS=0000h#
#IP=0000h#

#DS=0000h#
#ES=0000h#

#SS=0000h#
#SP=FFFEh#

#AX=0000h#
#BX=0000h#
#CX=0000h#
#DX=0000h#
#SI=0000h#
#DI=0000h#
#BP=0000h#

jmp st1
db 509 dup(0)
dw isr80
dw 00
db 508 dup(0)

st1:
cli
mov ax,0200h 
mov ds,ax
mov ss,ax 
mov es,ax
mov sp,0FFFEH
temp db -30,29-28,-27,-26,-25,-24,-23,-22,-21,-20,-19,-18,-17,-16,-15,-14,-13,-12,-11,-10
	 db	-9,-8,-7,-6,-5,-4,-3,-2,-1,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34
	 db	35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70
	; temp table

hum db 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34
	db	35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70
	db 71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100

;port addresses
porta1 equ 00h	;8255(1)
portb1 equ 02h
portc1 equ 04h
creg1 equ 06h
	
porta2 equ 10h	;8255(2)
portb2 equ 12h
portc2 equ 14h
creg2 equ 16h

flag db 0

tval db 0;value of temperature
tcurr db ? ;value of current temperature
hval db 4 dup(0); values of humidity
havg db 0

ladd1 db 80h,81h,84h,85h,0c0h,0c1h,0c4h,0c5h,0c6h
ladd2 db 82h,83h,0c2h,0c3h
dispc1 db 'T',':','^','C','H',':','%','R','h'
dispc2 db 4 dup(?)

;stack initalize
;org 0100h
stack dw 100 dup(?)
top_stack label word

;procedure to get temperature
get_temp proc near
sti
push ax
push si
lea si,tval
mov flag,0
mov al,00h
out 04h,al;select in0
mov al,00100000b   
out 04h,al        ;ale signal   
mov al,00110000b   
out 04h,al        ;soc signal   
nop
nop
nop
nop
mov al , 00010000b
out 04h , al 
mov al , 00000000b
out 04h , al 
mov al,1
x1: cmp flag,al 
	jnz x1
pop si
pop ax
ret
get_temp endp

;procedure to get humidity
get_hum proc near
sti
push cx
push dx
push ax
push si
lea si,hval
mov flag,0
mov cl,1
mov dx,0
x2: mov flag,0
	mov al,cl
	out portc1,al
	mov al,00100000b   
	out 04h,al        ;ale signal   
	mov al,00110000b   
	out 04h,al        ;soc signal   
	nop
	nop
	nop
	nop
	mov al , 00010000b
	out 04h , al 
	mov al , 00000000b
	out 04h , al    
	mov al,1
L:  cmp flag,al
	jnz L
	inc si
	inc dx
	cmp dx,4
	jnz x2
	pop si
	pop ax
	pop dx
	pop cx
ret
get_hum endp



;procedure to get delay of 3 seconds(approx.)
delay_3sec proc near     
push cx  
push ax  
mov al,11 
l2: mov cx,0ffffh 
l1: nop  
	nop  
	loop l1  
dec al  
jnz l2   
pop ax 
pop cx  
ret 
delay_3sec endp 

;delays for lcd
DELAY_L  PROC near    ;procedure to give a delay of 40us    
MOV CX,10d   
D1:   
NOP    
NOP    
LOOP D1 
DELAY_L  ENDP

DELAY_H  PROC near    ;procedure to give delay of 1.64ms    
MOV CX,540d 
D2:   
NOP    
NOP    
LOOP D2 
DELAY_H  ENDP

;procedure for displaying characters on lcd
dispchar proc near
again:	mov al,[di]
		out porta2,al
		call DELAY_L
		mov al,06h
		out portb2,al
		mov al,[si]
		inc si
		out porta2,al
		call DELAY_L
		mov al,02h
		out portb2,al
		loop again
dispchar endp

;procedure for transfroming temp,hum values into their ascii equivalent
trans_char proc near
lea si,dispc2;converting temp
mov al,dl
mov ah,00
mov cl,10d
div cl
add al,30h
mov [si],al
inc si
add ah,30h
mov [si],ah
inc si
mov al,dh;converting humidity
mov ah,00
mov cl,10d
div cl
add al,30h
mov [si],al
inc si
add ah,30h
mov [si],ah
trans_char endp





;main program
lea sp,Top_stack     ;initialize stack pointer   
;mov ax,0000h
;mov es,ax
;mov word ptr es:0200h,offset int_proc    
;mov word ptr es:0202h,seg int_proc 	;seg is used to return segment of expression
;initialize IVT 

;initializing the 8255(1)
mov al,10010010b
out creg1,al

;initializing the 8255(2)
mov al,10000000b
out creg2,al

;intializing 8254
mov al,00110110b
out 56h,al
mov al,02h
out 50h,al
mov al,00
out 50h,al

;intializing 8259
;mov al,00010011b
;out 60h,al;icw1 edge triggered
;mov al,10000000b
;out 62h,al;icw2
;mov al,00000001b
;out 62h,al;icw4
;mov al,11111110b
;out 62h,al

;intializing the lcd
MOV AL,04h   
OUT portb2,AL   
MOV AL,01h   
OUT porta2,AL 
CALL    DELAY_H   
	MOV AL,0Ch   
	OUT porta2,AL 
CALL DELAY_L   
	MOV AL,38h   
	OUT porta2,AL  
CALL DELAY_L
	lea di,ladd1
	lea si,dispc1
	mov cx,09d
call dispchar ; urvil 
cli
call get_temp
	mov al,tval
	mov tcurr,al
	cli
	lea si,temp
	lea di,hum
	mov cx,100d
	dec si
j:  inc si
	cmp al,[si]
	loopne j
	sub si,offset temp
	add di,si
	mov bl,[di]
	
go:	call get_hum
	mov ax,0
	lea si,hval
	mov cx,4
k:	add ax,[si] ;finding the average humidity
	inc si
	loop k
	mov cl,4
	div cl
	mov havg,al
	call trans_char
	
	;printing temp and hum values onto lcd
	lea di,ladd2
	lea si,dispc2
	mov cx,4d
	call dispchar
	
	;comparing room humidity with standard humidity
	cmp bl,havg
	jb off
	
	;ON the humidifier
	mov al,11111110b
	out 14h,al
delay: call delay_3sec
	call get_hum
	mov ax,0
	lea si,hval
	mov cx,4
f:	add ax,[si] ;finding the average humidity
	inc si
	loop f
	mov cl,4
	div cl
	mov havg,al
	cmp bl,havg
	ja delay
	
	;off the humidifier
	mov al,00000001b
	out 14h,al

off: 
	mov al,00000001b
	out 14h,al
	call delay_3sec
	mov al,tval
	call get_temp
	cmp al,tval
	ja off
	mov cl,tval
	sub cl,al
	add bl,cl
	jmp go
	

;interrupt service for 80h
isr80:
push ax
push si
mov al,00001000b;enable pc3 i.e. OE
out 04h,al
in al,00h
mov [si],al
mov al,00000000b;disable pc3 i.e. OE
out 04h,al
mov flag,1

pop si
pop ax
iret


