;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                QUEUE.INC                                   ;
;                             Queue Functions                                ;
;                                 EE/CS 51                                   ;
;                               Include File                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for constants used in the queue functions
; (queue.asm) as well as the definition for the queue structure.
;
; Revision History:
;     12/13/14    Victor Han    added SET_WORD_SIZE and SET_BYTE_SIZE
;     11/01/14    Victor Han    initial revision

; Constant definitions

MAX_SIZE       EQU     256             ; max size possible for the queue in 
                                       ; bytes. This is set because we do not
                                       ; dynamically allocate memory
BYTE_SIZE      EQU     1               ; number of data array index values that
                                       ; a byte sized element in the queue takes
WORD_SIZE      EQU     2               ; number of data array index values that
                                       ; a word sized element in the queue takes
SET_WORD_SIZE  EQU     1               ; value to pass to InitQueue as an 
                                       ; argument if a queue with word elements
                                       ; is desired
SET_BYTE_SIZE EQU     0               ;indicates that a queue should be 
                                       ;  initialized with byte sized elements

; Structure for the queue

QUEUE         STRUC                  
    head      DW       ?                         ; index of the top element of
                                                 ; the queue relative to the
                                                 ; byte indexed array qdata
                                                 ; holding the values
	tail      DW       ?                         ; index below the bottom
                                                 ; element of the queue relative
                                                 ; to the byte indexed array
                                                 ; qdata holding the values
	len       DW       ?                         ; length of the array qdata 
                                                 ; holding the queue values in
                                                 ; bytes
	elem_size DW       ?                         ; the size of an element in
                                                 ; the queue. set to BYTE_SIZE
                                                 ; for bytes and WORD_SIZE for
                                                 ; words
	qdata     DB       MAX_SIZE    DUP    (?)    ; array holding the actual 
                                                 ; values of the queue. indexed
                                                 ; by bytes
QUEUE         ENDS
