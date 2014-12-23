;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  mtrLsr.INC                                ;
;                          Motor and Laser Functions                         ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for the motor and laser functions 
; (mtrLsr.asm). Included are constants regarding the 8255A programmable 
; peripheral interface control, RoboTrike speed and angle settings, the 
; number of movement motors on the RoboTrike, and Port B parallel I/O constants.


; 8255A Programmable Peripheral Interface Addresses

PERIPH_CONTROL_ADDR      EQU       0183H         ;Address of the 8255A control 
                                                 ;  word
PERIPH_CONTROL_VAL       EQU       10011001B     ;Value to be written to the
                                                 ;  8255A control word. The 
                                                 ;  0th, 3rd, and 4th bits are
                                                 ;  set to make Port C and Port
                                                 ;  A input, though they don't
                                                 ;  matter. Bit 2 is 0 to make
                                                 ;  Port B output. Bit 3 is 0 to
                                                 ;  select mode 0 for group B.
                                                 ;  Bits 5 and 6 are 0 to select
                                                 ;  mode 0 for group A. And bit
                                                 ;  7 is set to 1 to activate 
                                                 ;  the mode set flag.                                                 

; RoboTrike Speed and Angle Constants

NUM_SPEEDS               EQU       128           ;Number of different speeds 
                                                 ;  each individual motor of the
                                                 ;  RoboTrike can move at.
MAX_SPEED                EQU       65534         ;Maximum value GetMotorSpeed 
                                                 ;  will return.
DONT_CHANGE_SPEED        EQU       65535         ;Input speed value to  
                                                 ;  SetMotorSpeed that does not 
                                                 ;  change the current RoboTrike 
                                                 ;  speed.
DONT_CHANGE_ANGLE        EQU       -32768        ;Input angle value to 
                                                 ;  SetMotorSpeed that does not
                                                 ;  change the current RoboTrike
                                                 ;  direction.

; RoboTrike Motor Constants

NUM_MOTORS               EQU       3             ;Number of RoboTrike motors for
                                                 ;  its wheels (motors for 
                                                 ;  moving).

; Port B Parallel I/O Constants

PORTB_ADDR               EQU       0181H         ;Address of I/O Port B. Writing
                                                 ;  to this address turns the
                                                 ;  motors and laser on or off.
LASER_BIT_ON             EQU       10000000B     ;Value that should be written
                                                 ;  to Port B in order to turn
                                                 ;  the laser bit on.
