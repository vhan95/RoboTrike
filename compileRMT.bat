asm86chk rmtmain.asm

asm86chk converts.asm
asm86chk eventQ.asm
asm86chk illEvent.asm
asm86chk initCS.asm
asm86chk int2.asm
asm86chk queue.asm
asm86chk serial.asm
asm86chk errortbl.asm

asm86chk display.asm
asm86chk keypad.asm
asm86chk timer.asm
asm86chk user.asm
asm86chk segtab14.asm


asm86 rmtmain.asm m1 ep db

asm86 converts.asm m1 ep db
asm86 eventQ.asm m1 ep db
asm86 illEvent.asm m1 ep db
asm86 initCS.asm m1 ep db
asm86 int2.asm m1 ep db
asm86 queue.asm m1 ep db
asm86 serial.asm m1 ep db
asm86 errortbl.asm m1 ep db

asm86 display.asm m1 ep db
asm86 keypad.asm m1 ep db
asm86 timer.asm m1 ep db
asm86 user.asm m1 ep db
asm86 segtab14.asm m1 ep db


link86 converts.obj, eventQ.obj, illEvent.obj, initCS.obj to int1.lnk
link86 int2.obj, queue.obj, serial.obj, errortbl.obj to int2.lnk
link86 rmtmain.obj, display.obj, keypad.obj, timer.obj, user.obj, segtab14.obj to int3.lnk

link86 int1.lnk, int2.lnk, int3.lnk to rmtmain.lnk
loc86 rmtmain.lnk to rmtmain noic ad(sm(code(4000h), data(400h), stack(7000h)))