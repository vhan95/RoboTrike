;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                               GENERAL.INC                                  ;
;                            general constants                               ;
;                                 EE/CS 51                                   ;
;                               Include File                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for constants used in several files and are
; universal to the system.
;
; Revision History:
;     12/14/14    Victor Han    updated comments
;     12/13/14    Victor Han    initial revision

; Universal Constant definitions

TRUE                    EQU     1    ;a true boolean value
FALSE                   EQU     0    ;a false boolean value
ASCII_NULL              EQU     0    ;the ASCII code for the NULL character
ASCII_RET               EQU     13   ;the ASCII code for the carriage return
NUM_DIGITS              EQU     8    ;number of digits on the remote board LED
                                     ;  display

; Event Key Definitions

SERIAL_CHAR_EVENT       EQU     100B ;event key for a character received over 
                                     ;  serial
SERIAL_ERROR_EVENT      EQU     110B ;event key for a serial error event
KEYPRESS_EVENT          EQU     0EH  ;event key for a keypad keypress
