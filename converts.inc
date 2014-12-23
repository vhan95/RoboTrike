;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   CONVERTS                                 ;
;                             Conversion Functions                           ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;This file contains the definitions for the converts procecdures 
;(converts.asm).
;
;Revision History:
;    12/14/14  Victor Han        removed NULL_CHAR
;    10/25/14  Victor Han        initial revision
;


; General Definitions
    SIGN_BIT            EQU    1000000000000000B    ;sign bit of a word
    ASCII_NUM_OFFSET    EQU    '0'      ;add this to digit to get ASCII value
    ASCII_CHAR_OFFSET   EQU    'A'-10   ;add to cap letter to get ASCII value
    BIGGEST_HEX_DIGIT   EQU    1000h    ;largest hex digit possible for the 
                                        ;  result of the conversion in Hex2String
    BIGGEST_DEC_DIGIT   EQU    10000    ;largest decimal digit possible for the
                                        ;  result of the conversion in Dec2String