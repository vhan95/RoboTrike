;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  KEYPAD.INC                                ;
;                              Display Functions                             ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for the keypad functions (keypad.asm). 
; Included are general definitions about the keypad, times used in determining
; presses, defintions for checking key values, and the key pressed event value.
;
; Revision History:
;    11/16/14  Victor Han   Updated Comments
;    11/14/14  Victor Han   Initial Revision


; General Keypad Definitions

KEYPAD          EQU    80H             ;Keypad base address. First keypad row

NUM_ROWS        EQU    4               ;number of rows in keypad

; Debouncing and Auto-Repeat Defintions

DEBOUNCE_TIME   EQU    30              ;time to debounce for in milliseconds

REPEAT_TIME     EQU    1000            ;wait time before auto-repeating a key
                                       ;  press. That is, time before a single
                                       ;  press counts as another press. 
                                       ;  Represents milliseconds.
                                       
; Key Checking Definitions

NOTHING_PRESSED EQU    0FH             ;second hex digit represents the value
                                       ;  that is given when no keys are pressed
                                       ;  for a row when the row is read.

DIGIT_MASK      EQU    0FH             ;value used to mask the first hex digit
                                       ;  of a byte

; Keypressed Event Definitions

KEY_EVENT       EQU    0EH             ;keypad event value. tells other 
                                       ;  functions what that a keypad event has
                                       ;  occured.
INPUTS_PER_ROW  EQU    16

