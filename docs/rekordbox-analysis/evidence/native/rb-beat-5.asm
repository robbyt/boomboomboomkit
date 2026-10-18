/Applications/rekordbox 7/rekordbox.app/Contents/MacOS/rekordbox:
(__TEXT,__text) section
__ZN8analyzer22AnalyzeJobBeatDetector6DetectEv:
102327c80:	ff 03 01 d1	sub	sp, sp, #0x40
102327c84:	f4 4f 02 a9	stp	x20, x19, [sp, #0x20]
102327c88:	fd 7b 03 a9	stp	x29, x30, [sp, #0x30]
102327c8c:	fd c3 00 91	add	x29, sp, #0x30
102327c90:	f3 03 00 aa	mov	x19, x0
102327c94:	21 66 01 d0	adrp	x1, 11462 ; 0x104fed000
102327c98:	21 60 31 91	add	x1, x1, #0xc58 ; literal pool for: "virtual analyzer::AnalyzeJobStatus analyzer::AnalyzeJobBeatDetector::Detect()"
102327c9c:	e0 63 00 91	add	x0, sp, #0x18
102327ca0:	e7 1a 06 94	bl	__ZN4juce6StringC1EPKc
102327ca4:	68 02 40 f9	ldr	x8, [x19]
102327ca8:	08 21 40 f9	ldr	x8, [x8, #0x40]
102327cac:	e2 63 00 91	add	x2, sp, #0x18
102327cb0:	e0 03 13 aa	mov	x0, x19
102327cb4:	01 00 80 52	mov	w1, #0x0
102327cb8:	63 05 80 52	mov	w3, #0x2b
102327cbc:	00 01 3f d6	blr	x8
102327cc0:	e0 63 00 91	add	x0, sp, #0x18
102327cc4:	8e 0a 06 94	bl	__ZN4juce6StringD1Ev
102327cc8:	68 02 40 f9	ldr	x8, [x19]
102327ccc:	08 25 40 f9	ldr	x8, [x8, #0x48]
102327cd0:	e0 03 13 aa	mov	x0, x19
102327cd4:	00 01 3f d6	blr	x8
102327cd8:	a0 02 00 36	tbz	w0, #0x0, 0x102327d2c
102327cdc:	68 4e 40 f9	ldr	x8, [x19, #0x98]
102327ce0:	c8 04 00 b4	cbz	x8, 0x102327d78
102327ce4:	68 0e 40 f9	ldr	x8, [x19, #0x18]
102327ce8:	08 71 40 b9	ldr	w8, [x8, #0x70]
102327cec:	08 09 00 51	sub	w8, w8, #0x2
102327cf0:	e0 03 13 aa	mov	x0, x19
102327cf4:	1f 09 00 71	cmp	w8, #0x2
102327cf8:	68 06 00 54	b.hi	0x102327dc4
102327cfc:	55 00 00 94	bl	__ZN8analyzer22AnalyzeJobBeatDetector24highPrecisionBeatAnalyzeEv
102327d00:	60 06 00 34	cbz	w0, 0x102327dcc
102327d04:	68 02 40 f9	ldr	x8, [x19]
102327d08:	08 15 40 f9	ldr	x8, [x8, #0x28]
102327d0c:	e0 03 13 aa	mov	x0, x19
102327d10:	00 01 3f d6	blr	x8
102327d14:	f3 03 00 aa	mov	x19, x0
102327d18:	e0 03 13 aa	mov	x0, x19
102327d1c:	fd 7b 43 a9	ldp	x29, x30, [sp, #0x30]
102327d20:	f4 4f 42 a9	ldp	x20, x19, [sp, #0x20]
102327d24:	ff 03 01 91	add	sp, sp, #0x40
102327d28:	c0 03 5f d6	ret
102327d2c:	21 66 01 d0	adrp	x1, 11462 ; 0x104fed000
102327d30:	21 60 31 91	add	x1, x1, #0xc58 ; literal pool for: "virtual analyzer::AnalyzeJobStatus analyzer::AnalyzeJobBeatDetector::Detect()"
102327d34:	e0 43 00 91	add	x0, sp, #0x10
102327d38:	c1 1a 06 94	bl	__ZN4juce6StringC1EPKc
102327d3c:	68 02 40 f9	ldr	x8, [x19]
102327d40:	08 21 40 f9	ldr	x8, [x8, #0x40]
102327d44:	e2 43 00 91	add	x2, sp, #0x10
102327d48:	e0 03 13 aa	mov	x0, x19
102327d4c:	21 00 80 52	mov	w1, #0x1
102327d50:	c3 05 80 52	mov	w3, #0x2e
102327d54:	00 01 3f d6	blr	x8
102327d58:	f3 03 00 aa	mov	x19, x0
102327d5c:	e0 43 00 91	add	x0, sp, #0x10
102327d60:	67 0a 06 94	bl	__ZN4juce6StringD1Ev
102327d64:	e0 03 13 aa	mov	x0, x19
102327d68:	fd 7b 43 a9	ldp	x29, x30, [sp, #0x30]
102327d6c:	f4 4f 42 a9	ldp	x20, x19, [sp, #0x20]
102327d70:	ff 03 01 91	add	sp, sp, #0x40
102327d74:	c0 03 5f d6	ret
102327d78:	21 66 01 d0	adrp	x1, 11462 ; 0x104fed000
102327d7c:	21 60 31 91	add	x1, x1, #0xc58 ; literal pool for: "virtual analyzer::AnalyzeJobStatus analyzer::AnalyzeJobBeatDetector::Detect()"
102327d80:	e0 23 00 91	add	x0, sp, #0x8
102327d84:	ae 1a 06 94	bl	__ZN4juce6StringC1EPKc
102327d88:	68 02 40 f9	ldr	x8, [x19]
102327d8c:	08 21 40 f9	ldr	x8, [x8, #0x40]
102327d90:	e2 23 00 91	add	x2, sp, #0x8
102327d94:	e0 03 13 aa	mov	x0, x19
102327d98:	21 00 80 52	mov	w1, #0x1
102327d9c:	43 06 80 52	mov	w3, #0x32
102327da0:	00 01 3f d6	blr	x8
102327da4:	f3 03 00 aa	mov	x19, x0
102327da8:	e0 23 00 91	add	x0, sp, #0x8
102327dac:	54 0a 06 94	bl	__ZN4juce6StringD1Ev
102327db0:	e0 03 13 aa	mov	x0, x19
102327db4:	fd 7b 43 a9	ldp	x29, x30, [sp, #0x30]
102327db8:	f4 4f 42 a9	ldp	x20, x19, [sp, #0x20]
102327dbc:	ff 03 01 91	add	sp, sp, #0x40
102327dc0:	c0 03 5f d6	ret
102327dc4:	30 02 00 94	bl	__ZN8analyzer22AnalyzeJobBeatDetector17legacyBeatAnalyzeEv
102327dc8:	e0 f9 ff 35	cbnz	w0, 0x102327d04
102327dcc:	21 66 01 d0	adrp	x1, 11462 ; 0x104fed000
102327dd0:	21 60 31 91	add	x1, x1, #0xc58 ; literal pool for: "virtual analyzer::AnalyzeJobStatus analyzer::AnalyzeJobBeatDetector::Detect()"
102327dd4:	e0 03 00 91	mov	x0, sp
102327dd8:	99 1a 06 94	bl	__ZN4juce6StringC1EPKc
102327ddc:	68 02 40 f9	ldr	x8, [x19]
102327de0:	08 21 40 f9	ldr	x8, [x8, #0x40]
102327de4:	e2 03 00 91	mov	x2, sp
102327de8:	e0 03 13 aa	mov	x0, x19
102327dec:	01 00 80 52	mov	w1, #0x0
102327df0:	63 08 80 52	mov	w3, #0x43
102327df4:	00 01 3f d6	blr	x8
102327df8:	f3 03 00 aa	mov	x19, x0
102327dfc:	e0 03 00 91	mov	x0, sp
102327e00:	3f 0a 06 94	bl	__ZN4juce6StringD1Ev
102327e04:	e0 03 13 aa	mov	x0, x19
102327e08:	fd 7b 43 a9	ldp	x29, x30, [sp, #0x30]
102327e0c:	f4 4f 42 a9	ldp	x20, x19, [sp, #0x20]
102327e10:	ff 03 01 91	add	sp, sp, #0x40
102327e14:	c0 03 5f d6	ret
102327e18:	f3 03 00 aa	mov	x19, x0
102327e1c:	e0 03 00 91	mov	x0, sp
102327e20:	09 00 00 14	b	0x102327e44
102327e24:	f3 03 00 aa	mov	x19, x0
102327e28:	e0 23 00 91	add	x0, sp, #0x8
102327e2c:	06 00 00 14	b	0x102327e44
102327e30:	f3 03 00 aa	mov	x19, x0
102327e34:	e0 43 00 91	add	x0, sp, #0x10
102327e38:	03 00 00 14	b	0x102327e44
102327e3c:	f3 03 00 aa	mov	x19, x0
102327e40:	e0 63 00 91	add	x0, sp, #0x18
102327e44:	2e 0a 06 94	bl	__ZN4juce6StringD1Ev
102327e48:	e0 03 13 aa	mov	x0, x19
102327e4c:	a8 a4 46 94	bl	0x1034d10ec ; symbol stub for: __Unwind_Resume
