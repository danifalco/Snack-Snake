#include <xc.inc>
    
psect	udata_acs   ; named variables in access ram

W2	    ds	1   ; Second WREG 

GLCD_CS1    EQU	0   ; GLCD Chip Select 1 (1-64)
GLCD_CS2    EQU	1   ; GLCD Chip Select 2 (65-128)
GLCD_RS	    EQU	2   ; GLCD Register Select (high=data, low=instruct) aka DI
GLCD_RW	    EQU	3   ; GLCD Read/Write (high=read, low=write)
GLCD_E	    EQU	4   ; GLCD Enable, keep high
GLCD_RST    EQU	5   ; GLCD Reset, (high=reset, low=no reset)
    
Y_addr	EQU 01000000B	; Y-address (add num 0-63 to this to select address)
X_addr	EQU 10111000B	; X-address (add num 0-7 to this to select address)
write_d EQU 

psect glcd_code, class=CODE
    
GLCD_Setup:
    clrf    LATB, A
    movlw   11000000B	    ; PortB 0:5 all outputs
    movwf   TRISB, A
    
    clrf    LATD, A
    movlw   0x0		    ; PortD all outputs
    movwf   TRISD, A
    
    movlw   40
    call    LCD_delay_ms    ; TODO check that 40ms is the correct wait for LCD
			    ; to start properly
			    
    bsf	    LATB, GLCD_RST, A
    bcf	    LATB, GLCD_CS1, A	; select left side (by clearing the cs1 bit)
    bsf	    LATB, GLCD_CS2, A 
    bcf	    LATB, GLCD_E, A	; sect enable to low by default
    
    movlw   250	
    call    LCD_delay_ms
    
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
    
GLCD_Enable:		    ; Pulse enable bit GLCD_E
    movwf   W2		    ; Move whatever is in WREG to W2 to avoid issues
    movlw   1
    call    LCD_delay_ms
    bsf	    PORTB, GLCD_E, A
    call    LCD_delay_ms
    bcf	    PORTB, GLCD_E, A
    movf    W2, W	    ; Move W2 back to W
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