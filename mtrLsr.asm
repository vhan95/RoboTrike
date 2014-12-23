        NAME    MTRLSR

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                    MTRLSR                                  ;
;                          Motor and Laser Functions                         ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; This file contains the functional specifications and implementations for the
; SetMotorSpeed, GetMotorSpeed, GetMotorDirection, InitMotorAndLaser, 
; PulseWidthMod, SetLaser, and GetLaser functions. Together these functions 
; allow for the RoboTrike speed and direction to be set and read, the laser
; status to be set and read, and the motors and lasers to be actually run when
; PulseWidthMod is called by a separate timer event handler. 
;
; Contents:
;     SetMotorSpeed: Sets the speed and angle at which the RoboTrike should run,
;                    as well as the speeds and directions of the individual 
;                    motors.                    
;     GetMotorSpeed: Returns the current speed of the RoboTrike.
;     GetMotorDirection: Returns the current angle of motion of the RoboTrike.
;     InitMotorLaserParallel: Initializes motor and laser related shared  
;                             variables as well as the parallel I/O control 
;                             register.
;     PulseWidthMod: Actually implements the pulse width modulation of the 
;                    motors when it is called from a timer event handler. Also
;                    turns on the laser if it should.
;     SetLaser: Sets the laser status to be on or off.
;     GetLaser: Returns the laser status.
;
; Revision History:
;    11/22/14  Victor Han       wrote and debugged the assembly code
;    11/17/14  Victor Han       initial revision

; local include files
$INCLUDE(mtrLsr.inc)            ;includes definitions for constants regarding
                                ;  addresses, speeds and angles, number of 
                                ;  motors, and the laser output bit

CGROUP  GROUP   CODE
DGROUP  GROUP   DATA


CODE	SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP, DS:DGROUP
        
        ;tables of values for the calculation of individual motor angles and 
        ;  directions
        
        EXTRN   Sin_Table:WORD   ;values for the sin of angles
        EXTRN   Cos_Table:WORD   ;values for the cosine of angles
		
		
; SetMotorSpeed
;
; Description:       Sets the RoboTrike's speed and direction. The speed is 
;                    passed in as AX and is the absolute speed at which the 
;                    RoboTrike should run. A value of DONT_CHANGE_SPEED does
;                    not change the RoboTrike speed and all other speeds are
;                    greater with greater values of AX. The angle is passed in
;                    BX and is the signed angle at which the RoboTrike should
;                    move in degrees with zero degrees being straight ahead
;                    relative to the RoboTrike orientation. An angle of
;                    DONT_CHANGE_ANG does not change the RoboTrike angle.
;                    Angles are measured clockwise. Each individual  motor's
;                    speed and direction are also calculated.
;
; Operation:         If the passed in speed argument is not DONT_CHANGE_SPEED,
;                    the RoboTrikeSpeed shared variable is updated. If the 
;                    passed in angle is not DONT_CHANGE_ANGLE, the RoboTrikeDir
;                    shared variable is updated. Once the correct RoboTrike 
;                    speed and direction are obtained, the speeds and directions
;                    for each of the motors are calculated. This is done by
;                    taking the dot product of each motor's orientation with
;                    the RoboTrike velocity vector. That is, if Fx and Fy are
;                    the components of a motor's orientation in the x and y 
;                    directions respectively, then the speed of the motor will 
;                    be Fx*speed*cos(angle) + Fy*speed*sin(angle), with the
;                    sign bit of the result indicating whether the motor should
;                    be run forwards or backwards. This direction is then stored
;                    in the MotorDir[] shared variable and the absolute value
;                    of the motor's speed is stored in the PulseWidths[] shared
;                    variable.
;                    
;
; Arguments:         AX (speed) - Tells what speed the RoboTrike should run at.
;                                 Unsigned. Greater values mean greater speed.
;                                 If is DONT_CHANGE_SPEED, RoboTrikeSpeed is not
;                                 changed.
;                    BX (angle) - Tells what angle the RoboTrike should move at.
;                                 Signed value with zero being the angle right
;                                 ahead of the RoboTrike. If is DONT_CHANGE_ANG,
;                                 RoboTrikeDir is not changed. Angles are 
;                                 measured clockwise relative to the RoboTrike.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  RoboTrikeSpeed - written to and read
;                    RoboTrikeDir - written to and read
;                    PulseWidths[] - written to
;                    MotorDir[] - written to
; Global Variables:  None.
;
; Input:             None.
; Output:            Indirect movement through PulseWidthMod.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags, AX, BX, CX, DX
; Known Bugs:        None.
; Limitations:       Individual motor speeds resulting from calculations have
;                    7 bits of accuracy.
; Special Notes:     None.
;
; Revision History:     
;    11/22/14  Victor Han      wrote and debugged the assembly code
;    11/17/14  Victor Han      initial revision

SetMotorSpeed       PROC    NEAR
                    PUBLIC  SetMotorSpeed
                    
        CMP     AX, DONT_CHANGE_SPEED  ;check if should change RoboTrikeSpeed
        JNE     NewSpeed
        ;JE     OldSpeed
        
OldSpeed:
        MOV     AX, RoboTrikeSpeed     ;keep old speed
        ;JMP    SpeedDone
        
NewSpeed:
        MOV     RoboTrikeSpeed, AX     ;update RoboTrikeSpeed
        ;JMP    SpeedDone
        
SpeedDone:
        SHR     AX, 1                  ;change speed into Q0.15 fixed point form
        ;JMP    CheckAngle
        
CheckAngle:
        CMP     BX, DONT_CHANGE_ANGLE  ;check if should change RoboTrikeDir
        JNE     NewAngle
        ;JE     OldAngle
        
OldAngle:
        MOV     BX, RoboTrikeDir       ;keep old direction
        JMP     CalcMotorSpeeds        ;move on
        
NewAngle:       
        PUSH    AX                     ;save speed for later use
        MOV     AX, BX                 ;prepare for division of input angle to 
        MOV     BX, 360                ;  get equivalent angle between -359 and 
        CWD                            ;  359
        IDIV    BX                     
        MOV     BX, DX                 ;equivalent angle is result of mod
        POP     AX                     ;speed will be needed next in a mult
        TEST    BX, BX                 ;check sign of angle
        JNS     NewAngleDone           ;if pos, done
        ;JS     MakeAnglePos           ;if neg, change to equivalent pos angle
        
MakeAnglePos:
        ADD     BX, 360                ;get equivalent pos angle
        ;JMP    NewAngleDone
        
NewAngleDone:
        MOV     RoboTrikeDir, BX       ;save angle
        ;JMP    CalcMotorSpeeds
              
CalcMotorSpeeds:
        SAL     BX, 1                  ;indexing for angles in trig tables are 
                                       ;  multiplied by 2 b/c word tables
        MOV     CX, NUM_MOTORS         ;initialize loop counter
        
CalcMotorSpeedsLoop:
        DEC     CX                     ;update loop counter
        JS      SetMotorSpeedDone      ;if counter is neg, done
        ;JNS    SpeedsCalc             ;otherwise, calc speeds for corresponding
                                       ;  motor
        
SpeedsCalc:
        PUSH    AX                     ;save speed for next loop iteration
        PUSH    AX                     ;save speed for next calc involving it
        PUSH    BX                     ;save cos/sin table index
        MOV     BX, CX                 ;need BX for motor table index
        SAL     BX, 1                  ;index is mult by 2 b/c word table
        IMUL    CS:MotorY_Table[BX]    ;v * Fy
        MOV     AX, DX                 ;truncate to DX
        POP     BX                     ;get angle index back
        IMUL    Sin_Table[BX]          ;v * Fy * sin(angle)
        POP     AX                     ;get back speed for next multiplication
        PUSH    DX                     ;save truncated value of 
                                       ;  v * Fy * sin(angle)
     
        IMUL    Cos_Table[BX]          ;v * cos(angle)
        MOV     AX, DX                 ;truncate to DX
        PUSH    BX                     ;save cos/sin table index
        MOV     BX, CX                 ;get index for motor table
        SAL     BX, 1                  ;multiply index by 2 b/c word table
        IMUL    CS:MotorX_Table[BX]    ;v * cos(angle) * Fx
        POP     BX                     ;get cos/sin table index back

        POP     AX                     ;get v * Fy * sin(angle) result
        ADD     AX, DX                 ;add the two multiplication results
        SAL     AX, 2                  ;truncate result
        PUSH    BX                     ;save sin/cos table index
        MOV     BX, CX                 ;get index for MotorDir and PulseWidths
        TEST    AH, AH                 ;check if speed is positive
        JNS     PosDir                 ;if so, motor direction is forwards
        ;JS     NegDir                 ;if not, motor direction is backwards
        
NegDir:
        MOV     MotorDir[BX], 1        ;motor direction is backwards
        NEG     AH                     ;make speed positive equivalent
        JMP     CalcDone
        
PosDir:
        MOV     MotorDir[BX], 0        ;motor direction is forwards
        ;JMP    CalcDone
        
CalcDone:
        MOV     PulseWidths[BX], AH    ;make truncated speed the pulsewidth  
                                       ;  because PulseWidthMod gives greater
                                       ;  PulseWidths values greater speeds
        POP     BX                     ;get back sin/cos table index
        POP     AX                     ;get back speed for next iteration
        JMP     CalcMotorSpeedsLoop    ;go to next iteration
		
SetMotorSpeedDone:
        RET
        
SetMotorSpeed       ENDP     


; GetMotorSpeed
;
; Description:       This procedure returns the current RoboTrike speed. Return
;                    values are between 0 and MAX_SPEED. A value of 0 means the
;                    RoboTrike is not moving.
;
; Operation:         Returns the RoboTrikeSpeed shared variable.
; Arguments:         None.
; Return Value:      AX - The current RoboTrike speed.
;
; Local Variables:   None.
; Shared Variables:  RoboTrikeSpeed - read
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
; Registers Changed: AX.
; Known Bugs:        None.
; Limitations:       None.
; Special Notes:     None.
;
; Revision History:   
;    11/22/14  Victor Han      wrote the assembly code  
;    11/17/14  Victor Han      initial revision

GetMotorSpeed       PROC    NEAR
                    PUBLIC  GetMotorSpeed
                    
        MOV     AX, RoboTrikeSpeed    ;put in return register
        RET
		
GetMotorSpeed       ENDP     


; GetMotorDirection
;
; Description:       This procedure returns the current RoboTrike angle. An 
;                    angle of zero means that the RoboTrike is moving straight
;                    ahead and other angles are measured clockwise relative to
;                    the RoboTrike orientation. Returned values are between
;                    0 and 359.
;
; Operation:         Returns the RoboTrikeDir shared variable.
; Arguments:         None.
; Return Value:      AX - The current RoboTrike angle.
;
; Local Variables:   None.
; Shared Variables:  RoboTrikeDir - read
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
; Registers Changed: AX.
; Known Bugs:        None.
; Limitations:       None.
; Special Notes:     None.
;
; Revision History:     
;    11/22/14  Victor Han      wrote the assembly code
;    11/17/14  Victor Han      initial revision

GetMotorDirection   PROC    NEAR
                    PUBLIC  GetMotorDirection
                    
        MOV     AX, RoboTrikeDir   ;put in return register
        RET
		
GetMotorDirection   ENDP        


; InitMotorLaserParallel
;
; Description:       This procedure initializes the RoboTrike motors, laser, and
;                    parallel I/O values. The RoboTrike starts out stationary,
;                    the laser is initially off, and Port B is set-up to be 
;                    output.
;
; Operation:         Sets RoboTrikeSpeed to be 0, RoboTrikeDir to be 0, all 
;                    PulseWidths values to be 0, all MotorDir values to be 0, 
;                    PulseWidthCounter to be NUM_SPEEDS - 1, and LaserStatus to
;                    be 0. Also sets the 8255A control word to 
;                    PERIPH_CONTROL_VAL.
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  RoboTrikeSpeed - written to
;                    RoboTrikeDir - written to
;                    PulseWidths[] - written to
;                    MotorDir[] - written to
;                    PulseWidthCounter - written to
;                    LaserStatus - written to
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
; Registers Changed: flags, AX, BX, DX.
; Known Bugs:        None.
; Limitations:       None.
; Special Notes:     None.
;
; Revision History:     
;    11/22/14  Victor Han      wrote the assembly code
;    11/17/14  Victor Han      initial revision

InitMotorLaserParallel      PROC    NEAR
                            PUBLIC  InitMotorLaserParallel
                    
        MOV     RoboTrikeSpeed, 0                  ;no initial movement
        MOV     RoboTrikeDir, 0                    ;no initial angle
        MOV     LaserStatus, 0                     ;laser initially off
        MOV     PulseWidthCounter, NUM_SPEEDS - 1  ;first call of PulseWidthMod
                                                   ;  will make PulseWidthCounter
                                                   ;  0
        MOV     DX, PERIPH_CONTROL_ADDR            ;Set up 8255A with Port B as
        MOV     AL, PERIPH_CONTROL_VAL             ;  output and mode 0
        OUT     DX, AL
        MOV     BX, NUM_MOTORS                     ;Set up for iteration through
                                                   ;  PulseWidths and MotorDir
        ;JMP    SetPulseWidthDirVars
        
SetPulseWidthDirVarsLoop:
        DEC     BX                                 ;Update loop iteration counter
        JS      InitMotorLaserDone                 ;If counter is negative, done
        ;JNS    SetPulseWidthDirVars               ;Else, set corresponding vars
        
SetPulseWidthDirVars:
        MOV     PulseWidths[BX], 0                 ;All motors initially 0 speed
        MOV     MotorDir[BX], 0                    ;Direction doesn't matter, 
                                                   ;  but all motors initially 
                                                   ;  set on forward drive
        JMP     SetPulseWidthDirVarsLoop           ;Go to next loop iteration
        
InitMotorLaserDone:
        RET
		
InitMotorLaserParallel      ENDP      


; PulseWidthMod
;
; Description:       This procedure implements the pulse width modulation of
;                    the motors when it is called from a timer event handler.
;
; Operation:         Each time this function is called, it increments the 
;                    PulseWidthCounter variable, wrapping when it reaches 
;                    NUM_SPEEDS. Whenever PulseWidthCounter is less than any 
;                    motor's value in PulseWidths, that corresponding motor is
;                    turned on with its corresponding direction. Whenever 
;                    PulseWidthCounter is greater or equal to one of these, the
;                    corresponding motor is turned off. Each corresponding motor
;                    on/off and direction bit is sequentially OR'd into an 
;                    initially empty AL. Once all of the motor bits have been 
;                    set, the correct laser bit is also OR'd in. Once this is 
;                    done, AL is finally output to Port B.
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  PulseWidths[] - read
;                    MotorDir[] - read
;                    PulseWidthCounter - read and written to
;                    LaserStatus - read
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
; Registers Changed: flags, AX, BX, CX, DX
; Known Bugs:        None.
; Limitations:       None.
; Special Notes:     None.
;
; Revision History:     
;    11/22/14  Victor Han      wrote the assembly code
;    11/17/14  Victor Han      initial revision

PulseWidthMod       PROC    NEAR
                    PUBLIC  PulseWidthMod
                    
        MOV     AL, 0                            ;eventually will output this to
                                                 ;  Port B
        MOV     BX, NUM_MOTORS                   ;set up loop counter
        INC     PulseWidthCounter                ;update counter for this func's
                                                 ;  calls to determine PWM
        CMP     PulseWidthCounter, NUM_SPEEDS    ;see if should reset counter
        JNE     SetMotorBitsLoop                 ;if not, move on
        ;JE     Wrap                             ;if so, do so

Wrap:
        MOV     PulseWidthCounter, 0             ;reset
        ;JMP    SetMotorBitsLoop    

SetMotorBitsLoop:
        DEC     BX                               ;update loop counter for 
                                                 ;  setting motor bits in Port B
        JS      SetLaserBit                      ;set laser bit if done w/ loop
        ;JNS    SetMotorBits                     ;else, set next motor bit

SetMotorBits:
        MOV     DL, MotorDir[BX]                 ;get this motor's direction in
                                                 ;  temp register
        MOV     CL, PulseWidths[BX]              ;check if the motor should be
        CMP     PulseWidthCounter, CL            ;  off or on
        JNL     SetBits                          ;if off, temp register already
                                                 ;  has correct bit
        ;JL     MotorOn                          ;if on, set second bit of temp
                                                 ;  register with the direction
        
MotorOn:
        OR      DL, 10B                          ;get correct motor bits to OR
                                                 ;  into Port B output
        ;JMP    SetBits
        
SetBits:
        MOV     CX, BX                           ;need a modified loop counter
        SAL     CX, 1                            ;move temp register for motor                                               
        SAL     DL, CL                           ;  bits to corresponding Port B
                                                 ;  output position
        OR      AL, DL                           ;set temp bits in Port B output
        JMP     SetMotorBitsLoop                 ;move onto next loop iteration
        
SetLaserBit:
        CMP     LaserStatus, 0                   ;check if laser is on or off
        JE      PulseWidthModDone                ;if off, no need to do more
        ;JNE    SetLaserBitOn                    ;if on, must set the bit
        
SetLaserBitOn:
        OR      AL, LASER_BIT_ON                 ;set laser bit in Port B output
        ;JMP    PulseWidthModDone
        
PulseWidthModDone:
        MOV     DX, PORTB_ADDR                   ;output motor and laser vals
                                                 ;  to Port B
        OUT     DX, AL
        RET  
		
PulseWidthMod       ENDP        


; SetLaser
;
; Description:       Turns the laser on or off. When the argument AX is 0, the
;                    laser is turned off. When it is non-zero, the laser is 
;                    turned on.
;
; Operation:         Sets the LaserStatus shared variable to AX.
;
; Arguments:         AX - If zero, the laser is turned off. If non-zero, the
;                         laser is turned on.   
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  LaserStatus - written to
; Global Variables:  None.
;
; Input:             None.
; Output:            The laser indirectly is turned on or off through 
;                    PulseWidthMod.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: None.
; Known Bugs:        None.
; Limitations:       None.
; Special Notes:     None.
;
; Revision History:     
;    11/22/14  Victor Han      wrote the assembly code
;    11/17/14  Victor Han      initial revision

SetLaser            PROC    NEAR
                    PUBLIC  SetLaser
                    
        MOV     LaserStatus, AX
		RET
        
SetLaser             ENDP        


; GetLaser
;
; Description:       This procedure returns the status of the laser in AX. If
;                    AX is returned as zero, the laser is off. If it is
;                    non-zero, the laser is on.
;
; Operation:         Returns LaserStatus in AX.

; Arguments:         None.
; Return Value:      AX - If zero, the laser is off. If non-zero, the laser is
;                         on.
;
; Local Variables:   None.
; Shared Variables:  LaserStatus - read
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
; Registers Changed: AX
; Known Bugs:        None.
; Limitations:       None.
; Special Notes:     None.
;
; Revision History:     
;    11/20/14  Victor Han      wrote the assembly code
;    11/17/14  Victor Han      initial revision
;

GetLaser            PROC    NEAR
                    PUBLIC  GetLaser
                    
        MOV     AX, LaserStatus        ;put in return register
        RET
		
GetLaser            ENDP        

; MotorX_Table 
;
; Description:      This is the table for each motor's x orientation
;                   component. Ordered sequentially by motor. The magnitude of
;                   each motor's full direction vector as described by this 
;                   table and the MotorY_Table is 1.
;
; Notes:            READ ONLY tables should always be in the code segment so
;                   that in a standalone system it will be located in the
;                   ROM with the code.
;
; Revision History:
;    11/22/14  Victor Han      initial revision

MotorX_Table    LABEL   WORD
                PUBLIC  MotorX_Table


;       DW         Motor x Orientation Component
			
        DW         07FFFH        ; Motor 1 x-component
        DW         0C000H        ; Motor 2 x-component
        DW         0C000H        ; Motor 3 x-component
        
        
; MotorY_Table 
;
; Description:      This is the table for each motor's y orientation
;                   component. Ordered sequentially by motor. The magnitude of
;                   each motor's full direction vector as described by this 
;                   table and the MotorX_Table is 1.
;
; Notes:            READ ONLY tables should always be in the code segment so
;                   that in a standalone system it will be located in the
;                   ROM with the code.
;
; Revision History:
;    11/22/14  Victor Han      initial revision

MotorY_Table    LABEL   WORD
                PUBLIC  MotorY_Table


;       DW         Motor y Orientation Component
			
        DW         00000H        ; Motor 1 y-component
        DW         09127H        ; Motor 2 y-component
        DW         06ED9H        ; Motor 3 y-component

        
CODE    ENDS

;the data segment

DATA    SEGMENT PUBLIC  'DATA'

PulseWidths         DB       NUM_MOTORS  dup  (?) ;The width of the active high
                                                  ;  pulse that each motor 
                                                  ;  should receive in its PWM.
                                                  ;  The max width is NUM_SPEEDS,
                                                  ;  which corresponds to the
                                                  ;  max speed.
MotorDir            DB       NUM_MOTORS  dup  (?) ;The direction each motor 
                                                  ;  should rotate. 0 means 
                                                  ;  forward, 1 means reverse

PulseWidthCounter   DB       ?  ;A counter for how many times PulseWidthMod has
                                ;  been called. Reset whenever it reaches 
                                ;  NUM_SPEEDS and is used to determine when to
                                ;  turn on or off the motors for PWM.
LaserStatus         DW       ?  ;The status of the laser. Zero means the laser
                                ;  is off, non-zero means on.
RoboTrikeSpeed      DW       ?  ;The speed of the RoboTrike. Unsigned and ranges
                                ;  from 0 to MAX_SPEED.
RoboTrikeDir        DW       ?  ;The direction of RoboTrike motion. Unsigned and
                                ;  ranges from 0 to 359, with 0 being right in
                                ;  from of the RoboTrike and angles measured
                                ;  clockwise relative to RoboTrike.

DATA    ENDS

        END