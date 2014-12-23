        NAME  ERROR_TBL

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   ERROR_TBL                                ;
;                           Tables of error messages                         ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the tables of characters making up strings to display as
; error messages to the user.
;       TrikeErrorStrTable: Error messages for errors from the RoboTrike board
;       RemoteErrorStrTable: Error messages for errors from the remote board
;
; Revision History:
;    12/14/14  Victor Han      updated comments
;    12/13/14  Victor Han      initial revision



; local include files
$INCLUDE(general.inc)


;setup code group and start the code segment
CGROUP  GROUP   CODE

CODE    SEGMENT PUBLIC 'CODE'

;macro defining a string for readability. All strings are NULL terminated.

%*DEFINE(STRING(char0, char1, char2, char3, char4, char5, char6, char7))  (
        DB      %char0
        DB      %char1
        DB      %char2
        DB      %char3
        DB      %char4
        DB      %char5
        DB      %char6
        DB      %char7
        DB      ASCII_NULL
)


; TrikeErrorStrTable 
;
; Description:      This table is used to determine which error message should
;                   be displayed to the user. It is indexed by error, with some
;                   indices defined in main.inc.
;                   This specific table holds error messages for errors coming
;                   from the RoboTrike side. TE stands for Trike Error.
;
; Notes:            READ ONLY tables should always be in the code segment so
;                   that in a standalone system it will be located in the
;                   ROM with the code.
;
; Revision History:
;    12/14/14  Victor Han      updated comments
;    12/13/14  Victor Han      initial revision

TrikeErrorStrTable          LABEL   BYTE
                            PUBLIC  TrikeErrorStrTable
			
        %STRING('T','E',' ','O','v','r','u','n') ;serial overrun error
        %STRING('T','E',' ','P','r','i','t','y') ;serial parity error
        %STRING('T','E',' ','F','r','m','n','g') ;serial framing error
        %STRING('T','E',' ','C','r','t','c','l') ;critical error
        %STRING('T','E',' ','U','n','k','n','w') ;unknown error
        %STRING('T','E',' ','P','r','s','n','g') ;command parsing error
        
; RemoteErrorStrTable 
;
; Description:      This table is used to determine which error message should
;                   be displayed to the user. It is indexed by error, with some
;                   indices defined in main.inc.
;                   This specific table holds error messages for errors coming
;                   from the remote side. RE stands for Remote Error.
;
; Notes:            READ ONLY tables should always be in the code segment so
;                   that in a standalone system it will be located in the
;                   ROM with the code.
;
; Revision History:
;    12/14/14  Victor Han      updated comments
;    12/13/14  Victor Han      initial revision

RemoteErrorStrTable         LABEL   BYTE
                            PUBLIC  RemoteErrorStrTable
			
        %STRING('R','E',' ','O','v','r','u','n') ;serial overrun error
        %STRING('R','E',' ','P','r','i','t','y') ;serial parity error
        %STRING('R','E',' ','F','r','m','n','g') ;serial framing error
        %STRING('R','E',' ','C','r','t','c','l') ;critical error
        %STRING('R','E',' ','U','n','k','n','w') ;unknown error

CODE    ENDS



        END
