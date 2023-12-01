#include <xc.inc>

global	propagation_setup, init_position, propagate, dsp_pos
global	mv_right, mv_left, mv_up, mv_down
global	remain, temp, counter

extrn	GLCD_Send_I, GLCD_Send_D, vert_line
    
psect udata_acs	    ; named variables in access RAM

x_pos:	    ds	1   ; reserve 1 byte for current x position
y_pos:	    ds	1   ; reserve 1 byte for current y position
x_prev:	    ds	1   ; reserve 1 byte for previous x position
y_prev:	    ds	1   ; reserve 1 byte for previous y position
x_temp:	    ds	1   ; reserve 1 temporary byte for x
y_temp:	    ds	1   ; reserve 1 temporary byte for y
remain:	    ds	1   ; reserve 1 byte for the division remainder
temp:	    ds	1   ; reserve 1 byte for a versatile temp variable
counter:    ds	1   ; reserve 1 byte for a counter variable
    
one:	    ds	1
two:	    ds  1
three:	    ds	1
four:	    ds  1
    
    Y_POS_COMMAND   EQU	01000000B
    X_POS_COMMAND   EQU 10111000B
 
psect propagation_code,class=CODE
    
propagation_setup:
    movlw   1
    movwf   one, A
    movlw   2
    movwf   two, A
    movlw   3
    movwf   three, A
    movlw   4
    movwf   four, A
    
    clrf    remain, A
    
    return    

init_position:
    movlw   0x0
    movwf   x_pos, A
    movlw   0x0
    movwf   y_pos, A
    
    return
    
propagate:  ; Propagate: 1 - Right, 2 - Left, 3 - Up, 4 - Down
    
    ;movff    x_pos, x_prev, A
    ;movff    y_pos, y_prev, A
    clrf    remain
    cpfseq  one, A
    bra	    left
    call    mv_right
    call    dsp_pos	    ; Branch to display position
    
left:
    cpfseq  two, A
    bra	    up
    call    mv_left
    call    dsp_pos
    
up: 
    cpfseq  three, A
    bra	    down
    call    mv_up
    call    dsp_pos
   
down:
    cpfseq  four, A
    call    mv_down
    call    dsp_pos

dsp_pos:
    movf    y_pos, W, A		; Move new y position into WREG
    addlw   Y_POS_COMMAND	; Sum with the command vlaue and store in W
    call    GLCD_Send_I		; Send instruction to select y
    
    ; ****************delete******************
;    movlw   10111000B
;    call    GLCD_Send_I	    ; Select x=0 column
;    movlw   11111111B
;    call    GLCD_Send_D
    
    ;*****************************************
    
    ;	********** X-Position Code **********
    movff   x_pos, x_temp, A	; Move the x position to its temporary variable
    
    bcf	    CARRY		; Clear the carry flag ready for rotation
    rrcf    x_temp, 1		; Divide x_temp by 8 (i.e. divide by 2 3 times)
    btfsc   CARRY
    bsf	    remain, 0
    
    bcf	    CARRY		; Clear the carry flag ready for rotation
    rrcf    x_temp, 1		; Divide x_temp by 8 (i.e. divide by 2 3 times)
    btfsc   CARRY
    bsf	    remain, 1
    
    bcf	    CARRY		; Clear the carry flag ready for rotation
    rrcf    x_temp, 1		; Divide x_temp by 8 (i.e. divide by 2 3 times)
    btfsc   CARRY
    bsf	    remain, 2
    ; Now x_temp has been divided by 8 (so this will be the x page) and the 
    ; carry variable contains the pixel to light up within this page (column)
    
    movf    x_temp, W, A	; Move new x position into WREG
    addlw   X_POS_COMMAND	; Sum with the command value and store in W
    call    GLCD_Send_I		; Send instruction to select y
    
    movlw   00000001B
    movwf   temp, A
    movlw   0x0
    pos_loop:
	cpfsgt	remain
	bra	end_display
	addlw	1
	rlncf	temp
	bra	pos_loop
	
end_display:
    movf    temp, W, A
    call    GLCD_Send_D
    
    return    
    
mv_right:
    movlw   62
    cpfslt  y_pos, A
    return
    incf    y_pos, A
    return
    
mv_left:
    movlw   0x0
    cpfseq  y_pos, A
    return
    decf    y_pos, A
    return
    
mv_up:
    movlw   0x0
    cpfseq  x_pos, A
    return
    decf    x_pos, A
    return
    
mv_down:
    movlw   63
    cpfslt  x_pos, A
    return
    incf    x_pos, A
    return
