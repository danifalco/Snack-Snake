#include <xc.inc>

global	randgen_setup, random_int, spawn_food, vert_line
global	food_x, food_y
    
extrn	x_pos, y_pos, check_if_in_snek, in_snek, loop_cnt, snek_len, x_Arr
extrn	y_Arr
extrn	LCD_delay_ms
extrn	vert_line
; Below is borrowed from propagation.s
extrn	Y_POS_COMMAND, X_POS_COMMAND, y_col_inst, x_row_inst, x_temp, temp
extrn	dirty_read, GLCD_Send_I, GLCD_Send_D, remain
    
psect	udata_acs
ranx:	    ds 1    ; Reserve 1 byte for the random number of x
rany:	    ds 1    ; Reserve 1 byte for the random number of y
food_x:	    ds 1    ; Reserve 1 byte for x-position of food spawn
food_y:	    ds 1    ; Reserve 1 byte for y-position of food spawn
temp_1:	    ds 1
temp_2:	    ds 1    ; Reserve space for 2 temp variables 
    
psect	randgen_code,class=CODE
    
randgen_setup:
    clrf    T0CON, A	    ; Reset everything
    bsf	    T0CON, 2, A	    ; Make timer slowish
    bsf	    T0CON, 1, A	    ; Make timer slowish
    bsf	    T0CON, 3, A	    ; I think this increases count speed
    ;	    4		    ; We don't really care about bit 4 see pg186
    bcf	    T0CON, 5, A	    ; Timer uses internal clock instead of external
    bsf	    T0CON, 6, A	    ; Timer configured as an 8-bit counter
    bsf	    T0CON, 7, A	    ; Enables Timer0
    
    clrf    T1CON, A	    ; Reset everything
    bsf	    T1CON, 3, A	    ; I think this increases count speed
    bsf	    T1CON, 2, A	    ; This makes the count speed 16x slower than x for extra randomness
    bsf	    T1CON, 0, A
    ;	    4		    ; We don't really care about bit 4 see pg186
    bcf	    T1CON, 5, A	    ; Timer uses internal clock instead of external
    bsf	    T1CON, 6, A	    ; Timer configured as an 8-bit counter
    bsf	    T1CON, 7, A	    ; Enables Timer1
    
;    clrf    T4CON, A	    ; Reset everything
;    bsf	    T4CON, 1, A	    ; Turn on timer4
    
    return
    
random_int:	    ; Generates random number between 0 and 63 (inclusive)
    movff   TMR0, ranx	; Take a reading off of timer
    movff   TMR1, rany	
    movlw   00111111B	
    andwf   ranx, F, A	; Make rand number something between 0-63
    andwf   rany, F, A
    return
    
spawn_food: ; Generates random position for x and y for the food to spawn in
	    ; checks said position is not inside the snake and if so displays it
    call    random_int
    movff   ranx, food_x
    movff   rany, food_y
    
    call    check_if_in_snek_food   ; Check if rand points are inside snek
				    ; Keep trying until false
    call    display_food
    return
    
    
check_if_in_snek_food:	; Checks if x_pos is in x_Arr and y_Arr: retries if yes
    ; A very close copy to subroutine in arrays.s
    clrf    in_snek, A	    ; Clear check variable (see uses below)
    clrf    loop_cnt, A
    check_x_loop_food:
	movf    INDF0, W, A	; moves the value of first position in array to WREG
	cpfseq  food_x, A	; Compare if value is the same as x_pos, if so handle
	bra	continue_loop_x_food    ; x_pos is not in x_Arr, continue
	;call	vert_line
	bra	in_x_arr_food  ; x_pos somewhere in x_Arr, check for y
	continue_loop_x_food:
	movf	snek_len, W, A	; Load snek_len to WREG
	incf	loop_cnt, A	; Increase counter
	incf	FSR0L, A	; Move array pointer to next location
	incf	FSR1L, A	; Also move y_arr pointer
	cpfslt	loop_cnt, A	; Check if counter has reached snek_len
	bra	end_check_food	
	bra	check_x_loop_food	

in_x_arr_food:   ; x_pos == x_Arr[i], so check if y_pos == y_Arr[i]
    movf    INDF1, W, A
    cpfseq  food_y, A		; Compare if value is same as y_pos if so handle
    bra	    continue_loop_x_food	; If it's not in y_arr, keep checking until done
    bra	    try_again		; TODO CHANGE TO spawn_food	    
    incf    in_snek, A		; x_value is true, increment in_snek and check y 

try_again:
    lfsr    0, x_Arr
    lfsr    1, y_Arr
    goto    spawn_food
end_check_food:	    ; x_pos and y_pos not in snake. Reset counters and return
    lfsr    0, x_Arr	    ; Reset FSR0 to point to x_Arr
    lfsr    1, y_Arr	    ; Reset FSR1 to point to y_Arr
    return
    
temp_thing:
    goto    spawn_food
    
display_food:
    ; Slightly different subroutine but identical in essence to propagation.s subroutine
    
    movf    food_y, W, A    	; Move new y position into WREG
    ;movwf   y_pos, A
    addlw   Y_POS_COMMAND	; Sum with the command vlaue and store in W
    movwf   y_col_inst, A
    
    ;	********** X-Position Code **********
    movff   food_x, x_temp, A	; Move the x position to its temporary variable
    
    bcf	    CARRY		; Clear the carry flag ready for rotation
    rrcf    x_temp, F, A	; Divide x_temp by 8 (i.e. divide by 2 3 times)
    btfsc   CARRY
    bsf	    remain, 0, A
    
    bcf	    CARRY		; Clear the carry flag ready for rotation
    rrcf    x_temp, F, A		; Divide x_temp by 8 (i.e. divide by 2 3 times)
    btfsc   CARRY
    bsf	    remain, 1, A
    
    bcf	    CARRY		; Clear the carry flag ready for rotation
    rrcf    x_temp, F, A		; Divide x_temp by 8 (i.e. divide by 2 3 times)
    btfsc   CARRY
    bsf	    remain, 2, A
    ; Now x_temp has been divided by 8 (so this will be the x page) and the 
    ; carry variable contains the pixel to light up within this page (column)
    
    movf    x_temp, W, A		; Move new x position into WREG
    addlw   X_POS_COMMAND	; Sum with the command value and store in W
    movwf   x_row_inst, A
    
    movlw   00000001B
    movwf   temp, A
    movlw   0x0
    pos_loop_:
	cpfsgt	remain, A
	bra	end_display_
	addlw	1
	rlncf	temp, F, A
	bra	pos_loop_
	
end_display_:
    movff   temp, remain	; Free temp by moving temp to remain
    
    call    dirty_read
    
    movwf   temp, A		; Move the read result into temp variable
    
    movf    y_col_inst, W, A
    call    GLCD_Send_I		; Select y column
    
    movf    temp, W, A		; Restore value from GLCD_Read into WREG
    
    iorwf   remain, W, A	; OR W and remain, store in W
    call    GLCD_Send_D
    
    movf    food_y, W, A	; Move new y position into WREG
    addlw   Y_POS_COMMAND	; Sum with the command vlaue and store in W
    call    GLCD_Send_I		; Reset y position since GLCD_Read +1'ed it
    return
