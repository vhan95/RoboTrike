;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                 USER.INC                                   ;
;                         User Inferface Functions                           ;
;                                 EE/CS 51                                   ;
;                               Include File                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for constants used in the user interface
; functions, such as for indexing the command string table. 
;
; Revision History:
;     12/14/14    Victor Han    updated comments
;     12/13/14    Victor Han    initial revision

; Command string definitions

CMD_LEN         EQU     9  ;the length of a command string. used for table 
                           ;  indexing