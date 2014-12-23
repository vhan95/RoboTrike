;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                 MAIN.INC                                   ;
;                                Main Loops                                  ;
;                                 EE/CS 51                                   ;
;                               Include File                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for constants used in the main loops for 
; both the RoboTrike board and the remote board. Included are indexes for errors
; and the length of an error string, which are used for finding the memory 
; locations of the proper error messages to be displayed.
;
; Revision History:
;     12/14/14    Victor Han    updated comments
;     12/13/14    Victor Han    initial revision

; Error Indexing Constant definitions

CRITICAL_ERROR_INDEX    EQU     3  ;index for the critical error string in the
                                   ;  TrikeErrorStrTable and RemoteErrorStrTable
UNKNOWN_ERROR_INDEX     EQU     4  ;index for the unknown error string in the
                                   ;  TrikeErrorStrTable and RemoteErrorStrTable
PARSING_ERROR_INDEX     EQU     5  ;index for the parsing error string in the
                                   ;  TrikeErrorStrTable and RemoteErrorStrTable

ERROR_STR_LEN           EQU     9  ;the length of an error string. used to find
                                   ;  the proper index in the error tables when
                                   ;  multiplied by the sequential indices
