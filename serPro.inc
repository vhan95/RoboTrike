;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  SERPRO.INC                                ;
;                         Serial Proccessing Functions                       ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for constants for the serial processing
; functions. Included are constants for the laser status, input sign values,
; error values, maximum input values, a mask, token types, and state numbers
; for the mealy state machine.
;
; Revision History:
;    12/05/14   Victor Han    updated comments
;    12/05/14   Victor Han    initial revision

; SetLaser Constants
LASER_ON_VAL      EQU     1             ;pass this to SetLaser to turn laser on
LASER_OFF_VAL     EQU     0             ;pass this to SetLaser to turn laser off

; Input Sign Constants
POS_SIGN          EQU     1             ;value denoting a positive parsed input
NEG_SIGN          EQU     2             ;value denoting a negative parsed input
NULL              EQU     0             ;value denoting an unsigned/pos input

; Error COnstants
ERROR_VAL         EQU     1             ;denotes that an error has been caught
NO_ERROR          EQU     0             ;denotes that there is currently no error

; Max Value Constants
MAX_TUR_ELV       EQU     60            ;max magnitude of number passed into 
                                        ;  the set turret elevation command
MAX_INPUT_VAL     EQU     32768         ;max negative magnitude and one above
                                        ;  max positive magnitude of number
                                        ;  passed into any other command

; Token Constants

; token utilities
TOKEN_MASK        EQU     01111111B     ;used to allow token lookup in the
                                        ;  TokenTypeTable and TokenValueTable
                                        ;  as those tables are indexed with the
                                        ;  unmasked bits in this mask
NUM_TOKEN_TYPES   EQU     12            ;total number of token types. used in
                                        ;  indexing to find the proper state
                                        ;  machine transition and action

; token types                           ;indexed sequentially
TOKEN_SIGN        EQU     0             ;a sign character
TOKEN_DIGIT       EQU     1             ;a numerical digit for a number
TOKEN_OTHER       EQU     2             ;any token not in another category
TOKEN_EOS         EQU     3             ;carriage return to mark end of command
TOKEN_ABS_SPD     EQU     4             ;indicates Set Absolute Speed command
TOKEN_REL_SPD     EQU     5             ;indicates Set Relative Speed command
TOKEN_SET_DIR     EQU     6             ;indicates Set Direction command 
TOKEN_ROT_TUR     EQU     7             ;indicates Rotate Turret Angle command
TOKEN_TUR_ELV     EQU     8             ;indicates Set Turret Elevation command
TOKEN_LASERON     EQU     9             ;indicates Fire Laser command
TOKEN_LASEROFF    EQU     10            ;indicates Laser Off command
TOKEN_IGNORE      EQU     11            ;indicates horizonal whitespace to be 
                                        ;  ignored

; Mealy State Machine States            ;indexed sequentially

IDLE            EQU       0             ;waits for a new command
ST_ERROR        EQU       1             ;error state that waits for TOKEN_EOS
                                        ;  to go back to IDLE
ABS_SPD         EQU       2             ;beginning of Absolute Speed command
ABS_SPD_SIGN    EQU       3             ;Absolute Speed command track after 
                                        ;  parsing a sign
ABS_SPD_DIGIT   EQU       4             ;Absolute Speed command track after
                                        ;  parsing a digit
REL_SPD         EQU       5             ;Relative Speed command track beginning
REL_SPD_SIGN    EQU       6             ;Relative Speed command track after
                                        ;  parsing a sign
REL_SPD_DIGIT   EQU       7             ;Relative Speed command track after
                                        ; parsing a digit
SET_DIR         EQU       8             ;Set Direction command track beginning
SET_DIR_SIGN    EQU       9             ;Set Direction command track after 
                                        ;  parsing a sign
SET_DIR_DIGIT   EQU       10            ;Set Direction command track after 
                                        ;  parsing a digit
ROT_TUR         EQU       11            ;Rotate Turret command track beginning
ROT_TUR_SIGN    EQU       12            ;Rotate Turret command track after
                                        ;  parsing a sign
ROT_TUR_DIGIT   EQU       13            ;Rotate Turret command track after
                                        ;  parsing a digit
TUR_ELV         EQU       14            ;Turret Elevation command track beginning
TUR_ELV_SIGN    EQU       15            ;Turret Elevation command track after
                                        ;  parsing a sign
TUR_ELV_DIGIT   EQU       16            ;Turret Elevation command track after 
                                        ;  parsing a digit
LASER_ON        EQU       17            ;Fire Laser command on EOS
LASER_OFF       EQU       18            ;Laser Off command on EOS