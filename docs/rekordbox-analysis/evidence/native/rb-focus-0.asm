/Applications/rekordbox 7/rekordbox.app/Contents/MacOS/rekordbox:
(__TEXT,__text) section
__ZN8analyzer12BALibWrapper17CalcBeatPos_FocusEP11BA_BeatInfoiiS2_ii:
101f54788:	f4 4f be a9	stp	x20, x19, [sp, #-0x20]!
101f5478c:	fd 7b 01 a9	stp	x29, x30, [sp, #0x10]
101f54790:	fd 43 00 91	add	x29, sp, #0x10
101f54794:	13 04 40 f9	ldr	x19, [x0, #0x8]
101f54798:	13 01 00 b4	cbz	x19, 0x101f547b8
101f5479c:	08 14 40 b9	ldr	w8, [x0, #0x14]
101f547a0:	1f 09 00 71	cmp	w8, #0x2
101f547a4:	a1 00 00 54	b.ne	0x101f547b8
101f547a8:	07 40 00 91	add	x7, x0, #0x10
101f547ac:	e0 03 13 aa	mov	x0, x19
101f547b0:	01 00 80 d2	mov	x1, #0x0
101f547b4:	9a 4b c9 97	bl	__ZN16BeatAnalyzer_2_020BA_CalcBeatPos_FocusEPvP11BA_BeatInfoiiS2_iiRb
101f547b8:	7f 02 00 f1	cmp	x19, #0x0
101f547bc:	e0 07 9f 1a	cset	w0, ne
101f547c0:	fd 7b 41 a9	ldp	x29, x30, [sp, #0x10]
101f547c4:	f4 4f c2 a8	ldp	x20, x19, [sp], #0x20
101f547c8:	c0 03 5f d6	ret
