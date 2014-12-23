asm86chk trkmain.asm

asm86chk converts.asm
asm86chk eventQ.asm
asm86chk illEvent.asm
asm86chk initCS.asm
asm86chk int2.asm
asm86chk queue.asm
asm86chk serial.asm
asm86chk errortbl.asm

asm86chk mtrlsr.asm
asm86chk serpro.asm
asm86chk tmrmtr.asm
asm86chk trigtbl.asm

asm86 trkmain.asm m1 ep db

asm86 converts.asm m1 ep db
asm86 eventQ.asm m1 ep db
asm86 illEvent.asm m1 ep db
asm86 initCS.asm m1 ep db
asm86 int2.asm m1 ep db
asm86 queue.asm m1 ep db
asm86 serial.asm m1 ep db
asm86 errortbl.asm m1 ep db

asm86 mtrlsr.asm m1 ep db
asm86 serpro.asm m1 ep db
asm86 tmrmtr.asm m1 ep db
asm86 trigtbl.asm m1 ep db


link86 converts.obj, eventQ.obj, illEvent.obj, initCS.obj to int1.lnk
link86 int2.obj, queue.obj, serial.obj, errortbl.obj to int2.lnk
link86 trkmain.obj, mtrlsr.obj, serpro.obj, tmrmtr.obj, trigtbl.obj to int3.lnk

link86 int1.lnk, int2.lnk, int3.lnk to trkmain.lnk
loc86 trkmain.lnk to trkmain noic ad(sm(code(4000h), data(400h), stack(7000h)))