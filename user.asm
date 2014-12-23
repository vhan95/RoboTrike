        NAME    user

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                     USER                                   ;
;                           User Interface Functions                         ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; This file contains the functional specification and implementation for the
; ParseUserKeypress function. Using this function with the 
; ParseUserKeypress_Jump_Table and the Keyval_Command_Table allow for the 
; mapping of key presses on the keypad to the appropriate commands sent to
; the RoboTrike board. ParseUserKeypress expects to be called whenever a key 
; event is dequeued from the EventQueue. The mapping between key and command is 
; displayed on the following table.
;        ____________ ____________ ____________ ____________
;       |Move        |Turn Around |Turn Left   |Turn Right  |
;       |____________|____________|____________|____________| 
;       |Inc Speed   |Dec Speed   |Shift Left  |Shift Right |
;       |____________|____________|____________|____________| 
;       |Fire Laser  |Laser Off   |Do Nothing  |Do Nothing  |
;       |____________|____________|____________|____________| 
;       |Do Nothing  |Do Nothing  |Do Nothing  |Stop        |
;       |____________|____________|____________|____________| 
;
; Contents:
;     ParseUserKeypress: Maps the user keypress into a RoboTrike command.
;     ParseUserKeypress_Jump_Table: Determines whether a particular keypress
;                                   should send a command or not.
;     Keyval_Command_Table: Determines what command string a particular keypress
;                           should send.
;
; Revision History:
;    12/14/14  Victor Han       updated comments
;    12/13/14  Victor Han       wrote the assembly code
;    12/08/14  Victor Han       initial revision

; local include files
$INCLUDE(general.inc)   ; includes definitions for general constants
$INCLUDE(user.inc)      ; includes definitions for indexing the command string
                        ;   table                          

CGROUP  GROUP   CODE

CODE	SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP
        
        EXTRN   SerialPutString:NEAR  ;sends a string to the RoboTrike board
        
        
; ParseUserKeypress
;
; Description:       Maps the user keypress into a RoboTrike command or nothing.
;
; Operation:         Uses the passed in key value to index the 
;                    ParseUserKeypress_Jump_Table, which allows for a jump to
;                    either doing nothing or sending a command. If the key value
;                    is one for which a command should be sent, the key value
;                    is then used to index Keyval_Command_Table, which contains
;                    command strings to be sent to the RoboTrike board. These
;                    strings are sent using SerialPutString.
;
; Arguments:         AL - value of the key that was pressed.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags, AX, BX, ES
; Known Bugs:        None.
; Limitations:       None.
; Special Notes:     None.
;
; Revision History:     
;    12/14/14  Victor Han       updated comments
;    12/13/14  Victor Han       wrote the assembly code
;    12/08/14  Victor Han       initial revision

ParseUserKeypress   PROC    NEAR
                    PUBLIC  ParseUserKeypress
                    
        MOV     BL, AL      ;get the proper jump table index
        MOV     BH, 0
        SHL     BX, 1       ;because the jump table is a word table
        JMP     CS:ParseUserKeypress_Jump_Table[BX] ;find if the keyvalue should
                                                    ;  be acted upon or not
        
KeypressDoNothing:
        JMP     ParseUserKeypressEnd  ;do nothing
        
KeypressSendCommand:
        SHR     BX, 1           ;undo a previous action to get back key val
        MOV     AX, BX          ;ready key val for multiplication
        MOV     BX, CMD_LEN
        MUL     BX              ;get actual command string table index
        MOV     BX, AX          ;move result to indexing register
        LEA     SI, CS:Keyval_Command_Table[BX] ;get address of first cmd char
        PUSH    CS              ;prepare for SerialPutString call
        POP     ES
        CALL    SerialPutString ;send the cmd to the RoboTrike board
        ;JMP     ParseUserKeypressEnd ;done
        
ParseUserKeypressEnd:
        RET    
        
ParseUserKeypress   ENDP

        
; ParseUserKeypress_Jump_Table 
;
; Description:      This table is used to determine which label in 
;                   ParseUserKeypress should be jumped to based on the passed
;                   in keypad key. The only two options are KeypressDoNothing
;                   and KeypressSendCommand.
;
; Notes:            READ ONLY tables should always be in the code segment so
;                   that in a standalone system it will be located in the
;                   ROM with the code.
;
; Revision History:
;    12/14/14  Victor Han       updated comments
;    12/13/14  Victor Han       updated table contents
;    12/08/14  Victor Han       initial revision

ParseUserKeypress_Jump_Table    LABEL   WORD
                                PUBLIC  ParseUserKeypress_Jump_Table
                        
;       DW         label                   Keys pressed in row. x for pressed
;                                            o for not pressed

;row 1
        DW         KeypressDoNothing       ;oooo
        DW         KeypressSendCommand     ;xooo
        DW         KeypressSendCommand     ;oxoo
        DW         KeypressDoNothing       ;xxoo
        DW         KeypressSendCommand     ;ooxo
        DW         KeypressDoNothing       ;xoxo
        DW         KeypressDoNothing       ;oxxo
        DW         KeypressDoNothing       ;xxxo
        DW         KeypressSendCommand     ;ooox
        DW         KeypressDoNothing       ;xoox
        DW         KeypressDoNothing       ;oxox
        DW         KeypressDoNothing       ;xxox
        DW         KeypressDoNothing       ;ooxx
        DW         KeypressDoNothing       ;xoxx
        DW         KeypressDoNothing       ;oxxx
        DW         KeypressDoNothing       ;xxxx
;row 2
        DW         KeypressDoNothing       ;oooo
        DW         KeypressSendCommand     ;xooo
        DW         KeypressSendCommand     ;oxoo
        DW         KeypressDoNothing       ;xxoo
        DW         KeypressSendCommand     ;ooxo
        DW         KeypressDoNothing       ;xoxo
        DW         KeypressDoNothing       ;oxxo
        DW         KeypressDoNothing       ;xxxo
        DW         KeypressSendCommand     ;ooox
        DW         KeypressDoNothing       ;xoox
        DW         KeypressDoNothing       ;oxox
        DW         KeypressDoNothing       ;xxox
        DW         KeypressDoNothing       ;ooxx
        DW         KeypressDoNothing       ;xoxx
        DW         KeypressDoNothing       ;oxxx
        DW         KeypressDoNothing       ;xxxx
;row 3
        DW         KeypressDoNothing       ;oooo
        DW         KeypressSendCommand     ;xooo
        DW         KeypressSendCommand     ;oxoo
        DW         KeypressDoNothing       ;xxoo
        DW         KeypressSendCommand     ;ooxo
        DW         KeypressDoNothing       ;xoxo
        DW         KeypressDoNothing       ;oxxo
        DW         KeypressDoNothing       ;xxxo
        DW         KeypressSendCommand     ;ooox
        DW         KeypressDoNothing       ;xoox
        DW         KeypressDoNothing       ;oxox
        DW         KeypressDoNothing       ;xxox
        DW         KeypressDoNothing       ;ooxx
        DW         KeypressDoNothing       ;xoxx
        DW         KeypressDoNothing       ;oxxx
        DW         KeypressDoNothing       ;xxxx
;row 4
        DW         KeypressDoNothing       ;oooo
        DW         KeypressSendCommand     ;xooo
        DW         KeypressSendCommand     ;oxoo
        DW         KeypressDoNothing       ;xxoo
        DW         KeypressSendCommand     ;ooxo
        DW         KeypressDoNothing       ;xoxo
        DW         KeypressDoNothing       ;oxxo
        DW         KeypressDoNothing       ;xxxo
        DW         KeypressSendCommand     ;ooox
        DW         KeypressDoNothing       ;xoox
        DW         KeypressDoNothing       ;oxox
        DW         KeypressDoNothing       ;xxox
        DW         KeypressDoNothing       ;ooxx
        DW         KeypressDoNothing       ;xoxx
        DW         KeypressDoNothing       ;oxxx
        DW         KeypressDoNothing       ;xxxx
        
  
; macros for command string readability in Keyval_Command_Table

; macro for a command string. all strings are NULL terminated
%*DEFINE(CMD(char0, char1, char2, char3, char4, char5, char6, char7))  (
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

; macro for a null command. this command should generate no action for the 
;   RoboTrike
%*DEFINE(CMDNULL)  (
        DB      ' '           ; white-space is ignored when parsing commands
        DB      ' '
        DB      ' '
        DB      ' '
        DB      ' '
        DB      ' '
        DB      ' '
        DB      ' '
		DB      ASCII_NULL
)

; Keyval_Command_Table 
;
; Description:      This table is used to determine which command string a
;                   keypress should send to the RoboTrike board. To get the
;                   proper string address, the keypress value should be
;                   multiplied by CMD_LEN. The indexing for each string macro
;                   is the same as in ParseUserKeypress_Jump_Table.
;
; Notes:            READ ONLY tables should always be in the code segment so
;                   that in a standalone system it will be located in the
;                   ROM with the code.
;
; Revision History:
;    12/14/14  Victor Han       updated comments
;    12/13/14  Victor Han       updated table contents
;    12/08/14  Victor Han      initial revision

Keyval_Command_Table        LABEL   BYTE
                            PUBLIC  Keyval_Command_Table
			
;       command string                        Keys pressed in row, cmd if any

; row1
        %CMDNULL                               ;oooo
        %CMD('S','7','5','0','0',' ',' ',' ')  ;xooo  sets some initial speed
        %CMD('D','1','8','0',' ',' ',' ',' ')  ;oxoo  reverses RoboTrike direction
        %CMDNULL                               ;xxoo 
        %CMD('D','2','7','0',' ',' ',' ',' ')  ;ooxo  turns the RoboTrike left
        %CMDNULL                               ;xoxo
        %CMDNULL                               ;oxxo
        %CMDNULL                               ;xxxo
        %CMD('D','9','0',' ',' ',' ',' ',' ')  ;ooox  turns the RoboTrike right
        %CMDNULL                               ;xoox
        %CMDNULL                               ;oxox
        %CMDNULL                               ;xxox
        %CMDNULL                               ;ooxx
        %CMDNULL                               ;xoxx
        %CMDNULL                               ;oxxx
        %CMDNULL                               ;xxxx
;row 2
        %CMDNULL                               ;oooo
        %CMD('V','5','0','0',' ',' ',' ',' ')  ;xooo  increases speed
        %CMD('V','-','5','0','0',' ',' ',' ')  ;oxoo  decreases speed
        %CMDNULL                               ;xxoo
        %CMD('D','-','1','0',' ',' ',' ',' ')  ;ooxo  shifts direction to left
        %CMDNULL                               ;xoxo
        %CMDNULL                               ;oxxo
        %CMDNULL                               ;xxxo
        %CMD('D','+','1','0',' ',' ',' ',' ')  ;ooox  shifts direction to right
        %CMDNULL                               ;xoox
        %CMDNULL                               ;oxox
        %CMDNULL                               ;xxox
        %CMDNULL                               ;ooxx
        %CMDNULL                               ;xoxx
        %CMDNULL                               ;oxxx
        %CMDNULL                               ;xxxx
;row 3
        %CMDNULL                               ;oooo
        %CMD('F',' ',' ',' ',' ',' ',' ',' ')  ;xooo  fires the laser
        %CMD('O',' ',' ',' ',' ',' ',' ',' ')  ;oxoo  turns off the laser
        %CMDNULL                               ;xxoo
        %CMDNULL                               ;ooxo
        %CMDNULL                               ;xoxo
        %CMDNULL                               ;oxxo
        %CMDNULL                               ;xxxo
        %CMDNULL                               ;ooox
        %CMDNULL                               ;xoox
        %CMDNULL                               ;oxox
        %CMDNULL                               ;xxox
        %CMDNULL                               ;ooxx
        %CMDNULL                               ;xoxx
        %CMDNULL                               ;oxxx
        %CMDNULL                               ;xxxx
;row4
        %CMDNULL                               ;oooo
        %CMDNULL                               ;xooo
        %CMDNULL                               ;oxoo
        %CMDNULL                               ;xxoo
        %CMDNULL                               ;ooxo
        %CMDNULL                               ;xoxo
        %CMDNULL                               ;oxxo
        %CMDNULL                               ;xxxo
        %CMD('S','0',' ',' ',' ',' ',' ',' ')  ;ooox  stops the RoboTrike
        %CMDNULL                               ;xoox
        %CMDNULL                               ;oxox
        %CMDNULL                               ;xxox
        %CMDNULL                               ;ooxx
        %CMDNULL                               ;xoxx
        %CMDNULL                               ;oxxx
        %CMDNULL                               ;xxxx

CODE    ENDS


        END