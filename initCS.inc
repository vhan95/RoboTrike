;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                INITCS.INC                                  ;
;                          Chip Select Functions                             ;
;                                 EE/CS 51                                   ;
;                               Include File                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for constants used in initializing chip
; selects (InitCS.asm). Included are addesses adn values to write to those
; adddresses.
;
; Revision History:
;     12/14/14    Victor Han    updated comments
;     11/01/14    Victor Han    initial revision


; Chip Select Unit Definitions

; Addresses
PACSreg         EQU     0FFA4H          ;address of PACS register
MPCSreg         EQU     0FFA8H          ;address of MPCS register

; Control Register Values
PACSval         EQU     00003H          ;PCS base at 0, 3 wait states
                                        ;0000000000------  starts at address 0
                                        ;----------000---  reserved
                                        ;-------------0--  wait for RDY inputs
                                        ;--------------11  3 wait states
MPCSval         EQU     00183H          ;PCS in I/O space, use PCS5/6, 3 wait states
                                        ;0---------000---  reserved
                                        ;-0000001--------  MCS is 8KB
                                        ;--------1-------  output PCS5/PCS6
                                        ;---------0------  PCS in I/O space
                                        ;-------------0--  wait for RDY inputs
                                        ;--------------11  3 wait states
