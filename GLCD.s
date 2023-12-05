#include <xc.inc>

global	GLCD_Setup, GLCD_Send_I, GLCD_Send_D, LCM_Reset, LCD_delay_ms, GLCD_Read
global	out_data
    
extrn	vert_line

psect	udata_acs   ; named variables in access ram

W2:		ds 1	; Second WREG 
LCD_cnt_l:	ds 1	; reserve 1 byte for variable LCD_cnt_l
LCD_cnt_h:	ds 1	; reserve 1 byte for variable LCD_cnt_h
LCD_cnt_ms:	ds 1	; reserve 1 byte for ms counter
y_pos_cnt:	ds 1	; reserve 1 byte for the y-position counter
x_pos_cnt:	ds 1	; reserve 1 byte for the y-position counter
out_data:	ds 1	; reserve 1 byte for the data output (when reading GLCD)

GLCD_CS1    EQU	0   ; GLCD Chip Select 1 (1-64)
GLCD_CS2    EQU	1   ; GLCD Chip Select 2 (65-128)
GLCD_RS	    EQU	2   ; GLCD Register Select (high=data, low=instruct) aka DI
GLCD_RW	    EQU	3   ; GLCD Read/Write (high=read, low=write)
GLCD_E	    EQU	4   ; GLCD Enable, keep high
GLCD_RST    EQU	5   ; GLCD Reset, (high=reset, low=no reset)
    
Y_addr	EQU 01000000B	; Y-address (add num 0-63 to this to select address)
X_addr	EQU 10111000B	; X-address (add num 0-7 to this to select address)

psect glcd_code, class=CODE
    
GLCD_Setup:
    clrf    LATB, A
    movlw   11000000B	    ; PortB 0:5 all outputs
    movwf   TRISB, A
    
    movlw   01010101B
    movwf   LATD, A
    
    clrf    LATD, A
    movlw   0x0		    ; PortD all outputs
    movwf   TRISD, A
    
    movlw   40
    call    LCD_delay_ms    ; TODO check that 40ms is the correct wait for LCD
			    ; to start properly
    bcf	    LATB, GLCD_RST, A
    movlw   10
    call    LCD_delay_ms
    bsf	    LATB, GLCD_RST, A
    bcf	    LATB, GLCD_CS1, A	; select left side (by clearing the cs1 bit)
    bsf	    LATB, GLCD_CS2, A 
    bcf	    LATB, GLCD_E, A	; sect enable to low by default
    
    movlw   01000000B
    movwf   y_pos_cnt, A	; reset y_position counter (y=0)
    movlw   10111000B
    movwf   x_pos_cnt, A	; reset x_position counter (x=0)
    
    movlw   250	
    call    LCD_delay_ms
    
    movlw   00111111B		; Turn on display
    call    GLCD_Send_I
    
    ;call    vert_line
    call    LCM_Reset
    ;call    vert_line
    return

GLCD_Send_I:
    movwf   LATD, A		; WREG taken as instruction
    bcf	    LATB, GLCD_RS, A	; set to low since instruction
    bcf	    LATB, GLCD_RW, A	; set to low since write
    call    GLCD_Enable
    return
    
GLCD_Send_D:
    movwf   LATD, A		; WREG taken as data
    bsf	    LATB, GLCD_RS, A	; set to high since data
    bcf	    LATB, GLCD_RW, A	; set to low since write
    call    GLCD_Enable
    return
    
GLCD_Read:	
    movlw   0xFF		; PortD all inputs
    movwf   TRISD, A
    ;clrf    LATD, A
    
    bsf	    LATB, GLCD_RS, A	; set to high since data
    bsf	    LATB, GLCD_RW, A	; set to high since read
    
    movlw   1
    call    LCD_delay_x4us
    bsf	    LATB, GLCD_E, A	; Start enable pulse
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ;movlw   200
    ;call    LCD_delay_ms
    
    movff   PORTD, out_data	; temporarily output to out_data
    movff   out_data, PORTE
    
    bcf	    LATB, GLCD_E, A	; End enable pulse
    bcf	    LATB, GLCD_RW, A	; set to low since write
    
    movlw   10
    call    LCD_delay_ms
    
    movlw   0x00		; PortD all outputs
    movwf   TRISD, A
    movf    out_data, W, A	; Output data to WREG
    return
    
LCM_Reset:
    movlw   10111000B
    call    GLCD_Send_I	    ; Select x=0 column
    reset_loop1:
	movf    x_pos_cnt, W, A
	call	GLCD_Send_I	    ; Select y=0 column
	incf    x_pos_cnt, F, A ; increment the x-pos counter
	reset_loop2:
	    movlw   00000000B   
	    call    GLCD_Send_D
	
	    incf    y_pos_cnt, F, A ; increment the y-pos counter
	    movlw   01111111B	    ; This is the max y-value
	    cpfseq  y_pos_cnt, A    ; Check if counter has reached max val
	    bra	    reset_loop2	  ; If it hasn't loop back to loop2 until it has
	    
	    movlw   10111111B	    ; This is the max x-value
	    cpfsgt  x_pos_cnt, A    ; Check if counter has reached max val
	    bra	    reset_loop1	  ; If it hasn't loop back to loop1 until it has
    movlw   01000000B
    movwf   y_pos_cnt, A	; reset y_position counter
    movlw   10111000B
    movwf   x_pos_cnt, A	; reset x_position counter  
    return
    
GLCD_Enable:		    ; Pulse enable bit GLCD_E
    movwf   W2, A	    ; Move whatever is in WREG to W2 to avoid issues
    movlw   1
    call    LCD_delay_x4us
    bsf	    LATB, GLCD_E, A
    movlw   1
    call    LCD_delay_x4us
    bcf	    LATB, GLCD_E, A
    movf    W2, W, A	    ; Move W2 back to W
    return


; ** a few delay routines below here as LCD timing can be quite critical ****
LCD_delay_ms:		    ; delay given in ms in W
	movwf	LCD_cnt_ms, A
lcdlp2:	movlw	250	    ; 1 ms delay
	call	LCD_delay_x4us	
	decfsz	LCD_cnt_ms, A
	bra	lcdlp2
	return
    
LCD_delay_x4us:		    ; delay given in chunks of 4 microsecond in W
	movwf	LCD_cnt_l, A	; now need to multiply by 16
	swapf   LCD_cnt_l, F, A	; swap nibbles
	movlw	0x0f	    
	andwf	LCD_cnt_l, W, A ; move low nibble to W
	movwf	LCD_cnt_h, A	; then to LCD_cnt_h
	movlw	0xf0	    
	andwf	LCD_cnt_l, F, A ; keep high nibble in LCD_cnt_l
	call	LCD_delay
	return
	
LCD_delay:			; delay routine	4 instruction loop == 250ns	    
	movlw 	0x00		; W=0
lcdlp1:	decf 	LCD_cnt_l, F, A	; no carry when 0x00 -> 0xff
	subwfb 	LCD_cnt_h, F, A	; no carry when 0x00 -> 0xff
	bc 	lcdlp1		; carry, then loop again
	return			; carry reset so return
