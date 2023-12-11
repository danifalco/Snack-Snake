#include <xc.inc>

extrn	x_pos, y_pos, Setup
    
global	array_setup, snek_not_grow, snek_grow, ret_x_tail, ret_y_tail
global	ret_x_head, ret_y_head
global	snek_len, check_if_in_snek
global	x_Arr, y_Arr, in_snek, loop_cnt
    
psect	udata_acs
snek_len:	ds  1	    ; Reserve 1 byte for length of snake
loop_cnt:	ds  1	    ; Reserve 1 byte for a loop counter
temp_:		ds  1	    ; Useful temp variable
in_snek:	ds  1	    ; variable to check whether snek eats itself

psect	udata_bank1	    ; We store the x-values array in bank 1
x_Arr:		ds  0xFF    ; We can have a snake of length up to 256
psect	udata_bank2	    ; Store the y-values in bank 2
y_Arr:		ds  0xFF    

psect	array_code,class=CODE

array_setup:
    lfsr    0, x_Arr	    ; Load FSR0 to point to x_Arr
    lfsr    1, y_Arr	    ; Load FSR1 to point to y_Arr
    
    movlw   0		    ; Start snake at y=(0, 0, 0, 0, 0) x=(5, 4, 3, 2, 1)  
			    ; Remember the head of the snake is the first number
    movwf   INDF1, A	
    incf    FSR1L, A
    movwf   INDF1, A
    incf    FSR1L, A
    movwf   INDF1, A
    incf    FSR1L, A
    movwf   INDF1, A
    incf    FSR1L, A
    movwf   INDF1, A
    incf    FSR1L, A
    movwf   INDF1, A
    incf    FSR1L, A
    movwf   INDF1, A
    incf    FSR1L, A
    
    movlw   7
    movwf   INDF0, A
    incf    FSR0L, A
    movlw   6
    movwf   INDF0, A
    incf    FSR0L, A
    movwf   snek_len, A	    ; Snake initially has length 7 so it has value 6
    movlw   5
    movwf   INDF0, A
    incf    FSR0L, A
    movlw   4
    movwf   INDF0, A
    incf    FSR0L, A
    movlw   3
    movwf   INDF0, A
    incf    FSR0L, A
    movlw   2
    movwf   INDF0, A
    incf    FSR0L, A
    movlw   1
    movwf   INDF0, A
    
    lfsr    0, x_Arr	    ; Reload FSR Pointers
    lfsr    1, y_Arr
    return

snek_not_grow:
    ; Shifts every value of the array to the right, puts the new value of x,y in
    ; the first array intexes. Does NOT increase snek_len. This will probably 
    ; Run into trouble when snek_len>255 but hey    
    movf    snek_len, W, A  ; Load snek length into W
    addwf   FSR0L, A	    ; Select the nth position of the list
    movlw   0x0
    movwf   loop_cnt, A
    snek_not_grow_loop_x:
	movf    INDF0, W, A	; Move the value of n to WREG
	incf    FSR0L, A	; Select position n+1
	movwf   INDF0, A	; Move WREG to n+1
	decf    FSR0L, A	; Move pointer back to n
	movf	snek_len, W, A	; Move snek len to W to compare in next inst
	cpfslt	loop_cnt, A ; Break loop once snek_len iterations are performed
	bra	_in_new_x
	decf    FSR0L, A	; Move pointer to n-1 (if loop hasn't terminated)
	incf	loop_cnt, A	; Increment the counter
	bra	snek_not_grow_loop_x
    _in_new_x:
	lfsr	0, x_Arr	; Set FRS0 back to back to the first point
	movff	x_pos, INDF0	
	bra	snek_not_grow_y	; Notice how we can't increase length yet, first
				; deal with the y array
	
snek_not_grow_y:			; Same thing as x, but with y
    movf    snek_len, W, A 
    addwf   FSR1L, A	    
    movlw   0x0
    movwf   loop_cnt, A
    snek_not_grow_loop_y:
	movf    INDF1, W, A
	incf    FSR1L, A	
	movwf   INDF1, A	
	decf    FSR1L, A	
	movf	snek_len, W, A
	cpfslt	loop_cnt, A 
	bra	_in_new_y
	decf    FSR1L, A	
	incf	loop_cnt, A	
	bra	snek_not_grow_loop_y
    _in_new_y:
	lfsr	0, y_Arr	
	movff	y_pos, INDF1
	return			    ; Notice we do not increase snek_len
	
	
snek_grow:
    ; Shifts every value of the array to the right, puts the new value of x,y in
    ; the first array indexes and increses snek_len by 1
    movf    snek_len, W, A  ; Load snek length into W
    addwf   FSR0L, A	    ; Select the nth position of the list
    movlw   0x0
    movwf   loop_cnt, A
    snek_grow_loop_x:
	movf    INDF0, W, A	; Move the value of n to WREG
	incf    FSR0L, A	; Select position n+1
	movwf   INDF0, A	; Move WREG to n+1
	decf    FSR0L, A	; Move pointer back to n
	movf	snek_len, W, A	; Move snek len to W to compare in next inst
	cpfslt	loop_cnt, A ; Break loop once snek_len iterations are performed
	bra	in_new_x
	decf    FSR0L, A	; Move pointer to n-1 (if loop hasn't terminated)
	incf	loop_cnt, A	; Increment the counter
	bra	snek_grow_loop_x
    in_new_x:
	lfsr	0, x_Arr	; Set FRS0 back to back to the first point
	movff	x_pos, INDF0	; TODO CHANGE
	bra snek_grow_y		; Notice how we can't increase length yet, first
				; deal with the y array
	
snek_grow_y:			; Same thing as x, but with y
    movf    snek_len, W, A 
    addwf   FSR1L, A	    
    movlw   0x0
    movwf   loop_cnt, A
    snek_grow_loop_y:
	movf    INDF1, W, A
	incf    FSR1L, A	
	movwf   INDF1, A	
	decf    FSR1L, A	
	movf	snek_len, W, A
	cpfslt	loop_cnt, A 
	bra	in_new_y
	decf    FSR1L, A	
	incf	loop_cnt, A	
	bra	snek_grow_loop_y
    in_new_y:
	lfsr	0, y_Arr	
	movff	y_pos, INDF1
	incf	snek_len, A	; This time, increase snek_len
	return
	
ret_x_tail:	; Returns the x-position of the tali in WREG
    movf    snek_len, W, A	   
    addwf   FSR0L, A	    ; Point FSR0 to last element (i.e. tail)
    movf    INDF0, W, A	    ; Move tail value to WREG
    lfsr    0, x_Arr	    ; Reset FSR0 to point to x_Arr
    return
    
ret_y_tail:	; Returns the y-position of the tail in WREG
    movf    snek_len, W, A	   
    addwf   FSR1L, A	    ; Point FSR1 to last element (i.e. tail)
    movf    INDF1, W, A	    ; Move tail value to WREG
    lfsr    1, y_Arr	    ; Reset FSR1 to point to y_Arr
    return
    
ret_x_head:	; Returns the x-position of the head in WREG
    lfsr    0, x_Arr	    
    movf    INDF0, W, A
    return
    
ret_y_head:	; Returns the y-position of the head in WREG
    lfsr    1, y_Arr	    
    movf    INDF1, W, A
    return
    
check_if_in_snek:	; Checks if x_pos is in x_Arr and y_Arr: resets if yes
    clrf    in_snek, A	    ; Clear check variable (see uses below)
    clrf    loop_cnt, A
    check_x_loop:
	movf    INDF0, W, A	; moves the value of first position in array to WREG
	cpfseq  x_pos, A	; Compare if value is the same as x_pos, if so handle
	bra	continue_loop_x	    ; x_pos is not in x_Arr, continue
	bra	in_x_arr  ; x_pos somewhere in x_Arr, check for y
	continue_loop_x:
	movf	snek_len, W, A	; Load snek_len to WREG
	incf	loop_cnt, A	; Increase counter
	incf	FSR0L, A	; Move array pointer to next location
	incf	FSR1L, A	; Also move y_arr pointer
	cpfslt	loop_cnt, A	; Check if counter has reached snek_len
	bra	end_check			; These names are getting long...
	bra	check_x_loop	

in_x_arr:   ; x_pos == x_Arr[i], so check if y_pos == y_Arr[i]
    movf    INDF1, W, A
    cpfseq  y_pos, A		; Compare if value is same as y_pos if so handle
    bra	    continue_loop_x	; If it's not in y_arr, keep checking until done
    goto    Setup	    
    incf    in_snek, A		; x_value is true, increment in_snek and check y 

end_check:	    ; x_pos and y_pos not in snake. Reset counters and return
    lfsr    0, x_Arr	    ; Reset FSR0 to point to x_Arr
    lfsr    1, y_Arr	    ; Reset FSR1 to point to y_Arr
    return
