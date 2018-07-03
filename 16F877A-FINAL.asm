    #INCLUDE <P16F877A.INC>
    __CONFIG _HS_OSC&_WDT_OFF&_PWRTE_ON&_CP_OFF
	
	#DEFINE OUTPUT_LED PORTC,3
	
	#DEFINE PST_LCK	   0x20,0   ;States to help with code flow
	#DEFINE PST_OPN	   0x20,1   ;States to help with code flow
	
	#DEFINE BT_OPN_CLS PORTB,7  ;Open/Close button
	#DEFINE BT_PSW_CHG PORTB,6  ;Password change button
	
	#DEFINE MATRIX_1   PORTD,6  ;Keyboard
	#DEFINE MATRIX_2   PORTD,5  ;Keyboard
	#DEFINE MATRIX_3   PORTD,4  ;Keyboard
	#DEFINE MATRIX_A   PORTD,3  ;Keyboard
	#DEFINE MATRIX_B   PORTD,2  ;Keyboard
	#DEFINE MATRIX_C   PORTD,1  ;Keyboard
	#DEFINE MATRIX_D   PORTD,0  ;Keyboard
	
	;Memory definitions
	#DEFINE PASS_PRESS_1 0x21   ;Value in the 1st key-press
	#DEFINE PASS_PRESS_2 0x22   ;Value in the 2nd key-press
	#DEFINE PASS_PRESS_3 0x23   ;Value in the 3rd key-press
	#DEFINE PASS_PRESS_4 0x24   ;Value in the 4th key-press
	
	#DEFINE PASSWORD_1 0x25	    ;1st password value
	#DEFINE PASSWORD_2 0x26	    ;2nd password value
	#DEFINE PASSWORD_3 0x27	    ;3rd password value
	#DEFINE PASSWORD_4 0x28	    ;4th password value
		
;Just goes to setup from here
	ORG	0x00
	GOTO	SETUP

;Interrupt routine
	ORG 	0x04			;Start of interrupt routine
	BTFSC	INTCON,0		;check which interruption happened (RBIF here)
	GOTO 	INTERRUPT_PRIORITY
	GOTO	INTR_EXIT
INTERRUPT_PRIORITY			;Here we check which interrupt happened
	BTFSC	BT_OPN_CLS			
	GOTO 	BT_INT_CHECK		;Open/Close operation
	
	BTFSC	BT_PSW_CHG
	GOTO 	PASSWORD_CHANGE		;Password change operation
	
	GOTO	INTERRUPT_PRIORITY
	
PASSWORD_CHANGE
	BTFSS	BT_PSW_CHG		;Just waiting the the key to be released
	GOTO 	PASSWORD_CHANGE_CONT
	GOTO	PASSWORD_CHANGE
PASSWORD_CHANGE_CONT
	BTFSC	PST_LCK	
	GOTO	INTR_EXIT   ;We can't continue unless the lock is open 
	
	;If the lock is open we can proceed capturing the new password
	CALL	BT_PRESS_LOOP
	MOVWF	PASSWORD_1
	CALL	BT_PRESS_LOOP
	MOVWF	PASSWORD_2
	CALL	BT_PRESS_LOOP
	MOVWF	PASSWORD_3
	CALL	BT_PRESS_LOOP
	MOVWF	PASSWORD_4
	
	;Then we clear W just to be safe
	CLRW
	
	;Then we can lock it again
	BSF	PST_LCK
	BCF	PST_OPN
	BSF	OUTPUT_LED
	
	;And we can finally leave the interruption
	GOTO	INTR_EXIT

;In the Open/Close operation we always arrive here first
;And we wait for the key to be released
BT_INT_CHECK				
	BTFSS	BT_OPN_CLS
	GOTO 	STATE_CHANGE_0
	GOTO	BT_INT_CHECK

;The course of the code changes if the lock is open or closed
STATE_CHANGE_0
	BTFSC	PST_LCK	
	GOTO	STATE_CHANGE_PST_LCK
	BTFSC	PST_OPN
	GOTO	STATE_CHANGE_PST_OPN

;Again we wait for the key to be released then proceed to the password insertion
STATE_CHANGE_PST_LCK				
	BTFSS	BT_OPN_CLS
	GOTO 	LCK
	GOTO	STATE_CHANGE_PST_LCK				

;Again we wait for the key to be released then proceed to locking
STATE_CHANGE_PST_OPN		
	BTFSS	BT_OPN_CLS
	GOTO 	OPN
	GOTO	STATE_CHANGE_PST_OPN

;Here we'll just lock things
OPN
	BSF	PST_LCK
	BCF	PST_OPN
	BSF	OUTPUT_LED
	GOTO	INTR_EXIT

;Here we'll check if the user knows the correct password
LCK
	;Just to make sure everything stays at it should
	BSF	PST_LCK
	BCF	PST_OPN
	BSF	OUTPUT_LED
	
	;Calling the button press loop subroutine 
	;so we can get key-presses and store them
	CALL	BT_PRESS_LOOP
	MOVWF	PASS_PRESS_1
	CALL	BT_PRESS_LOOP
	MOVWF	PASS_PRESS_2
	CALL	BT_PRESS_LOOP
	MOVWF	PASS_PRESS_3
	CALL	BT_PRESS_LOOP
	MOVWF	PASS_PRESS_4
	
	;Now we start to compare the pressed keys with the password
	MOVF	PASS_PRESS_1,0
	SUBWF	PASSWORD_1,0
	BTFSS	STATUS,2
	GOTO	STAY_LOCKED
	
	MOVF	PASS_PRESS_2,0
	SUBWF	PASSWORD_2,0
	BTFSS	STATUS,2
	GOTO	STAY_LOCKED
	
	MOVF	PASS_PRESS_3,0
	SUBWF	PASSWORD_3,0
	BTFSS	STATUS,2
	GOTO	STAY_LOCKED
	
	MOVF	PASS_PRESS_4,0
	SUBWF	PASSWORD_4,0
	BTFSS	STATUS,2
	GOTO	STAY_LOCKED
	
	;If every key was correct we can open
	GOTO	CAN_OPEN
		
BT_PRESS_LOOP
	;We energise each letter while waiting for presses in the numbers
	BSF	MATRIX_A
	BCF	MATRIX_B
	BCF	MATRIX_C
	BCF	MATRIX_D
	BTFSC	MATRIX_1
	GOTO	A_1_PRESSED
	BTFSC	MATRIX_2
	GOTO	A_2_PRESSED
	BTFSC	MATRIX_3
	GOTO	A_3_PRESSED
	
	;Energising the B line
	BCF	MATRIX_A
	BSF	MATRIX_B
	BCF	MATRIX_C
	BCF	MATRIX_D
	BTFSC	MATRIX_1
	GOTO	B_1_PRESSED
	BTFSC	MATRIX_2
	GOTO	B_2_PRESSED
	BTFSC	MATRIX_3
	GOTO	B_3_PRESSED
	
	;Energising the C line
	BCF	MATRIX_A
	BCF	MATRIX_B
	BSF	MATRIX_C
	BCF	MATRIX_D
	BTFSC	MATRIX_1
	GOTO	C_1_PRESSED
	BTFSC	MATRIX_2
	GOTO	C_2_PRESSED
	BTFSC	MATRIX_3
	GOTO	C_3_PRESSED
	
	;Energising the D line
	BCF	MATRIX_A
	BCF	MATRIX_B
	BCF	MATRIX_C
	BSF	MATRIX_D
	BTFSC	MATRIX_1
	GOTO	D_1_PRESSED
	BTFSC	MATRIX_2
	GOTO	D_2_PRESSED
	BTFSC	MATRIX_3
	GOTO	D_3_PRESSED
	
	;Back to the beginning of the loop if nothing was pressed
	GOTO	BT_PRESS_LOOP

;Depending on which key was pressed, we load W with a different value
;and call for a subroutine that prevents keys from being capture multiple times
A_1_PRESSED
	MOVLW	b'00000001'
	CALL	BT_RLS_CHK_ROUTINE
	RETURN
A_2_PRESSED
	MOVLW	b'00000010'
	CALL	BT_RLS_CHK_ROUTINE
	RETURN
A_3_PRESSED
	MOVLW	b'00000011'
	CALL	BT_RLS_CHK_ROUTINE
	RETURN
B_1_PRESSED
	MOVLW	b'00000100'
	CALL	BT_RLS_CHK_ROUTINE
	RETURN
B_2_PRESSED
	MOVLW	b'00000101'
	CALL	BT_RLS_CHK_ROUTINE
	RETURN
B_3_PRESSED
	MOVLW	b'00000111'
	CALL	BT_RLS_CHK_ROUTINE
	RETURN
C_1_PRESSED
	MOVLW	b'00001000'
	CALL	BT_RLS_CHK_ROUTINE
	RETURN
C_2_PRESSED
	MOVLW	b'00001001'
	CALL	BT_RLS_CHK_ROUTINE
	RETURN
C_3_PRESSED
	MOVLW	b'00001010'
	CALL	BT_RLS_CHK_ROUTINE
	RETURN
D_1_PRESSED
	MOVLW	b'00001011'
	CALL	BT_RLS_CHK_ROUTINE
	RETURN
D_2_PRESSED
	MOVLW	b'00001100'
	CALL	BT_RLS_CHK_ROUTINE
	RETURN
D_3_PRESSED
	MOVLW	b'00001101'
	CALL	BT_RLS_CHK_ROUTINE
	RETURN

BT_RLS_CHK_ROUTINE ;In this subroutine we prevent accidental key-presses
BT_RLS_CHK_1		
	BTFSS	MATRIX_1
	GOTO 	BT_RLS_CHK_2
	GOTO	BT_RLS_CHK_1
BT_RLS_CHK_2		
	BTFSS	MATRIX_2
	GOTO 	BT_RLS_CHK_3
	GOTO	BT_RLS_CHK_2
BT_RLS_CHK_3	
	BTFSS	MATRIX_3
	RETURN
	GOTO	BT_RLS_CHK_3
	
;If the inserted password is wrong we arrive here
STAY_LOCKED
	BSF	OUTPUT_LED
	BSF	PST_LCK
	BCF	PST_OPN
	GOTO	INTR_EXIT

;And if it's correct we arrive here
CAN_OPEN
	BCF	OUTPUT_LED
	BCF	PST_LCK
	BSF	PST_OPN
	GOTO	INTR_EXIT

;Before exiting the interrupt we need to clean our mess
INTR_EXIT	
	BCF	MATRIX_A
	BCF	MATRIX_B
	BCF	MATRIX_C
	BCF	MATRIX_D
	CLRF	PASS_PRESS_1
	CLRF	PASS_PRESS_2
	CLRF	PASS_PRESS_3
	CLRF	PASS_PRESS_4
	
	BCF	INTCON,0	;And we also need to clear interrupt flags
	RETFIE

SETUP
	;Port configuration
	BSF     STATUS,5		;Switch to Bank 1               
	MOVLW   b'11110000'		
	MOVWF   TRISD			;Set Port D pins to input/output
	MOVLW   b'11000000'	
	MOVWF   TRISB			;Set Port B pins to input/output

	MOVLW   b'00000000'		
	MOVWF   TRISC			;Set Port C pins to output
	MOVLW	b'000000'
	MOVWF	TRISA			;Set Port A pins to output
	
	MOVLW	b'10001000';		
	MOVWF	INTCON;			;interrupt enable bits (global, RB7:RB4)

	BCF     STATUS,5		;Switch back to Bank 0
	
	;Initially clearing everything
	CLRF	PORTA
	CLRF	PORTB
	CLRF	PORTC
	CLRF	PORTD
		
	BSF	OUTPUT_LED
	
	BSF	PST_LCK
	BCF	PST_OPN
	
	;Clearing the key-press values
	CLRF	PASS_PRESS_1
	CLRF	PASS_PRESS_2
	CLRF	PASS_PRESS_3
	CLRF	PASS_PRESS_4
	
	;Default password
	MOVLW	b'00000001'
	MOVWF	PASSWORD_1
	MOVLW	b'00000010'
	MOVWF	PASSWORD_2
	MOVLW	b'00000011'
	MOVWF	PASSWORD_3
	MOVLW	b'00000100'
	MOVWF	PASSWORD_4
	
	GOTO	START
START
	GOTO	START
	END