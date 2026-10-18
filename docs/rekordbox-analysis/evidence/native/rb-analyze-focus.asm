/Applications/rekordbox 7/rekordbox.app/Contents/MacOS/rekordbox:
(__TEXT,__text) section
__ZN16BeatAnalyzer_2_08Analyzer12analyzeFocusEP11BA_BeatInfoiiS2_iiRb:
10116c050:	ef 3b b6 6d	stp	d15, d14, [sp, #-0xa0]!
10116c054:	ed 33 01 6d	stp	d13, d12, [sp, #0x10]
10116c058:	eb 2b 02 6d	stp	d11, d10, [sp, #0x20]
10116c05c:	e9 23 03 6d	stp	d9, d8, [sp, #0x30]
10116c060:	fc 6f 04 a9	stp	x28, x27, [sp, #0x40]
10116c064:	fa 67 05 a9	stp	x26, x25, [sp, #0x50]
10116c068:	f8 5f 06 a9	stp	x24, x23, [sp, #0x60]
10116c06c:	f6 57 07 a9	stp	x22, x21, [sp, #0x70]
10116c070:	f4 4f 08 a9	stp	x20, x19, [sp, #0x80]
10116c074:	fd 7b 09 a9	stp	x29, x30, [sp, #0x90]
10116c078:	fd 43 02 91	add	x29, sp, #0x90
10116c07c:	09 12 83 52	mov	w9, #0x1890
10116c080:	10 ff 01 d0	adrp	x16, 16354 ; 0x10514e000
10116c084:	10 fa 41 f9	ldr	x16, [x16, #0x3f0] ; literal pool symbol address: ___chkstk_darwin
10116c088:	00 02 3f d6	blr	x16
10116c08c:	ff 07 40 d1	sub	sp, sp, #0x1, lsl #12
10116c090:	ff 43 22 d1	sub	sp, sp, #0x890
10116c094:	08 ff 01 d0	adrp	x8, 16354 ; 0x10514e000
10116c098:	08 7d 42 f9	ldr	x8, [x8, #0x4f8] ; literal pool symbol address: ___stack_chk_guard
10116c09c:	08 01 40 f9	ldr	x8, [x8]
10116c0a0:	a8 83 15 f8	stur	x8, [x29, #-0xa8]
10116c0a4:	ff 00 00 39	strb	wzr, [x7]
10116c0a8:	08 20 40 39	ldrb	w8, [x0, #0x8]
10116c0ac:	a8 01 00 34	cbz	w8, 0x10116c0e0
10116c0b0:	fc 03 00 aa	mov	x28, x0
10116c0b4:	08 24 40 39	ldrb	w8, [x0, #0x9]
10116c0b8:	48 01 00 35	cbnz	w8, 0x10116c0e0
10116c0bc:	f9 03 06 aa	mov	x25, x6
10116c0c0:	f3 03 05 aa	mov	x19, x5
10116c0c4:	88 47 40 39	ldrb	w8, [x28, #0x11]
10116c0c8:	1f 01 00 71	cmp	w8, #0x0
10116c0cc:	44 08 40 7a	ccmp	w2, #0x0, #0x4, eq
10116c0d0:	64 18 40 7a	ccmp	w3, #0x0, #0x4, ne
10116c0d4:	a4 18 40 7a	ccmp	w5, #0x0, #0x4, ne
10116c0d8:	c4 18 40 7a	ccmp	w6, #0x0, #0x4, ne
10116c0dc:	81 02 00 54	b.ne	0x10116c12c
10116c0e0:	a8 83 55 f8	ldur	x8, [x29, #-0xa8]
10116c0e4:	09 ff 01 d0	adrp	x9, 16354 ; 0x10514e000
10116c0e8:	29 7d 42 f9	ldr	x9, [x9, #0x4f8] ; literal pool symbol address: ___stack_chk_guard
10116c0ec:	29 01 40 f9	ldr	x9, [x9]
10116c0f0:	3f 01 08 eb	cmp	x9, x8
10116c0f4:	61 63 0a 54	b.ne	0x101180d60
10116c0f8:	ff 07 40 91	add	sp, sp, #0x1, lsl #12
10116c0fc:	ff 43 22 91	add	sp, sp, #0x890
10116c100:	fd 7b 49 a9	ldp	x29, x30, [sp, #0x90]
10116c104:	f4 4f 48 a9	ldp	x20, x19, [sp, #0x80]
10116c108:	f6 57 47 a9	ldp	x22, x21, [sp, #0x70]
10116c10c:	f8 5f 46 a9	ldp	x24, x23, [sp, #0x60]
10116c110:	fa 67 45 a9	ldp	x26, x25, [sp, #0x50]
10116c114:	fc 6f 44 a9	ldp	x28, x27, [sp, #0x40]
10116c118:	e9 23 43 6d	ldp	d9, d8, [sp, #0x30]
10116c11c:	eb 2b 42 6d	ldp	d11, d10, [sp, #0x20]
10116c120:	ed 33 41 6d	ldp	d13, d12, [sp, #0x10]
10116c124:	ef 3b ca 6c	ldp	d15, d14, [sp], #0xa0
10116c128:	c0 03 5f d6	ret
10116c12c:	fb 03 1c aa	mov	x27, x28
10116c130:	68 4f 41 b8	ldr	w8, [x27, #0x14]!
10116c134:	68 fd ff 34	cbz	w8, 0x10116c0e0
10116c138:	28 00 80 52	mov	w8, #0x1
10116c13c:	88 47 00 39	strb	w8, [x28, #0x11]
10116c140:	88 2f 40 39	ldrb	w8, [x28, #0xb]
10116c144:	e8 fc ff 34	cbz	w8, 0x10116c0e0
10116c148:	f7 03 07 aa	mov	x23, x7
10116c14c:	f8 03 04 aa	mov	x24, x4
10116c150:	7f 06 00 71	cmp	w19, #0x1
10116c154:	eb 02 00 54	b.lt	0x10116c1b0
10116c158:	88 00 80 52	mov	w8, #0x4
10116c15c:	7f 12 00 71	cmp	w19, #0x4
10116c160:	68 b2 88 1a	csel	w8, w19, w8, lt
10116c164:	09 07 40 b9	ldr	w9, [x24, #0x4]
10116c168:	3f 01 00 71	cmp	w9, #0x0
10116c16c:	34 c1 9f 1a	csel	w20, w9, wzr, gt
10116c170:	1f 05 00 71	cmp	w8, #0x1
10116c174:	00 02 00 54	b.eq	0x10116c1b4
10116c178:	09 13 40 b9	ldr	w9, [x24, #0x10]
10116c17c:	9f 02 09 6b	cmp	w20, w9
10116c180:	94 c2 89 1a	csel	w20, w20, w9, gt
10116c184:	1f 09 00 71	cmp	w8, #0x2
10116c188:	60 01 00 54	b.eq	0x10116c1b4
10116c18c:	09 1f 40 b9	ldr	w9, [x24, #0x1c]
10116c190:	9f 02 09 6b	cmp	w20, w9
10116c194:	94 c2 89 1a	csel	w20, w20, w9, gt
10116c198:	1f 0d 00 71	cmp	w8, #0x3
10116c19c:	c0 00 00 54	b.eq	0x10116c1b4
10116c1a0:	08 2b 40 b9	ldr	w8, [x24, #0x28]
10116c1a4:	9f 02 08 6b	cmp	w20, w8
10116c1a8:	94 c2 88 1a	csel	w20, w20, w8, gt
10116c1ac:	02 00 00 14	b	0x10116c1b4
10116c1b0:	14 00 80 52	mov	w20, #0x0
10116c1b4:	60 00 22 1e	scvtf	s0, w3
10116c1b8:	48 e1 9a 52	mov	w8, #0xd70a
10116c1bc:	68 84 a7 72	movk	w8, #0x3c23, lsl #16
10116c1c0:	01 01 27 1e	fmov	s1, w8
10116c1c4:	00 08 21 1e	fmul	s0, s0, s1
10116c1c8:	e8 03 1c aa	mov	x8, x28
10116c1cc:	00 8d 04 bc	str	s0, [x8, #0x48]!
10116c1d0:	e8 77 00 f9	str	x8, [sp, #0xe8]
10116c1d4:	e8 07 40 91	add	x8, sp, #0x1, lsl #12
10116c1d8:	08 c1 11 91	add	x8, x8, #0x470
10116c1dc:	04 04 bc 97	bl	__ZN6common12PropertyPathEv
10116c1e0:	41 f2 01 d0	adrp	x1, 15946 ; 0x104fb6000
10116c1e4:	21 24 1e 91	add	x1, x1, #0x789 ; literal pool for: "csv"
10116c1e8:	e0 03 11 91	add	x0, sp, #0x440
10116c1ec:	3c f8 4c 94	bl	__ZN4juce9StringRefC1EPKc
10116c1f0:	e1 23 42 f9	ldr	x1, [sp, #0x440]
10116c1f4:	e8 07 40 91	add	x8, sp, #0x1, lsl #12
10116c1f8:	08 c1 19 91	add	x8, x8, #0x670
10116c1fc:	e0 07 40 91	add	x0, sp, #0x1, lsl #12
10116c200:	00 c0 11 91	add	x0, x0, #0x470
10116c204:	9f 15 4d 94	bl	__ZNK4juce4File12getChildFileENS_9StringRefE
10116c208:	e0 07 40 91	add	x0, sp, #0x1, lsl #12
10116c20c:	00 c0 11 91	add	x0, x0, #0x470
10116c210:	3b f9 4c 94	bl	__ZN4juce6StringD1Ev
10116c214:	e0 07 40 91	add	x0, sp, #0x1, lsl #12
10116c218:	00 c0 19 91	add	x0, x0, #0x670
10116c21c:	e9 19 4d 94	bl	__ZNK4juce4File6existsEv
10116c220:	e0 00 00 37	tbnz	w0, #0x0, 0x10116c23c
10116c224:	e8 e3 10 91	add	x8, sp, #0x438
10116c228:	e0 07 40 91	add	x0, sp, #0x1, lsl #12
10116c22c:	00 c0 19 91	add	x0, x0, #0x670
10116c230:	8d 1b 4d 94	bl	__ZNK4juce4File15createDirectoryEv
10116c234:	e0 e3 10 91	add	x0, sp, #0x438
10116c238:	31 f9 4c 94	bl	__ZN4juce6StringD1Ev
10116c23c:	41 f2 01 d0	adrp	x1, 15946 ; 0x104fb6000
10116c240:	21 34 1e 91	add	x1, x1, #0x78d ; literal pool for: "interval.csv"
10116c244:	e0 c3 10 91	add	x0, sp, #0x430
10116c248:	25 f8 4c 94	bl	__ZN4juce9StringRefC1EPKc
10116c24c:	e1 1b 42 f9	ldr	x1, [sp, #0x430]
10116c250:	e8 07 40 91	add	x8, sp, #0x1, lsl #12
10116c254:	08 c1 11 91	add	x8, x8, #0x470
10116c258:	e0 07 40 91	add	x0, sp, #0x1, lsl #12
10116c25c:	00 c0 19 91	add	x0, x0, #0x670
10116c260:	88 15 4d 94	bl	__ZNK4juce4File12getChildFileENS_9StringRefE
10116c264:	f4 33 01 b9	str	w20, [sp, #0x130]
10116c268:	7f 06 00 71	cmp	w19, #0x1
10116c26c:	f3 73 12 a9	stp	x19, x28, [sp, #0x120]
10116c270:	fb 9f 00 f9	str	x27, [sp, #0x138]
10116c274:	0b 0e 00 54	b.lt	0x10116c434
10116c278:	f6 03 13 2a	mov	w22, w19
10116c27c:	88 c3 01 91	add	x8, x28, #0x70
10116c280:	e8 a3 00 f9	str	x8, [sp, #0x140]
10116c284:	1a 23 00 91	add	x26, x24, #0x8
10116c288:	08 e4 00 2f	movi	d8, #0000000000000000
10116c28c:	0e 00 00 14	b	0x10116c2c4
10116c290:	e9 63 41 b9	ldr	w9, [sp, #0x160]
10116c294:	09 7d 00 29	stp	w9, wzr, [x8]
10116c298:	08 09 00 bd	str	s8, [x8, #0x8]
10116c29c:	ea 5b 41 b9	ldr	w10, [sp, #0x158]
10116c2a0:	09 00 80 12	mov	w9, #-0x1
10116c2a4:	0a a5 01 29	stp	w10, w9, [x8, #0xc]
10116c2a8:	1f 51 00 39	strb	wzr, [x8, #0x14]
10116c2ac:	08 61 00 91	add	x8, x8, #0x18
10116c2b0:	88 3f 00 f9	str	x8, [x28, #0x78]
10116c2b4:	5a 33 00 91	add	x26, x26, #0xc
10116c2b8:	d6 06 00 f1	subs	x22, x22, #0x1
10116c2bc:	fc 97 40 f9	ldr	x28, [sp, #0x128]
10116c2c0:	00 0c 00 54	b.eq	0x10116c440
10116c2c4:	48 83 5f b8	ldur	w8, [x26, #-0x8]
10116c2c8:	e8 63 01 b9	str	w8, [sp, #0x160]
10116c2cc:	48 cf 7f 29	ldp	w8, w19, [x26, #-0x4]
10116c2d0:	e8 5b 01 b9	str	w8, [sp, #0x158]
10116c2d4:	b3 04 00 34	cbz	w19, 0x10116c368
10116c2d8:	e0 07 40 91	add	x0, sp, #0x1, lsl #12
10116c2dc:	00 c0 01 91	add	x0, x0, #0x70
10116c2e0:	41 f2 01 d0	adrp	x1, 15946 ; 0x104fb6000
10116c2e4:	21 68 1e 91	add	x1, x1, #0x79a ; literal pool for: "%.3f, %u\015\n"
10116c2e8:	55 09 4d 94	bl	__ZN4juce6StringC1EPKc
10116c2ec:	54 03 40 b9	ldr	w20, [x26]
10116c2f0:	e0 07 40 91	add	x0, sp, #0x1, lsl #12
10116c2f4:	00 c0 01 91	add	x0, x0, #0x70
10116c2f8:	14 3d 4d 94	bl	__ZNK4juce6String9toRawUTF8Ev
10116c2fc:	60 02 62 1e	scvtf	d0, w19
10116c300:	08 6c dc d2	mov	x8, #0xe36000000000
10116c304:	c8 2a e8 f2	movk	x8, #0x4156, lsl #48
10116c308:	01 01 67 9e	fmov	d1, x8
10116c30c:	20 18 60 1e	fdiv	d0, d1, d0
10116c310:	08 40 62 1e	fcvt	s8, d0
10116c314:	00 c1 22 1e	fcvt	d0, s8
10116c318:	f4 07 00 f9	str	x20, [sp, #0x8]
10116c31c:	e0 03 00 fd	str	d0, [sp]
10116c320:	e8 07 40 91	add	x8, sp, #0x1, lsl #12
10116c324:	08 c1 09 91	add	x8, x8, #0x270
10116c328:	90 aa 4d 94	bl	__ZN4juce6String12formattedRawEPKcz
10116c32c:	e0 07 40 91	add	x0, sp, #0x1, lsl #12
10116c330:	00 c0 11 91	add	x0, x0, #0x470
10116c334:	e1 07 40 91	add	x1, sp, #0x1, lsl #12
10116c338:	21 c0 09 91	add	x1, x1, #0x270
10116c33c:	02 00 80 52	mov	w2, #0x0
10116c340:	03 00 80 52	mov	w3, #0x0
10116c344:	04 f0 01 b0	adrp	x4, 15873 ; 0x104f6d000
10116c348:	84 d8 1a 91	add	x4, x4, #0x6b6 ; literal pool for: "\015\n"
10116c34c:	b4 35 4d 94	bl	__ZNK4juce4File10appendTextERKNS_6StringEbbPKc
10116c350:	e0 07 40 91	add	x0, sp, #0x1, lsl #12
10116c354:	00 c0 09 91	add	x0, x0, #0x270
10116c358:	e9 f8 4c 94	bl	__ZN4juce6StringD1Ev
10116c35c:	e0 07 40 91	add	x0, sp, #0x1, lsl #12
10116c360:	00 c0 01 91	add	x0, x0, #0x70
10116c364:	e6 f8 4c 94	bl	__ZN4juce6StringD1Ev
10116c368:	88 a7 47 a9	ldp	x8, x9, [x28, #0x78]
10116c36c:	1f 01 09 eb	cmp	x8, x9
10116c370:	01 f9 ff 54	b.ne	0x10116c290
10116c374:	e9 a3 40 f9	ldr	x9, [sp, #0x140]
10116c378:	3c 01 40 f9	ldr	x28, [x9]
10116c37c:	14 01 1c cb	sub	x20, x8, x28
10116c380:	88 fe 43 93	asr	x8, x20, #3
10116c384:	e9 f3 01 b2	mov	x9, #-0x5555555555555556
10116c388:	69 55 95 f2	movk	x9, #0xaaab
10116c38c:	13 7d 09 9b	mul	x19, x8, x9
10116c390:	68 06 00 91	add	x8, x19, #0x1
10116c394:	ea f3 01 b2	mov	x10, #-0x5555555555555556
10116c398:	4a 55 e1 f2	movk	x10, #0xaaa, lsl #48
10116c39c:	1f 01 0a eb	cmp	x8, x10
10116c3a0:	88 5d 0a 54	b.hi	0x101180f50
10116c3a4:	69 fa 7f d3	lsl	x9, x19, #1
10116c3a8:	3f 01 08 eb	cmp	x9, x8
10116c3ac:	28 81 88 9a	csel	x8, x9, x8, hi
10116c3b0:	e9 f3 00 b2	mov	x9, #0x5555555555555555
10116c3b4:	a9 aa e0 f2	movk	x9, #0x555, lsl #48
10116c3b8:	7f 02 09 eb	cmp	x19, x9
10116c3bc:	15 31 8a 9a	csel	x21, x8, x10, lo
10116c3c0:	bf 02 0a eb	cmp	x21, x10
10116c3c4:	c8 5c 0a 54	b.hi	0x101180f5c
10116c3c8:	a8 06 15 8b	add	x8, x21, x21, lsl #1
10116c3cc:	00 f1 7d d3	lsl	x0, x8, #3
10116c3d0:	c0 95 8d 94	bl	0x1034d1ad0 ; symbol stub for: __Znwm
10116c3d4:	0a 03 80 52	mov	w10, #0x18
10116c3d8:	68 02 0a 9b	madd	x8, x19, x10, x0
10116c3dc:	e9 63 41 b9	ldr	w9, [sp, #0x160]
10116c3e0:	09 7d 00 29	stp	w9, wzr, [x8]
10116c3e4:	08 09 00 bd	str	s8, [x8, #0x8]
10116c3e8:	b5 02 0a 9b	madd	x21, x21, x10, x0
10116c3ec:	ea 5b 41 b9	ldr	w10, [sp, #0x158]
10116c3f0:	09 00 80 12	mov	w9, #-0x1
10116c3f4:	0a a5 01 29	stp	w10, w9, [x8, #0xc]
10116c3f8:	1f 51 00 39	strb	wzr, [x8, #0x14]
10116c3fc:	1b 61 00 91	add	x27, x8, #0x18
10116c400:	13 01 14 cb	sub	x19, x8, x20
10116c404:	e0 03 13 aa	mov	x0, x19
10116c408:	e1 03 1c aa	mov	x1, x28
10116c40c:	e2 03 14 aa	mov	x2, x20
10116c410:	8f 98 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
10116c414:	e8 97 40 f9	ldr	x8, [sp, #0x128]
10116c418:	13 6d 07 a9	stp	x19, x27, [x8, #0x70]
10116c41c:	15 41 00 f9	str	x21, [x8, #0x80]
10116c420:	fb 9f 40 f9	ldr	x27, [sp, #0x138]
10116c424:	9c f4 ff b4	cbz	x28, 0x10116c2b4
10116c428:	e0 03 1c aa	mov	x0, x28
10116c42c:	a3 95 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10116c430:	a1 ff ff 17	b	0x10116c2b4
10116c434:	ff 5b 01 b9	str	wzr, [sp, #0x158]
10116c438:	ff 63 01 b9	str	wzr, [sp, #0x160]
10116c43c:	08 e4 00 2f	movi	d8, #0000000000000000
10116c440:	e0 07 40 91	add	x0, sp, #0x1, lsl #12
10116c444:	00 c0 11 91	add	x0, x0, #0x470
10116c448:	ad f8 4c 94	bl	__ZN4juce6StringD1Ev
10116c44c:	f3 07 40 91	add	x19, sp, #0x1, lsl #12
10116c450:	73 c2 19 91	add	x19, x19, #0x670
10116c454:	e0 07 40 91	add	x0, sp, #0x1, lsl #12
10116c458:	00 c0 19 91	add	x0, x0, #0x670
10116c45c:	a8 f8 4c 94	bl	__ZN4juce6StringD1Ev
10116c460:	88 b7 40 39	ldrb	w8, [x28, #0x2d]
10116c464:	00 f6 03 6f	fmov.2d	v0, #1.00000000
10116c468:	e0 17 80 3d	str	q0, [sp, #0x50]
10116c46c:	a8 02 00 35	cbnz	w8, 0x10116c4c0
10116c470:	e8 33 41 b9	ldr	w8, [sp, #0x130]
10116c474:	1f 11 00 71	cmp	w8, #0x4
10116c478:	41 02 00 54	b.ne	0x10116c4c0
10116c47c:	f6 93 40 f9	ldr	x22, [sp, #0x120]
10116c480:	d5 7e 40 93	sxtw	x21, w22
10116c484:	e0 43 29 91	add	x0, sp, #0xa50
10116c488:	e1 03 15 aa	mov	x1, x21
10116c48c:	59 56 00 94	bl	__ZNSt3__16vectorIdNS_9allocatorIdEEEC1Em
10116c490:	c8 06 00 71	subs	w8, w22, #0x1
10116c494:	e8 9b 00 f9	str	x8, [sp, #0x130]
10116c498:	4b b0 06 54	b.lt	0x101179aa0
10116c49c:	60 03 40 bd	ldr	s0, [x27]
10116c4a0:	00 a4 20 0f	sshll.2d	v0, v0, #0x0
10116c4a4:	00 d8 61 5e	scvtf	d0, d0
10116c4a8:	e9 2b 45 f9	ldr	x9, [sp, #0xa50]
10116c4ac:	e8 03 16 2a	mov	w8, w22
10116c4b0:	df 22 00 71	cmp	w22, #0x8
10116c4b4:	c8 a5 06 54	b.hi	0x10117996c
10116c4b8:	0a 00 80 d2	mov	x10, #0x0
10116c4bc:	62 35 00 14	b	0x101179a44
10116c4c0:	ff b7 00 b9	str	wzr, [sp, #0xb4]
10116c4c4:	88 c3 01 91	add	x8, x28, #0x70
10116c4c8:	e8 b3 00 f9	str	x8, [sp, #0x160]
10116c4cc:	89 e3 01 91	add	x9, x28, #0x78
10116c4d0:	20 03 62 1e	scvtf	d0, w25
10116c4d4:	c8 09 e8 d2	mov	x8, #0x404e000000000000
10116c4d8:	01 01 67 9e	fmov	d1, x8
10116c4dc:	17 00 c8 d2	mov	x23, #0x400000000000
10116c4e0:	f7 11 e8 f2	movk	x23, #0x408f, lsl #48
10116c4e4:	e2 02 67 9e	fmov	d2, x23
10116c4e8:	88 3f 95 d2	mov	x8, #0xa9fc
10116c4ec:	28 5e ba f2	movk	x8, #0xd2f1, lsl #16
10116c4f0:	a8 49 cc f2	movk	x8, #0x624d, lsl #32
10116c4f4:	08 f0 e7 f2	movk	x8, #0x3f80, lsl #48
10116c4f8:	03 01 67 9e	fmov	d3, x8
10116c4fc:	e8 e7 01 b2	mov	x8, #-0x6666666666666667
10116c500:	48 33 93 f2	movk	x8, #0x999a
10116c504:	28 f1 e7 f2	movk	x8, #0x3f89, lsl #48
10116c508:	04 01 67 9e	fmov	d4, x8
10116c50c:	48 e1 9a 52	mov	w8, #0xd70a
10116c510:	68 84 a7 72	movk	w8, #0x3c23, lsl #16
10116c514:	05 01 27 1e	fmov	s5, w8
10116c518:	08 40 cd d2	mov	x8, #0x6a0000000000
10116c51c:	08 1f e8 f2	movk	x8, #0x40f8, lsl #48
10116c520:	06 01 67 9e	fmov	d6, x8
10116c524:	68 12 00 91	add	x8, x19, #0x4
10116c528:	e8 0f 00 f9	str	x8, [sp, #0x18]
10116c52c:	21 18 60 1e	fdiv	d1, d1, d0
10116c530:	22 08 62 1e	fmul	d2, d1, d2
10116c534:	e2 37 00 fd	str	d2, [sp, #0x68]
10116c538:	02 08 63 1e	fmul	d2, d0, d3
10116c53c:	00 08 64 1e	fmul	d0, d0, d4
10116c540:	e0 0b 09 6d	stp	d0, d2, [sp, #0x90]
10116c544:	ea f3 01 b2	mov	x10, #-0x5555555555555556
10116c548:	6a 55 95 f2	movk	x10, #0xaaab
10116c54c:	88 3f 95 d2	mov	x8, #0xa9fc
10116c550:	28 5e ba f2	movk	x8, #0xd2f1, lsl #16
10116c554:	a8 49 cc f2	movk	x8, #0x624d, lsl #32
10116c558:	08 ea e7 f2	movk	x8, #0x3f50, lsl #48
10116c55c:	20 03 22 1e	scvtf	s0, w25
10116c560:	f9 03 09 aa	mov	x25, x9
10116c564:	00 08 25 1e	fmul	s0, s0, s5
10116c568:	e0 8f 00 bd	str	s0, [sp, #0x8c]
10116c56c:	20 08 66 1e	fmul	d0, d1, d6
10116c570:	e0 43 00 fd	str	d0, [sp, #0x80]
10116c574:	0d 10 6e 1e	fmov	d13, #1.00000000
10116c578:	01 0d 08 4e	dup.2d	v1, x8
10116c57c:	0e 10 6c 1e	fmov	d14, #0.50000000
10116c580:	e0 0e 08 4e	dup.2d	v0, x23
10116c584:	e0 87 01 ad	stp	q0, q1, [sp, #0x30]
10116c588:	00 f4 03 6f	fmov.2d	v0, #0.50000000
10116c58c:	e0 0b 80 3d	str	q0, [sp, #0x20]
10116c590:	0f d0 64 1e	fmov	d15, #11.00000000
10116c594:	08 00 80 12	mov	w8, #-0x1
10116c598:	e8 f3 00 b9	str	w8, [sp, #0xf0]
10116c59c:	28 00 80 52	mov	w8, #0x1
10116c5a0:	e9 9b 00 f9	str	x9, [sp, #0x130]
10116c5a4:	07 00 00 14	b	0x10116c5c0
10116c5a8:	08 00 80 52	mov	w8, #0x0
10116c5ac:	ea f3 01 b2	mov	x10, #-0x5555555555555556
10116c5b0:	6a 55 95 f2	movk	x10, #0xaaab
10116c5b4:	e9 df 40 b9	ldr	w9, [sp, #0xdc]
10116c5b8:	49 00 00 37	tbnz	w9, #0x0, 0x10116c5c0
10116c5bc:	45 30 00 14	b	0x1011786d0
10116c5c0:	16 03 80 52	mov	w22, #0x18
10116c5c4:	e8 df 00 b9	str	w8, [sp, #0xdc]
10116c5c8:	28 03 40 f9	ldr	x8, [x25]
10116c5cc:	e9 b3 40 f9	ldr	x9, [sp, #0x160]
10116c5d0:	34 01 40 f9	ldr	x20, [x9]
10116c5d4:	08 01 14 cb	sub	x8, x8, x20
10116c5d8:	08 fd 43 93	asr	x8, x8, #3
10116c5dc:	08 7d 0a 9b	mul	x8, x8, x10
10116c5e0:	0e 7d 60 d3	lsl	x14, x8, #32
10116c5e4:	e8 af 00 f9	str	x8, [sp, #0x158]
10116c5e8:	13 7d 40 93	sxtw	x19, w8
10116c5ec:	ff 13 02 f9	str	xzr, [sp, #0x420]
10116c5f0:	ff 0f 02 f9	str	xzr, [sp, #0x418]
10116c5f4:	ff 17 02 f9	str	xzr, [sp, #0x428]
10116c5f8:	d8 fd 5d d3	lsr	x24, x14, #29
10116c5fc:	7a f2 7d d3	lsl	x26, x19, #3
10116c600:	ee a3 00 f9	str	x14, [sp, #0x140]
10116c604:	2e 02 00 b4	cbz	x14, 0x10116c648
10116c608:	4e 00 f8 b6	tbz	x14, #0x3f, 0x10116c610
10116c60c:	48 52 00 14	b	0x101180f2c
10116c610:	e0 03 18 aa	mov	x0, x24
10116c614:	2f 95 8d 94	bl	0x1034d1ad0 ; symbol stub for: __Znwm
10116c618:	f9 03 00 aa	mov	x25, x0
10116c61c:	15 00 1a 8b	add	x21, x0, x26
10116c620:	e0 0f 02 f9	str	x0, [sp, #0x418]
10116c624:	f5 17 02 f9	str	x21, [sp, #0x428]
10116c628:	e1 03 1a aa	mov	x1, x26
10116c62c:	e9 95 8d 94	bl	0x1034d1dd0 ; symbol stub for: _bzero
10116c630:	f5 13 02 f9	str	x21, [sp, #0x420]
10116c634:	ee a3 40 f9	ldr	x14, [sp, #0x140]
10116c638:	e8 af 40 f9	ldr	x8, [sp, #0x158]
10116c63c:	1f 05 00 71	cmp	w8, #0x1
10116c640:	ca 00 00 54	b.ge	0x10116c658
10116c644:	37 00 00 14	b	0x10116c720
10116c648:	19 00 80 d2	mov	x25, #0x0
10116c64c:	e8 af 40 f9	ldr	x8, [sp, #0x158]
10116c650:	1f 05 00 71	cmp	w8, #0x1
10116c654:	6b 06 00 54	b.lt	0x10116c720
10116c658:	60 03 40 bd	ldr	s0, [x27]
10116c65c:	00 a4 20 0f	sshll.2d	v0, v0, #0x0
10116c660:	00 d8 61 5e	scvtf	d0, d0
10116c664:	e9 af 40 f9	ldr	x9, [sp, #0x158]
10116c668:	28 7d 40 92	and	x8, x9, #0xffffffff
10116c66c:	1f 09 00 f1	cmp	x8, #0x2
10116c670:	68 00 00 54	b.hi	0x10116c67c
10116c674:	09 00 80 d2	mov	x9, #0x0
10116c678:	17 00 00 14	b	0x10116c6d4
10116c67c:	29 01 40 f2	ands	x9, x9, #0x1
10116c680:	4a 00 80 52	mov	w10, #0x2
10116c684:	49 01 89 9a	csel	x9, x10, x9, eq
10116c688:	09 01 09 cb	sub	x9, x8, x9
10116c68c:	e1 02 67 9e	fmov	d1, x23
10116c690:	ea 03 09 aa	mov	x10, x9
10116c694:	eb 03 19 aa	mov	x11, x25
10116c698:	ec 03 14 aa	mov	x12, x20
10116c69c:	21 18 60 1e	fdiv	d1, d1, d0
10116c6a0:	e3 13 c0 3d	ldr	q3, [sp, #0x40]
10116c6a4:	82 01 c0 3d	ldr	q2, [x12]
10116c6a8:	8d 61 00 91	add	x13, x12, #0x18
10116c6ac:	a2 91 40 0d	ld1.s	{ v2 }[1], [x13]
10116c6b0:	42 a4 20 0f	sshll.2d	v2, v2, #0x0
10116c6b4:	42 d8 61 4e	scvtf.2d	v2, v2
10116c6b8:	42 90 c1 4f	fmul.2d	v2, v2, v1[0]
10116c6bc:	42 88 61 6e	frinta.2d	v2, v2
10116c6c0:	42 dc 63 6e	fmul.2d	v2, v2, v3
10116c6c4:	62 05 81 3c	str	q2, [x11], #0x10
10116c6c8:	8c c1 00 91	add	x12, x12, #0x30
10116c6cc:	4a 09 00 f1	subs	x10, x10, #0x2
10116c6d0:	a1 fe ff 54	b.ne	0x10116c6a4
10116c6d4:	2a 0f 09 8b	add	x10, x25, x9, lsl #3
10116c6d8:	2b 51 16 9b	madd	x11, x9, x22, x20
10116c6dc:	08 01 09 cb	sub	x8, x8, x9
10116c6e0:	a0 19 60 1e	fdiv	d0, d13, d0
10116c6e4:	8c 3f 95 d2	mov	x12, #0xa9fc
10116c6e8:	2c 5e ba f2	movk	x12, #0xd2f1, lsl #16
10116c6ec:	ac 49 cc f2	movk	x12, #0x624d, lsl #32
10116c6f0:	0c ea e7 f2	movk	x12, #0x3f50, lsl #48
10116c6f4:	69 85 41 b8	ldr	w9, [x11], #0x18
10116c6f8:	21 01 62 1e	scvtf	d1, w9
10116c6fc:	e2 02 67 9e	fmov	d2, x23
10116c700:	21 08 62 1e	fmul	d1, d1, d2
10116c704:	21 08 60 1e	fmul	d1, d1, d0
10116c708:	21 40 66 1e	frinta	d1, d1
10116c70c:	82 01 67 9e	fmov	d2, x12
10116c710:	21 08 62 1e	fmul	d1, d1, d2
10116c714:	41 85 00 fc	str	d1, [x10], #0x8
10116c718:	08 05 00 f1	subs	x8, x8, #0x1
10116c71c:	c1 fe ff 54	b.ne	0x10116c6f4
10116c720:	fc af 40 f9	ldr	x28, [sp, #0x158]
10116c724:	88 0b 00 51	sub	w8, w28, #0x2
10116c728:	9b 07 00 71	subs	w27, w28, #0x1
10116c72c:	08 c1 9f 1a	csel	w8, w8, wzr, gt
10116c730:	9f 57 00 71	cmp	w28, #0x15
10116c734:	89 02 80 52	mov	w9, #0x14
10116c738:	34 c1 88 1a	csel	w20, w9, w8, gt
10116c73c:	ff 07 02 f9	str	xzr, [sp, #0x408]
10116c740:	ff 03 02 f9	str	xzr, [sp, #0x400]
10116c744:	ff 0b 02 f9	str	xzr, [sp, #0x410]
10116c748:	f8 93 00 f9	str	x24, [sp, #0x120]
10116c74c:	ae 02 00 b4	cbz	x14, 0x10116c7a0
10116c750:	4e 00 f8 b6	tbz	x14, #0x3f, 0x10116c758
10116c754:	f8 51 00 14	b	0x101180f34
10116c758:	e0 03 18 aa	mov	x0, x24
10116c75c:	dd 94 8d 94	bl	0x1034d1ad0 ; symbol stub for: __Znwm
10116c760:	f6 03 00 aa	mov	x22, x0
10116c764:	15 00 1a 8b	add	x21, x0, x26
10116c768:	e0 03 02 f9	str	x0, [sp, #0x400]
10116c76c:	f5 0b 02 f9	str	x21, [sp, #0x410]
10116c770:	e1 03 1a aa	mov	x1, x26
10116c774:	97 95 8d 94	bl	0x1034d1dd0 ; symbol stub for: _bzero
10116c778:	f5 07 02 f9	str	x21, [sp, #0x408]
10116c77c:	e0 03 18 aa	mov	x0, x24
10116c780:	d4 94 8d 94	bl	0x1034d1ad0 ; symbol stub for: __Znwm
10116c784:	f5 03 00 aa	mov	x21, x0
10116c788:	e1 03 1a aa	mov	x1, x26
10116c78c:	91 95 8d 94	bl	0x1034d1dd0 ; symbol stub for: _bzero
10116c790:	f8 03 1b aa	mov	x24, x27
10116c794:	9f 0b 00 71	cmp	w28, #0x2
10116c798:	ea 00 00 54	b.ge	0x10116c7b4
10116c79c:	3c 00 00 14	b	0x10116c88c
10116c7a0:	16 00 80 d2	mov	x22, #0x0
10116c7a4:	15 00 80 d2	mov	x21, #0x0
10116c7a8:	f8 03 1b aa	mov	x24, x27
10116c7ac:	9f 0b 00 71	cmp	w28, #0x2
10116c7b0:	eb 06 00 54	b.lt	0x10116c88c
10116c7b4:	20 03 40 fd	ldr	d0, [x25]
10116c7b8:	1f 23 00 71	cmp	w24, #0x8
10116c7bc:	62 00 00 54	b.hs	0x10116c7c8
10116c7c0:	08 00 80 d2	mov	x8, #0x0
10116c7c4:	24 00 00 14	b	0x10116c854
10116c7c8:	08 73 7d 92	and	x8, x24, #0xfffffff8
10116c7cc:	00 04 08 4e	dup.2d	v0, v0[0]
10116c7d0:	c9 82 00 91	add	x9, x22, #0x20
10116c7d4:	2a a3 00 91	add	x10, x25, #0x28
10116c7d8:	eb 03 08 aa	mov	x11, x8
10116c7dc:	f1 43 41 ad	ldp	q17, q16, [sp, #0x20]
10116c7e0:	41 09 7f ad	ldp	q1, q2, [x10, #-0x20]
10116c7e4:	03 40 01 6e	ext.16b	v3, v0, v1, #0x8
10116c7e8:	44 01 c2 ac	ldp	q4, q0, [x10], #0x40
10116c7ec:	25 40 02 6e	ext.16b	v5, v1, v2, #0x8
10116c7f0:	46 40 04 6e	ext.16b	v6, v2, v4, #0x8
10116c7f4:	87 40 00 6e	ext.16b	v7, v4, v0, #0x8
10116c7f8:	21 d4 e3 4e	fsub.2d	v1, v1, v3
10116c7fc:	42 d4 e5 4e	fsub.2d	v2, v2, v5
10116c800:	83 d4 e6 4e	fsub.2d	v3, v4, v6
10116c804:	04 d4 e7 4e	fsub.2d	v4, v0, v7
10116c808:	25 1e b1 4e	mov.16b	v5, v17
10116c80c:	25 cc 70 4e	fmla.2d	v5, v1, v16
10116c810:	21 1e b1 4e	mov.16b	v1, v17
10116c814:	41 cc 70 4e	fmla.2d	v1, v2, v16
10116c818:	22 1e b1 4e	mov.16b	v2, v17
10116c81c:	62 cc 70 4e	fmla.2d	v2, v3, v16
10116c820:	23 1e b1 4e	mov.16b	v3, v17
10116c824:	83 cc 70 4e	fmla.2d	v3, v4, v16
10116c828:	a4 98 e1 4e	frintz.2d	v4, v5
10116c82c:	21 98 e1 4e	frintz.2d	v1, v1
10116c830:	42 98 e1 4e	frintz.2d	v2, v2
10116c834:	24 05 3f ad	stp	q4, q1, [x9, #-0x20]
10116c838:	61 98 e1 4e	frintz.2d	v1, v3
10116c83c:	22 05 82 ac	stp	q2, q1, [x9], #0x40
10116c840:	6b 21 00 f1	subs	x11, x11, #0x8
10116c844:	e1 fc ff 54	b.ne	0x10116c7e0
10116c848:	1f 01 18 eb	cmp	x8, x24
10116c84c:	00 02 00 54	b.eq	0x10116c88c
10116c850:	00 04 18 5e	mov	d0, v0[1]
10116c854:	0a f1 7d d3	lsl	x10, x8, #3
10116c858:	c9 02 0a 8b	add	x9, x22, x10
10116c85c:	08 03 08 cb	sub	x8, x24, x8
10116c860:	2a 03 0a 8b	add	x10, x25, x10
10116c864:	4a 21 00 91	add	x10, x10, #0x8
10116c868:	41 85 40 fc	ldr	d1, [x10], #0x8
10116c86c:	20 38 60 1e	fsub	d0, d1, d0
10116c870:	e2 02 67 9e	fmov	d2, x23
10116c874:	00 38 42 1f	fmadd	d0, d0, d2, d14
10116c878:	00 c0 65 1e	frintz	d0, d0
10116c87c:	20 85 00 fc	str	d0, [x9], #0x8
10116c880:	20 40 60 1e	fmov	d0, d1
10116c884:	08 05 00 f1	subs	x8, x8, #0x1
10116c888:	01 ff ff 54	b.ne	0x10116c868
10116c88c:	9f 97 00 71	cmp	w28, #0x25
10116c890:	a8 04 80 52	mov	w8, #0x25
10116c894:	88 b3 88 1a	csel	w8, w28, w8, lt
10116c898:	97 03 14 4b	sub	w23, w28, w20
10116c89c:	fa 06 00 71	subs	w26, w23, #0x1
10116c8a0:	2d 04 00 54	b.le	0x10116c924
10116c8a4:	5f 23 00 71	cmp	w26, #0x8
10116c8a8:	14 96 e7 d2	mov	x20, #0x3cb0000000000000
10116c8ac:	8f 02 80 52	mov	w15, #0x14
10116c8b0:	23 05 00 54	b.lo	0x10116c954
10116c8b4:	49 f3 7d d3	lsl	x9, x26, #3
10116c8b8:	aa 02 09 8b	add	x10, x21, x9
10116c8bc:	c9 02 09 8b	add	x9, x22, x9
10116c8c0:	29 21 00 91	add	x9, x9, #0x8
10116c8c4:	bf 02 09 eb	cmp	x21, x9
10116c8c8:	c2 32 4a fa	ccmp	x22, x10, #0x2, lo
10116c8cc:	43 04 00 54	b.lo	0x10116c954
10116c8d0:	49 73 7d 92	and	x9, x26, #0xfffffff8
10116c8d4:	aa 82 00 91	add	x10, x21, #0x20
10116c8d8:	cb 82 00 91	add	x11, x22, #0x20
10116c8dc:	ec 03 09 aa	mov	x12, x9
10116c8e0:	60 81 de 3c	ldur	q0, [x11, #-0x18]
10116c8e4:	61 81 df 3c	ldur	q1, [x11, #-0x8]
10116c8e8:	62 81 c0 3c	ldur	q2, [x11, #0x8]
10116c8ec:	63 81 c1 3c	ldur	q3, [x11, #0x18]
10116c8f0:	64 15 7f ad	ldp	q4, q5, [x11, #-0x20]
10116c8f4:	66 1d c2 ac	ldp	q6, q7, [x11], #0x40
10116c8f8:	00 d4 e4 6e	fabd.2d	v0, v0, v4
10116c8fc:	21 d4 e5 6e	fabd.2d	v1, v1, v5
10116c900:	42 d4 e6 6e	fabd.2d	v2, v2, v6
10116c904:	63 d4 e7 6e	fabd.2d	v3, v3, v7
10116c908:	40 05 3f ad	stp	q0, q1, [x10, #-0x20]
10116c90c:	42 0d 82 ac	stp	q2, q3, [x10], #0x40
10116c910:	8c 21 00 f1	subs	x12, x12, #0x8
10116c914:	61 fe ff 54	b.ne	0x10116c8e0
10116c918:	3f 01 1a eb	cmp	x9, x26
10116c91c:	e1 01 00 54	b.ne	0x10116c958
10116c920:	19 00 00 14	b	0x10116c984
10116c924:	09 00 80 52	mov	w9, #0x0
10116c928:	0c 00 80 52	mov	w12, #0x0
10116c92c:	5f 07 00 71	cmp	w26, #0x1
10116c930:	50 c7 9f 1a	csinc	w16, w26, wzr, gt
10116c934:	ea 03 1a aa	mov	x10, x26
10116c938:	4e 7d 40 93	sxtw	x14, w10
10116c93c:	00 e4 00 2f	movi	d0, #0000000000000000
10116c940:	4b 00 80 52	mov	w11, #0x2
10116c944:	8a 02 80 52	mov	w10, #0x14
10116c948:	14 96 e7 d2	mov	x20, #0x3cb0000000000000
10116c94c:	8f 02 80 52	mov	w15, #0x14
10116c950:	42 00 00 14	b	0x10116ca58
10116c954:	09 00 80 d2	mov	x9, #0x0
10116c958:	2b f1 7d d3	lsl	x11, x9, #3
10116c95c:	ca 02 0b 8b	add	x10, x22, x11
10116c960:	4a 21 00 91	add	x10, x10, #0x8
10116c964:	ab 02 0b 8b	add	x11, x21, x11
10116c968:	49 03 09 cb	sub	x9, x26, x9
10116c96c:	41 81 7f 6d	ldp	d1, d0, [x10, #-0x8]
10116c970:	00 d4 e1 7e	fabd	d0, d0, d1
10116c974:	60 85 00 fc	str	d0, [x11], #0x8
10116c978:	4a 21 00 91	add	x10, x10, #0x8
10116c97c:	29 05 00 f1	subs	x9, x9, #0x1
10116c980:	61 ff ff 54	b.ne	0x10116c96c
10116c984:	0a 00 80 d2	mov	x10, #0x0
10116c988:	09 00 80 52	mov	w9, #0x0
10116c98c:	eb 03 1a aa	mov	x11, x26
10116c990:	6e 7d 40 93	sxtw	x14, w11
10116c994:	00 e4 00 2f	movi	d0, #0000000000000000
10116c998:	07 00 00 14	b	0x10116c9b4
10116c99c:	c1 7a 6a fc	ldr	d1, [x22, x10, lsl #3]
10116c9a0:	20 28 60 1e	fadd	d0, d1, d0
10116c9a4:	29 05 00 11	add	w9, w9, #0x1
10116c9a8:	4a 05 00 91	add	x10, x10, #0x1
10116c9ac:	5f 03 0a eb	cmp	x26, x10
10116c9b0:	60 01 00 54	b.eq	0x10116c9dc
10116c9b4:	a1 7a 6a fc	ldr	d1, [x21, x10, lsl #3]
10116c9b8:	20 20 6f 1e	fcmp	d1, d15
10116c9bc:	0d ff ff 54	b.le	0x10116c99c
10116c9c0:	3f 01 08 6b	cmp	w9, w8
10116c9c4:	4a 0a 00 54	b.ge	0x10116cb0c
10116c9c8:	09 00 80 52	mov	w9, #0x0
10116c9cc:	00 e4 00 2f	movi	d0, #0000000000000000
10116c9d0:	4a 05 00 91	add	x10, x10, #0x1
10116c9d4:	5f 03 0a eb	cmp	x26, x10
10116c9d8:	e1 fe ff 54	b.ne	0x10116c9b4
10116c9dc:	0c 00 80 d2	mov	x12, #0x0
10116c9e0:	5f 01 0e eb	cmp	x10, x14
10116c9e4:	2a 00 80 52	mov	w10, #0x1
10116c9e8:	4b 00 80 52	mov	w11, #0x2
10116c9ec:	6b a1 8a 1a	csel	w11, w11, w10, ge
10116c9f0:	6a 01 80 52	mov	w10, #0xb
10116c9f4:	ea a1 8a 1a	csel	w10, w15, w10, ge
10116c9f8:	e9 a3 89 1a	csel	w9, wzr, w9, ge
10116c9fc:	01 e4 00 2f	movi	d1, #0000000000000000
10116ca00:	20 ac 60 1e	fcsel	d0, d1, d0, ge
10116ca04:	41 01 62 1e	scvtf	d1, w10
10116ca08:	07 00 00 14	b	0x10116ca24
10116ca0c:	c2 7a 6c fc	ldr	d2, [x22, x12, lsl #3]
10116ca10:	40 28 60 1e	fadd	d0, d2, d0
10116ca14:	29 05 00 11	add	w9, w9, #0x1
10116ca18:	8c 05 00 91	add	x12, x12, #0x1
10116ca1c:	5f 03 0c eb	cmp	x26, x12
10116ca20:	60 01 00 54	b.eq	0x10116ca4c
10116ca24:	a2 7a 6c fc	ldr	d2, [x21, x12, lsl #3]
10116ca28:	40 20 61 1e	fcmp	d2, d1
10116ca2c:	0d ff ff 54	b.le	0x10116ca0c
10116ca30:	3f 01 08 6b	cmp	w9, w8
10116ca34:	ca 06 00 54	b.ge	0x10116cb0c
10116ca38:	09 00 80 52	mov	w9, #0x0
10116ca3c:	00 e4 00 2f	movi	d0, #0000000000000000
10116ca40:	8c 05 00 91	add	x12, x12, #0x1
10116ca44:	5f 03 0c eb	cmp	x26, x12
10116ca48:	e1 fe ff 54	b.ne	0x10116ca24
10116ca4c:	9f 01 0e eb	cmp	x12, x14
10116ca50:	ec a7 9f 1a	cset	w12, lt
10116ca54:	f0 03 1a aa	mov	x16, x26
10116ca58:	8c 01 00 52	eor	w12, w12, #0x1
10116ca5c:	6b 01 0c 0b	add	w11, w11, w12
10116ca60:	7f 0d 00 71	cmp	w11, #0x3
10116ca64:	cc 03 80 52	mov	w12, #0x1e
10116ca68:	4a 11 8c 1a	csel	w10, w10, w12, ne
10116ca6c:	29 11 9f 1a	csel	w9, w9, wzr, ne
10116ca70:	01 e4 00 2f	movi	d1, #0000000000000000
10116ca74:	00 1c 61 1e	fcsel	d0, d0, d1, ne
10116ca78:	7f 09 00 71	cmp	w11, #0x2
10116ca7c:	ea 01 8a 1a	csel	w10, w15, w10, eq
10116ca80:	e9 03 89 1a	csel	w9, wzr, w9, eq
10116ca84:	20 0c 60 1e	fcsel	d0, d1, d0, eq
10116ca88:	ff 06 00 71	cmp	w23, #0x1
10116ca8c:	ed 02 00 54	b.le	0x10116cae8
10116ca90:	41 01 62 1e	scvtf	d1, w10
10116ca94:	ea 03 10 2a	mov	w10, w16
10116ca98:	eb 03 15 aa	mov	x11, x21
10116ca9c:	ec 03 16 aa	mov	x12, x22
10116caa0:	07 00 00 14	b	0x10116cabc
10116caa4:	82 85 40 fc	ldr	d2, [x12], #0x8
10116caa8:	40 28 60 1e	fadd	d0, d2, d0
10116caac:	29 05 00 11	add	w9, w9, #0x1
10116cab0:	6b 21 00 91	add	x11, x11, #0x8
10116cab4:	4a 05 00 f1	subs	x10, x10, #0x1
10116cab8:	80 01 00 54	b.eq	0x10116cae8
10116cabc:	62 01 40 fd	ldr	d2, [x11]
10116cac0:	40 20 61 1e	fcmp	d2, d1
10116cac4:	0d ff ff 54	b.le	0x10116caa4
10116cac8:	3f 01 08 6b	cmp	w9, w8
10116cacc:	6a 08 00 54	b.ge	0x10116cbd8
10116cad0:	09 00 80 52	mov	w9, #0x0
10116cad4:	00 e4 00 2f	movi	d0, #0000000000000000
10116cad8:	8c 21 00 91	add	x12, x12, #0x8
10116cadc:	6b 21 00 91	add	x11, x11, #0x8
10116cae0:	4a 05 00 f1	subs	x10, x10, #0x1
10116cae4:	c1 fe ff 54	b.ne	0x10116cabc
10116cae8:	9f 07 00 71	cmp	w28, #0x1
10116caec:	0b 04 00 54	b.lt	0x10116cb6c
10116caf0:	1f 05 00 71	cmp	w8, #0x1
10116caf4:	09 c5 9f 1a	csinc	w9, w8, wzr, gt
10116caf8:	3f 09 00 71	cmp	w9, #0x2
10116cafc:	02 04 00 54	b.hs	0x10116cb7c
10116cb00:	0a 00 80 d2	mov	x10, #0x0
10116cb04:	00 e4 00 2f	movi	d0, #0000000000000000
10116cb08:	28 00 00 14	b	0x10116cba8
10116cb0c:	f0 03 1a aa	mov	x16, x26
10116cb10:	e8 03 09 aa	mov	x8, x9
10116cb14:	f5 73 00 f9	str	x21, [sp, #0xe0]
10116cb18:	88 05 00 35	cbnz	w8, 0x10116cbc8
10116cb1c:	e8 37 40 fd	ldr	d8, [sp, #0x68]
10116cb20:	fb 0a 00 71	subs	w27, w23, #0x2
10116cb24:	f5 a3 40 f9	ldr	x21, [sp, #0x140]
10116cb28:	eb 0d 00 54	b.lt	0x10116cce4
10116cb2c:	f5 03 10 aa	mov	x21, x16
10116cb30:	ee 8b 00 f9	str	x14, [sp, #0x110]
10116cb34:	54 f3 7d d3	lsl	x20, x26, #3
10116cb38:	e0 03 14 aa	mov	x0, x20
10116cb3c:	e5 93 8d 94	bl	0x1034d1ad0 ; symbol stub for: __Znwm
10116cb40:	f9 03 00 aa	mov	x25, x0
10116cb44:	e1 03 14 aa	mov	x1, x20
10116cb48:	a2 94 8d 94	bl	0x1034d1dd0 ; symbol stub for: _bzero
10116cb4c:	e8 03 15 2a	mov	w8, w21
10116cb50:	bf 22 00 71	cmp	w21, #0x8
10116cb54:	a2 04 00 54	b.hs	0x10116cbe8
10116cb58:	09 00 80 d2	mov	x9, #0x0
10116cb5c:	14 96 e7 d2	mov	x20, #0x3cb0000000000000
10116cb60:	ee 8b 40 f9	ldr	x14, [sp, #0x110]
10116cb64:	f5 a3 40 f9	ldr	x21, [sp, #0x140]
10116cb68:	2f 00 00 14	b	0x10116cc24
10116cb6c:	00 e4 00 2f	movi	d0, #0000000000000000
10116cb70:	f5 73 00 f9	str	x21, [sp, #0xe0]
10116cb74:	a8 02 00 35	cbnz	w8, 0x10116cbc8
10116cb78:	e9 ff ff 17	b	0x10116cb1c
10116cb7c:	2a 75 7f 92	and	x10, x9, #0x7ffffffe
10116cb80:	00 e4 00 6f	movi.2d	v0, #0000000000000000
10116cb84:	eb 03 0a aa	mov	x11, x10
10116cb88:	ec 03 16 aa	mov	x12, x22
10116cb8c:	81 05 c1 3c	ldr	q1, [x12], #0x10
10116cb90:	20 d4 60 4e	fadd.2d	v0, v1, v0
10116cb94:	6b 09 00 f1	subs	x11, x11, #0x2
10116cb98:	a1 ff ff 54	b.ne	0x10116cb8c
10116cb9c:	00 d8 70 7e	faddp.2d	d0, v0
10116cba0:	5f 01 09 eb	cmp	x10, x9
10116cba4:	e0 00 00 54	b.eq	0x10116cbc0
10116cba8:	cb 0e 0a 8b	add	x11, x22, x10, lsl #3
10116cbac:	29 01 0a cb	sub	x9, x9, x10
10116cbb0:	61 85 40 fc	ldr	d1, [x11], #0x8
10116cbb4:	20 28 60 1e	fadd	d0, d1, d0
10116cbb8:	29 05 00 f1	subs	x9, x9, #0x1
10116cbbc:	a1 ff ff 54	b.ne	0x10116cbb0
10116cbc0:	f5 73 00 f9	str	x21, [sp, #0xe0]
10116cbc4:	c8 fa ff 34	cbz	w8, 0x10116cb1c
10116cbc8:	01 01 62 1e	scvtf	d1, w8
10116cbcc:	08 18 61 1e	fdiv	d8, d0, d1
10116cbd0:	f5 a3 40 f9	ldr	x21, [sp, #0x140]
10116cbd4:	44 00 00 14	b	0x10116cce4
10116cbd8:	e8 03 09 aa	mov	x8, x9
10116cbdc:	f5 73 00 f9	str	x21, [sp, #0xe0]
10116cbe0:	48 ff ff 35	cbnz	w8, 0x10116cbc8
10116cbe4:	ce ff ff 17	b	0x10116cb1c
10116cbe8:	09 71 7d 92	and	x9, x8, #0xfffffff8
10116cbec:	2a 83 00 91	add	x10, x25, #0x20
10116cbf0:	cb 82 00 91	add	x11, x22, #0x20
10116cbf4:	ec 03 09 aa	mov	x12, x9
10116cbf8:	14 96 e7 d2	mov	x20, #0x3cb0000000000000
10116cbfc:	ee 8b 40 f9	ldr	x14, [sp, #0x110]
10116cc00:	f5 a3 40 f9	ldr	x21, [sp, #0x140]
10116cc04:	60 05 7f ad	ldp	q0, q1, [x11, #-0x20]
10116cc08:	62 0d c2 ac	ldp	q2, q3, [x11], #0x40
10116cc0c:	40 05 3f ad	stp	q0, q1, [x10, #-0x20]
10116cc10:	42 0d 82 ac	stp	q2, q3, [x10], #0x40
10116cc14:	8c 21 00 f1	subs	x12, x12, #0x8
10116cc18:	61 ff ff 54	b.ne	0x10116cc04
10116cc1c:	3f 01 08 eb	cmp	x9, x8
10116cc20:	20 01 00 54	b.eq	0x10116cc44
10116cc24:	2b f1 7d d3	lsl	x11, x9, #3
10116cc28:	ca 02 0b 8b	add	x10, x22, x11
10116cc2c:	2b 03 0b 8b	add	x11, x25, x11
10116cc30:	08 01 09 cb	sub	x8, x8, x9
10116cc34:	40 85 40 fc	ldr	d0, [x10], #0x8
10116cc38:	60 85 00 fc	str	d0, [x11], #0x8
10116cc3c:	08 05 00 f1	subs	x8, x8, #0x1
10116cc40:	a1 ff ff 54	b.ne	0x10116cc34
10116cc44:	ff 0e 00 71	cmp	w23, #0x3
10116cc48:	eb 02 00 54	b.lt	0x10116cca4
10116cc4c:	09 00 80 d2	mov	x9, #0x0
10116cc50:	28 00 80 52	mov	w8, #0x1
10116cc54:	05 00 00 14	b	0x10116cc68
10116cc58:	08 05 00 91	add	x8, x8, #0x1
10116cc5c:	e9 03 0a aa	mov	x9, x10
10116cc60:	5f 01 1b eb	cmp	x10, x27
10116cc64:	00 02 00 54	b.eq	0x10116cca4
10116cc68:	2a 05 00 91	add	x10, x9, #0x1
10116cc6c:	5f 01 0e eb	cmp	x10, x14
10116cc70:	4a ff ff 54	b.ge	0x10116cc58
10116cc74:	eb 03 08 aa	mov	x11, x8
10116cc78:	04 00 00 14	b	0x10116cc88
10116cc7c:	6b 05 00 91	add	x11, x11, #0x1
10116cc80:	5f 03 0b 6b	cmp	w26, w11
10116cc84:	ad fe ff 54	b.le	0x10116cc58
10116cc88:	20 7b 69 fc	ldr	d0, [x25, x9, lsl #3]
10116cc8c:	21 7b 6b fc	ldr	d1, [x25, x11, lsl #3]
10116cc90:	00 20 61 1e	fcmp	d0, d1
10116cc94:	4a ff ff 54	b.ge	0x10116cc7c
10116cc98:	21 7b 29 fc	str	d1, [x25, x9, lsl #3]
10116cc9c:	20 7b 2b fc	str	d0, [x25, x11, lsl #3]
10116cca0:	f7 ff ff 17	b	0x10116cc7c
10116cca4:	48 07 01 12	and	w8, w26, #0x80000001
10116cca8:	1f 05 00 71	cmp	w8, #0x1
10116ccac:	81 00 00 54	b.ne	0x10116ccbc
10116ccb0:	48 7f 01 53	lsr	w8, w26, #1
10116ccb4:	28 5b 68 fc	ldr	d8, [x25, w8, uxtw #3]
10116ccb8:	09 00 00 14	b	0x10116ccdc
10116ccbc:	5f 03 00 71	cmp	w26, #0x0
10116ccc0:	48 a7 9a 1a	cinc	w8, w26, lt
10116ccc4:	08 7d 01 13	asr	w8, w8, #1
10116ccc8:	09 05 00 51	sub	w9, w8, #0x1
10116cccc:	20 db 69 fc	ldr	d0, [x25, w9, sxtw #3]
10116ccd0:	21 5b 68 fc	ldr	d1, [x25, w8, uxtw #3]
10116ccd4:	20 28 60 1e	fadd	d0, d1, d0
10116ccd8:	08 08 6e 1e	fmul	d8, d0, d14
10116ccdc:	e0 03 19 aa	mov	x0, x25
10116cce0:	76 93 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10116cce4:	08 80 c9 d2	mov	x8, #0x4c0000000000
10116cce8:	a8 1d e8 f2	movk	x8, #0x40ed, lsl #48
10116ccec:	00 01 67 9e	fmov	d0, x8
10116ccf0:	00 18 68 1e	fdiv	d0, d0, d8
10116ccf4:	e1 4f 40 fd	ldr	d1, [sp, #0x98]
10116ccf8:	00 20 61 1e	fcmp	d0, d1
10116ccfc:	e8 a7 9f 1a	cset	w8, lt
10116cd00:	e1 4b 40 fd	ldr	d1, [sp, #0x90]
10116cd04:	00 20 61 1e	fcmp	d0, d1
10116cd08:	e9 d7 9f 1a	cset	w9, gt
10116cd0c:	08 01 09 2a	orr	w8, w8, w9
10116cd10:	00 40 62 1e	fcvt	s0, d0
10116cd14:	1f 01 00 71	cmp	w8, #0x0
10116cd18:	e1 8f 40 bd	ldr	s1, [sp, #0x8c]
10116cd1c:	20 1c 20 1e	fcsel	s0, s1, s0, ne
10116cd20:	e8 77 40 f9	ldr	x8, [sp, #0xe8]
10116cd24:	00 01 00 bd	str	s0, [x8]
10116cd28:	e0 43 40 fd	ldr	d0, [sp, #0x80]
10116cd2c:	0c 1c 68 1e	fcsel	d12, d0, d8, ne
10116cd30:	ff fb 01 f9	str	xzr, [sp, #0x3f0]
10116cd34:	ff f7 01 f9	str	xzr, [sp, #0x3e8]
10116cd38:	ff ff 01 f9	str	xzr, [sp, #0x3f8]
10116cd3c:	15 16 00 b4	cbz	x21, 0x10116cffc
10116cd40:	fb 9f 40 f9	ldr	x27, [sp, #0x138]
10116cd44:	f7 07 40 91	add	x23, sp, #0x1, lsl #12
10116cd48:	f7 c2 11 91	add	x23, x23, #0x470
10116cd4c:	1a 03 80 52	mov	w26, #0x18
10116cd50:	55 00 f8 b6	tbz	x21, #0x3f, 0x10116cd58
10116cd54:	73 50 00 14	b	0x101180f20
10116cd58:	fc 93 40 f9	ldr	x28, [sp, #0x120]
10116cd5c:	e0 03 1c aa	mov	x0, x28
10116cd60:	5c 93 8d 94	bl	0x1034d1ad0 ; symbol stub for: __Znwm
10116cd64:	f9 03 00 aa	mov	x25, x0
10116cd68:	08 0c 13 8b	add	x8, x0, x19, lsl #3
10116cd6c:	e0 f7 01 f9	str	x0, [sp, #0x3e8]
10116cd70:	e8 ff 01 f9	str	x8, [sp, #0x3f8]
10116cd74:	68 06 00 d1	sub	x8, x19, #0x1
10116cd78:	15 f1 40 92	and	x21, x8, #0x1fffffffffffffff
10116cd7c:	a8 f2 7d d3	lsl	x8, x21, #3
10116cd80:	14 21 00 91	add	x20, x8, #0x8
10116cd84:	e1 03 14 aa	mov	x1, x20
10116cd88:	12 94 8d 94	bl	0x1034d1dd0 ; symbol stub for: _bzero
10116cd8c:	b5 06 00 91	add	x21, x21, #0x1
10116cd90:	28 0f 15 8b	add	x8, x25, x21, lsl #3
10116cd94:	e8 fb 01 f9	str	x8, [sp, #0x3f0]
10116cd98:	e0 03 1c aa	mov	x0, x28
10116cd9c:	4d 93 8d 94	bl	0x1034d1ad0 ; symbol stub for: __Znwm
10116cda0:	fc 03 00 aa	mov	x28, x0
10116cda4:	e1 03 14 aa	mov	x1, x20
10116cda8:	0a 94 8d 94	bl	0x1034d1dd0 ; symbol stub for: _bzero
10116cdac:	fc 8b 00 f9	str	x28, [sp, #0x110]
10116cdb0:	88 0f 15 8b	add	x8, x28, x21, lsl #3
10116cdb4:	14 96 e7 d2	mov	x20, #0x3cb0000000000000
10116cdb8:	fc af 40 f9	ldr	x28, [sp, #0x158]
10116cdbc:	9f 0b 00 71	cmp	w28, #0x2
10116cdc0:	0b 13 00 54	b.lt	0x10116d020
10116cdc4:	09 00 80 d2	mov	x9, #0x0
10116cdc8:	1f 0b 00 71	cmp	w24, #0x2
10116cdcc:	f0 a3 40 f9	ldr	x16, [sp, #0x140]
10116cdd0:	c3 1d 00 54	b.lo	0x10116d188
10116cdd4:	ea 8b 40 f9	ldr	x10, [sp, #0x110]
10116cdd8:	4a 01 19 cb	sub	x10, x10, x25
10116cddc:	5f 41 00 f1	cmp	x10, #0x10
10116cde0:	43 1d 00 54	b.lo	0x10116d188
10116cde4:	09 7b 7f 92	and	x9, x24, #0xfffffffe
10116cde8:	ea 03 09 aa	mov	x10, x9
10116cdec:	eb 8b 40 f9	ldr	x11, [sp, #0x110]
10116cdf0:	ec 03 19 aa	mov	x12, x25
10116cdf4:	ed 03 16 aa	mov	x13, x22
10116cdf8:	a0 19 6c 1e	fdiv	d0, d13, d12
10116cdfc:	e5 17 c0 3d	ldr	q5, [sp, #0x50]
10116ce00:	a1 05 c1 3c	ldr	q1, [x13], #0x10
10116ce04:	21 90 c0 4f	fmul.2d	v1, v1, v0[0]
10116ce08:	22 f8 e0 4e	fabs.2d	v2, v1
10116ce0c:	43 04 18 5e	mov	d3, v2[1]
10116ce10:	84 02 67 9e	fmov	d4, x20
10116ce14:	60 20 64 1e	fcmp	d3, d4
10116ce18:	ee c3 9f da	csetm	x14, le
10116ce1c:	40 20 64 1e	fcmp	d2, d4
10116ce20:	ef c3 9f da	csetm	x15, le
10116ce24:	e2 01 67 9e	fmov	d2, x15
10116ce28:	c2 1d 18 4e	mov.d	v2[1], x14
10116ce2c:	a3 e4 e1 6e	fcmgt.2d	v3, v5, v1
10116ce30:	81 05 81 3c	str	q1, [x12], #0x10
10116ce34:	a4 fc 61 6e	fdiv.2d	v4, v5, v1
10116ce38:	81 1c a3 6e	bit.16b	v1, v4, v3
10116ce3c:	21 1c 62 4e	bic.16b	v1, v1, v2
10116ce40:	61 05 81 3c	str	q1, [x11], #0x10
10116ce44:	4a 09 00 f1	subs	x10, x10, #0x2
10116ce48:	c1 fd ff 54	b.ne	0x10116ce00
10116ce4c:	3f 01 18 eb	cmp	x9, x24
10116ce50:	c1 19 00 54	b.ne	0x10116d188
10116ce54:	0a 00 80 52	mov	w10, #0x0
10116ce58:	09 00 80 52	mov	w9, #0x0
10116ce5c:	eb 7b 5f b2	mov	x11, #-0x200000000
10116ce60:	0b 02 0b 8b	add	x11, x16, x11
10116ce64:	6b fd 5d 93	asr	x11, x11, #29
10116ce68:	20 6b 6b fc	ldr	d0, [x25, x11]
10116ce6c:	0c f3 7d d3	lsl	x12, x24, #3
10116ce70:	20 6b 2c fc	str	d0, [x25, x12]
10116ce74:	ee 8b 40 f9	ldr	x14, [sp, #0x110]
10116ce78:	c0 69 6b fc	ldr	d0, [x14, x11]
10116ce7c:	c0 69 2c fc	str	d0, [x14, x12]
10116ce80:	eb 07 40 91	add	x11, sp, #0x1, lsl #12
10116ce84:	6b c1 09 91	add	x11, x11, #0x270
10116ce88:	00 e4 00 6f	movi.2d	v0, #0000000000000000
10116ce8c:	60 7d 81 3d	str	q0, [x11, #0x5f0]
10116ce90:	60 79 81 3d	str	q0, [x11, #0x5e0]
10116ce94:	60 75 81 3d	str	q0, [x11, #0x5d0]
10116ce98:	60 71 81 3d	str	q0, [x11, #0x5c0]
10116ce9c:	60 6d 81 3d	str	q0, [x11, #0x5b0]
10116cea0:	60 69 81 3d	str	q0, [x11, #0x5a0]
10116cea4:	60 65 81 3d	str	q0, [x11, #0x590]
10116cea8:	60 61 81 3d	str	q0, [x11, #0x580]
10116ceac:	60 5d 81 3d	str	q0, [x11, #0x570]
10116ceb0:	60 59 81 3d	str	q0, [x11, #0x560]
10116ceb4:	60 55 81 3d	str	q0, [x11, #0x550]
10116ceb8:	60 51 81 3d	str	q0, [x11, #0x540]
10116cebc:	60 4d 81 3d	str	q0, [x11, #0x530]
10116cec0:	60 49 81 3d	str	q0, [x11, #0x520]
10116cec4:	60 45 81 3d	str	q0, [x11, #0x510]
10116cec8:	60 41 81 3d	str	q0, [x11, #0x500]
10116cecc:	60 3d 81 3d	str	q0, [x11, #0x4f0]
10116ced0:	60 39 81 3d	str	q0, [x11, #0x4e0]
10116ced4:	60 35 81 3d	str	q0, [x11, #0x4d0]
10116ced8:	60 31 81 3d	str	q0, [x11, #0x4c0]
10116cedc:	60 2d 81 3d	str	q0, [x11, #0x4b0]
10116cee0:	60 29 81 3d	str	q0, [x11, #0x4a0]
10116cee4:	60 25 81 3d	str	q0, [x11, #0x490]
10116cee8:	60 21 81 3d	str	q0, [x11, #0x480]
10116ceec:	60 1d 81 3d	str	q0, [x11, #0x470]
10116cef0:	60 19 81 3d	str	q0, [x11, #0x460]
10116cef4:	60 15 81 3d	str	q0, [x11, #0x450]
10116cef8:	60 11 81 3d	str	q0, [x11, #0x440]
10116cefc:	60 0d 81 3d	str	q0, [x11, #0x430]
10116cf00:	60 09 81 3d	str	q0, [x11, #0x420]
10116cf04:	60 05 81 3d	str	q0, [x11, #0x410]
10116cf08:	60 81 1f ad	stp	q0, q0, [x11, #0x3f0]
10116cf0c:	60 81 1e ad	stp	q0, q0, [x11, #0x3d0]
10116cf10:	60 81 1d ad	stp	q0, q0, [x11, #0x3b0]
10116cf14:	60 81 1c ad	stp	q0, q0, [x11, #0x390]
10116cf18:	60 81 1b ad	stp	q0, q0, [x11, #0x370]
10116cf1c:	60 81 1a ad	stp	q0, q0, [x11, #0x350]
10116cf20:	60 81 19 ad	stp	q0, q0, [x11, #0x330]
10116cf24:	60 81 18 ad	stp	q0, q0, [x11, #0x310]
10116cf28:	60 81 17 ad	stp	q0, q0, [x11, #0x2f0]
10116cf2c:	60 81 16 ad	stp	q0, q0, [x11, #0x2d0]
10116cf30:	60 81 15 ad	stp	q0, q0, [x11, #0x2b0]
10116cf34:	60 81 14 ad	stp	q0, q0, [x11, #0x290]
10116cf38:	60 81 13 ad	stp	q0, q0, [x11, #0x270]
10116cf3c:	60 81 12 ad	stp	q0, q0, [x11, #0x250]
10116cf40:	60 81 11 ad	stp	q0, q0, [x11, #0x230]
10116cf44:	60 81 10 ad	stp	q0, q0, [x11, #0x210]
10116cf48:	08 01 0e cb	sub	x8, x8, x14
10116cf4c:	08 fd 43 93	asr	x8, x8, #3
10116cf50:	60 81 80 3d	str	q0, [x11, #0x200]
10116cf54:	2d 5c 8f d2	mov	x13, #0x7ae1
10116cf58:	8d c2 b5 f2	movk	x13, #0xae14, lsl #16
10116cf5c:	ed 28 dc f2	movk	x13, #0xe147, lsl #32
10116cf60:	4d fe e7 f2	movk	x13, #0x3ff2, lsl #48
10116cf64:	c0 d9 6a fc	ldr	d0, [x14, w10, sxtw #3]
10116cf68:	a1 01 67 9e	fmov	d1, x13
10116cf6c:	00 20 61 1e	fcmp	d0, d1
10116cf70:	ad 03 00 54	b.le	0x10116cfe4
10116cf74:	4b 7d 40 93	sxtw	x11, w10
10116cf78:	6b 05 00 91	add	x11, x11, #0x1
10116cf7c:	c0 79 6b fc	ldr	d0, [x14, x11, lsl #3]
10116cf80:	a1 01 67 9e	fmov	d1, x13
10116cf84:	00 20 61 1e	fcmp	d0, d1
10116cf88:	ed 02 00 54	b.le	0x10116cfe4
10116cf8c:	ec 07 40 91	add	x12, sp, #0x1, lsl #12
10116cf90:	8c c1 19 91	add	x12, x12, #0x670
10116cf94:	8a d9 29 b8	str	w10, [x12, w9, sxtw #2]
10116cf98:	1f 01 0b eb	cmp	x8, x11
10116cf9c:	a9 01 00 54	b.ls	0x10116cfd0
10116cfa0:	7f 02 0b eb	cmp	x19, x11
10116cfa4:	6d 01 00 54	b.le	0x10116cfd0
10116cfa8:	6a 05 00 91	add	x10, x11, #0x1
10116cfac:	eb 03 0a aa	mov	x11, x10
10116cfb0:	1f 01 0a eb	cmp	x8, x10
10116cfb4:	e9 00 00 54	b.ls	0x10116cfd0
10116cfb8:	c0 79 6b fc	ldr	d0, [x14, x11, lsl #3]
10116cfbc:	6a 05 00 91	add	x10, x11, #0x1
10116cfc0:	a1 01 67 9e	fmov	d1, x13
10116cfc4:	00 20 61 1e	fcmp	d0, d1
10116cfc8:	60 c1 53 fa	ccmp	x11, x19, #0x0, gt
10116cfcc:	0b ff ff 54	b.lt	0x10116cfac
10116cfd0:	2a 7d 40 93	sxtw	x10, w9
10116cfd4:	6c 05 00 51	sub	w12, w11, #0x1
10116cfd8:	ec 7a 2a b8	str	w12, [x23, x10, lsl #2]
10116cfdc:	29 05 00 11	add	w9, w9, #0x1
10116cfe0:	ea 03 0b aa	mov	x10, x11
10116cfe4:	4a 05 00 11	add	w10, w10, #0x1
10116cfe8:	5f 01 18 6b	cmp	w10, w24
10116cfec:	0a 08 00 54	b.ge	0x10116d0ec
10116cff0:	3f 01 02 71	cmp	w9, #0x80
10116cff4:	8b fb ff 54	b.lt	0x10116cf64
10116cff8:	3d 00 00 14	b	0x10116d0ec
10116cffc:	19 00 80 d2	mov	x25, #0x0
10116d000:	08 00 80 d2	mov	x8, #0x0
10116d004:	ff 8b 00 f9	str	xzr, [sp, #0x110]
10116d008:	fb 9f 40 f9	ldr	x27, [sp, #0x138]
10116d00c:	f7 07 40 91	add	x23, sp, #0x1, lsl #12
10116d010:	f7 c2 11 91	add	x23, x23, #0x470
10116d014:	1a 03 80 52	mov	w26, #0x18
10116d018:	9f 0b 00 71	cmp	w28, #0x2
10116d01c:	4a ed ff 54	b.ge	0x10116cdc4
10116d020:	e8 07 40 91	add	x8, sp, #0x1, lsl #12
10116d024:	08 c1 09 91	add	x8, x8, #0x270
10116d028:	00 e4 00 6f	movi.2d	v0, #0000000000000000
10116d02c:	00 7d 81 3d	str	q0, [x8, #0x5f0]
10116d030:	00 79 81 3d	str	q0, [x8, #0x5e0]
10116d034:	00 75 81 3d	str	q0, [x8, #0x5d0]
10116d038:	00 71 81 3d	str	q0, [x8, #0x5c0]
10116d03c:	00 6d 81 3d	str	q0, [x8, #0x5b0]
10116d040:	00 69 81 3d	str	q0, [x8, #0x5a0]
10116d044:	00 65 81 3d	str	q0, [x8, #0x590]
10116d048:	00 61 81 3d	str	q0, [x8, #0x580]
10116d04c:	00 5d 81 3d	str	q0, [x8, #0x570]
10116d050:	00 59 81 3d	str	q0, [x8, #0x560]
10116d054:	00 55 81 3d	str	q0, [x8, #0x550]
10116d058:	00 51 81 3d	str	q0, [x8, #0x540]
10116d05c:	00 4d 81 3d	str	q0, [x8, #0x530]
10116d060:	00 49 81 3d	str	q0, [x8, #0x520]
10116d064:	00 45 81 3d	str	q0, [x8, #0x510]
10116d068:	00 41 81 3d	str	q0, [x8, #0x500]
10116d06c:	00 3d 81 3d	str	q0, [x8, #0x4f0]
10116d070:	00 39 81 3d	str	q0, [x8, #0x4e0]
10116d074:	00 35 81 3d	str	q0, [x8, #0x4d0]
10116d078:	00 31 81 3d	str	q0, [x8, #0x4c0]
10116d07c:	00 2d 81 3d	str	q0, [x8, #0x4b0]
10116d080:	00 29 81 3d	str	q0, [x8, #0x4a0]
10116d084:	00 25 81 3d	str	q0, [x8, #0x490]
10116d088:	00 21 81 3d	str	q0, [x8, #0x480]
10116d08c:	00 1d 81 3d	str	q0, [x8, #0x470]
10116d090:	00 19 81 3d	str	q0, [x8, #0x460]
10116d094:	00 15 81 3d	str	q0, [x8, #0x450]
10116d098:	00 11 81 3d	str	q0, [x8, #0x440]
10116d09c:	00 0d 81 3d	str	q0, [x8, #0x430]
10116d0a0:	00 09 81 3d	str	q0, [x8, #0x420]
10116d0a4:	00 05 81 3d	str	q0, [x8, #0x410]
10116d0a8:	00 81 1f ad	stp	q0, q0, [x8, #0x3f0]
10116d0ac:	00 81 1e ad	stp	q0, q0, [x8, #0x3d0]
10116d0b0:	00 81 1d ad	stp	q0, q0, [x8, #0x3b0]
10116d0b4:	00 81 1c ad	stp	q0, q0, [x8, #0x390]
10116d0b8:	00 81 1b ad	stp	q0, q0, [x8, #0x370]
10116d0bc:	00 81 1a ad	stp	q0, q0, [x8, #0x350]
10116d0c0:	00 81 19 ad	stp	q0, q0, [x8, #0x330]
10116d0c4:	00 81 18 ad	stp	q0, q0, [x8, #0x310]
10116d0c8:	00 81 17 ad	stp	q0, q0, [x8, #0x2f0]
10116d0cc:	00 81 16 ad	stp	q0, q0, [x8, #0x2d0]
10116d0d0:	00 81 15 ad	stp	q0, q0, [x8, #0x2b0]
10116d0d4:	00 81 14 ad	stp	q0, q0, [x8, #0x290]
10116d0d8:	00 81 13 ad	stp	q0, q0, [x8, #0x270]
10116d0dc:	00 81 12 ad	stp	q0, q0, [x8, #0x250]
10116d0e0:	00 81 11 ad	stp	q0, q0, [x8, #0x230]
10116d0e4:	00 81 10 ad	stp	q0, q0, [x8, #0x210]
10116d0e8:	00 81 80 3d	str	q0, [x8, #0x200]
10116d0ec:	08 00 80 d2	mov	x8, #0x0
10116d0f0:	fc 97 40 f9	ldr	x28, [sp, #0x128]
10116d0f4:	e9 7a 68 b8	ldr	w9, [x23, x8, lsl #2]
10116d0f8:	3f 01 00 71	cmp	w9, #0x0
10116d0fc:	0d 01 00 54	b.le	0x10116d11c
10116d100:	08 05 00 91	add	x8, x8, #0x1
10116d104:	1f 01 02 f1	cmp	x8, #0x80
10116d108:	61 ff ff 54	b.ne	0x10116d0f4
10116d10c:	e9 f3 40 b9	ldr	w9, [sp, #0xf0]
10116d110:	69 09 f8 36	tbz	w9, #0x1f, 0x10116d23c
10116d114:	e9 0f 80 52	mov	w9, #0x7f
10116d118:	05 00 00 14	b	0x10116d12c
10116d11c:	e9 f3 40 b9	ldr	w9, [sp, #0xf0]
10116d120:	e9 08 f8 36	tbz	w9, #0x1f, 0x10116d23c
10116d124:	28 ad 05 34	cbz	w8, 0x1011786c8
10116d128:	09 05 00 d1	sub	x9, x8, #0x1
10116d12c:	eb 73 56 b9	ldr	w11, [sp, #0x1670]
10116d130:	6d 05 00 51	sub	w13, w11, #0x1
10116d134:	7f 01 00 71	cmp	w11, #0x0
10116d138:	6c c1 9f 1a	csel	w12, w11, wzr, gt
10116d13c:	ab c1 98 1a	csel	w11, w13, w24, gt
10116d140:	1f 09 00 71	cmp	w8, #0x2
10116d144:	4b 05 00 54	b.lt	0x10116d1ec
10116d148:	0a 00 80 52	mov	w10, #0x0
10116d14c:	ed 07 40 91	add	x13, sp, #0x1, lsl #12
10116d150:	ad c1 11 91	add	x13, x13, #0x470
10116d154:	ee 0f 40 f9	ldr	x14, [sp, #0x18]
10116d158:	ef 03 09 2a	mov	w15, w9
10116d15c:	d0 45 40 b8	ldr	w16, [x14], #0x4
10116d160:	b1 45 40 b8	ldr	w17, [x13], #0x4
10116d164:	00 06 00 51	sub	w0, w16, #0x1
10116d168:	10 02 11 4b	sub	w16, w16, w17
10116d16c:	9f 01 10 6b	cmp	w12, w16
10116d170:	8c c1 90 1a	csel	w12, w12, w16, gt
10116d174:	0b b0 8b 1a	csel	w11, w0, w11, lt
10116d178:	4a a5 91 1a	csinc	w10, w10, w17, ge
10116d17c:	ef 05 00 f1	subs	x15, x15, #0x1
10116d180:	e1 fe ff 54	b.ne	0x10116d15c
10116d184:	1b 00 00 14	b	0x10116d1f0
10116d188:	2c f1 7d d3	lsl	x12, x9, #3
10116d18c:	ea 8b 40 f9	ldr	x10, [sp, #0x110]
10116d190:	4a 01 0c 8b	add	x10, x10, x12
10116d194:	cb 02 0c 8b	add	x11, x22, x12
10116d198:	2c 03 0c 8b	add	x12, x25, x12
10116d19c:	09 03 09 cb	sub	x9, x24, x9
10116d1a0:	a0 19 6c 1e	fdiv	d0, d13, d12
10116d1a4:	06 00 00 14	b	0x10116d1bc
10116d1a8:	42 85 00 fc	str	d2, [x10], #0x8
10116d1ac:	6b 21 00 91	add	x11, x11, #0x8
10116d1b0:	8c 21 00 91	add	x12, x12, #0x8
10116d1b4:	29 05 00 f1	subs	x9, x9, #0x1
10116d1b8:	e0 e4 ff 54	b.eq	0x10116ce54
10116d1bc:	61 01 40 fd	ldr	d1, [x11]
10116d1c0:	21 08 60 1e	fmul	d1, d1, d0
10116d1c4:	81 01 00 fd	str	d1, [x12]
10116d1c8:	23 c0 60 1e	fabs	d3, d1
10116d1cc:	02 e4 00 2f	movi	d2, #0000000000000000
10116d1d0:	84 02 67 9e	fmov	d4, x20
10116d1d4:	60 20 64 1e	fcmp	d3, d4
10116d1d8:	8d fe ff 54	b.le	0x10116d1a8
10116d1dc:	a2 19 61 1e	fdiv	d2, d13, d1
10116d1e0:	20 20 6d 1e	fcmp	d1, d13
10116d1e4:	42 bc 61 1e	fcsel	d2, d2, d1, lt
10116d1e8:	f0 ff ff 17	b	0x10116d1a8
10116d1ec:	0a 00 80 52	mov	w10, #0x0
10116d1f0:	e9 da 69 b8	ldr	w9, [x23, w9, sxtw #2]
10116d1f4:	0d 03 09 6b	subs	w13, w24, w9
10116d1f8:	ee d7 9f 1a	cset	w14, gt
10116d1fc:	9f 01 0d 6b	cmp	w12, w13
10116d200:	ec a7 9f 1a	cset	w12, lt
10116d204:	df 01 0c 6a	tst	w14, w12
10116d208:	18 13 8b 1a	csel	w24, w24, w11, ne
10116d20c:	49 05 89 1a	csinc	w9, w10, w9, eq
10116d210:	09 03 09 4b	sub	w9, w24, w9
10116d214:	3f 01 00 71	cmp	w9, #0x0
10116d218:	29 a5 89 1a	cinc	w9, w9, lt
10116d21c:	29 7d 01 13	asr	w9, w9, #1
10116d220:	ea b3 40 f9	ldr	x10, [sp, #0x160]
10116d224:	4a 01 40 f9	ldr	x10, [x10]
10116d228:	29 29 3a 9b	smaddl	x9, w9, w26, x10
10116d22c:	2a 01 40 b9	ldr	w10, [x9]
10116d230:	ea f3 00 b9	str	w10, [sp, #0xf0]
10116d234:	29 0d 40 b9	ldr	w9, [x9, #0xc]
10116d238:	e9 b7 00 b9	str	w9, [sp, #0xb4]
10116d23c:	e9 83 0d 91	add	x9, sp, #0x360
10116d240:	e0 e7 07 6f	movi.2d	v0, #0xffffffffffffffff
10116d244:	20 c5 83 3d	str	q0, [x9, #0xf10]
10116d248:	20 c9 83 3d	str	q0, [x9, #0xf20]
10116d24c:	20 cd 83 3d	str	q0, [x9, #0xf30]
10116d250:	20 d1 83 3d	str	q0, [x9, #0xf40]
10116d254:	20 d5 83 3d	str	q0, [x9, #0xf50]
10116d258:	20 d9 83 3d	str	q0, [x9, #0xf60]
10116d25c:	20 dd 83 3d	str	q0, [x9, #0xf70]
10116d260:	20 e1 83 3d	str	q0, [x9, #0xf80]
10116d264:	20 e5 83 3d	str	q0, [x9, #0xf90]
10116d268:	20 e9 83 3d	str	q0, [x9, #0xfa0]
10116d26c:	20 ed 83 3d	str	q0, [x9, #0xfb0]
10116d270:	20 f1 83 3d	str	q0, [x9, #0xfc0]
10116d274:	20 f5 83 3d	str	q0, [x9, #0xfd0]
10116d278:	20 f9 83 3d	str	q0, [x9, #0xfe0]
10116d27c:	20 fd 83 3d	str	q0, [x9, #0xff0]
10116d280:	20 01 84 3d	str	q0, [x9, #0x1000]
10116d284:	20 05 84 3d	str	q0, [x9, #0x1010]
10116d288:	20 09 84 3d	str	q0, [x9, #0x1020]
10116d28c:	20 0d 84 3d	str	q0, [x9, #0x1030]
10116d290:	20 11 84 3d	str	q0, [x9, #0x1040]
10116d294:	20 15 84 3d	str	q0, [x9, #0x1050]
10116d298:	20 19 84 3d	str	q0, [x9, #0x1060]
10116d29c:	20 1d 84 3d	str	q0, [x9, #0x1070]
10116d2a0:	20 21 84 3d	str	q0, [x9, #0x1080]
10116d2a4:	20 25 84 3d	str	q0, [x9, #0x1090]
10116d2a8:	20 29 84 3d	str	q0, [x9, #0x10a0]
10116d2ac:	20 2d 84 3d	str	q0, [x9, #0x10b0]
10116d2b0:	20 31 84 3d	str	q0, [x9, #0x10c0]
10116d2b4:	20 35 84 3d	str	q0, [x9, #0x10d0]
10116d2b8:	20 39 84 3d	str	q0, [x9, #0x10e0]
10116d2bc:	20 3d 84 3d	str	q0, [x9, #0x10f0]
10116d2c0:	20 41 84 3d	str	q0, [x9, #0x1100]
10116d2c4:	20 c1 83 3d	str	q0, [x9, #0xf00]
10116d2c8:	20 bd 83 3d	str	q0, [x9, #0xef0]
10116d2cc:	20 b9 83 3d	str	q0, [x9, #0xee0]
10116d2d0:	20 b5 83 3d	str	q0, [x9, #0xed0]
10116d2d4:	20 b1 83 3d	str	q0, [x9, #0xec0]
10116d2d8:	20 ad 83 3d	str	q0, [x9, #0xeb0]
10116d2dc:	20 a9 83 3d	str	q0, [x9, #0xea0]
10116d2e0:	20 a5 83 3d	str	q0, [x9, #0xe90]
10116d2e4:	20 a1 83 3d	str	q0, [x9, #0xe80]
10116d2e8:	20 9d 83 3d	str	q0, [x9, #0xe70]
10116d2ec:	20 99 83 3d	str	q0, [x9, #0xe60]
10116d2f0:	20 95 83 3d	str	q0, [x9, #0xe50]
10116d2f4:	20 91 83 3d	str	q0, [x9, #0xe40]
10116d2f8:	20 8d 83 3d	str	q0, [x9, #0xe30]
10116d2fc:	20 89 83 3d	str	q0, [x9, #0xe20]
10116d300:	20 85 83 3d	str	q0, [x9, #0xe10]
10116d304:	20 81 83 3d	str	q0, [x9, #0xe00]
10116d308:	20 7d 83 3d	str	q0, [x9, #0xdf0]
10116d30c:	20 79 83 3d	str	q0, [x9, #0xde0]
10116d310:	20 75 83 3d	str	q0, [x9, #0xdd0]
10116d314:	20 71 83 3d	str	q0, [x9, #0xdc0]
10116d318:	20 6d 83 3d	str	q0, [x9, #0xdb0]
10116d31c:	20 69 83 3d	str	q0, [x9, #0xda0]
10116d320:	20 65 83 3d	str	q0, [x9, #0xd90]
10116d324:	20 61 83 3d	str	q0, [x9, #0xd80]
10116d328:	20 5d 83 3d	str	q0, [x9, #0xd70]
10116d32c:	20 59 83 3d	str	q0, [x9, #0xd60]
10116d330:	20 55 83 3d	str	q0, [x9, #0xd50]
10116d334:	20 51 83 3d	str	q0, [x9, #0xd40]
10116d338:	20 4d 83 3d	str	q0, [x9, #0xd30]
10116d33c:	20 49 83 3d	str	q0, [x9, #0xd20]
10116d340:	20 45 83 3d	str	q0, [x9, #0xd10]
10116d344:	20 41 83 3d	str	q0, [x9, #0xd00]
10116d348:	20 3d 83 3d	str	q0, [x9, #0xcf0]
10116d34c:	20 39 83 3d	str	q0, [x9, #0xce0]
10116d350:	20 35 83 3d	str	q0, [x9, #0xcd0]
10116d354:	20 31 83 3d	str	q0, [x9, #0xcc0]
10116d358:	20 2d 83 3d	str	q0, [x9, #0xcb0]
10116d35c:	20 29 83 3d	str	q0, [x9, #0xca0]
10116d360:	20 25 83 3d	str	q0, [x9, #0xc90]
10116d364:	20 21 83 3d	str	q0, [x9, #0xc80]
10116d368:	20 1d 83 3d	str	q0, [x9, #0xc70]
10116d36c:	20 19 83 3d	str	q0, [x9, #0xc60]
10116d370:	20 15 83 3d	str	q0, [x9, #0xc50]
10116d374:	20 11 83 3d	str	q0, [x9, #0xc40]
10116d378:	20 0d 83 3d	str	q0, [x9, #0xc30]
10116d37c:	20 09 83 3d	str	q0, [x9, #0xc20]
10116d380:	20 05 83 3d	str	q0, [x9, #0xc10]
10116d384:	20 01 83 3d	str	q0, [x9, #0xc00]
10116d388:	20 fd 82 3d	str	q0, [x9, #0xbf0]
10116d38c:	20 f9 82 3d	str	q0, [x9, #0xbe0]
10116d390:	20 f5 82 3d	str	q0, [x9, #0xbd0]
10116d394:	20 f1 82 3d	str	q0, [x9, #0xbc0]
10116d398:	20 ed 82 3d	str	q0, [x9, #0xbb0]
10116d39c:	20 e9 82 3d	str	q0, [x9, #0xba0]
10116d3a0:	20 e5 82 3d	str	q0, [x9, #0xb90]
10116d3a4:	20 e1 82 3d	str	q0, [x9, #0xb80]
10116d3a8:	20 dd 82 3d	str	q0, [x9, #0xb70]
10116d3ac:	20 d9 82 3d	str	q0, [x9, #0xb60]
10116d3b0:	20 d5 82 3d	str	q0, [x9, #0xb50]
10116d3b4:	20 d1 82 3d	str	q0, [x9, #0xb40]
10116d3b8:	20 cd 82 3d	str	q0, [x9, #0xb30]
10116d3bc:	20 c9 82 3d	str	q0, [x9, #0xb20]
10116d3c0:	20 c5 82 3d	str	q0, [x9, #0xb10]
10116d3c4:	20 c1 82 3d	str	q0, [x9, #0xb00]
10116d3c8:	20 bd 82 3d	str	q0, [x9, #0xaf0]
10116d3cc:	20 b9 82 3d	str	q0, [x9, #0xae0]
10116d3d0:	20 b5 82 3d	str	q0, [x9, #0xad0]
10116d3d4:	20 b1 82 3d	str	q0, [x9, #0xac0]
10116d3d8:	20 ad 82 3d	str	q0, [x9, #0xab0]
10116d3dc:	20 a9 82 3d	str	q0, [x9, #0xaa0]
10116d3e0:	20 a5 82 3d	str	q0, [x9, #0xa90]
10116d3e4:	20 a1 82 3d	str	q0, [x9, #0xa80]
10116d3e8:	20 9d 82 3d	str	q0, [x9, #0xa70]
10116d3ec:	20 99 82 3d	str	q0, [x9, #0xa60]
10116d3f0:	20 95 82 3d	str	q0, [x9, #0xa50]
10116d3f4:	20 91 82 3d	str	q0, [x9, #0xa40]
10116d3f8:	20 8d 82 3d	str	q0, [x9, #0xa30]
10116d3fc:	20 89 82 3d	str	q0, [x9, #0xa20]
10116d400:	20 85 82 3d	str	q0, [x9, #0xa10]
10116d404:	20 81 82 3d	str	q0, [x9, #0xa00]
10116d408:	20 7d 82 3d	str	q0, [x9, #0x9f0]
10116d40c:	20 79 82 3d	str	q0, [x9, #0x9e0]
10116d410:	20 75 82 3d	str	q0, [x9, #0x9d0]
10116d414:	20 71 82 3d	str	q0, [x9, #0x9c0]
10116d418:	20 6d 82 3d	str	q0, [x9, #0x9b0]
10116d41c:	20 69 82 3d	str	q0, [x9, #0x9a0]
10116d420:	20 65 82 3d	str	q0, [x9, #0x990]
10116d424:	20 61 82 3d	str	q0, [x9, #0x980]
10116d428:	20 5d 82 3d	str	q0, [x9, #0x970]
10116d42c:	20 59 82 3d	str	q0, [x9, #0x960]
10116d430:	20 55 82 3d	str	q0, [x9, #0x950]
10116d434:	20 51 82 3d	str	q0, [x9, #0x940]
10116d438:	20 4d 82 3d	str	q0, [x9, #0x930]
10116d43c:	20 49 82 3d	str	q0, [x9, #0x920]
10116d440:	20 45 82 3d	str	q0, [x9, #0x910]
10116d444:	20 39 82 3d	str	q0, [x9, #0x8e0]
10116d448:	20 35 82 3d	str	q0, [x9, #0x8d0]
10116d44c:	20 31 82 3d	str	q0, [x9, #0x8c0]
10116d450:	20 2d 82 3d	str	q0, [x9, #0x8b0]
10116d454:	20 29 82 3d	str	q0, [x9, #0x8a0]
10116d458:	20 25 82 3d	str	q0, [x9, #0x890]
10116d45c:	20 21 82 3d	str	q0, [x9, #0x880]
10116d460:	20 1d 82 3d	str	q0, [x9, #0x870]
10116d464:	20 19 82 3d	str	q0, [x9, #0x860]
10116d468:	20 15 82 3d	str	q0, [x9, #0x850]
10116d46c:	20 11 82 3d	str	q0, [x9, #0x840]
10116d470:	20 0d 82 3d	str	q0, [x9, #0x830]
10116d474:	20 09 82 3d	str	q0, [x9, #0x820]
10116d478:	20 05 82 3d	str	q0, [x9, #0x810]
10116d47c:	20 01 82 3d	str	q0, [x9, #0x800]
10116d480:	20 fd 81 3d	str	q0, [x9, #0x7f0]
10116d484:	20 f9 81 3d	str	q0, [x9, #0x7e0]
10116d488:	20 f5 81 3d	str	q0, [x9, #0x7d0]
10116d48c:	20 f1 81 3d	str	q0, [x9, #0x7c0]
10116d490:	20 ed 81 3d	str	q0, [x9, #0x7b0]
10116d494:	20 e9 81 3d	str	q0, [x9, #0x7a0]
10116d498:	20 e5 81 3d	str	q0, [x9, #0x790]
10116d49c:	20 e1 81 3d	str	q0, [x9, #0x780]
10116d4a0:	20 dd 81 3d	str	q0, [x9, #0x770]
10116d4a4:	20 d9 81 3d	str	q0, [x9, #0x760]
10116d4a8:	20 d5 81 3d	str	q0, [x9, #0x750]
10116d4ac:	20 d1 81 3d	str	q0, [x9, #0x740]
10116d4b0:	20 cd 81 3d	str	q0, [x9, #0x730]
10116d4b4:	20 c9 81 3d	str	q0, [x9, #0x720]
10116d4b8:	20 c5 81 3d	str	q0, [x9, #0x710]
10116d4bc:	20 c1 81 3d	str	q0, [x9, #0x700]
10116d4c0:	20 bd 81 3d	str	q0, [x9, #0x6f0]
10116d4c4:	20 b9 81 3d	str	q0, [x9, #0x6e0]
10116d4c8:	20 b5 81 3d	str	q0, [x9, #0x6d0]
10116d4cc:	20 b1 81 3d	str	q0, [x9, #0x6c0]
10116d4d0:	20 ad 81 3d	str	q0, [x9, #0x6b0]
10116d4d4:	20 a9 81 3d	str	q0, [x9, #0x6a0]
10116d4d8:	20 a5 81 3d	str	q0, [x9, #0x690]
10116d4dc:	20 a1 81 3d	str	q0, [x9, #0x680]
10116d4e0:	20 9d 81 3d	str	q0, [x9, #0x670]
10116d4e4:	20 99 81 3d	str	q0, [x9, #0x660]
10116d4e8:	20 95 81 3d	str	q0, [x9, #0x650]
10116d4ec:	20 91 81 3d	str	q0, [x9, #0x640]
10116d4f0:	20 8d 81 3d	str	q0, [x9, #0x630]
10116d4f4:	20 89 81 3d	str	q0, [x9, #0x620]
10116d4f8:	20 85 81 3d	str	q0, [x9, #0x610]
10116d4fc:	20 81 81 3d	str	q0, [x9, #0x600]
10116d500:	20 7d 81 3d	str	q0, [x9, #0x5f0]
10116d504:	20 79 81 3d	str	q0, [x9, #0x5e0]
10116d508:	20 75 81 3d	str	q0, [x9, #0x5d0]
10116d50c:	20 71 81 3d	str	q0, [x9, #0x5c0]
10116d510:	20 6d 81 3d	str	q0, [x9, #0x5b0]
10116d514:	20 69 81 3d	str	q0, [x9, #0x5a0]
10116d518:	20 65 81 3d	str	q0, [x9, #0x590]
10116d51c:	20 61 81 3d	str	q0, [x9, #0x580]
10116d520:	20 5d 81 3d	str	q0, [x9, #0x570]
10116d524:	20 59 81 3d	str	q0, [x9, #0x560]
10116d528:	20 55 81 3d	str	q0, [x9, #0x550]
10116d52c:	20 51 81 3d	str	q0, [x9, #0x540]
10116d530:	20 4d 81 3d	str	q0, [x9, #0x530]
10116d534:	20 49 81 3d	str	q0, [x9, #0x520]
10116d538:	20 45 81 3d	str	q0, [x9, #0x510]
10116d53c:	20 41 81 3d	str	q0, [x9, #0x500]
10116d540:	20 3d 81 3d	str	q0, [x9, #0x4f0]
10116d544:	20 39 81 3d	str	q0, [x9, #0x4e0]
10116d548:	20 35 81 3d	str	q0, [x9, #0x4d0]
10116d54c:	20 31 81 3d	str	q0, [x9, #0x4c0]
10116d550:	20 2d 81 3d	str	q0, [x9, #0x4b0]
10116d554:	20 29 81 3d	str	q0, [x9, #0x4a0]
10116d558:	20 25 81 3d	str	q0, [x9, #0x490]
10116d55c:	20 21 81 3d	str	q0, [x9, #0x480]
10116d560:	20 1d 81 3d	str	q0, [x9, #0x470]
10116d564:	20 19 81 3d	str	q0, [x9, #0x460]
10116d568:	20 15 81 3d	str	q0, [x9, #0x450]
10116d56c:	20 11 81 3d	str	q0, [x9, #0x440]
10116d570:	20 0d 81 3d	str	q0, [x9, #0x430]
10116d574:	20 09 81 3d	str	q0, [x9, #0x420]
10116d578:	20 05 81 3d	str	q0, [x9, #0x410]
10116d57c:	20 81 1f ad	stp	q0, q0, [x9, #0x3f0]
10116d580:	20 81 1e ad	stp	q0, q0, [x9, #0x3d0]
10116d584:	20 81 1d ad	stp	q0, q0, [x9, #0x3b0]
10116d588:	20 81 1c ad	stp	q0, q0, [x9, #0x390]
10116d58c:	20 81 1b ad	stp	q0, q0, [x9, #0x370]
10116d590:	20 81 1a ad	stp	q0, q0, [x9, #0x350]
10116d594:	20 81 19 ad	stp	q0, q0, [x9, #0x330]
10116d598:	20 81 18 ad	stp	q0, q0, [x9, #0x310]
10116d59c:	20 81 17 ad	stp	q0, q0, [x9, #0x2f0]
10116d5a0:	20 81 16 ad	stp	q0, q0, [x9, #0x2d0]
10116d5a4:	20 81 15 ad	stp	q0, q0, [x9, #0x2b0]
10116d5a8:	20 81 14 ad	stp	q0, q0, [x9, #0x290]
10116d5ac:	20 81 13 ad	stp	q0, q0, [x9, #0x270]
10116d5b0:	20 81 12 ad	stp	q0, q0, [x9, #0x250]
10116d5b4:	20 81 11 ad	stp	q0, q0, [x9, #0x230]
10116d5b8:	20 81 10 ad	stp	q0, q0, [x9, #0x210]
10116d5bc:	20 81 0f ad	stp	q0, q0, [x9, #0x1f0]
10116d5c0:	20 81 0e ad	stp	q0, q0, [x9, #0x1d0]
10116d5c4:	20 81 0d ad	stp	q0, q0, [x9, #0x1b0]
10116d5c8:	20 81 0c ad	stp	q0, q0, [x9, #0x190]
10116d5cc:	20 81 0b ad	stp	q0, q0, [x9, #0x170]
10116d5d0:	20 81 0a ad	stp	q0, q0, [x9, #0x150]
10116d5d4:	20 81 09 ad	stp	q0, q0, [x9, #0x130]
10116d5d8:	20 81 08 ad	stp	q0, q0, [x9, #0x110]
10116d5dc:	20 81 07 ad	stp	q0, q0, [x9, #0xf0]
10116d5e0:	f6 07 40 91	add	x22, sp, #0x1, lsl #12
10116d5e4:	d6 c2 19 91	add	x22, x22, #0x670
10116d5e8:	5a b8 9e d2	mov	x26, #0xf5c2
10116d5ec:	1a 85 ab f2	movk	x26, #0x5c28, lsl #16
10116d5f0:	fa 51 d8 f2	movk	x26, #0xc28f, lsl #32
10116d5f4:	5a ff e7 f2	movk	x26, #0x3ffa, lsl #48
10116d5f8:	08 84 05 34	cbz	w8, 0x101178678
10116d5fc:	09 00 80 d2	mov	x9, #0x0
10116d600:	fe 03 08 2a	mov	w30, w8
10116d604:	2a 23 00 d1	sub	x10, x25, #0x8
10116d608:	e1 07 40 91	add	x1, sp, #0x1, lsl #12
10116d60c:	21 c0 01 91	add	x1, x1, #0x70
10116d610:	e2 07 40 91	add	x2, sp, #0x1, lsl #12
10116d614:	42 c0 09 91	add	x2, x2, #0x270
10116d618:	e3 c3 31 91	add	x3, sp, #0xc70
10116d61c:	e4 c3 39 91	add	x4, sp, #0xe70
10116d620:	e5 43 21 91	add	x5, sp, #0x850
10116d624:	e6 43 29 91	add	x6, sp, #0xa50
10116d628:	e7 43 11 91	add	x7, sp, #0x450
10116d62c:	f3 43 19 91	add	x19, sp, #0x650
10116d630:	f4 7a 94 d2	mov	x20, #0xa3d7
10116d634:	14 ae a7 f2	movk	x20, #0x3d70, lsl #16
10116d638:	54 e1 da f2	movk	x20, #0xd70a, lsl #32
10116d63c:	34 fc e7 f2	movk	x20, #0x3fe1, lsl #48
10116d640:	55 0a 97 d2	mov	x21, #0xb852
10116d644:	d5 a3 b0 f2	movk	x21, #0x851e, lsl #16
10116d648:	75 3d ca f2	movk	x21, #0x51eb, lsl #32
10116d64c:	95 fb e7 f2	movk	x21, #0x3fdc, lsl #48
10116d650:	38 f9 85 d2	mov	x24, #0x2fc9
10116d654:	d8 92 bf f2	movk	x24, #0xfc96, lsl #16
10116d658:	58 2c d9 f2	movk	x24, #0xc962, lsl #32
10116d65c:	f8 fc e7 f2	movk	x24, #0x3fe7, lsl #48
10116d660:	39 5c 8f d2	mov	x25, #0x7ae1
10116d664:	99 c2 b5 f2	movk	x25, #0xae14, lsl #16
10116d668:	f9 28 dc f2	movk	x25, #0xe147, lsl #32
10116d66c:	59 fc e7 f2	movk	x25, #0x3fe2, lsl #48
10116d670:	05 00 00 14	b	0x10116d684
10116d674:	4e 78 29 b8	str	w14, [x2, x9, lsl #2]
10116d678:	29 05 00 91	add	x9, x9, #0x1
10116d67c:	3f 01 1e eb	cmp	x9, x30
10116d680:	60 13 00 54	b.eq	0x10116d8ec
10116d684:	2b f5 7e d3	lsl	x11, x9, #2
10116d688:	cc 6a ab b8	ldrsw	x12, [x22, x11]
10116d68c:	ed 6a ab b8	ldrsw	x13, [x23, x11]
10116d690:	9f 01 0d 6b	cmp	w12, w13
10116d694:	2c ff ff 54	b.gt	0x10116d678
10116d698:	4e 78 69 b8	ldr	w14, [x2, x9, lsl #2]
10116d69c:	8f 05 00 51	sub	w15, w12, #0x1
10116d6a0:	50 0d 0c 8b	add	x16, x10, x12, lsl #3
10116d6a4:	07 00 00 14	b	0x10116d6c0
10116d6a8:	2f 78 29 b8	str	w15, [x1, x9, lsl #2]
10116d6ac:	8c 05 00 91	add	x12, x12, #0x1
10116d6b0:	ef 05 00 11	add	w15, w15, #0x1
10116d6b4:	10 22 00 91	add	x16, x16, #0x8
10116d6b8:	bf 01 0f 6b	cmp	w13, w15
10116d6bc:	c0 fd ff 54	b.eq	0x10116d674
10116d6c0:	00 06 40 fd	ldr	d0, [x16, #0x8]
10116d6c4:	81 02 67 9e	fmov	d1, x20
10116d6c8:	00 20 61 1e	fcmp	d0, d1
10116d6cc:	a1 02 67 9e	fmov	d1, x21
10116d6d0:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
10116d6d4:	8c 09 00 54	b.gt	0x10116d804
10116d6d8:	4e 01 f8 37	tbnz	w14, #0x1f, 0x10116d700
10116d6dc:	31 78 69 b8	ldr	w17, [x1, x9, lsl #2]
10116d6e0:	3f 06 00 31	cmn	w17, #0x1
10116d6e4:	e1 00 00 54	b.ne	0x10116d700
10116d6e8:	01 02 40 fd	ldr	d1, [x16]
10116d6ec:	82 02 67 9e	fmov	d2, x20
10116d6f0:	20 20 62 1e	fcmp	d1, d2
10116d6f4:	a2 02 67 9e	fmov	d2, x21
10116d6f8:	24 b4 62 1e	fccmp	d1, d2, #0x4, lt
10116d6fc:	6c fd ff 54	b.gt	0x10116d6a8
10116d700:	91 78 69 b8	ldr	w17, [x4, x9, lsl #2]
10116d704:	01 03 67 9e	fmov	d1, x24
10116d708:	00 20 61 1e	fcmp	d0, d1
10116d70c:	21 03 67 9e	fmov	d1, x25
10116d710:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
10116d714:	cc 08 00 54	b.gt	0x10116d82c
10116d718:	51 01 f8 37	tbnz	w17, #0x1f, 0x10116d740
10116d71c:	71 78 69 b8	ldr	w17, [x3, x9, lsl #2]
10116d720:	3f 06 00 31	cmn	w17, #0x1
10116d724:	e1 00 00 54	b.ne	0x10116d740
10116d728:	01 02 40 fd	ldr	d1, [x16]
10116d72c:	02 03 67 9e	fmov	d2, x24
10116d730:	20 20 62 1e	fcmp	d1, d2
10116d734:	22 03 67 9e	fmov	d2, x25
10116d738:	24 b4 62 1e	fccmp	d1, d2, #0x4, lt
10116d73c:	ac 0b 00 54	b.gt	0x10116d8b0
10116d740:	d1 78 69 b8	ldr	w17, [x6, x9, lsl #2]
10116d744:	41 03 67 9e	fmov	d1, x26
10116d748:	00 20 61 1e	fcmp	d0, d1
10116d74c:	c0 47 81 d2	mov	x0, #0xa3e
10116d750:	e0 7a b4 f2	movk	x0, #0xa3d7, lsl #16
10116d754:	00 ae c7 f2	movk	x0, #0x3d70, lsl #32
10116d758:	a0 fe e7 f2	movk	x0, #0x3ff5, lsl #48
10116d75c:	01 00 67 9e	fmov	d1, x0
10116d760:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
10116d764:	ac 07 00 54	b.gt	0x10116d858
10116d768:	91 00 f8 37	tbnz	w17, #0x1f, 0x10116d778
10116d76c:	b1 78 69 b8	ldr	w17, [x5, x9, lsl #2]
10116d770:	3f 06 00 31	cmn	w17, #0x1
10116d774:	20 0a 00 54	b.eq	0x10116d8b8
10116d778:	71 7a 69 b8	ldr	w17, [x19, x9, lsl #2]
10116d77c:	e0 7a 94 d2	mov	x0, #0xa3d7
10116d780:	00 ae a7 f2	movk	x0, #0x3d70, lsl #16
10116d784:	40 e1 da f2	movk	x0, #0xd70a, lsl #32
10116d788:	20 00 e8 f2	movk	x0, #0x4001, lsl #48
10116d78c:	01 00 67 9e	fmov	d1, x0
10116d790:	00 20 61 1e	fcmp	d0, d1
10116d794:	40 0a 97 d2	mov	x0, #0xb852
10116d798:	c0 a3 b0 f2	movk	x0, #0x851e, lsl #16
10116d79c:	60 3d ca f2	movk	x0, #0x51eb, lsl #32
10116d7a0:	80 ff e7 f2	movk	x0, #0x3ffc, lsl #48
10116d7a4:	01 00 67 9e	fmov	d1, x0
10116d7a8:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
10116d7ac:	cc 06 00 54	b.gt	0x10116d884
10116d7b0:	f1 f7 ff 37	tbnz	w17, #0x1f, 0x10116d6ac
10116d7b4:	f1 78 69 b8	ldr	w17, [x7, x9, lsl #2]
10116d7b8:	3f 06 00 31	cmn	w17, #0x1
10116d7bc:	81 f7 ff 54	b.ne	0x10116d6ac
10116d7c0:	00 02 40 fd	ldr	d0, [x16]
10116d7c4:	f1 7a 94 d2	mov	x17, #0xa3d7
10116d7c8:	11 ae a7 f2	movk	x17, #0x3d70, lsl #16
10116d7cc:	51 e1 da f2	movk	x17, #0xd70a, lsl #32
10116d7d0:	31 00 e8 f2	movk	x17, #0x4001, lsl #48
10116d7d4:	21 02 67 9e	fmov	d1, x17
10116d7d8:	00 20 61 1e	fcmp	d0, d1
10116d7dc:	8a f6 ff 54	b.ge	0x10116d6ac
10116d7e0:	51 0a 97 d2	mov	x17, #0xb852
10116d7e4:	d1 a3 b0 f2	movk	x17, #0x851e, lsl #16
10116d7e8:	71 3d ca f2	movk	x17, #0x51eb, lsl #32
10116d7ec:	91 ff e7 f2	movk	x17, #0x3ffc, lsl #48
10116d7f0:	21 02 67 9e	fmov	d1, x17
10116d7f4:	00 20 61 1e	fcmp	d0, d1
10116d7f8:	ad f5 ff 54	b.le	0x10116d6ac
10116d7fc:	ef 78 29 b8	str	w15, [x7, x9, lsl #2]
10116d800:	ab ff ff 17	b	0x10116d6ac
10116d804:	df 05 00 31	cmn	w14, #0x1
10116d808:	ce 15 8f 1a	csinc	w14, w14, w15, ne
10116d80c:	9f 01 0d eb	cmp	x12, x13
10116d810:	eb f4 ff 54	b.lt	0x10116d6ac
10116d814:	f1 05 00 11	add	w17, w15, #0x1
10116d818:	20 68 6b b8	ldr	w0, [x1, x11]
10116d81c:	1f 04 00 31	cmn	w0, #0x1
10116d820:	31 02 80 1a	csel	w17, w17, w0, eq
10116d824:	31 68 2b b8	str	w17, [x1, x11]
10116d828:	a1 ff ff 17	b	0x10116d6ac
10116d82c:	3f 06 00 31	cmn	w17, #0x1
10116d830:	31 16 8f 1a	csinc	w17, w17, w15, ne
10116d834:	91 78 29 b8	str	w17, [x4, x9, lsl #2]
10116d838:	9f 01 0d eb	cmp	x12, x13
10116d83c:	8b f3 ff 54	b.lt	0x10116d6ac
10116d840:	f1 05 00 11	add	w17, w15, #0x1
10116d844:	60 68 6b b8	ldr	w0, [x3, x11]
10116d848:	1f 04 00 31	cmn	w0, #0x1
10116d84c:	31 02 80 1a	csel	w17, w17, w0, eq
10116d850:	71 68 2b b8	str	w17, [x3, x11]
10116d854:	96 ff ff 17	b	0x10116d6ac
10116d858:	3f 06 00 31	cmn	w17, #0x1
10116d85c:	31 16 8f 1a	csinc	w17, w17, w15, ne
10116d860:	d1 78 29 b8	str	w17, [x6, x9, lsl #2]
10116d864:	9f 01 0d eb	cmp	x12, x13
10116d868:	2b f2 ff 54	b.lt	0x10116d6ac
10116d86c:	f1 05 00 11	add	w17, w15, #0x1
10116d870:	a0 68 6b b8	ldr	w0, [x5, x11]
10116d874:	1f 04 00 31	cmn	w0, #0x1
10116d878:	31 02 80 1a	csel	w17, w17, w0, eq
10116d87c:	b1 68 2b b8	str	w17, [x5, x11]
10116d880:	8b ff ff 17	b	0x10116d6ac
10116d884:	3f 06 00 31	cmn	w17, #0x1
10116d888:	31 16 8f 1a	csinc	w17, w17, w15, ne
10116d88c:	71 7a 29 b8	str	w17, [x19, x9, lsl #2]
10116d890:	9f 01 0d eb	cmp	x12, x13
10116d894:	cb f0 ff 54	b.lt	0x10116d6ac
10116d898:	f1 05 00 11	add	w17, w15, #0x1
10116d89c:	e0 68 6b b8	ldr	w0, [x7, x11]
10116d8a0:	1f 04 00 31	cmn	w0, #0x1
10116d8a4:	31 02 80 1a	csel	w17, w17, w0, eq
10116d8a8:	f1 68 2b b8	str	w17, [x7, x11]
10116d8ac:	80 ff ff 17	b	0x10116d6ac
10116d8b0:	6f 78 29 b8	str	w15, [x3, x9, lsl #2]
10116d8b4:	7e ff ff 17	b	0x10116d6ac
10116d8b8:	01 02 40 fd	ldr	d1, [x16]
10116d8bc:	42 03 67 9e	fmov	d2, x26
10116d8c0:	20 20 62 1e	fcmp	d1, d2
10116d8c4:	aa f5 ff 54	b.ge	0x10116d778
10116d8c8:	d1 47 81 d2	mov	x17, #0xa3e
10116d8cc:	f1 7a b4 f2	movk	x17, #0xa3d7, lsl #16
10116d8d0:	11 ae c7 f2	movk	x17, #0x3d70, lsl #32
10116d8d4:	b1 fe e7 f2	movk	x17, #0x3ff5, lsl #48
10116d8d8:	22 02 67 9e	fmov	d2, x17
10116d8dc:	20 20 62 1e	fcmp	d1, d2
10116d8e0:	cd f4 ff 54	b.le	0x10116d778
10116d8e4:	af 78 29 b8	str	w15, [x5, x9, lsl #2]
10116d8e8:	71 ff ff 17	b	0x10116d6ac
10116d8ec:	1f 05 00 71	cmp	w8, #0x1
10116d8f0:	f9 9b 40 f9	ldr	x25, [sp, #0x130]
10116d8f4:	4b 6c 05 54	b.lt	0x10117867c
10116d8f8:	88 3f 95 d2	mov	x8, #0xa9fc
10116d8fc:	28 5e ba f2	movk	x8, #0xd2f1, lsl #16
10116d900:	a8 49 cc f2	movk	x8, #0x624d, lsl #32
10116d904:	08 ea e7 f2	movk	x8, #0x3f50, lsl #48
10116d908:	00 01 67 9e	fmov	d0, x8
10116d90c:	80 09 60 1e	fmul	d0, d12, d0
10116d910:	e0 7f 00 fd	str	d0, [sp, #0xf8]
10116d914:	88 3f 95 d2	mov	x8, #0xa9fc
10116d918:	28 5e ba f2	movk	x8, #0xd2f1, lsl #16
10116d91c:	a8 49 cc f2	movk	x8, #0x624d, lsl #32
10116d920:	08 e6 e7 f2	movk	x8, #0x3f30, lsl #48
10116d924:	00 01 67 9e	fmov	d0, x8
10116d928:	89 09 60 1e	fmul	d9, d12, d0
10116d92c:	88 3f 95 d2	mov	x8, #0xa9fc
10116d930:	28 5e ba f2	movk	x8, #0xd2f1, lsl #16
10116d934:	a8 49 cc f2	movk	x8, #0x624d, lsl #32
10116d938:	08 ec e7 f2	movk	x8, #0x3f60, lsl #48
10116d93c:	00 01 67 9e	fmov	d0, x8
10116d940:	80 09 60 1e	fmul	d0, d12, d0
10116d944:	e0 5f 00 fd	str	d0, [sp, #0xb8]
10116d948:	48 df 8f d2	mov	x8, #0x7efa
10116d94c:	48 8d b7 f2	movk	x8, #0xbc6a, lsl #16
10116d950:	88 6e d2 f2	movk	x8, #0x9374, lsl #32
10116d954:	08 ed e7 f2	movk	x8, #0x3f68, lsl #48
10116d958:	00 01 67 9e	fmov	d0, x8
10116d95c:	80 09 60 1e	fmul	d0, d12, d0
10116d960:	e0 3f 00 fd	str	d0, [sp, #0x78]
10116d964:	f4 8b 40 f9	ldr	x20, [sp, #0x110]
10116d968:	88 82 00 91	add	x8, x20, #0x20
10116d96c:	e8 57 00 f9	str	x8, [sp, #0xa8]
10116d970:	e7 af 40 f9	ldr	x7, [sp, #0x158]
10116d974:	ac 19 6c 1e	fdiv	d12, d13, d12
10116d978:	f3 03 1e aa	mov	x19, x30
10116d97c:	05 00 00 14	b	0x10116d990
10116d980:	f6 07 40 91	add	x22, sp, #0x1, lsl #12
10116d984:	d6 c2 19 91	add	x22, x22, #0x670
10116d988:	1f 07 00 f1	cmp	x24, #0x1
10116d98c:	ad 67 05 54	b.le	0x101178680
10116d990:	f8 03 13 aa	mov	x24, x19
10116d994:	73 06 00 d1	sub	x19, x19, #0x1
10116d998:	69 f6 7e d3	lsl	x9, x19, #2
10116d99c:	e8 02 09 8b	add	x8, x23, x9
10116d9a0:	e8 a3 00 f9	str	x8, [sp, #0x140]
10116d9a4:	08 01 40 b9	ldr	w8, [x8]
10116d9a8:	e9 93 00 f9	str	x9, [sp, #0x120]
10116d9ac:	da 6a 69 b8	ldr	w26, [x22, x9]
10116d9b0:	09 01 1a 4b	sub	w9, w8, w26
10116d9b4:	3f 05 00 71	cmp	w9, #0x1
10116d9b8:	8b fe ff 54	b.lt	0x10116d988
10116d9bc:	ea 03 1a aa	mov	x10, x26
10116d9c0:	4f 7d 40 93	sxtw	x15, w10
10116d9c4:	3f 21 00 71	cmp	w9, #0x8
10116d9c8:	f3 af 00 f9	str	x19, [sp, #0x158]
10116d9cc:	42 01 00 54	b.hs	0x10116d9f4
10116d9d0:	00 e4 00 2f	movi	d0, #0000000000000000
10116d9d4:	01 e4 00 2f	movi	d1, #0000000000000000
10116d9d8:	1f 01 1a 6b	cmp	w8, w26
10116d9dc:	4b 92 00 54	b.lt	0x10116ec24
10116d9e0:	3f 1d 00 71	cmp	w9, #0x7
10116d9e4:	22 8e 00 54	b.hs	0x10116eba8
10116d9e8:	01 e4 00 2f	movi	d1, #0000000000000000
10116d9ec:	ea 03 0f aa	mov	x10, x15
10116d9f0:	86 04 00 14	b	0x10116ec08
10116d9f4:	0a 01 1a 6b	subs	w10, w8, w26
10116d9f8:	0a 02 00 54	b.ge	0x10116da38
10116d9fc:	2a 05 00 11	add	w10, w9, #0x1
10116da00:	41 01 62 1e	scvtf	d1, w10
10116da04:	00 e4 00 2f	movi	d0, #0000000000000000
10116da08:	02 e4 00 2f	movi	d2, #0000000000000000
10116da0c:	e1 07 40 91	add	x1, sp, #0x1, lsl #12
10116da10:	21 c0 01 91	add	x1, x1, #0x70
10116da14:	e2 07 40 91	add	x2, sp, #0x1, lsl #12
10116da18:	42 c0 09 91	add	x2, x2, #0x270
10116da1c:	e3 c3 31 91	add	x3, sp, #0xc70
10116da20:	e4 c3 39 91	add	x4, sp, #0xe70
10116da24:	e5 43 21 91	add	x5, sp, #0x850
10116da28:	e6 43 29 91	add	x6, sp, #0xa50
10116da2c:	f4 43 11 91	add	x20, sp, #0x450
10116da30:	f5 93 40 f9	ldr	x21, [sp, #0x120]
10116da34:	53 00 00 14	b	0x10116db80
10116da38:	f0 f7 41 f9	ldr	x16, [sp, #0x3e8]
10116da3c:	2b 05 00 91	add	x11, x9, #0x1
10116da40:	6d 75 7d 92	and	x13, x11, #0x1fffffff8
10116da44:	ee 03 0d aa	mov	x14, x13
10116da48:	ac 01 0f 8b	add	x12, x13, x15
10116da4c:	11 0e 0f 8b	add	x17, x16, x15, lsl #3
10116da50:	31 82 00 91	add	x17, x17, #0x20
10116da54:	00 e4 00 6f	movi.2d	v0, #0000000000000000
10116da58:	e0 03 0d aa	mov	x0, x13
10116da5c:	01 e4 00 6f	movi.2d	v1, #0000000000000000
10116da60:	02 e4 00 6f	movi.2d	v2, #0000000000000000
10116da64:	03 e4 00 6f	movi.2d	v3, #0000000000000000
10116da68:	e1 07 40 91	add	x1, sp, #0x1, lsl #12
10116da6c:	21 c0 01 91	add	x1, x1, #0x70
10116da70:	e2 07 40 91	add	x2, sp, #0x1, lsl #12
10116da74:	42 c0 09 91	add	x2, x2, #0x270
10116da78:	e3 c3 31 91	add	x3, sp, #0xc70
10116da7c:	e4 c3 39 91	add	x4, sp, #0xe70
10116da80:	e5 43 21 91	add	x5, sp, #0x850
10116da84:	e6 43 29 91	add	x6, sp, #0xa50
10116da88:	f4 43 11 91	add	x20, sp, #0x450
10116da8c:	f5 93 40 f9	ldr	x21, [sp, #0x120]
10116da90:	24 16 7f ad	ldp	q4, q5, [x17, #-0x20]
10116da94:	26 1e c2 ac	ldp	q6, q7, [x17], #0x40
10116da98:	80 d4 60 4e	fadd.2d	v0, v4, v0
10116da9c:	a1 d4 61 4e	fadd.2d	v1, v5, v1
10116daa0:	c2 d4 62 4e	fadd.2d	v2, v6, v2
10116daa4:	e3 d4 63 4e	fadd.2d	v3, v7, v3
10116daa8:	00 20 00 f1	subs	x0, x0, #0x8
10116daac:	21 ff ff 54	b.ne	0x10116da90
10116dab0:	20 d4 60 4e	fadd.2d	v0, v1, v0
10116dab4:	40 d4 60 4e	fadd.2d	v0, v2, v0
10116dab8:	60 d4 60 4e	fadd.2d	v0, v3, v0
10116dabc:	00 d8 70 7e	faddp.2d	d0, v0
10116dac0:	7f 01 0d eb	cmp	x11, x13
10116dac4:	20 01 00 54	b.eq	0x10116dae8
10116dac8:	10 0e 0c 8b	add	x16, x16, x12, lsl #3
10116dacc:	71 71 1d 12	and	w17, w11, #0xfffffff8
10116dad0:	51 01 11 4b	sub	w17, w10, w17
10116dad4:	31 06 00 11	add	w17, w17, #0x1
10116dad8:	01 86 40 fc	ldr	d1, [x16], #0x8
10116dadc:	20 28 60 1e	fadd	d0, d1, d0
10116dae0:	31 06 00 71	subs	w17, w17, #0x1
10116dae4:	a1 ff ff 54	b.ne	0x10116dad8
10116dae8:	30 05 00 11	add	w16, w9, #0x1
10116daec:	01 02 62 1e	scvtf	d1, w16
10116daf0:	00 18 61 1e	fdiv	d0, d0, d1
10116daf4:	f0 f7 41 f9	ldr	x16, [sp, #0x3e8]
10116daf8:	02 04 08 4e	dup.2d	v2, v0[0]
10116dafc:	0f 0e 0f 8b	add	x15, x16, x15, lsl #3
10116db00:	ef 81 00 91	add	x15, x15, #0x20
10116db04:	03 e4 00 6f	movi.2d	v3, #0000000000000000
10116db08:	04 e4 00 6f	movi.2d	v4, #0000000000000000
10116db0c:	05 e4 00 6f	movi.2d	v5, #0000000000000000
10116db10:	06 e4 00 6f	movi.2d	v6, #0000000000000000
10116db14:	e7 41 7f ad	ldp	q7, q16, [x15, #-0x20]
10116db18:	f1 49 c2 ac	ldp	q17, q18, [x15], #0x40
10116db1c:	e7 d4 e2 4e	fsub.2d	v7, v7, v2
10116db20:	10 d6 e2 4e	fsub.2d	v16, v16, v2
10116db24:	31 d6 e2 4e	fsub.2d	v17, v17, v2
10116db28:	52 d6 e2 4e	fsub.2d	v18, v18, v2
10116db2c:	e3 cc 67 4e	fmla.2d	v3, v7, v7
10116db30:	04 ce 70 4e	fmla.2d	v4, v16, v16
10116db34:	25 ce 71 4e	fmla.2d	v5, v17, v17
10116db38:	46 ce 72 4e	fmla.2d	v6, v18, v18
10116db3c:	ce 21 00 f1	subs	x14, x14, #0x8
10116db40:	a1 fe ff 54	b.ne	0x10116db14
10116db44:	82 d4 63 4e	fadd.2d	v2, v4, v3
10116db48:	a2 d4 62 4e	fadd.2d	v2, v5, v2
10116db4c:	c2 d4 62 4e	fadd.2d	v2, v6, v2
10116db50:	42 d8 70 7e	faddp.2d	d2, v2
10116db54:	7f 01 0d eb	cmp	x11, x13
10116db58:	40 01 00 54	b.eq	0x10116db80
10116db5c:	0c 0e 0c 8b	add	x12, x16, x12, lsl #3
10116db60:	6b 71 1d 12	and	w11, w11, #0xfffffff8
10116db64:	4a 01 0b 4b	sub	w10, w10, w11
10116db68:	4a 05 00 11	add	w10, w10, #0x1
10116db6c:	83 85 40 fc	ldr	d3, [x12], #0x8
10116db70:	63 38 60 1e	fsub	d3, d3, d0
10116db74:	62 08 43 1f	fmadd	d2, d3, d3, d2
10116db78:	4a 05 00 71	subs	w10, w10, #0x1
10116db7c:	81 ff ff 54	b.ne	0x10116db6c
10116db80:	59 07 00 11	add	w25, w26, #0x1
10116db84:	03 e4 00 2f	movi	d3, #0000000000000000
10116db88:	04 e4 00 2f	movi	d4, #0000000000000000
10116db8c:	3f 0d 00 71	cmp	w9, #0x3
10116db90:	eb 01 00 54	b.lt	0x10116dbcc
10116db94:	04 e4 00 2f	movi	d4, #0000000000000000
10116db98:	3f 03 07 6b	cmp	w25, w7
10116db9c:	8a 01 00 54	b.ge	0x10116dbcc
10116dba0:	04 e4 00 2f	movi	d4, #0000000000000000
10116dba4:	1f 01 00 71	cmp	w8, #0x0
10116dba8:	2d 01 00 54	b.le	0x10116dbcc
10116dbac:	0a 05 00 51	sub	w10, w8, #0x1
10116dbb0:	eb f7 41 f9	ldr	x11, [sp, #0x3e8]
10116dbb4:	64 59 6a fc	ldr	d4, [x11, w10, uxtw #3]
10116dbb8:	65 d9 79 fc	ldr	d5, [x11, w25, sxtw #3]
10116dbbc:	84 d4 e5 7e	fabd	d4, d4, d5
10116dbc0:	2a 09 00 51	sub	w10, w9, #0x2
10116dbc4:	45 01 62 1e	scvtf	d5, w10
10116dbc8:	84 18 65 1e	fdiv	d4, d4, d5
10116dbcc:	50 0b 00 11	add	w16, w26, #0x2
10116dbd0:	2a 0d 00 71	subs	w10, w9, #0x3
10116dbd4:	f8 87 00 f9	str	x24, [sp, #0x108]
10116dbd8:	06 e4 00 2f	movi	d6, #0000000000000000
10116dbdc:	0d 02 00 54	b.le	0x10116dc1c
10116dbe0:	1f 02 07 6b	cmp	w16, w7
10116dbe4:	ca 01 00 54	b.ge	0x10116dc1c
10116dbe8:	0b 09 00 71	subs	w11, w8, #0x2
10116dbec:	8b 01 00 54	b.lt	0x10116dc1c
10116dbf0:	ec f7 41 f9	ldr	x12, [sp, #0x3e8]
10116dbf4:	83 59 6b fc	ldr	d3, [x12, w11, uxtw #3]
10116dbf8:	85 d9 79 fc	ldr	d5, [x12, w25, sxtw #3]
10116dbfc:	63 d4 e5 7e	fabd	d3, d3, d5
10116dc00:	45 01 62 1e	scvtf	d5, w10
10116dc04:	66 18 65 1e	fdiv	d6, d3, d5
10116dc08:	0a 05 00 51	sub	w10, w8, #0x1
10116dc0c:	83 59 6a fc	ldr	d3, [x12, w10, uxtw #3]
10116dc10:	87 d9 70 fc	ldr	d7, [x12, w16, sxtw #3]
10116dc14:	63 d4 e7 7e	fabd	d3, d3, d7
10116dc18:	63 18 65 1e	fdiv	d3, d3, d5
10116dc1c:	2b 68 75 b8	ldr	w11, [x1, x21]
10116dc20:	58 68 75 b8	ldr	w24, [x2, x21]
10116dc24:	05 e4 00 2f	movi	d5, #0000000000000000
10116dc28:	07 e4 00 2f	movi	d7, #0000000000000000
10116dc2c:	61 01 18 6b	subs	w1, w11, w24
10116dc30:	0b 04 00 54	b.lt	0x10116dcb0
10116dc34:	ea f7 41 f9	ldr	x10, [sp, #0x3e8]
10116dc38:	6d 05 00 11	add	w13, w11, #0x1
10116dc3c:	0c 07 00 51	sub	w12, w24, #0x1
10116dc40:	10 e4 00 2f	movi	d16, #0000000000000000
10116dc44:	ef 03 0c aa	mov	x15, x12
10116dc48:	04 00 00 14	b	0x10116dc58
10116dc4c:	ef 03 0e aa	mov	x15, x14
10116dc50:	7f 01 0e 6b	cmp	w11, w14
10116dc54:	e0 00 00 54	b.eq	0x10116dc70
10116dc58:	ee 05 00 11	add	w14, w15, #0x1
10116dc5c:	ff f9 01 71	cmp	w15, #0x7e
10116dc60:	68 ff ff 54	b.hi	0x10116dc4c
10116dc64:	47 59 6e fc	ldr	d7, [x10, w14, uxtw #3]
10116dc68:	f0 28 70 1e	fadd	d16, d7, d16
10116dc6c:	f8 ff ff 17	b	0x10116dc4c
10116dc70:	ad 01 18 4b	sub	w13, w13, w24
10116dc74:	a7 01 62 1e	scvtf	d7, w13
10116dc78:	11 1a 67 1e	fdiv	d17, d16, d7
10116dc7c:	10 e4 00 2f	movi	d16, #0000000000000000
10116dc80:	04 00 00 14	b	0x10116dc90
10116dc84:	ec 03 0d aa	mov	x12, x13
10116dc88:	7f 01 0d 6b	cmp	w11, w13
10116dc8c:	00 01 00 54	b.eq	0x10116dcac
10116dc90:	8d 05 00 11	add	w13, w12, #0x1
10116dc94:	9f f9 01 71	cmp	w12, #0x7e
10116dc98:	68 ff ff 54	b.hi	0x10116dc84
10116dc9c:	52 59 6d fc	ldr	d18, [x10, w13, uxtw #3]
10116dca0:	52 3a 71 1e	fsub	d18, d18, d17
10116dca4:	50 42 52 1f	fmadd	d16, d18, d18, d16
10116dca8:	f7 ff ff 17	b	0x10116dc84
10116dcac:	07 1a 67 1e	fdiv	d7, d16, d7
10116dcb0:	1c 07 00 11	add	w28, w24, #0x1
10116dcb4:	3f 0c 00 71	cmp	w1, #0x3
10116dcb8:	8b 01 00 54	b.lt	0x10116dce8
10116dcbc:	9f 03 07 6b	cmp	w28, w7
10116dcc0:	4a 01 00 54	b.ge	0x10116dce8
10116dcc4:	6a 05 00 71	subs	w10, w11, #0x1
10116dcc8:	0b 01 00 54	b.lt	0x10116dce8
10116dccc:	ec f7 41 f9	ldr	x12, [sp, #0x3e8]
10116dcd0:	85 59 6a fc	ldr	d5, [x12, w10, uxtw #3]
10116dcd4:	90 d9 7c fc	ldr	d16, [x12, w28, sxtw #3]
10116dcd8:	a5 d4 f0 7e	fabd	d5, d5, d16
10116dcdc:	2a 08 00 51	sub	w10, w1, #0x2
10116dce0:	50 01 62 1e	scvtf	d16, w10
10116dce4:	a5 18 70 1e	fdiv	d5, d5, d16
10116dce8:	11 0b 00 11	add	w17, w24, #0x2
10116dcec:	10 e4 00 2f	movi	d16, #0000000000000000
10116dcf0:	12 e4 00 2f	movi	d18, #0000000000000000
10116dcf4:	11 e4 00 2f	movi	d17, #0000000000000000
10116dcf8:	2a 0c 00 71	subs	w10, w1, #0x3
10116dcfc:	8d 02 00 54	b.le	0x10116dd4c
10116dd00:	12 e4 00 2f	movi	d18, #0000000000000000
10116dd04:	11 e4 00 2f	movi	d17, #0000000000000000
10116dd08:	3f 02 07 6b	cmp	w17, w7
10116dd0c:	0a 02 00 54	b.ge	0x10116dd4c
10116dd10:	12 e4 00 2f	movi	d18, #0000000000000000
10116dd14:	11 e4 00 2f	movi	d17, #0000000000000000
10116dd18:	6c 09 00 71	subs	w12, w11, #0x2
10116dd1c:	8b 01 00 54	b.lt	0x10116dd4c
10116dd20:	ed f7 41 f9	ldr	x13, [sp, #0x3e8]
10116dd24:	b1 59 6c fc	ldr	d17, [x13, w12, uxtw #3]
10116dd28:	b2 d9 7c fc	ldr	d18, [x13, w28, sxtw #3]
10116dd2c:	31 d6 f2 7e	fabd	d17, d17, d18
10116dd30:	52 01 62 1e	scvtf	d18, w10
10116dd34:	31 1a 72 1e	fdiv	d17, d17, d18
10116dd38:	6a 05 00 51	sub	w10, w11, #0x1
10116dd3c:	b3 59 6a fc	ldr	d19, [x13, w10, uxtw #3]
10116dd40:	b4 d9 71 fc	ldr	d20, [x13, w17, sxtw #3]
10116dd44:	73 d6 f4 7e	fabd	d19, d19, d20
10116dd48:	72 1a 72 1e	fdiv	d18, d19, d18
10116dd4c:	6a 68 75 b8	ldr	w10, [x3, x21]
10116dd50:	8e 68 75 b8	ldr	w14, [x4, x21]
10116dd54:	43 01 0e 6b	subs	w3, w10, w14
10116dd58:	ab 04 00 54	b.lt	0x10116ddec
10116dd5c:	ed fb 41 f9	ldr	x13, [sp, #0x3f0]
10116dd60:	ec f7 41 f9	ldr	x12, [sp, #0x3e8]
10116dd64:	ad 01 0c cb	sub	x13, x13, x12
10116dd68:	ad fd 43 93	asr	x13, x13, #3
10116dd6c:	4f 05 00 11	add	w15, w10, #0x1
10116dd70:	13 e4 00 2f	movi	d19, #0000000000000000
10116dd74:	e0 03 0e aa	mov	x0, x14
10116dd78:	04 00 00 14	b	0x10116dd88
10116dd7c:	00 04 00 11	add	w0, w0, #0x1
10116dd80:	ff 01 00 6b	cmp	w15, w0
10116dd84:	00 01 00 54	b.eq	0x10116dda4
10116dd88:	a0 ff ff 37	tbnz	w0, #0x1f, 0x10116dd7c
10116dd8c:	e2 03 00 2a	mov	w2, w0
10116dd90:	bf 01 02 eb	cmp	x13, x2
10116dd94:	49 ff ff 54	b.ls	0x10116dd7c
10116dd98:	90 79 62 fc	ldr	d16, [x12, x2, lsl #3]
10116dd9c:	13 2a 73 1e	fadd	d19, d16, d19
10116dda0:	f7 ff ff 17	b	0x10116dd7c
10116dda4:	e0 01 0e 4b	sub	w0, w15, w14
10116dda8:	10 00 62 1e	scvtf	d16, w0
10116ddac:	74 1a 70 1e	fdiv	d20, d19, d16
10116ddb0:	13 e4 00 2f	movi	d19, #0000000000000000
10116ddb4:	e0 03 0e aa	mov	x0, x14
10116ddb8:	04 00 00 14	b	0x10116ddc8
10116ddbc:	00 04 00 11	add	w0, w0, #0x1
10116ddc0:	ff 01 00 6b	cmp	w15, w0
10116ddc4:	20 01 00 54	b.eq	0x10116dde8
10116ddc8:	a0 ff ff 37	tbnz	w0, #0x1f, 0x10116ddbc
10116ddcc:	e2 03 00 2a	mov	w2, w0
10116ddd0:	bf 01 02 eb	cmp	x13, x2
10116ddd4:	49 ff ff 54	b.ls	0x10116ddbc
10116ddd8:	95 79 62 fc	ldr	d21, [x12, x2, lsl #3]
10116dddc:	b5 3a 74 1e	fsub	d21, d21, d20
10116dde0:	b3 4e 55 1f	fmadd	d19, d21, d21, d19
10116dde4:	f6 ff ff 17	b	0x10116ddbc
10116dde8:	70 1a 70 1e	fdiv	d16, d19, d16
10116ddec:	f0 83 00 f9	str	x16, [sp, #0x100]
10116ddf0:	d6 05 00 11	add	w22, w14, #0x1
10116ddf4:	13 e4 00 2f	movi	d19, #0000000000000000
10116ddf8:	14 e4 00 2f	movi	d20, #0000000000000000
10116ddfc:	7f 0c 00 71	cmp	w3, #0x3
10116de00:	cb 01 00 54	b.lt	0x10116de38
10116de04:	14 e4 00 2f	movi	d20, #0000000000000000
10116de08:	df 02 07 6b	cmp	w22, w7
10116de0c:	6a 01 00 54	b.ge	0x10116de38
10116de10:	14 e4 00 2f	movi	d20, #0000000000000000
10116de14:	4c 05 00 71	subs	w12, w10, #0x1
10116de18:	0b 01 00 54	b.lt	0x10116de38
10116de1c:	ed f7 41 f9	ldr	x13, [sp, #0x3e8]
10116de20:	b4 59 6c fc	ldr	d20, [x13, w12, uxtw #3]
10116de24:	b5 d9 76 fc	ldr	d21, [x13, w22, sxtw #3]
10116de28:	94 d6 f5 7e	fabd	d20, d20, d21
10116de2c:	6c 08 00 51	sub	w12, w3, #0x2
10116de30:	95 01 62 1e	scvtf	d21, w12
10116de34:	94 1a 75 1e	fdiv	d20, d20, d21
10116de38:	de 09 00 11	add	w30, w14, #0x2
10116de3c:	16 e4 00 2f	movi	d22, #0000000000000000
10116de40:	6c 0c 00 71	subs	w12, w3, #0x3
10116de44:	0d 02 00 54	b.le	0x10116de84
10116de48:	df 03 07 6b	cmp	w30, w7
10116de4c:	ca 01 00 54	b.ge	0x10116de84
10116de50:	4d 09 00 71	subs	w13, w10, #0x2
10116de54:	8b 01 00 54	b.lt	0x10116de84
10116de58:	ef f7 41 f9	ldr	x15, [sp, #0x3e8]
10116de5c:	f3 59 6d fc	ldr	d19, [x15, w13, uxtw #3]
10116de60:	f5 d9 76 fc	ldr	d21, [x15, w22, sxtw #3]
10116de64:	73 d6 f5 7e	fabd	d19, d19, d21
10116de68:	95 01 62 1e	scvtf	d21, w12
10116de6c:	76 1a 75 1e	fdiv	d22, d19, d21
10116de70:	4c 05 00 51	sub	w12, w10, #0x1
10116de74:	f3 59 6c fc	ldr	d19, [x15, w12, uxtw #3]
10116de78:	f7 d9 7e fc	ldr	d23, [x15, w30, sxtw #3]
10116de7c:	73 d6 f7 7e	fabd	d19, d19, d23
10116de80:	73 1a 75 1e	fdiv	d19, d19, d21
10116de84:	ac 68 75 b8	ldr	w12, [x5, x21]
10116de88:	cf 68 75 b8	ldr	w15, [x6, x21]
10116de8c:	15 e4 00 2f	movi	d21, #0000000000000000
10116de90:	17 e4 00 2f	movi	d23, #0000000000000000
10116de94:	84 01 0f 6b	subs	w4, w12, w15
10116de98:	6b 04 00 54	b.lt	0x10116df24
10116de9c:	f0 03 07 aa	mov	x16, x7
10116dea0:	ed 03 0f aa	mov	x13, x15
10116dea4:	a2 7d 40 93	sxtw	x2, w13
10116dea8:	ed fb 41 f9	ldr	x13, [sp, #0x3f0]
10116deac:	e5 f7 41 f9	ldr	x5, [sp, #0x3e8]
10116deb0:	ad 01 05 cb	sub	x13, x13, x5
10116deb4:	ad fd 43 93	asr	x13, x13, #3
10116deb8:	86 05 00 11	add	w6, w12, #0x1
10116debc:	ad 01 02 eb	subs	x13, x13, x2
10116dec0:	ed 33 8d 9a	csel	x13, xzr, x13, lo
10116dec4:	a2 0c 02 8b	add	x2, x5, x2, lsl #3
10116dec8:	c5 00 0f 4b	sub	w5, w6, w15
10116decc:	18 e4 00 2f	movi	d24, #0000000000000000
10116ded0:	e6 03 05 aa	mov	x6, x5
10116ded4:	e7 03 02 aa	mov	x7, x2
10116ded8:	f3 03 0d aa	mov	x19, x13
10116dedc:	d3 00 00 b4	cbz	x19, 0x10116def4
10116dee0:	f7 84 40 fc	ldr	d23, [x7], #0x8
10116dee4:	f8 2a 78 1e	fadd	d24, d23, d24
10116dee8:	73 06 00 d1	sub	x19, x19, #0x1
10116deec:	c6 04 00 71	subs	w6, w6, #0x1
10116def0:	61 ff ff 54	b.ne	0x10116dedc
10116def4:	b7 00 62 1e	scvtf	d23, w5
10116def8:	19 1b 77 1e	fdiv	d25, d24, d23
10116defc:	18 e4 00 2f	movi	d24, #0000000000000000
10116df00:	e7 03 10 aa	mov	x7, x16
10116df04:	ed 00 00 b4	cbz	x13, 0x10116df20
10116df08:	5a 84 40 fc	ldr	d26, [x2], #0x8
10116df0c:	5a 3b 79 1e	fsub	d26, d26, d25
10116df10:	58 63 5a 1f	fmadd	d24, d26, d26, d24
10116df14:	ad 05 00 d1	sub	x13, x13, #0x1
10116df18:	a5 04 00 71	subs	w5, w5, #0x1
10116df1c:	41 ff ff 54	b.ne	0x10116df04
10116df20:	17 1b 77 1e	fdiv	d23, d24, d23
10116df24:	f7 05 00 11	add	w23, w15, #0x1
10116df28:	9f 0c 00 71	cmp	w4, #0x3
10116df2c:	8b 01 00 54	b.lt	0x10116df5c
10116df30:	ff 02 07 6b	cmp	w23, w7
10116df34:	4a 01 00 54	b.ge	0x10116df5c
10116df38:	8d 05 00 71	subs	w13, w12, #0x1
10116df3c:	0b 01 00 54	b.lt	0x10116df5c
10116df40:	e2 f7 41 f9	ldr	x2, [sp, #0x3e8]
10116df44:	55 58 6d fc	ldr	d21, [x2, w13, uxtw #3]
10116df48:	58 d8 77 fc	ldr	d24, [x2, w23, sxtw #3]
10116df4c:	b5 d6 f8 7e	fabd	d21, d21, d24
10116df50:	8d 08 00 51	sub	w13, w4, #0x2
10116df54:	b8 01 62 1e	scvtf	d24, w13
10116df58:	b5 1a 78 1e	fdiv	d21, d21, d24
10116df5c:	e0 03 19 aa	mov	x0, x25
10116df60:	e2 09 00 11	add	w2, w15, #0x2
10116df64:	18 e4 00 2f	movi	d24, #0000000000000000
10116df68:	1a e4 00 2f	movi	d26, #0000000000000000
10116df6c:	19 e4 00 2f	movi	d25, #0000000000000000
10116df70:	8d 0c 00 71	subs	w13, w4, #0x3
10116df74:	8d 02 00 54	b.le	0x10116dfc4
10116df78:	1a e4 00 2f	movi	d26, #0000000000000000
10116df7c:	19 e4 00 2f	movi	d25, #0000000000000000
10116df80:	5f 00 07 6b	cmp	w2, w7
10116df84:	0a 02 00 54	b.ge	0x10116dfc4
10116df88:	1a e4 00 2f	movi	d26, #0000000000000000
10116df8c:	19 e4 00 2f	movi	d25, #0000000000000000
10116df90:	85 09 00 71	subs	w5, w12, #0x2
10116df94:	8b 01 00 54	b.lt	0x10116dfc4
10116df98:	e6 f7 41 f9	ldr	x6, [sp, #0x3e8]
10116df9c:	d9 58 65 fc	ldr	d25, [x6, w5, uxtw #3]
10116dfa0:	da d8 77 fc	ldr	d26, [x6, w23, sxtw #3]
10116dfa4:	39 d7 fa 7e	fabd	d25, d25, d26
10116dfa8:	ba 01 62 1e	scvtf	d26, w13
10116dfac:	39 1b 7a 1e	fdiv	d25, d25, d26
10116dfb0:	8d 05 00 51	sub	w13, w12, #0x1
10116dfb4:	db 58 6d fc	ldr	d27, [x6, w13, uxtw #3]
10116dfb8:	dc d8 62 fc	ldr	d28, [x6, w2, sxtw #3]
10116dfbc:	7b d7 fc 7e	fabd	d27, d27, d28
10116dfc0:	7a 1b 7a 1e	fdiv	d26, d27, d26
10116dfc4:	f0 03 07 aa	mov	x16, x7
10116dfc8:	8d 6a 75 b8	ldr	w13, [x20, x21]
10116dfcc:	e5 43 19 91	add	x5, sp, #0x650
10116dfd0:	b9 68 75 b8	ldr	w25, [x5, x21]
10116dfd4:	a7 01 19 6b	subs	w7, w13, w25
10116dfd8:	f4 8b 40 f9	ldr	x20, [sp, #0x110]
10116dfdc:	cb 04 00 54	b.lt	0x10116e074
10116dfe0:	e6 fb 41 f9	ldr	x6, [sp, #0x3f0]
10116dfe4:	e5 f7 41 f9	ldr	x5, [sp, #0x3e8]
10116dfe8:	c6 00 05 cb	sub	x6, x6, x5
10116dfec:	c6 fc 43 93	asr	x6, x6, #3
10116dff0:	bb 05 00 11	add	w27, w13, #0x1
10116dff4:	1b e4 00 2f	movi	d27, #0000000000000000
10116dff8:	f3 03 19 aa	mov	x19, x25
10116dffc:	04 00 00 14	b	0x10116e00c
10116e000:	73 06 00 11	add	w19, w19, #0x1
10116e004:	7f 03 13 6b	cmp	w27, w19
10116e008:	00 01 00 54	b.eq	0x10116e028
10116e00c:	b3 ff ff 37	tbnz	w19, #0x1f, 0x10116e000
10116e010:	f5 03 13 2a	mov	w21, w19
10116e014:	df 00 15 eb	cmp	x6, x21
10116e018:	49 ff ff 54	b.ls	0x10116e000
10116e01c:	b8 78 75 fc	ldr	d24, [x5, x21, lsl #3]
10116e020:	1b 2b 7b 1e	fadd	d27, d24, d27
10116e024:	f7 ff ff 17	b	0x10116e000
10116e028:	73 03 19 4b	sub	w19, w27, w25
10116e02c:	78 02 62 1e	scvtf	d24, w19
10116e030:	7c 1b 78 1e	fdiv	d28, d27, d24
10116e034:	1b e4 00 2f	movi	d27, #0000000000000000
10116e038:	f3 03 19 aa	mov	x19, x25
10116e03c:	04 00 00 14	b	0x10116e04c
10116e040:	73 06 00 11	add	w19, w19, #0x1
10116e044:	7f 03 13 6b	cmp	w27, w19
10116e048:	20 01 00 54	b.eq	0x10116e06c
10116e04c:	b3 ff ff 37	tbnz	w19, #0x1f, 0x10116e040
10116e050:	f5 03 13 2a	mov	w21, w19
10116e054:	df 00 15 eb	cmp	x6, x21
10116e058:	49 ff ff 54	b.ls	0x10116e040
10116e05c:	bd 78 75 fc	ldr	d29, [x5, x21, lsl #3]
10116e060:	bd 3b 7c 1e	fsub	d29, d29, d28
10116e064:	bb 6f 5d 1f	fmadd	d27, d29, d29, d27
10116e068:	f6 ff ff 17	b	0x10116e040
10116e06c:	78 1b 78 1e	fdiv	d24, d27, d24
10116e070:	fb 9f 40 f9	ldr	x27, [sp, #0x138]
10116e074:	25 07 00 11	add	w5, w25, #0x1
10116e078:	1b e4 00 2f	movi	d27, #0000000000000000
10116e07c:	1c e4 00 2f	movi	d28, #0000000000000000
10116e080:	ff 0c 00 71	cmp	w7, #0x3
10116e084:	cb 01 00 54	b.lt	0x10116e0bc
10116e088:	1c e4 00 2f	movi	d28, #0000000000000000
10116e08c:	bf 00 10 6b	cmp	w5, w16
10116e090:	6a 01 00 54	b.ge	0x10116e0bc
10116e094:	1c e4 00 2f	movi	d28, #0000000000000000
10116e098:	a6 05 00 71	subs	w6, w13, #0x1
10116e09c:	0b 01 00 54	b.lt	0x10116e0bc
10116e0a0:	f3 f7 41 f9	ldr	x19, [sp, #0x3e8]
10116e0a4:	7c 5a 66 fc	ldr	d28, [x19, w6, uxtw #3]
10116e0a8:	7d da 65 fc	ldr	d29, [x19, w5, sxtw #3]
10116e0ac:	9c d7 fd 7e	fabd	d28, d28, d29
10116e0b0:	e6 08 00 51	sub	w6, w7, #0x2
10116e0b4:	dd 00 62 1e	scvtf	d29, w6
10116e0b8:	9c 1b 7d 1e	fdiv	d28, d28, d29
10116e0bc:	26 0b 00 11	add	w6, w25, #0x2
10116e0c0:	1d e4 00 2f	movi	d29, #0000000000000000
10116e0c4:	f3 0c 00 71	subs	w19, w7, #0x3
10116e0c8:	2d 02 00 54	b.le	0x10116e10c
10116e0cc:	df 00 10 6b	cmp	w6, w16
10116e0d0:	ea 01 00 54	b.ge	0x10116e10c
10116e0d4:	b5 09 00 71	subs	w21, w13, #0x2
10116e0d8:	ab 01 00 54	b.lt	0x10116e10c
10116e0dc:	fb f7 41 f9	ldr	x27, [sp, #0x3e8]
10116e0e0:	7b 5b 75 fc	ldr	d27, [x27, w21, uxtw #3]
10116e0e4:	7d db 65 fc	ldr	d29, [x27, w5, sxtw #3]
10116e0e8:	7b d7 fd 7e	fabd	d27, d27, d29
10116e0ec:	7d 02 62 1e	scvtf	d29, w19
10116e0f0:	7b 1b 7d 1e	fdiv	d27, d27, d29
10116e0f4:	b3 05 00 51	sub	w19, w13, #0x1
10116e0f8:	7e 5b 73 fc	ldr	d30, [x27, w19, uxtw #3]
10116e0fc:	7f db 66 fc	ldr	d31, [x27, w6, sxtw #3]
10116e100:	fb 9f 40 f9	ldr	x27, [sp, #0x138]
10116e104:	de d7 ff 7e	fabd	d30, d30, d31
10116e108:	dd 1b 7d 1e	fdiv	d29, d30, d29
10116e10c:	41 18 61 1e	fdiv	d1, d2, d1
10116e110:	62 28 64 1e	fadd	d2, d3, d4
10116e114:	42 28 66 1e	fadd	d2, d2, d6
10116e118:	f3 f3 00 b2	mov	x19, #0x5555555555555555
10116e11c:	b3 fa e7 f2	movk	x19, #0x3fd5, lsl #48
10116e120:	63 02 67 9e	fmov	d3, x19
10116e124:	42 08 63 1e	fmul	d2, d2, d3
10116e128:	73 8f 82 d2	mov	x19, #0x147b
10116e12c:	d3 f5 a8 f2	movk	x19, #0x47ae, lsl #16
10116e130:	33 5c cf f2	movk	x19, #0x7ae1, lsl #32
10116e134:	13 fc e7 f2	movk	x19, #0x3fe0, lsl #48
10116e138:	63 02 67 9e	fmov	d3, x19
10116e13c:	00 20 63 1e	fcmp	d0, d3
10116e140:	ea 09 00 54	b.ge	0x10116e27c
10116e144:	53 e1 9a d2	mov	x19, #0xd70a
10116e148:	73 14 ae f2	movk	x19, #0x70a3, lsl #16
10116e14c:	b3 47 c1 f2	movk	x19, #0xa3d, lsl #32
10116e150:	f3 fb e7 f2	movk	x19, #0x3fdf, lsl #48
10116e154:	63 02 67 9e	fmov	d3, x19
10116e158:	00 20 63 1e	fcmp	d0, d3
10116e15c:	0d 09 00 54	b.le	0x10116e27c
10116e160:	93 3f 95 d2	mov	x19, #0xa9fc
10116e164:	33 5e ba f2	movk	x19, #0xd2f1, lsl #16
10116e168:	b3 49 cc f2	movk	x19, #0x624d, lsl #32
10116e16c:	13 f0 e7 f2	movk	x19, #0x3f80, lsl #48
10116e170:	63 02 67 9e	fmov	d3, x19
10116e174:	40 20 63 1e	fcmp	d2, d3
10116e178:	2a 08 00 54	b.ge	0x10116e27c
10116e17c:	1a 08 f8 37	tbnz	w26, #0x1f, 0x10116e27c
10116e180:	3f 21 00 71	cmp	w9, #0x8
10116e184:	cb 07 00 54	b.lt	0x10116e27c
10116e188:	13 d7 83 d2	mov	x19, #0x1eb8
10116e18c:	b3 70 bd f2	movk	x19, #0xeb85, lsl #16
10116e190:	33 0a d7 f2	movk	x19, #0xb851, lsl #32
10116e194:	d3 f1 e7 f2	movk	x19, #0x3f8e, lsl #48
10116e198:	63 02 67 9e	fmov	d3, x19
10116e19c:	20 20 63 1e	fcmp	d1, d3
10116e1a0:	ea 06 00 54	b.ge	0x10116e27c
10116e1a4:	7a 8a 00 34	cbz	w26, 0x10116f2f0
10116e1a8:	56 07 00 51	sub	w22, w26, #0x1
10116e1ac:	80 5a 76 fc	ldr	d0, [x20, w22, uxtw #3]
10116e1b0:	ee e7 02 b2	mov	x14, #-0x3333333333333334
10116e1b4:	ae 99 99 f2	movk	x14, #0xcccd
10116e1b8:	8e ff e7 f2	movk	x14, #0x3ffc, lsl #48
10116e1bc:	c1 01 67 9e	fmov	d1, x14
10116e1c0:	00 20 61 1e	fcmp	d0, d1
10116e1c4:	e9 a3 90 d2	mov	x9, #0x851f
10116e1c8:	69 3d aa f2	movk	x9, #0x51eb, lsl #16
10116e1cc:	09 d7 c3 f2	movk	x9, #0x1eb8, lsl #32
10116e1d0:	29 fe e7 f2	movk	x9, #0x3ff1, lsl #48
10116e1d4:	21 01 67 9e	fmov	d1, x9
10116e1d8:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
10116e1dc:	ef e7 01 b2	mov	x15, #-0x6666666666666667
10116e1e0:	4f 33 93 f2	movk	x15, #0x999a
10116e1e4:	2f 00 e8 f2	movk	x15, #0x4001, lsl #48
10116e1e8:	e1 01 67 9e	fmov	d1, x15
10116e1ec:	00 d4 61 1e	fccmp	d0, d1, #0x0, le
10116e1f0:	fc e7 52 a9	ldp	x28, x25, [sp, #0x128]
10116e1f4:	ed 8e 00 54	b.le	0x10116f3d0
10116e1f8:	49 0b 00 71	subs	w9, w26, #0x2
10116e1fc:	63 61 01 54	b.lo	0x101170e28
10116e200:	80 5a 69 fc	ldr	d0, [x20, w9, uxtw #3]
10116e204:	c1 01 67 9e	fmov	d1, x14
10116e208:	00 20 61 1e	fcmp	d0, d1
10116e20c:	ea a3 90 d2	mov	x10, #0x851f
10116e210:	6a 3d aa f2	movk	x10, #0x51eb, lsl #16
10116e214:	0a d7 c3 f2	movk	x10, #0x1eb8, lsl #32
10116e218:	2a fe e7 f2	movk	x10, #0x3ff1, lsl #48
10116e21c:	41 01 67 9e	fmov	d1, x10
10116e220:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
10116e224:	8c 00 00 54	b.gt	0x10116e234
10116e228:	e1 01 67 9e	fmov	d1, x15
10116e22c:	00 20 61 1e	fcmp	d0, d1
10116e230:	ed 5f 01 54	b.le	0x101170e2c
10116e234:	56 0f 00 71	subs	w22, w26, #0x3
10116e238:	83 5f 01 54	b.lo	0x101170e28
10116e23c:	80 5a 76 fc	ldr	d0, [x20, w22, uxtw #3]
10116e240:	c1 01 67 9e	fmov	d1, x14
10116e244:	00 20 61 1e	fcmp	d0, d1
10116e248:	ea a3 90 d2	mov	x10, #0x851f
10116e24c:	6a 3d aa f2	movk	x10, #0x51eb, lsl #16
10116e250:	0a d7 c3 f2	movk	x10, #0x1eb8, lsl #32
10116e254:	2a fe e7 f2	movk	x10, #0x3ff1, lsl #48
10116e258:	41 01 67 9e	fmov	d1, x10
10116e25c:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
10116e260:	cc 59 01 54	b.gt	0x101170d98
10116e264:	e1 01 67 9e	fmov	d1, x15
10116e268:	00 20 61 1e	fcmp	d0, d1
10116e26c:	6c 59 01 54	b.gt	0x101170d98
10116e270:	11 00 80 52	mov	w17, #0x0
10116e274:	f6 03 09 aa	mov	x22, x9
10116e278:	ee 0a 00 14	b	0x101170e30
10116e27c:	43 2a 65 1e	fadd	d3, d18, d5
10116e280:	63 28 71 1e	fadd	d3, d3, d17
10116e284:	f3 f3 00 b2	mov	x19, #0x5555555555555555
10116e288:	b3 fa e7 f2	movk	x19, #0x3fd5, lsl #48
10116e28c:	64 02 67 9e	fmov	d4, x19
10116e290:	63 08 64 1e	fmul	d3, d3, d4
10116e294:	93 3f 95 d2	mov	x19, #0xa9fc
10116e298:	33 5e ba f2	movk	x19, #0xd2f1, lsl #16
10116e29c:	b3 49 cc f2	movk	x19, #0x624d, lsl #32
10116e2a0:	13 f0 e7 f2	movk	x19, #0x3f80, lsl #48
10116e2a4:	64 02 67 9e	fmov	d4, x19
10116e2a8:	60 20 64 1e	fcmp	d3, d4
10116e2ac:	2a 08 00 54	b.ge	0x10116e3b0
10116e2b0:	18 08 f8 37	tbnz	w24, #0x1f, 0x10116e3b0
10116e2b4:	3f 20 00 71	cmp	w1, #0x8
10116e2b8:	cb 07 00 54	b.lt	0x10116e3b0
10116e2bc:	01 d7 83 d2	mov	x1, #0x1eb8
10116e2c0:	a1 70 bd f2	movk	x1, #0xeb85, lsl #16
10116e2c4:	21 0a d7 f2	movk	x1, #0xb851, lsl #32
10116e2c8:	c1 f1 e7 f2	movk	x1, #0x3f8e, lsl #48
10116e2cc:	23 00 67 9e	fmov	d3, x1
10116e2d0:	e0 20 63 1e	fcmp	d7, d3
10116e2d4:	ea 06 00 54	b.ge	0x10116e3b0
10116e2d8:	38 88 00 34	cbz	w24, 0x10116f3dc
10116e2dc:	16 07 00 51	sub	w22, w24, #0x1
10116e2e0:	80 5a 76 fc	ldr	d0, [x20, w22, uxtw #3]
10116e2e4:	ee e7 02 b2	mov	x14, #-0x3333333333333334
10116e2e8:	ae 99 99 f2	movk	x14, #0xcccd
10116e2ec:	8e ff e7 f2	movk	x14, #0x3ffc, lsl #48
10116e2f0:	c1 01 67 9e	fmov	d1, x14
10116e2f4:	00 20 61 1e	fcmp	d0, d1
10116e2f8:	e8 a3 90 d2	mov	x8, #0x851f
10116e2fc:	68 3d aa f2	movk	x8, #0x51eb, lsl #16
10116e300:	08 d7 c3 f2	movk	x8, #0x1eb8, lsl #32
10116e304:	28 fe e7 f2	movk	x8, #0x3ff1, lsl #48
10116e308:	01 01 67 9e	fmov	d1, x8
10116e30c:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
10116e310:	ef e7 01 b2	mov	x15, #-0x6666666666666667
10116e314:	4f 33 93 f2	movk	x15, #0x999a
10116e318:	2f 00 e8 f2	movk	x15, #0x4001, lsl #48
10116e31c:	e1 01 67 9e	fmov	d1, x15
10116e320:	00 d4 61 1e	fccmp	d0, d1, #0x0, le
10116e324:	f9 9b 40 f9	ldr	x25, [sp, #0x130]
10116e328:	ed 90 00 54	b.le	0x10116f544
10116e32c:	08 0b 00 71	subs	w8, w24, #0x2
10116e330:	23 a1 02 54	b.lo	0x101173754
10116e334:	80 5a 68 fc	ldr	d0, [x20, w8, uxtw #3]
10116e338:	c1 01 67 9e	fmov	d1, x14
10116e33c:	00 20 61 1e	fcmp	d0, d1
10116e340:	e9 a3 90 d2	mov	x9, #0x851f
10116e344:	69 3d aa f2	movk	x9, #0x51eb, lsl #16
10116e348:	09 d7 c3 f2	movk	x9, #0x1eb8, lsl #32
10116e34c:	29 fe e7 f2	movk	x9, #0x3ff1, lsl #48
10116e350:	21 01 67 9e	fmov	d1, x9
10116e354:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
10116e358:	8c 00 00 54	b.gt	0x10116e368
10116e35c:	e1 01 67 9e	fmov	d1, x15
10116e360:	00 20 61 1e	fcmp	d0, d1
10116e364:	ad 9f 02 54	b.le	0x101173758
10116e368:	16 0f 00 71	subs	w22, w24, #0x3
10116e36c:	43 9f 02 54	b.lo	0x101173754
10116e370:	80 5a 76 fc	ldr	d0, [x20, w22, uxtw #3]
10116e374:	c1 01 67 9e	fmov	d1, x14
10116e378:	00 20 61 1e	fcmp	d0, d1
10116e37c:	e9 a3 90 d2	mov	x9, #0x851f
10116e380:	69 3d aa f2	movk	x9, #0x51eb, lsl #16
10116e384:	09 d7 c3 f2	movk	x9, #0x1eb8, lsl #32
10116e388:	29 fe e7 f2	movk	x9, #0x3ff1, lsl #48
10116e38c:	21 01 67 9e	fmov	d1, x9
10116e390:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
10116e394:	8c 99 02 54	b.gt	0x1011736c4
10116e398:	e1 01 67 9e	fmov	d1, x15
10116e39c:	00 20 61 1e	fcmp	d0, d1
10116e3a0:	2c 99 02 54	b.gt	0x1011736c4
10116e3a4:	00 00 80 52	mov	w0, #0x0
10116e3a8:	f6 03 08 aa	mov	x22, x8
10116e3ac:	ec 14 00 14	b	0x10117375c
10116e3b0:	2b bf 98 d2	mov	x11, #0xc5f9
10116e3b4:	4b f2 ab f2	movk	x11, #0x5f92, lsl #16
10116e3b8:	8b 25 df f2	movk	x11, #0xf92c, lsl #32
10116e3bc:	ab fc e7 f2	movk	x11, #0x3fe5, lsl #48
10116e3c0:	63 01 67 9e	fmov	d3, x11
10116e3c4:	00 20 63 1e	fcmp	d0, d3
10116e3c8:	f3 af 40 f9	ldr	x19, [sp, #0x158]
10116e3cc:	ea 14 00 54	b.ge	0x10116e668
10116e3d0:	2b 96 9c d2	mov	x11, #0xe4b1
10116e3d4:	eb 62 a9 f2	movk	x11, #0x4b17, lsl #16
10116e3d8:	cb 2f d6 f2	movk	x11, #0xb17e, lsl #32
10116e3dc:	8b fc e7 f2	movk	x11, #0x3fe4, lsl #48
10116e3e0:	63 01 67 9e	fmov	d3, x11
10116e3e4:	00 20 63 1e	fcmp	d0, d3
10116e3e8:	0d 14 00 54	b.le	0x10116e668
10116e3ec:	8b 3f 95 d2	mov	x11, #0xa9fc
10116e3f0:	2b 5e ba f2	movk	x11, #0xd2f1, lsl #16
10116e3f4:	ab 49 cc f2	movk	x11, #0x624d, lsl #32
10116e3f8:	0b f0 e7 f2	movk	x11, #0x3f80, lsl #48
10116e3fc:	63 01 67 9e	fmov	d3, x11
10116e400:	40 20 63 1e	fcmp	d2, d3
10116e404:	2a 13 00 54	b.ge	0x10116e668
10116e408:	1a 13 f8 37	tbnz	w26, #0x1f, 0x10116e668
10116e40c:	3f 21 00 71	cmp	w9, #0x8
10116e410:	cb 12 00 54	b.lt	0x10116e668
10116e414:	0b d7 83 d2	mov	x11, #0x1eb8
10116e418:	ab 70 bd f2	movk	x11, #0xeb85, lsl #16
10116e41c:	2b 0a d7 f2	movk	x11, #0xb851, lsl #32
10116e420:	cb f1 e7 f2	movk	x11, #0x3f8e, lsl #48
10116e424:	63 01 67 9e	fmov	d3, x11
10116e428:	20 20 63 1e	fcmp	d1, d3
10116e42c:	ea 11 00 54	b.ge	0x10116e668
10116e430:	ec e7 02 b2	mov	x12, #-0x3333333333333334
10116e434:	ac 99 99 f2	movk	x12, #0xcccd
10116e438:	8c ff e7 f2	movk	x12, #0x3ffc, lsl #48
10116e43c:	ba 88 00 34	cbz	w26, 0x10116f550
10116e440:	4a 07 00 51	sub	w10, w26, #0x1
10116e444:	80 5a 6a fc	ldr	d0, [x20, w10, uxtw #3]
10116e448:	e9 a3 90 d2	mov	x9, #0x851f
10116e44c:	69 3d aa f2	movk	x9, #0x51eb, lsl #16
10116e450:	09 d7 c3 f2	movk	x9, #0x1eb8, lsl #32
10116e454:	29 fe e7 f2	movk	x9, #0x3ff1, lsl #48
10116e458:	21 01 67 9e	fmov	d1, x9
10116e45c:	00 20 61 1e	fcmp	d0, d1
10116e460:	ed 9b 40 f9	ldr	x13, [sp, #0x130]
10116e464:	ef 83 40 f9	ldr	x15, [sp, #0x100]
10116e468:	cd 00 00 54	b.le	0x10116e480
10116e46c:	e9 e7 02 b2	mov	x9, #-0x3333333333333334
10116e470:	c9 fe e7 f2	movk	x9, #0x3ff6, lsl #48
10116e474:	21 01 67 9e	fmov	d1, x9
10116e478:	00 20 61 1e	fcmp	d0, d1
10116e47c:	8b 01 00 54	b.lt	0x10116e4ac
10116e480:	11 00 80 52	mov	w17, #0x0
10116e484:	e9 e7 00 b2	mov	x9, #0x3333333333333333
10116e488:	89 66 86 f2	movk	x9, #0x3334
10116e48c:	29 ff e7 f2	movk	x9, #0x3ff9, lsl #48
10116e490:	21 01 67 9e	fmov	d1, x9
10116e494:	00 20 61 1e	fcmp	d0, d1
10116e498:	cd b2 00 54	b.le	0x10116faf0
10116e49c:	81 01 67 9e	fmov	d1, x12
10116e4a0:	00 20 61 1e	fcmp	d0, d1
10116e4a4:	f4 03 1a aa	mov	x20, x26
10116e4a8:	2a 86 00 54	b.ge	0x10116f56c
10116e4ac:	49 0b 00 71	subs	w9, w26, #0x2
10116e4b0:	a3 85 00 54	b.lo	0x10116f564
10116e4b4:	eb 8b 40 f9	ldr	x11, [sp, #0x110]
10116e4b8:	60 59 69 fc	ldr	d0, [x11, w9, uxtw #3]
10116e4bc:	eb a3 90 d2	mov	x11, #0x851f
10116e4c0:	6b 3d aa f2	movk	x11, #0x51eb, lsl #16
10116e4c4:	0b d7 c3 f2	movk	x11, #0x1eb8, lsl #32
10116e4c8:	2b fe e7 f2	movk	x11, #0x3ff1, lsl #48
10116e4cc:	61 01 67 9e	fmov	d1, x11
10116e4d0:	00 20 61 1e	fcmp	d0, d1
10116e4d4:	cd 00 00 54	b.le	0x10116e4ec
10116e4d8:	eb e7 02 b2	mov	x11, #-0x3333333333333334
10116e4dc:	cb fe e7 f2	movk	x11, #0x3ff6, lsl #48
10116e4e0:	61 01 67 9e	fmov	d1, x11
10116e4e4:	00 20 61 1e	fcmp	d0, d1
10116e4e8:	8b 01 00 54	b.lt	0x10116e518
10116e4ec:	11 00 80 52	mov	w17, #0x0
10116e4f0:	eb e7 00 b2	mov	x11, #0x3333333333333333
10116e4f4:	8b 66 86 f2	movk	x11, #0x3334
10116e4f8:	2b ff e7 f2	movk	x11, #0x3ff9, lsl #48
10116e4fc:	61 01 67 9e	fmov	d1, x11
10116e500:	00 20 61 1e	fcmp	d0, d1
10116e504:	ed 0a 00 54	b.le	0x10116e660
10116e508:	81 01 67 9e	fmov	d1, x12
10116e50c:	00 20 61 1e	fcmp	d0, d1
10116e510:	f4 03 0a aa	mov	x20, x10
10116e514:	ca 82 00 54	b.ge	0x10116f56c
10116e518:	4a 0f 00 71	subs	w10, w26, #0x3
10116e51c:	43 82 00 54	b.lo	0x10116f564
10116e520:	eb 8b 40 f9	ldr	x11, [sp, #0x110]
10116e524:	60 59 6a fc	ldr	d0, [x11, w10, uxtw #3]
10116e528:	eb a3 90 d2	mov	x11, #0x851f
10116e52c:	6b 3d aa f2	movk	x11, #0x51eb, lsl #16
10116e530:	0b d7 c3 f2	movk	x11, #0x1eb8, lsl #32
10116e534:	2b fe e7 f2	movk	x11, #0x3ff1, lsl #48
10116e538:	61 01 67 9e	fmov	d1, x11
10116e53c:	00 20 61 1e	fcmp	d0, d1
10116e540:	cd 00 00 54	b.le	0x10116e558
10116e544:	eb e7 02 b2	mov	x11, #-0x3333333333333334
10116e548:	cb fe e7 f2	movk	x11, #0x3ff6, lsl #48
10116e54c:	61 01 67 9e	fmov	d1, x11
10116e550:	00 20 61 1e	fcmp	d0, d1
10116e554:	8b 01 00 54	b.lt	0x10116e584
10116e558:	11 00 80 52	mov	w17, #0x0
10116e55c:	eb e7 00 b2	mov	x11, #0x3333333333333333
10116e560:	8b 66 86 f2	movk	x11, #0x3334
10116e564:	2b ff e7 f2	movk	x11, #0x3ff9, lsl #48
10116e568:	61 01 67 9e	fmov	d1, x11
10116e56c:	00 20 61 1e	fcmp	d0, d1
10116e570:	ed ab 03 54	b.le	0x101175aec
10116e574:	81 01 67 9e	fmov	d1, x12
10116e578:	00 20 61 1e	fcmp	d0, d1
10116e57c:	f4 03 09 aa	mov	x20, x9
10116e580:	6a 7f 00 54	b.ge	0x10116f56c
10116e584:	49 13 00 71	subs	w9, w26, #0x4
10116e588:	e3 7e 00 54	b.lo	0x10116f564
10116e58c:	eb 8b 40 f9	ldr	x11, [sp, #0x110]
10116e590:	60 59 69 fc	ldr	d0, [x11, w9, uxtw #3]
10116e594:	eb a3 90 d2	mov	x11, #0x851f
10116e598:	6b 3d aa f2	movk	x11, #0x51eb, lsl #16
10116e59c:	0b d7 c3 f2	movk	x11, #0x1eb8, lsl #32
10116e5a0:	2b fe e7 f2	movk	x11, #0x3ff1, lsl #48
10116e5a4:	61 01 67 9e	fmov	d1, x11
10116e5a8:	00 20 61 1e	fcmp	d0, d1
10116e5ac:	cd 00 00 54	b.le	0x10116e5c4
10116e5b0:	eb e7 02 b2	mov	x11, #-0x3333333333333334
10116e5b4:	cb fe e7 f2	movk	x11, #0x3ff6, lsl #48
10116e5b8:	61 01 67 9e	fmov	d1, x11
10116e5bc:	00 20 61 1e	fcmp	d0, d1
10116e5c0:	8b 01 00 54	b.lt	0x10116e5f0
10116e5c4:	11 00 80 52	mov	w17, #0x0
10116e5c8:	eb e7 00 b2	mov	x11, #0x3333333333333333
10116e5cc:	8b 66 86 f2	movk	x11, #0x3334
10116e5d0:	2b ff e7 f2	movk	x11, #0x3ff9, lsl #48
10116e5d4:	61 01 67 9e	fmov	d1, x11
10116e5d8:	00 20 61 1e	fcmp	d0, d1
10116e5dc:	2d 04 00 54	b.le	0x10116e660
10116e5e0:	81 01 67 9e	fmov	d1, x12
10116e5e4:	00 20 61 1e	fcmp	d0, d1
10116e5e8:	f4 03 0a aa	mov	x20, x10
10116e5ec:	0a 7c 00 54	b.ge	0x10116f56c
10116e5f0:	4a 17 00 71	subs	w10, w26, #0x5
10116e5f4:	83 7b 00 54	b.lo	0x10116f564
10116e5f8:	eb 8b 40 f9	ldr	x11, [sp, #0x110]
10116e5fc:	60 59 6a fc	ldr	d0, [x11, w10, uxtw #3]
10116e600:	eb a3 90 d2	mov	x11, #0x851f
10116e604:	6b 3d aa f2	movk	x11, #0x51eb, lsl #16
10116e608:	0b d7 c3 f2	movk	x11, #0x1eb8, lsl #32
10116e60c:	2b fe e7 f2	movk	x11, #0x3ff1, lsl #48
10116e610:	61 01 67 9e	fmov	d1, x11
10116e614:	00 20 61 1e	fcmp	d0, d1
10116e618:	cd 00 00 54	b.le	0x10116e630
10116e61c:	eb e7 02 b2	mov	x11, #-0x3333333333333334
10116e620:	cb fe e7 f2	movk	x11, #0x3ff6, lsl #48
10116e624:	61 01 67 9e	fmov	d1, x11
10116e628:	00 20 61 1e	fcmp	d0, d1
10116e62c:	8b 01 00 54	b.lt	0x10116e65c
10116e630:	11 00 80 52	mov	w17, #0x0
10116e634:	eb e7 00 b2	mov	x11, #0x3333333333333333
10116e638:	8b 66 86 f2	movk	x11, #0x3334
10116e63c:	2b ff e7 f2	movk	x11, #0x3ff9, lsl #48
10116e640:	61 01 67 9e	fmov	d1, x11
10116e644:	00 20 61 1e	fcmp	d0, d1
10116e648:	2d a5 03 54	b.le	0x101175aec
10116e64c:	81 01 67 9e	fmov	d1, x12
10116e650:	00 20 61 1e	fcmp	d0, d1
10116e654:	f4 03 09 aa	mov	x20, x9
10116e658:	aa 78 00 54	b.ge	0x10116f56c
10116e65c:	31 00 80 52	mov	w17, #0x1
10116e660:	f4 03 0a aa	mov	x20, x10
10116e664:	c2 03 00 14	b	0x10116f56c
10116e668:	63 2a 74 1e	fadd	d3, d19, d20
10116e66c:	63 28 76 1e	fadd	d3, d3, d22
10116e670:	eb f3 00 b2	mov	x11, #0x5555555555555555
10116e674:	ab fa e7 f2	movk	x11, #0x3fd5, lsl #48
10116e678:	64 01 67 9e	fmov	d4, x11
10116e67c:	63 08 64 1e	fmul	d3, d3, d4
10116e680:	8b 3f 95 d2	mov	x11, #0xa9fc
10116e684:	2b 5e ba f2	movk	x11, #0xd2f1, lsl #16
10116e688:	ab 49 cc f2	movk	x11, #0x624d, lsl #32
10116e68c:	0b f0 e7 f2	movk	x11, #0x3f80, lsl #48
10116e690:	64 01 67 9e	fmov	d4, x11
10116e694:	60 20 64 1e	fcmp	d3, d4
10116e698:	f8 87 40 f9	ldr	x24, [sp, #0x108]
10116e69c:	fc 97 40 f9	ldr	x28, [sp, #0x128]
10116e6a0:	8a 12 00 54	b.ge	0x10116e8f0
10116e6a4:	6e 12 f8 37	tbnz	w14, #0x1f, 0x10116e8f0
10116e6a8:	7f 20 00 71	cmp	w3, #0x8
10116e6ac:	2b 12 00 54	b.lt	0x10116e8f0
10116e6b0:	0b d7 83 d2	mov	x11, #0x1eb8
10116e6b4:	ab 70 bd f2	movk	x11, #0xeb85, lsl #16
10116e6b8:	2b 0a d7 f2	movk	x11, #0xb851, lsl #32
10116e6bc:	cb f1 e7 f2	movk	x11, #0x3f8e, lsl #48
10116e6c0:	63 01 67 9e	fmov	d3, x11
10116e6c4:	00 22 63 1e	fcmp	d16, d3
10116e6c8:	4a 11 00 54	b.ge	0x10116e8f0
10116e6cc:	6e 7c 00 34	cbz	w14, 0x10116f658
10116e6d0:	c9 05 00 51	sub	w9, w14, #0x1
10116e6d4:	80 5a 69 fc	ldr	d0, [x20, w9, uxtw #3]
10116e6d8:	e8 a3 90 d2	mov	x8, #0x851f
10116e6dc:	68 3d aa f2	movk	x8, #0x51eb, lsl #16
10116e6e0:	08 d7 c3 f2	movk	x8, #0x1eb8, lsl #32
10116e6e4:	28 fe e7 f2	movk	x8, #0x3ff1, lsl #48
10116e6e8:	01 01 67 9e	fmov	d1, x8
10116e6ec:	00 20 61 1e	fcmp	d0, d1
10116e6f0:	f8 9b 40 f9	ldr	x24, [sp, #0x130]
10116e6f4:	ed e7 02 b2	mov	x13, #-0x3333333333333334
10116e6f8:	ad 99 99 f2	movk	x13, #0xcccd
10116e6fc:	8d ff e7 f2	movk	x13, #0x3ffc, lsl #48
10116e700:	cd 00 00 54	b.le	0x10116e718
10116e704:	e8 e7 02 b2	mov	x8, #-0x3333333333333334
10116e708:	c8 fe e7 f2	movk	x8, #0x3ff6, lsl #48
10116e70c:	01 01 67 9e	fmov	d1, x8
10116e710:	00 20 61 1e	fcmp	d0, d1
10116e714:	8b 01 00 54	b.lt	0x10116e744
10116e718:	11 00 80 52	mov	w17, #0x0
10116e71c:	e8 e7 00 b2	mov	x8, #0x3333333333333333
10116e720:	88 66 86 f2	movk	x8, #0x3334
10116e724:	28 ff e7 f2	movk	x8, #0x3ff9, lsl #48
10116e728:	01 01 67 9e	fmov	d1, x8
10116e72c:	00 20 61 1e	fcmp	d0, d1
10116e730:	0d a6 00 54	b.le	0x10116fbf0
10116e734:	a1 01 67 9e	fmov	d1, x13
10116e738:	00 20 61 1e	fcmp	d0, d1
10116e73c:	f3 03 0e aa	mov	x19, x14
10116e740:	ea 79 00 54	b.ge	0x10116f67c
10116e744:	c8 09 00 71	subs	w8, w14, #0x2
10116e748:	63 79 00 54	b.lo	0x10116f674
10116e74c:	80 5a 68 fc	ldr	d0, [x20, w8, uxtw #3]
10116e750:	eb a3 90 d2	mov	x11, #0x851f
10116e754:	6b 3d aa f2	movk	x11, #0x51eb, lsl #16
10116e758:	0b d7 c3 f2	movk	x11, #0x1eb8, lsl #32
10116e75c:	2b fe e7 f2	movk	x11, #0x3ff1, lsl #48
10116e760:	61 01 67 9e	fmov	d1, x11
10116e764:	00 20 61 1e	fcmp	d0, d1
10116e768:	cd 00 00 54	b.le	0x10116e780
10116e76c:	eb e7 02 b2	mov	x11, #-0x3333333333333334
10116e770:	cb fe e7 f2	movk	x11, #0x3ff6, lsl #48
10116e774:	61 01 67 9e	fmov	d1, x11
10116e778:	00 20 61 1e	fcmp	d0, d1
10116e77c:	8b 01 00 54	b.lt	0x10116e7ac
10116e780:	11 00 80 52	mov	w17, #0x0
10116e784:	eb e7 00 b2	mov	x11, #0x3333333333333333
10116e788:	8b 66 86 f2	movk	x11, #0x3334
10116e78c:	2b ff e7 f2	movk	x11, #0x3ff9, lsl #48
10116e790:	61 01 67 9e	fmov	d1, x11
10116e794:	00 20 61 1e	fcmp	d0, d1
10116e798:	8d 0a 00 54	b.le	0x10116e8e8
10116e79c:	a1 01 67 9e	fmov	d1, x13
10116e7a0:	00 20 61 1e	fcmp	d0, d1
10116e7a4:	f3 03 09 aa	mov	x19, x9
10116e7a8:	aa 76 00 54	b.ge	0x10116f67c
10116e7ac:	c9 0d 00 71	subs	w9, w14, #0x3
10116e7b0:	23 76 00 54	b.lo	0x10116f674
10116e7b4:	80 5a 69 fc	ldr	d0, [x20, w9, uxtw #3]
10116e7b8:	eb a3 90 d2	mov	x11, #0x851f
10116e7bc:	6b 3d aa f2	movk	x11, #0x51eb, lsl #16
10116e7c0:	0b d7 c3 f2	movk	x11, #0x1eb8, lsl #32
10116e7c4:	2b fe e7 f2	movk	x11, #0x3ff1, lsl #48
10116e7c8:	61 01 67 9e	fmov	d1, x11
10116e7cc:	00 20 61 1e	fcmp	d0, d1
10116e7d0:	cd 00 00 54	b.le	0x10116e7e8
10116e7d4:	eb e7 02 b2	mov	x11, #-0x3333333333333334
10116e7d8:	cb fe e7 f2	movk	x11, #0x3ff6, lsl #48
10116e7dc:	61 01 67 9e	fmov	d1, x11
10116e7e0:	00 20 61 1e	fcmp	d0, d1
10116e7e4:	8b 01 00 54	b.lt	0x10116e814
10116e7e8:	11 00 80 52	mov	w17, #0x0
10116e7ec:	eb e7 00 b2	mov	x11, #0x3333333333333333
10116e7f0:	8b 66 86 f2	movk	x11, #0x3334
10116e7f4:	2b ff e7 f2	movk	x11, #0x3ff9, lsl #48
10116e7f8:	61 01 67 9e	fmov	d1, x11
10116e7fc:	00 20 61 1e	fcmp	d0, d1
10116e800:	cd 10 04 54	b.le	0x101176a18
10116e804:	a1 01 67 9e	fmov	d1, x13
10116e808:	00 20 61 1e	fcmp	d0, d1
10116e80c:	f3 03 08 aa	mov	x19, x8
10116e810:	6a 73 00 54	b.ge	0x10116f67c
10116e814:	c8 11 00 71	subs	w8, w14, #0x4
10116e818:	e3 72 00 54	b.lo	0x10116f674
10116e81c:	80 5a 68 fc	ldr	d0, [x20, w8, uxtw #3]
10116e820:	eb a3 90 d2	mov	x11, #0x851f
10116e824:	6b 3d aa f2	movk	x11, #0x51eb, lsl #16
10116e828:	0b d7 c3 f2	movk	x11, #0x1eb8, lsl #32
10116e82c:	2b fe e7 f2	movk	x11, #0x3ff1, lsl #48
10116e830:	61 01 67 9e	fmov	d1, x11
10116e834:	00 20 61 1e	fcmp	d0, d1
10116e838:	cd 00 00 54	b.le	0x10116e850
10116e83c:	eb e7 02 b2	mov	x11, #-0x3333333333333334
10116e840:	cb fe e7 f2	movk	x11, #0x3ff6, lsl #48
10116e844:	61 01 67 9e	fmov	d1, x11
10116e848:	00 20 61 1e	fcmp	d0, d1
10116e84c:	8b 01 00 54	b.lt	0x10116e87c
10116e850:	11 00 80 52	mov	w17, #0x0
10116e854:	eb e7 00 b2	mov	x11, #0x3333333333333333
10116e858:	8b 66 86 f2	movk	x11, #0x3334
10116e85c:	2b ff e7 f2	movk	x11, #0x3ff9, lsl #48
10116e860:	61 01 67 9e	fmov	d1, x11
10116e864:	00 20 61 1e	fcmp	d0, d1
10116e868:	0d 04 00 54	b.le	0x10116e8e8
10116e86c:	a1 01 67 9e	fmov	d1, x13
10116e870:	00 20 61 1e	fcmp	d0, d1
10116e874:	f3 03 09 aa	mov	x19, x9
10116e878:	2a 70 00 54	b.ge	0x10116f67c
10116e87c:	c9 15 00 71	subs	w9, w14, #0x5
10116e880:	a3 6f 00 54	b.lo	0x10116f674
10116e884:	80 5a 69 fc	ldr	d0, [x20, w9, uxtw #3]
10116e888:	eb a3 90 d2	mov	x11, #0x851f
10116e88c:	6b 3d aa f2	movk	x11, #0x51eb, lsl #16
10116e890:	0b d7 c3 f2	movk	x11, #0x1eb8, lsl #32
10116e894:	2b fe e7 f2	movk	x11, #0x3ff1, lsl #48
10116e898:	61 01 67 9e	fmov	d1, x11
10116e89c:	00 20 61 1e	fcmp	d0, d1
10116e8a0:	cd 00 00 54	b.le	0x10116e8b8
10116e8a4:	eb e7 02 b2	mov	x11, #-0x3333333333333334
10116e8a8:	cb fe e7 f2	movk	x11, #0x3ff6, lsl #48
10116e8ac:	61 01 67 9e	fmov	d1, x11
10116e8b0:	00 20 61 1e	fcmp	d0, d1
10116e8b4:	8b 01 00 54	b.lt	0x10116e8e4
10116e8b8:	11 00 80 52	mov	w17, #0x0
10116e8bc:	eb e7 00 b2	mov	x11, #0x3333333333333333
10116e8c0:	8b 66 86 f2	movk	x11, #0x3334
10116e8c4:	2b ff e7 f2	movk	x11, #0x3ff9, lsl #48
10116e8c8:	61 01 67 9e	fmov	d1, x11
10116e8cc:	00 20 61 1e	fcmp	d0, d1
10116e8d0:	4d 0a 04 54	b.le	0x101176a18
10116e8d4:	a1 01 67 9e	fmov	d1, x13
10116e8d8:	00 20 61 1e	fcmp	d0, d1
10116e8dc:	f3 03 08 aa	mov	x19, x8
10116e8e0:	ea 6c 00 54	b.ge	0x10116f67c
10116e8e4:	31 00 80 52	mov	w17, #0x1
10116e8e8:	f3 03 09 aa	mov	x19, x9
10116e8ec:	64 03 00 14	b	0x10116f67c
10116e8f0:	0a d7 83 d2	mov	x10, #0x1eb8
10116e8f4:	aa 70 bd f2	movk	x10, #0xeb85, lsl #16
10116e8f8:	2a 0a d7 f2	movk	x10, #0xb851, lsl #32
10116e8fc:	0a ff e7 f2	movk	x10, #0x3ff8, lsl #48
10116e900:	43 01 67 9e	fmov	d3, x10
10116e904:	00 20 63 1e	fcmp	d0, d3
10116e908:	0a 2b 00 54	b.ge	0x10116ee68
10116e90c:	0a 29 9c d2	mov	x10, #0xe148
10116e910:	4a 8f a2 f2	movk	x10, #0x147a, lsl #16
10116e914:	ca f5 c8 f2	movk	x10, #0x47ae, lsl #32
10116e918:	ea fe e7 f2	movk	x10, #0x3ff7, lsl #48
10116e91c:	43 01 67 9e	fmov	d3, x10
10116e920:	00 20 63 1e	fcmp	d0, d3
10116e924:	2d 2a 00 54	b.le	0x10116ee68
10116e928:	8a 3f 95 d2	mov	x10, #0xa9fc
10116e92c:	2a 5e ba f2	movk	x10, #0xd2f1, lsl #16
10116e930:	aa 49 cc f2	movk	x10, #0x624d, lsl #32
10116e934:	0a f0 e7 f2	movk	x10, #0x3f80, lsl #48
10116e938:	43 01 67 9e	fmov	d3, x10
10116e93c:	40 20 63 1e	fcmp	d2, d3
10116e940:	4a 29 00 54	b.ge	0x10116ee68
10116e944:	3a 29 f8 37	tbnz	w26, #0x1f, 0x10116ee68
10116e948:	3f 21 00 71	cmp	w9, #0x8
10116e94c:	eb 28 00 54	b.lt	0x10116ee68
10116e950:	0a d7 83 d2	mov	x10, #0x1eb8
10116e954:	aa 70 bd f2	movk	x10, #0xeb85, lsl #16
10116e958:	2a 0a d7 f2	movk	x10, #0xb851, lsl #32
10116e95c:	ca f1 e7 f2	movk	x10, #0x3f8e, lsl #48
10116e960:	43 01 67 9e	fmov	d3, x10
10116e964:	20 20 63 1e	fcmp	d1, d3
10116e968:	0a 28 00 54	b.ge	0x10116ee68
10116e96c:	ba 6f 00 34	cbz	w26, 0x10116f760
10116e970:	4a 07 00 51	sub	w10, w26, #0x1
10116e974:	80 5a 6a fc	ldr	d0, [x20, w10, uxtw #3]
10116e978:	e9 a3 90 d2	mov	x9, #0x851f
10116e97c:	69 3d aa f2	movk	x9, #0x51eb, lsl #16
10116e980:	09 d7 c3 f2	movk	x9, #0x1eb8, lsl #32
10116e984:	29 fe e7 f2	movk	x9, #0x3ff1, lsl #48
10116e988:	21 01 67 9e	fmov	d1, x9
10116e98c:	00 20 61 1e	fcmp	d0, d1
10116e990:	ed 9b 40 f9	ldr	x13, [sp, #0x130]
10116e994:	ee e7 02 b2	mov	x14, #-0x3333333333333334
10116e998:	ae 99 99 f2	movk	x14, #0xcccd
10116e99c:	8e ff e7 f2	movk	x14, #0x3ffc, lsl #48
10116e9a0:	ef 03 10 aa	mov	x15, x16
10116e9a4:	f0 83 40 f9	ldr	x16, [sp, #0x100]
10116e9a8:	cd 00 00 54	b.le	0x10116e9c0
10116e9ac:	e9 e7 02 b2	mov	x9, #-0x3333333333333334
10116e9b0:	c9 fe e7 f2	movk	x9, #0x3ff6, lsl #48
10116e9b4:	21 01 67 9e	fmov	d1, x9
10116e9b8:	00 20 61 1e	fcmp	d0, d1
10116e9bc:	8b 01 00 54	b.lt	0x10116e9ec
10116e9c0:	11 00 80 52	mov	w17, #0x0
10116e9c4:	e9 e7 00 b2	mov	x9, #0x3333333333333333
10116e9c8:	89 66 86 f2	movk	x9, #0x3334
10116e9cc:	29 ff e7 f2	movk	x9, #0x3ff9, lsl #48
10116e9d0:	21 01 67 9e	fmov	d1, x9
10116e9d4:	00 20 61 1e	fcmp	d0, d1
10116e9d8:	cd e1 00 54	b.le	0x101170610
10116e9dc:	c1 01 67 9e	fmov	d1, x14
10116e9e0:	00 20 61 1e	fcmp	d0, d1
10116e9e4:	e1 03 1a aa	mov	x1, x26
10116e9e8:	2a 6d 00 54	b.ge	0x10116f78c
10116e9ec:	49 0b 00 71	subs	w9, w26, #0x2
10116e9f0:	a3 6c 00 54	b.lo	0x10116f784
10116e9f4:	eb 8b 40 f9	ldr	x11, [sp, #0x110]
10116e9f8:	60 59 69 fc	ldr	d0, [x11, w9, uxtw #3]
10116e9fc:	eb a3 90 d2	mov	x11, #0x851f
10116ea00:	6b 3d aa f2	movk	x11, #0x51eb, lsl #16
10116ea04:	0b d7 c3 f2	movk	x11, #0x1eb8, lsl #32
10116ea08:	2b fe e7 f2	movk	x11, #0x3ff1, lsl #48
10116ea0c:	61 01 67 9e	fmov	d1, x11
10116ea10:	00 20 61 1e	fcmp	d0, d1
10116ea14:	cd 00 00 54	b.le	0x10116ea2c
10116ea18:	eb e7 02 b2	mov	x11, #-0x3333333333333334
10116ea1c:	cb fe e7 f2	movk	x11, #0x3ff6, lsl #48
10116ea20:	61 01 67 9e	fmov	d1, x11
10116ea24:	00 20 61 1e	fcmp	d0, d1
10116ea28:	8b 01 00 54	b.lt	0x10116ea58
10116ea2c:	11 00 80 52	mov	w17, #0x0
10116ea30:	eb e7 00 b2	mov	x11, #0x3333333333333333
10116ea34:	8b 66 86 f2	movk	x11, #0x3334
10116ea38:	2b ff e7 f2	movk	x11, #0x3ff9, lsl #48
10116ea3c:	61 01 67 9e	fmov	d1, x11
10116ea40:	00 20 61 1e	fcmp	d0, d1
10116ea44:	ed 0a 00 54	b.le	0x10116eba0
10116ea48:	c1 01 67 9e	fmov	d1, x14
10116ea4c:	00 20 61 1e	fcmp	d0, d1
10116ea50:	e1 03 0a aa	mov	x1, x10
10116ea54:	ca 69 00 54	b.ge	0x10116f78c
10116ea58:	4a 0f 00 71	subs	w10, w26, #0x3
10116ea5c:	43 69 00 54	b.lo	0x10116f784
10116ea60:	eb 8b 40 f9	ldr	x11, [sp, #0x110]
10116ea64:	60 59 6a fc	ldr	d0, [x11, w10, uxtw #3]
10116ea68:	eb a3 90 d2	mov	x11, #0x851f
10116ea6c:	6b 3d aa f2	movk	x11, #0x51eb, lsl #16
10116ea70:	0b d7 c3 f2	movk	x11, #0x1eb8, lsl #32
10116ea74:	2b fe e7 f2	movk	x11, #0x3ff1, lsl #48
10116ea78:	61 01 67 9e	fmov	d1, x11
10116ea7c:	00 20 61 1e	fcmp	d0, d1
10116ea80:	cd 00 00 54	b.le	0x10116ea98
10116ea84:	eb e7 02 b2	mov	x11, #-0x3333333333333334
10116ea88:	cb fe e7 f2	movk	x11, #0x3ff6, lsl #48
10116ea8c:	61 01 67 9e	fmov	d1, x11
10116ea90:	00 20 61 1e	fcmp	d0, d1
10116ea94:	8b 01 00 54	b.lt	0x10116eac4
10116ea98:	11 00 80 52	mov	w17, #0x0
10116ea9c:	eb e7 00 b2	mov	x11, #0x3333333333333333
10116eaa0:	8b 66 86 f2	movk	x11, #0x3334
10116eaa4:	2b ff e7 f2	movk	x11, #0x3ff9, lsl #48
10116eaa8:	61 01 67 9e	fmov	d1, x11
10116eaac:	00 20 61 1e	fcmp	d0, d1
10116eab0:	8d fb 03 54	b.le	0x101176a20
10116eab4:	c1 01 67 9e	fmov	d1, x14
10116eab8:	00 20 61 1e	fcmp	d0, d1
10116eabc:	e1 03 09 aa	mov	x1, x9
10116eac0:	6a 66 00 54	b.ge	0x10116f78c
10116eac4:	49 13 00 71	subs	w9, w26, #0x4
10116eac8:	e3 65 00 54	b.lo	0x10116f784
10116eacc:	eb 8b 40 f9	ldr	x11, [sp, #0x110]
10116ead0:	60 59 69 fc	ldr	d0, [x11, w9, uxtw #3]
10116ead4:	eb a3 90 d2	mov	x11, #0x851f
10116ead8:	6b 3d aa f2	movk	x11, #0x51eb, lsl #16
10116eadc:	0b d7 c3 f2	movk	x11, #0x1eb8, lsl #32
10116eae0:	2b fe e7 f2	movk	x11, #0x3ff1, lsl #48
10116eae4:	61 01 67 9e	fmov	d1, x11
10116eae8:	00 20 61 1e	fcmp	d0, d1
10116eaec:	cd 00 00 54	b.le	0x10116eb04
10116eaf0:	eb e7 02 b2	mov	x11, #-0x3333333333333334
10116eaf4:	cb fe e7 f2	movk	x11, #0x3ff6, lsl #48
10116eaf8:	61 01 67 9e	fmov	d1, x11
10116eafc:	00 20 61 1e	fcmp	d0, d1
10116eb00:	8b 01 00 54	b.lt	0x10116eb30
10116eb04:	11 00 80 52	mov	w17, #0x0
10116eb08:	eb e7 00 b2	mov	x11, #0x3333333333333333
10116eb0c:	8b 66 86 f2	movk	x11, #0x3334
10116eb10:	2b ff e7 f2	movk	x11, #0x3ff9, lsl #48
10116eb14:	61 01 67 9e	fmov	d1, x11
10116eb18:	00 20 61 1e	fcmp	d0, d1
10116eb1c:	2d 04 00 54	b.le	0x10116eba0
10116eb20:	c1 01 67 9e	fmov	d1, x14
10116eb24:	00 20 61 1e	fcmp	d0, d1
10116eb28:	e1 03 0a aa	mov	x1, x10
10116eb2c:	0a 63 00 54	b.ge	0x10116f78c
10116eb30:	4a 17 00 71	subs	w10, w26, #0x5
10116eb34:	83 62 00 54	b.lo	0x10116f784
10116eb38:	eb 8b 40 f9	ldr	x11, [sp, #0x110]
10116eb3c:	60 59 6a fc	ldr	d0, [x11, w10, uxtw #3]
10116eb40:	eb a3 90 d2	mov	x11, #0x851f
10116eb44:	6b 3d aa f2	movk	x11, #0x51eb, lsl #16
10116eb48:	0b d7 c3 f2	movk	x11, #0x1eb8, lsl #32
10116eb4c:	2b fe e7 f2	movk	x11, #0x3ff1, lsl #48
10116eb50:	61 01 67 9e	fmov	d1, x11
10116eb54:	00 20 61 1e	fcmp	d0, d1
10116eb58:	cd 00 00 54	b.le	0x10116eb70
10116eb5c:	eb e7 02 b2	mov	x11, #-0x3333333333333334
10116eb60:	cb fe e7 f2	movk	x11, #0x3ff6, lsl #48
10116eb64:	61 01 67 9e	fmov	d1, x11
10116eb68:	00 20 61 1e	fcmp	d0, d1
10116eb6c:	8b 01 00 54	b.lt	0x10116eb9c
10116eb70:	11 00 80 52	mov	w17, #0x0
10116eb74:	eb e7 00 b2	mov	x11, #0x3333333333333333
10116eb78:	8b 66 86 f2	movk	x11, #0x3334
10116eb7c:	2b ff e7 f2	movk	x11, #0x3ff9, lsl #48
10116eb80:	61 01 67 9e	fmov	d1, x11
10116eb84:	00 20 61 1e	fcmp	d0, d1
10116eb88:	cd f4 03 54	b.le	0x101176a20
10116eb8c:	c1 01 67 9e	fmov	d1, x14
10116eb90:	00 20 61 1e	fcmp	d0, d1
10116eb94:	e1 03 09 aa	mov	x1, x9
10116eb98:	aa 5f 00 54	b.ge	0x10116f78c
10116eb9c:	31 00 80 52	mov	w17, #0x1
10116eba0:	e1 03 0a aa	mov	x1, x10
10116eba4:	fa 02 00 14	b	0x10116f78c
10116eba8:	2b 05 00 91	add	x11, x9, #0x1
10116ebac:	6c 75 7d 92	and	x12, x11, #0x1fffffff8
10116ebb0:	8a 01 0f 8b	add	x10, x12, x15
10116ebb4:	ed 57 40 f9	ldr	x13, [sp, #0xa8]
10116ebb8:	ad 0d 0f 8b	add	x13, x13, x15, lsl #3
10116ebbc:	01 e4 00 6f	movi.2d	v1, #0000000000000000
10116ebc0:	ee 03 0c aa	mov	x14, x12
10116ebc4:	02 e4 00 6f	movi.2d	v2, #0000000000000000
10116ebc8:	03 e4 00 6f	movi.2d	v3, #0000000000000000
10116ebcc:	04 e4 00 6f	movi.2d	v4, #0000000000000000
10116ebd0:	a5 19 7f ad	ldp	q5, q6, [x13, #-0x20]
10116ebd4:	a7 41 c2 ac	ldp	q7, q16, [x13], #0x40
10116ebd8:	a1 d4 61 4e	fadd.2d	v1, v5, v1
10116ebdc:	c2 d4 62 4e	fadd.2d	v2, v6, v2
10116ebe0:	e3 d4 63 4e	fadd.2d	v3, v7, v3
10116ebe4:	04 d6 64 4e	fadd.2d	v4, v16, v4
10116ebe8:	ce 21 00 f1	subs	x14, x14, #0x8
10116ebec:	21 ff ff 54	b.ne	0x10116ebd0
10116ebf0:	41 d4 61 4e	fadd.2d	v1, v2, v1
10116ebf4:	61 d4 61 4e	fadd.2d	v1, v3, v1
10116ebf8:	81 d4 61 4e	fadd.2d	v1, v4, v1
10116ebfc:	21 d8 70 7e	faddp.2d	d1, v1
10116ec00:	7f 01 0c eb	cmp	x11, x12
10116ec04:	00 01 00 54	b.eq	0x10116ec24
10116ec08:	8b 0e 0a 8b	add	x11, x20, x10, lsl #3
10116ec0c:	0a 01 0a 4b	sub	w10, w8, w10
10116ec10:	4a 05 00 11	add	w10, w10, #0x1
10116ec14:	62 85 40 fc	ldr	d2, [x11], #0x8
10116ec18:	41 28 61 1e	fadd	d1, d2, d1
10116ec1c:	4a 05 00 71	subs	w10, w10, #0x1
10116ec20:	a1 ff ff 54	b.ne	0x10116ec14
10116ec24:	4b 23 00 71	subs	w11, w26, #0x8
10116ec28:	0a 01 80 52	mov	w10, #0x8
10116ec2c:	4a b3 8a 1a	csel	w10, w26, w10, lt
10116ec30:	4c 07 00 71	subs	w12, w26, #0x1
10116ec34:	ab 04 00 54	b.lt	0x10116ecc8
10116ec38:	80 da 6c fc	ldr	d0, [x20, w12, sxtw #3]
10116ec3c:	5f 05 00 71	cmp	w10, #0x1
10116ec40:	4c c5 9f 1a	csinc	w12, w10, wzr, gt
10116ec44:	2d 04 00 54	b.le	0x10116ecc8
10116ec48:	4d 0b 00 51	sub	w13, w26, #0x2
10116ec4c:	82 da 6d fc	ldr	d2, [x20, w13, sxtw #3]
10116ec50:	40 28 60 1e	fadd	d0, d2, d0
10116ec54:	9f 09 00 71	cmp	w12, #0x2
10116ec58:	80 03 00 54	b.eq	0x10116ecc8
10116ec5c:	4d 0f 00 51	sub	w13, w26, #0x3
10116ec60:	82 da 6d fc	ldr	d2, [x20, w13, sxtw #3]
10116ec64:	40 28 60 1e	fadd	d0, d2, d0
10116ec68:	9f 0d 00 71	cmp	w12, #0x3
10116ec6c:	e0 02 00 54	b.eq	0x10116ecc8
10116ec70:	4d 13 00 51	sub	w13, w26, #0x4
10116ec74:	82 da 6d fc	ldr	d2, [x20, w13, sxtw #3]
10116ec78:	40 28 60 1e	fadd	d0, d2, d0
10116ec7c:	9f 11 00 71	cmp	w12, #0x4
10116ec80:	40 02 00 54	b.eq	0x10116ecc8
10116ec84:	4d 17 00 51	sub	w13, w26, #0x5
10116ec88:	82 da 6d fc	ldr	d2, [x20, w13, sxtw #3]
10116ec8c:	40 28 60 1e	fadd	d0, d2, d0
10116ec90:	9f 15 00 71	cmp	w12, #0x5
10116ec94:	a0 01 00 54	b.eq	0x10116ecc8
10116ec98:	4d 1b 00 51	sub	w13, w26, #0x6
10116ec9c:	82 da 6d fc	ldr	d2, [x20, w13, sxtw #3]
10116eca0:	40 28 60 1e	fadd	d0, d2, d0
10116eca4:	9f 19 00 71	cmp	w12, #0x6
10116eca8:	00 01 00 54	b.eq	0x10116ecc8
10116ecac:	4d 1f 00 51	sub	w13, w26, #0x7
10116ecb0:	82 da 6d fc	ldr	d2, [x20, w13, sxtw #3]
10116ecb4:	40 28 60 1e	fadd	d0, d2, d0
10116ecb8:	9f 1d 00 71	cmp	w12, #0x7
10116ecbc:	60 00 00 54	b.eq	0x10116ecc8
10116ecc0:	82 da 6b fc	ldr	d2, [x20, w11, sxtw #3]
10116ecc4:	40 28 60 1e	fadd	d0, d2, d0
10116ecc8:	eb 03 28 2a	mvn	w11, w8
10116eccc:	ec 00 0b 0b	add	w12, w7, w11
10116ecd0:	9f 21 00 71	cmp	w12, #0x8
10116ecd4:	0b 01 80 52	mov	w11, #0x8
10116ecd8:	8b b1 8b 1a	csel	w11, w12, w11, lt
10116ecdc:	9f 05 00 71	cmp	w12, #0x1
10116ece0:	2b 05 00 54	b.lt	0x10116ed84
10116ece4:	7f 05 00 71	cmp	w11, #0x1
10116ece8:	6c c5 9f 1a	csinc	w12, w11, wzr, gt
10116ecec:	0d 05 00 11	add	w13, w8, #0x1
10116ecf0:	82 da 6d fc	ldr	d2, [x20, w13, sxtw #3]
10116ecf4:	40 28 60 1e	fadd	d0, d2, d0
10116ecf8:	7f 09 00 71	cmp	w11, #0x2
10116ecfc:	4b 04 00 54	b.lt	0x10116ed84
10116ed00:	0d 09 00 11	add	w13, w8, #0x2
10116ed04:	82 da 6d fc	ldr	d2, [x20, w13, sxtw #3]
10116ed08:	40 28 60 1e	fadd	d0, d2, d0
10116ed0c:	9f 09 00 71	cmp	w12, #0x2
10116ed10:	a0 03 00 54	b.eq	0x10116ed84
10116ed14:	0d 0d 00 11	add	w13, w8, #0x3
10116ed18:	82 da 6d fc	ldr	d2, [x20, w13, sxtw #3]
10116ed1c:	40 28 60 1e	fadd	d0, d2, d0
10116ed20:	9f 0d 00 71	cmp	w12, #0x3
10116ed24:	00 03 00 54	b.eq	0x10116ed84
10116ed28:	0d 11 00 11	add	w13, w8, #0x4
10116ed2c:	82 da 6d fc	ldr	d2, [x20, w13, sxtw #3]
10116ed30:	40 28 60 1e	fadd	d0, d2, d0
10116ed34:	9f 11 00 71	cmp	w12, #0x4
10116ed38:	60 02 00 54	b.eq	0x10116ed84
10116ed3c:	0d 15 00 11	add	w13, w8, #0x5
10116ed40:	82 da 6d fc	ldr	d2, [x20, w13, sxtw #3]
10116ed44:	40 28 60 1e	fadd	d0, d2, d0
10116ed48:	9f 15 00 71	cmp	w12, #0x5
10116ed4c:	c0 01 00 54	b.eq	0x10116ed84
10116ed50:	0d 19 00 11	add	w13, w8, #0x6
10116ed54:	82 da 6d fc	ldr	d2, [x20, w13, sxtw #3]
10116ed58:	40 28 60 1e	fadd	d0, d2, d0
10116ed5c:	9f 19 00 71	cmp	w12, #0x6
10116ed60:	20 01 00 54	b.eq	0x10116ed84
10116ed64:	0d 1d 00 11	add	w13, w8, #0x7
10116ed68:	82 da 6d fc	ldr	d2, [x20, w13, sxtw #3]
10116ed6c:	40 28 60 1e	fadd	d0, d2, d0
10116ed70:	9f 1d 00 71	cmp	w12, #0x7
10116ed74:	80 00 00 54	b.eq	0x10116ed84
10116ed78:	0c 21 00 11	add	w12, w8, #0x8
10116ed7c:	82 da 6c fc	ldr	d2, [x20, w12, sxtw #3]
10116ed80:	40 28 60 1e	fadd	d0, d2, d0
10116ed84:	29 05 00 11	add	w9, w9, #0x1
10116ed88:	22 01 62 1e	scvtf	d2, w9
10116ed8c:	21 18 62 1e	fdiv	d1, d1, d2
10116ed90:	49 01 0b 2b	adds	w9, w10, w11
10116ed94:	22 01 62 1e	scvtf	d2, w9
10116ed98:	02 18 62 1e	fdiv	d2, d0, d2
10116ed9c:	00 0c 62 1e	fcsel	d0, d0, d2, eq
10116eda0:	20 38 60 1e	fsub	d0, d1, d0
10116eda4:	69 8f 82 d2	mov	x9, #0x147b
10116eda8:	c9 f5 a8 f2	movk	x9, #0x47ae, lsl #16
10116edac:	29 5c cf f2	movk	x9, #0x7ae1, lsl #32
10116edb0:	89 f8 e7 f2	movk	x9, #0x3fc4, lsl #48
10116edb4:	21 01 67 9e	fmov	d1, x9
10116edb8:	00 20 61 1e	fcmp	d0, d1
10116edbc:	6d 5e ff 54	b.le	0x10116d988
10116edc0:	4a 07 00 71	subs	w10, w26, #0x1
10116edc4:	eb 1a 00 54	b.lt	0x10116f120
10116edc8:	80 5a 6a fc	ldr	d0, [x20, w10, uxtw #3]
10116edcc:	e9 a3 90 d2	mov	x9, #0x851f
10116edd0:	69 3d aa f2	movk	x9, #0x51eb, lsl #16
10116edd4:	09 d7 c3 f2	movk	x9, #0x1eb8, lsl #32
10116edd8:	29 fe e7 f2	movk	x9, #0x3ff1, lsl #48
10116eddc:	21 01 67 9e	fmov	d1, x9
10116ede0:	00 20 61 1e	fcmp	d0, d1
10116ede4:	e9 03 1a aa	mov	x9, x26
10116ede8:	0d 2a 00 54	b.le	0x10116f328
10116edec:	ca 7a 33 b8	str	w10, [x22, x19, lsl #2]
10116edf0:	4b 0b 00 71	subs	w11, w26, #0x2
10116edf4:	83 29 00 54	b.lo	0x10116f324
10116edf8:	80 5a 6b fc	ldr	d0, [x20, w11, uxtw #3]
10116edfc:	e9 a3 90 d2	mov	x9, #0x851f
10116ee00:	69 3d aa f2	movk	x9, #0x51eb, lsl #16
10116ee04:	09 d7 c3 f2	movk	x9, #0x1eb8, lsl #32
10116ee08:	29 fe e7 f2	movk	x9, #0x3ff1, lsl #48
10116ee0c:	21 01 67 9e	fmov	d1, x9
10116ee10:	00 20 61 1e	fcmp	d0, d1
10116ee14:	e9 03 0a aa	mov	x9, x10
10116ee18:	8d 28 00 54	b.le	0x10116f328
10116ee1c:	cb 7a 33 b8	str	w11, [x22, x19, lsl #2]
10116ee20:	5f 09 00 71	cmp	w10, #0x2
10116ee24:	03 58 00 54	b.lo	0x10116f924
10116ee28:	4a 0f 00 51	sub	w10, w26, #0x3
10116ee2c:	80 5a 6a fc	ldr	d0, [x20, w10, uxtw #3]
10116ee30:	e9 a3 90 d2	mov	x9, #0x851f
10116ee34:	69 3d aa f2	movk	x9, #0x51eb, lsl #16
10116ee38:	09 d7 c3 f2	movk	x9, #0x1eb8, lsl #32
10116ee3c:	29 fe e7 f2	movk	x9, #0x3ff1, lsl #48
10116ee40:	21 01 67 9e	fmov	d1, x9
10116ee44:	00 20 61 1e	fcmp	d0, d1
10116ee48:	e9 03 0b aa	mov	x9, x11
10116ee4c:	ed 26 00 54	b.le	0x10116f328
10116ee50:	ca 7a 33 b8	str	w10, [x22, x19, lsl #2]
10116ee54:	e9 03 0a aa	mov	x9, x10
10116ee58:	ea 08 00 51	sub	w10, w7, #0x2
10116ee5c:	1f 01 0a 6b	cmp	w8, w10
10116ee60:	ab 26 00 54	b.lt	0x10116f334
10116ee64:	b3 00 00 14	b	0x10116f130
10116ee68:	43 2b 75 1e	fadd	d3, d26, d21
10116ee6c:	63 28 79 1e	fadd	d3, d3, d25
10116ee70:	ea f3 00 b2	mov	x10, #0x5555555555555555
10116ee74:	aa fa e7 f2	movk	x10, #0x3fd5, lsl #48
10116ee78:	44 01 67 9e	fmov	d4, x10
10116ee7c:	63 08 64 1e	fmul	d3, d3, d4
10116ee80:	8a 3f 95 d2	mov	x10, #0xa9fc
10116ee84:	2a 5e ba f2	movk	x10, #0xd2f1, lsl #16
10116ee88:	aa 49 cc f2	movk	x10, #0x624d, lsl #32
10116ee8c:	0a f0 e7 f2	movk	x10, #0x3f80, lsl #48
10116ee90:	44 01 67 9e	fmov	d4, x10
10116ee94:	60 20 64 1e	fcmp	d3, d4
10116ee98:	f6 07 40 91	add	x22, sp, #0x1, lsl #12
10116ee9c:	d6 c2 19 91	add	x22, x22, #0x670
10116eea0:	6a 15 00 54	b.ge	0x10116f14c
10116eea4:	4f 15 f8 37	tbnz	w15, #0x1f, 0x10116f14c
10116eea8:	9f 20 00 71	cmp	w4, #0x8
10116eeac:	0b 15 00 54	b.lt	0x10116f14c
10116eeb0:	0a d7 83 d2	mov	x10, #0x1eb8
10116eeb4:	aa 70 bd f2	movk	x10, #0xeb85, lsl #16
10116eeb8:	2a 0a d7 f2	movk	x10, #0xb851, lsl #32
10116eebc:	ca f1 e7 f2	movk	x10, #0x3f8e, lsl #48
10116eec0:	43 01 67 9e	fmov	d3, x10
10116eec4:	e0 22 63 1e	fcmp	d23, d3
10116eec8:	2a 14 00 54	b.ge	0x10116f14c
10116eecc:	2f 4a 00 34	cbz	w15, 0x10116f810
10116eed0:	e9 05 00 51	sub	w9, w15, #0x1
10116eed4:	80 5a 69 fc	ldr	d0, [x20, w9, uxtw #3]
10116eed8:	e8 a3 90 d2	mov	x8, #0x851f
10116eedc:	68 3d aa f2	movk	x8, #0x51eb, lsl #16
10116eee0:	08 d7 c3 f2	movk	x8, #0x1eb8, lsl #32
10116eee4:	28 fe e7 f2	movk	x8, #0x3ff1, lsl #48
10116eee8:	01 01 67 9e	fmov	d1, x8
10116eeec:	00 20 61 1e	fcmp	d0, d1
10116eef0:	f9 9b 40 f9	ldr	x25, [sp, #0x130]
10116eef4:	cd 00 00 54	b.le	0x10116ef0c
10116eef8:	e8 e7 02 b2	mov	x8, #-0x3333333333333334
10116eefc:	c8 fe e7 f2	movk	x8, #0x3ff6, lsl #48
10116ef00:	01 01 67 9e	fmov	d1, x8
10116ef04:	00 20 61 1e	fcmp	d0, d1
10116ef08:	eb 01 00 54	b.lt	0x10116ef44
10116ef0c:	0e 00 80 52	mov	w14, #0x0
10116ef10:	e8 e7 00 b2	mov	x8, #0x3333333333333333
10116ef14:	88 66 86 f2	movk	x8, #0x3334
10116ef18:	28 ff e7 f2	movk	x8, #0x3ff9, lsl #48
10116ef1c:	01 01 67 9e	fmov	d1, x8
10116ef20:	00 20 61 1e	fcmp	d0, d1
10116ef24:	8d 7d 01 54	b.le	0x101171ed4
10116ef28:	e8 e7 02 b2	mov	x8, #-0x3333333333333334
10116ef2c:	a8 99 99 f2	movk	x8, #0xcccd
10116ef30:	88 ff e7 f2	movk	x8, #0x3ffc, lsl #48
10116ef34:	01 01 67 9e	fmov	d1, x8
10116ef38:	00 20 61 1e	fcmp	d0, d1
10116ef3c:	f3 03 0f aa	mov	x19, x15
10116ef40:	4a 47 00 54	b.ge	0x10116f828
10116ef44:	e8 09 00 71	subs	w8, w15, #0x2
10116ef48:	c3 46 00 54	b.lo	0x10116f820
10116ef4c:	80 5a 68 fc	ldr	d0, [x20, w8, uxtw #3]
10116ef50:	ea a3 90 d2	mov	x10, #0x851f
10116ef54:	6a 3d aa f2	movk	x10, #0x51eb, lsl #16
10116ef58:	0a d7 c3 f2	movk	x10, #0x1eb8, lsl #32
10116ef5c:	2a fe e7 f2	movk	x10, #0x3ff1, lsl #48
10116ef60:	41 01 67 9e	fmov	d1, x10
10116ef64:	00 20 61 1e	fcmp	d0, d1
10116ef68:	cd 00 00 54	b.le	0x10116ef80
10116ef6c:	ea e7 02 b2	mov	x10, #-0x3333333333333334
10116ef70:	ca fe e7 f2	movk	x10, #0x3ff6, lsl #48
10116ef74:	41 01 67 9e	fmov	d1, x10
10116ef78:	00 20 61 1e	fcmp	d0, d1
10116ef7c:	eb 01 00 54	b.lt	0x10116efb8
10116ef80:	0e 00 80 52	mov	w14, #0x0
10116ef84:	ea e7 00 b2	mov	x10, #0x3333333333333333
10116ef88:	8a 66 86 f2	movk	x10, #0x3334
10116ef8c:	2a ff e7 f2	movk	x10, #0x3ff9, lsl #48
10116ef90:	41 01 67 9e	fmov	d1, x10
10116ef94:	00 20 61 1e	fcmp	d0, d1
10116ef98:	0d 0c 00 54	b.le	0x10116f118
10116ef9c:	ea e7 02 b2	mov	x10, #-0x3333333333333334
10116efa0:	aa 99 99 f2	movk	x10, #0xcccd
10116efa4:	8a ff e7 f2	movk	x10, #0x3ffc, lsl #48
10116efa8:	41 01 67 9e	fmov	d1, x10
10116efac:	00 20 61 1e	fcmp	d0, d1
10116efb0:	f3 03 09 aa	mov	x19, x9
10116efb4:	aa 43 00 54	b.ge	0x10116f828
10116efb8:	e9 0d 00 71	subs	w9, w15, #0x3
10116efbc:	23 43 00 54	b.lo	0x10116f820
10116efc0:	80 5a 69 fc	ldr	d0, [x20, w9, uxtw #3]
10116efc4:	ea a3 90 d2	mov	x10, #0x851f
10116efc8:	6a 3d aa f2	movk	x10, #0x51eb, lsl #16
10116efcc:	0a d7 c3 f2	movk	x10, #0x1eb8, lsl #32
10116efd0:	2a fe e7 f2	movk	x10, #0x3ff1, lsl #48
10116efd4:	41 01 67 9e	fmov	d1, x10
10116efd8:	00 20 61 1e	fcmp	d0, d1
10116efdc:	cd 00 00 54	b.le	0x10116eff4
10116efe0:	ea e7 02 b2	mov	x10, #-0x3333333333333334
10116efe4:	ca fe e7 f2	movk	x10, #0x3ff6, lsl #48
10116efe8:	41 01 67 9e	fmov	d1, x10
10116efec:	00 20 61 1e	fcmp	d0, d1
10116eff0:	eb 01 00 54	b.lt	0x10116f02c
10116eff4:	0e 00 80 52	mov	w14, #0x0
10116eff8:	ea e7 00 b2	mov	x10, #0x3333333333333333
10116effc:	8a 66 86 f2	movk	x10, #0x3334
10116f000:	2a ff e7 f2	movk	x10, #0x3ff9, lsl #48
10116f004:	41 01 67 9e	fmov	d1, x10
10116f008:	00 20 61 1e	fcmp	d0, d1
10116f00c:	6d 34 04 54	b.le	0x101177698
10116f010:	ea e7 02 b2	mov	x10, #-0x3333333333333334
10116f014:	aa 99 99 f2	movk	x10, #0xcccd
10116f018:	8a ff e7 f2	movk	x10, #0x3ffc, lsl #48
10116f01c:	41 01 67 9e	fmov	d1, x10
10116f020:	00 20 61 1e	fcmp	d0, d1
10116f024:	f3 03 08 aa	mov	x19, x8
10116f028:	0a 40 00 54	b.ge	0x10116f828
10116f02c:	e8 11 00 71	subs	w8, w15, #0x4
10116f030:	83 3f 00 54	b.lo	0x10116f820
10116f034:	80 5a 68 fc	ldr	d0, [x20, w8, uxtw #3]
10116f038:	ea a3 90 d2	mov	x10, #0x851f
10116f03c:	6a 3d aa f2	movk	x10, #0x51eb, lsl #16
10116f040:	0a d7 c3 f2	movk	x10, #0x1eb8, lsl #32
10116f044:	2a fe e7 f2	movk	x10, #0x3ff1, lsl #48
10116f048:	41 01 67 9e	fmov	d1, x10
10116f04c:	00 20 61 1e	fcmp	d0, d1
10116f050:	cd 00 00 54	b.le	0x10116f068
10116f054:	ea e7 02 b2	mov	x10, #-0x3333333333333334
10116f058:	ca fe e7 f2	movk	x10, #0x3ff6, lsl #48
10116f05c:	41 01 67 9e	fmov	d1, x10
10116f060:	00 20 61 1e	fcmp	d0, d1
10116f064:	eb 01 00 54	b.lt	0x10116f0a0
10116f068:	0e 00 80 52	mov	w14, #0x0
10116f06c:	ea e7 00 b2	mov	x10, #0x3333333333333333
10116f070:	8a 66 86 f2	movk	x10, #0x3334
10116f074:	2a ff e7 f2	movk	x10, #0x3ff9, lsl #48
10116f078:	41 01 67 9e	fmov	d1, x10
10116f07c:	00 20 61 1e	fcmp	d0, d1
10116f080:	cd 04 00 54	b.le	0x10116f118
10116f084:	ea e7 02 b2	mov	x10, #-0x3333333333333334
10116f088:	aa 99 99 f2	movk	x10, #0xcccd
10116f08c:	8a ff e7 f2	movk	x10, #0x3ffc, lsl #48
10116f090:	41 01 67 9e	fmov	d1, x10
10116f094:	00 20 61 1e	fcmp	d0, d1
10116f098:	f3 03 09 aa	mov	x19, x9
10116f09c:	6a 3c 00 54	b.ge	0x10116f828
10116f0a0:	e9 15 00 71	subs	w9, w15, #0x5
10116f0a4:	e3 3b 00 54	b.lo	0x10116f820
10116f0a8:	80 5a 69 fc	ldr	d0, [x20, w9, uxtw #3]
10116f0ac:	ea a3 90 d2	mov	x10, #0x851f
10116f0b0:	6a 3d aa f2	movk	x10, #0x51eb, lsl #16
10116f0b4:	0a d7 c3 f2	movk	x10, #0x1eb8, lsl #32
10116f0b8:	2a fe e7 f2	movk	x10, #0x3ff1, lsl #48
10116f0bc:	41 01 67 9e	fmov	d1, x10
10116f0c0:	00 20 61 1e	fcmp	d0, d1
10116f0c4:	cd 00 00 54	b.le	0x10116f0dc
10116f0c8:	ea e7 02 b2	mov	x10, #-0x3333333333333334
10116f0cc:	ca fe e7 f2	movk	x10, #0x3ff6, lsl #48
10116f0d0:	41 01 67 9e	fmov	d1, x10
10116f0d4:	00 20 61 1e	fcmp	d0, d1
10116f0d8:	eb 01 00 54	b.lt	0x10116f114
10116f0dc:	0e 00 80 52	mov	w14, #0x0
10116f0e0:	ea e7 00 b2	mov	x10, #0x3333333333333333
10116f0e4:	8a 66 86 f2	movk	x10, #0x3334
10116f0e8:	2a ff e7 f2	movk	x10, #0x3ff9, lsl #48
10116f0ec:	41 01 67 9e	fmov	d1, x10
10116f0f0:	00 20 61 1e	fcmp	d0, d1
10116f0f4:	2d 2d 04 54	b.le	0x101177698
10116f0f8:	ea e7 02 b2	mov	x10, #-0x3333333333333334
10116f0fc:	aa 99 99 f2	movk	x10, #0xcccd
10116f100:	8a ff e7 f2	movk	x10, #0x3ffc, lsl #48
10116f104:	41 01 67 9e	fmov	d1, x10
10116f108:	00 20 61 1e	fcmp	d0, d1
10116f10c:	f3 03 08 aa	mov	x19, x8
10116f110:	ca 38 00 54	b.ge	0x10116f828
10116f114:	2e 00 80 52	mov	w14, #0x1
10116f118:	f3 03 09 aa	mov	x19, x9
10116f11c:	c3 01 00 14	b	0x10116f828
10116f120:	e9 03 1a aa	mov	x9, x26
10116f124:	ea 08 00 51	sub	w10, w7, #0x2
10116f128:	1f 01 0a 6b	cmp	w8, w10
10116f12c:	4b 10 00 54	b.lt	0x10116f334
10116f130:	eb 03 08 aa	mov	x11, x8
10116f134:	15 03 80 52	mov	w21, #0x18
10116f138:	ee a3 40 f9	ldr	x14, [sp, #0x140]
10116f13c:	6d 16 00 54	b.le	0x10116f408
10116f140:	ca 01 00 b9	str	w10, [x14]
10116f144:	eb 03 0a aa	mov	x11, x10
10116f148:	b0 00 00 14	b	0x10116f408
10116f14c:	6a 8f 82 d2	mov	x10, #0x147b
10116f150:	ca f5 a8 f2	movk	x10, #0x47ae, lsl #16
10116f154:	2a 5c cf f2	movk	x10, #0x7ae1, lsl #32
10116f158:	0a 00 e8 f2	movk	x10, #0x4000, lsl #48
10116f15c:	43 01 67 9e	fmov	d3, x10
10116f160:	00 20 63 1e	fcmp	d0, d3
10116f164:	2a 06 00 54	b.ge	0x10116f228
10116f168:	4a e1 9a d2	mov	x10, #0xd70a
10116f16c:	6a 14 ae f2	movk	x10, #0x70a3, lsl #16
10116f170:	aa 47 c1 f2	movk	x10, #0xa3d, lsl #32
10116f174:	ea ff e7 f2	movk	x10, #0x3fff, lsl #48
10116f178:	43 01 67 9e	fmov	d3, x10
10116f17c:	00 20 63 1e	fcmp	d0, d3
10116f180:	4d 05 00 54	b.le	0x10116f228
10116f184:	8a 3f 95 d2	mov	x10, #0xa9fc
10116f188:	2a 5e ba f2	movk	x10, #0xd2f1, lsl #16
10116f18c:	aa 49 cc f2	movk	x10, #0x624d, lsl #32
10116f190:	0a f0 e7 f2	movk	x10, #0x3f80, lsl #48
10116f194:	40 01 67 9e	fmov	d0, x10
10116f198:	40 20 60 1e	fcmp	d2, d0
10116f19c:	6a 04 00 54	b.ge	0x10116f228
10116f1a0:	5a 04 f8 37	tbnz	w26, #0x1f, 0x10116f228
10116f1a4:	3f 21 00 71	cmp	w9, #0x8
10116f1a8:	0b 04 00 54	b.lt	0x10116f228
10116f1ac:	09 d7 83 d2	mov	x9, #0x1eb8
10116f1b0:	a9 70 bd f2	movk	x9, #0xeb85, lsl #16
10116f1b4:	29 0a d7 f2	movk	x9, #0xb851, lsl #32
10116f1b8:	c9 f1 e7 f2	movk	x9, #0x3f8e, lsl #48
10116f1bc:	20 01 67 9e	fmov	d0, x9
10116f1c0:	20 20 60 1e	fcmp	d1, d0
10116f1c4:	2a 03 00 54	b.ge	0x10116f228
10116f1c8:	da 3b 00 34	cbz	w26, 0x10116f940
10116f1cc:	51 07 00 51	sub	w17, w26, #0x1
10116f1d0:	80 5a 71 fc	ldr	d0, [x20, w17, uxtw #3]
10116f1d4:	ee e7 02 b2	mov	x14, #-0x3333333333333334
10116f1d8:	ae 99 99 f2	movk	x14, #0xcccd
10116f1dc:	8e ff e7 f2	movk	x14, #0x3ffc, lsl #48
10116f1e0:	c1 01 67 9e	fmov	d1, x14
10116f1e4:	00 20 61 1e	fcmp	d0, d1
10116f1e8:	e9 a3 90 d2	mov	x9, #0x851f
10116f1ec:	69 3d aa f2	movk	x9, #0x51eb, lsl #16
10116f1f0:	09 d7 c3 f2	movk	x9, #0x1eb8, lsl #32
10116f1f4:	29 fe e7 f2	movk	x9, #0x3ff1, lsl #48
10116f1f8:	21 01 67 9e	fmov	d1, x9
10116f1fc:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
10116f200:	ef e7 01 b2	mov	x15, #-0x6666666666666667
10116f204:	4f 33 93 f2	movk	x15, #0x999a
10116f208:	2f 00 e8 f2	movk	x15, #0x4001, lsl #48
10116f20c:	ec 41 00 54	b.gt	0x10116fa48
10116f210:	e1 01 67 9e	fmov	d1, x15
10116f214:	00 20 61 1e	fcmp	d0, d1
10116f218:	8c 41 00 54	b.gt	0x10116fa48
10116f21c:	15 00 80 52	mov	w21, #0x0
10116f220:	f1 03 1a aa	mov	x17, x26
10116f224:	44 1e 00 14	b	0x101176b34
10116f228:	60 2b 7c 1e	fadd	d0, d27, d28
10116f22c:	00 28 7d 1e	fadd	d0, d0, d29
10116f230:	e8 f3 00 b2	mov	x8, #0x5555555555555555
10116f234:	a8 fa e7 f2	movk	x8, #0x3fd5, lsl #48
10116f238:	01 01 67 9e	fmov	d1, x8
10116f23c:	00 08 61 1e	fmul	d0, d0, d1
10116f240:	88 3f 95 d2	mov	x8, #0xa9fc
10116f244:	28 5e ba f2	movk	x8, #0xd2f1, lsl #16
10116f248:	a8 49 cc f2	movk	x8, #0x624d, lsl #32
10116f24c:	08 f0 e7 f2	movk	x8, #0x3f80, lsl #48
10116f250:	01 01 67 9e	fmov	d1, x8
10116f254:	00 20 61 1e	fcmp	d0, d1
10116f258:	f7 07 40 91	add	x23, sp, #0x1, lsl #12
10116f25c:	f7 c2 11 91	add	x23, x23, #0x470
10116f260:	ca 05 00 54	b.ge	0x10116f318
10116f264:	b9 05 f8 37	tbnz	w25, #0x1f, 0x10116f318
10116f268:	ff 20 00 71	cmp	w7, #0x8
10116f26c:	6b 05 00 54	b.lt	0x10116f318
10116f270:	08 d7 83 d2	mov	x8, #0x1eb8
10116f274:	a8 70 bd f2	movk	x8, #0xeb85, lsl #16
10116f278:	28 0a d7 f2	movk	x8, #0xb851, lsl #32
10116f27c:	c8 f1 e7 f2	movk	x8, #0x3f8e, lsl #48
10116f280:	00 01 67 9e	fmov	d0, x8
10116f284:	00 23 60 1e	fcmp	d24, d0
10116f288:	e7 03 10 aa	mov	x7, x16
10116f28c:	6a 35 00 54	b.ge	0x10116f938
10116f290:	f9 41 00 34	cbz	w25, 0x10116facc
10116f294:	31 07 00 51	sub	w17, w25, #0x1
10116f298:	80 5a 71 fc	ldr	d0, [x20, w17, uxtw #3]
10116f29c:	ef e7 02 b2	mov	x15, #-0x3333333333333334
10116f2a0:	af 99 99 f2	movk	x15, #0xcccd
10116f2a4:	8f ff e7 f2	movk	x15, #0x3ffc, lsl #48
10116f2a8:	e1 01 67 9e	fmov	d1, x15
10116f2ac:	00 20 61 1e	fcmp	d0, d1
10116f2b0:	e8 a3 90 d2	mov	x8, #0x851f
10116f2b4:	68 3d aa f2	movk	x8, #0x51eb, lsl #16
10116f2b8:	08 d7 c3 f2	movk	x8, #0x1eb8, lsl #32
10116f2bc:	28 fe e7 f2	movk	x8, #0x3ff1, lsl #48
10116f2c0:	01 01 67 9e	fmov	d1, x8
10116f2c4:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
10116f2c8:	f0 e7 01 b2	mov	x16, #-0x6666666666666667
10116f2cc:	50 33 93 f2	movk	x16, #0x999a
10116f2d0:	30 00 e8 f2	movk	x16, #0x4001, lsl #48
10116f2d4:	2c 41 00 54	b.gt	0x10116faf8
10116f2d8:	01 02 67 9e	fmov	d1, x16
10116f2dc:	00 20 61 1e	fcmp	d0, d1
10116f2e0:	cc 40 00 54	b.gt	0x10116faf8
10116f2e4:	1a 00 80 52	mov	w26, #0x0
10116f2e8:	f1 03 19 aa	mov	x17, x25
10116f2ec:	56 21 00 14	b	0x101177844
10116f2f0:	16 00 80 52	mov	w22, #0x0
10116f2f4:	11 00 80 52	mov	w17, #0x0
10116f2f8:	fc e7 52 a9	ldp	x28, x25, [sp, #0x128]
10116f2fc:	ee e7 02 b2	mov	x14, #-0x3333333333333334
10116f300:	ae 99 99 f2	movk	x14, #0xcccd
10116f304:	8e ff e7 f2	movk	x14, #0x3ffc, lsl #48
10116f308:	ef e7 01 b2	mov	x15, #-0x6666666666666667
10116f30c:	4f 33 93 f2	movk	x15, #0x999a
10116f310:	2f 00 e8 f2	movk	x15, #0x4001, lsl #48
10116f314:	c7 06 00 14	b	0x101170e30
10116f318:	f9 9b 40 f9	ldr	x25, [sp, #0x130]
10116f31c:	e7 03 10 aa	mov	x7, x16
10116f320:	9a f9 ff 17	b	0x10116d988
10116f324:	09 00 80 52	mov	w9, #0x0
10116f328:	ea 08 00 51	sub	w10, w7, #0x2
10116f32c:	1f 01 0a 6b	cmp	w8, w10
10116f330:	0a f0 ff 54	b.ge	0x10116f130
10116f334:	0d 05 00 11	add	w13, w8, #0x1
10116f338:	80 da 6d fc	ldr	d0, [x20, w13, sxtw #3]
10116f33c:	eb a3 90 d2	mov	x11, #0x851f
10116f340:	6b 3d aa f2	movk	x11, #0x51eb, lsl #16
10116f344:	0b d7 c3 f2	movk	x11, #0x1eb8, lsl #32
10116f348:	2b fe e7 f2	movk	x11, #0x3ff1, lsl #48
10116f34c:	61 01 67 9e	fmov	d1, x11
10116f350:	00 20 61 1e	fcmp	d0, d1
10116f354:	eb 03 08 aa	mov	x11, x8
10116f358:	15 03 80 52	mov	w21, #0x18
10116f35c:	ee a3 40 f9	ldr	x14, [sp, #0x140]
10116f360:	4d 05 00 54	b.le	0x10116f408
10116f364:	cd 01 00 b9	str	w13, [x14]
10116f368:	bf 01 0a 6b	cmp	w13, w10
10116f36c:	ca 04 00 54	b.ge	0x10116f404
10116f370:	0c 09 00 11	add	w12, w8, #0x2
10116f374:	80 da 6c fc	ldr	d0, [x20, w12, sxtw #3]
10116f378:	eb a3 90 d2	mov	x11, #0x851f
10116f37c:	6b 3d aa f2	movk	x11, #0x51eb, lsl #16
10116f380:	0b d7 c3 f2	movk	x11, #0x1eb8, lsl #32
10116f384:	2b fe e7 f2	movk	x11, #0x3ff1, lsl #48
10116f388:	61 01 67 9e	fmov	d1, x11
10116f38c:	00 20 61 1e	fcmp	d0, d1
10116f390:	eb 03 0d aa	mov	x11, x13
10116f394:	ad 03 00 54	b.le	0x10116f408
10116f398:	cc 01 00 b9	str	w12, [x14]
10116f39c:	9f 01 0a 6b	cmp	w12, w10
10116f3a0:	2a 2e 00 54	b.ge	0x10116f964
10116f3a4:	0a 0d 00 11	add	w10, w8, #0x3
10116f3a8:	80 da 6a fc	ldr	d0, [x20, w10, sxtw #3]
10116f3ac:	e8 a3 90 d2	mov	x8, #0x851f
10116f3b0:	68 3d aa f2	movk	x8, #0x51eb, lsl #16
10116f3b4:	08 d7 c3 f2	movk	x8, #0x1eb8, lsl #32
10116f3b8:	28 fe e7 f2	movk	x8, #0x3ff1, lsl #48
10116f3bc:	01 01 67 9e	fmov	d1, x8
10116f3c0:	00 20 61 1e	fcmp	d0, d1
10116f3c4:	eb 03 0c aa	mov	x11, x12
10116f3c8:	cc eb ff 54	b.gt	0x10116f140
10116f3cc:	0f 00 00 14	b	0x10116f408
10116f3d0:	11 00 80 52	mov	w17, #0x0
10116f3d4:	f6 03 1a aa	mov	x22, x26
10116f3d8:	96 06 00 14	b	0x101170e30
10116f3dc:	16 00 80 52	mov	w22, #0x0
10116f3e0:	00 00 80 52	mov	w0, #0x0
10116f3e4:	f9 9b 40 f9	ldr	x25, [sp, #0x130]
10116f3e8:	ee e7 02 b2	mov	x14, #-0x3333333333333334
10116f3ec:	ae 99 99 f2	movk	x14, #0xcccd
10116f3f0:	8e ff e7 f2	movk	x14, #0x3ffc, lsl #48
10116f3f4:	ef e7 01 b2	mov	x15, #-0x6666666666666667
10116f3f8:	4f 33 93 f2	movk	x15, #0x999a
10116f3fc:	2f 00 e8 f2	movk	x15, #0x4001, lsl #48
10116f400:	d7 10 00 14	b	0x10117375c
10116f404:	eb 03 0d aa	mov	x11, x13
10116f408:	e8 0f 42 f9	ldr	x8, [sp, #0x418]
10116f40c:	0b d9 69 fc	ldr	d11, [x8, w9, sxtw #3]
10116f410:	08 cd 2b 8b	add	x8, x8, w11, sxtw #3
10116f414:	00 05 40 fd	ldr	d0, [x8, #0x8]
10116f418:	0a 38 6b 1e	fsub	d10, d0, d11
10116f41c:	08 00 c8 d2	mov	x8, #0x400000000000
10116f420:	e8 11 e8 f2	movk	x8, #0x408f, lsl #48
10116f424:	00 01 67 9e	fmov	d0, x8
10116f428:	40 09 60 1e	fmul	d0, d10, d0
10116f42c:	00 08 6c 1e	fmul	d0, d0, d12
10116f430:	01 28 6e 1e	fadd	d1, d0, d14
10116f434:	36 00 78 1e	fcvtzs	w22, d1
10116f438:	28 c0 65 1e	frintz	d8, d1
10116f43c:	00 d4 e8 7e	fabd	d0, d0, d8
10116f440:	df 0a 00 71	cmp	w22, #0x2
10116f444:	01 10 6a 1e	fmov	d1, #0.25000000
10116f448:	00 a4 61 1e	fccmp	d0, d1, #0x0, ge
10116f44c:	aa 29 ff 54	b.ge	0x10116d980
10116f450:	fa 03 07 aa	mov	x26, x7
10116f454:	37 7d 40 93	sxtw	x23, w9
10116f458:	68 7d 40 93	sxtw	x8, w11
10116f45c:	3f 01 08 6b	cmp	w9, w8
10116f460:	a0 01 00 54	b.eq	0x10116f494
10116f464:	e9 b3 40 f9	ldr	x9, [sp, #0x160]
10116f468:	29 01 40 f9	ldr	x9, [x9]
10116f46c:	29 61 00 91	add	x9, x9, #0x18
10116f470:	01 25 15 9b	madd	x1, x8, x21, x9
10116f474:	f3 26 15 9b	madd	x19, x23, x21, x9
10116f478:	28 03 40 f9	ldr	x8, [x25]
10116f47c:	14 01 01 cb	sub	x20, x8, x1
10116f480:	e0 03 13 aa	mov	x0, x19
10116f484:	e2 03 14 aa	mov	x2, x20
10116f488:	71 8c 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
10116f48c:	68 02 14 8b	add	x8, x19, x20
10116f490:	28 03 00 f9	str	x8, [x25]
10116f494:	13 00 80 d2	mov	x19, #0x0
10116f498:	ff ef 01 f9	str	xzr, [sp, #0x3d8]
10116f49c:	ff eb 01 f9	str	xzr, [sp, #0x3d0]
10116f4a0:	d4 06 00 51	sub	w20, w22, #0x1
10116f4a4:	e8 07 7d b2	orr	x8, xzr, #0x18
10116f4a8:	e8 22 15 9b	madd	x8, x23, x21, x8
10116f4ac:	09 00 80 12	mov	w9, #-0x1
10116f4b0:	e9 e3 03 b9	str	w9, [sp, #0x3e0]
10116f4b4:	ff 93 0f 39	strb	wzr, [sp, #0x3e4]
10116f4b8:	a8 19 68 1e	fdiv	d8, d13, d8
10116f4bc:	f7 07 40 91	add	x23, sp, #0x1, lsl #12
10116f4c0:	f7 c2 11 91	add	x23, x23, #0x470
10116f4c4:	f6 07 40 91	add	x22, sp, #0x1, lsl #12
10116f4c8:	d6 c2 19 91	add	x22, x22, #0x670
10116f4cc:	9f 02 13 eb	cmp	x20, x19
10116f4d0:	80 02 00 54	b.eq	0x10116f520
10116f4d4:	73 06 00 91	add	x19, x19, #0x1
10116f4d8:	60 02 62 1e	scvtf	d0, w19
10116f4dc:	40 09 60 1e	fmul	d0, d10, d0
10116f4e0:	00 2c 48 1f	fmadd	d0, d0, d8, d11
10116f4e4:	61 03 40 bd	ldr	s1, [x27]
10116f4e8:	21 a4 20 0f	sshll.2d	v1, v1, #0x0
10116f4ec:	21 d8 61 5e	scvtf	d1, d1
10116f4f0:	00 38 41 1f	fmadd	d0, d0, d1, d14
10116f4f4:	09 00 78 1e	fcvtzs	w9, d0
10116f4f8:	e9 d3 03 b9	str	w9, [sp, #0x3d0]
10116f4fc:	ff ef 01 f9	str	xzr, [sp, #0x3d8]
10116f500:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
10116f504:	09 00 40 f9	ldr	x9, [x0]
10116f508:	15 61 00 91	add	x21, x8, #0x18
10116f50c:	01 01 09 8b	add	x1, x8, x9
10116f510:	e2 43 0f 91	add	x2, sp, #0x3d0
10116f514:	41 3f ff 97	bl	__ZNSt3__16vectorIN16BeatAnalyzer_2_06peakss8BeatInfoENS_9allocatorIS3_EEE6insertENS_11__wrap_iterIPKS3_EERS8_
10116f518:	e8 03 15 aa	mov	x8, x21
10116f51c:	ec ff ff 17	b	0x10116f4cc
10116f520:	f3 a3 55 a9	ldp	x19, x8, [sp, #0x158]
10116f524:	08 01 40 f9	ldr	x8, [x8]
10116f528:	09 01 40 b9	ldr	w9, [x8]
10116f52c:	e9 f3 00 b9	str	w9, [sp, #0xf0]
10116f530:	08 0d 40 b9	ldr	w8, [x8, #0xc]
10116f534:	e8 b7 00 b9	str	w8, [sp, #0xb4]
10116f538:	f4 8b 40 f9	ldr	x20, [sp, #0x110]
10116f53c:	e7 03 1a aa	mov	x7, x26
10116f540:	12 f9 ff 17	b	0x10116d988
10116f544:	00 00 80 52	mov	w0, #0x0
10116f548:	f6 03 18 aa	mov	x22, x24
10116f54c:	84 10 00 14	b	0x10117375c
10116f550:	14 00 80 52	mov	w20, #0x0
10116f554:	11 00 80 52	mov	w17, #0x0
10116f558:	ed 9b 40 f9	ldr	x13, [sp, #0x130]
10116f55c:	ef 83 40 f9	ldr	x15, [sp, #0x100]
10116f560:	03 00 00 14	b	0x10116f56c
10116f564:	14 00 80 52	mov	w20, #0x0
10116f568:	11 00 80 52	mov	w17, #0x0
10116f56c:	09 0a 00 51	sub	w9, w16, #0x2
10116f570:	5f 03 09 6b	cmp	w26, w9
10116f574:	6d 00 00 54	b.le	0x10116f580
10116f578:	e0 03 1a aa	mov	x0, x26
10116f57c:	e3 0b 00 14	b	0x101172508
10116f580:	ea 8b 40 f9	ldr	x10, [sp, #0x110]
10116f584:	40 d9 60 fc	ldr	d0, [x10, w0, sxtw #3]
10116f588:	ea a3 90 d2	mov	x10, #0x851f
10116f58c:	6a 3d aa f2	movk	x10, #0x51eb, lsl #16
10116f590:	0a d7 c3 f2	movk	x10, #0x1eb8, lsl #32
10116f594:	2a fe e7 f2	movk	x10, #0x3ff1, lsl #48
10116f598:	41 01 67 9e	fmov	d1, x10
10116f59c:	00 20 61 1e	fcmp	d0, d1
10116f5a0:	cd 00 00 54	b.le	0x10116f5b8
10116f5a4:	ea e7 02 b2	mov	x10, #-0x3333333333333334
10116f5a8:	ca fe e7 f2	movk	x10, #0x3ff6, lsl #48
10116f5ac:	41 01 67 9e	fmov	d1, x10
10116f5b0:	00 20 61 1e	fcmp	d0, d1
10116f5b4:	4b 01 00 54	b.lt	0x10116f5dc
10116f5b8:	ea e7 00 b2	mov	x10, #0x3333333333333333
10116f5bc:	8a 66 86 f2	movk	x10, #0x3334
10116f5c0:	2a ff e7 f2	movk	x10, #0x3ff9, lsl #48
10116f5c4:	41 01 67 9e	fmov	d1, x10
10116f5c8:	00 20 61 1e	fcmp	d0, d1
10116f5cc:	6d fd ff 54	b.le	0x10116f578
10116f5d0:	81 01 67 9e	fmov	d1, x12
10116f5d4:	00 20 61 1e	fcmp	d0, d1
10116f5d8:	0a fd ff 54	b.ge	0x10116f578
10116f5dc:	0a 0e 00 51	sub	w10, w16, #0x3
10116f5e0:	5f 03 0a 6b	cmp	w26, w10
10116f5e4:	2c 79 01 54	b.gt	0x101172508
10116f5e8:	ea 8b 40 f9	ldr	x10, [sp, #0x110]
10116f5ec:	40 d9 6f fc	ldr	d0, [x10, w15, sxtw #3]
10116f5f0:	ea a3 90 d2	mov	x10, #0x851f
10116f5f4:	6a 3d aa f2	movk	x10, #0x51eb, lsl #16
10116f5f8:	0a d7 c3 f2	movk	x10, #0x1eb8, lsl #32
10116f5fc:	2a fe e7 f2	movk	x10, #0x3ff1, lsl #48
10116f600:	41 01 67 9e	fmov	d1, x10
10116f604:	00 20 61 1e	fcmp	d0, d1
10116f608:	cd 00 00 54	b.le	0x10116f620
10116f60c:	ea e7 02 b2	mov	x10, #-0x3333333333333334
10116f610:	ca fe e7 f2	movk	x10, #0x3ff6, lsl #48
10116f614:	41 01 67 9e	fmov	d1, x10
10116f618:	00 20 61 1e	fcmp	d0, d1
10116f61c:	4b 01 00 54	b.lt	0x10116f644
10116f620:	ea e7 00 b2	mov	x10, #0x3333333333333333
10116f624:	8a 66 86 f2	movk	x10, #0x3334
10116f628:	2a ff e7 f2	movk	x10, #0x3ff9, lsl #48
10116f62c:	41 01 67 9e	fmov	d1, x10
10116f630:	00 20 61 1e	fcmp	d0, d1
10116f634:	ad 76 01 54	b.le	0x101172508
10116f638:	81 01 67 9e	fmov	d1, x12
10116f63c:	00 20 61 1e	fcmp	d0, d1
10116f640:	4a 76 01 54	b.ge	0x101172508
10116f644:	0a 12 00 51	sub	w10, w16, #0x4
10116f648:	5f 03 0a 6b	cmp	w26, w10
10116f64c:	8d 29 00 54	b.le	0x10116fb7c
10116f650:	e0 03 0f aa	mov	x0, x15
10116f654:	ad 0b 00 14	b	0x101172508
10116f658:	13 00 80 52	mov	w19, #0x0
10116f65c:	11 00 80 52	mov	w17, #0x0
10116f660:	f8 9b 40 f9	ldr	x24, [sp, #0x130]
10116f664:	ed e7 02 b2	mov	x13, #-0x3333333333333334
10116f668:	ad 99 99 f2	movk	x13, #0xcccd
10116f66c:	8d ff e7 f2	movk	x13, #0x3ffc, lsl #48
10116f670:	03 00 00 14	b	0x10116f67c
10116f674:	13 00 80 52	mov	w19, #0x0
10116f678:	11 00 80 52	mov	w17, #0x0
10116f67c:	08 0a 00 51	sub	w8, w16, #0x2
10116f680:	df 01 08 6b	cmp	w14, w8
10116f684:	6d 00 00 54	b.le	0x10116f690
10116f688:	f6 03 0e aa	mov	x22, x14
10116f68c:	a8 01 00 14	b	0x10116fd2c
10116f690:	80 da 76 fc	ldr	d0, [x20, w22, sxtw #3]
10116f694:	e9 a3 90 d2	mov	x9, #0x851f
10116f698:	69 3d aa f2	movk	x9, #0x51eb, lsl #16
10116f69c:	09 d7 c3 f2	movk	x9, #0x1eb8, lsl #32
10116f6a0:	29 fe e7 f2	movk	x9, #0x3ff1, lsl #48
10116f6a4:	21 01 67 9e	fmov	d1, x9
10116f6a8:	00 20 61 1e	fcmp	d0, d1
10116f6ac:	cd 00 00 54	b.le	0x10116f6c4
10116f6b0:	e9 e7 02 b2	mov	x9, #-0x3333333333333334
10116f6b4:	c9 fe e7 f2	movk	x9, #0x3ff6, lsl #48
10116f6b8:	21 01 67 9e	fmov	d1, x9
10116f6bc:	00 20 61 1e	fcmp	d0, d1
10116f6c0:	4b 01 00 54	b.lt	0x10116f6e8
10116f6c4:	e9 e7 00 b2	mov	x9, #0x3333333333333333
10116f6c8:	89 66 86 f2	movk	x9, #0x3334
10116f6cc:	29 ff e7 f2	movk	x9, #0x3ff9, lsl #48
10116f6d0:	21 01 67 9e	fmov	d1, x9
10116f6d4:	00 20 61 1e	fcmp	d0, d1
10116f6d8:	8d fd ff 54	b.le	0x10116f688
10116f6dc:	a1 01 67 9e	fmov	d1, x13
10116f6e0:	00 20 61 1e	fcmp	d0, d1
10116f6e4:	2a fd ff 54	b.ge	0x10116f688
10116f6e8:	09 0e 00 51	sub	w9, w16, #0x3
10116f6ec:	df 01 09 6b	cmp	w14, w9
10116f6f0:	ec 31 00 54	b.gt	0x10116fd2c
10116f6f4:	80 da 7e fc	ldr	d0, [x20, w30, sxtw #3]
10116f6f8:	e9 a3 90 d2	mov	x9, #0x851f
10116f6fc:	69 3d aa f2	movk	x9, #0x51eb, lsl #16
10116f700:	09 d7 c3 f2	movk	x9, #0x1eb8, lsl #32
10116f704:	29 fe e7 f2	movk	x9, #0x3ff1, lsl #48
10116f708:	21 01 67 9e	fmov	d1, x9
10116f70c:	00 20 61 1e	fcmp	d0, d1
10116f710:	cd 00 00 54	b.le	0x10116f728
10116f714:	e9 e7 02 b2	mov	x9, #-0x3333333333333334
10116f718:	c9 fe e7 f2	movk	x9, #0x3ff6, lsl #48
10116f71c:	21 01 67 9e	fmov	d1, x9
10116f720:	00 20 61 1e	fcmp	d0, d1
10116f724:	4b 01 00 54	b.lt	0x10116f74c
10116f728:	e9 e7 00 b2	mov	x9, #0x3333333333333333
10116f72c:	89 66 86 f2	movk	x9, #0x3334
10116f730:	29 ff e7 f2	movk	x9, #0x3ff9, lsl #48
10116f734:	21 01 67 9e	fmov	d1, x9
10116f738:	00 20 61 1e	fcmp	d0, d1
10116f73c:	8d 2f 00 54	b.le	0x10116fd2c
10116f740:	a1 01 67 9e	fmov	d1, x13
10116f744:	00 20 61 1e	fcmp	d0, d1
10116f748:	2a 2f 00 54	b.ge	0x10116fd2c
10116f74c:	09 12 00 51	sub	w9, w16, #0x4
10116f750:	df 01 09 6b	cmp	w14, w9
10116f754:	2d 25 00 54	b.le	0x10116fbf8
10116f758:	f6 03 1e aa	mov	x22, x30
10116f75c:	74 01 00 14	b	0x10116fd2c
10116f760:	01 00 80 52	mov	w1, #0x0
10116f764:	11 00 80 52	mov	w17, #0x0
10116f768:	ed 9b 40 f9	ldr	x13, [sp, #0x130]
10116f76c:	ee e7 02 b2	mov	x14, #-0x3333333333333334
10116f770:	ae 99 99 f2	movk	x14, #0xcccd
10116f774:	8e ff e7 f2	movk	x14, #0x3ffc, lsl #48
10116f778:	ef 03 10 aa	mov	x15, x16
10116f77c:	f0 83 40 f9	ldr	x16, [sp, #0x100]
10116f780:	03 00 00 14	b	0x10116f78c
10116f784:	01 00 80 52	mov	w1, #0x0
10116f788:	11 00 80 52	mov	w17, #0x0
10116f78c:	e9 09 00 51	sub	w9, w15, #0x2
10116f790:	5f 03 09 6b	cmp	w26, w9
10116f794:	6d 00 00 54	b.le	0x10116f7a0
10116f798:	f0 03 1a aa	mov	x16, x26
10116f79c:	6b 14 00 14	b	0x101174948
10116f7a0:	ea 8b 40 f9	ldr	x10, [sp, #0x110]
10116f7a4:	40 d9 60 fc	ldr	d0, [x10, w0, sxtw #3]
10116f7a8:	ea a3 90 d2	mov	x10, #0x851f
10116f7ac:	6a 3d aa f2	movk	x10, #0x51eb, lsl #16
10116f7b0:	0a d7 c3 f2	movk	x10, #0x1eb8, lsl #32
10116f7b4:	2a fe e7 f2	movk	x10, #0x3ff1, lsl #48
10116f7b8:	41 01 67 9e	fmov	d1, x10
10116f7bc:	00 20 61 1e	fcmp	d0, d1
10116f7c0:	cd 00 00 54	b.le	0x10116f7d8
10116f7c4:	ea e7 02 b2	mov	x10, #-0x3333333333333334
10116f7c8:	ca fe e7 f2	movk	x10, #0x3ff6, lsl #48
10116f7cc:	41 01 67 9e	fmov	d1, x10
10116f7d0:	00 20 61 1e	fcmp	d0, d1
10116f7d4:	4b 01 00 54	b.lt	0x10116f7fc
10116f7d8:	ea e7 00 b2	mov	x10, #0x3333333333333333
10116f7dc:	8a 66 86 f2	movk	x10, #0x3334
10116f7e0:	2a ff e7 f2	movk	x10, #0x3ff9, lsl #48
10116f7e4:	41 01 67 9e	fmov	d1, x10
10116f7e8:	00 20 61 1e	fcmp	d0, d1
10116f7ec:	6d fd ff 54	b.le	0x10116f798
10116f7f0:	c1 01 67 9e	fmov	d1, x14
10116f7f4:	00 20 61 1e	fcmp	d0, d1
10116f7f8:	0a fd ff 54	b.ge	0x10116f798
10116f7fc:	ea 0d 00 51	sub	w10, w15, #0x3
10116f800:	5f 03 0a 6b	cmp	w26, w10
10116f804:	4d 0b 00 54	b.le	0x10116f96c
10116f808:	f0 03 00 aa	mov	x16, x0
10116f80c:	4f 14 00 14	b	0x101174948
10116f810:	13 00 80 52	mov	w19, #0x0
10116f814:	0e 00 80 52	mov	w14, #0x0
10116f818:	f9 9b 40 f9	ldr	x25, [sp, #0x130]
10116f81c:	03 00 00 14	b	0x10116f828
10116f820:	13 00 80 52	mov	w19, #0x0
10116f824:	0e 00 80 52	mov	w14, #0x0
10116f828:	08 0a 00 51	sub	w8, w16, #0x2
10116f82c:	ff 01 08 6b	cmp	w15, w8
10116f830:	6d 00 00 54	b.le	0x10116f83c
10116f834:	f7 03 0f aa	mov	x23, x15
10116f838:	ff 09 00 14	b	0x101172034
10116f83c:	80 da 77 fc	ldr	d0, [x20, w23, sxtw #3]
10116f840:	e9 a3 90 d2	mov	x9, #0x851f
10116f844:	69 3d aa f2	movk	x9, #0x51eb, lsl #16
10116f848:	09 d7 c3 f2	movk	x9, #0x1eb8, lsl #32
10116f84c:	29 fe e7 f2	movk	x9, #0x3ff1, lsl #48
10116f850:	21 01 67 9e	fmov	d1, x9
10116f854:	00 20 61 1e	fcmp	d0, d1
10116f858:	cd 00 00 54	b.le	0x10116f870
10116f85c:	e9 e7 02 b2	mov	x9, #-0x3333333333333334
10116f860:	c9 fe e7 f2	movk	x9, #0x3ff6, lsl #48
10116f864:	21 01 67 9e	fmov	d1, x9
10116f868:	00 20 61 1e	fcmp	d0, d1
10116f86c:	ab 01 00 54	b.lt	0x10116f8a0
10116f870:	e9 e7 00 b2	mov	x9, #0x3333333333333333
10116f874:	89 66 86 f2	movk	x9, #0x3334
10116f878:	29 ff e7 f2	movk	x9, #0x3ff9, lsl #48
10116f87c:	21 01 67 9e	fmov	d1, x9
10116f880:	00 20 61 1e	fcmp	d0, d1
10116f884:	8d fd ff 54	b.le	0x10116f834
10116f888:	e9 e7 02 b2	mov	x9, #-0x3333333333333334
10116f88c:	a9 99 99 f2	movk	x9, #0xcccd
10116f890:	89 ff e7 f2	movk	x9, #0x3ffc, lsl #48
10116f894:	21 01 67 9e	fmov	d1, x9
10116f898:	00 20 61 1e	fcmp	d0, d1
10116f89c:	ca fc ff 54	b.ge	0x10116f834
10116f8a0:	09 0e 00 51	sub	w9, w16, #0x3
10116f8a4:	ff 01 09 6b	cmp	w15, w9
10116f8a8:	6c 3c 01 54	b.gt	0x101172034
10116f8ac:	80 da 62 fc	ldr	d0, [x20, w2, sxtw #3]
10116f8b0:	e9 a3 90 d2	mov	x9, #0x851f
10116f8b4:	69 3d aa f2	movk	x9, #0x51eb, lsl #16
10116f8b8:	09 d7 c3 f2	movk	x9, #0x1eb8, lsl #32
10116f8bc:	29 fe e7 f2	movk	x9, #0x3ff1, lsl #48
10116f8c0:	21 01 67 9e	fmov	d1, x9
10116f8c4:	00 20 61 1e	fcmp	d0, d1
10116f8c8:	cd 00 00 54	b.le	0x10116f8e0
10116f8cc:	e9 e7 02 b2	mov	x9, #-0x3333333333333334
10116f8d0:	c9 fe e7 f2	movk	x9, #0x3ff6, lsl #48
10116f8d4:	21 01 67 9e	fmov	d1, x9
10116f8d8:	00 20 61 1e	fcmp	d0, d1
10116f8dc:	ab 01 00 54	b.lt	0x10116f910
10116f8e0:	e9 e7 00 b2	mov	x9, #0x3333333333333333
10116f8e4:	89 66 86 f2	movk	x9, #0x3334
10116f8e8:	29 ff e7 f2	movk	x9, #0x3ff9, lsl #48
10116f8ec:	21 01 67 9e	fmov	d1, x9
10116f8f0:	00 20 61 1e	fcmp	d0, d1
10116f8f4:	0d 3a 01 54	b.le	0x101172034
10116f8f8:	e9 e7 02 b2	mov	x9, #-0x3333333333333334
10116f8fc:	a9 99 99 f2	movk	x9, #0xcccd
10116f900:	89 ff e7 f2	movk	x9, #0x3ffc, lsl #48
10116f904:	21 01 67 9e	fmov	d1, x9
10116f908:	00 20 61 1e	fcmp	d0, d1
10116f90c:	4a 39 01 54	b.ge	0x101172034
10116f910:	09 12 00 51	sub	w9, w16, #0x4
10116f914:	ff 01 09 6b	cmp	w15, w9
10116f918:	2d 2e 01 54	b.le	0x101171edc
10116f91c:	f7 03 02 aa	mov	x23, x2
10116f920:	c5 09 00 14	b	0x101172034
10116f924:	e9 03 0b aa	mov	x9, x11
10116f928:	ea 08 00 51	sub	w10, w7, #0x2
10116f92c:	1f 01 0a 6b	cmp	w8, w10
10116f930:	2b d0 ff 54	b.lt	0x10116f334
10116f934:	ff fd ff 17	b	0x10116f130
10116f938:	f9 9b 40 f9	ldr	x25, [sp, #0x130]
10116f93c:	13 f8 ff 17	b	0x10116d988
10116f940:	11 00 80 52	mov	w17, #0x0
10116f944:	15 00 80 52	mov	w21, #0x0
10116f948:	ee e7 02 b2	mov	x14, #-0x3333333333333334
10116f94c:	ae 99 99 f2	movk	x14, #0xcccd
10116f950:	8e ff e7 f2	movk	x14, #0x3ffc, lsl #48
10116f954:	ef e7 01 b2	mov	x15, #-0x6666666666666667
10116f958:	4f 33 93 f2	movk	x15, #0x999a
10116f95c:	2f 00 e8 f2	movk	x15, #0x4001, lsl #48
10116f960:	75 1c 00 14	b	0x101176b34
10116f964:	eb 03 0c aa	mov	x11, x12
10116f968:	a8 fe ff 17	b	0x10116f408
10116f96c:	ea 8b 40 f9	ldr	x10, [sp, #0x110]
10116f970:	40 d9 70 fc	ldr	d0, [x10, w16, sxtw #3]
10116f974:	ea a3 90 d2	mov	x10, #0x851f
10116f978:	6a 3d aa f2	movk	x10, #0x51eb, lsl #16
10116f97c:	0a d7 c3 f2	movk	x10, #0x1eb8, lsl #32
10116f980:	2a fe e7 f2	movk	x10, #0x3ff1, lsl #48
10116f984:	41 01 67 9e	fmov	d1, x10
10116f988:	00 20 61 1e	fcmp	d0, d1
10116f98c:	cd 00 00 54	b.le	0x10116f9a4
10116f990:	ea e7 02 b2	mov	x10, #-0x3333333333333334
10116f994:	ca fe e7 f2	movk	x10, #0x3ff6, lsl #48
10116f998:	41 01 67 9e	fmov	d1, x10
10116f99c:	00 20 61 1e	fcmp	d0, d1
10116f9a0:	4b 01 00 54	b.lt	0x10116f9c8
10116f9a4:	ea e7 00 b2	mov	x10, #0x3333333333333333
10116f9a8:	8a 66 86 f2	movk	x10, #0x3334
10116f9ac:	2a ff e7 f2	movk	x10, #0x3ff9, lsl #48
10116f9b0:	41 01 67 9e	fmov	d1, x10
10116f9b4:	00 20 61 1e	fcmp	d0, d1
10116f9b8:	8d f2 ff 54	b.le	0x10116f808
10116f9bc:	c1 01 67 9e	fmov	d1, x14
10116f9c0:	00 20 61 1e	fcmp	d0, d1
10116f9c4:	2a f2 ff 54	b.ge	0x10116f808
10116f9c8:	ea 11 00 51	sub	w10, w15, #0x4
10116f9cc:	5f 03 0a 6b	cmp	w26, w10
10116f9d0:	cc 7b 02 54	b.gt	0x101174948
10116f9d4:	4a 0f 00 91	add	x10, x26, #0x3
10116f9d8:	eb 8b 40 f9	ldr	x11, [sp, #0x110]
10116f9dc:	60 79 6a fc	ldr	d0, [x11, x10, lsl #3]
10116f9e0:	eb a3 90 d2	mov	x11, #0x851f
10116f9e4:	6b 3d aa f2	movk	x11, #0x51eb, lsl #16
10116f9e8:	0b d7 c3 f2	movk	x11, #0x1eb8, lsl #32
10116f9ec:	2b fe e7 f2	movk	x11, #0x3ff1, lsl #48
10116f9f0:	61 01 67 9e	fmov	d1, x11
10116f9f4:	00 20 61 1e	fcmp	d0, d1
10116f9f8:	cd 00 00 54	b.le	0x10116fa10
10116f9fc:	eb e7 02 b2	mov	x11, #-0x3333333333333334
10116fa00:	cb fe e7 f2	movk	x11, #0x3ff6, lsl #48
10116fa04:	61 01 67 9e	fmov	d1, x11
10116fa08:	00 20 61 1e	fcmp	d0, d1
10116fa0c:	4b 01 00 54	b.lt	0x10116fa34
10116fa10:	eb e7 00 b2	mov	x11, #0x3333333333333333
10116fa14:	8b 66 86 f2	movk	x11, #0x3334
10116fa18:	2b ff e7 f2	movk	x11, #0x3ff9, lsl #48
10116fa1c:	61 01 67 9e	fmov	d1, x11
10116fa20:	00 20 61 1e	fcmp	d0, d1
10116fa24:	2d 79 02 54	b.le	0x101174948
10116fa28:	c1 01 67 9e	fmov	d1, x14
10116fa2c:	00 20 61 1e	fcmp	d0, d1
10116fa30:	ca 78 02 54	b.ge	0x101174948
10116fa34:	eb 15 00 51	sub	w11, w15, #0x5
10116fa38:	5f 03 0b 6b	cmp	w26, w11
10116fa3c:	0d 75 02 54	b.le	0x1011748dc
10116fa40:	f0 03 0a aa	mov	x16, x10
10116fa44:	c1 13 00 14	b	0x101174948
10116fa48:	49 0b 00 71	subs	w9, w26, #0x2
10116fa4c:	03 87 03 54	b.lo	0x101176b2c
10116fa50:	80 5a 69 fc	ldr	d0, [x20, w9, uxtw #3]
10116fa54:	c1 01 67 9e	fmov	d1, x14
10116fa58:	00 20 61 1e	fcmp	d0, d1
10116fa5c:	ea a3 90 d2	mov	x10, #0x851f
10116fa60:	6a 3d aa f2	movk	x10, #0x51eb, lsl #16
10116fa64:	0a d7 c3 f2	movk	x10, #0x1eb8, lsl #32
10116fa68:	2a fe e7 f2	movk	x10, #0x3ff1, lsl #48
10116fa6c:	41 01 67 9e	fmov	d1, x10
10116fa70:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
10116fa74:	8c 00 00 54	b.gt	0x10116fa84
10116fa78:	e1 01 67 9e	fmov	d1, x15
10116fa7c:	00 20 61 1e	fcmp	d0, d1
10116fa80:	8d 85 03 54	b.le	0x101176b30
10116fa84:	51 0f 00 71	subs	w17, w26, #0x3
10116fa88:	23 85 03 54	b.lo	0x101176b2c
10116fa8c:	80 5a 71 fc	ldr	d0, [x20, w17, uxtw #3]
10116fa90:	c1 01 67 9e	fmov	d1, x14
10116fa94:	00 20 61 1e	fcmp	d0, d1
10116fa98:	ea a3 90 d2	mov	x10, #0x851f
10116fa9c:	6a 3d aa f2	movk	x10, #0x51eb, lsl #16
10116faa0:	0a d7 c3 f2	movk	x10, #0x1eb8, lsl #32
10116faa4:	2a fe e7 f2	movk	x10, #0x3ff1, lsl #48
10116faa8:	41 01 67 9e	fmov	d1, x10
10116faac:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
10116fab0:	6c 7f 03 54	b.gt	0x101176a9c
10116fab4:	e1 01 67 9e	fmov	d1, x15
10116fab8:	00 20 61 1e	fcmp	d0, d1
10116fabc:	0c 7f 03 54	b.gt	0x101176a9c
10116fac0:	15 00 80 52	mov	w21, #0x0
10116fac4:	f1 03 09 aa	mov	x17, x9
10116fac8:	1b 1c 00 14	b	0x101176b34
10116facc:	11 00 80 52	mov	w17, #0x0
10116fad0:	1a 00 80 52	mov	w26, #0x0
10116fad4:	ef e7 02 b2	mov	x15, #-0x3333333333333334
10116fad8:	af 99 99 f2	movk	x15, #0xcccd
10116fadc:	8f ff e7 f2	movk	x15, #0x3ffc, lsl #48
10116fae0:	f0 e7 01 b2	mov	x16, #-0x6666666666666667
10116fae4:	50 33 93 f2	movk	x16, #0x999a
10116fae8:	30 00 e8 f2	movk	x16, #0x4001, lsl #48
10116faec:	56 1f 00 14	b	0x101177844
10116faf0:	f4 03 1a aa	mov	x20, x26
10116faf4:	9e fe ff 17	b	0x10116f56c
10116faf8:	28 0b 00 71	subs	w8, w25, #0x2
10116fafc:	03 ea 03 54	b.lo	0x10117783c
10116fb00:	80 5a 68 fc	ldr	d0, [x20, w8, uxtw #3]
10116fb04:	e1 01 67 9e	fmov	d1, x15
10116fb08:	00 20 61 1e	fcmp	d0, d1
10116fb0c:	e9 a3 90 d2	mov	x9, #0x851f
10116fb10:	69 3d aa f2	movk	x9, #0x51eb, lsl #16
10116fb14:	09 d7 c3 f2	movk	x9, #0x1eb8, lsl #32
10116fb18:	29 fe e7 f2	movk	x9, #0x3ff1, lsl #48
10116fb1c:	21 01 67 9e	fmov	d1, x9
10116fb20:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
10116fb24:	8c 00 00 54	b.gt	0x10116fb34
10116fb28:	01 02 67 9e	fmov	d1, x16
10116fb2c:	00 20 61 1e	fcmp	d0, d1
10116fb30:	8d e8 03 54	b.le	0x101177840
10116fb34:	31 0f 00 71	subs	w17, w25, #0x3
10116fb38:	23 e8 03 54	b.lo	0x10117783c
10116fb3c:	80 5a 71 fc	ldr	d0, [x20, w17, uxtw #3]
10116fb40:	e1 01 67 9e	fmov	d1, x15
10116fb44:	00 20 61 1e	fcmp	d0, d1
10116fb48:	e9 a3 90 d2	mov	x9, #0x851f
10116fb4c:	69 3d aa f2	movk	x9, #0x51eb, lsl #16
10116fb50:	09 d7 c3 f2	movk	x9, #0x1eb8, lsl #32
10116fb54:	29 fe e7 f2	movk	x9, #0x3ff1, lsl #48
10116fb58:	21 01 67 9e	fmov	d1, x9
10116fb5c:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
10116fb60:	6c e2 03 54	b.gt	0x1011777ac
10116fb64:	01 02 67 9e	fmov	d1, x16
10116fb68:	00 20 61 1e	fcmp	d0, d1
10116fb6c:	0c e2 03 54	b.gt	0x1011777ac
10116fb70:	1a 00 80 52	mov	w26, #0x0
10116fb74:	f1 03 08 aa	mov	x17, x8
10116fb78:	33 1f 00 14	b	0x101177844
10116fb7c:	4a 0f 00 91	add	x10, x26, #0x3
10116fb80:	eb 8b 40 f9	ldr	x11, [sp, #0x110]
10116fb84:	60 79 6a fc	ldr	d0, [x11, x10, lsl #3]
10116fb88:	eb a3 90 d2	mov	x11, #0x851f
10116fb8c:	6b 3d aa f2	movk	x11, #0x51eb, lsl #16
10116fb90:	0b d7 c3 f2	movk	x11, #0x1eb8, lsl #32
10116fb94:	2b fe e7 f2	movk	x11, #0x3ff1, lsl #48
10116fb98:	61 01 67 9e	fmov	d1, x11
10116fb9c:	00 20 61 1e	fcmp	d0, d1
10116fba0:	cd 00 00 54	b.le	0x10116fbb8
10116fba4:	eb e7 02 b2	mov	x11, #-0x3333333333333334
10116fba8:	cb fe e7 f2	movk	x11, #0x3ff6, lsl #48
10116fbac:	61 01 67 9e	fmov	d1, x11
10116fbb0:	00 20 61 1e	fcmp	d0, d1
10116fbb4:	4b 01 00 54	b.lt	0x10116fbdc
10116fbb8:	eb e7 00 b2	mov	x11, #0x3333333333333333
10116fbbc:	8b 66 86 f2	movk	x11, #0x3334
10116fbc0:	2b ff e7 f2	movk	x11, #0x3ff9, lsl #48
10116fbc4:	61 01 67 9e	fmov	d1, x11
10116fbc8:	00 20 61 1e	fcmp	d0, d1
10116fbcc:	2d d4 ff 54	b.le	0x10116f650
10116fbd0:	81 01 67 9e	fmov	d1, x12
10116fbd4:	00 20 61 1e	fcmp	d0, d1
10116fbd8:	ca d3 ff 54	b.ge	0x10116f650
10116fbdc:	0b 16 00 51	sub	w11, w16, #0x5
10116fbe0:	5f 03 0b 6b	cmp	w26, w11
10116fbe4:	cd 45 01 54	b.le	0x10117249c
10116fbe8:	e0 03 0a aa	mov	x0, x10
10116fbec:	47 0a 00 14	b	0x101172508
10116fbf0:	f3 03 0e aa	mov	x19, x14
10116fbf4:	a2 fe ff 17	b	0x10116f67c
10116fbf8:	c9 0d 00 91	add	x9, x14, #0x3
10116fbfc:	80 7a 69 fc	ldr	d0, [x20, x9, lsl #3]
10116fc00:	eb a3 90 d2	mov	x11, #0x851f
10116fc04:	6b 3d aa f2	movk	x11, #0x51eb, lsl #16
10116fc08:	0b d7 c3 f2	movk	x11, #0x1eb8, lsl #32
10116fc0c:	2b fe e7 f2	movk	x11, #0x3ff1, lsl #48
10116fc10:	61 01 67 9e	fmov	d1, x11
10116fc14:	00 20 61 1e	fcmp	d0, d1
10116fc18:	cd 00 00 54	b.le	0x10116fc30
10116fc1c:	eb e7 02 b2	mov	x11, #-0x3333333333333334
10116fc20:	cb fe e7 f2	movk	x11, #0x3ff6, lsl #48
10116fc24:	61 01 67 9e	fmov	d1, x11
10116fc28:	00 20 61 1e	fcmp	d0, d1
10116fc2c:	4b 01 00 54	b.lt	0x10116fc54
10116fc30:	eb e7 00 b2	mov	x11, #0x3333333333333333
10116fc34:	8b 66 86 f2	movk	x11, #0x3334
10116fc38:	2b ff e7 f2	movk	x11, #0x3ff9, lsl #48
10116fc3c:	61 01 67 9e	fmov	d1, x11
10116fc40:	00 20 61 1e	fcmp	d0, d1
10116fc44:	ad d8 ff 54	b.le	0x10116f758
10116fc48:	a1 01 67 9e	fmov	d1, x13
10116fc4c:	00 20 61 1e	fcmp	d0, d1
10116fc50:	4a d8 ff 54	b.ge	0x10116f758
10116fc54:	0b 16 00 51	sub	w11, w16, #0x5
10116fc58:	df 01 0b 6b	cmp	w14, w11
10116fc5c:	6c 06 00 54	b.gt	0x10116fd28
10116fc60:	d6 11 00 91	add	x22, x14, #0x4
10116fc64:	80 7a 76 fc	ldr	d0, [x20, x22, lsl #3]
10116fc68:	eb a3 90 d2	mov	x11, #0x851f
10116fc6c:	6b 3d aa f2	movk	x11, #0x51eb, lsl #16
10116fc70:	0b d7 c3 f2	movk	x11, #0x1eb8, lsl #32
10116fc74:	2b fe e7 f2	movk	x11, #0x3ff1, lsl #48
10116fc78:	61 01 67 9e	fmov	d1, x11
10116fc7c:	00 20 61 1e	fcmp	d0, d1
10116fc80:	cd 00 00 54	b.le	0x10116fc98
10116fc84:	eb e7 02 b2	mov	x11, #-0x3333333333333334
10116fc88:	cb fe e7 f2	movk	x11, #0x3ff6, lsl #48
10116fc8c:	61 01 67 9e	fmov	d1, x11
10116fc90:	00 20 61 1e	fcmp	d0, d1
10116fc94:	4b 01 00 54	b.lt	0x10116fcbc
10116fc98:	eb e7 00 b2	mov	x11, #0x3333333333333333
10116fc9c:	8b 66 86 f2	movk	x11, #0x3334
10116fca0:	2b ff e7 f2	movk	x11, #0x3ff9, lsl #48
10116fca4:	61 01 67 9e	fmov	d1, x11
10116fca8:	00 20 61 1e	fcmp	d0, d1
10116fcac:	ed 03 00 54	b.le	0x10116fd28
10116fcb0:	a1 01 67 9e	fmov	d1, x13
10116fcb4:	00 20 61 1e	fcmp	d0, d1
10116fcb8:	8a 03 00 54	b.ge	0x10116fd28
10116fcbc:	09 1a 00 51	sub	w9, w16, #0x6
10116fcc0:	df 01 09 6b	cmp	w14, w9
10116fcc4:	4c 03 00 54	b.gt	0x10116fd2c
10116fcc8:	c9 15 00 91	add	x9, x14, #0x5
10116fccc:	80 7a 69 fc	ldr	d0, [x20, x9, lsl #3]
10116fcd0:	eb a3 90 d2	mov	x11, #0x851f
10116fcd4:	6b 3d aa f2	movk	x11, #0x51eb, lsl #16
10116fcd8:	0b d7 c3 f2	movk	x11, #0x1eb8, lsl #32
10116fcdc:	2b fe e7 f2	movk	x11, #0x3ff1, lsl #48
10116fce0:	61 01 67 9e	fmov	d1, x11
10116fce4:	00 20 61 1e	fcmp	d0, d1
10116fce8:	cd 00 00 54	b.le	0x10116fd00
10116fcec:	eb e7 02 b2	mov	x11, #-0x3333333333333334
10116fcf0:	cb fe e7 f2	movk	x11, #0x3ff6, lsl #48
10116fcf4:	61 01 67 9e	fmov	d1, x11
10116fcf8:	00 20 61 1e	fcmp	d0, d1
10116fcfc:	4b 01 00 54	b.lt	0x10116fd24
10116fd00:	eb e7 00 b2	mov	x11, #0x3333333333333333
10116fd04:	8b 66 86 f2	movk	x11, #0x3334
10116fd08:	2b ff e7 f2	movk	x11, #0x3ff9, lsl #48
10116fd0c:	61 01 67 9e	fmov	d1, x11
10116fd10:	00 20 61 1e	fcmp	d0, d1
10116fd14:	cd 00 00 54	b.le	0x10116fd2c
10116fd18:	a1 01 67 9e	fmov	d1, x13
10116fd1c:	00 20 61 1e	fcmp	d0, d1
10116fd20:	6a 00 00 54	b.ge	0x10116fd2c
10116fd24:	31 00 80 52	mov	w17, #0x1
10116fd28:	f6 03 09 aa	mov	x22, x9
10116fd2c:	4b 05 00 71	subs	w11, w10, #0x1
10116fd30:	2b 02 00 54	b.lt	0x10116fd74
10116fd34:	80 5a 6b fc	ldr	d0, [x20, w11, uxtw #3]
10116fd38:	e9 a3 90 d2	mov	x9, #0x851f
10116fd3c:	69 3d aa f2	movk	x9, #0x51eb, lsl #16
10116fd40:	09 d7 c3 f2	movk	x9, #0x1eb8, lsl #32
10116fd44:	29 fe e7 f2	movk	x9, #0x3ff1, lsl #48
10116fd48:	21 01 67 9e	fmov	d1, x9
10116fd4c:	00 20 61 1e	fcmp	d0, d1
10116fd50:	6d 01 00 54	b.le	0x10116fd7c
10116fd54:	e9 e7 02 b2	mov	x9, #-0x3333333333333334
10116fd58:	c9 fe e7 f2	movk	x9, #0x3ff6, lsl #48
10116fd5c:	21 01 67 9e	fmov	d1, x9
10116fd60:	00 20 61 1e	fcmp	d0, d1
10116fd64:	ca 00 00 54	b.ge	0x10116fd7c
10116fd68:	5f 09 00 71	cmp	w10, #0x2
10116fd6c:	6a 02 00 54	b.ge	0x10116fdb8
10116fd70:	74 00 00 14	b	0x10116ff40
10116fd74:	e9 03 0a aa	mov	x9, x10
10116fd78:	73 00 00 14	b	0x10116ff44
10116fd7c:	e9 e7 00 b2	mov	x9, #0x3333333333333333
10116fd80:	89 66 86 f2	movk	x9, #0x3334
10116fd84:	29 ff e7 f2	movk	x9, #0x3ff9, lsl #48
10116fd88:	21 01 67 9e	fmov	d1, x9
10116fd8c:	00 20 61 1e	fcmp	d0, d1
10116fd90:	e9 c7 9f 1a	cset	w9, le
10116fd94:	a1 01 67 9e	fmov	d1, x13
10116fd98:	00 20 61 1e	fcmp	d0, d1
10116fd9c:	ec b7 9f 1a	cset	w12, ge
10116fda0:	2c 01 0c 2a	orr	w12, w9, w12
10116fda4:	9f 01 00 71	cmp	w12, #0x0
10116fda8:	49 11 9f 1a	csel	w9, w10, wzr, ne
10116fdac:	cc 0c 00 37	tbnz	w12, #0x0, 0x10116ff44
10116fdb0:	5f 09 00 71	cmp	w10, #0x2
10116fdb4:	8b 0c 00 54	b.lt	0x10116ff44
10116fdb8:	49 09 00 51	sub	w9, w10, #0x2
10116fdbc:	80 5a 69 fc	ldr	d0, [x20, w9, uxtw #3]
10116fdc0:	ec a3 90 d2	mov	x12, #0x851f
10116fdc4:	6c 3d aa f2	movk	x12, #0x51eb, lsl #16
10116fdc8:	0c d7 c3 f2	movk	x12, #0x1eb8, lsl #32
10116fdcc:	2c fe e7 f2	movk	x12, #0x3ff1, lsl #48
10116fdd0:	81 01 67 9e	fmov	d1, x12
10116fdd4:	00 20 61 1e	fcmp	d0, d1
10116fdd8:	cd 00 00 54	b.le	0x10116fdf0
10116fddc:	ec e7 02 b2	mov	x12, #-0x3333333333333334
10116fde0:	cc fe e7 f2	movk	x12, #0x3ff6, lsl #48
10116fde4:	81 01 67 9e	fmov	d1, x12
10116fde8:	00 20 61 1e	fcmp	d0, d1
10116fdec:	4b 01 00 54	b.lt	0x10116fe14
10116fdf0:	ec e7 00 b2	mov	x12, #0x3333333333333333
10116fdf4:	8c 66 86 f2	movk	x12, #0x3334
10116fdf8:	2c ff e7 f2	movk	x12, #0x3ff9, lsl #48
10116fdfc:	81 01 67 9e	fmov	d1, x12
10116fe00:	00 20 61 1e	fcmp	d0, d1
10116fe04:	ad 09 00 54	b.le	0x10116ff38
10116fe08:	a1 01 67 9e	fmov	d1, x13
10116fe0c:	00 20 61 1e	fcmp	d0, d1
10116fe10:	4a 09 00 54	b.ge	0x10116ff38
10116fe14:	4b 0d 00 71	subs	w11, w10, #0x3
10116fe18:	43 09 00 54	b.lo	0x10116ff40
10116fe1c:	80 5a 6b fc	ldr	d0, [x20, w11, uxtw #3]
10116fe20:	ec a3 90 d2	mov	x12, #0x851f
10116fe24:	6c 3d aa f2	movk	x12, #0x51eb, lsl #16
10116fe28:	0c d7 c3 f2	movk	x12, #0x1eb8, lsl #32
10116fe2c:	2c fe e7 f2	movk	x12, #0x3ff1, lsl #48
10116fe30:	81 01 67 9e	fmov	d1, x12
10116fe34:	00 20 61 1e	fcmp	d0, d1
10116fe38:	cd 00 00 54	b.le	0x10116fe50
10116fe3c:	ec e7 02 b2	mov	x12, #-0x3333333333333334
10116fe40:	cc fe e7 f2	movk	x12, #0x3ff6, lsl #48
10116fe44:	81 01 67 9e	fmov	d1, x12
10116fe48:	00 20 61 1e	fcmp	d0, d1
10116fe4c:	4b 01 00 54	b.lt	0x10116fe74
10116fe50:	ec e7 00 b2	mov	x12, #0x3333333333333333
10116fe54:	8c 66 86 f2	movk	x12, #0x3334
10116fe58:	2c ff e7 f2	movk	x12, #0x3ff9, lsl #48
10116fe5c:	81 01 67 9e	fmov	d1, x12
10116fe60:	00 20 61 1e	fcmp	d0, d1
10116fe64:	0d 07 00 54	b.le	0x10116ff44
10116fe68:	a1 01 67 9e	fmov	d1, x13
10116fe6c:	00 20 61 1e	fcmp	d0, d1
10116fe70:	aa 06 00 54	b.ge	0x10116ff44
10116fe74:	49 11 00 71	subs	w9, w10, #0x4
10116fe78:	43 06 00 54	b.lo	0x10116ff40
10116fe7c:	80 5a 69 fc	ldr	d0, [x20, w9, uxtw #3]
10116fe80:	ec a3 90 d2	mov	x12, #0x851f
10116fe84:	6c 3d aa f2	movk	x12, #0x51eb, lsl #16
10116fe88:	0c d7 c3 f2	movk	x12, #0x1eb8, lsl #32
10116fe8c:	2c fe e7 f2	movk	x12, #0x3ff1, lsl #48
10116fe90:	81 01 67 9e	fmov	d1, x12
10116fe94:	00 20 61 1e	fcmp	d0, d1
10116fe98:	cd 00 00 54	b.le	0x10116feb0
10116fe9c:	ec e7 02 b2	mov	x12, #-0x3333333333333334
10116fea0:	cc fe e7 f2	movk	x12, #0x3ff6, lsl #48
10116fea4:	81 01 67 9e	fmov	d1, x12
10116fea8:	00 20 61 1e	fcmp	d0, d1
10116feac:	4b 01 00 54	b.lt	0x10116fed4
10116feb0:	ec e7 00 b2	mov	x12, #0x3333333333333333
10116feb4:	8c 66 86 f2	movk	x12, #0x3334
10116feb8:	2c ff e7 f2	movk	x12, #0x3ff9, lsl #48
10116febc:	81 01 67 9e	fmov	d1, x12
10116fec0:	00 20 61 1e	fcmp	d0, d1
10116fec4:	ad 03 00 54	b.le	0x10116ff38
10116fec8:	a1 01 67 9e	fmov	d1, x13
10116fecc:	00 20 61 1e	fcmp	d0, d1
10116fed0:	4a 03 00 54	b.ge	0x10116ff38
10116fed4:	4b 15 00 71	subs	w11, w10, #0x5
10116fed8:	43 03 00 54	b.lo	0x10116ff40
10116fedc:	80 5a 6b fc	ldr	d0, [x20, w11, uxtw #3]
10116fee0:	ec a3 90 d2	mov	x12, #0x851f
10116fee4:	6c 3d aa f2	movk	x12, #0x51eb, lsl #16
10116fee8:	0c d7 c3 f2	movk	x12, #0x1eb8, lsl #32
10116feec:	2c fe e7 f2	movk	x12, #0x3ff1, lsl #48
10116fef0:	81 01 67 9e	fmov	d1, x12
10116fef4:	00 20 61 1e	fcmp	d0, d1
10116fef8:	cd 00 00 54	b.le	0x10116ff10
10116fefc:	ec e7 02 b2	mov	x12, #-0x3333333333333334
10116ff00:	cc fe e7 f2	movk	x12, #0x3ff6, lsl #48
10116ff04:	81 01 67 9e	fmov	d1, x12
10116ff08:	00 20 61 1e	fcmp	d0, d1
10116ff0c:	4b 01 00 54	b.lt	0x10116ff34
10116ff10:	ec e7 00 b2	mov	x12, #0x3333333333333333
10116ff14:	8c 66 86 f2	movk	x12, #0x3334
10116ff18:	2c ff e7 f2	movk	x12, #0x3ff9, lsl #48
10116ff1c:	81 01 67 9e	fmov	d1, x12
10116ff20:	00 20 61 1e	fcmp	d0, d1
10116ff24:	0d 01 00 54	b.le	0x10116ff44
10116ff28:	a1 01 67 9e	fmov	d1, x13
10116ff2c:	00 20 61 1e	fcmp	d0, d1
10116ff30:	aa 00 00 54	b.ge	0x10116ff44
10116ff34:	31 00 80 52	mov	w17, #0x1
10116ff38:	e9 03 0b aa	mov	x9, x11
10116ff3c:	02 00 00 14	b	0x10116ff44
10116ff40:	09 00 80 52	mov	w9, #0x0
10116ff44:	5f 01 08 6b	cmp	w10, w8
10116ff48:	ad 00 00 54	b.le	0x10116ff5c
10116ff4c:	eb 03 0a aa	mov	x11, x10
10116ff50:	ea f3 01 b2	mov	x10, #-0x5555555555555556
10116ff54:	6a 55 95 f2	movk	x10, #0xaaab
10116ff58:	59 00 00 14	b	0x1011700bc
10116ff5c:	4b 05 00 11	add	w11, w10, #0x1
10116ff60:	80 da 6b fc	ldr	d0, [x20, w11, sxtw #3]
10116ff64:	e8 a3 90 d2	mov	x8, #0x851f
10116ff68:	68 3d aa f2	movk	x8, #0x51eb, lsl #16
10116ff6c:	08 d7 c3 f2	movk	x8, #0x1eb8, lsl #32
10116ff70:	28 fe e7 f2	movk	x8, #0x3ff1, lsl #48
10116ff74:	01 01 67 9e	fmov	d1, x8
10116ff78:	00 20 61 1e	fcmp	d0, d1
10116ff7c:	cd 00 00 54	b.le	0x10116ff94
10116ff80:	e8 e7 02 b2	mov	x8, #-0x3333333333333334
10116ff84:	c8 fe e7 f2	movk	x8, #0x3ff6, lsl #48
10116ff88:	01 01 67 9e	fmov	d1, x8
10116ff8c:	00 20 61 1e	fcmp	d0, d1
10116ff90:	4b 01 00 54	b.lt	0x10116ffb8
10116ff94:	e8 e7 00 b2	mov	x8, #0x3333333333333333
10116ff98:	88 66 86 f2	movk	x8, #0x3334
10116ff9c:	28 ff e7 f2	movk	x8, #0x3ff9, lsl #48
10116ffa0:	01 01 67 9e	fmov	d1, x8
10116ffa4:	00 20 61 1e	fcmp	d0, d1
10116ffa8:	2d fd ff 54	b.le	0x10116ff4c
10116ffac:	a1 01 67 9e	fmov	d1, x13
10116ffb0:	00 20 61 1e	fcmp	d0, d1
10116ffb4:	ca fc ff 54	b.ge	0x10116ff4c
10116ffb8:	08 0e 00 51	sub	w8, w16, #0x3
10116ffbc:	5f 01 08 6b	cmp	w10, w8
10116ffc0:	8d 00 00 54	b.le	0x10116ffd0
10116ffc4:	ea f3 01 b2	mov	x10, #-0x5555555555555556
10116ffc8:	6a 55 95 f2	movk	x10, #0xaaab
10116ffcc:	3c 00 00 14	b	0x1011700bc
10116ffd0:	48 09 00 11	add	w8, w10, #0x2
10116ffd4:	80 da 68 fc	ldr	d0, [x20, w8, sxtw #3]
10116ffd8:	ec a3 90 d2	mov	x12, #0x851f
10116ffdc:	6c 3d aa f2	movk	x12, #0x51eb, lsl #16
10116ffe0:	0c d7 c3 f2	movk	x12, #0x1eb8, lsl #32
10116ffe4:	2c fe e7 f2	movk	x12, #0x3ff1, lsl #48
10116ffe8:	81 01 67 9e	fmov	d1, x12
10116ffec:	00 20 61 1e	fcmp	d0, d1
10116fff0:	cd 00 00 54	b.le	0x101170008
10116fff4:	ec e7 02 b2	mov	x12, #-0x3333333333333334
10116fff8:	cc fe e7 f2	movk	x12, #0x3ff6, lsl #48
10116fffc:	81 01 67 9e	fmov	d1, x12
101170000:	00 20 61 1e	fcmp	d0, d1
101170004:	4b 01 00 54	b.lt	0x10117002c
101170008:	ec e7 00 b2	mov	x12, #0x3333333333333333
10117000c:	8c 66 86 f2	movk	x12, #0x3334
101170010:	2c ff e7 f2	movk	x12, #0x3ff9, lsl #48
101170014:	81 01 67 9e	fmov	d1, x12
101170018:	00 20 61 1e	fcmp	d0, d1
10117001c:	4d fd ff 54	b.le	0x10116ffc4
101170020:	a1 01 67 9e	fmov	d1, x13
101170024:	00 20 61 1e	fcmp	d0, d1
101170028:	ea fc ff 54	b.ge	0x10116ffc4
10117002c:	0b 12 00 51	sub	w11, w16, #0x4
101170030:	5f 01 0b 6b	cmp	w10, w11
101170034:	ad 00 00 54	b.le	0x101170048
101170038:	eb 03 08 aa	mov	x11, x8
10117003c:	ea f3 01 b2	mov	x10, #-0x5555555555555556
101170040:	6a 55 95 f2	movk	x10, #0xaaab
101170044:	1e 00 00 14	b	0x1011700bc
101170048:	4c 0d 00 11	add	w12, w10, #0x3
10117004c:	80 da 6c fc	ldr	d0, [x20, w12, sxtw #3]
101170050:	eb a3 90 d2	mov	x11, #0x851f
101170054:	6b 3d aa f2	movk	x11, #0x51eb, lsl #16
101170058:	0b d7 c3 f2	movk	x11, #0x1eb8, lsl #32
10117005c:	2b fe e7 f2	movk	x11, #0x3ff1, lsl #48
101170060:	61 01 67 9e	fmov	d1, x11
101170064:	00 20 61 1e	fcmp	d0, d1
101170068:	cd 00 00 54	b.le	0x101170080
10117006c:	eb e7 02 b2	mov	x11, #-0x3333333333333334
101170070:	cb fe e7 f2	movk	x11, #0x3ff6, lsl #48
101170074:	61 01 67 9e	fmov	d1, x11
101170078:	00 20 61 1e	fcmp	d0, d1
10117007c:	4b 01 00 54	b.lt	0x1011700a4
101170080:	eb e7 00 b2	mov	x11, #0x3333333333333333
101170084:	8b 66 86 f2	movk	x11, #0x3334
101170088:	2b ff e7 f2	movk	x11, #0x3ff9, lsl #48
10117008c:	61 01 67 9e	fmov	d1, x11
101170090:	00 20 61 1e	fcmp	d0, d1
101170094:	2d fd ff 54	b.le	0x101170038
101170098:	a1 01 67 9e	fmov	d1, x13
10117009c:	00 20 61 1e	fcmp	d0, d1
1011700a0:	ca fc ff 54	b.ge	0x101170038
1011700a4:	08 16 00 51	sub	w8, w16, #0x5
1011700a8:	5f 01 08 6b	cmp	w10, w8
1011700ac:	cd 3a 02 54	b.le	0x101174804
1011700b0:	eb 03 0c aa	mov	x11, x12
1011700b4:	ea f3 01 b2	mov	x10, #-0x5555555555555556
1011700b8:	6a 55 95 f2	movk	x10, #0xaaab
1011700bc:	f1 c3 00 b9	str	w17, [sp, #0xc0]
1011700c0:	3f 01 00 71	cmp	w9, #0x0
1011700c4:	39 c1 9f 1a	csel	w25, w9, wzr, gt
1011700c8:	1a 03 40 f9	ldr	x26, [x24]
1011700cc:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
1011700d0:	08 01 40 f9	ldr	x8, [x8]
1011700d4:	49 03 08 cb	sub	x9, x26, x8
1011700d8:	29 fd 43 93	asr	x9, x9, #3
1011700dc:	29 7d 0a 9b	mul	x9, x9, x10
1011700e0:	2a 05 00 d1	sub	x10, x9, #0x1
1011700e4:	2c 05 00 51	sub	w12, w9, #0x1
1011700e8:	5f c1 2b eb	cmp	x10, w11, sxtw
1011700ec:	8b 31 8b 1a	csel	w11, w12, w11, lo
1011700f0:	7f 01 19 6b	cmp	w11, w25
1011700f4:	f9 83 00 f9	str	x25, [sp, #0x100]
1011700f8:	eb 6b 00 f9	str	x11, [sp, #0xd0]
1011700fc:	2d 04 00 54	b.le	0x101170180
101170100:	75 7d 40 93	sxtw	x21, w11
101170104:	14 03 80 52	mov	w20, #0x18
101170108:	60 21 34 9b	smaddl	x0, w11, w20, x8
10117010c:	01 60 00 91	add	x1, x0, #0x18
101170110:	42 03 01 cb	sub	x2, x26, x1
101170114:	4e 89 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
101170118:	5a 63 00 d1	sub	x26, x26, #0x18
10117011c:	1a 03 00 f9	str	x26, [x24]
101170120:	b5 06 00 d1	sub	x21, x21, #0x1
101170124:	bf 02 19 eb	cmp	x21, x25
101170128:	f7 b3 40 f9	ldr	x23, [sp, #0x160]
10117012c:	6d 01 00 54	b.le	0x101170158
101170130:	e8 02 40 f9	ldr	x8, [x23]
101170134:	a0 22 14 9b	madd	x0, x21, x20, x8
101170138:	01 60 00 91	add	x1, x0, #0x18
10117013c:	42 03 01 cb	sub	x2, x26, x1
101170140:	43 89 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
101170144:	5a 63 00 d1	sub	x26, x26, #0x18
101170148:	1a 03 00 f9	str	x26, [x24]
10117014c:	b5 06 00 d1	sub	x21, x21, #0x1
101170150:	bf 02 19 eb	cmp	x21, x25
101170154:	ec fe ff 54	b.gt	0x101170130
101170158:	e8 02 40 f9	ldr	x8, [x23]
10117015c:	49 03 08 cb	sub	x9, x26, x8
101170160:	29 fd 43 93	asr	x9, x9, #3
101170164:	ea f3 01 b2	mov	x10, #-0x5555555555555556
101170168:	6a 55 95 f2	movk	x10, #0xaaab
10117016c:	29 7d 0a 9b	mul	x9, x9, x10
101170170:	2a 05 00 d1	sub	x10, x9, #0x1
101170174:	2c 05 00 51	sub	w12, w9, #0x1
101170178:	f7 03 19 aa	mov	x23, x25
10117017c:	02 00 00 14	b	0x101170184
101170180:	f7 03 0b aa	mov	x23, x11
101170184:	eb af 40 f9	ldr	x11, [sp, #0x158]
101170188:	f9 c3 31 91	add	x25, sp, #0xc70
10117018c:	37 7b 2b b8	str	w23, [x25, x11, lsl #2]
101170190:	7f 02 00 71	cmp	w19, #0x0
101170194:	6b c2 9f 1a	csel	w11, w19, wzr, gt
101170198:	5f c1 36 eb	cmp	x10, w22, sxtw
10117019c:	8a 31 96 1a	csel	w10, w12, w22, lo
1011701a0:	ec 03 0b aa	mov	x12, x11
1011701a4:	5f 01 0c 6b	cmp	w10, w12
1011701a8:	eb a3 00 f9	str	x11, [sp, #0x140]
1011701ac:	ea 67 00 f9	str	x10, [sp, #0xc8]
1011701b0:	ed 07 00 54	b.le	0x1011702ac
1011701b4:	55 7d 40 93	sxtw	x21, w10
1011701b8:	09 03 80 52	mov	w9, #0x18
1011701bc:	40 21 29 9b	smaddl	x0, w10, w9, x8
1011701c0:	01 60 00 91	add	x1, x0, #0x18
1011701c4:	42 03 01 cb	sub	x2, x26, x1
1011701c8:	21 89 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
1011701cc:	ec a3 40 f9	ldr	x12, [sp, #0x140]
1011701d0:	5a 63 00 d1	sub	x26, x26, #0x18
1011701d4:	e9 93 40 f9	ldr	x9, [sp, #0x120]
1011701d8:	28 6b 69 b8	ldr	w8, [x25, x9]
1011701dc:	1a 03 00 f9	str	x26, [x24]
1011701e0:	17 05 00 51	sub	w23, w8, #0x1
1011701e4:	37 6b 29 b8	str	w23, [x25, x9]
1011701e8:	b6 06 00 d1	sub	x22, x21, #0x1
1011701ec:	df 02 0c eb	cmp	x22, x12
1011701f0:	0d 05 00 54	b.le	0x101170290
1011701f4:	a8 06 15 8b	add	x8, x21, x21, lsl #1
1011701f8:	1b f1 7d d3	lsl	x27, x8, #3
1011701fc:	f3 03 18 aa	mov	x19, x24
101170200:	e8 02 80 92	mov	x8, #-0x18
101170204:	b9 7e 08 9b	mul	x25, x21, x8
101170208:	f5 b3 40 f9	ldr	x21, [sp, #0x160]
10117020c:	f4 f3 01 b2	mov	x20, #-0x5555555555555556
101170210:	74 55 95 f2	movk	x20, #0xaaab
101170214:	54 55 e5 f2	movk	x20, #0x2aaa, lsl #48
101170218:	bc 02 40 f9	ldr	x28, [x21]
10117021c:	48 03 1c cb	sub	x8, x26, x28
101170220:	22 03 08 8b	add	x2, x25, x8
101170224:	48 7c 54 9b	smulh	x8, x2, x20
101170228:	09 fd 42 93	asr	x9, x8, #2
10117022c:	38 fd 48 8b	add	x24, x9, x8, lsr #63
101170230:	81 03 1b 8b	add	x1, x28, x27
101170234:	20 60 00 d1	sub	x0, x1, #0x18
101170238:	05 89 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
10117023c:	ec a3 40 f9	ldr	x12, [sp, #0x140]
101170240:	08 03 80 52	mov	w8, #0x18
101170244:	08 6f 08 9b	madd	x8, x24, x8, x27
101170248:	88 03 08 8b	add	x8, x28, x8
10117024c:	1a 61 00 d1	sub	x26, x8, #0x18
101170250:	7a 02 00 f9	str	x26, [x19]
101170254:	f7 06 00 51	sub	w23, w23, #0x1
101170258:	d6 06 00 d1	sub	x22, x22, #0x1
10117025c:	7b 63 00 d1	sub	x27, x27, #0x18
101170260:	39 63 00 91	add	x25, x25, #0x18
101170264:	df 02 0c eb	cmp	x22, x12
101170268:	8c fd ff 54	b.gt	0x101170218
10117026c:	e8 c3 31 91	add	x8, sp, #0xc70
101170270:	e9 af 40 f9	ldr	x9, [sp, #0x158]
101170274:	17 79 29 b8	str	w23, [x8, x9, lsl #2]
101170278:	08 03 80 52	mov	w8, #0x18
10117027c:	08 73 08 9b	madd	x8, x24, x8, x28
101170280:	1a 01 19 cb	sub	x26, x8, x25
101170284:	f9 c3 31 91	add	x25, sp, #0xc70
101170288:	fb 9f 40 f9	ldr	x27, [sp, #0x138]
10117028c:	f8 03 13 aa	mov	x24, x19
101170290:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
101170294:	08 01 40 f9	ldr	x8, [x8]
101170298:	49 03 08 cb	sub	x9, x26, x8
10117029c:	29 fd 43 93	asr	x9, x9, #3
1011702a0:	ea f3 01 b2	mov	x10, #-0x5555555555555556
1011702a4:	6a 55 95 f2	movk	x10, #0xaaab
1011702a8:	29 7d 0a 9b	mul	x9, x9, x10
1011702ac:	ea c3 39 91	add	x10, sp, #0xe70
1011702b0:	f3 af 40 f9	ldr	x19, [sp, #0x158]
1011702b4:	4c 79 33 b8	str	w12, [x10, x19, lsl #2]
1011702b8:	2a 01 0c 6b	subs	w10, w9, w12
1011702bc:	ed 09 00 54	b.le	0x1011703f8
1011702c0:	2b 15 00 51	sub	w11, w9, #0x5
1011702c4:	9f 01 0b 6b	cmp	w12, w11
1011702c8:	ab 00 80 52	mov	w11, #0x5
1011702cc:	4a c1 8b 1a	csel	w10, w10, w11, gt
1011702d0:	5f 05 00 71	cmp	w10, #0x1
1011702d4:	2b 09 00 54	b.lt	0x1011703f8
1011702d8:	ed 03 0c aa	mov	x13, x12
1011702dc:	0c 03 80 52	mov	w12, #0x18
1011702e0:	ab 7d ac 9b	umull	x11, w13, w12
1011702e4:	00 69 6b bc	ldr	s0, [x8, x11]
1011702e8:	00 a4 20 0f	sshll.2d	v0, v0, #0x0
1011702ec:	00 d8 61 5e	scvtf	d0, d0
1011702f0:	61 03 40 bd	ldr	s1, [x27]
1011702f4:	21 a4 20 0f	sshll.2d	v1, v1, #0x0
1011702f8:	23 d8 61 5e	scvtf	d3, d1
1011702fc:	01 18 63 1e	fdiv	d1, d0, d3
101170300:	4a 7d 40 93	sxtw	x10, w10
101170304:	e0 7f 40 fd	ldr	d0, [sp, #0xf8]
101170308:	22 28 60 1e	fadd	d2, d1, d0
10117030c:	a0 19 63 1e	fdiv	d0, d13, d3
101170310:	ab 05 00 91	add	x11, x13, #0x1
101170314:	ac 21 0c 9b	madd	x12, x13, x12, x8
101170318:	8c 61 00 91	add	x12, x12, #0x18
10117031c:	ed 03 0c aa	mov	x13, x12
101170320:	f6 03 0b aa	mov	x22, x11
101170324:	ee 03 0a aa	mov	x14, x10
101170328:	3f 01 16 eb	cmp	x9, x22
10117032c:	c9 01 00 54	b.ls	0x101170364
101170330:	a3 01 40 bd	ldr	s3, [x13]
101170334:	63 a4 20 0f	sshll.2d	v3, v3, #0x0
101170338:	63 d8 61 5e	scvtf	d3, d3
10117033c:	63 08 60 1e	fmul	d3, d3, d0
101170340:	64 38 69 1e	fsub	d4, d3, d9
101170344:	63 28 69 1e	fadd	d3, d3, d9
101170348:	40 20 64 1e	fcmp	d2, d4
10117034c:	40 c4 63 1e	fccmp	d2, d3, #0x0, gt
101170350:	4b d6 00 54	b.lt	0x101171e18
101170354:	d6 06 00 91	add	x22, x22, #0x1
101170358:	ad 61 00 91	add	x13, x13, #0x18
10117035c:	ce 05 00 f1	subs	x14, x14, #0x1
101170360:	41 fe ff 54	b.ne	0x101170328
101170364:	e2 5f 40 fd	ldr	d2, [sp, #0xb8]
101170368:	22 28 62 1e	fadd	d2, d1, d2
10117036c:	ed 03 0c aa	mov	x13, x12
101170370:	f6 03 0b aa	mov	x22, x11
101170374:	ee 03 0a aa	mov	x14, x10
101170378:	3f 01 16 eb	cmp	x9, x22
10117037c:	c9 01 00 54	b.ls	0x1011703b4
101170380:	a3 01 40 bd	ldr	s3, [x13]
101170384:	63 a4 20 0f	sshll.2d	v3, v3, #0x0
101170388:	63 d8 61 5e	scvtf	d3, d3
10117038c:	63 08 60 1e	fmul	d3, d3, d0
101170390:	64 38 69 1e	fsub	d4, d3, d9
101170394:	63 28 69 1e	fadd	d3, d3, d9
101170398:	40 20 64 1e	fcmp	d2, d4
10117039c:	40 c4 63 1e	fccmp	d2, d3, #0x0, gt
1011703a0:	cb d3 00 54	b.lt	0x101171e18
1011703a4:	d6 06 00 91	add	x22, x22, #0x1
1011703a8:	ad 61 00 91	add	x13, x13, #0x18
1011703ac:	ce 05 00 f1	subs	x14, x14, #0x1
1011703b0:	41 fe ff 54	b.ne	0x101170378
1011703b4:	e2 3f 40 fd	ldr	d2, [sp, #0x78]
1011703b8:	21 28 62 1e	fadd	d1, d1, d2
1011703bc:	3f 01 0b eb	cmp	x9, x11
1011703c0:	c9 01 00 54	b.ls	0x1011703f8
1011703c4:	82 01 40 bd	ldr	s2, [x12]
1011703c8:	42 a4 20 0f	sshll.2d	v2, v2, #0x0
1011703cc:	42 d8 61 5e	scvtf	d2, d2
1011703d0:	42 08 60 1e	fmul	d2, d2, d0
1011703d4:	43 38 69 1e	fsub	d3, d2, d9
1011703d8:	42 28 69 1e	fadd	d2, d2, d9
1011703dc:	20 20 63 1e	fcmp	d1, d3
1011703e0:	20 c4 62 1e	fccmp	d1, d2, #0x0, gt
1011703e4:	8b d1 00 54	b.lt	0x101171e14
1011703e8:	6b 05 00 91	add	x11, x11, #0x1
1011703ec:	8c 61 00 91	add	x12, x12, #0x18
1011703f0:	4a 05 00 f1	subs	x10, x10, #0x1
1011703f4:	41 fe ff 54	b.ne	0x1011703bc
1011703f8:	ff 23 01 b9	str	wzr, [sp, #0x120]
1011703fc:	e9 06 00 71	subs	w9, w23, #0x1
101170400:	0b 09 00 54	b.lt	0x101170520
101170404:	eb 03 17 2a	mov	w11, w23
101170408:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
10117040c:	08 01 40 f9	ldr	x8, [x8]
101170410:	0a 03 80 52	mov	w10, #0x18
101170414:	ed 22 aa 9b	umaddl	x13, w23, w10, x8
101170418:	a0 01 40 bd	ldr	s0, [x13]
10117041c:	00 a4 20 0f	sshll.2d	v0, v0, #0x0
101170420:	00 d8 61 5e	scvtf	d0, d0
101170424:	61 03 40 bd	ldr	s1, [x27]
101170428:	21 a4 20 0f	sshll.2d	v1, v1, #0x0
10117042c:	21 d8 61 5e	scvtf	d1, d1
101170430:	00 18 61 1e	fdiv	d0, d0, d1
101170434:	ff 16 00 71	cmp	w23, #0x5
101170438:	aa 00 80 52	mov	w10, #0x5
10117043c:	ec b2 8a 1a	csel	w12, w23, w10, lt
101170440:	e2 7f 40 fd	ldr	d2, [sp, #0xf8]
101170444:	02 38 62 1e	fsub	d2, d0, d2
101170448:	6a 05 00 d1	sub	x10, x11, #0x1
10117044c:	a3 81 5e bc	ldur	s3, [x13, #-0x18]
101170450:	63 a4 20 0f	sshll.2d	v3, v3, #0x0
101170454:	63 d8 61 5e	scvtf	d3, d3
101170458:	63 18 61 1e	fdiv	d3, d3, d1
10117045c:	64 38 69 1e	fsub	d4, d3, d9
101170460:	63 28 69 1e	fadd	d3, d3, d9
101170464:	40 20 64 1e	fcmp	d2, d4
101170468:	40 c4 63 1e	fccmp	d2, d3, #0x0, gt
10117046c:	f4 03 0a aa	mov	x20, x10
101170470:	6b 0d 00 54	b.lt	0x10117061c
101170474:	8c 05 00 11	add	w12, w12, #0x1
101170478:	9f 09 00 71	cmp	w12, #0x2
10117047c:	a1 05 00 54	b.ne	0x101170530
101170480:	e2 5f 40 fd	ldr	d2, [sp, #0xb8]
101170484:	02 38 62 1e	fsub	d2, d0, d2
101170488:	8c 05 00 d1	sub	x12, x12, #0x1
10117048c:	0d 03 80 52	mov	w13, #0x18
101170490:	6b 21 0d 9b	madd	x11, x11, x13, x8
101170494:	6b 61 00 d1	sub	x11, x11, #0x18
101170498:	ed 03 0b aa	mov	x13, x11
10117049c:	f4 03 0a aa	mov	x20, x10
1011704a0:	ee 03 0c aa	mov	x14, x12
1011704a4:	a1 19 61 1e	fdiv	d1, d13, d1
1011704a8:	a3 01 40 bd	ldr	s3, [x13]
1011704ac:	63 a4 20 0f	sshll.2d	v3, v3, #0x0
1011704b0:	63 d8 61 5e	scvtf	d3, d3
1011704b4:	63 08 61 1e	fmul	d3, d3, d1
1011704b8:	64 38 69 1e	fsub	d4, d3, d9
1011704bc:	63 28 69 1e	fadd	d3, d3, d9
1011704c0:	40 20 64 1e	fcmp	d2, d4
1011704c4:	40 c4 63 1e	fccmp	d2, d3, #0x0, gt
1011704c8:	ab 0a 00 54	b.lt	0x10117061c
1011704cc:	94 06 00 d1	sub	x20, x20, #0x1
1011704d0:	ad 61 00 d1	sub	x13, x13, #0x18
1011704d4:	ce 05 00 d1	sub	x14, x14, #0x1
1011704d8:	8e fe ff b5	cbnz	x14, 0x1011704a8
1011704dc:	e2 3f 40 fd	ldr	d2, [sp, #0x78]
1011704e0:	00 38 62 1e	fsub	d0, d0, d2
1011704e4:	62 01 40 bd	ldr	s2, [x11]
1011704e8:	42 a4 20 0f	sshll.2d	v2, v2, #0x0
1011704ec:	42 d8 61 5e	scvtf	d2, d2
1011704f0:	42 08 61 1e	fmul	d2, d2, d1
1011704f4:	43 38 69 1e	fsub	d3, d2, d9
1011704f8:	42 28 69 1e	fadd	d2, d2, d9
1011704fc:	00 20 63 1e	fcmp	d0, d3
101170500:	00 c4 62 1e	fccmp	d0, d2, #0x0, gt
101170504:	ab 08 00 54	b.lt	0x101170618
101170508:	4a 05 00 d1	sub	x10, x10, #0x1
10117050c:	6b 61 00 d1	sub	x11, x11, #0x18
101170510:	8c 05 00 d1	sub	x12, x12, #0x1
101170514:	8c fe ff b5	cbnz	x12, 0x1011704e4
101170518:	f4 03 17 aa	mov	x20, x23
10117051c:	40 00 00 14	b	0x10117061c
101170520:	fc c3 31 91	add	x28, sp, #0xc70
101170524:	0d 00 80 52	mov	w13, #0x0
101170528:	ec c3 39 91	add	x12, sp, #0xe70
10117052c:	b4 00 00 14	b	0x1011707fc
101170530:	74 09 00 d1	sub	x20, x11, #0x2
101170534:	0d 03 80 52	mov	w13, #0x18
101170538:	8d 7e 0d 9b	mul	x13, x20, x13
10117053c:	03 69 6d bc	ldr	s3, [x8, x13]
101170540:	63 a4 20 0f	sshll.2d	v3, v3, #0x0
101170544:	63 d8 61 5e	scvtf	d3, d3
101170548:	63 18 61 1e	fdiv	d3, d3, d1
10117054c:	64 38 69 1e	fsub	d4, d3, d9
101170550:	63 28 69 1e	fadd	d3, d3, d9
101170554:	40 20 64 1e	fcmp	d2, d4
101170558:	40 c4 63 1e	fccmp	d2, d3, #0x0, gt
10117055c:	0b 06 00 54	b.lt	0x10117061c
101170560:	9f 0d 00 71	cmp	w12, #0x3
101170564:	e0 f8 ff 54	b.eq	0x101170480
101170568:	74 0d 00 d1	sub	x20, x11, #0x3
10117056c:	0d 03 80 52	mov	w13, #0x18
101170570:	8d 7e 0d 9b	mul	x13, x20, x13
101170574:	03 69 6d bc	ldr	s3, [x8, x13]
101170578:	63 a4 20 0f	sshll.2d	v3, v3, #0x0
10117057c:	63 d8 61 5e	scvtf	d3, d3
101170580:	63 18 61 1e	fdiv	d3, d3, d1
101170584:	64 38 69 1e	fsub	d4, d3, d9
101170588:	63 28 69 1e	fadd	d3, d3, d9
10117058c:	40 20 64 1e	fcmp	d2, d4
101170590:	40 c4 63 1e	fccmp	d2, d3, #0x0, gt
101170594:	4b 04 00 54	b.lt	0x10117061c
101170598:	9f 11 00 71	cmp	w12, #0x4
10117059c:	20 f7 ff 54	b.eq	0x101170480
1011705a0:	74 11 00 d1	sub	x20, x11, #0x4
1011705a4:	0d 03 80 52	mov	w13, #0x18
1011705a8:	8d 7e 0d 9b	mul	x13, x20, x13
1011705ac:	03 69 6d bc	ldr	s3, [x8, x13]
1011705b0:	63 a4 20 0f	sshll.2d	v3, v3, #0x0
1011705b4:	63 d8 61 5e	scvtf	d3, d3
1011705b8:	63 18 61 1e	fdiv	d3, d3, d1
1011705bc:	64 38 69 1e	fsub	d4, d3, d9
1011705c0:	63 28 69 1e	fadd	d3, d3, d9
1011705c4:	40 20 64 1e	fcmp	d2, d4
1011705c8:	40 c4 63 1e	fccmp	d2, d3, #0x0, gt
1011705cc:	8b 02 00 54	b.lt	0x10117061c
1011705d0:	9f 15 00 71	cmp	w12, #0x5
1011705d4:	60 f5 ff 54	b.eq	0x101170480
1011705d8:	74 15 00 d1	sub	x20, x11, #0x5
1011705dc:	0d 03 80 52	mov	w13, #0x18
1011705e0:	8d 7e 0d 9b	mul	x13, x20, x13
1011705e4:	03 69 6d bc	ldr	s3, [x8, x13]
1011705e8:	63 a4 20 0f	sshll.2d	v3, v3, #0x0
1011705ec:	63 d8 61 5e	scvtf	d3, d3
1011705f0:	63 18 61 1e	fdiv	d3, d3, d1
1011705f4:	64 38 69 1e	fsub	d4, d3, d9
1011705f8:	40 20 64 1e	fcmp	d2, d4
1011705fc:	2d f4 ff 54	b.le	0x101170480
101170600:	63 28 69 1e	fadd	d3, d3, d9
101170604:	40 20 63 1e	fcmp	d2, d3
101170608:	ab 00 00 54	b.lt	0x10117061c
10117060c:	9d ff ff 17	b	0x101170480
101170610:	e1 03 1a aa	mov	x1, x26
101170614:	5e fc ff 17	b	0x10116f78c
101170618:	f4 03 0a aa	mov	x20, x10
10117061c:	3f 01 14 6b	cmp	w9, w20
101170620:	ea f3 01 b2	mov	x10, #-0x5555555555555556
101170624:	6a 55 95 f2	movk	x10, #0xaaab
101170628:	2d 05 00 54	b.le	0x1011706cc
10117062c:	36 7d 40 93	sxtw	x22, w9
101170630:	49 03 08 cb	sub	x9, x26, x8
101170634:	29 fd 43 93	asr	x9, x9, #3
101170638:	29 7d 0a 9b	mul	x9, x9, x10
10117063c:	3f 01 16 eb	cmp	x9, x22
101170640:	69 04 00 54	b.ls	0x1011706cc
101170644:	f3 f3 01 b2	mov	x19, #-0x5555555555555556
101170648:	73 55 95 f2	movk	x19, #0xaaab
10117064c:	e9 0a 00 51	sub	w9, w23, #0x2
101170650:	f7 03 09 aa	mov	x23, x9
101170654:	09 03 80 52	mov	w9, #0x18
101170658:	c0 22 09 9b	madd	x0, x22, x9, x8
10117065c:	01 60 00 91	add	x1, x0, #0x18
101170660:	42 03 01 cb	sub	x2, x26, x1
101170664:	fa 87 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
101170668:	5a 63 00 d1	sub	x26, x26, #0x18
10117066c:	1a 03 00 f9	str	x26, [x24]
101170670:	9f 02 17 6b	cmp	w20, w23
101170674:	20 01 00 54	b.eq	0x101170698
101170678:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
10117067c:	08 01 40 f9	ldr	x8, [x8]
101170680:	49 03 08 cb	sub	x9, x26, x8
101170684:	29 fd 43 93	asr	x9, x9, #3
101170688:	2a 7d 13 9b	mul	x10, x9, x19
10117068c:	e9 06 00 51	sub	w9, w23, #0x1
101170690:	5f 01 16 eb	cmp	x10, x22
101170694:	e8 fd ff 54	b.hi	0x101170650
101170698:	f7 06 00 11	add	w23, w23, #0x1
10117069c:	f3 af 40 f9	ldr	x19, [sp, #0x158]
1011706a0:	37 7b 33 b8	str	w23, [x25, x19, lsl #2]
1011706a4:	2d 00 80 52	mov	w13, #0x1
1011706a8:	ea f3 01 b2	mov	x10, #-0x5555555555555556
1011706ac:	6a 55 95 f2	movk	x10, #0xaaab
1011706b0:	fc c3 31 91	add	x28, sp, #0xc70
1011706b4:	ec c3 39 91	add	x12, sp, #0xe70
1011706b8:	88 79 73 b8	ldr	w8, [x12, x19, lsl #2]
1011706bc:	08 05 00 11	add	w8, w8, #0x1
1011706c0:	1f 01 17 6b	cmp	w8, w23
1011706c4:	2b 01 00 54	b.lt	0x1011706e8
1011706c8:	4d 00 00 14	b	0x1011707fc
1011706cc:	0d 00 80 52	mov	w13, #0x0
1011706d0:	fc c3 31 91	add	x28, sp, #0xc70
1011706d4:	ec c3 39 91	add	x12, sp, #0xe70
1011706d8:	88 79 73 b8	ldr	w8, [x12, x19, lsl #2]
1011706dc:	08 05 00 11	add	w8, w8, #0x1
1011706e0:	1f 01 17 6b	cmp	w8, w23
1011706e4:	ca 08 00 54	b.ge	0x1011707fc
1011706e8:	ed a7 00 b9	str	w13, [sp, #0xa4]
1011706ec:	1b 7d 40 93	sxtw	x27, w8
1011706f0:	68 c7 28 8b	add	x8, x27, w8, sxtw #1
1011706f4:	08 f1 7d d3	lsl	x8, x8, #3
1011706f8:	16 c1 00 91	add	x22, x8, #0x30
1011706fc:	e9 05 80 92	mov	x9, #-0x30
101170700:	39 01 08 cb	sub	x25, x9, x8
101170704:	12 00 00 14	b	0x10117074c
101170708:	89 02 08 cb	sub	x9, x20, x8
10117070c:	c9 02 09 8b	add	x9, x22, x9
101170710:	21 01 08 8b	add	x1, x9, x8
101170714:	42 03 01 cb	sub	x2, x26, x1
101170718:	20 60 00 d1	sub	x0, x1, #0x18
10117071c:	cc 87 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
101170720:	ea f3 01 b2	mov	x10, #-0x5555555555555556
101170724:	6a 55 95 f2	movk	x10, #0xaaab
101170728:	5a 63 00 d1	sub	x26, x26, #0x18
10117072c:	e8 9b 40 f9	ldr	x8, [sp, #0x130]
101170730:	1a 01 00 f9	str	x26, [x8]
101170734:	f7 06 00 51	sub	w23, w23, #0x1
101170738:	97 7b 33 b8	str	w23, [x28, x19, lsl #2]
10117073c:	d6 62 00 91	add	x22, x22, #0x18
101170740:	39 63 00 d1	sub	x25, x25, #0x18
101170744:	7f c3 37 eb	cmp	x27, w23, sxtw
101170748:	4a 05 00 54	b.ge	0x1011707f0
10117074c:	f8 b3 40 f9	ldr	x24, [sp, #0x160]
101170750:	14 03 40 f9	ldr	x20, [x24]
101170754:	7b 07 00 91	add	x27, x27, #0x1
101170758:	48 03 14 cb	sub	x8, x26, x20
10117075c:	09 fd 43 93	asr	x9, x8, #3
101170760:	29 7d 0a 9b	mul	x9, x9, x10
101170764:	3f 01 1b eb	cmp	x9, x27
101170768:	c9 03 00 54	b.ls	0x1011707e0
10117076c:	22 03 08 8b	add	x2, x25, x8
101170770:	e8 f3 01 b2	mov	x8, #-0x5555555555555556
101170774:	68 55 95 f2	movk	x8, #0xaaab
101170778:	48 55 e5 f2	movk	x8, #0x2aaa, lsl #48
10117077c:	48 7c 48 9b	smulh	x8, x2, x8
101170780:	09 fd 42 93	asr	x9, x8, #2
101170784:	35 fd 48 8b	add	x21, x9, x8, lsr #63
101170788:	81 02 16 8b	add	x1, x20, x22
10117078c:	20 60 00 d1	sub	x0, x1, #0x18
101170790:	af 87 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
101170794:	ea f3 01 b2	mov	x10, #-0x5555555555555556
101170798:	6a 55 95 f2	movk	x10, #0xaaab
10117079c:	08 03 80 52	mov	w8, #0x18
1011707a0:	a9 52 08 9b	madd	x9, x21, x8, x20
1011707a4:	28 01 16 8b	add	x8, x9, x22
1011707a8:	1a 61 00 d1	sub	x26, x8, #0x18
1011707ac:	e8 9b 40 f9	ldr	x8, [sp, #0x130]
1011707b0:	1a 01 00 f9	str	x26, [x8]
1011707b4:	f7 06 00 51	sub	w23, w23, #0x1
1011707b8:	97 7b 33 b8	str	w23, [x28, x19, lsl #2]
1011707bc:	08 03 40 f9	ldr	x8, [x24]
1011707c0:	29 01 08 cb	sub	x9, x9, x8
1011707c4:	c9 02 09 8b	add	x9, x22, x9
1011707c8:	29 61 00 d1	sub	x9, x9, #0x18
1011707cc:	29 fd 43 93	asr	x9, x9, #3
1011707d0:	29 7d 0a 9b	mul	x9, x9, x10
1011707d4:	3f 01 1b eb	cmp	x9, x27
1011707d8:	29 fb ff 54	b.ls	0x10117073c
1011707dc:	cb ff ff 17	b	0x101170708
1011707e0:	e8 03 14 aa	mov	x8, x20
1011707e4:	3f 01 1b eb	cmp	x9, x27
1011707e8:	a9 fa ff 54	b.ls	0x10117073c
1011707ec:	c7 ff ff 17	b	0x101170708
1011707f0:	fb 9f 40 f9	ldr	x27, [sp, #0x138]
1011707f4:	ec c3 39 91	add	x12, sp, #0xe70
1011707f8:	ed a7 40 b9	ldr	w13, [sp, #0xa4]
1011707fc:	e8 83 40 f9	ldr	x8, [sp, #0x100]
101170800:	e9 6b 40 f9	ldr	x9, [sp, #0xd0]
101170804:	3f 01 08 6b	cmp	w9, w8
101170808:	e9 d7 9f 1a	cset	w9, gt
10117080c:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
101170810:	08 01 40 f9	ldr	x8, [x8]
101170814:	4a 03 08 cb	sub	x10, x26, x8
101170818:	4a fd 43 d3	lsr	x10, x10, #3
10117081c:	6b 55 95 52	mov	w11, #0xaaab
101170820:	4b 55 b5 72	movk	w11, #0xaaaa, lsl #16
101170824:	58 7d 0b 1b	mul	w24, w10, w11
101170828:	ff ef 01 f9	str	xzr, [sp, #0x3d8]
10117082c:	ff eb 01 f9	str	xzr, [sp, #0x3d0]
101170830:	0a 00 80 12	mov	w10, #-0x1
101170834:	ea e3 03 b9	str	w10, [sp, #0x3e0]
101170838:	ff 93 0f 39	strb	wzr, [sp, #0x3e4]
10117083c:	36 01 0d 2a	orr	w22, w9, w13
101170840:	09 07 00 51	sub	w9, w24, #0x1
101170844:	ff 02 09 6b	cmp	w23, w9
101170848:	e9 17 9f 1a	cset	w9, eq
10117084c:	df 02 00 72	tst	w22, #0x1
101170850:	2a 00 80 52	mov	w10, #0x1
101170854:	49 11 89 1a	csel	w9, w10, w9, ne
101170858:	ea a3 40 f9	ldr	x10, [sp, #0x140]
10117085c:	eb 67 40 f9	ldr	x11, [sp, #0xc8]
101170860:	7f 01 0a 6b	cmp	w11, w10
101170864:	ea d7 9f 1a	cset	w10, gt
101170868:	0b 0b 00 51	sub	w11, w24, #0x2
10117086c:	e9 02 09 4b	sub	w9, w23, w9
101170870:	3f 01 0b 6b	cmp	w9, w11
101170874:	29 b1 8b 1a	csel	w9, w9, w11, lt
101170878:	eb 23 41 b9	ldr	w11, [sp, #0x120]
10117087c:	54 01 0b 2a	orr	w20, w10, w11
101170880:	93 79 b3 b8	ldrsw	x19, [x12, x19, lsl #2]
101170884:	79 02 14 8b	add	x25, x19, x20
101170888:	3f 01 19 6b	cmp	w9, w25
10117088c:	cb 04 00 54	b.lt	0x101170924
101170890:	38 7d 40 93	sxtw	x24, w9
101170894:	f7 06 00 11	add	w23, w23, #0x1
101170898:	09 c7 29 8b	add	x9, x24, w9, sxtw #1
10117089c:	3a f1 7d d3	lsl	x26, x9, #3
1011708a0:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
1011708a4:	01 01 1a 8b	add	x1, x8, x26
1011708a8:	29 8c 41 b8	ldr	w9, [x1, #0x18]!
1011708ac:	08 69 7a b8	ldr	w8, [x8, x26]
1011708b0:	29 01 08 4b	sub	w9, w9, w8
1011708b4:	20 01 62 1e	scvtf	d0, w9
1011708b8:	01 01 62 1e	scvtf	d1, w8
1011708bc:	21 28 6e 1e	fadd	d1, d1, d14
1011708c0:	00 04 4e 1f	fmadd	d0, d0, d14, d1
1011708c4:	08 00 78 1e	fcvtzs	w8, d0
1011708c8:	e8 d3 03 b9	str	w8, [sp, #0x3d0]
1011708cc:	ff ef 01 f9	str	xzr, [sp, #0x3d8]
1011708d0:	e2 43 0f 91	add	x2, sp, #0x3d0
1011708d4:	51 3a ff 97	bl	__ZNSt3__16vectorIN16BeatAnalyzer_2_06peakss8BeatInfoENS_9allocatorIS3_EEE6insertENS_11__wrap_iterIPKS3_EERS8_
1011708d8:	e8 af 40 f9	ldr	x8, [sp, #0x158]
1011708dc:	97 7b 28 b8	str	w23, [x28, x8, lsl #2]
1011708e0:	1f 03 19 eb	cmp	x24, x25
1011708e4:	ed 00 00 54	b.le	0x101170900
1011708e8:	18 07 00 d1	sub	x24, x24, #0x1
1011708ec:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
1011708f0:	08 00 40 f9	ldr	x8, [x0]
1011708f4:	f7 06 00 11	add	w23, w23, #0x1
1011708f8:	5a 63 00 d1	sub	x26, x26, #0x18
1011708fc:	ea ff ff 17	b	0x1011708a4
101170900:	e8 9b 40 f9	ldr	x8, [sp, #0x130]
101170904:	09 01 40 f9	ldr	x9, [x8]
101170908:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
10117090c:	08 01 40 f9	ldr	x8, [x8]
101170910:	29 01 08 cb	sub	x9, x9, x8
101170914:	29 fd 43 d3	lsr	x9, x9, #3
101170918:	6a 55 95 52	mov	w10, #0xaaab
10117091c:	4a 55 b5 72	movk	w10, #0xaaaa, lsl #16
101170920:	38 7d 0a 1b	mul	w24, w9, w10
101170924:	15 03 80 52	mov	w21, #0x18
101170928:	96 07 00 36	tbz	w22, #0x0, 0x101170a18
10117092c:	f6 06 00 11	add	w22, w23, #0x1
101170930:	df 02 18 6b	cmp	w22, w24
101170934:	2a 07 00 54	b.ge	0x101170a18
101170938:	ea 7e 35 9b	smull	x10, w23, w21
10117093c:	00 69 6a bc	ldr	s0, [x8, x10]
101170940:	00 a4 20 0f	sshll.2d	v0, v0, #0x0
101170944:	00 d8 61 5e	scvtf	d0, d0
101170948:	69 03 40 b9	ldr	w9, [x27]
10117094c:	21 01 62 1e	scvtf	d1, w9
101170950:	0a 18 61 1e	fdiv	d10, d0, d1
101170954:	cb 7e 35 9b	smull	x11, w22, w21
101170958:	00 69 6b bc	ldr	s0, [x8, x11]
10117095c:	00 a4 20 0f	sshll.2d	v0, v0, #0x0
101170960:	00 d8 61 5e	scvtf	d0, d0
101170964:	00 18 61 1e	fdiv	d0, d0, d1
101170968:	0b 38 6a 1e	fsub	d11, d0, d10
10117096c:	0b 00 c8 d2	mov	x11, #0x400000000000
101170970:	eb 11 e8 f2	movk	x11, #0x408f, lsl #48
101170974:	60 01 67 9e	fmov	d0, x11
101170978:	60 09 60 1e	fmul	d0, d11, d0
10117097c:	00 38 4c 1f	fmadd	d0, d0, d12, d14
101170980:	0b 00 78 1e	fcvtzs	w11, d0
101170984:	79 09 00 71	subs	w25, w11, #0x2
101170988:	8b 04 00 54	b.lt	0x101170a18
10117098c:	1a 00 80 52	mov	w26, #0x0
101170990:	60 01 62 1e	scvtf	d0, w11
101170994:	ff bf 03 b9	str	wzr, [sp, #0x3bc]
101170998:	0b 00 80 12	mov	w11, #-0x1
10117099c:	eb cb 03 b9	str	w11, [sp, #0x3c8]
1011709a0:	ff 33 0f 39	strb	wzr, [sp, #0x3cc]
1011709a4:	a8 19 60 1e	fdiv	d8, d13, d0
1011709a8:	5b 61 00 91	add	x27, x10, #0x18
1011709ac:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
1011709b0:	4a 07 00 11	add	w10, w26, #0x1
1011709b4:	40 01 62 1e	scvtf	d0, w10
1011709b8:	60 09 60 1e	fmul	d0, d11, d0
1011709bc:	00 28 48 1f	fmadd	d0, d0, d8, d10
1011709c0:	21 01 62 1e	scvtf	d1, w9
1011709c4:	00 38 41 1f	fmadd	d0, d0, d1, d14
1011709c8:	09 00 78 1e	fcvtzs	w9, d0
1011709cc:	e9 bb 03 b9	str	w9, [sp, #0x3b8]
1011709d0:	ff e3 01 f9	str	xzr, [sp, #0x3c0]
1011709d4:	61 03 08 8b	add	x1, x27, x8
1011709d8:	e2 e3 0e 91	add	x2, sp, #0x3b8
1011709dc:	0f 3a ff 97	bl	__ZNSt3__16vectorIN16BeatAnalyzer_2_06peakss8BeatInfoENS_9allocatorIS3_EEE6insertENS_11__wrap_iterIPKS3_EERS8_
1011709e0:	d7 02 1a 0b	add	w23, w22, w26
1011709e4:	e8 af 40 f9	ldr	x8, [sp, #0x158]
1011709e8:	97 7b 28 b8	str	w23, [x28, x8, lsl #2]
1011709ec:	3f 03 1a 6b	cmp	w25, w26
1011709f0:	00 01 00 54	b.eq	0x101170a10
1011709f4:	e8 9f 40 f9	ldr	x8, [sp, #0x138]
1011709f8:	09 01 40 b9	ldr	w9, [x8]
1011709fc:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
101170a00:	08 00 40 f9	ldr	x8, [x0]
101170a04:	7b 63 00 91	add	x27, x27, #0x18
101170a08:	5a 07 00 11	add	w26, w26, #0x1
101170a0c:	e9 ff ff 17	b	0x1011709b0
101170a10:	fb 9f 40 f9	ldr	x27, [sp, #0x138]
101170a14:	15 03 80 52	mov	w21, #0x18
101170a18:	14 08 00 34	cbz	w20, 0x101170b18
101170a1c:	6a 06 00 91	add	x10, x19, #0x1
101170a20:	5f 01 18 6b	cmp	w10, w24
101170a24:	f9 9b 40 f9	ldr	x25, [sp, #0x130]
101170a28:	f6 07 40 91	add	x22, sp, #0x1, lsl #12
101170a2c:	d6 c2 19 91	add	x22, x22, #0x670
101170a30:	aa 07 00 54	b.ge	0x101170b24
101170a34:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
101170a38:	08 01 40 f9	ldr	x8, [x8]
101170a3c:	69 7e 15 9b	mul	x9, x19, x21
101170a40:	00 69 69 bc	ldr	s0, [x8, x9]
101170a44:	00 a4 20 0f	sshll.2d	v0, v0, #0x0
101170a48:	00 d8 61 5e	scvtf	d0, d0
101170a4c:	69 03 40 b9	ldr	w9, [x27]
101170a50:	21 01 62 1e	scvtf	d1, w9
101170a54:	0a 18 61 1e	fdiv	d10, d0, d1
101170a58:	4a 7d 15 9b	mul	x10, x10, x21
101170a5c:	00 69 6a bc	ldr	s0, [x8, x10]
101170a60:	00 a4 20 0f	sshll.2d	v0, v0, #0x0
101170a64:	00 d8 61 5e	scvtf	d0, d0
101170a68:	00 18 61 1e	fdiv	d0, d0, d1
101170a6c:	0b 38 6a 1e	fsub	d11, d0, d10
101170a70:	0a 00 c8 d2	mov	x10, #0x400000000000
101170a74:	ea 11 e8 f2	movk	x10, #0x408f, lsl #48
101170a78:	40 01 67 9e	fmov	d0, x10
101170a7c:	60 09 60 1e	fmul	d0, d11, d0
101170a80:	00 38 4c 1f	fmadd	d0, d0, d12, d14
101170a84:	0a 00 78 1e	fcvtzs	w10, d0
101170a88:	5f 09 00 71	cmp	w10, #0x2
101170a8c:	cb 04 00 54	b.lt	0x101170b24
101170a90:	40 01 62 1e	scvtf	d0, w10
101170a94:	ff bf 03 b9	str	wzr, [sp, #0x3bc]
101170a98:	0b 00 80 12	mov	w11, #-0x1
101170a9c:	eb cb 03 b9	str	w11, [sp, #0x3c8]
101170aa0:	ff 33 0f 39	strb	wzr, [sp, #0x3cc]
101170aa4:	54 05 00 51	sub	w20, w10, #0x1
101170aa8:	a8 19 60 1e	fdiv	d8, d13, d0
101170aac:	f6 03 17 2a	mov	w22, w23
101170ab0:	ea 07 7d b2	orr	x10, xzr, #0x18
101170ab4:	73 2a 15 9b	madd	x19, x19, x21, x10
101170ab8:	38 00 80 52	mov	w24, #0x1
101170abc:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
101170ac0:	00 03 62 1e	scvtf	d0, w24
101170ac4:	60 09 60 1e	fmul	d0, d11, d0
101170ac8:	00 28 48 1f	fmadd	d0, d0, d8, d10
101170acc:	21 01 62 1e	scvtf	d1, w9
101170ad0:	00 38 41 1f	fmadd	d0, d0, d1, d14
101170ad4:	09 00 78 1e	fcvtzs	w9, d0
101170ad8:	e9 bb 03 b9	str	w9, [sp, #0x3b8]
101170adc:	ff e3 01 f9	str	xzr, [sp, #0x3c0]
101170ae0:	61 02 08 8b	add	x1, x19, x8
101170ae4:	e2 e3 0e 91	add	x2, sp, #0x3b8
101170ae8:	cc 39 ff 97	bl	__ZNSt3__16vectorIN16BeatAnalyzer_2_06peakss8BeatInfoENS_9allocatorIS3_EEE6insertENS_11__wrap_iterIPKS3_EERS8_
101170aec:	c8 02 18 0b	add	w8, w22, w24
101170af0:	e9 af 40 f9	ldr	x9, [sp, #0x158]
101170af4:	88 7b 29 b8	str	w8, [x28, x9, lsl #2]
101170af8:	9f 02 18 eb	cmp	x20, x24
101170afc:	a0 14 00 54	b.eq	0x101170d90
101170b00:	69 03 40 b9	ldr	w9, [x27]
101170b04:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
101170b08:	08 00 40 f9	ldr	x8, [x0]
101170b0c:	18 07 00 91	add	x24, x24, #0x1
101170b10:	73 62 00 91	add	x19, x19, #0x18
101170b14:	eb ff ff 17	b	0x101170ac0
101170b18:	f9 9b 40 f9	ldr	x25, [sp, #0x130]
101170b1c:	f6 07 40 91	add	x22, sp, #0x1, lsl #12
101170b20:	d6 c2 19 91	add	x22, x22, #0x670
101170b24:	f8 87 40 f9	ldr	x24, [sp, #0x108]
101170b28:	f3 b3 40 f9	ldr	x19, [sp, #0x160]
101170b2c:	61 02 40 f9	ldr	x1, [x19]
101170b30:	28 18 40 b9	ldr	w8, [x1, #0x18]
101170b34:	29 00 40 b9	ldr	w9, [x1]
101170b38:	08 01 09 4b	sub	w8, w8, w9
101170b3c:	28 01 08 6b	subs	w8, w9, w8
101170b40:	4d 01 00 54	b.le	0x101170b68
101170b44:	e8 d3 03 b9	str	w8, [sp, #0x3d0]
101170b48:	ff ef 01 f9	str	xzr, [sp, #0x3d8]
101170b4c:	e2 43 0f 91	add	x2, sp, #0x3d0
101170b50:	e0 03 13 aa	mov	x0, x19
101170b54:	b1 39 ff 97	bl	__ZNSt3__16vectorIN16BeatAnalyzer_2_06peakss8BeatInfoENS_9allocatorIS3_EEE6insertENS_11__wrap_iterIPKS3_EERS8_
101170b58:	e8 06 00 11	add	w8, w23, #0x1
101170b5c:	e9 af 40 f9	ldr	x9, [sp, #0x158]
101170b60:	88 7b 29 b8	str	w8, [x28, x9, lsl #2]
101170b64:	61 02 40 f9	ldr	x1, [x19]
101170b68:	e9 f3 01 b2	mov	x9, #-0x5555555555555556
101170b6c:	69 55 95 f2	movk	x9, #0xaaab
101170b70:	28 03 40 f9	ldr	x8, [x25]
101170b74:	08 01 01 cb	sub	x8, x8, x1
101170b78:	08 fd 43 93	asr	x8, x8, #3
101170b7c:	13 7d 09 9b	mul	x19, x8, x9
101170b80:	7f 0a 00 71	cmp	w19, #0x2
101170b84:	f7 07 40 91	add	x23, sp, #0x1, lsl #12
101170b88:	f7 c2 11 91	add	x23, x23, #0x470
101170b8c:	fc 97 40 f9	ldr	x28, [sp, #0x128]
101170b90:	ab 06 00 54	b.lt	0x101170c64
101170b94:	68 06 00 51	sub	w8, w19, #0x1
101170b98:	09 7d b5 9b	umull	x9, w8, w21
101170b9c:	2a 68 69 b8	ldr	w10, [x1, x9]
101170ba0:	69 7e 60 d3	lsl	x9, x19, #32
101170ba4:	eb 7b 5f b2	mov	x11, #-0x200000000
101170ba8:	2b 01 0b 8b	add	x11, x9, x11
101170bac:	6b fd 60 93	asr	x11, x11, #32
101170bb0:	6b 7d 15 9b	mul	x11, x11, x21
101170bb4:	2b 68 6b b8	ldr	w11, [x1, x11]
101170bb8:	54 01 0b 6b	subs	w20, w10, w11
101170bbc:	40 05 00 54	b.eq	0x101170c64
101170bc0:	8b 1f 40 b9	ldr	w11, [x28, #0x1c]
101170bc4:	6a 01 0a 4b	sub	w10, w11, w10
101170bc8:	40 01 62 1e	scvtf	d0, w10
101170bcc:	81 02 62 1e	scvtf	d1, w20
101170bd0:	00 18 61 1e	fdiv	d0, d0, d1
101170bd4:	00 20 6d 1e	fcmp	d0, d13
101170bd8:	6d 04 00 54	b.le	0x101170c64
101170bdc:	0a 00 78 1e	fcvtzs	w10, d0
101170be0:	ff e3 01 f9	str	xzr, [sp, #0x3c0]
101170be4:	ff df 01 f9	str	xzr, [sp, #0x3b8]
101170be8:	0b 00 80 12	mov	w11, #-0x1
101170bec:	eb cb 03 b9	str	w11, [sp, #0x3c8]
101170bf0:	ff 33 0f 39	strb	wzr, [sp, #0x3cc]
101170bf4:	5f 05 00 71	cmp	w10, #0x1
101170bf8:	cb 02 00 54	b.lt	0x101170c50
101170bfc:	29 fd 60 93	asr	x9, x9, #32
101170c00:	08 05 08 8b	add	x8, x8, x8, lsl #1
101170c04:	16 f1 7d d3	lsl	x22, x8, #3
101170c08:	28 05 09 8b	add	x8, x9, x9, lsl #1
101170c0c:	17 f1 7d d3	lsl	x23, x8, #3
101170c10:	58 05 00 d1	sub	x24, x10, #0x1
101170c14:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
101170c18:	28 68 76 b8	ldr	w8, [x1, x22]
101170c1c:	08 01 14 0b	add	w8, w8, w20
101170c20:	e8 bb 03 b9	str	w8, [sp, #0x3b8]
101170c24:	ff e3 01 f9	str	xzr, [sp, #0x3c0]
101170c28:	e1 02 01 8b	add	x1, x23, x1
101170c2c:	e2 e3 0e 91	add	x2, sp, #0x3b8
101170c30:	7a 39 ff 97	bl	__ZNSt3__16vectorIN16BeatAnalyzer_2_06peakss8BeatInfoENS_9allocatorIS3_EEE6insertENS_11__wrap_iterIPKS3_EERS8_
101170c34:	f8 00 00 b4	cbz	x24, 0x101170c50
101170c38:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
101170c3c:	01 00 40 f9	ldr	x1, [x0]
101170c40:	d6 62 00 91	add	x22, x22, #0x18
101170c44:	f7 62 00 91	add	x23, x23, #0x18
101170c48:	18 07 00 d1	sub	x24, x24, #0x1
101170c4c:	f3 ff ff 17	b	0x101170c18
101170c50:	f7 07 40 91	add	x23, sp, #0x1, lsl #12
101170c54:	f7 c2 11 91	add	x23, x23, #0x470
101170c58:	f6 07 40 91	add	x22, sp, #0x1, lsl #12
101170c5c:	d6 c2 19 91	add	x22, x22, #0x670
101170c60:	f8 87 40 f9	ldr	x24, [sp, #0x108]
101170c64:	e8 c3 40 b9	ldr	w8, [sp, #0xc0]
101170c68:	48 b1 03 34	cbz	w8, 0x101178290
101170c6c:	29 03 40 f9	ldr	x9, [x25]
101170c70:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
101170c74:	08 01 40 f9	ldr	x8, [x8]
101170c78:	29 01 08 cb	sub	x9, x9, x8
101170c7c:	29 fd 43 d3	lsr	x9, x9, #3
101170c80:	6a 55 95 52	mov	w10, #0xaaab
101170c84:	4a 55 b5 72	movk	w10, #0xaaaa, lsl #16
101170c88:	33 7d 0a 1b	mul	w19, w9, w10
101170c8c:	69 0a 00 51	sub	w9, w19, #0x2
101170c90:	3f 05 00 71	cmp	w9, #0x1
101170c94:	2a c5 9f 1a	csinc	w10, w9, wzr, gt
101170c98:	0f 06 80 52	mov	w15, #0x30
101170c9c:	2b 00 80 52	mov	w11, #0x1
101170ca0:	7f 01 0a eb	cmp	x11, x10
101170ca4:	60 af 03 54	b.eq	0x101178290
101170ca8:	e9 03 0b aa	mov	x9, x11
101170cac:	f4 03 0f aa	mov	x20, x15
101170cb0:	6b 21 15 9b	madd	x11, x11, x21, x8
101170cb4:	70 01 40 b9	ldr	w16, [x11]
101170cb8:	6d 81 5e b8	ldur	w13, [x11, #-0x18]
101170cbc:	2b 05 00 91	add	x11, x9, #0x1
101170cc0:	6c 7d 40 92	and	x12, x11, #0xffffffff
101170cc4:	8c 7d 15 9b	mul	x12, x12, x21
101170cc8:	0c 69 6c b8	ldr	w12, [x8, x12]
101170ccc:	0f 02 0d 4b	sub	w15, w16, w13
101170cd0:	2d 09 00 11	add	w13, w9, #0x2
101170cd4:	ad 7d b5 9b	umull	x13, w13, w21
101170cd8:	0e 69 6d b8	ldr	w14, [x8, x13]
101170cdc:	cd 01 0c 4b	sub	w13, w14, w12
101170ce0:	f1 09 0f 0b	add	w17, w15, w15, lsl #2
101170ce4:	a0 09 0d 0b	add	w0, w13, w13, lsl #2
101170ce8:	8f 62 00 91	add	x15, x20, #0x18
101170cec:	90 01 10 4b	sub	w16, w12, w16
101170cf0:	1f 02 11 6b	cmp	w16, w17
101170cf4:	00 d2 40 7a	ccmp	w16, w0, #0x0, le
101170cf8:	4d fd ff 54	b.le	0x101170ca0
101170cfc:	df 01 0c 6b	cmp	w14, w12
101170d00:	80 ac 03 54	b.eq	0x101178290
101170d04:	00 02 62 1e	scvtf	d0, w16
101170d08:	a1 01 62 1e	scvtf	d1, w13
101170d0c:	01 18 61 1e	fdiv	d1, d0, d1
101170d10:	20 20 6d 1e	fcmp	d1, d13
101170d14:	ed ab 03 54	b.le	0x101178290
101170d18:	2a 00 78 1e	fcvtzs	w10, d1
101170d1c:	ff e3 01 f9	str	xzr, [sp, #0x3c0]
101170d20:	ff df 01 f9	str	xzr, [sp, #0x3b8]
101170d24:	0b 00 80 12	mov	w11, #-0x1
101170d28:	eb cb 03 b9	str	w11, [sp, #0x3c8]
101170d2c:	ff 33 0f 39	strb	wzr, [sp, #0x3cc]
101170d30:	5f 09 00 71	cmp	w10, #0x2
101170d34:	2b aa 03 54	b.lt	0x101178278
101170d38:	21 c0 65 1e	frintz	d1, d1
101170d3c:	00 18 61 1e	fdiv	d0, d0, d1
101170d40:	16 00 78 1e	fcvtzs	w22, d0
101170d44:	37 7d 40 92	and	x23, x9, #0xffffffff
101170d48:	58 09 00 d1	sub	x24, x10, #0x2
101170d4c:	f9 03 16 aa	mov	x25, x22
101170d50:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
101170d54:	e9 7e 15 9b	mul	x9, x23, x21
101170d58:	09 69 69 b8	ldr	w9, [x8, x9]
101170d5c:	29 03 09 0b	add	w9, w25, w9
101170d60:	e9 bb 03 b9	str	w9, [sp, #0x3b8]
101170d64:	ff e3 01 f9	str	xzr, [sp, #0x3c0]
101170d68:	81 02 08 8b	add	x1, x20, x8
101170d6c:	e2 e3 0e 91	add	x2, sp, #0x3b8
101170d70:	2a 39 ff 97	bl	__ZNSt3__16vectorIN16BeatAnalyzer_2_06peakss8BeatInfoENS_9allocatorIS3_EEE6insertENS_11__wrap_iterIPKS3_EERS8_
101170d74:	38 a8 03 b4	cbz	x24, 0x101178278
101170d78:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
101170d7c:	08 00 40 f9	ldr	x8, [x0]
101170d80:	39 03 16 0b	add	w25, w25, w22
101170d84:	94 62 00 91	add	x20, x20, #0x18
101170d88:	18 07 00 d1	sub	x24, x24, #0x1
101170d8c:	f2 ff ff 17	b	0x101170d54
101170d90:	f7 02 18 0b	add	w23, w23, w24
101170d94:	62 ff ff 17	b	0x101170b1c
101170d98:	49 13 00 71	subs	w9, w26, #0x4
101170d9c:	63 04 00 54	b.lo	0x101170e28
101170da0:	80 5a 69 fc	ldr	d0, [x20, w9, uxtw #3]
101170da4:	c1 01 67 9e	fmov	d1, x14
101170da8:	00 20 61 1e	fcmp	d0, d1
101170dac:	ea a3 90 d2	mov	x10, #0x851f
101170db0:	6a 3d aa f2	movk	x10, #0x51eb, lsl #16
101170db4:	0a d7 c3 f2	movk	x10, #0x1eb8, lsl #32
101170db8:	2a fe e7 f2	movk	x10, #0x3ff1, lsl #48
101170dbc:	41 01 67 9e	fmov	d1, x10
101170dc0:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
101170dc4:	8c 00 00 54	b.gt	0x101170dd4
101170dc8:	e1 01 67 9e	fmov	d1, x15
101170dcc:	00 20 61 1e	fcmp	d0, d1
101170dd0:	ed 02 00 54	b.le	0x101170e2c
101170dd4:	4a 17 00 71	subs	w10, w26, #0x5
101170dd8:	83 02 00 54	b.lo	0x101170e28
101170ddc:	80 5a 6a fc	ldr	d0, [x20, w10, uxtw #3]
101170de0:	eb a3 90 d2	mov	x11, #0x851f
101170de4:	6b 3d aa f2	movk	x11, #0x51eb, lsl #16
101170de8:	0b d7 c3 f2	movk	x11, #0x1eb8, lsl #32
101170dec:	2b fe e7 f2	movk	x11, #0x3ff1, lsl #48
101170df0:	61 01 67 9e	fmov	d1, x11
101170df4:	00 20 61 1e	fcmp	d0, d1
101170df8:	eb d7 9f 1a	cset	w11, gt
101170dfc:	c1 01 67 9e	fmov	d1, x14
101170e00:	00 20 61 1e	fcmp	d0, d1
101170e04:	ec a7 9f 1a	cset	w12, lt
101170e08:	6b 01 0c 0a	and	w11, w11, w12
101170e0c:	e1 01 67 9e	fmov	d1, x15
101170e10:	00 20 61 1e	fcmp	d0, d1
101170e14:	ec d7 9f 1a	cset	w12, gt
101170e18:	71 01 0c 2a	orr	w17, w11, w12
101170e1c:	3f 02 00 71	cmp	w17, #0x0
101170e20:	56 11 89 1a	csel	w22, w10, w9, ne
101170e24:	03 00 00 14	b	0x101170e30
101170e28:	16 00 80 52	mov	w22, #0x0
101170e2c:	11 00 80 52	mov	w17, #0x0
101170e30:	09 0a 00 51	sub	w9, w16, #0x2
101170e34:	5f 03 09 6b	cmp	w26, w9
101170e38:	0c 04 00 54	b.gt	0x101170eb8
101170e3c:	80 da 60 fc	ldr	d0, [x20, w0, sxtw #3]
101170e40:	c1 01 67 9e	fmov	d1, x14
101170e44:	00 20 61 1e	fcmp	d0, d1
101170e48:	ea a3 90 d2	mov	x10, #0x851f
101170e4c:	6a 3d aa f2	movk	x10, #0x51eb, lsl #16
101170e50:	0a d7 c3 f2	movk	x10, #0x1eb8, lsl #32
101170e54:	2a fe e7 f2	movk	x10, #0x3ff1, lsl #48
101170e58:	41 01 67 9e	fmov	d1, x10
101170e5c:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
101170e60:	8c 00 00 54	b.gt	0x101170e70
101170e64:	e1 01 67 9e	fmov	d1, x15
101170e68:	00 20 61 1e	fcmp	d0, d1
101170e6c:	6d 02 00 54	b.le	0x101170eb8
101170e70:	0a 0e 00 51	sub	w10, w16, #0x3
101170e74:	5f 03 0a 6b	cmp	w26, w10
101170e78:	ec 01 00 54	b.gt	0x101170eb4
101170e7c:	ea 83 40 f9	ldr	x10, [sp, #0x100]
101170e80:	80 da 6a fc	ldr	d0, [x20, w10, sxtw #3]
101170e84:	c1 01 67 9e	fmov	d1, x14
101170e88:	00 20 61 1e	fcmp	d0, d1
101170e8c:	ea a3 90 d2	mov	x10, #0x851f
101170e90:	6a 3d aa f2	movk	x10, #0x51eb, lsl #16
101170e94:	0a d7 c3 f2	movk	x10, #0x1eb8, lsl #32
101170e98:	2a fe e7 f2	movk	x10, #0x3ff1, lsl #48
101170e9c:	41 01 67 9e	fmov	d1, x10
101170ea0:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
101170ea4:	6c 3a 00 54	b.gt	0x1011715f0
101170ea8:	e1 01 67 9e	fmov	d1, x15
101170eac:	00 20 61 1e	fcmp	d0, d1
101170eb0:	0c 3a 00 54	b.gt	0x1011715f0
101170eb4:	fa 03 00 aa	mov	x26, x0
101170eb8:	0b 05 00 71	subs	w11, w8, #0x1
101170ebc:	eb 01 00 54	b.lt	0x101170ef8
101170ec0:	80 5a 6b fc	ldr	d0, [x20, w11, uxtw #3]
101170ec4:	ea a3 90 d2	mov	x10, #0x851f
101170ec8:	6a 3d aa f2	movk	x10, #0x51eb, lsl #16
101170ecc:	0a d7 c3 f2	movk	x10, #0x1eb8, lsl #32
101170ed0:	2a fe e7 f2	movk	x10, #0x3ff1, lsl #48
101170ed4:	41 01 67 9e	fmov	d1, x10
101170ed8:	00 20 61 1e	fcmp	d0, d1
101170edc:	2d 01 00 54	b.le	0x101170f00
101170ee0:	c1 01 67 9e	fmov	d1, x14
101170ee4:	00 20 61 1e	fcmp	d0, d1
101170ee8:	ca 00 00 54	b.ge	0x101170f00
101170eec:	1f 09 00 71	cmp	w8, #0x2
101170ef0:	4a 01 00 54	b.ge	0x101170f18
101170ef4:	4d 00 00 14	b	0x101171028
101170ef8:	ea 03 08 aa	mov	x10, x8
101170efc:	4c 00 00 14	b	0x10117102c
101170f00:	e1 01 67 9e	fmov	d1, x15
101170f04:	00 20 61 1e	fcmp	d0, d1
101170f08:	0a d1 9f 1a	csel	w10, w8, wzr, le
101170f0c:	0d 09 00 54	b.le	0x10117102c
101170f10:	1f 09 00 71	cmp	w8, #0x2
101170f14:	cb 08 00 54	b.lt	0x10117102c
101170f18:	0a 09 00 51	sub	w10, w8, #0x2
101170f1c:	80 5a 6a fc	ldr	d0, [x20, w10, uxtw #3]
101170f20:	c1 01 67 9e	fmov	d1, x14
101170f24:	00 20 61 1e	fcmp	d0, d1
101170f28:	ec a3 90 d2	mov	x12, #0x851f
101170f2c:	6c 3d aa f2	movk	x12, #0x51eb, lsl #16
101170f30:	0c d7 c3 f2	movk	x12, #0x1eb8, lsl #32
101170f34:	2c fe e7 f2	movk	x12, #0x3ff1, lsl #48
101170f38:	81 01 67 9e	fmov	d1, x12
101170f3c:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
101170f40:	cc 00 00 54	b.gt	0x101170f58
101170f44:	e1 01 67 9e	fmov	d1, x15
101170f48:	00 20 61 1e	fcmp	d0, d1
101170f4c:	6c 00 00 54	b.gt	0x101170f58
101170f50:	ea 03 0b aa	mov	x10, x11
101170f54:	36 00 00 14	b	0x10117102c
101170f58:	0b 0d 00 71	subs	w11, w8, #0x3
101170f5c:	63 06 00 54	b.lo	0x101171028
101170f60:	80 5a 6b fc	ldr	d0, [x20, w11, uxtw #3]
101170f64:	c1 01 67 9e	fmov	d1, x14
101170f68:	00 20 61 1e	fcmp	d0, d1
101170f6c:	ec a3 90 d2	mov	x12, #0x851f
101170f70:	6c 3d aa f2	movk	x12, #0x51eb, lsl #16
101170f74:	0c d7 c3 f2	movk	x12, #0x1eb8, lsl #32
101170f78:	2c fe e7 f2	movk	x12, #0x3ff1, lsl #48
101170f7c:	81 01 67 9e	fmov	d1, x12
101170f80:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
101170f84:	8c 00 00 54	b.gt	0x101170f94
101170f88:	e1 01 67 9e	fmov	d1, x15
101170f8c:	00 20 61 1e	fcmp	d0, d1
101170f90:	ed 04 00 54	b.le	0x10117102c
101170f94:	0a 11 00 71	subs	w10, w8, #0x4
101170f98:	83 04 00 54	b.lo	0x101171028
101170f9c:	80 5a 6a fc	ldr	d0, [x20, w10, uxtw #3]
101170fa0:	c1 01 67 9e	fmov	d1, x14
101170fa4:	00 20 61 1e	fcmp	d0, d1
101170fa8:	ec a3 90 d2	mov	x12, #0x851f
101170fac:	6c 3d aa f2	movk	x12, #0x51eb, lsl #16
101170fb0:	0c d7 c3 f2	movk	x12, #0x1eb8, lsl #32
101170fb4:	2c fe e7 f2	movk	x12, #0x3ff1, lsl #48
101170fb8:	81 01 67 9e	fmov	d1, x12
101170fbc:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
101170fc0:	8c 00 00 54	b.gt	0x101170fd0
101170fc4:	e1 01 67 9e	fmov	d1, x15
101170fc8:	00 20 61 1e	fcmp	d0, d1
101170fcc:	2d fc ff 54	b.le	0x101170f50
101170fd0:	0b 15 00 71	subs	w11, w8, #0x5
101170fd4:	a3 02 00 54	b.lo	0x101171028
101170fd8:	80 5a 6b fc	ldr	d0, [x20, w11, uxtw #3]
101170fdc:	ec a3 90 d2	mov	x12, #0x851f
101170fe0:	6c 3d aa f2	movk	x12, #0x51eb, lsl #16
101170fe4:	0c d7 c3 f2	movk	x12, #0x1eb8, lsl #32
101170fe8:	2c fe e7 f2	movk	x12, #0x3ff1, lsl #48
101170fec:	81 01 67 9e	fmov	d1, x12
101170ff0:	00 20 61 1e	fcmp	d0, d1
101170ff4:	ec d7 9f 1a	cset	w12, gt
101170ff8:	c1 01 67 9e	fmov	d1, x14
101170ffc:	00 20 61 1e	fcmp	d0, d1
101171000:	ed a7 9f 1a	cset	w13, lt
101171004:	8c 01 0d 0a	and	w12, w12, w13
101171008:	e1 01 67 9e	fmov	d1, x15
10117100c:	00 20 61 1e	fcmp	d0, d1
101171010:	ed d7 9f 1a	cset	w13, gt
101171014:	8c 01 0d 2a	orr	w12, w12, w13
101171018:	9f 01 00 71	cmp	w12, #0x0
10117101c:	6a 11 8a 1a	csel	w10, w11, w10, ne
101171020:	91 01 11 2a	orr	w17, w12, w17
101171024:	02 00 00 14	b	0x10117102c
101171028:	0a 00 80 52	mov	w10, #0x0
10117102c:	1f 01 09 6b	cmp	w8, w9
101171030:	2c 04 00 54	b.gt	0x1011710b4
101171034:	09 05 00 11	add	w9, w8, #0x1
101171038:	80 da 69 fc	ldr	d0, [x20, w9, sxtw #3]
10117103c:	c1 01 67 9e	fmov	d1, x14
101171040:	00 20 61 1e	fcmp	d0, d1
101171044:	eb a3 90 d2	mov	x11, #0x851f
101171048:	6b 3d aa f2	movk	x11, #0x51eb, lsl #16
10117104c:	0b d7 c3 f2	movk	x11, #0x1eb8, lsl #32
101171050:	2b fe e7 f2	movk	x11, #0x3ff1, lsl #48
101171054:	61 01 67 9e	fmov	d1, x11
101171058:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
10117105c:	8c 00 00 54	b.gt	0x10117106c
101171060:	e1 01 67 9e	fmov	d1, x15
101171064:	00 20 61 1e	fcmp	d0, d1
101171068:	6d 02 00 54	b.le	0x1011710b4
10117106c:	0b 0e 00 51	sub	w11, w16, #0x3
101171070:	1f 01 0b 6b	cmp	w8, w11
101171074:	ec 01 00 54	b.gt	0x1011710b0
101171078:	0b 09 00 11	add	w11, w8, #0x2
10117107c:	80 da 6b fc	ldr	d0, [x20, w11, sxtw #3]
101171080:	c1 01 67 9e	fmov	d1, x14
101171084:	00 20 61 1e	fcmp	d0, d1
101171088:	ec a3 90 d2	mov	x12, #0x851f
10117108c:	6c 3d aa f2	movk	x12, #0x51eb, lsl #16
101171090:	0c d7 c3 f2	movk	x12, #0x1eb8, lsl #32
101171094:	2c fe e7 f2	movk	x12, #0x3ff1, lsl #48
101171098:	81 01 67 9e	fmov	d1, x12
10117109c:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
1011710a0:	ec 2c 00 54	b.gt	0x10117163c
1011710a4:	e1 01 67 9e	fmov	d1, x15
1011710a8:	00 20 61 1e	fcmp	d0, d1
1011710ac:	8c 2c 00 54	b.gt	0x10117163c
1011710b0:	e8 03 09 aa	mov	x8, x9
1011710b4:	f1 c3 00 b9	str	w17, [sp, #0xc0]
1011710b8:	5f 01 00 71	cmp	w10, #0x0
1011710bc:	58 c1 9f 1a	csel	w24, w10, wzr, gt
1011710c0:	37 03 40 f9	ldr	x23, [x25]
1011710c4:	e9 b3 40 f9	ldr	x9, [sp, #0x160]
1011710c8:	29 01 40 f9	ldr	x9, [x9]
1011710cc:	ea 02 09 cb	sub	x10, x23, x9
1011710d0:	4a fd 43 93	asr	x10, x10, #3
1011710d4:	eb f3 01 b2	mov	x11, #-0x5555555555555556
1011710d8:	6b 55 95 f2	movk	x11, #0xaaab
1011710dc:	4a 7d 0b 9b	mul	x10, x10, x11
1011710e0:	4b 05 00 d1	sub	x11, x10, #0x1
1011710e4:	4c 05 00 51	sub	w12, w10, #0x1
1011710e8:	7f c1 28 eb	cmp	x11, w8, sxtw
1011710ec:	94 31 88 1a	csel	w20, w12, w8, lo
1011710f0:	9f 02 18 6b	cmp	w20, w24
1011710f4:	f4 6b 00 f9	str	x20, [sp, #0xd0]
1011710f8:	2d 04 00 54	b.le	0x10117117c
1011710fc:	93 7e 40 93	sxtw	x19, w20
101171100:	15 03 80 52	mov	w21, #0x18
101171104:	80 26 35 9b	smaddl	x0, w20, w21, x9
101171108:	01 60 00 91	add	x1, x0, #0x18
10117110c:	e2 02 01 cb	sub	x2, x23, x1
101171110:	4f 85 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
101171114:	f7 62 00 d1	sub	x23, x23, #0x18
101171118:	37 03 00 f9	str	x23, [x25]
10117111c:	73 06 00 d1	sub	x19, x19, #0x1
101171120:	7f 02 18 eb	cmp	x19, x24
101171124:	f4 b3 40 f9	ldr	x20, [sp, #0x160]
101171128:	6d 01 00 54	b.le	0x101171154
10117112c:	88 02 40 f9	ldr	x8, [x20]
101171130:	60 22 15 9b	madd	x0, x19, x21, x8
101171134:	01 60 00 91	add	x1, x0, #0x18
101171138:	e2 02 01 cb	sub	x2, x23, x1
10117113c:	44 85 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
101171140:	f7 62 00 d1	sub	x23, x23, #0x18
101171144:	37 03 00 f9	str	x23, [x25]
101171148:	73 06 00 d1	sub	x19, x19, #0x1
10117114c:	7f 02 18 eb	cmp	x19, x24
101171150:	ec fe ff 54	b.gt	0x10117112c
101171154:	89 02 40 f9	ldr	x9, [x20]
101171158:	e8 02 09 cb	sub	x8, x23, x9
10117115c:	08 fd 43 93	asr	x8, x8, #3
101171160:	ea f3 01 b2	mov	x10, #-0x5555555555555556
101171164:	6a 55 95 f2	movk	x10, #0xaaab
101171168:	0a 7d 0a 9b	mul	x10, x8, x10
10117116c:	4b 05 00 d1	sub	x11, x10, #0x1
101171170:	4c 05 00 51	sub	w12, w10, #0x1
101171174:	f4 03 18 aa	mov	x20, x24
101171178:	01 00 00 14	b	0x10117117c
10117117c:	f3 a3 40 f9	ldr	x19, [sp, #0x140]
101171180:	74 02 00 b9	str	w20, [x19]
101171184:	df 02 00 71	cmp	w22, #0x0
101171188:	cf c2 9f 1a	csel	w15, w22, wzr, gt
10117118c:	7f c1 3a eb	cmp	x11, w26, sxtw
101171190:	88 31 9a 1a	csel	w8, w12, w26, lo
101171194:	1f 01 0f 6b	cmp	w8, w15
101171198:	ef 93 00 f9	str	x15, [sp, #0x120]
10117119c:	f8 83 00 f9	str	x24, [sp, #0x100]
1011711a0:	e8 67 00 f9	str	x8, [sp, #0xc8]
1011711a4:	6d 07 00 54	b.le	0x101171290
1011711a8:	15 7d 40 93	sxtw	x21, w8
1011711ac:	1a 03 80 52	mov	w26, #0x18
1011711b0:	00 25 3a 9b	smaddl	x0, w8, w26, x9
1011711b4:	01 60 00 91	add	x1, x0, #0x18
1011711b8:	e2 02 01 cb	sub	x2, x23, x1
1011711bc:	24 85 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
1011711c0:	ef 93 40 f9	ldr	x15, [sp, #0x120]
1011711c4:	f7 62 00 d1	sub	x23, x23, #0x18
1011711c8:	37 03 00 f9	str	x23, [x25]
1011711cc:	68 02 40 b9	ldr	w8, [x19]
1011711d0:	14 05 00 51	sub	w20, w8, #0x1
1011711d4:	74 02 00 b9	str	w20, [x19]
1011711d8:	b3 06 00 d1	sub	x19, x21, #0x1
1011711dc:	7f 02 0f eb	cmp	x19, x15
1011711e0:	8d 06 00 54	b.le	0x1011712b0
1011711e4:	a8 06 15 8b	add	x8, x21, x21, lsl #1
1011711e8:	1a f1 7d d3	lsl	x26, x8, #3
1011711ec:	e8 02 80 92	mov	x8, #-0x18
1011711f0:	b8 7e 08 9b	mul	x24, x21, x8
1011711f4:	f5 b3 40 f9	ldr	x21, [sp, #0x160]
1011711f8:	f6 03 19 aa	mov	x22, x25
1011711fc:	fc f3 01 b2	mov	x28, #-0x5555555555555556
101171200:	7c 55 95 f2	movk	x28, #0xaaab
101171204:	5c 55 e5 f2	movk	x28, #0x2aaa, lsl #48
101171208:	b9 02 40 f9	ldr	x25, [x21]
10117120c:	e8 02 19 cb	sub	x8, x23, x25
101171210:	02 03 08 8b	add	x2, x24, x8
101171214:	48 7c 5c 9b	smulh	x8, x2, x28
101171218:	09 fd 42 93	asr	x9, x8, #2
10117121c:	3b fd 48 8b	add	x27, x9, x8, lsr #63
101171220:	21 03 1a 8b	add	x1, x25, x26
101171224:	20 60 00 d1	sub	x0, x1, #0x18
101171228:	09 85 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
10117122c:	ef 93 40 f9	ldr	x15, [sp, #0x120]
101171230:	08 03 80 52	mov	w8, #0x18
101171234:	68 6b 08 9b	madd	x8, x27, x8, x26
101171238:	28 03 08 8b	add	x8, x25, x8
10117123c:	17 61 00 d1	sub	x23, x8, #0x18
101171240:	d7 02 00 f9	str	x23, [x22]
101171244:	94 06 00 51	sub	w20, w20, #0x1
101171248:	73 06 00 d1	sub	x19, x19, #0x1
10117124c:	5a 63 00 d1	sub	x26, x26, #0x18
101171250:	18 63 00 91	add	x24, x24, #0x18
101171254:	7f 02 0f eb	cmp	x19, x15
101171258:	8c fd ff 54	b.gt	0x101171208
10117125c:	e8 a3 40 f9	ldr	x8, [sp, #0x140]
101171260:	14 01 00 b9	str	w20, [x8]
101171264:	08 03 80 52	mov	w8, #0x18
101171268:	68 67 08 9b	madd	x8, x27, x8, x25
10117126c:	17 01 18 cb	sub	x23, x8, x24
101171270:	fb 9f 40 f9	ldr	x27, [sp, #0x138]
101171274:	f9 03 16 aa	mov	x25, x22
101171278:	f6 07 40 91	add	x22, sp, #0x1, lsl #12
10117127c:	d6 c2 19 91	add	x22, x22, #0x670
101171280:	1a 03 80 52	mov	w26, #0x18
101171284:	fc 97 40 f9	ldr	x28, [sp, #0x128]
101171288:	f8 83 40 f9	ldr	x24, [sp, #0x100]
10117128c:	0b 00 00 14	b	0x1011712b8
101171290:	f6 07 40 91	add	x22, sp, #0x1, lsl #12
101171294:	d6 c2 19 91	add	x22, x22, #0x670
101171298:	1a 03 80 52	mov	w26, #0x18
10117129c:	f3 af 40 f9	ldr	x19, [sp, #0x158]
1011712a0:	cf 7a 33 b8	str	w15, [x22, x19, lsl #2]
1011712a4:	48 01 0f 6b	subs	w8, w10, w15
1011712a8:	cc 01 00 54	b.gt	0x1011712e0
1011712ac:	54 00 00 14	b	0x1011713fc
1011712b0:	f6 07 40 91	add	x22, sp, #0x1, lsl #12
1011712b4:	d6 c2 19 91	add	x22, x22, #0x670
1011712b8:	f3 a3 55 a9	ldp	x19, x8, [sp, #0x158]
1011712bc:	09 01 40 f9	ldr	x9, [x8]
1011712c0:	e8 02 09 cb	sub	x8, x23, x9
1011712c4:	08 fd 43 d3	lsr	x8, x8, #3
1011712c8:	6a 55 95 52	mov	w10, #0xaaab
1011712cc:	4a 55 b5 72	movk	w10, #0xaaaa, lsl #16
1011712d0:	0a 7d 0a 1b	mul	w10, w8, w10
1011712d4:	cf 7a 33 b8	str	w15, [x22, x19, lsl #2]
1011712d8:	48 01 0f 6b	subs	w8, w10, w15
1011712dc:	0d 09 00 54	b.le	0x1011713fc
1011712e0:	4a 15 00 51	sub	w10, w10, #0x5
1011712e4:	ff 01 0a 6b	cmp	w15, w10
1011712e8:	aa 00 80 52	mov	w10, #0x5
1011712ec:	08 c1 8a 1a	csel	w8, w8, w10, gt
1011712f0:	1f 05 00 71	cmp	w8, #0x1
1011712f4:	4b 08 00 54	b.lt	0x1011713fc
1011712f8:	ea 7d ba 9b	umull	x10, w15, w26
1011712fc:	20 69 6a bc	ldr	s0, [x9, x10]
101171300:	00 a4 20 0f	sshll.2d	v0, v0, #0x0
101171304:	00 d8 61 5e	scvtf	d0, d0
101171308:	61 03 40 bd	ldr	s1, [x27]
10117130c:	21 a4 20 0f	sshll.2d	v1, v1, #0x0
101171310:	23 d8 61 5e	scvtf	d3, d1
101171314:	01 18 63 1e	fdiv	d1, d0, d3
101171318:	08 7d 40 93	sxtw	x8, w8
10117131c:	e0 7f 40 fd	ldr	d0, [sp, #0xf8]
101171320:	22 28 60 1e	fadd	d2, d1, d0
101171324:	a0 19 63 1e	fdiv	d0, d13, d3
101171328:	ea 05 00 91	add	x10, x15, #0x1
10117132c:	eb 25 1a 9b	madd	x11, x15, x26, x9
101171330:	6b 61 00 91	add	x11, x11, #0x18
101171334:	ec 03 0b aa	mov	x12, x11
101171338:	f8 03 0a aa	mov	x24, x10
10117133c:	ed 03 08 aa	mov	x13, x8
101171340:	83 01 40 bd	ldr	s3, [x12]
101171344:	63 a4 20 0f	sshll.2d	v3, v3, #0x0
101171348:	63 d8 61 5e	scvtf	d3, d3
10117134c:	63 08 60 1e	fmul	d3, d3, d0
101171350:	64 38 69 1e	fsub	d4, d3, d9
101171354:	63 28 69 1e	fadd	d3, d3, d9
101171358:	40 20 64 1e	fcmp	d2, d4
10117135c:	40 c4 63 1e	fccmp	d2, d3, #0x0, gt
101171360:	ab 26 00 54	b.lt	0x101171834
101171364:	18 07 00 91	add	x24, x24, #0x1
101171368:	8c 61 00 91	add	x12, x12, #0x18
10117136c:	ad 05 00 f1	subs	x13, x13, #0x1
101171370:	81 fe ff 54	b.ne	0x101171340
101171374:	e2 5f 40 fd	ldr	d2, [sp, #0xb8]
101171378:	22 28 62 1e	fadd	d2, d1, d2
10117137c:	ec 03 0b aa	mov	x12, x11
101171380:	f8 03 0a aa	mov	x24, x10
101171384:	ed 03 08 aa	mov	x13, x8
101171388:	83 01 40 bd	ldr	s3, [x12]
10117138c:	63 a4 20 0f	sshll.2d	v3, v3, #0x0
101171390:	63 d8 61 5e	scvtf	d3, d3
101171394:	63 08 60 1e	fmul	d3, d3, d0
101171398:	64 38 69 1e	fsub	d4, d3, d9
10117139c:	63 28 69 1e	fadd	d3, d3, d9
1011713a0:	40 20 64 1e	fcmp	d2, d4
1011713a4:	40 c4 63 1e	fccmp	d2, d3, #0x0, gt
1011713a8:	6b 24 00 54	b.lt	0x101171834
1011713ac:	18 07 00 91	add	x24, x24, #0x1
1011713b0:	8c 61 00 91	add	x12, x12, #0x18
1011713b4:	ad 05 00 f1	subs	x13, x13, #0x1
1011713b8:	81 fe ff 54	b.ne	0x101171388
1011713bc:	e2 3f 40 fd	ldr	d2, [sp, #0x78]
1011713c0:	21 28 62 1e	fadd	d1, d1, d2
1011713c4:	f8 83 40 f9	ldr	x24, [sp, #0x100]
1011713c8:	62 01 40 bd	ldr	s2, [x11]
1011713cc:	42 a4 20 0f	sshll.2d	v2, v2, #0x0
1011713d0:	42 d8 61 5e	scvtf	d2, d2
1011713d4:	42 08 60 1e	fmul	d2, d2, d0
1011713d8:	43 38 69 1e	fsub	d3, d2, d9
1011713dc:	42 28 69 1e	fadd	d2, d2, d9
1011713e0:	20 20 63 1e	fcmp	d1, d3
1011713e4:	20 c4 62 1e	fccmp	d1, d2, #0x0, gt
1011713e8:	4b 22 00 54	b.lt	0x101171830
1011713ec:	4a 05 00 91	add	x10, x10, #0x1
1011713f0:	6b 61 00 91	add	x11, x11, #0x18
1011713f4:	08 05 00 f1	subs	x8, x8, #0x1
1011713f8:	81 fe ff 54	b.ne	0x1011713c8
1011713fc:	0e 03 80 52	mov	w14, #0x18
101171400:	10 00 80 52	mov	w16, #0x0
101171404:	9a 06 00 71	subs	w26, w20, #0x1
101171408:	2b 27 00 54	b.lt	0x1011718ec
10117140c:	ea 03 14 2a	mov	w10, w20
101171410:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
101171414:	08 01 40 f9	ldr	x8, [x8]
101171418:	8c 22 ae 9b	umaddl	x12, w20, w14, x8
10117141c:	80 01 40 bd	ldr	s0, [x12]
101171420:	00 a4 20 0f	sshll.2d	v0, v0, #0x0
101171424:	00 d8 61 5e	scvtf	d0, d0
101171428:	61 03 40 bd	ldr	s1, [x27]
10117142c:	21 a4 20 0f	sshll.2d	v1, v1, #0x0
101171430:	21 d8 61 5e	scvtf	d1, d1
101171434:	00 18 61 1e	fdiv	d0, d0, d1
101171438:	9f 16 00 71	cmp	w20, #0x5
10117143c:	a9 00 80 52	mov	w9, #0x5
101171440:	8b b2 89 1a	csel	w11, w20, w9, lt
101171444:	e2 7f 40 fd	ldr	d2, [sp, #0xf8]
101171448:	02 38 62 1e	fsub	d2, d0, d2
10117144c:	49 05 00 d1	sub	x9, x10, #0x1
101171450:	83 81 5e bc	ldur	s3, [x12, #-0x18]
101171454:	63 a4 20 0f	sshll.2d	v3, v3, #0x0
101171458:	63 d8 61 5e	scvtf	d3, d3
10117145c:	63 18 61 1e	fdiv	d3, d3, d1
101171460:	64 38 69 1e	fsub	d4, d3, d9
101171464:	63 28 69 1e	fadd	d3, d3, d9
101171468:	40 20 64 1e	fcmp	d2, d4
10117146c:	40 c4 63 1e	fccmp	d2, d3, #0x0, gt
101171470:	f8 03 09 aa	mov	x24, x9
101171474:	cb 10 00 54	b.lt	0x10117168c
101171478:	6b 05 00 11	add	w11, w11, #0x1
10117147c:	7f 09 00 71	cmp	w11, #0x2
101171480:	01 05 00 54	b.ne	0x101171520
101171484:	e2 5f 40 fd	ldr	d2, [sp, #0xb8]
101171488:	02 38 62 1e	fsub	d2, d0, d2
10117148c:	6b 05 00 d1	sub	x11, x11, #0x1
101171490:	4a 21 0e 9b	madd	x10, x10, x14, x8
101171494:	4a 61 00 d1	sub	x10, x10, #0x18
101171498:	ec 03 0a aa	mov	x12, x10
10117149c:	f8 03 09 aa	mov	x24, x9
1011714a0:	ed 03 0b aa	mov	x13, x11
1011714a4:	a1 19 61 1e	fdiv	d1, d13, d1
1011714a8:	83 01 40 bd	ldr	s3, [x12]
1011714ac:	63 a4 20 0f	sshll.2d	v3, v3, #0x0
1011714b0:	63 d8 61 5e	scvtf	d3, d3
1011714b4:	63 08 61 1e	fmul	d3, d3, d1
1011714b8:	64 38 69 1e	fsub	d4, d3, d9
1011714bc:	63 28 69 1e	fadd	d3, d3, d9
1011714c0:	40 20 64 1e	fcmp	d2, d4
1011714c4:	40 c4 63 1e	fccmp	d2, d3, #0x0, gt
1011714c8:	2b 0e 00 54	b.lt	0x10117168c
1011714cc:	18 07 00 d1	sub	x24, x24, #0x1
1011714d0:	8c 61 00 d1	sub	x12, x12, #0x18
1011714d4:	ad 05 00 d1	sub	x13, x13, #0x1
1011714d8:	8d fe ff b5	cbnz	x13, 0x1011714a8
1011714dc:	e2 3f 40 fd	ldr	d2, [sp, #0x78]
1011714e0:	00 38 62 1e	fsub	d0, d0, d2
1011714e4:	42 01 40 bd	ldr	s2, [x10]
1011714e8:	42 a4 20 0f	sshll.2d	v2, v2, #0x0
1011714ec:	42 d8 61 5e	scvtf	d2, d2
1011714f0:	42 08 61 1e	fmul	d2, d2, d1
1011714f4:	43 38 69 1e	fsub	d3, d2, d9
1011714f8:	42 28 69 1e	fadd	d2, d2, d9
1011714fc:	00 20 63 1e	fcmp	d0, d3
101171500:	00 c4 62 1e	fccmp	d0, d2, #0x0, gt
101171504:	2b 0c 00 54	b.lt	0x101171688
101171508:	29 05 00 d1	sub	x9, x9, #0x1
10117150c:	4a 61 00 d1	sub	x10, x10, #0x18
101171510:	6b 05 00 d1	sub	x11, x11, #0x1
101171514:	8b fe ff b5	cbnz	x11, 0x1011714e4
101171518:	f8 03 14 aa	mov	x24, x20
10117151c:	5c 00 00 14	b	0x10117168c
101171520:	58 09 00 d1	sub	x24, x10, #0x2
101171524:	0c 7f 0e 9b	mul	x12, x24, x14
101171528:	03 69 6c bc	ldr	s3, [x8, x12]
10117152c:	63 a4 20 0f	sshll.2d	v3, v3, #0x0
101171530:	63 d8 61 5e	scvtf	d3, d3
101171534:	63 18 61 1e	fdiv	d3, d3, d1
101171538:	64 38 69 1e	fsub	d4, d3, d9
10117153c:	63 28 69 1e	fadd	d3, d3, d9
101171540:	40 20 64 1e	fcmp	d2, d4
101171544:	40 c4 63 1e	fccmp	d2, d3, #0x0, gt
101171548:	2b 0a 00 54	b.lt	0x10117168c
10117154c:	7f 0d 00 71	cmp	w11, #0x3
101171550:	a0 f9 ff 54	b.eq	0x101171484
101171554:	58 0d 00 d1	sub	x24, x10, #0x3
101171558:	0c 7f 0e 9b	mul	x12, x24, x14
10117155c:	03 69 6c bc	ldr	s3, [x8, x12]
101171560:	63 a4 20 0f	sshll.2d	v3, v3, #0x0
101171564:	63 d8 61 5e	scvtf	d3, d3
101171568:	63 18 61 1e	fdiv	d3, d3, d1
10117156c:	64 38 69 1e	fsub	d4, d3, d9
101171570:	63 28 69 1e	fadd	d3, d3, d9
101171574:	40 20 64 1e	fcmp	d2, d4
101171578:	40 c4 63 1e	fccmp	d2, d3, #0x0, gt
10117157c:	8b 08 00 54	b.lt	0x10117168c
101171580:	7f 11 00 71	cmp	w11, #0x4
101171584:	00 f8 ff 54	b.eq	0x101171484
101171588:	58 11 00 d1	sub	x24, x10, #0x4
10117158c:	0c 7f 0e 9b	mul	x12, x24, x14
101171590:	03 69 6c bc	ldr	s3, [x8, x12]
101171594:	63 a4 20 0f	sshll.2d	v3, v3, #0x0
101171598:	63 d8 61 5e	scvtf	d3, d3
10117159c:	63 18 61 1e	fdiv	d3, d3, d1
1011715a0:	64 38 69 1e	fsub	d4, d3, d9
1011715a4:	63 28 69 1e	fadd	d3, d3, d9
1011715a8:	40 20 64 1e	fcmp	d2, d4
1011715ac:	40 c4 63 1e	fccmp	d2, d3, #0x0, gt
1011715b0:	eb 06 00 54	b.lt	0x10117168c
1011715b4:	7f 15 00 71	cmp	w11, #0x5
1011715b8:	60 f6 ff 54	b.eq	0x101171484
1011715bc:	58 15 00 d1	sub	x24, x10, #0x5
1011715c0:	0c 7f 0e 9b	mul	x12, x24, x14
1011715c4:	03 69 6c bc	ldr	s3, [x8, x12]
1011715c8:	63 a4 20 0f	sshll.2d	v3, v3, #0x0
1011715cc:	63 d8 61 5e	scvtf	d3, d3
1011715d0:	63 18 61 1e	fdiv	d3, d3, d1
1011715d4:	64 38 69 1e	fsub	d4, d3, d9
1011715d8:	40 20 64 1e	fcmp	d2, d4
1011715dc:	4d f5 ff 54	b.le	0x101171484
1011715e0:	63 28 69 1e	fadd	d3, d3, d9
1011715e4:	40 20 63 1e	fcmp	d2, d3
1011715e8:	2b 05 00 54	b.lt	0x10117168c
1011715ec:	a6 ff ff 17	b	0x101171484
1011715f0:	0a 12 00 51	sub	w10, w16, #0x4
1011715f4:	5f 03 0a 6b	cmp	w26, w10
1011715f8:	ec 01 00 54	b.gt	0x101171634
1011715fc:	4b 0f 00 91	add	x11, x26, #0x3
101171600:	80 7a 6b fc	ldr	d0, [x20, x11, lsl #3]
101171604:	c1 01 67 9e	fmov	d1, x14
101171608:	00 20 61 1e	fcmp	d0, d1
10117160c:	ea a3 90 d2	mov	x10, #0x851f
101171610:	6a 3d aa f2	movk	x10, #0x51eb, lsl #16
101171614:	0a d7 c3 f2	movk	x10, #0x1eb8, lsl #32
101171618:	2a fe e7 f2	movk	x10, #0x3ff1, lsl #48
10117161c:	41 01 67 9e	fmov	d1, x10
101171620:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
101171624:	0c 6f 00 54	b.gt	0x101172404
101171628:	e1 01 67 9e	fmov	d1, x15
10117162c:	00 20 61 1e	fcmp	d0, d1
101171630:	ac 6e 00 54	b.gt	0x101172404
101171634:	fa 83 40 f9	ldr	x26, [sp, #0x100]
101171638:	20 fe ff 17	b	0x101170eb8
10117163c:	09 12 00 51	sub	w9, w16, #0x4
101171640:	1f 01 09 6b	cmp	w8, w9
101171644:	ec 01 00 54	b.gt	0x101171680
101171648:	0c 0d 00 11	add	w12, w8, #0x3
10117164c:	80 da 6c fc	ldr	d0, [x20, w12, sxtw #3]
101171650:	c1 01 67 9e	fmov	d1, x14
101171654:	00 20 61 1e	fcmp	d0, d1
101171658:	e9 a3 90 d2	mov	x9, #0x851f
10117165c:	69 3d aa f2	movk	x9, #0x51eb, lsl #16
101171660:	09 d7 c3 f2	movk	x9, #0x1eb8, lsl #32
101171664:	29 fe e7 f2	movk	x9, #0x3ff1, lsl #48
101171668:	21 01 67 9e	fmov	d1, x9
10117166c:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
101171670:	0c 6f 00 54	b.gt	0x101172450
101171674:	e1 01 67 9e	fmov	d1, x15
101171678:	00 20 61 1e	fcmp	d0, d1
10117167c:	ac 6e 00 54	b.gt	0x101172450
101171680:	e8 03 0b aa	mov	x8, x11
101171684:	8c fe ff 17	b	0x1011710b4
101171688:	f8 03 09 aa	mov	x24, x9
10117168c:	5f 03 18 6b	cmp	w26, w24
101171690:	f5 d7 9f 1a	cset	w21, gt
101171694:	6d 05 00 54	b.le	0x101171740
101171698:	fb 03 1c aa	mov	x27, x28
10117169c:	fc 03 10 aa	mov	x28, x16
1011716a0:	40 23 2e 9b	smaddl	x0, w26, w14, x8
1011716a4:	01 60 00 91	add	x1, x0, #0x18
1011716a8:	e2 02 01 cb	sub	x2, x23, x1
1011716ac:	e8 83 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
1011716b0:	f7 62 00 d1	sub	x23, x23, #0x18
1011716b4:	37 03 00 f9	str	x23, [x25]
1011716b8:	08 07 00 11	add	w8, w24, #0x1
1011716bc:	1f 01 1a 6b	cmp	w8, w26
1011716c0:	60 02 00 54	b.eq	0x10117170c
1011716c4:	f5 a7 00 b9	str	w21, [sp, #0xa4]
1011716c8:	55 7f 40 93	sxtw	x21, w26
1011716cc:	93 0a 00 51	sub	w19, w20, #0x2
1011716d0:	f4 b3 40 f9	ldr	x20, [sp, #0x160]
1011716d4:	1a 03 80 52	mov	w26, #0x18
1011716d8:	88 02 40 f9	ldr	x8, [x20]
1011716dc:	a0 22 1a 9b	madd	x0, x21, x26, x8
1011716e0:	01 60 00 91	add	x1, x0, #0x18
1011716e4:	e2 02 01 cb	sub	x2, x23, x1
1011716e8:	d9 83 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
1011716ec:	f7 62 00 d1	sub	x23, x23, #0x18
1011716f0:	37 03 00 f9	str	x23, [x25]
1011716f4:	73 06 00 51	sub	w19, w19, #0x1
1011716f8:	1f 03 13 6b	cmp	w24, w19
1011716fc:	e1 fe ff 54	b.ne	0x1011716d8
101171700:	7a 06 00 11	add	w26, w19, #0x1
101171704:	f3 af 40 f9	ldr	x19, [sp, #0x158]
101171708:	f5 a7 40 b9	ldr	w21, [sp, #0xa4]
10117170c:	e8 a3 40 f9	ldr	x8, [sp, #0x140]
101171710:	1a 01 00 b9	str	w26, [x8]
101171714:	f4 03 1a aa	mov	x20, x26
101171718:	ef 93 40 f9	ldr	x15, [sp, #0x120]
10117171c:	f8 83 40 f9	ldr	x24, [sp, #0x100]
101171720:	f0 03 1c aa	mov	x16, x28
101171724:	fc 03 1b aa	mov	x28, x27
101171728:	fb 9f 40 f9	ldr	x27, [sp, #0x138]
10117172c:	c8 7a 73 b8	ldr	w8, [x22, x19, lsl #2]
101171730:	08 05 00 11	add	w8, w8, #0x1
101171734:	1f 01 14 6b	cmp	w8, w20
101171738:	eb 00 00 54	b.lt	0x101171754
10117173c:	6d 00 00 14	b	0x1011718f0
101171740:	f8 83 40 f9	ldr	x24, [sp, #0x100]
101171744:	c8 7a 73 b8	ldr	w8, [x22, x19, lsl #2]
101171748:	08 05 00 11	add	w8, w8, #0x1
10117174c:	1f 01 14 6b	cmp	w8, w20
101171750:	0a 0d 00 54	b.ge	0x1011718f0
101171754:	f5 a7 00 b9	str	w21, [sp, #0xa4]
101171758:	f0 77 00 b9	str	w16, [sp, #0x74]
10117175c:	18 7d 40 93	sxtw	x24, w8
101171760:	94 7e 40 93	sxtw	x20, w20
101171764:	08 c7 28 8b	add	x8, x24, w8, sxtw #1
101171768:	1a f1 7d d3	lsl	x26, x8, #3
10117176c:	e8 05 80 92	mov	x8, #-0x30
101171770:	1b 01 1a cb	sub	x27, x8, x26
101171774:	13 07 00 91	add	x19, x24, #0x1
101171778:	f6 03 19 aa	mov	x22, x25
10117177c:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
101171780:	1c 01 40 f9	ldr	x28, [x8]
101171784:	08 03 80 52	mov	w8, #0x18
101171788:	08 73 08 9b	madd	x8, x24, x8, x28
10117178c:	e9 02 1c cb	sub	x9, x23, x28
101171790:	62 03 09 8b	add	x2, x27, x9
101171794:	e9 f3 01 b2	mov	x9, #-0x5555555555555556
101171798:	69 55 95 f2	movk	x9, #0xaaab
10117179c:	49 55 e5 f2	movk	x9, #0x2aaa, lsl #48
1011717a0:	49 7c 49 9b	smulh	x9, x2, x9
1011717a4:	2a fd 42 93	asr	x10, x9, #2
1011717a8:	59 fd 49 8b	add	x25, x10, x9, lsr #63
1011717ac:	29 07 19 8b	add	x9, x25, x25, lsl #1
1011717b0:	35 f1 7d d3	lsl	x21, x9, #3
1011717b4:	17 01 15 8b	add	x23, x8, x21
1011717b8:	88 03 1a 8b	add	x8, x28, x26
1011717bc:	00 61 00 91	add	x0, x8, #0x18
1011717c0:	01 c1 00 91	add	x1, x8, #0x30
1011717c4:	a2 83 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
1011717c8:	f7 62 00 91	add	x23, x23, #0x18
1011717cc:	88 03 15 8b	add	x8, x28, x21
1011717d0:	08 01 1a 8b	add	x8, x8, x26
1011717d4:	08 61 00 91	add	x8, x8, #0x18
1011717d8:	c8 02 00 f9	str	x8, [x22]
1011717dc:	18 07 00 91	add	x24, x24, #0x1
1011717e0:	94 06 00 d1	sub	x20, x20, #0x1
1011717e4:	5a 63 00 91	add	x26, x26, #0x18
1011717e8:	7b 63 00 d1	sub	x27, x27, #0x18
1011717ec:	68 06 00 91	add	x8, x19, #0x1
1011717f0:	7f 02 14 eb	cmp	x19, x20
1011717f4:	f3 03 08 aa	mov	x19, x8
1011717f8:	2b fc ff 54	b.lt	0x10117177c
1011717fc:	fb a3 53 a9	ldp	x27, x8, [sp, #0x138]
101171800:	14 01 00 b9	str	w20, [x8]
101171804:	08 03 80 52	mov	w8, #0x18
101171808:	28 73 08 9b	madd	x8, x25, x8, x28
10117180c:	17 01 1a 8b	add	x23, x8, x26
101171810:	ef 73 52 a9	ldp	x15, x28, [sp, #0x120]
101171814:	f6 07 40 91	add	x22, sp, #0x1, lsl #12
101171818:	d6 c2 19 91	add	x22, x22, #0x670
10117181c:	f3 af 40 f9	ldr	x19, [sp, #0x158]
101171820:	f8 83 40 f9	ldr	x24, [sp, #0x100]
101171824:	f0 77 40 b9	ldr	w16, [sp, #0x74]
101171828:	f5 a7 40 b9	ldr	w21, [sp, #0xa4]
10117182c:	31 00 00 14	b	0x1011718f0
101171830:	f8 03 0a aa	mov	x24, x10
101171834:	f3 05 00 11	add	w19, w15, #0x1
101171838:	7f 02 18 6b	cmp	w19, w24
10117183c:	ca 03 00 54	b.ge	0x1011718b4
101171840:	60 26 ba 9b	umaddl	x0, w19, w26, x9
101171844:	01 60 00 91	add	x1, x0, #0x18
101171848:	e2 02 01 cb	sub	x2, x23, x1
10117184c:	80 83 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
101171850:	f7 62 00 d1	sub	x23, x23, #0x18
101171854:	37 03 00 f9	str	x23, [x25]
101171858:	e9 a3 40 f9	ldr	x9, [sp, #0x140]
10117185c:	28 01 40 b9	ldr	w8, [x9]
101171860:	14 05 00 51	sub	w20, w8, #0x1
101171864:	34 01 00 b9	str	w20, [x9]
101171868:	18 07 00 51	sub	w24, w24, #0x1
10117186c:	7f 02 18 6b	cmp	w19, w24
101171870:	0a 03 00 54	b.ge	0x1011718d0
101171874:	f5 b3 40 f9	ldr	x21, [sp, #0x160]
101171878:	a8 02 40 f9	ldr	x8, [x21]
10117187c:	60 22 1a 9b	madd	x0, x19, x26, x8
101171880:	01 60 00 91	add	x1, x0, #0x18
101171884:	e2 02 01 cb	sub	x2, x23, x1
101171888:	71 83 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
10117188c:	f7 62 00 d1	sub	x23, x23, #0x18
101171890:	37 03 00 f9	str	x23, [x25]
101171894:	94 06 00 51	sub	w20, w20, #0x1
101171898:	18 07 00 51	sub	w24, w24, #0x1
10117189c:	7f 02 18 6b	cmp	w19, w24
1011718a0:	cb fe ff 54	b.lt	0x101171878
1011718a4:	0e 03 80 52	mov	w14, #0x18
1011718a8:	e8 a3 40 f9	ldr	x8, [sp, #0x140]
1011718ac:	14 01 00 b9	str	w20, [x8]
1011718b0:	09 00 00 14	b	0x1011718d4
1011718b4:	0e 03 80 52	mov	w14, #0x18
1011718b8:	10 00 80 52	mov	w16, #0x0
1011718bc:	f3 af 40 f9	ldr	x19, [sp, #0x158]
1011718c0:	f8 83 40 f9	ldr	x24, [sp, #0x100]
1011718c4:	9a 06 00 71	subs	w26, w20, #0x1
1011718c8:	2a da ff 54	b.ge	0x10117140c
1011718cc:	08 00 00 14	b	0x1011718ec
1011718d0:	0e 03 80 52	mov	w14, #0x18
1011718d4:	30 00 80 52	mov	w16, #0x1
1011718d8:	f3 af 40 f9	ldr	x19, [sp, #0x158]
1011718dc:	ef 93 40 f9	ldr	x15, [sp, #0x120]
1011718e0:	f8 83 40 f9	ldr	x24, [sp, #0x100]
1011718e4:	9a 06 00 71	subs	w26, w20, #0x1
1011718e8:	2a d9 ff 54	b.ge	0x10117140c
1011718ec:	15 00 80 52	mov	w21, #0x0
1011718f0:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
1011718f4:	08 01 40 f9	ldr	x8, [x8]
1011718f8:	e9 02 08 cb	sub	x9, x23, x8
1011718fc:	29 fd 43 d3	lsr	x9, x9, #3
101171900:	6a 55 95 52	mov	w10, #0xaaab
101171904:	4a 55 b5 72	movk	w10, #0xaaaa, lsl #16
101171908:	37 7d 0a 1b	mul	w23, w9, w10
10117190c:	e9 6b 40 f9	ldr	x9, [sp, #0xd0]
101171910:	3f 01 18 6b	cmp	w9, w24
101171914:	ac 00 00 54	b.gt	0x101171928
101171918:	95 00 00 35	cbnz	w21, 0x101171928
10117191c:	15 03 80 52	mov	w21, #0x18
101171920:	fa a3 40 f9	ldr	x26, [sp, #0x140]
101171924:	41 00 00 14	b	0x101171a28
101171928:	98 06 00 11	add	w24, w20, #0x1
10117192c:	1f 03 17 6b	cmp	w24, w23
101171930:	15 03 80 52	mov	w21, #0x18
101171934:	fa a3 40 f9	ldr	x26, [sp, #0x140]
101171938:	8a 07 00 54	b.ge	0x101171a28
10117193c:	8a 7e 35 9b	smull	x10, w20, w21
101171940:	00 69 6a bc	ldr	s0, [x8, x10]
101171944:	00 a4 20 0f	sshll.2d	v0, v0, #0x0
101171948:	00 d8 61 5e	scvtf	d0, d0
10117194c:	69 03 40 b9	ldr	w9, [x27]
101171950:	21 01 62 1e	scvtf	d1, w9
101171954:	0a 18 61 1e	fdiv	d10, d0, d1
101171958:	0b 7f 35 9b	smull	x11, w24, w21
10117195c:	00 69 6b bc	ldr	s0, [x8, x11]
101171960:	00 a4 20 0f	sshll.2d	v0, v0, #0x0
101171964:	00 d8 61 5e	scvtf	d0, d0
101171968:	00 18 61 1e	fdiv	d0, d0, d1
10117196c:	0b 38 6a 1e	fsub	d11, d0, d10
101171970:	0b 00 c8 d2	mov	x11, #0x400000000000
101171974:	eb 11 e8 f2	movk	x11, #0x408f, lsl #48
101171978:	60 01 67 9e	fmov	d0, x11
10117197c:	60 09 60 1e	fmul	d0, d11, d0
101171980:	00 38 4c 1f	fmadd	d0, d0, d12, d14
101171984:	0b 00 78 1e	fcvtzs	w11, d0
101171988:	79 09 00 71	subs	w25, w11, #0x2
10117198c:	eb 04 00 54	b.lt	0x101171a28
101171990:	fc 03 10 aa	mov	x28, x16
101171994:	1a 00 80 52	mov	w26, #0x0
101171998:	60 01 62 1e	scvtf	d0, w11
10117199c:	ff d7 03 b9	str	wzr, [sp, #0x3d4]
1011719a0:	0b 00 80 12	mov	w11, #-0x1
1011719a4:	eb e3 03 b9	str	w11, [sp, #0x3e0]
1011719a8:	ff 93 0f 39	strb	wzr, [sp, #0x3e4]
1011719ac:	a8 19 60 1e	fdiv	d8, d13, d0
1011719b0:	53 61 00 91	add	x19, x10, #0x18
1011719b4:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
1011719b8:	4a 07 00 11	add	w10, w26, #0x1
1011719bc:	40 01 62 1e	scvtf	d0, w10
1011719c0:	60 09 60 1e	fmul	d0, d11, d0
1011719c4:	00 28 48 1f	fmadd	d0, d0, d8, d10
1011719c8:	21 01 62 1e	scvtf	d1, w9
1011719cc:	00 38 41 1f	fmadd	d0, d0, d1, d14
1011719d0:	09 00 78 1e	fcvtzs	w9, d0
1011719d4:	e9 d3 03 b9	str	w9, [sp, #0x3d0]
1011719d8:	ff ef 01 f9	str	xzr, [sp, #0x3d8]
1011719dc:	61 02 08 8b	add	x1, x19, x8
1011719e0:	e2 43 0f 91	add	x2, sp, #0x3d0
1011719e4:	0d 36 ff 97	bl	__ZNSt3__16vectorIN16BeatAnalyzer_2_06peakss8BeatInfoENS_9allocatorIS3_EEE6insertENS_11__wrap_iterIPKS3_EERS8_
1011719e8:	14 03 1a 0b	add	w20, w24, w26
1011719ec:	e8 a3 40 f9	ldr	x8, [sp, #0x140]
1011719f0:	14 01 00 b9	str	w20, [x8]
1011719f4:	3f 03 1a 6b	cmp	w25, w26
1011719f8:	e0 00 00 54	b.eq	0x101171a14
1011719fc:	69 03 40 b9	ldr	w9, [x27]
101171a00:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
101171a04:	08 00 40 f9	ldr	x8, [x0]
101171a08:	73 62 00 91	add	x19, x19, #0x18
101171a0c:	5a 07 00 11	add	w26, w26, #0x1
101171a10:	ea ff ff 17	b	0x1011719b8
101171a14:	15 03 80 52	mov	w21, #0x18
101171a18:	f3 af 40 f9	ldr	x19, [sp, #0x158]
101171a1c:	fa a3 40 f9	ldr	x26, [sp, #0x140]
101171a20:	f0 03 1c aa	mov	x16, x28
101171a24:	ef 73 52 a9	ldp	x15, x28, [sp, #0x120]
101171a28:	e8 67 40 f9	ldr	x8, [sp, #0xc8]
101171a2c:	1f 01 0f 6b	cmp	w8, w15
101171a30:	e8 c7 9f 1a	cset	w8, le
101171a34:	09 02 00 52	eor	w9, w16, #0x1
101171a38:	08 01 09 0a	and	w8, w8, w9
101171a3c:	e8 07 00 37	tbnz	w8, #0x0, 0x101171b38
101171a40:	ca 7a b3 b8	ldrsw	x10, [x22, x19, lsl #2]
101171a44:	4b 05 00 91	add	x11, x10, #0x1
101171a48:	7f 01 17 6b	cmp	w11, w23
101171a4c:	f9 9b 40 f9	ldr	x25, [sp, #0x130]
101171a50:	f8 87 40 f9	ldr	x24, [sp, #0x108]
101171a54:	0a 08 00 54	b.ge	0x101171b54
101171a58:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
101171a5c:	08 01 40 f9	ldr	x8, [x8]
101171a60:	49 7d 15 9b	mul	x9, x10, x21
101171a64:	00 69 69 bc	ldr	s0, [x8, x9]
101171a68:	00 a4 20 0f	sshll.2d	v0, v0, #0x0
101171a6c:	00 d8 61 5e	scvtf	d0, d0
101171a70:	69 03 40 b9	ldr	w9, [x27]
101171a74:	21 01 62 1e	scvtf	d1, w9
101171a78:	0a 18 61 1e	fdiv	d10, d0, d1
101171a7c:	6b 7d 15 9b	mul	x11, x11, x21
101171a80:	00 69 6b bc	ldr	s0, [x8, x11]
101171a84:	00 a4 20 0f	sshll.2d	v0, v0, #0x0
101171a88:	00 d8 61 5e	scvtf	d0, d0
101171a8c:	00 18 61 1e	fdiv	d0, d0, d1
101171a90:	0b 38 6a 1e	fsub	d11, d0, d10
101171a94:	0b 00 c8 d2	mov	x11, #0x400000000000
101171a98:	eb 11 e8 f2	movk	x11, #0x408f, lsl #48
101171a9c:	60 01 67 9e	fmov	d0, x11
101171aa0:	60 09 60 1e	fmul	d0, d11, d0
101171aa4:	00 38 4c 1f	fmadd	d0, d0, d12, d14
101171aa8:	0b 00 78 1e	fcvtzs	w11, d0
101171aac:	7f 09 00 71	cmp	w11, #0x2
101171ab0:	2b 05 00 54	b.lt	0x101171b54
101171ab4:	60 01 62 1e	scvtf	d0, w11
101171ab8:	ff d7 03 b9	str	wzr, [sp, #0x3d4]
101171abc:	0c 00 80 12	mov	w12, #-0x1
101171ac0:	ec e3 03 b9	str	w12, [sp, #0x3e0]
101171ac4:	ff 93 0f 39	strb	wzr, [sp, #0x3e4]
101171ac8:	76 05 00 51	sub	w22, w11, #0x1
101171acc:	a8 19 60 1e	fdiv	d8, d13, d0
101171ad0:	f3 03 14 2a	mov	w19, w20
101171ad4:	eb 07 7d b2	orr	x11, xzr, #0x18
101171ad8:	57 2d 15 9b	madd	x23, x10, x21, x11
101171adc:	38 00 80 52	mov	w24, #0x1
101171ae0:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
101171ae4:	00 03 62 1e	scvtf	d0, w24
101171ae8:	60 09 60 1e	fmul	d0, d11, d0
101171aec:	00 28 48 1f	fmadd	d0, d0, d8, d10
101171af0:	21 01 62 1e	scvtf	d1, w9
101171af4:	00 38 41 1f	fmadd	d0, d0, d1, d14
101171af8:	09 00 78 1e	fcvtzs	w9, d0
101171afc:	e9 d3 03 b9	str	w9, [sp, #0x3d0]
101171b00:	ff ef 01 f9	str	xzr, [sp, #0x3d8]
101171b04:	e1 02 08 8b	add	x1, x23, x8
101171b08:	e2 43 0f 91	add	x2, sp, #0x3d0
101171b0c:	c3 35 ff 97	bl	__ZNSt3__16vectorIN16BeatAnalyzer_2_06peakss8BeatInfoENS_9allocatorIS3_EEE6insertENS_11__wrap_iterIPKS3_EERS8_
101171b10:	68 02 18 0b	add	w8, w19, w24
101171b14:	48 03 00 b9	str	w8, [x26]
101171b18:	df 02 18 eb	cmp	x22, x24
101171b1c:	40 16 00 54	b.eq	0x101171de4
101171b20:	69 03 40 b9	ldr	w9, [x27]
101171b24:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
101171b28:	08 00 40 f9	ldr	x8, [x0]
101171b2c:	18 07 00 91	add	x24, x24, #0x1
101171b30:	f7 62 00 91	add	x23, x23, #0x18
101171b34:	ec ff ff 17	b	0x101171ae4
101171b38:	f9 9b 40 f9	ldr	x25, [sp, #0x130]
101171b3c:	f7 07 40 91	add	x23, sp, #0x1, lsl #12
101171b40:	f7 c2 11 91	add	x23, x23, #0x470
101171b44:	ea f3 01 b2	mov	x10, #-0x5555555555555556
101171b48:	6a 55 95 f2	movk	x10, #0xaaab
101171b4c:	f8 87 40 f9	ldr	x24, [sp, #0x108]
101171b50:	05 00 00 14	b	0x101171b64
101171b54:	f7 07 40 91	add	x23, sp, #0x1, lsl #12
101171b58:	f7 c2 11 91	add	x23, x23, #0x470
101171b5c:	ea f3 01 b2	mov	x10, #-0x5555555555555556
101171b60:	6a 55 95 f2	movk	x10, #0xaaab
101171b64:	ff ef 01 f9	str	xzr, [sp, #0x3d8]
101171b68:	ff eb 01 f9	str	xzr, [sp, #0x3d0]
101171b6c:	08 00 80 12	mov	w8, #-0x1
101171b70:	e8 e3 03 b9	str	w8, [sp, #0x3e0]
101171b74:	ff 93 0f 39	strb	wzr, [sp, #0x3e4]
101171b78:	f3 b3 40 f9	ldr	x19, [sp, #0x160]
101171b7c:	61 02 40 f9	ldr	x1, [x19]
101171b80:	28 18 40 b9	ldr	w8, [x1, #0x18]
101171b84:	29 00 40 b9	ldr	w9, [x1]
101171b88:	08 01 09 4b	sub	w8, w8, w9
101171b8c:	28 01 08 6b	subs	w8, w9, w8
101171b90:	6d 01 00 54	b.le	0x101171bbc
101171b94:	e8 d3 03 b9	str	w8, [sp, #0x3d0]
101171b98:	ff db 03 b9	str	wzr, [sp, #0x3d8]
101171b9c:	e2 43 0f 91	add	x2, sp, #0x3d0
101171ba0:	e0 03 13 aa	mov	x0, x19
101171ba4:	9d 35 ff 97	bl	__ZNSt3__16vectorIN16BeatAnalyzer_2_06peakss8BeatInfoENS_9allocatorIS3_EEE6insertENS_11__wrap_iterIPKS3_EERS8_
101171ba8:	88 06 00 11	add	w8, w20, #0x1
101171bac:	48 03 00 b9	str	w8, [x26]
101171bb0:	61 02 40 f9	ldr	x1, [x19]
101171bb4:	ea f3 01 b2	mov	x10, #-0x5555555555555556
101171bb8:	6a 55 95 f2	movk	x10, #0xaaab
101171bbc:	28 03 40 f9	ldr	x8, [x25]
101171bc0:	08 01 01 cb	sub	x8, x8, x1
101171bc4:	08 fd 43 93	asr	x8, x8, #3
101171bc8:	07 7d 0a 9b	mul	x7, x8, x10
101171bcc:	ff 08 00 71	cmp	w7, #0x2
101171bd0:	f4 8b 40 f9	ldr	x20, [sp, #0x110]
101171bd4:	eb 06 00 54	b.lt	0x101171cb0
101171bd8:	e8 04 00 51	sub	w8, w7, #0x1
101171bdc:	09 7d b5 9b	umull	x9, w8, w21
101171be0:	2a 68 69 b8	ldr	w10, [x1, x9]
101171be4:	e9 7c 60 d3	lsl	x9, x7, #32
101171be8:	eb 7b 5f b2	mov	x11, #-0x200000000
101171bec:	2b 01 0b 8b	add	x11, x9, x11
101171bf0:	6b fd 60 93	asr	x11, x11, #32
101171bf4:	6b 7d 15 9b	mul	x11, x11, x21
101171bf8:	2b 68 6b b8	ldr	w11, [x1, x11]
101171bfc:	53 01 0b 6b	subs	w19, w10, w11
101171c00:	80 05 00 54	b.eq	0x101171cb0
101171c04:	8b 1f 40 b9	ldr	w11, [x28, #0x1c]
101171c08:	6a 01 0a 4b	sub	w10, w11, w10
101171c0c:	40 01 62 1e	scvtf	d0, w10
101171c10:	61 02 62 1e	scvtf	d1, w19
101171c14:	00 18 61 1e	fdiv	d0, d0, d1
101171c18:	00 20 6d 1e	fcmp	d0, d13
101171c1c:	ad 04 00 54	b.le	0x101171cb0
101171c20:	0a 00 78 1e	fcvtzs	w10, d0
101171c24:	ff e3 01 f9	str	xzr, [sp, #0x3c0]
101171c28:	ff df 01 f9	str	xzr, [sp, #0x3b8]
101171c2c:	0b 00 80 12	mov	w11, #-0x1
101171c30:	eb cb 03 b9	str	w11, [sp, #0x3c8]
101171c34:	ff 33 0f 39	strb	wzr, [sp, #0x3cc]
101171c38:	5f 05 00 71	cmp	w10, #0x1
101171c3c:	0b 03 00 54	b.lt	0x101171c9c
101171c40:	fa 03 07 aa	mov	x26, x7
101171c44:	29 fd 60 93	asr	x9, x9, #32
101171c48:	08 05 08 8b	add	x8, x8, x8, lsl #1
101171c4c:	14 f1 7d d3	lsl	x20, x8, #3
101171c50:	28 05 09 8b	add	x8, x9, x9, lsl #1
101171c54:	16 f1 7d d3	lsl	x22, x8, #3
101171c58:	57 05 00 d1	sub	x23, x10, #0x1
101171c5c:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
101171c60:	28 68 74 b8	ldr	w8, [x1, x20]
101171c64:	08 01 13 0b	add	w8, w8, w19
101171c68:	e8 bb 03 b9	str	w8, [sp, #0x3b8]
101171c6c:	ff e3 01 f9	str	xzr, [sp, #0x3c0]
101171c70:	c1 02 01 8b	add	x1, x22, x1
101171c74:	e2 e3 0e 91	add	x2, sp, #0x3b8
101171c78:	68 35 ff 97	bl	__ZNSt3__16vectorIN16BeatAnalyzer_2_06peakss8BeatInfoENS_9allocatorIS3_EEE6insertENS_11__wrap_iterIPKS3_EERS8_
101171c7c:	e7 03 1a aa	mov	x7, x26
101171c80:	f7 00 00 b4	cbz	x23, 0x101171c9c
101171c84:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
101171c88:	01 00 40 f9	ldr	x1, [x0]
101171c8c:	94 62 00 91	add	x20, x20, #0x18
101171c90:	d6 62 00 91	add	x22, x22, #0x18
101171c94:	f7 06 00 d1	sub	x23, x23, #0x1
101171c98:	f2 ff ff 17	b	0x101171c60
101171c9c:	f7 07 40 91	add	x23, sp, #0x1, lsl #12
101171ca0:	f7 c2 11 91	add	x23, x23, #0x470
101171ca4:	f6 07 40 91	add	x22, sp, #0x1, lsl #12
101171ca8:	d6 c2 19 91	add	x22, x22, #0x670
101171cac:	f4 8b 40 f9	ldr	x20, [sp, #0x110]
101171cb0:	e8 c3 40 b9	ldr	w8, [sp, #0xc0]
101171cb4:	28 2f 03 34	cbz	w8, 0x101178298
101171cb8:	29 03 40 f9	ldr	x9, [x25]
101171cbc:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
101171cc0:	08 01 40 f9	ldr	x8, [x8]
101171cc4:	29 01 08 cb	sub	x9, x9, x8
101171cc8:	29 fd 43 d3	lsr	x9, x9, #3
101171ccc:	6a 55 95 52	mov	w10, #0xaaab
101171cd0:	4a 55 b5 72	movk	w10, #0xaaaa, lsl #16
101171cd4:	27 7d 0a 1b	mul	w7, w9, w10
101171cd8:	e9 08 00 51	sub	w9, w7, #0x2
101171cdc:	3f 05 00 71	cmp	w9, #0x1
101171ce0:	2a c5 9f 1a	csinc	w10, w9, wzr, gt
101171ce4:	0f 06 80 52	mov	w15, #0x30
101171ce8:	2b 00 80 52	mov	w11, #0x1
101171cec:	7f 01 0a eb	cmp	x11, x10
101171cf0:	40 2d 03 54	b.eq	0x101178298
101171cf4:	e9 03 0b aa	mov	x9, x11
101171cf8:	f3 03 0f aa	mov	x19, x15
101171cfc:	6b 21 15 9b	madd	x11, x11, x21, x8
101171d00:	70 01 40 b9	ldr	w16, [x11]
101171d04:	6d 81 5e b8	ldur	w13, [x11, #-0x18]
101171d08:	2b 05 00 91	add	x11, x9, #0x1
101171d0c:	6c 7d 40 92	and	x12, x11, #0xffffffff
101171d10:	8c 7d 15 9b	mul	x12, x12, x21
101171d14:	0c 69 6c b8	ldr	w12, [x8, x12]
101171d18:	0f 02 0d 4b	sub	w15, w16, w13
101171d1c:	2d 09 00 11	add	w13, w9, #0x2
101171d20:	ad 7d b5 9b	umull	x13, w13, w21
101171d24:	0e 69 6d b8	ldr	w14, [x8, x13]
101171d28:	cd 01 0c 4b	sub	w13, w14, w12
101171d2c:	f1 09 0f 0b	add	w17, w15, w15, lsl #2
101171d30:	a1 09 0d 0b	add	w1, w13, w13, lsl #2
101171d34:	6f 62 00 91	add	x15, x19, #0x18
101171d38:	90 01 10 4b	sub	w16, w12, w16
101171d3c:	1f 02 11 6b	cmp	w16, w17
101171d40:	00 d2 41 7a	ccmp	w16, w1, #0x0, le
101171d44:	4d fd ff 54	b.le	0x101171cec
101171d48:	df 01 0c 6b	cmp	w14, w12
101171d4c:	60 2a 03 54	b.eq	0x101178298
101171d50:	00 02 62 1e	scvtf	d0, w16
101171d54:	a1 01 62 1e	scvtf	d1, w13
101171d58:	01 18 61 1e	fdiv	d1, d0, d1
101171d5c:	20 20 6d 1e	fcmp	d1, d13
101171d60:	cd 29 03 54	b.le	0x101178298
101171d64:	2a 00 78 1e	fcvtzs	w10, d1
101171d68:	ff e3 01 f9	str	xzr, [sp, #0x3c0]
101171d6c:	ff df 01 f9	str	xzr, [sp, #0x3b8]
101171d70:	0b 00 80 12	mov	w11, #-0x1
101171d74:	eb cb 03 b9	str	w11, [sp, #0x3c8]
101171d78:	ff 33 0f 39	strb	wzr, [sp, #0x3cc]
101171d7c:	5f 09 00 71	cmp	w10, #0x2
101171d80:	eb 03 00 54	b.lt	0x101171dfc
101171d84:	fa 03 07 aa	mov	x26, x7
101171d88:	21 c0 65 1e	frintz	d1, d1
101171d8c:	00 18 61 1e	fdiv	d0, d0, d1
101171d90:	14 00 78 1e	fcvtzs	w20, d0
101171d94:	36 7d 40 92	and	x22, x9, #0xffffffff
101171d98:	57 09 00 d1	sub	x23, x10, #0x2
101171d9c:	f8 03 14 aa	mov	x24, x20
101171da0:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
101171da4:	c9 7e 15 9b	mul	x9, x22, x21
101171da8:	09 69 69 b8	ldr	w9, [x8, x9]
101171dac:	09 03 09 0b	add	w9, w24, w9
101171db0:	e9 bb 03 b9	str	w9, [sp, #0x3b8]
101171db4:	ff e3 01 f9	str	xzr, [sp, #0x3c0]
101171db8:	61 02 08 8b	add	x1, x19, x8
101171dbc:	e2 e3 0e 91	add	x2, sp, #0x3b8
101171dc0:	16 35 ff 97	bl	__ZNSt3__16vectorIN16BeatAnalyzer_2_06peakss8BeatInfoENS_9allocatorIS3_EEE6insertENS_11__wrap_iterIPKS3_EERS8_
101171dc4:	e7 03 1a aa	mov	x7, x26
101171dc8:	b7 01 00 b4	cbz	x23, 0x101171dfc
101171dcc:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
101171dd0:	08 00 40 f9	ldr	x8, [x0]
101171dd4:	18 03 14 0b	add	w24, w24, w20
101171dd8:	73 62 00 91	add	x19, x19, #0x18
101171ddc:	f7 06 00 d1	sub	x23, x23, #0x1
101171de0:	f1 ff ff 17	b	0x101171da4
101171de4:	94 02 18 0b	add	w20, w20, w24
101171de8:	f7 07 40 91	add	x23, sp, #0x1, lsl #12
101171dec:	f7 c2 11 91	add	x23, x23, #0x470
101171df0:	f6 07 40 91	add	x22, sp, #0x1, lsl #12
101171df4:	d6 c2 19 91	add	x22, x22, #0x670
101171df8:	53 ff ff 17	b	0x101171b44
101171dfc:	f7 07 40 91	add	x23, sp, #0x1, lsl #12
101171e00:	f7 c2 11 91	add	x23, x23, #0x470
101171e04:	f6 07 40 91	add	x22, sp, #0x1, lsl #12
101171e08:	d6 c2 19 91	add	x22, x22, #0x670
101171e0c:	f8 d3 50 a9	ldp	x24, x20, [sp, #0x108]
101171e10:	22 19 00 14	b	0x101178298
101171e14:	f6 03 0b aa	mov	x22, x11
101171e18:	e9 a3 40 f9	ldr	x9, [sp, #0x140]
101171e1c:	39 05 00 11	add	w25, w9, #0x1
101171e20:	3f 03 16 6b	cmp	w25, w22
101171e24:	aa 04 00 54	b.ge	0x101171eb8
101171e28:	09 03 80 52	mov	w9, #0x18
101171e2c:	20 23 a9 9b	umaddl	x0, w25, w9, x8
101171e30:	01 60 00 91	add	x1, x0, #0x18
101171e34:	42 03 01 cb	sub	x2, x26, x1
101171e38:	05 82 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
101171e3c:	5a 63 00 d1	sub	x26, x26, #0x18
101171e40:	ea c3 31 91	add	x10, sp, #0xc70
101171e44:	eb 93 40 f9	ldr	x11, [sp, #0x120]
101171e48:	48 69 6b b8	ldr	w8, [x10, x11]
101171e4c:	e9 9b 40 f9	ldr	x9, [sp, #0x130]
101171e50:	3a 01 00 f9	str	x26, [x9]
101171e54:	17 05 00 51	sub	w23, w8, #0x1
101171e58:	57 69 2b b8	str	w23, [x10, x11]
101171e5c:	d4 06 00 51	sub	w20, w22, #0x1
101171e60:	3f 03 14 6b	cmp	w25, w20
101171e64:	ea 02 00 54	b.ge	0x101171ec0
101171e68:	f5 b3 40 f9	ldr	x21, [sp, #0x160]
101171e6c:	f8 9b 40 f9	ldr	x24, [sp, #0x130]
101171e70:	13 03 80 52	mov	w19, #0x18
101171e74:	a8 02 40 f9	ldr	x8, [x21]
101171e78:	20 23 13 9b	madd	x0, x25, x19, x8
101171e7c:	01 60 00 91	add	x1, x0, #0x18
101171e80:	42 03 01 cb	sub	x2, x26, x1
101171e84:	f2 81 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
101171e88:	5a 63 00 d1	sub	x26, x26, #0x18
101171e8c:	1a 03 00 f9	str	x26, [x24]
101171e90:	f7 06 00 51	sub	w23, w23, #0x1
101171e94:	94 06 00 51	sub	w20, w20, #0x1
101171e98:	3f 03 14 6b	cmp	w25, w20
101171e9c:	cb fe ff 54	b.lt	0x101171e74
101171ea0:	f9 c3 31 91	add	x25, sp, #0xc70
101171ea4:	f3 af 40 f9	ldr	x19, [sp, #0x158]
101171ea8:	37 7b 33 b8	str	w23, [x25, x19, lsl #2]
101171eac:	28 00 80 52	mov	w8, #0x1
101171eb0:	e8 23 01 b9	str	w8, [sp, #0x120]
101171eb4:	52 f9 ff 17	b	0x1011703fc
101171eb8:	ff 23 01 b9	str	wzr, [sp, #0x120]
101171ebc:	03 00 00 14	b	0x101171ec8
101171ec0:	28 00 80 52	mov	w8, #0x1
101171ec4:	e8 23 01 b9	str	w8, [sp, #0x120]
101171ec8:	f8 9b 40 f9	ldr	x24, [sp, #0x130]
101171ecc:	f9 c3 31 91	add	x25, sp, #0xc70
101171ed0:	4b f9 ff 17	b	0x1011703fc
101171ed4:	f3 03 0f aa	mov	x19, x15
101171ed8:	54 f6 ff 17	b	0x10116f828
101171edc:	e9 0d 00 91	add	x9, x15, #0x3
101171ee0:	80 7a 69 fc	ldr	d0, [x20, x9, lsl #3]
101171ee4:	ea a3 90 d2	mov	x10, #0x851f
101171ee8:	6a 3d aa f2	movk	x10, #0x51eb, lsl #16
101171eec:	0a d7 c3 f2	movk	x10, #0x1eb8, lsl #32
101171ef0:	2a fe e7 f2	movk	x10, #0x3ff1, lsl #48
101171ef4:	41 01 67 9e	fmov	d1, x10
101171ef8:	00 20 61 1e	fcmp	d0, d1
101171efc:	cd 00 00 54	b.le	0x101171f14
101171f00:	ea e7 02 b2	mov	x10, #-0x3333333333333334
101171f04:	ca fe e7 f2	movk	x10, #0x3ff6, lsl #48
101171f08:	41 01 67 9e	fmov	d1, x10
101171f0c:	00 20 61 1e	fcmp	d0, d1
101171f10:	ab 01 00 54	b.lt	0x101171f44
101171f14:	ea e7 00 b2	mov	x10, #0x3333333333333333
101171f18:	8a 66 86 f2	movk	x10, #0x3334
101171f1c:	2a ff e7 f2	movk	x10, #0x3ff9, lsl #48
101171f20:	41 01 67 9e	fmov	d1, x10
101171f24:	00 20 61 1e	fcmp	d0, d1
101171f28:	ad cf fe 54	b.le	0x10116f91c
101171f2c:	ea e7 02 b2	mov	x10, #-0x3333333333333334
101171f30:	aa 99 99 f2	movk	x10, #0xcccd
101171f34:	8a ff e7 f2	movk	x10, #0x3ffc, lsl #48
101171f38:	41 01 67 9e	fmov	d1, x10
101171f3c:	00 20 61 1e	fcmp	d0, d1
101171f40:	ea ce fe 54	b.ge	0x10116f91c
101171f44:	0a 16 00 51	sub	w10, w16, #0x5
101171f48:	ff 01 0a 6b	cmp	w15, w10
101171f4c:	2c 07 00 54	b.gt	0x101172030
101171f50:	f7 11 00 91	add	x23, x15, #0x4
101171f54:	80 7a 77 fc	ldr	d0, [x20, x23, lsl #3]
101171f58:	ea a3 90 d2	mov	x10, #0x851f
101171f5c:	6a 3d aa f2	movk	x10, #0x51eb, lsl #16
101171f60:	0a d7 c3 f2	movk	x10, #0x1eb8, lsl #32
101171f64:	2a fe e7 f2	movk	x10, #0x3ff1, lsl #48
101171f68:	41 01 67 9e	fmov	d1, x10
101171f6c:	00 20 61 1e	fcmp	d0, d1
101171f70:	cd 00 00 54	b.le	0x101171f88
101171f74:	ea e7 02 b2	mov	x10, #-0x3333333333333334
101171f78:	ca fe e7 f2	movk	x10, #0x3ff6, lsl #48
101171f7c:	41 01 67 9e	fmov	d1, x10
101171f80:	00 20 61 1e	fcmp	d0, d1
101171f84:	ab 01 00 54	b.lt	0x101171fb8
101171f88:	ea e7 00 b2	mov	x10, #0x3333333333333333
101171f8c:	8a 66 86 f2	movk	x10, #0x3334
101171f90:	2a ff e7 f2	movk	x10, #0x3ff9, lsl #48
101171f94:	41 01 67 9e	fmov	d1, x10
101171f98:	00 20 61 1e	fcmp	d0, d1
101171f9c:	ad 04 00 54	b.le	0x101172030
101171fa0:	ea e7 02 b2	mov	x10, #-0x3333333333333334
101171fa4:	aa 99 99 f2	movk	x10, #0xcccd
101171fa8:	8a ff e7 f2	movk	x10, #0x3ffc, lsl #48
101171fac:	41 01 67 9e	fmov	d1, x10
101171fb0:	00 20 61 1e	fcmp	d0, d1
101171fb4:	ea 03 00 54	b.ge	0x101172030
101171fb8:	09 1a 00 51	sub	w9, w16, #0x6
101171fbc:	ff 01 09 6b	cmp	w15, w9
101171fc0:	ac 03 00 54	b.gt	0x101172034
101171fc4:	e9 15 00 91	add	x9, x15, #0x5
101171fc8:	80 7a 69 fc	ldr	d0, [x20, x9, lsl #3]
101171fcc:	ea a3 90 d2	mov	x10, #0x851f
101171fd0:	6a 3d aa f2	movk	x10, #0x51eb, lsl #16
101171fd4:	0a d7 c3 f2	movk	x10, #0x1eb8, lsl #32
101171fd8:	2a fe e7 f2	movk	x10, #0x3ff1, lsl #48
101171fdc:	41 01 67 9e	fmov	d1, x10
101171fe0:	00 20 61 1e	fcmp	d0, d1
101171fe4:	cd 00 00 54	b.le	0x101171ffc
101171fe8:	ea e7 02 b2	mov	x10, #-0x3333333333333334
101171fec:	ca fe e7 f2	movk	x10, #0x3ff6, lsl #48
101171ff0:	41 01 67 9e	fmov	d1, x10
101171ff4:	00 20 61 1e	fcmp	d0, d1
101171ff8:	ab 01 00 54	b.lt	0x10117202c
101171ffc:	ea e7 00 b2	mov	x10, #0x3333333333333333
101172000:	8a 66 86 f2	movk	x10, #0x3334
101172004:	2a ff e7 f2	movk	x10, #0x3ff9, lsl #48
101172008:	41 01 67 9e	fmov	d1, x10
10117200c:	00 20 61 1e	fcmp	d0, d1
101172010:	2d 01 00 54	b.le	0x101172034
101172014:	ea e7 02 b2	mov	x10, #-0x3333333333333334
101172018:	aa 99 99 f2	movk	x10, #0xcccd
10117201c:	8a ff e7 f2	movk	x10, #0x3ffc, lsl #48
101172020:	41 01 67 9e	fmov	d1, x10
101172024:	00 20 61 1e	fcmp	d0, d1
101172028:	6a 00 00 54	b.ge	0x101172034
10117202c:	2e 00 80 52	mov	w14, #0x1
101172030:	f7 03 09 aa	mov	x23, x9
101172034:	8a 05 00 71	subs	w10, w12, #0x1
101172038:	2b 02 00 54	b.lt	0x10117207c
10117203c:	80 5a 6a fc	ldr	d0, [x20, w10, uxtw #3]
101172040:	e9 a3 90 d2	mov	x9, #0x851f
101172044:	69 3d aa f2	movk	x9, #0x51eb, lsl #16
101172048:	09 d7 c3 f2	movk	x9, #0x1eb8, lsl #32
10117204c:	29 fe e7 f2	movk	x9, #0x3ff1, lsl #48
101172050:	21 01 67 9e	fmov	d1, x9
101172054:	00 20 61 1e	fcmp	d0, d1
101172058:	6d 01 00 54	b.le	0x101172084
10117205c:	e9 e7 02 b2	mov	x9, #-0x3333333333333334
101172060:	c9 fe e7 f2	movk	x9, #0x3ff6, lsl #48
101172064:	21 01 67 9e	fmov	d1, x9
101172068:	00 20 61 1e	fcmp	d0, d1
10117206c:	ca 00 00 54	b.ge	0x101172084
101172070:	9f 09 00 71	cmp	w12, #0x2
101172074:	ca 02 00 54	b.ge	0x1011720cc
101172078:	83 00 00 14	b	0x101172284
10117207c:	e9 03 0c aa	mov	x9, x12
101172080:	82 00 00 14	b	0x101172288
101172084:	e9 e7 00 b2	mov	x9, #0x3333333333333333
101172088:	89 66 86 f2	movk	x9, #0x3334
10117208c:	29 ff e7 f2	movk	x9, #0x3ff9, lsl #48
101172090:	21 01 67 9e	fmov	d1, x9
101172094:	00 20 61 1e	fcmp	d0, d1
101172098:	e9 c7 9f 1a	cset	w9, le
10117209c:	eb e7 02 b2	mov	x11, #-0x3333333333333334
1011720a0:	ab 99 99 f2	movk	x11, #0xcccd
1011720a4:	8b ff e7 f2	movk	x11, #0x3ffc, lsl #48
1011720a8:	61 01 67 9e	fmov	d1, x11
1011720ac:	00 20 61 1e	fcmp	d0, d1
1011720b0:	eb b7 9f 1a	cset	w11, ge
1011720b4:	2b 01 0b 2a	orr	w11, w9, w11
1011720b8:	7f 01 00 71	cmp	w11, #0x0
1011720bc:	89 11 9f 1a	csel	w9, w12, wzr, ne
1011720c0:	4b 0e 00 37	tbnz	w11, #0x0, 0x101172288
1011720c4:	9f 09 00 71	cmp	w12, #0x2
1011720c8:	0b 0e 00 54	b.lt	0x101172288
1011720cc:	89 09 00 51	sub	w9, w12, #0x2
1011720d0:	80 5a 69 fc	ldr	d0, [x20, w9, uxtw #3]
1011720d4:	eb a3 90 d2	mov	x11, #0x851f
1011720d8:	6b 3d aa f2	movk	x11, #0x51eb, lsl #16
1011720dc:	0b d7 c3 f2	movk	x11, #0x1eb8, lsl #32
1011720e0:	2b fe e7 f2	movk	x11, #0x3ff1, lsl #48
1011720e4:	61 01 67 9e	fmov	d1, x11
1011720e8:	00 20 61 1e	fcmp	d0, d1
1011720ec:	cd 00 00 54	b.le	0x101172104
1011720f0:	eb e7 02 b2	mov	x11, #-0x3333333333333334
1011720f4:	cb fe e7 f2	movk	x11, #0x3ff6, lsl #48
1011720f8:	61 01 67 9e	fmov	d1, x11
1011720fc:	00 20 61 1e	fcmp	d0, d1
101172100:	ab 01 00 54	b.lt	0x101172134
101172104:	eb e7 00 b2	mov	x11, #0x3333333333333333
101172108:	8b 66 86 f2	movk	x11, #0x3334
10117210c:	2b ff e7 f2	movk	x11, #0x3ff9, lsl #48
101172110:	61 01 67 9e	fmov	d1, x11
101172114:	00 20 61 1e	fcmp	d0, d1
101172118:	2d 0b 00 54	b.le	0x10117227c
10117211c:	eb e7 02 b2	mov	x11, #-0x3333333333333334
101172120:	ab 99 99 f2	movk	x11, #0xcccd
101172124:	8b ff e7 f2	movk	x11, #0x3ffc, lsl #48
101172128:	61 01 67 9e	fmov	d1, x11
10117212c:	00 20 61 1e	fcmp	d0, d1
101172130:	6a 0a 00 54	b.ge	0x10117227c
101172134:	8a 0d 00 71	subs	w10, w12, #0x3
101172138:	63 0a 00 54	b.lo	0x101172284
10117213c:	80 5a 6a fc	ldr	d0, [x20, w10, uxtw #3]
101172140:	eb a3 90 d2	mov	x11, #0x851f
101172144:	6b 3d aa f2	movk	x11, #0x51eb, lsl #16
101172148:	0b d7 c3 f2	movk	x11, #0x1eb8, lsl #32
10117214c:	2b fe e7 f2	movk	x11, #0x3ff1, lsl #48
101172150:	61 01 67 9e	fmov	d1, x11
101172154:	00 20 61 1e	fcmp	d0, d1
101172158:	cd 00 00 54	b.le	0x101172170
10117215c:	eb e7 02 b2	mov	x11, #-0x3333333333333334
101172160:	cb fe e7 f2	movk	x11, #0x3ff6, lsl #48
101172164:	61 01 67 9e	fmov	d1, x11
101172168:	00 20 61 1e	fcmp	d0, d1
10117216c:	ab 01 00 54	b.lt	0x1011721a0
101172170:	eb e7 00 b2	mov	x11, #0x3333333333333333
101172174:	8b 66 86 f2	movk	x11, #0x3334
101172178:	2b ff e7 f2	movk	x11, #0x3ff9, lsl #48
10117217c:	61 01 67 9e	fmov	d1, x11
101172180:	00 20 61 1e	fcmp	d0, d1
101172184:	2d 08 00 54	b.le	0x101172288
101172188:	eb e7 02 b2	mov	x11, #-0x3333333333333334
10117218c:	ab 99 99 f2	movk	x11, #0xcccd
101172190:	8b ff e7 f2	movk	x11, #0x3ffc, lsl #48
101172194:	61 01 67 9e	fmov	d1, x11
101172198:	00 20 61 1e	fcmp	d0, d1
10117219c:	6a 07 00 54	b.ge	0x101172288
1011721a0:	89 11 00 71	subs	w9, w12, #0x4
1011721a4:	03 07 00 54	b.lo	0x101172284
1011721a8:	80 5a 69 fc	ldr	d0, [x20, w9, uxtw #3]
1011721ac:	eb a3 90 d2	mov	x11, #0x851f
1011721b0:	6b 3d aa f2	movk	x11, #0x51eb, lsl #16
1011721b4:	0b d7 c3 f2	movk	x11, #0x1eb8, lsl #32
1011721b8:	2b fe e7 f2	movk	x11, #0x3ff1, lsl #48
1011721bc:	61 01 67 9e	fmov	d1, x11
1011721c0:	00 20 61 1e	fcmp	d0, d1
1011721c4:	cd 00 00 54	b.le	0x1011721dc
1011721c8:	eb e7 02 b2	mov	x11, #-0x3333333333333334
1011721cc:	cb fe e7 f2	movk	x11, #0x3ff6, lsl #48
1011721d0:	61 01 67 9e	fmov	d1, x11
1011721d4:	00 20 61 1e	fcmp	d0, d1
1011721d8:	ab 01 00 54	b.lt	0x10117220c
1011721dc:	eb e7 00 b2	mov	x11, #0x3333333333333333
1011721e0:	8b 66 86 f2	movk	x11, #0x3334
1011721e4:	2b ff e7 f2	movk	x11, #0x3ff9, lsl #48
1011721e8:	61 01 67 9e	fmov	d1, x11
1011721ec:	00 20 61 1e	fcmp	d0, d1
1011721f0:	6d 04 00 54	b.le	0x10117227c
1011721f4:	eb e7 02 b2	mov	x11, #-0x3333333333333334
1011721f8:	ab 99 99 f2	movk	x11, #0xcccd
1011721fc:	8b ff e7 f2	movk	x11, #0x3ffc, lsl #48
101172200:	61 01 67 9e	fmov	d1, x11
101172204:	00 20 61 1e	fcmp	d0, d1
101172208:	aa 03 00 54	b.ge	0x10117227c
10117220c:	8a 15 00 71	subs	w10, w12, #0x5
101172210:	a3 03 00 54	b.lo	0x101172284
101172214:	80 5a 6a fc	ldr	d0, [x20, w10, uxtw #3]
101172218:	eb a3 90 d2	mov	x11, #0x851f
10117221c:	6b 3d aa f2	movk	x11, #0x51eb, lsl #16
101172220:	0b d7 c3 f2	movk	x11, #0x1eb8, lsl #32
101172224:	2b fe e7 f2	movk	x11, #0x3ff1, lsl #48
101172228:	61 01 67 9e	fmov	d1, x11
10117222c:	00 20 61 1e	fcmp	d0, d1
101172230:	cd 00 00 54	b.le	0x101172248
101172234:	eb e7 02 b2	mov	x11, #-0x3333333333333334
101172238:	cb fe e7 f2	movk	x11, #0x3ff6, lsl #48
10117223c:	61 01 67 9e	fmov	d1, x11
101172240:	00 20 61 1e	fcmp	d0, d1
101172244:	ab 01 00 54	b.lt	0x101172278
101172248:	eb e7 00 b2	mov	x11, #0x3333333333333333
10117224c:	8b 66 86 f2	movk	x11, #0x3334
101172250:	2b ff e7 f2	movk	x11, #0x3ff9, lsl #48
101172254:	61 01 67 9e	fmov	d1, x11
101172258:	00 20 61 1e	fcmp	d0, d1
10117225c:	6d 01 00 54	b.le	0x101172288
101172260:	eb e7 02 b2	mov	x11, #-0x3333333333333334
101172264:	ab 99 99 f2	movk	x11, #0xcccd
101172268:	8b ff e7 f2	movk	x11, #0x3ffc, lsl #48
10117226c:	61 01 67 9e	fmov	d1, x11
101172270:	00 20 61 1e	fcmp	d0, d1
101172274:	aa 00 00 54	b.ge	0x101172288
101172278:	2e 00 80 52	mov	w14, #0x1
10117227c:	e9 03 0a aa	mov	x9, x10
101172280:	02 00 00 14	b	0x101172288
101172284:	09 00 80 52	mov	w9, #0x0
101172288:	9f 01 08 6b	cmp	w12, w8
10117228c:	6d 00 00 54	b.le	0x101172298
101172290:	ea 03 0c aa	mov	x10, x12
101172294:	35 0e 00 14	b	0x101175b68
101172298:	8a 05 00 11	add	w10, w12, #0x1
10117229c:	80 da 6a fc	ldr	d0, [x20, w10, sxtw #3]
1011722a0:	e8 a3 90 d2	mov	x8, #0x851f
1011722a4:	68 3d aa f2	movk	x8, #0x51eb, lsl #16
1011722a8:	08 d7 c3 f2	movk	x8, #0x1eb8, lsl #32
1011722ac:	28 fe e7 f2	movk	x8, #0x3ff1, lsl #48
1011722b0:	01 01 67 9e	fmov	d1, x8
1011722b4:	00 20 61 1e	fcmp	d0, d1
1011722b8:	cd 00 00 54	b.le	0x1011722d0
1011722bc:	e8 e7 02 b2	mov	x8, #-0x3333333333333334
1011722c0:	c8 fe e7 f2	movk	x8, #0x3ff6, lsl #48
1011722c4:	01 01 67 9e	fmov	d1, x8
1011722c8:	00 20 61 1e	fcmp	d0, d1
1011722cc:	ab 01 00 54	b.lt	0x101172300
1011722d0:	e8 e7 00 b2	mov	x8, #0x3333333333333333
1011722d4:	88 66 86 f2	movk	x8, #0x3334
1011722d8:	28 ff e7 f2	movk	x8, #0x3ff9, lsl #48
1011722dc:	01 01 67 9e	fmov	d1, x8
1011722e0:	00 20 61 1e	fcmp	d0, d1
1011722e4:	6d fd ff 54	b.le	0x101172290
1011722e8:	e8 e7 02 b2	mov	x8, #-0x3333333333333334
1011722ec:	a8 99 99 f2	movk	x8, #0xcccd
1011722f0:	88 ff e7 f2	movk	x8, #0x3ffc, lsl #48
1011722f4:	01 01 67 9e	fmov	d1, x8
1011722f8:	00 20 61 1e	fcmp	d0, d1
1011722fc:	aa fc ff 54	b.ge	0x101172290
101172300:	08 0e 00 51	sub	w8, w16, #0x3
101172304:	9f 01 08 6b	cmp	w12, w8
101172308:	0c c3 01 54	b.gt	0x101175b68
10117230c:	88 09 00 11	add	w8, w12, #0x2
101172310:	80 da 68 fc	ldr	d0, [x20, w8, sxtw #3]
101172314:	eb a3 90 d2	mov	x11, #0x851f
101172318:	6b 3d aa f2	movk	x11, #0x51eb, lsl #16
10117231c:	0b d7 c3 f2	movk	x11, #0x1eb8, lsl #32
101172320:	2b fe e7 f2	movk	x11, #0x3ff1, lsl #48
101172324:	61 01 67 9e	fmov	d1, x11
101172328:	00 20 61 1e	fcmp	d0, d1
10117232c:	cd 00 00 54	b.le	0x101172344
101172330:	eb e7 02 b2	mov	x11, #-0x3333333333333334
101172334:	cb fe e7 f2	movk	x11, #0x3ff6, lsl #48
101172338:	61 01 67 9e	fmov	d1, x11
10117233c:	00 20 61 1e	fcmp	d0, d1
101172340:	ab 01 00 54	b.lt	0x101172374
101172344:	eb e7 00 b2	mov	x11, #0x3333333333333333
101172348:	8b 66 86 f2	movk	x11, #0x3334
10117234c:	2b ff e7 f2	movk	x11, #0x3ff9, lsl #48
101172350:	61 01 67 9e	fmov	d1, x11
101172354:	00 20 61 1e	fcmp	d0, d1
101172358:	8d c0 01 54	b.le	0x101175b68
10117235c:	eb e7 02 b2	mov	x11, #-0x3333333333333334
101172360:	ab 99 99 f2	movk	x11, #0xcccd
101172364:	8b ff e7 f2	movk	x11, #0x3ffc, lsl #48
101172368:	61 01 67 9e	fmov	d1, x11
10117236c:	00 20 61 1e	fcmp	d0, d1
101172370:	ca bf 01 54	b.ge	0x101175b68
101172374:	0a 12 00 51	sub	w10, w16, #0x4
101172378:	9f 01 0a 6b	cmp	w12, w10
10117237c:	6d 00 00 54	b.le	0x101172388
101172380:	ea 03 08 aa	mov	x10, x8
101172384:	f9 0d 00 14	b	0x101175b68
101172388:	8b 0d 00 11	add	w11, w12, #0x3
10117238c:	80 da 6b fc	ldr	d0, [x20, w11, sxtw #3]
101172390:	ea a3 90 d2	mov	x10, #0x851f
101172394:	6a 3d aa f2	movk	x10, #0x51eb, lsl #16
101172398:	0a d7 c3 f2	movk	x10, #0x1eb8, lsl #32
10117239c:	2a fe e7 f2	movk	x10, #0x3ff1, lsl #48
1011723a0:	41 01 67 9e	fmov	d1, x10
1011723a4:	00 20 61 1e	fcmp	d0, d1
1011723a8:	cd 00 00 54	b.le	0x1011723c0
1011723ac:	ea e7 02 b2	mov	x10, #-0x3333333333333334
1011723b0:	ca fe e7 f2	movk	x10, #0x3ff6, lsl #48
1011723b4:	41 01 67 9e	fmov	d1, x10
1011723b8:	00 20 61 1e	fcmp	d0, d1
1011723bc:	ab 01 00 54	b.lt	0x1011723f0
1011723c0:	ea e7 00 b2	mov	x10, #0x3333333333333333
1011723c4:	8a 66 86 f2	movk	x10, #0x3334
1011723c8:	2a ff e7 f2	movk	x10, #0x3ff9, lsl #48
1011723cc:	41 01 67 9e	fmov	d1, x10
1011723d0:	00 20 61 1e	fcmp	d0, d1
1011723d4:	6d fd ff 54	b.le	0x101172380
1011723d8:	ea e7 02 b2	mov	x10, #-0x3333333333333334
1011723dc:	aa 99 99 f2	movk	x10, #0xcccd
1011723e0:	8a ff e7 f2	movk	x10, #0x3ffc, lsl #48
1011723e4:	41 01 67 9e	fmov	d1, x10
1011723e8:	00 20 61 1e	fcmp	d0, d1
1011723ec:	aa fc ff 54	b.ge	0x101172380
1011723f0:	08 16 00 51	sub	w8, w16, #0x5
1011723f4:	9f 01 08 6b	cmp	w12, w8
1011723f8:	ed b7 01 54	b.le	0x101175af4
1011723fc:	ea 03 0b aa	mov	x10, x11
101172400:	da 0d 00 14	b	0x101175b68
101172404:	0a 16 00 51	sub	w10, w16, #0x5
101172408:	5f 03 0a 6b	cmp	w26, w10
10117240c:	ec 01 00 54	b.gt	0x101172448
101172410:	4a 13 00 91	add	x10, x26, #0x4
101172414:	80 7a 6a fc	ldr	d0, [x20, x10, lsl #3]
101172418:	c1 01 67 9e	fmov	d1, x14
10117241c:	00 20 61 1e	fcmp	d0, d1
101172420:	ec a3 90 d2	mov	x12, #0x851f
101172424:	6c 3d aa f2	movk	x12, #0x51eb, lsl #16
101172428:	0c d7 c3 f2	movk	x12, #0x1eb8, lsl #32
10117242c:	2c fe e7 f2	movk	x12, #0x3ff1, lsl #48
101172430:	81 01 67 9e	fmov	d1, x12
101172434:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
101172438:	8c 2f 02 54	b.gt	0x101176a28
10117243c:	e1 01 67 9e	fmov	d1, x15
101172440:	00 20 61 1e	fcmp	d0, d1
101172444:	2c 2f 02 54	b.gt	0x101176a28
101172448:	fa 03 0b aa	mov	x26, x11
10117244c:	9b fa ff 17	b	0x101170eb8
101172450:	09 16 00 51	sub	w9, w16, #0x5
101172454:	1f 01 09 6b	cmp	w8, w9
101172458:	ec 01 00 54	b.gt	0x101172494
10117245c:	09 11 00 11	add	w9, w8, #0x4
101172460:	80 da 69 fc	ldr	d0, [x20, w9, sxtw #3]
101172464:	c1 01 67 9e	fmov	d1, x14
101172468:	00 20 61 1e	fcmp	d0, d1
10117246c:	eb a3 90 d2	mov	x11, #0x851f
101172470:	6b 3d aa f2	movk	x11, #0x51eb, lsl #16
101172474:	0b d7 c3 f2	movk	x11, #0x1eb8, lsl #32
101172478:	2b fe e7 f2	movk	x11, #0x3ff1, lsl #48
10117247c:	61 01 67 9e	fmov	d1, x11
101172480:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
101172484:	cc 2d 02 54	b.gt	0x101176a3c
101172488:	e1 01 67 9e	fmov	d1, x15
10117248c:	00 20 61 1e	fcmp	d0, d1
101172490:	6c 2d 02 54	b.gt	0x101176a3c
101172494:	e8 03 0c aa	mov	x8, x12
101172498:	07 fb ff 17	b	0x1011710b4
10117249c:	40 13 00 91	add	x0, x26, #0x4
1011724a0:	eb 8b 40 f9	ldr	x11, [sp, #0x110]
1011724a4:	60 79 60 fc	ldr	d0, [x11, x0, lsl #3]
1011724a8:	eb a3 90 d2	mov	x11, #0x851f
1011724ac:	6b 3d aa f2	movk	x11, #0x51eb, lsl #16
1011724b0:	0b d7 c3 f2	movk	x11, #0x1eb8, lsl #32
1011724b4:	2b fe e7 f2	movk	x11, #0x3ff1, lsl #48
1011724b8:	61 01 67 9e	fmov	d1, x11
1011724bc:	00 20 61 1e	fcmp	d0, d1
1011724c0:	cd 00 00 54	b.le	0x1011724d8
1011724c4:	eb e7 02 b2	mov	x11, #-0x3333333333333334
1011724c8:	cb fe e7 f2	movk	x11, #0x3ff6, lsl #48
1011724cc:	61 01 67 9e	fmov	d1, x11
1011724d0:	00 20 61 1e	fcmp	d0, d1
1011724d4:	4b 01 00 54	b.lt	0x1011724fc
1011724d8:	eb e7 00 b2	mov	x11, #0x3333333333333333
1011724dc:	8b 66 86 f2	movk	x11, #0x3334
1011724e0:	2b ff e7 f2	movk	x11, #0x3ff9, lsl #48
1011724e4:	61 01 67 9e	fmov	d1, x11
1011724e8:	00 20 61 1e	fcmp	d0, d1
1011724ec:	ed b7 fe 54	b.le	0x10116fbe8
1011724f0:	81 01 67 9e	fmov	d1, x12
1011724f4:	00 20 61 1e	fcmp	d0, d1
1011724f8:	8a b7 fe 54	b.ge	0x10116fbe8
1011724fc:	0a 1a 00 51	sub	w10, w16, #0x6
101172500:	5f 03 0a 6b	cmp	w26, w10
101172504:	0d 21 02 54	b.le	0x101176924
101172508:	17 03 80 52	mov	w23, #0x18
10117250c:	fa a3 40 f9	ldr	x26, [sp, #0x140]
101172510:	0b 05 00 71	subs	w11, w8, #0x1
101172514:	4b 02 00 54	b.lt	0x10117255c
101172518:	ea 8b 40 f9	ldr	x10, [sp, #0x110]
10117251c:	40 59 6b fc	ldr	d0, [x10, w11, uxtw #3]
101172520:	ea a3 90 d2	mov	x10, #0x851f
101172524:	6a 3d aa f2	movk	x10, #0x51eb, lsl #16
101172528:	0a d7 c3 f2	movk	x10, #0x1eb8, lsl #32
10117252c:	2a fe e7 f2	movk	x10, #0x3ff1, lsl #48
101172530:	41 01 67 9e	fmov	d1, x10
101172534:	00 20 61 1e	fcmp	d0, d1
101172538:	6d 01 00 54	b.le	0x101172564
10117253c:	ea e7 02 b2	mov	x10, #-0x3333333333333334
101172540:	ca fe e7 f2	movk	x10, #0x3ff6, lsl #48
101172544:	41 01 67 9e	fmov	d1, x10
101172548:	00 20 61 1e	fcmp	d0, d1
10117254c:	ca 00 00 54	b.ge	0x101172564
101172550:	1f 09 00 71	cmp	w8, #0x2
101172554:	ca 02 00 54	b.ge	0x1011725ac
101172558:	87 00 00 14	b	0x101172774
10117255c:	ea 03 08 aa	mov	x10, x8
101172560:	86 00 00 14	b	0x101172778
101172564:	ea e7 00 b2	mov	x10, #0x3333333333333333
101172568:	8a 66 86 f2	movk	x10, #0x3334
10117256c:	2a ff e7 f2	movk	x10, #0x3ff9, lsl #48
101172570:	41 01 67 9e	fmov	d1, x10
101172574:	00 20 61 1e	fcmp	d0, d1
101172578:	ea c7 9f 1a	cset	w10, le
10117257c:	ec e7 02 b2	mov	x12, #-0x3333333333333334
101172580:	ac 99 99 f2	movk	x12, #0xcccd
101172584:	8c ff e7 f2	movk	x12, #0x3ffc, lsl #48
101172588:	81 01 67 9e	fmov	d1, x12
10117258c:	00 20 61 1e	fcmp	d0, d1
101172590:	ec b7 9f 1a	cset	w12, ge
101172594:	4c 01 0c 2a	orr	w12, w10, w12
101172598:	9f 01 00 71	cmp	w12, #0x0
10117259c:	0a 11 9f 1a	csel	w10, w8, wzr, ne
1011725a0:	cc 0e 00 37	tbnz	w12, #0x0, 0x101172778
1011725a4:	1f 09 00 71	cmp	w8, #0x2
1011725a8:	8b 0e 00 54	b.lt	0x101172778
1011725ac:	0a 09 00 51	sub	w10, w8, #0x2
1011725b0:	ec 8b 40 f9	ldr	x12, [sp, #0x110]
1011725b4:	80 59 6a fc	ldr	d0, [x12, w10, uxtw #3]
1011725b8:	ec a3 90 d2	mov	x12, #0x851f
1011725bc:	6c 3d aa f2	movk	x12, #0x51eb, lsl #16
1011725c0:	0c d7 c3 f2	movk	x12, #0x1eb8, lsl #32
1011725c4:	2c fe e7 f2	movk	x12, #0x3ff1, lsl #48
1011725c8:	81 01 67 9e	fmov	d1, x12
1011725cc:	00 20 61 1e	fcmp	d0, d1
1011725d0:	cd 00 00 54	b.le	0x1011725e8
1011725d4:	ec e7 02 b2	mov	x12, #-0x3333333333333334
1011725d8:	cc fe e7 f2	movk	x12, #0x3ff6, lsl #48
1011725dc:	81 01 67 9e	fmov	d1, x12
1011725e0:	00 20 61 1e	fcmp	d0, d1
1011725e4:	ab 01 00 54	b.lt	0x101172618
1011725e8:	ec e7 00 b2	mov	x12, #0x3333333333333333
1011725ec:	8c 66 86 f2	movk	x12, #0x3334
1011725f0:	2c ff e7 f2	movk	x12, #0x3ff9, lsl #48
1011725f4:	81 01 67 9e	fmov	d1, x12
1011725f8:	00 20 61 1e	fcmp	d0, d1
1011725fc:	8d 0b 00 54	b.le	0x10117276c
101172600:	ec e7 02 b2	mov	x12, #-0x3333333333333334
101172604:	ac 99 99 f2	movk	x12, #0xcccd
101172608:	8c ff e7 f2	movk	x12, #0x3ffc, lsl #48
10117260c:	81 01 67 9e	fmov	d1, x12
101172610:	00 20 61 1e	fcmp	d0, d1
101172614:	ca 0a 00 54	b.ge	0x10117276c
101172618:	0b 0d 00 71	subs	w11, w8, #0x3
10117261c:	c3 0a 00 54	b.lo	0x101172774
101172620:	ec 8b 40 f9	ldr	x12, [sp, #0x110]
101172624:	80 59 6b fc	ldr	d0, [x12, w11, uxtw #3]
101172628:	ec a3 90 d2	mov	x12, #0x851f
10117262c:	6c 3d aa f2	movk	x12, #0x51eb, lsl #16
101172630:	0c d7 c3 f2	movk	x12, #0x1eb8, lsl #32
101172634:	2c fe e7 f2	movk	x12, #0x3ff1, lsl #48
101172638:	81 01 67 9e	fmov	d1, x12
10117263c:	00 20 61 1e	fcmp	d0, d1
101172640:	cd 00 00 54	b.le	0x101172658
101172644:	ec e7 02 b2	mov	x12, #-0x3333333333333334
101172648:	cc fe e7 f2	movk	x12, #0x3ff6, lsl #48
10117264c:	81 01 67 9e	fmov	d1, x12
101172650:	00 20 61 1e	fcmp	d0, d1
101172654:	ab 01 00 54	b.lt	0x101172688
101172658:	ec e7 00 b2	mov	x12, #0x3333333333333333
10117265c:	8c 66 86 f2	movk	x12, #0x3334
101172660:	2c ff e7 f2	movk	x12, #0x3ff9, lsl #48
101172664:	81 01 67 9e	fmov	d1, x12
101172668:	00 20 61 1e	fcmp	d0, d1
10117266c:	6d 08 00 54	b.le	0x101172778
101172670:	ec e7 02 b2	mov	x12, #-0x3333333333333334
101172674:	ac 99 99 f2	movk	x12, #0xcccd
101172678:	8c ff e7 f2	movk	x12, #0x3ffc, lsl #48
10117267c:	81 01 67 9e	fmov	d1, x12
101172680:	00 20 61 1e	fcmp	d0, d1
101172684:	aa 07 00 54	b.ge	0x101172778
101172688:	0a 11 00 71	subs	w10, w8, #0x4
10117268c:	43 07 00 54	b.lo	0x101172774
101172690:	ec 8b 40 f9	ldr	x12, [sp, #0x110]
101172694:	80 59 6a fc	ldr	d0, [x12, w10, uxtw #3]
101172698:	ec a3 90 d2	mov	x12, #0x851f
10117269c:	6c 3d aa f2	movk	x12, #0x51eb, lsl #16
1011726a0:	0c d7 c3 f2	movk	x12, #0x1eb8, lsl #32
1011726a4:	2c fe e7 f2	movk	x12, #0x3ff1, lsl #48
1011726a8:	81 01 67 9e	fmov	d1, x12
1011726ac:	00 20 61 1e	fcmp	d0, d1
1011726b0:	cd 00 00 54	b.le	0x1011726c8
1011726b4:	ec e7 02 b2	mov	x12, #-0x3333333333333334
1011726b8:	cc fe e7 f2	movk	x12, #0x3ff6, lsl #48
1011726bc:	81 01 67 9e	fmov	d1, x12
1011726c0:	00 20 61 1e	fcmp	d0, d1
1011726c4:	ab 01 00 54	b.lt	0x1011726f8
1011726c8:	ec e7 00 b2	mov	x12, #0x3333333333333333
1011726cc:	8c 66 86 f2	movk	x12, #0x3334
1011726d0:	2c ff e7 f2	movk	x12, #0x3ff9, lsl #48
1011726d4:	81 01 67 9e	fmov	d1, x12
1011726d8:	00 20 61 1e	fcmp	d0, d1
1011726dc:	8d 04 00 54	b.le	0x10117276c
1011726e0:	ec e7 02 b2	mov	x12, #-0x3333333333333334
1011726e4:	ac 99 99 f2	movk	x12, #0xcccd
1011726e8:	8c ff e7 f2	movk	x12, #0x3ffc, lsl #48
1011726ec:	81 01 67 9e	fmov	d1, x12
1011726f0:	00 20 61 1e	fcmp	d0, d1
1011726f4:	ca 03 00 54	b.ge	0x10117276c
1011726f8:	0b 15 00 71	subs	w11, w8, #0x5
1011726fc:	c3 03 00 54	b.lo	0x101172774
101172700:	ec 8b 40 f9	ldr	x12, [sp, #0x110]
101172704:	80 59 6b fc	ldr	d0, [x12, w11, uxtw #3]
101172708:	ec a3 90 d2	mov	x12, #0x851f
10117270c:	6c 3d aa f2	movk	x12, #0x51eb, lsl #16
101172710:	0c d7 c3 f2	movk	x12, #0x1eb8, lsl #32
101172714:	2c fe e7 f2	movk	x12, #0x3ff1, lsl #48
101172718:	81 01 67 9e	fmov	d1, x12
10117271c:	00 20 61 1e	fcmp	d0, d1
101172720:	cd 00 00 54	b.le	0x101172738
101172724:	ec e7 02 b2	mov	x12, #-0x3333333333333334
101172728:	cc fe e7 f2	movk	x12, #0x3ff6, lsl #48
10117272c:	81 01 67 9e	fmov	d1, x12
101172730:	00 20 61 1e	fcmp	d0, d1
101172734:	ab 01 00 54	b.lt	0x101172768
101172738:	ec e7 00 b2	mov	x12, #0x3333333333333333
10117273c:	8c 66 86 f2	movk	x12, #0x3334
101172740:	2c ff e7 f2	movk	x12, #0x3ff9, lsl #48
101172744:	81 01 67 9e	fmov	d1, x12
101172748:	00 20 61 1e	fcmp	d0, d1
10117274c:	6d 01 00 54	b.le	0x101172778
101172750:	ec e7 02 b2	mov	x12, #-0x3333333333333334
101172754:	ac 99 99 f2	movk	x12, #0xcccd
101172758:	8c ff e7 f2	movk	x12, #0x3ffc, lsl #48
10117275c:	81 01 67 9e	fmov	d1, x12
101172760:	00 20 61 1e	fcmp	d0, d1
101172764:	aa 00 00 54	b.ge	0x101172778
101172768:	31 00 80 52	mov	w17, #0x1
10117276c:	ea 03 0b aa	mov	x10, x11
101172770:	02 00 00 14	b	0x101172778
101172774:	0a 00 80 52	mov	w10, #0x0
101172778:	1f 01 09 6b	cmp	w8, w9
10117277c:	8d 00 00 54	b.le	0x10117278c
101172780:	f8 03 00 aa	mov	x24, x0
101172784:	e9 03 08 aa	mov	x9, x8
101172788:	7e 00 00 14	b	0x101172980
10117278c:	09 05 00 11	add	w9, w8, #0x1
101172790:	eb 8b 40 f9	ldr	x11, [sp, #0x110]
101172794:	60 d9 69 fc	ldr	d0, [x11, w9, sxtw #3]
101172798:	eb a3 90 d2	mov	x11, #0x851f
10117279c:	6b 3d aa f2	movk	x11, #0x51eb, lsl #16
1011727a0:	0b d7 c3 f2	movk	x11, #0x1eb8, lsl #32
1011727a4:	2b fe e7 f2	movk	x11, #0x3ff1, lsl #48
1011727a8:	61 01 67 9e	fmov	d1, x11
1011727ac:	00 20 61 1e	fcmp	d0, d1
1011727b0:	cd 00 00 54	b.le	0x1011727c8
1011727b4:	eb e7 02 b2	mov	x11, #-0x3333333333333334
1011727b8:	cb fe e7 f2	movk	x11, #0x3ff6, lsl #48
1011727bc:	61 01 67 9e	fmov	d1, x11
1011727c0:	00 20 61 1e	fcmp	d0, d1
1011727c4:	ab 01 00 54	b.lt	0x1011727f8
1011727c8:	eb e7 00 b2	mov	x11, #0x3333333333333333
1011727cc:	8b 66 86 f2	movk	x11, #0x3334
1011727d0:	2b ff e7 f2	movk	x11, #0x3ff9, lsl #48
1011727d4:	61 01 67 9e	fmov	d1, x11
1011727d8:	00 20 61 1e	fcmp	d0, d1
1011727dc:	2d fd ff 54	b.le	0x101172780
1011727e0:	eb e7 02 b2	mov	x11, #-0x3333333333333334
1011727e4:	ab 99 99 f2	movk	x11, #0xcccd
1011727e8:	8b ff e7 f2	movk	x11, #0x3ffc, lsl #48
1011727ec:	61 01 67 9e	fmov	d1, x11
1011727f0:	00 20 61 1e	fcmp	d0, d1
1011727f4:	6a fc ff 54	b.ge	0x101172780
1011727f8:	f8 03 00 aa	mov	x24, x0
1011727fc:	0b 0e 00 51	sub	w11, w16, #0x3
101172800:	1f 01 0b 6b	cmp	w8, w11
101172804:	ec 0b 00 54	b.gt	0x101172980
101172808:	0b 09 00 11	add	w11, w8, #0x2
10117280c:	ec 8b 40 f9	ldr	x12, [sp, #0x110]
101172810:	80 d9 6b fc	ldr	d0, [x12, w11, sxtw #3]
101172814:	ec a3 90 d2	mov	x12, #0x851f
101172818:	6c 3d aa f2	movk	x12, #0x51eb, lsl #16
10117281c:	0c d7 c3 f2	movk	x12, #0x1eb8, lsl #32
101172820:	2c fe e7 f2	movk	x12, #0x3ff1, lsl #48
101172824:	81 01 67 9e	fmov	d1, x12
101172828:	00 20 61 1e	fcmp	d0, d1
10117282c:	cd 00 00 54	b.le	0x101172844
101172830:	ec e7 02 b2	mov	x12, #-0x3333333333333334
101172834:	cc fe e7 f2	movk	x12, #0x3ff6, lsl #48
101172838:	81 01 67 9e	fmov	d1, x12
10117283c:	00 20 61 1e	fcmp	d0, d1
101172840:	ab 01 00 54	b.lt	0x101172874
101172844:	ec e7 00 b2	mov	x12, #0x3333333333333333
101172848:	8c 66 86 f2	movk	x12, #0x3334
10117284c:	2c ff e7 f2	movk	x12, #0x3ff9, lsl #48
101172850:	81 01 67 9e	fmov	d1, x12
101172854:	00 20 61 1e	fcmp	d0, d1
101172858:	4d 09 00 54	b.le	0x101172980
10117285c:	ec e7 02 b2	mov	x12, #-0x3333333333333334
101172860:	ac 99 99 f2	movk	x12, #0xcccd
101172864:	8c ff e7 f2	movk	x12, #0x3ffc, lsl #48
101172868:	81 01 67 9e	fmov	d1, x12
10117286c:	00 20 61 1e	fcmp	d0, d1
101172870:	8a 08 00 54	b.ge	0x101172980
101172874:	09 12 00 51	sub	w9, w16, #0x4
101172878:	1f 01 09 6b	cmp	w8, w9
10117287c:	6d 00 00 54	b.le	0x101172888
101172880:	e9 03 0b aa	mov	x9, x11
101172884:	3f 00 00 14	b	0x101172980
101172888:	0c 0d 00 11	add	w12, w8, #0x3
10117288c:	e9 8b 40 f9	ldr	x9, [sp, #0x110]
101172890:	20 d9 6c fc	ldr	d0, [x9, w12, sxtw #3]
101172894:	e9 a3 90 d2	mov	x9, #0x851f
101172898:	69 3d aa f2	movk	x9, #0x51eb, lsl #16
10117289c:	09 d7 c3 f2	movk	x9, #0x1eb8, lsl #32
1011728a0:	29 fe e7 f2	movk	x9, #0x3ff1, lsl #48
1011728a4:	21 01 67 9e	fmov	d1, x9
1011728a8:	00 20 61 1e	fcmp	d0, d1
1011728ac:	cd 00 00 54	b.le	0x1011728c4
1011728b0:	e9 e7 02 b2	mov	x9, #-0x3333333333333334
1011728b4:	c9 fe e7 f2	movk	x9, #0x3ff6, lsl #48
1011728b8:	21 01 67 9e	fmov	d1, x9
1011728bc:	00 20 61 1e	fcmp	d0, d1
1011728c0:	ab 01 00 54	b.lt	0x1011728f4
1011728c4:	e9 e7 00 b2	mov	x9, #0x3333333333333333
1011728c8:	89 66 86 f2	movk	x9, #0x3334
1011728cc:	29 ff e7 f2	movk	x9, #0x3ff9, lsl #48
1011728d0:	21 01 67 9e	fmov	d1, x9
1011728d4:	00 20 61 1e	fcmp	d0, d1
1011728d8:	4d fd ff 54	b.le	0x101172880
1011728dc:	e9 e7 02 b2	mov	x9, #-0x3333333333333334
1011728e0:	a9 99 99 f2	movk	x9, #0xcccd
1011728e4:	89 ff e7 f2	movk	x9, #0x3ffc, lsl #48
1011728e8:	21 01 67 9e	fmov	d1, x9
1011728ec:	00 20 61 1e	fcmp	d0, d1
1011728f0:	8a fc ff 54	b.ge	0x101172880
1011728f4:	09 16 00 51	sub	w9, w16, #0x5
1011728f8:	1f 01 09 6b	cmp	w8, w9
1011728fc:	6d 00 00 54	b.le	0x101172908
101172900:	e9 03 0c aa	mov	x9, x12
101172904:	1f 00 00 14	b	0x101172980
101172908:	09 11 00 11	add	w9, w8, #0x4
10117290c:	eb 8b 40 f9	ldr	x11, [sp, #0x110]
101172910:	60 d9 69 fc	ldr	d0, [x11, w9, sxtw #3]
101172914:	eb a3 90 d2	mov	x11, #0x851f
101172918:	6b 3d aa f2	movk	x11, #0x51eb, lsl #16
10117291c:	0b d7 c3 f2	movk	x11, #0x1eb8, lsl #32
101172920:	2b fe e7 f2	movk	x11, #0x3ff1, lsl #48
101172924:	61 01 67 9e	fmov	d1, x11
101172928:	00 20 61 1e	fcmp	d0, d1
10117292c:	cd 00 00 54	b.le	0x101172944
101172930:	eb e7 02 b2	mov	x11, #-0x3333333333333334
101172934:	cb fe e7 f2	movk	x11, #0x3ff6, lsl #48
101172938:	61 01 67 9e	fmov	d1, x11
10117293c:	00 20 61 1e	fcmp	d0, d1
101172940:	ab 01 00 54	b.lt	0x101172974
101172944:	eb e7 00 b2	mov	x11, #0x3333333333333333
101172948:	8b 66 86 f2	movk	x11, #0x3334
10117294c:	2b ff e7 f2	movk	x11, #0x3ff9, lsl #48
101172950:	61 01 67 9e	fmov	d1, x11
101172954:	00 20 61 1e	fcmp	d0, d1
101172958:	4d fd ff 54	b.le	0x101172900
10117295c:	eb e7 02 b2	mov	x11, #-0x3333333333333334
101172960:	ab 99 99 f2	movk	x11, #0xcccd
101172964:	8b ff e7 f2	movk	x11, #0x3ffc, lsl #48
101172968:	61 01 67 9e	fmov	d1, x11
10117296c:	00 20 61 1e	fcmp	d0, d1
101172970:	8a fc ff 54	b.ge	0x101172900
101172974:	0b 1a 00 51	sub	w11, w16, #0x6
101172978:	1f 01 0b 6b	cmp	w8, w11
10117297c:	4d 01 02 54	b.le	0x1011769a4
101172980:	5f 01 00 71	cmp	w10, #0x0
101172984:	5c c1 9f 1a	csel	w28, w10, wzr, gt
101172988:	b9 01 40 f9	ldr	x25, [x13]
10117298c:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
101172990:	08 01 40 f9	ldr	x8, [x8]
101172994:	2a 03 08 cb	sub	x10, x25, x8
101172998:	4a fd 43 93	asr	x10, x10, #3
10117299c:	eb f3 01 b2	mov	x11, #-0x5555555555555556
1011729a0:	6b 55 95 f2	movk	x11, #0xaaab
1011729a4:	4a 7d 0b 9b	mul	x10, x10, x11
1011729a8:	4b 05 00 d1	sub	x11, x10, #0x1
1011729ac:	4c 05 00 51	sub	w12, w10, #0x1
1011729b0:	7f c1 29 eb	cmp	x11, w9, sxtw
1011729b4:	89 31 89 1a	csel	w9, w12, w9, lo
1011729b8:	3f 01 1c 6b	cmp	w9, w28
1011729bc:	e9 93 00 f9	str	x9, [sp, #0x120]
1011729c0:	f1 a7 00 b9	str	w17, [sp, #0xa4]
1011729c4:	fc 6b 00 f9	str	x28, [sp, #0xd0]
1011729c8:	8d 04 00 54	b.le	0x101172a58
1011729cc:	f6 03 0d aa	mov	x22, x13
1011729d0:	33 7d 40 93	sxtw	x19, w9
1011729d4:	20 21 37 9b	smaddl	x0, w9, w23, x8
1011729d8:	01 60 00 91	add	x1, x0, #0x18
1011729dc:	22 03 01 cb	sub	x2, x25, x1
1011729e0:	1b 7f 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
1011729e4:	39 63 00 d1	sub	x25, x25, #0x18
1011729e8:	d9 02 00 f9	str	x25, [x22]
1011729ec:	73 06 00 d1	sub	x19, x19, #0x1
1011729f0:	7f 02 1c eb	cmp	x19, x28
1011729f4:	f5 b3 40 f9	ldr	x21, [sp, #0x160]
1011729f8:	6d 01 00 54	b.le	0x101172a24
1011729fc:	a8 02 40 f9	ldr	x8, [x21]
101172a00:	60 22 17 9b	madd	x0, x19, x23, x8
101172a04:	01 60 00 91	add	x1, x0, #0x18
101172a08:	22 03 01 cb	sub	x2, x25, x1
101172a0c:	10 7f 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
101172a10:	39 63 00 d1	sub	x25, x25, #0x18
101172a14:	d9 02 00 f9	str	x25, [x22]
101172a18:	73 06 00 d1	sub	x19, x19, #0x1
101172a1c:	7f 02 1c eb	cmp	x19, x28
101172a20:	ec fe ff 54	b.gt	0x1011729fc
101172a24:	ed 03 1c aa	mov	x13, x28
101172a28:	1c 03 80 52	mov	w28, #0x18
101172a2c:	a8 02 40 f9	ldr	x8, [x21]
101172a30:	29 03 08 cb	sub	x9, x25, x8
101172a34:	29 fd 43 93	asr	x9, x9, #3
101172a38:	ea f3 01 b2	mov	x10, #-0x5555555555555556
101172a3c:	6a 55 95 f2	movk	x10, #0xaaab
101172a40:	2a 7d 0a 9b	mul	x10, x9, x10
101172a44:	4b 05 00 d1	sub	x11, x10, #0x1
101172a48:	4c 05 00 51	sub	w12, w10, #0x1
101172a4c:	f6 03 0d aa	mov	x22, x13
101172a50:	f3 af 40 f9	ldr	x19, [sp, #0x158]
101172a54:	03 00 00 14	b	0x101172a60
101172a58:	1c 03 80 52	mov	w28, #0x18
101172a5c:	f6 03 09 aa	mov	x22, x9
101172a60:	56 03 00 b9	str	w22, [x26]
101172a64:	9f 02 00 71	cmp	w20, #0x0
101172a68:	89 c2 9f 1a	csel	w9, w20, wzr, gt
101172a6c:	7f c1 38 eb	cmp	x11, w24, sxtw
101172a70:	8b 31 98 1a	csel	w11, w12, w24, lo
101172a74:	f8 03 09 aa	mov	x24, x9
101172a78:	e9 03 0b aa	mov	x9, x11
101172a7c:	3f 01 18 6b	cmp	w9, w24
101172a80:	eb 63 00 f9	str	x11, [sp, #0xc0]
101172a84:	ad 07 00 54	b.le	0x101172b78
101172a88:	34 7d 40 93	sxtw	x20, w9
101172a8c:	20 21 3c 9b	smaddl	x0, w9, w28, x8
101172a90:	01 60 00 91	add	x1, x0, #0x18
101172a94:	22 03 01 cb	sub	x2, x25, x1
101172a98:	ed 7e 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
101172a9c:	39 63 00 d1	sub	x25, x25, #0x18
101172aa0:	e8 9b 40 f9	ldr	x8, [sp, #0x130]
101172aa4:	19 01 00 f9	str	x25, [x8]
101172aa8:	48 03 40 b9	ldr	w8, [x26]
101172aac:	16 05 00 51	sub	w22, w8, #0x1
101172ab0:	56 03 00 b9	str	w22, [x26]
101172ab4:	93 06 00 d1	sub	x19, x20, #0x1
101172ab8:	7f 02 18 eb	cmp	x19, x24
101172abc:	0d 05 00 54	b.le	0x101172b5c
101172ac0:	88 06 14 8b	add	x8, x20, x20, lsl #1
101172ac4:	17 f1 7d d3	lsl	x23, x8, #3
101172ac8:	e8 02 80 92	mov	x8, #-0x18
101172acc:	94 7e 08 9b	mul	x20, x20, x8
101172ad0:	f5 b3 40 f9	ldr	x21, [sp, #0x160]
101172ad4:	fc 9b 40 f9	ldr	x28, [sp, #0x130]
101172ad8:	fa 03 18 aa	mov	x26, x24
101172adc:	b8 02 40 f9	ldr	x24, [x21]
101172ae0:	28 03 18 cb	sub	x8, x25, x24
101172ae4:	82 02 08 8b	add	x2, x20, x8
101172ae8:	e8 f3 01 b2	mov	x8, #-0x5555555555555556
101172aec:	68 55 95 f2	movk	x8, #0xaaab
101172af0:	48 55 e5 f2	movk	x8, #0x2aaa, lsl #48
101172af4:	48 7c 48 9b	smulh	x8, x2, x8
101172af8:	09 fd 42 93	asr	x9, x8, #2
101172afc:	3b fd 48 8b	add	x27, x9, x8, lsr #63
101172b00:	01 03 17 8b	add	x1, x24, x23
101172b04:	20 60 00 d1	sub	x0, x1, #0x18
101172b08:	d1 7e 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
101172b0c:	08 03 80 52	mov	w8, #0x18
101172b10:	68 5f 08 9b	madd	x8, x27, x8, x23
101172b14:	08 03 08 8b	add	x8, x24, x8
101172b18:	19 61 00 d1	sub	x25, x8, #0x18
101172b1c:	99 03 00 f9	str	x25, [x28]
101172b20:	d6 06 00 51	sub	w22, w22, #0x1
101172b24:	73 06 00 d1	sub	x19, x19, #0x1
101172b28:	f7 62 00 d1	sub	x23, x23, #0x18
101172b2c:	94 62 00 91	add	x20, x20, #0x18
101172b30:	7f 02 1a eb	cmp	x19, x26
101172b34:	4c fd ff 54	b.gt	0x101172adc
101172b38:	e9 a3 40 f9	ldr	x9, [sp, #0x140]
101172b3c:	36 01 00 b9	str	w22, [x9]
101172b40:	1c 03 80 52	mov	w28, #0x18
101172b44:	08 03 80 52	mov	w8, #0x18
101172b48:	68 63 08 9b	madd	x8, x27, x8, x24
101172b4c:	19 01 14 cb	sub	x25, x8, x20
101172b50:	fb 9f 40 f9	ldr	x27, [sp, #0x138]
101172b54:	f8 03 1a aa	mov	x24, x26
101172b58:	fa 03 09 aa	mov	x26, x9
101172b5c:	f3 a3 55 a9	ldp	x19, x8, [sp, #0x158]
101172b60:	08 01 40 f9	ldr	x8, [x8]
101172b64:	29 03 08 cb	sub	x9, x25, x8
101172b68:	29 fd 43 d3	lsr	x9, x9, #3
101172b6c:	6a 55 95 52	mov	w10, #0xaaab
101172b70:	4a 55 b5 72	movk	w10, #0xaaaa, lsl #16
101172b74:	2a 7d 0a 1b	mul	w10, w9, w10
101172b78:	e9 07 40 91	add	x9, sp, #0x1, lsl #12
101172b7c:	29 c1 19 91	add	x9, x9, #0x670
101172b80:	38 79 33 b8	str	w24, [x9, x19, lsl #2]
101172b84:	49 01 18 6b	subs	w9, w10, w24
101172b88:	f8 67 00 f9	str	x24, [sp, #0xc8]
101172b8c:	2d 09 00 54	b.le	0x101172cb0
101172b90:	4a 15 00 51	sub	w10, w10, #0x5
101172b94:	1f 03 0a 6b	cmp	w24, w10
101172b98:	aa 00 80 52	mov	w10, #0x5
101172b9c:	29 c1 8a 1a	csel	w9, w9, w10, gt
101172ba0:	3f 05 00 71	cmp	w9, #0x1
101172ba4:	6b 08 00 54	b.lt	0x101172cb0
101172ba8:	0b 03 80 52	mov	w11, #0x18
101172bac:	0a 7f ab 9b	umull	x10, w24, w11
101172bb0:	00 69 6a bc	ldr	s0, [x8, x10]
101172bb4:	00 a4 20 0f	sshll.2d	v0, v0, #0x0
101172bb8:	00 d8 61 5e	scvtf	d0, d0
101172bbc:	61 03 40 bd	ldr	s1, [x27]
101172bc0:	21 a4 20 0f	sshll.2d	v1, v1, #0x0
101172bc4:	23 d8 61 5e	scvtf	d3, d1
101172bc8:	01 18 63 1e	fdiv	d1, d0, d3
101172bcc:	29 7d 40 93	sxtw	x9, w9
101172bd0:	e0 7f 40 fd	ldr	d0, [sp, #0xf8]
101172bd4:	22 28 60 1e	fadd	d2, d1, d0
101172bd8:	a0 19 63 1e	fdiv	d0, d13, d3
101172bdc:	0a 07 00 91	add	x10, x24, #0x1
101172be0:	1c 03 80 52	mov	w28, #0x18
101172be4:	0b 23 0b 9b	madd	x11, x24, x11, x8
101172be8:	6b 61 00 91	add	x11, x11, #0x18
101172bec:	ec 03 0b aa	mov	x12, x11
101172bf0:	f4 03 0a aa	mov	x20, x10
101172bf4:	ed 03 09 aa	mov	x13, x9
101172bf8:	83 01 40 bd	ldr	s3, [x12]
101172bfc:	63 a4 20 0f	sshll.2d	v3, v3, #0x0
101172c00:	63 d8 61 5e	scvtf	d3, d3
101172c04:	63 08 60 1e	fmul	d3, d3, d0
101172c08:	64 38 69 1e	fsub	d4, d3, d9
101172c0c:	63 28 69 1e	fadd	d3, d3, d9
101172c10:	40 20 64 1e	fcmp	d2, d4
101172c14:	40 c4 63 1e	fccmp	d2, d3, #0x0, gt
101172c18:	ab 22 00 54	b.lt	0x10117306c
101172c1c:	94 06 00 91	add	x20, x20, #0x1
101172c20:	8c 61 00 91	add	x12, x12, #0x18
101172c24:	ad 05 00 f1	subs	x13, x13, #0x1
101172c28:	81 fe ff 54	b.ne	0x101172bf8
101172c2c:	e2 5f 40 fd	ldr	d2, [sp, #0xb8]
101172c30:	22 28 62 1e	fadd	d2, d1, d2
101172c34:	ec 03 0b aa	mov	x12, x11
101172c38:	f4 03 0a aa	mov	x20, x10
101172c3c:	ed 03 09 aa	mov	x13, x9
101172c40:	83 01 40 bd	ldr	s3, [x12]
101172c44:	63 a4 20 0f	sshll.2d	v3, v3, #0x0
101172c48:	63 d8 61 5e	scvtf	d3, d3
101172c4c:	63 08 60 1e	fmul	d3, d3, d0
101172c50:	64 38 69 1e	fsub	d4, d3, d9
101172c54:	63 28 69 1e	fadd	d3, d3, d9
101172c58:	40 20 64 1e	fcmp	d2, d4
101172c5c:	40 c4 63 1e	fccmp	d2, d3, #0x0, gt
101172c60:	6b 20 00 54	b.lt	0x10117306c
101172c64:	94 06 00 91	add	x20, x20, #0x1
101172c68:	8c 61 00 91	add	x12, x12, #0x18
101172c6c:	ad 05 00 f1	subs	x13, x13, #0x1
101172c70:	81 fe ff 54	b.ne	0x101172c40
101172c74:	e2 3f 40 fd	ldr	d2, [sp, #0x78]
101172c78:	21 28 62 1e	fadd	d1, d1, d2
101172c7c:	62 01 40 bd	ldr	s2, [x11]
101172c80:	42 a4 20 0f	sshll.2d	v2, v2, #0x0
101172c84:	42 d8 61 5e	scvtf	d2, d2
101172c88:	42 08 60 1e	fmul	d2, d2, d0
101172c8c:	43 38 69 1e	fsub	d3, d2, d9
101172c90:	42 28 69 1e	fadd	d2, d2, d9
101172c94:	20 20 63 1e	fcmp	d1, d3
101172c98:	20 c4 62 1e	fccmp	d1, d2, #0x0, gt
101172c9c:	6b 1e 00 54	b.lt	0x101173068
101172ca0:	4a 05 00 91	add	x10, x10, #0x1
101172ca4:	6b 61 00 91	add	x11, x11, #0x18
101172ca8:	29 05 00 f1	subs	x9, x9, #0x1
101172cac:	81 fe ff 54	b.ne	0x101172c7c
101172cb0:	ff 03 01 b9	str	wzr, [sp, #0x100]
101172cb4:	e9 93 40 f9	ldr	x9, [sp, #0x120]
101172cb8:	d4 06 00 71	subs	w20, w22, #0x1
101172cbc:	8b 22 00 54	b.lt	0x10117310c
101172cc0:	ea 03 16 2a	mov	w10, w22
101172cc4:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
101172cc8:	08 01 40 f9	ldr	x8, [x8]
101172ccc:	cc 22 bc 9b	umaddl	x12, w22, w28, x8
101172cd0:	80 01 40 bd	ldr	s0, [x12]
101172cd4:	00 a4 20 0f	sshll.2d	v0, v0, #0x0
101172cd8:	00 d8 61 5e	scvtf	d0, d0
101172cdc:	61 03 40 bd	ldr	s1, [x27]
101172ce0:	21 a4 20 0f	sshll.2d	v1, v1, #0x0
101172ce4:	21 d8 61 5e	scvtf	d1, d1
101172ce8:	00 18 61 1e	fdiv	d0, d0, d1
101172cec:	df 16 00 71	cmp	w22, #0x5
101172cf0:	a9 00 80 52	mov	w9, #0x5
101172cf4:	cb b2 89 1a	csel	w11, w22, w9, lt
101172cf8:	e2 7f 40 fd	ldr	d2, [sp, #0xf8]
101172cfc:	02 38 62 1e	fsub	d2, d0, d2
101172d00:	49 05 00 d1	sub	x9, x10, #0x1
101172d04:	83 81 5e bc	ldur	s3, [x12, #-0x18]
101172d08:	63 a4 20 0f	sshll.2d	v3, v3, #0x0
101172d0c:	63 d8 61 5e	scvtf	d3, d3
101172d10:	63 18 61 1e	fdiv	d3, d3, d1
101172d14:	64 38 69 1e	fsub	d4, d3, d9
101172d18:	63 28 69 1e	fadd	d3, d3, d9
101172d1c:	40 20 64 1e	fcmp	d2, d4
101172d20:	40 c4 63 1e	fccmp	d2, d3, #0x0, gt
101172d24:	f8 03 09 aa	mov	x24, x9
101172d28:	0b 0c 00 54	b.lt	0x101172ea8
101172d2c:	6b 05 00 11	add	w11, w11, #0x1
101172d30:	7f 09 00 71	cmp	w11, #0x2
101172d34:	01 05 00 54	b.ne	0x101172dd4
101172d38:	e2 5f 40 fd	ldr	d2, [sp, #0xb8]
101172d3c:	02 38 62 1e	fsub	d2, d0, d2
101172d40:	6b 05 00 d1	sub	x11, x11, #0x1
101172d44:	4a 21 1c 9b	madd	x10, x10, x28, x8
101172d48:	4a 61 00 d1	sub	x10, x10, #0x18
101172d4c:	ec 03 0a aa	mov	x12, x10
101172d50:	f8 03 09 aa	mov	x24, x9
101172d54:	ed 03 0b aa	mov	x13, x11
101172d58:	a1 19 61 1e	fdiv	d1, d13, d1
101172d5c:	83 01 40 bd	ldr	s3, [x12]
101172d60:	63 a4 20 0f	sshll.2d	v3, v3, #0x0
101172d64:	63 d8 61 5e	scvtf	d3, d3
101172d68:	63 08 61 1e	fmul	d3, d3, d1
101172d6c:	64 38 69 1e	fsub	d4, d3, d9
101172d70:	63 28 69 1e	fadd	d3, d3, d9
101172d74:	40 20 64 1e	fcmp	d2, d4
101172d78:	40 c4 63 1e	fccmp	d2, d3, #0x0, gt
101172d7c:	6b 09 00 54	b.lt	0x101172ea8
101172d80:	18 07 00 d1	sub	x24, x24, #0x1
101172d84:	8c 61 00 d1	sub	x12, x12, #0x18
101172d88:	ad 05 00 d1	sub	x13, x13, #0x1
101172d8c:	8d fe ff b5	cbnz	x13, 0x101172d5c
101172d90:	e2 3f 40 fd	ldr	d2, [sp, #0x78]
101172d94:	00 38 62 1e	fsub	d0, d0, d2
101172d98:	42 01 40 bd	ldr	s2, [x10]
101172d9c:	42 a4 20 0f	sshll.2d	v2, v2, #0x0
101172da0:	42 d8 61 5e	scvtf	d2, d2
101172da4:	42 08 61 1e	fmul	d2, d2, d1
101172da8:	43 38 69 1e	fsub	d3, d2, d9
101172dac:	42 28 69 1e	fadd	d2, d2, d9
101172db0:	00 20 63 1e	fcmp	d0, d3
101172db4:	00 c4 62 1e	fccmp	d0, d2, #0x0, gt
101172db8:	6b 07 00 54	b.lt	0x101172ea4
101172dbc:	29 05 00 d1	sub	x9, x9, #0x1
101172dc0:	4a 61 00 d1	sub	x10, x10, #0x18
101172dc4:	6b 05 00 d1	sub	x11, x11, #0x1
101172dc8:	8b fe ff b5	cbnz	x11, 0x101172d98
101172dcc:	f8 03 16 aa	mov	x24, x22
101172dd0:	36 00 00 14	b	0x101172ea8
101172dd4:	58 09 00 d1	sub	x24, x10, #0x2
101172dd8:	0c 7f 1c 9b	mul	x12, x24, x28
101172ddc:	03 69 6c bc	ldr	s3, [x8, x12]
101172de0:	63 a4 20 0f	sshll.2d	v3, v3, #0x0
101172de4:	63 d8 61 5e	scvtf	d3, d3
101172de8:	63 18 61 1e	fdiv	d3, d3, d1
101172dec:	64 38 69 1e	fsub	d4, d3, d9
101172df0:	63 28 69 1e	fadd	d3, d3, d9
101172df4:	40 20 64 1e	fcmp	d2, d4
101172df8:	40 c4 63 1e	fccmp	d2, d3, #0x0, gt
101172dfc:	6b 05 00 54	b.lt	0x101172ea8
101172e00:	7f 0d 00 71	cmp	w11, #0x3
101172e04:	a0 f9 ff 54	b.eq	0x101172d38
101172e08:	58 0d 00 d1	sub	x24, x10, #0x3
101172e0c:	0c 7f 1c 9b	mul	x12, x24, x28
101172e10:	03 69 6c bc	ldr	s3, [x8, x12]
101172e14:	63 a4 20 0f	sshll.2d	v3, v3, #0x0
101172e18:	63 d8 61 5e	scvtf	d3, d3
101172e1c:	63 18 61 1e	fdiv	d3, d3, d1
101172e20:	64 38 69 1e	fsub	d4, d3, d9
101172e24:	63 28 69 1e	fadd	d3, d3, d9
101172e28:	40 20 64 1e	fcmp	d2, d4
101172e2c:	40 c4 63 1e	fccmp	d2, d3, #0x0, gt
101172e30:	cb 03 00 54	b.lt	0x101172ea8
101172e34:	7f 11 00 71	cmp	w11, #0x4
101172e38:	00 f8 ff 54	b.eq	0x101172d38
101172e3c:	58 11 00 d1	sub	x24, x10, #0x4
101172e40:	0c 7f 1c 9b	mul	x12, x24, x28
101172e44:	03 69 6c bc	ldr	s3, [x8, x12]
101172e48:	63 a4 20 0f	sshll.2d	v3, v3, #0x0
101172e4c:	63 d8 61 5e	scvtf	d3, d3
101172e50:	63 18 61 1e	fdiv	d3, d3, d1
101172e54:	64 38 69 1e	fsub	d4, d3, d9
101172e58:	63 28 69 1e	fadd	d3, d3, d9
101172e5c:	40 20 64 1e	fcmp	d2, d4
101172e60:	40 c4 63 1e	fccmp	d2, d3, #0x0, gt
101172e64:	2b 02 00 54	b.lt	0x101172ea8
101172e68:	7f 15 00 71	cmp	w11, #0x5
101172e6c:	60 f6 ff 54	b.eq	0x101172d38
101172e70:	58 15 00 d1	sub	x24, x10, #0x5
101172e74:	0c 7f 1c 9b	mul	x12, x24, x28
101172e78:	03 69 6c bc	ldr	s3, [x8, x12]
101172e7c:	63 a4 20 0f	sshll.2d	v3, v3, #0x0
101172e80:	63 d8 61 5e	scvtf	d3, d3
101172e84:	63 18 61 1e	fdiv	d3, d3, d1
101172e88:	64 38 69 1e	fsub	d4, d3, d9
101172e8c:	40 20 64 1e	fcmp	d2, d4
101172e90:	4d f5 ff 54	b.le	0x101172d38
101172e94:	63 28 69 1e	fadd	d3, d3, d9
101172e98:	40 20 63 1e	fcmp	d2, d3
101172e9c:	6b 00 00 54	b.lt	0x101172ea8
101172ea0:	a6 ff ff 17	b	0x101172d38
101172ea4:	f8 03 09 aa	mov	x24, x9
101172ea8:	9f 02 18 6b	cmp	w20, w24
101172eac:	e9 d7 9f 1a	cset	w9, gt
101172eb0:	e9 77 00 b9	str	w9, [sp, #0x74]
101172eb4:	ed 03 00 54	b.le	0x101172f30
101172eb8:	80 22 3c 9b	smaddl	x0, w20, w28, x8
101172ebc:	01 60 00 91	add	x1, x0, #0x18
101172ec0:	22 03 01 cb	sub	x2, x25, x1
101172ec4:	e2 7d 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
101172ec8:	39 63 00 d1	sub	x25, x25, #0x18
101172ecc:	e8 9b 40 f9	ldr	x8, [sp, #0x130]
101172ed0:	19 01 00 f9	str	x25, [x8]
101172ed4:	08 07 00 11	add	w8, w24, #0x1
101172ed8:	1f 01 14 6b	cmp	w8, w20
101172edc:	60 02 00 54	b.eq	0x101172f28
101172ee0:	94 7e 40 93	sxtw	x20, w20
101172ee4:	d3 0a 00 51	sub	w19, w22, #0x2
101172ee8:	f5 b3 40 f9	ldr	x21, [sp, #0x160]
101172eec:	f6 9b 40 f9	ldr	x22, [sp, #0x130]
101172ef0:	17 03 80 52	mov	w23, #0x18
101172ef4:	a8 02 40 f9	ldr	x8, [x21]
101172ef8:	80 22 17 9b	madd	x0, x20, x23, x8
101172efc:	01 60 00 91	add	x1, x0, #0x18
101172f00:	22 03 01 cb	sub	x2, x25, x1
101172f04:	d2 7d 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
101172f08:	39 63 00 d1	sub	x25, x25, #0x18
101172f0c:	d9 02 00 f9	str	x25, [x22]
101172f10:	73 06 00 51	sub	w19, w19, #0x1
101172f14:	1f 03 13 6b	cmp	w24, w19
101172f18:	e1 fe ff 54	b.ne	0x101172ef4
101172f1c:	1c 03 80 52	mov	w28, #0x18
101172f20:	74 06 00 11	add	w20, w19, #0x1
101172f24:	f3 af 40 f9	ldr	x19, [sp, #0x158]
101172f28:	54 03 00 b9	str	w20, [x26]
101172f2c:	f6 03 14 aa	mov	x22, x20
101172f30:	ea f3 01 b2	mov	x10, #-0x5555555555555556
101172f34:	6a 55 95 f2	movk	x10, #0xaaab
101172f38:	e9 93 40 f9	ldr	x9, [sp, #0x120]
101172f3c:	e8 07 40 91	add	x8, sp, #0x1, lsl #12
101172f40:	08 c1 19 91	add	x8, x8, #0x670
101172f44:	08 79 73 b8	ldr	w8, [x8, x19, lsl #2]
101172f48:	08 05 00 11	add	w8, w8, #0x1
101172f4c:	1f 01 16 6b	cmp	w8, w22
101172f50:	8a 08 00 54	b.ge	0x101173060
101172f54:	14 7d 40 93	sxtw	x20, w8
101172f58:	88 c6 28 8b	add	x8, x20, w8, sxtw #1
101172f5c:	08 f1 7d d3	lsl	x8, x8, #3
101172f60:	18 c1 00 91	add	x24, x8, #0x30
101172f64:	e9 05 80 92	mov	x9, #-0x30
101172f68:	3b 01 08 cb	sub	x27, x9, x8
101172f6c:	12 00 00 14	b	0x101172fb4
101172f70:	e9 02 08 cb	sub	x9, x23, x8
101172f74:	09 03 09 8b	add	x9, x24, x9
101172f78:	21 01 08 8b	add	x1, x9, x8
101172f7c:	22 03 01 cb	sub	x2, x25, x1
101172f80:	20 60 00 d1	sub	x0, x1, #0x18
101172f84:	b2 7d 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
101172f88:	ea f3 01 b2	mov	x10, #-0x5555555555555556
101172f8c:	6a 55 95 f2	movk	x10, #0xaaab
101172f90:	39 63 00 d1	sub	x25, x25, #0x18
101172f94:	e8 9b 40 f9	ldr	x8, [sp, #0x130]
101172f98:	19 01 00 f9	str	x25, [x8]
101172f9c:	d6 06 00 51	sub	w22, w22, #0x1
101172fa0:	56 03 00 b9	str	w22, [x26]
101172fa4:	18 63 00 91	add	x24, x24, #0x18
101172fa8:	7b 63 00 d1	sub	x27, x27, #0x18
101172fac:	9f c2 36 eb	cmp	x20, w22, sxtw
101172fb0:	4a 05 00 54	b.ge	0x101173058
101172fb4:	f5 b3 40 f9	ldr	x21, [sp, #0x160]
101172fb8:	b7 02 40 f9	ldr	x23, [x21]
101172fbc:	94 06 00 91	add	x20, x20, #0x1
101172fc0:	28 03 17 cb	sub	x8, x25, x23
101172fc4:	09 fd 43 93	asr	x9, x8, #3
101172fc8:	29 7d 0a 9b	mul	x9, x9, x10
101172fcc:	3f 01 14 eb	cmp	x9, x20
101172fd0:	c9 03 00 54	b.ls	0x101173048
101172fd4:	62 03 08 8b	add	x2, x27, x8
101172fd8:	e8 f3 01 b2	mov	x8, #-0x5555555555555556
101172fdc:	68 55 95 f2	movk	x8, #0xaaab
101172fe0:	48 55 e5 f2	movk	x8, #0x2aaa, lsl #48
101172fe4:	48 7c 48 9b	smulh	x8, x2, x8
101172fe8:	09 fd 42 93	asr	x9, x8, #2
101172fec:	33 fd 48 8b	add	x19, x9, x8, lsr #63
101172ff0:	e1 02 18 8b	add	x1, x23, x24
101172ff4:	20 60 00 d1	sub	x0, x1, #0x18
101172ff8:	95 7d 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
101172ffc:	ea f3 01 b2	mov	x10, #-0x5555555555555556
101173000:	6a 55 95 f2	movk	x10, #0xaaab
101173004:	69 5e 1c 9b	madd	x9, x19, x28, x23
101173008:	f3 af 40 f9	ldr	x19, [sp, #0x158]
10117300c:	28 01 18 8b	add	x8, x9, x24
101173010:	19 61 00 d1	sub	x25, x8, #0x18
101173014:	e8 9b 40 f9	ldr	x8, [sp, #0x130]
101173018:	19 01 00 f9	str	x25, [x8]
10117301c:	d6 06 00 51	sub	w22, w22, #0x1
101173020:	56 03 00 b9	str	w22, [x26]
101173024:	a8 02 40 f9	ldr	x8, [x21]
101173028:	29 01 08 cb	sub	x9, x9, x8
10117302c:	09 03 09 8b	add	x9, x24, x9
101173030:	29 61 00 d1	sub	x9, x9, #0x18
101173034:	29 fd 43 93	asr	x9, x9, #3
101173038:	29 7d 0a 9b	mul	x9, x9, x10
10117303c:	3f 01 14 eb	cmp	x9, x20
101173040:	29 fb ff 54	b.ls	0x101172fa4
101173044:	cb ff ff 17	b	0x101172f70
101173048:	e8 03 17 aa	mov	x8, x23
10117304c:	3f 01 14 eb	cmp	x9, x20
101173050:	a9 fa ff 54	b.ls	0x101172fa4
101173054:	c7 ff ff 17	b	0x101172f70
101173058:	fb 9f 40 f9	ldr	x27, [sp, #0x138]
10117305c:	e9 93 40 f9	ldr	x9, [sp, #0x120]
101173060:	ec 77 40 b9	ldr	w12, [sp, #0x74]
101173064:	2b 00 00 14	b	0x101173110
101173068:	f4 03 0a aa	mov	x20, x10
10117306c:	13 07 00 11	add	w19, w24, #0x1
101173070:	7f 02 14 6b	cmp	w19, w20
101173074:	2a 04 00 54	b.ge	0x1011730f8
101173078:	60 22 bc 9b	umaddl	x0, w19, w28, x8
10117307c:	01 60 00 91	add	x1, x0, #0x18
101173080:	22 03 01 cb	sub	x2, x25, x1
101173084:	72 7d 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
101173088:	39 63 00 d1	sub	x25, x25, #0x18
10117308c:	e8 9b 40 f9	ldr	x8, [sp, #0x130]
101173090:	19 01 00 f9	str	x25, [x8]
101173094:	48 03 40 b9	ldr	w8, [x26]
101173098:	16 05 00 51	sub	w22, w8, #0x1
10117309c:	56 03 00 b9	str	w22, [x26]
1011730a0:	94 06 00 51	sub	w20, w20, #0x1
1011730a4:	7f 02 14 6b	cmp	w19, w20
1011730a8:	2a 02 00 54	b.ge	0x1011730ec
1011730ac:	f5 b3 40 f9	ldr	x21, [sp, #0x160]
1011730b0:	f7 9b 40 f9	ldr	x23, [sp, #0x130]
1011730b4:	18 03 80 52	mov	w24, #0x18
1011730b8:	a8 02 40 f9	ldr	x8, [x21]
1011730bc:	60 22 18 9b	madd	x0, x19, x24, x8
1011730c0:	01 60 00 91	add	x1, x0, #0x18
1011730c4:	22 03 01 cb	sub	x2, x25, x1
1011730c8:	61 7d 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
1011730cc:	39 63 00 d1	sub	x25, x25, #0x18
1011730d0:	f9 02 00 f9	str	x25, [x23]
1011730d4:	d6 06 00 51	sub	w22, w22, #0x1
1011730d8:	94 06 00 51	sub	w20, w20, #0x1
1011730dc:	7f 02 14 6b	cmp	w19, w20
1011730e0:	cb fe ff 54	b.lt	0x1011730b8
1011730e4:	1c 03 80 52	mov	w28, #0x18
1011730e8:	56 03 00 b9	str	w22, [x26]
1011730ec:	28 00 80 52	mov	w8, #0x1
1011730f0:	e8 03 01 b9	str	w8, [sp, #0x100]
1011730f4:	02 00 00 14	b	0x1011730fc
1011730f8:	ff 03 01 b9	str	wzr, [sp, #0x100]
1011730fc:	f3 af 40 f9	ldr	x19, [sp, #0x158]
101173100:	e9 93 40 f9	ldr	x9, [sp, #0x120]
101173104:	d4 06 00 71	subs	w20, w22, #0x1
101173108:	ca dd ff 54	b.ge	0x101172cc0
10117310c:	0c 00 80 52	mov	w12, #0x0
101173110:	e8 6b 40 f9	ldr	x8, [sp, #0xd0]
101173114:	3f 01 08 6b	cmp	w9, w8
101173118:	e9 d7 9f 1a	cset	w9, gt
10117311c:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
101173120:	08 01 40 f9	ldr	x8, [x8]
101173124:	2a 03 08 cb	sub	x10, x25, x8
101173128:	4a fd 43 d3	lsr	x10, x10, #3
10117312c:	6b 55 95 52	mov	w11, #0xaaab
101173130:	4b 55 b5 72	movk	w11, #0xaaaa, lsl #16
101173134:	58 7d 0b 1b	mul	w24, w10, w11
101173138:	ff ef 01 f9	str	xzr, [sp, #0x3d8]
10117313c:	ff eb 01 f9	str	xzr, [sp, #0x3d0]
101173140:	0a 00 80 12	mov	w10, #-0x1
101173144:	ea e3 03 b9	str	w10, [sp, #0x3e0]
101173148:	ff 93 0f 39	strb	wzr, [sp, #0x3e4]
10117314c:	39 01 0c 2a	orr	w25, w9, w12
101173150:	09 07 00 51	sub	w9, w24, #0x1
101173154:	df 02 09 6b	cmp	w22, w9
101173158:	e9 17 9f 1a	cset	w9, eq
10117315c:	3f 03 00 72	tst	w25, #0x1
101173160:	2a 00 80 52	mov	w10, #0x1
101173164:	49 11 89 1a	csel	w9, w10, w9, ne
101173168:	eb 2b 4c a9	ldp	x11, x10, [sp, #0xc0]
10117316c:	7f 01 0a 6b	cmp	w11, w10
101173170:	ea d7 9f 1a	cset	w10, gt
101173174:	0b 0b 00 51	sub	w11, w24, #0x2
101173178:	c9 02 09 4b	sub	w9, w22, w9
10117317c:	3f 01 0b 6b	cmp	w9, w11
101173180:	29 b1 8b 1a	csel	w9, w9, w11, lt
101173184:	eb 03 41 b9	ldr	w11, [sp, #0x100]
101173188:	57 01 0b 2a	orr	w23, w10, w11
10117318c:	ea 07 40 91	add	x10, sp, #0x1, lsl #12
101173190:	4a c1 19 91	add	x10, x10, #0x670
101173194:	54 79 b3 b8	ldrsw	x20, [x10, x19, lsl #2]
101173198:	9a 02 17 8b	add	x26, x20, x23
10117319c:	3f 01 1a 6b	cmp	w9, w26
1011731a0:	fc 97 40 f9	ldr	x28, [sp, #0x128]
1011731a4:	cb 04 00 54	b.lt	0x10117323c
1011731a8:	33 7d 40 93	sxtw	x19, w9
1011731ac:	d6 06 00 11	add	w22, w22, #0x1
1011731b0:	69 c6 29 8b	add	x9, x19, w9, sxtw #1
1011731b4:	38 f1 7d d3	lsl	x24, x9, #3
1011731b8:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
1011731bc:	01 01 18 8b	add	x1, x8, x24
1011731c0:	29 8c 41 b8	ldr	w9, [x1, #0x18]!
1011731c4:	08 69 78 b8	ldr	w8, [x8, x24]
1011731c8:	29 01 08 4b	sub	w9, w9, w8
1011731cc:	20 01 62 1e	scvtf	d0, w9
1011731d0:	01 01 62 1e	scvtf	d1, w8
1011731d4:	21 28 6e 1e	fadd	d1, d1, d14
1011731d8:	00 04 4e 1f	fmadd	d0, d0, d14, d1
1011731dc:	08 00 78 1e	fcvtzs	w8, d0
1011731e0:	e8 d3 03 b9	str	w8, [sp, #0x3d0]
1011731e4:	ff ef 01 f9	str	xzr, [sp, #0x3d8]
1011731e8:	e2 43 0f 91	add	x2, sp, #0x3d0
1011731ec:	0b 30 ff 97	bl	__ZNSt3__16vectorIN16BeatAnalyzer_2_06peakss8BeatInfoENS_9allocatorIS3_EEE6insertENS_11__wrap_iterIPKS3_EERS8_
1011731f0:	e8 a3 40 f9	ldr	x8, [sp, #0x140]
1011731f4:	16 01 00 b9	str	w22, [x8]
1011731f8:	7f 02 1a eb	cmp	x19, x26
1011731fc:	ed 00 00 54	b.le	0x101173218
101173200:	73 06 00 d1	sub	x19, x19, #0x1
101173204:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
101173208:	08 00 40 f9	ldr	x8, [x0]
10117320c:	d6 06 00 11	add	w22, w22, #0x1
101173210:	18 63 00 d1	sub	x24, x24, #0x18
101173214:	ea ff ff 17	b	0x1011731bc
101173218:	e8 9b 40 f9	ldr	x8, [sp, #0x130]
10117321c:	09 01 40 f9	ldr	x9, [x8]
101173220:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
101173224:	08 01 40 f9	ldr	x8, [x8]
101173228:	29 01 08 cb	sub	x9, x9, x8
10117322c:	29 fd 43 d3	lsr	x9, x9, #3
101173230:	6a 55 95 52	mov	w10, #0xaaab
101173234:	4a 55 b5 72	movk	w10, #0xaaaa, lsl #16
101173238:	38 7d 0a 1b	mul	w24, w9, w10
10117323c:	99 07 00 36	tbz	w25, #0x0, 0x10117332c
101173240:	d9 06 00 11	add	w25, w22, #0x1
101173244:	3f 03 18 6b	cmp	w25, w24
101173248:	2a 07 00 54	b.ge	0x10117332c
10117324c:	0b 03 80 52	mov	w11, #0x18
101173250:	ca 7e 2b 9b	smull	x10, w22, w11
101173254:	00 69 6a bc	ldr	s0, [x8, x10]
101173258:	00 a4 20 0f	sshll.2d	v0, v0, #0x0
10117325c:	00 d8 61 5e	scvtf	d0, d0
101173260:	69 03 40 b9	ldr	w9, [x27]
101173264:	21 01 62 1e	scvtf	d1, w9
101173268:	0a 18 61 1e	fdiv	d10, d0, d1
10117326c:	2b 7f 2b 9b	smull	x11, w25, w11
101173270:	00 69 6b bc	ldr	s0, [x8, x11]
101173274:	00 a4 20 0f	sshll.2d	v0, v0, #0x0
101173278:	00 d8 61 5e	scvtf	d0, d0
10117327c:	00 18 61 1e	fdiv	d0, d0, d1
101173280:	0b 38 6a 1e	fsub	d11, d0, d10
101173284:	0b 00 c8 d2	mov	x11, #0x400000000000
101173288:	eb 11 e8 f2	movk	x11, #0x408f, lsl #48
10117328c:	60 01 67 9e	fmov	d0, x11
101173290:	60 09 60 1e	fmul	d0, d11, d0
101173294:	00 38 4c 1f	fmadd	d0, d0, d12, d14
101173298:	0b 00 78 1e	fcvtzs	w11, d0
10117329c:	7a 09 00 71	subs	w26, w11, #0x2
1011732a0:	6b 04 00 54	b.lt	0x10117332c
1011732a4:	1b 00 80 52	mov	w27, #0x0
1011732a8:	60 01 62 1e	scvtf	d0, w11
1011732ac:	ff bf 03 b9	str	wzr, [sp, #0x3bc]
1011732b0:	0b 00 80 12	mov	w11, #-0x1
1011732b4:	eb cb 03 b9	str	w11, [sp, #0x3c8]
1011732b8:	ff 33 0f 39	strb	wzr, [sp, #0x3cc]
1011732bc:	a8 19 60 1e	fdiv	d8, d13, d0
1011732c0:	53 61 00 91	add	x19, x10, #0x18
1011732c4:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
1011732c8:	6a 07 00 11	add	w10, w27, #0x1
1011732cc:	40 01 62 1e	scvtf	d0, w10
1011732d0:	60 09 60 1e	fmul	d0, d11, d0
1011732d4:	00 28 48 1f	fmadd	d0, d0, d8, d10
1011732d8:	21 01 62 1e	scvtf	d1, w9
1011732dc:	00 38 41 1f	fmadd	d0, d0, d1, d14
1011732e0:	09 00 78 1e	fcvtzs	w9, d0
1011732e4:	e9 bb 03 b9	str	w9, [sp, #0x3b8]
1011732e8:	ff e3 01 f9	str	xzr, [sp, #0x3c0]
1011732ec:	61 02 08 8b	add	x1, x19, x8
1011732f0:	e2 e3 0e 91	add	x2, sp, #0x3b8
1011732f4:	c9 2f ff 97	bl	__ZNSt3__16vectorIN16BeatAnalyzer_2_06peakss8BeatInfoENS_9allocatorIS3_EEE6insertENS_11__wrap_iterIPKS3_EERS8_
1011732f8:	36 03 1b 0b	add	w22, w25, w27
1011732fc:	e8 a3 40 f9	ldr	x8, [sp, #0x140]
101173300:	16 01 00 b9	str	w22, [x8]
101173304:	5f 03 1b 6b	cmp	w26, w27
101173308:	00 01 00 54	b.eq	0x101173328
10117330c:	e8 9f 40 f9	ldr	x8, [sp, #0x138]
101173310:	09 01 40 b9	ldr	w9, [x8]
101173314:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
101173318:	08 00 40 f9	ldr	x8, [x0]
10117331c:	73 62 00 91	add	x19, x19, #0x18
101173320:	7b 07 00 11	add	w27, w27, #0x1
101173324:	e9 ff ff 17	b	0x1011732c8
101173328:	fb 9f 40 f9	ldr	x27, [sp, #0x138]
10117332c:	f7 07 00 34	cbz	w23, 0x101173428
101173330:	8a 06 00 91	add	x10, x20, #0x1
101173334:	5f 01 18 6b	cmp	w10, w24
101173338:	f9 9b 40 f9	ldr	x25, [sp, #0x130]
10117333c:	15 03 80 52	mov	w21, #0x18
101173340:	fa a3 40 f9	ldr	x26, [sp, #0x140]
101173344:	6a 08 00 54	b.ge	0x101173450
101173348:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
10117334c:	08 01 40 f9	ldr	x8, [x8]
101173350:	89 7e 15 9b	mul	x9, x20, x21
101173354:	00 69 69 bc	ldr	s0, [x8, x9]
101173358:	00 a4 20 0f	sshll.2d	v0, v0, #0x0
10117335c:	00 d8 61 5e	scvtf	d0, d0
101173360:	69 03 40 b9	ldr	w9, [x27]
101173364:	21 01 62 1e	scvtf	d1, w9
101173368:	0a 18 61 1e	fdiv	d10, d0, d1
10117336c:	4a 7d 15 9b	mul	x10, x10, x21
101173370:	00 69 6a bc	ldr	s0, [x8, x10]
101173374:	00 a4 20 0f	sshll.2d	v0, v0, #0x0
101173378:	00 d8 61 5e	scvtf	d0, d0
10117337c:	00 18 61 1e	fdiv	d0, d0, d1
101173380:	0b 38 6a 1e	fsub	d11, d0, d10
101173384:	0a 00 c8 d2	mov	x10, #0x400000000000
101173388:	ea 11 e8 f2	movk	x10, #0x408f, lsl #48
10117338c:	40 01 67 9e	fmov	d0, x10
101173390:	60 09 60 1e	fmul	d0, d11, d0
101173394:	00 38 4c 1f	fmadd	d0, d0, d12, d14
101173398:	0a 00 78 1e	fcvtzs	w10, d0
10117339c:	5f 09 00 71	cmp	w10, #0x2
1011733a0:	8b 05 00 54	b.lt	0x101173450
1011733a4:	40 01 62 1e	scvtf	d0, w10
1011733a8:	ff bf 03 b9	str	wzr, [sp, #0x3bc]
1011733ac:	0b 00 80 12	mov	w11, #-0x1
1011733b0:	eb cb 03 b9	str	w11, [sp, #0x3c8]
1011733b4:	ff 33 0f 39	strb	wzr, [sp, #0x3cc]
1011733b8:	57 05 00 51	sub	w23, w10, #0x1
1011733bc:	a8 19 60 1e	fdiv	d8, d13, d0
1011733c0:	f3 03 16 2a	mov	w19, w22
1011733c4:	ea 07 7d b2	orr	x10, xzr, #0x18
1011733c8:	94 2a 15 9b	madd	x20, x20, x21, x10
1011733cc:	38 00 80 52	mov	w24, #0x1
1011733d0:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
1011733d4:	00 03 62 1e	scvtf	d0, w24
1011733d8:	60 09 60 1e	fmul	d0, d11, d0
1011733dc:	00 28 48 1f	fmadd	d0, d0, d8, d10
1011733e0:	21 01 62 1e	scvtf	d1, w9
1011733e4:	00 38 41 1f	fmadd	d0, d0, d1, d14
1011733e8:	09 00 78 1e	fcvtzs	w9, d0
1011733ec:	e9 bb 03 b9	str	w9, [sp, #0x3b8]
1011733f0:	ff e3 01 f9	str	xzr, [sp, #0x3c0]
1011733f4:	81 02 08 8b	add	x1, x20, x8
1011733f8:	e2 e3 0e 91	add	x2, sp, #0x3b8
1011733fc:	87 2f ff 97	bl	__ZNSt3__16vectorIN16BeatAnalyzer_2_06peakss8BeatInfoENS_9allocatorIS3_EEE6insertENS_11__wrap_iterIPKS3_EERS8_
101173400:	68 02 18 0b	add	w8, w19, w24
101173404:	48 03 00 b9	str	w8, [x26]
101173408:	ff 02 18 eb	cmp	x23, x24
10117340c:	00 02 00 54	b.eq	0x10117344c
101173410:	69 03 40 b9	ldr	w9, [x27]
101173414:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
101173418:	08 00 40 f9	ldr	x8, [x0]
10117341c:	18 07 00 91	add	x24, x24, #0x1
101173420:	94 62 00 91	add	x20, x20, #0x18
101173424:	ec ff ff 17	b	0x1011733d4
101173428:	f9 9b 40 f9	ldr	x25, [sp, #0x130]
10117342c:	f7 07 40 91	add	x23, sp, #0x1, lsl #12
101173430:	f7 c2 11 91	add	x23, x23, #0x470
101173434:	ea f3 01 b2	mov	x10, #-0x5555555555555556
101173438:	6a 55 95 f2	movk	x10, #0xaaab
10117343c:	15 03 80 52	mov	w21, #0x18
101173440:	f8 87 40 f9	ldr	x24, [sp, #0x108]
101173444:	fa a3 40 f9	ldr	x26, [sp, #0x140]
101173448:	07 00 00 14	b	0x101173464
10117344c:	d6 02 18 0b	add	w22, w22, w24
101173450:	f7 07 40 91	add	x23, sp, #0x1, lsl #12
101173454:	f7 c2 11 91	add	x23, x23, #0x470
101173458:	ea f3 01 b2	mov	x10, #-0x5555555555555556
10117345c:	6a 55 95 f2	movk	x10, #0xaaab
101173460:	f8 87 40 f9	ldr	x24, [sp, #0x108]
101173464:	f3 b3 40 f9	ldr	x19, [sp, #0x160]
101173468:	61 02 40 f9	ldr	x1, [x19]
10117346c:	28 18 40 b9	ldr	w8, [x1, #0x18]
101173470:	29 00 40 b9	ldr	w9, [x1]
101173474:	08 01 09 4b	sub	w8, w8, w9
101173478:	28 01 08 6b	subs	w8, w9, w8
10117347c:	6d 01 00 54	b.le	0x1011734a8
101173480:	e8 d3 03 b9	str	w8, [sp, #0x3d0]
101173484:	ff ef 01 f9	str	xzr, [sp, #0x3d8]
101173488:	e2 43 0f 91	add	x2, sp, #0x3d0
10117348c:	e0 03 13 aa	mov	x0, x19
101173490:	62 2f ff 97	bl	__ZNSt3__16vectorIN16BeatAnalyzer_2_06peakss8BeatInfoENS_9allocatorIS3_EEE6insertENS_11__wrap_iterIPKS3_EERS8_
101173494:	c8 06 00 11	add	w8, w22, #0x1
101173498:	48 03 00 b9	str	w8, [x26]
10117349c:	61 02 40 f9	ldr	x1, [x19]
1011734a0:	ea f3 01 b2	mov	x10, #-0x5555555555555556
1011734a4:	6a 55 95 f2	movk	x10, #0xaaab
1011734a8:	28 03 40 f9	ldr	x8, [x25]
1011734ac:	08 01 01 cb	sub	x8, x8, x1
1011734b0:	08 fd 43 93	asr	x8, x8, #3
1011734b4:	13 7d 0a 9b	mul	x19, x8, x10
1011734b8:	7f 0a 00 71	cmp	w19, #0x2
1011734bc:	f6 07 40 91	add	x22, sp, #0x1, lsl #12
1011734c0:	d6 c2 19 91	add	x22, x22, #0x670
1011734c4:	ab 06 00 54	b.lt	0x101173598
1011734c8:	68 06 00 51	sub	w8, w19, #0x1
1011734cc:	09 7d b5 9b	umull	x9, w8, w21
1011734d0:	2a 68 69 b8	ldr	w10, [x1, x9]
1011734d4:	69 7e 60 d3	lsl	x9, x19, #32
1011734d8:	eb 7b 5f b2	mov	x11, #-0x200000000
1011734dc:	2b 01 0b 8b	add	x11, x9, x11
1011734e0:	6b fd 60 93	asr	x11, x11, #32
1011734e4:	6b 7d 15 9b	mul	x11, x11, x21
1011734e8:	2b 68 6b b8	ldr	w11, [x1, x11]
1011734ec:	54 01 0b 6b	subs	w20, w10, w11
1011734f0:	40 05 00 54	b.eq	0x101173598
1011734f4:	8b 1f 40 b9	ldr	w11, [x28, #0x1c]
1011734f8:	6a 01 0a 4b	sub	w10, w11, w10
1011734fc:	40 01 62 1e	scvtf	d0, w10
101173500:	81 02 62 1e	scvtf	d1, w20
101173504:	00 18 61 1e	fdiv	d0, d0, d1
101173508:	00 20 6d 1e	fcmp	d0, d13
10117350c:	6d 04 00 54	b.le	0x101173598
101173510:	0a 00 78 1e	fcvtzs	w10, d0
101173514:	ff e3 01 f9	str	xzr, [sp, #0x3c0]
101173518:	ff df 01 f9	str	xzr, [sp, #0x3b8]
10117351c:	0b 00 80 12	mov	w11, #-0x1
101173520:	eb cb 03 b9	str	w11, [sp, #0x3c8]
101173524:	ff 33 0f 39	strb	wzr, [sp, #0x3cc]
101173528:	5f 05 00 71	cmp	w10, #0x1
10117352c:	cb 02 00 54	b.lt	0x101173584
101173530:	29 fd 60 93	asr	x9, x9, #32
101173534:	08 05 08 8b	add	x8, x8, x8, lsl #1
101173538:	16 f1 7d d3	lsl	x22, x8, #3
10117353c:	28 05 09 8b	add	x8, x9, x9, lsl #1
101173540:	17 f1 7d d3	lsl	x23, x8, #3
101173544:	58 05 00 d1	sub	x24, x10, #0x1
101173548:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
10117354c:	28 68 76 b8	ldr	w8, [x1, x22]
101173550:	08 01 14 0b	add	w8, w8, w20
101173554:	e8 bb 03 b9	str	w8, [sp, #0x3b8]
101173558:	ff e3 01 f9	str	xzr, [sp, #0x3c0]
10117355c:	e1 02 01 8b	add	x1, x23, x1
101173560:	e2 e3 0e 91	add	x2, sp, #0x3b8
101173564:	2d 2f ff 97	bl	__ZNSt3__16vectorIN16BeatAnalyzer_2_06peakss8BeatInfoENS_9allocatorIS3_EEE6insertENS_11__wrap_iterIPKS3_EERS8_
101173568:	f8 00 00 b4	cbz	x24, 0x101173584
10117356c:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
101173570:	01 00 40 f9	ldr	x1, [x0]
101173574:	d6 62 00 91	add	x22, x22, #0x18
101173578:	f7 62 00 91	add	x23, x23, #0x18
10117357c:	18 07 00 d1	sub	x24, x24, #0x1
101173580:	f3 ff ff 17	b	0x10117354c
101173584:	f7 07 40 91	add	x23, sp, #0x1, lsl #12
101173588:	f7 c2 11 91	add	x23, x23, #0x470
10117358c:	f6 07 40 91	add	x22, sp, #0x1, lsl #12
101173590:	d6 c2 19 91	add	x22, x22, #0x670
101173594:	f8 87 40 f9	ldr	x24, [sp, #0x108]
101173598:	e8 a7 40 b9	ldr	w8, [sp, #0xa4]
10117359c:	a8 67 02 34	cbz	w8, 0x101178290
1011735a0:	29 03 40 f9	ldr	x9, [x25]
1011735a4:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
1011735a8:	08 01 40 f9	ldr	x8, [x8]
1011735ac:	29 01 08 cb	sub	x9, x9, x8
1011735b0:	29 fd 43 d3	lsr	x9, x9, #3
1011735b4:	6a 55 95 52	mov	w10, #0xaaab
1011735b8:	4a 55 b5 72	movk	w10, #0xaaaa, lsl #16
1011735bc:	33 7d 0a 1b	mul	w19, w9, w10
1011735c0:	69 0a 00 51	sub	w9, w19, #0x2
1011735c4:	3f 05 00 71	cmp	w9, #0x1
1011735c8:	2a c5 9f 1a	csinc	w10, w9, wzr, gt
1011735cc:	0f 06 80 52	mov	w15, #0x30
1011735d0:	2b 00 80 52	mov	w11, #0x1
1011735d4:	7f 01 0a eb	cmp	x11, x10
1011735d8:	c0 65 02 54	b.eq	0x101178290
1011735dc:	e9 03 0b aa	mov	x9, x11
1011735e0:	f4 03 0f aa	mov	x20, x15
1011735e4:	6b 21 15 9b	madd	x11, x11, x21, x8
1011735e8:	70 01 40 b9	ldr	w16, [x11]
1011735ec:	6d 81 5e b8	ldur	w13, [x11, #-0x18]
1011735f0:	2b 05 00 91	add	x11, x9, #0x1
1011735f4:	6c 7d 40 92	and	x12, x11, #0xffffffff
1011735f8:	8c 7d 15 9b	mul	x12, x12, x21
1011735fc:	0c 69 6c b8	ldr	w12, [x8, x12]
101173600:	0f 02 0d 4b	sub	w15, w16, w13
101173604:	2d 09 00 11	add	w13, w9, #0x2
101173608:	ad 7d b5 9b	umull	x13, w13, w21
10117360c:	0e 69 6d b8	ldr	w14, [x8, x13]
101173610:	cd 01 0c 4b	sub	w13, w14, w12
101173614:	f1 09 0f 0b	add	w17, w15, w15, lsl #2
101173618:	a0 09 0d 0b	add	w0, w13, w13, lsl #2
10117361c:	8f 62 00 91	add	x15, x20, #0x18
101173620:	90 01 10 4b	sub	w16, w12, w16
101173624:	1f 02 11 6b	cmp	w16, w17
101173628:	00 d2 40 7a	ccmp	w16, w0, #0x0, le
10117362c:	4d fd ff 54	b.le	0x1011735d4
101173630:	df 01 0c 6b	cmp	w14, w12
101173634:	e0 62 02 54	b.eq	0x101178290
101173638:	00 02 62 1e	scvtf	d0, w16
10117363c:	a1 01 62 1e	scvtf	d1, w13
101173640:	01 18 61 1e	fdiv	d1, d0, d1
101173644:	20 20 6d 1e	fcmp	d1, d13
101173648:	4d 62 02 54	b.le	0x101178290
10117364c:	2a 00 78 1e	fcvtzs	w10, d1
101173650:	ff e3 01 f9	str	xzr, [sp, #0x3c0]
101173654:	ff df 01 f9	str	xzr, [sp, #0x3b8]
101173658:	0b 00 80 12	mov	w11, #-0x1
10117365c:	eb cb 03 b9	str	w11, [sp, #0x3c8]
101173660:	ff 33 0f 39	strb	wzr, [sp, #0x3cc]
101173664:	5f 09 00 71	cmp	w10, #0x2
101173668:	8b 60 02 54	b.lt	0x101178278
10117366c:	21 c0 65 1e	frintz	d1, d1
101173670:	00 18 61 1e	fdiv	d0, d0, d1
101173674:	16 00 78 1e	fcvtzs	w22, d0
101173678:	37 7d 40 92	and	x23, x9, #0xffffffff
10117367c:	58 09 00 d1	sub	x24, x10, #0x2
101173680:	f9 03 16 aa	mov	x25, x22
101173684:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
101173688:	e9 7e 15 9b	mul	x9, x23, x21
10117368c:	09 69 69 b8	ldr	w9, [x8, x9]
101173690:	29 03 09 0b	add	w9, w25, w9
101173694:	e9 bb 03 b9	str	w9, [sp, #0x3b8]
101173698:	ff e3 01 f9	str	xzr, [sp, #0x3c0]
10117369c:	81 02 08 8b	add	x1, x20, x8
1011736a0:	e2 e3 0e 91	add	x2, sp, #0x3b8
1011736a4:	dd 2e ff 97	bl	__ZNSt3__16vectorIN16BeatAnalyzer_2_06peakss8BeatInfoENS_9allocatorIS3_EEE6insertENS_11__wrap_iterIPKS3_EERS8_
1011736a8:	98 5e 02 b4	cbz	x24, 0x101178278
1011736ac:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
1011736b0:	08 00 40 f9	ldr	x8, [x0]
1011736b4:	39 03 16 0b	add	w25, w25, w22
1011736b8:	94 62 00 91	add	x20, x20, #0x18
1011736bc:	18 07 00 d1	sub	x24, x24, #0x1
1011736c0:	f2 ff ff 17	b	0x101173688
1011736c4:	08 13 00 71	subs	w8, w24, #0x4
1011736c8:	63 04 00 54	b.lo	0x101173754
1011736cc:	80 5a 68 fc	ldr	d0, [x20, w8, uxtw #3]
1011736d0:	c1 01 67 9e	fmov	d1, x14
1011736d4:	00 20 61 1e	fcmp	d0, d1
1011736d8:	e9 a3 90 d2	mov	x9, #0x851f
1011736dc:	69 3d aa f2	movk	x9, #0x51eb, lsl #16
1011736e0:	09 d7 c3 f2	movk	x9, #0x1eb8, lsl #32
1011736e4:	29 fe e7 f2	movk	x9, #0x3ff1, lsl #48
1011736e8:	21 01 67 9e	fmov	d1, x9
1011736ec:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
1011736f0:	8c 00 00 54	b.gt	0x101173700
1011736f4:	e1 01 67 9e	fmov	d1, x15
1011736f8:	00 20 61 1e	fcmp	d0, d1
1011736fc:	ed 02 00 54	b.le	0x101173758
101173700:	09 17 00 71	subs	w9, w24, #0x5
101173704:	83 02 00 54	b.lo	0x101173754
101173708:	80 5a 69 fc	ldr	d0, [x20, w9, uxtw #3]
10117370c:	ea a3 90 d2	mov	x10, #0x851f
101173710:	6a 3d aa f2	movk	x10, #0x51eb, lsl #16
101173714:	0a d7 c3 f2	movk	x10, #0x1eb8, lsl #32
101173718:	2a fe e7 f2	movk	x10, #0x3ff1, lsl #48
10117371c:	41 01 67 9e	fmov	d1, x10
101173720:	00 20 61 1e	fcmp	d0, d1
101173724:	ea d7 9f 1a	cset	w10, gt
101173728:	c1 01 67 9e	fmov	d1, x14
10117372c:	00 20 61 1e	fcmp	d0, d1
101173730:	ec a7 9f 1a	cset	w12, lt
101173734:	4a 01 0c 0a	and	w10, w10, w12
101173738:	e1 01 67 9e	fmov	d1, x15
10117373c:	00 20 61 1e	fcmp	d0, d1
101173740:	ec d7 9f 1a	cset	w12, gt
101173744:	40 01 0c 2a	orr	w0, w10, w12
101173748:	1f 00 00 71	cmp	w0, #0x0
10117374c:	36 11 88 1a	csel	w22, w9, w8, ne
101173750:	03 00 00 14	b	0x10117375c
101173754:	16 00 80 52	mov	w22, #0x0
101173758:	00 00 80 52	mov	w0, #0x0
10117375c:	08 0a 00 51	sub	w8, w16, #0x2
101173760:	1f 03 08 6b	cmp	w24, w8
101173764:	ec 03 00 54	b.gt	0x1011737e0
101173768:	80 da 7c fc	ldr	d0, [x20, w28, sxtw #3]
10117376c:	c1 01 67 9e	fmov	d1, x14
101173770:	00 20 61 1e	fcmp	d0, d1
101173774:	e9 a3 90 d2	mov	x9, #0x851f
101173778:	69 3d aa f2	movk	x9, #0x51eb, lsl #16
10117377c:	09 d7 c3 f2	movk	x9, #0x1eb8, lsl #32
101173780:	29 fe e7 f2	movk	x9, #0x3ff1, lsl #48
101173784:	21 01 67 9e	fmov	d1, x9
101173788:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
10117378c:	8c 00 00 54	b.gt	0x10117379c
101173790:	e1 01 67 9e	fmov	d1, x15
101173794:	00 20 61 1e	fcmp	d0, d1
101173798:	4d 02 00 54	b.le	0x1011737e0
10117379c:	09 0e 00 51	sub	w9, w16, #0x3
1011737a0:	1f 03 09 6b	cmp	w24, w9
1011737a4:	cc 01 00 54	b.gt	0x1011737dc
1011737a8:	80 da 71 fc	ldr	d0, [x20, w17, sxtw #3]
1011737ac:	c1 01 67 9e	fmov	d1, x14
1011737b0:	00 20 61 1e	fcmp	d0, d1
1011737b4:	e9 a3 90 d2	mov	x9, #0x851f
1011737b8:	69 3d aa f2	movk	x9, #0x51eb, lsl #16
1011737bc:	09 d7 c3 f2	movk	x9, #0x1eb8, lsl #32
1011737c0:	29 fe e7 f2	movk	x9, #0x3ff1, lsl #48
1011737c4:	21 01 67 9e	fmov	d1, x9
1011737c8:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
1011737cc:	8c 3b 00 54	b.gt	0x101173f3c
1011737d0:	e1 01 67 9e	fmov	d1, x15
1011737d4:	00 20 61 1e	fcmp	d0, d1
1011737d8:	2c 3b 00 54	b.gt	0x101173f3c
1011737dc:	f8 03 1c aa	mov	x24, x28
1011737e0:	fc 97 40 f9	ldr	x28, [sp, #0x128]
1011737e4:	6a 05 00 71	subs	w10, w11, #0x1
1011737e8:	eb 01 00 54	b.lt	0x101173824
1011737ec:	80 5a 6a fc	ldr	d0, [x20, w10, uxtw #3]
1011737f0:	e9 a3 90 d2	mov	x9, #0x851f
1011737f4:	69 3d aa f2	movk	x9, #0x51eb, lsl #16
1011737f8:	09 d7 c3 f2	movk	x9, #0x1eb8, lsl #32
1011737fc:	29 fe e7 f2	movk	x9, #0x3ff1, lsl #48
101173800:	21 01 67 9e	fmov	d1, x9
101173804:	00 20 61 1e	fcmp	d0, d1
101173808:	2d 01 00 54	b.le	0x10117382c
10117380c:	c1 01 67 9e	fmov	d1, x14
101173810:	00 20 61 1e	fcmp	d0, d1
101173814:	ca 00 00 54	b.ge	0x10117382c
101173818:	7f 09 00 71	cmp	w11, #0x2
10117381c:	4a 01 00 54	b.ge	0x101173844
101173820:	4d 00 00 14	b	0x101173954
101173824:	e9 03 0b aa	mov	x9, x11
101173828:	4c 00 00 14	b	0x101173958
10117382c:	e1 01 67 9e	fmov	d1, x15
101173830:	00 20 61 1e	fcmp	d0, d1
101173834:	69 d1 9f 1a	csel	w9, w11, wzr, le
101173838:	0d 09 00 54	b.le	0x101173958
10117383c:	7f 09 00 71	cmp	w11, #0x2
101173840:	cb 08 00 54	b.lt	0x101173958
101173844:	69 09 00 51	sub	w9, w11, #0x2
101173848:	80 5a 69 fc	ldr	d0, [x20, w9, uxtw #3]
10117384c:	c1 01 67 9e	fmov	d1, x14
101173850:	00 20 61 1e	fcmp	d0, d1
101173854:	ec a3 90 d2	mov	x12, #0x851f
101173858:	6c 3d aa f2	movk	x12, #0x51eb, lsl #16
10117385c:	0c d7 c3 f2	movk	x12, #0x1eb8, lsl #32
101173860:	2c fe e7 f2	movk	x12, #0x3ff1, lsl #48
101173864:	81 01 67 9e	fmov	d1, x12
101173868:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
10117386c:	cc 00 00 54	b.gt	0x101173884
101173870:	e1 01 67 9e	fmov	d1, x15
101173874:	00 20 61 1e	fcmp	d0, d1
101173878:	6c 00 00 54	b.gt	0x101173884
10117387c:	e9 03 0a aa	mov	x9, x10
101173880:	36 00 00 14	b	0x101173958
101173884:	6a 0d 00 71	subs	w10, w11, #0x3
101173888:	63 06 00 54	b.lo	0x101173954
10117388c:	80 5a 6a fc	ldr	d0, [x20, w10, uxtw #3]
101173890:	c1 01 67 9e	fmov	d1, x14
101173894:	00 20 61 1e	fcmp	d0, d1
101173898:	ec a3 90 d2	mov	x12, #0x851f
10117389c:	6c 3d aa f2	movk	x12, #0x51eb, lsl #16
1011738a0:	0c d7 c3 f2	movk	x12, #0x1eb8, lsl #32
1011738a4:	2c fe e7 f2	movk	x12, #0x3ff1, lsl #48
1011738a8:	81 01 67 9e	fmov	d1, x12
1011738ac:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
1011738b0:	8c 00 00 54	b.gt	0x1011738c0
1011738b4:	e1 01 67 9e	fmov	d1, x15
1011738b8:	00 20 61 1e	fcmp	d0, d1
1011738bc:	ed 04 00 54	b.le	0x101173958
1011738c0:	69 11 00 71	subs	w9, w11, #0x4
1011738c4:	83 04 00 54	b.lo	0x101173954
1011738c8:	80 5a 69 fc	ldr	d0, [x20, w9, uxtw #3]
1011738cc:	c1 01 67 9e	fmov	d1, x14
1011738d0:	00 20 61 1e	fcmp	d0, d1
1011738d4:	ec a3 90 d2	mov	x12, #0x851f
1011738d8:	6c 3d aa f2	movk	x12, #0x51eb, lsl #16
1011738dc:	0c d7 c3 f2	movk	x12, #0x1eb8, lsl #32
1011738e0:	2c fe e7 f2	movk	x12, #0x3ff1, lsl #48
1011738e4:	81 01 67 9e	fmov	d1, x12
1011738e8:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
1011738ec:	8c 00 00 54	b.gt	0x1011738fc
1011738f0:	e1 01 67 9e	fmov	d1, x15
1011738f4:	00 20 61 1e	fcmp	d0, d1
1011738f8:	2d fc ff 54	b.le	0x10117387c
1011738fc:	6a 15 00 71	subs	w10, w11, #0x5
101173900:	a3 02 00 54	b.lo	0x101173954
101173904:	80 5a 6a fc	ldr	d0, [x20, w10, uxtw #3]
101173908:	ec a3 90 d2	mov	x12, #0x851f
10117390c:	6c 3d aa f2	movk	x12, #0x51eb, lsl #16
101173910:	0c d7 c3 f2	movk	x12, #0x1eb8, lsl #32
101173914:	2c fe e7 f2	movk	x12, #0x3ff1, lsl #48
101173918:	81 01 67 9e	fmov	d1, x12
10117391c:	00 20 61 1e	fcmp	d0, d1
101173920:	ec d7 9f 1a	cset	w12, gt
101173924:	c1 01 67 9e	fmov	d1, x14
101173928:	00 20 61 1e	fcmp	d0, d1
10117392c:	ed a7 9f 1a	cset	w13, lt
101173930:	8c 01 0d 0a	and	w12, w12, w13
101173934:	e1 01 67 9e	fmov	d1, x15
101173938:	00 20 61 1e	fcmp	d0, d1
10117393c:	ed d7 9f 1a	cset	w13, gt
101173940:	8c 01 0d 2a	orr	w12, w12, w13
101173944:	9f 01 00 71	cmp	w12, #0x0
101173948:	49 11 89 1a	csel	w9, w10, w9, ne
10117394c:	80 01 00 2a	orr	w0, w12, w0
101173950:	02 00 00 14	b	0x101173958
101173954:	09 00 80 52	mov	w9, #0x0
101173958:	7f 01 08 6b	cmp	w11, w8
10117395c:	ea f3 01 b2	mov	x10, #-0x5555555555555556
101173960:	6a 55 95 f2	movk	x10, #0xaaab
101173964:	6c 04 00 54	b.gt	0x1011739f0
101173968:	68 05 00 11	add	w8, w11, #0x1
10117396c:	80 da 68 fc	ldr	d0, [x20, w8, sxtw #3]
101173970:	c1 01 67 9e	fmov	d1, x14
101173974:	00 20 61 1e	fcmp	d0, d1
101173978:	ec a3 90 d2	mov	x12, #0x851f
10117397c:	6c 3d aa f2	movk	x12, #0x51eb, lsl #16
101173980:	0c d7 c3 f2	movk	x12, #0x1eb8, lsl #32
101173984:	2c fe e7 f2	movk	x12, #0x3ff1, lsl #48
101173988:	81 01 67 9e	fmov	d1, x12
10117398c:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
101173990:	8c 00 00 54	b.gt	0x1011739a0
101173994:	e1 01 67 9e	fmov	d1, x15
101173998:	00 20 61 1e	fcmp	d0, d1
10117399c:	ad 02 00 54	b.le	0x1011739f0
1011739a0:	0a 0e 00 51	sub	w10, w16, #0x3
1011739a4:	7f 01 0a 6b	cmp	w11, w10
1011739a8:	ec 01 00 54	b.gt	0x1011739e4
1011739ac:	6a 09 00 11	add	w10, w11, #0x2
1011739b0:	80 da 6a fc	ldr	d0, [x20, w10, sxtw #3]
1011739b4:	c1 01 67 9e	fmov	d1, x14
1011739b8:	00 20 61 1e	fcmp	d0, d1
1011739bc:	ec a3 90 d2	mov	x12, #0x851f
1011739c0:	6c 3d aa f2	movk	x12, #0x51eb, lsl #16
1011739c4:	0c d7 c3 f2	movk	x12, #0x1eb8, lsl #32
1011739c8:	2c fe e7 f2	movk	x12, #0x3ff1, lsl #48
1011739cc:	81 01 67 9e	fmov	d1, x12
1011739d0:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
1011739d4:	ec 2b 00 54	b.gt	0x101173f50
1011739d8:	e1 01 67 9e	fmov	d1, x15
1011739dc:	00 20 61 1e	fcmp	d0, d1
1011739e0:	8c 2b 00 54	b.gt	0x101173f50
1011739e4:	eb 03 08 aa	mov	x11, x8
1011739e8:	ea f3 01 b2	mov	x10, #-0x5555555555555556
1011739ec:	6a 55 95 f2	movk	x10, #0xaaab
1011739f0:	e0 c3 00 b9	str	w0, [sp, #0xc0]
1011739f4:	3f 01 00 71	cmp	w9, #0x0
1011739f8:	2d c1 9f 1a	csel	w13, w9, wzr, gt
1011739fc:	ed a3 00 f9	str	x13, [sp, #0x140]
101173a00:	37 03 40 f9	ldr	x23, [x25]
101173a04:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
101173a08:	08 01 40 f9	ldr	x8, [x8]
101173a0c:	e9 02 08 cb	sub	x9, x23, x8
101173a10:	29 fd 43 93	asr	x9, x9, #3
101173a14:	fa f3 01 b2	mov	x26, #-0x5555555555555556
101173a18:	7a 55 95 f2	movk	x26, #0xaaab
101173a1c:	29 7d 0a 9b	mul	x9, x9, x10
101173a20:	2a 05 00 d1	sub	x10, x9, #0x1
101173a24:	2c 05 00 51	sub	w12, w9, #0x1
101173a28:	5f c1 2b eb	cmp	x10, w11, sxtw
101173a2c:	8b 31 8b 1a	csel	w11, w12, w11, lo
101173a30:	7f 01 0d 6b	cmp	w11, w13
101173a34:	eb 6b 00 f9	str	x11, [sp, #0xd0]
101173a38:	ed 03 00 54	b.le	0x101173ab4
101173a3c:	73 7d 40 93	sxtw	x19, w11
101173a40:	14 03 80 52	mov	w20, #0x18
101173a44:	60 21 34 9b	smaddl	x0, w11, w20, x8
101173a48:	01 60 00 91	add	x1, x0, #0x18
101173a4c:	e2 02 01 cb	sub	x2, x23, x1
101173a50:	ff 7a 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
101173a54:	eb a3 40 f9	ldr	x11, [sp, #0x140]
101173a58:	f7 62 00 d1	sub	x23, x23, #0x18
101173a5c:	37 03 00 f9	str	x23, [x25]
101173a60:	73 06 00 d1	sub	x19, x19, #0x1
101173a64:	7f 02 0b eb	cmp	x19, x11
101173a68:	f5 b3 40 f9	ldr	x21, [sp, #0x160]
101173a6c:	8d 01 00 54	b.le	0x101173a9c
101173a70:	a8 02 40 f9	ldr	x8, [x21]
101173a74:	60 22 14 9b	madd	x0, x19, x20, x8
101173a78:	01 60 00 91	add	x1, x0, #0x18
101173a7c:	e2 02 01 cb	sub	x2, x23, x1
101173a80:	f3 7a 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
101173a84:	eb a3 40 f9	ldr	x11, [sp, #0x140]
101173a88:	f7 62 00 d1	sub	x23, x23, #0x18
101173a8c:	37 03 00 f9	str	x23, [x25]
101173a90:	73 06 00 d1	sub	x19, x19, #0x1
101173a94:	7f 02 0b eb	cmp	x19, x11
101173a98:	cc fe ff 54	b.gt	0x101173a70
101173a9c:	a8 02 40 f9	ldr	x8, [x21]
101173aa0:	e9 02 08 cb	sub	x9, x23, x8
101173aa4:	29 fd 43 93	asr	x9, x9, #3
101173aa8:	29 7d 1a 9b	mul	x9, x9, x26
101173aac:	2a 05 00 d1	sub	x10, x9, #0x1
101173ab0:	2c 05 00 51	sub	w12, w9, #0x1
101173ab4:	f3 03 0b aa	mov	x19, x11
101173ab8:	f4 07 40 91	add	x20, sp, #0x1, lsl #12
101173abc:	94 c2 01 91	add	x20, x20, #0x70
101173ac0:	eb af 40 f9	ldr	x11, [sp, #0x158]
101173ac4:	93 7a 2b b8	str	w19, [x20, x11, lsl #2]
101173ac8:	df 02 00 71	cmp	w22, #0x0
101173acc:	ce c2 9f 1a	csel	w14, w22, wzr, gt
101173ad0:	5f c1 38 eb	cmp	x10, w24, sxtw
101173ad4:	8a 31 98 1a	csel	w10, w12, w24, lo
101173ad8:	5f 01 0e 6b	cmp	w10, w14
101173adc:	1a 03 80 52	mov	w26, #0x18
101173ae0:	ee 83 00 f9	str	x14, [sp, #0x100]
101173ae4:	ea 67 00 f9	str	x10, [sp, #0xc8]
101173ae8:	8d 07 00 54	b.le	0x101173bd8
101173aec:	55 7d 40 93	sxtw	x21, w10
101173af0:	40 21 3a 9b	smaddl	x0, w10, w26, x8
101173af4:	01 60 00 91	add	x1, x0, #0x18
101173af8:	e2 02 01 cb	sub	x2, x23, x1
101173afc:	d4 7a 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
101173b00:	ee 83 40 f9	ldr	x14, [sp, #0x100]
101173b04:	f7 62 00 d1	sub	x23, x23, #0x18
101173b08:	e9 93 40 f9	ldr	x9, [sp, #0x120]
101173b0c:	88 6a 69 b8	ldr	w8, [x20, x9]
101173b10:	37 03 00 f9	str	x23, [x25]
101173b14:	13 05 00 51	sub	w19, w8, #0x1
101173b18:	93 6a 29 b8	str	w19, [x20, x9]
101173b1c:	b8 06 00 d1	sub	x24, x21, #0x1
101173b20:	1f 03 0e eb	cmp	x24, x14
101173b24:	cd 06 00 54	b.le	0x101173bfc
101173b28:	a8 06 15 8b	add	x8, x21, x21, lsl #1
101173b2c:	1b f1 7d d3	lsl	x27, x8, #3
101173b30:	f6 03 19 aa	mov	x22, x25
101173b34:	e8 02 80 92	mov	x8, #-0x18
101173b38:	b9 7e 08 9b	mul	x25, x21, x8
101173b3c:	f5 b3 40 f9	ldr	x21, [sp, #0x160]
101173b40:	f4 f3 01 b2	mov	x20, #-0x5555555555555556
101173b44:	74 55 95 f2	movk	x20, #0xaaab
101173b48:	54 55 e5 f2	movk	x20, #0x2aaa, lsl #48
101173b4c:	ba 02 40 f9	ldr	x26, [x21]
101173b50:	e8 02 1a cb	sub	x8, x23, x26
101173b54:	22 03 08 8b	add	x2, x25, x8
101173b58:	48 7c 54 9b	smulh	x8, x2, x20
101173b5c:	09 fd 42 93	asr	x9, x8, #2
101173b60:	3c fd 48 8b	add	x28, x9, x8, lsr #63
101173b64:	41 03 1b 8b	add	x1, x26, x27
101173b68:	20 60 00 d1	sub	x0, x1, #0x18
101173b6c:	b8 7a 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
101173b70:	ee 83 40 f9	ldr	x14, [sp, #0x100]
101173b74:	08 03 80 52	mov	w8, #0x18
101173b78:	88 6f 08 9b	madd	x8, x28, x8, x27
101173b7c:	48 03 08 8b	add	x8, x26, x8
101173b80:	17 61 00 d1	sub	x23, x8, #0x18
101173b84:	d7 02 00 f9	str	x23, [x22]
101173b88:	73 06 00 51	sub	w19, w19, #0x1
101173b8c:	18 07 00 d1	sub	x24, x24, #0x1
101173b90:	7b 63 00 d1	sub	x27, x27, #0x18
101173b94:	39 63 00 91	add	x25, x25, #0x18
101173b98:	1f 03 0e eb	cmp	x24, x14
101173b9c:	8c fd ff 54	b.gt	0x101173b4c
101173ba0:	e8 07 40 91	add	x8, sp, #0x1, lsl #12
101173ba4:	08 c1 01 91	add	x8, x8, #0x70
101173ba8:	e9 af 40 f9	ldr	x9, [sp, #0x158]
101173bac:	13 79 29 b8	str	w19, [x8, x9, lsl #2]
101173bb0:	08 03 80 52	mov	w8, #0x18
101173bb4:	88 6b 08 9b	madd	x8, x28, x8, x26
101173bb8:	17 01 19 cb	sub	x23, x8, x25
101173bbc:	fc 97 40 f9	ldr	x28, [sp, #0x128]
101173bc0:	fb 9f 40 f9	ldr	x27, [sp, #0x138]
101173bc4:	f9 03 16 aa	mov	x25, x22
101173bc8:	f6 07 40 91	add	x22, sp, #0x1, lsl #12
101173bcc:	d6 c2 19 91	add	x22, x22, #0x670
101173bd0:	1a 03 80 52	mov	w26, #0x18
101173bd4:	0c 00 00 14	b	0x101173c04
101173bd8:	f6 07 40 91	add	x22, sp, #0x1, lsl #12
101173bdc:	d6 c2 19 91	add	x22, x22, #0x670
101173be0:	ea 07 40 91	add	x10, sp, #0x1, lsl #12
101173be4:	4a c1 09 91	add	x10, x10, #0x270
101173be8:	eb af 40 f9	ldr	x11, [sp, #0x158]
101173bec:	4e 79 2b b8	str	w14, [x10, x11, lsl #2]
101173bf0:	2a 01 0e 6b	subs	w10, w9, w14
101173bf4:	0c 02 00 54	b.gt	0x101173c34
101173bf8:	55 00 00 14	b	0x101173d4c
101173bfc:	f6 07 40 91	add	x22, sp, #0x1, lsl #12
101173c00:	d6 c2 19 91	add	x22, x22, #0x670
101173c04:	eb a3 55 a9	ldp	x11, x8, [sp, #0x158]
101173c08:	08 01 40 f9	ldr	x8, [x8]
101173c0c:	e9 02 08 cb	sub	x9, x23, x8
101173c10:	29 fd 43 d3	lsr	x9, x9, #3
101173c14:	6a 55 95 52	mov	w10, #0xaaab
101173c18:	4a 55 b5 72	movk	w10, #0xaaaa, lsl #16
101173c1c:	29 7d 0a 1b	mul	w9, w9, w10
101173c20:	ea 07 40 91	add	x10, sp, #0x1, lsl #12
101173c24:	4a c1 09 91	add	x10, x10, #0x270
101173c28:	4e 79 2b b8	str	w14, [x10, x11, lsl #2]
101173c2c:	2a 01 0e 6b	subs	w10, w9, w14
101173c30:	ed 08 00 54	b.le	0x101173d4c
101173c34:	29 15 00 51	sub	w9, w9, #0x5
101173c38:	df 01 09 6b	cmp	w14, w9
101173c3c:	a9 00 80 52	mov	w9, #0x5
101173c40:	49 c1 89 1a	csel	w9, w10, w9, gt
101173c44:	3f 05 00 71	cmp	w9, #0x1
101173c48:	2b 08 00 54	b.lt	0x101173d4c
101173c4c:	ca 7d ba 9b	umull	x10, w14, w26
101173c50:	00 69 6a bc	ldr	s0, [x8, x10]
101173c54:	00 a4 20 0f	sshll.2d	v0, v0, #0x0
101173c58:	00 d8 61 5e	scvtf	d0, d0
101173c5c:	61 03 40 bd	ldr	s1, [x27]
101173c60:	21 a4 20 0f	sshll.2d	v1, v1, #0x0
101173c64:	23 d8 61 5e	scvtf	d3, d1
101173c68:	01 18 63 1e	fdiv	d1, d0, d3
101173c6c:	29 7d 40 93	sxtw	x9, w9
101173c70:	e0 7f 40 fd	ldr	d0, [sp, #0xf8]
101173c74:	22 28 60 1e	fadd	d2, d1, d0
101173c78:	a0 19 63 1e	fdiv	d0, d13, d3
101173c7c:	ca 05 00 91	add	x10, x14, #0x1
101173c80:	cb 21 1a 9b	madd	x11, x14, x26, x8
101173c84:	6b 61 00 91	add	x11, x11, #0x18
101173c88:	ec 03 0b aa	mov	x12, x11
101173c8c:	f8 03 0a aa	mov	x24, x10
101173c90:	ed 03 09 aa	mov	x13, x9
101173c94:	83 01 40 bd	ldr	s3, [x12]
101173c98:	63 a4 20 0f	sshll.2d	v3, v3, #0x0
101173c9c:	63 d8 61 5e	scvtf	d3, d3
101173ca0:	63 08 60 1e	fmul	d3, d3, d0
101173ca4:	64 38 69 1e	fsub	d4, d3, d9
101173ca8:	63 28 69 1e	fadd	d3, d3, d9
101173cac:	40 20 64 1e	fcmp	d2, d4
101173cb0:	40 c4 63 1e	fccmp	d2, d3, #0x0, gt
101173cb4:	cb 25 00 54	b.lt	0x10117416c
101173cb8:	18 07 00 91	add	x24, x24, #0x1
101173cbc:	8c 61 00 91	add	x12, x12, #0x18
101173cc0:	ad 05 00 f1	subs	x13, x13, #0x1
101173cc4:	81 fe ff 54	b.ne	0x101173c94
101173cc8:	e2 5f 40 fd	ldr	d2, [sp, #0xb8]
101173ccc:	22 28 62 1e	fadd	d2, d1, d2
101173cd0:	ec 03 0b aa	mov	x12, x11
101173cd4:	f8 03 0a aa	mov	x24, x10
101173cd8:	ed 03 09 aa	mov	x13, x9
101173cdc:	83 01 40 bd	ldr	s3, [x12]
101173ce0:	63 a4 20 0f	sshll.2d	v3, v3, #0x0
101173ce4:	63 d8 61 5e	scvtf	d3, d3
101173ce8:	63 08 60 1e	fmul	d3, d3, d0
101173cec:	64 38 69 1e	fsub	d4, d3, d9
101173cf0:	63 28 69 1e	fadd	d3, d3, d9
101173cf4:	40 20 64 1e	fcmp	d2, d4
101173cf8:	40 c4 63 1e	fccmp	d2, d3, #0x0, gt
101173cfc:	8b 23 00 54	b.lt	0x10117416c
101173d00:	18 07 00 91	add	x24, x24, #0x1
101173d04:	8c 61 00 91	add	x12, x12, #0x18
101173d08:	ad 05 00 f1	subs	x13, x13, #0x1
101173d0c:	81 fe ff 54	b.ne	0x101173cdc
101173d10:	e2 3f 40 fd	ldr	d2, [sp, #0x78]
101173d14:	21 28 62 1e	fadd	d1, d1, d2
101173d18:	62 01 40 bd	ldr	s2, [x11]
101173d1c:	42 a4 20 0f	sshll.2d	v2, v2, #0x0
101173d20:	42 d8 61 5e	scvtf	d2, d2
101173d24:	42 08 60 1e	fmul	d2, d2, d0
101173d28:	43 38 69 1e	fsub	d3, d2, d9
101173d2c:	42 28 69 1e	fadd	d2, d2, d9
101173d30:	20 20 63 1e	fcmp	d1, d3
101173d34:	20 c4 62 1e	fccmp	d1, d2, #0x0, gt
101173d38:	8b 21 00 54	b.lt	0x101174168
101173d3c:	4a 05 00 91	add	x10, x10, #0x1
101173d40:	6b 61 00 91	add	x11, x11, #0x18
101173d44:	29 05 00 f1	subs	x9, x9, #0x1
101173d48:	81 fe ff 54	b.ne	0x101173d18
101173d4c:	15 00 80 52	mov	w21, #0x0
101173d50:	74 06 00 71	subs	w20, w19, #0x1
101173d54:	2b 27 00 54	b.lt	0x101174238
101173d58:	ea 03 13 2a	mov	w10, w19
101173d5c:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
101173d60:	08 01 40 f9	ldr	x8, [x8]
101173d64:	6c 22 ba 9b	umaddl	x12, w19, w26, x8
101173d68:	80 01 40 bd	ldr	s0, [x12]
101173d6c:	00 a4 20 0f	sshll.2d	v0, v0, #0x0
101173d70:	00 d8 61 5e	scvtf	d0, d0
101173d74:	61 03 40 bd	ldr	s1, [x27]
101173d78:	21 a4 20 0f	sshll.2d	v1, v1, #0x0
101173d7c:	21 d8 61 5e	scvtf	d1, d1
101173d80:	00 18 61 1e	fdiv	d0, d0, d1
101173d84:	7f 16 00 71	cmp	w19, #0x5
101173d88:	a9 00 80 52	mov	w9, #0x5
101173d8c:	6b b2 89 1a	csel	w11, w19, w9, lt
101173d90:	e2 7f 40 fd	ldr	d2, [sp, #0xf8]
101173d94:	02 38 62 1e	fsub	d2, d0, d2
101173d98:	49 05 00 d1	sub	x9, x10, #0x1
101173d9c:	83 81 5e bc	ldur	s3, [x12, #-0x18]
101173da0:	63 a4 20 0f	sshll.2d	v3, v3, #0x0
101173da4:	63 d8 61 5e	scvtf	d3, d3
101173da8:	63 18 61 1e	fdiv	d3, d3, d1
101173dac:	64 38 69 1e	fsub	d4, d3, d9
101173db0:	63 28 69 1e	fadd	d3, d3, d9
101173db4:	40 20 64 1e	fcmp	d2, d4
101173db8:	40 c4 63 1e	fccmp	d2, d3, #0x0, gt
101173dbc:	f9 03 09 aa	mov	x25, x9
101173dc0:	0b 0f 00 54	b.lt	0x101173fa0
101173dc4:	6b 05 00 11	add	w11, w11, #0x1
101173dc8:	7f 09 00 71	cmp	w11, #0x2
101173dcc:	01 05 00 54	b.ne	0x101173e6c
101173dd0:	e2 5f 40 fd	ldr	d2, [sp, #0xb8]
101173dd4:	02 38 62 1e	fsub	d2, d0, d2
101173dd8:	6b 05 00 d1	sub	x11, x11, #0x1
101173ddc:	4a 21 1a 9b	madd	x10, x10, x26, x8
101173de0:	4a 61 00 d1	sub	x10, x10, #0x18
101173de4:	ec 03 0a aa	mov	x12, x10
101173de8:	f9 03 09 aa	mov	x25, x9
101173dec:	ed 03 0b aa	mov	x13, x11
101173df0:	a1 19 61 1e	fdiv	d1, d13, d1
101173df4:	83 01 40 bd	ldr	s3, [x12]
101173df8:	63 a4 20 0f	sshll.2d	v3, v3, #0x0
101173dfc:	63 d8 61 5e	scvtf	d3, d3
101173e00:	63 08 61 1e	fmul	d3, d3, d1
101173e04:	64 38 69 1e	fsub	d4, d3, d9
101173e08:	63 28 69 1e	fadd	d3, d3, d9
101173e0c:	40 20 64 1e	fcmp	d2, d4
101173e10:	40 c4 63 1e	fccmp	d2, d3, #0x0, gt
101173e14:	6b 0c 00 54	b.lt	0x101173fa0
101173e18:	39 07 00 d1	sub	x25, x25, #0x1
101173e1c:	8c 61 00 d1	sub	x12, x12, #0x18
101173e20:	ad 05 00 d1	sub	x13, x13, #0x1
101173e24:	8d fe ff b5	cbnz	x13, 0x101173df4
101173e28:	e2 3f 40 fd	ldr	d2, [sp, #0x78]
101173e2c:	00 38 62 1e	fsub	d0, d0, d2
101173e30:	42 01 40 bd	ldr	s2, [x10]
101173e34:	42 a4 20 0f	sshll.2d	v2, v2, #0x0
101173e38:	42 d8 61 5e	scvtf	d2, d2
101173e3c:	42 08 61 1e	fmul	d2, d2, d1
101173e40:	43 38 69 1e	fsub	d3, d2, d9
101173e44:	42 28 69 1e	fadd	d2, d2, d9
101173e48:	00 20 63 1e	fcmp	d0, d3
101173e4c:	00 c4 62 1e	fccmp	d0, d2, #0x0, gt
101173e50:	6b 0a 00 54	b.lt	0x101173f9c
101173e54:	29 05 00 d1	sub	x9, x9, #0x1
101173e58:	4a 61 00 d1	sub	x10, x10, #0x18
101173e5c:	6b 05 00 d1	sub	x11, x11, #0x1
101173e60:	8b fe ff b5	cbnz	x11, 0x101173e30
101173e64:	f9 03 13 aa	mov	x25, x19
101173e68:	4e 00 00 14	b	0x101173fa0
101173e6c:	59 09 00 d1	sub	x25, x10, #0x2
101173e70:	2c 7f 1a 9b	mul	x12, x25, x26
101173e74:	03 69 6c bc	ldr	s3, [x8, x12]
101173e78:	63 a4 20 0f	sshll.2d	v3, v3, #0x0
101173e7c:	63 d8 61 5e	scvtf	d3, d3
101173e80:	63 18 61 1e	fdiv	d3, d3, d1
101173e84:	64 38 69 1e	fsub	d4, d3, d9
101173e88:	63 28 69 1e	fadd	d3, d3, d9
101173e8c:	40 20 64 1e	fcmp	d2, d4
101173e90:	40 c4 63 1e	fccmp	d2, d3, #0x0, gt
101173e94:	6b 08 00 54	b.lt	0x101173fa0
101173e98:	7f 0d 00 71	cmp	w11, #0x3
101173e9c:	a0 f9 ff 54	b.eq	0x101173dd0
101173ea0:	59 0d 00 d1	sub	x25, x10, #0x3
101173ea4:	2c 7f 1a 9b	mul	x12, x25, x26
101173ea8:	03 69 6c bc	ldr	s3, [x8, x12]
101173eac:	63 a4 20 0f	sshll.2d	v3, v3, #0x0
101173eb0:	63 d8 61 5e	scvtf	d3, d3
101173eb4:	63 18 61 1e	fdiv	d3, d3, d1
101173eb8:	64 38 69 1e	fsub	d4, d3, d9
101173ebc:	63 28 69 1e	fadd	d3, d3, d9
101173ec0:	40 20 64 1e	fcmp	d2, d4
101173ec4:	40 c4 63 1e	fccmp	d2, d3, #0x0, gt
101173ec8:	cb 06 00 54	b.lt	0x101173fa0
101173ecc:	7f 11 00 71	cmp	w11, #0x4
101173ed0:	00 f8 ff 54	b.eq	0x101173dd0
101173ed4:	59 11 00 d1	sub	x25, x10, #0x4
101173ed8:	2c 7f 1a 9b	mul	x12, x25, x26
101173edc:	03 69 6c bc	ldr	s3, [x8, x12]
101173ee0:	63 a4 20 0f	sshll.2d	v3, v3, #0x0
101173ee4:	63 d8 61 5e	scvtf	d3, d3
101173ee8:	63 18 61 1e	fdiv	d3, d3, d1
101173eec:	64 38 69 1e	fsub	d4, d3, d9
101173ef0:	63 28 69 1e	fadd	d3, d3, d9
101173ef4:	40 20 64 1e	fcmp	d2, d4
101173ef8:	40 c4 63 1e	fccmp	d2, d3, #0x0, gt
101173efc:	2b 05 00 54	b.lt	0x101173fa0
101173f00:	7f 15 00 71	cmp	w11, #0x5
101173f04:	60 f6 ff 54	b.eq	0x101173dd0
101173f08:	59 15 00 d1	sub	x25, x10, #0x5
101173f0c:	2c 7f 1a 9b	mul	x12, x25, x26
101173f10:	03 69 6c bc	ldr	s3, [x8, x12]
101173f14:	63 a4 20 0f	sshll.2d	v3, v3, #0x0
101173f18:	63 d8 61 5e	scvtf	d3, d3
101173f1c:	63 18 61 1e	fdiv	d3, d3, d1
101173f20:	64 38 69 1e	fsub	d4, d3, d9
101173f24:	40 20 64 1e	fcmp	d2, d4
101173f28:	4d f5 ff 54	b.le	0x101173dd0
101173f2c:	63 28 69 1e	fadd	d3, d3, d9
101173f30:	40 20 63 1e	fcmp	d2, d3
101173f34:	6b 03 00 54	b.lt	0x101173fa0
101173f38:	a6 ff ff 17	b	0x101173dd0
101173f3c:	09 12 00 51	sub	w9, w16, #0x4
101173f40:	1f 03 09 6b	cmp	w24, w9
101173f44:	2d 3f 00 54	b.le	0x101174728
101173f48:	f8 03 11 aa	mov	x24, x17
101173f4c:	25 fe ff 17	b	0x1011737e0
101173f50:	08 12 00 51	sub	w8, w16, #0x4
101173f54:	7f 01 08 6b	cmp	w11, w8
101173f58:	ec 01 00 54	b.gt	0x101173f94
101173f5c:	6c 0d 00 11	add	w12, w11, #0x3
101173f60:	80 da 6c fc	ldr	d0, [x20, w12, sxtw #3]
101173f64:	c1 01 67 9e	fmov	d1, x14
101173f68:	00 20 61 1e	fcmp	d0, d1
101173f6c:	e8 a3 90 d2	mov	x8, #0x851f
101173f70:	68 3d aa f2	movk	x8, #0x51eb, lsl #16
101173f74:	08 d7 c3 f2	movk	x8, #0x1eb8, lsl #32
101173f78:	28 fe e7 f2	movk	x8, #0x3ff1, lsl #48
101173f7c:	01 01 67 9e	fmov	d1, x8
101173f80:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
101173f84:	4c 3f 00 54	b.gt	0x10117476c
101173f88:	e1 01 67 9e	fmov	d1, x15
101173f8c:	00 20 61 1e	fcmp	d0, d1
101173f90:	ec 3e 00 54	b.gt	0x10117476c
101173f94:	eb 03 0a aa	mov	x11, x10
101173f98:	94 fe ff 17	b	0x1011739e8
101173f9c:	f9 03 09 aa	mov	x25, x9
101173fa0:	9f 02 19 6b	cmp	w20, w25
101173fa4:	f8 d7 9f 1a	cset	w24, gt
101173fa8:	ed 05 00 54	b.le	0x101174064
101173fac:	80 22 3a 9b	smaddl	x0, w20, w26, x8
101173fb0:	01 60 00 91	add	x1, x0, #0x18
101173fb4:	e2 02 01 cb	sub	x2, x23, x1
101173fb8:	a5 79 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
101173fbc:	f7 62 00 d1	sub	x23, x23, #0x18
101173fc0:	e8 9b 40 f9	ldr	x8, [sp, #0x130]
101173fc4:	17 01 00 f9	str	x23, [x8]
101173fc8:	28 07 00 11	add	w8, w25, #0x1
101173fcc:	1f 01 14 6b	cmp	w8, w20
101173fd0:	e0 02 00 54	b.eq	0x10117402c
101173fd4:	fc 03 18 aa	mov	x28, x24
101173fd8:	f8 03 15 aa	mov	x24, x21
101173fdc:	94 7e 40 93	sxtw	x20, w20
101173fe0:	73 0a 00 51	sub	w19, w19, #0x2
101173fe4:	f5 b3 40 f9	ldr	x21, [sp, #0x160]
101173fe8:	f6 9b 40 f9	ldr	x22, [sp, #0x130]
101173fec:	a8 02 40 f9	ldr	x8, [x21]
101173ff0:	80 22 1a 9b	madd	x0, x20, x26, x8
101173ff4:	01 60 00 91	add	x1, x0, #0x18
101173ff8:	e2 02 01 cb	sub	x2, x23, x1
101173ffc:	94 79 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
101174000:	f7 62 00 d1	sub	x23, x23, #0x18
101174004:	d7 02 00 f9	str	x23, [x22]
101174008:	73 06 00 51	sub	w19, w19, #0x1
10117400c:	3f 03 13 6b	cmp	w25, w19
101174010:	e1 fe ff 54	b.ne	0x101173fec
101174014:	74 06 00 11	add	w20, w19, #0x1
101174018:	f6 07 40 91	add	x22, sp, #0x1, lsl #12
10117401c:	d6 c2 19 91	add	x22, x22, #0x670
101174020:	f5 03 18 aa	mov	x21, x24
101174024:	f8 03 1c aa	mov	x24, x28
101174028:	fc 97 40 f9	ldr	x28, [sp, #0x128]
10117402c:	e8 07 40 91	add	x8, sp, #0x1, lsl #12
101174030:	08 c1 01 91	add	x8, x8, #0x70
101174034:	e9 af 40 f9	ldr	x9, [sp, #0x158]
101174038:	14 79 29 b8	str	w20, [x8, x9, lsl #2]
10117403c:	f3 03 14 aa	mov	x19, x20
101174040:	e8 07 40 91	add	x8, sp, #0x1, lsl #12
101174044:	08 c1 09 91	add	x8, x8, #0x270
101174048:	ee 83 40 f9	ldr	x14, [sp, #0x100]
10117404c:	08 79 69 b8	ldr	w8, [x8, x9, lsl #2]
101174050:	08 05 00 11	add	w8, w8, #0x1
101174054:	1f 01 13 6b	cmp	w8, w19
101174058:	4b 01 00 54	b.lt	0x101174080
10117405c:	f9 9b 40 f9	ldr	x25, [sp, #0x130]
101174060:	77 00 00 14	b	0x10117423c
101174064:	e8 07 40 91	add	x8, sp, #0x1, lsl #12
101174068:	08 c1 09 91	add	x8, x8, #0x270
10117406c:	e9 af 40 f9	ldr	x9, [sp, #0x158]
101174070:	08 79 69 b8	ldr	w8, [x8, x9, lsl #2]
101174074:	08 05 00 11	add	w8, w8, #0x1
101174078:	1f 01 13 6b	cmp	w8, w19
10117407c:	0a ff ff 54	b.ge	0x10117405c
101174080:	f8 a7 00 b9	str	w24, [sp, #0xa4]
101174084:	f5 23 01 b9	str	w21, [sp, #0x120]
101174088:	14 7d 40 93	sxtw	x20, w8
10117408c:	73 7e 40 93	sxtw	x19, w19
101174090:	88 c6 28 8b	add	x8, x20, w8, sxtw #1
101174094:	19 f1 7d d3	lsl	x25, x8, #3
101174098:	e8 05 80 92	mov	x8, #-0x30
10117409c:	1b 01 19 cb	sub	x27, x8, x25
1011740a0:	98 06 00 91	add	x24, x20, #0x1
1011740a4:	f6 b3 40 f9	ldr	x22, [sp, #0x160]
1011740a8:	dc 02 40 f9	ldr	x28, [x22]
1011740ac:	08 03 80 52	mov	w8, #0x18
1011740b0:	88 72 08 9b	madd	x8, x20, x8, x28
1011740b4:	e9 02 1c cb	sub	x9, x23, x28
1011740b8:	62 03 09 8b	add	x2, x27, x9
1011740bc:	e9 f3 01 b2	mov	x9, #-0x5555555555555556
1011740c0:	69 55 95 f2	movk	x9, #0xaaab
1011740c4:	49 55 e5 f2	movk	x9, #0x2aaa, lsl #48
1011740c8:	49 7c 49 9b	smulh	x9, x2, x9
1011740cc:	2a fd 42 93	asr	x10, x9, #2
1011740d0:	5a fd 49 8b	add	x26, x10, x9, lsr #63
1011740d4:	49 07 1a 8b	add	x9, x26, x26, lsl #1
1011740d8:	35 f1 7d d3	lsl	x21, x9, #3
1011740dc:	17 01 15 8b	add	x23, x8, x21
1011740e0:	88 03 19 8b	add	x8, x28, x25
1011740e4:	00 61 00 91	add	x0, x8, #0x18
1011740e8:	01 c1 00 91	add	x1, x8, #0x30
1011740ec:	58 79 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
1011740f0:	f7 62 00 91	add	x23, x23, #0x18
1011740f4:	88 03 15 8b	add	x8, x28, x21
1011740f8:	08 01 19 8b	add	x8, x8, x25
1011740fc:	08 61 00 91	add	x8, x8, #0x18
101174100:	e9 9b 40 f9	ldr	x9, [sp, #0x130]
101174104:	28 01 00 f9	str	x8, [x9]
101174108:	94 06 00 91	add	x20, x20, #0x1
10117410c:	73 06 00 d1	sub	x19, x19, #0x1
101174110:	39 63 00 91	add	x25, x25, #0x18
101174114:	7b 63 00 d1	sub	x27, x27, #0x18
101174118:	08 07 00 91	add	x8, x24, #0x1
10117411c:	1f 03 13 eb	cmp	x24, x19
101174120:	f8 03 08 aa	mov	x24, x8
101174124:	2b fc ff 54	b.lt	0x1011740a8
101174128:	e8 07 40 91	add	x8, sp, #0x1, lsl #12
10117412c:	08 c1 01 91	add	x8, x8, #0x70
101174130:	e9 af 40 f9	ldr	x9, [sp, #0x158]
101174134:	13 79 29 b8	str	w19, [x8, x9, lsl #2]
101174138:	08 03 80 52	mov	w8, #0x18
10117413c:	48 73 08 9b	madd	x8, x26, x8, x28
101174140:	17 01 19 8b	add	x23, x8, x25
101174144:	fc e7 52 a9	ldp	x28, x25, [sp, #0x128]
101174148:	fb 9f 40 f9	ldr	x27, [sp, #0x138]
10117414c:	f6 07 40 91	add	x22, sp, #0x1, lsl #12
101174150:	d6 c2 19 91	add	x22, x22, #0x670
101174154:	1a 03 80 52	mov	w26, #0x18
101174158:	ee 83 40 f9	ldr	x14, [sp, #0x100]
10117415c:	f5 23 41 b9	ldr	w21, [sp, #0x120]
101174160:	f8 a7 40 b9	ldr	w24, [sp, #0xa4]
101174164:	36 00 00 14	b	0x10117423c
101174168:	f8 03 0a aa	mov	x24, x10
10117416c:	d9 05 00 11	add	w25, w14, #0x1
101174170:	3f 03 18 6b	cmp	w25, w24
101174174:	ea 04 00 54	b.ge	0x101174210
101174178:	20 23 ba 9b	umaddl	x0, w25, w26, x8
10117417c:	01 60 00 91	add	x1, x0, #0x18
101174180:	e2 02 01 cb	sub	x2, x23, x1
101174184:	32 79 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
101174188:	f7 62 00 d1	sub	x23, x23, #0x18
10117418c:	ea 07 40 91	add	x10, sp, #0x1, lsl #12
101174190:	4a c1 01 91	add	x10, x10, #0x70
101174194:	eb 93 40 f9	ldr	x11, [sp, #0x120]
101174198:	48 69 6b b8	ldr	w8, [x10, x11]
10117419c:	e9 9b 40 f9	ldr	x9, [sp, #0x130]
1011741a0:	37 01 00 f9	str	x23, [x9]
1011741a4:	13 05 00 51	sub	w19, w8, #0x1
1011741a8:	53 69 2b b8	str	w19, [x10, x11]
1011741ac:	14 07 00 51	sub	w20, w24, #0x1
1011741b0:	3f 03 14 6b	cmp	w25, w20
1011741b4:	8a 03 00 54	b.ge	0x101174224
1011741b8:	f5 b3 40 f9	ldr	x21, [sp, #0x160]
1011741bc:	f6 9b 40 f9	ldr	x22, [sp, #0x130]
1011741c0:	a8 02 40 f9	ldr	x8, [x21]
1011741c4:	20 23 1a 9b	madd	x0, x25, x26, x8
1011741c8:	01 60 00 91	add	x1, x0, #0x18
1011741cc:	e2 02 01 cb	sub	x2, x23, x1
1011741d0:	1f 79 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
1011741d4:	f7 62 00 d1	sub	x23, x23, #0x18
1011741d8:	d7 02 00 f9	str	x23, [x22]
1011741dc:	73 06 00 51	sub	w19, w19, #0x1
1011741e0:	94 06 00 51	sub	w20, w20, #0x1
1011741e4:	3f 03 14 6b	cmp	w25, w20
1011741e8:	cb fe ff 54	b.lt	0x1011741c0
1011741ec:	e8 07 40 91	add	x8, sp, #0x1, lsl #12
1011741f0:	08 c1 01 91	add	x8, x8, #0x70
1011741f4:	e9 af 40 f9	ldr	x9, [sp, #0x158]
1011741f8:	13 79 29 b8	str	w19, [x8, x9, lsl #2]
1011741fc:	35 00 80 52	mov	w21, #0x1
101174200:	f9 03 16 aa	mov	x25, x22
101174204:	f6 07 40 91	add	x22, sp, #0x1, lsl #12
101174208:	d6 c2 19 91	add	x22, x22, #0x670
10117420c:	08 00 00 14	b	0x10117422c
101174210:	15 00 80 52	mov	w21, #0x0
101174214:	f9 9b 40 f9	ldr	x25, [sp, #0x130]
101174218:	74 06 00 71	subs	w20, w19, #0x1
10117421c:	ea d9 ff 54	b.ge	0x101173d58
101174220:	06 00 00 14	b	0x101174238
101174224:	35 00 80 52	mov	w21, #0x1
101174228:	f9 9b 40 f9	ldr	x25, [sp, #0x130]
10117422c:	ee 83 40 f9	ldr	x14, [sp, #0x100]
101174230:	74 06 00 71	subs	w20, w19, #0x1
101174234:	2a d9 ff 54	b.ge	0x101173d58
101174238:	18 00 80 52	mov	w24, #0x0
10117423c:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
101174240:	08 01 40 f9	ldr	x8, [x8]
101174244:	e9 02 08 cb	sub	x9, x23, x8
101174248:	29 fd 43 d3	lsr	x9, x9, #3
10117424c:	6a 55 95 52	mov	w10, #0xaaab
101174250:	4a 55 b5 72	movk	w10, #0xaaaa, lsl #16
101174254:	34 7d 0a 1b	mul	w20, w9, w10
101174258:	e9 a3 40 f9	ldr	x9, [sp, #0x140]
10117425c:	ea 6b 40 f9	ldr	x10, [sp, #0xd0]
101174260:	5f 01 09 6b	cmp	w10, w9
101174264:	4c 00 00 54	b.gt	0x10117426c
101174268:	d8 07 00 34	cbz	w24, 0x101174360
10117426c:	77 06 00 11	add	w23, w19, #0x1
101174270:	ff 02 14 6b	cmp	w23, w20
101174274:	6a 07 00 54	b.ge	0x101174360
101174278:	6a 7e 3a 9b	smull	x10, w19, w26
10117427c:	00 69 6a bc	ldr	s0, [x8, x10]
101174280:	00 a4 20 0f	sshll.2d	v0, v0, #0x0
101174284:	00 d8 61 5e	scvtf	d0, d0
101174288:	69 03 40 b9	ldr	w9, [x27]
10117428c:	21 01 62 1e	scvtf	d1, w9
101174290:	0a 18 61 1e	fdiv	d10, d0, d1
101174294:	eb 7e 3a 9b	smull	x11, w23, w26
101174298:	00 69 6b bc	ldr	s0, [x8, x11]
10117429c:	00 a4 20 0f	sshll.2d	v0, v0, #0x0
1011742a0:	00 d8 61 5e	scvtf	d0, d0
1011742a4:	00 18 61 1e	fdiv	d0, d0, d1
1011742a8:	0b 38 6a 1e	fsub	d11, d0, d10
1011742ac:	0b 00 c8 d2	mov	x11, #0x400000000000
1011742b0:	eb 11 e8 f2	movk	x11, #0x408f, lsl #48
1011742b4:	60 01 67 9e	fmov	d0, x11
1011742b8:	60 09 60 1e	fmul	d0, d11, d0
1011742bc:	00 38 4c 1f	fmadd	d0, d0, d12, d14
1011742c0:	0b 00 78 1e	fcvtzs	w11, d0
1011742c4:	78 09 00 71	subs	w24, w11, #0x2
1011742c8:	cb 04 00 54	b.lt	0x101174360
1011742cc:	19 00 80 52	mov	w25, #0x0
1011742d0:	60 01 62 1e	scvtf	d0, w11
1011742d4:	ff d7 03 b9	str	wzr, [sp, #0x3d4]
1011742d8:	0b 00 80 12	mov	w11, #-0x1
1011742dc:	eb e3 03 b9	str	w11, [sp, #0x3e0]
1011742e0:	ff 93 0f 39	strb	wzr, [sp, #0x3e4]
1011742e4:	a8 19 60 1e	fdiv	d8, d13, d0
1011742e8:	5a 61 00 91	add	x26, x10, #0x18
1011742ec:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
1011742f0:	2a 07 00 11	add	w10, w25, #0x1
1011742f4:	40 01 62 1e	scvtf	d0, w10
1011742f8:	60 09 60 1e	fmul	d0, d11, d0
1011742fc:	00 28 48 1f	fmadd	d0, d0, d8, d10
101174300:	21 01 62 1e	scvtf	d1, w9
101174304:	00 38 41 1f	fmadd	d0, d0, d1, d14
101174308:	09 00 78 1e	fcvtzs	w9, d0
10117430c:	e9 d3 03 b9	str	w9, [sp, #0x3d0]
101174310:	ff ef 01 f9	str	xzr, [sp, #0x3d8]
101174314:	41 03 08 8b	add	x1, x26, x8
101174318:	e2 43 0f 91	add	x2, sp, #0x3d0
10117431c:	bf 2b ff 97	bl	__ZNSt3__16vectorIN16BeatAnalyzer_2_06peakss8BeatInfoENS_9allocatorIS3_EEE6insertENS_11__wrap_iterIPKS3_EERS8_
101174320:	f3 02 19 0b	add	w19, w23, w25
101174324:	e8 07 40 91	add	x8, sp, #0x1, lsl #12
101174328:	08 c1 01 91	add	x8, x8, #0x70
10117432c:	e9 af 40 f9	ldr	x9, [sp, #0x158]
101174330:	13 79 29 b8	str	w19, [x8, x9, lsl #2]
101174334:	1f 03 19 6b	cmp	w24, w25
101174338:	e0 00 00 54	b.eq	0x101174354
10117433c:	69 03 40 b9	ldr	w9, [x27]
101174340:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
101174344:	08 00 40 f9	ldr	x8, [x0]
101174348:	5a 63 00 91	add	x26, x26, #0x18
10117434c:	39 07 00 11	add	w25, w25, #0x1
101174350:	e8 ff ff 17	b	0x1011742f0
101174354:	f9 9b 40 f9	ldr	x25, [sp, #0x130]
101174358:	1a 03 80 52	mov	w26, #0x18
10117435c:	ee 83 40 f9	ldr	x14, [sp, #0x100]
101174360:	e8 67 40 f9	ldr	x8, [sp, #0xc8]
101174364:	1f 01 0e 6b	cmp	w8, w14
101174368:	e8 c7 9f 1a	cset	w8, le
10117436c:	a9 02 00 52	eor	w9, w21, #0x1
101174370:	08 01 09 0a	and	w8, w8, w9
101174374:	c8 08 00 37	tbnz	w8, #0x0, 0x10117448c
101174378:	e8 07 40 91	add	x8, sp, #0x1, lsl #12
10117437c:	08 c1 09 91	add	x8, x8, #0x270
101174380:	e9 af 40 f9	ldr	x9, [sp, #0x158]
101174384:	0a 79 a9 b8	ldrsw	x10, [x8, x9, lsl #2]
101174388:	4b 05 00 91	add	x11, x10, #0x1
10117438c:	7f 01 14 6b	cmp	w11, w20
101174390:	f7 07 40 91	add	x23, sp, #0x1, lsl #12
101174394:	f7 c2 11 91	add	x23, x23, #0x470
101174398:	f8 87 40 f9	ldr	x24, [sp, #0x108]
10117439c:	ea 07 00 54	b.ge	0x101174498
1011743a0:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
1011743a4:	08 01 40 f9	ldr	x8, [x8]
1011743a8:	49 7d 1a 9b	mul	x9, x10, x26
1011743ac:	00 69 69 bc	ldr	s0, [x8, x9]
1011743b0:	00 a4 20 0f	sshll.2d	v0, v0, #0x0
1011743b4:	00 d8 61 5e	scvtf	d0, d0
1011743b8:	69 03 40 b9	ldr	w9, [x27]
1011743bc:	21 01 62 1e	scvtf	d1, w9
1011743c0:	0a 18 61 1e	fdiv	d10, d0, d1
1011743c4:	6b 7d 1a 9b	mul	x11, x11, x26
1011743c8:	00 69 6b bc	ldr	s0, [x8, x11]
1011743cc:	00 a4 20 0f	sshll.2d	v0, v0, #0x0
1011743d0:	00 d8 61 5e	scvtf	d0, d0
1011743d4:	00 18 61 1e	fdiv	d0, d0, d1
1011743d8:	0b 38 6a 1e	fsub	d11, d0, d10
1011743dc:	0b 00 c8 d2	mov	x11, #0x400000000000
1011743e0:	eb 11 e8 f2	movk	x11, #0x408f, lsl #48
1011743e4:	60 01 67 9e	fmov	d0, x11
1011743e8:	60 09 60 1e	fmul	d0, d11, d0
1011743ec:	00 38 4c 1f	fmadd	d0, d0, d12, d14
1011743f0:	0b 00 78 1e	fcvtzs	w11, d0
1011743f4:	7f 09 00 71	cmp	w11, #0x2
1011743f8:	0b 05 00 54	b.lt	0x101174498
1011743fc:	60 01 62 1e	scvtf	d0, w11
101174400:	ff d7 03 b9	str	wzr, [sp, #0x3d4]
101174404:	0c 00 80 12	mov	w12, #-0x1
101174408:	ec e3 03 b9	str	w12, [sp, #0x3e0]
10117440c:	ff 93 0f 39	strb	wzr, [sp, #0x3e4]
101174410:	74 05 00 51	sub	w20, w11, #0x1
101174414:	a8 19 60 1e	fdiv	d8, d13, d0
101174418:	f6 03 13 2a	mov	w22, w19
10117441c:	eb 07 7d b2	orr	x11, xzr, #0x18
101174420:	57 2d 1a 9b	madd	x23, x10, x26, x11
101174424:	38 00 80 52	mov	w24, #0x1
101174428:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
10117442c:	00 03 62 1e	scvtf	d0, w24
101174430:	60 09 60 1e	fmul	d0, d11, d0
101174434:	00 28 48 1f	fmadd	d0, d0, d8, d10
101174438:	21 01 62 1e	scvtf	d1, w9
10117443c:	00 38 41 1f	fmadd	d0, d0, d1, d14
101174440:	09 00 78 1e	fcvtzs	w9, d0
101174444:	e9 d3 03 b9	str	w9, [sp, #0x3d0]
101174448:	ff ef 01 f9	str	xzr, [sp, #0x3d8]
10117444c:	e1 02 08 8b	add	x1, x23, x8
101174450:	e2 43 0f 91	add	x2, sp, #0x3d0
101174454:	71 2b ff 97	bl	__ZNSt3__16vectorIN16BeatAnalyzer_2_06peakss8BeatInfoENS_9allocatorIS3_EEE6insertENS_11__wrap_iterIPKS3_EERS8_
101174458:	c8 02 18 0b	add	w8, w22, w24
10117445c:	e9 07 40 91	add	x9, sp, #0x1, lsl #12
101174460:	29 c1 01 91	add	x9, x9, #0x70
101174464:	ea af 40 f9	ldr	x10, [sp, #0x158]
101174468:	28 79 2a b8	str	w8, [x9, x10, lsl #2]
10117446c:	9f 02 18 eb	cmp	x20, x24
101174470:	00 15 00 54	b.eq	0x101174710
101174474:	69 03 40 b9	ldr	w9, [x27]
101174478:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
10117447c:	08 00 40 f9	ldr	x8, [x0]
101174480:	18 07 00 91	add	x24, x24, #0x1
101174484:	f7 62 00 91	add	x23, x23, #0x18
101174488:	e9 ff ff 17	b	0x10117442c
10117448c:	f7 07 40 91	add	x23, sp, #0x1, lsl #12
101174490:	f7 c2 11 91	add	x23, x23, #0x470
101174494:	f8 87 40 f9	ldr	x24, [sp, #0x108]
101174498:	ff ef 01 f9	str	xzr, [sp, #0x3d8]
10117449c:	ff eb 01 f9	str	xzr, [sp, #0x3d0]
1011744a0:	08 00 80 12	mov	w8, #-0x1
1011744a4:	e8 e3 03 b9	str	w8, [sp, #0x3e0]
1011744a8:	ff 93 0f 39	strb	wzr, [sp, #0x3e4]
1011744ac:	f4 b3 40 f9	ldr	x20, [sp, #0x160]
1011744b0:	81 02 40 f9	ldr	x1, [x20]
1011744b4:	28 18 40 b9	ldr	w8, [x1, #0x18]
1011744b8:	29 00 40 b9	ldr	w9, [x1]
1011744bc:	08 01 09 4b	sub	w8, w8, w9
1011744c0:	28 01 08 6b	subs	w8, w9, w8
1011744c4:	8d 01 00 54	b.le	0x1011744f4
1011744c8:	e8 d3 03 b9	str	w8, [sp, #0x3d0]
1011744cc:	ff db 03 b9	str	wzr, [sp, #0x3d8]
1011744d0:	e2 43 0f 91	add	x2, sp, #0x3d0
1011744d4:	e0 03 14 aa	mov	x0, x20
1011744d8:	50 2b ff 97	bl	__ZNSt3__16vectorIN16BeatAnalyzer_2_06peakss8BeatInfoENS_9allocatorIS3_EEE6insertENS_11__wrap_iterIPKS3_EERS8_
1011744dc:	68 06 00 11	add	w8, w19, #0x1
1011744e0:	e9 07 40 91	add	x9, sp, #0x1, lsl #12
1011744e4:	29 c1 01 91	add	x9, x9, #0x70
1011744e8:	ea af 40 f9	ldr	x10, [sp, #0x158]
1011744ec:	28 79 2a b8	str	w8, [x9, x10, lsl #2]
1011744f0:	81 02 40 f9	ldr	x1, [x20]
1011744f4:	e9 f3 01 b2	mov	x9, #-0x5555555555555556
1011744f8:	69 55 95 f2	movk	x9, #0xaaab
1011744fc:	28 03 40 f9	ldr	x8, [x25]
101174500:	08 01 01 cb	sub	x8, x8, x1
101174504:	08 fd 43 93	asr	x8, x8, #3
101174508:	13 7d 09 9b	mul	x19, x8, x9
10117450c:	7f 0a 00 71	cmp	w19, #0x2
101174510:	ab 06 00 54	b.lt	0x1011745e4
101174514:	68 06 00 51	sub	w8, w19, #0x1
101174518:	09 7d ba 9b	umull	x9, w8, w26
10117451c:	2a 68 69 b8	ldr	w10, [x1, x9]
101174520:	69 7e 60 d3	lsl	x9, x19, #32
101174524:	eb 7b 5f b2	mov	x11, #-0x200000000
101174528:	2b 01 0b 8b	add	x11, x9, x11
10117452c:	6b fd 60 93	asr	x11, x11, #32
101174530:	6b 7d 1a 9b	mul	x11, x11, x26
101174534:	2b 68 6b b8	ldr	w11, [x1, x11]
101174538:	54 01 0b 6b	subs	w20, w10, w11
10117453c:	40 05 00 54	b.eq	0x1011745e4
101174540:	8b 1f 40 b9	ldr	w11, [x28, #0x1c]
101174544:	6a 01 0a 4b	sub	w10, w11, w10
101174548:	40 01 62 1e	scvtf	d0, w10
10117454c:	81 02 62 1e	scvtf	d1, w20
101174550:	00 18 61 1e	fdiv	d0, d0, d1
101174554:	00 20 6d 1e	fcmp	d0, d13
101174558:	6d 04 00 54	b.le	0x1011745e4
10117455c:	0a 00 78 1e	fcvtzs	w10, d0
101174560:	ff e3 01 f9	str	xzr, [sp, #0x3c0]
101174564:	ff df 01 f9	str	xzr, [sp, #0x3b8]
101174568:	0b 00 80 12	mov	w11, #-0x1
10117456c:	eb cb 03 b9	str	w11, [sp, #0x3c8]
101174570:	ff 33 0f 39	strb	wzr, [sp, #0x3cc]
101174574:	5f 05 00 71	cmp	w10, #0x1
101174578:	cb 02 00 54	b.lt	0x1011745d0
10117457c:	29 fd 60 93	asr	x9, x9, #32
101174580:	08 05 08 8b	add	x8, x8, x8, lsl #1
101174584:	16 f1 7d d3	lsl	x22, x8, #3
101174588:	28 05 09 8b	add	x8, x9, x9, lsl #1
10117458c:	17 f1 7d d3	lsl	x23, x8, #3
101174590:	58 05 00 d1	sub	x24, x10, #0x1
101174594:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
101174598:	28 68 76 b8	ldr	w8, [x1, x22]
10117459c:	08 01 14 0b	add	w8, w8, w20
1011745a0:	e8 bb 03 b9	str	w8, [sp, #0x3b8]
1011745a4:	ff e3 01 f9	str	xzr, [sp, #0x3c0]
1011745a8:	e1 02 01 8b	add	x1, x23, x1
1011745ac:	e2 e3 0e 91	add	x2, sp, #0x3b8
1011745b0:	1a 2b ff 97	bl	__ZNSt3__16vectorIN16BeatAnalyzer_2_06peakss8BeatInfoENS_9allocatorIS3_EEE6insertENS_11__wrap_iterIPKS3_EERS8_
1011745b4:	f8 00 00 b4	cbz	x24, 0x1011745d0
1011745b8:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
1011745bc:	01 00 40 f9	ldr	x1, [x0]
1011745c0:	d6 62 00 91	add	x22, x22, #0x18
1011745c4:	f7 62 00 91	add	x23, x23, #0x18
1011745c8:	18 07 00 d1	sub	x24, x24, #0x1
1011745cc:	f3 ff ff 17	b	0x101174598
1011745d0:	f7 07 40 91	add	x23, sp, #0x1, lsl #12
1011745d4:	f7 c2 11 91	add	x23, x23, #0x470
1011745d8:	f6 07 40 91	add	x22, sp, #0x1, lsl #12
1011745dc:	d6 c2 19 91	add	x22, x22, #0x670
1011745e0:	f8 87 40 f9	ldr	x24, [sp, #0x108]
1011745e4:	e8 c3 40 b9	ldr	w8, [sp, #0xc0]
1011745e8:	48 e5 01 34	cbz	w8, 0x101178290
1011745ec:	29 03 40 f9	ldr	x9, [x25]
1011745f0:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
1011745f4:	08 01 40 f9	ldr	x8, [x8]
1011745f8:	29 01 08 cb	sub	x9, x9, x8
1011745fc:	29 fd 43 d3	lsr	x9, x9, #3
101174600:	6a 55 95 52	mov	w10, #0xaaab
101174604:	4a 55 b5 72	movk	w10, #0xaaaa, lsl #16
101174608:	33 7d 0a 1b	mul	w19, w9, w10
10117460c:	69 0a 00 51	sub	w9, w19, #0x2
101174610:	3f 05 00 71	cmp	w9, #0x1
101174614:	2a c5 9f 1a	csinc	w10, w9, wzr, gt
101174618:	0f 06 80 52	mov	w15, #0x30
10117461c:	2b 00 80 52	mov	w11, #0x1
101174620:	7f 01 0a eb	cmp	x11, x10
101174624:	60 e3 01 54	b.eq	0x101178290
101174628:	e9 03 0b aa	mov	x9, x11
10117462c:	f4 03 0f aa	mov	x20, x15
101174630:	6b 21 1a 9b	madd	x11, x11, x26, x8
101174634:	70 01 40 b9	ldr	w16, [x11]
101174638:	6d 81 5e b8	ldur	w13, [x11, #-0x18]
10117463c:	2b 05 00 91	add	x11, x9, #0x1
101174640:	6c 7d 40 92	and	x12, x11, #0xffffffff
101174644:	8c 7d 1a 9b	mul	x12, x12, x26
101174648:	0c 69 6c b8	ldr	w12, [x8, x12]
10117464c:	0f 02 0d 4b	sub	w15, w16, w13
101174650:	2d 09 00 11	add	w13, w9, #0x2
101174654:	ad 7d ba 9b	umull	x13, w13, w26
101174658:	0e 69 6d b8	ldr	w14, [x8, x13]
10117465c:	cd 01 0c 4b	sub	w13, w14, w12
101174660:	f1 09 0f 0b	add	w17, w15, w15, lsl #2
101174664:	a0 09 0d 0b	add	w0, w13, w13, lsl #2
101174668:	8f 62 00 91	add	x15, x20, #0x18
10117466c:	90 01 10 4b	sub	w16, w12, w16
101174670:	1f 02 11 6b	cmp	w16, w17
101174674:	00 d2 40 7a	ccmp	w16, w0, #0x0, le
101174678:	4d fd ff 54	b.le	0x101174620
10117467c:	df 01 0c 6b	cmp	w14, w12
101174680:	80 e0 01 54	b.eq	0x101178290
101174684:	00 02 62 1e	scvtf	d0, w16
101174688:	a1 01 62 1e	scvtf	d1, w13
10117468c:	01 18 61 1e	fdiv	d1, d0, d1
101174690:	20 20 6d 1e	fcmp	d1, d13
101174694:	ed df 01 54	b.le	0x101178290
101174698:	2a 00 78 1e	fcvtzs	w10, d1
10117469c:	ff e3 01 f9	str	xzr, [sp, #0x3c0]
1011746a0:	ff df 01 f9	str	xzr, [sp, #0x3b8]
1011746a4:	0b 00 80 12	mov	w11, #-0x1
1011746a8:	eb cb 03 b9	str	w11, [sp, #0x3c8]
1011746ac:	ff 33 0f 39	strb	wzr, [sp, #0x3cc]
1011746b0:	5f 09 00 71	cmp	w10, #0x2
1011746b4:	2b de 01 54	b.lt	0x101178278
1011746b8:	21 c0 65 1e	frintz	d1, d1
1011746bc:	00 18 61 1e	fdiv	d0, d0, d1
1011746c0:	16 00 78 1e	fcvtzs	w22, d0
1011746c4:	37 7d 40 92	and	x23, x9, #0xffffffff
1011746c8:	58 09 00 d1	sub	x24, x10, #0x2
1011746cc:	f9 03 16 aa	mov	x25, x22
1011746d0:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
1011746d4:	e9 7e 1a 9b	mul	x9, x23, x26
1011746d8:	09 69 69 b8	ldr	w9, [x8, x9]
1011746dc:	29 03 09 0b	add	w9, w25, w9
1011746e0:	e9 bb 03 b9	str	w9, [sp, #0x3b8]
1011746e4:	ff e3 01 f9	str	xzr, [sp, #0x3c0]
1011746e8:	81 02 08 8b	add	x1, x20, x8
1011746ec:	e2 e3 0e 91	add	x2, sp, #0x3b8
1011746f0:	ca 2a ff 97	bl	__ZNSt3__16vectorIN16BeatAnalyzer_2_06peakss8BeatInfoENS_9allocatorIS3_EEE6insertENS_11__wrap_iterIPKS3_EERS8_
1011746f4:	38 dc 01 b4	cbz	x24, 0x101178278
1011746f8:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
1011746fc:	08 00 40 f9	ldr	x8, [x0]
101174700:	39 03 16 0b	add	w25, w25, w22
101174704:	94 62 00 91	add	x20, x20, #0x18
101174708:	18 07 00 d1	sub	x24, x24, #0x1
10117470c:	f2 ff ff 17	b	0x1011746d4
101174710:	73 02 18 0b	add	w19, w19, w24
101174714:	f7 07 40 91	add	x23, sp, #0x1, lsl #12
101174718:	f7 c2 11 91	add	x23, x23, #0x470
10117471c:	f6 07 40 91	add	x22, sp, #0x1, lsl #12
101174720:	d6 c2 19 91	add	x22, x22, #0x670
101174724:	5c ff ff 17	b	0x101174494
101174728:	0a 0f 00 91	add	x10, x24, #0x3
10117472c:	80 7a 6a fc	ldr	d0, [x20, x10, lsl #3]
101174730:	c1 01 67 9e	fmov	d1, x14
101174734:	00 20 61 1e	fcmp	d0, d1
101174738:	e9 a3 90 d2	mov	x9, #0x851f
10117473c:	69 3d aa f2	movk	x9, #0x51eb, lsl #16
101174740:	09 d7 c3 f2	movk	x9, #0x1eb8, lsl #32
101174744:	29 fe e7 f2	movk	x9, #0x3ff1, lsl #48
101174748:	21 01 67 9e	fmov	d1, x9
10117474c:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
101174750:	fc 97 40 f9	ldr	x28, [sp, #0x128]
101174754:	2c 03 00 54	b.gt	0x1011747b8
101174758:	e1 01 67 9e	fmov	d1, x15
10117475c:	00 20 61 1e	fcmp	d0, d1
101174760:	cc 02 00 54	b.gt	0x1011747b8
101174764:	f8 03 11 aa	mov	x24, x17
101174768:	1f fc ff 17	b	0x1011737e4
10117476c:	08 16 00 51	sub	w8, w16, #0x5
101174770:	7f 01 08 6b	cmp	w11, w8
101174774:	ec 01 00 54	b.gt	0x1011747b0
101174778:	68 11 00 11	add	w8, w11, #0x4
10117477c:	80 da 68 fc	ldr	d0, [x20, w8, sxtw #3]
101174780:	c1 01 67 9e	fmov	d1, x14
101174784:	00 20 61 1e	fcmp	d0, d1
101174788:	ea a3 90 d2	mov	x10, #0x851f
10117478c:	6a 3d aa f2	movk	x10, #0x51eb, lsl #16
101174790:	0a d7 c3 f2	movk	x10, #0x1eb8, lsl #32
101174794:	2a fe e7 f2	movk	x10, #0x3ff1, lsl #48
101174798:	41 01 67 9e	fmov	d1, x10
10117479c:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
1011747a0:	0c 78 01 54	b.gt	0x1011776a0
1011747a4:	e1 01 67 9e	fmov	d1, x15
1011747a8:	00 20 61 1e	fcmp	d0, d1
1011747ac:	ac 77 01 54	b.gt	0x1011776a0
1011747b0:	eb 03 0c aa	mov	x11, x12
1011747b4:	8d fc ff 17	b	0x1011739e8
1011747b8:	09 16 00 51	sub	w9, w16, #0x5
1011747bc:	1f 03 09 6b	cmp	w24, w9
1011747c0:	ec 01 00 54	b.gt	0x1011747fc
1011747c4:	09 13 00 91	add	x9, x24, #0x4
1011747c8:	80 7a 69 fc	ldr	d0, [x20, x9, lsl #3]
1011747cc:	c1 01 67 9e	fmov	d1, x14
1011747d0:	00 20 61 1e	fcmp	d0, d1
1011747d4:	ec a3 90 d2	mov	x12, #0x851f
1011747d8:	6c 3d aa f2	movk	x12, #0x51eb, lsl #16
1011747dc:	0c d7 c3 f2	movk	x12, #0x1eb8, lsl #32
1011747e0:	2c fe e7 f2	movk	x12, #0x3ff1, lsl #48
1011747e4:	81 01 67 9e	fmov	d1, x12
1011747e8:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
1011747ec:	ac 78 01 54	b.gt	0x101177700
1011747f0:	e1 01 67 9e	fmov	d1, x15
1011747f4:	00 20 61 1e	fcmp	d0, d1
1011747f8:	4c 78 01 54	b.gt	0x101177700
1011747fc:	f8 03 0a aa	mov	x24, x10
101174800:	f9 fb ff 17	b	0x1011737e4
101174804:	4b 11 00 11	add	w11, w10, #0x4
101174808:	80 da 6b fc	ldr	d0, [x20, w11, sxtw #3]
10117480c:	e8 a3 90 d2	mov	x8, #0x851f
101174810:	68 3d aa f2	movk	x8, #0x51eb, lsl #16
101174814:	08 d7 c3 f2	movk	x8, #0x1eb8, lsl #32
101174818:	28 fe e7 f2	movk	x8, #0x3ff1, lsl #48
10117481c:	01 01 67 9e	fmov	d1, x8
101174820:	00 20 61 1e	fcmp	d0, d1
101174824:	cd 00 00 54	b.le	0x10117483c
101174828:	e8 e7 02 b2	mov	x8, #-0x3333333333333334
10117482c:	c8 fe e7 f2	movk	x8, #0x3ff6, lsl #48
101174830:	01 01 67 9e	fmov	d1, x8
101174834:	00 20 61 1e	fcmp	d0, d1
101174838:	4b 01 00 54	b.lt	0x101174860
10117483c:	e8 e7 00 b2	mov	x8, #0x3333333333333333
101174840:	88 66 86 f2	movk	x8, #0x3334
101174844:	28 ff e7 f2	movk	x8, #0x3ff9, lsl #48
101174848:	01 01 67 9e	fmov	d1, x8
10117484c:	00 20 61 1e	fcmp	d0, d1
101174850:	0d c3 fd 54	b.le	0x1011700b0
101174854:	a1 01 67 9e	fmov	d1, x13
101174858:	00 20 61 1e	fcmp	d0, d1
10117485c:	aa c2 fd 54	b.ge	0x1011700b0
101174860:	08 1a 00 51	sub	w8, w16, #0x6
101174864:	5f 01 08 6b	cmp	w10, w8
101174868:	ec ba fd 54	b.gt	0x10116ffc4
10117486c:	48 15 00 11	add	w8, w10, #0x5
101174870:	80 da 68 fc	ldr	d0, [x20, w8, sxtw #3]
101174874:	ea a3 90 d2	mov	x10, #0x851f
101174878:	6a 3d aa f2	movk	x10, #0x51eb, lsl #16
10117487c:	0a d7 c3 f2	movk	x10, #0x1eb8, lsl #32
101174880:	2a fe e7 f2	movk	x10, #0x3ff1, lsl #48
101174884:	41 01 67 9e	fmov	d1, x10
101174888:	00 20 61 1e	fcmp	d0, d1
10117488c:	ea f3 01 b2	mov	x10, #-0x5555555555555556
101174890:	6a 55 95 f2	movk	x10, #0xaaab
101174894:	cd 00 00 54	b.le	0x1011748ac
101174898:	ec e7 02 b2	mov	x12, #-0x3333333333333334
10117489c:	cc fe e7 f2	movk	x12, #0x3ff6, lsl #48
1011748a0:	81 01 67 9e	fmov	d1, x12
1011748a4:	00 20 61 1e	fcmp	d0, d1
1011748a8:	4b 01 00 54	b.lt	0x1011748d0
1011748ac:	ec e7 00 b2	mov	x12, #0x3333333333333333
1011748b0:	8c 66 86 f2	movk	x12, #0x3334
1011748b4:	2c ff e7 f2	movk	x12, #0x3ff9, lsl #48
1011748b8:	81 01 67 9e	fmov	d1, x12
1011748bc:	00 20 61 1e	fcmp	d0, d1
1011748c0:	ed bf fd 54	b.le	0x1011700bc
1011748c4:	a1 01 67 9e	fmov	d1, x13
1011748c8:	00 20 61 1e	fcmp	d0, d1
1011748cc:	8a bf fd 54	b.ge	0x1011700bc
1011748d0:	31 00 80 52	mov	w17, #0x1
1011748d4:	eb 03 08 aa	mov	x11, x8
1011748d8:	f9 ed ff 17	b	0x1011700bc
1011748dc:	50 13 00 91	add	x16, x26, #0x4
1011748e0:	eb 8b 40 f9	ldr	x11, [sp, #0x110]
1011748e4:	60 79 70 fc	ldr	d0, [x11, x16, lsl #3]
1011748e8:	eb a3 90 d2	mov	x11, #0x851f
1011748ec:	6b 3d aa f2	movk	x11, #0x51eb, lsl #16
1011748f0:	0b d7 c3 f2	movk	x11, #0x1eb8, lsl #32
1011748f4:	2b fe e7 f2	movk	x11, #0x3ff1, lsl #48
1011748f8:	61 01 67 9e	fmov	d1, x11
1011748fc:	00 20 61 1e	fcmp	d0, d1
101174900:	cd 00 00 54	b.le	0x101174918
101174904:	eb e7 02 b2	mov	x11, #-0x3333333333333334
101174908:	cb fe e7 f2	movk	x11, #0x3ff6, lsl #48
10117490c:	61 01 67 9e	fmov	d1, x11
101174910:	00 20 61 1e	fcmp	d0, d1
101174914:	4b 01 00 54	b.lt	0x10117493c
101174918:	eb e7 00 b2	mov	x11, #0x3333333333333333
10117491c:	8b 66 86 f2	movk	x11, #0x3334
101174920:	2b ff e7 f2	movk	x11, #0x3ff9, lsl #48
101174924:	61 01 67 9e	fmov	d1, x11
101174928:	00 20 61 1e	fcmp	d0, d1
10117492c:	ad 88 fd 54	b.le	0x10116fa40
101174930:	c1 01 67 9e	fmov	d1, x14
101174934:	00 20 61 1e	fcmp	d0, d1
101174938:	4a 88 fd 54	b.ge	0x10116fa40
10117493c:	ea 19 00 51	sub	w10, w15, #0x6
101174940:	5f 03 0a 6b	cmp	w26, w10
101174944:	cd 63 01 54	b.le	0x1011775bc
101174948:	18 03 80 52	mov	w24, #0x18
10117494c:	e0 a3 40 f9	ldr	x0, [sp, #0x140]
101174950:	0b 05 00 71	subs	w11, w8, #0x1
101174954:	4b 02 00 54	b.lt	0x10117499c
101174958:	ea 8b 40 f9	ldr	x10, [sp, #0x110]
10117495c:	40 59 6b fc	ldr	d0, [x10, w11, uxtw #3]
101174960:	ea a3 90 d2	mov	x10, #0x851f
101174964:	6a 3d aa f2	movk	x10, #0x51eb, lsl #16
101174968:	0a d7 c3 f2	movk	x10, #0x1eb8, lsl #32
10117496c:	2a fe e7 f2	movk	x10, #0x3ff1, lsl #48
101174970:	41 01 67 9e	fmov	d1, x10
101174974:	00 20 61 1e	fcmp	d0, d1
101174978:	6d 01 00 54	b.le	0x1011749a4
10117497c:	ea e7 02 b2	mov	x10, #-0x3333333333333334
101174980:	ca fe e7 f2	movk	x10, #0x3ff6, lsl #48
101174984:	41 01 67 9e	fmov	d1, x10
101174988:	00 20 61 1e	fcmp	d0, d1
10117498c:	ca 00 00 54	b.ge	0x1011749a4
101174990:	1f 09 00 71	cmp	w8, #0x2
101174994:	6a 02 00 54	b.ge	0x1011749e0
101174998:	78 00 00 14	b	0x101174b78
10117499c:	ea 03 08 aa	mov	x10, x8
1011749a0:	77 00 00 14	b	0x101174b7c
1011749a4:	ea e7 00 b2	mov	x10, #0x3333333333333333
1011749a8:	8a 66 86 f2	movk	x10, #0x3334
1011749ac:	2a ff e7 f2	movk	x10, #0x3ff9, lsl #48
1011749b0:	41 01 67 9e	fmov	d1, x10
1011749b4:	00 20 61 1e	fcmp	d0, d1
1011749b8:	ea c7 9f 1a	cset	w10, le
1011749bc:	c1 01 67 9e	fmov	d1, x14
1011749c0:	00 20 61 1e	fcmp	d0, d1
1011749c4:	ec b7 9f 1a	cset	w12, ge
1011749c8:	4c 01 0c 2a	orr	w12, w10, w12
1011749cc:	9f 01 00 71	cmp	w12, #0x0
1011749d0:	0a 11 9f 1a	csel	w10, w8, wzr, ne
1011749d4:	4c 0d 00 37	tbnz	w12, #0x0, 0x101174b7c
1011749d8:	1f 09 00 71	cmp	w8, #0x2
1011749dc:	0b 0d 00 54	b.lt	0x101174b7c
1011749e0:	0a 09 00 51	sub	w10, w8, #0x2
1011749e4:	ec 8b 40 f9	ldr	x12, [sp, #0x110]
1011749e8:	80 59 6a fc	ldr	d0, [x12, w10, uxtw #3]
1011749ec:	ec a3 90 d2	mov	x12, #0x851f
1011749f0:	6c 3d aa f2	movk	x12, #0x51eb, lsl #16
1011749f4:	0c d7 c3 f2	movk	x12, #0x1eb8, lsl #32
1011749f8:	2c fe e7 f2	movk	x12, #0x3ff1, lsl #48
1011749fc:	81 01 67 9e	fmov	d1, x12
101174a00:	00 20 61 1e	fcmp	d0, d1
101174a04:	cd 00 00 54	b.le	0x101174a1c
101174a08:	ec e7 02 b2	mov	x12, #-0x3333333333333334
101174a0c:	cc fe e7 f2	movk	x12, #0x3ff6, lsl #48
101174a10:	81 01 67 9e	fmov	d1, x12
101174a14:	00 20 61 1e	fcmp	d0, d1
101174a18:	4b 01 00 54	b.lt	0x101174a40
101174a1c:	ec e7 00 b2	mov	x12, #0x3333333333333333
101174a20:	8c 66 86 f2	movk	x12, #0x3334
101174a24:	2c ff e7 f2	movk	x12, #0x3ff9, lsl #48
101174a28:	81 01 67 9e	fmov	d1, x12
101174a2c:	00 20 61 1e	fcmp	d0, d1
101174a30:	0d 0a 00 54	b.le	0x101174b70
101174a34:	c1 01 67 9e	fmov	d1, x14
101174a38:	00 20 61 1e	fcmp	d0, d1
101174a3c:	aa 09 00 54	b.ge	0x101174b70
101174a40:	0b 0d 00 71	subs	w11, w8, #0x3
101174a44:	a3 09 00 54	b.lo	0x101174b78
101174a48:	ec 8b 40 f9	ldr	x12, [sp, #0x110]
101174a4c:	80 59 6b fc	ldr	d0, [x12, w11, uxtw #3]
101174a50:	ec a3 90 d2	mov	x12, #0x851f
101174a54:	6c 3d aa f2	movk	x12, #0x51eb, lsl #16
101174a58:	0c d7 c3 f2	movk	x12, #0x1eb8, lsl #32
101174a5c:	2c fe e7 f2	movk	x12, #0x3ff1, lsl #48
101174a60:	81 01 67 9e	fmov	d1, x12
101174a64:	00 20 61 1e	fcmp	d0, d1
101174a68:	cd 00 00 54	b.le	0x101174a80
101174a6c:	ec e7 02 b2	mov	x12, #-0x3333333333333334
101174a70:	cc fe e7 f2	movk	x12, #0x3ff6, lsl #48
101174a74:	81 01 67 9e	fmov	d1, x12
101174a78:	00 20 61 1e	fcmp	d0, d1
101174a7c:	4b 01 00 54	b.lt	0x101174aa4
101174a80:	ec e7 00 b2	mov	x12, #0x3333333333333333
101174a84:	8c 66 86 f2	movk	x12, #0x3334
101174a88:	2c ff e7 f2	movk	x12, #0x3ff9, lsl #48
101174a8c:	81 01 67 9e	fmov	d1, x12
101174a90:	00 20 61 1e	fcmp	d0, d1
101174a94:	4d 07 00 54	b.le	0x101174b7c
101174a98:	c1 01 67 9e	fmov	d1, x14
101174a9c:	00 20 61 1e	fcmp	d0, d1
101174aa0:	ea 06 00 54	b.ge	0x101174b7c
101174aa4:	0a 11 00 71	subs	w10, w8, #0x4
101174aa8:	83 06 00 54	b.lo	0x101174b78
101174aac:	ec 8b 40 f9	ldr	x12, [sp, #0x110]
101174ab0:	80 59 6a fc	ldr	d0, [x12, w10, uxtw #3]
101174ab4:	ec a3 90 d2	mov	x12, #0x851f
101174ab8:	6c 3d aa f2	movk	x12, #0x51eb, lsl #16
101174abc:	0c d7 c3 f2	movk	x12, #0x1eb8, lsl #32
101174ac0:	2c fe e7 f2	movk	x12, #0x3ff1, lsl #48
101174ac4:	81 01 67 9e	fmov	d1, x12
101174ac8:	00 20 61 1e	fcmp	d0, d1
101174acc:	cd 00 00 54	b.le	0x101174ae4
101174ad0:	ec e7 02 b2	mov	x12, #-0x3333333333333334
101174ad4:	cc fe e7 f2	movk	x12, #0x3ff6, lsl #48
101174ad8:	81 01 67 9e	fmov	d1, x12
101174adc:	00 20 61 1e	fcmp	d0, d1
101174ae0:	4b 01 00 54	b.lt	0x101174b08
101174ae4:	ec e7 00 b2	mov	x12, #0x3333333333333333
101174ae8:	8c 66 86 f2	movk	x12, #0x3334
101174aec:	2c ff e7 f2	movk	x12, #0x3ff9, lsl #48
101174af0:	81 01 67 9e	fmov	d1, x12
101174af4:	00 20 61 1e	fcmp	d0, d1
101174af8:	cd 03 00 54	b.le	0x101174b70
101174afc:	c1 01 67 9e	fmov	d1, x14
101174b00:	00 20 61 1e	fcmp	d0, d1
101174b04:	6a 03 00 54	b.ge	0x101174b70
101174b08:	0b 15 00 71	subs	w11, w8, #0x5
101174b0c:	63 03 00 54	b.lo	0x101174b78
101174b10:	ec 8b 40 f9	ldr	x12, [sp, #0x110]
101174b14:	80 59 6b fc	ldr	d0, [x12, w11, uxtw #3]
101174b18:	ec a3 90 d2	mov	x12, #0x851f
101174b1c:	6c 3d aa f2	movk	x12, #0x51eb, lsl #16
101174b20:	0c d7 c3 f2	movk	x12, #0x1eb8, lsl #32
101174b24:	2c fe e7 f2	movk	x12, #0x3ff1, lsl #48
101174b28:	81 01 67 9e	fmov	d1, x12
101174b2c:	00 20 61 1e	fcmp	d0, d1
101174b30:	cd 00 00 54	b.le	0x101174b48
101174b34:	ec e7 02 b2	mov	x12, #-0x3333333333333334
101174b38:	cc fe e7 f2	movk	x12, #0x3ff6, lsl #48
101174b3c:	81 01 67 9e	fmov	d1, x12
101174b40:	00 20 61 1e	fcmp	d0, d1
101174b44:	4b 01 00 54	b.lt	0x101174b6c
101174b48:	ec e7 00 b2	mov	x12, #0x3333333333333333
101174b4c:	8c 66 86 f2	movk	x12, #0x3334
101174b50:	2c ff e7 f2	movk	x12, #0x3ff9, lsl #48
101174b54:	81 01 67 9e	fmov	d1, x12
101174b58:	00 20 61 1e	fcmp	d0, d1
101174b5c:	0d 01 00 54	b.le	0x101174b7c
101174b60:	c1 01 67 9e	fmov	d1, x14
101174b64:	00 20 61 1e	fcmp	d0, d1
101174b68:	aa 00 00 54	b.ge	0x101174b7c
101174b6c:	31 00 80 52	mov	w17, #0x1
101174b70:	ea 03 0b aa	mov	x10, x11
101174b74:	02 00 00 14	b	0x101174b7c
101174b78:	0a 00 80 52	mov	w10, #0x0
101174b7c:	1f 01 09 6b	cmp	w8, w9
101174b80:	f0 83 00 f9	str	x16, [sp, #0x100]
101174b84:	6d 00 00 54	b.le	0x101174b90
101174b88:	e9 03 08 aa	mov	x9, x8
101174b8c:	71 00 00 14	b	0x101174d50
101174b90:	09 05 00 11	add	w9, w8, #0x1
101174b94:	eb 8b 40 f9	ldr	x11, [sp, #0x110]
101174b98:	60 d9 69 fc	ldr	d0, [x11, w9, sxtw #3]
101174b9c:	eb a3 90 d2	mov	x11, #0x851f
101174ba0:	6b 3d aa f2	movk	x11, #0x51eb, lsl #16
101174ba4:	0b d7 c3 f2	movk	x11, #0x1eb8, lsl #32
101174ba8:	2b fe e7 f2	movk	x11, #0x3ff1, lsl #48
101174bac:	61 01 67 9e	fmov	d1, x11
101174bb0:	00 20 61 1e	fcmp	d0, d1
101174bb4:	cd 00 00 54	b.le	0x101174bcc
101174bb8:	eb e7 02 b2	mov	x11, #-0x3333333333333334
101174bbc:	cb fe e7 f2	movk	x11, #0x3ff6, lsl #48
101174bc0:	61 01 67 9e	fmov	d1, x11
101174bc4:	00 20 61 1e	fcmp	d0, d1
101174bc8:	4b 01 00 54	b.lt	0x101174bf0
101174bcc:	eb e7 00 b2	mov	x11, #0x3333333333333333
101174bd0:	8b 66 86 f2	movk	x11, #0x3334
101174bd4:	2b ff e7 f2	movk	x11, #0x3ff9, lsl #48
101174bd8:	61 01 67 9e	fmov	d1, x11
101174bdc:	00 20 61 1e	fcmp	d0, d1
101174be0:	4d fd ff 54	b.le	0x101174b88
101174be4:	c1 01 67 9e	fmov	d1, x14
101174be8:	00 20 61 1e	fcmp	d0, d1
101174bec:	ea fc ff 54	b.ge	0x101174b88
101174bf0:	eb 0d 00 51	sub	w11, w15, #0x3
101174bf4:	1f 01 0b 6b	cmp	w8, w11
101174bf8:	cc 0a 00 54	b.gt	0x101174d50
101174bfc:	0b 09 00 11	add	w11, w8, #0x2
101174c00:	ec 8b 40 f9	ldr	x12, [sp, #0x110]
101174c04:	80 d9 6b fc	ldr	d0, [x12, w11, sxtw #3]
101174c08:	ec a3 90 d2	mov	x12, #0x851f
101174c0c:	6c 3d aa f2	movk	x12, #0x51eb, lsl #16
101174c10:	0c d7 c3 f2	movk	x12, #0x1eb8, lsl #32
101174c14:	2c fe e7 f2	movk	x12, #0x3ff1, lsl #48
101174c18:	81 01 67 9e	fmov	d1, x12
101174c1c:	00 20 61 1e	fcmp	d0, d1
101174c20:	cd 00 00 54	b.le	0x101174c38
101174c24:	ec e7 02 b2	mov	x12, #-0x3333333333333334
101174c28:	cc fe e7 f2	movk	x12, #0x3ff6, lsl #48
101174c2c:	81 01 67 9e	fmov	d1, x12
101174c30:	00 20 61 1e	fcmp	d0, d1
101174c34:	4b 01 00 54	b.lt	0x101174c5c
101174c38:	ec e7 00 b2	mov	x12, #0x3333333333333333
101174c3c:	8c 66 86 f2	movk	x12, #0x3334
101174c40:	2c ff e7 f2	movk	x12, #0x3ff9, lsl #48
101174c44:	81 01 67 9e	fmov	d1, x12
101174c48:	00 20 61 1e	fcmp	d0, d1
101174c4c:	2d 08 00 54	b.le	0x101174d50
101174c50:	c1 01 67 9e	fmov	d1, x14
101174c54:	00 20 61 1e	fcmp	d0, d1
101174c58:	ca 07 00 54	b.ge	0x101174d50
101174c5c:	e9 11 00 51	sub	w9, w15, #0x4
101174c60:	1f 01 09 6b	cmp	w8, w9
101174c64:	6d 00 00 54	b.le	0x101174c70
101174c68:	e9 03 0b aa	mov	x9, x11
101174c6c:	39 00 00 14	b	0x101174d50
101174c70:	0c 0d 00 11	add	w12, w8, #0x3
101174c74:	e9 8b 40 f9	ldr	x9, [sp, #0x110]
101174c78:	20 d9 6c fc	ldr	d0, [x9, w12, sxtw #3]
101174c7c:	e9 a3 90 d2	mov	x9, #0x851f
101174c80:	69 3d aa f2	movk	x9, #0x51eb, lsl #16
101174c84:	09 d7 c3 f2	movk	x9, #0x1eb8, lsl #32
101174c88:	29 fe e7 f2	movk	x9, #0x3ff1, lsl #48
101174c8c:	21 01 67 9e	fmov	d1, x9
101174c90:	00 20 61 1e	fcmp	d0, d1
101174c94:	cd 00 00 54	b.le	0x101174cac
101174c98:	e9 e7 02 b2	mov	x9, #-0x3333333333333334
101174c9c:	c9 fe e7 f2	movk	x9, #0x3ff6, lsl #48
101174ca0:	21 01 67 9e	fmov	d1, x9
101174ca4:	00 20 61 1e	fcmp	d0, d1
101174ca8:	4b 01 00 54	b.lt	0x101174cd0
101174cac:	e9 e7 00 b2	mov	x9, #0x3333333333333333
101174cb0:	89 66 86 f2	movk	x9, #0x3334
101174cb4:	29 ff e7 f2	movk	x9, #0x3ff9, lsl #48
101174cb8:	21 01 67 9e	fmov	d1, x9
101174cbc:	00 20 61 1e	fcmp	d0, d1
101174cc0:	4d fd ff 54	b.le	0x101174c68
101174cc4:	c1 01 67 9e	fmov	d1, x14
101174cc8:	00 20 61 1e	fcmp	d0, d1
101174ccc:	ea fc ff 54	b.ge	0x101174c68
101174cd0:	e9 15 00 51	sub	w9, w15, #0x5
101174cd4:	1f 01 09 6b	cmp	w8, w9
101174cd8:	6d 00 00 54	b.le	0x101174ce4
101174cdc:	e9 03 0c aa	mov	x9, x12
101174ce0:	1c 00 00 14	b	0x101174d50
101174ce4:	09 11 00 11	add	w9, w8, #0x4
101174ce8:	eb 8b 40 f9	ldr	x11, [sp, #0x110]
101174cec:	60 d9 69 fc	ldr	d0, [x11, w9, sxtw #3]
101174cf0:	eb a3 90 d2	mov	x11, #0x851f
101174cf4:	6b 3d aa f2	movk	x11, #0x51eb, lsl #16
101174cf8:	0b d7 c3 f2	movk	x11, #0x1eb8, lsl #32
101174cfc:	2b fe e7 f2	movk	x11, #0x3ff1, lsl #48
101174d00:	61 01 67 9e	fmov	d1, x11
101174d04:	00 20 61 1e	fcmp	d0, d1
101174d08:	cd 00 00 54	b.le	0x101174d20
101174d0c:	eb e7 02 b2	mov	x11, #-0x3333333333333334
101174d10:	cb fe e7 f2	movk	x11, #0x3ff6, lsl #48
101174d14:	61 01 67 9e	fmov	d1, x11
101174d18:	00 20 61 1e	fcmp	d0, d1
101174d1c:	4b 01 00 54	b.lt	0x101174d44
101174d20:	eb e7 00 b2	mov	x11, #0x3333333333333333
101174d24:	8b 66 86 f2	movk	x11, #0x3334
101174d28:	2b ff e7 f2	movk	x11, #0x3ff9, lsl #48
101174d2c:	61 01 67 9e	fmov	d1, x11
101174d30:	00 20 61 1e	fcmp	d0, d1
101174d34:	4d fd ff 54	b.le	0x101174cdc
101174d38:	c1 01 67 9e	fmov	d1, x14
101174d3c:	00 20 61 1e	fcmp	d0, d1
101174d40:	ea fc ff 54	b.ge	0x101174cdc
101174d44:	eb 19 00 51	sub	w11, w15, #0x6
101174d48:	1f 01 0b 6b	cmp	w8, w11
101174d4c:	2d 47 01 54	b.le	0x101177630
101174d50:	5f 01 00 71	cmp	w10, #0x0
101174d54:	57 c1 9f 1a	csel	w23, w10, wzr, gt
101174d58:	b9 01 40 f9	ldr	x25, [x13]
101174d5c:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
101174d60:	08 01 40 f9	ldr	x8, [x8]
101174d64:	2a 03 08 cb	sub	x10, x25, x8
101174d68:	4a fd 43 93	asr	x10, x10, #3
101174d6c:	eb f3 01 b2	mov	x11, #-0x5555555555555556
101174d70:	6b 55 95 f2	movk	x11, #0xaaab
101174d74:	4a 7d 0b 9b	mul	x10, x10, x11
101174d78:	4b 05 00 d1	sub	x11, x10, #0x1
101174d7c:	4c 05 00 51	sub	w12, w10, #0x1
101174d80:	7f c1 29 eb	cmp	x11, w9, sxtw
101174d84:	89 31 89 1a	csel	w9, w12, w9, lo
101174d88:	3f 01 17 6b	cmp	w9, w23
101174d8c:	e9 93 00 f9	str	x9, [sp, #0x120]
101174d90:	f1 cb 00 b9	str	w17, [sp, #0xc8]
101174d94:	f7 6b 00 f9	str	x23, [sp, #0xd0]
101174d98:	ed 04 00 54	b.le	0x101174e34
101174d9c:	f6 03 0d aa	mov	x22, x13
101174da0:	fa 03 1c aa	mov	x26, x28
101174da4:	fc 03 01 aa	mov	x28, x1
101174da8:	f4 03 00 aa	mov	x20, x0
101174dac:	33 7d 40 93	sxtw	x19, w9
101174db0:	20 21 38 9b	smaddl	x0, w9, w24, x8
101174db4:	01 60 00 91	add	x1, x0, #0x18
101174db8:	22 03 01 cb	sub	x2, x25, x1
101174dbc:	24 76 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
101174dc0:	39 63 00 d1	sub	x25, x25, #0x18
101174dc4:	d9 02 00 f9	str	x25, [x22]
101174dc8:	73 06 00 d1	sub	x19, x19, #0x1
101174dcc:	7f 02 17 eb	cmp	x19, x23
101174dd0:	f5 b3 40 f9	ldr	x21, [sp, #0x160]
101174dd4:	6d 01 00 54	b.le	0x101174e00
101174dd8:	a8 02 40 f9	ldr	x8, [x21]
101174ddc:	60 22 18 9b	madd	x0, x19, x24, x8
101174de0:	01 60 00 91	add	x1, x0, #0x18
101174de4:	22 03 01 cb	sub	x2, x25, x1
101174de8:	19 76 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
101174dec:	39 63 00 d1	sub	x25, x25, #0x18
101174df0:	d9 02 00 f9	str	x25, [x22]
101174df4:	73 06 00 d1	sub	x19, x19, #0x1
101174df8:	7f 02 17 eb	cmp	x19, x23
101174dfc:	ec fe ff 54	b.gt	0x101174dd8
101174e00:	a8 02 40 f9	ldr	x8, [x21]
101174e04:	29 03 08 cb	sub	x9, x25, x8
101174e08:	29 fd 43 93	asr	x9, x9, #3
101174e0c:	ea f3 01 b2	mov	x10, #-0x5555555555555556
101174e10:	6a 55 95 f2	movk	x10, #0xaaab
101174e14:	2a 7d 0a 9b	mul	x10, x9, x10
101174e18:	4b 05 00 d1	sub	x11, x10, #0x1
101174e1c:	4c 05 00 51	sub	w12, w10, #0x1
101174e20:	f3 af 40 f9	ldr	x19, [sp, #0x158]
101174e24:	e0 03 14 aa	mov	x0, x20
101174e28:	e1 03 1c aa	mov	x1, x28
101174e2c:	fc 03 1a aa	mov	x28, x26
101174e30:	02 00 00 14	b	0x101174e38
101174e34:	f7 03 09 aa	mov	x23, x9
101174e38:	17 00 00 b9	str	w23, [x0]
101174e3c:	3f 00 00 71	cmp	w1, #0x0
101174e40:	36 c0 9f 1a	csel	w22, w1, wzr, gt
101174e44:	fa 83 40 f9	ldr	x26, [sp, #0x100]
101174e48:	7f c1 3a eb	cmp	x11, w26, sxtw
101174e4c:	89 31 9a 1a	csel	w9, w12, w26, lo
101174e50:	3f 01 16 6b	cmp	w9, w22
101174e54:	f5 07 40 91	add	x21, sp, #0x1, lsl #12
101174e58:	b5 c2 19 91	add	x21, x21, #0x670
101174e5c:	e9 83 00 f9	str	x9, [sp, #0x100]
101174e60:	4d 08 00 54	b.le	0x101174f68
101174e64:	34 7d 40 93	sxtw	x20, w9
101174e68:	f3 03 00 aa	mov	x19, x0
101174e6c:	20 21 38 9b	smaddl	x0, w9, w24, x8
101174e70:	01 60 00 91	add	x1, x0, #0x18
101174e74:	22 03 01 cb	sub	x2, x25, x1
101174e78:	f5 75 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
101174e7c:	e0 03 13 aa	mov	x0, x19
101174e80:	39 63 00 d1	sub	x25, x25, #0x18
101174e84:	e8 9b 40 f9	ldr	x8, [sp, #0x130]
101174e88:	19 01 00 f9	str	x25, [x8]
101174e8c:	68 02 40 b9	ldr	w8, [x19]
101174e90:	17 05 00 51	sub	w23, w8, #0x1
101174e94:	77 02 00 b9	str	w23, [x19]
101174e98:	93 06 00 d1	sub	x19, x20, #0x1
101174e9c:	7f 02 16 eb	cmp	x19, x22
101174ea0:	6d 05 00 54	b.le	0x101174f4c
101174ea4:	88 06 14 8b	add	x8, x20, x20, lsl #1
101174ea8:	fc 03 16 aa	mov	x28, x22
101174eac:	16 f1 7d d3	lsl	x22, x8, #3
101174eb0:	e8 02 80 92	mov	x8, #-0x18
101174eb4:	94 7e 08 9b	mul	x20, x20, x8
101174eb8:	f5 b3 40 f9	ldr	x21, [sp, #0x160]
101174ebc:	fa 9b 40 f9	ldr	x26, [sp, #0x130]
101174ec0:	b8 02 40 f9	ldr	x24, [x21]
101174ec4:	28 03 18 cb	sub	x8, x25, x24
101174ec8:	82 02 08 8b	add	x2, x20, x8
101174ecc:	e8 f3 01 b2	mov	x8, #-0x5555555555555556
101174ed0:	68 55 95 f2	movk	x8, #0xaaab
101174ed4:	48 55 e5 f2	movk	x8, #0x2aaa, lsl #48
101174ed8:	48 7c 48 9b	smulh	x8, x2, x8
101174edc:	09 fd 42 93	asr	x9, x8, #2
101174ee0:	3b fd 48 8b	add	x27, x9, x8, lsr #63
101174ee4:	01 03 16 8b	add	x1, x24, x22
101174ee8:	20 60 00 d1	sub	x0, x1, #0x18
101174eec:	d8 75 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
101174ef0:	08 03 80 52	mov	w8, #0x18
101174ef4:	68 5b 08 9b	madd	x8, x27, x8, x22
101174ef8:	08 03 08 8b	add	x8, x24, x8
101174efc:	19 61 00 d1	sub	x25, x8, #0x18
101174f00:	59 03 00 f9	str	x25, [x26]
101174f04:	f7 06 00 51	sub	w23, w23, #0x1
101174f08:	73 06 00 d1	sub	x19, x19, #0x1
101174f0c:	d6 62 00 d1	sub	x22, x22, #0x18
101174f10:	94 62 00 91	add	x20, x20, #0x18
101174f14:	7f 02 1c eb	cmp	x19, x28
101174f18:	4c fd ff 54	b.gt	0x101174ec0
101174f1c:	e0 a3 40 f9	ldr	x0, [sp, #0x140]
101174f20:	17 00 00 b9	str	w23, [x0]
101174f24:	08 03 80 52	mov	w8, #0x18
101174f28:	68 63 08 9b	madd	x8, x27, x8, x24
101174f2c:	19 01 14 cb	sub	x25, x8, x20
101174f30:	fb 9f 40 f9	ldr	x27, [sp, #0x138]
101174f34:	f5 07 40 91	add	x21, sp, #0x1, lsl #12
101174f38:	b5 c2 19 91	add	x21, x21, #0x670
101174f3c:	18 03 80 52	mov	w24, #0x18
101174f40:	e8 97 40 f9	ldr	x8, [sp, #0x128]
101174f44:	f6 03 1c aa	mov	x22, x28
101174f48:	fc 03 08 aa	mov	x28, x8
101174f4c:	f3 a3 55 a9	ldp	x19, x8, [sp, #0x158]
101174f50:	08 01 40 f9	ldr	x8, [x8]
101174f54:	29 03 08 cb	sub	x9, x25, x8
101174f58:	29 fd 43 d3	lsr	x9, x9, #3
101174f5c:	6a 55 95 52	mov	w10, #0xaaab
101174f60:	4a 55 b5 72	movk	w10, #0xaaaa, lsl #16
101174f64:	2a 7d 0a 1b	mul	w10, w9, w10
101174f68:	b6 7a 33 b8	str	w22, [x21, x19, lsl #2]
101174f6c:	49 01 16 6b	subs	w9, w10, w22
101174f70:	4d 09 00 54	b.le	0x101175098
101174f74:	4a 15 00 51	sub	w10, w10, #0x5
101174f78:	df 02 0a 6b	cmp	w22, w10
101174f7c:	aa 00 80 52	mov	w10, #0x5
101174f80:	29 c1 8a 1a	csel	w9, w9, w10, gt
101174f84:	3f 05 00 71	cmp	w9, #0x1
101174f88:	f5 93 40 f9	ldr	x21, [sp, #0x120]
101174f8c:	2b 08 00 54	b.lt	0x101175090
101174f90:	ca 7e b8 9b	umull	x10, w22, w24
101174f94:	00 69 6a bc	ldr	s0, [x8, x10]
101174f98:	00 a4 20 0f	sshll.2d	v0, v0, #0x0
101174f9c:	00 d8 61 5e	scvtf	d0, d0
101174fa0:	61 03 40 bd	ldr	s1, [x27]
101174fa4:	21 a4 20 0f	sshll.2d	v1, v1, #0x0
101174fa8:	23 d8 61 5e	scvtf	d3, d1
101174fac:	01 18 63 1e	fdiv	d1, d0, d3
101174fb0:	29 7d 40 93	sxtw	x9, w9
101174fb4:	e0 7f 40 fd	ldr	d0, [sp, #0xf8]
101174fb8:	22 28 60 1e	fadd	d2, d1, d0
101174fbc:	a0 19 63 1e	fdiv	d0, d13, d3
101174fc0:	ca 06 00 91	add	x10, x22, #0x1
101174fc4:	cb 22 18 9b	madd	x11, x22, x24, x8
101174fc8:	6b 61 00 91	add	x11, x11, #0x18
101174fcc:	ec 03 0b aa	mov	x12, x11
101174fd0:	f4 03 0a aa	mov	x20, x10
101174fd4:	ed 03 09 aa	mov	x13, x9
101174fd8:	83 01 40 bd	ldr	s3, [x12]
101174fdc:	63 a4 20 0f	sshll.2d	v3, v3, #0x0
101174fe0:	63 d8 61 5e	scvtf	d3, d3
101174fe4:	63 08 60 1e	fmul	d3, d3, d0
101174fe8:	64 38 69 1e	fsub	d4, d3, d9
101174fec:	63 28 69 1e	fadd	d3, d3, d9
101174ff0:	40 20 64 1e	fcmp	d2, d4
101174ff4:	40 c4 63 1e	fccmp	d2, d3, #0x0, gt
101174ff8:	8b 05 00 54	b.lt	0x1011750a8
101174ffc:	94 06 00 91	add	x20, x20, #0x1
101175000:	8c 61 00 91	add	x12, x12, #0x18
101175004:	ad 05 00 f1	subs	x13, x13, #0x1
101175008:	81 fe ff 54	b.ne	0x101174fd8
10117500c:	e2 5f 40 fd	ldr	d2, [sp, #0xb8]
101175010:	22 28 62 1e	fadd	d2, d1, d2
101175014:	ec 03 0b aa	mov	x12, x11
101175018:	f4 03 0a aa	mov	x20, x10
10117501c:	ed 03 09 aa	mov	x13, x9
101175020:	83 01 40 bd	ldr	s3, [x12]
101175024:	63 a4 20 0f	sshll.2d	v3, v3, #0x0
101175028:	63 d8 61 5e	scvtf	d3, d3
10117502c:	63 08 60 1e	fmul	d3, d3, d0
101175030:	64 38 69 1e	fsub	d4, d3, d9
101175034:	63 28 69 1e	fadd	d3, d3, d9
101175038:	40 20 64 1e	fcmp	d2, d4
10117503c:	40 c4 63 1e	fccmp	d2, d3, #0x0, gt
101175040:	4b 03 00 54	b.lt	0x1011750a8
101175044:	94 06 00 91	add	x20, x20, #0x1
101175048:	8c 61 00 91	add	x12, x12, #0x18
10117504c:	ad 05 00 f1	subs	x13, x13, #0x1
101175050:	81 fe ff 54	b.ne	0x101175020
101175054:	e2 3f 40 fd	ldr	d2, [sp, #0x78]
101175058:	21 28 62 1e	fadd	d1, d1, d2
10117505c:	62 01 40 bd	ldr	s2, [x11]
101175060:	42 a4 20 0f	sshll.2d	v2, v2, #0x0
101175064:	42 d8 61 5e	scvtf	d2, d2
101175068:	42 08 60 1e	fmul	d2, d2, d0
10117506c:	43 38 69 1e	fsub	d3, d2, d9
101175070:	42 28 69 1e	fadd	d2, d2, d9
101175074:	20 20 63 1e	fcmp	d1, d3
101175078:	20 c4 62 1e	fccmp	d1, d2, #0x0, gt
10117507c:	4b 01 00 54	b.lt	0x1011750a4
101175080:	4a 05 00 91	add	x10, x10, #0x1
101175084:	6b 61 00 91	add	x11, x11, #0x18
101175088:	29 05 00 f1	subs	x9, x9, #0x1
10117508c:	81 fe ff 54	b.ne	0x10117505c
101175090:	0e 00 80 52	mov	w14, #0x0
101175094:	30 00 00 14	b	0x101175154
101175098:	0e 00 80 52	mov	w14, #0x0
10117509c:	f5 93 40 f9	ldr	x21, [sp, #0x120]
1011750a0:	2d 00 00 14	b	0x101175154
1011750a4:	f4 03 0a aa	mov	x20, x10
1011750a8:	d3 06 00 11	add	w19, w22, #0x1
1011750ac:	7f 02 14 6b	cmp	w19, w20
1011750b0:	8a 04 00 54	b.ge	0x101175140
1011750b4:	fa 03 00 aa	mov	x26, x0
1011750b8:	60 22 b8 9b	umaddl	x0, w19, w24, x8
1011750bc:	01 60 00 91	add	x1, x0, #0x18
1011750c0:	22 03 01 cb	sub	x2, x25, x1
1011750c4:	62 75 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
1011750c8:	39 63 00 d1	sub	x25, x25, #0x18
1011750cc:	e8 9b 40 f9	ldr	x8, [sp, #0x130]
1011750d0:	19 01 00 f9	str	x25, [x8]
1011750d4:	48 03 40 b9	ldr	w8, [x26]
1011750d8:	17 05 00 51	sub	w23, w8, #0x1
1011750dc:	57 03 00 b9	str	w23, [x26]
1011750e0:	94 06 00 51	sub	w20, w20, #0x1
1011750e4:	7f 02 14 6b	cmp	w19, w20
1011750e8:	0a 03 00 54	b.ge	0x101175148
1011750ec:	fc 03 16 aa	mov	x28, x22
1011750f0:	f5 b3 40 f9	ldr	x21, [sp, #0x160]
1011750f4:	f6 9b 40 f9	ldr	x22, [sp, #0x130]
1011750f8:	a8 02 40 f9	ldr	x8, [x21]
1011750fc:	60 22 18 9b	madd	x0, x19, x24, x8
101175100:	01 60 00 91	add	x1, x0, #0x18
101175104:	22 03 01 cb	sub	x2, x25, x1
101175108:	51 75 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
10117510c:	39 63 00 d1	sub	x25, x25, #0x18
101175110:	d9 02 00 f9	str	x25, [x22]
101175114:	f7 06 00 51	sub	w23, w23, #0x1
101175118:	94 06 00 51	sub	w20, w20, #0x1
10117511c:	7f 02 14 6b	cmp	w19, w20
101175120:	cb fe ff 54	b.lt	0x1011750f8
101175124:	e0 03 1a aa	mov	x0, x26
101175128:	57 03 00 b9	str	w23, [x26]
10117512c:	2e 00 80 52	mov	w14, #0x1
101175130:	f3 af 40 f9	ldr	x19, [sp, #0x158]
101175134:	f6 03 1c aa	mov	x22, x28
101175138:	f5 73 52 a9	ldp	x21, x28, [sp, #0x120]
10117513c:	06 00 00 14	b	0x101175154
101175140:	0e 00 80 52	mov	w14, #0x0
101175144:	03 00 00 14	b	0x101175150
101175148:	e0 03 1a aa	mov	x0, x26
10117514c:	2e 00 80 52	mov	w14, #0x1
101175150:	f3 af 40 f9	ldr	x19, [sp, #0x158]
101175154:	f4 06 00 71	subs	w20, w23, #0x1
101175158:	eb 08 00 54	b.lt	0x101175274
10117515c:	f6 63 00 f9	str	x22, [sp, #0xc0]
101175160:	ea 03 17 2a	mov	w10, w23
101175164:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
101175168:	08 01 40 f9	ldr	x8, [x8]
10117516c:	ec 22 b8 9b	umaddl	x12, w23, w24, x8
101175170:	80 01 40 bd	ldr	s0, [x12]
101175174:	00 a4 20 0f	sshll.2d	v0, v0, #0x0
101175178:	00 d8 61 5e	scvtf	d0, d0
10117517c:	61 03 40 bd	ldr	s1, [x27]
101175180:	21 a4 20 0f	sshll.2d	v1, v1, #0x0
101175184:	21 d8 61 5e	scvtf	d1, d1
101175188:	00 18 61 1e	fdiv	d0, d0, d1
10117518c:	ff 16 00 71	cmp	w23, #0x5
101175190:	a9 00 80 52	mov	w9, #0x5
101175194:	eb b2 89 1a	csel	w11, w23, w9, lt
101175198:	e2 7f 40 fd	ldr	d2, [sp, #0xf8]
10117519c:	02 38 62 1e	fsub	d2, d0, d2
1011751a0:	49 05 00 d1	sub	x9, x10, #0x1
1011751a4:	83 81 5e bc	ldur	s3, [x12, #-0x18]
1011751a8:	63 a4 20 0f	sshll.2d	v3, v3, #0x0
1011751ac:	63 d8 61 5e	scvtf	d3, d3
1011751b0:	63 18 61 1e	fdiv	d3, d3, d1
1011751b4:	64 38 69 1e	fsub	d4, d3, d9
1011751b8:	63 28 69 1e	fadd	d3, d3, d9
1011751bc:	40 20 64 1e	fcmp	d2, d4
1011751c0:	40 c4 63 1e	fccmp	d2, d3, #0x0, gt
1011751c4:	f6 03 09 aa	mov	x22, x9
1011751c8:	4b 0c 00 54	b.lt	0x101175350
1011751cc:	6b 05 00 11	add	w11, w11, #0x1
1011751d0:	7f 09 00 71	cmp	w11, #0x2
1011751d4:	41 05 00 54	b.ne	0x10117527c
1011751d8:	e2 5f 40 fd	ldr	d2, [sp, #0xb8]
1011751dc:	02 38 62 1e	fsub	d2, d0, d2
1011751e0:	6b 05 00 d1	sub	x11, x11, #0x1
1011751e4:	4a 21 18 9b	madd	x10, x10, x24, x8
1011751e8:	4a 61 00 d1	sub	x10, x10, #0x18
1011751ec:	ec 03 0a aa	mov	x12, x10
1011751f0:	f6 03 09 aa	mov	x22, x9
1011751f4:	ed 03 0b aa	mov	x13, x11
1011751f8:	a1 19 61 1e	fdiv	d1, d13, d1
1011751fc:	83 01 40 bd	ldr	s3, [x12]
101175200:	63 a4 20 0f	sshll.2d	v3, v3, #0x0
101175204:	63 d8 61 5e	scvtf	d3, d3
101175208:	63 08 61 1e	fmul	d3, d3, d1
10117520c:	64 38 69 1e	fsub	d4, d3, d9
101175210:	63 28 69 1e	fadd	d3, d3, d9
101175214:	40 20 64 1e	fcmp	d2, d4
101175218:	40 c4 63 1e	fccmp	d2, d3, #0x0, gt
10117521c:	ab 09 00 54	b.lt	0x101175350
101175220:	d6 06 00 d1	sub	x22, x22, #0x1
101175224:	8c 61 00 d1	sub	x12, x12, #0x18
101175228:	ad 05 00 d1	sub	x13, x13, #0x1
10117522c:	8d fe ff b5	cbnz	x13, 0x1011751fc
101175230:	e2 3f 40 fd	ldr	d2, [sp, #0x78]
101175234:	00 38 62 1e	fsub	d0, d0, d2
101175238:	42 01 40 bd	ldr	s2, [x10]
10117523c:	42 a4 20 0f	sshll.2d	v2, v2, #0x0
101175240:	42 d8 61 5e	scvtf	d2, d2
101175244:	42 08 61 1e	fmul	d2, d2, d1
101175248:	43 38 69 1e	fsub	d3, d2, d9
10117524c:	42 28 69 1e	fadd	d2, d2, d9
101175250:	00 20 63 1e	fcmp	d0, d3
101175254:	00 c4 62 1e	fccmp	d0, d2, #0x0, gt
101175258:	ab 07 00 54	b.lt	0x10117534c
10117525c:	29 05 00 d1	sub	x9, x9, #0x1
101175260:	4a 61 00 d1	sub	x10, x10, #0x18
101175264:	6b 05 00 d1	sub	x11, x11, #0x1
101175268:	8b fe ff b5	cbnz	x11, 0x101175238
10117526c:	f6 03 17 aa	mov	x22, x23
101175270:	38 00 00 14	b	0x101175350
101175274:	0c 00 80 52	mov	w12, #0x0
101175278:	9d 00 00 14	b	0x1011754ec
10117527c:	56 09 00 d1	sub	x22, x10, #0x2
101175280:	cc 7e 18 9b	mul	x12, x22, x24
101175284:	03 69 6c bc	ldr	s3, [x8, x12]
101175288:	63 a4 20 0f	sshll.2d	v3, v3, #0x0
10117528c:	63 d8 61 5e	scvtf	d3, d3
101175290:	63 18 61 1e	fdiv	d3, d3, d1
101175294:	64 38 69 1e	fsub	d4, d3, d9
101175298:	63 28 69 1e	fadd	d3, d3, d9
10117529c:	40 20 64 1e	fcmp	d2, d4
1011752a0:	40 c4 63 1e	fccmp	d2, d3, #0x0, gt
1011752a4:	6b 05 00 54	b.lt	0x101175350
1011752a8:	7f 0d 00 71	cmp	w11, #0x3
1011752ac:	60 f9 ff 54	b.eq	0x1011751d8
1011752b0:	56 0d 00 d1	sub	x22, x10, #0x3
1011752b4:	cc 7e 18 9b	mul	x12, x22, x24
1011752b8:	03 69 6c bc	ldr	s3, [x8, x12]
1011752bc:	63 a4 20 0f	sshll.2d	v3, v3, #0x0
1011752c0:	63 d8 61 5e	scvtf	d3, d3
1011752c4:	63 18 61 1e	fdiv	d3, d3, d1
1011752c8:	64 38 69 1e	fsub	d4, d3, d9
1011752cc:	63 28 69 1e	fadd	d3, d3, d9
1011752d0:	40 20 64 1e	fcmp	d2, d4
1011752d4:	40 c4 63 1e	fccmp	d2, d3, #0x0, gt
1011752d8:	cb 03 00 54	b.lt	0x101175350
1011752dc:	7f 11 00 71	cmp	w11, #0x4
1011752e0:	c0 f7 ff 54	b.eq	0x1011751d8
1011752e4:	56 11 00 d1	sub	x22, x10, #0x4
1011752e8:	cc 7e 18 9b	mul	x12, x22, x24
1011752ec:	03 69 6c bc	ldr	s3, [x8, x12]
1011752f0:	63 a4 20 0f	sshll.2d	v3, v3, #0x0
1011752f4:	63 d8 61 5e	scvtf	d3, d3
1011752f8:	63 18 61 1e	fdiv	d3, d3, d1
1011752fc:	64 38 69 1e	fsub	d4, d3, d9
101175300:	63 28 69 1e	fadd	d3, d3, d9
101175304:	40 20 64 1e	fcmp	d2, d4
101175308:	40 c4 63 1e	fccmp	d2, d3, #0x0, gt
10117530c:	2b 02 00 54	b.lt	0x101175350
101175310:	7f 15 00 71	cmp	w11, #0x5
101175314:	20 f6 ff 54	b.eq	0x1011751d8
101175318:	56 15 00 d1	sub	x22, x10, #0x5
10117531c:	cc 7e 18 9b	mul	x12, x22, x24
101175320:	03 69 6c bc	ldr	s3, [x8, x12]
101175324:	63 a4 20 0f	sshll.2d	v3, v3, #0x0
101175328:	63 d8 61 5e	scvtf	d3, d3
10117532c:	63 18 61 1e	fdiv	d3, d3, d1
101175330:	64 38 69 1e	fsub	d4, d3, d9
101175334:	40 20 64 1e	fcmp	d2, d4
101175338:	0d f5 ff 54	b.le	0x1011751d8
10117533c:	63 28 69 1e	fadd	d3, d3, d9
101175340:	40 20 63 1e	fcmp	d2, d3
101175344:	6b 00 00 54	b.lt	0x101175350
101175348:	a4 ff ff 17	b	0x1011751d8
10117534c:	f6 03 09 aa	mov	x22, x9
101175350:	9f 02 16 6b	cmp	w20, w22
101175354:	ec d7 9f 1a	cset	w12, gt
101175358:	ec a7 00 b9	str	w12, [sp, #0xa4]
10117535c:	6d 05 00 54	b.le	0x101175408
101175360:	fc 03 0e aa	mov	x28, x14
101175364:	fa 03 00 aa	mov	x26, x0
101175368:	80 22 38 9b	smaddl	x0, w20, w24, x8
10117536c:	01 60 00 91	add	x1, x0, #0x18
101175370:	22 03 01 cb	sub	x2, x25, x1
101175374:	b6 74 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
101175378:	39 63 00 d1	sub	x25, x25, #0x18
10117537c:	e8 9b 40 f9	ldr	x8, [sp, #0x130]
101175380:	19 01 00 f9	str	x25, [x8]
101175384:	c8 06 00 11	add	w8, w22, #0x1
101175388:	1f 01 14 6b	cmp	w8, w20
10117538c:	40 02 00 54	b.eq	0x1011753d4
101175390:	94 7e 40 93	sxtw	x20, w20
101175394:	f3 0a 00 51	sub	w19, w23, #0x2
101175398:	f5 b3 40 f9	ldr	x21, [sp, #0x160]
10117539c:	f7 9b 40 f9	ldr	x23, [sp, #0x130]
1011753a0:	a8 02 40 f9	ldr	x8, [x21]
1011753a4:	80 22 18 9b	madd	x0, x20, x24, x8
1011753a8:	01 60 00 91	add	x1, x0, #0x18
1011753ac:	22 03 01 cb	sub	x2, x25, x1
1011753b0:	a7 74 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
1011753b4:	39 63 00 d1	sub	x25, x25, #0x18
1011753b8:	f9 02 00 f9	str	x25, [x23]
1011753bc:	73 06 00 51	sub	w19, w19, #0x1
1011753c0:	df 02 13 6b	cmp	w22, w19
1011753c4:	e1 fe ff 54	b.ne	0x1011753a0
1011753c8:	74 06 00 11	add	w20, w19, #0x1
1011753cc:	f3 af 40 f9	ldr	x19, [sp, #0x158]
1011753d0:	f5 93 40 f9	ldr	x21, [sp, #0x120]
1011753d4:	54 03 00 b9	str	w20, [x26]
1011753d8:	f7 03 14 aa	mov	x23, x20
1011753dc:	e8 07 40 91	add	x8, sp, #0x1, lsl #12
1011753e0:	08 c1 19 91	add	x8, x8, #0x670
1011753e4:	ee 03 1c aa	mov	x14, x28
1011753e8:	fc 97 40 f9	ldr	x28, [sp, #0x128]
1011753ec:	ec a7 40 b9	ldr	w12, [sp, #0xa4]
1011753f0:	08 79 73 b8	ldr	w8, [x8, x19, lsl #2]
1011753f4:	08 05 00 11	add	w8, w8, #0x1
1011753f8:	1f 01 17 6b	cmp	w8, w23
1011753fc:	2b 01 00 54	b.lt	0x101175420
101175400:	f6 63 40 f9	ldr	x22, [sp, #0xc0]
101175404:	3a 00 00 14	b	0x1011754ec
101175408:	e8 07 40 91	add	x8, sp, #0x1, lsl #12
10117540c:	08 c1 19 91	add	x8, x8, #0x670
101175410:	08 79 73 b8	ldr	w8, [x8, x19, lsl #2]
101175414:	08 05 00 11	add	w8, w8, #0x1
101175418:	1f 01 17 6b	cmp	w8, w23
10117541c:	2a ff ff 54	b.ge	0x101175400
101175420:	ee 77 00 b9	str	w14, [sp, #0x74]
101175424:	14 7d 40 93	sxtw	x20, w8
101175428:	f7 7e 40 93	sxtw	x23, w23
10117542c:	88 c6 28 8b	add	x8, x20, w8, sxtw #1
101175430:	16 f1 7d d3	lsl	x22, x8, #3
101175434:	e8 05 80 92	mov	x8, #-0x30
101175438:	1b 01 16 cb	sub	x27, x8, x22
10117543c:	93 06 00 91	add	x19, x20, #0x1
101175440:	fa 9b 40 f9	ldr	x26, [sp, #0x130]
101175444:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
101175448:	18 01 40 f9	ldr	x24, [x8]
10117544c:	08 03 80 52	mov	w8, #0x18
101175450:	88 62 08 9b	madd	x8, x20, x8, x24
101175454:	29 03 18 cb	sub	x9, x25, x24
101175458:	62 03 09 8b	add	x2, x27, x9
10117545c:	e9 f3 01 b2	mov	x9, #-0x5555555555555556
101175460:	69 55 95 f2	movk	x9, #0xaaab
101175464:	49 55 e5 f2	movk	x9, #0x2aaa, lsl #48
101175468:	49 7c 49 9b	smulh	x9, x2, x9
10117546c:	2a fd 42 93	asr	x10, x9, #2
101175470:	5c fd 49 8b	add	x28, x10, x9, lsr #63
101175474:	89 07 1c 8b	add	x9, x28, x28, lsl #1
101175478:	35 f1 7d d3	lsl	x21, x9, #3
10117547c:	19 01 15 8b	add	x25, x8, x21
101175480:	08 03 16 8b	add	x8, x24, x22
101175484:	00 61 00 91	add	x0, x8, #0x18
101175488:	01 c1 00 91	add	x1, x8, #0x30
10117548c:	70 74 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
101175490:	39 63 00 91	add	x25, x25, #0x18
101175494:	08 03 15 8b	add	x8, x24, x21
101175498:	08 01 16 8b	add	x8, x8, x22
10117549c:	08 61 00 91	add	x8, x8, #0x18
1011754a0:	48 03 00 f9	str	x8, [x26]
1011754a4:	94 06 00 91	add	x20, x20, #0x1
1011754a8:	f7 06 00 d1	sub	x23, x23, #0x1
1011754ac:	d6 62 00 91	add	x22, x22, #0x18
1011754b0:	7b 63 00 d1	sub	x27, x27, #0x18
1011754b4:	68 06 00 91	add	x8, x19, #0x1
1011754b8:	7f 02 17 eb	cmp	x19, x23
1011754bc:	f3 03 08 aa	mov	x19, x8
1011754c0:	2b fc ff 54	b.lt	0x101175444
1011754c4:	fb a3 53 a9	ldp	x27, x8, [sp, #0x138]
1011754c8:	17 01 00 b9	str	w23, [x8]
1011754cc:	08 03 80 52	mov	w8, #0x18
1011754d0:	88 63 08 9b	madd	x8, x28, x8, x24
1011754d4:	19 01 16 8b	add	x25, x8, x22
1011754d8:	f5 73 52 a9	ldp	x21, x28, [sp, #0x120]
1011754dc:	f3 af 40 f9	ldr	x19, [sp, #0x158]
1011754e0:	f6 63 40 f9	ldr	x22, [sp, #0xc0]
1011754e4:	ee 77 40 b9	ldr	w14, [sp, #0x74]
1011754e8:	ec a7 40 b9	ldr	w12, [sp, #0xa4]
1011754ec:	e8 6b 40 f9	ldr	x8, [sp, #0xd0]
1011754f0:	bf 02 08 6b	cmp	w21, w8
1011754f4:	e9 d7 9f 1a	cset	w9, gt
1011754f8:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
1011754fc:	08 01 40 f9	ldr	x8, [x8]
101175500:	2a 03 08 cb	sub	x10, x25, x8
101175504:	4a fd 43 d3	lsr	x10, x10, #3
101175508:	6b 55 95 52	mov	w11, #0xaaab
10117550c:	4b 55 b5 72	movk	w11, #0xaaaa, lsl #16
101175510:	58 7d 0b 1b	mul	w24, w10, w11
101175514:	ff ef 01 f9	str	xzr, [sp, #0x3d8]
101175518:	ff eb 01 f9	str	xzr, [sp, #0x3d0]
10117551c:	0a 00 80 12	mov	w10, #-0x1
101175520:	ea e3 03 b9	str	w10, [sp, #0x3e0]
101175524:	ff 93 0f 39	strb	wzr, [sp, #0x3e4]
101175528:	39 01 0c 2a	orr	w25, w9, w12
10117552c:	09 07 00 51	sub	w9, w24, #0x1
101175530:	ff 02 09 6b	cmp	w23, w9
101175534:	e9 17 9f 1a	cset	w9, eq
101175538:	3f 03 00 72	tst	w25, #0x1
10117553c:	2a 00 80 52	mov	w10, #0x1
101175540:	49 11 89 1a	csel	w9, w10, w9, ne
101175544:	ea 83 40 f9	ldr	x10, [sp, #0x100]
101175548:	5f 01 16 6b	cmp	w10, w22
10117554c:	ea d7 9f 1a	cset	w10, gt
101175550:	0b 0b 00 51	sub	w11, w24, #0x2
101175554:	e9 02 09 4b	sub	w9, w23, w9
101175558:	3f 01 0b 6b	cmp	w9, w11
10117555c:	29 b1 8b 1a	csel	w9, w9, w11, lt
101175560:	56 01 0e 2a	orr	w22, w10, w14
101175564:	ea 07 40 91	add	x10, sp, #0x1, lsl #12
101175568:	4a c1 19 91	add	x10, x10, #0x670
10117556c:	54 79 b3 b8	ldrsw	x20, [x10, x19, lsl #2]
101175570:	9a 02 16 8b	add	x26, x20, x22
101175574:	3f 01 1a 6b	cmp	w9, w26
101175578:	eb 07 00 54	b.lt	0x101175674
10117557c:	38 7d 40 93	sxtw	x24, w9
101175580:	f7 0a 00 11	add	w23, w23, #0x2
101175584:	09 c7 29 8b	add	x9, x24, w9, sxtw #1
101175588:	3b f1 7d d3	lsl	x27, x9, #3
10117558c:	f5 b3 40 f9	ldr	x21, [sp, #0x160]
101175590:	01 01 1b 8b	add	x1, x8, x27
101175594:	29 8c 41 b8	ldr	w9, [x1, #0x18]!
101175598:	08 69 7b b8	ldr	w8, [x8, x27]
10117559c:	29 01 08 4b	sub	w9, w9, w8
1011755a0:	20 01 62 1e	scvtf	d0, w9
1011755a4:	f3 9f 40 f9	ldr	x19, [sp, #0x138]
1011755a8:	61 02 40 bd	ldr	s1, [x19]
1011755ac:	21 a4 20 0f	sshll.2d	v1, v1, #0x0
1011755b0:	21 d8 61 5e	scvtf	d1, d1
1011755b4:	e9 f3 00 b2	mov	x9, #0x5555555555555555
1011755b8:	a9 fa e7 f2	movk	x9, #0x3fd5, lsl #48
1011755bc:	22 01 67 9e	fmov	d2, x9
1011755c0:	00 08 62 1e	fmul	d0, d0, d2
1011755c4:	08 18 61 1e	fdiv	d8, d0, d1
1011755c8:	00 01 62 1e	scvtf	d0, w8
1011755cc:	02 29 68 1e	fadd	d2, d8, d8
1011755d0:	00 28 6e 1e	fadd	d0, d0, d14
1011755d4:	20 00 42 1f	fmadd	d0, d1, d2, d0
1011755d8:	08 00 78 1e	fcvtzs	w8, d0
1011755dc:	e8 d3 03 b9	str	w8, [sp, #0x3d0]
1011755e0:	ff ef 01 f9	str	xzr, [sp, #0x3d8]
1011755e4:	e2 43 0f 91	add	x2, sp, #0x3d0
1011755e8:	e0 03 15 aa	mov	x0, x21
1011755ec:	0b 27 ff 97	bl	__ZNSt3__16vectorIN16BeatAnalyzer_2_06peakss8BeatInfoENS_9allocatorIS3_EEE6insertENS_11__wrap_iterIPKS3_EERS8_
1011755f0:	a8 02 40 f9	ldr	x8, [x21]
1011755f4:	01 01 1b 8b	add	x1, x8, x27
1011755f8:	28 84 41 b8	ldr	w8, [x1], #0x18
1011755fc:	00 01 62 1e	scvtf	d0, w8
101175600:	61 02 40 bd	ldr	s1, [x19]
101175604:	21 a4 20 0f	sshll.2d	v1, v1, #0x0
101175608:	21 d8 61 5e	scvtf	d1, d1
10117560c:	00 28 6e 1e	fadd	d0, d0, d14
101175610:	00 01 41 1f	fmadd	d0, d8, d1, d0
101175614:	08 00 78 1e	fcvtzs	w8, d0
101175618:	e8 d3 03 b9	str	w8, [sp, #0x3d0]
10117561c:	e2 43 0f 91	add	x2, sp, #0x3d0
101175620:	e0 03 15 aa	mov	x0, x21
101175624:	fd 26 ff 97	bl	__ZNSt3__16vectorIN16BeatAnalyzer_2_06peakss8BeatInfoENS_9allocatorIS3_EEE6insertENS_11__wrap_iterIPKS3_EERS8_
101175628:	e8 a3 40 f9	ldr	x8, [sp, #0x140]
10117562c:	17 01 00 b9	str	w23, [x8]
101175630:	1f 03 1a eb	cmp	x24, x26
101175634:	ed 00 00 54	b.le	0x101175650
101175638:	18 07 00 d1	sub	x24, x24, #0x1
10117563c:	f5 b3 40 f9	ldr	x21, [sp, #0x160]
101175640:	a8 02 40 f9	ldr	x8, [x21]
101175644:	f7 0a 00 11	add	w23, w23, #0x2
101175648:	7b 63 00 d1	sub	x27, x27, #0x18
10117564c:	d1 ff ff 17	b	0x101175590
101175650:	e8 6f 53 a9	ldp	x8, x27, [sp, #0x130]
101175654:	09 01 40 f9	ldr	x9, [x8]
101175658:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
10117565c:	08 01 40 f9	ldr	x8, [x8]
101175660:	29 01 08 cb	sub	x9, x9, x8
101175664:	29 fd 43 d3	lsr	x9, x9, #3
101175668:	6a 55 95 52	mov	w10, #0xaaab
10117566c:	4a 55 b5 72	movk	w10, #0xaaaa, lsl #16
101175670:	38 7d 0a 1b	mul	w24, w9, w10
101175674:	99 07 00 36	tbz	w25, #0x0, 0x101175764
101175678:	f9 06 00 11	add	w25, w23, #0x1
10117567c:	3f 03 18 6b	cmp	w25, w24
101175680:	2a 07 00 54	b.ge	0x101175764
101175684:	0b 03 80 52	mov	w11, #0x18
101175688:	ea 7e 2b 9b	smull	x10, w23, w11
10117568c:	00 69 6a bc	ldr	s0, [x8, x10]
101175690:	00 a4 20 0f	sshll.2d	v0, v0, #0x0
101175694:	00 d8 61 5e	scvtf	d0, d0
101175698:	69 03 40 b9	ldr	w9, [x27]
10117569c:	21 01 62 1e	scvtf	d1, w9
1011756a0:	0a 18 61 1e	fdiv	d10, d0, d1
1011756a4:	2b 7f 2b 9b	smull	x11, w25, w11
1011756a8:	00 69 6b bc	ldr	s0, [x8, x11]
1011756ac:	00 a4 20 0f	sshll.2d	v0, v0, #0x0
1011756b0:	00 d8 61 5e	scvtf	d0, d0
1011756b4:	00 18 61 1e	fdiv	d0, d0, d1
1011756b8:	0b 38 6a 1e	fsub	d11, d0, d10
1011756bc:	0b 00 c8 d2	mov	x11, #0x400000000000
1011756c0:	eb 11 e8 f2	movk	x11, #0x408f, lsl #48
1011756c4:	60 01 67 9e	fmov	d0, x11
1011756c8:	60 09 60 1e	fmul	d0, d11, d0
1011756cc:	00 38 4c 1f	fmadd	d0, d0, d12, d14
1011756d0:	0b 00 78 1e	fcvtzs	w11, d0
1011756d4:	7a 09 00 71	subs	w26, w11, #0x2
1011756d8:	6b 04 00 54	b.lt	0x101175764
1011756dc:	1b 00 80 52	mov	w27, #0x0
1011756e0:	60 01 62 1e	scvtf	d0, w11
1011756e4:	ff bf 03 b9	str	wzr, [sp, #0x3bc]
1011756e8:	0b 00 80 12	mov	w11, #-0x1
1011756ec:	eb cb 03 b9	str	w11, [sp, #0x3c8]
1011756f0:	ff 33 0f 39	strb	wzr, [sp, #0x3cc]
1011756f4:	a8 19 60 1e	fdiv	d8, d13, d0
1011756f8:	53 61 00 91	add	x19, x10, #0x18
1011756fc:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
101175700:	6a 07 00 11	add	w10, w27, #0x1
101175704:	40 01 62 1e	scvtf	d0, w10
101175708:	60 09 60 1e	fmul	d0, d11, d0
10117570c:	00 28 48 1f	fmadd	d0, d0, d8, d10
101175710:	21 01 62 1e	scvtf	d1, w9
101175714:	00 38 41 1f	fmadd	d0, d0, d1, d14
101175718:	09 00 78 1e	fcvtzs	w9, d0
10117571c:	e9 bb 03 b9	str	w9, [sp, #0x3b8]
101175720:	ff e3 01 f9	str	xzr, [sp, #0x3c0]
101175724:	61 02 08 8b	add	x1, x19, x8
101175728:	e2 e3 0e 91	add	x2, sp, #0x3b8
10117572c:	bb 26 ff 97	bl	__ZNSt3__16vectorIN16BeatAnalyzer_2_06peakss8BeatInfoENS_9allocatorIS3_EEE6insertENS_11__wrap_iterIPKS3_EERS8_
101175730:	37 03 1b 0b	add	w23, w25, w27
101175734:	e8 a3 40 f9	ldr	x8, [sp, #0x140]
101175738:	17 01 00 b9	str	w23, [x8]
10117573c:	5f 03 1b 6b	cmp	w26, w27
101175740:	00 01 00 54	b.eq	0x101175760
101175744:	e8 9f 40 f9	ldr	x8, [sp, #0x138]
101175748:	09 01 40 b9	ldr	w9, [x8]
10117574c:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
101175750:	08 00 40 f9	ldr	x8, [x0]
101175754:	73 62 00 91	add	x19, x19, #0x18
101175758:	7b 07 00 11	add	w27, w27, #0x1
10117575c:	e9 ff ff 17	b	0x101175700
101175760:	fb 9f 40 f9	ldr	x27, [sp, #0x138]
101175764:	f6 07 00 34	cbz	w22, 0x101175860
101175768:	8a 06 00 91	add	x10, x20, #0x1
10117576c:	5f 01 18 6b	cmp	w10, w24
101175770:	f9 9b 40 f9	ldr	x25, [sp, #0x130]
101175774:	15 03 80 52	mov	w21, #0x18
101175778:	fa a3 40 f9	ldr	x26, [sp, #0x140]
10117577c:	2a 08 00 54	b.ge	0x101175880
101175780:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
101175784:	08 01 40 f9	ldr	x8, [x8]
101175788:	89 7e 15 9b	mul	x9, x20, x21
10117578c:	00 69 69 bc	ldr	s0, [x8, x9]
101175790:	00 a4 20 0f	sshll.2d	v0, v0, #0x0
101175794:	00 d8 61 5e	scvtf	d0, d0
101175798:	69 03 40 b9	ldr	w9, [x27]
10117579c:	21 01 62 1e	scvtf	d1, w9
1011757a0:	0a 18 61 1e	fdiv	d10, d0, d1
1011757a4:	4a 7d 15 9b	mul	x10, x10, x21
1011757a8:	00 69 6a bc	ldr	s0, [x8, x10]
1011757ac:	00 a4 20 0f	sshll.2d	v0, v0, #0x0
1011757b0:	00 d8 61 5e	scvtf	d0, d0
1011757b4:	00 18 61 1e	fdiv	d0, d0, d1
1011757b8:	0b 38 6a 1e	fsub	d11, d0, d10
1011757bc:	0a 00 c8 d2	mov	x10, #0x400000000000
1011757c0:	ea 11 e8 f2	movk	x10, #0x408f, lsl #48
1011757c4:	40 01 67 9e	fmov	d0, x10
1011757c8:	60 09 60 1e	fmul	d0, d11, d0
1011757cc:	00 38 4c 1f	fmadd	d0, d0, d12, d14
1011757d0:	0a 00 78 1e	fcvtzs	w10, d0
1011757d4:	5f 09 00 71	cmp	w10, #0x2
1011757d8:	4b 05 00 54	b.lt	0x101175880
1011757dc:	40 01 62 1e	scvtf	d0, w10
1011757e0:	ff bf 03 b9	str	wzr, [sp, #0x3bc]
1011757e4:	0b 00 80 12	mov	w11, #-0x1
1011757e8:	eb cb 03 b9	str	w11, [sp, #0x3c8]
1011757ec:	ff 33 0f 39	strb	wzr, [sp, #0x3cc]
1011757f0:	56 05 00 51	sub	w22, w10, #0x1
1011757f4:	a8 19 60 1e	fdiv	d8, d13, d0
1011757f8:	f3 03 17 2a	mov	w19, w23
1011757fc:	ea 07 7d b2	orr	x10, xzr, #0x18
101175800:	94 2a 15 9b	madd	x20, x20, x21, x10
101175804:	38 00 80 52	mov	w24, #0x1
101175808:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
10117580c:	00 03 62 1e	scvtf	d0, w24
101175810:	60 09 60 1e	fmul	d0, d11, d0
101175814:	00 28 48 1f	fmadd	d0, d0, d8, d10
101175818:	21 01 62 1e	scvtf	d1, w9
10117581c:	00 38 41 1f	fmadd	d0, d0, d1, d14
101175820:	09 00 78 1e	fcvtzs	w9, d0
101175824:	e9 bb 03 b9	str	w9, [sp, #0x3b8]
101175828:	ff e3 01 f9	str	xzr, [sp, #0x3c0]
10117582c:	81 02 08 8b	add	x1, x20, x8
101175830:	e2 e3 0e 91	add	x2, sp, #0x3b8
101175834:	79 26 ff 97	bl	__ZNSt3__16vectorIN16BeatAnalyzer_2_06peakss8BeatInfoENS_9allocatorIS3_EEE6insertENS_11__wrap_iterIPKS3_EERS8_
101175838:	68 02 18 0b	add	w8, w19, w24
10117583c:	48 03 00 b9	str	w8, [x26]
101175840:	df 02 18 eb	cmp	x22, x24
101175844:	c0 01 00 54	b.eq	0x10117587c
101175848:	69 03 40 b9	ldr	w9, [x27]
10117584c:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
101175850:	08 00 40 f9	ldr	x8, [x0]
101175854:	18 07 00 91	add	x24, x24, #0x1
101175858:	94 62 00 91	add	x20, x20, #0x18
10117585c:	ec ff ff 17	b	0x10117580c
101175860:	f9 9b 40 f9	ldr	x25, [sp, #0x130]
101175864:	f6 07 40 91	add	x22, sp, #0x1, lsl #12
101175868:	d6 c2 19 91	add	x22, x22, #0x670
10117586c:	15 03 80 52	mov	w21, #0x18
101175870:	f8 87 40 f9	ldr	x24, [sp, #0x108]
101175874:	fa a3 40 f9	ldr	x26, [sp, #0x140]
101175878:	05 00 00 14	b	0x10117588c
10117587c:	f7 02 18 0b	add	w23, w23, w24
101175880:	f6 07 40 91	add	x22, sp, #0x1, lsl #12
101175884:	d6 c2 19 91	add	x22, x22, #0x670
101175888:	f8 87 40 f9	ldr	x24, [sp, #0x108]
10117588c:	f3 b3 40 f9	ldr	x19, [sp, #0x160]
101175890:	61 02 40 f9	ldr	x1, [x19]
101175894:	28 18 40 b9	ldr	w8, [x1, #0x18]
101175898:	29 00 40 b9	ldr	w9, [x1]
10117589c:	08 01 09 4b	sub	w8, w8, w9
1011758a0:	28 01 08 6b	subs	w8, w9, w8
1011758a4:	2d 01 00 54	b.le	0x1011758c8
1011758a8:	e8 d3 03 b9	str	w8, [sp, #0x3d0]
1011758ac:	ff ef 01 f9	str	xzr, [sp, #0x3d8]
1011758b0:	e2 43 0f 91	add	x2, sp, #0x3d0
1011758b4:	e0 03 13 aa	mov	x0, x19
1011758b8:	58 26 ff 97	bl	__ZNSt3__16vectorIN16BeatAnalyzer_2_06peakss8BeatInfoENS_9allocatorIS3_EEE6insertENS_11__wrap_iterIPKS3_EERS8_
1011758bc:	e8 06 00 11	add	w8, w23, #0x1
1011758c0:	48 03 00 b9	str	w8, [x26]
1011758c4:	61 02 40 f9	ldr	x1, [x19]
1011758c8:	e9 f3 01 b2	mov	x9, #-0x5555555555555556
1011758cc:	69 55 95 f2	movk	x9, #0xaaab
1011758d0:	28 03 40 f9	ldr	x8, [x25]
1011758d4:	08 01 01 cb	sub	x8, x8, x1
1011758d8:	08 fd 43 93	asr	x8, x8, #3
1011758dc:	13 7d 09 9b	mul	x19, x8, x9
1011758e0:	7f 0a 00 71	cmp	w19, #0x2
1011758e4:	f7 07 40 91	add	x23, sp, #0x1, lsl #12
1011758e8:	f7 c2 11 91	add	x23, x23, #0x470
1011758ec:	ab 06 00 54	b.lt	0x1011759c0
1011758f0:	68 06 00 51	sub	w8, w19, #0x1
1011758f4:	09 7d b5 9b	umull	x9, w8, w21
1011758f8:	2a 68 69 b8	ldr	w10, [x1, x9]
1011758fc:	69 7e 60 d3	lsl	x9, x19, #32
101175900:	eb 7b 5f b2	mov	x11, #-0x200000000
101175904:	2b 01 0b 8b	add	x11, x9, x11
101175908:	6b fd 60 93	asr	x11, x11, #32
10117590c:	6b 7d 15 9b	mul	x11, x11, x21
101175910:	2b 68 6b b8	ldr	w11, [x1, x11]
101175914:	54 01 0b 6b	subs	w20, w10, w11
101175918:	40 05 00 54	b.eq	0x1011759c0
10117591c:	8b 1f 40 b9	ldr	w11, [x28, #0x1c]
101175920:	6a 01 0a 4b	sub	w10, w11, w10
101175924:	40 01 62 1e	scvtf	d0, w10
101175928:	81 02 62 1e	scvtf	d1, w20
10117592c:	00 18 61 1e	fdiv	d0, d0, d1
101175930:	00 20 6d 1e	fcmp	d0, d13
101175934:	6d 04 00 54	b.le	0x1011759c0
101175938:	0a 00 78 1e	fcvtzs	w10, d0
10117593c:	ff e3 01 f9	str	xzr, [sp, #0x3c0]
101175940:	ff df 01 f9	str	xzr, [sp, #0x3b8]
101175944:	0b 00 80 12	mov	w11, #-0x1
101175948:	eb cb 03 b9	str	w11, [sp, #0x3c8]
10117594c:	ff 33 0f 39	strb	wzr, [sp, #0x3cc]
101175950:	5f 05 00 71	cmp	w10, #0x1
101175954:	cb 02 00 54	b.lt	0x1011759ac
101175958:	29 fd 60 93	asr	x9, x9, #32
10117595c:	08 05 08 8b	add	x8, x8, x8, lsl #1
101175960:	16 f1 7d d3	lsl	x22, x8, #3
101175964:	28 05 09 8b	add	x8, x9, x9, lsl #1
101175968:	17 f1 7d d3	lsl	x23, x8, #3
10117596c:	58 05 00 d1	sub	x24, x10, #0x1
101175970:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
101175974:	28 68 76 b8	ldr	w8, [x1, x22]
101175978:	08 01 14 0b	add	w8, w8, w20
10117597c:	e8 bb 03 b9	str	w8, [sp, #0x3b8]
101175980:	ff e3 01 f9	str	xzr, [sp, #0x3c0]
101175984:	e1 02 01 8b	add	x1, x23, x1
101175988:	e2 e3 0e 91	add	x2, sp, #0x3b8
10117598c:	23 26 ff 97	bl	__ZNSt3__16vectorIN16BeatAnalyzer_2_06peakss8BeatInfoENS_9allocatorIS3_EEE6insertENS_11__wrap_iterIPKS3_EERS8_
101175990:	f8 00 00 b4	cbz	x24, 0x1011759ac
101175994:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
101175998:	01 00 40 f9	ldr	x1, [x0]
10117599c:	d6 62 00 91	add	x22, x22, #0x18
1011759a0:	f7 62 00 91	add	x23, x23, #0x18
1011759a4:	18 07 00 d1	sub	x24, x24, #0x1
1011759a8:	f3 ff ff 17	b	0x101175974
1011759ac:	f7 07 40 91	add	x23, sp, #0x1, lsl #12
1011759b0:	f7 c2 11 91	add	x23, x23, #0x470
1011759b4:	f6 07 40 91	add	x22, sp, #0x1, lsl #12
1011759b8:	d6 c2 19 91	add	x22, x22, #0x670
1011759bc:	f8 87 40 f9	ldr	x24, [sp, #0x108]
1011759c0:	e8 cb 40 b9	ldr	w8, [sp, #0xc8]
1011759c4:	68 46 01 34	cbz	w8, 0x101178290
1011759c8:	29 03 40 f9	ldr	x9, [x25]
1011759cc:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
1011759d0:	08 01 40 f9	ldr	x8, [x8]
1011759d4:	29 01 08 cb	sub	x9, x9, x8
1011759d8:	29 fd 43 d3	lsr	x9, x9, #3
1011759dc:	6a 55 95 52	mov	w10, #0xaaab
1011759e0:	4a 55 b5 72	movk	w10, #0xaaaa, lsl #16
1011759e4:	33 7d 0a 1b	mul	w19, w9, w10
1011759e8:	69 0a 00 51	sub	w9, w19, #0x2
1011759ec:	3f 05 00 71	cmp	w9, #0x1
1011759f0:	2a c5 9f 1a	csinc	w10, w9, wzr, gt
1011759f4:	0f 06 80 52	mov	w15, #0x30
1011759f8:	2b 00 80 52	mov	w11, #0x1
1011759fc:	7f 01 0a eb	cmp	x11, x10
101175a00:	80 44 01 54	b.eq	0x101178290
101175a04:	e9 03 0b aa	mov	x9, x11
101175a08:	f4 03 0f aa	mov	x20, x15
101175a0c:	6b 21 15 9b	madd	x11, x11, x21, x8
101175a10:	70 01 40 b9	ldr	w16, [x11]
101175a14:	6d 81 5e b8	ldur	w13, [x11, #-0x18]
101175a18:	2b 05 00 91	add	x11, x9, #0x1
101175a1c:	6c 7d 40 92	and	x12, x11, #0xffffffff
101175a20:	8c 7d 15 9b	mul	x12, x12, x21
101175a24:	0c 69 6c b8	ldr	w12, [x8, x12]
101175a28:	0f 02 0d 4b	sub	w15, w16, w13
101175a2c:	2d 09 00 11	add	w13, w9, #0x2
101175a30:	ad 7d b5 9b	umull	x13, w13, w21
101175a34:	0e 69 6d b8	ldr	w14, [x8, x13]
101175a38:	cd 01 0c 4b	sub	w13, w14, w12
101175a3c:	f1 09 0f 0b	add	w17, w15, w15, lsl #2
101175a40:	a0 09 0d 0b	add	w0, w13, w13, lsl #2
101175a44:	8f 62 00 91	add	x15, x20, #0x18
101175a48:	90 01 10 4b	sub	w16, w12, w16
101175a4c:	1f 02 11 6b	cmp	w16, w17
101175a50:	00 d2 40 7a	ccmp	w16, w0, #0x0, le
101175a54:	4d fd ff 54	b.le	0x1011759fc
101175a58:	df 01 0c 6b	cmp	w14, w12
101175a5c:	a0 41 01 54	b.eq	0x101178290
101175a60:	00 02 62 1e	scvtf	d0, w16
101175a64:	a1 01 62 1e	scvtf	d1, w13
101175a68:	01 18 61 1e	fdiv	d1, d0, d1
101175a6c:	20 20 6d 1e	fcmp	d1, d13
101175a70:	0d 41 01 54	b.le	0x101178290
101175a74:	2a 00 78 1e	fcvtzs	w10, d1
101175a78:	ff e3 01 f9	str	xzr, [sp, #0x3c0]
101175a7c:	ff df 01 f9	str	xzr, [sp, #0x3b8]
101175a80:	0b 00 80 12	mov	w11, #-0x1
101175a84:	eb cb 03 b9	str	w11, [sp, #0x3c8]
101175a88:	ff 33 0f 39	strb	wzr, [sp, #0x3cc]
101175a8c:	5f 09 00 71	cmp	w10, #0x2
101175a90:	4b 3f 01 54	b.lt	0x101178278
101175a94:	21 c0 65 1e	frintz	d1, d1
101175a98:	00 18 61 1e	fdiv	d0, d0, d1
101175a9c:	16 00 78 1e	fcvtzs	w22, d0
101175aa0:	37 7d 40 92	and	x23, x9, #0xffffffff
101175aa4:	58 09 00 d1	sub	x24, x10, #0x2
101175aa8:	f9 03 16 aa	mov	x25, x22
101175aac:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
101175ab0:	e9 7e 15 9b	mul	x9, x23, x21
101175ab4:	09 69 69 b8	ldr	w9, [x8, x9]
101175ab8:	29 03 09 0b	add	w9, w25, w9
101175abc:	e9 bb 03 b9	str	w9, [sp, #0x3b8]
101175ac0:	ff e3 01 f9	str	xzr, [sp, #0x3c0]
101175ac4:	81 02 08 8b	add	x1, x20, x8
101175ac8:	e2 e3 0e 91	add	x2, sp, #0x3b8
101175acc:	d3 25 ff 97	bl	__ZNSt3__16vectorIN16BeatAnalyzer_2_06peakss8BeatInfoENS_9allocatorIS3_EEE6insertENS_11__wrap_iterIPKS3_EERS8_
101175ad0:	58 3d 01 b4	cbz	x24, 0x101178278
101175ad4:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
101175ad8:	08 00 40 f9	ldr	x8, [x0]
101175adc:	39 03 16 0b	add	w25, w25, w22
101175ae0:	94 62 00 91	add	x20, x20, #0x18
101175ae4:	18 07 00 d1	sub	x24, x24, #0x1
101175ae8:	f2 ff ff 17	b	0x101175ab0
101175aec:	f4 03 09 aa	mov	x20, x9
101175af0:	9f e6 ff 17	b	0x10116f56c
101175af4:	8a 11 00 11	add	w10, w12, #0x4
101175af8:	80 da 6a fc	ldr	d0, [x20, w10, sxtw #3]
101175afc:	e8 a3 90 d2	mov	x8, #0x851f
101175b00:	68 3d aa f2	movk	x8, #0x51eb, lsl #16
101175b04:	08 d7 c3 f2	movk	x8, #0x1eb8, lsl #32
101175b08:	28 fe e7 f2	movk	x8, #0x3ff1, lsl #48
101175b0c:	01 01 67 9e	fmov	d1, x8
101175b10:	00 20 61 1e	fcmp	d0, d1
101175b14:	cd 00 00 54	b.le	0x101175b2c
101175b18:	e8 e7 02 b2	mov	x8, #-0x3333333333333334
101175b1c:	c8 fe e7 f2	movk	x8, #0x3ff6, lsl #48
101175b20:	01 01 67 9e	fmov	d1, x8
101175b24:	00 20 61 1e	fcmp	d0, d1
101175b28:	ab 01 00 54	b.lt	0x101175b5c
101175b2c:	e8 e7 00 b2	mov	x8, #0x3333333333333333
101175b30:	88 66 86 f2	movk	x8, #0x3334
101175b34:	28 ff e7 f2	movk	x8, #0x3ff9, lsl #48
101175b38:	01 01 67 9e	fmov	d1, x8
101175b3c:	00 20 61 1e	fcmp	d0, d1
101175b40:	ed 45 fe 54	b.le	0x1011723fc
101175b44:	e8 e7 02 b2	mov	x8, #-0x3333333333333334
101175b48:	a8 99 99 f2	movk	x8, #0xcccd
101175b4c:	88 ff e7 f2	movk	x8, #0x3ffc, lsl #48
101175b50:	01 01 67 9e	fmov	d1, x8
101175b54:	00 20 61 1e	fcmp	d0, d1
101175b58:	2a 45 fe 54	b.ge	0x1011723fc
101175b5c:	08 1a 00 51	sub	w8, w16, #0x6
101175b60:	9f 01 08 6b	cmp	w12, w8
101175b64:	ad 3e 01 54	b.le	0x101178338
101175b68:	3f 01 00 71	cmp	w9, #0x0
101175b6c:	38 c1 9f 1a	csel	w24, w9, wzr, gt
101175b70:	3a 03 40 f9	ldr	x26, [x25]
101175b74:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
101175b78:	08 01 40 f9	ldr	x8, [x8]
101175b7c:	49 03 08 cb	sub	x9, x26, x8
101175b80:	29 fd 43 93	asr	x9, x9, #3
101175b84:	eb f3 01 b2	mov	x11, #-0x5555555555555556
101175b88:	6b 55 95 f2	movk	x11, #0xaaab
101175b8c:	29 7d 0b 9b	mul	x9, x9, x11
101175b90:	2b 05 00 d1	sub	x11, x9, #0x1
101175b94:	2c 05 00 51	sub	w12, w9, #0x1
101175b98:	7f c1 2a eb	cmp	x11, w10, sxtw
101175b9c:	8a 31 8a 1a	csel	w10, w12, w10, lo
101175ba0:	5f 01 18 6b	cmp	w10, w24
101175ba4:	ee c3 00 b9	str	w14, [sp, #0xc0]
101175ba8:	f8 83 00 f9	str	x24, [sp, #0x100]
101175bac:	ea 6b 00 f9	str	x10, [sp, #0xd0]
101175bb0:	0d 04 00 54	b.le	0x101175c30
101175bb4:	55 7d 40 93	sxtw	x21, w10
101175bb8:	14 03 80 52	mov	w20, #0x18
101175bbc:	40 21 34 9b	smaddl	x0, w10, w20, x8
101175bc0:	01 60 00 91	add	x1, x0, #0x18
101175bc4:	42 03 01 cb	sub	x2, x26, x1
101175bc8:	a1 72 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
101175bcc:	5a 63 00 d1	sub	x26, x26, #0x18
101175bd0:	3a 03 00 f9	str	x26, [x25]
101175bd4:	b5 06 00 d1	sub	x21, x21, #0x1
101175bd8:	bf 02 18 eb	cmp	x21, x24
101175bdc:	f6 b3 40 f9	ldr	x22, [sp, #0x160]
101175be0:	6d 01 00 54	b.le	0x101175c0c
101175be4:	c8 02 40 f9	ldr	x8, [x22]
101175be8:	a0 22 14 9b	madd	x0, x21, x20, x8
101175bec:	01 60 00 91	add	x1, x0, #0x18
101175bf0:	42 03 01 cb	sub	x2, x26, x1
101175bf4:	96 72 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
101175bf8:	5a 63 00 d1	sub	x26, x26, #0x18
101175bfc:	3a 03 00 f9	str	x26, [x25]
101175c00:	b5 06 00 d1	sub	x21, x21, #0x1
101175c04:	bf 02 18 eb	cmp	x21, x24
101175c08:	ec fe ff 54	b.gt	0x101175be4
101175c0c:	c8 02 40 f9	ldr	x8, [x22]
101175c10:	49 03 08 cb	sub	x9, x26, x8
101175c14:	29 fd 43 93	asr	x9, x9, #3
101175c18:	ea f3 01 b2	mov	x10, #-0x5555555555555556
101175c1c:	6a 55 95 f2	movk	x10, #0xaaab
101175c20:	29 7d 0a 9b	mul	x9, x9, x10
101175c24:	2b 05 00 d1	sub	x11, x9, #0x1
101175c28:	2c 05 00 51	sub	w12, w9, #0x1
101175c2c:	02 00 00 14	b	0x101175c34
101175c30:	f8 03 0a aa	mov	x24, x10
101175c34:	f4 43 21 91	add	x20, sp, #0x850
101175c38:	ea af 40 f9	ldr	x10, [sp, #0x158]
101175c3c:	98 7a 2a b8	str	w24, [x20, x10, lsl #2]
101175c40:	7f 02 00 71	cmp	w19, #0x0
101175c44:	6f c2 9f 1a	csel	w15, w19, wzr, gt
101175c48:	7f c1 37 eb	cmp	x11, w23, sxtw
101175c4c:	8a 31 97 1a	csel	w10, w12, w23, lo
101175c50:	5f 01 0f 6b	cmp	w10, w15
101175c54:	ef a3 00 f9	str	x15, [sp, #0x140]
101175c58:	ea 67 00 f9	str	x10, [sp, #0xc8]
101175c5c:	2d 07 00 54	b.le	0x101175d40
101175c60:	55 7d 40 93	sxtw	x21, w10
101175c64:	09 03 80 52	mov	w9, #0x18
101175c68:	40 21 29 9b	smaddl	x0, w10, w9, x8
101175c6c:	01 60 00 91	add	x1, x0, #0x18
101175c70:	42 03 01 cb	sub	x2, x26, x1
101175c74:	76 72 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
101175c78:	ef a3 40 f9	ldr	x15, [sp, #0x140]
101175c7c:	5a 63 00 d1	sub	x26, x26, #0x18
101175c80:	e9 93 40 f9	ldr	x9, [sp, #0x120]
101175c84:	88 6a 69 b8	ldr	w8, [x20, x9]
101175c88:	3a 03 00 f9	str	x26, [x25]
101175c8c:	18 05 00 51	sub	w24, w8, #0x1
101175c90:	98 6a 29 b8	str	w24, [x20, x9]
101175c94:	b6 06 00 d1	sub	x22, x21, #0x1
101175c98:	df 02 0f eb	cmp	x22, x15
101175c9c:	ed 05 00 54	b.le	0x101175d58
101175ca0:	a8 06 15 8b	add	x8, x21, x21, lsl #1
101175ca4:	1b f1 7d d3	lsl	x27, x8, #3
101175ca8:	e8 02 80 92	mov	x8, #-0x18
101175cac:	b7 7e 08 9b	mul	x23, x21, x8
101175cb0:	f3 b3 40 f9	ldr	x19, [sp, #0x160]
101175cb4:	f5 03 19 aa	mov	x21, x25
101175cb8:	f4 f3 01 b2	mov	x20, #-0x5555555555555556
101175cbc:	74 55 95 f2	movk	x20, #0xaaab
101175cc0:	54 55 e5 f2	movk	x20, #0x2aaa, lsl #48
101175cc4:	79 02 40 f9	ldr	x25, [x19]
101175cc8:	48 03 19 cb	sub	x8, x26, x25
101175ccc:	e2 02 08 8b	add	x2, x23, x8
101175cd0:	48 7c 54 9b	smulh	x8, x2, x20
101175cd4:	09 fd 42 93	asr	x9, x8, #2
101175cd8:	3c fd 48 8b	add	x28, x9, x8, lsr #63
101175cdc:	21 03 1b 8b	add	x1, x25, x27
101175ce0:	20 60 00 d1	sub	x0, x1, #0x18
101175ce4:	5a 72 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
101175ce8:	ef a3 40 f9	ldr	x15, [sp, #0x140]
101175cec:	08 03 80 52	mov	w8, #0x18
101175cf0:	88 6f 08 9b	madd	x8, x28, x8, x27
101175cf4:	28 03 08 8b	add	x8, x25, x8
101175cf8:	1a 61 00 d1	sub	x26, x8, #0x18
101175cfc:	ba 02 00 f9	str	x26, [x21]
101175d00:	18 07 00 51	sub	w24, w24, #0x1
101175d04:	d6 06 00 d1	sub	x22, x22, #0x1
101175d08:	7b 63 00 d1	sub	x27, x27, #0x18
101175d0c:	f7 62 00 91	add	x23, x23, #0x18
101175d10:	df 02 0f eb	cmp	x22, x15
101175d14:	8c fd ff 54	b.gt	0x101175cc4
101175d18:	e8 43 21 91	add	x8, sp, #0x850
101175d1c:	f3 af 40 f9	ldr	x19, [sp, #0x158]
101175d20:	18 79 33 b8	str	w24, [x8, x19, lsl #2]
101175d24:	08 03 80 52	mov	w8, #0x18
101175d28:	88 67 08 9b	madd	x8, x28, x8, x25
101175d2c:	1a 01 17 cb	sub	x26, x8, x23
101175d30:	fc 97 40 f9	ldr	x28, [sp, #0x128]
101175d34:	fb 9f 40 f9	ldr	x27, [sp, #0x138]
101175d38:	f9 03 15 aa	mov	x25, x21
101175d3c:	08 00 00 14	b	0x101175d5c
101175d40:	f3 af 40 f9	ldr	x19, [sp, #0x158]
101175d44:	ea 43 29 91	add	x10, sp, #0xa50
101175d48:	4f 79 33 b8	str	w15, [x10, x19, lsl #2]
101175d4c:	2a 01 0f 6b	subs	w10, w9, w15
101175d50:	cc 01 00 54	b.gt	0x101175d88
101175d54:	85 00 00 14	b	0x101175f68
101175d58:	f3 af 40 f9	ldr	x19, [sp, #0x158]
101175d5c:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
101175d60:	08 01 40 f9	ldr	x8, [x8]
101175d64:	49 03 08 cb	sub	x9, x26, x8
101175d68:	29 fd 43 93	asr	x9, x9, #3
101175d6c:	ea f3 01 b2	mov	x10, #-0x5555555555555556
101175d70:	6a 55 95 f2	movk	x10, #0xaaab
101175d74:	29 7d 0a 9b	mul	x9, x9, x10
101175d78:	ea 43 29 91	add	x10, sp, #0xa50
101175d7c:	4f 79 33 b8	str	w15, [x10, x19, lsl #2]
101175d80:	2a 01 0f 6b	subs	w10, w9, w15
101175d84:	2d 0f 00 54	b.le	0x101175f68
101175d88:	2b 15 00 51	sub	w11, w9, #0x5
101175d8c:	ff 01 0b 6b	cmp	w15, w11
101175d90:	ab 00 80 52	mov	w11, #0x5
101175d94:	4a c1 8b 1a	csel	w10, w10, w11, gt
101175d98:	5f 05 00 71	cmp	w10, #0x1
101175d9c:	6b 0e 00 54	b.lt	0x101175f68
101175da0:	0c 03 80 52	mov	w12, #0x18
101175da4:	eb 7d ac 9b	umull	x11, w15, w12
101175da8:	00 69 6b bc	ldr	s0, [x8, x11]
101175dac:	00 a4 20 0f	sshll.2d	v0, v0, #0x0
101175db0:	00 d8 61 5e	scvtf	d0, d0
101175db4:	61 03 40 bd	ldr	s1, [x27]
101175db8:	21 a4 20 0f	sshll.2d	v1, v1, #0x0
101175dbc:	23 d8 61 5e	scvtf	d3, d1
101175dc0:	01 18 63 1e	fdiv	d1, d0, d3
101175dc4:	4a 7d 40 93	sxtw	x10, w10
101175dc8:	e0 7f 40 fd	ldr	d0, [sp, #0xf8]
101175dcc:	22 28 60 1e	fadd	d2, d1, d0
101175dd0:	a0 19 63 1e	fdiv	d0, d13, d3
101175dd4:	eb 05 00 91	add	x11, x15, #0x1
101175dd8:	ec 21 0c 9b	madd	x12, x15, x12, x8
101175ddc:	8c 61 00 91	add	x12, x12, #0x18
101175de0:	ed 03 0c aa	mov	x13, x12
101175de4:	f6 03 0b aa	mov	x22, x11
101175de8:	ee 03 0a aa	mov	x14, x10
101175dec:	05 00 00 14	b	0x101175e00
101175df0:	d6 06 00 91	add	x22, x22, #0x1
101175df4:	ad 61 00 91	add	x13, x13, #0x18
101175df8:	ce 05 00 f1	subs	x14, x14, #0x1
101175dfc:	a0 01 00 54	b.eq	0x101175e30
101175e00:	3f 01 16 eb	cmp	x9, x22
101175e04:	69 ff ff 54	b.ls	0x101175df0
101175e08:	a3 01 40 bd	ldr	s3, [x13]
101175e0c:	63 a4 20 0f	sshll.2d	v3, v3, #0x0
101175e10:	63 d8 61 5e	scvtf	d3, d3
101175e14:	63 08 60 1e	fmul	d3, d3, d0
101175e18:	64 38 69 1e	fsub	d4, d3, d9
101175e1c:	63 28 69 1e	fadd	d3, d3, d9
101175e20:	40 20 64 1e	fcmp	d2, d4
101175e24:	40 c4 63 1e	fccmp	d2, d3, #0x0, gt
101175e28:	4a fe ff 54	b.ge	0x101175df0
101175e2c:	2a 00 00 14	b	0x101175ed4
101175e30:	e2 5f 40 fd	ldr	d2, [sp, #0xb8]
101175e34:	22 28 62 1e	fadd	d2, d1, d2
101175e38:	ed 03 0c aa	mov	x13, x12
101175e3c:	f6 03 0b aa	mov	x22, x11
101175e40:	ee 03 0a aa	mov	x14, x10
101175e44:	05 00 00 14	b	0x101175e58
101175e48:	d6 06 00 91	add	x22, x22, #0x1
101175e4c:	ad 61 00 91	add	x13, x13, #0x18
101175e50:	ce 05 00 f1	subs	x14, x14, #0x1
101175e54:	a0 01 00 54	b.eq	0x101175e88
101175e58:	3f 01 16 eb	cmp	x9, x22
101175e5c:	69 ff ff 54	b.ls	0x101175e48
101175e60:	a3 01 40 bd	ldr	s3, [x13]
101175e64:	63 a4 20 0f	sshll.2d	v3, v3, #0x0
101175e68:	63 d8 61 5e	scvtf	d3, d3
101175e6c:	63 08 60 1e	fmul	d3, d3, d0
101175e70:	64 38 69 1e	fsub	d4, d3, d9
101175e74:	63 28 69 1e	fadd	d3, d3, d9
101175e78:	40 20 64 1e	fcmp	d2, d4
101175e7c:	40 c4 63 1e	fccmp	d2, d3, #0x0, gt
101175e80:	4a fe ff 54	b.ge	0x101175e48
101175e84:	14 00 00 14	b	0x101175ed4
101175e88:	e2 3f 40 fd	ldr	d2, [sp, #0x78]
101175e8c:	21 28 62 1e	fadd	d1, d1, d2
101175e90:	05 00 00 14	b	0x101175ea4
101175e94:	6b 05 00 91	add	x11, x11, #0x1
101175e98:	8c 61 00 91	add	x12, x12, #0x18
101175e9c:	4a 05 00 f1	subs	x10, x10, #0x1
101175ea0:	40 06 00 54	b.eq	0x101175f68
101175ea4:	3f 01 0b eb	cmp	x9, x11
101175ea8:	69 ff ff 54	b.ls	0x101175e94
101175eac:	82 01 40 bd	ldr	s2, [x12]
101175eb0:	42 a4 20 0f	sshll.2d	v2, v2, #0x0
101175eb4:	42 d8 61 5e	scvtf	d2, d2
101175eb8:	42 08 60 1e	fmul	d2, d2, d0
101175ebc:	43 38 69 1e	fsub	d3, d2, d9
101175ec0:	42 28 69 1e	fadd	d2, d2, d9
101175ec4:	20 20 63 1e	fcmp	d1, d3
101175ec8:	20 c4 62 1e	fccmp	d1, d2, #0x0, gt
101175ecc:	4a fe ff 54	b.ge	0x101175e94
101175ed0:	f6 03 0b aa	mov	x22, x11
101175ed4:	f7 05 00 11	add	w23, w15, #0x1
101175ed8:	ff 02 16 6b	cmp	w23, w22
101175edc:	6a 04 00 54	b.ge	0x101175f68
101175ee0:	09 03 80 52	mov	w9, #0x18
101175ee4:	e0 22 a9 9b	umaddl	x0, w23, w9, x8
101175ee8:	01 60 00 91	add	x1, x0, #0x18
101175eec:	42 03 01 cb	sub	x2, x26, x1
101175ef0:	d7 71 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
101175ef4:	5a 63 00 d1	sub	x26, x26, #0x18
101175ef8:	e9 43 21 91	add	x9, sp, #0x850
101175efc:	ea 93 40 f9	ldr	x10, [sp, #0x120]
101175f00:	28 69 6a b8	ldr	w8, [x9, x10]
101175f04:	3a 03 00 f9	str	x26, [x25]
101175f08:	18 05 00 51	sub	w24, w8, #0x1
101175f0c:	38 69 2a b8	str	w24, [x9, x10]
101175f10:	d4 06 00 51	sub	w20, w22, #0x1
101175f14:	ff 02 14 6b	cmp	w23, w20
101175f18:	2a 02 00 54	b.ge	0x101175f5c
101175f1c:	f3 b3 40 f9	ldr	x19, [sp, #0x160]
101175f20:	15 03 80 52	mov	w21, #0x18
101175f24:	68 02 40 f9	ldr	x8, [x19]
101175f28:	e0 22 15 9b	madd	x0, x23, x21, x8
101175f2c:	01 60 00 91	add	x1, x0, #0x18
101175f30:	42 03 01 cb	sub	x2, x26, x1
101175f34:	c6 71 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
101175f38:	5a 63 00 d1	sub	x26, x26, #0x18
101175f3c:	3a 03 00 f9	str	x26, [x25]
101175f40:	18 07 00 51	sub	w24, w24, #0x1
101175f44:	94 06 00 51	sub	w20, w20, #0x1
101175f48:	ff 02 14 6b	cmp	w23, w20
101175f4c:	cb fe ff 54	b.lt	0x101175f24
101175f50:	e8 43 21 91	add	x8, sp, #0x850
101175f54:	f3 af 40 f9	ldr	x19, [sp, #0x158]
101175f58:	18 79 33 b8	str	w24, [x8, x19, lsl #2]
101175f5c:	35 00 80 52	mov	w21, #0x1
101175f60:	ef a3 40 f9	ldr	x15, [sp, #0x140]
101175f64:	02 00 00 14	b	0x101175f6c
101175f68:	15 00 80 52	mov	w21, #0x0
101175f6c:	14 07 00 71	subs	w20, w24, #0x1
101175f70:	0b 09 00 54	b.lt	0x101176090
101175f74:	ea 03 18 2a	mov	w10, w24
101175f78:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
101175f7c:	08 01 40 f9	ldr	x8, [x8]
101175f80:	09 03 80 52	mov	w9, #0x18
101175f84:	0c 23 a9 9b	umaddl	x12, w24, w9, x8
101175f88:	80 01 40 bd	ldr	s0, [x12]
101175f8c:	00 a4 20 0f	sshll.2d	v0, v0, #0x0
101175f90:	00 d8 61 5e	scvtf	d0, d0
101175f94:	61 03 40 bd	ldr	s1, [x27]
101175f98:	21 a4 20 0f	sshll.2d	v1, v1, #0x0
101175f9c:	21 d8 61 5e	scvtf	d1, d1
101175fa0:	00 18 61 1e	fdiv	d0, d0, d1
101175fa4:	1f 17 00 71	cmp	w24, #0x5
101175fa8:	a9 00 80 52	mov	w9, #0x5
101175fac:	0b b3 89 1a	csel	w11, w24, w9, lt
101175fb0:	e2 7f 40 fd	ldr	d2, [sp, #0xf8]
101175fb4:	02 38 62 1e	fsub	d2, d0, d2
101175fb8:	49 05 00 d1	sub	x9, x10, #0x1
101175fbc:	83 81 5e bc	ldur	s3, [x12, #-0x18]
101175fc0:	63 a4 20 0f	sshll.2d	v3, v3, #0x0
101175fc4:	63 d8 61 5e	scvtf	d3, d3
101175fc8:	63 18 61 1e	fdiv	d3, d3, d1
101175fcc:	64 38 69 1e	fsub	d4, d3, d9
101175fd0:	63 28 69 1e	fadd	d3, d3, d9
101175fd4:	40 20 64 1e	fcmp	d2, d4
101175fd8:	40 c4 63 1e	fccmp	d2, d3, #0x0, gt
101175fdc:	f6 03 09 aa	mov	x22, x9
101175fe0:	0b 0d 00 54	b.lt	0x101176180
101175fe4:	6b 05 00 11	add	w11, w11, #0x1
101175fe8:	7f 09 00 71	cmp	w11, #0x2
101175fec:	81 05 00 54	b.ne	0x10117609c
101175ff0:	e2 5f 40 fd	ldr	d2, [sp, #0xb8]
101175ff4:	02 38 62 1e	fsub	d2, d0, d2
101175ff8:	6b 05 00 d1	sub	x11, x11, #0x1
101175ffc:	0c 03 80 52	mov	w12, #0x18
101176000:	4a 21 0c 9b	madd	x10, x10, x12, x8
101176004:	4a 61 00 d1	sub	x10, x10, #0x18
101176008:	ec 03 0a aa	mov	x12, x10
10117600c:	f6 03 09 aa	mov	x22, x9
101176010:	ed 03 0b aa	mov	x13, x11
101176014:	a1 19 61 1e	fdiv	d1, d13, d1
101176018:	83 01 40 bd	ldr	s3, [x12]
10117601c:	63 a4 20 0f	sshll.2d	v3, v3, #0x0
101176020:	63 d8 61 5e	scvtf	d3, d3
101176024:	63 08 61 1e	fmul	d3, d3, d1
101176028:	64 38 69 1e	fsub	d4, d3, d9
10117602c:	63 28 69 1e	fadd	d3, d3, d9
101176030:	40 20 64 1e	fcmp	d2, d4
101176034:	40 c4 63 1e	fccmp	d2, d3, #0x0, gt
101176038:	4b 0a 00 54	b.lt	0x101176180
10117603c:	d6 06 00 d1	sub	x22, x22, #0x1
101176040:	8c 61 00 d1	sub	x12, x12, #0x18
101176044:	ad 05 00 d1	sub	x13, x13, #0x1
101176048:	8d fe ff b5	cbnz	x13, 0x101176018
10117604c:	e2 3f 40 fd	ldr	d2, [sp, #0x78]
101176050:	00 38 62 1e	fsub	d0, d0, d2
101176054:	42 01 40 bd	ldr	s2, [x10]
101176058:	42 a4 20 0f	sshll.2d	v2, v2, #0x0
10117605c:	42 d8 61 5e	scvtf	d2, d2
101176060:	42 08 61 1e	fmul	d2, d2, d1
101176064:	43 38 69 1e	fsub	d3, d2, d9
101176068:	42 28 69 1e	fadd	d2, d2, d9
10117606c:	00 20 63 1e	fcmp	d0, d3
101176070:	00 c4 62 1e	fccmp	d0, d2, #0x0, gt
101176074:	4b 08 00 54	b.lt	0x10117617c
101176078:	29 05 00 d1	sub	x9, x9, #0x1
10117607c:	4a 61 00 d1	sub	x10, x10, #0x18
101176080:	6b 05 00 d1	sub	x11, x11, #0x1
101176084:	8b fe ff b5	cbnz	x11, 0x101176054
101176088:	f6 03 18 aa	mov	x22, x24
10117608c:	3d 00 00 14	b	0x101176180
101176090:	17 00 80 52	mov	w23, #0x0
101176094:	ec 43 29 91	add	x12, sp, #0xa50
101176098:	9d 00 00 14	b	0x10117630c
10117609c:	56 09 00 d1	sub	x22, x10, #0x2
1011760a0:	0c 03 80 52	mov	w12, #0x18
1011760a4:	cc 7e 0c 9b	mul	x12, x22, x12
1011760a8:	03 69 6c bc	ldr	s3, [x8, x12]
1011760ac:	63 a4 20 0f	sshll.2d	v3, v3, #0x0
1011760b0:	63 d8 61 5e	scvtf	d3, d3
1011760b4:	63 18 61 1e	fdiv	d3, d3, d1
1011760b8:	64 38 69 1e	fsub	d4, d3, d9
1011760bc:	63 28 69 1e	fadd	d3, d3, d9
1011760c0:	40 20 64 1e	fcmp	d2, d4
1011760c4:	40 c4 63 1e	fccmp	d2, d3, #0x0, gt
1011760c8:	cb 05 00 54	b.lt	0x101176180
1011760cc:	7f 0d 00 71	cmp	w11, #0x3
1011760d0:	00 f9 ff 54	b.eq	0x101175ff0
1011760d4:	56 0d 00 d1	sub	x22, x10, #0x3
1011760d8:	0c 03 80 52	mov	w12, #0x18
1011760dc:	cc 7e 0c 9b	mul	x12, x22, x12
1011760e0:	03 69 6c bc	ldr	s3, [x8, x12]
1011760e4:	63 a4 20 0f	sshll.2d	v3, v3, #0x0
1011760e8:	63 d8 61 5e	scvtf	d3, d3
1011760ec:	63 18 61 1e	fdiv	d3, d3, d1
1011760f0:	64 38 69 1e	fsub	d4, d3, d9
1011760f4:	63 28 69 1e	fadd	d3, d3, d9
1011760f8:	40 20 64 1e	fcmp	d2, d4
1011760fc:	40 c4 63 1e	fccmp	d2, d3, #0x0, gt
101176100:	0b 04 00 54	b.lt	0x101176180
101176104:	7f 11 00 71	cmp	w11, #0x4
101176108:	40 f7 ff 54	b.eq	0x101175ff0
10117610c:	56 11 00 d1	sub	x22, x10, #0x4
101176110:	0c 03 80 52	mov	w12, #0x18
101176114:	cc 7e 0c 9b	mul	x12, x22, x12
101176118:	03 69 6c bc	ldr	s3, [x8, x12]
10117611c:	63 a4 20 0f	sshll.2d	v3, v3, #0x0
101176120:	63 d8 61 5e	scvtf	d3, d3
101176124:	63 18 61 1e	fdiv	d3, d3, d1
101176128:	64 38 69 1e	fsub	d4, d3, d9
10117612c:	63 28 69 1e	fadd	d3, d3, d9
101176130:	40 20 64 1e	fcmp	d2, d4
101176134:	40 c4 63 1e	fccmp	d2, d3, #0x0, gt
101176138:	4b 02 00 54	b.lt	0x101176180
10117613c:	7f 15 00 71	cmp	w11, #0x5
101176140:	80 f5 ff 54	b.eq	0x101175ff0
101176144:	56 15 00 d1	sub	x22, x10, #0x5
101176148:	0c 03 80 52	mov	w12, #0x18
10117614c:	cc 7e 0c 9b	mul	x12, x22, x12
101176150:	03 69 6c bc	ldr	s3, [x8, x12]
101176154:	63 a4 20 0f	sshll.2d	v3, v3, #0x0
101176158:	63 d8 61 5e	scvtf	d3, d3
10117615c:	63 18 61 1e	fdiv	d3, d3, d1
101176160:	64 38 69 1e	fsub	d4, d3, d9
101176164:	40 20 64 1e	fcmp	d2, d4
101176168:	4d f4 ff 54	b.le	0x101175ff0
10117616c:	63 28 69 1e	fadd	d3, d3, d9
101176170:	40 20 63 1e	fcmp	d2, d3
101176174:	6b 00 00 54	b.lt	0x101176180
101176178:	9e ff ff 17	b	0x101175ff0
10117617c:	f6 03 09 aa	mov	x22, x9
101176180:	9f 02 16 6b	cmp	w20, w22
101176184:	f7 d7 9f 1a	cset	w23, gt
101176188:	ad 04 00 54	b.le	0x10117621c
10117618c:	09 03 80 52	mov	w9, #0x18
101176190:	80 22 29 9b	smaddl	x0, w20, w9, x8
101176194:	01 60 00 91	add	x1, x0, #0x18
101176198:	42 03 01 cb	sub	x2, x26, x1
10117619c:	2c 71 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
1011761a0:	5a 63 00 d1	sub	x26, x26, #0x18
1011761a4:	3a 03 00 f9	str	x26, [x25]
1011761a8:	c8 06 00 11	add	w8, w22, #0x1
1011761ac:	1f 01 14 6b	cmp	w8, w20
1011761b0:	a0 02 00 54	b.eq	0x101176204
1011761b4:	f7 a7 00 b9	str	w23, [sp, #0xa4]
1011761b8:	f5 23 01 b9	str	w21, [sp, #0x120]
1011761bc:	95 7e 40 93	sxtw	x21, w20
1011761c0:	14 0b 00 51	sub	w20, w24, #0x2
1011761c4:	f3 b3 40 f9	ldr	x19, [sp, #0x160]
1011761c8:	17 03 80 52	mov	w23, #0x18
1011761cc:	68 02 40 f9	ldr	x8, [x19]
1011761d0:	a0 22 17 9b	madd	x0, x21, x23, x8
1011761d4:	01 60 00 91	add	x1, x0, #0x18
1011761d8:	42 03 01 cb	sub	x2, x26, x1
1011761dc:	1c 71 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
1011761e0:	5a 63 00 d1	sub	x26, x26, #0x18
1011761e4:	3a 03 00 f9	str	x26, [x25]
1011761e8:	94 06 00 51	sub	w20, w20, #0x1
1011761ec:	df 02 14 6b	cmp	w22, w20
1011761f0:	e1 fe ff 54	b.ne	0x1011761cc
1011761f4:	94 06 00 11	add	w20, w20, #0x1
1011761f8:	f3 af 40 f9	ldr	x19, [sp, #0x158]
1011761fc:	f5 23 41 b9	ldr	w21, [sp, #0x120]
101176200:	f7 a7 40 b9	ldr	w23, [sp, #0xa4]
101176204:	e8 43 21 91	add	x8, sp, #0x850
101176208:	14 79 33 b8	str	w20, [x8, x19, lsl #2]
10117620c:	f8 03 14 aa	mov	x24, x20
101176210:	ec 43 29 91	add	x12, sp, #0xa50
101176214:	ef a3 40 f9	ldr	x15, [sp, #0x140]
101176218:	02 00 00 14	b	0x101176220
10117621c:	ec 43 29 91	add	x12, sp, #0xa50
101176220:	88 79 73 b8	ldr	w8, [x12, x19, lsl #2]
101176224:	08 05 00 11	add	w8, w8, #0x1
101176228:	1f 01 18 6b	cmp	w8, w24
10117622c:	0a 07 00 54	b.ge	0x10117630c
101176230:	f7 a7 00 b9	str	w23, [sp, #0xa4]
101176234:	f5 23 01 b9	str	w21, [sp, #0x120]
101176238:	14 7d 40 93	sxtw	x20, w8
10117623c:	18 7f 40 93	sxtw	x24, w24
101176240:	88 c6 28 8b	add	x8, x20, w8, sxtw #1
101176244:	16 f1 7d d3	lsl	x22, x8, #3
101176248:	e8 05 80 92	mov	x8, #-0x30
10117624c:	1b 01 16 cb	sub	x27, x8, x22
101176250:	97 06 00 91	add	x23, x20, #0x1
101176254:	f3 9b 40 f9	ldr	x19, [sp, #0x130]
101176258:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
10117625c:	19 01 40 f9	ldr	x25, [x8]
101176260:	08 03 80 52	mov	w8, #0x18
101176264:	88 66 08 9b	madd	x8, x20, x8, x25
101176268:	49 03 19 cb	sub	x9, x26, x25
10117626c:	62 03 09 8b	add	x2, x27, x9
101176270:	e9 f3 01 b2	mov	x9, #-0x5555555555555556
101176274:	69 55 95 f2	movk	x9, #0xaaab
101176278:	49 55 e5 f2	movk	x9, #0x2aaa, lsl #48
10117627c:	49 7c 49 9b	smulh	x9, x2, x9
101176280:	2a fd 42 93	asr	x10, x9, #2
101176284:	5c fd 49 8b	add	x28, x10, x9, lsr #63
101176288:	89 07 1c 8b	add	x9, x28, x28, lsl #1
10117628c:	35 f1 7d d3	lsl	x21, x9, #3
101176290:	1a 01 15 8b	add	x26, x8, x21
101176294:	28 03 16 8b	add	x8, x25, x22
101176298:	00 61 00 91	add	x0, x8, #0x18
10117629c:	01 c1 00 91	add	x1, x8, #0x30
1011762a0:	eb 70 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
1011762a4:	5a 63 00 91	add	x26, x26, #0x18
1011762a8:	28 03 15 8b	add	x8, x25, x21
1011762ac:	08 01 16 8b	add	x8, x8, x22
1011762b0:	08 61 00 91	add	x8, x8, #0x18
1011762b4:	68 02 00 f9	str	x8, [x19]
1011762b8:	94 06 00 91	add	x20, x20, #0x1
1011762bc:	18 07 00 d1	sub	x24, x24, #0x1
1011762c0:	d6 62 00 91	add	x22, x22, #0x18
1011762c4:	7b 63 00 d1	sub	x27, x27, #0x18
1011762c8:	e8 06 00 91	add	x8, x23, #0x1
1011762cc:	ff 02 18 eb	cmp	x23, x24
1011762d0:	f7 03 08 aa	mov	x23, x8
1011762d4:	2b fc ff 54	b.lt	0x101176258
1011762d8:	e8 43 21 91	add	x8, sp, #0x850
1011762dc:	f3 af 40 f9	ldr	x19, [sp, #0x158]
1011762e0:	18 79 33 b8	str	w24, [x8, x19, lsl #2]
1011762e4:	08 03 80 52	mov	w8, #0x18
1011762e8:	88 67 08 9b	madd	x8, x28, x8, x25
1011762ec:	1a 01 16 8b	add	x26, x8, x22
1011762f0:	fc 97 40 f9	ldr	x28, [sp, #0x128]
1011762f4:	fb bf 53 a9	ldp	x27, x15, [sp, #0x138]
1011762f8:	ec 43 29 91	add	x12, sp, #0xa50
1011762fc:	e9 6b 40 f9	ldr	x9, [sp, #0xd0]
101176300:	f5 23 41 b9	ldr	w21, [sp, #0x120]
101176304:	f7 a7 40 b9	ldr	w23, [sp, #0xa4]
101176308:	02 00 00 14	b	0x101176310
10117630c:	e9 6b 40 f9	ldr	x9, [sp, #0xd0]
101176310:	e8 83 40 f9	ldr	x8, [sp, #0x100]
101176314:	3f 01 08 6b	cmp	w9, w8
101176318:	e9 d7 9f 1a	cset	w9, gt
10117631c:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
101176320:	08 01 40 f9	ldr	x8, [x8]
101176324:	4a 03 08 cb	sub	x10, x26, x8
101176328:	4a fd 43 d3	lsr	x10, x10, #3
10117632c:	6b 55 95 52	mov	w11, #0xaaab
101176330:	4b 55 b5 72	movk	w11, #0xaaaa, lsl #16
101176334:	56 7d 0b 1b	mul	w22, w10, w11
101176338:	ff ef 01 f9	str	xzr, [sp, #0x3d8]
10117633c:	ff eb 01 f9	str	xzr, [sp, #0x3d0]
101176340:	0a 00 80 12	mov	w10, #-0x1
101176344:	ea e3 03 b9	str	w10, [sp, #0x3e0]
101176348:	ff 93 0f 39	strb	wzr, [sp, #0x3e4]
10117634c:	37 01 17 2a	orr	w23, w9, w23
101176350:	c9 06 00 51	sub	w9, w22, #0x1
101176354:	1f 03 09 6b	cmp	w24, w9
101176358:	e9 17 9f 1a	cset	w9, eq
10117635c:	ff 02 00 72	tst	w23, #0x1
101176360:	2a 00 80 52	mov	w10, #0x1
101176364:	49 11 89 1a	csel	w9, w10, w9, ne
101176368:	ea 67 40 f9	ldr	x10, [sp, #0xc8]
10117636c:	5f 01 0f 6b	cmp	w10, w15
101176370:	ea d7 9f 1a	cset	w10, gt
101176374:	cb 0a 00 51	sub	w11, w22, #0x2
101176378:	09 03 09 4b	sub	w9, w24, w9
10117637c:	3f 01 0b 6b	cmp	w9, w11
101176380:	29 b1 8b 1a	csel	w9, w9, w11, lt
101176384:	54 01 15 2a	orr	w20, w10, w21
101176388:	93 79 b3 b8	ldrsw	x19, [x12, x19, lsl #2]
10117638c:	79 02 14 8b	add	x25, x19, x20
101176390:	3f 01 19 6b	cmp	w9, w25
101176394:	aa 00 00 54	b.ge	0x1011763a8
101176398:	f9 9b 40 f9	ldr	x25, [sp, #0x130]
10117639c:	15 03 80 52	mov	w21, #0x18
1011763a0:	57 08 00 37	tbnz	w23, #0x0, 0x1011764a8
1011763a4:	82 00 00 14	b	0x1011765ac
1011763a8:	36 7d 40 93	sxtw	x22, w9
1011763ac:	18 0b 00 11	add	w24, w24, #0x2
1011763b0:	c9 c6 29 8b	add	x9, x22, w9, sxtw #1
1011763b4:	3a f1 7d d3	lsl	x26, x9, #3
1011763b8:	f5 b3 40 f9	ldr	x21, [sp, #0x160]
1011763bc:	01 01 1a 8b	add	x1, x8, x26
1011763c0:	29 8c 41 b8	ldr	w9, [x1, #0x18]!
1011763c4:	08 69 7a b8	ldr	w8, [x8, x26]
1011763c8:	29 01 08 4b	sub	w9, w9, w8
1011763cc:	20 01 62 1e	scvtf	d0, w9
1011763d0:	61 03 40 bd	ldr	s1, [x27]
1011763d4:	21 a4 20 0f	sshll.2d	v1, v1, #0x0
1011763d8:	21 d8 61 5e	scvtf	d1, d1
1011763dc:	e9 f3 00 b2	mov	x9, #0x5555555555555555
1011763e0:	a9 fa e7 f2	movk	x9, #0x3fd5, lsl #48
1011763e4:	22 01 67 9e	fmov	d2, x9
1011763e8:	00 08 62 1e	fmul	d0, d0, d2
1011763ec:	08 18 61 1e	fdiv	d8, d0, d1
1011763f0:	00 01 62 1e	scvtf	d0, w8
1011763f4:	02 29 68 1e	fadd	d2, d8, d8
1011763f8:	00 28 6e 1e	fadd	d0, d0, d14
1011763fc:	20 00 42 1f	fmadd	d0, d1, d2, d0
101176400:	08 00 78 1e	fcvtzs	w8, d0
101176404:	e8 d3 03 b9	str	w8, [sp, #0x3d0]
101176408:	ff ef 01 f9	str	xzr, [sp, #0x3d8]
10117640c:	e2 43 0f 91	add	x2, sp, #0x3d0
101176410:	e0 03 15 aa	mov	x0, x21
101176414:	81 23 ff 97	bl	__ZNSt3__16vectorIN16BeatAnalyzer_2_06peakss8BeatInfoENS_9allocatorIS3_EEE6insertENS_11__wrap_iterIPKS3_EERS8_
101176418:	a8 02 40 f9	ldr	x8, [x21]
10117641c:	01 01 1a 8b	add	x1, x8, x26
101176420:	28 84 41 b8	ldr	w8, [x1], #0x18
101176424:	00 01 62 1e	scvtf	d0, w8
101176428:	61 03 40 bd	ldr	s1, [x27]
10117642c:	21 a4 20 0f	sshll.2d	v1, v1, #0x0
101176430:	21 d8 61 5e	scvtf	d1, d1
101176434:	00 28 6e 1e	fadd	d0, d0, d14
101176438:	00 01 41 1f	fmadd	d0, d8, d1, d0
10117643c:	08 00 78 1e	fcvtzs	w8, d0
101176440:	e8 d3 03 b9	str	w8, [sp, #0x3d0]
101176444:	e2 43 0f 91	add	x2, sp, #0x3d0
101176448:	e0 03 15 aa	mov	x0, x21
10117644c:	73 23 ff 97	bl	__ZNSt3__16vectorIN16BeatAnalyzer_2_06peakss8BeatInfoENS_9allocatorIS3_EEE6insertENS_11__wrap_iterIPKS3_EERS8_
101176450:	e8 43 21 91	add	x8, sp, #0x850
101176454:	e9 af 40 f9	ldr	x9, [sp, #0x158]
101176458:	18 79 29 b8	str	w24, [x8, x9, lsl #2]
10117645c:	df 02 19 eb	cmp	x22, x25
101176460:	ed 00 00 54	b.le	0x10117647c
101176464:	d6 06 00 d1	sub	x22, x22, #0x1
101176468:	f5 b3 40 f9	ldr	x21, [sp, #0x160]
10117646c:	a8 02 40 f9	ldr	x8, [x21]
101176470:	18 0b 00 11	add	w24, w24, #0x2
101176474:	5a 63 00 d1	sub	x26, x26, #0x18
101176478:	d1 ff ff 17	b	0x1011763bc
10117647c:	f9 9b 40 f9	ldr	x25, [sp, #0x130]
101176480:	29 03 40 f9	ldr	x9, [x25]
101176484:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
101176488:	08 01 40 f9	ldr	x8, [x8]
10117648c:	29 01 08 cb	sub	x9, x9, x8
101176490:	29 fd 43 d3	lsr	x9, x9, #3
101176494:	6a 55 95 52	mov	w10, #0xaaab
101176498:	4a 55 b5 72	movk	w10, #0xaaaa, lsl #16
10117649c:	36 7d 0a 1b	mul	w22, w9, w10
1011764a0:	15 03 80 52	mov	w21, #0x18
1011764a4:	57 08 00 36	tbz	w23, #0x0, 0x1011765ac
1011764a8:	38 08 f8 37	tbnz	w24, #0x1f, 0x1011765ac
1011764ac:	1f 03 16 6b	cmp	w24, w22
1011764b0:	f7 07 40 91	add	x23, sp, #0x1, lsl #12
1011764b4:	f7 c2 11 91	add	x23, x23, #0x470
1011764b8:	ea 07 00 54	b.ge	0x1011765b4
1011764bc:	0a 07 00 11	add	w10, w24, #0x1
1011764c0:	5f 01 16 6b	cmp	w10, w22
1011764c4:	8a 07 00 54	b.ge	0x1011765b4
1011764c8:	09 7f b5 9b	umull	x9, w24, w21
1011764cc:	00 69 69 bc	ldr	s0, [x8, x9]
1011764d0:	00 a4 20 0f	sshll.2d	v0, v0, #0x0
1011764d4:	00 d8 61 5e	scvtf	d0, d0
1011764d8:	69 03 40 b9	ldr	w9, [x27]
1011764dc:	21 01 62 1e	scvtf	d1, w9
1011764e0:	0a 18 61 1e	fdiv	d10, d0, d1
1011764e4:	4a 7d b5 9b	umull	x10, w10, w21
1011764e8:	00 69 6a bc	ldr	s0, [x8, x10]
1011764ec:	00 a4 20 0f	sshll.2d	v0, v0, #0x0
1011764f0:	00 d8 61 5e	scvtf	d0, d0
1011764f4:	00 18 61 1e	fdiv	d0, d0, d1
1011764f8:	0b 38 6a 1e	fsub	d11, d0, d10
1011764fc:	0a 00 c8 d2	mov	x10, #0x400000000000
101176500:	ea 11 e8 f2	movk	x10, #0x408f, lsl #48
101176504:	40 01 67 9e	fmov	d0, x10
101176508:	60 09 60 1e	fmul	d0, d11, d0
10117650c:	00 38 4c 1f	fmadd	d0, d0, d12, d14
101176510:	17 00 78 1e	fcvtzs	w23, d0
101176514:	ff 0a 00 71	cmp	w23, #0x2
101176518:	ab 04 00 54	b.lt	0x1011765ac
10117651c:	e0 02 62 1e	scvtf	d0, w23
101176520:	ff bf 03 b9	str	wzr, [sp, #0x3bc]
101176524:	0a 00 80 12	mov	w10, #-0x1
101176528:	ea cb 03 b9	str	w10, [sp, #0x3c8]
10117652c:	ff 33 0f 39	strb	wzr, [sp, #0x3cc]
101176530:	a8 19 60 1e	fdiv	d8, d13, d0
101176534:	59 00 80 52	mov	w25, #0x2
101176538:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
10117653c:	2a 07 00 51	sub	w10, w25, #0x1
101176540:	40 01 62 1e	scvtf	d0, w10
101176544:	60 09 60 1e	fmul	d0, d11, d0
101176548:	00 28 48 1f	fmadd	d0, d0, d8, d10
10117654c:	21 01 62 1e	scvtf	d1, w9
101176550:	00 38 41 1f	fmadd	d0, d0, d1, d14
101176554:	09 00 78 1e	fcvtzs	w9, d0
101176558:	e9 bb 03 b9	str	w9, [sp, #0x3b8]
10117655c:	ff e3 01 f9	str	xzr, [sp, #0x3c0]
101176560:	08 23 35 9b	smaddl	x8, w24, w21, x8
101176564:	01 61 00 91	add	x1, x8, #0x18
101176568:	e2 e3 0e 91	add	x2, sp, #0x3b8
10117656c:	2b 23 ff 97	bl	__ZNSt3__16vectorIN16BeatAnalyzer_2_06peakss8BeatInfoENS_9allocatorIS3_EEE6insertENS_11__wrap_iterIPKS3_EERS8_
101176570:	e8 87 40 f9	ldr	x8, [sp, #0x108]
101176574:	1f 01 02 f1	cmp	x8, #0x80
101176578:	ac 00 00 54	b.gt	0x10117658c
10117657c:	18 07 00 11	add	w24, w24, #0x1
101176580:	e8 43 21 91	add	x8, sp, #0x850
101176584:	e9 af 40 f9	ldr	x9, [sp, #0x158]
101176588:	18 79 29 b8	str	w24, [x8, x9, lsl #2]
10117658c:	ff 02 19 6b	cmp	w23, w25
101176590:	c0 00 00 54	b.eq	0x1011765a8
101176594:	69 03 40 b9	ldr	w9, [x27]
101176598:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
10117659c:	08 00 40 f9	ldr	x8, [x0]
1011765a0:	39 07 00 11	add	w25, w25, #0x1
1011765a4:	e6 ff ff 17	b	0x10117653c
1011765a8:	f9 9b 40 f9	ldr	x25, [sp, #0x130]
1011765ac:	f7 07 40 91	add	x23, sp, #0x1, lsl #12
1011765b0:	f7 c2 11 91	add	x23, x23, #0x470
1011765b4:	34 08 00 34	cbz	w20, 0x1011766b8
1011765b8:	6a 06 00 91	add	x10, x19, #0x1
1011765bc:	5f 01 16 6b	cmp	w10, w22
1011765c0:	ca 07 00 54	b.ge	0x1011766b8
1011765c4:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
1011765c8:	08 01 40 f9	ldr	x8, [x8]
1011765cc:	69 7e 15 9b	mul	x9, x19, x21
1011765d0:	00 69 69 bc	ldr	s0, [x8, x9]
1011765d4:	00 a4 20 0f	sshll.2d	v0, v0, #0x0
1011765d8:	00 d8 61 5e	scvtf	d0, d0
1011765dc:	69 03 40 b9	ldr	w9, [x27]
1011765e0:	21 01 62 1e	scvtf	d1, w9
1011765e4:	0a 18 61 1e	fdiv	d10, d0, d1
1011765e8:	4a 7d 15 9b	mul	x10, x10, x21
1011765ec:	00 69 6a bc	ldr	s0, [x8, x10]
1011765f0:	00 a4 20 0f	sshll.2d	v0, v0, #0x0
1011765f4:	00 d8 61 5e	scvtf	d0, d0
1011765f8:	00 18 61 1e	fdiv	d0, d0, d1
1011765fc:	0b 38 6a 1e	fsub	d11, d0, d10
101176600:	0a 00 c8 d2	mov	x10, #0x400000000000
101176604:	ea 11 e8 f2	movk	x10, #0x408f, lsl #48
101176608:	40 01 67 9e	fmov	d0, x10
10117660c:	60 09 60 1e	fmul	d0, d11, d0
101176610:	00 38 4c 1f	fmadd	d0, d0, d12, d14
101176614:	0a 00 78 1e	fcvtzs	w10, d0
101176618:	5f 09 00 71	cmp	w10, #0x2
10117661c:	eb 04 00 54	b.lt	0x1011766b8
101176620:	40 01 62 1e	scvtf	d0, w10
101176624:	ff bf 03 b9	str	wzr, [sp, #0x3bc]
101176628:	0b 00 80 12	mov	w11, #-0x1
10117662c:	eb cb 03 b9	str	w11, [sp, #0x3c8]
101176630:	ff 33 0f 39	strb	wzr, [sp, #0x3cc]
101176634:	54 05 00 51	sub	w20, w10, #0x1
101176638:	a8 19 60 1e	fdiv	d8, d13, d0
10117663c:	f6 03 18 2a	mov	w22, w24
101176640:	ea 07 7d b2	orr	x10, xzr, #0x18
101176644:	73 2a 15 9b	madd	x19, x19, x21, x10
101176648:	37 00 80 52	mov	w23, #0x1
10117664c:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
101176650:	e0 02 62 1e	scvtf	d0, w23
101176654:	60 09 60 1e	fmul	d0, d11, d0
101176658:	00 28 48 1f	fmadd	d0, d0, d8, d10
10117665c:	21 01 62 1e	scvtf	d1, w9
101176660:	00 38 41 1f	fmadd	d0, d0, d1, d14
101176664:	09 00 78 1e	fcvtzs	w9, d0
101176668:	e9 bb 03 b9	str	w9, [sp, #0x3b8]
10117666c:	ff e3 01 f9	str	xzr, [sp, #0x3c0]
101176670:	61 02 08 8b	add	x1, x19, x8
101176674:	e2 e3 0e 91	add	x2, sp, #0x3b8
101176678:	e8 22 ff 97	bl	__ZNSt3__16vectorIN16BeatAnalyzer_2_06peakss8BeatInfoENS_9allocatorIS3_EEE6insertENS_11__wrap_iterIPKS3_EERS8_
10117667c:	c8 02 17 0b	add	w8, w22, w23
101176680:	e9 43 21 91	add	x9, sp, #0x850
101176684:	ea af 40 f9	ldr	x10, [sp, #0x158]
101176688:	28 79 2a b8	str	w8, [x9, x10, lsl #2]
10117668c:	9f 02 17 eb	cmp	x20, x23
101176690:	e0 00 00 54	b.eq	0x1011766ac
101176694:	69 03 40 b9	ldr	w9, [x27]
101176698:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
10117669c:	08 00 40 f9	ldr	x8, [x0]
1011766a0:	f7 06 00 91	add	x23, x23, #0x1
1011766a4:	73 62 00 91	add	x19, x19, #0x18
1011766a8:	ea ff ff 17	b	0x101176650
1011766ac:	18 03 17 0b	add	w24, w24, w23
1011766b0:	f7 07 40 91	add	x23, sp, #0x1, lsl #12
1011766b4:	f7 c2 11 91	add	x23, x23, #0x470
1011766b8:	f6 07 40 91	add	x22, sp, #0x1, lsl #12
1011766bc:	d6 c2 19 91	add	x22, x22, #0x670
1011766c0:	f3 b3 40 f9	ldr	x19, [sp, #0x160]
1011766c4:	61 02 40 f9	ldr	x1, [x19]
1011766c8:	28 18 40 b9	ldr	w8, [x1, #0x18]
1011766cc:	29 00 40 b9	ldr	w9, [x1]
1011766d0:	08 01 09 4b	sub	w8, w8, w9
1011766d4:	28 01 08 6b	subs	w8, w9, w8
1011766d8:	6d 01 00 54	b.le	0x101176704
1011766dc:	e8 d3 03 b9	str	w8, [sp, #0x3d0]
1011766e0:	ff ef 01 f9	str	xzr, [sp, #0x3d8]
1011766e4:	e2 43 0f 91	add	x2, sp, #0x3d0
1011766e8:	e0 03 13 aa	mov	x0, x19
1011766ec:	cb 22 ff 97	bl	__ZNSt3__16vectorIN16BeatAnalyzer_2_06peakss8BeatInfoENS_9allocatorIS3_EEE6insertENS_11__wrap_iterIPKS3_EERS8_
1011766f0:	08 07 00 11	add	w8, w24, #0x1
1011766f4:	e9 43 21 91	add	x9, sp, #0x850
1011766f8:	ea af 40 f9	ldr	x10, [sp, #0x158]
1011766fc:	28 79 2a b8	str	w8, [x9, x10, lsl #2]
101176700:	61 02 40 f9	ldr	x1, [x19]
101176704:	e9 f3 01 b2	mov	x9, #-0x5555555555555556
101176708:	69 55 95 f2	movk	x9, #0xaaab
10117670c:	28 03 40 f9	ldr	x8, [x25]
101176710:	08 01 01 cb	sub	x8, x8, x1
101176714:	08 fd 43 93	asr	x8, x8, #3
101176718:	13 7d 09 9b	mul	x19, x8, x9
10117671c:	7f 0a 00 71	cmp	w19, #0x2
101176720:	f8 87 40 f9	ldr	x24, [sp, #0x108]
101176724:	ab 06 00 54	b.lt	0x1011767f8
101176728:	68 06 00 51	sub	w8, w19, #0x1
10117672c:	09 7d b5 9b	umull	x9, w8, w21
101176730:	2a 68 69 b8	ldr	w10, [x1, x9]
101176734:	69 7e 60 d3	lsl	x9, x19, #32
101176738:	eb 7b 5f b2	mov	x11, #-0x200000000
10117673c:	2b 01 0b 8b	add	x11, x9, x11
101176740:	6b fd 60 93	asr	x11, x11, #32
101176744:	6b 7d 15 9b	mul	x11, x11, x21
101176748:	2b 68 6b b8	ldr	w11, [x1, x11]
10117674c:	54 01 0b 6b	subs	w20, w10, w11
101176750:	40 05 00 54	b.eq	0x1011767f8
101176754:	8b 1f 40 b9	ldr	w11, [x28, #0x1c]
101176758:	6a 01 0a 4b	sub	w10, w11, w10
10117675c:	40 01 62 1e	scvtf	d0, w10
101176760:	81 02 62 1e	scvtf	d1, w20
101176764:	00 18 61 1e	fdiv	d0, d0, d1
101176768:	00 20 6d 1e	fcmp	d0, d13
10117676c:	6d 04 00 54	b.le	0x1011767f8
101176770:	0a 00 78 1e	fcvtzs	w10, d0
101176774:	ff e3 01 f9	str	xzr, [sp, #0x3c0]
101176778:	ff df 01 f9	str	xzr, [sp, #0x3b8]
10117677c:	0b 00 80 12	mov	w11, #-0x1
101176780:	eb cb 03 b9	str	w11, [sp, #0x3c8]
101176784:	ff 33 0f 39	strb	wzr, [sp, #0x3cc]
101176788:	5f 05 00 71	cmp	w10, #0x1
10117678c:	cb 02 00 54	b.lt	0x1011767e4
101176790:	29 fd 60 93	asr	x9, x9, #32
101176794:	08 05 08 8b	add	x8, x8, x8, lsl #1
101176798:	16 f1 7d d3	lsl	x22, x8, #3
10117679c:	28 05 09 8b	add	x8, x9, x9, lsl #1
1011767a0:	17 f1 7d d3	lsl	x23, x8, #3
1011767a4:	58 05 00 d1	sub	x24, x10, #0x1
1011767a8:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
1011767ac:	28 68 76 b8	ldr	w8, [x1, x22]
1011767b0:	08 01 14 0b	add	w8, w8, w20
1011767b4:	e8 bb 03 b9	str	w8, [sp, #0x3b8]
1011767b8:	ff e3 01 f9	str	xzr, [sp, #0x3c0]
1011767bc:	e1 02 01 8b	add	x1, x23, x1
1011767c0:	e2 e3 0e 91	add	x2, sp, #0x3b8
1011767c4:	95 22 ff 97	bl	__ZNSt3__16vectorIN16BeatAnalyzer_2_06peakss8BeatInfoENS_9allocatorIS3_EEE6insertENS_11__wrap_iterIPKS3_EERS8_
1011767c8:	f8 00 00 b4	cbz	x24, 0x1011767e4
1011767cc:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
1011767d0:	01 00 40 f9	ldr	x1, [x0]
1011767d4:	d6 62 00 91	add	x22, x22, #0x18
1011767d8:	f7 62 00 91	add	x23, x23, #0x18
1011767dc:	18 07 00 d1	sub	x24, x24, #0x1
1011767e0:	f3 ff ff 17	b	0x1011767ac
1011767e4:	f7 07 40 91	add	x23, sp, #0x1, lsl #12
1011767e8:	f7 c2 11 91	add	x23, x23, #0x470
1011767ec:	f6 07 40 91	add	x22, sp, #0x1, lsl #12
1011767f0:	d6 c2 19 91	add	x22, x22, #0x670
1011767f4:	f8 87 40 f9	ldr	x24, [sp, #0x108]
1011767f8:	e8 c3 40 b9	ldr	w8, [sp, #0xc0]
1011767fc:	a8 d4 00 34	cbz	w8, 0x101178290
101176800:	29 03 40 f9	ldr	x9, [x25]
101176804:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
101176808:	08 01 40 f9	ldr	x8, [x8]
10117680c:	29 01 08 cb	sub	x9, x9, x8
101176810:	29 fd 43 d3	lsr	x9, x9, #3
101176814:	6a 55 95 52	mov	w10, #0xaaab
101176818:	4a 55 b5 72	movk	w10, #0xaaaa, lsl #16
10117681c:	33 7d 0a 1b	mul	w19, w9, w10
101176820:	69 0a 00 51	sub	w9, w19, #0x2
101176824:	3f 05 00 71	cmp	w9, #0x1
101176828:	2a c5 9f 1a	csinc	w10, w9, wzr, gt
10117682c:	0f 06 80 52	mov	w15, #0x30
101176830:	2b 00 80 52	mov	w11, #0x1
101176834:	7f 01 0a eb	cmp	x11, x10
101176838:	c0 d2 00 54	b.eq	0x101178290
10117683c:	e9 03 0b aa	mov	x9, x11
101176840:	f4 03 0f aa	mov	x20, x15
101176844:	6b 21 15 9b	madd	x11, x11, x21, x8
101176848:	70 01 40 b9	ldr	w16, [x11]
10117684c:	6d 81 5e b8	ldur	w13, [x11, #-0x18]
101176850:	2b 05 00 91	add	x11, x9, #0x1
101176854:	6c 7d 40 92	and	x12, x11, #0xffffffff
101176858:	8c 7d 15 9b	mul	x12, x12, x21
10117685c:	0c 69 6c b8	ldr	w12, [x8, x12]
101176860:	0f 02 0d 4b	sub	w15, w16, w13
101176864:	2d 09 00 11	add	w13, w9, #0x2
101176868:	ad 7d b5 9b	umull	x13, w13, w21
10117686c:	0e 69 6d b8	ldr	w14, [x8, x13]
101176870:	cd 01 0c 4b	sub	w13, w14, w12
101176874:	f1 09 0f 0b	add	w17, w15, w15, lsl #2
101176878:	a0 09 0d 0b	add	w0, w13, w13, lsl #2
10117687c:	8f 62 00 91	add	x15, x20, #0x18
101176880:	90 01 10 4b	sub	w16, w12, w16
101176884:	1f 02 11 6b	cmp	w16, w17
101176888:	00 d2 40 7a	ccmp	w16, w0, #0x0, le
10117688c:	4d fd ff 54	b.le	0x101176834
101176890:	df 01 0c 6b	cmp	w14, w12
101176894:	e0 cf 00 54	b.eq	0x101178290
101176898:	00 02 62 1e	scvtf	d0, w16
10117689c:	a1 01 62 1e	scvtf	d1, w13
1011768a0:	01 18 61 1e	fdiv	d1, d0, d1
1011768a4:	20 20 6d 1e	fcmp	d1, d13
1011768a8:	4d cf 00 54	b.le	0x101178290
1011768ac:	2a 00 78 1e	fcvtzs	w10, d1
1011768b0:	ff e3 01 f9	str	xzr, [sp, #0x3c0]
1011768b4:	ff df 01 f9	str	xzr, [sp, #0x3b8]
1011768b8:	0b 00 80 12	mov	w11, #-0x1
1011768bc:	eb cb 03 b9	str	w11, [sp, #0x3c8]
1011768c0:	ff 33 0f 39	strb	wzr, [sp, #0x3cc]
1011768c4:	5f 09 00 71	cmp	w10, #0x2
1011768c8:	8b cd 00 54	b.lt	0x101178278
1011768cc:	21 c0 65 1e	frintz	d1, d1
1011768d0:	00 18 61 1e	fdiv	d0, d0, d1
1011768d4:	16 00 78 1e	fcvtzs	w22, d0
1011768d8:	37 7d 40 92	and	x23, x9, #0xffffffff
1011768dc:	58 09 00 d1	sub	x24, x10, #0x2
1011768e0:	f9 03 16 aa	mov	x25, x22
1011768e4:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
1011768e8:	e9 7e 15 9b	mul	x9, x23, x21
1011768ec:	09 69 69 b8	ldr	w9, [x8, x9]
1011768f0:	29 03 09 0b	add	w9, w25, w9
1011768f4:	e9 bb 03 b9	str	w9, [sp, #0x3b8]
1011768f8:	ff e3 01 f9	str	xzr, [sp, #0x3c0]
1011768fc:	81 02 08 8b	add	x1, x20, x8
101176900:	e2 e3 0e 91	add	x2, sp, #0x3b8
101176904:	45 22 ff 97	bl	__ZNSt3__16vectorIN16BeatAnalyzer_2_06peakss8BeatInfoENS_9allocatorIS3_EEE6insertENS_11__wrap_iterIPKS3_EERS8_
101176908:	98 cb 00 b4	cbz	x24, 0x101178278
10117690c:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
101176910:	08 00 40 f9	ldr	x8, [x0]
101176914:	39 03 16 0b	add	w25, w25, w22
101176918:	94 62 00 91	add	x20, x20, #0x18
10117691c:	18 07 00 d1	sub	x24, x24, #0x1
101176920:	f2 ff ff 17	b	0x1011768e8
101176924:	4a 17 00 91	add	x10, x26, #0x5
101176928:	eb 8b 40 f9	ldr	x11, [sp, #0x110]
10117692c:	60 79 6a fc	ldr	d0, [x11, x10, lsl #3]
101176930:	eb a3 90 d2	mov	x11, #0x851f
101176934:	6b 3d aa f2	movk	x11, #0x51eb, lsl #16
101176938:	0b d7 c3 f2	movk	x11, #0x1eb8, lsl #32
10117693c:	2b fe e7 f2	movk	x11, #0x3ff1, lsl #48
101176940:	61 01 67 9e	fmov	d1, x11
101176944:	00 20 61 1e	fcmp	d0, d1
101176948:	17 03 80 52	mov	w23, #0x18
10117694c:	fa a3 40 f9	ldr	x26, [sp, #0x140]
101176950:	cd 00 00 54	b.le	0x101176968
101176954:	eb e7 02 b2	mov	x11, #-0x3333333333333334
101176958:	cb fe e7 f2	movk	x11, #0x3ff6, lsl #48
10117695c:	61 01 67 9e	fmov	d1, x11
101176960:	00 20 61 1e	fcmp	d0, d1
101176964:	ab 01 00 54	b.lt	0x101176998
101176968:	eb e7 00 b2	mov	x11, #0x3333333333333333
10117696c:	8b 66 86 f2	movk	x11, #0x3334
101176970:	2b ff e7 f2	movk	x11, #0x3ff9, lsl #48
101176974:	61 01 67 9e	fmov	d1, x11
101176978:	00 20 61 1e	fcmp	d0, d1
10117697c:	ad dc fd 54	b.le	0x101172510
101176980:	eb e7 02 b2	mov	x11, #-0x3333333333333334
101176984:	ab 99 99 f2	movk	x11, #0xcccd
101176988:	8b ff e7 f2	movk	x11, #0x3ffc, lsl #48
10117698c:	61 01 67 9e	fmov	d1, x11
101176990:	00 20 61 1e	fcmp	d0, d1
101176994:	ea db fd 54	b.ge	0x101172510
101176998:	31 00 80 52	mov	w17, #0x1
10117699c:	e0 03 0a aa	mov	x0, x10
1011769a0:	dc ee ff 17	b	0x101172510
1011769a4:	08 15 00 11	add	w8, w8, #0x5
1011769a8:	eb 8b 40 f9	ldr	x11, [sp, #0x110]
1011769ac:	60 d9 68 fc	ldr	d0, [x11, w8, sxtw #3]
1011769b0:	eb a3 90 d2	mov	x11, #0x851f
1011769b4:	6b 3d aa f2	movk	x11, #0x51eb, lsl #16
1011769b8:	0b d7 c3 f2	movk	x11, #0x1eb8, lsl #32
1011769bc:	2b fe e7 f2	movk	x11, #0x3ff1, lsl #48
1011769c0:	61 01 67 9e	fmov	d1, x11
1011769c4:	00 20 61 1e	fcmp	d0, d1
1011769c8:	cd 00 00 54	b.le	0x1011769e0
1011769cc:	eb e7 02 b2	mov	x11, #-0x3333333333333334
1011769d0:	cb fe e7 f2	movk	x11, #0x3ff6, lsl #48
1011769d4:	61 01 67 9e	fmov	d1, x11
1011769d8:	00 20 61 1e	fcmp	d0, d1
1011769dc:	ab 01 00 54	b.lt	0x101176a10
1011769e0:	eb e7 00 b2	mov	x11, #0x3333333333333333
1011769e4:	8b 66 86 f2	movk	x11, #0x3334
1011769e8:	2b ff e7 f2	movk	x11, #0x3ff9, lsl #48
1011769ec:	61 01 67 9e	fmov	d1, x11
1011769f0:	00 20 61 1e	fcmp	d0, d1
1011769f4:	6d fc fd 54	b.le	0x101172980
1011769f8:	eb e7 02 b2	mov	x11, #-0x3333333333333334
1011769fc:	ab 99 99 f2	movk	x11, #0xcccd
101176a00:	8b ff e7 f2	movk	x11, #0x3ffc, lsl #48
101176a04:	61 01 67 9e	fmov	d1, x11
101176a08:	00 20 61 1e	fcmp	d0, d1
101176a0c:	aa fb fd 54	b.ge	0x101172980
101176a10:	31 00 80 52	mov	w17, #0x1
101176a14:	5c ef ff 17	b	0x101172784
101176a18:	f3 03 08 aa	mov	x19, x8
101176a1c:	18 e3 ff 17	b	0x10116f67c
101176a20:	e1 03 09 aa	mov	x1, x9
101176a24:	5a e3 ff 17	b	0x10116f78c
101176a28:	0b 1a 00 51	sub	w11, w16, #0x6
101176a2c:	5f 03 0b 6b	cmp	w26, w11
101176a30:	8d d0 00 54	b.le	0x101178440
101176a34:	fa 03 0a aa	mov	x26, x10
101176a38:	20 e9 ff 17	b	0x101170eb8
101176a3c:	0b 1a 00 51	sub	w11, w16, #0x6
101176a40:	1f 01 0b 6b	cmp	w8, w11
101176a44:	6c 33 fd 54	b.gt	0x1011710b0
101176a48:	08 15 00 11	add	w8, w8, #0x5
101176a4c:	80 da 68 fc	ldr	d0, [x20, w8, sxtw #3]
101176a50:	eb a3 90 d2	mov	x11, #0x851f
101176a54:	6b 3d aa f2	movk	x11, #0x51eb, lsl #16
101176a58:	0b d7 c3 f2	movk	x11, #0x1eb8, lsl #32
101176a5c:	2b fe e7 f2	movk	x11, #0x3ff1, lsl #48
101176a60:	61 01 67 9e	fmov	d1, x11
101176a64:	00 20 61 1e	fcmp	d0, d1
101176a68:	eb d7 9f 1a	cset	w11, gt
101176a6c:	c1 01 67 9e	fmov	d1, x14
101176a70:	00 20 61 1e	fcmp	d0, d1
101176a74:	ec a7 9f 1a	cset	w12, lt
101176a78:	6b 01 0c 0a	and	w11, w11, w12
101176a7c:	e1 01 67 9e	fmov	d1, x15
101176a80:	00 20 61 1e	fcmp	d0, d1
101176a84:	ec d7 9f 1a	cset	w12, gt
101176a88:	6b 01 0c 2a	orr	w11, w11, w12
101176a8c:	7f 01 00 71	cmp	w11, #0x0
101176a90:	08 11 89 1a	csel	w8, w8, w9, ne
101176a94:	71 01 11 2a	orr	w17, w11, w17
101176a98:	87 e9 ff 17	b	0x1011710b4
101176a9c:	49 13 00 71	subs	w9, w26, #0x4
101176aa0:	63 04 00 54	b.lo	0x101176b2c
101176aa4:	80 5a 69 fc	ldr	d0, [x20, w9, uxtw #3]
101176aa8:	c1 01 67 9e	fmov	d1, x14
101176aac:	00 20 61 1e	fcmp	d0, d1
101176ab0:	ea a3 90 d2	mov	x10, #0x851f
101176ab4:	6a 3d aa f2	movk	x10, #0x51eb, lsl #16
101176ab8:	0a d7 c3 f2	movk	x10, #0x1eb8, lsl #32
101176abc:	2a fe e7 f2	movk	x10, #0x3ff1, lsl #48
101176ac0:	41 01 67 9e	fmov	d1, x10
101176ac4:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
101176ac8:	8c 00 00 54	b.gt	0x101176ad8
101176acc:	e1 01 67 9e	fmov	d1, x15
101176ad0:	00 20 61 1e	fcmp	d0, d1
101176ad4:	ed 02 00 54	b.le	0x101176b30
101176ad8:	4a 17 00 71	subs	w10, w26, #0x5
101176adc:	83 02 00 54	b.lo	0x101176b2c
101176ae0:	80 5a 6a fc	ldr	d0, [x20, w10, uxtw #3]
101176ae4:	eb a3 90 d2	mov	x11, #0x851f
101176ae8:	6b 3d aa f2	movk	x11, #0x51eb, lsl #16
101176aec:	0b d7 c3 f2	movk	x11, #0x1eb8, lsl #32
101176af0:	2b fe e7 f2	movk	x11, #0x3ff1, lsl #48
101176af4:	61 01 67 9e	fmov	d1, x11
101176af8:	00 20 61 1e	fcmp	d0, d1
101176afc:	eb d7 9f 1a	cset	w11, gt
101176b00:	c1 01 67 9e	fmov	d1, x14
101176b04:	00 20 61 1e	fcmp	d0, d1
101176b08:	ec a7 9f 1a	cset	w12, lt
101176b0c:	6b 01 0c 0a	and	w11, w11, w12
101176b10:	e1 01 67 9e	fmov	d1, x15
101176b14:	00 20 61 1e	fcmp	d0, d1
101176b18:	ec d7 9f 1a	cset	w12, gt
101176b1c:	75 01 0c 2a	orr	w21, w11, w12
101176b20:	bf 02 00 71	cmp	w21, #0x0
101176b24:	51 11 89 1a	csel	w17, w10, w9, ne
101176b28:	03 00 00 14	b	0x101176b34
101176b2c:	11 00 80 52	mov	w17, #0x0
101176b30:	15 00 80 52	mov	w21, #0x0
101176b34:	09 0a 00 51	sub	w9, w16, #0x2
101176b38:	5f 03 09 6b	cmp	w26, w9
101176b3c:	0c 04 00 54	b.gt	0x101176bbc
101176b40:	80 da 60 fc	ldr	d0, [x20, w0, sxtw #3]
101176b44:	c1 01 67 9e	fmov	d1, x14
101176b48:	00 20 61 1e	fcmp	d0, d1
101176b4c:	ea a3 90 d2	mov	x10, #0x851f
101176b50:	6a 3d aa f2	movk	x10, #0x51eb, lsl #16
101176b54:	0a d7 c3 f2	movk	x10, #0x1eb8, lsl #32
101176b58:	2a fe e7 f2	movk	x10, #0x3ff1, lsl #48
101176b5c:	41 01 67 9e	fmov	d1, x10
101176b60:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
101176b64:	8c 00 00 54	b.gt	0x101176b74
101176b68:	e1 01 67 9e	fmov	d1, x15
101176b6c:	00 20 61 1e	fcmp	d0, d1
101176b70:	6d 02 00 54	b.le	0x101176bbc
101176b74:	0a 0e 00 51	sub	w10, w16, #0x3
101176b78:	5f 03 0a 6b	cmp	w26, w10
101176b7c:	ec 01 00 54	b.gt	0x101176bb8
101176b80:	ea 83 40 f9	ldr	x10, [sp, #0x100]
101176b84:	80 da 6a fc	ldr	d0, [x20, w10, sxtw #3]
101176b88:	c1 01 67 9e	fmov	d1, x14
101176b8c:	00 20 61 1e	fcmp	d0, d1
101176b90:	ea a3 90 d2	mov	x10, #0x851f
101176b94:	6a 3d aa f2	movk	x10, #0x51eb, lsl #16
101176b98:	0a d7 c3 f2	movk	x10, #0x1eb8, lsl #32
101176b9c:	2a fe e7 f2	movk	x10, #0x3ff1, lsl #48
101176ba0:	41 01 67 9e	fmov	d1, x10
101176ba4:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
101176ba8:	ec 4b 00 54	b.gt	0x101177524
101176bac:	e1 01 67 9e	fmov	d1, x15
101176bb0:	00 20 61 1e	fcmp	d0, d1
101176bb4:	8c 4b 00 54	b.gt	0x101177524
101176bb8:	fa 03 00 aa	mov	x26, x0
101176bbc:	0b 05 00 71	subs	w11, w8, #0x1
101176bc0:	eb 01 00 54	b.lt	0x101176bfc
101176bc4:	80 5a 6b fc	ldr	d0, [x20, w11, uxtw #3]
101176bc8:	ea a3 90 d2	mov	x10, #0x851f
101176bcc:	6a 3d aa f2	movk	x10, #0x51eb, lsl #16
101176bd0:	0a d7 c3 f2	movk	x10, #0x1eb8, lsl #32
101176bd4:	2a fe e7 f2	movk	x10, #0x3ff1, lsl #48
101176bd8:	41 01 67 9e	fmov	d1, x10
101176bdc:	00 20 61 1e	fcmp	d0, d1
101176be0:	2d 01 00 54	b.le	0x101176c04
101176be4:	c1 01 67 9e	fmov	d1, x14
101176be8:	00 20 61 1e	fcmp	d0, d1
101176bec:	ca 00 00 54	b.ge	0x101176c04
101176bf0:	1f 09 00 71	cmp	w8, #0x2
101176bf4:	4a 01 00 54	b.ge	0x101176c1c
101176bf8:	4d 00 00 14	b	0x101176d2c
101176bfc:	ea 03 08 aa	mov	x10, x8
101176c00:	4c 00 00 14	b	0x101176d30
101176c04:	e1 01 67 9e	fmov	d1, x15
101176c08:	00 20 61 1e	fcmp	d0, d1
101176c0c:	0a d1 9f 1a	csel	w10, w8, wzr, le
101176c10:	0d 09 00 54	b.le	0x101176d30
101176c14:	1f 09 00 71	cmp	w8, #0x2
101176c18:	cb 08 00 54	b.lt	0x101176d30
101176c1c:	0a 09 00 51	sub	w10, w8, #0x2
101176c20:	80 5a 6a fc	ldr	d0, [x20, w10, uxtw #3]
101176c24:	c1 01 67 9e	fmov	d1, x14
101176c28:	00 20 61 1e	fcmp	d0, d1
101176c2c:	ec a3 90 d2	mov	x12, #0x851f
101176c30:	6c 3d aa f2	movk	x12, #0x51eb, lsl #16
101176c34:	0c d7 c3 f2	movk	x12, #0x1eb8, lsl #32
101176c38:	2c fe e7 f2	movk	x12, #0x3ff1, lsl #48
101176c3c:	81 01 67 9e	fmov	d1, x12
101176c40:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
101176c44:	cc 00 00 54	b.gt	0x101176c5c
101176c48:	e1 01 67 9e	fmov	d1, x15
101176c4c:	00 20 61 1e	fcmp	d0, d1
101176c50:	6c 00 00 54	b.gt	0x101176c5c
101176c54:	ea 03 0b aa	mov	x10, x11
101176c58:	36 00 00 14	b	0x101176d30
101176c5c:	0b 0d 00 71	subs	w11, w8, #0x3
101176c60:	63 06 00 54	b.lo	0x101176d2c
101176c64:	80 5a 6b fc	ldr	d0, [x20, w11, uxtw #3]
101176c68:	c1 01 67 9e	fmov	d1, x14
101176c6c:	00 20 61 1e	fcmp	d0, d1
101176c70:	ec a3 90 d2	mov	x12, #0x851f
101176c74:	6c 3d aa f2	movk	x12, #0x51eb, lsl #16
101176c78:	0c d7 c3 f2	movk	x12, #0x1eb8, lsl #32
101176c7c:	2c fe e7 f2	movk	x12, #0x3ff1, lsl #48
101176c80:	81 01 67 9e	fmov	d1, x12
101176c84:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
101176c88:	8c 00 00 54	b.gt	0x101176c98
101176c8c:	e1 01 67 9e	fmov	d1, x15
101176c90:	00 20 61 1e	fcmp	d0, d1
101176c94:	ed 04 00 54	b.le	0x101176d30
101176c98:	0a 11 00 71	subs	w10, w8, #0x4
101176c9c:	83 04 00 54	b.lo	0x101176d2c
101176ca0:	80 5a 6a fc	ldr	d0, [x20, w10, uxtw #3]
101176ca4:	c1 01 67 9e	fmov	d1, x14
101176ca8:	00 20 61 1e	fcmp	d0, d1
101176cac:	ec a3 90 d2	mov	x12, #0x851f
101176cb0:	6c 3d aa f2	movk	x12, #0x51eb, lsl #16
101176cb4:	0c d7 c3 f2	movk	x12, #0x1eb8, lsl #32
101176cb8:	2c fe e7 f2	movk	x12, #0x3ff1, lsl #48
101176cbc:	81 01 67 9e	fmov	d1, x12
101176cc0:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
101176cc4:	8c 00 00 54	b.gt	0x101176cd4
101176cc8:	e1 01 67 9e	fmov	d1, x15
101176ccc:	00 20 61 1e	fcmp	d0, d1
101176cd0:	2d fc ff 54	b.le	0x101176c54
101176cd4:	0b 15 00 71	subs	w11, w8, #0x5
101176cd8:	a3 02 00 54	b.lo	0x101176d2c
101176cdc:	80 5a 6b fc	ldr	d0, [x20, w11, uxtw #3]
101176ce0:	ec a3 90 d2	mov	x12, #0x851f
101176ce4:	6c 3d aa f2	movk	x12, #0x51eb, lsl #16
101176ce8:	0c d7 c3 f2	movk	x12, #0x1eb8, lsl #32
101176cec:	2c fe e7 f2	movk	x12, #0x3ff1, lsl #48
101176cf0:	81 01 67 9e	fmov	d1, x12
101176cf4:	00 20 61 1e	fcmp	d0, d1
101176cf8:	ec d7 9f 1a	cset	w12, gt
101176cfc:	c1 01 67 9e	fmov	d1, x14
101176d00:	00 20 61 1e	fcmp	d0, d1
101176d04:	ed a7 9f 1a	cset	w13, lt
101176d08:	8c 01 0d 0a	and	w12, w12, w13
101176d0c:	e1 01 67 9e	fmov	d1, x15
101176d10:	00 20 61 1e	fcmp	d0, d1
101176d14:	ed d7 9f 1a	cset	w13, gt
101176d18:	8c 01 0d 2a	orr	w12, w12, w13
101176d1c:	9f 01 00 71	cmp	w12, #0x0
101176d20:	6a 11 8a 1a	csel	w10, w11, w10, ne
101176d24:	95 01 15 2a	orr	w21, w12, w21
101176d28:	02 00 00 14	b	0x101176d30
101176d2c:	0a 00 80 52	mov	w10, #0x0
101176d30:	1f 01 09 6b	cmp	w8, w9
101176d34:	2c 04 00 54	b.gt	0x101176db8
101176d38:	09 05 00 11	add	w9, w8, #0x1
101176d3c:	80 da 69 fc	ldr	d0, [x20, w9, sxtw #3]
101176d40:	c1 01 67 9e	fmov	d1, x14
101176d44:	00 20 61 1e	fcmp	d0, d1
101176d48:	eb a3 90 d2	mov	x11, #0x851f
101176d4c:	6b 3d aa f2	movk	x11, #0x51eb, lsl #16
101176d50:	0b d7 c3 f2	movk	x11, #0x1eb8, lsl #32
101176d54:	2b fe e7 f2	movk	x11, #0x3ff1, lsl #48
101176d58:	61 01 67 9e	fmov	d1, x11
101176d5c:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
101176d60:	8c 00 00 54	b.gt	0x101176d70
101176d64:	e1 01 67 9e	fmov	d1, x15
101176d68:	00 20 61 1e	fcmp	d0, d1
101176d6c:	6d 02 00 54	b.le	0x101176db8
101176d70:	0b 0e 00 51	sub	w11, w16, #0x3
101176d74:	1f 01 0b 6b	cmp	w8, w11
101176d78:	ec 01 00 54	b.gt	0x101176db4
101176d7c:	0b 09 00 11	add	w11, w8, #0x2
101176d80:	80 da 6b fc	ldr	d0, [x20, w11, sxtw #3]
101176d84:	c1 01 67 9e	fmov	d1, x14
101176d88:	00 20 61 1e	fcmp	d0, d1
101176d8c:	ec a3 90 d2	mov	x12, #0x851f
101176d90:	6c 3d aa f2	movk	x12, #0x51eb, lsl #16
101176d94:	0c d7 c3 f2	movk	x12, #0x1eb8, lsl #32
101176d98:	2c fe e7 f2	movk	x12, #0x3ff1, lsl #48
101176d9c:	81 01 67 9e	fmov	d1, x12
101176da0:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
101176da4:	6c 3e 00 54	b.gt	0x101177570
101176da8:	e1 01 67 9e	fmov	d1, x15
101176dac:	00 20 61 1e	fcmp	d0, d1
101176db0:	0c 3e 00 54	b.gt	0x101177570
101176db4:	e8 03 09 aa	mov	x8, x9
101176db8:	5f 01 00 71	cmp	w10, #0x0
101176dbc:	56 c1 9f 1a	csel	w22, w10, wzr, gt
101176dc0:	f7 9b 40 f9	ldr	x23, [sp, #0x130]
101176dc4:	fb 02 40 f9	ldr	x27, [x23]
101176dc8:	e9 b3 40 f9	ldr	x9, [sp, #0x160]
101176dcc:	29 01 40 f9	ldr	x9, [x9]
101176dd0:	6a 03 09 cb	sub	x10, x27, x9
101176dd4:	4a fd 43 93	asr	x10, x10, #3
101176dd8:	eb f3 01 b2	mov	x11, #-0x5555555555555556
101176ddc:	6b 55 95 f2	movk	x11, #0xaaab
101176de0:	58 7d 0b 9b	mul	x24, x10, x11
101176de4:	0b 07 00 d1	sub	x11, x24, #0x1
101176de8:	0a 07 00 51	sub	w10, w24, #0x1
101176dec:	7f c1 28 eb	cmp	x11, w8, sxtw
101176df0:	59 31 88 1a	csel	w25, w10, w8, lo
101176df4:	3f 03 16 6b	cmp	w25, w22
101176df8:	f5 03 01 b9	str	w21, [sp, #0x100]
101176dfc:	f6 93 00 f9	str	x22, [sp, #0x120]
101176e00:	cd 04 00 54	b.le	0x101176e98
101176e04:	e8 03 19 aa	mov	x8, x25
101176e08:	f1 d3 00 b9	str	w17, [sp, #0xd0]
101176e0c:	33 7f 40 93	sxtw	x19, w25
101176e10:	14 03 80 52	mov	w20, #0x18
101176e14:	00 25 34 9b	smaddl	x0, w8, w20, x9
101176e18:	01 60 00 91	add	x1, x0, #0x18
101176e1c:	62 03 01 cb	sub	x2, x27, x1
101176e20:	0b 6e 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
101176e24:	7b 63 00 d1	sub	x27, x27, #0x18
101176e28:	fb 02 00 f9	str	x27, [x23]
101176e2c:	73 06 00 d1	sub	x19, x19, #0x1
101176e30:	7f 02 16 eb	cmp	x19, x22
101176e34:	f5 b3 40 f9	ldr	x21, [sp, #0x160]
101176e38:	6d 01 00 54	b.le	0x101176e64
101176e3c:	a8 02 40 f9	ldr	x8, [x21]
101176e40:	60 22 14 9b	madd	x0, x19, x20, x8
101176e44:	01 60 00 91	add	x1, x0, #0x18
101176e48:	62 03 01 cb	sub	x2, x27, x1
101176e4c:	00 6e 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
101176e50:	7b 63 00 d1	sub	x27, x27, #0x18
101176e54:	fb 02 00 f9	str	x27, [x23]
101176e58:	73 06 00 d1	sub	x19, x19, #0x1
101176e5c:	7f 02 16 eb	cmp	x19, x22
101176e60:	ec fe ff 54	b.gt	0x101176e3c
101176e64:	a9 02 40 f9	ldr	x9, [x21]
101176e68:	68 03 09 cb	sub	x8, x27, x9
101176e6c:	08 fd 43 93	asr	x8, x8, #3
101176e70:	ea f3 01 b2	mov	x10, #-0x5555555555555556
101176e74:	6a 55 95 f2	movk	x10, #0xaaab
101176e78:	18 7d 0a 9b	mul	x24, x8, x10
101176e7c:	0b 07 00 d1	sub	x11, x24, #0x1
101176e80:	0a 07 00 51	sub	w10, w24, #0x1
101176e84:	f7 03 16 aa	mov	x23, x22
101176e88:	f3 af 40 f9	ldr	x19, [sp, #0x158]
101176e8c:	f5 03 41 b9	ldr	w21, [sp, #0x100]
101176e90:	f1 d3 40 b9	ldr	w17, [sp, #0xd0]
101176e94:	02 00 00 14	b	0x101176e9c
101176e98:	f7 03 19 aa	mov	x23, x25
101176e9c:	f4 a3 40 f9	ldr	x20, [sp, #0x140]
101176ea0:	97 02 00 b9	str	w23, [x20]
101176ea4:	3f 02 00 71	cmp	w17, #0x0
101176ea8:	36 c2 9f 1a	csel	w22, w17, wzr, gt
101176eac:	7f c1 3a eb	cmp	x11, w26, sxtw
101176eb0:	4c 31 9a 1a	csel	w12, w10, w26, lo
101176eb4:	9f 01 16 6b	cmp	w12, w22
101176eb8:	4d 08 00 54	b.le	0x101176fc0
101176ebc:	95 7d 40 93	sxtw	x21, w12
101176ec0:	1a 03 80 52	mov	w26, #0x18
101176ec4:	ec 6b 00 f9	str	x12, [sp, #0xd0]
101176ec8:	80 25 3a 9b	smaddl	x0, w12, w26, x9
101176ecc:	01 60 00 91	add	x1, x0, #0x18
101176ed0:	62 03 01 cb	sub	x2, x27, x1
101176ed4:	de 6d 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
101176ed8:	68 63 00 d1	sub	x8, x27, #0x18
101176edc:	e9 9b 40 f9	ldr	x9, [sp, #0x130]
101176ee0:	28 01 00 f9	str	x8, [x9]
101176ee4:	89 02 40 b9	ldr	w9, [x20]
101176ee8:	37 05 00 51	sub	w23, w9, #0x1
101176eec:	97 02 00 b9	str	w23, [x20]
101176ef0:	b3 06 00 d1	sub	x19, x21, #0x1
101176ef4:	7f 02 16 eb	cmp	x19, x22
101176ef8:	ed 04 00 54	b.le	0x101176f94
101176efc:	f9 67 00 f9	str	x25, [sp, #0xc8]
101176f00:	a9 06 15 8b	add	x9, x21, x21, lsl #1
101176f04:	3b f1 7d d3	lsl	x27, x9, #3
101176f08:	e9 02 80 92	mov	x9, #-0x18
101176f0c:	b8 7e 09 9b	mul	x24, x21, x9
101176f10:	f5 b3 40 f9	ldr	x21, [sp, #0x160]
101176f14:	f4 9b 40 f9	ldr	x20, [sp, #0x130]
101176f18:	f9 f3 01 b2	mov	x25, #-0x5555555555555556
101176f1c:	79 55 95 f2	movk	x25, #0xaaab
101176f20:	59 55 e5 f2	movk	x25, #0x2aaa, lsl #48
101176f24:	bc 02 40 f9	ldr	x28, [x21]
101176f28:	08 01 1c cb	sub	x8, x8, x28
101176f2c:	02 03 08 8b	add	x2, x24, x8
101176f30:	48 7c 59 9b	smulh	x8, x2, x25
101176f34:	09 fd 42 93	asr	x9, x8, #2
101176f38:	3a fd 48 8b	add	x26, x9, x8, lsr #63
101176f3c:	81 03 1b 8b	add	x1, x28, x27
101176f40:	20 60 00 d1	sub	x0, x1, #0x18
101176f44:	c2 6d 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
101176f48:	08 03 80 52	mov	w8, #0x18
101176f4c:	48 6f 08 9b	madd	x8, x26, x8, x27
101176f50:	88 03 08 8b	add	x8, x28, x8
101176f54:	08 61 00 d1	sub	x8, x8, #0x18
101176f58:	88 02 00 f9	str	x8, [x20]
101176f5c:	f7 06 00 51	sub	w23, w23, #0x1
101176f60:	73 06 00 d1	sub	x19, x19, #0x1
101176f64:	7b 63 00 d1	sub	x27, x27, #0x18
101176f68:	18 63 00 91	add	x24, x24, #0x18
101176f6c:	7f 02 16 eb	cmp	x19, x22
101176f70:	ac fd ff 54	b.gt	0x101176f24
101176f74:	e8 a3 40 f9	ldr	x8, [sp, #0x140]
101176f78:	17 01 00 b9	str	w23, [x8]
101176f7c:	08 03 80 52	mov	w8, #0x18
101176f80:	48 73 08 9b	madd	x8, x26, x8, x28
101176f84:	08 01 18 cb	sub	x8, x8, x24
101176f88:	fc 97 40 f9	ldr	x28, [sp, #0x128]
101176f8c:	1a 03 80 52	mov	w26, #0x18
101176f90:	f9 67 40 f9	ldr	x25, [sp, #0xc8]
101176f94:	f3 a7 55 a9	ldp	x19, x9, [sp, #0x158]
101176f98:	29 01 40 f9	ldr	x9, [x9]
101176f9c:	08 01 09 cb	sub	x8, x8, x9
101176fa0:	08 fd 43 d3	lsr	x8, x8, #3
101176fa4:	6a 55 95 52	mov	w10, #0xaaab
101176fa8:	4a 55 b5 72	movk	w10, #0xaaaa, lsl #16
101176fac:	18 7d 0a 1b	mul	w24, w8, w10
101176fb0:	0a 07 00 51	sub	w10, w24, #0x1
101176fb4:	f5 03 41 b9	ldr	w21, [sp, #0x100]
101176fb8:	ec 6b 40 f9	ldr	x12, [sp, #0xd0]
101176fbc:	02 00 00 14	b	0x101176fc4
101176fc0:	1a 03 80 52	mov	w26, #0x18
101176fc4:	e8 93 40 f9	ldr	x8, [sp, #0x120]
101176fc8:	3f 03 08 6b	cmp	w25, w8
101176fcc:	e4 d2 4a 7a	ccmp	w23, w10, #0x4, le
101176fd0:	e8 17 9f 1a	cset	w8, eq
101176fd4:	0a 0b 00 51	sub	w10, w24, #0x2
101176fd8:	e8 02 08 4b	sub	w8, w23, w8
101176fdc:	1f 01 0a 6b	cmp	w8, w10
101176fe0:	08 b1 8a 1a	csel	w8, w8, w10, lt
101176fe4:	ea 07 40 91	add	x10, sp, #0x1, lsl #12
101176fe8:	4a c1 19 91	add	x10, x10, #0x670
101176fec:	56 79 33 b8	str	w22, [x10, x19, lsl #2]
101176ff0:	9f 01 16 6b	cmp	w12, w22
101176ff4:	ff ef 01 f9	str	xzr, [sp, #0x3d8]
101176ff8:	ff eb 01 f9	str	xzr, [sp, #0x3d0]
101176ffc:	0a 00 80 12	mov	w10, #-0x1
101177000:	ea e3 03 b9	str	w10, [sp, #0x3e0]
101177004:	ff 93 0f 39	strb	wzr, [sp, #0x3e4]
101177008:	db d6 96 1a	cinc	w27, w22, gt
10117700c:	1f 01 1b 6b	cmp	w8, w27
101177010:	0b 05 00 54	b.lt	0x1011770b0
101177014:	f4 03 0c aa	mov	x20, x12
101177018:	13 7d 40 93	sxtw	x19, w8
10117701c:	68 c6 28 8b	add	x8, x19, w8, sxtw #1
101177020:	18 f1 7d d3	lsl	x24, x8, #3
101177024:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
101177028:	21 01 18 8b	add	x1, x9, x24
10117702c:	28 8c 41 b8	ldr	w8, [x1, #0x18]!
101177030:	29 69 78 b8	ldr	w9, [x9, x24]
101177034:	08 01 09 4b	sub	w8, w8, w9
101177038:	00 01 62 1e	scvtf	d0, w8
10117703c:	21 01 62 1e	scvtf	d1, w9
101177040:	21 28 6e 1e	fadd	d1, d1, d14
101177044:	00 04 4e 1f	fmadd	d0, d0, d14, d1
101177048:	08 00 78 1e	fcvtzs	w8, d0
10117704c:	e8 d3 03 b9	str	w8, [sp, #0x3d0]
101177050:	ff ef 01 f9	str	xzr, [sp, #0x3d8]
101177054:	e2 43 0f 91	add	x2, sp, #0x3d0
101177058:	70 20 ff 97	bl	__ZNSt3__16vectorIN16BeatAnalyzer_2_06peakss8BeatInfoENS_9allocatorIS3_EEE6insertENS_11__wrap_iterIPKS3_EERS8_
10117705c:	e9 a3 40 f9	ldr	x9, [sp, #0x140]
101177060:	28 01 40 b9	ldr	w8, [x9]
101177064:	17 05 00 11	add	w23, w8, #0x1
101177068:	37 01 00 b9	str	w23, [x9]
10117706c:	7f 02 1b eb	cmp	x19, x27
101177070:	cd 00 00 54	b.le	0x101177088
101177074:	73 06 00 d1	sub	x19, x19, #0x1
101177078:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
10117707c:	09 00 40 f9	ldr	x9, [x0]
101177080:	18 63 00 d1	sub	x24, x24, #0x18
101177084:	e9 ff ff 17	b	0x101177028
101177088:	e8 9b 40 f9	ldr	x8, [sp, #0x130]
10117708c:	08 01 40 f9	ldr	x8, [x8]
101177090:	e9 b3 40 f9	ldr	x9, [sp, #0x160]
101177094:	29 01 40 f9	ldr	x9, [x9]
101177098:	08 01 09 cb	sub	x8, x8, x9
10117709c:	08 fd 43 d3	lsr	x8, x8, #3
1011770a0:	6a 55 95 52	mov	w10, #0xaaab
1011770a4:	4a 55 b5 72	movk	w10, #0xaaaa, lsl #16
1011770a8:	18 7d 0a 1b	mul	w24, w8, w10
1011770ac:	ec 03 14 aa	mov	x12, x20
1011770b0:	e8 93 40 f9	ldr	x8, [sp, #0x120]
1011770b4:	3f 03 08 6b	cmp	w25, w8
1011770b8:	fb 9f 40 f9	ldr	x27, [sp, #0x138]
1011770bc:	ad 07 00 54	b.le	0x1011771b0
1011770c0:	f4 06 00 11	add	w20, w23, #0x1
1011770c4:	9f 02 18 6b	cmp	w20, w24
1011770c8:	4a 07 00 54	b.ge	0x1011771b0
1011770cc:	ea 7e 3a 9b	smull	x10, w23, w26
1011770d0:	20 69 6a bc	ldr	s0, [x9, x10]
1011770d4:	00 a4 20 0f	sshll.2d	v0, v0, #0x0
1011770d8:	00 d8 61 5e	scvtf	d0, d0
1011770dc:	68 03 40 b9	ldr	w8, [x27]
1011770e0:	01 01 62 1e	scvtf	d1, w8
1011770e4:	0a 18 61 1e	fdiv	d10, d0, d1
1011770e8:	8b 7e 3a 9b	smull	x11, w20, w26
1011770ec:	20 69 6b bc	ldr	s0, [x9, x11]
1011770f0:	00 a4 20 0f	sshll.2d	v0, v0, #0x0
1011770f4:	00 d8 61 5e	scvtf	d0, d0
1011770f8:	00 18 61 1e	fdiv	d0, d0, d1
1011770fc:	0b 38 6a 1e	fsub	d11, d0, d10
101177100:	0b 00 c8 d2	mov	x11, #0x400000000000
101177104:	eb 11 e8 f2	movk	x11, #0x408f, lsl #48
101177108:	60 01 67 9e	fmov	d0, x11
10117710c:	60 09 60 1e	fmul	d0, d11, d0
101177110:	00 38 4c 1f	fmadd	d0, d0, d12, d14
101177114:	0b 00 78 1e	fcvtzs	w11, d0
101177118:	79 09 00 71	subs	w25, w11, #0x2
10117711c:	ab 04 00 54	b.lt	0x1011771b0
101177120:	ec 6b 00 f9	str	x12, [sp, #0xd0]
101177124:	1b 00 80 52	mov	w27, #0x0
101177128:	60 01 62 1e	scvtf	d0, w11
10117712c:	ff bf 03 b9	str	wzr, [sp, #0x3bc]
101177130:	0b 00 80 12	mov	w11, #-0x1
101177134:	eb cb 03 b9	str	w11, [sp, #0x3c8]
101177138:	ff 33 0f 39	strb	wzr, [sp, #0x3cc]
10117713c:	a8 19 60 1e	fdiv	d8, d13, d0
101177140:	53 61 00 91	add	x19, x10, #0x18
101177144:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
101177148:	6a 07 00 11	add	w10, w27, #0x1
10117714c:	40 01 62 1e	scvtf	d0, w10
101177150:	60 09 60 1e	fmul	d0, d11, d0
101177154:	00 28 48 1f	fmadd	d0, d0, d8, d10
101177158:	01 01 62 1e	scvtf	d1, w8
10117715c:	00 38 41 1f	fmadd	d0, d0, d1, d14
101177160:	08 00 78 1e	fcvtzs	w8, d0
101177164:	e8 bb 03 b9	str	w8, [sp, #0x3b8]
101177168:	ff e3 01 f9	str	xzr, [sp, #0x3c0]
10117716c:	61 02 09 8b	add	x1, x19, x9
101177170:	e2 e3 0e 91	add	x2, sp, #0x3b8
101177174:	29 20 ff 97	bl	__ZNSt3__16vectorIN16BeatAnalyzer_2_06peakss8BeatInfoENS_9allocatorIS3_EEE6insertENS_11__wrap_iterIPKS3_EERS8_
101177178:	97 02 1b 0b	add	w23, w20, w27
10117717c:	e8 a3 40 f9	ldr	x8, [sp, #0x140]
101177180:	17 01 00 b9	str	w23, [x8]
101177184:	3f 03 1b 6b	cmp	w25, w27
101177188:	00 01 00 54	b.eq	0x1011771a8
10117718c:	e8 9f 40 f9	ldr	x8, [sp, #0x138]
101177190:	08 01 40 b9	ldr	w8, [x8]
101177194:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
101177198:	09 00 40 f9	ldr	x9, [x0]
10117719c:	73 62 00 91	add	x19, x19, #0x18
1011771a0:	7b 07 00 11	add	w27, w27, #0x1
1011771a4:	e9 ff ff 17	b	0x101177148
1011771a8:	fb 9f 40 f9	ldr	x27, [sp, #0x138]
1011771ac:	ec 6b 40 f9	ldr	x12, [sp, #0xd0]
1011771b0:	9f 01 16 6b	cmp	w12, w22
1011771b4:	cd 07 00 54	b.le	0x1011772ac
1011771b8:	ca 06 00 11	add	w10, w22, #0x1
1011771bc:	5f 01 18 6b	cmp	w10, w24
1011771c0:	f9 9b 40 f9	ldr	x25, [sp, #0x130]
1011771c4:	6a 07 00 54	b.ge	0x1011772b0
1011771c8:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
1011771cc:	08 01 40 f9	ldr	x8, [x8]
1011771d0:	c9 7e ba 9b	umull	x9, w22, w26
1011771d4:	00 69 69 bc	ldr	s0, [x8, x9]
1011771d8:	00 a4 20 0f	sshll.2d	v0, v0, #0x0
1011771dc:	00 d8 61 5e	scvtf	d0, d0
1011771e0:	69 03 40 b9	ldr	w9, [x27]
1011771e4:	21 01 62 1e	scvtf	d1, w9
1011771e8:	0a 18 61 1e	fdiv	d10, d0, d1
1011771ec:	4a 7d ba 9b	umull	x10, w10, w26
1011771f0:	00 69 6a bc	ldr	s0, [x8, x10]
1011771f4:	00 a4 20 0f	sshll.2d	v0, v0, #0x0
1011771f8:	00 d8 61 5e	scvtf	d0, d0
1011771fc:	00 18 61 1e	fdiv	d0, d0, d1
101177200:	0b 38 6a 1e	fsub	d11, d0, d10
101177204:	0a 00 c8 d2	mov	x10, #0x400000000000
101177208:	ea 11 e8 f2	movk	x10, #0x408f, lsl #48
10117720c:	40 01 67 9e	fmov	d0, x10
101177210:	60 09 60 1e	fmul	d0, d11, d0
101177214:	00 38 4c 1f	fmadd	d0, d0, d12, d14
101177218:	0a 00 78 1e	fcvtzs	w10, d0
10117721c:	5f 09 00 71	cmp	w10, #0x2
101177220:	8b 04 00 54	b.lt	0x1011772b0
101177224:	40 01 62 1e	scvtf	d0, w10
101177228:	ff bf 03 b9	str	wzr, [sp, #0x3bc]
10117722c:	0b 00 80 12	mov	w11, #-0x1
101177230:	eb cb 03 b9	str	w11, [sp, #0x3c8]
101177234:	ff 33 0f 39	strb	wzr, [sp, #0x3cc]
101177238:	54 05 00 51	sub	w20, w10, #0x1
10117723c:	a8 19 60 1e	fdiv	d8, d13, d0
101177240:	f3 03 17 2a	mov	w19, w23
101177244:	ea 07 7d b2	orr	x10, xzr, #0x18
101177248:	d6 2a 1a 9b	madd	x22, x22, x26, x10
10117724c:	38 00 80 52	mov	w24, #0x1
101177250:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
101177254:	00 03 62 1e	scvtf	d0, w24
101177258:	60 09 60 1e	fmul	d0, d11, d0
10117725c:	00 28 48 1f	fmadd	d0, d0, d8, d10
101177260:	21 01 62 1e	scvtf	d1, w9
101177264:	00 38 41 1f	fmadd	d0, d0, d1, d14
101177268:	09 00 78 1e	fcvtzs	w9, d0
10117726c:	e9 bb 03 b9	str	w9, [sp, #0x3b8]
101177270:	ff e3 01 f9	str	xzr, [sp, #0x3c0]
101177274:	c1 02 08 8b	add	x1, x22, x8
101177278:	e2 e3 0e 91	add	x2, sp, #0x3b8
10117727c:	e7 1f ff 97	bl	__ZNSt3__16vectorIN16BeatAnalyzer_2_06peakss8BeatInfoENS_9allocatorIS3_EEE6insertENS_11__wrap_iterIPKS3_EERS8_
101177280:	68 02 18 0b	add	w8, w19, w24
101177284:	e9 a3 40 f9	ldr	x9, [sp, #0x140]
101177288:	28 01 00 b9	str	w8, [x9]
10117728c:	9f 02 18 eb	cmp	x20, x24
101177290:	60 14 00 54	b.eq	0x10117751c
101177294:	69 03 40 b9	ldr	w9, [x27]
101177298:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
10117729c:	08 00 40 f9	ldr	x8, [x0]
1011772a0:	18 07 00 91	add	x24, x24, #0x1
1011772a4:	d6 62 00 91	add	x22, x22, #0x18
1011772a8:	eb ff ff 17	b	0x101177254
1011772ac:	f9 9b 40 f9	ldr	x25, [sp, #0x130]
1011772b0:	f8 87 40 f9	ldr	x24, [sp, #0x108]
1011772b4:	f3 b3 40 f9	ldr	x19, [sp, #0x160]
1011772b8:	61 02 40 f9	ldr	x1, [x19]
1011772bc:	28 18 40 b9	ldr	w8, [x1, #0x18]
1011772c0:	29 00 40 b9	ldr	w9, [x1]
1011772c4:	08 01 09 4b	sub	w8, w8, w9
1011772c8:	28 01 08 6b	subs	w8, w9, w8
1011772cc:	f6 07 40 91	add	x22, sp, #0x1, lsl #12
1011772d0:	d6 c2 19 91	add	x22, x22, #0x670
1011772d4:	4d 01 00 54	b.le	0x1011772fc
1011772d8:	e8 d3 03 b9	str	w8, [sp, #0x3d0]
1011772dc:	ff ef 01 f9	str	xzr, [sp, #0x3d8]
1011772e0:	e2 43 0f 91	add	x2, sp, #0x3d0
1011772e4:	e0 03 13 aa	mov	x0, x19
1011772e8:	cc 1f ff 97	bl	__ZNSt3__16vectorIN16BeatAnalyzer_2_06peakss8BeatInfoENS_9allocatorIS3_EEE6insertENS_11__wrap_iterIPKS3_EERS8_
1011772ec:	e8 06 00 11	add	w8, w23, #0x1
1011772f0:	e9 a3 40 f9	ldr	x9, [sp, #0x140]
1011772f4:	28 01 00 b9	str	w8, [x9]
1011772f8:	61 02 40 f9	ldr	x1, [x19]
1011772fc:	e9 f3 01 b2	mov	x9, #-0x5555555555555556
101177300:	69 55 95 f2	movk	x9, #0xaaab
101177304:	28 03 40 f9	ldr	x8, [x25]
101177308:	08 01 01 cb	sub	x8, x8, x1
10117730c:	08 fd 43 93	asr	x8, x8, #3
101177310:	13 7d 09 9b	mul	x19, x8, x9
101177314:	7f 0a 00 71	cmp	w19, #0x2
101177318:	f7 07 40 91	add	x23, sp, #0x1, lsl #12
10117731c:	f7 c2 11 91	add	x23, x23, #0x470
101177320:	ab 06 00 54	b.lt	0x1011773f4
101177324:	68 06 00 51	sub	w8, w19, #0x1
101177328:	09 7d ba 9b	umull	x9, w8, w26
10117732c:	2a 68 69 b8	ldr	w10, [x1, x9]
101177330:	69 7e 60 d3	lsl	x9, x19, #32
101177334:	eb 7b 5f b2	mov	x11, #-0x200000000
101177338:	2b 01 0b 8b	add	x11, x9, x11
10117733c:	6b fd 60 93	asr	x11, x11, #32
101177340:	6b 7d 1a 9b	mul	x11, x11, x26
101177344:	2b 68 6b b8	ldr	w11, [x1, x11]
101177348:	54 01 0b 6b	subs	w20, w10, w11
10117734c:	40 05 00 54	b.eq	0x1011773f4
101177350:	8b 1f 40 b9	ldr	w11, [x28, #0x1c]
101177354:	6a 01 0a 4b	sub	w10, w11, w10
101177358:	40 01 62 1e	scvtf	d0, w10
10117735c:	81 02 62 1e	scvtf	d1, w20
101177360:	00 18 61 1e	fdiv	d0, d0, d1
101177364:	00 20 6d 1e	fcmp	d0, d13
101177368:	6d 04 00 54	b.le	0x1011773f4
10117736c:	0a 00 78 1e	fcvtzs	w10, d0
101177370:	ff e3 01 f9	str	xzr, [sp, #0x3c0]
101177374:	ff df 01 f9	str	xzr, [sp, #0x3b8]
101177378:	0b 00 80 12	mov	w11, #-0x1
10117737c:	eb cb 03 b9	str	w11, [sp, #0x3c8]
101177380:	ff 33 0f 39	strb	wzr, [sp, #0x3cc]
101177384:	5f 05 00 71	cmp	w10, #0x1
101177388:	cb 02 00 54	b.lt	0x1011773e0
10117738c:	29 fd 60 93	asr	x9, x9, #32
101177390:	08 05 08 8b	add	x8, x8, x8, lsl #1
101177394:	16 f1 7d d3	lsl	x22, x8, #3
101177398:	28 05 09 8b	add	x8, x9, x9, lsl #1
10117739c:	17 f1 7d d3	lsl	x23, x8, #3
1011773a0:	58 05 00 d1	sub	x24, x10, #0x1
1011773a4:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
1011773a8:	28 68 76 b8	ldr	w8, [x1, x22]
1011773ac:	08 01 14 0b	add	w8, w8, w20
1011773b0:	e8 bb 03 b9	str	w8, [sp, #0x3b8]
1011773b4:	ff e3 01 f9	str	xzr, [sp, #0x3c0]
1011773b8:	e1 02 01 8b	add	x1, x23, x1
1011773bc:	e2 e3 0e 91	add	x2, sp, #0x3b8
1011773c0:	96 1f ff 97	bl	__ZNSt3__16vectorIN16BeatAnalyzer_2_06peakss8BeatInfoENS_9allocatorIS3_EEE6insertENS_11__wrap_iterIPKS3_EERS8_
1011773c4:	f8 00 00 b4	cbz	x24, 0x1011773e0
1011773c8:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
1011773cc:	01 00 40 f9	ldr	x1, [x0]
1011773d0:	d6 62 00 91	add	x22, x22, #0x18
1011773d4:	f7 62 00 91	add	x23, x23, #0x18
1011773d8:	18 07 00 d1	sub	x24, x24, #0x1
1011773dc:	f3 ff ff 17	b	0x1011773a8
1011773e0:	f7 07 40 91	add	x23, sp, #0x1, lsl #12
1011773e4:	f7 c2 11 91	add	x23, x23, #0x470
1011773e8:	f6 07 40 91	add	x22, sp, #0x1, lsl #12
1011773ec:	d6 c2 19 91	add	x22, x22, #0x670
1011773f0:	f8 87 40 f9	ldr	x24, [sp, #0x108]
1011773f4:	f5 74 00 34	cbz	w21, 0x101178290
1011773f8:	29 03 40 f9	ldr	x9, [x25]
1011773fc:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
101177400:	08 01 40 f9	ldr	x8, [x8]
101177404:	29 01 08 cb	sub	x9, x9, x8
101177408:	29 fd 43 d3	lsr	x9, x9, #3
10117740c:	6a 55 95 52	mov	w10, #0xaaab
101177410:	4a 55 b5 72	movk	w10, #0xaaaa, lsl #16
101177414:	33 7d 0a 1b	mul	w19, w9, w10
101177418:	69 0a 00 51	sub	w9, w19, #0x2
10117741c:	3f 05 00 71	cmp	w9, #0x1
101177420:	2a c5 9f 1a	csinc	w10, w9, wzr, gt
101177424:	0f 06 80 52	mov	w15, #0x30
101177428:	2b 00 80 52	mov	w11, #0x1
10117742c:	7f 01 0a eb	cmp	x11, x10
101177430:	00 73 00 54	b.eq	0x101178290
101177434:	e9 03 0b aa	mov	x9, x11
101177438:	f4 03 0f aa	mov	x20, x15
10117743c:	6b 21 1a 9b	madd	x11, x11, x26, x8
101177440:	70 01 40 b9	ldr	w16, [x11]
101177444:	6d 81 5e b8	ldur	w13, [x11, #-0x18]
101177448:	2b 05 00 91	add	x11, x9, #0x1
10117744c:	6c 7d 40 92	and	x12, x11, #0xffffffff
101177450:	8c 7d 1a 9b	mul	x12, x12, x26
101177454:	0c 69 6c b8	ldr	w12, [x8, x12]
101177458:	0f 02 0d 4b	sub	w15, w16, w13
10117745c:	2d 09 00 11	add	w13, w9, #0x2
101177460:	ad 7d ba 9b	umull	x13, w13, w26
101177464:	0e 69 6d b8	ldr	w14, [x8, x13]
101177468:	cd 01 0c 4b	sub	w13, w14, w12
10117746c:	f1 09 0f 0b	add	w17, w15, w15, lsl #2
101177470:	a0 09 0d 0b	add	w0, w13, w13, lsl #2
101177474:	8f 62 00 91	add	x15, x20, #0x18
101177478:	90 01 10 4b	sub	w16, w12, w16
10117747c:	1f 02 11 6b	cmp	w16, w17
101177480:	00 d2 40 7a	ccmp	w16, w0, #0x0, le
101177484:	4d fd ff 54	b.le	0x10117742c
101177488:	df 01 0c 6b	cmp	w14, w12
10117748c:	20 70 00 54	b.eq	0x101178290
101177490:	00 02 62 1e	scvtf	d0, w16
101177494:	a1 01 62 1e	scvtf	d1, w13
101177498:	01 18 61 1e	fdiv	d1, d0, d1
10117749c:	20 20 6d 1e	fcmp	d1, d13
1011774a0:	8d 6f 00 54	b.le	0x101178290
1011774a4:	2a 00 78 1e	fcvtzs	w10, d1
1011774a8:	ff e3 01 f9	str	xzr, [sp, #0x3c0]
1011774ac:	ff df 01 f9	str	xzr, [sp, #0x3b8]
1011774b0:	0b 00 80 12	mov	w11, #-0x1
1011774b4:	eb cb 03 b9	str	w11, [sp, #0x3c8]
1011774b8:	ff 33 0f 39	strb	wzr, [sp, #0x3cc]
1011774bc:	5f 09 00 71	cmp	w10, #0x2
1011774c0:	cb 6d 00 54	b.lt	0x101178278
1011774c4:	21 c0 65 1e	frintz	d1, d1
1011774c8:	00 18 61 1e	fdiv	d0, d0, d1
1011774cc:	16 00 78 1e	fcvtzs	w22, d0
1011774d0:	37 7d 40 92	and	x23, x9, #0xffffffff
1011774d4:	58 09 00 d1	sub	x24, x10, #0x2
1011774d8:	f9 03 16 aa	mov	x25, x22
1011774dc:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
1011774e0:	e9 7e 1a 9b	mul	x9, x23, x26
1011774e4:	09 69 69 b8	ldr	w9, [x8, x9]
1011774e8:	29 03 09 0b	add	w9, w25, w9
1011774ec:	e9 bb 03 b9	str	w9, [sp, #0x3b8]
1011774f0:	ff e3 01 f9	str	xzr, [sp, #0x3c0]
1011774f4:	81 02 08 8b	add	x1, x20, x8
1011774f8:	e2 e3 0e 91	add	x2, sp, #0x3b8
1011774fc:	47 1f ff 97	bl	__ZNSt3__16vectorIN16BeatAnalyzer_2_06peakss8BeatInfoENS_9allocatorIS3_EEE6insertENS_11__wrap_iterIPKS3_EERS8_
101177500:	d8 6b 00 b4	cbz	x24, 0x101178278
101177504:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
101177508:	08 00 40 f9	ldr	x8, [x0]
10117750c:	39 03 16 0b	add	w25, w25, w22
101177510:	94 62 00 91	add	x20, x20, #0x18
101177514:	18 07 00 d1	sub	x24, x24, #0x1
101177518:	f2 ff ff 17	b	0x1011774e0
10117751c:	f7 02 18 0b	add	w23, w23, w24
101177520:	64 ff ff 17	b	0x1011772b0
101177524:	0a 12 00 51	sub	w10, w16, #0x4
101177528:	5f 03 0a 6b	cmp	w26, w10
10117752c:	ec 01 00 54	b.gt	0x101177568
101177530:	4b 0f 00 91	add	x11, x26, #0x3
101177534:	80 7a 6b fc	ldr	d0, [x20, x11, lsl #3]
101177538:	c1 01 67 9e	fmov	d1, x14
10117753c:	00 20 61 1e	fcmp	d0, d1
101177540:	ea a3 90 d2	mov	x10, #0x851f
101177544:	6a 3d aa f2	movk	x10, #0x51eb, lsl #16
101177548:	0a d7 c3 f2	movk	x10, #0x1eb8, lsl #32
10117754c:	2a fe e7 f2	movk	x10, #0x3ff1, lsl #48
101177550:	41 01 67 9e	fmov	d1, x10
101177554:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
101177558:	ec 0d 00 54	b.gt	0x101177714
10117755c:	e1 01 67 9e	fmov	d1, x15
101177560:	00 20 61 1e	fcmp	d0, d1
101177564:	8c 0d 00 54	b.gt	0x101177714
101177568:	fa 83 40 f9	ldr	x26, [sp, #0x100]
10117756c:	94 fd ff 17	b	0x101176bbc
101177570:	09 12 00 51	sub	w9, w16, #0x4
101177574:	1f 01 09 6b	cmp	w8, w9
101177578:	ec 01 00 54	b.gt	0x1011775b4
10117757c:	0c 0d 00 11	add	w12, w8, #0x3
101177580:	80 da 6c fc	ldr	d0, [x20, w12, sxtw #3]
101177584:	c1 01 67 9e	fmov	d1, x14
101177588:	00 20 61 1e	fcmp	d0, d1
10117758c:	e9 a3 90 d2	mov	x9, #0x851f
101177590:	69 3d aa f2	movk	x9, #0x51eb, lsl #16
101177594:	09 d7 c3 f2	movk	x9, #0x1eb8, lsl #32
101177598:	29 fe e7 f2	movk	x9, #0x3ff1, lsl #48
10117759c:	21 01 67 9e	fmov	d1, x9
1011775a0:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
1011775a4:	ec 0d 00 54	b.gt	0x101177760
1011775a8:	e1 01 67 9e	fmov	d1, x15
1011775ac:	00 20 61 1e	fcmp	d0, d1
1011775b0:	8c 0d 00 54	b.gt	0x101177760
1011775b4:	e8 03 0b aa	mov	x8, x11
1011775b8:	00 fe ff 17	b	0x101176db8
1011775bc:	4a 17 00 91	add	x10, x26, #0x5
1011775c0:	eb 8b 40 f9	ldr	x11, [sp, #0x110]
1011775c4:	60 79 6a fc	ldr	d0, [x11, x10, lsl #3]
1011775c8:	eb a3 90 d2	mov	x11, #0x851f
1011775cc:	6b 3d aa f2	movk	x11, #0x51eb, lsl #16
1011775d0:	0b d7 c3 f2	movk	x11, #0x1eb8, lsl #32
1011775d4:	2b fe e7 f2	movk	x11, #0x3ff1, lsl #48
1011775d8:	61 01 67 9e	fmov	d1, x11
1011775dc:	00 20 61 1e	fcmp	d0, d1
1011775e0:	18 03 80 52	mov	w24, #0x18
1011775e4:	e0 a3 40 f9	ldr	x0, [sp, #0x140]
1011775e8:	cd 00 00 54	b.le	0x101177600
1011775ec:	eb e7 02 b2	mov	x11, #-0x3333333333333334
1011775f0:	cb fe e7 f2	movk	x11, #0x3ff6, lsl #48
1011775f4:	61 01 67 9e	fmov	d1, x11
1011775f8:	00 20 61 1e	fcmp	d0, d1
1011775fc:	4b 01 00 54	b.lt	0x101177624
101177600:	eb e7 00 b2	mov	x11, #0x3333333333333333
101177604:	8b 66 86 f2	movk	x11, #0x3334
101177608:	2b ff e7 f2	movk	x11, #0x3ff9, lsl #48
10117760c:	61 01 67 9e	fmov	d1, x11
101177610:	00 20 61 1e	fcmp	d0, d1
101177614:	ed 99 fe 54	b.le	0x101174950
101177618:	c1 01 67 9e	fmov	d1, x14
10117761c:	00 20 61 1e	fcmp	d0, d1
101177620:	8a 99 fe 54	b.ge	0x101174950
101177624:	31 00 80 52	mov	w17, #0x1
101177628:	f0 03 0a aa	mov	x16, x10
10117762c:	c9 f4 ff 17	b	0x101174950
101177630:	08 15 00 11	add	w8, w8, #0x5
101177634:	eb 8b 40 f9	ldr	x11, [sp, #0x110]
101177638:	60 d9 68 fc	ldr	d0, [x11, w8, sxtw #3]
10117763c:	eb a3 90 d2	mov	x11, #0x851f
101177640:	6b 3d aa f2	movk	x11, #0x51eb, lsl #16
101177644:	0b d7 c3 f2	movk	x11, #0x1eb8, lsl #32
101177648:	2b fe e7 f2	movk	x11, #0x3ff1, lsl #48
10117764c:	61 01 67 9e	fmov	d1, x11
101177650:	00 20 61 1e	fcmp	d0, d1
101177654:	cd 00 00 54	b.le	0x10117766c
101177658:	eb e7 02 b2	mov	x11, #-0x3333333333333334
10117765c:	cb fe e7 f2	movk	x11, #0x3ff6, lsl #48
101177660:	61 01 67 9e	fmov	d1, x11
101177664:	00 20 61 1e	fcmp	d0, d1
101177668:	4b 01 00 54	b.lt	0x101177690
10117766c:	eb e7 00 b2	mov	x11, #0x3333333333333333
101177670:	8b 66 86 f2	movk	x11, #0x3334
101177674:	2b ff e7 f2	movk	x11, #0x3ff9, lsl #48
101177678:	61 01 67 9e	fmov	d1, x11
10117767c:	00 20 61 1e	fcmp	d0, d1
101177680:	8d b6 fe 54	b.le	0x101174d50
101177684:	c1 01 67 9e	fmov	d1, x14
101177688:	00 20 61 1e	fcmp	d0, d1
10117768c:	2a b6 fe 54	b.ge	0x101174d50
101177690:	31 00 80 52	mov	w17, #0x1
101177694:	3d f5 ff 17	b	0x101174b88
101177698:	f3 03 08 aa	mov	x19, x8
10117769c:	63 e0 ff 17	b	0x10116f828
1011776a0:	0a 1a 00 51	sub	w10, w16, #0x6
1011776a4:	7f 01 0a 6b	cmp	w11, w10
1011776a8:	ec 19 fe 54	b.gt	0x1011739e4
1011776ac:	6a 15 00 11	add	w10, w11, #0x5
1011776b0:	80 da 6a fc	ldr	d0, [x20, w10, sxtw #3]
1011776b4:	eb a3 90 d2	mov	x11, #0x851f
1011776b8:	6b 3d aa f2	movk	x11, #0x51eb, lsl #16
1011776bc:	0b d7 c3 f2	movk	x11, #0x1eb8, lsl #32
1011776c0:	2b fe e7 f2	movk	x11, #0x3ff1, lsl #48
1011776c4:	61 01 67 9e	fmov	d1, x11
1011776c8:	00 20 61 1e	fcmp	d0, d1
1011776cc:	eb d7 9f 1a	cset	w11, gt
1011776d0:	c1 01 67 9e	fmov	d1, x14
1011776d4:	00 20 61 1e	fcmp	d0, d1
1011776d8:	ec a7 9f 1a	cset	w12, lt
1011776dc:	6b 01 0c 0a	and	w11, w11, w12
1011776e0:	e1 01 67 9e	fmov	d1, x15
1011776e4:	00 20 61 1e	fcmp	d0, d1
1011776e8:	ec d7 9f 1a	cset	w12, gt
1011776ec:	6c 01 0c 2a	orr	w12, w11, w12
1011776f0:	9f 01 00 71	cmp	w12, #0x0
1011776f4:	4b 11 88 1a	csel	w11, w10, w8, ne
1011776f8:	80 01 00 2a	orr	w0, w12, w0
1011776fc:	bb f0 ff 17	b	0x1011739e8
101177700:	0a 1a 00 51	sub	w10, w16, #0x6
101177704:	1f 03 0a 6b	cmp	w24, w10
101177708:	6d 6c 00 54	b.le	0x101178494
10117770c:	f8 03 09 aa	mov	x24, x9
101177710:	35 f0 ff 17	b	0x1011737e4
101177714:	0a 16 00 51	sub	w10, w16, #0x5
101177718:	5f 03 0a 6b	cmp	w26, w10
10117771c:	ec 01 00 54	b.gt	0x101177758
101177720:	4a 13 00 91	add	x10, x26, #0x4
101177724:	80 7a 6a fc	ldr	d0, [x20, x10, lsl #3]
101177728:	c1 01 67 9e	fmov	d1, x14
10117772c:	00 20 61 1e	fcmp	d0, d1
101177730:	ec a3 90 d2	mov	x12, #0x851f
101177734:	6c 3d aa f2	movk	x12, #0x51eb, lsl #16
101177738:	0c d7 c3 f2	movk	x12, #0x1eb8, lsl #32
10117773c:	2c fe e7 f2	movk	x12, #0x3ff1, lsl #48
101177740:	81 01 67 9e	fmov	d1, x12
101177744:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
101177748:	0c 6d 00 54	b.gt	0x1011784e8
10117774c:	e1 01 67 9e	fmov	d1, x15
101177750:	00 20 61 1e	fcmp	d0, d1
101177754:	ac 6c 00 54	b.gt	0x1011784e8
101177758:	fa 03 0b aa	mov	x26, x11
10117775c:	18 fd ff 17	b	0x101176bbc
101177760:	09 16 00 51	sub	w9, w16, #0x5
101177764:	1f 01 09 6b	cmp	w8, w9
101177768:	ec 01 00 54	b.gt	0x1011777a4
10117776c:	09 11 00 11	add	w9, w8, #0x4
101177770:	80 da 69 fc	ldr	d0, [x20, w9, sxtw #3]
101177774:	c1 01 67 9e	fmov	d1, x14
101177778:	00 20 61 1e	fcmp	d0, d1
10117777c:	eb a3 90 d2	mov	x11, #0x851f
101177780:	6b 3d aa f2	movk	x11, #0x51eb, lsl #16
101177784:	0b d7 c3 f2	movk	x11, #0x1eb8, lsl #32
101177788:	2b fe e7 f2	movk	x11, #0x3ff1, lsl #48
10117778c:	61 01 67 9e	fmov	d1, x11
101177790:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
101177794:	4c 6b 00 54	b.gt	0x1011784fc
101177798:	e1 01 67 9e	fmov	d1, x15
10117779c:	00 20 61 1e	fcmp	d0, d1
1011777a0:	ec 6a 00 54	b.gt	0x1011784fc
1011777a4:	e8 03 0c aa	mov	x8, x12
1011777a8:	84 fd ff 17	b	0x101176db8
1011777ac:	28 13 00 71	subs	w8, w25, #0x4
1011777b0:	63 04 00 54	b.lo	0x10117783c
1011777b4:	80 5a 68 fc	ldr	d0, [x20, w8, uxtw #3]
1011777b8:	e1 01 67 9e	fmov	d1, x15
1011777bc:	00 20 61 1e	fcmp	d0, d1
1011777c0:	e9 a3 90 d2	mov	x9, #0x851f
1011777c4:	69 3d aa f2	movk	x9, #0x51eb, lsl #16
1011777c8:	09 d7 c3 f2	movk	x9, #0x1eb8, lsl #32
1011777cc:	29 fe e7 f2	movk	x9, #0x3ff1, lsl #48
1011777d0:	21 01 67 9e	fmov	d1, x9
1011777d4:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
1011777d8:	8c 00 00 54	b.gt	0x1011777e8
1011777dc:	01 02 67 9e	fmov	d1, x16
1011777e0:	00 20 61 1e	fcmp	d0, d1
1011777e4:	ed 02 00 54	b.le	0x101177840
1011777e8:	29 17 00 71	subs	w9, w25, #0x5
1011777ec:	83 02 00 54	b.lo	0x10117783c
1011777f0:	80 5a 69 fc	ldr	d0, [x20, w9, uxtw #3]
1011777f4:	ea a3 90 d2	mov	x10, #0x851f
1011777f8:	6a 3d aa f2	movk	x10, #0x51eb, lsl #16
1011777fc:	0a d7 c3 f2	movk	x10, #0x1eb8, lsl #32
101177800:	2a fe e7 f2	movk	x10, #0x3ff1, lsl #48
101177804:	41 01 67 9e	fmov	d1, x10
101177808:	00 20 61 1e	fcmp	d0, d1
10117780c:	ea d7 9f 1a	cset	w10, gt
101177810:	e1 01 67 9e	fmov	d1, x15
101177814:	00 20 61 1e	fcmp	d0, d1
101177818:	eb a7 9f 1a	cset	w11, lt
10117781c:	4a 01 0b 0a	and	w10, w10, w11
101177820:	01 02 67 9e	fmov	d1, x16
101177824:	00 20 61 1e	fcmp	d0, d1
101177828:	eb d7 9f 1a	cset	w11, gt
10117782c:	5a 01 0b 2a	orr	w26, w10, w11
101177830:	5f 03 00 71	cmp	w26, #0x0
101177834:	31 11 88 1a	csel	w17, w9, w8, ne
101177838:	03 00 00 14	b	0x101177844
10117783c:	11 00 80 52	mov	w17, #0x0
101177840:	1a 00 80 52	mov	w26, #0x0
101177844:	e8 08 00 51	sub	w8, w7, #0x2
101177848:	3f 03 08 6b	cmp	w25, w8
10117784c:	ec 03 00 54	b.gt	0x1011778c8
101177850:	80 5a 65 fc	ldr	d0, [x20, w5, uxtw #3]
101177854:	e1 01 67 9e	fmov	d1, x15
101177858:	00 20 61 1e	fcmp	d0, d1
10117785c:	e9 a3 90 d2	mov	x9, #0x851f
101177860:	69 3d aa f2	movk	x9, #0x51eb, lsl #16
101177864:	09 d7 c3 f2	movk	x9, #0x1eb8, lsl #32
101177868:	29 fe e7 f2	movk	x9, #0x3ff1, lsl #48
10117786c:	21 01 67 9e	fmov	d1, x9
101177870:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
101177874:	8c 00 00 54	b.gt	0x101177884
101177878:	01 02 67 9e	fmov	d1, x16
10117787c:	00 20 61 1e	fcmp	d0, d1
101177880:	4d 02 00 54	b.le	0x1011778c8
101177884:	e9 0c 00 51	sub	w9, w7, #0x3
101177888:	3f 03 09 6b	cmp	w25, w9
10117788c:	cc 01 00 54	b.gt	0x1011778c4
101177890:	80 5a 66 fc	ldr	d0, [x20, w6, uxtw #3]
101177894:	e1 01 67 9e	fmov	d1, x15
101177898:	00 20 61 1e	fcmp	d0, d1
10117789c:	e9 a3 90 d2	mov	x9, #0x851f
1011778a0:	69 3d aa f2	movk	x9, #0x51eb, lsl #16
1011778a4:	09 d7 c3 f2	movk	x9, #0x1eb8, lsl #32
1011778a8:	29 fe e7 f2	movk	x9, #0x3ff1, lsl #48
1011778ac:	21 01 67 9e	fmov	d1, x9
1011778b0:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
1011778b4:	6c 4f 00 54	b.gt	0x1011782a0
1011778b8:	01 02 67 9e	fmov	d1, x16
1011778bc:	00 20 61 1e	fcmp	d0, d1
1011778c0:	0c 4f 00 54	b.gt	0x1011782a0
1011778c4:	f9 03 05 aa	mov	x25, x5
1011778c8:	aa 05 00 71	subs	w10, w13, #0x1
1011778cc:	eb 01 00 54	b.lt	0x101177908
1011778d0:	80 5a 6a fc	ldr	d0, [x20, w10, uxtw #3]
1011778d4:	e9 a3 90 d2	mov	x9, #0x851f
1011778d8:	69 3d aa f2	movk	x9, #0x51eb, lsl #16
1011778dc:	09 d7 c3 f2	movk	x9, #0x1eb8, lsl #32
1011778e0:	29 fe e7 f2	movk	x9, #0x3ff1, lsl #48
1011778e4:	21 01 67 9e	fmov	d1, x9
1011778e8:	00 20 61 1e	fcmp	d0, d1
1011778ec:	2d 01 00 54	b.le	0x101177910
1011778f0:	e1 01 67 9e	fmov	d1, x15
1011778f4:	00 20 61 1e	fcmp	d0, d1
1011778f8:	ca 00 00 54	b.ge	0x101177910
1011778fc:	bf 09 00 71	cmp	w13, #0x2
101177900:	4a 01 00 54	b.ge	0x101177928
101177904:	4d 00 00 14	b	0x101177a38
101177908:	e9 03 0d aa	mov	x9, x13
10117790c:	4c 00 00 14	b	0x101177a3c
101177910:	01 02 67 9e	fmov	d1, x16
101177914:	00 20 61 1e	fcmp	d0, d1
101177918:	a9 d1 9f 1a	csel	w9, w13, wzr, le
10117791c:	0d 09 00 54	b.le	0x101177a3c
101177920:	bf 09 00 71	cmp	w13, #0x2
101177924:	cb 08 00 54	b.lt	0x101177a3c
101177928:	a9 09 00 51	sub	w9, w13, #0x2
10117792c:	80 5a 69 fc	ldr	d0, [x20, w9, uxtw #3]
101177930:	e1 01 67 9e	fmov	d1, x15
101177934:	00 20 61 1e	fcmp	d0, d1
101177938:	eb a3 90 d2	mov	x11, #0x851f
10117793c:	6b 3d aa f2	movk	x11, #0x51eb, lsl #16
101177940:	0b d7 c3 f2	movk	x11, #0x1eb8, lsl #32
101177944:	2b fe e7 f2	movk	x11, #0x3ff1, lsl #48
101177948:	61 01 67 9e	fmov	d1, x11
10117794c:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
101177950:	cc 00 00 54	b.gt	0x101177968
101177954:	01 02 67 9e	fmov	d1, x16
101177958:	00 20 61 1e	fcmp	d0, d1
10117795c:	6c 00 00 54	b.gt	0x101177968
101177960:	e9 03 0a aa	mov	x9, x10
101177964:	36 00 00 14	b	0x101177a3c
101177968:	aa 0d 00 71	subs	w10, w13, #0x3
10117796c:	63 06 00 54	b.lo	0x101177a38
101177970:	80 5a 6a fc	ldr	d0, [x20, w10, uxtw #3]
101177974:	e1 01 67 9e	fmov	d1, x15
101177978:	00 20 61 1e	fcmp	d0, d1
10117797c:	eb a3 90 d2	mov	x11, #0x851f
101177980:	6b 3d aa f2	movk	x11, #0x51eb, lsl #16
101177984:	0b d7 c3 f2	movk	x11, #0x1eb8, lsl #32
101177988:	2b fe e7 f2	movk	x11, #0x3ff1, lsl #48
10117798c:	61 01 67 9e	fmov	d1, x11
101177990:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
101177994:	8c 00 00 54	b.gt	0x1011779a4
101177998:	01 02 67 9e	fmov	d1, x16
10117799c:	00 20 61 1e	fcmp	d0, d1
1011779a0:	ed 04 00 54	b.le	0x101177a3c
1011779a4:	a9 11 00 71	subs	w9, w13, #0x4
1011779a8:	83 04 00 54	b.lo	0x101177a38
1011779ac:	80 5a 69 fc	ldr	d0, [x20, w9, uxtw #3]
1011779b0:	e1 01 67 9e	fmov	d1, x15
1011779b4:	00 20 61 1e	fcmp	d0, d1
1011779b8:	eb a3 90 d2	mov	x11, #0x851f
1011779bc:	6b 3d aa f2	movk	x11, #0x51eb, lsl #16
1011779c0:	0b d7 c3 f2	movk	x11, #0x1eb8, lsl #32
1011779c4:	2b fe e7 f2	movk	x11, #0x3ff1, lsl #48
1011779c8:	61 01 67 9e	fmov	d1, x11
1011779cc:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
1011779d0:	8c 00 00 54	b.gt	0x1011779e0
1011779d4:	01 02 67 9e	fmov	d1, x16
1011779d8:	00 20 61 1e	fcmp	d0, d1
1011779dc:	2d fc ff 54	b.le	0x101177960
1011779e0:	aa 15 00 71	subs	w10, w13, #0x5
1011779e4:	a3 02 00 54	b.lo	0x101177a38
1011779e8:	80 5a 6a fc	ldr	d0, [x20, w10, uxtw #3]
1011779ec:	eb a3 90 d2	mov	x11, #0x851f
1011779f0:	6b 3d aa f2	movk	x11, #0x51eb, lsl #16
1011779f4:	0b d7 c3 f2	movk	x11, #0x1eb8, lsl #32
1011779f8:	2b fe e7 f2	movk	x11, #0x3ff1, lsl #48
1011779fc:	61 01 67 9e	fmov	d1, x11
101177a00:	00 20 61 1e	fcmp	d0, d1
101177a04:	eb d7 9f 1a	cset	w11, gt
101177a08:	e1 01 67 9e	fmov	d1, x15
101177a0c:	00 20 61 1e	fcmp	d0, d1
101177a10:	ec a7 9f 1a	cset	w12, lt
101177a14:	6b 01 0c 0a	and	w11, w11, w12
101177a18:	01 02 67 9e	fmov	d1, x16
101177a1c:	00 20 61 1e	fcmp	d0, d1
101177a20:	ec d7 9f 1a	cset	w12, gt
101177a24:	6b 01 0c 2a	orr	w11, w11, w12
101177a28:	7f 01 00 71	cmp	w11, #0x0
101177a2c:	49 11 89 1a	csel	w9, w10, w9, ne
101177a30:	7a 01 1a 2a	orr	w26, w11, w26
101177a34:	02 00 00 14	b	0x101177a3c
101177a38:	09 00 80 52	mov	w9, #0x0
101177a3c:	bf 01 08 6b	cmp	w13, w8
101177a40:	ea f3 01 b2	mov	x10, #-0x5555555555555556
101177a44:	6a 55 95 f2	movk	x10, #0xaaab
101177a48:	ec 01 00 54	b.gt	0x101177a84
101177a4c:	a8 05 00 11	add	w8, w13, #0x1
101177a50:	80 da 68 fc	ldr	d0, [x20, w8, sxtw #3]
101177a54:	e1 01 67 9e	fmov	d1, x15
101177a58:	00 20 61 1e	fcmp	d0, d1
101177a5c:	eb a3 90 d2	mov	x11, #0x851f
101177a60:	6b 3d aa f2	movk	x11, #0x51eb, lsl #16
101177a64:	0b d7 c3 f2	movk	x11, #0x1eb8, lsl #32
101177a68:	2b fe e7 f2	movk	x11, #0x3ff1, lsl #48
101177a6c:	61 01 67 9e	fmov	d1, x11
101177a70:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
101177a74:	cc 00 00 54	b.gt	0x101177a8c
101177a78:	01 02 67 9e	fmov	d1, x16
101177a7c:	00 20 61 1e	fcmp	d0, d1
101177a80:	6c 00 00 54	b.gt	0x101177a8c
101177a84:	0e 03 80 52	mov	w14, #0x18
101177a88:	16 00 00 14	b	0x101177ae0
101177a8c:	ea 0c 00 51	sub	w10, w7, #0x3
101177a90:	0e 03 80 52	mov	w14, #0x18
101177a94:	bf 01 0a 6b	cmp	w13, w10
101177a98:	ec 01 00 54	b.gt	0x101177ad4
101177a9c:	aa 09 00 11	add	w10, w13, #0x2
101177aa0:	80 da 6a fc	ldr	d0, [x20, w10, sxtw #3]
101177aa4:	e1 01 67 9e	fmov	d1, x15
101177aa8:	00 20 61 1e	fcmp	d0, d1
101177aac:	eb a3 90 d2	mov	x11, #0x851f
101177ab0:	6b 3d aa f2	movk	x11, #0x51eb, lsl #16
101177ab4:	0b d7 c3 f2	movk	x11, #0x1eb8, lsl #32
101177ab8:	2b fe e7 f2	movk	x11, #0x3ff1, lsl #48
101177abc:	61 01 67 9e	fmov	d1, x11
101177ac0:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
101177ac4:	4c 41 00 54	b.gt	0x1011782ec
101177ac8:	01 02 67 9e	fmov	d1, x16
101177acc:	00 20 61 1e	fcmp	d0, d1
101177ad0:	ec 40 00 54	b.gt	0x1011782ec
101177ad4:	ed 03 08 aa	mov	x13, x8
101177ad8:	ea f3 01 b2	mov	x10, #-0x5555555555555556
101177adc:	6a 55 95 f2	movk	x10, #0xaaab
101177ae0:	3f 01 00 71	cmp	w9, #0x0
101177ae4:	33 c1 9f 1a	csel	w19, w9, wzr, gt
101177ae8:	f6 9b 40 f9	ldr	x22, [sp, #0x130]
101177aec:	db 02 40 f9	ldr	x27, [x22]
101177af0:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
101177af4:	08 01 40 f9	ldr	x8, [x8]
101177af8:	69 03 08 cb	sub	x9, x27, x8
101177afc:	29 fd 43 93	asr	x9, x9, #3
101177b00:	38 7d 0a 9b	mul	x24, x9, x10
101177b04:	0a 07 00 d1	sub	x10, x24, #0x1
101177b08:	09 07 00 51	sub	w9, w24, #0x1
101177b0c:	5f c1 2d eb	cmp	x10, w13, sxtw
101177b10:	2d 31 8d 1a	csel	w13, w9, w13, lo
101177b14:	bf 01 13 6b	cmp	w13, w19
101177b18:	ed 83 00 f9	str	x13, [sp, #0x100]
101177b1c:	f3 a3 00 f9	str	x19, [sp, #0x140]
101177b20:	ed 04 00 54	b.le	0x101177bbc
101177b24:	fa d3 00 b9	str	w26, [sp, #0xd0]
101177b28:	fa 03 11 aa	mov	x26, x17
101177b2c:	b5 7d 40 93	sxtw	x21, w13
101177b30:	14 03 80 52	mov	w20, #0x18
101177b34:	a0 21 34 9b	smaddl	x0, w13, w20, x8
101177b38:	01 60 00 91	add	x1, x0, #0x18
101177b3c:	62 03 01 cb	sub	x2, x27, x1
101177b40:	c3 6a 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
101177b44:	7b 63 00 d1	sub	x27, x27, #0x18
101177b48:	db 02 00 f9	str	x27, [x22]
101177b4c:	b5 06 00 d1	sub	x21, x21, #0x1
101177b50:	bf 02 13 eb	cmp	x21, x19
101177b54:	f7 b3 40 f9	ldr	x23, [sp, #0x160]
101177b58:	6d 01 00 54	b.le	0x101177b84
101177b5c:	e8 02 40 f9	ldr	x8, [x23]
101177b60:	a0 22 14 9b	madd	x0, x21, x20, x8
101177b64:	01 60 00 91	add	x1, x0, #0x18
101177b68:	62 03 01 cb	sub	x2, x27, x1
101177b6c:	b8 6a 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
101177b70:	7b 63 00 d1	sub	x27, x27, #0x18
101177b74:	db 02 00 f9	str	x27, [x22]
101177b78:	b5 06 00 d1	sub	x21, x21, #0x1
101177b7c:	bf 02 13 eb	cmp	x21, x19
101177b80:	ec fe ff 54	b.gt	0x101177b5c
101177b84:	0e 03 80 52	mov	w14, #0x18
101177b88:	e8 02 40 f9	ldr	x8, [x23]
101177b8c:	69 03 08 cb	sub	x9, x27, x8
101177b90:	29 fd 43 93	asr	x9, x9, #3
101177b94:	ea f3 01 b2	mov	x10, #-0x5555555555555556
101177b98:	6a 55 95 f2	movk	x10, #0xaaab
101177b9c:	38 7d 0a 9b	mul	x24, x9, x10
101177ba0:	0a 07 00 d1	sub	x10, x24, #0x1
101177ba4:	09 07 00 51	sub	w9, w24, #0x1
101177ba8:	f7 03 13 aa	mov	x23, x19
101177bac:	f1 03 1a aa	mov	x17, x26
101177bb0:	fa d3 40 b9	ldr	w26, [sp, #0xd0]
101177bb4:	ed 83 40 f9	ldr	x13, [sp, #0x100]
101177bb8:	02 00 00 14	b	0x101177bc0
101177bbc:	f7 03 0d aa	mov	x23, x13
101177bc0:	f3 43 11 91	add	x19, sp, #0x450
101177bc4:	eb af 40 f9	ldr	x11, [sp, #0x158]
101177bc8:	77 7a 2b b8	str	w23, [x19, x11, lsl #2]
101177bcc:	3f 02 00 71	cmp	w17, #0x0
101177bd0:	36 c2 9f 1a	csel	w22, w17, wzr, gt
101177bd4:	5f c1 39 eb	cmp	x10, w25, sxtw
101177bd8:	2c 31 99 1a	csel	w12, w9, w25, lo
101177bdc:	9f 01 16 6b	cmp	w12, w22
101177be0:	6d 08 00 54	b.le	0x101177cec
101177be4:	95 7d 40 93	sxtw	x21, w12
101177be8:	ec 67 00 f9	str	x12, [sp, #0xc8]
101177bec:	80 21 2e 9b	smaddl	x0, w12, w14, x8
101177bf0:	01 60 00 91	add	x1, x0, #0x18
101177bf4:	62 03 01 cb	sub	x2, x27, x1
101177bf8:	95 6a 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
101177bfc:	69 63 00 d1	sub	x9, x27, #0x18
101177c00:	ea 93 40 f9	ldr	x10, [sp, #0x120]
101177c04:	68 6a 6a b8	ldr	w8, [x19, x10]
101177c08:	f9 9b 40 f9	ldr	x25, [sp, #0x130]
101177c0c:	29 03 00 f9	str	x9, [x25]
101177c10:	17 05 00 51	sub	w23, w8, #0x1
101177c14:	77 6a 2a b8	str	w23, [x19, x10]
101177c18:	b4 06 00 d1	sub	x20, x21, #0x1
101177c1c:	9f 02 16 eb	cmp	x20, x22
101177c20:	0d 05 00 54	b.le	0x101177cc0
101177c24:	fa d3 00 b9	str	w26, [sp, #0xd0]
101177c28:	a8 06 15 8b	add	x8, x21, x21, lsl #1
101177c2c:	1b f1 7d d3	lsl	x27, x8, #3
101177c30:	e8 02 80 92	mov	x8, #-0x18
101177c34:	b8 7e 08 9b	mul	x24, x21, x8
101177c38:	f5 b3 40 f9	ldr	x21, [sp, #0x160]
101177c3c:	f3 03 19 aa	mov	x19, x25
101177c40:	fa f3 01 b2	mov	x26, #-0x5555555555555556
101177c44:	7a 55 95 f2	movk	x26, #0xaaab
101177c48:	5a 55 e5 f2	movk	x26, #0x2aaa, lsl #48
101177c4c:	bc 02 40 f9	ldr	x28, [x21]
101177c50:	28 01 1c cb	sub	x8, x9, x28
101177c54:	02 03 08 8b	add	x2, x24, x8
101177c58:	48 7c 5a 9b	smulh	x8, x2, x26
101177c5c:	09 fd 42 93	asr	x9, x8, #2
101177c60:	39 fd 48 8b	add	x25, x9, x8, lsr #63
101177c64:	81 03 1b 8b	add	x1, x28, x27
101177c68:	20 60 00 d1	sub	x0, x1, #0x18
101177c6c:	78 6a 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
101177c70:	08 03 80 52	mov	w8, #0x18
101177c74:	28 6f 08 9b	madd	x8, x25, x8, x27
101177c78:	88 03 08 8b	add	x8, x28, x8
101177c7c:	09 61 00 d1	sub	x9, x8, #0x18
101177c80:	69 02 00 f9	str	x9, [x19]
101177c84:	f7 06 00 51	sub	w23, w23, #0x1
101177c88:	94 06 00 d1	sub	x20, x20, #0x1
101177c8c:	7b 63 00 d1	sub	x27, x27, #0x18
101177c90:	18 63 00 91	add	x24, x24, #0x18
101177c94:	9f 02 16 eb	cmp	x20, x22
101177c98:	ac fd ff 54	b.gt	0x101177c4c
101177c9c:	e8 43 11 91	add	x8, sp, #0x450
101177ca0:	e9 af 40 f9	ldr	x9, [sp, #0x158]
101177ca4:	17 79 29 b8	str	w23, [x8, x9, lsl #2]
101177ca8:	08 03 80 52	mov	w8, #0x18
101177cac:	28 73 08 9b	madd	x8, x25, x8, x28
101177cb0:	09 01 18 cb	sub	x9, x8, x24
101177cb4:	fc 97 40 f9	ldr	x28, [sp, #0x128]
101177cb8:	f9 03 13 aa	mov	x25, x19
101177cbc:	fa d3 40 b9	ldr	w26, [sp, #0xd0]
101177cc0:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
101177cc4:	08 01 40 f9	ldr	x8, [x8]
101177cc8:	29 01 08 cb	sub	x9, x9, x8
101177ccc:	29 fd 43 d3	lsr	x9, x9, #3
101177cd0:	6a 55 95 52	mov	w10, #0xaaab
101177cd4:	4a 55 b5 72	movk	w10, #0xaaaa, lsl #16
101177cd8:	38 7d 0a 1b	mul	w24, w9, w10
101177cdc:	09 07 00 51	sub	w9, w24, #0x1
101177ce0:	ec 67 40 f9	ldr	x12, [sp, #0xc8]
101177ce4:	ed 83 40 f9	ldr	x13, [sp, #0x100]
101177ce8:	02 00 00 14	b	0x101177cf0
101177cec:	f9 9b 40 f9	ldr	x25, [sp, #0x130]
101177cf0:	ea a3 40 f9	ldr	x10, [sp, #0x140]
101177cf4:	bf 01 0a 6b	cmp	w13, w10
101177cf8:	e4 d2 49 7a	ccmp	w23, w9, #0x4, le
101177cfc:	e9 17 9f 1a	cset	w9, eq
101177d00:	0a 0b 00 51	sub	w10, w24, #0x2
101177d04:	e9 02 09 4b	sub	w9, w23, w9
101177d08:	3f 01 0a 6b	cmp	w9, w10
101177d0c:	29 b1 8a 1a	csel	w9, w9, w10, lt
101177d10:	ea 43 19 91	add	x10, sp, #0x650
101177d14:	f3 af 40 f9	ldr	x19, [sp, #0x158]
101177d18:	56 79 33 b8	str	w22, [x10, x19, lsl #2]
101177d1c:	9f 01 16 6b	cmp	w12, w22
101177d20:	ff ef 01 f9	str	xzr, [sp, #0x3d8]
101177d24:	ff eb 01 f9	str	xzr, [sp, #0x3d0]
101177d28:	0a 00 80 12	mov	w10, #-0x1
101177d2c:	ea e3 03 b9	str	w10, [sp, #0x3e0]
101177d30:	ff 93 0f 39	strb	wzr, [sp, #0x3e4]
101177d34:	d4 d6 96 1a	cinc	w20, w22, gt
101177d38:	3f 01 14 6b	cmp	w9, w20
101177d3c:	6a 00 00 54	b.ge	0x101177d48
101177d40:	fb 9f 40 f9	ldr	x27, [sp, #0x138]
101177d44:	29 00 00 14	b	0x101177de8
101177d48:	f5 03 0c aa	mov	x21, x12
101177d4c:	38 7d 40 93	sxtw	x24, w9
101177d50:	f7 06 00 11	add	w23, w23, #0x1
101177d54:	09 c7 29 8b	add	x9, x24, w9, sxtw #1
101177d58:	3b f1 7d d3	lsl	x27, x9, #3
101177d5c:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
101177d60:	01 01 1b 8b	add	x1, x8, x27
101177d64:	29 8c 41 b8	ldr	w9, [x1, #0x18]!
101177d68:	08 69 7b b8	ldr	w8, [x8, x27]
101177d6c:	29 01 08 4b	sub	w9, w9, w8
101177d70:	20 01 62 1e	scvtf	d0, w9
101177d74:	01 01 62 1e	scvtf	d1, w8
101177d78:	21 28 6e 1e	fadd	d1, d1, d14
101177d7c:	00 04 4e 1f	fmadd	d0, d0, d14, d1
101177d80:	08 00 78 1e	fcvtzs	w8, d0
101177d84:	e8 d3 03 b9	str	w8, [sp, #0x3d0]
101177d88:	ff ef 01 f9	str	xzr, [sp, #0x3d8]
101177d8c:	e2 43 0f 91	add	x2, sp, #0x3d0
101177d90:	22 1d ff 97	bl	__ZNSt3__16vectorIN16BeatAnalyzer_2_06peakss8BeatInfoENS_9allocatorIS3_EEE6insertENS_11__wrap_iterIPKS3_EERS8_
101177d94:	e8 43 11 91	add	x8, sp, #0x450
101177d98:	17 79 33 b8	str	w23, [x8, x19, lsl #2]
101177d9c:	1f 03 14 eb	cmp	x24, x20
101177da0:	ed 00 00 54	b.le	0x101177dbc
101177da4:	18 07 00 d1	sub	x24, x24, #0x1
101177da8:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
101177dac:	08 00 40 f9	ldr	x8, [x0]
101177db0:	f7 06 00 11	add	w23, w23, #0x1
101177db4:	7b 63 00 d1	sub	x27, x27, #0x18
101177db8:	ea ff ff 17	b	0x101177d60
101177dbc:	29 03 40 f9	ldr	x9, [x25]
101177dc0:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
101177dc4:	08 01 40 f9	ldr	x8, [x8]
101177dc8:	29 01 08 cb	sub	x9, x9, x8
101177dcc:	29 fd 43 d3	lsr	x9, x9, #3
101177dd0:	6a 55 95 52	mov	w10, #0xaaab
101177dd4:	4a 55 b5 72	movk	w10, #0xaaaa, lsl #16
101177dd8:	38 7d 0a 1b	mul	w24, w9, w10
101177ddc:	fb 9f 40 f9	ldr	x27, [sp, #0x138]
101177de0:	ec 03 15 aa	mov	x12, x21
101177de4:	ed 83 40 f9	ldr	x13, [sp, #0x100]
101177de8:	e9 a3 40 f9	ldr	x9, [sp, #0x140]
101177dec:	bf 01 09 6b	cmp	w13, w9
101177df0:	cd 07 00 54	b.le	0x101177ee8
101177df4:	f3 06 00 11	add	w19, w23, #0x1
101177df8:	7f 02 18 6b	cmp	w19, w24
101177dfc:	15 03 80 52	mov	w21, #0x18
101177e00:	6a 07 00 54	b.ge	0x101177eec
101177e04:	ea 7e 35 9b	smull	x10, w23, w21
101177e08:	00 69 6a bc	ldr	s0, [x8, x10]
101177e0c:	00 a4 20 0f	sshll.2d	v0, v0, #0x0
101177e10:	00 d8 61 5e	scvtf	d0, d0
101177e14:	69 03 40 b9	ldr	w9, [x27]
101177e18:	21 01 62 1e	scvtf	d1, w9
101177e1c:	0a 18 61 1e	fdiv	d10, d0, d1
101177e20:	6b 7e 35 9b	smull	x11, w19, w21
101177e24:	00 69 6b bc	ldr	s0, [x8, x11]
101177e28:	00 a4 20 0f	sshll.2d	v0, v0, #0x0
101177e2c:	00 d8 61 5e	scvtf	d0, d0
101177e30:	00 18 61 1e	fdiv	d0, d0, d1
101177e34:	0b 38 6a 1e	fsub	d11, d0, d10
101177e38:	0b 00 c8 d2	mov	x11, #0x400000000000
101177e3c:	eb 11 e8 f2	movk	x11, #0x408f, lsl #48
101177e40:	60 01 67 9e	fmov	d0, x11
101177e44:	60 09 60 1e	fmul	d0, d11, d0
101177e48:	00 38 4c 1f	fmadd	d0, d0, d12, d14
101177e4c:	0b 00 78 1e	fcvtzs	w11, d0
101177e50:	74 09 00 71	subs	w20, w11, #0x2
101177e54:	cb 04 00 54	b.lt	0x101177eec
101177e58:	ec 67 00 f9	str	x12, [sp, #0xc8]
101177e5c:	fa d3 00 b9	str	w26, [sp, #0xd0]
101177e60:	1a 00 80 52	mov	w26, #0x0
101177e64:	60 01 62 1e	scvtf	d0, w11
101177e68:	ff bf 03 b9	str	wzr, [sp, #0x3bc]
101177e6c:	0b 00 80 12	mov	w11, #-0x1
101177e70:	eb cb 03 b9	str	w11, [sp, #0x3c8]
101177e74:	ff 33 0f 39	strb	wzr, [sp, #0x3cc]
101177e78:	a8 19 60 1e	fdiv	d8, d13, d0
101177e7c:	5b 61 00 91	add	x27, x10, #0x18
101177e80:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
101177e84:	4a 07 00 11	add	w10, w26, #0x1
101177e88:	40 01 62 1e	scvtf	d0, w10
101177e8c:	60 09 60 1e	fmul	d0, d11, d0
101177e90:	00 28 48 1f	fmadd	d0, d0, d8, d10
101177e94:	21 01 62 1e	scvtf	d1, w9
101177e98:	00 38 41 1f	fmadd	d0, d0, d1, d14
101177e9c:	09 00 78 1e	fcvtzs	w9, d0
101177ea0:	e9 bb 03 b9	str	w9, [sp, #0x3b8]
101177ea4:	ff e3 01 f9	str	xzr, [sp, #0x3c0]
101177ea8:	61 03 08 8b	add	x1, x27, x8
101177eac:	e2 e3 0e 91	add	x2, sp, #0x3b8
101177eb0:	da 1c ff 97	bl	__ZNSt3__16vectorIN16BeatAnalyzer_2_06peakss8BeatInfoENS_9allocatorIS3_EEE6insertENS_11__wrap_iterIPKS3_EERS8_
101177eb4:	77 02 1a 0b	add	w23, w19, w26
101177eb8:	e8 43 11 91	add	x8, sp, #0x450
101177ebc:	e9 af 40 f9	ldr	x9, [sp, #0x158]
101177ec0:	17 79 29 b8	str	w23, [x8, x9, lsl #2]
101177ec4:	9f 02 1a 6b	cmp	w20, w26
101177ec8:	00 09 00 54	b.eq	0x101177fe8
101177ecc:	e8 9f 40 f9	ldr	x8, [sp, #0x138]
101177ed0:	09 01 40 b9	ldr	w9, [x8]
101177ed4:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
101177ed8:	08 00 40 f9	ldr	x8, [x0]
101177edc:	7b 63 00 91	add	x27, x27, #0x18
101177ee0:	5a 07 00 11	add	w26, w26, #0x1
101177ee4:	e8 ff ff 17	b	0x101177e84
101177ee8:	15 03 80 52	mov	w21, #0x18
101177eec:	9f 01 16 6b	cmp	w12, w22
101177ef0:	cd 08 00 54	b.le	0x101178008
101177ef4:	ca 06 00 11	add	w10, w22, #0x1
101177ef8:	5f 01 18 6b	cmp	w10, w24
101177efc:	6a 08 00 54	b.ge	0x101178008
101177f00:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
101177f04:	08 01 40 f9	ldr	x8, [x8]
101177f08:	c9 7e b5 9b	umull	x9, w22, w21
101177f0c:	00 69 69 bc	ldr	s0, [x8, x9]
101177f10:	00 a4 20 0f	sshll.2d	v0, v0, #0x0
101177f14:	00 d8 61 5e	scvtf	d0, d0
101177f18:	69 03 40 b9	ldr	w9, [x27]
101177f1c:	21 01 62 1e	scvtf	d1, w9
101177f20:	0a 18 61 1e	fdiv	d10, d0, d1
101177f24:	4a 7d b5 9b	umull	x10, w10, w21
101177f28:	00 69 6a bc	ldr	s0, [x8, x10]
101177f2c:	00 a4 20 0f	sshll.2d	v0, v0, #0x0
101177f30:	00 d8 61 5e	scvtf	d0, d0
101177f34:	00 18 61 1e	fdiv	d0, d0, d1
101177f38:	0b 38 6a 1e	fsub	d11, d0, d10
101177f3c:	0a 00 c8 d2	mov	x10, #0x400000000000
101177f40:	ea 11 e8 f2	movk	x10, #0x408f, lsl #48
101177f44:	40 01 67 9e	fmov	d0, x10
101177f48:	60 09 60 1e	fmul	d0, d11, d0
101177f4c:	00 38 4c 1f	fmadd	d0, d0, d12, d14
101177f50:	0a 00 78 1e	fcvtzs	w10, d0
101177f54:	5f 09 00 71	cmp	w10, #0x2
101177f58:	8b 05 00 54	b.lt	0x101178008
101177f5c:	40 01 62 1e	scvtf	d0, w10
101177f60:	ff bf 03 b9	str	wzr, [sp, #0x3bc]
101177f64:	0b 00 80 12	mov	w11, #-0x1
101177f68:	eb cb 03 b9	str	w11, [sp, #0x3c8]
101177f6c:	ff 33 0f 39	strb	wzr, [sp, #0x3cc]
101177f70:	53 05 00 51	sub	w19, w10, #0x1
101177f74:	a8 19 60 1e	fdiv	d8, d13, d0
101177f78:	f4 03 17 2a	mov	w20, w23
101177f7c:	ea 07 7d b2	orr	x10, xzr, #0x18
101177f80:	d6 2a 15 9b	madd	x22, x22, x21, x10
101177f84:	38 00 80 52	mov	w24, #0x1
101177f88:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
101177f8c:	00 03 62 1e	scvtf	d0, w24
101177f90:	60 09 60 1e	fmul	d0, d11, d0
101177f94:	00 28 48 1f	fmadd	d0, d0, d8, d10
101177f98:	21 01 62 1e	scvtf	d1, w9
101177f9c:	00 38 41 1f	fmadd	d0, d0, d1, d14
101177fa0:	09 00 78 1e	fcvtzs	w9, d0
101177fa4:	e9 bb 03 b9	str	w9, [sp, #0x3b8]
101177fa8:	ff e3 01 f9	str	xzr, [sp, #0x3c0]
101177fac:	c1 02 08 8b	add	x1, x22, x8
101177fb0:	e2 e3 0e 91	add	x2, sp, #0x3b8
101177fb4:	99 1c ff 97	bl	__ZNSt3__16vectorIN16BeatAnalyzer_2_06peakss8BeatInfoENS_9allocatorIS3_EEE6insertENS_11__wrap_iterIPKS3_EERS8_
101177fb8:	88 02 18 0b	add	w8, w20, w24
101177fbc:	e9 43 11 91	add	x9, sp, #0x450
101177fc0:	ea af 40 f9	ldr	x10, [sp, #0x158]
101177fc4:	28 79 2a b8	str	w8, [x9, x10, lsl #2]
101177fc8:	7f 02 18 eb	cmp	x19, x24
101177fcc:	c0 01 00 54	b.eq	0x101178004
101177fd0:	69 03 40 b9	ldr	w9, [x27]
101177fd4:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
101177fd8:	08 00 40 f9	ldr	x8, [x0]
101177fdc:	18 07 00 91	add	x24, x24, #0x1
101177fe0:	d6 62 00 91	add	x22, x22, #0x18
101177fe4:	ea ff ff 17	b	0x101177f8c
101177fe8:	fb 9f 40 f9	ldr	x27, [sp, #0x138]
101177fec:	15 03 80 52	mov	w21, #0x18
101177ff0:	fa d3 40 b9	ldr	w26, [sp, #0xd0]
101177ff4:	ec 67 40 f9	ldr	x12, [sp, #0xc8]
101177ff8:	9f 01 16 6b	cmp	w12, w22
101177ffc:	cc f7 ff 54	b.gt	0x101177ef4
101178000:	02 00 00 14	b	0x101178008
101178004:	f7 02 18 0b	add	w23, w23, w24
101178008:	f8 87 40 f9	ldr	x24, [sp, #0x108]
10117800c:	f3 b3 40 f9	ldr	x19, [sp, #0x160]
101178010:	61 02 40 f9	ldr	x1, [x19]
101178014:	28 18 40 b9	ldr	w8, [x1, #0x18]
101178018:	29 00 40 b9	ldr	w9, [x1]
10117801c:	08 01 09 4b	sub	w8, w8, w9
101178020:	28 01 08 6b	subs	w8, w9, w8
101178024:	f6 07 40 91	add	x22, sp, #0x1, lsl #12
101178028:	d6 c2 19 91	add	x22, x22, #0x670
10117802c:	6d 01 00 54	b.le	0x101178058
101178030:	e8 d3 03 b9	str	w8, [sp, #0x3d0]
101178034:	ff ef 01 f9	str	xzr, [sp, #0x3d8]
101178038:	e2 43 0f 91	add	x2, sp, #0x3d0
10117803c:	e0 03 13 aa	mov	x0, x19
101178040:	76 1c ff 97	bl	__ZNSt3__16vectorIN16BeatAnalyzer_2_06peakss8BeatInfoENS_9allocatorIS3_EEE6insertENS_11__wrap_iterIPKS3_EERS8_
101178044:	e8 06 00 11	add	w8, w23, #0x1
101178048:	e9 43 11 91	add	x9, sp, #0x450
10117804c:	ea af 40 f9	ldr	x10, [sp, #0x158]
101178050:	28 79 2a b8	str	w8, [x9, x10, lsl #2]
101178054:	61 02 40 f9	ldr	x1, [x19]
101178058:	e9 f3 01 b2	mov	x9, #-0x5555555555555556
10117805c:	69 55 95 f2	movk	x9, #0xaaab
101178060:	28 03 40 f9	ldr	x8, [x25]
101178064:	08 01 01 cb	sub	x8, x8, x1
101178068:	08 fd 43 93	asr	x8, x8, #3
10117806c:	13 7d 09 9b	mul	x19, x8, x9
101178070:	7f 0a 00 71	cmp	w19, #0x2
101178074:	f7 07 40 91	add	x23, sp, #0x1, lsl #12
101178078:	f7 c2 11 91	add	x23, x23, #0x470
10117807c:	ab 06 00 54	b.lt	0x101178150
101178080:	68 06 00 51	sub	w8, w19, #0x1
101178084:	09 7d b5 9b	umull	x9, w8, w21
101178088:	2a 68 69 b8	ldr	w10, [x1, x9]
10117808c:	69 7e 60 d3	lsl	x9, x19, #32
101178090:	eb 7b 5f b2	mov	x11, #-0x200000000
101178094:	2b 01 0b 8b	add	x11, x9, x11
101178098:	6b fd 60 93	asr	x11, x11, #32
10117809c:	6b 7d 15 9b	mul	x11, x11, x21
1011780a0:	2b 68 6b b8	ldr	w11, [x1, x11]
1011780a4:	54 01 0b 6b	subs	w20, w10, w11
1011780a8:	40 05 00 54	b.eq	0x101178150
1011780ac:	8b 1f 40 b9	ldr	w11, [x28, #0x1c]
1011780b0:	6a 01 0a 4b	sub	w10, w11, w10
1011780b4:	40 01 62 1e	scvtf	d0, w10
1011780b8:	81 02 62 1e	scvtf	d1, w20
1011780bc:	00 18 61 1e	fdiv	d0, d0, d1
1011780c0:	00 20 6d 1e	fcmp	d0, d13
1011780c4:	6d 04 00 54	b.le	0x101178150
1011780c8:	0a 00 78 1e	fcvtzs	w10, d0
1011780cc:	ff e3 01 f9	str	xzr, [sp, #0x3c0]
1011780d0:	ff df 01 f9	str	xzr, [sp, #0x3b8]
1011780d4:	0b 00 80 12	mov	w11, #-0x1
1011780d8:	eb cb 03 b9	str	w11, [sp, #0x3c8]
1011780dc:	ff 33 0f 39	strb	wzr, [sp, #0x3cc]
1011780e0:	5f 05 00 71	cmp	w10, #0x1
1011780e4:	cb 02 00 54	b.lt	0x10117813c
1011780e8:	29 fd 60 93	asr	x9, x9, #32
1011780ec:	08 05 08 8b	add	x8, x8, x8, lsl #1
1011780f0:	16 f1 7d d3	lsl	x22, x8, #3
1011780f4:	28 05 09 8b	add	x8, x9, x9, lsl #1
1011780f8:	17 f1 7d d3	lsl	x23, x8, #3
1011780fc:	58 05 00 d1	sub	x24, x10, #0x1
101178100:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
101178104:	28 68 76 b8	ldr	w8, [x1, x22]
101178108:	08 01 14 0b	add	w8, w8, w20
10117810c:	e8 bb 03 b9	str	w8, [sp, #0x3b8]
101178110:	ff e3 01 f9	str	xzr, [sp, #0x3c0]
101178114:	e1 02 01 8b	add	x1, x23, x1
101178118:	e2 e3 0e 91	add	x2, sp, #0x3b8
10117811c:	3f 1c ff 97	bl	__ZNSt3__16vectorIN16BeatAnalyzer_2_06peakss8BeatInfoENS_9allocatorIS3_EEE6insertENS_11__wrap_iterIPKS3_EERS8_
101178120:	f8 00 00 b4	cbz	x24, 0x10117813c
101178124:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
101178128:	01 00 40 f9	ldr	x1, [x0]
10117812c:	d6 62 00 91	add	x22, x22, #0x18
101178130:	f7 62 00 91	add	x23, x23, #0x18
101178134:	18 07 00 d1	sub	x24, x24, #0x1
101178138:	f3 ff ff 17	b	0x101178104
10117813c:	f7 07 40 91	add	x23, sp, #0x1, lsl #12
101178140:	f7 c2 11 91	add	x23, x23, #0x470
101178144:	f6 07 40 91	add	x22, sp, #0x1, lsl #12
101178148:	d6 c2 19 91	add	x22, x22, #0x670
10117814c:	f8 87 40 f9	ldr	x24, [sp, #0x108]
101178150:	1a 0a 00 34	cbz	w26, 0x101178290
101178154:	29 03 40 f9	ldr	x9, [x25]
101178158:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
10117815c:	08 01 40 f9	ldr	x8, [x8]
101178160:	29 01 08 cb	sub	x9, x9, x8
101178164:	29 fd 43 d3	lsr	x9, x9, #3
101178168:	6a 55 95 52	mov	w10, #0xaaab
10117816c:	4a 55 b5 72	movk	w10, #0xaaaa, lsl #16
101178170:	33 7d 0a 1b	mul	w19, w9, w10
101178174:	69 0a 00 51	sub	w9, w19, #0x2
101178178:	3f 05 00 71	cmp	w9, #0x1
10117817c:	2a c5 9f 1a	csinc	w10, w9, wzr, gt
101178180:	0f 06 80 52	mov	w15, #0x30
101178184:	2b 00 80 52	mov	w11, #0x1
101178188:	7f 01 0a eb	cmp	x11, x10
10117818c:	20 08 00 54	b.eq	0x101178290
101178190:	e9 03 0b aa	mov	x9, x11
101178194:	f4 03 0f aa	mov	x20, x15
101178198:	6b 21 15 9b	madd	x11, x11, x21, x8
10117819c:	70 01 40 b9	ldr	w16, [x11]
1011781a0:	6d 81 5e b8	ldur	w13, [x11, #-0x18]
1011781a4:	2b 05 00 91	add	x11, x9, #0x1
1011781a8:	6c 7d 40 92	and	x12, x11, #0xffffffff
1011781ac:	8c 7d 15 9b	mul	x12, x12, x21
1011781b0:	0c 69 6c b8	ldr	w12, [x8, x12]
1011781b4:	0f 02 0d 4b	sub	w15, w16, w13
1011781b8:	2d 09 00 11	add	w13, w9, #0x2
1011781bc:	ad 7d b5 9b	umull	x13, w13, w21
1011781c0:	0e 69 6d b8	ldr	w14, [x8, x13]
1011781c4:	cd 01 0c 4b	sub	w13, w14, w12
1011781c8:	f1 09 0f 0b	add	w17, w15, w15, lsl #2
1011781cc:	a0 09 0d 0b	add	w0, w13, w13, lsl #2
1011781d0:	8f 62 00 91	add	x15, x20, #0x18
1011781d4:	90 01 10 4b	sub	w16, w12, w16
1011781d8:	1f 02 11 6b	cmp	w16, w17
1011781dc:	00 d2 40 7a	ccmp	w16, w0, #0x0, le
1011781e0:	4d fd ff 54	b.le	0x101178188
1011781e4:	df 01 0c 6b	cmp	w14, w12
1011781e8:	40 05 00 54	b.eq	0x101178290
1011781ec:	00 02 62 1e	scvtf	d0, w16
1011781f0:	a1 01 62 1e	scvtf	d1, w13
1011781f4:	01 18 61 1e	fdiv	d1, d0, d1
1011781f8:	20 20 6d 1e	fcmp	d1, d13
1011781fc:	ad 04 00 54	b.le	0x101178290
101178200:	2a 00 78 1e	fcvtzs	w10, d1
101178204:	ff e3 01 f9	str	xzr, [sp, #0x3c0]
101178208:	ff df 01 f9	str	xzr, [sp, #0x3b8]
10117820c:	0b 00 80 12	mov	w11, #-0x1
101178210:	eb cb 03 b9	str	w11, [sp, #0x3c8]
101178214:	ff 33 0f 39	strb	wzr, [sp, #0x3cc]
101178218:	5f 09 00 71	cmp	w10, #0x2
10117821c:	eb 02 00 54	b.lt	0x101178278
101178220:	21 c0 65 1e	frintz	d1, d1
101178224:	00 18 61 1e	fdiv	d0, d0, d1
101178228:	16 00 78 1e	fcvtzs	w22, d0
10117822c:	37 7d 40 92	and	x23, x9, #0xffffffff
101178230:	58 09 00 d1	sub	x24, x10, #0x2
101178234:	f9 03 16 aa	mov	x25, x22
101178238:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
10117823c:	e9 7e 15 9b	mul	x9, x23, x21
101178240:	09 69 69 b8	ldr	w9, [x8, x9]
101178244:	29 03 09 0b	add	w9, w25, w9
101178248:	e9 bb 03 b9	str	w9, [sp, #0x3b8]
10117824c:	ff e3 01 f9	str	xzr, [sp, #0x3c0]
101178250:	81 02 08 8b	add	x1, x20, x8
101178254:	e2 e3 0e 91	add	x2, sp, #0x3b8
101178258:	f0 1b ff 97	bl	__ZNSt3__16vectorIN16BeatAnalyzer_2_06peakss8BeatInfoENS_9allocatorIS3_EEE6insertENS_11__wrap_iterIPKS3_EERS8_
10117825c:	f8 00 00 b4	cbz	x24, 0x101178278
101178260:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
101178264:	08 00 40 f9	ldr	x8, [x0]
101178268:	39 03 16 0b	add	w25, w25, w22
10117826c:	94 62 00 91	add	x20, x20, #0x18
101178270:	18 07 00 d1	sub	x24, x24, #0x1
101178274:	f2 ff ff 17	b	0x10117823c
101178278:	f9 9b 40 f9	ldr	x25, [sp, #0x130]
10117827c:	f7 07 40 91	add	x23, sp, #0x1, lsl #12
101178280:	f7 c2 11 91	add	x23, x23, #0x470
101178284:	f6 07 40 91	add	x22, sp, #0x1, lsl #12
101178288:	d6 c2 19 91	add	x22, x22, #0x670
10117828c:	f8 87 40 f9	ldr	x24, [sp, #0x108]
101178290:	e7 03 13 aa	mov	x7, x19
101178294:	f4 8b 40 f9	ldr	x20, [sp, #0x110]
101178298:	f3 af 40 f9	ldr	x19, [sp, #0x158]
10117829c:	bb d5 ff 17	b	0x10116d988
1011782a0:	e9 10 00 51	sub	w9, w7, #0x4
1011782a4:	3f 03 09 6b	cmp	w25, w9
1011782a8:	ec 01 00 54	b.gt	0x1011782e4
1011782ac:	2a 0f 00 91	add	x10, x25, #0x3
1011782b0:	80 7a 6a fc	ldr	d0, [x20, x10, lsl #3]
1011782b4:	e1 01 67 9e	fmov	d1, x15
1011782b8:	00 20 61 1e	fcmp	d0, d1
1011782bc:	e9 a3 90 d2	mov	x9, #0x851f
1011782c0:	69 3d aa f2	movk	x9, #0x51eb, lsl #16
1011782c4:	09 d7 c3 f2	movk	x9, #0x1eb8, lsl #32
1011782c8:	29 fe e7 f2	movk	x9, #0x3ff1, lsl #48
1011782cc:	21 01 67 9e	fmov	d1, x9
1011782d0:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
1011782d4:	ac 06 00 54	b.gt	0x1011783a8
1011782d8:	01 02 67 9e	fmov	d1, x16
1011782dc:	00 20 61 1e	fcmp	d0, d1
1011782e0:	4c 06 00 54	b.gt	0x1011783a8
1011782e4:	f9 03 06 aa	mov	x25, x6
1011782e8:	78 fd ff 17	b	0x1011778c8
1011782ec:	e8 10 00 51	sub	w8, w7, #0x4
1011782f0:	bf 01 08 6b	cmp	w13, w8
1011782f4:	ec 01 00 54	b.gt	0x101178330
1011782f8:	ab 0d 00 11	add	w11, w13, #0x3
1011782fc:	80 da 6b fc	ldr	d0, [x20, w11, sxtw #3]
101178300:	e1 01 67 9e	fmov	d1, x15
101178304:	00 20 61 1e	fcmp	d0, d1
101178308:	e8 a3 90 d2	mov	x8, #0x851f
10117830c:	68 3d aa f2	movk	x8, #0x51eb, lsl #16
101178310:	08 d7 c3 f2	movk	x8, #0x1eb8, lsl #32
101178314:	28 fe e7 f2	movk	x8, #0x3ff1, lsl #48
101178318:	01 01 67 9e	fmov	d1, x8
10117831c:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
101178320:	ac 06 00 54	b.gt	0x1011783f4
101178324:	01 02 67 9e	fmov	d1, x16
101178328:	00 20 61 1e	fcmp	d0, d1
10117832c:	4c 06 00 54	b.gt	0x1011783f4
101178330:	ed 03 0a aa	mov	x13, x10
101178334:	e9 fd ff 17	b	0x101177ad8
101178338:	88 15 00 11	add	w8, w12, #0x5
10117833c:	80 da 68 fc	ldr	d0, [x20, w8, sxtw #3]
101178340:	eb a3 90 d2	mov	x11, #0x851f
101178344:	6b 3d aa f2	movk	x11, #0x51eb, lsl #16
101178348:	0b d7 c3 f2	movk	x11, #0x1eb8, lsl #32
10117834c:	2b fe e7 f2	movk	x11, #0x3ff1, lsl #48
101178350:	61 01 67 9e	fmov	d1, x11
101178354:	00 20 61 1e	fcmp	d0, d1
101178358:	cd 00 00 54	b.le	0x101178370
10117835c:	eb e7 02 b2	mov	x11, #-0x3333333333333334
101178360:	cb fe e7 f2	movk	x11, #0x3ff6, lsl #48
101178364:	61 01 67 9e	fmov	d1, x11
101178368:	00 20 61 1e	fcmp	d0, d1
10117836c:	ab 01 00 54	b.lt	0x1011783a0
101178370:	eb e7 00 b2	mov	x11, #0x3333333333333333
101178374:	8b 66 86 f2	movk	x11, #0x3334
101178378:	2b ff e7 f2	movk	x11, #0x3ff9, lsl #48
10117837c:	61 01 67 9e	fmov	d1, x11
101178380:	00 20 61 1e	fcmp	d0, d1
101178384:	2d bf fe 54	b.le	0x101175b68
101178388:	eb e7 02 b2	mov	x11, #-0x3333333333333334
10117838c:	ab 99 99 f2	movk	x11, #0xcccd
101178390:	8b ff e7 f2	movk	x11, #0x3ffc, lsl #48
101178394:	61 01 67 9e	fmov	d1, x11
101178398:	00 20 61 1e	fcmp	d0, d1
10117839c:	6a be fe 54	b.ge	0x101175b68
1011783a0:	2e 00 80 52	mov	w14, #0x1
1011783a4:	f7 e7 ff 17	b	0x101172380
1011783a8:	e9 14 00 51	sub	w9, w7, #0x5
1011783ac:	3f 03 09 6b	cmp	w25, w9
1011783b0:	ec 01 00 54	b.gt	0x1011783ec
1011783b4:	29 13 00 91	add	x9, x25, #0x4
1011783b8:	80 7a 69 fc	ldr	d0, [x20, x9, lsl #3]
1011783bc:	e1 01 67 9e	fmov	d1, x15
1011783c0:	00 20 61 1e	fcmp	d0, d1
1011783c4:	eb a3 90 d2	mov	x11, #0x851f
1011783c8:	6b 3d aa f2	movk	x11, #0x51eb, lsl #16
1011783cc:	0b d7 c3 f2	movk	x11, #0x1eb8, lsl #32
1011783d0:	2b fe e7 f2	movk	x11, #0x3ff1, lsl #48
1011783d4:	61 01 67 9e	fmov	d1, x11
1011783d8:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
1011783dc:	0c 0c 00 54	b.gt	0x10117855c
1011783e0:	01 02 67 9e	fmov	d1, x16
1011783e4:	00 20 61 1e	fcmp	d0, d1
1011783e8:	ac 0b 00 54	b.gt	0x10117855c
1011783ec:	f9 03 0a aa	mov	x25, x10
1011783f0:	36 fd ff 17	b	0x1011778c8
1011783f4:	e8 14 00 51	sub	w8, w7, #0x5
1011783f8:	bf 01 08 6b	cmp	w13, w8
1011783fc:	ec 01 00 54	b.gt	0x101178438
101178400:	a8 11 00 11	add	w8, w13, #0x4
101178404:	80 da 68 fc	ldr	d0, [x20, w8, sxtw #3]
101178408:	e1 01 67 9e	fmov	d1, x15
10117840c:	00 20 61 1e	fcmp	d0, d1
101178410:	ea a3 90 d2	mov	x10, #0x851f
101178414:	6a 3d aa f2	movk	x10, #0x51eb, lsl #16
101178418:	0a d7 c3 f2	movk	x10, #0x1eb8, lsl #32
10117841c:	2a fe e7 f2	movk	x10, #0x3ff1, lsl #48
101178420:	41 01 67 9e	fmov	d1, x10
101178424:	04 b4 61 1e	fccmp	d0, d1, #0x4, lt
101178428:	4c 0a 00 54	b.gt	0x101178570
10117842c:	01 02 67 9e	fmov	d1, x16
101178430:	00 20 61 1e	fcmp	d0, d1
101178434:	ec 09 00 54	b.gt	0x101178570
101178438:	ed 03 0b aa	mov	x13, x11
10117843c:	a7 fd ff 17	b	0x101177ad8
101178440:	4b 17 00 91	add	x11, x26, #0x5
101178444:	80 7a 6b fc	ldr	d0, [x20, x11, lsl #3]
101178448:	ec a3 90 d2	mov	x12, #0x851f
10117844c:	6c 3d aa f2	movk	x12, #0x51eb, lsl #16
101178450:	0c d7 c3 f2	movk	x12, #0x1eb8, lsl #32
101178454:	2c fe e7 f2	movk	x12, #0x3ff1, lsl #48
101178458:	81 01 67 9e	fmov	d1, x12
10117845c:	00 20 61 1e	fcmp	d0, d1
101178460:	ec d7 9f 1a	cset	w12, gt
101178464:	c1 01 67 9e	fmov	d1, x14
101178468:	00 20 61 1e	fcmp	d0, d1
10117846c:	ed a7 9f 1a	cset	w13, lt
101178470:	8c 01 0d 0a	and	w12, w12, w13
101178474:	e1 01 67 9e	fmov	d1, x15
101178478:	00 20 61 1e	fcmp	d0, d1
10117847c:	ed d7 9f 1a	cset	w13, gt
101178480:	8c 01 0d 2a	orr	w12, w12, w13
101178484:	9f 01 00 71	cmp	w12, #0x0
101178488:	7a 11 8a 1a	csel	w26, w11, w10, ne
10117848c:	31 02 0c 2a	orr	w17, w17, w12
101178490:	8a e2 ff 17	b	0x101170eb8
101178494:	0a 17 00 91	add	x10, x24, #0x5
101178498:	80 7a 6a fc	ldr	d0, [x20, x10, lsl #3]
10117849c:	ec a3 90 d2	mov	x12, #0x851f
1011784a0:	6c 3d aa f2	movk	x12, #0x51eb, lsl #16
1011784a4:	0c d7 c3 f2	movk	x12, #0x1eb8, lsl #32
1011784a8:	2c fe e7 f2	movk	x12, #0x3ff1, lsl #48
1011784ac:	81 01 67 9e	fmov	d1, x12
1011784b0:	00 20 61 1e	fcmp	d0, d1
1011784b4:	ec d7 9f 1a	cset	w12, gt
1011784b8:	c1 01 67 9e	fmov	d1, x14
1011784bc:	00 20 61 1e	fcmp	d0, d1
1011784c0:	ed a7 9f 1a	cset	w13, lt
1011784c4:	8c 01 0d 0a	and	w12, w12, w13
1011784c8:	e1 01 67 9e	fmov	d1, x15
1011784cc:	00 20 61 1e	fcmp	d0, d1
1011784d0:	ed d7 9f 1a	cset	w13, gt
1011784d4:	8c 01 0d 2a	orr	w12, w12, w13
1011784d8:	9f 01 00 71	cmp	w12, #0x0
1011784dc:	58 11 89 1a	csel	w24, w10, w9, ne
1011784e0:	00 00 0c 2a	orr	w0, w0, w12
1011784e4:	c0 ec ff 17	b	0x1011737e4
1011784e8:	0b 1a 00 51	sub	w11, w16, #0x6
1011784ec:	5f 03 0b 6b	cmp	w26, w11
1011784f0:	0d 07 00 54	b.le	0x1011785d0
1011784f4:	fa 03 0a aa	mov	x26, x10
1011784f8:	b1 f9 ff 17	b	0x101176bbc
1011784fc:	0b 1a 00 51	sub	w11, w16, #0x6
101178500:	1f 01 0b 6b	cmp	w8, w11
101178504:	8c 45 ff 54	b.gt	0x101176db4
101178508:	08 15 00 11	add	w8, w8, #0x5
10117850c:	80 da 68 fc	ldr	d0, [x20, w8, sxtw #3]
101178510:	eb a3 90 d2	mov	x11, #0x851f
101178514:	6b 3d aa f2	movk	x11, #0x51eb, lsl #16
101178518:	0b d7 c3 f2	movk	x11, #0x1eb8, lsl #32
10117851c:	2b fe e7 f2	movk	x11, #0x3ff1, lsl #48
101178520:	61 01 67 9e	fmov	d1, x11
101178524:	00 20 61 1e	fcmp	d0, d1
101178528:	eb d7 9f 1a	cset	w11, gt
10117852c:	c1 01 67 9e	fmov	d1, x14
101178530:	00 20 61 1e	fcmp	d0, d1
101178534:	ec a7 9f 1a	cset	w12, lt
101178538:	6b 01 0c 0a	and	w11, w11, w12
10117853c:	e1 01 67 9e	fmov	d1, x15
101178540:	00 20 61 1e	fcmp	d0, d1
101178544:	ec d7 9f 1a	cset	w12, gt
101178548:	6b 01 0c 2a	orr	w11, w11, w12
10117854c:	7f 01 00 71	cmp	w11, #0x0
101178550:	08 11 89 1a	csel	w8, w8, w9, ne
101178554:	75 01 15 2a	orr	w21, w11, w21
101178558:	18 fa ff 17	b	0x101176db8
10117855c:	ea 18 00 51	sub	w10, w7, #0x6
101178560:	3f 03 0a 6b	cmp	w25, w10
101178564:	0d 06 00 54	b.le	0x101178624
101178568:	f9 03 09 aa	mov	x25, x9
10117856c:	d7 fc ff 17	b	0x1011778c8
101178570:	ea 18 00 51	sub	w10, w7, #0x6
101178574:	bf 01 0a 6b	cmp	w13, w10
101178578:	ec aa ff 54	b.gt	0x101177ad4
10117857c:	aa 15 00 11	add	w10, w13, #0x5
101178580:	80 da 6a fc	ldr	d0, [x20, w10, sxtw #3]
101178584:	eb a3 90 d2	mov	x11, #0x851f
101178588:	6b 3d aa f2	movk	x11, #0x51eb, lsl #16
10117858c:	0b d7 c3 f2	movk	x11, #0x1eb8, lsl #32
101178590:	2b fe e7 f2	movk	x11, #0x3ff1, lsl #48
101178594:	61 01 67 9e	fmov	d1, x11
101178598:	00 20 61 1e	fcmp	d0, d1
10117859c:	eb d7 9f 1a	cset	w11, gt
1011785a0:	e1 01 67 9e	fmov	d1, x15
1011785a4:	00 20 61 1e	fcmp	d0, d1
1011785a8:	ec a7 9f 1a	cset	w12, lt
1011785ac:	6b 01 0c 0a	and	w11, w11, w12
1011785b0:	01 02 67 9e	fmov	d1, x16
1011785b4:	00 20 61 1e	fcmp	d0, d1
1011785b8:	ec d7 9f 1a	cset	w12, gt
1011785bc:	6b 01 0c 2a	orr	w11, w11, w12
1011785c0:	7f 01 00 71	cmp	w11, #0x0
1011785c4:	4d 11 88 1a	csel	w13, w10, w8, ne
1011785c8:	7a 01 1a 2a	orr	w26, w11, w26
1011785cc:	43 fd ff 17	b	0x101177ad8
1011785d0:	4b 17 00 91	add	x11, x26, #0x5
1011785d4:	80 7a 6b fc	ldr	d0, [x20, x11, lsl #3]
1011785d8:	ec a3 90 d2	mov	x12, #0x851f
1011785dc:	6c 3d aa f2	movk	x12, #0x51eb, lsl #16
1011785e0:	0c d7 c3 f2	movk	x12, #0x1eb8, lsl #32
1011785e4:	2c fe e7 f2	movk	x12, #0x3ff1, lsl #48
1011785e8:	81 01 67 9e	fmov	d1, x12
1011785ec:	00 20 61 1e	fcmp	d0, d1
1011785f0:	ec d7 9f 1a	cset	w12, gt
1011785f4:	c1 01 67 9e	fmov	d1, x14
1011785f8:	00 20 61 1e	fcmp	d0, d1
1011785fc:	ed a7 9f 1a	cset	w13, lt
101178600:	8c 01 0d 0a	and	w12, w12, w13
101178604:	e1 01 67 9e	fmov	d1, x15
101178608:	00 20 61 1e	fcmp	d0, d1
10117860c:	ed d7 9f 1a	cset	w13, gt
101178610:	8c 01 0d 2a	orr	w12, w12, w13
101178614:	9f 01 00 71	cmp	w12, #0x0
101178618:	7a 11 8a 1a	csel	w26, w11, w10, ne
10117861c:	b5 02 0c 2a	orr	w21, w21, w12
101178620:	67 f9 ff 17	b	0x101176bbc
101178624:	2a 17 00 91	add	x10, x25, #0x5
101178628:	80 7a 6a fc	ldr	d0, [x20, x10, lsl #3]
10117862c:	eb a3 90 d2	mov	x11, #0x851f
101178630:	6b 3d aa f2	movk	x11, #0x51eb, lsl #16
101178634:	0b d7 c3 f2	movk	x11, #0x1eb8, lsl #32
101178638:	2b fe e7 f2	movk	x11, #0x3ff1, lsl #48
10117863c:	61 01 67 9e	fmov	d1, x11
101178640:	00 20 61 1e	fcmp	d0, d1
101178644:	eb d7 9f 1a	cset	w11, gt
101178648:	e1 01 67 9e	fmov	d1, x15
10117864c:	00 20 61 1e	fcmp	d0, d1
101178650:	ec a7 9f 1a	cset	w12, lt
101178654:	6b 01 0c 0a	and	w11, w11, w12
101178658:	01 02 67 9e	fmov	d1, x16
10117865c:	00 20 61 1e	fcmp	d0, d1
101178660:	ec d7 9f 1a	cset	w12, gt
101178664:	6b 01 0c 2a	orr	w11, w11, w12
101178668:	7f 01 00 71	cmp	w11, #0x0
10117866c:	59 11 89 1a	csel	w25, w10, w9, ne
101178670:	5a 03 0b 2a	orr	w26, w26, w11
101178674:	95 fc ff 17	b	0x1011778c8
101178678:	f9 9b 40 f9	ldr	x25, [sp, #0x130]
10117867c:	f4 8b 40 f9	ldr	x20, [sp, #0x110]
101178680:	74 00 00 b4	cbz	x20, 0x10117868c
101178684:	e0 03 14 aa	mov	x0, x20
101178688:	0c 65 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10117868c:	e0 f7 41 f9	ldr	x0, [sp, #0x3e8]
101178690:	17 00 c8 d2	mov	x23, #0x400000000000
101178694:	f7 11 e8 f2	movk	x23, #0x408f, lsl #48
101178698:	40 00 00 b4	cbz	x0, 0x1011786a0
10117869c:	07 65 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
1011786a0:	e0 73 40 f9	ldr	x0, [sp, #0xe0]
1011786a4:	40 00 00 b4	cbz	x0, 0x1011786ac
1011786a8:	04 65 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
1011786ac:	e0 03 42 f9	ldr	x0, [sp, #0x400]
1011786b0:	40 00 00 b4	cbz	x0, 0x1011786b8
1011786b4:	01 65 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
1011786b8:	e0 0f 42 f9	ldr	x0, [sp, #0x418]
1011786bc:	60 f7 f9 b4	cbz	x0, 0x10116c5a8
1011786c0:	fe 64 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
1011786c4:	b9 cf ff 17	b	0x10116c5a8
1011786c8:	09 00 80 52	mov	w9, #0x0
1011786cc:	d1 d2 ff 17	b	0x10116d210
1011786d0:	e8 07 40 91	add	x8, sp, #0x1, lsl #12
1011786d4:	08 c1 19 91	add	x8, x8, #0x670
1011786d8:	08 a1 00 91	add	x8, x8, #0x28
1011786dc:	e8 83 00 f9	str	x8, [sp, #0x100]
1011786e0:	28 00 80 52	mov	w8, #0x1
1011786e4:	04 03 80 52	mov	w4, #0x18
1011786e8:	08 10 6c 1e	fmov	d8, #0.50000000
1011786ec:	e6 e7 07 6f	movi.2d	v6, #0xffffffffffffffff
1011786f0:	09 10 6e 1e	fmov	d9, #1.00000000
1011786f4:	0a 10 61 1e	fmov	d10, #3.00000000
1011786f8:	0b 10 70 1e	fmov	d11, #-2.00000000
1011786fc:	0c 10 71 1e	fmov	d12, #-3.00000000
101178700:	0d 10 62 1e	fmov	d13, #4.00000000
101178704:	35 00 00 14	b	0x1011787d8
101178708:	e8 07 40 91	add	x8, sp, #0x1, lsl #12
10117870c:	08 c1 09 91	add	x8, x8, #0x270
101178710:	06 01 81 3d	str	q6, [x8, #0x400]
101178714:	06 05 81 3d	str	q6, [x8, #0x410]
101178718:	06 09 81 3d	str	q6, [x8, #0x420]
10117871c:	06 0d 81 3d	str	q6, [x8, #0x430]
101178720:	06 11 81 3d	str	q6, [x8, #0x440]
101178724:	06 15 81 3d	str	q6, [x8, #0x450]
101178728:	06 19 81 3d	str	q6, [x8, #0x460]
10117872c:	06 1d 81 3d	str	q6, [x8, #0x470]
101178730:	06 21 81 3d	str	q6, [x8, #0x480]
101178734:	06 25 81 3d	str	q6, [x8, #0x490]
101178738:	06 29 81 3d	str	q6, [x8, #0x4a0]
10117873c:	06 2d 81 3d	str	q6, [x8, #0x4b0]
101178740:	06 31 81 3d	str	q6, [x8, #0x4c0]
101178744:	06 35 81 3d	str	q6, [x8, #0x4d0]
101178748:	06 39 81 3d	str	q6, [x8, #0x4e0]
10117874c:	06 3d 81 3d	str	q6, [x8, #0x4f0]
101178750:	06 41 81 3d	str	q6, [x8, #0x500]
101178754:	06 45 81 3d	str	q6, [x8, #0x510]
101178758:	06 49 81 3d	str	q6, [x8, #0x520]
10117875c:	06 4d 81 3d	str	q6, [x8, #0x530]
101178760:	06 51 81 3d	str	q6, [x8, #0x540]
101178764:	06 55 81 3d	str	q6, [x8, #0x550]
101178768:	06 59 81 3d	str	q6, [x8, #0x560]
10117876c:	06 5d 81 3d	str	q6, [x8, #0x570]
101178770:	06 61 81 3d	str	q6, [x8, #0x580]
101178774:	06 65 81 3d	str	q6, [x8, #0x590]
101178778:	06 69 81 3d	str	q6, [x8, #0x5a0]
10117877c:	06 6d 81 3d	str	q6, [x8, #0x5b0]
101178780:	06 71 81 3d	str	q6, [x8, #0x5c0]
101178784:	06 75 81 3d	str	q6, [x8, #0x5d0]
101178788:	06 79 81 3d	str	q6, [x8, #0x5e0]
10117878c:	06 7d 81 3d	str	q6, [x8, #0x5f0]
101178790:	06 19 1f ad	stp	q6, q6, [x8, #0x3e0]
101178794:	06 19 1e ad	stp	q6, q6, [x8, #0x3c0]
101178798:	06 19 1d ad	stp	q6, q6, [x8, #0x3a0]
10117879c:	06 19 1c ad	stp	q6, q6, [x8, #0x380]
1011787a0:	06 19 1b ad	stp	q6, q6, [x8, #0x360]
1011787a4:	06 19 1a ad	stp	q6, q6, [x8, #0x340]
1011787a8:	06 19 19 ad	stp	q6, q6, [x8, #0x320]
1011787ac:	06 19 18 ad	stp	q6, q6, [x8, #0x300]
1011787b0:	06 19 17 ad	stp	q6, q6, [x8, #0x2e0]
1011787b4:	06 19 16 ad	stp	q6, q6, [x8, #0x2c0]
1011787b8:	06 19 15 ad	stp	q6, q6, [x8, #0x2a0]
1011787bc:	06 19 14 ad	stp	q6, q6, [x8, #0x280]
1011787c0:	06 19 13 ad	stp	q6, q6, [x8, #0x260]
1011787c4:	06 19 12 ad	stp	q6, q6, [x8, #0x240]
1011787c8:	06 19 11 ad	stp	q6, q6, [x8, #0x220]
1011787cc:	06 19 10 ad	stp	q6, q6, [x8, #0x200]
1011787d0:	08 00 80 52	mov	w8, #0x0
1011787d4:	d3 75 00 36	tbz	w19, #0x0, 0x10117968c
1011787d8:	f3 03 08 aa	mov	x19, x8
1011787dc:	28 03 40 f9	ldr	x8, [x25]
1011787e0:	e9 b3 40 f9	ldr	x9, [sp, #0x160]
1011787e4:	29 01 40 f9	ldr	x9, [x9]
1011787e8:	08 01 09 cb	sub	x8, x8, x9
1011787ec:	08 fd 43 93	asr	x8, x8, #3
1011787f0:	e9 f3 01 b2	mov	x9, #-0x5555555555555556
1011787f4:	69 55 95 f2	movk	x9, #0xaaab
1011787f8:	08 7d 09 9b	mul	x8, x8, x9
1011787fc:	1f 09 00 71	cmp	w8, #0x2
101178800:	4d f8 ff 54	b.le	0x101178708
101178804:	f3 23 01 b9	str	w19, [sp, #0x120]
101178808:	13 05 00 51	sub	w19, w8, #0x1
10117880c:	08 09 00 51	sub	w8, w8, #0x2
101178810:	14 7d 40 93	sxtw	x20, w8
101178814:	15 09 80 52	mov	w21, #0x48
101178818:	37 00 80 52	mov	w23, #0x1
10117881c:	08 00 00 14	b	0x10117883c
101178820:	fc 97 40 f9	ldr	x28, [sp, #0x128]
101178824:	e6 e7 07 6f	movi.2d	v6, #0xffffffffffffffff
101178828:	b5 62 00 91	add	x21, x21, #0x18
10117882c:	f7 03 19 aa	mov	x23, x25
101178830:	3f 03 13 eb	cmp	x25, x19
101178834:	fb 9f 40 f9	ldr	x27, [sp, #0x138]
101178838:	40 13 00 54	b.eq	0x101178aa0
10117883c:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
101178840:	08 01 40 f9	ldr	x8, [x8]
101178844:	e9 22 04 9b	madd	x9, x23, x4, x8
101178848:	2c 81 5e b8	ldur	w12, [x9, #-0x18]
10117884c:	2a 01 40 b9	ldr	w10, [x9]
101178850:	f9 06 00 91	add	x25, x23, #0x1
101178854:	ff 02 14 eb	cmp	x23, x20
101178858:	4a 0a 00 54	b.ge	0x1011789a0
10117885c:	2b 7f 04 9b	mul	x11, x25, x4
101178860:	0b 69 6b b8	ldr	w11, [x8, x11]
101178864:	00 e4 00 2f	movi	d0, #0000000000000000
101178868:	01 e4 00 2f	movi	d1, #0000000000000000
10117886c:	4c 01 0c 6b	subs	w12, w10, w12
101178870:	a0 00 00 54	b.eq	0x101178884
101178874:	6d 01 0a 4b	sub	w13, w11, w10
101178878:	a1 01 62 1e	scvtf	d1, w13
10117887c:	82 01 62 1e	scvtf	d2, w12
101178880:	21 18 62 1e	fdiv	d1, d1, d2
101178884:	ec 0a 00 11	add	w12, w23, #0x2
101178888:	8c 7d a4 9b	umull	x12, w12, w4
10117888c:	0c 69 6c b8	ldr	w12, [x8, x12]
101178890:	8c 01 0b 6b	subs	w12, w12, w11
101178894:	a0 00 00 54	b.eq	0x1011788a8
101178898:	6d 01 0a 4b	sub	w13, w11, w10
10117889c:	a0 01 62 1e	scvtf	d0, w13
1011788a0:	82 01 62 1e	scvtf	d2, w12
1011788a4:	00 18 62 1e	fdiv	d0, d0, d2
1011788a8:	22 28 68 1e	fadd	d2, d1, d8
1011788ac:	5b 00 78 1e	fcvtzs	w27, d2
1011788b0:	02 28 68 1e	fadd	d2, d0, d8
1011788b4:	4c 00 78 1e	fcvtzs	w12, d2
1011788b8:	7f 07 00 71	cmp	w27, #0x1
1011788bc:	88 a9 41 7a	ccmp	w12, #0x1, #0x8, ge
1011788c0:	ec e7 02 b2	mov	x12, #-0x3333333333333334
1011788c4:	ac 99 99 f2	movk	x12, #0xcccd
1011788c8:	8c ff e7 f2	movk	x12, #0x3ffc, lsl #48
1011788cc:	82 01 67 9e	fmov	d2, x12
1011788d0:	24 a4 62 1e	fccmp	d1, d2, #0x4, ge
1011788d4:	04 c4 62 1e	fccmp	d0, d2, #0x4, gt
1011788d8:	8d fa ff 54	b.le	0x101178828
1011788dc:	ff 3f 0b f9	str	xzr, [sp, #0x1678]
1011788e0:	ff 3b 0b f9	str	xzr, [sp, #0x1670]
1011788e4:	0c 00 80 12	mov	w12, #-0x1
1011788e8:	ec 83 16 b9	str	w12, [sp, #0x1680]
1011788ec:	ec 07 40 91	add	x12, sp, #0x1, lsl #12
1011788f0:	8c c1 09 91	add	x12, x12, #0x270
1011788f4:	9f 51 10 39	strb	wzr, [x12, #0x414]
1011788f8:	7f 0b 00 71	cmp	w27, #0x2
1011788fc:	f8 b3 40 f9	ldr	x24, [sp, #0x160]
101178900:	03 f9 ff 54	b.lo	0x101178820
101178904:	6a 01 0a 4b	sub	w10, w11, w10
101178908:	40 01 62 1e	scvtf	d0, w10
10117890c:	61 03 62 1e	scvtf	d1, w27
101178910:	00 18 61 1e	fdiv	d0, d0, d1
101178914:	00 28 68 1e	fadd	d0, d0, d8
101178918:	1a 00 78 1e	fcvtzs	w26, d0
10117891c:	29 01 40 b9	ldr	w9, [x9]
101178920:	29 01 1a 0b	add	w9, w9, w26
101178924:	e9 73 16 b9	str	w9, [sp, #0x1670]
101178928:	ff 3f 0b f9	str	xzr, [sp, #0x1678]
10117892c:	e8 22 04 9b	madd	x8, x23, x4, x8
101178930:	01 61 00 91	add	x1, x8, #0x18
101178934:	e2 07 40 91	add	x2, sp, #0x1, lsl #12
101178938:	42 c0 19 91	add	x2, x2, #0x670
10117893c:	e0 03 18 aa	mov	x0, x24
101178940:	36 1a ff 97	bl	__ZNSt3__16vectorIN16BeatAnalyzer_2_06peakss8BeatInfoENS_9allocatorIS3_EEE6insertENS_11__wrap_iterIPKS3_EERS8_
101178944:	04 03 80 52	mov	w4, #0x18
101178948:	7f 0b 00 71	cmp	w27, #0x2
10117894c:	a0 f6 ff 54	b.eq	0x101178820
101178950:	7b 0b 00 d1	sub	x27, x27, #0x2
101178954:	5c 7b 1f 53	lsl	w28, w26, #1
101178958:	f6 03 15 aa	mov	x22, x21
10117895c:	08 03 40 f9	ldr	x8, [x24]
101178960:	e9 7e 04 9b	mul	x9, x23, x4
101178964:	09 69 69 b8	ldr	w9, [x8, x9]
101178968:	89 03 09 0b	add	w9, w28, w9
10117896c:	e9 73 16 b9	str	w9, [sp, #0x1670]
101178970:	ff 3f 0b f9	str	xzr, [sp, #0x1678]
101178974:	c1 02 08 8b	add	x1, x22, x8
101178978:	e2 07 40 91	add	x2, sp, #0x1, lsl #12
10117897c:	42 c0 19 91	add	x2, x2, #0x670
101178980:	e0 03 18 aa	mov	x0, x24
101178984:	25 1a ff 97	bl	__ZNSt3__16vectorIN16BeatAnalyzer_2_06peakss8BeatInfoENS_9allocatorIS3_EEE6insertENS_11__wrap_iterIPKS3_EERS8_
101178988:	04 03 80 52	mov	w4, #0x18
10117898c:	d6 62 00 91	add	x22, x22, #0x18
101178990:	9c 03 1a 0b	add	w28, w28, w26
101178994:	7b 07 00 f1	subs	x27, x27, #0x1
101178998:	21 fe ff 54	b.ne	0x10117895c
10117899c:	a1 ff ff 17	b	0x101178820
1011789a0:	4b 01 0c 6b	subs	w11, w10, w12
1011789a4:	20 f4 ff 54	b.eq	0x101178828
1011789a8:	2c 7f 04 9b	mul	x12, x25, x4
1011789ac:	0c 69 6c b8	ldr	w12, [x8, x12]
1011789b0:	8a 01 0a 4b	sub	w10, w12, w10
1011789b4:	40 01 62 1e	scvtf	d0, w10
1011789b8:	61 01 62 1e	scvtf	d1, w11
1011789bc:	01 18 61 1e	fdiv	d1, d0, d1
1011789c0:	22 28 68 1e	fadd	d2, d1, d8
1011789c4:	5b 00 78 1e	fcvtzs	w27, d2
1011789c8:	7f 07 00 71	cmp	w27, #0x1
1011789cc:	ea e7 02 b2	mov	x10, #-0x3333333333333334
1011789d0:	aa 99 99 f2	movk	x10, #0xcccd
1011789d4:	8a ff e7 f2	movk	x10, #0x3ffc, lsl #48
1011789d8:	42 01 67 9e	fmov	d2, x10
1011789dc:	24 a4 62 1e	fccmp	d1, d2, #0x4, ge
1011789e0:	4d f2 ff 54	b.le	0x101178828
1011789e4:	ff 3f 0b f9	str	xzr, [sp, #0x1678]
1011789e8:	ff 3b 0b f9	str	xzr, [sp, #0x1670]
1011789ec:	0a 00 80 12	mov	w10, #-0x1
1011789f0:	ea 83 16 b9	str	w10, [sp, #0x1680]
1011789f4:	ea 07 40 91	add	x10, sp, #0x1, lsl #12
1011789f8:	4a c1 09 91	add	x10, x10, #0x270
1011789fc:	5f 51 10 39	strb	wzr, [x10, #0x414]
101178a00:	7f 0b 00 71	cmp	w27, #0x2
101178a04:	f8 b3 40 f9	ldr	x24, [sp, #0x160]
101178a08:	c3 f0 ff 54	b.lo	0x101178820
101178a0c:	61 03 62 1e	scvtf	d1, w27
101178a10:	00 18 61 1e	fdiv	d0, d0, d1
101178a14:	00 28 68 1e	fadd	d0, d0, d8
101178a18:	1a 00 78 1e	fcvtzs	w26, d0
101178a1c:	29 01 40 b9	ldr	w9, [x9]
101178a20:	29 01 1a 0b	add	w9, w9, w26
101178a24:	e9 73 16 b9	str	w9, [sp, #0x1670]
101178a28:	ff 3f 0b f9	str	xzr, [sp, #0x1678]
101178a2c:	e8 22 04 9b	madd	x8, x23, x4, x8
101178a30:	01 61 00 91	add	x1, x8, #0x18
101178a34:	e2 07 40 91	add	x2, sp, #0x1, lsl #12
101178a38:	42 c0 19 91	add	x2, x2, #0x670
101178a3c:	e0 03 18 aa	mov	x0, x24
101178a40:	f6 19 ff 97	bl	__ZNSt3__16vectorIN16BeatAnalyzer_2_06peakss8BeatInfoENS_9allocatorIS3_EEE6insertENS_11__wrap_iterIPKS3_EERS8_
101178a44:	04 03 80 52	mov	w4, #0x18
101178a48:	7f 0b 00 71	cmp	w27, #0x2
101178a4c:	a0 ee ff 54	b.eq	0x101178820
101178a50:	7b 0b 00 d1	sub	x27, x27, #0x2
101178a54:	5c 7b 1f 53	lsl	w28, w26, #1
101178a58:	f6 03 15 aa	mov	x22, x21
101178a5c:	08 03 40 f9	ldr	x8, [x24]
101178a60:	e9 7e 04 9b	mul	x9, x23, x4
101178a64:	09 69 69 b8	ldr	w9, [x8, x9]
101178a68:	89 03 09 0b	add	w9, w28, w9
101178a6c:	e9 73 16 b9	str	w9, [sp, #0x1670]
101178a70:	ff 3f 0b f9	str	xzr, [sp, #0x1678]
101178a74:	c1 02 08 8b	add	x1, x22, x8
101178a78:	e2 07 40 91	add	x2, sp, #0x1, lsl #12
101178a7c:	42 c0 19 91	add	x2, x2, #0x670
101178a80:	e0 03 18 aa	mov	x0, x24
101178a84:	e5 19 ff 97	bl	__ZNSt3__16vectorIN16BeatAnalyzer_2_06peakss8BeatInfoENS_9allocatorIS3_EEE6insertENS_11__wrap_iterIPKS3_EERS8_
101178a88:	04 03 80 52	mov	w4, #0x18
101178a8c:	d6 62 00 91	add	x22, x22, #0x18
101178a90:	9c 03 1a 0b	add	w28, w28, w26
101178a94:	7b 07 00 f1	subs	x27, x27, #0x1
101178a98:	21 fe ff 54	b.ne	0x101178a5c
101178a9c:	61 ff ff 17	b	0x101178820
101178aa0:	f9 9b 40 f9	ldr	x25, [sp, #0x130]
101178aa4:	2a 03 40 f9	ldr	x10, [x25]
101178aa8:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
101178aac:	08 01 40 f9	ldr	x8, [x8]
101178ab0:	49 01 08 cb	sub	x9, x10, x8
101178ab4:	eb f3 01 b2	mov	x11, #-0x5555555555555556
101178ab8:	6b 55 95 f2	movk	x11, #0xaaab
101178abc:	4b 55 e5 f2	movk	x11, #0x2aaa, lsl #48
101178ac0:	29 7d 4b 9b	smulh	x9, x9, x11
101178ac4:	2b fd 42 93	asr	x11, x9, #2
101178ac8:	ec 07 40 91	add	x12, sp, #0x1, lsl #12
101178acc:	8c c1 09 91	add	x12, x12, #0x270
101178ad0:	86 01 81 3d	str	q6, [x12, #0x400]
101178ad4:	69 fd 49 8b	add	x9, x11, x9, lsr #63
101178ad8:	86 05 81 3d	str	q6, [x12, #0x410]
101178adc:	86 09 81 3d	str	q6, [x12, #0x420]
101178ae0:	86 0d 81 3d	str	q6, [x12, #0x430]
101178ae4:	86 11 81 3d	str	q6, [x12, #0x440]
101178ae8:	86 15 81 3d	str	q6, [x12, #0x450]
101178aec:	86 19 81 3d	str	q6, [x12, #0x460]
101178af0:	86 1d 81 3d	str	q6, [x12, #0x470]
101178af4:	86 21 81 3d	str	q6, [x12, #0x480]
101178af8:	86 25 81 3d	str	q6, [x12, #0x490]
101178afc:	86 29 81 3d	str	q6, [x12, #0x4a0]
101178b00:	86 2d 81 3d	str	q6, [x12, #0x4b0]
101178b04:	86 31 81 3d	str	q6, [x12, #0x4c0]
101178b08:	86 35 81 3d	str	q6, [x12, #0x4d0]
101178b0c:	86 39 81 3d	str	q6, [x12, #0x4e0]
101178b10:	86 3d 81 3d	str	q6, [x12, #0x4f0]
101178b14:	86 41 81 3d	str	q6, [x12, #0x500]
101178b18:	86 45 81 3d	str	q6, [x12, #0x510]
101178b1c:	86 49 81 3d	str	q6, [x12, #0x520]
101178b20:	86 4d 81 3d	str	q6, [x12, #0x530]
101178b24:	86 51 81 3d	str	q6, [x12, #0x540]
101178b28:	86 55 81 3d	str	q6, [x12, #0x550]
101178b2c:	86 59 81 3d	str	q6, [x12, #0x560]
101178b30:	86 5d 81 3d	str	q6, [x12, #0x570]
101178b34:	86 61 81 3d	str	q6, [x12, #0x580]
101178b38:	86 65 81 3d	str	q6, [x12, #0x590]
101178b3c:	86 69 81 3d	str	q6, [x12, #0x5a0]
101178b40:	86 6d 81 3d	str	q6, [x12, #0x5b0]
101178b44:	86 71 81 3d	str	q6, [x12, #0x5c0]
101178b48:	86 75 81 3d	str	q6, [x12, #0x5d0]
101178b4c:	86 79 81 3d	str	q6, [x12, #0x5e0]
101178b50:	86 7d 81 3d	str	q6, [x12, #0x5f0]
101178b54:	86 19 1f ad	stp	q6, q6, [x12, #0x3e0]
101178b58:	86 19 1e ad	stp	q6, q6, [x12, #0x3c0]
101178b5c:	86 19 1d ad	stp	q6, q6, [x12, #0x3a0]
101178b60:	86 19 1c ad	stp	q6, q6, [x12, #0x380]
101178b64:	86 19 1b ad	stp	q6, q6, [x12, #0x360]
101178b68:	86 19 1a ad	stp	q6, q6, [x12, #0x340]
101178b6c:	86 19 19 ad	stp	q6, q6, [x12, #0x320]
101178b70:	86 19 18 ad	stp	q6, q6, [x12, #0x300]
101178b74:	86 19 17 ad	stp	q6, q6, [x12, #0x2e0]
101178b78:	86 19 16 ad	stp	q6, q6, [x12, #0x2c0]
101178b7c:	86 19 15 ad	stp	q6, q6, [x12, #0x2a0]
101178b80:	86 19 14 ad	stp	q6, q6, [x12, #0x280]
101178b84:	86 19 13 ad	stp	q6, q6, [x12, #0x260]
101178b88:	86 19 12 ad	stp	q6, q6, [x12, #0x240]
101178b8c:	86 19 11 ad	stp	q6, q6, [x12, #0x220]
101178b90:	86 19 10 ad	stp	q6, q6, [x12, #0x200]
101178b94:	3f 01 01 71	cmp	w9, #0x40
101178b98:	f5 07 40 91	add	x21, sp, #0x1, lsl #12
101178b9c:	b5 c2 19 91	add	x21, x21, #0x670
101178ba0:	e2 e7 01 b2	mov	x2, #-0x6666666666666667
101178ba4:	42 33 93 f2	movk	x2, #0x999a
101178ba8:	22 fb e7 f2	movk	x2, #0x3fd9, lsl #48
101178bac:	e3 e7 00 b2	mov	x3, #0x3333333333333333
101178bb0:	63 fc e7 f2	movk	x3, #0x3fe3, lsl #48
101178bb4:	f3 23 41 b9	ldr	w19, [sp, #0x120]
101178bb8:	cd e0 ff 54	b.le	0x1011787d0
101178bbc:	0f 00 80 52	mov	w15, #0x0
101178bc0:	0d 00 80 52	mov	w13, #0x0
101178bc4:	05 00 80 52	mov	w5, #0x0
101178bc8:	2b 81 00 51	sub	w11, w9, #0x20
101178bcc:	0c 81 0d 91	add	x12, x8, #0x360
101178bd0:	0e 04 80 52	mov	w14, #0x20
101178bd4:	07 00 00 14	b	0x101178bf0
101178bd8:	0f 00 80 52	mov	w15, #0x0
101178bdc:	ad 05 00 11	add	w13, w13, #0x1
101178be0:	ce 05 00 91	add	x14, x14, #0x1
101178be4:	8c 61 00 91	add	x12, x12, #0x18
101178be8:	7f 01 0e eb	cmp	x11, x14
101178bec:	c0 06 00 54	b.eq	0x101178cc4
101178bf0:	91 01 40 b9	ldr	w17, [x12]
101178bf4:	80 01 5a b8	ldur	w0, [x12, #-0x60]
101178bf8:	30 02 00 4b	sub	w16, w17, w0
101178bfc:	81 01 54 b8	ldur	w1, [x12, #-0xc0]
101178c00:	00 e4 00 2f	movi	d0, #0000000000000000
101178c04:	01 e4 00 2f	movi	d1, #0000000000000000
101178c08:	00 00 01 6b	subs	w0, w0, w1
101178c0c:	a0 00 00 54	b.eq	0x101178c20
101178c10:	01 02 62 1e	scvtf	d1, w16
101178c14:	02 00 62 1e	scvtf	d2, w0
101178c18:	21 08 6d 1e	fmul	d1, d1, d13
101178c1c:	21 18 62 1e	fdiv	d1, d1, d2
101178c20:	c0 21 00 11	add	w0, w14, #0x8
101178c24:	00 7c a4 9b	umull	x0, w0, w4
101178c28:	00 69 60 b8	ldr	w0, [x8, x0]
101178c2c:	11 00 11 6b	subs	w17, w0, w17
101178c30:	a0 00 00 54	b.eq	0x101178c44
101178c34:	00 02 62 1e	scvtf	d0, w16
101178c38:	22 02 62 1e	scvtf	d2, w17
101178c3c:	00 08 6d 1e	fmul	d0, d0, d13
101178c40:	00 18 62 1e	fdiv	d0, d0, d2
101178c44:	22 c0 65 1e	frintz	d2, d1
101178c48:	22 38 62 1e	fsub	d2, d1, d2
101178c4c:	03 c0 65 1e	frintz	d3, d0
101178c50:	03 38 63 1e	fsub	d3, d0, d3
101178c54:	44 00 67 9e	fmov	d4, x2
101178c58:	40 20 64 1e	fcmp	d2, d4
101178c5c:	65 00 67 9e	fmov	d5, x3
101178c60:	40 c4 65 1e	fccmp	d2, d5, #0x0, gt
101178c64:	64 b4 64 1e	fccmp	d3, d4, #0x4, lt
101178c68:	60 c4 65 1e	fccmp	d3, d5, #0x0, gt
101178c6c:	6a fb ff 54	b.ge	0x101178bd8
101178c70:	30 00 78 1e	fcvtzs	w16, d1
101178c74:	11 00 78 1e	fcvtzs	w17, d0
101178c78:	1f 02 11 6b	cmp	w16, w17
101178c7c:	a8 09 45 7a	ccmp	w13, #0x5, #0x8, eq
101178c80:	f1 a7 9f 1a	cset	w17, lt
101178c84:	2f 02 0f 2a	orr	w15, w17, w15
101178c88:	6f 00 00 36	tbz	w15, #0x0, 0x101178c94
101178c8c:	2f 02 00 52	eor	w15, w17, #0x1
101178c90:	d3 ff ff 17	b	0x101178bdc
101178c94:	ad 7c 7e 93	sbfiz	x13, x5, #2, #32
101178c98:	ae 6a 2d b8	str	w14, [x21, x13]
101178c9c:	ef 07 40 91	add	x15, sp, #0x1, lsl #12
101178ca0:	ef c1 11 91	add	x15, x15, #0x470
101178ca4:	f0 69 2d b8	str	w16, [x15, x13]
101178ca8:	b0 04 00 11	add	w16, w5, #0x1
101178cac:	bf f8 01 71	cmp	w5, #0x7e
101178cb0:	0c 01 00 54	b.gt	0x101178cd0
101178cb4:	0d 00 80 52	mov	w13, #0x0
101178cb8:	2f 00 80 52	mov	w15, #0x1
101178cbc:	e5 03 10 aa	mov	x5, x16
101178cc0:	c7 ff ff 17	b	0x101178bdc
101178cc4:	bf 08 00 71	cmp	w5, #0x2
101178cc8:	6a 00 00 54	b.ge	0x101178cd4
101178ccc:	bc 01 00 14	b	0x1011793bc
101178cd0:	e5 03 10 aa	mov	x5, x16
101178cd4:	17 00 80 d2	mov	x23, #0x0
101178cd8:	b8 7c 01 53	lsr	w24, w5, #1
101178cdc:	e5 e3 10 a9	stp	x5, x24, [sp, #0x108]
101178ce0:	e9 03 05 2a	mov	w9, w5
101178ce4:	e9 af 00 f9	str	x9, [sp, #0x158]
101178ce8:	23 09 00 d1	sub	x3, x9, #0x2
101178cec:	fc 83 40 f9	ldr	x28, [sp, #0x100]
101178cf0:	f4 03 03 aa	mov	x20, x3
101178cf4:	5b 00 80 52	mov	w27, #0x2
101178cf8:	e2 07 40 91	add	x2, sp, #0x1, lsl #12
101178cfc:	42 c0 11 91	add	x2, x2, #0x470
101178d00:	e3 a3 00 f9	str	x3, [sp, #0x140]
101178d04:	93 ee 7c 92	and	x19, x20, #0xfffffffffffffff0
101178d08:	e9 f2 7d d3	lsl	x9, x23, #3
101178d0c:	aa 6a a9 b8	ldrsw	x10, [x21, x9]
101178d10:	4a 21 04 9b	madd	x10, x10, x4, x8
101178d14:	4b 61 40 b9	ldr	w11, [x10, #0x60]
101178d18:	4c 01 40 b9	ldr	w12, [x10]
101178d1c:	6b 01 0c 4b	sub	w11, w11, w12
101178d20:	60 01 62 1e	scvtf	d0, w11
101178d24:	49 68 69 b8	ldr	w9, [x2, x9]
101178d28:	f9 fa 7f d3	lsl	x25, x23, #1
101178d2c:	21 01 62 1e	scvtf	d1, w9
101178d30:	21 28 68 1e	fadd	d1, d1, d8
101178d34:	82 01 62 1e	scvtf	d2, w12
101178d38:	42 28 68 1e	fadd	d2, d2, d8
101178d3c:	4b 00 78 1e	fcvtzs	w11, d2
101178d40:	4b 01 00 b9	str	w11, [x10]
101178d44:	42 c0 65 1e	frintz	d2, d2
101178d48:	21 19 61 1e	fdiv	d1, d9, d1
101178d4c:	03 20 41 1f	fmadd	d3, d0, d1, d8
101178d50:	63 28 62 1e	fadd	d3, d3, d2
101178d54:	6b 00 78 1e	fcvtzs	w11, d3
101178d58:	4b 19 00 b9	str	w11, [x10, #0x18]
101178d5c:	23 28 61 1e	fadd	d3, d1, d1
101178d60:	03 20 43 1f	fmadd	d3, d0, d3, d8
101178d64:	63 28 62 1e	fadd	d3, d3, d2
101178d68:	6b 00 78 1e	fcvtzs	w11, d3
101178d6c:	4b 31 00 b9	str	w11, [x10, #0x30]
101178d70:	00 08 6a 1e	fmul	d0, d0, d10
101178d74:	00 20 41 1f	fmadd	d0, d0, d1, d8
101178d78:	00 28 62 1e	fadd	d0, d0, d2
101178d7c:	0b 00 78 1e	fcvtzs	w11, d0
101178d80:	4b 49 00 b9	str	w11, [x10, #0x48]
101178d84:	36 00 80 52	mov	w22, #0x1
101178d88:	f6 fa 7f b3	bfi	x22, x23, #1, #63
101178d8c:	ca f6 7e d3	lsl	x10, x22, #2
101178d90:	ab 6a aa b8	ldrsw	x11, [x21, x10]
101178d94:	6b 21 04 9b	madd	x11, x11, x4, x8
101178d98:	6c 61 40 b9	ldr	w12, [x11, #0x60]
101178d9c:	6d 01 40 b9	ldr	w13, [x11]
101178da0:	8d 01 0d 4b	sub	w13, w12, w13
101178da4:	a0 01 62 1e	scvtf	d0, w13
101178da8:	41 68 6a bc	ldr	s1, [x2, x10]
101178dac:	7a 00 19 cb	sub	x26, x3, x25
101178db0:	21 a4 20 0f	sshll.2d	v1, v1, #0x0
101178db4:	21 d8 61 5e	scvtf	d1, d1
101178db8:	21 28 68 1e	fadd	d1, d1, d8
101178dbc:	82 01 62 1e	scvtf	d2, w12
101178dc0:	42 28 68 1e	fadd	d2, d2, d8
101178dc4:	4a 00 78 1e	fcvtzs	w10, d2
101178dc8:	6a 61 00 b9	str	w10, [x11, #0x60]
101178dcc:	42 c0 65 1e	frintz	d2, d2
101178dd0:	21 19 61 1e	fdiv	d1, d9, d1
101178dd4:	03 a0 41 1f	fmsub	d3, d0, d1, d8
101178dd8:	63 28 62 1e	fadd	d3, d3, d2
101178ddc:	6a 00 78 1e	fcvtzs	w10, d3
101178de0:	6a 49 00 b9	str	w10, [x11, #0x48]
101178de4:	03 08 6b 1e	fmul	d3, d0, d11
101178de8:	63 20 41 1f	fmadd	d3, d3, d1, d8
101178dec:	63 28 62 1e	fadd	d3, d3, d2
101178df0:	6a 00 78 1e	fcvtzs	w10, d3
101178df4:	6a 31 00 b9	str	w10, [x11, #0x30]
101178df8:	00 08 6c 1e	fmul	d0, d0, d12
101178dfc:	00 20 41 1f	fmadd	d0, d0, d1, d8
101178e00:	00 28 62 1e	fadd	d0, d0, d2
101178e04:	0a 00 78 1e	fcvtzs	w10, d0
101178e08:	6a 19 00 b9	str	w10, [x11, #0x18]
101178e0c:	3f 11 00 71	cmp	w9, #0x4
101178e10:	e0 02 00 54	b.eq	0x101178e6c
101178e14:	3f 0d 00 71	cmp	w9, #0x3
101178e18:	81 2a 00 54	b.ne	0x101179368
101178e1c:	49 78 76 b8	ldr	w9, [x2, x22, lsl #2]
101178e20:	3f 11 00 71	cmp	w9, #0x4
101178e24:	80 0e 00 54	b.eq	0x101178ff4
101178e28:	3f 0d 00 71	cmp	w9, #0x3
101178e2c:	e1 29 00 54	b.ne	0x101179368
101178e30:	ab 7a 79 b8	ldr	w11, [x21, x25, lsl #2]
101178e34:	6a 11 00 11	add	w10, w11, #0x4
101178e38:	a9 7a b6 b8	ldrsw	x9, [x21, x22, lsl #2]
101178e3c:	2c 05 00 51	sub	w12, w9, #0x1
101178e40:	5f 01 0c 6b	cmp	w10, w12
101178e44:	aa 19 00 54	b.ge	0x101179178
101178e48:	4e 7d 40 93	sxtw	x14, w10
101178e4c:	4a 7d 24 9b	smull	x10, w10, w4
101178e50:	0a 69 6a b8	ldr	w10, [x8, x10]
101178e54:	2b 01 0b 4b	sub	w11, w9, w11
101178e58:	6b 19 00 51	sub	w11, w11, #0x6
101178e5c:	7f 0d 00 71	cmp	w11, #0x3
101178e60:	a2 12 00 54	b.hs	0x1011790b4
101178e64:	eb 03 0e aa	mov	x11, x14
101178e68:	b6 00 00 14	b	0x101179140
101178e6c:	49 78 76 b8	ldr	w9, [x2, x22, lsl #2]
101178e70:	3f 0d 00 71	cmp	w9, #0x3
101178e74:	c0 0d 00 54	b.eq	0x10117902c
101178e78:	3f 11 00 71	cmp	w9, #0x4
101178e7c:	61 27 00 54	b.ne	0x101179368
101178e80:	ab 7a b6 b8	ldrsw	x11, [x21, x22, lsl #2]
101178e84:	a9 7a b9 b8	ldrsw	x9, [x21, x25, lsl #2]
101178e88:	2a 11 00 91	add	x10, x9, #0x4
101178e8c:	7f 01 0a 6b	cmp	w11, w10
101178e90:	0d 02 00 54	b.le	0x101178ed0
101178e94:	4a 7d 40 93	sxtw	x10, w10
101178e98:	6d 21 04 9b	madd	x13, x11, x4, x8
101178e9c:	ae 01 40 b9	ldr	w14, [x13]
101178ea0:	ec 03 0d aa	mov	x12, x13
101178ea4:	6b 05 00 d1	sub	x11, x11, #0x1
101178ea8:	8f 8d 5e b8	ldr	w15, [x12, #-0x18]!
101178eac:	ee 01 0e 0b	add	w14, w15, w14
101178eb0:	c0 01 62 1e	scvtf	d0, w14
101178eb4:	00 20 48 1f	fmadd	d0, d0, d8, d8
101178eb8:	0e 00 78 1e	fcvtzs	w14, d0
101178ebc:	ae 01 00 b9	str	w14, [x13]
101178ec0:	ed 03 0c aa	mov	x13, x12
101178ec4:	ee 03 0f aa	mov	x14, x15
101178ec8:	7f 01 0a eb	cmp	x11, x10
101178ecc:	cc fe ff 54	b.gt	0x101178ea4
101178ed0:	4a 7d 04 9b	mul	x10, x10, x4
101178ed4:	0b 69 6a b8	ldr	w11, [x8, x10]
101178ed8:	29 21 04 9b	madd	x9, x9, x4, x8
101178edc:	29 49 40 b9	ldr	w9, [x9, #0x48]
101178ee0:	69 01 09 4b	sub	w9, w11, w9
101178ee4:	20 01 62 1e	scvtf	d0, w9
101178ee8:	e9 f3 00 b2	mov	x9, #0x5555555555555555
101178eec:	a9 fa e7 f2	movk	x9, #0x3fd5, lsl #48
101178ef0:	21 01 67 9e	fmov	d1, x9
101178ef4:	00 20 41 1f	fmadd	d0, d0, d1, d8
101178ef8:	09 00 78 1e	fcvtzs	w9, d0
101178efc:	69 01 09 4b	sub	w9, w11, w9
101178f00:	09 69 2a b8	str	w9, [x8, x10]
101178f04:	ff 3f 09 f9	str	xzr, [sp, #0x1278]
101178f08:	ff 3b 09 f9	str	xzr, [sp, #0x1270]
101178f0c:	09 00 80 12	mov	w9, #-0x1
101178f10:	e9 83 12 b9	str	w9, [sp, #0x1280]
101178f14:	e9 83 0d 91	add	x9, sp, #0x360
101178f18:	3f 91 3c 39	strb	wzr, [x9, #0xf24]
101178f1c:	a9 7a b6 b8	ldrsw	x9, [x21, x22, lsl #2]
101178f20:	29 7d 04 9b	mul	x9, x9, x4
101178f24:	01 01 09 8b	add	x1, x8, x9
101178f28:	2a 8c 41 b8	ldr	w10, [x1, #0x18]!
101178f2c:	08 69 69 b8	ldr	w8, [x8, x9]
101178f30:	08 01 0a 0b	add	w8, w8, w10
101178f34:	00 01 62 1e	scvtf	d0, w8
101178f38:	00 20 48 1f	fmadd	d0, d0, d8, d8
101178f3c:	08 00 78 1e	fcvtzs	w8, d0
101178f40:	e8 73 12 b9	str	w8, [sp, #0x1270]
101178f44:	ff 7b 12 b9	str	wzr, [sp, #0x1278]
101178f48:	e2 07 40 91	add	x2, sp, #0x1, lsl #12
101178f4c:	42 c0 09 91	add	x2, x2, #0x270
101178f50:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
101178f54:	b1 18 ff 97	bl	__ZNSt3__16vectorIN16BeatAnalyzer_2_06peakss8BeatInfoENS_9allocatorIS3_EEE6insertENS_11__wrap_iterIPKS3_EERS8_
101178f58:	e3 a3 40 f9	ldr	x3, [sp, #0x140]
101178f5c:	e2 07 40 91	add	x2, sp, #0x1, lsl #12
101178f60:	42 c0 11 91	add	x2, x2, #0x470
101178f64:	e6 e7 07 6f	movi.2d	v6, #0xffffffffffffffff
101178f68:	eb af 40 f9	ldr	x11, [sp, #0x158]
101178f6c:	68 01 19 cb	sub	x8, x11, x25
101178f70:	1f 0d 00 f1	cmp	x8, #0x3
101178f74:	24 04 00 4f	movi.4s	v4, #0x1
101178f78:	ab 03 00 54	b.lt	0x101178fec
101178f7c:	28 0b 00 91	add	x8, x25, #0x2
101178f80:	1f 01 0b eb	cmp	x8, x11
101178f84:	42 03 00 54	b.hs	0x101178fec
101178f88:	e8 03 1b aa	mov	x8, x27
101178f8c:	5f 43 00 f1	cmp	x26, #0x10
101178f90:	03 02 00 54	b.lo	0x101178fd0
101178f94:	49 ef 7c 92	and	x9, x26, #0xfffffffffffffff0
101178f98:	68 03 09 8b	add	x8, x27, x9
101178f9c:	ea 03 1c aa	mov	x10, x28
101178fa0:	40 05 7f ad	ldp	q0, q1, [x10, #-0x20]
101178fa4:	42 0d 40 ad	ldp	q2, q3, [x10]
101178fa8:	00 84 a4 4e	add.4s	v0, v0, v4
101178fac:	21 84 a4 4e	add.4s	v1, v1, v4
101178fb0:	42 84 a4 4e	add.4s	v2, v2, v4
101178fb4:	63 84 a4 4e	add.4s	v3, v3, v4
101178fb8:	40 05 3f ad	stp	q0, q1, [x10, #-0x20]
101178fbc:	42 0d 82 ac	stp	q2, q3, [x10], #0x40
101178fc0:	73 42 00 f1	subs	x19, x19, #0x10
101178fc4:	e1 fe ff 54	b.ne	0x101178fa0
101178fc8:	5f 03 09 eb	cmp	x26, x9
101178fcc:	00 01 00 54	b.eq	0x101178fec
101178fd0:	a9 0a 08 8b	add	x9, x21, x8, lsl #2
101178fd4:	68 01 08 cb	sub	x8, x11, x8
101178fd8:	2a 01 40 b9	ldr	w10, [x9]
101178fdc:	4a 05 00 11	add	w10, w10, #0x1
101178fe0:	2a 45 00 b8	str	w10, [x9], #0x4
101178fe4:	08 05 00 f1	subs	x8, x8, #0x1
101178fe8:	81 ff ff 54	b.ne	0x101178fd8
101178fec:	04 03 80 52	mov	w4, #0x18
101178ff0:	de 00 00 14	b	0x101179368
101178ff4:	ab 7a 79 b8	ldr	w11, [x21, x25, lsl #2]
101178ff8:	6a 11 00 11	add	w10, w11, #0x4
101178ffc:	a9 7a b6 b8	ldrsw	x9, [x21, x22, lsl #2]
101179000:	5f 01 09 6b	cmp	w10, w9
101179004:	8a 19 00 54	b.ge	0x101179334
101179008:	4e 7d 40 93	sxtw	x14, w10
10117900c:	4a 7d 24 9b	smull	x10, w10, w4
101179010:	0a 69 6a b8	ldr	w10, [x8, x10]
101179014:	2b 01 0b 4b	sub	w11, w9, w11
101179018:	6b 15 00 51	sub	w11, w11, #0x5
10117901c:	7f 0d 00 71	cmp	w11, #0x3
101179020:	a2 12 00 54	b.hs	0x101179274
101179024:	eb 03 0e aa	mov	x11, x14
101179028:	b6 00 00 14	b	0x101179300
10117902c:	ab 7a b6 b8	ldrsw	x11, [x21, x22, lsl #2]
101179030:	a9 7a b9 b8	ldrsw	x9, [x21, x25, lsl #2]
101179034:	2a 11 00 91	add	x10, x9, #0x4
101179038:	7f 01 0a 6b	cmp	w11, w10
10117903c:	0d 02 00 54	b.le	0x10117907c
101179040:	4a 7d 40 93	sxtw	x10, w10
101179044:	6d 21 04 9b	madd	x13, x11, x4, x8
101179048:	ae 01 40 b9	ldr	w14, [x13]
10117904c:	ec 03 0d aa	mov	x12, x13
101179050:	6b 05 00 d1	sub	x11, x11, #0x1
101179054:	8f 8d 5e b8	ldr	w15, [x12, #-0x18]!
101179058:	ee 01 0e 0b	add	w14, w15, w14
10117905c:	c0 01 62 1e	scvtf	d0, w14
101179060:	00 20 48 1f	fmadd	d0, d0, d8, d8
101179064:	0e 00 78 1e	fcvtzs	w14, d0
101179068:	ae 01 00 b9	str	w14, [x13]
10117906c:	ed 03 0c aa	mov	x13, x12
101179070:	ee 03 0f aa	mov	x14, x15
101179074:	7f 01 0a eb	cmp	x11, x10
101179078:	cc fe ff 54	b.gt	0x101179050
10117907c:	4a 7d 04 9b	mul	x10, x10, x4
101179080:	0b 69 6a b8	ldr	w11, [x8, x10]
101179084:	29 21 04 9b	madd	x9, x9, x4, x8
101179088:	29 49 40 b9	ldr	w9, [x9, #0x48]
10117908c:	69 01 09 4b	sub	w9, w11, w9
101179090:	20 01 62 1e	scvtf	d0, w9
101179094:	e9 f3 00 b2	mov	x9, #0x5555555555555555
101179098:	a9 fa e7 f2	movk	x9, #0x3fd5, lsl #48
10117909c:	21 01 67 9e	fmov	d1, x9
1011790a0:	00 20 41 1f	fmadd	d0, d0, d1, d8
1011790a4:	09 00 78 1e	fcvtzs	w9, d0
1011790a8:	69 01 09 4b	sub	w9, w11, w9
1011790ac:	09 69 2a b8	str	w9, [x8, x10]
1011790b0:	ae 00 00 14	b	0x101179368
1011790b4:	6c 05 00 91	add	x12, x11, #0x1
1011790b8:	8d 79 7e 92	and	x13, x12, #0x1fffffffc
1011790bc:	ab 01 0e 8b	add	x11, x13, x14
1011790c0:	ce 21 04 9b	madd	x14, x14, x4, x8
1011790c4:	ce c1 00 91	add	x14, x14, #0x30
1011790c8:	ef 03 0d aa	mov	x15, x13
1011790cc:	d0 81 5e b8	ldur	w16, [x14, #-0x18]
1011790d0:	d1 01 40 b9	ldr	w17, [x14]
1011790d4:	c0 19 40 b9	ldr	w0, [x14, #0x18]
1011790d8:	41 01 10 0b	add	w1, w10, w16
1011790dc:	ca 31 40 b9	ldr	w10, [x14, #0x30]
1011790e0:	10 02 11 0b	add	w16, w16, w17
1011790e4:	31 02 00 0b	add	w17, w17, w0
1011790e8:	00 00 0a 0b	add	w0, w0, w10
1011790ec:	20 00 62 1e	scvtf	d0, w1
1011790f0:	01 02 62 1e	scvtf	d1, w16
1011790f4:	22 02 62 1e	scvtf	d2, w17
1011790f8:	03 00 62 1e	scvtf	d3, w0
1011790fc:	00 20 48 1f	fmadd	d0, d0, d8, d8
101179100:	21 20 48 1f	fmadd	d1, d1, d8, d8
101179104:	42 20 48 1f	fmadd	d2, d2, d8, d8
101179108:	63 20 48 1f	fmadd	d3, d3, d8, d8
10117910c:	10 00 78 1e	fcvtzs	w16, d0
101179110:	31 00 78 1e	fcvtzs	w17, d1
101179114:	40 00 78 1e	fcvtzs	w0, d2
101179118:	61 00 78 1e	fcvtzs	w1, d3
10117911c:	d0 01 1d b8	stur	w16, [x14, #-0x30]
101179120:	d1 81 1e b8	stur	w17, [x14, #-0x18]
101179124:	c0 01 00 b9	str	w0, [x14]
101179128:	c1 19 00 b9	str	w1, [x14, #0x18]
10117912c:	ce 81 01 91	add	x14, x14, #0x60
101179130:	ef 11 00 f1	subs	x15, x15, #0x4
101179134:	c1 fc ff 54	b.ne	0x1011790cc
101179138:	9f 01 0d eb	cmp	x12, x13
10117913c:	e0 01 00 54	b.eq	0x101179178
101179140:	6d 21 04 9b	madd	x13, x11, x4, x8
101179144:	eb 03 2b 2a	mvn	w11, w11
101179148:	6b 01 09 0b	add	w11, w11, w9
10117914c:	ec 03 0d aa	mov	x12, x13
101179150:	8e 8d 41 b8	ldr	w14, [x12, #0x18]!
101179154:	4a 01 0e 0b	add	w10, w10, w14
101179158:	40 01 62 1e	scvtf	d0, w10
10117915c:	00 20 48 1f	fmadd	d0, d0, d8, d8
101179160:	0a 00 78 1e	fcvtzs	w10, d0
101179164:	aa 01 00 b9	str	w10, [x13]
101179168:	ed 03 0c aa	mov	x13, x12
10117916c:	ea 03 0e aa	mov	x10, x14
101179170:	6b 05 00 71	subs	w11, w11, #0x1
101179174:	e1 fe ff 54	b.ne	0x101179150
101179178:	20 21 04 9b	madd	x0, x9, x4, x8
10117917c:	01 60 00 91	add	x1, x0, #0x18
101179180:	f8 9b 40 f9	ldr	x24, [sp, #0x130]
101179184:	15 03 40 f9	ldr	x21, [x24]
101179188:	a2 02 01 cb	sub	x2, x21, x1
10117918c:	30 65 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
101179190:	04 03 80 52	mov	w4, #0x18
101179194:	a8 62 00 d1	sub	x8, x21, #0x18
101179198:	08 03 00 f9	str	x8, [x24]
10117919c:	f5 07 40 91	add	x21, sp, #0x1, lsl #12
1011791a0:	b5 c2 19 91	add	x21, x21, #0x670
1011791a4:	a8 7a b6 b8	ldrsw	x8, [x21, x22, lsl #2]
1011791a8:	eb a7 55 a9	ldp	x11, x9, [sp, #0x158]
1011791ac:	29 01 40 f9	ldr	x9, [x9]
1011791b0:	08 25 04 9b	madd	x8, x8, x4, x9
1011791b4:	09 01 40 b9	ldr	w9, [x8]
1011791b8:	0a 81 5e b8	ldur	w10, [x8, #-0x18]
1011791bc:	29 01 0a 4b	sub	w9, w9, w10
1011791c0:	20 01 62 1e	scvtf	d0, w9
1011791c4:	e9 f3 00 b2	mov	x9, #0x5555555555555555
1011791c8:	a9 fa e7 f2	movk	x9, #0x3fd5, lsl #48
1011791cc:	21 01 67 9e	fmov	d1, x9
1011791d0:	00 20 41 1f	fmadd	d0, d0, d1, d8
1011791d4:	09 00 78 1e	fcvtzs	w9, d0
1011791d8:	49 01 09 0b	add	w9, w10, w9
1011791dc:	09 81 1e b8	stur	w9, [x8, #-0x18]
1011791e0:	68 01 19 cb	sub	x8, x11, x25
1011791e4:	1f 0d 00 f1	cmp	x8, #0x3
1011791e8:	e6 e7 07 6f	movi.2d	v6, #0xffffffffffffffff
1011791ec:	e2 07 40 91	add	x2, sp, #0x1, lsl #12
1011791f0:	42 c0 11 91	add	x2, x2, #0x470
1011791f4:	f8 8b 40 f9	ldr	x24, [sp, #0x110]
1011791f8:	e3 a3 40 f9	ldr	x3, [sp, #0x140]
1011791fc:	6b 0b 00 54	b.lt	0x101179368
101179200:	28 0b 00 91	add	x8, x25, #0x2
101179204:	1f 01 0b eb	cmp	x8, x11
101179208:	02 0b 00 54	b.hs	0x101179368
10117920c:	e8 03 1b aa	mov	x8, x27
101179210:	5f 43 00 f1	cmp	x26, #0x10
101179214:	03 02 00 54	b.lo	0x101179254
101179218:	49 ef 7c 92	and	x9, x26, #0xfffffffffffffff0
10117921c:	68 03 09 8b	add	x8, x27, x9
101179220:	ea 03 1c aa	mov	x10, x28
101179224:	40 05 7f ad	ldp	q0, q1, [x10, #-0x20]
101179228:	42 0d 40 ad	ldp	q2, q3, [x10]
10117922c:	00 84 a6 4e	add.4s	v0, v0, v6
101179230:	21 84 a6 4e	add.4s	v1, v1, v6
101179234:	42 84 a6 4e	add.4s	v2, v2, v6
101179238:	63 84 a6 4e	add.4s	v3, v3, v6
10117923c:	40 05 3f ad	stp	q0, q1, [x10, #-0x20]
101179240:	42 0d 82 ac	stp	q2, q3, [x10], #0x40
101179244:	73 42 00 f1	subs	x19, x19, #0x10
101179248:	e1 fe ff 54	b.ne	0x101179224
10117924c:	5f 03 09 eb	cmp	x26, x9
101179250:	c0 08 00 54	b.eq	0x101179368
101179254:	a9 0a 08 8b	add	x9, x21, x8, lsl #2
101179258:	68 01 08 cb	sub	x8, x11, x8
10117925c:	2a 01 40 b9	ldr	w10, [x9]
101179260:	4a 05 00 51	sub	w10, w10, #0x1
101179264:	2a 45 00 b8	str	w10, [x9], #0x4
101179268:	08 05 00 f1	subs	x8, x8, #0x1
10117926c:	81 ff ff 54	b.ne	0x10117925c
101179270:	3e 00 00 14	b	0x101179368
101179274:	6c 05 00 91	add	x12, x11, #0x1
101179278:	8d 79 7e 92	and	x13, x12, #0x1fffffffc
10117927c:	ab 01 0e 8b	add	x11, x13, x14
101179280:	ce 21 04 9b	madd	x14, x14, x4, x8
101179284:	ce c1 00 91	add	x14, x14, #0x30
101179288:	ef 03 0d aa	mov	x15, x13
10117928c:	d0 81 5e b8	ldur	w16, [x14, #-0x18]
101179290:	d1 01 40 b9	ldr	w17, [x14]
101179294:	c0 19 40 b9	ldr	w0, [x14, #0x18]
101179298:	41 01 10 0b	add	w1, w10, w16
10117929c:	ca 31 40 b9	ldr	w10, [x14, #0x30]
1011792a0:	10 02 11 0b	add	w16, w16, w17
1011792a4:	31 02 00 0b	add	w17, w17, w0
1011792a8:	00 00 0a 0b	add	w0, w0, w10
1011792ac:	20 00 62 1e	scvtf	d0, w1
1011792b0:	01 02 62 1e	scvtf	d1, w16
1011792b4:	22 02 62 1e	scvtf	d2, w17
1011792b8:	03 00 62 1e	scvtf	d3, w0
1011792bc:	00 20 48 1f	fmadd	d0, d0, d8, d8
1011792c0:	21 20 48 1f	fmadd	d1, d1, d8, d8
1011792c4:	42 20 48 1f	fmadd	d2, d2, d8, d8
1011792c8:	63 20 48 1f	fmadd	d3, d3, d8, d8
1011792cc:	10 00 78 1e	fcvtzs	w16, d0
1011792d0:	31 00 78 1e	fcvtzs	w17, d1
1011792d4:	40 00 78 1e	fcvtzs	w0, d2
1011792d8:	61 00 78 1e	fcvtzs	w1, d3
1011792dc:	d0 01 1d b8	stur	w16, [x14, #-0x30]
1011792e0:	d1 81 1e b8	stur	w17, [x14, #-0x18]
1011792e4:	c0 01 00 b9	str	w0, [x14]
1011792e8:	c1 19 00 b9	str	w1, [x14, #0x18]
1011792ec:	ce 81 01 91	add	x14, x14, #0x60
1011792f0:	ef 11 00 f1	subs	x15, x15, #0x4
1011792f4:	c1 fc ff 54	b.ne	0x10117928c
1011792f8:	9f 01 0d eb	cmp	x12, x13
1011792fc:	c0 01 00 54	b.eq	0x101179334
101179300:	6d 21 04 9b	madd	x13, x11, x4, x8
101179304:	2b 01 0b 4b	sub	w11, w9, w11
101179308:	ec 03 0d aa	mov	x12, x13
10117930c:	8e 8d 41 b8	ldr	w14, [x12, #0x18]!
101179310:	4a 01 0e 0b	add	w10, w10, w14
101179314:	40 01 62 1e	scvtf	d0, w10
101179318:	00 20 48 1f	fmadd	d0, d0, d8, d8
10117931c:	0a 00 78 1e	fcvtzs	w10, d0
101179320:	aa 01 00 b9	str	w10, [x13]
101179324:	ed 03 0c aa	mov	x13, x12
101179328:	ea 03 0e aa	mov	x10, x14
10117932c:	6b 05 00 71	subs	w11, w11, #0x1
101179330:	e1 fe ff 54	b.ne	0x10117930c
101179334:	29 7d 04 9b	mul	x9, x9, x4
101179338:	28 01 08 8b	add	x8, x9, x8
10117933c:	09 19 40 b9	ldr	w9, [x8, #0x18]
101179340:	0a 01 40 b9	ldr	w10, [x8]
101179344:	29 01 0a 4b	sub	w9, w9, w10
101179348:	20 01 62 1e	scvtf	d0, w9
10117934c:	e9 f3 00 b2	mov	x9, #0x5555555555555555
101179350:	a9 fa e7 f2	movk	x9, #0x3fd5, lsl #48
101179354:	21 01 67 9e	fmov	d1, x9
101179358:	00 20 41 1f	fmadd	d0, d0, d1, d8
10117935c:	09 00 78 1e	fcvtzs	w9, d0
101179360:	49 01 09 0b	add	w9, w10, w9
101179364:	09 01 00 b9	str	w9, [x8]
101179368:	f7 06 00 91	add	x23, x23, #0x1
10117936c:	ff 02 18 eb	cmp	x23, x24
101179370:	e0 00 00 54	b.eq	0x10117938c
101179374:	7b 0b 00 91	add	x27, x27, #0x2
101179378:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
10117937c:	08 01 40 f9	ldr	x8, [x8]
101179380:	94 0a 00 d1	sub	x20, x20, #0x2
101179384:	9c 23 00 91	add	x28, x28, #0x8
101179388:	5f fe ff 17	b	0x101178d04
10117938c:	fc e7 52 a9	ldp	x28, x25, [sp, #0x128]
101179390:	2a 03 40 f9	ldr	x10, [x25]
101179394:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
101179398:	08 01 40 f9	ldr	x8, [x8]
10117939c:	49 01 08 cb	sub	x9, x10, x8
1011793a0:	29 fd 43 93	asr	x9, x9, #3
1011793a4:	eb f3 01 b2	mov	x11, #-0x5555555555555556
1011793a8:	6b 55 95 f2	movk	x11, #0xaaab
1011793ac:	29 7d 0b 9b	mul	x9, x9, x11
1011793b0:	fb 9f 40 f9	ldr	x27, [sp, #0x138]
1011793b4:	f3 23 41 b9	ldr	w19, [sp, #0x120]
1011793b8:	e5 87 40 f9	ldr	x5, [sp, #0x108]
1011793bc:	ab 04 01 12	and	w11, w5, #0x80000001
1011793c0:	7f 05 00 71	cmp	w11, #0x1
1011793c4:	61 a0 ff 54	b.ne	0x1011787d0
1011793c8:	ab 04 00 51	sub	w11, w5, #0x1
1011793cc:	6c f5 7e d3	lsl	x12, x11, #2
1011793d0:	ad 6a ac b8	ldrsw	x13, [x21, x12]
1011793d4:	ad 21 04 9b	madd	x13, x13, x4, x8
1011793d8:	ae 61 40 b9	ldr	w14, [x13, #0x60]
1011793dc:	af 01 40 b9	ldr	w15, [x13]
1011793e0:	ce 01 0f 4b	sub	w14, w14, w15
1011793e4:	c0 01 62 1e	scvtf	d0, w14
1011793e8:	ee 07 40 91	add	x14, sp, #0x1, lsl #12
1011793ec:	ce c1 11 91	add	x14, x14, #0x470
1011793f0:	cc 69 6c b8	ldr	w12, [x14, x12]
1011793f4:	81 01 62 1e	scvtf	d1, w12
1011793f8:	21 28 68 1e	fadd	d1, d1, d8
1011793fc:	e2 01 62 1e	scvtf	d2, w15
101179400:	42 28 68 1e	fadd	d2, d2, d8
101179404:	4e 00 78 1e	fcvtzs	w14, d2
101179408:	ae 01 00 b9	str	w14, [x13]
10117940c:	42 c0 65 1e	frintz	d2, d2
101179410:	21 19 61 1e	fdiv	d1, d9, d1
101179414:	03 20 41 1f	fmadd	d3, d0, d1, d8
101179418:	63 28 62 1e	fadd	d3, d3, d2
10117941c:	6e 00 78 1e	fcvtzs	w14, d3
101179420:	ae 19 00 b9	str	w14, [x13, #0x18]
101179424:	23 28 61 1e	fadd	d3, d1, d1
101179428:	03 20 43 1f	fmadd	d3, d0, d3, d8
10117942c:	63 28 62 1e	fadd	d3, d3, d2
101179430:	6e 00 78 1e	fcvtzs	w14, d3
101179434:	ae 31 00 b9	str	w14, [x13, #0x30]
101179438:	00 08 6a 1e	fmul	d0, d0, d10
10117943c:	00 20 41 1f	fmadd	d0, d0, d1, d8
101179440:	00 28 62 1e	fadd	d0, d0, d2
101179444:	0e 00 78 1e	fcvtzs	w14, d0
101179448:	ae 49 00 b9	str	w14, [x13, #0x48]
10117944c:	9f 11 00 71	cmp	w12, #0x4
101179450:	20 02 00 54	b.eq	0x101179494
101179454:	9f 0d 00 71	cmp	w12, #0x3
101179458:	c1 9b ff 54	b.ne	0x1011787d0
10117945c:	ad 7a 6b b8	ldr	w13, [x21, x11, lsl #2]
101179460:	ac 11 00 11	add	w12, w13, #0x4
101179464:	2b 05 00 51	sub	w11, w9, #0x1
101179468:	9f 01 0b 6b	cmp	w12, w11
10117946c:	ea 0e 00 54	b.ge	0x101179648
101179470:	90 7d 40 93	sxtw	x16, w12
101179474:	8c 7d 24 9b	smull	x12, w12, w4
101179478:	0c 69 6c b8	ldr	w12, [x8, x12]
10117947c:	2d 01 0d 4b	sub	w13, w9, w13
101179480:	ad 19 00 51	sub	w13, w13, #0x6
101179484:	bf 0d 00 71	cmp	w13, #0x3
101179488:	e2 07 00 54	b.hs	0x101179584
10117948c:	ed 03 10 aa	mov	x13, x16
101179490:	60 00 00 14	b	0x101179610
101179494:	2a 05 00 51	sub	w10, w9, #0x1
101179498:	ab 7a ab b8	ldrsw	x11, [x21, x11, lsl #2]
10117949c:	6c 11 00 91	add	x12, x11, #0x4
1011794a0:	5f 01 0c 6b	cmp	w10, w12
1011794a4:	2d 02 00 54	b.le	0x1011794e8
1011794a8:	4d 7d 40 93	sxtw	x13, w10
1011794ac:	8c 7d 40 93	sxtw	x12, w12
1011794b0:	4f 21 24 9b	smaddl	x15, w10, w4, x8
1011794b4:	f0 01 40 b9	ldr	w16, [x15]
1011794b8:	ee 03 0f aa	mov	x14, x15
1011794bc:	ad 05 00 d1	sub	x13, x13, #0x1
1011794c0:	d1 8d 5e b8	ldr	w17, [x14, #-0x18]!
1011794c4:	30 02 10 0b	add	w16, w17, w16
1011794c8:	00 02 62 1e	scvtf	d0, w16
1011794cc:	00 20 48 1f	fmadd	d0, d0, d8, d8
1011794d0:	10 00 78 1e	fcvtzs	w16, d0
1011794d4:	f0 01 00 b9	str	w16, [x15]
1011794d8:	ef 03 0e aa	mov	x15, x14
1011794dc:	f0 03 11 aa	mov	x16, x17
1011794e0:	bf 01 0c eb	cmp	x13, x12
1011794e4:	cc fe ff 54	b.gt	0x1011794bc
1011794e8:	8c 7d 04 9b	mul	x12, x12, x4
1011794ec:	0d 69 6c b8	ldr	w13, [x8, x12]
1011794f0:	6b 21 04 9b	madd	x11, x11, x4, x8
1011794f4:	6b 49 40 b9	ldr	w11, [x11, #0x48]
1011794f8:	ab 01 0b 4b	sub	w11, w13, w11
1011794fc:	60 01 62 1e	scvtf	d0, w11
101179500:	eb f3 00 b2	mov	x11, #0x5555555555555555
101179504:	ab fa e7 f2	movk	x11, #0x3fd5, lsl #48
101179508:	61 01 67 9e	fmov	d1, x11
10117950c:	00 20 41 1f	fmadd	d0, d0, d1, d8
101179510:	0b 00 78 1e	fcvtzs	w11, d0
101179514:	ab 01 0b 4b	sub	w11, w13, w11
101179518:	0b 69 2c b8	str	w11, [x8, x12]
10117951c:	3f 05 00 71	cmp	w9, #0x1
101179520:	8d 95 ff 54	b.le	0x1011787d0
101179524:	4a 7d a4 9b	umull	x10, w10, w4
101179528:	0a 69 6a b8	ldr	w10, [x8, x10]
10117952c:	29 09 00 51	sub	w9, w9, #0x2
101179530:	29 7d 24 9b	smull	x9, w9, w4
101179534:	08 69 69 b8	ldr	w8, [x8, x9]
101179538:	48 01 08 4b	sub	w8, w10, w8
10117953c:	08 01 0a 0b	add	w8, w8, w10
101179540:	89 1f 40 b9	ldr	w9, [x28, #0x1c]
101179544:	1f 01 09 6b	cmp	w8, w9
101179548:	4c 94 ff 54	b.gt	0x1011787d0
10117954c:	e9 07 40 91	add	x9, sp, #0x1, lsl #12
101179550:	29 c1 09 91	add	x9, x9, #0x270
101179554:	3f 41 00 f8	stur	xzr, [x9, #0x4]
101179558:	3f 51 00 39	strb	wzr, [x9, #0x14]
10117955c:	e8 73 12 b9	str	w8, [sp, #0x1270]
101179560:	e8 7f 60 b2	mov	x8, #-0x100000000
101179564:	28 c1 00 f8	stur	x8, [x9, #0xc]
101179568:	e1 07 40 91	add	x1, sp, #0x1, lsl #12
10117956c:	21 c0 09 91	add	x1, x1, #0x270
101179570:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
101179574:	d7 21 00 94	bl	__ZNSt3__16vectorIN16BeatAnalyzer_2_06peakss8BeatInfoENS_9allocatorIS3_EEE9push_backB6v15006ERKS3_
101179578:	e6 e7 07 6f	movi.2d	v6, #0xffffffffffffffff
10117957c:	04 03 80 52	mov	w4, #0x18
101179580:	94 fc ff 17	b	0x1011787d0
101179584:	ae 05 00 91	add	x14, x13, #0x1
101179588:	cf 79 7e 92	and	x15, x14, #0x1fffffffc
10117958c:	ed 01 10 8b	add	x13, x15, x16
101179590:	10 22 04 9b	madd	x16, x16, x4, x8
101179594:	10 c2 00 91	add	x16, x16, #0x30
101179598:	f1 03 0f aa	mov	x17, x15
10117959c:	00 82 5e b8	ldur	w0, [x16, #-0x18]
1011795a0:	01 02 40 b9	ldr	w1, [x16]
1011795a4:	02 1a 40 b9	ldr	w2, [x16, #0x18]
1011795a8:	83 01 00 0b	add	w3, w12, w0
1011795ac:	0c 32 40 b9	ldr	w12, [x16, #0x30]
1011795b0:	00 00 01 0b	add	w0, w0, w1
1011795b4:	21 00 02 0b	add	w1, w1, w2
1011795b8:	42 00 0c 0b	add	w2, w2, w12
1011795bc:	60 00 62 1e	scvtf	d0, w3
1011795c0:	01 00 62 1e	scvtf	d1, w0
1011795c4:	22 00 62 1e	scvtf	d2, w1
1011795c8:	43 00 62 1e	scvtf	d3, w2
1011795cc:	00 20 48 1f	fmadd	d0, d0, d8, d8
1011795d0:	21 20 48 1f	fmadd	d1, d1, d8, d8
1011795d4:	42 20 48 1f	fmadd	d2, d2, d8, d8
1011795d8:	63 20 48 1f	fmadd	d3, d3, d8, d8
1011795dc:	00 00 78 1e	fcvtzs	w0, d0
1011795e0:	21 00 78 1e	fcvtzs	w1, d1
1011795e4:	42 00 78 1e	fcvtzs	w2, d2
1011795e8:	63 00 78 1e	fcvtzs	w3, d3
1011795ec:	00 02 1d b8	stur	w0, [x16, #-0x30]
1011795f0:	01 82 1e b8	stur	w1, [x16, #-0x18]
1011795f4:	02 02 00 b9	str	w2, [x16]
1011795f8:	03 1a 00 b9	str	w3, [x16, #0x18]
1011795fc:	10 82 01 91	add	x16, x16, #0x60
101179600:	31 12 00 f1	subs	x17, x17, #0x4
101179604:	c1 fc ff 54	b.ne	0x10117959c
101179608:	df 01 0f eb	cmp	x14, x15
10117960c:	e0 01 00 54	b.eq	0x101179648
101179610:	af 21 04 9b	madd	x15, x13, x4, x8
101179614:	ed 03 2d 2a	mvn	w13, w13
101179618:	ad 01 09 0b	add	w13, w13, w9
10117961c:	ee 03 0f aa	mov	x14, x15
101179620:	d0 8d 41 b8	ldr	w16, [x14, #0x18]!
101179624:	8c 01 10 0b	add	w12, w12, w16
101179628:	80 01 62 1e	scvtf	d0, w12
10117962c:	00 20 48 1f	fmadd	d0, d0, d8, d8
101179630:	0c 00 78 1e	fcvtzs	w12, d0
101179634:	ec 01 00 b9	str	w12, [x15]
101179638:	ef 03 0e aa	mov	x15, x14
10117963c:	ec 03 10 aa	mov	x12, x16
101179640:	ad 05 00 71	subs	w13, w13, #0x1
101179644:	e1 fe ff 54	b.ne	0x101179620
101179648:	3f 05 00 71	cmp	w9, #0x1
10117964c:	2d 8c ff 54	b.le	0x1011787d0
101179650:	6b 21 a4 9b	umaddl	x11, w11, w4, x8
101179654:	6c 01 40 b9	ldr	w12, [x11]
101179658:	29 09 00 51	sub	w9, w9, #0x2
10117965c:	29 7d 24 9b	smull	x9, w9, w4
101179660:	08 69 69 b8	ldr	w8, [x8, x9]
101179664:	88 01 08 4b	sub	w8, w12, w8
101179668:	08 01 0c 0b	add	w8, w8, w12
10117966c:	89 1f 40 b9	ldr	w9, [x28, #0x1c]
101179670:	1f 01 09 6b	cmp	w8, w9
101179674:	8d 00 00 54	b.le	0x101179684
101179678:	48 61 00 d1	sub	x8, x10, #0x18
10117967c:	28 03 00 f9	str	x8, [x25]
101179680:	54 fc ff 17	b	0x1011787d0
101179684:	68 01 00 b9	str	w8, [x11]
101179688:	52 fc ff 17	b	0x1011787d0
10117968c:	88 27 47 a9	ldp	x8, x9, [x28, #0x70]
101179690:	29 01 08 cb	sub	x9, x9, x8
101179694:	29 fd 43 93	asr	x9, x9, #3
101179698:	ea f3 01 b2	mov	x10, #-0x5555555555555556
10117969c:	6a 55 95 f2	movk	x10, #0xaaab
1011796a0:	33 7d 0a 9b	mul	x19, x9, x10
1011796a4:	ff 3f 0b f9	str	xzr, [sp, #0x1678]
1011796a8:	ff 3b 0b f9	str	xzr, [sp, #0x1670]
1011796ac:	ff 43 0b f9	str	xzr, [sp, #0x1680]
1011796b0:	7f 0a 00 71	cmp	w19, #0x2
1011796b4:	4b 0f 00 54	b.lt	0x10117989c
1011796b8:	18 00 80 d2	mov	x24, #0x0
1011796bc:	77 06 00 51	sub	w23, w19, #0x1
1011796c0:	19 4e a8 52	mov	w25, #0x42700000
1011796c4:	fc 03 17 aa	mov	x28, x23
1011796c8:	08 00 00 14	b	0x1011796e8
1011796cc:	28 45 00 bc	str	s8, [x9], #0x4
1011796d0:	e9 3f 0b f9	str	x9, [sp, #0x1678]
1011796d4:	e8 97 40 f9	ldr	x8, [sp, #0x128]
1011796d8:	08 39 40 f9	ldr	x8, [x8, #0x70]
1011796dc:	18 63 00 91	add	x24, x24, #0x18
1011796e0:	9c 07 00 f1	subs	x28, x28, #0x1
1011796e4:	a0 06 00 54	b.eq	0x1011797b8
1011796e8:	08 01 18 8b	add	x8, x8, x24
1011796ec:	09 19 40 b9	ldr	w9, [x8, #0x18]
1011796f0:	08 01 40 b9	ldr	w8, [x8]
1011796f4:	28 01 08 6b	subs	w8, w9, w8
1011796f8:	e0 fe ff 54	b.eq	0x1011796d4
1011796fc:	00 01 22 1e	scvtf	s0, w8
101179700:	61 03 40 bd	ldr	s1, [x27]
101179704:	21 d8 21 5e	scvtf	s1, s1
101179708:	22 03 27 1e	fmov	s2, w25
10117970c:	21 08 22 1e	fmul	s1, s1, s2
101179710:	28 18 20 1e	fdiv	s8, s1, s0
101179714:	e9 3f 4b f9	ldr	x9, [sp, #0x1678]
101179718:	e8 43 4b f9	ldr	x8, [sp, #0x1680]
10117971c:	3f 01 08 eb	cmp	x9, x8
101179720:	63 fd ff 54	b.lo	0x1011796cc
101179724:	f4 3b 4b f9	ldr	x20, [sp, #0x1670]
101179728:	35 01 14 cb	sub	x21, x9, x20
10117972c:	ba fe 42 93	asr	x26, x21, #2
101179730:	49 07 00 91	add	x9, x26, #0x1
101179734:	2a fd 7e d3	lsr	x10, x9, #62
101179738:	ca d3 03 b5	cbnz	x10, 0x1011811b0
10117973c:	08 01 14 cb	sub	x8, x8, x20
101179740:	0a fd 41 93	asr	x10, x8, #1
101179744:	5f 01 09 eb	cmp	x10, x9
101179748:	49 81 89 9a	csel	x9, x10, x9, hi
10117974c:	ea f3 7e b2	mov	x10, #0x7ffffffffffffffc
101179750:	1f 01 0a eb	cmp	x8, x10
101179754:	08 00 f8 92	mov	x8, #0x3fffffffffffffff
101179758:	3b 31 88 9a	csel	x27, x9, x8, lo
10117975c:	fb 00 00 b4	cbz	x27, 0x101179778
101179760:	68 ff 7e d3	lsr	x8, x27, #62
101179764:	28 d3 03 b5	cbnz	x8, 0x1011811c8
101179768:	60 f7 7e d3	lsl	x0, x27, #2
10117976c:	d9 60 8d 94	bl	0x1034d1ad0 ; symbol stub for: __Znwm
101179770:	f6 03 00 aa	mov	x22, x0
101179774:	02 00 00 14	b	0x10117977c
101179778:	16 00 80 d2	mov	x22, #0x0
10117977c:	da 0a 1a 8b	add	x26, x22, x26, lsl #2
101179780:	db 0a 1b 8b	add	x27, x22, x27, lsl #2
101179784:	48 47 00 bc	str	s8, [x26], #0x4
101179788:	e0 03 16 aa	mov	x0, x22
10117978c:	e1 03 14 aa	mov	x1, x20
101179790:	e2 03 15 aa	mov	x2, x21
101179794:	ae 63 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
101179798:	f6 3b 0b f9	str	x22, [sp, #0x1670]
10117979c:	fa 3f 0b f9	str	x26, [sp, #0x1678]
1011797a0:	fb 43 0b f9	str	x27, [sp, #0x1680]
1011797a4:	fb 9f 40 f9	ldr	x27, [sp, #0x138]
1011797a8:	74 f9 ff b4	cbz	x20, 0x1011796d4
1011797ac:	e0 03 14 aa	mov	x0, x20
1011797b0:	c2 60 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
1011797b4:	c8 ff ff 17	b	0x1011796d4
1011797b8:	09 03 80 52	mov	w9, #0x18
1011797bc:	ea 7e 09 9b	mul	x10, x23, x9
1011797c0:	0a 69 6a b8	ldr	w10, [x8, x10]
1011797c4:	74 7e 60 d3	lsl	x20, x19, #32
1011797c8:	eb 7b 5f b2	mov	x11, #-0x200000000
1011797cc:	8b 02 0b 8b	add	x11, x20, x11
1011797d0:	6b fd 60 93	asr	x11, x11, #32
1011797d4:	69 7d 09 9b	mul	x9, x11, x9
1011797d8:	08 69 69 b8	ldr	w8, [x8, x9]
1011797dc:	48 01 08 6b	subs	w8, w10, w8
1011797e0:	fc 97 40 f9	ldr	x28, [sp, #0x128]
1011797e4:	c0 01 00 54	b.eq	0x10117981c
1011797e8:	00 01 22 1e	scvtf	s0, w8
1011797ec:	61 03 40 bd	ldr	s1, [x27]
1011797f0:	21 d8 21 5e	scvtf	s1, s1
1011797f4:	08 4e a8 52	mov	w8, #0x42700000
1011797f8:	02 01 27 1e	fmov	s2, w8
1011797fc:	21 08 22 1e	fmul	s1, s1, s2
101179800:	20 18 20 1e	fdiv	s0, s1, s0
101179804:	e0 73 14 bd	str	s0, [sp, #0x1470]
101179808:	e0 07 40 91	add	x0, sp, #0x1, lsl #12
10117980c:	00 c0 19 91	add	x0, x0, #0x670
101179810:	e1 07 40 91	add	x1, sp, #0x1, lsl #12
101179814:	21 c0 11 91	add	x1, x1, #0x470
101179818:	e8 21 00 94	bl	__ZNSt3__16vectorIfNS_9allocatorIfEEE9push_backB6v15006EOf
10117981c:	0c 00 80 d2	mov	x12, #0x0
101179820:	e8 3b 4b f9	ldr	x8, [sp, #0x1670]
101179824:	89 fe 60 93	asr	x9, x20, #32
101179828:	6a 7e 40 92	and	x10, x19, #0xffffffff
10117982c:	0b 11 00 91	add	x11, x8, #0x4
101179830:	2d 00 80 52	mov	w13, #0x1
101179834:	06 00 00 14	b	0x10117984c
101179838:	ad 05 00 91	add	x13, x13, #0x1
10117983c:	6b 11 00 91	add	x11, x11, #0x4
101179840:	ec 03 0e aa	mov	x12, x14
101179844:	df 01 17 eb	cmp	x14, x23
101179848:	a0 02 00 54	b.eq	0x10117989c
10117984c:	8e 05 00 91	add	x14, x12, #0x1
101179850:	df 01 09 eb	cmp	x14, x9
101179854:	2a ff ff 54	b.ge	0x101179838
101179858:	ef 3b 4b f9	ldr	x15, [sp, #0x1670]
10117985c:	ef 09 0d 8b	add	x15, x15, x13, lsl #2
101179860:	f0 03 0a aa	mov	x16, x10
101179864:	f1 03 0b aa	mov	x17, x11
101179868:	06 00 00 14	b	0x101179880
10117986c:	31 12 00 91	add	x17, x17, #0x4
101179870:	ef 11 00 91	add	x15, x15, #0x4
101179874:	10 06 00 d1	sub	x16, x16, #0x1
101179878:	bf 01 10 eb	cmp	x13, x16
10117987c:	e0 fd ff 54	b.eq	0x101179838
101179880:	00 79 6c bc	ldr	s0, [x8, x12, lsl #2]
101179884:	21 02 40 bd	ldr	s1, [x17]
101179888:	00 20 21 1e	fcmp	s0, s1
10117988c:	0d ff ff 54	b.le	0x10117986c
101179890:	01 79 2c bc	str	s1, [x8, x12, lsl #2]
101179894:	e0 01 00 bd	str	s0, [x15]
101179898:	f5 ff ff 17	b	0x10117986c
10117989c:	68 06 01 12	and	w8, w19, #0x80000001
1011798a0:	1f 05 00 71	cmp	w8, #0x1
1011798a4:	a1 00 00 54	b.ne	0x1011798b8
1011798a8:	68 7e 41 d3	ubfx	x8, x19, #1, #31
1011798ac:	e0 3b 4b f9	ldr	x0, [sp, #0x1670]
1011798b0:	00 78 68 bc	ldr	s0, [x0, x8, lsl #2]
1011798b4:	0a 00 00 14	b	0x1011798dc
1011798b8:	7f 02 00 71	cmp	w19, #0x0
1011798bc:	68 a6 93 1a	cinc	w8, w19, lt
1011798c0:	08 7d 01 13	asr	w8, w8, #1
1011798c4:	e0 3b 4b f9	ldr	x0, [sp, #0x1670]
1011798c8:	08 c8 28 8b	add	x8, x0, w8, sxtw #2
1011798cc:	00 85 7f 2d	ldp	s0, s1, [x8, #-0x4]
1011798d0:	20 28 20 1e	fadd	s0, s1, s0
1011798d4:	01 10 2c 1e	fmov	s1, #0.50000000
1011798d8:	00 08 21 1e	fmul	s0, s0, s1
1011798dc:	80 4b 00 bd	str	s0, [x28, #0x48]
1011798e0:	88 27 47 a9	ldp	x8, x9, [x28, #0x70]
1011798e4:	29 01 08 cb	sub	x9, x9, x8
1011798e8:	29 fd 43 93	asr	x9, x9, #3
1011798ec:	ea f3 01 b2	mov	x10, #-0x5555555555555556
1011798f0:	6a 55 95 f2	movk	x10, #0xaaab
1011798f4:	29 7d 0a 9b	mul	x9, x9, x10
1011798f8:	2a 05 00 71	subs	w10, w9, #0x1
1011798fc:	4d 03 00 54	b.le	0x101179964
101179900:	0b 01 40 b9	ldr	w11, [x8]
101179904:	ed f3 40 b9	ldr	w13, [sp, #0xf0]
101179908:	6b 01 0d 6b	subs	w11, w11, w13
10117990c:	6b 55 8b 5a	cneg	w11, w11, mi
101179910:	0c 19 40 b9	ldr	w12, [x8, #0x18]
101179914:	8c 01 0d 6b	subs	w12, w12, w13
101179918:	8c 55 8c 5a	cneg	w12, w12, mi
10117991c:	7f 01 0c 6b	cmp	w11, w12
101179920:	69 22 00 54	b.ls	0x101179d6c
101179924:	0b 00 80 d2	mov	x11, #0x0
101179928:	2e 7d 40 92	and	x14, x9, #0xffffffff
10117992c:	0d c1 00 91	add	x13, x8, #0x30
101179930:	ce 09 00 d1	sub	x14, x14, #0x2
101179934:	f0 f3 40 b9	ldr	w16, [sp, #0xf0]
101179938:	df 01 0b eb	cmp	x14, x11
10117993c:	a0 21 00 54	b.eq	0x101179d70
101179940:	af 85 41 b8	ldr	w15, [x13], #0x18
101179944:	ef 01 10 6b	subs	w15, w15, w16
101179948:	ef 55 8f 5a	cneg	w15, w15, mi
10117994c:	6b 05 00 91	add	x11, x11, #0x1
101179950:	9f 01 0f 6b	cmp	w12, w15
101179954:	ec 03 0f aa	mov	x12, x15
101179958:	08 ff ff 54	b.hi	0x101179938
10117995c:	ea 03 0b aa	mov	x10, x11
101179960:	04 01 00 14	b	0x101179d70
101179964:	0a 00 80 52	mov	w10, #0x0
101179968:	3f 01 00 14	b	0x101179e64
10117996c:	0a 09 40 f2	ands	x10, x8, #0x7
101179970:	0b 01 80 52	mov	w11, #0x8
101179974:	6a 01 8a 9a	csel	x10, x11, x10, eq
101179978:	0a 01 0a cb	sub	x10, x8, x10
10117997c:	01 04 08 4e	dup.2d	v1, v0[0]
101179980:	e2 17 c0 3d	ldr	q2, [sp, #0x50]
101179984:	41 fc 61 6e	fdiv.2d	v1, v2, v1
101179988:	2b 81 00 91	add	x11, x9, #0x20
10117998c:	0c c3 00 91	add	x12, x24, #0x30
101179990:	0d 00 c8 d2	mov	x13, #0x400000000000
101179994:	ed 11 e8 f2	movk	x13, #0x408f, lsl #48
101179998:	a2 0d 08 4e	dup.2d	v2, x13
10117999c:	8d 3f 95 d2	mov	x13, #0xa9fc
1011799a0:	2d 5e ba f2	movk	x13, #0xd2f1, lsl #16
1011799a4:	ad 49 cc f2	movk	x13, #0x624d, lsl #32
1011799a8:	0d ea e7 f2	movk	x13, #0x3f50, lsl #48
1011799ac:	a3 0d 08 4e	dup.2d	v3, x13
1011799b0:	ed 03 0a aa	mov	x13, x10
1011799b4:	8e c1 00 d1	sub	x14, x12, #0x30
1011799b8:	8f 61 00 d1	sub	x15, x12, #0x18
1011799bc:	c4 49 40 0c	ld3.2s	{ v4, v5, v6 }, [x14]
1011799c0:	ee 03 0c aa	mov	x14, x12
1011799c4:	f0 49 40 0c	ld3.2s	{ v16, v17, v18 }, [x15]
1011799c8:	d3 49 df 0c	ld3.2s	{ v19, v20, v21 }, [x14], #24
1011799cc:	d6 49 40 0c	ld3.2s	{ v22, v23, v24 }, [x14]
1011799d0:	84 a4 20 0f	sshll.2d	v4, v4, #0x0
1011799d4:	84 d8 61 4e	scvtf.2d	v4, v4
1011799d8:	05 a6 20 0f	sshll.2d	v5, v16, #0x0
1011799dc:	66 a6 20 0f	sshll.2d	v6, v19, #0x0
1011799e0:	c6 d8 61 4e	scvtf.2d	v6, v6
1011799e4:	c7 a6 20 0f	sshll.2d	v7, v22, #0x0
1011799e8:	a5 d8 61 4e	scvtf.2d	v5, v5
1011799ec:	e7 d8 61 4e	scvtf.2d	v7, v7
1011799f0:	84 dc 62 6e	fmul.2d	v4, v4, v2
1011799f4:	a5 dc 62 6e	fmul.2d	v5, v5, v2
1011799f8:	c6 dc 62 6e	fmul.2d	v6, v6, v2
1011799fc:	e7 dc 62 6e	fmul.2d	v7, v7, v2
101179a00:	84 dc 61 6e	fmul.2d	v4, v4, v1
101179a04:	a5 dc 61 6e	fmul.2d	v5, v5, v1
101179a08:	c6 dc 61 6e	fmul.2d	v6, v6, v1
101179a0c:	e7 dc 61 6e	fmul.2d	v7, v7, v1
101179a10:	84 88 61 6e	frinta.2d	v4, v4
101179a14:	c6 88 61 6e	frinta.2d	v6, v6
101179a18:	a5 88 61 6e	frinta.2d	v5, v5
101179a1c:	e7 88 61 6e	frinta.2d	v7, v7
101179a20:	84 dc 63 6e	fmul.2d	v4, v4, v3
101179a24:	a5 dc 63 6e	fmul.2d	v5, v5, v3
101179a28:	c6 dc 63 6e	fmul.2d	v6, v6, v3
101179a2c:	64 15 3f ad	stp	q4, q5, [x11, #-0x20]
101179a30:	e4 dc 63 6e	fmul.2d	v4, v7, v3
101179a34:	66 11 82 ac	stp	q6, q4, [x11], #0x40
101179a38:	8c 81 01 91	add	x12, x12, #0x60
101179a3c:	ad 21 00 f1	subs	x13, x13, #0x8
101179a40:	a1 fb ff 54	b.ne	0x1011799b4
101179a44:	01 10 6e 1e	fmov	d1, #1.00000000
101179a48:	8b 01 80 52	mov	w11, #0xc
101179a4c:	4b 61 0b 9b	madd	x11, x10, x11, x24
101179a50:	29 0d 0a 8b	add	x9, x9, x10, lsl #3
101179a54:	08 01 0a cb	sub	x8, x8, x10
101179a58:	0a 00 c8 d2	mov	x10, #0x400000000000
101179a5c:	ea 11 e8 f2	movk	x10, #0x408f, lsl #48
101179a60:	8c 3f 95 d2	mov	x12, #0xa9fc
101179a64:	2c 5e ba f2	movk	x12, #0xd2f1, lsl #16
101179a68:	ac 49 cc f2	movk	x12, #0x624d, lsl #32
101179a6c:	0c ea e7 f2	movk	x12, #0x3f50, lsl #48
101179a70:	20 18 60 1e	fdiv	d0, d1, d0
101179a74:	6d c5 40 b8	ldr	w13, [x11], #0xc
101179a78:	a1 01 62 1e	scvtf	d1, w13
101179a7c:	42 01 67 9e	fmov	d2, x10
101179a80:	21 08 62 1e	fmul	d1, d1, d2
101179a84:	21 08 60 1e	fmul	d1, d1, d0
101179a88:	21 40 66 1e	frinta	d1, d1
101179a8c:	82 01 67 9e	fmov	d2, x12
101179a90:	21 08 62 1e	fmul	d1, d1, d2
101179a94:	21 85 00 fc	str	d1, [x9], #0x8
101179a98:	08 05 00 f1	subs	x8, x8, #0x1
101179a9c:	c1 fe ff 54	b.ne	0x101179a74
101179aa0:	e0 43 21 91	add	x0, sp, #0x850
101179aa4:	e1 03 15 aa	mov	x1, x21
101179aa8:	d2 20 00 94	bl	__ZNSt3__16vectorIdNS_9allocatorIdEEEC1Em
101179aac:	e0 43 19 91	add	x0, sp, #0x650
101179ab0:	e1 03 15 aa	mov	x1, x21
101179ab4:	cf 20 00 94	bl	__ZNSt3__16vectorIdNS_9allocatorIdEEEC1Em
101179ab8:	df 06 00 71	cmp	w22, #0x1
101179abc:	2d 04 00 54	b.le	0x101179b40
101179ac0:	e9 2b 45 f9	ldr	x9, [sp, #0xa50]
101179ac4:	e8 2b 44 f9	ldr	x8, [sp, #0x850]
101179ac8:	ea 9b 40 f9	ldr	x10, [sp, #0x130]
101179acc:	5f 21 00 71	cmp	w10, #0x8
101179ad0:	23 01 00 54	b.lo	0x101179af4
101179ad4:	4a f1 7d d3	lsl	x10, x10, #3
101179ad8:	4b 01 09 8b	add	x11, x10, x9
101179adc:	6b 21 00 91	add	x11, x11, #0x8
101179ae0:	1f 01 0b eb	cmp	x8, x11
101179ae4:	42 51 00 54	b.hs	0x10117a50c
101179ae8:	0a 01 0a 8b	add	x10, x8, x10
101179aec:	3f 01 0a eb	cmp	x9, x10
101179af0:	e2 50 00 54	b.hs	0x10117a50c
101179af4:	0a 00 80 d2	mov	x10, #0x0
101179af8:	4b f1 7d d3	lsl	x11, x10, #3
101179afc:	69 01 09 8b	add	x9, x11, x9
101179b00:	29 21 00 91	add	x9, x9, #0x8
101179b04:	08 01 0b 8b	add	x8, x8, x11
101179b08:	eb 9b 40 f9	ldr	x11, [sp, #0x130]
101179b0c:	6a 01 0a cb	sub	x10, x11, x10
101179b10:	0b 00 c8 d2	mov	x11, #0x400000000000
101179b14:	eb 11 e8 f2	movk	x11, #0x408f, lsl #48
101179b18:	00 10 6c 1e	fmov	d0, #0.50000000
101179b1c:	22 85 7f 6d	ldp	d2, d1, [x9, #-0x8]
101179b20:	21 38 62 1e	fsub	d1, d1, d2
101179b24:	62 01 67 9e	fmov	d2, x11
101179b28:	21 00 42 1f	fmadd	d1, d1, d2, d0
101179b2c:	21 c0 65 1e	frintz	d1, d1
101179b30:	01 85 00 fc	str	d1, [x8], #0x8
101179b34:	29 21 00 91	add	x9, x9, #0x8
101179b38:	4a 05 00 f1	subs	x10, x10, #0x1
101179b3c:	01 ff ff 54	b.ne	0x101179b1c
101179b40:	a8 04 80 52	mov	w8, #0x25
101179b44:	df 96 00 71	cmp	w22, #0x25
101179b48:	c8 b2 88 1a	csel	w8, w22, w8, lt
101179b4c:	29 00 80 52	mov	w9, #0x1
101179b50:	29 01 16 4b	sub	w9, w9, w22
101179b54:	df 06 00 71	cmp	w22, #0x1
101179b58:	29 c1 9f 5a	csinv	w9, w9, wzr, gt
101179b5c:	8a 02 80 12	mov	w10, #-0x15
101179b60:	df 56 00 71	cmp	w22, #0x15
101179b64:	49 c1 89 1a	csel	w9, w10, w9, gt
101179b68:	29 01 16 0b	add	w9, w9, w22
101179b6c:	3f 05 00 71	cmp	w9, #0x1
101179b70:	eb 09 00 54	b.lt	0x101179cac
101179b74:	eb 2b 44 f9	ldr	x11, [sp, #0x850]
101179b78:	ea 2b 43 f9	ldr	x10, [sp, #0x650]
101179b7c:	3f 21 00 71	cmp	w9, #0x8
101179b80:	a3 03 00 54	b.lo	0x101179bf4
101179b84:	2c f1 7d d3	lsl	x12, x9, #3
101179b88:	4d 01 0c 8b	add	x13, x10, x12
101179b8c:	8c 01 0b 8b	add	x12, x12, x11
101179b90:	8c 21 00 91	add	x12, x12, #0x8
101179b94:	5f 01 0c eb	cmp	x10, x12
101179b98:	62 31 4d fa	ccmp	x11, x13, #0x2, lo
101179b9c:	c3 02 00 54	b.lo	0x101179bf4
101179ba0:	2c 71 7d 92	and	x12, x9, #0xfffffff8
101179ba4:	4d 81 00 91	add	x13, x10, #0x20
101179ba8:	6e 81 00 91	add	x14, x11, #0x20
101179bac:	ef 03 0c aa	mov	x15, x12
101179bb0:	c0 81 de 3c	ldur	q0, [x14, #-0x18]
101179bb4:	c1 81 df 3c	ldur	q1, [x14, #-0x8]
101179bb8:	c2 81 c0 3c	ldur	q2, [x14, #0x8]
101179bbc:	c3 81 c1 3c	ldur	q3, [x14, #0x18]
101179bc0:	c4 15 7f ad	ldp	q4, q5, [x14, #-0x20]
101179bc4:	c6 1d c2 ac	ldp	q6, q7, [x14], #0x40
101179bc8:	00 d4 e4 6e	fabd.2d	v0, v0, v4
101179bcc:	21 d4 e5 6e	fabd.2d	v1, v1, v5
101179bd0:	42 d4 e6 6e	fabd.2d	v2, v2, v6
101179bd4:	63 d4 e7 6e	fabd.2d	v3, v3, v7
101179bd8:	a0 05 3f ad	stp	q0, q1, [x13, #-0x20]
101179bdc:	a2 0d 82 ac	stp	q2, q3, [x13], #0x40
101179be0:	ef 21 00 f1	subs	x15, x15, #0x8
101179be4:	61 fe ff 54	b.ne	0x101179bb0
101179be8:	9f 01 09 eb	cmp	x12, x9
101179bec:	61 00 00 54	b.ne	0x101179bf8
101179bf0:	0d 00 00 14	b	0x101179c24
101179bf4:	0c 00 80 d2	mov	x12, #0x0
101179bf8:	8d f1 7d d3	lsl	x13, x12, #3
101179bfc:	ab 01 0b 8b	add	x11, x13, x11
101179c00:	6b 21 00 91	add	x11, x11, #0x8
101179c04:	4a 01 0d 8b	add	x10, x10, x13
101179c08:	2c 01 0c cb	sub	x12, x9, x12
101179c0c:	61 81 7f 6d	ldp	d1, d0, [x11, #-0x8]
101179c10:	00 d4 e1 7e	fabd	d0, d0, d1
101179c14:	40 85 00 fc	str	d0, [x10], #0x8
101179c18:	6b 21 00 91	add	x11, x11, #0x8
101179c1c:	8c 05 00 f1	subs	x12, x12, #0x1
101179c20:	61 ff ff 54	b.ne	0x101179c0c
101179c24:	0f 00 80 d2	mov	x15, #0x0
101179c28:	0b 00 80 52	mov	w11, #0x0
101179c2c:	ec 2b 43 f9	ldr	x12, [sp, #0x650]
101179c30:	ea 2b 44 f9	ldr	x10, [sp, #0x850]
101179c34:	ed 03 09 aa	mov	x13, x9
101179c38:	ae 7d 40 93	sxtw	x14, w13
101179c3c:	0d 00 80 12	mov	w13, #-0x1
101179c40:	00 e4 00 2f	movi	d0, #0000000000000000
101179c44:	01 d0 64 1e	fmov	d1, #11.00000000
101179c48:	09 00 00 14	b	0x101179c6c
101179c4c:	42 79 6f fc	ldr	d2, [x10, x15, lsl #3]
101179c50:	40 28 60 1e	fadd	d0, d2, d0
101179c54:	6b 05 00 11	add	w11, w11, #0x1
101179c58:	bf 01 00 71	cmp	w13, #0x0
101179c5c:	ed b1 8d 1a	csel	w13, w15, w13, lt
101179c60:	ef 05 00 91	add	x15, x15, #0x1
101179c64:	3f 01 0f eb	cmp	x9, x15
101179c68:	80 01 00 54	b.eq	0x101179c98
101179c6c:	82 79 6f fc	ldr	d2, [x12, x15, lsl #3]
101179c70:	40 20 61 1e	fcmp	d2, d1
101179c74:	cd fe ff 54	b.le	0x101179c4c
101179c78:	7f 01 08 6b	cmp	w11, w8
101179c7c:	2a 1f 00 54	b.ge	0x10117a060
101179c80:	0b 00 80 52	mov	w11, #0x0
101179c84:	00 e4 00 2f	movi	d0, #0000000000000000
101179c88:	0d 00 80 12	mov	w13, #-0x1
101179c8c:	ef 05 00 91	add	x15, x15, #0x1
101179c90:	3f 01 0f eb	cmp	x9, x15
101179c94:	c1 fe ff 54	b.ne	0x101179c6c
101179c98:	ff 01 0e eb	cmp	x15, x14
101179c9c:	0a 01 00 54	b.ge	0x101179cbc
101179ca0:	6f 01 80 52	mov	w15, #0xb
101179ca4:	30 00 80 52	mov	w16, #0x1
101179ca8:	0a 00 00 14	b	0x101179cd0
101179cac:	ec 2b 43 f9	ldr	x12, [sp, #0x650]
101179cb0:	ea 2b 44 f9	ldr	x10, [sp, #0x850]
101179cb4:	eb 03 09 aa	mov	x11, x9
101179cb8:	6e 7d 40 93	sxtw	x14, w11
101179cbc:	0b 00 80 52	mov	w11, #0x0
101179cc0:	00 e4 00 2f	movi	d0, #0000000000000000
101179cc4:	8f 02 80 52	mov	w15, #0x14
101179cc8:	0d 00 80 12	mov	w13, #-0x1
101179ccc:	50 00 80 52	mov	w16, #0x2
101179cd0:	3f 05 00 71	cmp	w9, #0x1
101179cd4:	4b 03 00 54	b.lt	0x101179d3c
101179cd8:	11 00 80 d2	mov	x17, #0x0
101179cdc:	e1 01 62 1e	scvtf	d1, w15
101179ce0:	09 00 00 14	b	0x101179d04
101179ce4:	42 79 71 fc	ldr	d2, [x10, x17, lsl #3]
101179ce8:	40 28 60 1e	fadd	d0, d2, d0
101179cec:	6b 05 00 11	add	w11, w11, #0x1
101179cf0:	bf 01 00 71	cmp	w13, #0x0
101179cf4:	2d b2 8d 1a	csel	w13, w17, w13, lt
101179cf8:	31 06 00 91	add	x17, x17, #0x1
101179cfc:	3f 01 11 eb	cmp	x9, x17
101179d00:	80 01 00 54	b.eq	0x101179d30
101179d04:	82 79 71 fc	ldr	d2, [x12, x17, lsl #3]
101179d08:	40 20 61 1e	fcmp	d2, d1
101179d0c:	cd fe ff 54	b.le	0x101179ce4
101179d10:	7f 01 08 6b	cmp	w11, w8
101179d14:	2a 20 00 54	b.ge	0x10117a118
101179d18:	0b 00 80 52	mov	w11, #0x0
101179d1c:	00 e4 00 2f	movi	d0, #0000000000000000
101179d20:	0d 00 80 12	mov	w13, #-0x1
101179d24:	31 06 00 91	add	x17, x17, #0x1
101179d28:	3f 01 11 eb	cmp	x9, x17
101179d2c:	c1 fe ff 54	b.ne	0x101179d04
101179d30:	3f 02 0e eb	cmp	x17, x14
101179d34:	ee a7 9f 1a	cset	w14, lt
101179d38:	02 00 00 14	b	0x101179d40
101179d3c:	0e 00 80 52	mov	w14, #0x0
101179d40:	ce 01 00 52	eor	w14, w14, #0x1
101179d44:	0e 02 0e 0b	add	w14, w16, w14
101179d48:	01 e4 00 2f	movi	d1, #0000000000000000
101179d4c:	df 09 00 71	cmp	w14, #0x2
101179d50:	c0 18 00 54	b.eq	0x10117a068
101179d54:	df 0d 00 71	cmp	w14, #0x3
101179d58:	01 19 00 54	b.ne	0x10117a078
101179d5c:	0b 00 80 52	mov	w11, #0x0
101179d60:	cf 03 80 52	mov	w15, #0x1e
101179d64:	0d 00 80 12	mov	w13, #-0x1
101179d68:	c5 00 00 14	b	0x10117a07c
101179d6c:	0a 00 80 52	mov	w10, #0x0
101179d70:	3f 15 00 71	cmp	w9, #0x5
101179d74:	8b 07 00 54	b.lt	0x101179e64
101179d78:	2b 09 00 51	sub	w11, w9, #0x2
101179d7c:	6c 03 40 b9	ldr	w12, [x27]
101179d80:	11 31 40 b9	ldr	w17, [x8, #0x30]
101179d84:	0d f1 00 91	add	x13, x8, #0x3c
101179d88:	4e 00 80 52	mov	w14, #0x2
101179d8c:	2f 11 91 52	mov	w15, #0x8889
101179d90:	0f 11 b1 72	movk	w15, #0x8888, lsl #16
101179d94:	10 03 80 52	mov	w16, #0x18
101179d98:	08 00 00 14	b	0x101179db8
101179d9c:	0a 00 80 52	mov	w10, #0x0
101179da0:	01 0d 40 b9	ldr	w1, [x8, #0xc]
101179da4:	e1 b7 00 b9	str	w1, [sp, #0xb4]
101179da8:	ce 05 00 91	add	x14, x14, #0x1
101179dac:	ad 61 00 91	add	x13, x13, #0x18
101179db0:	7f 01 0e eb	cmp	x11, x14
101179db4:	80 05 00 54	b.eq	0x101179e64
101179db8:	31 0e cc 1a	sdiv	w17, w17, w12
101179dbc:	21 7e 2f 9b	smull	x1, w17, w15
101179dc0:	21 fc 60 d3	lsr	x1, x1, #32
101179dc4:	31 00 11 0b	add	w17, w1, w17
101179dc8:	21 7e 05 13	asr	w1, w17, #5
101179dcc:	21 7c 51 0b	add	w1, w1, w17, lsr #31
101179dd0:	b1 0d 40 b9	ldr	w17, [x13, #0xc]
101179dd4:	22 0e cc 1a	sdiv	w2, w17, w12
101179dd8:	43 7c 2f 9b	smull	x3, w2, w15
101179ddc:	63 fc 60 d3	lsr	x3, x3, #32
101179de0:	62 00 02 0b	add	w2, w3, w2
101179de4:	43 7c 05 13	asr	w3, w2, #5
101179de8:	62 7c 42 0b	add	w2, w3, w2, lsr #31
101179dec:	3f 00 02 6b	cmp	w1, w2
101179df0:	c0 fd ff 54	b.eq	0x101179da8
101179df4:	a4 81 5e b8	ldur	w4, [x13, #-0x18]
101179df8:	a1 01 5d b8	ldur	w1, [x13, #-0x30]
101179dfc:	85 00 01 4b	sub	w5, w4, w1
101179e00:	a3 01 40 b9	ldr	w3, [x13]
101179e04:	a1 19 40 b9	ldr	w1, [x13, #0x18]
101179e08:	c2 09 00 11	add	w2, w14, #0x2
101179e0c:	42 20 b0 9b	umaddl	x2, w2, w16, x8
101179e10:	42 0c 40 b9	ldr	w2, [x2, #0xc]
101179e14:	bf 04 00 71	cmp	w5, #0x1
101179e18:	60 00 00 54	b.eq	0x101179e24
101179e1c:	bf 0c 00 31	cmn	w5, #0x3
101179e20:	e1 fb ff 54	b.ne	0x101179d9c
101179e24:	64 00 04 4b	sub	w4, w3, w4
101179e28:	9f 04 00 71	cmp	w4, #0x1
101179e2c:	60 00 00 54	b.eq	0x101179e38
101179e30:	9f 0c 00 31	cmn	w4, #0x3
101179e34:	41 fb ff 54	b.ne	0x101179d9c
101179e38:	23 00 03 4b	sub	w3, w1, w3
101179e3c:	7f 04 00 71	cmp	w3, #0x1
101179e40:	60 00 00 54	b.eq	0x101179e4c
101179e44:	7f 0c 00 31	cmn	w3, #0x3
101179e48:	a1 fa ff 54	b.ne	0x101179d9c
101179e4c:	41 00 01 4b	sub	w1, w2, w1
101179e50:	3f 0c 00 31	cmn	w1, #0x3
101179e54:	a0 fa ff 54	b.eq	0x101179da8
101179e58:	3f 04 00 71	cmp	w1, #0x1
101179e5c:	60 fa ff 54	b.eq	0x101179da8
101179e60:	cf ff ff 17	b	0x101179d9c
101179e64:	2b 05 00 71	subs	w11, w9, #0x1
101179e68:	ab 0d 00 54	b.lt	0x10117a01c
101179e6c:	2c 7d 40 92	and	x12, x9, #0xffffffff
101179e70:	9f 11 00 f1	cmp	x12, #0x4
101179e74:	62 00 00 54	b.hs	0x101179e80
101179e78:	0d 00 80 d2	mov	x13, #0x0
101179e7c:	33 00 00 14	b	0x101179f48
101179e80:	2e 05 40 92	and	x14, x9, #0x3
101179e84:	8d 01 0e cb	sub	x13, x12, x14
101179e88:	ef b7 40 b9	ldr	w15, [sp, #0xb4]
101179e8c:	ef 01 0a 4b	sub	w15, w15, w10
101179e90:	10 f1 00 91	add	x16, x8, #0x3c
101179e94:	f1 03 0d aa	mov	x17, x13
101179e98:	e1 05 00 51	sub	w1, w15, #0x1
101179e9c:	e2 05 00 11	add	w2, w15, #0x1
101179ea0:	e3 09 00 11	add	w3, w15, #0x2
101179ea4:	e4 03 01 6b	negs	w4, w1
101179ea8:	84 04 00 12	and	w4, w4, #0x3
101179eac:	21 04 00 12	and	w1, w1, #0x3
101179eb0:	21 44 84 5a	csneg	w1, w1, w4, mi
101179eb4:	e4 03 0f 6b	negs	w4, w15
101179eb8:	84 04 00 12	and	w4, w4, #0x3
101179ebc:	e5 05 00 12	and	w5, w15, #0x3
101179ec0:	a4 44 84 5a	csneg	w4, w5, w4, mi
101179ec4:	e5 03 02 6b	negs	w5, w2
101179ec8:	a5 04 00 12	and	w5, w5, #0x3
101179ecc:	42 04 00 12	and	w2, w2, #0x3
101179ed0:	42 44 85 5a	csneg	w2, w2, w5, mi
101179ed4:	e5 03 03 6b	negs	w5, w3
101179ed8:	a5 04 00 12	and	w5, w5, #0x3
101179edc:	63 04 00 12	and	w3, w3, #0x3
101179ee0:	63 44 85 5a	csneg	w3, w3, w5, mi
101179ee4:	25 10 00 11	add	w5, w1, #0x4
101179ee8:	86 10 00 11	add	w6, w4, #0x4
101179eec:	47 10 00 11	add	w7, w2, #0x4
101179ef0:	73 10 00 11	add	w19, w3, #0x4
101179ef4:	3f 00 00 71	cmp	w1, #0x0
101179ef8:	a1 b0 81 1a	csel	w1, w5, w1, lt
101179efc:	9f 00 00 71	cmp	w4, #0x0
101179f00:	c4 b0 84 1a	csel	w4, w6, w4, lt
101179f04:	5f 00 00 71	cmp	w2, #0x0
101179f08:	e2 b0 82 1a	csel	w2, w7, w2, lt
101179f0c:	7f 00 00 71	cmp	w3, #0x0
101179f10:	63 b2 83 1a	csel	w3, w19, w3, lt
101179f14:	21 04 00 11	add	w1, w1, #0x1
101179f18:	84 04 00 11	add	w4, w4, #0x1
101179f1c:	42 04 00 11	add	w2, w2, #0x1
101179f20:	01 02 1d b8	stur	w1, [x16, #-0x30]
101179f24:	04 82 1e b8	stur	w4, [x16, #-0x18]
101179f28:	61 04 00 11	add	w1, w3, #0x1
101179f2c:	02 02 00 b9	str	w2, [x16]
101179f30:	01 1a 00 b9	str	w1, [x16, #0x18]
101179f34:	ef 11 00 11	add	w15, w15, #0x4
101179f38:	10 82 01 91	add	x16, x16, #0x60
101179f3c:	31 12 00 f1	subs	x17, x17, #0x4
101179f40:	c1 fa ff 54	b.ne	0x101179e98
101179f44:	ae 02 00 b4	cbz	x14, 0x101179f98
101179f48:	0e 03 80 52	mov	w14, #0x18
101179f4c:	ae 21 0e 9b	madd	x14, x13, x14, x8
101179f50:	ce 31 00 91	add	x14, x14, #0xc
101179f54:	ea 03 2a 2a	mvn	w10, w10
101179f58:	ef b7 40 b9	ldr	w15, [sp, #0xb4]
101179f5c:	ef 01 0d 0b	add	w15, w15, w13
101179f60:	4a 01 0f 0b	add	w10, w10, w15
101179f64:	8d 01 0d cb	sub	x13, x12, x13
101179f68:	ef 03 0a 6b	negs	w15, w10
101179f6c:	ef 05 00 12	and	w15, w15, #0x3
101179f70:	50 05 00 12	and	w16, w10, #0x3
101179f74:	0f 46 8f 5a	csneg	w15, w16, w15, mi
101179f78:	f0 11 00 11	add	w16, w15, #0x4
101179f7c:	ff 01 00 71	cmp	w15, #0x0
101179f80:	0f b2 8f 1a	csel	w15, w16, w15, lt
101179f84:	ef 05 00 11	add	w15, w15, #0x1
101179f88:	cf 85 01 b8	str	w15, [x14], #0x18
101179f8c:	4a 05 00 11	add	w10, w10, #0x1
101179f90:	ad 05 00 f1	subs	x13, x13, #0x1
101179f94:	a1 fe ff 54	b.ne	0x101179f68
101179f98:	0a 00 80 d2	mov	x10, #0x0
101179f9c:	0d 21 00 91	add	x13, x8, #0x8
101179fa0:	0e 01 80 52	mov	w14, #0x8
101179fa4:	0f 03 80 52	mov	w15, #0x18
101179fa8:	50 8f a8 52	mov	w16, #0x447a0000
101179fac:	05 00 00 14	b	0x101179fc0
101179fb0:	4a 05 00 91	add	x10, x10, #0x1
101179fb4:	ad 61 00 91	add	x13, x13, #0x18
101179fb8:	9f 01 0a eb	cmp	x12, x10
101179fbc:	00 03 00 54	b.eq	0x10117a01c
101179fc0:	5f 21 00 71	cmp	w10, #0x8
101179fc4:	51 c1 8e 1a	csel	w17, w10, w14, gt
101179fc8:	31 22 00 51	sub	w17, w17, #0x8
101179fcc:	41 21 00 11	add	w1, w10, #0x8
101179fd0:	3f 00 09 6b	cmp	w1, w9
101179fd4:	22 b0 8b 1a	csel	w2, w1, w11, lt
101179fd8:	41 00 11 6b	subs	w1, w2, w17
101179fdc:	a0 fe ff 54	b.eq	0x101179fb0
101179fe0:	42 7c 2f 9b	smull	x2, w2, w15
101179fe4:	02 69 62 b8	ldr	w2, [x8, x2]
101179fe8:	31 7e af 9b	umull	x17, w17, w15
101179fec:	11 69 71 b8	ldr	w17, [x8, x17]
101179ff0:	51 00 11 4b	sub	w17, w2, w17
101179ff4:	20 02 22 1e	scvtf	s0, w17
101179ff8:	21 00 22 1e	scvtf	s1, w1
101179ffc:	62 03 40 bd	ldr	s2, [x27]
10117a000:	42 d8 21 5e	scvtf	s2, s2
10117a004:	41 08 21 1e	fmul	s1, s2, s1
10117a008:	02 02 27 1e	fmov	s2, w16
10117a00c:	00 08 22 1e	fmul	s0, s0, s2
10117a010:	00 18 21 1e	fdiv	s0, s0, s1
10117a014:	a0 01 00 bd	str	s0, [x13]
10117a018:	e6 ff ff 17	b	0x101179fb0
10117a01c:	0a 0d 40 b9	ldr	w10, [x8, #0xc]
10117a020:	5f 05 00 71	cmp	w10, #0x1
10117a024:	81 00 00 54	b.ne	0x10117a034
10117a028:	0a 00 80 52	mov	w10, #0x0
10117a02c:	2b 00 80 52	mov	w11, #0x1
10117a030:	d0 08 00 14	b	0x10117c370
10117a034:	0a 25 40 b9	ldr	w10, [x8, #0x24]
10117a038:	5f 05 00 71	cmp	w10, #0x1
10117a03c:	61 00 00 54	b.ne	0x10117a048
10117a040:	0b 00 80 52	mov	w11, #0x0
10117a044:	cb 08 00 14	b	0x10117c370
10117a048:	0a 3d 40 b9	ldr	w10, [x8, #0x3c]
10117a04c:	5f 05 00 71	cmp	w10, #0x1
10117a050:	61 18 01 54	b.ne	0x10117c35c
10117a054:	0b 00 80 52	mov	w11, #0x0
10117a058:	4a 00 80 52	mov	w10, #0x2
10117a05c:	c5 08 00 14	b	0x10117c370
10117a060:	e8 05 00 51	sub	w8, w15, #0x1
10117a064:	2e 00 00 14	b	0x10117a11c
10117a068:	0b 00 80 52	mov	w11, #0x0
10117a06c:	8f 02 80 52	mov	w15, #0x14
10117a070:	0d 00 80 12	mov	w13, #-0x1
10117a074:	02 00 00 14	b	0x10117a07c
10117a078:	01 40 60 1e	fmov	d1, d0
10117a07c:	3f 05 00 71	cmp	w9, #0x1
10117a080:	6b 03 00 54	b.lt	0x10117a0ec
10117a084:	e0 01 62 1e	scvtf	d0, w15
10117a088:	0e 00 80 12	mov	w14, #-0x1
10117a08c:	ef 03 0a aa	mov	x15, x10
10117a090:	0a 00 00 14	b	0x10117a0b8
10117a094:	e2 85 40 fc	ldr	d2, [x15], #0x8
10117a098:	41 28 61 1e	fadd	d1, d2, d1
10117a09c:	6b 05 00 11	add	w11, w11, #0x1
10117a0a0:	bf 01 00 71	cmp	w13, #0x0
10117a0a4:	ad a5 8e 1a	csinc	w13, w13, w14, ge
10117a0a8:	ce 05 00 11	add	w14, w14, #0x1
10117a0ac:	8c 21 00 91	add	x12, x12, #0x8
10117a0b0:	29 05 00 f1	subs	x9, x9, #0x1
10117a0b4:	c0 01 00 54	b.eq	0x10117a0ec
10117a0b8:	82 01 40 fd	ldr	d2, [x12]
10117a0bc:	40 20 60 1e	fcmp	d2, d0
10117a0c0:	ad fe ff 54	b.le	0x10117a094
10117a0c4:	7f 01 08 6b	cmp	w11, w8
10117a0c8:	aa 05 00 54	b.ge	0x10117a17c
10117a0cc:	0b 00 80 52	mov	w11, #0x0
10117a0d0:	01 e4 00 2f	movi	d1, #0000000000000000
10117a0d4:	0d 00 80 12	mov	w13, #-0x1
10117a0d8:	ce 05 00 11	add	w14, w14, #0x1
10117a0dc:	ef 21 00 91	add	x15, x15, #0x8
10117a0e0:	8c 21 00 91	add	x12, x12, #0x8
10117a0e4:	29 05 00 f1	subs	x9, x9, #0x1
10117a0e8:	81 fe ff 54	b.ne	0x10117a0b8
10117a0ec:	df 06 00 71	cmp	w22, #0x1
10117a0f0:	0b 01 00 54	b.lt	0x10117a110
10117a0f4:	1f 05 00 71	cmp	w8, #0x1
10117a0f8:	09 c5 9f 1a	csinc	w9, w8, wzr, gt
10117a0fc:	3f 09 00 71	cmp	w9, #0x2
10117a100:	42 01 00 54	b.hs	0x10117a128
10117a104:	0b 00 80 d2	mov	x11, #0x0
10117a108:	00 e4 00 2f	movi	d0, #0000000000000000
10117a10c:	12 00 00 14	b	0x10117a154
10117a110:	00 e4 00 2f	movi	d0, #0000000000000000
10117a114:	16 00 00 14	b	0x10117a16c
10117a118:	28 06 00 51	sub	w8, w17, #0x1
10117a11c:	bf 01 00 71	cmp	w13, #0x0
10117a120:	09 a1 9f 5a	csinv	w9, w8, wzr, ge
10117a124:	19 00 00 14	b	0x10117a188
10117a128:	2b 75 7f 92	and	x11, x9, #0x7ffffffe
10117a12c:	00 e4 00 6f	movi.2d	v0, #0000000000000000
10117a130:	ec 03 0b aa	mov	x12, x11
10117a134:	ed 03 0a aa	mov	x13, x10
10117a138:	a1 05 c1 3c	ldr	q1, [x13], #0x10
10117a13c:	20 d4 60 4e	fadd.2d	v0, v1, v0
10117a140:	8c 09 00 f1	subs	x12, x12, #0x2
10117a144:	a1 ff ff 54	b.ne	0x10117a138
10117a148:	00 d8 70 7e	faddp.2d	d0, v0
10117a14c:	7f 01 09 eb	cmp	x11, x9
10117a150:	e0 00 00 54	b.eq	0x10117a16c
10117a154:	4a 0d 0b 8b	add	x10, x10, x11, lsl #3
10117a158:	29 01 0b cb	sub	x9, x9, x11
10117a15c:	41 85 40 fc	ldr	d1, [x10], #0x8
10117a160:	20 28 60 1e	fadd	d0, d1, d0
10117a164:	29 05 00 f1	subs	x9, x9, #0x1
10117a168:	a1 ff ff 54	b.ne	0x10117a15c
10117a16c:	0d 00 80 52	mov	w13, #0x0
10117a170:	09 05 00 51	sub	w9, w8, #0x1
10117a174:	eb 03 08 aa	mov	x11, x8
10117a178:	04 00 00 14	b	0x10117a188
10117a17c:	bf 01 00 71	cmp	w13, #0x0
10117a180:	c9 a1 9f 5a	csinv	w9, w14, wzr, ge
10117a184:	20 40 60 1e	fmov	d0, d1
10117a188:	d4 0a 00 51	sub	w20, w22, #0x2
10117a18c:	bf 01 00 71	cmp	w13, #0x0
10117a190:	a8 c1 9f 1a	csel	w8, w13, wzr, gt
10117a194:	e8 e3 00 b9	str	w8, [sp, #0xe0]
10117a198:	3f 01 00 71	cmp	w9, #0x0
10117a19c:	33 c1 9f 1a	csel	w19, w9, wzr, gt
10117a1a0:	8b 00 00 34	cbz	w11, 0x10117a1b0
10117a1a4:	61 01 62 1e	scvtf	d1, w11
10117a1a8:	05 18 61 1e	fdiv	d5, d0, d1
10117a1ac:	5a 00 00 14	b	0x10117a314
10117a1b0:	e0 07 40 91	add	x0, sp, #0x1, lsl #12
10117a1b4:	00 c0 19 91	add	x0, x0, #0x670
10117a1b8:	e1 03 15 aa	mov	x1, x21
10117a1bc:	0d 1f 00 94	bl	__ZNSt3__16vectorIdNS_9allocatorIdEEEC1Em
10117a1c0:	df 0a 00 71	cmp	w22, #0x2
10117a1c4:	eb 07 00 54	b.lt	0x10117a2c0
10117a1c8:	08 00 80 d2	mov	x8, #0x0
10117a1cc:	ea 2b 44 f9	ldr	x10, [sp, #0x850]
10117a1d0:	e9 3b 4b f9	ldr	x9, [sp, #0x1670]
10117a1d4:	eb 9b 40 f9	ldr	x11, [sp, #0x130]
10117a1d8:	7f 21 00 71	cmp	w11, #0x8
10117a1dc:	43 02 00 54	b.lo	0x10117a224
10117a1e0:	2b 01 0a cb	sub	x11, x9, x10
10117a1e4:	7f 01 01 f1	cmp	x11, #0x40
10117a1e8:	e3 01 00 54	b.lo	0x10117a224
10117a1ec:	e8 9b 40 f9	ldr	x8, [sp, #0x130]
10117a1f0:	08 71 7d 92	and	x8, x8, #0xfffffff8
10117a1f4:	2b 81 00 91	add	x11, x9, #0x20
10117a1f8:	4c 81 00 91	add	x12, x10, #0x20
10117a1fc:	ed 03 08 aa	mov	x13, x8
10117a200:	80 05 7f ad	ldp	q0, q1, [x12, #-0x20]
10117a204:	82 0d c2 ac	ldp	q2, q3, [x12], #0x40
10117a208:	60 05 3f ad	stp	q0, q1, [x11, #-0x20]
10117a20c:	62 0d 82 ac	stp	q2, q3, [x11], #0x40
10117a210:	ad 21 00 f1	subs	x13, x13, #0x8
10117a214:	61 ff ff 54	b.ne	0x10117a200
10117a218:	eb 9b 40 f9	ldr	x11, [sp, #0x130]
10117a21c:	1f 01 0b eb	cmp	x8, x11
10117a220:	40 01 00 54	b.eq	0x10117a248
10117a224:	0b f1 7d d3	lsl	x11, x8, #3
10117a228:	4a 01 0b 8b	add	x10, x10, x11
10117a22c:	29 01 0b 8b	add	x9, x9, x11
10117a230:	eb 9b 40 f9	ldr	x11, [sp, #0x130]
10117a234:	68 01 08 cb	sub	x8, x11, x8
10117a238:	40 85 40 fc	ldr	d0, [x10], #0x8
10117a23c:	20 85 00 fc	str	d0, [x9], #0x8
10117a240:	08 05 00 f1	subs	x8, x8, #0x1
10117a244:	a1 ff ff 54	b.ne	0x10117a238
10117a248:	df 0e 00 71	cmp	w22, #0x3
10117a24c:	ab 03 00 54	b.lt	0x10117a2c0
10117a250:	0b 00 80 d2	mov	x11, #0x0
10117a254:	e8 3b 4b f9	ldr	x8, [sp, #0x1670]
10117a258:	09 21 00 91	add	x9, x8, #0x8
10117a25c:	2a 00 80 52	mov	w10, #0x1
10117a260:	06 00 00 14	b	0x10117a278
10117a264:	4a 05 00 91	add	x10, x10, #0x1
10117a268:	29 21 00 91	add	x9, x9, #0x8
10117a26c:	eb 03 0c aa	mov	x11, x12
10117a270:	9f 01 14 eb	cmp	x12, x20
10117a274:	60 02 00 54	b.eq	0x10117a2c0
10117a278:	6c 05 00 91	add	x12, x11, #0x1
10117a27c:	ed 9b 40 f9	ldr	x13, [sp, #0x130]
10117a280:	9f 01 0d eb	cmp	x12, x13
10117a284:	02 ff ff 54	b.hs	0x10117a264
10117a288:	ed 9b 40 f9	ldr	x13, [sp, #0x130]
10117a28c:	ee 03 09 aa	mov	x14, x9
10117a290:	05 00 00 14	b	0x10117a2a4
10117a294:	ce 21 00 91	add	x14, x14, #0x8
10117a298:	ad 05 00 d1	sub	x13, x13, #0x1
10117a29c:	5f 01 0d eb	cmp	x10, x13
10117a2a0:	20 fe ff 54	b.eq	0x10117a264
10117a2a4:	00 79 6b fc	ldr	d0, [x8, x11, lsl #3]
10117a2a8:	c1 01 40 fd	ldr	d1, [x14]
10117a2ac:	00 20 61 1e	fcmp	d0, d1
10117a2b0:	2a ff ff 54	b.ge	0x10117a294
10117a2b4:	01 79 2b fc	str	d1, [x8, x11, lsl #3]
10117a2b8:	c0 01 00 fd	str	d0, [x14]
10117a2bc:	f6 ff ff 17	b	0x10117a294
10117a2c0:	e9 9b 40 f9	ldr	x9, [sp, #0x130]
10117a2c4:	28 05 01 12	and	w8, w9, #0x80000001
10117a2c8:	1f 05 00 71	cmp	w8, #0x1
10117a2cc:	a1 00 00 54	b.ne	0x10117a2e0
10117a2d0:	28 7d 01 53	lsr	w8, w9, #1
10117a2d4:	e0 3b 4b f9	ldr	x0, [sp, #0x1670]
10117a2d8:	00 58 68 fc	ldr	d0, [x0, w8, uxtw #3]
10117a2dc:	0a 00 00 14	b	0x10117a304
10117a2e0:	3f 01 00 71	cmp	w9, #0x0
10117a2e4:	28 a5 89 1a	cinc	w8, w9, lt
10117a2e8:	08 7d 01 13	asr	w8, w8, #1
10117a2ec:	e0 3b 4b f9	ldr	x0, [sp, #0x1670]
10117a2f0:	08 cc 28 8b	add	x8, x0, w8, sxtw #3
10117a2f4:	00 85 7f 6d	ldp	d0, d1, [x8, #-0x8]
10117a2f8:	20 28 60 1e	fadd	d0, d1, d0
10117a2fc:	01 10 6c 1e	fmov	d1, #0.50000000
10117a300:	00 08 61 1e	fmul	d0, d0, d1
10117a304:	e0 47 80 3d	str	q0, [sp, #0x110]
10117a308:	e0 3f 0b f9	str	x0, [sp, #0x1678]
10117a30c:	eb 5d 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10117a310:	e5 47 c0 3d	ldr	q5, [sp, #0x110]
10117a314:	e8 77 40 f9	ldr	x8, [sp, #0xe8]
10117a318:	09 01 40 bd	ldr	s9, [x8]
10117a31c:	20 c1 22 1e	fcvt	d0, s9
10117a320:	21 41 26 1e	frinta	s1, s9
10117a324:	22 c0 22 1e	fcvt	d2, s1
10117a328:	c8 72 88 d2	mov	x8, #0x4396
10117a32c:	68 91 ad f2	movk	x8, #0x6c8b, lsl #16
10117a330:	e8 7c df f2	movk	x8, #0xfbe7, lsl #32
10117a334:	e8 fd e7 f2	movk	x8, #0x3fef, lsl #48
10117a338:	03 01 67 9e	fmov	d3, x8
10117a33c:	43 08 63 1e	fmul	d3, d2, d3
10117a340:	a8 c6 8b d2	mov	x8, #0x5e35
10117a344:	48 37 a9 f2	movk	x8, #0x49ba, lsl #16
10117a348:	88 41 c0 f2	movk	x8, #0x20c, lsl #32
10117a34c:	08 fe e7 f2	movk	x8, #0x3ff0, lsl #48
10117a350:	04 01 67 9e	fmov	d4, x8
10117a354:	44 08 64 1e	fmul	d4, d2, d4
10117a358:	60 20 60 1e	fcmp	d3, d0
10117a35c:	88 d4 60 1e	fccmp	d4, d0, #0x8, le
10117a360:	ab 00 00 54	b.lt	0x10117a374
10117a364:	e8 77 40 f9	ldr	x8, [sp, #0xe8]
10117a368:	01 01 00 bd	str	s1, [x8]
10117a36c:	40 40 60 1e	fmov	d0, d2
10117a370:	29 40 20 1e	fmov	s9, s1
10117a374:	08 80 c9 d2	mov	x8, #0x4c0000000000
10117a378:	a8 1d e8 f2	movk	x8, #0x40ed, lsl #48
10117a37c:	01 01 67 9e	fmov	d1, x8
10117a380:	21 18 65 1e	fdiv	d1, d1, d5
10117a384:	c8 f5 88 d2	mov	x8, #0x47ae
10117a388:	28 5c af f2	movk	x8, #0x7ae1, lsl #16
10117a38c:	88 c2 d5 f2	movk	x8, #0xae14, lsl #32
10117a390:	e8 ff e7 f2	movk	x8, #0x3fff, lsl #48
10117a394:	02 01 67 9e	fmov	d2, x8
10117a398:	02 08 62 1e	fmul	d2, d0, d2
10117a39c:	28 85 8b d2	mov	x8, #0x5c29
10117a3a0:	e8 51 b8 f2	movk	x8, #0xc28f, lsl #16
10117a3a4:	a8 1e c5 f2	movk	x8, #0x28f5, lsl #32
10117a3a8:	08 00 e8 f2	movk	x8, #0x4000, lsl #48
10117a3ac:	03 01 67 9e	fmov	d3, x8
10117a3b0:	03 08 63 1e	fmul	d3, d0, d3
10117a3b4:	20 20 62 1e	fcmp	d1, d2
10117a3b8:	20 a4 63 1e	fccmp	d1, d3, #0x0, ge
10117a3bc:	4d 04 00 54	b.le	0x10117a444
10117a3c0:	c8 f5 88 d2	mov	x8, #0x47ae
10117a3c4:	28 5c af f2	movk	x8, #0x7ae1, lsl #16
10117a3c8:	88 c2 d5 f2	movk	x8, #0xae14, lsl #32
10117a3cc:	e8 fb e7 f2	movk	x8, #0x3fdf, lsl #48
10117a3d0:	02 01 67 9e	fmov	d2, x8
10117a3d4:	02 08 62 1e	fmul	d2, d0, d2
10117a3d8:	28 85 8b d2	mov	x8, #0x5c29
10117a3dc:	e8 51 b8 f2	movk	x8, #0xc28f, lsl #16
10117a3e0:	a8 1e c5 f2	movk	x8, #0x28f5, lsl #32
10117a3e4:	08 fc e7 f2	movk	x8, #0x3fe0, lsl #48
10117a3e8:	03 01 67 9e	fmov	d3, x8
10117a3ec:	03 08 63 1e	fmul	d3, d0, d3
10117a3f0:	20 20 62 1e	fcmp	d1, d2
10117a3f4:	20 a4 63 1e	fccmp	d1, d3, #0x0, ge
10117a3f8:	2d 03 00 54	b.le	0x10117a45c
10117a3fc:	e8 e7 01 b2	mov	x8, #-0x6666666666666667
10117a400:	48 33 93 f2	movk	x8, #0x999a
10117a404:	28 fd e7 f2	movk	x8, #0x3fe9, lsl #48
10117a408:	02 01 67 9e	fmov	d2, x8
10117a40c:	02 08 62 1e	fmul	d2, d0, d2
10117a410:	03 90 6e 1e	fmov	d3, #1.25000000
10117a414:	00 08 63 1e	fmul	d0, d0, d3
10117a418:	20 20 62 1e	fcmp	d1, d2
10117a41c:	20 a4 60 1e	fccmp	d1, d0, #0x0, ge
10117a420:	ed 02 00 54	b.le	0x10117a47c
10117a424:	08 00 d0 d2	mov	x8, #0x800000000000
10117a428:	28 0a e8 f2	movk	x8, #0x4051, lsl #48
10117a42c:	00 01 67 9e	fmov	d0, x8
10117a430:	20 20 60 1e	fcmp	d1, d0
10117a434:	6a 0b 01 54	b.ge	0x10117c5a0
10117a438:	20 40 62 1e	fcvt	s0, d1
10117a43c:	09 28 20 1e	fadd	s9, s0, s0
10117a440:	0d 00 00 14	b	0x10117a474
10117a444:	88 56 a8 52	mov	w8, #0x42b40000
10117a448:	00 01 27 1e	fmov	s0, w8
10117a44c:	20 21 20 1e	fcmp	s9, s0
10117a450:	6c 01 00 54	b.gt	0x10117a47c
10117a454:	29 29 29 1e	fadd	s9, s9, s9
10117a458:	07 00 00 14	b	0x10117a474
10117a45c:	88 61 a8 52	mov	w8, #0x430c0000
10117a460:	00 01 27 1e	fmov	s0, w8
10117a464:	20 21 20 1e	fcmp	s9, s0
10117a468:	ab 00 00 54	b.lt	0x10117a47c
10117a46c:	00 10 2c 1e	fmov	s0, #0.50000000
10117a470:	29 09 20 1e	fmul	s9, s9, s0
10117a474:	e8 77 40 f9	ldr	x8, [sp, #0xe8]
10117a478:	09 01 00 bd	str	s9, [x8]
10117a47c:	e5 47 80 3d	str	q5, [sp, #0x110]
10117a480:	6a 03 40 bd	ldr	s10, [x27]
10117a484:	e0 43 11 91	add	x0, sp, #0x450
10117a488:	e1 03 15 aa	mov	x1, x21
10117a48c:	59 1e 00 94	bl	__ZNSt3__16vectorIdNS_9allocatorIdEEEC1Em
10117a490:	df 0a 00 71	cmp	w22, #0x2
10117a494:	fb 9b 40 f9	ldr	x27, [sp, #0x130]
10117a498:	2b 0a 00 54	b.lt	0x10117a5dc
10117a49c:	08 00 80 d2	mov	x8, #0x0
10117a4a0:	ea 2b 44 f9	ldr	x10, [sp, #0x850]
10117a4a4:	e9 2b 42 f9	ldr	x9, [sp, #0x450]
10117a4a8:	7f 23 00 71	cmp	w27, #0x8
10117a4ac:	e3 07 00 54	b.lo	0x10117a5a8
10117a4b0:	2b 01 0a cb	sub	x11, x9, x10
10117a4b4:	7f 01 01 f1	cmp	x11, #0x40
10117a4b8:	e1 47 c0 3d	ldr	q1, [sp, #0x110]
10117a4bc:	83 07 00 54	b.lo	0x10117a5ac
10117a4c0:	68 73 7d 92	and	x8, x27, #0xfffffff8
10117a4c4:	20 04 08 4e	dup.2d	v0, v1[0]
10117a4c8:	2b 81 00 91	add	x11, x9, #0x20
10117a4cc:	4c 81 00 91	add	x12, x10, #0x20
10117a4d0:	ed 03 08 aa	mov	x13, x8
10117a4d4:	81 09 7f ad	ldp	q1, q2, [x12, #-0x20]
10117a4d8:	83 11 c2 ac	ldp	q3, q4, [x12], #0x40
10117a4dc:	21 d4 e0 6e	fabd.2d	v1, v1, v0
10117a4e0:	42 d4 e0 6e	fabd.2d	v2, v2, v0
10117a4e4:	63 d4 e0 6e	fabd.2d	v3, v3, v0
10117a4e8:	84 d4 e0 6e	fabd.2d	v4, v4, v0
10117a4ec:	61 09 3f ad	stp	q1, q2, [x11, #-0x20]
10117a4f0:	63 11 82 ac	stp	q3, q4, [x11], #0x40
10117a4f4:	ad 21 00 f1	subs	x13, x13, #0x8
10117a4f8:	e1 fe ff 54	b.ne	0x10117a4d4
10117a4fc:	1f 01 1b eb	cmp	x8, x27
10117a500:	e1 47 c0 3d	ldr	q1, [sp, #0x110]
10117a504:	41 05 00 54	b.ne	0x10117a5ac
10117a508:	32 00 00 14	b	0x10117a5d0
10117a50c:	ea 9b 40 f9	ldr	x10, [sp, #0x130]
10117a510:	4a 71 7d 92	and	x10, x10, #0xfffffff8
10117a514:	0b 81 00 91	add	x11, x8, #0x20
10117a518:	2c 81 00 91	add	x12, x9, #0x20
10117a51c:	0d 00 c8 d2	mov	x13, #0x400000000000
10117a520:	ed 11 e8 f2	movk	x13, #0x408f, lsl #48
10117a524:	a0 0d 08 4e	dup.2d	v0, x13
10117a528:	01 f4 03 6f	fmov.2d	v1, #0.50000000
10117a52c:	ed 03 0a aa	mov	x13, x10
10117a530:	82 81 de 3c	ldur	q2, [x12, #-0x18]
10117a534:	83 81 df 3c	ldur	q3, [x12, #-0x8]
10117a538:	84 81 c0 3c	ldur	q4, [x12, #0x8]
10117a53c:	85 81 c1 3c	ldur	q5, [x12, #0x18]
10117a540:	86 1d 7f ad	ldp	q6, q7, [x12, #-0x20]
10117a544:	90 45 c2 ac	ldp	q16, q17, [x12], #0x40
10117a548:	42 d4 e6 4e	fsub.2d	v2, v2, v6
10117a54c:	63 d4 e7 4e	fsub.2d	v3, v3, v7
10117a550:	84 d4 f0 4e	fsub.2d	v4, v4, v16
10117a554:	a5 d4 f1 4e	fsub.2d	v5, v5, v17
10117a558:	26 1c a1 4e	mov.16b	v6, v1
10117a55c:	46 cc 60 4e	fmla.2d	v6, v2, v0
10117a560:	22 1c a1 4e	mov.16b	v2, v1
10117a564:	62 cc 60 4e	fmla.2d	v2, v3, v0
10117a568:	23 1c a1 4e	mov.16b	v3, v1
10117a56c:	83 cc 60 4e	fmla.2d	v3, v4, v0
10117a570:	24 1c a1 4e	mov.16b	v4, v1
10117a574:	a4 cc 60 4e	fmla.2d	v4, v5, v0
10117a578:	c5 98 e1 4e	frintz.2d	v5, v6
10117a57c:	42 98 e1 4e	frintz.2d	v2, v2
10117a580:	63 98 e1 4e	frintz.2d	v3, v3
10117a584:	84 98 e1 4e	frintz.2d	v4, v4
10117a588:	65 09 3f ad	stp	q5, q2, [x11, #-0x20]
10117a58c:	63 11 82 ac	stp	q3, q4, [x11], #0x40
10117a590:	ad 21 00 f1	subs	x13, x13, #0x8
10117a594:	e1 fc ff 54	b.ne	0x10117a530
10117a598:	eb 9b 40 f9	ldr	x11, [sp, #0x130]
10117a59c:	5f 01 0b eb	cmp	x10, x11
10117a5a0:	00 ad ff 54	b.eq	0x101179b40
10117a5a4:	55 fd ff 17	b	0x101179af8
10117a5a8:	e1 47 c0 3d	ldr	q1, [sp, #0x110]
10117a5ac:	0b f1 7d d3	lsl	x11, x8, #3
10117a5b0:	4a 01 0b 8b	add	x10, x10, x11
10117a5b4:	29 01 0b 8b	add	x9, x9, x11
10117a5b8:	68 03 08 cb	sub	x8, x27, x8
10117a5bc:	40 85 40 fc	ldr	d0, [x10], #0x8
10117a5c0:	00 d4 e1 7e	fabd	d0, d0, d1
10117a5c4:	20 85 00 fc	str	d0, [x9], #0x8
10117a5c8:	08 05 00 f1	subs	x8, x8, #0x1
10117a5cc:	81 ff ff 54	b.ne	0x10117a5bc
10117a5d0:	e8 2b 42 f9	ldr	x8, [sp, #0x450]
10117a5d4:	00 59 74 fc	ldr	d0, [x8, w20, uxtw #3]
10117a5d8:	00 79 3b fc	str	d0, [x8, x27, lsl #3]
10117a5dc:	e0 63 10 91	add	x0, sp, #0x418
10117a5e0:	e1 03 15 aa	mov	x1, x21
10117a5e4:	03 1e 00 94	bl	__ZNSt3__16vectorIdNS_9allocatorIdEEEC1Em
10117a5e8:	40 a5 20 0f	sshll.2d	v0, v10, #0x0
10117a5ec:	c8 09 e8 d2	mov	x8, #0x404e000000000000
10117a5f0:	01 d8 61 5e	scvtf	d1, d0
10117a5f4:	ff 07 02 f9	str	xzr, [sp, #0x408]
10117a5f8:	ff 03 02 f9	str	xzr, [sp, #0x400]
10117a5fc:	02 01 67 9e	fmov	d2, x8
10117a600:	20 c1 22 1e	fcvt	d0, s9
10117a604:	ff 0b 02 f9	str	xzr, [sp, #0x410]
10117a608:	21 08 62 1e	fmul	d1, d1, d2
10117a60c:	02 e4 00 6f	movi.2d	v2, #0000000000000000
10117a610:	e8 07 40 91	add	x8, sp, #0x1, lsl #12
10117a614:	08 c1 09 91	add	x8, x8, #0x270
10117a618:	02 7d 81 3d	str	q2, [x8, #0x5f0]
10117a61c:	02 79 81 3d	str	q2, [x8, #0x5e0]
10117a620:	02 75 81 3d	str	q2, [x8, #0x5d0]
10117a624:	02 71 81 3d	str	q2, [x8, #0x5c0]
10117a628:	02 6d 81 3d	str	q2, [x8, #0x5b0]
10117a62c:	02 69 81 3d	str	q2, [x8, #0x5a0]
10117a630:	02 65 81 3d	str	q2, [x8, #0x590]
10117a634:	02 61 81 3d	str	q2, [x8, #0x580]
10117a638:	02 5d 81 3d	str	q2, [x8, #0x570]
10117a63c:	02 59 81 3d	str	q2, [x8, #0x560]
10117a640:	02 55 81 3d	str	q2, [x8, #0x550]
10117a644:	02 51 81 3d	str	q2, [x8, #0x540]
10117a648:	02 4d 81 3d	str	q2, [x8, #0x530]
10117a64c:	02 49 81 3d	str	q2, [x8, #0x520]
10117a650:	02 45 81 3d	str	q2, [x8, #0x510]
10117a654:	02 41 81 3d	str	q2, [x8, #0x500]
10117a658:	02 3d 81 3d	str	q2, [x8, #0x4f0]
10117a65c:	02 39 81 3d	str	q2, [x8, #0x4e0]
10117a660:	02 35 81 3d	str	q2, [x8, #0x4d0]
10117a664:	02 31 81 3d	str	q2, [x8, #0x4c0]
10117a668:	02 2d 81 3d	str	q2, [x8, #0x4b0]
10117a66c:	02 29 81 3d	str	q2, [x8, #0x4a0]
10117a670:	02 25 81 3d	str	q2, [x8, #0x490]
10117a674:	02 21 81 3d	str	q2, [x8, #0x480]
10117a678:	02 1d 81 3d	str	q2, [x8, #0x470]
10117a67c:	02 19 81 3d	str	q2, [x8, #0x460]
10117a680:	02 15 81 3d	str	q2, [x8, #0x450]
10117a684:	02 11 81 3d	str	q2, [x8, #0x440]
10117a688:	02 0d 81 3d	str	q2, [x8, #0x430]
10117a68c:	02 09 81 3d	str	q2, [x8, #0x420]
10117a690:	02 05 81 3d	str	q2, [x8, #0x410]
10117a694:	02 89 1f ad	stp	q2, q2, [x8, #0x3f0]
10117a698:	02 89 1e ad	stp	q2, q2, [x8, #0x3d0]
10117a69c:	02 89 1d ad	stp	q2, q2, [x8, #0x3b0]
10117a6a0:	02 89 1c ad	stp	q2, q2, [x8, #0x390]
10117a6a4:	02 89 1b ad	stp	q2, q2, [x8, #0x370]
10117a6a8:	02 89 1a ad	stp	q2, q2, [x8, #0x350]
10117a6ac:	02 89 19 ad	stp	q2, q2, [x8, #0x330]
10117a6b0:	02 89 18 ad	stp	q2, q2, [x8, #0x310]
10117a6b4:	02 89 17 ad	stp	q2, q2, [x8, #0x2f0]
10117a6b8:	02 89 16 ad	stp	q2, q2, [x8, #0x2d0]
10117a6bc:	02 89 15 ad	stp	q2, q2, [x8, #0x2b0]
10117a6c0:	02 89 14 ad	stp	q2, q2, [x8, #0x290]
10117a6c4:	02 89 13 ad	stp	q2, q2, [x8, #0x270]
10117a6c8:	02 89 12 ad	stp	q2, q2, [x8, #0x250]
10117a6cc:	02 89 11 ad	stp	q2, q2, [x8, #0x230]
10117a6d0:	02 89 10 ad	stp	q2, q2, [x8, #0x210]
10117a6d4:	02 81 80 3d	str	q2, [x8, #0x200]
10117a6d8:	e8 83 0d 91	add	x8, sp, #0x360
10117a6dc:	02 41 84 3d	str	q2, [x8, #0x1100]
10117a6e0:	02 3d 84 3d	str	q2, [x8, #0x10f0]
10117a6e4:	02 39 84 3d	str	q2, [x8, #0x10e0]
10117a6e8:	02 35 84 3d	str	q2, [x8, #0x10d0]
10117a6ec:	02 31 84 3d	str	q2, [x8, #0x10c0]
10117a6f0:	02 2d 84 3d	str	q2, [x8, #0x10b0]
10117a6f4:	02 29 84 3d	str	q2, [x8, #0x10a0]
10117a6f8:	02 25 84 3d	str	q2, [x8, #0x1090]
10117a6fc:	02 21 84 3d	str	q2, [x8, #0x1080]
10117a700:	02 1d 84 3d	str	q2, [x8, #0x1070]
10117a704:	02 19 84 3d	str	q2, [x8, #0x1060]
10117a708:	02 15 84 3d	str	q2, [x8, #0x1050]
10117a70c:	02 11 84 3d	str	q2, [x8, #0x1040]
10117a710:	02 0d 84 3d	str	q2, [x8, #0x1030]
10117a714:	02 09 84 3d	str	q2, [x8, #0x1020]
10117a718:	02 05 84 3d	str	q2, [x8, #0x1010]
10117a71c:	02 01 84 3d	str	q2, [x8, #0x1000]
10117a720:	02 fd 83 3d	str	q2, [x8, #0xff0]
10117a724:	02 f9 83 3d	str	q2, [x8, #0xfe0]
10117a728:	02 f5 83 3d	str	q2, [x8, #0xfd0]
10117a72c:	02 f1 83 3d	str	q2, [x8, #0xfc0]
10117a730:	02 ed 83 3d	str	q2, [x8, #0xfb0]
10117a734:	02 e9 83 3d	str	q2, [x8, #0xfa0]
10117a738:	02 e5 83 3d	str	q2, [x8, #0xf90]
10117a73c:	02 e1 83 3d	str	q2, [x8, #0xf80]
10117a740:	02 dd 83 3d	str	q2, [x8, #0xf70]
10117a744:	02 d9 83 3d	str	q2, [x8, #0xf60]
10117a748:	02 d5 83 3d	str	q2, [x8, #0xf50]
10117a74c:	02 d1 83 3d	str	q2, [x8, #0xf40]
10117a750:	02 cd 83 3d	str	q2, [x8, #0xf30]
10117a754:	02 c9 83 3d	str	q2, [x8, #0xf20]
10117a758:	02 c5 83 3d	str	q2, [x8, #0xf10]
10117a75c:	02 c1 83 3d	str	q2, [x8, #0xf00]
10117a760:	02 bd 83 3d	str	q2, [x8, #0xef0]
10117a764:	02 b9 83 3d	str	q2, [x8, #0xee0]
10117a768:	02 b5 83 3d	str	q2, [x8, #0xed0]
10117a76c:	02 b1 83 3d	str	q2, [x8, #0xec0]
10117a770:	02 ad 83 3d	str	q2, [x8, #0xeb0]
10117a774:	02 a9 83 3d	str	q2, [x8, #0xea0]
10117a778:	02 a5 83 3d	str	q2, [x8, #0xe90]
10117a77c:	02 a1 83 3d	str	q2, [x8, #0xe80]
10117a780:	02 9d 83 3d	str	q2, [x8, #0xe70]
10117a784:	02 99 83 3d	str	q2, [x8, #0xe60]
10117a788:	02 95 83 3d	str	q2, [x8, #0xe50]
10117a78c:	02 91 83 3d	str	q2, [x8, #0xe40]
10117a790:	02 8d 83 3d	str	q2, [x8, #0xe30]
10117a794:	02 89 83 3d	str	q2, [x8, #0xe20]
10117a798:	02 85 83 3d	str	q2, [x8, #0xe10]
10117a79c:	02 81 83 3d	str	q2, [x8, #0xe00]
10117a7a0:	02 7d 83 3d	str	q2, [x8, #0xdf0]
10117a7a4:	02 79 83 3d	str	q2, [x8, #0xde0]
10117a7a8:	02 75 83 3d	str	q2, [x8, #0xdd0]
10117a7ac:	02 71 83 3d	str	q2, [x8, #0xdc0]
10117a7b0:	02 6d 83 3d	str	q2, [x8, #0xdb0]
10117a7b4:	02 69 83 3d	str	q2, [x8, #0xda0]
10117a7b8:	02 65 83 3d	str	q2, [x8, #0xd90]
10117a7bc:	02 61 83 3d	str	q2, [x8, #0xd80]
10117a7c0:	02 5d 83 3d	str	q2, [x8, #0xd70]
10117a7c4:	02 59 83 3d	str	q2, [x8, #0xd60]
10117a7c8:	02 55 83 3d	str	q2, [x8, #0xd50]
10117a7cc:	02 51 83 3d	str	q2, [x8, #0xd40]
10117a7d0:	02 4d 83 3d	str	q2, [x8, #0xd30]
10117a7d4:	02 49 83 3d	str	q2, [x8, #0xd20]
10117a7d8:	02 45 83 3d	str	q2, [x8, #0xd10]
10117a7dc:	02 41 83 3d	str	q2, [x8, #0xd00]
10117a7e0:	02 3d 83 3d	str	q2, [x8, #0xcf0]
10117a7e4:	02 39 83 3d	str	q2, [x8, #0xce0]
10117a7e8:	02 35 83 3d	str	q2, [x8, #0xcd0]
10117a7ec:	02 31 83 3d	str	q2, [x8, #0xcc0]
10117a7f0:	02 2d 83 3d	str	q2, [x8, #0xcb0]
10117a7f4:	02 29 83 3d	str	q2, [x8, #0xca0]
10117a7f8:	02 25 83 3d	str	q2, [x8, #0xc90]
10117a7fc:	02 21 83 3d	str	q2, [x8, #0xc80]
10117a800:	02 1d 83 3d	str	q2, [x8, #0xc70]
10117a804:	02 19 83 3d	str	q2, [x8, #0xc60]
10117a808:	02 15 83 3d	str	q2, [x8, #0xc50]
10117a80c:	02 11 83 3d	str	q2, [x8, #0xc40]
10117a810:	02 0d 83 3d	str	q2, [x8, #0xc30]
10117a814:	02 09 83 3d	str	q2, [x8, #0xc20]
10117a818:	02 05 83 3d	str	q2, [x8, #0xc10]
10117a81c:	02 01 83 3d	str	q2, [x8, #0xc00]
10117a820:	02 fd 82 3d	str	q2, [x8, #0xbf0]
10117a824:	02 f9 82 3d	str	q2, [x8, #0xbe0]
10117a828:	02 f5 82 3d	str	q2, [x8, #0xbd0]
10117a82c:	02 f1 82 3d	str	q2, [x8, #0xbc0]
10117a830:	02 ed 82 3d	str	q2, [x8, #0xbb0]
10117a834:	02 e9 82 3d	str	q2, [x8, #0xba0]
10117a838:	02 e5 82 3d	str	q2, [x8, #0xb90]
10117a83c:	02 e1 82 3d	str	q2, [x8, #0xb80]
10117a840:	02 dd 82 3d	str	q2, [x8, #0xb70]
10117a844:	02 d9 82 3d	str	q2, [x8, #0xb60]
10117a848:	02 d5 82 3d	str	q2, [x8, #0xb50]
10117a84c:	02 d1 82 3d	str	q2, [x8, #0xb40]
10117a850:	02 cd 82 3d	str	q2, [x8, #0xb30]
10117a854:	02 c9 82 3d	str	q2, [x8, #0xb20]
10117a858:	02 c5 82 3d	str	q2, [x8, #0xb10]
10117a85c:	02 c1 82 3d	str	q2, [x8, #0xb00]
10117a860:	02 bd 82 3d	str	q2, [x8, #0xaf0]
10117a864:	02 b9 82 3d	str	q2, [x8, #0xae0]
10117a868:	02 b5 82 3d	str	q2, [x8, #0xad0]
10117a86c:	02 b1 82 3d	str	q2, [x8, #0xac0]
10117a870:	02 ad 82 3d	str	q2, [x8, #0xab0]
10117a874:	02 a9 82 3d	str	q2, [x8, #0xaa0]
10117a878:	02 a5 82 3d	str	q2, [x8, #0xa90]
10117a87c:	02 a1 82 3d	str	q2, [x8, #0xa80]
10117a880:	02 9d 82 3d	str	q2, [x8, #0xa70]
10117a884:	02 99 82 3d	str	q2, [x8, #0xa60]
10117a888:	02 95 82 3d	str	q2, [x8, #0xa50]
10117a88c:	02 91 82 3d	str	q2, [x8, #0xa40]
10117a890:	02 8d 82 3d	str	q2, [x8, #0xa30]
10117a894:	02 89 82 3d	str	q2, [x8, #0xa20]
10117a898:	02 85 82 3d	str	q2, [x8, #0xa10]
10117a89c:	02 81 82 3d	str	q2, [x8, #0xa00]
10117a8a0:	02 7d 82 3d	str	q2, [x8, #0x9f0]
10117a8a4:	02 79 82 3d	str	q2, [x8, #0x9e0]
10117a8a8:	02 75 82 3d	str	q2, [x8, #0x9d0]
10117a8ac:	02 71 82 3d	str	q2, [x8, #0x9c0]
10117a8b0:	02 6d 82 3d	str	q2, [x8, #0x9b0]
10117a8b4:	02 69 82 3d	str	q2, [x8, #0x9a0]
10117a8b8:	02 65 82 3d	str	q2, [x8, #0x990]
10117a8bc:	02 61 82 3d	str	q2, [x8, #0x980]
10117a8c0:	02 5d 82 3d	str	q2, [x8, #0x970]
10117a8c4:	02 59 82 3d	str	q2, [x8, #0x960]
10117a8c8:	02 55 82 3d	str	q2, [x8, #0x950]
10117a8cc:	02 51 82 3d	str	q2, [x8, #0x940]
10117a8d0:	02 4d 82 3d	str	q2, [x8, #0x930]
10117a8d4:	02 49 82 3d	str	q2, [x8, #0x920]
10117a8d8:	02 45 82 3d	str	q2, [x8, #0x910]
10117a8dc:	df 06 00 71	cmp	w22, #0x1
10117a8e0:	eb 0a 00 54	b.lt	0x10117aa3c
10117a8e4:	08 00 80 d2	mov	x8, #0x0
10117a8e8:	eb 2b 45 f9	ldr	x11, [sp, #0xa50]
10117a8ec:	ea 0f 42 f9	ldr	x10, [sp, #0x418]
10117a8f0:	e9 03 16 2a	mov	w9, w22
10117a8f4:	df 22 00 71	cmp	w22, #0x8
10117a8f8:	e3 02 00 54	b.lo	0x10117a954
10117a8fc:	4c 01 0b cb	sub	x12, x10, x11
10117a900:	9f 01 01 f1	cmp	x12, #0x40
10117a904:	83 02 00 54	b.lo	0x10117a954
10117a908:	28 71 7d 92	and	x8, x9, #0xfffffff8
10117a90c:	4c 81 00 91	add	x12, x10, #0x20
10117a910:	6d 81 00 91	add	x13, x11, #0x20
10117a914:	0e 00 c8 d2	mov	x14, #0x400000000000
10117a918:	ee 11 e8 f2	movk	x14, #0x408f, lsl #48
10117a91c:	c2 0d 08 4e	dup.2d	v2, x14
10117a920:	ee 03 08 aa	mov	x14, x8
10117a924:	a3 11 7f ad	ldp	q3, q4, [x13, #-0x20]
10117a928:	a5 19 c2 ac	ldp	q5, q6, [x13], #0x40
10117a92c:	63 dc 62 6e	fmul.2d	v3, v3, v2
10117a930:	84 dc 62 6e	fmul.2d	v4, v4, v2
10117a934:	a5 dc 62 6e	fmul.2d	v5, v5, v2
10117a938:	c6 dc 62 6e	fmul.2d	v6, v6, v2
10117a93c:	83 11 3f ad	stp	q3, q4, [x12, #-0x20]
10117a940:	85 19 82 ac	stp	q5, q6, [x12], #0x40
10117a944:	ce 21 00 f1	subs	x14, x14, #0x8
10117a948:	e1 fe ff 54	b.ne	0x10117a924
10117a94c:	1f 01 09 eb	cmp	x8, x9
10117a950:	a0 01 00 54	b.eq	0x10117a984
10117a954:	0c f1 7d d3	lsl	x12, x8, #3
10117a958:	6b 01 0c 8b	add	x11, x11, x12
10117a95c:	4a 01 0c 8b	add	x10, x10, x12
10117a960:	28 01 08 cb	sub	x8, x9, x8
10117a964:	09 00 c8 d2	mov	x9, #0x400000000000
10117a968:	e9 11 e8 f2	movk	x9, #0x408f, lsl #48
10117a96c:	62 85 40 fc	ldr	d2, [x11], #0x8
10117a970:	23 01 67 9e	fmov	d3, x9
10117a974:	42 08 63 1e	fmul	d2, d2, d3
10117a978:	42 85 00 fc	str	d2, [x10], #0x8
10117a97c:	08 05 00 f1	subs	x8, x8, #0x1
10117a980:	61 ff ff 54	b.ne	0x10117a96c
10117a984:	df 0e 00 71	cmp	w22, #0x3
10117a988:	ab 05 00 54	b.lt	0x10117aa3c
10117a98c:	0e 00 80 52	mov	w14, #0x0
10117a990:	08 00 80 52	mov	w8, #0x0
10117a994:	e9 2b 42 f9	ldr	x9, [sp, #0x450]
10117a998:	2a 21 00 91	add	x10, x9, #0x8
10117a99c:	02 90 64 1e	fmov	d2, #10.00000000
10117a9a0:	eb 07 40 91	add	x11, sp, #0x1, lsl #12
10117a9a4:	6b c1 19 91	add	x11, x11, #0x670
10117a9a8:	ec 07 40 91	add	x12, sp, #0x1, lsl #12
10117a9ac:	8c c1 11 91	add	x12, x12, #0x470
10117a9b0:	cd 7d 40 93	sxtw	x13, w14
10117a9b4:	23 d9 6e fc	ldr	d3, [x9, w14, sxtw #3]
10117a9b8:	ad 05 00 91	add	x13, x13, #0x1
10117a9bc:	60 20 62 1e	fcmp	d3, d2
10117a9c0:	ed 01 00 54	b.le	0x10117a9fc
10117a9c4:	23 79 6d fc	ldr	d3, [x9, x13, lsl #3]
10117a9c8:	60 20 62 1e	fcmp	d3, d2
10117a9cc:	8d 01 00 54	b.le	0x10117a9fc
10117a9d0:	ce 09 00 11	add	w14, w14, #0x2
10117a9d4:	6e d9 28 b8	str	w14, [x11, w8, sxtw #2]
10117a9d8:	bf 01 14 eb	cmp	x13, x20
10117a9dc:	aa 01 00 54	b.ge	0x10117aa10
10117a9e0:	ae 05 00 91	add	x14, x13, #0x1
10117a9e4:	43 79 6d fc	ldr	d3, [x10, x13, lsl #3]
10117a9e8:	60 20 62 1e	fcmp	d3, d2
10117a9ec:	c0 c1 54 fa	ccmp	x14, x20, #0x0, gt
10117a9f0:	ed 03 0e aa	mov	x13, x14
10117a9f4:	6b ff ff 54	b.lt	0x10117a9e0
10117a9f8:	07 00 00 14	b	0x10117aa14
10117a9fc:	ee 03 0d aa	mov	x14, x13
10117aa00:	2d 00 80 52	mov	w13, #0x1
10117aa04:	df 01 14 6b	cmp	w14, w20
10117aa08:	4b 01 00 54	b.lt	0x10117aa30
10117aa0c:	0d 00 00 14	b	0x10117aa40
10117aa10:	ee 03 0d aa	mov	x14, x13
10117aa14:	0d 7d 40 93	sxtw	x13, w8
10117aa18:	ce 05 00 11	add	w14, w14, #0x1
10117aa1c:	8e 79 2d b8	str	w14, [x12, x13, lsl #2]
10117aa20:	08 05 00 11	add	w8, w8, #0x1
10117aa24:	2d 00 80 52	mov	w13, #0x1
10117aa28:	df 01 14 6b	cmp	w14, w20
10117aa2c:	aa 00 00 54	b.ge	0x10117aa40
10117aa30:	1f 01 02 71	cmp	w8, #0x80
10117aa34:	eb fb ff 54	b.lt	0x10117a9b0
10117aa38:	02 00 00 14	b	0x10117aa40
10117aa3c:	0d 00 80 52	mov	w13, #0x0
10117aa40:	09 00 80 d2	mov	x9, #0x0
10117aa44:	08 00 80 52	mov	w8, #0x0
10117aa48:	ea 07 40 91	add	x10, sp, #0x1, lsl #12
10117aa4c:	4a c1 19 91	add	x10, x10, #0x670
10117aa50:	eb 07 40 91	add	x11, sp, #0x1, lsl #12
10117aa54:	6b c1 11 91	add	x11, x11, #0x470
10117aa58:	20 18 60 1e	fdiv	d0, d1, d0
10117aa5c:	4c 69 69 b8	ldr	w12, [x10, x9]
10117aa60:	9f 01 00 71	cmp	w12, #0x0
10117aa64:	0d 01 00 54	b.le	0x10117aa84
10117aa68:	6e 69 69 b8	ldr	w14, [x11, x9]
10117aa6c:	08 01 0c 4b	sub	w8, w8, w12
10117aa70:	08 01 0e 0b	add	w8, w8, w14
10117aa74:	08 05 00 11	add	w8, w8, #0x1
10117aa78:	29 11 00 91	add	x9, x9, #0x4
10117aa7c:	3f 01 08 f1	cmp	x9, #0x200
10117aa80:	e1 fe ff 54	b.ne	0x10117aa5c
10117aa84:	e0 53 80 3d	str	q0, [sp, #0x140]
10117aa88:	00 01 62 1e	scvtf	d0, w8
10117aa8c:	c1 02 62 1e	scvtf	d1, w22
10117aa90:	00 18 61 1e	fdiv	d0, d0, d1
10117aa94:	01 10 6c 1e	fmov	d1, #0.50000000
10117aa98:	00 20 61 1e	fcmp	d0, d1
10117aa9c:	f5 7b 00 f9	str	x21, [sp, #0xf0]
10117aaa0:	f3 df 00 b9	str	w19, [sp, #0xdc]
10117aaa4:	0a 2c 00 54	b.ge	0x10117b024
10117aaa8:	8d 05 00 34	cbz	w13, 0x10117ab58
10117aaac:	0e 00 80 52	mov	w14, #0x0
10117aab0:	08 00 80 52	mov	w8, #0x0
10117aab4:	e9 2b 42 f9	ldr	x9, [sp, #0x450]
10117aab8:	ea 03 14 aa	mov	x10, x20
10117aabc:	4a 7d 40 93	sxtw	x10, w10
10117aac0:	2b 21 00 91	add	x11, x9, #0x8
10117aac4:	00 90 66 1e	fmov	d0, #20.00000000
10117aac8:	ec 07 40 91	add	x12, sp, #0x1, lsl #12
10117aacc:	8c c1 09 91	add	x12, x12, #0x270
10117aad0:	ed 07 40 91	add	x13, sp, #0x1, lsl #12
10117aad4:	ad c1 01 91	add	x13, x13, #0x70
10117aad8:	cf 7d 40 93	sxtw	x15, w14
10117aadc:	21 d9 6e fc	ldr	d1, [x9, w14, sxtw #3]
10117aae0:	ef 05 00 91	add	x15, x15, #0x1
10117aae4:	20 20 60 1e	fcmp	d1, d0
10117aae8:	ed 01 00 54	b.le	0x10117ab24
10117aaec:	21 79 6f fc	ldr	d1, [x9, x15, lsl #3]
10117aaf0:	20 20 60 1e	fcmp	d1, d0
10117aaf4:	8d 01 00 54	b.le	0x10117ab24
10117aaf8:	ce 09 00 11	add	w14, w14, #0x2
10117aafc:	8e d9 28 b8	str	w14, [x12, w8, sxtw #2]
10117ab00:	ff 01 14 6b	cmp	w15, w20
10117ab04:	8a 01 00 54	b.ge	0x10117ab34
10117ab08:	ee 05 00 91	add	x14, x15, #0x1
10117ab0c:	61 79 6f fc	ldr	d1, [x11, x15, lsl #3]
10117ab10:	20 20 60 1e	fcmp	d1, d0
10117ab14:	c0 c1 4a fa	ccmp	x14, x10, #0x0, gt
10117ab18:	ef 03 0e aa	mov	x15, x14
10117ab1c:	6b ff ff 54	b.lt	0x10117ab08
10117ab20:	06 00 00 14	b	0x10117ab38
10117ab24:	ee 03 0f aa	mov	x14, x15
10117ab28:	df 01 14 6b	cmp	w14, w20
10117ab2c:	2b 01 00 54	b.lt	0x10117ab50
10117ab30:	0a 00 00 14	b	0x10117ab58
10117ab34:	ee 03 0f aa	mov	x14, x15
10117ab38:	0f 7d 40 93	sxtw	x15, w8
10117ab3c:	ce 05 00 11	add	w14, w14, #0x1
10117ab40:	ae 79 2f b8	str	w14, [x13, x15, lsl #2]
10117ab44:	08 05 00 11	add	w8, w8, #0x1
10117ab48:	df 01 14 6b	cmp	w14, w20
10117ab4c:	6a 00 00 54	b.ge	0x10117ab58
10117ab50:	1f 01 02 71	cmp	w8, #0x80
10117ab54:	2b fc ff 54	b.lt	0x10117aad8
10117ab58:	e1 2b 45 f9	ldr	x1, [sp, #0xa50]
10117ab5c:	e0 03 10 91	add	x0, sp, #0x400
10117ab60:	be 1c 00 94	bl	__ZNSt3__16vectorIdNS_9allocatorIdEEE9push_backB6v15006ERKd
10117ab64:	0b 00 80 d2	mov	x11, #0x0
10117ab68:	e8 03 1b aa	mov	x8, x27
10117ab6c:	08 7d 40 93	sxtw	x8, w8
10117ab70:	e8 7f 00 f9	str	x8, [sp, #0xf8]
10117ab74:	00 10 6e 1e	fmov	d0, #1.00000000
10117ab78:	e2 47 c0 3d	ldr	q2, [sp, #0x110]
10117ab7c:	09 18 62 1e	fdiv	d9, d0, d2
10117ab80:	0b 00 00 14	b	0x10117abac
10117ab84:	e9 83 40 f9	ldr	x9, [sp, #0x100]
10117ab88:	60 7a 69 fc	ldr	d0, [x19, x9, lsl #3]
10117ab8c:	00 85 00 fc	str	d0, [x8], #0x8
10117ab90:	e8 07 02 f9	str	x8, [sp, #0x408]
10117ab94:	eb 87 40 f9	ldr	x11, [sp, #0x108]
10117ab98:	6b 05 00 91	add	x11, x11, #0x1
10117ab9c:	7f 01 02 f1	cmp	x11, #0x80
10117aba0:	fc 97 40 f9	ldr	x28, [sp, #0x128]
10117aba4:	e2 47 c0 3d	ldr	q2, [sp, #0x110]
10117aba8:	00 4c 00 54	b.eq	0x10117b528
10117abac:	e8 07 40 91	add	x8, sp, #0x1, lsl #12
10117abb0:	08 c1 09 91	add	x8, x8, #0x270
10117abb4:	16 79 6b b8	ldr	w22, [x8, x11, lsl #2]
10117abb8:	df 02 00 71	cmp	w22, #0x0
10117abbc:	6d 4b 00 54	b.le	0x10117b528
10117abc0:	68 f5 7e d3	lsl	x8, x11, #2
10117abc4:	e9 07 40 91	add	x9, sp, #0x1, lsl #12
10117abc8:	29 c1 01 91	add	x9, x9, #0x70
10117abcc:	2c 69 a8 b8	ldrsw	x12, [x9, x8]
10117abd0:	89 01 16 4b	sub	w9, w12, w22
10117abd4:	29 05 00 11	add	w9, w9, #0x1
10117abd8:	ea c3 39 91	add	x10, sp, #0xe70
10117abdc:	49 69 28 b8	str	w9, [x10, x8]
10117abe0:	c8 06 00 71	subs	w8, w22, #0x1
10117abe4:	01 01 00 54	b.ne	0x10117ac04
10117abe8:	e9 93 40 f9	ldr	x9, [sp, #0x120]
10117abec:	9f 01 09 6b	cmp	w12, w9
10117abf0:	8a 02 00 54	b.ge	0x10117ac40
10117abf4:	e9 0f 42 f9	ldr	x9, [sp, #0x418]
10117abf8:	20 79 6c fc	ldr	d0, [x9, x12, lsl #3]
10117abfc:	21 01 40 fd	ldr	d1, [x9]
10117ac00:	08 00 00 14	b	0x10117ac20
10117ac04:	e9 93 40 f9	ldr	x9, [sp, #0x120]
10117ac08:	9f 01 09 6b	cmp	w12, w9
10117ac0c:	4a 02 00 54	b.ge	0x10117ac54
10117ac10:	e9 0f 42 f9	ldr	x9, [sp, #0x418]
10117ac14:	20 79 6c fc	ldr	d0, [x9, x12, lsl #3]
10117ac18:	ca 0a 00 51	sub	w10, w22, #0x2
10117ac1c:	21 59 6a fc	ldr	d1, [x9, w10, uxtw #3]
10117ac20:	00 38 61 1e	fsub	d0, d0, d1
10117ac24:	01 08 69 1e	fmul	d1, d0, d9
10117ac28:	29 00 64 1e	fcvtas	w9, d1
10117ac2c:	69 02 00 34	cbz	w9, 0x10117ac78
10117ac30:	3c 05 00 51	sub	w28, w9, #0x1
10117ac34:	21 01 62 1e	scvtf	d1, w9
10117ac38:	0a 18 61 1e	fdiv	d10, d0, d1
10117ac3c:	11 00 00 14	b	0x10117ac80
10117ac40:	e9 0f 42 f9	ldr	x9, [sp, #0x418]
10117ac44:	ea 7f 40 f9	ldr	x10, [sp, #0xf8]
10117ac48:	20 79 6a fc	ldr	d0, [x9, x10, lsl #3]
10117ac4c:	21 01 40 fd	ldr	d1, [x9]
10117ac50:	06 00 00 14	b	0x10117ac68
10117ac54:	e9 0f 42 f9	ldr	x9, [sp, #0x418]
10117ac58:	ea 7f 40 f9	ldr	x10, [sp, #0xf8]
10117ac5c:	20 79 6a fc	ldr	d0, [x9, x10, lsl #3]
10117ac60:	ca 0a 00 51	sub	w10, w22, #0x2
10117ac64:	21 59 6a fc	ldr	d1, [x9, w10, uxtw #3]
10117ac68:	00 38 61 1e	fsub	d0, d0, d1
10117ac6c:	00 08 69 1e	fmul	d0, d0, d9
10117ac70:	1c 00 64 1e	fcvtas	w28, d0
10117ac74:	02 00 00 14	b	0x10117ac7c
10117ac78:	1c 00 80 12	mov	w28, #-0x1
10117ac7c:	4a 40 60 1e	fmov	d10, d2
10117ac80:	e9 c3 31 91	add	x9, sp, #0xc70
10117ac84:	3c 79 2b b8	str	w28, [x9, x11, lsl #2]
10117ac88:	ec 2f 10 a9	stp	x12, x11, [sp, #0x100]
10117ac8c:	6b 07 00 b4	cbz	x11, 0x10117ad78
10117ac90:	69 05 00 51	sub	w9, w11, #0x1
10117ac94:	ea 07 40 91	add	x10, sp, #0x1, lsl #12
10117ac98:	4a c1 01 91	add	x10, x10, #0x70
10117ac9c:	49 59 69 b8	ldr	w9, [x10, w9, uxtw #2]
10117aca0:	2a 05 00 11	add	w10, w9, #0x1
10117aca4:	5f 01 08 6b	cmp	w10, w8
10117aca8:	ca 0d 00 54	b.ge	0x10117ae60
10117acac:	5b 7d 7d 93	sbfiz	x27, x10, #3, #32
10117acb0:	c8 02 09 4b	sub	w8, w22, w9
10117acb4:	15 09 00 51	sub	w21, w8, #0x2
10117acb8:	07 00 00 14	b	0x10117acd4
10117acbc:	60 6a 7b fc	ldr	d0, [x19, x27]
10117acc0:	00 85 00 fc	str	d0, [x8], #0x8
10117acc4:	e8 07 02 f9	str	x8, [sp, #0x408]
10117acc8:	7b 23 00 91	add	x27, x27, #0x8
10117accc:	b5 06 00 71	subs	w21, w21, #0x1
10117acd0:	80 0c 00 54	b.eq	0x10117ae60
10117acd4:	f3 2b 45 f9	ldr	x19, [sp, #0xa50]
10117acd8:	e8 07 42 f9	ldr	x8, [sp, #0x408]
10117acdc:	e9 0b 42 f9	ldr	x9, [sp, #0x410]
10117ace0:	1f 01 09 eb	cmp	x8, x9
10117ace4:	c1 fe ff 54	b.ne	0x10117acbc
10117ace8:	f7 03 42 f9	ldr	x23, [sp, #0x400]
10117acec:	18 01 17 cb	sub	x24, x8, x23
10117acf0:	1a ff 43 93	asr	x26, x24, #3
10117acf4:	48 07 00 91	add	x8, x26, #0x1
10117acf8:	09 fd 7d d3	lsr	x9, x8, #61
10117acfc:	c9 08 03 b5	cbnz	x9, 0x101180e14
10117ad00:	09 ff 42 93	asr	x9, x24, #2
10117ad04:	3f 01 08 eb	cmp	x9, x8
10117ad08:	28 81 88 9a	csel	x8, x9, x8, hi
10117ad0c:	e9 ef 7d b2	mov	x9, #0x7ffffffffffffff8
10117ad10:	1f 03 09 eb	cmp	x24, x9
10117ad14:	09 00 fc 92	mov	x9, #0x1fffffffffffffff
10117ad18:	19 31 89 9a	csel	x25, x8, x9, lo
10117ad1c:	f9 00 00 b4	cbz	x25, 0x10117ad38
10117ad20:	28 ff 7d d3	lsr	x8, x25, #61
10117ad24:	e8 10 03 b5	cbnz	x8, 0x101180f40
10117ad28:	20 f3 7d d3	lsl	x0, x25, #3
10117ad2c:	69 5b 8d 94	bl	0x1034d1ad0 ; symbol stub for: __Znwm
10117ad30:	f4 03 00 aa	mov	x20, x0
10117ad34:	02 00 00 14	b	0x10117ad3c
10117ad38:	14 00 80 d2	mov	x20, #0x0
10117ad3c:	9a 0e 1a 8b	add	x26, x20, x26, lsl #3
10117ad40:	99 0e 19 8b	add	x25, x20, x25, lsl #3
10117ad44:	60 6a 7b fc	ldr	d0, [x19, x27]
10117ad48:	40 87 00 fc	str	d0, [x26], #0x8
10117ad4c:	e0 03 14 aa	mov	x0, x20
10117ad50:	e1 03 17 aa	mov	x1, x23
10117ad54:	e2 03 18 aa	mov	x2, x24
10117ad58:	3d 5e 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
10117ad5c:	f4 03 02 f9	str	x20, [sp, #0x400]
10117ad60:	fa 07 02 f9	str	x26, [sp, #0x408]
10117ad64:	f9 0b 02 f9	str	x25, [sp, #0x410]
10117ad68:	17 fb ff b4	cbz	x23, 0x10117acc8
10117ad6c:	e0 03 17 aa	mov	x0, x23
10117ad70:	52 5b 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10117ad74:	d5 ff ff 17	b	0x10117acc8
10117ad78:	c8 06 00 71	subs	w8, w22, #0x1
10117ad7c:	a1 00 00 54	b.ne	0x10117ad90
10117ad80:	9f 07 00 71	cmp	w28, #0x1
10117ad84:	80 a1 5b 7a	ccmp	w12, w27, #0x0, ge
10117ad88:	6a f0 ff 54	b.ge	0x10117ab94
10117ad8c:	3d 00 00 14	b	0x10117ae80
10117ad90:	df 0e 00 71	cmp	w22, #0x3
10117ad94:	c3 0a 00 54	b.lo	0x10117aeec
10117ad98:	15 f1 7d d3	lsl	x21, x8, #3
10117ad9c:	1b 01 80 52	mov	w27, #0x8
10117ada0:	07 00 00 14	b	0x10117adbc
10117ada4:	60 6a 7b fc	ldr	d0, [x19, x27]
10117ada8:	00 85 00 fc	str	d0, [x8], #0x8
10117adac:	e8 07 02 f9	str	x8, [sp, #0x408]
10117adb0:	7b 23 00 91	add	x27, x27, #0x8
10117adb4:	bf 02 1b eb	cmp	x21, x27
10117adb8:	40 05 00 54	b.eq	0x10117ae60
10117adbc:	f3 2b 45 f9	ldr	x19, [sp, #0xa50]
10117adc0:	e8 07 42 f9	ldr	x8, [sp, #0x408]
10117adc4:	e9 0b 42 f9	ldr	x9, [sp, #0x410]
10117adc8:	1f 01 09 eb	cmp	x8, x9
10117adcc:	c1 fe ff 54	b.ne	0x10117ada4
10117add0:	f7 03 42 f9	ldr	x23, [sp, #0x400]
10117add4:	18 01 17 cb	sub	x24, x8, x23
10117add8:	1a ff 43 93	asr	x26, x24, #3
10117addc:	48 07 00 91	add	x8, x26, #0x1
10117ade0:	09 fd 7d d3	lsr	x9, x8, #61
10117ade4:	a9 11 03 b5	cbnz	x9, 0x101181018
10117ade8:	09 ff 42 93	asr	x9, x24, #2
10117adec:	3f 01 08 eb	cmp	x9, x8
10117adf0:	28 81 88 9a	csel	x8, x9, x8, hi
10117adf4:	e9 ef 7d b2	mov	x9, #0x7ffffffffffffff8
10117adf8:	1f 03 09 eb	cmp	x24, x9
10117adfc:	09 00 fc 92	mov	x9, #0x1fffffffffffffff
10117ae00:	19 31 89 9a	csel	x25, x8, x9, lo
10117ae04:	f9 00 00 b4	cbz	x25, 0x10117ae20
10117ae08:	28 ff 7d d3	lsr	x8, x25, #61
10117ae0c:	88 16 03 b5	cbnz	x8, 0x1011810dc
10117ae10:	20 f3 7d d3	lsl	x0, x25, #3
10117ae14:	2f 5b 8d 94	bl	0x1034d1ad0 ; symbol stub for: __Znwm
10117ae18:	f4 03 00 aa	mov	x20, x0
10117ae1c:	02 00 00 14	b	0x10117ae24
10117ae20:	14 00 80 d2	mov	x20, #0x0
10117ae24:	9a 0e 1a 8b	add	x26, x20, x26, lsl #3
10117ae28:	99 0e 19 8b	add	x25, x20, x25, lsl #3
10117ae2c:	60 6a 7b fc	ldr	d0, [x19, x27]
10117ae30:	40 87 00 fc	str	d0, [x26], #0x8
10117ae34:	e0 03 14 aa	mov	x0, x20
10117ae38:	e1 03 17 aa	mov	x1, x23
10117ae3c:	e2 03 18 aa	mov	x2, x24
10117ae40:	03 5e 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
10117ae44:	f4 03 02 f9	str	x20, [sp, #0x400]
10117ae48:	fa 07 02 f9	str	x26, [sp, #0x408]
10117ae4c:	f9 0b 02 f9	str	x25, [sp, #0x410]
10117ae50:	17 fb ff b4	cbz	x23, 0x10117adb0
10117ae54:	e0 03 17 aa	mov	x0, x23
10117ae58:	18 5b 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10117ae5c:	d5 ff ff 17	b	0x10117adb0
10117ae60:	9f 03 00 71	cmp	w28, #0x0
10117ae64:	fb 9b 40 f9	ldr	x27, [sp, #0x130]
10117ae68:	6d e9 ff 54	b.le	0x10117ab94
10117ae6c:	df 06 00 71	cmp	w22, #0x1
10117ae70:	a1 03 00 54	b.ne	0x10117aee4
10117ae74:	e8 83 40 f9	ldr	x8, [sp, #0x100]
10117ae78:	1f 01 1b 6b	cmp	w8, w27
10117ae7c:	ca e8 ff 54	b.ge	0x10117ab94
10117ae80:	f3 2b 45 f9	ldr	x19, [sp, #0xa50]
10117ae84:	e8 07 42 f9	ldr	x8, [sp, #0x408]
10117ae88:	e9 0b 42 f9	ldr	x9, [sp, #0x410]
10117ae8c:	1f 01 09 eb	cmp	x8, x9
10117ae90:	a1 e7 ff 54	b.ne	0x10117ab84
10117ae94:	f7 03 42 f9	ldr	x23, [sp, #0x400]
10117ae98:	18 01 17 cb	sub	x24, x8, x23
10117ae9c:	15 ff 43 93	asr	x21, x24, #3
10117aea0:	a8 06 00 91	add	x8, x21, #0x1
10117aea4:	09 fd 7d d3	lsr	x9, x8, #61
10117aea8:	49 1b 03 b5	cbnz	x9, 0x101181210
10117aeac:	09 ff 42 93	asr	x9, x24, #2
10117aeb0:	3f 01 08 eb	cmp	x9, x8
10117aeb4:	28 81 88 9a	csel	x8, x9, x8, hi
10117aeb8:	e9 ef 7d b2	mov	x9, #0x7ffffffffffffff8
10117aebc:	1f 03 09 eb	cmp	x24, x9
10117aec0:	09 00 fc 92	mov	x9, #0x1fffffffffffffff
10117aec4:	16 31 89 9a	csel	x22, x8, x9, lo
10117aec8:	d6 08 00 b4	cbz	x22, 0x10117afe0
10117aecc:	c8 fe 7d d3	lsr	x8, x22, #61
10117aed0:	48 1b 03 b5	cbnz	x8, 0x101181238
10117aed4:	c0 f2 7d d3	lsl	x0, x22, #3
10117aed8:	fe 5a 8d 94	bl	0x1034d1ad0 ; symbol stub for: __Znwm
10117aedc:	f4 03 00 aa	mov	x20, x0
10117aee0:	41 00 00 14	b	0x10117afe4
10117aee4:	d6 0a 00 51	sub	w22, w22, #0x2
10117aee8:	04 00 00 14	b	0x10117aef8
10117aeec:	9f 03 00 71	cmp	w28, #0x0
10117aef0:	2d e5 ff 54	b.le	0x10117ab94
10117aef4:	16 00 80 d2	mov	x22, #0x0
10117aef8:	15 00 80 52	mov	w21, #0x0
10117aefc:	05 00 00 14	b	0x10117af10
10117af00:	2b 85 00 fc	str	d11, [x9], #0x8
10117af04:	e9 07 02 f9	str	x9, [sp, #0x408]
10117af08:	9f 03 15 6b	cmp	w28, w21
10117af0c:	40 fb ff 54	b.eq	0x10117ae74
10117af10:	e8 0f 42 f9	ldr	x8, [sp, #0x418]
10117af14:	00 79 76 fc	ldr	d0, [x8, x22, lsl #3]
10117af18:	b5 06 00 11	add	w21, w21, #0x1
10117af1c:	a1 02 62 1e	scvtf	d1, w21
10117af20:	40 01 41 1f	fmadd	d0, d10, d1, d0
10117af24:	00 40 66 1e	frinta	d0, d0
10117af28:	88 3f 95 d2	mov	x8, #0xa9fc
10117af2c:	28 5e ba f2	movk	x8, #0xd2f1, lsl #16
10117af30:	a8 49 cc f2	movk	x8, #0x624d, lsl #32
10117af34:	08 ea e7 f2	movk	x8, #0x3f50, lsl #48
10117af38:	01 01 67 9e	fmov	d1, x8
10117af3c:	0b 08 61 1e	fmul	d11, d0, d1
10117af40:	e9 07 42 f9	ldr	x9, [sp, #0x408]
10117af44:	e8 0b 42 f9	ldr	x8, [sp, #0x410]
10117af48:	3f 01 08 eb	cmp	x9, x8
10117af4c:	a3 fd ff 54	b.lo	0x10117af00
10117af50:	f7 03 42 f9	ldr	x23, [sp, #0x400]
10117af54:	38 01 17 cb	sub	x24, x9, x23
10117af58:	13 ff 43 93	asr	x19, x24, #3
10117af5c:	69 06 00 91	add	x9, x19, #0x1
10117af60:	2a fd 7d d3	lsr	x10, x9, #61
10117af64:	ca f4 02 b5	cbnz	x10, 0x101180dfc
10117af68:	08 01 17 cb	sub	x8, x8, x23
10117af6c:	0a fd 42 93	asr	x10, x8, #2
10117af70:	5f 01 09 eb	cmp	x10, x9
10117af74:	49 81 89 9a	csel	x9, x10, x9, hi
10117af78:	ea ef 7d b2	mov	x10, #0x7ffffffffffffff8
10117af7c:	1f 01 0a eb	cmp	x8, x10
10117af80:	08 00 fc 92	mov	x8, #0x1fffffffffffffff
10117af84:	39 31 88 9a	csel	x25, x9, x8, lo
10117af88:	f9 00 00 b4	cbz	x25, 0x10117afa4
10117af8c:	28 ff 7d d3	lsr	x8, x25, #61
10117af90:	28 fa 02 b5	cbnz	x8, 0x101180ed4
10117af94:	20 f3 7d d3	lsl	x0, x25, #3
10117af98:	ce 5a 8d 94	bl	0x1034d1ad0 ; symbol stub for: __Znwm
10117af9c:	f4 03 00 aa	mov	x20, x0
10117afa0:	02 00 00 14	b	0x10117afa8
10117afa4:	14 00 80 d2	mov	x20, #0x0
10117afa8:	93 0e 13 8b	add	x19, x20, x19, lsl #3
10117afac:	99 0e 19 8b	add	x25, x20, x25, lsl #3
10117afb0:	6b 86 00 fc	str	d11, [x19], #0x8
10117afb4:	e0 03 14 aa	mov	x0, x20
10117afb8:	e1 03 17 aa	mov	x1, x23
10117afbc:	e2 03 18 aa	mov	x2, x24
10117afc0:	a3 5d 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
10117afc4:	f4 03 02 f9	str	x20, [sp, #0x400]
10117afc8:	f3 07 02 f9	str	x19, [sp, #0x408]
10117afcc:	f9 0b 02 f9	str	x25, [sp, #0x410]
10117afd0:	d7 f9 ff b4	cbz	x23, 0x10117af08
10117afd4:	e0 03 17 aa	mov	x0, x23
10117afd8:	b8 5a 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10117afdc:	cb ff ff 17	b	0x10117af08
10117afe0:	14 00 80 d2	mov	x20, #0x0
10117afe4:	95 0e 15 8b	add	x21, x20, x21, lsl #3
10117afe8:	96 0e 16 8b	add	x22, x20, x22, lsl #3
10117afec:	e8 83 40 f9	ldr	x8, [sp, #0x100]
10117aff0:	60 7a 68 fc	ldr	d0, [x19, x8, lsl #3]
10117aff4:	a0 86 00 fc	str	d0, [x21], #0x8
10117aff8:	e0 03 14 aa	mov	x0, x20
10117affc:	e1 03 17 aa	mov	x1, x23
10117b000:	e2 03 18 aa	mov	x2, x24
10117b004:	92 5d 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
10117b008:	f4 03 02 f9	str	x20, [sp, #0x400]
10117b00c:	f5 07 02 f9	str	x21, [sp, #0x408]
10117b010:	f6 0b 02 f9	str	x22, [sp, #0x410]
10117b014:	17 dc ff b4	cbz	x23, 0x10117ab94
10117b018:	e0 03 17 aa	mov	x0, x23
10117b01c:	a7 5a 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10117b020:	dd fe ff 17	b	0x10117ab94
10117b024:	e1 2b 45 f9	ldr	x1, [sp, #0xa50]
10117b028:	e0 03 10 91	add	x0, sp, #0x400
10117b02c:	8b 1b 00 94	bl	__ZNSt3__16vectorIdNS_9allocatorIdEEE9push_backB6v15006ERKd
10117b030:	0a 00 80 d2	mov	x10, #0x0
10117b034:	e8 03 1b aa	mov	x8, x27
10117b038:	08 7d 40 93	sxtw	x8, w8
10117b03c:	e8 7f 00 f9	str	x8, [sp, #0xf8]
10117b040:	00 10 6e 1e	fmov	d0, #1.00000000
10117b044:	e2 47 c0 3d	ldr	q2, [sp, #0x110]
10117b048:	09 18 62 1e	fdiv	d9, d0, d2
10117b04c:	0a 00 00 14	b	0x10117b074
10117b050:	e9 83 40 f9	ldr	x9, [sp, #0x100]
10117b054:	60 7a 69 fc	ldr	d0, [x19, x9, lsl #3]
10117b058:	00 85 00 fc	str	d0, [x8], #0x8
10117b05c:	e8 07 02 f9	str	x8, [sp, #0x408]
10117b060:	ea 87 40 f9	ldr	x10, [sp, #0x108]
10117b064:	4a 05 00 91	add	x10, x10, #0x1
10117b068:	5f 01 02 f1	cmp	x10, #0x80
10117b06c:	e2 47 c0 3d	ldr	q2, [sp, #0x110]
10117b070:	e0 22 00 54	b.eq	0x10117b4cc
10117b074:	e8 07 40 91	add	x8, sp, #0x1, lsl #12
10117b078:	08 c1 19 91	add	x8, x8, #0x670
10117b07c:	16 79 6a b8	ldr	w22, [x8, x10, lsl #2]
10117b080:	df 02 00 71	cmp	w22, #0x0
10117b084:	4d 22 00 54	b.le	0x10117b4cc
10117b088:	e8 07 40 91	add	x8, sp, #0x1, lsl #12
10117b08c:	08 c1 11 91	add	x8, x8, #0x470
10117b090:	0b 79 aa b8	ldrsw	x11, [x8, x10, lsl #2]
10117b094:	d9 06 00 71	subs	w25, w22, #0x1
10117b098:	01 01 00 54	b.ne	0x10117b0b8
10117b09c:	e8 93 40 f9	ldr	x8, [sp, #0x120]
10117b0a0:	7f 01 08 6b	cmp	w11, w8
10117b0a4:	8a 02 00 54	b.ge	0x10117b0f4
10117b0a8:	e8 0f 42 f9	ldr	x8, [sp, #0x418]
10117b0ac:	00 79 6b fc	ldr	d0, [x8, x11, lsl #3]
10117b0b0:	01 01 40 fd	ldr	d1, [x8]
10117b0b4:	08 00 00 14	b	0x10117b0d4
10117b0b8:	e8 93 40 f9	ldr	x8, [sp, #0x120]
10117b0bc:	7f 01 08 6b	cmp	w11, w8
10117b0c0:	4a 02 00 54	b.ge	0x10117b108
10117b0c4:	e8 0f 42 f9	ldr	x8, [sp, #0x418]
10117b0c8:	00 79 6b fc	ldr	d0, [x8, x11, lsl #3]
10117b0cc:	c9 0a 00 51	sub	w9, w22, #0x2
10117b0d0:	01 59 69 fc	ldr	d1, [x8, w9, uxtw #3]
10117b0d4:	00 38 61 1e	fsub	d0, d0, d1
10117b0d8:	01 08 69 1e	fmul	d1, d0, d9
10117b0dc:	28 00 64 1e	fcvtas	w8, d1
10117b0e0:	68 02 00 34	cbz	w8, 0x10117b12c
10117b0e4:	1a 05 00 51	sub	w26, w8, #0x1
10117b0e8:	01 01 62 1e	scvtf	d1, w8
10117b0ec:	0a 18 61 1e	fdiv	d10, d0, d1
10117b0f0:	11 00 00 14	b	0x10117b134
10117b0f4:	e8 0f 42 f9	ldr	x8, [sp, #0x418]
10117b0f8:	e9 7f 40 f9	ldr	x9, [sp, #0xf8]
10117b0fc:	00 79 69 fc	ldr	d0, [x8, x9, lsl #3]
10117b100:	01 01 40 fd	ldr	d1, [x8]
10117b104:	06 00 00 14	b	0x10117b11c
10117b108:	e8 0f 42 f9	ldr	x8, [sp, #0x418]
10117b10c:	e9 7f 40 f9	ldr	x9, [sp, #0xf8]
10117b110:	00 79 69 fc	ldr	d0, [x8, x9, lsl #3]
10117b114:	c9 0a 00 51	sub	w9, w22, #0x2
10117b118:	01 59 69 fc	ldr	d1, [x8, w9, uxtw #3]
10117b11c:	00 38 61 1e	fsub	d0, d0, d1
10117b120:	00 08 69 1e	fmul	d0, d0, d9
10117b124:	1a 00 64 1e	fcvtas	w26, d0
10117b128:	02 00 00 14	b	0x10117b130
10117b12c:	1a 00 80 12	mov	w26, #-0x1
10117b130:	4a 40 60 1e	fmov	d10, d2
10117b134:	eb 2b 10 a9	stp	x11, x10, [sp, #0x100]
10117b138:	8a 07 00 b4	cbz	x10, 0x10117b228
10117b13c:	48 05 00 51	sub	w8, w10, #0x1
10117b140:	e9 07 40 91	add	x9, sp, #0x1, lsl #12
10117b144:	29 c1 11 91	add	x9, x9, #0x470
10117b148:	28 59 68 b8	ldr	w8, [x9, w8, uxtw #2]
10117b14c:	09 05 00 11	add	w9, w8, #0x1
10117b150:	3f 01 19 6b	cmp	w9, w25
10117b154:	4a 0e 00 54	b.ge	0x10117b31c
10117b158:	39 7d 7d 93	sbfiz	x25, x9, #3, #32
10117b15c:	c8 02 08 4b	sub	w8, w22, w8
10117b160:	13 09 00 51	sub	w19, w8, #0x2
10117b164:	07 00 00 14	b	0x10117b180
10117b168:	60 6b 79 fc	ldr	d0, [x27, x25]
10117b16c:	00 85 00 fc	str	d0, [x8], #0x8
10117b170:	e8 07 02 f9	str	x8, [sp, #0x408]
10117b174:	39 23 00 91	add	x25, x25, #0x8
10117b178:	73 06 00 71	subs	w19, w19, #0x1
10117b17c:	00 0d 00 54	b.eq	0x10117b31c
10117b180:	fb 2b 45 f9	ldr	x27, [sp, #0xa50]
10117b184:	e8 07 42 f9	ldr	x8, [sp, #0x408]
10117b188:	e9 0b 42 f9	ldr	x9, [sp, #0x410]
10117b18c:	1f 01 09 eb	cmp	x8, x9
10117b190:	c1 fe ff 54	b.ne	0x10117b168
10117b194:	f7 03 42 f9	ldr	x23, [sp, #0x400]
10117b198:	18 01 17 cb	sub	x24, x8, x23
10117b19c:	1c ff 43 93	asr	x28, x24, #3
10117b1a0:	88 07 00 91	add	x8, x28, #0x1
10117b1a4:	09 fd 7d d3	lsr	x9, x8, #61
10117b1a8:	c9 e3 02 b5	cbnz	x9, 0x101180e20
10117b1ac:	09 ff 42 93	asr	x9, x24, #2
10117b1b0:	3f 01 08 eb	cmp	x9, x8
10117b1b4:	28 81 88 9a	csel	x8, x9, x8, hi
10117b1b8:	e9 ef 7d b2	mov	x9, #0x7ffffffffffffff8
10117b1bc:	1f 03 09 eb	cmp	x24, x9
10117b1c0:	09 00 fc 92	mov	x9, #0x1fffffffffffffff
10117b1c4:	15 31 89 9a	csel	x21, x8, x9, lo
10117b1c8:	f5 00 00 b4	cbz	x21, 0x10117b1e4
10117b1cc:	a8 fe 7d d3	lsr	x8, x21, #61
10117b1d0:	c8 eb 02 b5	cbnz	x8, 0x101180f48
10117b1d4:	a0 f2 7d d3	lsl	x0, x21, #3
10117b1d8:	3e 5a 8d 94	bl	0x1034d1ad0 ; symbol stub for: __Znwm
10117b1dc:	f4 03 00 aa	mov	x20, x0
10117b1e0:	02 00 00 14	b	0x10117b1e8
10117b1e4:	14 00 80 d2	mov	x20, #0x0
10117b1e8:	9c 0e 1c 8b	add	x28, x20, x28, lsl #3
10117b1ec:	95 0e 15 8b	add	x21, x20, x21, lsl #3
10117b1f0:	60 6b 79 fc	ldr	d0, [x27, x25]
10117b1f4:	80 87 00 fc	str	d0, [x28], #0x8
10117b1f8:	e0 03 14 aa	mov	x0, x20
10117b1fc:	e1 03 17 aa	mov	x1, x23
10117b200:	e2 03 18 aa	mov	x2, x24
10117b204:	12 5d 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
10117b208:	f4 03 02 f9	str	x20, [sp, #0x400]
10117b20c:	fc 07 02 f9	str	x28, [sp, #0x408]
10117b210:	f5 0b 02 f9	str	x21, [sp, #0x410]
10117b214:	fc 97 40 f9	ldr	x28, [sp, #0x128]
10117b218:	f7 fa ff b4	cbz	x23, 0x10117b174
10117b21c:	e0 03 17 aa	mov	x0, x23
10117b220:	26 5a 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10117b224:	d4 ff ff 17	b	0x10117b174
10117b228:	df 0a 00 71	cmp	w22, #0x2
10117b22c:	c3 00 00 54	b.lo	0x10117b244
10117b230:	21 01 00 54	b.ne	0x10117b254
10117b234:	5f 03 00 71	cmp	w26, #0x0
10117b238:	4d f1 ff 54	b.le	0x10117b060
10117b23c:	16 00 80 d2	mov	x22, #0x0
10117b240:	3c 00 00 14	b	0x10117b330
10117b244:	5f 07 00 71	cmp	w26, #0x1
10117b248:	60 a1 5b 7a	ccmp	w11, w27, #0x0, ge
10117b24c:	aa f0 ff 54	b.ge	0x10117b060
10117b250:	75 00 00 14	b	0x10117b424
10117b254:	33 00 80 52	mov	w19, #0x1
10117b258:	07 00 00 14	b	0x10117b274
10117b25c:	60 7b 73 fc	ldr	d0, [x27, x19, lsl #3]
10117b260:	00 85 00 fc	str	d0, [x8], #0x8
10117b264:	e8 07 02 f9	str	x8, [sp, #0x408]
10117b268:	73 06 00 91	add	x19, x19, #0x1
10117b26c:	3f 03 13 eb	cmp	x25, x19
10117b270:	60 05 00 54	b.eq	0x10117b31c
10117b274:	fb 2b 45 f9	ldr	x27, [sp, #0xa50]
10117b278:	e8 07 42 f9	ldr	x8, [sp, #0x408]
10117b27c:	e9 0b 42 f9	ldr	x9, [sp, #0x410]
10117b280:	1f 01 09 eb	cmp	x8, x9
10117b284:	c1 fe ff 54	b.ne	0x10117b25c
10117b288:	f7 03 42 f9	ldr	x23, [sp, #0x400]
10117b28c:	18 01 17 cb	sub	x24, x8, x23
10117b290:	1c ff 43 93	asr	x28, x24, #3
10117b294:	88 07 00 91	add	x8, x28, #0x1
10117b298:	09 fd 7d d3	lsr	x9, x8, #61
10117b29c:	89 eb 02 b5	cbnz	x9, 0x10118100c
10117b2a0:	09 ff 42 93	asr	x9, x24, #2
10117b2a4:	3f 01 08 eb	cmp	x9, x8
10117b2a8:	28 81 88 9a	csel	x8, x9, x8, hi
10117b2ac:	e9 ef 7d b2	mov	x9, #0x7ffffffffffffff8
10117b2b0:	1f 03 09 eb	cmp	x24, x9
10117b2b4:	09 00 fc 92	mov	x9, #0x1fffffffffffffff
10117b2b8:	15 31 89 9a	csel	x21, x8, x9, lo
10117b2bc:	f5 00 00 b4	cbz	x21, 0x10117b2d8
10117b2c0:	a8 fe 7d d3	lsr	x8, x21, #61
10117b2c4:	08 f1 02 b5	cbnz	x8, 0x1011810e4
10117b2c8:	a0 f2 7d d3	lsl	x0, x21, #3
10117b2cc:	01 5a 8d 94	bl	0x1034d1ad0 ; symbol stub for: __Znwm
10117b2d0:	f4 03 00 aa	mov	x20, x0
10117b2d4:	02 00 00 14	b	0x10117b2dc
10117b2d8:	14 00 80 d2	mov	x20, #0x0
10117b2dc:	9c 0e 1c 8b	add	x28, x20, x28, lsl #3
10117b2e0:	95 0e 15 8b	add	x21, x20, x21, lsl #3
10117b2e4:	60 7b 73 fc	ldr	d0, [x27, x19, lsl #3]
10117b2e8:	80 87 00 fc	str	d0, [x28], #0x8
10117b2ec:	e0 03 14 aa	mov	x0, x20
10117b2f0:	e1 03 17 aa	mov	x1, x23
10117b2f4:	e2 03 18 aa	mov	x2, x24
10117b2f8:	d5 5c 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
10117b2fc:	f4 03 02 f9	str	x20, [sp, #0x400]
10117b300:	fc 07 02 f9	str	x28, [sp, #0x408]
10117b304:	f5 0b 02 f9	str	x21, [sp, #0x410]
10117b308:	fc 97 40 f9	ldr	x28, [sp, #0x128]
10117b30c:	f7 fa ff b4	cbz	x23, 0x10117b268
10117b310:	e0 03 17 aa	mov	x0, x23
10117b314:	e9 59 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10117b318:	d4 ff ff 17	b	0x10117b268
10117b31c:	5f 03 00 71	cmp	w26, #0x0
10117b320:	fb 9b 40 f9	ldr	x27, [sp, #0x130]
10117b324:	ed e9 ff 54	b.le	0x10117b060
10117b328:	d6 0a 00 71	subs	w22, w22, #0x2
10117b32c:	6b 07 00 54	b.lt	0x10117b418
10117b330:	13 00 80 52	mov	w19, #0x0
10117b334:	05 00 00 14	b	0x10117b348
10117b338:	2b 85 00 fc	str	d11, [x9], #0x8
10117b33c:	e9 07 02 f9	str	x9, [sp, #0x408]
10117b340:	5f 03 13 6b	cmp	w26, w19
10117b344:	a0 06 00 54	b.eq	0x10117b418
10117b348:	e8 0f 42 f9	ldr	x8, [sp, #0x418]
10117b34c:	00 79 76 fc	ldr	d0, [x8, x22, lsl #3]
10117b350:	73 06 00 11	add	w19, w19, #0x1
10117b354:	61 02 62 1e	scvtf	d1, w19
10117b358:	40 01 41 1f	fmadd	d0, d10, d1, d0
10117b35c:	00 40 66 1e	frinta	d0, d0
10117b360:	88 3f 95 d2	mov	x8, #0xa9fc
10117b364:	28 5e ba f2	movk	x8, #0xd2f1, lsl #16
10117b368:	a8 49 cc f2	movk	x8, #0x624d, lsl #32
10117b36c:	08 ea e7 f2	movk	x8, #0x3f50, lsl #48
10117b370:	01 01 67 9e	fmov	d1, x8
10117b374:	0b 08 61 1e	fmul	d11, d0, d1
10117b378:	e9 07 42 f9	ldr	x9, [sp, #0x408]
10117b37c:	e8 0b 42 f9	ldr	x8, [sp, #0x410]
10117b380:	3f 01 08 eb	cmp	x9, x8
10117b384:	a3 fd ff 54	b.lo	0x10117b338
10117b388:	f7 03 42 f9	ldr	x23, [sp, #0x400]
10117b38c:	38 01 17 cb	sub	x24, x9, x23
10117b390:	19 ff 43 93	asr	x25, x24, #3
10117b394:	29 07 00 91	add	x9, x25, #0x1
10117b398:	2a fd 7d d3	lsr	x10, x9, #61
10117b39c:	6a d3 02 b5	cbnz	x10, 0x101180e08
10117b3a0:	08 01 17 cb	sub	x8, x8, x23
10117b3a4:	0a fd 42 93	asr	x10, x8, #2
10117b3a8:	5f 01 09 eb	cmp	x10, x9
10117b3ac:	49 81 89 9a	csel	x9, x10, x9, hi
10117b3b0:	ea ef 7d b2	mov	x10, #0x7ffffffffffffff8
10117b3b4:	1f 01 0a eb	cmp	x8, x10
10117b3b8:	08 00 fc 92	mov	x8, #0x1fffffffffffffff
10117b3bc:	35 31 88 9a	csel	x21, x9, x8, lo
10117b3c0:	f5 00 00 b4	cbz	x21, 0x10117b3dc
10117b3c4:	a8 fe 7d d3	lsr	x8, x21, #61
10117b3c8:	a8 d8 02 b5	cbnz	x8, 0x101180edc
10117b3cc:	a0 f2 7d d3	lsl	x0, x21, #3
10117b3d0:	c0 59 8d 94	bl	0x1034d1ad0 ; symbol stub for: __Znwm
10117b3d4:	f4 03 00 aa	mov	x20, x0
10117b3d8:	02 00 00 14	b	0x10117b3e0
10117b3dc:	14 00 80 d2	mov	x20, #0x0
10117b3e0:	99 0e 19 8b	add	x25, x20, x25, lsl #3
10117b3e4:	95 0e 15 8b	add	x21, x20, x21, lsl #3
10117b3e8:	2b 87 00 fc	str	d11, [x25], #0x8
10117b3ec:	e0 03 14 aa	mov	x0, x20
10117b3f0:	e1 03 17 aa	mov	x1, x23
10117b3f4:	e2 03 18 aa	mov	x2, x24
10117b3f8:	95 5c 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
10117b3fc:	f4 03 02 f9	str	x20, [sp, #0x400]
10117b400:	f9 07 02 f9	str	x25, [sp, #0x408]
10117b404:	f5 0b 02 f9	str	x21, [sp, #0x410]
10117b408:	d7 f9 ff b4	cbz	x23, 0x10117b340
10117b40c:	e0 03 17 aa	mov	x0, x23
10117b410:	aa 59 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10117b414:	cb ff ff 17	b	0x10117b340
10117b418:	e8 83 40 f9	ldr	x8, [sp, #0x100]
10117b41c:	1f 01 1b 6b	cmp	w8, w27
10117b420:	0a e2 ff 54	b.ge	0x10117b060
10117b424:	f3 2b 45 f9	ldr	x19, [sp, #0xa50]
10117b428:	e8 07 42 f9	ldr	x8, [sp, #0x408]
10117b42c:	e9 0b 42 f9	ldr	x9, [sp, #0x410]
10117b430:	1f 01 09 eb	cmp	x8, x9
10117b434:	e1 e0 ff 54	b.ne	0x10117b050
10117b438:	f7 03 42 f9	ldr	x23, [sp, #0x400]
10117b43c:	18 01 17 cb	sub	x24, x8, x23
10117b440:	16 ff 43 93	asr	x22, x24, #3
10117b444:	c8 06 00 91	add	x8, x22, #0x1
10117b448:	09 fd 7d d3	lsr	x9, x8, #61
10117b44c:	89 ee 02 b5	cbnz	x9, 0x10118121c
10117b450:	09 ff 42 93	asr	x9, x24, #2
10117b454:	3f 01 08 eb	cmp	x9, x8
10117b458:	28 81 88 9a	csel	x8, x9, x8, hi
10117b45c:	e9 ef 7d b2	mov	x9, #0x7ffffffffffffff8
10117b460:	1f 03 09 eb	cmp	x24, x9
10117b464:	09 00 fc 92	mov	x9, #0x1fffffffffffffff
10117b468:	15 31 89 9a	csel	x21, x8, x9, lo
10117b46c:	f5 00 00 b4	cbz	x21, 0x10117b488
10117b470:	a8 fe 7d d3	lsr	x8, x21, #61
10117b474:	68 ee 02 b5	cbnz	x8, 0x101181240
10117b478:	a0 f2 7d d3	lsl	x0, x21, #3
10117b47c:	95 59 8d 94	bl	0x1034d1ad0 ; symbol stub for: __Znwm
10117b480:	f4 03 00 aa	mov	x20, x0
10117b484:	02 00 00 14	b	0x10117b48c
10117b488:	14 00 80 d2	mov	x20, #0x0
10117b48c:	96 0e 16 8b	add	x22, x20, x22, lsl #3
10117b490:	95 0e 15 8b	add	x21, x20, x21, lsl #3
10117b494:	e8 83 40 f9	ldr	x8, [sp, #0x100]
10117b498:	60 7a 68 fc	ldr	d0, [x19, x8, lsl #3]
10117b49c:	c0 86 00 fc	str	d0, [x22], #0x8
10117b4a0:	e0 03 14 aa	mov	x0, x20
10117b4a4:	e1 03 17 aa	mov	x1, x23
10117b4a8:	e2 03 18 aa	mov	x2, x24
10117b4ac:	68 5c 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
10117b4b0:	f4 03 02 f9	str	x20, [sp, #0x400]
10117b4b4:	f6 07 02 f9	str	x22, [sp, #0x408]
10117b4b8:	f5 0b 02 f9	str	x21, [sp, #0x410]
10117b4bc:	37 dd ff b4	cbz	x23, 0x10117b060
10117b4c0:	e0 03 17 aa	mov	x0, x23
10117b4c4:	7d 59 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10117b4c8:	e6 fe ff 17	b	0x10117b060
10117b4cc:	e8 73 56 b9	ldr	w8, [sp, #0x1670]
10117b4d0:	28 0c 00 34	cbz	w8, 0x10117b654
10117b4d4:	e8 07 40 91	add	x8, sp, #0x1, lsl #12
10117b4d8:	08 c1 19 91	add	x8, x8, #0x670
10117b4dc:	09 01 7e b2	orr	x9, x8, #0x4
10117b4e0:	e8 7f 60 b2	mov	x8, #-0x100000000
10117b4e4:	2a 00 c0 d2	mov	x10, #0x100000000
10117b4e8:	fa 7b 40 f9	ldr	x26, [sp, #0xf0]
10117b4ec:	ec 93 40 f9	ldr	x12, [sp, #0x120]
10117b4f0:	2b 45 40 b8	ldr	w11, [x9], #0x4
10117b4f4:	08 01 0a 8b	add	x8, x8, x10
10117b4f8:	7f 01 00 71	cmp	w11, #0x0
10117b4fc:	ac ff ff 54	b.gt	0x10117b4f0
10117b500:	08 fd 5e 93	asr	x8, x8, #30
10117b504:	e9 07 40 91	add	x9, sp, #0x1, lsl #12
10117b508:	29 c1 11 91	add	x9, x9, #0x470
10117b50c:	28 69 a8 b8	ldrsw	x8, [x9, x8]
10117b510:	09 05 00 11	add	w9, w8, #0x1
10117b514:	1f 01 0c 6b	cmp	w8, w12
10117b518:	20 b1 4c 7a	ccmp	w9, w12, #0x0, lt
10117b51c:	8b 17 00 54	b.lt	0x10117b80c
10117b520:	ff 33 01 b9	str	wzr, [sp, #0x130]
10117b524:	f1 00 00 14	b	0x10117b8e8
10117b528:	e8 73 52 b9	ldr	w8, [sp, #0x1270]
10117b52c:	e8 33 01 b9	str	w8, [sp, #0x130]
10117b530:	08 10 00 34	cbz	w8, 0x10117b730
10117b534:	e8 07 40 91	add	x8, sp, #0x1, lsl #12
10117b538:	08 c1 09 91	add	x8, x8, #0x270
10117b53c:	09 01 7e b2	orr	x9, x8, #0x4
10117b540:	e8 7f 60 b2	mov	x8, #-0x100000000
10117b544:	2a 00 c0 d2	mov	x10, #0x100000000
10117b548:	fa 7b 40 f9	ldr	x26, [sp, #0xf0]
10117b54c:	ec 93 40 f9	ldr	x12, [sp, #0x120]
10117b550:	2b 45 40 b8	ldr	w11, [x9], #0x4
10117b554:	08 01 0a 8b	add	x8, x8, x10
10117b558:	7f 01 00 71	cmp	w11, #0x0
10117b55c:	ac ff ff 54	b.gt	0x10117b550
10117b560:	08 fd 5e 93	asr	x8, x8, #30
10117b564:	e9 07 40 91	add	x9, sp, #0x1, lsl #12
10117b568:	29 c1 01 91	add	x9, x9, #0x70
10117b56c:	28 69 a8 b8	ldrsw	x8, [x9, x8]
10117b570:	09 05 00 11	add	w9, w8, #0x1
10117b574:	1f 01 0c 6b	cmp	w8, w12
10117b578:	20 b1 4c 7a	ccmp	w9, w12, #0x0, lt
10117b57c:	6a 1b 00 54	b.ge	0x10117b8e8
10117b580:	09 f1 7d d3	lsl	x9, x8, #3
10117b584:	33 21 00 91	add	x19, x9, #0x8
10117b588:	e8 03 28 2a	mvn	w8, w8
10117b58c:	15 01 0c 0b	add	w21, w8, w12
10117b590:	f8 ef 7d b2	mov	x24, #0x7ffffffffffffff8
10117b594:	19 00 fc 92	mov	x25, #0x1fffffffffffffff
10117b598:	07 00 00 14	b	0x10117b5b4
10117b59c:	40 6b 73 fc	ldr	d0, [x26, x19]
10117b5a0:	00 85 00 fc	str	d0, [x8], #0x8
10117b5a4:	e8 07 02 f9	str	x8, [sp, #0x408]
10117b5a8:	73 22 00 91	add	x19, x19, #0x8
10117b5ac:	b5 06 00 71	subs	w21, w21, #0x1
10117b5b0:	a0 19 00 54	b.eq	0x10117b8e4
10117b5b4:	fa 2b 45 f9	ldr	x26, [sp, #0xa50]
10117b5b8:	e8 07 42 f9	ldr	x8, [sp, #0x408]
10117b5bc:	e9 0b 42 f9	ldr	x9, [sp, #0x410]
10117b5c0:	1f 01 09 eb	cmp	x8, x9
10117b5c4:	c1 fe ff 54	b.ne	0x10117b59c
10117b5c8:	f6 03 42 f9	ldr	x22, [sp, #0x400]
10117b5cc:	17 01 16 cb	sub	x23, x8, x22
10117b5d0:	fb fe 43 93	asr	x27, x23, #3
10117b5d4:	68 07 00 91	add	x8, x27, #0x1
10117b5d8:	09 fd 7d d3	lsr	x9, x8, #61
10117b5dc:	a9 df 02 b5	cbnz	x9, 0x1011811d0
10117b5e0:	e9 fe 42 93	asr	x9, x23, #2
10117b5e4:	3f 01 08 eb	cmp	x9, x8
10117b5e8:	28 81 88 9a	csel	x8, x9, x8, hi
10117b5ec:	ff 02 18 eb	cmp	x23, x24
10117b5f0:	1c 31 99 9a	csel	x28, x8, x25, lo
10117b5f4:	fc 00 00 b4	cbz	x28, 0x10117b610
10117b5f8:	88 ff 7d d3	lsr	x8, x28, #61
10117b5fc:	68 df 02 b5	cbnz	x8, 0x1011811e8
10117b600:	80 f3 7d d3	lsl	x0, x28, #3
10117b604:	33 59 8d 94	bl	0x1034d1ad0 ; symbol stub for: __Znwm
10117b608:	f4 03 00 aa	mov	x20, x0
10117b60c:	02 00 00 14	b	0x10117b614
10117b610:	14 00 80 d2	mov	x20, #0x0
10117b614:	9b 0e 1b 8b	add	x27, x20, x27, lsl #3
10117b618:	9c 0e 1c 8b	add	x28, x20, x28, lsl #3
10117b61c:	40 6b 73 fc	ldr	d0, [x26, x19]
10117b620:	60 87 00 fc	str	d0, [x27], #0x8
10117b624:	e0 03 14 aa	mov	x0, x20
10117b628:	e1 03 16 aa	mov	x1, x22
10117b62c:	e2 03 17 aa	mov	x2, x23
10117b630:	07 5c 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
10117b634:	f4 03 02 f9	str	x20, [sp, #0x400]
10117b638:	fb 07 02 f9	str	x27, [sp, #0x408]
10117b63c:	fc 0b 02 f9	str	x28, [sp, #0x410]
10117b640:	fc 97 40 f9	ldr	x28, [sp, #0x128]
10117b644:	36 fb ff b4	cbz	x22, 0x10117b5a8
10117b648:	e0 03 16 aa	mov	x0, x22
10117b64c:	1b 59 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10117b650:	d6 ff ff 17	b	0x10117b5a8
10117b654:	e8 93 40 f9	ldr	x8, [sp, #0x120]
10117b658:	1f 09 00 71	cmp	w8, #0x2
10117b65c:	2b 14 00 54	b.lt	0x10117b8e0
10117b660:	e8 03 08 2a	mov	w8, w8
10117b664:	13 f1 7d d3	lsl	x19, x8, #3
10117b668:	15 01 80 52	mov	w21, #0x8
10117b66c:	f8 ef 7d b2	mov	x24, #0x7ffffffffffffff8
10117b670:	19 00 fc 92	mov	x25, #0x1fffffffffffffff
10117b674:	07 00 00 14	b	0x10117b690
10117b678:	40 6b 75 fc	ldr	d0, [x26, x21]
10117b67c:	00 85 00 fc	str	d0, [x8], #0x8
10117b680:	e8 07 02 f9	str	x8, [sp, #0x408]
10117b684:	b5 22 00 91	add	x21, x21, #0x8
10117b688:	7f 02 15 eb	cmp	x19, x21
10117b68c:	a0 12 00 54	b.eq	0x10117b8e0
10117b690:	fa 2b 45 f9	ldr	x26, [sp, #0xa50]
10117b694:	e8 07 42 f9	ldr	x8, [sp, #0x408]
10117b698:	e9 0b 42 f9	ldr	x9, [sp, #0x410]
10117b69c:	1f 01 09 eb	cmp	x8, x9
10117b6a0:	c1 fe ff 54	b.ne	0x10117b678
10117b6a4:	f6 03 42 f9	ldr	x22, [sp, #0x400]
10117b6a8:	17 01 16 cb	sub	x23, x8, x22
10117b6ac:	fb fe 43 93	asr	x27, x23, #3
10117b6b0:	68 07 00 91	add	x8, x27, #0x1
10117b6b4:	09 fd 7d d3	lsr	x9, x8, #61
10117b6b8:	09 da 02 b5	cbnz	x9, 0x1011811f8
10117b6bc:	e9 fe 42 93	asr	x9, x23, #2
10117b6c0:	3f 01 08 eb	cmp	x9, x8
10117b6c4:	28 81 88 9a	csel	x8, x9, x8, hi
10117b6c8:	ff 02 18 eb	cmp	x23, x24
10117b6cc:	1c 31 99 9a	csel	x28, x8, x25, lo
10117b6d0:	fc 00 00 b4	cbz	x28, 0x10117b6ec
10117b6d4:	88 ff 7d d3	lsr	x8, x28, #61
10117b6d8:	88 da 02 b5	cbnz	x8, 0x101181228
10117b6dc:	80 f3 7d d3	lsl	x0, x28, #3
10117b6e0:	fc 58 8d 94	bl	0x1034d1ad0 ; symbol stub for: __Znwm
10117b6e4:	f4 03 00 aa	mov	x20, x0
10117b6e8:	02 00 00 14	b	0x10117b6f0
10117b6ec:	14 00 80 d2	mov	x20, #0x0
10117b6f0:	9b 0e 1b 8b	add	x27, x20, x27, lsl #3
10117b6f4:	9c 0e 1c 8b	add	x28, x20, x28, lsl #3
10117b6f8:	40 6b 75 fc	ldr	d0, [x26, x21]
10117b6fc:	60 87 00 fc	str	d0, [x27], #0x8
10117b700:	e0 03 14 aa	mov	x0, x20
10117b704:	e1 03 16 aa	mov	x1, x22
10117b708:	e2 03 17 aa	mov	x2, x23
10117b70c:	d0 5b 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
10117b710:	f4 03 02 f9	str	x20, [sp, #0x400]
10117b714:	fb 07 02 f9	str	x27, [sp, #0x408]
10117b718:	fc 0b 02 f9	str	x28, [sp, #0x410]
10117b71c:	fc 97 40 f9	ldr	x28, [sp, #0x128]
10117b720:	36 fb ff b4	cbz	x22, 0x10117b684
10117b724:	e0 03 16 aa	mov	x0, x22
10117b728:	e4 58 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10117b72c:	d6 ff ff 17	b	0x10117b684
10117b730:	e8 93 40 f9	ldr	x8, [sp, #0x120]
10117b734:	1f 09 00 71	cmp	w8, #0x2
10117b738:	4b 0d 00 54	b.lt	0x10117b8e0
10117b73c:	e8 03 08 2a	mov	w8, w8
10117b740:	13 f1 7d d3	lsl	x19, x8, #3
10117b744:	15 01 80 52	mov	w21, #0x8
10117b748:	f8 ef 7d b2	mov	x24, #0x7ffffffffffffff8
10117b74c:	19 00 fc 92	mov	x25, #0x1fffffffffffffff
10117b750:	07 00 00 14	b	0x10117b76c
10117b754:	40 6b 75 fc	ldr	d0, [x26, x21]
10117b758:	00 85 00 fc	str	d0, [x8], #0x8
10117b75c:	e8 07 02 f9	str	x8, [sp, #0x408]
10117b760:	b5 22 00 91	add	x21, x21, #0x8
10117b764:	7f 02 15 eb	cmp	x19, x21
10117b768:	c0 0b 00 54	b.eq	0x10117b8e0
10117b76c:	fa 2b 45 f9	ldr	x26, [sp, #0xa50]
10117b770:	e8 07 42 f9	ldr	x8, [sp, #0x408]
10117b774:	e9 0b 42 f9	ldr	x9, [sp, #0x410]
10117b778:	1f 01 09 eb	cmp	x8, x9
10117b77c:	c1 fe ff 54	b.ne	0x10117b754
10117b780:	f6 03 42 f9	ldr	x22, [sp, #0x400]
10117b784:	17 01 16 cb	sub	x23, x8, x22
10117b788:	fb fe 43 93	asr	x27, x23, #3
10117b78c:	68 07 00 91	add	x8, x27, #0x1
10117b790:	09 fd 7d d3	lsr	x9, x8, #61
10117b794:	89 d3 02 b5	cbnz	x9, 0x101181204
10117b798:	e9 fe 42 93	asr	x9, x23, #2
10117b79c:	3f 01 08 eb	cmp	x9, x8
10117b7a0:	28 81 88 9a	csel	x8, x9, x8, hi
10117b7a4:	ff 02 18 eb	cmp	x23, x24
10117b7a8:	1c 31 99 9a	csel	x28, x8, x25, lo
10117b7ac:	fc 00 00 b4	cbz	x28, 0x10117b7c8
10117b7b0:	88 ff 7d d3	lsr	x8, x28, #61
10117b7b4:	e8 d3 02 b5	cbnz	x8, 0x101181230
10117b7b8:	80 f3 7d d3	lsl	x0, x28, #3
10117b7bc:	c5 58 8d 94	bl	0x1034d1ad0 ; symbol stub for: __Znwm
10117b7c0:	f4 03 00 aa	mov	x20, x0
10117b7c4:	02 00 00 14	b	0x10117b7cc
10117b7c8:	14 00 80 d2	mov	x20, #0x0
10117b7cc:	9b 0e 1b 8b	add	x27, x20, x27, lsl #3
10117b7d0:	9c 0e 1c 8b	add	x28, x20, x28, lsl #3
10117b7d4:	40 6b 75 fc	ldr	d0, [x26, x21]
10117b7d8:	60 87 00 fc	str	d0, [x27], #0x8
10117b7dc:	e0 03 14 aa	mov	x0, x20
10117b7e0:	e1 03 16 aa	mov	x1, x22
10117b7e4:	e2 03 17 aa	mov	x2, x23
10117b7e8:	99 5b 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
10117b7ec:	f4 03 02 f9	str	x20, [sp, #0x400]
10117b7f0:	fb 07 02 f9	str	x27, [sp, #0x408]
10117b7f4:	fc 0b 02 f9	str	x28, [sp, #0x410]
10117b7f8:	fc 97 40 f9	ldr	x28, [sp, #0x128]
10117b7fc:	36 fb ff b4	cbz	x22, 0x10117b760
10117b800:	e0 03 16 aa	mov	x0, x22
10117b804:	ad 58 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10117b808:	d6 ff ff 17	b	0x10117b760
10117b80c:	09 f1 7d d3	lsl	x9, x8, #3
10117b810:	33 21 00 91	add	x19, x9, #0x8
10117b814:	e8 03 28 2a	mvn	w8, w8
10117b818:	15 01 0c 0b	add	w21, w8, w12
10117b81c:	f8 ef 7d b2	mov	x24, #0x7ffffffffffffff8
10117b820:	19 00 fc 92	mov	x25, #0x1fffffffffffffff
10117b824:	07 00 00 14	b	0x10117b840
10117b828:	40 6b 73 fc	ldr	d0, [x26, x19]
10117b82c:	00 85 00 fc	str	d0, [x8], #0x8
10117b830:	e8 07 02 f9	str	x8, [sp, #0x408]
10117b834:	73 22 00 91	add	x19, x19, #0x8
10117b838:	b5 06 00 71	subs	w21, w21, #0x1
10117b83c:	20 05 00 54	b.eq	0x10117b8e0
10117b840:	fa 2b 45 f9	ldr	x26, [sp, #0xa50]
10117b844:	e8 07 42 f9	ldr	x8, [sp, #0x408]
10117b848:	e9 0b 42 f9	ldr	x9, [sp, #0x410]
10117b84c:	1f 01 09 eb	cmp	x8, x9
10117b850:	c1 fe ff 54	b.ne	0x10117b828
10117b854:	f6 03 42 f9	ldr	x22, [sp, #0x400]
10117b858:	17 01 16 cb	sub	x23, x8, x22
10117b85c:	fb fe 43 93	asr	x27, x23, #3
10117b860:	68 07 00 91	add	x8, x27, #0x1
10117b864:	09 fd 7d d3	lsr	x9, x8, #61
10117b868:	a9 cb 02 b5	cbnz	x9, 0x1011811dc
10117b86c:	e9 fe 42 93	asr	x9, x23, #2
10117b870:	3f 01 08 eb	cmp	x9, x8
10117b874:	28 81 88 9a	csel	x8, x9, x8, hi
10117b878:	ff 02 18 eb	cmp	x23, x24
10117b87c:	1c 31 99 9a	csel	x28, x8, x25, lo
10117b880:	fc 00 00 b4	cbz	x28, 0x10117b89c
10117b884:	88 ff 7d d3	lsr	x8, x28, #61
10117b888:	48 cb 02 b5	cbnz	x8, 0x1011811f0
10117b88c:	80 f3 7d d3	lsl	x0, x28, #3
10117b890:	90 58 8d 94	bl	0x1034d1ad0 ; symbol stub for: __Znwm
10117b894:	f4 03 00 aa	mov	x20, x0
10117b898:	02 00 00 14	b	0x10117b8a0
10117b89c:	14 00 80 d2	mov	x20, #0x0
10117b8a0:	9b 0e 1b 8b	add	x27, x20, x27, lsl #3
10117b8a4:	9c 0e 1c 8b	add	x28, x20, x28, lsl #3
10117b8a8:	40 6b 73 fc	ldr	d0, [x26, x19]
10117b8ac:	60 87 00 fc	str	d0, [x27], #0x8
10117b8b0:	e0 03 14 aa	mov	x0, x20
10117b8b4:	e1 03 16 aa	mov	x1, x22
10117b8b8:	e2 03 17 aa	mov	x2, x23
10117b8bc:	64 5b 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
10117b8c0:	f4 03 02 f9	str	x20, [sp, #0x400]
10117b8c4:	fb 07 02 f9	str	x27, [sp, #0x408]
10117b8c8:	fc 0b 02 f9	str	x28, [sp, #0x410]
10117b8cc:	fc 97 40 f9	ldr	x28, [sp, #0x128]
10117b8d0:	36 fb ff b4	cbz	x22, 0x10117b834
10117b8d4:	e0 03 16 aa	mov	x0, x22
10117b8d8:	78 58 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10117b8dc:	d6 ff ff 17	b	0x10117b834
10117b8e0:	ff 33 01 b9	str	wzr, [sp, #0x130]
10117b8e4:	fa 7b 40 f9	ldr	x26, [sp, #0xf0]
10117b8e8:	e8 07 42 f9	ldr	x8, [sp, #0x408]
10117b8ec:	e9 03 42 f9	ldr	x9, [sp, #0x400]
10117b8f0:	08 01 09 cb	sub	x8, x8, x9
10117b8f4:	08 fd 43 93	asr	x8, x8, #3
10117b8f8:	1f 01 1a eb	cmp	x8, x26
10117b8fc:	49 0a 00 54	b.ls	0x10117ba44
10117b900:	96 c3 01 91	add	x22, x28, #0x70
10117b904:	f4 f3 01 b2	mov	x20, #-0x5555555555555556
10117b908:	74 55 95 f2	movk	x20, #0xaaab
10117b90c:	15 03 80 52	mov	w21, #0x18
10117b910:	19 00 80 12	mov	w25, #-0x1
10117b914:	15 00 00 14	b	0x10117b968
10117b918:	e9 63 41 b9	ldr	w9, [sp, #0x160]
10117b91c:	09 7d 00 29	stp	w9, wzr, [x8]
10117b920:	08 09 00 bd	str	s8, [x8, #0x8]
10117b924:	e9 5b 41 b9	ldr	w9, [sp, #0x158]
10117b928:	09 e5 01 29	stp	w9, w25, [x8, #0xc]
10117b92c:	1f 51 00 39	strb	wzr, [x8, #0x14]
10117b930:	e9 83 0d 91	add	x9, sp, #0x360
10117b934:	29 d1 4e 78	ldurh	w9, [x9, #0xed]
10117b938:	09 51 01 78	sturh	w9, [x8, #0x15]
10117b93c:	e9 3f 51 39	ldrb	w9, [sp, #0x44f]
10117b940:	09 5d 00 39	strb	w9, [x8, #0x17]
10117b944:	08 61 00 91	add	x8, x8, #0x18
10117b948:	88 3f 00 f9	str	x8, [x28, #0x78]
10117b94c:	5a 07 00 91	add	x26, x26, #0x1
10117b950:	e8 07 42 f9	ldr	x8, [sp, #0x408]
10117b954:	e9 03 42 f9	ldr	x9, [sp, #0x400]
10117b958:	08 01 09 cb	sub	x8, x8, x9
10117b95c:	08 fd 43 93	asr	x8, x8, #3
10117b960:	1f 01 1a eb	cmp	x8, x26
10117b964:	e9 06 00 54	b.ls	0x10117ba40
10117b968:	88 a7 47 a9	ldp	x8, x9, [x28, #0x78]
10117b96c:	1f 01 09 eb	cmp	x8, x9
10117b970:	41 fd ff 54	b.ne	0x10117b918
10117b974:	d7 02 40 f9	ldr	x23, [x22]
10117b978:	18 01 17 cb	sub	x24, x8, x23
10117b97c:	08 ff 43 93	asr	x8, x24, #3
10117b980:	13 7d 14 9b	mul	x19, x8, x20
10117b984:	68 06 00 91	add	x8, x19, #0x1
10117b988:	ea f3 01 b2	mov	x10, #-0x5555555555555556
10117b98c:	4a 55 e1 f2	movk	x10, #0xaaa, lsl #48
10117b990:	1f 01 0a eb	cmp	x8, x10
10117b994:	e8 b9 02 54	b.hi	0x1011810d0
10117b998:	69 fa 7f d3	lsl	x9, x19, #1
10117b99c:	3f 01 08 eb	cmp	x9, x8
10117b9a0:	28 81 88 9a	csel	x8, x9, x8, hi
10117b9a4:	e9 f3 00 b2	mov	x9, #0x5555555555555555
10117b9a8:	a9 aa e0 f2	movk	x9, #0x555, lsl #48
10117b9ac:	7f 02 09 eb	cmp	x19, x9
10117b9b0:	1b 31 8a 9a	csel	x27, x8, x10, lo
10117b9b4:	fb 00 00 b4	cbz	x27, 0x10117b9d0
10117b9b8:	7f 03 0a eb	cmp	x27, x10
10117b9bc:	28 c0 02 54	b.hi	0x1011811c0
10117b9c0:	68 07 1b 8b	add	x8, x27, x27, lsl #1
10117b9c4:	00 f1 7d d3	lsl	x0, x8, #3
10117b9c8:	42 58 8d 94	bl	0x1034d1ad0 ; symbol stub for: __Znwm
10117b9cc:	02 00 00 14	b	0x10117b9d4
10117b9d0:	00 00 80 d2	mov	x0, #0x0
10117b9d4:	68 02 15 9b	madd	x8, x19, x21, x0
10117b9d8:	7b 03 15 9b	madd	x27, x27, x21, x0
10117b9dc:	e9 63 41 b9	ldr	w9, [sp, #0x160]
10117b9e0:	09 7d 00 29	stp	w9, wzr, [x8]
10117b9e4:	08 09 00 bd	str	s8, [x8, #0x8]
10117b9e8:	e9 5b 41 b9	ldr	w9, [sp, #0x158]
10117b9ec:	09 e5 01 29	stp	w9, w25, [x8, #0xc]
10117b9f0:	1f 51 00 39	strb	wzr, [x8, #0x14]
10117b9f4:	e9 83 0d 91	add	x9, sp, #0x360
10117b9f8:	29 d1 4e 78	ldurh	w9, [x9, #0xed]
10117b9fc:	09 51 01 78	sturh	w9, [x8, #0x15]
10117ba00:	e9 3f 51 39	ldrb	w9, [sp, #0x44f]
10117ba04:	09 5d 00 39	strb	w9, [x8, #0x17]
10117ba08:	1c 61 00 91	add	x28, x8, #0x18
10117ba0c:	13 01 18 cb	sub	x19, x8, x24
10117ba10:	e0 03 13 aa	mov	x0, x19
10117ba14:	e1 03 17 aa	mov	x1, x23
10117ba18:	e2 03 18 aa	mov	x2, x24
10117ba1c:	0c 5b 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
10117ba20:	e8 97 40 f9	ldr	x8, [sp, #0x128]
10117ba24:	13 71 07 a9	stp	x19, x28, [x8, #0x70]
10117ba28:	fc 03 08 aa	mov	x28, x8
10117ba2c:	1b 41 00 f9	str	x27, [x8, #0x80]
10117ba30:	f7 f8 ff b4	cbz	x23, 0x10117b94c
10117ba34:	e0 03 17 aa	mov	x0, x23
10117ba38:	20 58 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10117ba3c:	c4 ff ff 17	b	0x10117b94c
10117ba40:	fa 7b 40 f9	ldr	x26, [sp, #0xf0]
10117ba44:	1f 01 1a eb	cmp	x8, x26
10117ba48:	22 01 00 54	b.hs	0x10117ba6c
10117ba4c:	48 03 08 cb	sub	x8, x26, x8
10117ba50:	89 3f 40 f9	ldr	x9, [x28, #0x78]
10117ba54:	1f 05 00 f1	cmp	x8, #0x1
10117ba58:	08 85 9f 9a	csinc	x8, x8, xzr, hi
10117ba5c:	0a 03 80 52	mov	w10, #0x18
10117ba60:	08 fd 0a 9b	mneg	x8, x8, x10
10117ba64:	28 01 08 8b	add	x8, x9, x8
10117ba68:	88 3f 00 f9	str	x8, [x28, #0x78]
10117ba6c:	18 00 80 d2	mov	x24, #0x0
10117ba70:	f9 03 1c aa	mov	x25, x28
10117ba74:	28 27 c7 a9	ldp	x8, x9, [x25, #0x70]!
10117ba78:	28 01 08 cb	sub	x8, x9, x8
10117ba7c:	08 fd 43 93	asr	x8, x8, #3
10117ba80:	e9 f3 01 b2	mov	x9, #-0x5555555555555556
10117ba84:	69 55 95 f2	movk	x9, #0xaaab
10117ba88:	15 7d 09 9b	mul	x21, x8, x9
10117ba8c:	e8 07 40 91	add	x8, sp, #0x1, lsl #12
10117ba90:	08 c1 19 91	add	x8, x8, #0x670
10117ba94:	09 79 78 b8	ldr	w9, [x8, x24, lsl #2]
10117ba98:	a9 00 00 34	cbz	w9, 0x10117baac
10117ba9c:	18 07 00 91	add	x24, x24, #0x1
10117baa0:	1f 03 02 f1	cmp	x24, #0x80
10117baa4:	81 ff ff 54	b.ne	0x10117ba94
10117baa8:	18 00 80 52	mov	w24, #0x0
10117baac:	e8 33 41 b9	ldr	w8, [sp, #0x130]
10117bab0:	68 01 00 34	cbz	w8, 0x10117badc
10117bab4:	1a 00 80 d2	mov	x26, #0x0
10117bab8:	e8 07 40 91	add	x8, sp, #0x1, lsl #12
10117babc:	08 c1 09 91	add	x8, x8, #0x270
10117bac0:	08 01 7e b2	orr	x8, x8, #0x4
10117bac4:	5f ff 01 f1	cmp	x26, #0x7f
10117bac8:	e0 00 00 54	b.eq	0x10117bae4
10117bacc:	09 79 7a b8	ldr	w9, [x8, x26, lsl #2]
10117bad0:	5a 07 00 91	add	x26, x26, #0x1
10117bad4:	89 ff ff 35	cbnz	w9, 0x10117bac4
10117bad8:	04 00 00 14	b	0x10117bae8
10117badc:	1a 00 80 d2	mov	x26, #0x0
10117bae0:	02 00 00 14	b	0x10117bae8
10117bae4:	1a 00 80 52	mov	w26, #0x0
10117bae8:	f5 af 00 f9	str	x21, [sp, #0x158]
10117baec:	58 02 00 34	cbz	w24, 0x10117bb34
10117baf0:	f6 03 18 2a	mov	w22, w24
10117baf4:	e0 a3 0f 91	add	x0, sp, #0x3e8
10117baf8:	e1 03 16 aa	mov	x1, x22
10117bafc:	15 19 00 94	bl	__ZNSt3__16vectorIiNS_9allocatorIiEEEC1Em
10117bb00:	e8 73 56 b9	ldr	w8, [sp, #0x1670]
10117bb04:	1f 01 00 71	cmp	w8, #0x0
10117bb08:	08 a5 88 1a	cinc	w8, w8, lt
10117bb0c:	09 7d 01 13	asr	w9, w8, #1
10117bb10:	e8 f7 41 f9	ldr	x8, [sp, #0x3e8]
10117bb14:	09 01 00 b9	str	w9, [x8]
10117bb18:	17 07 00 51	sub	w23, w24, #0x1
10117bb1c:	1f 0b 00 71	cmp	w24, #0x2
10117bb20:	83 05 00 54	b.lo	0x10117bbd0
10117bb24:	ff 12 00 71	cmp	w23, #0x4
10117bb28:	a2 00 00 54	b.hs	0x10117bb3c
10117bb2c:	09 00 80 d2	mov	x9, #0x0
10117bb30:	15 00 00 14	b	0x10117bb84
10117bb34:	1b 00 80 52	mov	w27, #0x0
10117bb38:	c7 00 00 14	b	0x10117be54
10117bb3c:	e9 76 7e 92	and	x9, x23, #0xfffffffc
10117bb40:	ea 07 40 91	add	x10, sp, #0x1, lsl #12
10117bb44:	4a c1 19 91	add	x10, x10, #0x670
10117bb48:	4a 01 7e b2	orr	x10, x10, #0x4
10117bb4c:	0b 11 00 91	add	x11, x8, #0x4
10117bb50:	ec 07 40 91	add	x12, sp, #0x1, lsl #12
10117bb54:	8c c1 11 91	add	x12, x12, #0x470
10117bb58:	ed 03 09 aa	mov	x13, x9
10117bb5c:	80 05 c1 3c	ldr	q0, [x12], #0x10
10117bb60:	41 05 c1 3c	ldr	q1, [x10], #0x10
10117bb64:	20 84 a0 4e	add.4s	v0, v1, v0
10117bb68:	00 14 21 6f	usra.4s	v0, v0, #0x1f
10117bb6c:	00 04 3f 4f	sshr.4s	v0, v0, #0x1
10117bb70:	60 05 81 3c	str	q0, [x11], #0x10
10117bb74:	ad 11 00 f1	subs	x13, x13, #0x4
10117bb78:	21 ff ff 54	b.ne	0x10117bb5c
10117bb7c:	3f 01 17 eb	cmp	x9, x23
10117bb80:	80 02 00 54	b.eq	0x10117bbd0
10117bb84:	2b f5 7e d3	lsl	x11, x9, #2
10117bb88:	ea 07 40 91	add	x10, sp, #0x1, lsl #12
10117bb8c:	4a c1 11 91	add	x10, x10, #0x470
10117bb90:	4a 01 0b 8b	add	x10, x10, x11
10117bb94:	e9 02 09 cb	sub	x9, x23, x9
10117bb98:	6c 11 00 91	add	x12, x11, #0x4
10117bb9c:	eb 07 40 91	add	x11, sp, #0x1, lsl #12
10117bba0:	6b c1 19 91	add	x11, x11, #0x670
10117bba4:	6b 01 0c 8b	add	x11, x11, x12
10117bba8:	08 01 0c 8b	add	x8, x8, x12
10117bbac:	4c 45 40 b8	ldr	w12, [x10], #0x4
10117bbb0:	6d 45 40 b8	ldr	w13, [x11], #0x4
10117bbb4:	ac 01 0c 0b	add	w12, w13, w12
10117bbb8:	9f 01 00 71	cmp	w12, #0x0
10117bbbc:	8c a5 8c 1a	cinc	w12, w12, lt
10117bbc0:	8c 7d 01 13	asr	w12, w12, #1
10117bbc4:	0c 45 00 b8	str	w12, [x8], #0x4
10117bbc8:	29 05 00 f1	subs	x9, x9, #0x1
10117bbcc:	01 ff ff 54	b.ne	0x10117bbac
10117bbd0:	e0 e3 0e 91	add	x0, sp, #0x3b8
10117bbd4:	e1 03 16 aa	mov	x1, x22
10117bbd8:	de 18 00 94	bl	__ZNSt3__16vectorIiNS_9allocatorIiEEEC1Em
10117bbdc:	e0 43 0f 91	add	x0, sp, #0x3d0
10117bbe0:	e2 e3 0e 91	add	x2, sp, #0x3b8
10117bbe4:	e1 03 16 aa	mov	x1, x22
10117bbe8:	a8 1f 00 94	bl	__ZNSt3__16vectorINS0_IiNS_9allocatorIiEEEENS1_IS3_EEEC2EmRKS3_
10117bbec:	e0 df 41 f9	ldr	x0, [sp, #0x3b8]
10117bbf0:	60 00 00 b4	cbz	x0, 0x10117bbfc
10117bbf4:	e0 e3 01 f9	str	x0, [sp, #0x3c0]
10117bbf8:	b0 57 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10117bbfc:	f3 eb 41 f9	ldr	x19, [sp, #0x3d0]
10117bc00:	1f 07 00 71	cmp	w24, #0x1
10117bc04:	15 87 9f 1a	csinc	w21, w24, wzr, hi
10117bc08:	b4 f6 7e d3	lsl	x20, x21, #2
10117bc0c:	60 86 41 f8	ldr	x0, [x19], #0x18
10117bc10:	e1 03 14 aa	mov	x1, x20
10117bc14:	6f 58 8d 94	bl	0x1034d1dd0 ; symbol stub for: _bzero
10117bc18:	b5 06 00 f1	subs	x21, x21, #0x1
10117bc1c:	81 ff ff 54	b.ne	0x10117bc0c
10117bc20:	1f 0b 00 71	cmp	w24, #0x2
10117bc24:	83 0f 00 54	b.lo	0x10117be14
10117bc28:	09 00 80 d2	mov	x9, #0x0
10117bc2c:	e8 f7 41 f9	ldr	x8, [sp, #0x3e8]
10117bc30:	2a 03 40 f9	ldr	x10, [x25]
10117bc34:	00 10 6e 1e	fmov	d0, #1.00000000
10117bc38:	0b 11 00 91	add	x11, x8, #0x4
10117bc3c:	2c 00 80 52	mov	w12, #0x1
10117bc40:	0d 03 80 52	mov	w13, #0x18
10117bc44:	ee e7 00 b2	mov	x14, #0x3333333333333333
10117bc48:	6e fc e7 f2	movk	x14, #0x3fe3, lsl #48
10117bc4c:	ef e7 01 b2	mov	x15, #-0x6666666666666667
10117bc50:	4f 33 93 f2	movk	x15, #0x999a
10117bc54:	2f fb e7 f2	movk	x15, #0x3fd9, lsl #48
10117bc58:	30 00 80 52	mov	w16, #0x1
10117bc5c:	e1 53 c0 3d	ldr	q1, [sp, #0x140]
10117bc60:	00 18 61 1e	fdiv	d0, d0, d1
10117bc64:	f5 af 40 f9	ldr	x21, [sp, #0x158]
10117bc68:	f1 03 09 aa	mov	x17, x9
10117bc6c:	29 05 00 91	add	x9, x9, #0x1
10117bc70:	e0 eb 41 f9	ldr	x0, [sp, #0x3d0]
10117bc74:	21 7e 0d 9b	mul	x1, x17, x13
10117bc78:	00 68 61 f8	ldr	x0, [x0, x1]
10117bc7c:	00 08 10 8b	add	x0, x0, x16, lsl #2
10117bc80:	e1 03 16 aa	mov	x1, x22
10117bc84:	e2 03 0b aa	mov	x2, x11
10117bc88:	03 79 b1 b8	ldrsw	x3, [x8, x17, lsl #2]
10117bc8c:	63 7c 0d 9b	mul	x3, x3, x13
10117bc90:	44 44 80 b8	ldrsw	x4, [x2], #0x4
10117bc94:	84 7c 0d 9b	mul	x4, x4, x13
10117bc98:	43 69 63 b8	ldr	w3, [x10, x3]
10117bc9c:	44 69 64 b8	ldr	w4, [x10, x4]
10117bca0:	63 00 04 4b	sub	w3, w3, w4
10117bca4:	61 00 62 1e	scvtf	d1, w3
10117bca8:	21 08 60 1e	fmul	d1, d1, d0
10117bcac:	21 c0 60 1e	fabs	d1, d1
10117bcb0:	22 c0 65 1e	frintz	d2, d1
10117bcb4:	21 38 62 1e	fsub	d1, d1, d2
10117bcb8:	c2 01 67 9e	fmov	d2, x14
10117bcbc:	20 20 62 1e	fcmp	d1, d2
10117bcc0:	e2 01 67 9e	fmov	d2, x15
10117bcc4:	24 b4 62 1e	fccmp	d1, d2, #0x4, lt
10117bcc8:	83 c5 8c 5a	cneg	w3, w12, le
10117bccc:	03 44 00 b8	str	w3, [x0], #0x4
10117bcd0:	21 04 00 d1	sub	x1, x1, #0x1
10117bcd4:	1f 02 01 eb	cmp	x16, x1
10117bcd8:	81 fd ff 54	b.ne	0x10117bc88
10117bcdc:	10 06 00 91	add	x16, x16, #0x1
10117bce0:	6b 11 00 91	add	x11, x11, #0x4
10117bce4:	3f 01 17 eb	cmp	x9, x23
10117bce8:	01 fc ff 54	b.ne	0x10117bc68
10117bcec:	08 00 80 d2	mov	x8, #0x0
10117bcf0:	0f 00 80 52	mov	w15, #0x0
10117bcf4:	0e 00 80 52	mov	w14, #0x0
10117bcf8:	e9 eb 41 f9	ldr	x9, [sp, #0x3d0]
10117bcfc:	ca 06 00 d1	sub	x10, x22, #0x1
10117bd00:	2b 00 80 52	mov	w11, #0x1
10117bd04:	2c 01 80 52	mov	w12, #0x9
10117bd08:	0d 03 80 52	mov	w13, #0x18
10117bd0c:	07 00 00 14	b	0x10117bd28
10117bd10:	08 05 00 91	add	x8, x8, #0x1
10117bd14:	6b 05 00 91	add	x11, x11, #0x1
10117bd18:	4a 05 00 d1	sub	x10, x10, #0x1
10117bd1c:	8c 05 00 91	add	x12, x12, #0x1
10117bd20:	1f 01 17 eb	cmp	x8, x23
10117bd24:	e0 07 00 54	b.eq	0x10117be20
10117bd28:	f0 03 28 aa	mvn	x16, x8
10117bd2c:	00 02 16 8b	add	x0, x16, x22
10117bd30:	10 7d 0d 9b	mul	x16, x8, x13
10117bd34:	30 69 70 f8	ldr	x16, [x9, x16]
10117bd38:	1f 40 00 f1	cmp	x0, #0x10
10117bd3c:	62 00 00 54	b.hs	0x10117bd48
10117bd40:	f1 03 0b aa	mov	x17, x11
10117bd44:	2b 00 00 14	b	0x10117bdf0
10117bd48:	42 ed 7c 92	and	x2, x10, #0xfffffffffffffff0
10117bd4c:	01 ec 7c 92	and	x1, x0, #0xfffffffffffffff0
10117bd50:	71 01 01 8b	add	x17, x11, x1
10117bd54:	00 e4 00 6f	movi.2d	v0, #0000000000000000
10117bd58:	01 e4 00 6f	movi.2d	v1, #0000000000000000
10117bd5c:	e1 1d 04 4e	mov.s	v1[0], w15
10117bd60:	02 e4 00 6f	movi.2d	v2, #0000000000000000
10117bd64:	c2 1d 04 4e	mov.s	v2[0], w14
10117bd68:	0e 0a 0c 8b	add	x14, x16, x12, lsl #2
10117bd6c:	03 e4 00 6f	movi.2d	v3, #0000000000000000
10117bd70:	04 e4 00 6f	movi.2d	v4, #0000000000000000
10117bd74:	05 e4 00 6f	movi.2d	v5, #0000000000000000
10117bd78:	06 e4 00 6f	movi.2d	v6, #0000000000000000
10117bd7c:	07 e4 00 6f	movi.2d	v7, #0000000000000000
10117bd80:	d0 45 7f ad	ldp	q16, q17, [x14, #-0x20]
10117bd84:	d2 4d c2 ac	ldp	q18, q19, [x14], #0x40
10117bd88:	02 16 21 6f	usra.4s	v2, v16, #0x1f
10117bd8c:	25 16 21 6f	usra.4s	v5, v17, #0x1f
10117bd90:	46 16 21 6f	usra.4s	v6, v18, #0x1f
10117bd94:	67 16 21 6f	usra.4s	v7, v19, #0x1f
10117bd98:	10 8a a0 4e	cmgt.4s	v16, v16, #0
10117bd9c:	31 8a a0 4e	cmgt.4s	v17, v17, #0
10117bda0:	52 8a a0 4e	cmgt.4s	v18, v18, #0
10117bda4:	73 8a a0 4e	cmgt.4s	v19, v19, #0
10117bda8:	21 84 b0 6e	sub.4s	v1, v1, v16
10117bdac:	00 84 b1 6e	sub.4s	v0, v0, v17
10117bdb0:	63 84 b2 6e	sub.4s	v3, v3, v18
10117bdb4:	84 84 b3 6e	sub.4s	v4, v4, v19
10117bdb8:	42 40 00 f1	subs	x2, x2, #0x10
10117bdbc:	21 fe ff 54	b.ne	0x10117bd80
10117bdc0:	a2 84 a2 4e	add.4s	v2, v5, v2
10117bdc4:	c2 84 a2 4e	add.4s	v2, v6, v2
10117bdc8:	e2 84 a2 4e	add.4s	v2, v7, v2
10117bdcc:	42 b8 b1 4e	addv.4s	s2, v2
10117bdd0:	4e 00 26 1e	fmov	w14, s2
10117bdd4:	00 84 a1 4e	add.4s	v0, v0, v1
10117bdd8:	60 84 a0 4e	add.4s	v0, v3, v0
10117bddc:	80 84 a0 4e	add.4s	v0, v4, v0
10117bde0:	00 b8 b1 4e	addv.4s	s0, v0
10117bde4:	0f 00 26 1e	fmov	w15, s0
10117bde8:	1f 00 01 eb	cmp	x0, x1
10117bdec:	20 f9 ff 54	b.eq	0x10117bd10
10117bdf0:	10 0a 11 8b	add	x16, x16, x17, lsl #2
10117bdf4:	d1 02 11 cb	sub	x17, x22, x17
10117bdf8:	00 46 40 b8	ldr	w0, [x16], #0x4
10117bdfc:	1f 00 00 71	cmp	w0, #0x0
10117be00:	ce 7d 40 0b	add	w14, w14, w0, lsr #31
10117be04:	ef d5 8f 1a	cinc	w15, w15, gt
10117be08:	31 06 00 f1	subs	x17, x17, #0x1
10117be0c:	61 ff ff 54	b.ne	0x10117bdf8
10117be10:	c0 ff ff 17	b	0x10117bd10
10117be14:	0e 00 80 52	mov	w14, #0x0
10117be18:	0f 00 80 52	mov	w15, #0x0
10117be1c:	f5 af 40 f9	ldr	x21, [sp, #0x158]
10117be20:	e0 01 62 1e	scvtf	d0, w15
10117be24:	e8 01 0e 0b	add	w8, w15, w14
10117be28:	01 01 62 1e	scvtf	d1, w8
10117be2c:	02 10 6a 1e	fmov	d2, #0.25000000
10117be30:	21 08 62 1e	fmul	d1, d1, d2
10117be34:	20 20 60 1e	fcmp	d1, d0
10117be38:	fb a7 9f 1a	cset	w27, lt
10117be3c:	e0 43 0f 91	add	x0, sp, #0x3d0
10117be40:	1b b9 cc 97	bl	__ZNSt3__16vectorINS0_IiNS_9allocatorIiEEEENS1_IS3_EEED1B6v15006Ev
10117be44:	e0 f7 41 f9	ldr	x0, [sp, #0x3e8]
10117be48:	60 00 00 b4	cbz	x0, 0x10117be54
10117be4c:	e0 fb 01 f9	str	x0, [sp, #0x3f0]
10117be50:	1a 57 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10117be54:	5a 02 00 34	cbz	w26, 0x10117be9c
10117be58:	f6 03 1a 2a	mov	w22, w26
10117be5c:	e0 a3 0f 91	add	x0, sp, #0x3e8
10117be60:	e1 03 16 aa	mov	x1, x22
10117be64:	3b 18 00 94	bl	__ZNSt3__16vectorIiNS_9allocatorIiEEEC1Em
10117be68:	e8 33 41 b9	ldr	w8, [sp, #0x130]
10117be6c:	1f 01 00 71	cmp	w8, #0x0
10117be70:	08 a5 88 1a	cinc	w8, w8, lt
10117be74:	09 7d 01 13	asr	w9, w8, #1
10117be78:	e8 f7 41 f9	ldr	x8, [sp, #0x3e8]
10117be7c:	09 01 00 b9	str	w9, [x8]
10117be80:	57 07 00 51	sub	w23, w26, #0x1
10117be84:	5f 0b 00 71	cmp	w26, #0x2
10117be88:	83 05 00 54	b.lo	0x10117bf38
10117be8c:	ff 12 00 71	cmp	w23, #0x4
10117be90:	a2 00 00 54	b.hs	0x10117bea4
10117be94:	09 00 80 d2	mov	x9, #0x0
10117be98:	15 00 00 14	b	0x10117beec
10117be9c:	13 00 80 52	mov	w19, #0x0
10117bea0:	c7 00 00 14	b	0x10117c1bc
10117bea4:	e9 76 7e 92	and	x9, x23, #0xfffffffc
10117bea8:	ea 07 40 91	add	x10, sp, #0x1, lsl #12
10117beac:	4a c1 09 91	add	x10, x10, #0x270
10117beb0:	4a 01 7e b2	orr	x10, x10, #0x4
10117beb4:	0b 11 00 91	add	x11, x8, #0x4
10117beb8:	ec 07 40 91	add	x12, sp, #0x1, lsl #12
10117bebc:	8c c1 01 91	add	x12, x12, #0x70
10117bec0:	ed 03 09 aa	mov	x13, x9
10117bec4:	80 05 c1 3c	ldr	q0, [x12], #0x10
10117bec8:	41 05 c1 3c	ldr	q1, [x10], #0x10
10117becc:	20 84 a0 4e	add.4s	v0, v1, v0
10117bed0:	00 14 21 6f	usra.4s	v0, v0, #0x1f
10117bed4:	00 04 3f 4f	sshr.4s	v0, v0, #0x1
10117bed8:	60 05 81 3c	str	q0, [x11], #0x10
10117bedc:	ad 11 00 f1	subs	x13, x13, #0x4
10117bee0:	21 ff ff 54	b.ne	0x10117bec4
10117bee4:	3f 01 17 eb	cmp	x9, x23
10117bee8:	80 02 00 54	b.eq	0x10117bf38
10117beec:	2b f5 7e d3	lsl	x11, x9, #2
10117bef0:	ea 07 40 91	add	x10, sp, #0x1, lsl #12
10117bef4:	4a c1 01 91	add	x10, x10, #0x70
10117bef8:	4a 01 0b 8b	add	x10, x10, x11
10117befc:	e9 02 09 cb	sub	x9, x23, x9
10117bf00:	6c 11 00 91	add	x12, x11, #0x4
10117bf04:	eb 07 40 91	add	x11, sp, #0x1, lsl #12
10117bf08:	6b c1 09 91	add	x11, x11, #0x270
10117bf0c:	6b 01 0c 8b	add	x11, x11, x12
10117bf10:	08 01 0c 8b	add	x8, x8, x12
10117bf14:	4c 45 40 b8	ldr	w12, [x10], #0x4
10117bf18:	6d 45 40 b8	ldr	w13, [x11], #0x4
10117bf1c:	ac 01 0c 0b	add	w12, w13, w12
10117bf20:	9f 01 00 71	cmp	w12, #0x0
10117bf24:	8c a5 8c 1a	cinc	w12, w12, lt
10117bf28:	8c 7d 01 13	asr	w12, w12, #1
10117bf2c:	0c 45 00 b8	str	w12, [x8], #0x4
10117bf30:	29 05 00 f1	subs	x9, x9, #0x1
10117bf34:	01 ff ff 54	b.ne	0x10117bf14
10117bf38:	e0 e3 0e 91	add	x0, sp, #0x3b8
10117bf3c:	e1 03 16 aa	mov	x1, x22
10117bf40:	04 18 00 94	bl	__ZNSt3__16vectorIiNS_9allocatorIiEEEC1Em
10117bf44:	e0 43 0f 91	add	x0, sp, #0x3d0
10117bf48:	e2 e3 0e 91	add	x2, sp, #0x3b8
10117bf4c:	e1 03 16 aa	mov	x1, x22
10117bf50:	ce 1e 00 94	bl	__ZNSt3__16vectorINS0_IiNS_9allocatorIiEEEENS1_IS3_EEEC2EmRKS3_
10117bf54:	e0 df 41 f9	ldr	x0, [sp, #0x3b8]
10117bf58:	60 00 00 b4	cbz	x0, 0x10117bf64
10117bf5c:	e0 e3 01 f9	str	x0, [sp, #0x3c0]
10117bf60:	d6 56 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10117bf64:	f3 eb 41 f9	ldr	x19, [sp, #0x3d0]
10117bf68:	5f 07 00 71	cmp	w26, #0x1
10117bf6c:	55 87 9f 1a	csinc	w21, w26, wzr, hi
10117bf70:	b4 f6 7e d3	lsl	x20, x21, #2
10117bf74:	60 86 41 f8	ldr	x0, [x19], #0x18
10117bf78:	e1 03 14 aa	mov	x1, x20
10117bf7c:	95 57 8d 94	bl	0x1034d1dd0 ; symbol stub for: _bzero
10117bf80:	b5 06 00 f1	subs	x21, x21, #0x1
10117bf84:	81 ff ff 54	b.ne	0x10117bf74
10117bf88:	5f 0b 00 71	cmp	w26, #0x2
10117bf8c:	83 0f 00 54	b.lo	0x10117c17c
10117bf90:	09 00 80 d2	mov	x9, #0x0
10117bf94:	e8 f7 41 f9	ldr	x8, [sp, #0x3e8]
10117bf98:	2a 03 40 f9	ldr	x10, [x25]
10117bf9c:	00 10 6e 1e	fmov	d0, #1.00000000
10117bfa0:	0b 11 00 91	add	x11, x8, #0x4
10117bfa4:	2c 00 80 52	mov	w12, #0x1
10117bfa8:	0d 03 80 52	mov	w13, #0x18
10117bfac:	ee e7 00 b2	mov	x14, #0x3333333333333333
10117bfb0:	6e fc e7 f2	movk	x14, #0x3fe3, lsl #48
10117bfb4:	ef e7 01 b2	mov	x15, #-0x6666666666666667
10117bfb8:	4f 33 93 f2	movk	x15, #0x999a
10117bfbc:	2f fb e7 f2	movk	x15, #0x3fd9, lsl #48
10117bfc0:	30 00 80 52	mov	w16, #0x1
10117bfc4:	e1 53 c0 3d	ldr	q1, [sp, #0x140]
10117bfc8:	00 18 61 1e	fdiv	d0, d0, d1
10117bfcc:	f5 af 40 f9	ldr	x21, [sp, #0x158]
10117bfd0:	f1 03 09 aa	mov	x17, x9
10117bfd4:	29 05 00 91	add	x9, x9, #0x1
10117bfd8:	e0 eb 41 f9	ldr	x0, [sp, #0x3d0]
10117bfdc:	21 7e 0d 9b	mul	x1, x17, x13
10117bfe0:	00 68 61 f8	ldr	x0, [x0, x1]
10117bfe4:	00 08 10 8b	add	x0, x0, x16, lsl #2
10117bfe8:	e1 03 16 aa	mov	x1, x22
10117bfec:	e2 03 0b aa	mov	x2, x11
10117bff0:	03 79 b1 b8	ldrsw	x3, [x8, x17, lsl #2]
10117bff4:	63 7c 0d 9b	mul	x3, x3, x13
10117bff8:	44 44 80 b8	ldrsw	x4, [x2], #0x4
10117bffc:	84 7c 0d 9b	mul	x4, x4, x13
10117c000:	43 69 63 b8	ldr	w3, [x10, x3]
10117c004:	44 69 64 b8	ldr	w4, [x10, x4]
10117c008:	63 00 04 4b	sub	w3, w3, w4
10117c00c:	61 00 62 1e	scvtf	d1, w3
10117c010:	21 08 60 1e	fmul	d1, d1, d0
10117c014:	21 c0 60 1e	fabs	d1, d1
10117c018:	22 c0 65 1e	frintz	d2, d1
10117c01c:	21 38 62 1e	fsub	d1, d1, d2
10117c020:	c2 01 67 9e	fmov	d2, x14
10117c024:	20 20 62 1e	fcmp	d1, d2
10117c028:	e2 01 67 9e	fmov	d2, x15
10117c02c:	24 b4 62 1e	fccmp	d1, d2, #0x4, lt
10117c030:	83 c5 8c 5a	cneg	w3, w12, le
10117c034:	03 44 00 b8	str	w3, [x0], #0x4
10117c038:	21 04 00 d1	sub	x1, x1, #0x1
10117c03c:	1f 02 01 eb	cmp	x16, x1
10117c040:	81 fd ff 54	b.ne	0x10117bff0
10117c044:	10 06 00 91	add	x16, x16, #0x1
10117c048:	6b 11 00 91	add	x11, x11, #0x4
10117c04c:	3f 01 17 eb	cmp	x9, x23
10117c050:	01 fc ff 54	b.ne	0x10117bfd0
10117c054:	08 00 80 d2	mov	x8, #0x0
10117c058:	0f 00 80 52	mov	w15, #0x0
10117c05c:	0e 00 80 52	mov	w14, #0x0
10117c060:	e9 eb 41 f9	ldr	x9, [sp, #0x3d0]
10117c064:	ca 06 00 d1	sub	x10, x22, #0x1
10117c068:	2b 00 80 52	mov	w11, #0x1
10117c06c:	2c 01 80 52	mov	w12, #0x9
10117c070:	0d 03 80 52	mov	w13, #0x18
10117c074:	07 00 00 14	b	0x10117c090
10117c078:	08 05 00 91	add	x8, x8, #0x1
10117c07c:	6b 05 00 91	add	x11, x11, #0x1
10117c080:	4a 05 00 d1	sub	x10, x10, #0x1
10117c084:	8c 05 00 91	add	x12, x12, #0x1
10117c088:	1f 01 17 eb	cmp	x8, x23
10117c08c:	e0 07 00 54	b.eq	0x10117c188
10117c090:	f0 03 28 aa	mvn	x16, x8
10117c094:	00 02 16 8b	add	x0, x16, x22
10117c098:	10 7d 0d 9b	mul	x16, x8, x13
10117c09c:	30 69 70 f8	ldr	x16, [x9, x16]
10117c0a0:	1f 40 00 f1	cmp	x0, #0x10
10117c0a4:	62 00 00 54	b.hs	0x10117c0b0
10117c0a8:	f1 03 0b aa	mov	x17, x11
10117c0ac:	2b 00 00 14	b	0x10117c158
10117c0b0:	42 ed 7c 92	and	x2, x10, #0xfffffffffffffff0
10117c0b4:	01 ec 7c 92	and	x1, x0, #0xfffffffffffffff0
10117c0b8:	71 01 01 8b	add	x17, x11, x1
10117c0bc:	00 e4 00 6f	movi.2d	v0, #0000000000000000
10117c0c0:	01 e4 00 6f	movi.2d	v1, #0000000000000000
10117c0c4:	e1 1d 04 4e	mov.s	v1[0], w15
10117c0c8:	02 e4 00 6f	movi.2d	v2, #0000000000000000
10117c0cc:	c2 1d 04 4e	mov.s	v2[0], w14
10117c0d0:	0e 0a 0c 8b	add	x14, x16, x12, lsl #2
10117c0d4:	03 e4 00 6f	movi.2d	v3, #0000000000000000
10117c0d8:	04 e4 00 6f	movi.2d	v4, #0000000000000000
10117c0dc:	05 e4 00 6f	movi.2d	v5, #0000000000000000
10117c0e0:	06 e4 00 6f	movi.2d	v6, #0000000000000000
10117c0e4:	07 e4 00 6f	movi.2d	v7, #0000000000000000
10117c0e8:	d0 45 7f ad	ldp	q16, q17, [x14, #-0x20]
10117c0ec:	d2 4d c2 ac	ldp	q18, q19, [x14], #0x40
10117c0f0:	02 16 21 6f	usra.4s	v2, v16, #0x1f
10117c0f4:	25 16 21 6f	usra.4s	v5, v17, #0x1f
10117c0f8:	46 16 21 6f	usra.4s	v6, v18, #0x1f
10117c0fc:	67 16 21 6f	usra.4s	v7, v19, #0x1f
10117c100:	10 8a a0 4e	cmgt.4s	v16, v16, #0
10117c104:	31 8a a0 4e	cmgt.4s	v17, v17, #0
10117c108:	52 8a a0 4e	cmgt.4s	v18, v18, #0
10117c10c:	73 8a a0 4e	cmgt.4s	v19, v19, #0
10117c110:	21 84 b0 6e	sub.4s	v1, v1, v16
10117c114:	00 84 b1 6e	sub.4s	v0, v0, v17
10117c118:	63 84 b2 6e	sub.4s	v3, v3, v18
10117c11c:	84 84 b3 6e	sub.4s	v4, v4, v19
10117c120:	42 40 00 f1	subs	x2, x2, #0x10
10117c124:	21 fe ff 54	b.ne	0x10117c0e8
10117c128:	a2 84 a2 4e	add.4s	v2, v5, v2
10117c12c:	c2 84 a2 4e	add.4s	v2, v6, v2
10117c130:	e2 84 a2 4e	add.4s	v2, v7, v2
10117c134:	42 b8 b1 4e	addv.4s	s2, v2
10117c138:	4e 00 26 1e	fmov	w14, s2
10117c13c:	00 84 a1 4e	add.4s	v0, v0, v1
10117c140:	60 84 a0 4e	add.4s	v0, v3, v0
10117c144:	80 84 a0 4e	add.4s	v0, v4, v0
10117c148:	00 b8 b1 4e	addv.4s	s0, v0
10117c14c:	0f 00 26 1e	fmov	w15, s0
10117c150:	1f 00 01 eb	cmp	x0, x1
10117c154:	20 f9 ff 54	b.eq	0x10117c078
10117c158:	10 0a 11 8b	add	x16, x16, x17, lsl #2
10117c15c:	d1 02 11 cb	sub	x17, x22, x17
10117c160:	00 46 40 b8	ldr	w0, [x16], #0x4
10117c164:	1f 00 00 71	cmp	w0, #0x0
10117c168:	ce 7d 40 0b	add	w14, w14, w0, lsr #31
10117c16c:	ef d5 8f 1a	cinc	w15, w15, gt
10117c170:	31 06 00 f1	subs	x17, x17, #0x1
10117c174:	61 ff ff 54	b.ne	0x10117c160
10117c178:	c0 ff ff 17	b	0x10117c078
10117c17c:	0e 00 80 52	mov	w14, #0x0
10117c180:	0f 00 80 52	mov	w15, #0x0
10117c184:	f5 af 40 f9	ldr	x21, [sp, #0x158]
10117c188:	e0 01 62 1e	scvtf	d0, w15
10117c18c:	e8 01 0e 0b	add	w8, w15, w14
10117c190:	01 01 62 1e	scvtf	d1, w8
10117c194:	02 10 6a 1e	fmov	d2, #0.25000000
10117c198:	21 08 62 1e	fmul	d1, d1, d2
10117c19c:	20 20 60 1e	fcmp	d1, d0
10117c1a0:	f3 a7 9f 1a	cset	w19, lt
10117c1a4:	e0 43 0f 91	add	x0, sp, #0x3d0
10117c1a8:	41 b8 cc 97	bl	__ZNSt3__16vectorINS0_IiNS_9allocatorIiEEEENS1_IS3_EEED1B6v15006Ev
10117c1ac:	e0 f7 41 f9	ldr	x0, [sp, #0x3e8]
10117c1b0:	60 00 00 b4	cbz	x0, 0x10117c1bc
10117c1b4:	e0 fb 01 f9	str	x0, [sp, #0x3f0]
10117c1b8:	40 56 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10117c1bc:	f3 13 01 b9	str	w19, [sp, #0x110]
10117c1c0:	68 03 13 2a	orr	w8, w27, w19
10117c1c4:	b3 7e 40 93	sxtw	x19, w21
10117c1c8:	1f 05 00 71	cmp	w8, #0x1
10117c1cc:	f9 b3 00 f9	str	x25, [sp, #0x160]
10117c1d0:	fb 23 01 b9	str	w27, [sp, #0x120]
10117c1d4:	81 04 00 54	b.ne	0x10117c264
10117c1d8:	e0 a3 0f 91	add	x0, sp, #0x3e8
10117c1dc:	e1 03 13 aa	mov	x1, x19
10117c1e0:	04 17 00 94	bl	__ZNSt3__16vectorIdNS_9allocatorIdEEEC1Em
10117c1e4:	e0 43 0f 91	add	x0, sp, #0x3d0
10117c1e8:	e1 03 13 aa	mov	x1, x19
10117c1ec:	01 17 00 94	bl	__ZNSt3__16vectorIdNS_9allocatorIdEEEC1Em
10117c1f0:	b9 06 00 51	sub	w25, w21, #0x1
10117c1f4:	00 e4 00 2f	movi	d0, #0000000000000000
10117c1f8:	bf 0a 00 71	cmp	w21, #0x2
10117c1fc:	eb 08 00 54	b.lt	0x10117c318
10117c200:	f6 03 13 aa	mov	x22, x19
10117c204:	13 00 80 d2	mov	x19, #0x0
10117c208:	14 00 80 d2	mov	x20, #0x0
10117c20c:	97 43 19 91	add	x23, x28, #0x650
10117c210:	05 00 00 14	b	0x10117c224
10117c214:	94 06 00 91	add	x20, x20, #0x1
10117c218:	73 62 00 91	add	x19, x19, #0x18
10117c21c:	3f 03 14 eb	cmp	x25, x20
10117c220:	60 03 00 54	b.eq	0x10117c28c
10117c224:	80 4b 40 bd	ldr	s0, [x28, #0x48]
10117c228:	88 3b 40 f9	ldr	x8, [x28, #0x70]
10117c22c:	08 69 73 b8	ldr	w8, [x8, x19]
10117c230:	89 53 40 b9	ldr	w9, [x28, #0x50]
10117c234:	21 01 08 0b	add	w1, w9, w8
10117c238:	e0 03 17 aa	mov	x0, x23
10117c23c:	49 05 ff 97	bl	__ZN16BeatAnalyzer_2_014UnitBeatAdjust12calcLowIntegEfi
10117c240:	e8 f7 41 f9	ldr	x8, [sp, #0x3e8]
10117c244:	00 79 34 fc	str	d0, [x8, x20, lsl #3]
10117c248:	73 fe ff b4	cbz	x19, 0x10117c214
10117c24c:	08 20 60 1e	fcmp	d0, #0.0
10117c250:	2a fe ff 54	b.ge	0x10117c214
10117c254:	89 06 00 51	sub	w9, w20, #0x1
10117c258:	00 59 69 fc	ldr	d0, [x8, w9, uxtw #3]
10117c25c:	00 79 34 fc	str	d0, [x8, x20, lsl #3]
10117c260:	ed ff ff 17	b	0x10117c214
10117c264:	18 00 80 52	mov	w24, #0x0
10117c268:	1b 00 80 52	mov	w27, #0x0
10117c26c:	14 00 80 52	mov	w20, #0x0
10117c270:	28 03 40 f9	ldr	x8, [x25]
10117c274:	09 03 80 52	mov	w9, #0x18
10117c278:	ea e3 40 b9	ldr	w10, [sp, #0xe0]
10117c27c:	48 21 a9 9b	umaddl	x8, w10, w9, x8
10117c280:	1c 01 40 b9	ldr	w28, [x8]
10117c284:	17 0d 40 b9	ldr	w23, [x8, #0xc]
10117c288:	7f 01 00 14	b	0x10117c884
10117c28c:	e8 f7 41 f9	ldr	x8, [sp, #0x3e8]
10117c290:	3f 23 00 71	cmp	w25, #0x8
10117c294:	a2 00 00 54	b.hs	0x10117c2a8
10117c298:	09 00 80 d2	mov	x9, #0x0
10117c29c:	00 e4 00 2f	movi	d0, #0000000000000000
10117c2a0:	f3 03 16 aa	mov	x19, x22
10117c2a4:	17 00 00 14	b	0x10117c300
10117c2a8:	29 73 7d 92	and	x9, x25, #0xfffffff8
10117c2ac:	0a 81 00 91	add	x10, x8, #0x20
10117c2b0:	00 e4 00 6f	movi.2d	v0, #0000000000000000
10117c2b4:	eb 03 09 aa	mov	x11, x9
10117c2b8:	01 e4 00 6f	movi.2d	v1, #0000000000000000
10117c2bc:	02 e4 00 6f	movi.2d	v2, #0000000000000000
10117c2c0:	03 e4 00 6f	movi.2d	v3, #0000000000000000
10117c2c4:	f3 03 16 aa	mov	x19, x22
10117c2c8:	44 15 7f ad	ldp	q4, q5, [x10, #-0x20]
10117c2cc:	46 1d c2 ac	ldp	q6, q7, [x10], #0x40
10117c2d0:	00 c4 64 4e	fmaxnm.2d	v0, v0, v4
10117c2d4:	21 c4 65 4e	fmaxnm.2d	v1, v1, v5
10117c2d8:	42 c4 66 4e	fmaxnm.2d	v2, v2, v6
10117c2dc:	63 c4 67 4e	fmaxnm.2d	v3, v3, v7
10117c2e0:	6b 21 00 f1	subs	x11, x11, #0x8
10117c2e4:	21 ff ff 54	b.ne	0x10117c2c8
10117c2e8:	00 c4 61 4e	fmaxnm.2d	v0, v0, v1
10117c2ec:	00 c4 62 4e	fmaxnm.2d	v0, v0, v2
10117c2f0:	00 c4 63 4e	fmaxnm.2d	v0, v0, v3
10117c2f4:	00 c8 70 7e	fmaxnmp.2d	d0, v0
10117c2f8:	3f 01 19 eb	cmp	x9, x25
10117c2fc:	e0 00 00 54	b.eq	0x10117c318
10117c300:	08 0d 09 8b	add	x8, x8, x9, lsl #3
10117c304:	29 03 09 cb	sub	x9, x25, x9
10117c308:	01 85 40 fc	ldr	d1, [x8], #0x8
10117c30c:	00 68 61 1e	fmaxnm	d0, d0, d1
10117c310:	29 05 00 f1	subs	x9, x9, #0x1
10117c314:	a1 ff ff 54	b.ne	0x10117c308
10117c318:	01 c0 60 1e	fabs	d1, d0
10117c31c:	08 96 e7 d2	mov	x8, #0x3cb0000000000000
10117c320:	02 01 67 9e	fmov	d2, x8
10117c324:	20 20 62 1e	fcmp	d1, d2
10117c328:	ad 18 00 54	b.le	0x10117c63c
10117c32c:	bf 06 00 71	cmp	w21, #0x1
10117c330:	e2 17 c0 3d	ldr	q2, [sp, #0x50]
10117c334:	cd 00 00 54	b.le	0x10117c34c
10117c338:	e8 f7 41 f9	ldr	x8, [sp, #0x3e8]
10117c33c:	3f 23 00 71	cmp	w25, #0x8
10117c340:	a2 14 00 54	b.hs	0x10117c5d4
10117c344:	09 00 80 d2	mov	x9, #0x0
10117c348:	b4 00 00 14	b	0x10117c618
10117c34c:	14 00 80 52	mov	w20, #0x0
10117c350:	e0 eb 41 f9	ldr	x0, [sp, #0x3d0]
10117c354:	1f 00 00 f9	str	xzr, [x0]
10117c358:	f2 00 00 14	b	0x10117c720
10117c35c:	0a 55 40 b9	ldr	w10, [x8, #0x54]
10117c360:	6b 00 80 52	mov	w11, #0x3
10117c364:	5f 05 00 71	cmp	w10, #0x1
10117c368:	6a 01 9f 1a	csel	w10, w11, wzr, eq
10117c36c:	eb 07 9f 1a	cset	w11, ne
10117c370:	2d 11 00 51	sub	w13, w9, #0x4
10117c374:	ec 03 0a 2a	mov	w12, w10
10117c378:	5f 01 0d 6b	cmp	w10, w13
10117c37c:	aa 0d 00 54	b.ge	0x10117c530
10117c380:	2e 7d 40 93	sxtw	x14, w9
10117c384:	af 7d 40 93	sxtw	x15, w13
10117c388:	10 03 80 52	mov	w16, #0x18
10117c38c:	4d 21 b0 9b	umaddl	x13, w10, w16, x8
10117c390:	b1 21 03 91	add	x17, x13, #0xc8
10117c394:	01 21 00 91	add	x1, x8, #0x8
10117c398:	a2 e1 00 91	add	x2, x13, #0x38
10117c39c:	83 00 80 52	mov	w3, #0x4
10117c3a0:	04 02 80 52	mov	w4, #0x10
10117c3a4:	ed 03 0c aa	mov	x13, x12
10117c3a8:	05 00 00 14	b	0x10117c3bc
10117c3ac:	31 82 01 91	add	x17, x17, #0x60
10117c3b0:	42 80 01 91	add	x2, x2, #0x60
10117c3b4:	bf 01 0f eb	cmp	x13, x15
10117c3b8:	ea 0b 00 54	b.ge	0x10117c534
10117c3bc:	e6 03 0d aa	mov	x6, x13
10117c3c0:	ad 11 00 91	add	x13, x13, #0x4
10117c3c4:	25 01 06 4b	sub	w5, w9, w6
10117c3c8:	bf 01 0e eb	cmp	x13, x14
10117c3cc:	a5 c0 83 1a	csel	w5, w5, w3, gt
10117c3d0:	bf 04 00 71	cmp	w5, #0x1
10117c3d4:	cb fe ff 54	b.lt	0x10117c3ac
10117c3d8:	bf 44 00 71	cmp	w5, #0x11
10117c3dc:	82 00 00 54	b.hs	0x10117c3ec
10117c3e0:	07 00 80 d2	mov	x7, #0x0
10117c3e4:	00 e4 00 2f	movi	d0, #0000000000000000
10117c3e8:	32 00 00 14	b	0x10117c4b0
10117c3ec:	a7 0c 40 f2	ands	x7, x5, #0xf
10117c3f0:	87 00 87 9a	csel	x7, x4, x7, eq
10117c3f4:	a7 00 07 cb	sub	x7, x5, x7
10117c3f8:	00 e4 00 6f	movi.2d	v0, #0000000000000000
10117c3fc:	f3 03 11 aa	mov	x19, x17
10117c400:	f4 03 07 aa	mov	x20, x7
10117c404:	01 e4 00 6f	movi.2d	v1, #0000000000000000
10117c408:	02 e4 00 6f	movi.2d	v2, #0000000000000000
10117c40c:	03 e4 00 6f	movi.2d	v3, #0000000000000000
10117c410:	65 92 7b ad	ldp	q5, q4, [x19, #-0x90]
10117c414:	66 02 d4 3c	ldur	q6, [x19, #-0xc0]
10117c418:	70 9e 7e ad	ldp	q16, q7, [x19, #-0x30]
10117c41c:	71 02 da 3c	ldur	q17, [x19, #-0x60]
10117c420:	73 ca 41 ad	ldp	q19, q18, [x19, #0x30]
10117c424:	74 02 c0 3d	ldr	q20, [x19]
10117c428:	76 d6 44 ad	ldp	q22, q21, [x19, #0x90]
10117c42c:	75 a2 02 d1	sub	x21, x19, #0xa8
10117c430:	a6 92 40 0d	ld1.s	{ v6 }[1], [x21]
10117c434:	a5 18 85 4e	uzp1.4s	v5, v5, v5
10117c438:	a4 28 84 4e	trn1.4s	v4, v5, v4
10117c43c:	86 44 18 6e	mov.d	v6[1], v4[1]
10117c440:	75 22 01 d1	sub	x21, x19, #0x48
10117c444:	b1 92 40 0d	ld1.s	{ v17 }[1], [x21]
10117c448:	04 1a 90 4e	uzp1.4s	v4, v16, v16
10117c44c:	84 28 87 4e	trn1.4s	v4, v4, v7
10117c450:	91 44 18 6e	mov.d	v17[1], v4[1]
10117c454:	75 62 00 91	add	x21, x19, #0x18
10117c458:	b4 92 40 0d	ld1.s	{ v20 }[1], [x21]
10117c45c:	64 1a c0 3d	ldr	q4, [x19, #0x60]
10117c460:	65 1a 93 4e	uzp1.4s	v5, v19, v19
10117c464:	a5 28 92 4e	trn1.4s	v5, v5, v18
10117c468:	b4 44 18 6e	mov.d	v20[1], v5[1]
10117c46c:	75 e2 01 91	add	x21, x19, #0x78
10117c470:	a4 92 40 0d	ld1.s	{ v4 }[1], [x21]
10117c474:	c5 1a 96 4e	uzp1.4s	v5, v22, v22
10117c478:	a5 28 95 4e	trn1.4s	v5, v5, v21
10117c47c:	a4 44 18 6e	mov.d	v4[1], v5[1]
10117c480:	c0 d4 20 4e	fadd.4s	v0, v6, v0
10117c484:	21 d6 21 4e	fadd.4s	v1, v17, v1
10117c488:	82 d6 22 4e	fadd.4s	v2, v20, v2
10117c48c:	83 d4 23 4e	fadd.4s	v3, v4, v3
10117c490:	73 02 06 91	add	x19, x19, #0x180
10117c494:	94 42 00 f1	subs	x20, x20, #0x10
10117c498:	c1 fb ff 54	b.ne	0x10117c410
10117c49c:	20 d4 20 4e	fadd.4s	v0, v1, v0
10117c4a0:	40 d4 20 4e	fadd.4s	v0, v2, v0
10117c4a4:	60 d4 20 4e	fadd.4s	v0, v3, v0
10117c4a8:	00 d4 20 6e	faddp.4s	v0, v0, v0
10117c4ac:	00 d8 30 7e	faddp.2s	s0, v0
10117c4b0:	f3 00 06 8b	add	x19, x7, x6
10117c4b4:	73 06 10 9b	madd	x19, x19, x16, x1
10117c4b8:	61 86 41 bc	ldr	s1, [x19], #0x18
10117c4bc:	20 28 20 1e	fadd	s0, s1, s0
10117c4c0:	e7 04 00 91	add	x7, x7, #0x1
10117c4c4:	ff 00 05 eb	cmp	x7, x5
10117c4c8:	83 ff ff 54	b.lo	0x10117c4b8
10117c4cc:	a1 00 22 1e	scvtf	s1, w5
10117c4d0:	00 18 21 1e	fdiv	s0, s0, s1
10117c4d4:	bf 10 00 71	cmp	w5, #0x4
10117c4d8:	62 00 00 54	b.hs	0x10117c4e4
10117c4dc:	07 00 80 d2	mov	x7, #0x0
10117c4e0:	0d 00 00 14	b	0x10117c514
10117c4e4:	a7 74 7e 92	and	x7, x5, #0xfffffffc
10117c4e8:	f3 03 02 aa	mov	x19, x2
10117c4ec:	f4 03 07 aa	mov	x20, x7
10117c4f0:	60 02 1d bc	stur	s0, [x19, #-0x30]
10117c4f4:	60 82 1e bc	stur	s0, [x19, #-0x18]
10117c4f8:	60 02 00 bd	str	s0, [x19]
10117c4fc:	60 1a 00 bd	str	s0, [x19, #0x18]
10117c500:	73 82 01 91	add	x19, x19, #0x60
10117c504:	94 12 00 f1	subs	x20, x20, #0x4
10117c508:	41 ff ff 54	b.ne	0x10117c4f0
10117c50c:	ff 00 05 eb	cmp	x7, x5
10117c510:	e0 f4 ff 54	b.eq	0x10117c3ac
10117c514:	e6 00 06 8b	add	x6, x7, x6
10117c518:	c6 04 10 9b	madd	x6, x6, x16, x1
10117c51c:	c0 84 01 bc	str	s0, [x6], #0x18
10117c520:	e7 04 00 91	add	x7, x7, #0x1
10117c524:	ff 00 05 eb	cmp	x7, x5
10117c528:	a3 ff ff 54	b.lo	0x10117c51c
10117c52c:	a0 ff ff 17	b	0x10117c3ac
10117c530:	0d 00 80 52	mov	w13, #0x0
10117c534:	2b 01 00 37	tbnz	w11, #0x0, 0x10117c558
10117c538:	0b 03 80 52	mov	w11, #0x18
10117c53c:	4a 21 ab 9b	umaddl	x10, w10, w11, x8
10117c540:	4a 21 00 91	add	x10, x10, #0x8
10117c544:	0b 21 00 91	add	x11, x8, #0x8
10117c548:	40 01 40 bd	ldr	s0, [x10]
10117c54c:	60 85 01 bc	str	s0, [x11], #0x18
10117c550:	8c 05 00 f1	subs	x12, x12, #0x1
10117c554:	a1 ff ff 54	b.ne	0x10117c548
10117c558:	aa 05 00 71	subs	w10, w13, #0x1
10117c55c:	cb 01 00 54	b.lt	0x10117c594
10117c560:	bf 01 09 6b	cmp	w13, w9
10117c564:	8a 01 00 54	b.ge	0x10117c594
10117c568:	0b 03 80 52	mov	w11, #0x18
10117c56c:	4a 21 ab 9b	umaddl	x10, w10, w11, x8
10117c570:	4a 21 00 91	add	x10, x10, #0x8
10117c574:	29 7d 40 92	and	x9, x9, #0xffffffff
10117c578:	a8 21 ab 9b	umaddl	x8, w13, w11, x8
10117c57c:	08 21 00 91	add	x8, x8, #0x8
10117c580:	29 41 2d cb	sub	x9, x9, w13, uxtw
10117c584:	40 01 40 bd	ldr	s0, [x10]
10117c588:	00 85 01 bc	str	s0, [x8], #0x18
10117c58c:	29 05 00 f1	subs	x9, x9, #0x1
10117c590:	a1 ff ff 54	b.ne	0x10117c584
10117c594:	e0 0c 02 b4	cbz	x0, 0x101180730
10117c598:	e0 3f 0b f9	str	x0, [sp, #0x1678]
10117c59c:	64 10 00 14	b	0x10118072c
10117c5a0:	29 40 62 1e	fcvt	s9, d1
10117c5a4:	08 00 d0 d2	mov	x8, #0x800000000000
10117c5a8:	c8 0c e8 f2	movk	x8, #0x4066, lsl #48
10117c5ac:	00 01 67 9e	fmov	d0, x8
10117c5b0:	20 20 60 1e	fcmp	d1, d0
10117c5b4:	0d f6 fe 54	b.le	0x10117a474
10117c5b8:	00 10 2c 1e	fmov	s0, #0.50000000
10117c5bc:	29 09 20 1e	fmul	s9, s9, s0
10117c5c0:	e8 77 40 f9	ldr	x8, [sp, #0xe8]
10117c5c4:	09 01 00 bd	str	s9, [x8]
10117c5c8:	28 00 80 52	mov	w8, #0x1
10117c5cc:	e8 02 00 39	strb	w8, [x23]
10117c5d0:	ab f7 ff 17	b	0x10117a47c
10117c5d4:	29 73 7d 92	and	x9, x25, #0xfffffff8
10117c5d8:	01 04 08 4e	dup.2d	v1, v0[0]
10117c5dc:	41 fc 61 6e	fdiv.2d	v1, v2, v1
10117c5e0:	0a 81 00 91	add	x10, x8, #0x20
10117c5e4:	eb 03 09 aa	mov	x11, x9
10117c5e8:	42 0d 7f ad	ldp	q2, q3, [x10, #-0x20]
10117c5ec:	44 15 40 ad	ldp	q4, q5, [x10]
10117c5f0:	42 dc 61 6e	fmul.2d	v2, v2, v1
10117c5f4:	63 dc 61 6e	fmul.2d	v3, v3, v1
10117c5f8:	84 dc 61 6e	fmul.2d	v4, v4, v1
10117c5fc:	a5 dc 61 6e	fmul.2d	v5, v5, v1
10117c600:	42 0d 3f ad	stp	q2, q3, [x10, #-0x20]
10117c604:	44 15 82 ac	stp	q4, q5, [x10], #0x40
10117c608:	6b 21 00 f1	subs	x11, x11, #0x8
10117c60c:	e1 fe ff 54	b.ne	0x10117c5e8
10117c610:	3f 01 19 eb	cmp	x9, x25
10117c614:	40 01 00 54	b.eq	0x10117c63c
10117c618:	01 10 6e 1e	fmov	d1, #1.00000000
10117c61c:	08 0d 09 8b	add	x8, x8, x9, lsl #3
10117c620:	29 03 09 cb	sub	x9, x25, x9
10117c624:	20 18 60 1e	fdiv	d0, d1, d0
10117c628:	01 01 40 fd	ldr	d1, [x8]
10117c62c:	21 08 60 1e	fmul	d1, d1, d0
10117c630:	01 85 00 fc	str	d1, [x8], #0x8
10117c634:	29 05 00 f1	subs	x9, x9, #0x1
10117c638:	81 ff ff 54	b.ne	0x10117c628
10117c63c:	e0 eb 41 f9	ldr	x0, [sp, #0x3d0]
10117c640:	1f 00 00 f9	str	xzr, [x0]
10117c644:	bf 0a 00 71	cmp	w21, #0x2
10117c648:	0d 03 00 54	b.le	0x10117c6a8
10117c64c:	e8 f7 41 f9	ldr	x8, [sp, #0x3e8]
10117c650:	2a 07 00 d1	sub	x10, x25, #0x1
10117c654:	5f 21 00 f1	cmp	x10, #0x8
10117c658:	23 01 00 54	b.lo	0x10117c67c
10117c65c:	0b 20 00 91	add	x11, x0, #0x8
10117c660:	29 f3 7d d3	lsl	x9, x25, #3
10117c664:	0c 01 09 8b	add	x12, x8, x9
10117c668:	7f 01 0c eb	cmp	x11, x12
10117c66c:	a2 ec 01 54	b.hs	0x101180400
10117c670:	09 00 09 8b	add	x9, x0, x9
10117c674:	1f 01 09 eb	cmp	x8, x9
10117c678:	42 ec 01 54	b.hs	0x101180400
10117c67c:	29 00 80 52	mov	w9, #0x1
10117c680:	2a f1 7d d3	lsl	x10, x9, #3
10117c684:	08 01 0a 8b	add	x8, x8, x10
10117c688:	0a 00 0a 8b	add	x10, x0, x10
10117c68c:	29 03 09 cb	sub	x9, x25, x9
10117c690:	01 81 7f 6d	ldp	d1, d0, [x8, #-0x8]
10117c694:	00 d4 e1 7e	fabd	d0, d0, d1
10117c698:	40 85 00 fc	str	d0, [x10], #0x8
10117c69c:	08 21 00 91	add	x8, x8, #0x8
10117c6a0:	29 05 00 f1	subs	x9, x9, #0x1
10117c6a4:	61 ff ff 54	b.ne	0x10117c690
10117c6a8:	bf 0a 00 71	cmp	w21, #0x2
10117c6ac:	8b 03 00 54	b.lt	0x10117c71c
10117c6b0:	14 00 80 d2	mov	x20, #0x0
10117c6b4:	e8 f7 41 f9	ldr	x8, [sp, #0x3e8]
10117c6b8:	e9 e7 00 b2	mov	x9, #0x3333333333333333
10117c6bc:	69 fc e7 f2	movk	x9, #0x3fe3, lsl #48
10117c6c0:	ea e7 01 b2	mov	x10, #-0x6666666666666667
10117c6c4:	4a 33 93 f2	movk	x10, #0x999a
10117c6c8:	2a f9 e7 f2	movk	x10, #0x3fc9, lsl #48
10117c6cc:	eb e7 01 b2	mov	x11, #-0x6666666666666667
10117c6d0:	4b 33 93 f2	movk	x11, #0x999a
10117c6d4:	2b f7 e7 f2	movk	x11, #0x3fb9, lsl #48
10117c6d8:	04 00 00 14	b	0x10117c6e8
10117c6dc:	94 06 00 91	add	x20, x20, #0x1
10117c6e0:	3f 03 14 eb	cmp	x25, x20
10117c6e4:	c0 01 00 54	b.eq	0x10117c71c
10117c6e8:	00 79 74 fc	ldr	d0, [x8, x20, lsl #3]
10117c6ec:	21 01 67 9e	fmov	d1, x9
10117c6f0:	00 20 61 1e	fcmp	d0, d1
10117c6f4:	6c 01 00 54	b.gt	0x10117c720
10117c6f8:	34 ff ff b4	cbz	x20, 0x10117c6dc
10117c6fc:	41 01 67 9e	fmov	d1, x10
10117c700:	00 20 61 1e	fcmp	d0, d1
10117c704:	cd fe ff 54	b.le	0x10117c6dc
10117c708:	00 78 74 fc	ldr	d0, [x0, x20, lsl #3]
10117c70c:	61 01 67 9e	fmov	d1, x11
10117c710:	00 20 61 1e	fcmp	d0, d1
10117c714:	4d fe ff 54	b.le	0x10117c6dc
10117c718:	02 00 00 14	b	0x10117c720
10117c71c:	14 00 80 52	mov	w20, #0x0
10117c720:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
10117c724:	08 01 40 f9	ldr	x8, [x8]
10117c728:	09 03 80 52	mov	w9, #0x18
10117c72c:	88 22 a9 9b	umaddl	x8, w20, w9, x8
10117c730:	1c 01 40 b9	ldr	w28, [x8]
10117c734:	17 0d 40 b9	ldr	w23, [x8, #0xc]
10117c738:	48 07 00 51	sub	w8, w26, #0x1
10117c73c:	5f 0b 00 71	cmp	w26, #0x2
10117c740:	63 02 00 54	b.lo	0x10117c78c
10117c744:	e9 07 40 91	add	x9, sp, #0x1, lsl #12
10117c748:	29 c1 09 91	add	x9, x9, #0x270
10117c74c:	29 01 7e b2	orr	x9, x9, #0x4
10117c750:	ec 07 40 91	add	x12, sp, #0x1, lsl #12
10117c754:	8c c1 01 91	add	x12, x12, #0x70
10117c758:	ed 03 08 aa	mov	x13, x8
10117c75c:	05 00 00 14	b	0x10117c770
10117c760:	29 11 00 91	add	x9, x9, #0x4
10117c764:	8c 11 00 91	add	x12, x12, #0x4
10117c768:	ad 05 00 f1	subs	x13, x13, #0x1
10117c76c:	00 01 00 54	b.eq	0x10117c78c
10117c770:	8a 01 40 b9	ldr	w10, [x12]
10117c774:	5f 01 14 6b	cmp	w10, w20
10117c778:	4c ff ff 54	b.gt	0x10117c760
10117c77c:	2b 01 40 b9	ldr	w11, [x9]
10117c780:	7f 01 14 6b	cmp	w11, w20
10117c784:	eb fe ff 54	b.lt	0x10117c760
10117c788:	03 00 00 14	b	0x10117c794
10117c78c:	0b 00 80 52	mov	w11, #0x0
10117c790:	0a 00 80 52	mov	w10, #0x0
10117c794:	09 07 00 51	sub	w9, w24, #0x1
10117c798:	1f 0b 00 71	cmp	w24, #0x2
10117c79c:	83 02 00 54	b.lo	0x10117c7ec
10117c7a0:	ec 07 40 91	add	x12, sp, #0x1, lsl #12
10117c7a4:	8c c1 19 91	add	x12, x12, #0x670
10117c7a8:	8c 01 7e b2	orr	x12, x12, #0x4
10117c7ac:	ed 07 40 91	add	x13, sp, #0x1, lsl #12
10117c7b0:	ad c1 11 91	add	x13, x13, #0x470
10117c7b4:	ee 03 09 aa	mov	x14, x9
10117c7b8:	05 00 00 14	b	0x10117c7cc
10117c7bc:	8c 11 00 91	add	x12, x12, #0x4
10117c7c0:	ad 11 00 91	add	x13, x13, #0x4
10117c7c4:	ce 05 00 f1	subs	x14, x14, #0x1
10117c7c8:	20 01 00 54	b.eq	0x10117c7ec
10117c7cc:	af 01 40 b9	ldr	w15, [x13]
10117c7d0:	ff 01 14 6b	cmp	w15, w20
10117c7d4:	4c ff ff 54	b.gt	0x10117c7bc
10117c7d8:	90 01 40 b9	ldr	w16, [x12]
10117c7dc:	1f 02 14 6b	cmp	w16, w20
10117c7e0:	eb fe ff 54	b.lt	0x10117c7bc
10117c7e4:	eb 03 10 aa	mov	x11, x16
10117c7e8:	ea 03 0f aa	mov	x10, x15
10117c7ec:	ec 33 41 b9	ldr	w12, [sp, #0x130]
10117c7f0:	9f 01 14 6b	cmp	w12, w20
10117c7f4:	8c a1 8b 1a	csel	w12, w12, w11, ge
10117c7f8:	ed a3 8a 1a	csel	w13, wzr, w10, ge
10117c7fc:	0a 01 00 54	b.ge	0x10117c81c
10117c800:	fa 00 00 34	cbz	w26, 0x10117c81c
10117c804:	ec 07 40 91	add	x12, sp, #0x1, lsl #12
10117c808:	8c c1 01 91	add	x12, x12, #0x70
10117c80c:	88 d9 68 b8	ldr	w8, [x12, w8, sxtw #2]
10117c810:	1f 01 14 6b	cmp	w8, w20
10117c814:	6c c1 99 1a	csel	w12, w11, w25, gt
10117c818:	4d c1 88 1a	csel	w13, w10, w8, gt
10117c81c:	e8 73 56 b9	ldr	w8, [sp, #0x1670]
10117c820:	1f 01 14 6b	cmp	w8, w20
10117c824:	08 a1 8c 1a	csel	w8, w8, w12, ge
10117c828:	ea a3 8d 1a	csel	w10, wzr, w13, ge
10117c82c:	04 bb 40 7a	ccmp	w24, #0x0, #0x4, lt
10117c830:	e0 00 00 54	b.eq	0x10117c84c
10117c834:	e8 07 40 91	add	x8, sp, #0x1, lsl #12
10117c838:	08 c1 11 91	add	x8, x8, #0x470
10117c83c:	09 d9 69 b8	ldr	w9, [x8, w9, sxtw #2]
10117c840:	3f 01 14 6b	cmp	w9, w20
10117c844:	88 c1 99 1a	csel	w8, w12, w25, gt
10117c848:	aa c1 89 1a	csel	w10, w13, w9, gt
10117c84c:	49 01 08 2a	orr	w9, w10, w8
10117c850:	8b 42 00 11	add	w11, w20, #0x10
10117c854:	7f 01 15 6b	cmp	w11, w21
10117c858:	6b b1 99 1a	csel	w11, w11, w25, lt
10117c85c:	3f 01 00 71	cmp	w9, #0x0
10117c860:	18 11 8b 1a	csel	w24, w8, w11, ne
10117c864:	5b 11 94 1a	csel	w27, w10, w20, ne
10117c868:	e0 ef 01 f9	str	x0, [sp, #0x3d8]
10117c86c:	93 54 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10117c870:	e0 f7 41 f9	ldr	x0, [sp, #0x3e8]
10117c874:	60 00 00 b4	cbz	x0, 0x10117c880
10117c878:	e0 fb 01 f9	str	x0, [sp, #0x3f0]
10117c87c:	8f 54 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10117c880:	f9 b3 40 f9	ldr	x25, [sp, #0x160]
10117c884:	eb 03 42 f9	ldr	x11, [sp, #0x400]
10117c888:	e9 07 42 f9	ldr	x9, [sp, #0x408]
10117c88c:	7f 01 09 eb	cmp	x11, x9
10117c890:	a0 01 00 54	b.eq	0x10117c8c4
10117c894:	e8 9f 40 f9	ldr	x8, [sp, #0x138]
10117c898:	00 01 40 bd	ldr	s0, [x8]
10117c89c:	00 a4 20 0f	sshll.2d	v0, v0, #0x0
10117c8a0:	00 d8 61 5e	scvtf	d0, d0
10117c8a4:	28 03 40 f9	ldr	x8, [x25]
10117c8a8:	2a 01 0b cb	sub	x10, x9, x11
10117c8ac:	4a 21 00 d1	sub	x10, x10, #0x8
10117c8b0:	5f 21 00 f1	cmp	x10, #0x8
10117c8b4:	c2 00 00 54	b.hs	0x10117c8cc
10117c8b8:	0c 00 80 d2	mov	x12, #0x0
10117c8bc:	ea 03 0b aa	mov	x10, x11
10117c8c0:	21 00 00 14	b	0x10117c944
10117c8c4:	28 03 40 f9	ldr	x8, [x25]
10117c8c8:	34 00 00 14	b	0x10117c998
10117c8cc:	4a fd 43 d3	lsr	x10, x10, #3
10117c8d0:	4d 05 00 91	add	x13, x10, #0x1
10117c8d4:	ac f1 7f 92	and	x12, x13, #0x3ffffffffffffffe
10117c8d8:	6a 0d 0c 8b	add	x10, x11, x12, lsl #3
10117c8dc:	8e 3f 95 d2	mov	x14, #0xa9fc
10117c8e0:	2e 5e ba f2	movk	x14, #0xd2f1, lsl #16
10117c8e4:	ae 49 cc f2	movk	x14, #0x624d, lsl #32
10117c8e8:	0e ea e7 f2	movk	x14, #0x3f50, lsl #48
10117c8ec:	c1 01 67 9e	fmov	d1, x14
10117c8f0:	01 08 61 1e	fmul	d1, d0, d1
10117c8f4:	0e 61 00 91	add	x14, x8, #0x18
10117c8f8:	0f 00 c8 d2	mov	x15, #0x400000000000
10117c8fc:	ef 11 e8 f2	movk	x15, #0x408f, lsl #48
10117c900:	e2 0d 08 4e	dup.2d	v2, x15
10117c904:	ef 03 0c aa	mov	x15, x12
10117c908:	63 05 c1 3c	ldr	q3, [x11], #0x10
10117c90c:	63 dc 62 6e	fmul.2d	v3, v3, v2
10117c910:	63 88 61 6e	frinta.2d	v3, v3
10117c914:	63 90 c1 4f	fmul.2d	v3, v3, v1[0]
10117c918:	63 b8 e1 4e	fcvtzs.2d	v3, v3
10117c91c:	63 28 a1 0e	xtn.2s	v3, v3
10117c920:	c3 81 1e bc	stur	s3, [x14, #-0x18]
10117c924:	c3 91 00 0d	st1.s	{ v3 }[1], [x14]
10117c928:	df 01 1f b8	stur	wzr, [x14, #-0x10]
10117c92c:	df 09 00 b9	str	wzr, [x14, #0x8]
10117c930:	ce c1 00 91	add	x14, x14, #0x30
10117c934:	ef 09 00 f1	subs	x15, x15, #0x2
10117c938:	81 fe ff 54	b.ne	0x10117c908
10117c93c:	bf 01 0c eb	cmp	x13, x12
10117c940:	c0 02 00 54	b.eq	0x10117c998
10117c944:	0b 03 80 52	mov	w11, #0x18
10117c948:	8b 21 0b 9b	madd	x11, x12, x11, x8
10117c94c:	6b 21 00 91	add	x11, x11, #0x8
10117c950:	0c 00 c8 d2	mov	x12, #0x400000000000
10117c954:	ec 11 e8 f2	movk	x12, #0x408f, lsl #48
10117c958:	8d 3f 95 d2	mov	x13, #0xa9fc
10117c95c:	2d 5e ba f2	movk	x13, #0xd2f1, lsl #16
10117c960:	ad 49 cc f2	movk	x13, #0x624d, lsl #32
10117c964:	0d ea e7 f2	movk	x13, #0x3f50, lsl #48
10117c968:	41 85 40 fc	ldr	d1, [x10], #0x8
10117c96c:	82 01 67 9e	fmov	d2, x12
10117c970:	21 08 62 1e	fmul	d1, d1, d2
10117c974:	21 40 66 1e	frinta	d1, d1
10117c978:	a2 01 67 9e	fmov	d2, x13
10117c97c:	21 08 62 1e	fmul	d1, d1, d2
10117c980:	21 08 60 1e	fmul	d1, d1, d0
10117c984:	2e 00 78 1e	fcvtzs	w14, d1
10117c988:	6e 81 1f b8	stur	w14, [x11, #-0x8]
10117c98c:	7f 85 01 b8	str	wzr, [x11], #0x18
10117c990:	5f 01 09 eb	cmp	x10, x9
10117c994:	a1 fe ff 54	b.ne	0x10117c968
10117c998:	a9 06 00 71	subs	w9, w21, #0x1
10117c99c:	0d 03 00 54	b.le	0x10117c9fc
10117c9a0:	0a 01 40 b9	ldr	w10, [x8]
10117c9a4:	4a 01 1c 6b	subs	w10, w10, w28
10117c9a8:	4a 55 8a 5a	cneg	w10, w10, mi
10117c9ac:	0b 19 40 b9	ldr	w11, [x8, #0x18]
10117c9b0:	6b 01 1c 6b	subs	w11, w11, w28
10117c9b4:	6b 55 8b 5a	cneg	w11, w11, mi
10117c9b8:	5f 01 0b 6b	cmp	w10, w11
10117c9bc:	09 02 00 54	b.ls	0x10117c9fc
10117c9c0:	0a 00 80 d2	mov	x10, #0x0
10117c9c4:	ad 7e 40 92	and	x13, x21, #0xffffffff
10117c9c8:	0c c1 00 91	add	x12, x8, #0x30
10117c9cc:	ad 09 00 d1	sub	x13, x13, #0x2
10117c9d0:	bf 01 0a eb	cmp	x13, x10
10117c9d4:	60 01 00 54	b.eq	0x10117ca00
10117c9d8:	8e 85 41 b8	ldr	w14, [x12], #0x18
10117c9dc:	ce 01 1c 6b	subs	w14, w14, w28
10117c9e0:	ce 55 8e 5a	cneg	w14, w14, mi
10117c9e4:	4a 05 00 91	add	x10, x10, #0x1
10117c9e8:	7f 01 0e 6b	cmp	w11, w14
10117c9ec:	eb 03 0e aa	mov	x11, x14
10117c9f0:	08 ff ff 54	b.hi	0x10117c9d0
10117c9f4:	e9 03 0a aa	mov	x9, x10
10117c9f8:	02 00 00 14	b	0x10117ca00
10117c9fc:	09 00 80 52	mov	w9, #0x0
10117ca00:	e9 03 29 2a	mvn	w9, w9
10117ca04:	29 75 1e 32	orr	w9, w9, #0xfffffffc
10117ca08:	e9 02 09 0b	add	w9, w23, w9
10117ca0c:	2a 11 00 11	add	w10, w9, #0x4
10117ca10:	3f 01 00 71	cmp	w9, #0x0
10117ca14:	59 b1 89 1a	csel	w25, w10, w9, lt
10117ca18:	bf 06 00 71	cmp	w21, #0x1
10117ca1c:	f6 97 40 f9	ldr	x22, [sp, #0x128]
10117ca20:	2b 09 00 54	b.lt	0x10117cb44
10117ca24:	c9 3e 40 f9	ldr	x9, [x22, #0x78]
10117ca28:	29 01 08 cb	sub	x9, x9, x8
10117ca2c:	ea f3 01 b2	mov	x10, #-0x5555555555555556
10117ca30:	6a 55 95 f2	movk	x10, #0xaaab
10117ca34:	4a 55 e5 f2	movk	x10, #0x2aaa, lsl #48
10117ca38:	29 7d 4a 9b	smulh	x9, x9, x10
10117ca3c:	2a fd 42 93	asr	x10, x9, #2
10117ca40:	4a fd 49 8b	add	x10, x10, x9, lsr #63
10117ca44:	a9 7e 40 92	and	x9, x21, #0xffffffff
10117ca48:	2b 05 00 d1	sub	x11, x9, #0x1
10117ca4c:	5f 01 0b eb	cmp	x10, x11
10117ca50:	4b 31 8b 9a	csel	x11, x10, x11, lo
10117ca54:	6b 05 00 91	add	x11, x11, #0x1
10117ca58:	7f 15 00 f1	cmp	x11, #0x5
10117ca5c:	62 00 00 54	b.hs	0x10117ca68
10117ca60:	0b 00 80 d2	mov	x11, #0x0
10117ca64:	27 00 00 14	b	0x10117cb00
10117ca68:	6c 05 40 f2	ands	x12, x11, #0x3
10117ca6c:	8d 00 80 52	mov	w13, #0x4
10117ca70:	ac 01 8c 9a	csel	x12, x13, x12, eq
10117ca74:	6b 01 0c cb	sub	x11, x11, x12
10117ca78:	0c f1 00 91	add	x12, x8, #0x3c
10117ca7c:	ed 03 0b aa	mov	x13, x11
10117ca80:	ee 03 19 aa	mov	x14, x25
10117ca84:	cf 05 00 11	add	w15, w14, #0x1
10117ca88:	d0 09 00 11	add	w16, w14, #0x2
10117ca8c:	d1 0d 00 11	add	w17, w14, #0x3
10117ca90:	e0 03 0e 6b	negs	w0, w14
10117ca94:	00 04 00 12	and	w0, w0, #0x3
10117ca98:	c1 05 00 12	and	w1, w14, #0x3
10117ca9c:	20 44 80 5a	csneg	w0, w1, w0, mi
10117caa0:	e1 03 0f 6b	negs	w1, w15
10117caa4:	21 04 00 12	and	w1, w1, #0x3
10117caa8:	ef 05 00 12	and	w15, w15, #0x3
10117caac:	ef 45 81 5a	csneg	w15, w15, w1, mi
10117cab0:	e1 03 10 6b	negs	w1, w16
10117cab4:	21 04 00 12	and	w1, w1, #0x3
10117cab8:	10 06 00 12	and	w16, w16, #0x3
10117cabc:	10 46 81 5a	csneg	w16, w16, w1, mi
10117cac0:	e1 03 11 6b	negs	w1, w17
10117cac4:	21 04 00 12	and	w1, w1, #0x3
10117cac8:	31 06 00 12	and	w17, w17, #0x3
10117cacc:	31 46 81 5a	csneg	w17, w17, w1, mi
10117cad0:	00 04 00 11	add	w0, w0, #0x1
10117cad4:	ef 05 00 11	add	w15, w15, #0x1
10117cad8:	10 06 00 11	add	w16, w16, #0x1
10117cadc:	80 01 1d b8	stur	w0, [x12, #-0x30]
10117cae0:	8f 81 1e b8	stur	w15, [x12, #-0x18]
10117cae4:	2f 06 00 11	add	w15, w17, #0x1
10117cae8:	90 01 00 b9	str	w16, [x12]
10117caec:	8f 19 00 b9	str	w15, [x12, #0x18]
10117caf0:	ce 11 00 11	add	w14, w14, #0x4
10117caf4:	8c 81 01 91	add	x12, x12, #0x60
10117caf8:	ad 11 00 f1	subs	x13, x13, #0x4
10117cafc:	41 fc ff 54	b.ne	0x10117ca84
10117cb00:	4a 01 0b cb	sub	x10, x10, x11
10117cb04:	2c 03 0b 0b	add	w12, w25, w11
10117cb08:	0d 03 80 52	mov	w13, #0x18
10117cb0c:	68 21 0d 9b	madd	x8, x11, x13, x8
10117cb10:	08 31 00 91	add	x8, x8, #0xc
10117cb14:	29 01 0b cb	sub	x9, x9, x11
10117cb18:	6a 01 00 b4	cbz	x10, 0x10117cb44
10117cb1c:	eb 03 0c 6b	negs	w11, w12
10117cb20:	6b 05 00 12	and	w11, w11, #0x3
10117cb24:	8d 05 00 12	and	w13, w12, #0x3
10117cb28:	ab 45 8b 5a	csneg	w11, w13, w11, mi
10117cb2c:	6b 05 00 11	add	w11, w11, #0x1
10117cb30:	0b 85 01 b8	str	w11, [x8], #0x18
10117cb34:	4a 05 00 d1	sub	x10, x10, #0x1
10117cb38:	8c 05 00 11	add	w12, w12, #0x1
10117cb3c:	29 05 00 f1	subs	x9, x9, #0x1
10117cb40:	c1 fe ff 54	b.ne	0x10117cb18
10117cb44:	e8 a3 0f 91	add	x8, sp, #0x3e8
10117cb48:	a9 c1 bb 97	bl	__ZN6common12PropertyPathEv
10117cb4c:	c1 f1 01 d0	adrp	x1, 15930 ; 0x104fb6000
10117cb50:	21 24 1e 91	add	x1, x1, #0x789 ; literal pool for: "csv"
10117cb54:	e0 a3 0e 91	add	x0, sp, #0x3a8
10117cb58:	e1 b5 4c 94	bl	__ZN4juce9StringRefC1EPKc
10117cb5c:	e1 d7 41 f9	ldr	x1, [sp, #0x3a8]
10117cb60:	e8 c3 0e 91	add	x8, sp, #0x3b0
10117cb64:	e0 a3 0f 91	add	x0, sp, #0x3e8
10117cb68:	46 d3 4c 94	bl	__ZNK4juce4File12getChildFileENS_9StringRefE
10117cb6c:	e0 a3 0f 91	add	x0, sp, #0x3e8
10117cb70:	e3 b6 4c 94	bl	__ZN4juce6StringD1Ev
10117cb74:	e0 c3 0e 91	add	x0, sp, #0x3b0
10117cb78:	92 d7 4c 94	bl	__ZNK4juce4File6existsEv
10117cb7c:	c0 00 00 37	tbnz	w0, #0x0, 0x10117cb94
10117cb80:	e8 83 0e 91	add	x8, sp, #0x3a0
10117cb84:	e0 c3 0e 91	add	x0, sp, #0x3b0
10117cb88:	37 d9 4c 94	bl	__ZNK4juce4File15createDirectoryEv
10117cb8c:	e0 83 0e 91	add	x0, sp, #0x3a0
10117cb90:	db b6 4c 94	bl	__ZN4juce6StringD1Ev
10117cb94:	c1 f1 01 d0	adrp	x1, 15930 ; 0x104fb6000
10117cb98:	21 94 1e 91	add	x1, x1, #0x7a5 ; literal pool for: "interval2.csv"
10117cb9c:	e0 43 0e 91	add	x0, sp, #0x390
10117cba0:	cf b5 4c 94	bl	__ZN4juce9StringRefC1EPKc
10117cba4:	e1 cb 41 f9	ldr	x1, [sp, #0x390]
10117cba8:	e8 63 0e 91	add	x8, sp, #0x398
10117cbac:	e0 c3 0e 91	add	x0, sp, #0x3b0
10117cbb0:	34 d3 4c 94	bl	__ZNK4juce4File12getChildFileENS_9StringRefE
10117cbb4:	ba 06 00 71	subs	w26, w21, #0x1
10117cbb8:	cd 09 00 54	b.le	0x10117ccf0
10117cbbc:	f8 4f 10 a9	stp	x24, x19, [sp, #0x100]
10117cbc0:	15 00 80 d2	mov	x21, #0x0
10117cbc4:	1c 00 80 d2	mov	x28, #0x0
10117cbc8:	f6 f3 01 b2	mov	x22, #-0x5555555555555556
10117cbcc:	76 55 95 f2	movk	x22, #0xaaab
10117cbd0:	13 00 c8 d2	mov	x19, #0x400000000000
10117cbd4:	f3 11 e8 f2	movk	x19, #0x408f, lsl #48
10117cbd8:	d7 f1 01 d0	adrp	x23, 15930 ; 0x104fb6000
10117cbdc:	f7 ce 1e 91	add	x23, x23, #0x7b3 ; literal pool for: "%.3f\015\n"
10117cbe0:	98 ef 01 b0	adrp	x24, 15857 ; 0x104f6d000
10117cbe4:	18 db 1a 91	add	x24, x24, #0x6b6 ; literal pool for: "\015\n"
10117cbe8:	9c 07 00 91	add	x28, x28, #0x1
10117cbec:	e8 97 40 f9	ldr	x8, [sp, #0x128]
10117cbf0:	08 25 47 a9	ldp	x8, x9, [x8, #0x70]
10117cbf4:	29 01 08 cb	sub	x9, x9, x8
10117cbf8:	29 fd 43 93	asr	x9, x9, #3
10117cbfc:	29 7d 16 9b	mul	x9, x9, x22
10117cc00:	3f 01 1c eb	cmp	x9, x28
10117cc04:	29 05 00 54	b.ls	0x10117cca8
10117cc08:	08 01 15 8b	add	x8, x8, x21
10117cc0c:	09 19 40 b9	ldr	w9, [x8, #0x18]
10117cc10:	0a 01 40 b9	ldr	w10, [x8]
10117cc14:	29 01 0a 4b	sub	w9, w9, w10
10117cc18:	20 01 62 1e	scvtf	d0, w9
10117cc1c:	e9 9f 40 f9	ldr	x9, [sp, #0x138]
10117cc20:	21 01 40 bd	ldr	s1, [x9]
10117cc24:	21 a4 20 0f	sshll.2d	v1, v1, #0x0
10117cc28:	21 d8 61 5e	scvtf	d1, d1
10117cc2c:	62 02 67 9e	fmov	d2, x19
10117cc30:	00 08 62 1e	fmul	d0, d0, d2
10117cc34:	00 18 61 1e	fdiv	d0, d0, d1
10117cc38:	00 40 62 1e	fcvt	s0, d0
10117cc3c:	00 09 00 bd	str	s0, [x8, #0x8]
10117cc40:	e0 43 0f 91	add	x0, sp, #0x3d0
10117cc44:	e1 03 17 aa	mov	x1, x23
10117cc48:	fd c6 4c 94	bl	__ZN4juce6StringC1EPKc
10117cc4c:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
10117cc50:	08 01 40 f9	ldr	x8, [x8]
10117cc54:	08 01 15 8b	add	x8, x8, x21
10117cc58:	08 09 40 bd	ldr	s8, [x8, #0x8]
10117cc5c:	e0 43 0f 91	add	x0, sp, #0x3d0
10117cc60:	ba fa 4c 94	bl	__ZNK4juce6String9toRawUTF8Ev
10117cc64:	00 c1 22 1e	fcvt	d0, s8
10117cc68:	e0 03 00 fd	str	d0, [sp]
10117cc6c:	e8 a3 0f 91	add	x8, sp, #0x3e8
10117cc70:	3e 68 4d 94	bl	__ZN4juce6String12formattedRawEPKcz
10117cc74:	e0 63 0e 91	add	x0, sp, #0x398
10117cc78:	e1 a3 0f 91	add	x1, sp, #0x3e8
10117cc7c:	02 00 80 52	mov	w2, #0x0
10117cc80:	03 00 80 52	mov	w3, #0x0
10117cc84:	e4 03 18 aa	mov	x4, x24
10117cc88:	65 f3 4c 94	bl	__ZNK4juce4File10appendTextERKNS_6StringEbbPKc
10117cc8c:	e0 a3 0f 91	add	x0, sp, #0x3e8
10117cc90:	9b b6 4c 94	bl	__ZN4juce6StringD1Ev
10117cc94:	e0 43 0f 91	add	x0, sp, #0x3d0
10117cc98:	99 b6 4c 94	bl	__ZN4juce6StringD1Ev
10117cc9c:	b5 62 00 91	add	x21, x21, #0x18
10117cca0:	5f 03 1c eb	cmp	x26, x28
10117cca4:	21 fa ff 54	b.ne	0x10117cbe8
10117cca8:	f5 af 40 f9	ldr	x21, [sp, #0x158]
10117ccac:	b7 0a 00 51	sub	w23, w21, #0x2
10117ccb0:	f6 97 40 f9	ldr	x22, [sp, #0x128]
10117ccb4:	c8 26 47 a9	ldp	x8, x9, [x22, #0x70]
10117ccb8:	29 01 08 cb	sub	x9, x9, x8
10117ccbc:	29 fd 43 93	asr	x9, x9, #3
10117ccc0:	ea f3 01 b2	mov	x10, #-0x5555555555555556
10117ccc4:	6a 55 95 f2	movk	x10, #0xaaab
10117ccc8:	29 7d 0a 9b	mul	x9, x9, x10
10117cccc:	3f c1 35 eb	cmp	x9, w21, sxtw
10117ccd0:	f8 4f 50 a9	ldp	x24, x19, [sp, #0x100]
10117ccd4:	03 01 00 54	b.lo	0x10117ccf4
10117ccd8:	09 03 80 52	mov	w9, #0x18
10117ccdc:	ea 22 a9 9b	umaddl	x10, w23, w9, x8
10117cce0:	40 09 40 bd	ldr	s0, [x10, #0x8]
10117cce4:	48 23 09 9b	madd	x8, x26, x9, x8
10117cce8:	00 09 00 bd	str	s0, [x8, #0x8]
10117ccec:	02 00 00 14	b	0x10117ccf4
10117ccf0:	b7 0a 00 51	sub	w23, w21, #0x2
10117ccf4:	08 e4 00 2f	movi	d8, #0000000000000000
10117ccf8:	e8 23 41 b9	ldr	w8, [sp, #0x120]
10117ccfc:	68 1b 00 37	tbnz	w8, #0x0, 0x10117d068
10117cd00:	e8 13 41 b9	ldr	w8, [sp, #0x110]
10117cd04:	28 1b 00 37	tbnz	w8, #0x0, 0x10117d068
10117cd08:	e8 33 41 b9	ldr	w8, [sp, #0x130]
10117cd0c:	1f 05 00 71	cmp	w8, #0x1
10117cd10:	2b 03 00 54	b.lt	0x10117cd74
10117cd14:	09 00 80 d2	mov	x9, #0x0
10117cd18:	08 00 80 52	mov	w8, #0x0
10117cd1c:	ea 07 40 91	add	x10, sp, #0x1, lsl #12
10117cd20:	4a c1 09 91	add	x10, x10, #0x270
10117cd24:	4a 01 7e b2	orr	x10, x10, #0x4
10117cd28:	eb 07 40 91	add	x11, sp, #0x1, lsl #12
10117cd2c:	6b c1 01 91	add	x11, x11, #0x70
10117cd30:	ec c3 31 91	add	x12, sp, #0xc70
10117cd34:	ed c3 39 91	add	x13, sp, #0xe70
10117cd38:	f0 e3 40 b9	ldr	w16, [sp, #0xe0]
10117cd3c:	6e 69 69 b8	ldr	w14, [x11, x9]
10117cd40:	1f 02 0e 6b	cmp	w16, w14
10117cd44:	ab 00 00 54	b.lt	0x10117cd58
10117cd48:	8e 69 69 b8	ldr	w14, [x12, x9]
10117cd4c:	af 69 69 b8	ldr	w15, [x13, x9]
10117cd50:	c8 01 08 0b	add	w8, w14, w8
10117cd54:	08 01 0f 4b	sub	w8, w8, w15
10117cd58:	3f f1 07 f1	cmp	x9, #0x1fc
10117cd5c:	00 01 00 54	b.eq	0x10117cd7c
10117cd60:	4e 69 69 b8	ldr	w14, [x10, x9]
10117cd64:	29 11 00 91	add	x9, x9, #0x4
10117cd68:	df 01 00 71	cmp	w14, #0x0
10117cd6c:	8c fe ff 54	b.gt	0x10117cd3c
10117cd70:	03 00 00 14	b	0x10117cd7c
10117cd74:	08 00 80 52	mov	w8, #0x0
10117cd78:	f0 e3 40 b9	ldr	w16, [sp, #0xe0]
10117cd7c:	1b 01 10 0b	add	w27, w8, w16
10117cd80:	e9 df 40 b9	ldr	w9, [sp, #0xdc]
10117cd84:	18 01 09 0b	add	w24, w8, w9
10117cd88:	08 03 1b 0b	add	w8, w24, w27
10117cd8c:	1f 01 00 71	cmp	w8, #0x0
10117cd90:	08 a5 88 1a	cinc	w8, w8, lt
10117cd94:	0a 7d 01 13	asr	w10, w8, #1
10117cd98:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
10117cd9c:	08 01 40 f9	ldr	x8, [x8]
10117cda0:	09 03 80 52	mov	w9, #0x18
10117cda4:	4b 21 29 9b	smaddl	x11, w10, w9, x8
10117cda8:	6b 0d 40 b9	ldr	w11, [x11, #0xc]
10117cdac:	4c 01 0b 4b	sub	w12, w10, w11
10117cdb0:	7f 05 00 71	cmp	w11, #0x1
10117cdb4:	54 05 8c 1a	csinc	w20, w10, w12, eq
10117cdb8:	6a 07 00 71	subs	w10, w27, #0x1
10117cdbc:	eb 07 00 54	b.lt	0x10117ceb8
10117cdc0:	0b 00 80 d2	mov	x11, #0x0
10117cdc4:	8c 7e 29 9b	smull	x12, w20, w9
10117cdc8:	00 69 6c bc	ldr	s0, [x8, x12]
10117cdcc:	00 a4 20 0f	sshll.2d	v0, v0, #0x0
10117cdd0:	02 d8 61 5e	scvtf	d2, d0
10117cdd4:	0c e1 01 d1	sub	x12, x8, #0x78
10117cdd8:	00 e4 00 2f	movi	d0, #0000000000000000
10117cddc:	ad 00 80 52	mov	w13, #0x5
10117cde0:	03 90 6e 1e	fmov	d3, #1.25000000
10117cde4:	01 e4 00 2f	movi	d1, #0000000000000000
10117cde8:	12 00 00 14	b	0x10117ce30
10117cdec:	07 42 60 1e	fmov	d7, d16
10117cdf0:	6e 7d 09 9b	mul	x14, x11, x9
10117cdf4:	06 69 6e bc	ldr	s6, [x8, x14]
10117cdf8:	c6 a4 20 0f	sshll.2d	v6, v6, #0x0
10117cdfc:	c6 d8 61 5e	scvtf	d6, d6
10117ce00:	84 28 66 1e	fadd	d4, d4, d6
10117ce04:	84 38 62 1e	fsub	d4, d4, d2
10117ce08:	e6 08 63 1e	fmul	d6, d7, d3
10117ce0c:	90 c0 60 1e	fabs	d16, d4
10117ce10:	c0 20 70 1e	fcmp	d6, d16
10117ce14:	06 ce 67 1e	fcsel	d6, d16, d7, gt
10117ce18:	84 cc 65 1e	fcsel	d4, d4, d5, gt
10117ce1c:	80 28 60 1e	fadd	d0, d4, d0
10117ce20:	c1 28 61 1e	fadd	d1, d6, d1
10117ce24:	6b 05 00 91	add	x11, x11, #0x1
10117ce28:	7f 01 1b eb	cmp	x11, x27
10117ce2c:	a0 04 00 54	b.eq	0x10117cec0
10117ce30:	7f 15 00 71	cmp	w11, #0x5
10117ce34:	6f c1 8d 1a	csel	w15, w11, w13, gt
10117ce38:	ee 15 00 51	sub	w14, w15, #0x5
10117ce3c:	70 15 00 11	add	w16, w11, #0x5
10117ce40:	1f 02 1b 6b	cmp	w16, w27
10117ce44:	10 b2 8a 1a	csel	w16, w16, w10, lt
10117ce48:	91 02 0b 4b	sub	w17, w20, w11
10117ce4c:	24 02 62 1e	scvtf	d4, w17
10117ce50:	e5 53 c0 3d	ldr	q5, [sp, #0x140]
10117ce54:	a4 08 64 1e	fmul	d4, d5, d4
10117ce58:	d1 7d a9 9b	umull	x17, w14, w9
10117ce5c:	05 69 71 bc	ldr	s5, [x8, x17]
10117ce60:	a5 a4 20 0f	sshll.2d	v5, v5, #0x0
10117ce64:	a5 d8 61 5e	scvtf	d5, d5
10117ce68:	86 38 62 1e	fsub	d6, d4, d2
10117ce6c:	c5 28 65 1e	fadd	d5, d6, d5
10117ce70:	b0 c0 60 1e	fabs	d16, d5
10117ce74:	df 01 10 6b	cmp	w14, w16
10117ce78:	ac fb ff 54	b.gt	0x10117cdec
10117ce7c:	ee 19 00 d1	sub	x14, x15, #0x6
10117ce80:	ef 31 a9 9b	umaddl	x15, w15, w9, x12
10117ce84:	10 7e 40 93	sxtw	x16, w16
10117ce88:	f1 85 41 b8	ldr	w17, [x15], #0x18
10117ce8c:	27 02 62 1e	scvtf	d7, w17
10117ce90:	d1 28 67 1e	fadd	d17, d6, d7
10117ce94:	32 c2 60 1e	fabs	d18, d17
10117ce98:	07 7a 72 1e	fminnm	d7, d16, d18
10117ce9c:	00 22 72 1e	fcmp	d16, d18
10117cea0:	25 ce 65 1e	fcsel	d5, d17, d5, gt
10117cea4:	ce 05 00 91	add	x14, x14, #0x1
10117cea8:	f0 40 60 1e	fmov	d16, d7
10117ceac:	df 01 10 eb	cmp	x14, x16
10117ceb0:	cb fe ff 54	b.lt	0x10117ce88
10117ceb4:	cf ff ff 17	b	0x10117cdf0
10117ceb8:	01 e4 00 2f	movi	d1, #0000000000000000
10117cebc:	00 e4 00 2f	movi	d0, #0000000000000000
10117cec0:	09 07 00 11	add	w9, w24, #0x1
10117cec4:	3f 01 15 6b	cmp	w9, w21
10117cec8:	aa 09 00 54	b.ge	0x10117cffc
10117cecc:	ca 3e 40 f9	ldr	x10, [x22, #0x78]
10117ced0:	4a 01 08 cb	sub	x10, x10, x8
10117ced4:	eb f3 01 b2	mov	x11, #-0x5555555555555556
10117ced8:	6b 55 95 f2	movk	x11, #0xaaab
10117cedc:	4b 55 e5 f2	movk	x11, #0x2aaa, lsl #48
10117cee0:	4a 7d 4b 9b	smulh	x10, x10, x11
10117cee4:	4b fd 42 93	asr	x11, x10, #2
10117cee8:	6a fd 4a 8b	add	x10, x11, x10, lsr #63
10117ceec:	0b 03 80 52	mov	w11, #0x18
10117cef0:	8c 22 2b 9b	smaddl	x12, w20, w11, x8
10117cef4:	2d 7d 40 93	sxtw	x13, w9
10117cef8:	0e 7f 40 93	sxtw	x14, w24
10117cefc:	5f 01 0d eb	cmp	x10, x13
10117cf00:	4f 81 8d 9a	csel	x15, x10, x13, hi
10117cf04:	02 90 6e 1e	fmov	d2, #1.25000000
10117cf08:	12 00 00 14	b	0x10117cf50
10117cf0c:	f0 40 60 1e	fmov	d16, d7
10117cf10:	b0 7d 0b 9b	mul	x16, x13, x11
10117cf14:	06 69 70 bc	ldr	s6, [x8, x16]
10117cf18:	c6 a4 20 0f	sshll.2d	v6, v6, #0x0
10117cf1c:	c6 d8 61 5e	scvtf	d6, d6
10117cf20:	63 28 66 1e	fadd	d3, d3, d6
10117cf24:	63 38 64 1e	fsub	d3, d3, d4
10117cf28:	04 0a 62 1e	fmul	d4, d16, d2
10117cf2c:	66 c0 60 1e	fabs	d6, d3
10117cf30:	80 20 66 1e	fcmp	d4, d6
10117cf34:	c4 cc 70 1e	fcsel	d4, d6, d16, gt
10117cf38:	63 cc 65 1e	fcsel	d3, d3, d5, gt
10117cf3c:	60 28 60 1e	fadd	d0, d3, d0
10117cf40:	81 28 61 1e	fadd	d1, d4, d1
10117cf44:	ad 05 00 91	add	x13, x13, #0x1
10117cf48:	bf 01 13 eb	cmp	x13, x19
10117cf4c:	8a 05 00 54	b.ge	0x10117cffc
10117cf50:	bf 01 0f eb	cmp	x13, x15
10117cf54:	40 05 00 54	b.eq	0x10117cffc
10117cf58:	b0 15 00 d1	sub	x16, x13, #0x5
10117cf5c:	b1 15 00 91	add	x17, x13, #0x5
10117cf60:	1f 02 0e eb	cmp	x16, x14
10117cf64:	10 c2 89 1a	csel	w16, w16, w9, gt
10117cf68:	3f 02 13 eb	cmp	x17, x19
10117cf6c:	20 b2 9a 1a	csel	w0, w17, w26, lt
10117cf70:	91 02 0d 4b	sub	w17, w20, w13
10117cf74:	23 02 62 1e	scvtf	d3, w17
10117cf78:	e4 53 c0 3d	ldr	q4, [sp, #0x140]
10117cf7c:	83 08 63 1e	fmul	d3, d4, d3
10117cf80:	84 01 40 bd	ldr	s4, [x12]
10117cf84:	84 a4 20 0f	sshll.2d	v4, v4, #0x0
10117cf88:	84 d8 61 5e	scvtf	d4, d4
10117cf8c:	11 7e 2b 9b	smull	x17, w16, w11
10117cf90:	05 69 71 bc	ldr	s5, [x8, x17]
10117cf94:	a5 a4 20 0f	sshll.2d	v5, v5, #0x0
10117cf98:	a5 d8 61 5e	scvtf	d5, d5
10117cf9c:	66 38 64 1e	fsub	d6, d3, d4
10117cfa0:	c5 28 65 1e	fadd	d5, d6, d5
10117cfa4:	a7 c0 60 1e	fabs	d7, d5
10117cfa8:	1f 02 00 6b	cmp	w16, w0
10117cfac:	0c fb ff 54	b.gt	0x10117cf0c
10117cfb0:	01 7e 40 93	sxtw	x1, w16
10117cfb4:	50 01 01 eb	subs	x16, x10, x1
10117cfb8:	f0 33 90 9a	csel	x16, xzr, x16, lo
10117cfbc:	31 20 0b 9b	madd	x17, x1, x11, x8
10117cfc0:	00 00 01 4b	sub	w0, w0, w1
10117cfc4:	00 04 00 11	add	w0, w0, #0x1
10117cfc8:	30 fa ff b4	cbz	x16, 0x10117cf0c
10117cfcc:	21 86 41 b8	ldr	w1, [x17], #0x18
10117cfd0:	30 00 62 1e	scvtf	d16, w1
10117cfd4:	d1 28 70 1e	fadd	d17, d6, d16
10117cfd8:	32 c2 60 1e	fabs	d18, d17
10117cfdc:	f0 78 72 1e	fminnm	d16, d7, d18
10117cfe0:	e0 20 72 1e	fcmp	d7, d18
10117cfe4:	25 ce 65 1e	fcsel	d5, d17, d5, gt
10117cfe8:	10 06 00 d1	sub	x16, x16, #0x1
10117cfec:	07 42 60 1e	fmov	d7, d16
10117cff0:	00 04 00 71	subs	w0, w0, #0x1
10117cff4:	a1 fe ff 54	b.ne	0x10117cfc8
10117cff8:	c6 ff ff 17	b	0x10117cf10
10117cffc:	e8 03 38 2a	mvn	w8, w24
10117d000:	69 03 15 0b	add	w9, w27, w21
10117d004:	28 01 08 2b	adds	w8, w9, w8
10117d008:	08 e4 00 2f	movi	d8, #0000000000000000
10117d00c:	02 e4 00 2f	movi	d2, #0000000000000000
10117d010:	60 00 00 54	b.eq	0x10117d01c
10117d014:	02 01 62 1e	scvtf	d2, w8
10117d018:	22 18 62 1e	fdiv	d2, d1, d2
10117d01c:	e9 e7 00 b2	mov	x9, #0x3333333333333333
10117d020:	69 fa e7 f2	movk	x9, #0x3fd3, lsl #48
10117d024:	21 01 67 9e	fmov	d1, x9
10117d028:	e3 53 c0 3d	ldr	q3, [sp, #0x140]
10117d02c:	61 08 61 1e	fmul	d1, d3, d1
10117d030:	40 20 61 1e	fcmp	d2, d1
10117d034:	ad 01 00 54	b.le	0x10117d068
10117d038:	01 01 62 1e	scvtf	d1, w8
10117d03c:	a2 02 62 1e	scvtf	d2, w21
10117d040:	22 18 62 1e	fdiv	d2, d1, d2
10117d044:	01 10 6c 1e	fmov	d1, #0.50000000
10117d048:	40 20 61 1e	fcmp	d2, d1
10117d04c:	ed 00 00 54	b.le	0x10117d068
10117d050:	08 20 60 1e	fcmp	d0, #0.0
10117d054:	00 10 7c 1e	fmov	d0, #-0.50000000
10117d058:	e2 53 c0 3d	ldr	q2, [sp, #0x140]
10117d05c:	40 08 60 1e	fmul	d0, d2, d0
10117d060:	41 08 61 1e	fmul	d1, d2, d1
10117d064:	08 dc 61 1e	fcsel	d8, d0, d1, le
10117d068:	e0 a3 0f 91	add	x0, sp, #0x3e8
10117d06c:	e1 03 13 aa	mov	x1, x19
10117d070:	60 13 00 94	bl	__ZNSt3__16vectorIdNS_9allocatorIdEEEC1Em
10117d074:	e0 43 0f 91	add	x0, sp, #0x3d0
10117d078:	e1 03 13 aa	mov	x1, x19
10117d07c:	5d 13 00 94	bl	__ZNSt3__16vectorIdNS_9allocatorIdEEEC1Em
10117d080:	e0 e3 0e 91	add	x0, sp, #0x3b8
10117d084:	e1 03 13 aa	mov	x1, x19
10117d088:	5a 13 00 94	bl	__ZNSt3__16vectorIdNS_9allocatorIdEEEC1Em
10117d08c:	0c 03 1b 6b	subs	w12, w24, w27
10117d090:	04 11 00 54	b.mi	0x10117d2b0
10117d094:	88 05 00 11	add	w8, w12, #0x1
10117d098:	01 e4 00 2f	movi	d1, #0000000000000000
10117d09c:	1f 03 1b 6b	cmp	w24, w27
10117d0a0:	2b 10 00 54	b.lt	0x10117d2a4
10117d0a4:	e9 b3 40 f9	ldr	x9, [sp, #0x160]
10117d0a8:	29 01 40 f9	ldr	x9, [x9]
10117d0ac:	0a 03 80 52	mov	w10, #0x18
10117d0b0:	8a 7e 2a 9b	smull	x10, w20, w10
10117d0b4:	20 69 6a bc	ldr	s0, [x9, x10]
10117d0b8:	00 a4 20 0f	sshll.2d	v0, v0, #0x0
10117d0bc:	00 d8 61 5e	scvtf	d0, d0
10117d0c0:	eb f7 41 f9	ldr	x11, [sp, #0x3e8]
10117d0c4:	ea eb 41 f9	ldr	x10, [sp, #0x3d0]
10117d0c8:	ed 03 1b aa	mov	x13, x27
10117d0cc:	ae 7d 40 93	sxtw	x14, w13
10117d0d0:	01 e4 00 2f	movi	d1, #0000000000000000
10117d0d4:	9f 21 00 71	cmp	w12, #0x8
10117d0d8:	e3 0b 00 54	b.lo	0x10117d254
10117d0dc:	cd f1 7d d3	lsl	x13, x14, #3
10117d0e0:	af 01 0a 8b	add	x15, x13, x10
10117d0e4:	ad 01 0b 8b	add	x13, x13, x11
10117d0e8:	ed 01 0d cb	sub	x13, x15, x13
10117d0ec:	bf 01 01 f1	cmp	x13, #0x40
10117d0f0:	23 0b 00 54	b.lo	0x10117d254
10117d0f4:	8c 05 00 91	add	x12, x12, #0x1
10117d0f8:	8d 09 40 f2	ands	x13, x12, #0x7
10117d0fc:	0f 01 80 52	mov	w15, #0x8
10117d100:	ed 01 8d 9a	csel	x13, x15, x13, eq
10117d104:	8d 01 0d cb	sub	x13, x12, x13
10117d108:	ac 01 0e 8b	add	x12, x13, x14
10117d10c:	61 0f 04 0e	dup.2s	v1, w27
10117d110:	af 2e 01 90	adrp	x15, 9684 ; 0x103751000
10117d114:	e2 45 42 fd	ldr	d2, [x15, #0x488]
10117d118:	21 84 a2 0e	add.2s	v1, v1, v2
10117d11c:	82 0e 04 0e	dup.2s	v2, w20
10117d120:	03 04 08 4e	dup.2d	v3, v0[0]
10117d124:	cf 11 00 91	add	x15, x14, #0x4
10117d128:	f0 f1 7d d3	lsl	x16, x15, #3
10117d12c:	4e 01 10 8b	add	x14, x10, x16
10117d130:	11 03 80 52	mov	w17, #0x18
10117d134:	04 e4 00 6f	movi.2d	v4, #0000000000000000
10117d138:	45 04 00 0f	movi.2s	v5, #0x2
10117d13c:	ef 25 11 9b	madd	x15, x15, x17, x9
10117d140:	70 01 10 8b	add	x16, x11, x16
10117d144:	86 04 00 0f	movi.2s	v6, #0x4
10117d148:	c7 04 00 0f	movi.2s	v7, #0x6
10117d14c:	10 05 00 0f	movi.2s	v16, #0x8
10117d150:	11 e4 00 6f	movi.2d	v17, #0000000000000000
10117d154:	12 e4 00 6f	movi.2d	v18, #0000000000000000
10117d158:	13 e4 00 6f	movi.2d	v19, #0000000000000000
10117d15c:	fc 53 c0 3d	ldr	q28, [sp, #0x140]
10117d160:	34 84 a2 2e	sub.2s	v20, v1, v2
10117d164:	95 86 a5 0e	add.2s	v21, v20, v5
10117d168:	96 86 a6 0e	add.2s	v22, v20, v6
10117d16c:	97 86 a7 0e	add.2s	v23, v20, v7
10117d170:	94 a6 20 0f	sshll.2d	v20, v20, #0x0
10117d174:	94 da 61 4e	scvtf.2d	v20, v20
10117d178:	b5 a6 20 0f	sshll.2d	v21, v21, #0x0
10117d17c:	b5 da 61 4e	scvtf.2d	v21, v21
10117d180:	d6 a6 20 0f	sshll.2d	v22, v22, #0x0
10117d184:	d6 da 61 4e	scvtf.2d	v22, v22
10117d188:	f7 a6 20 0f	sshll.2d	v23, v23, #0x0
10117d18c:	f7 da 61 4e	scvtf.2d	v23, v23
10117d190:	78 1c a3 4e	mov.16b	v24, v3
10117d194:	98 12 dc 4f	fmla.2d	v24, v20, v28[0]
10117d198:	74 1c a3 4e	mov.16b	v20, v3
10117d19c:	b4 12 dc 4f	fmla.2d	v20, v21, v28[0]
10117d1a0:	75 1c a3 4e	mov.16b	v21, v3
10117d1a4:	d5 12 dc 4f	fmla.2d	v21, v22, v28[0]
10117d1a8:	76 1c a3 4e	mov.16b	v22, v3
10117d1ac:	f6 12 dc 4f	fmla.2d	v22, v23, v28[0]
10117d1b0:	18 52 3f ad	stp	q24, q20, [x16, #-0x20]
10117d1b4:	15 5a 82 ac	stp	q21, q22, [x16], #0x40
10117d1b8:	f7 01 da 3c	ldur	q23, [x15, #-0x60]
10117d1bc:	f9 01 dd 3c	ldur	q25, [x15, #-0x30]
10117d1c0:	fa 01 c0 3d	ldr	q26, [x15]
10117d1c4:	fb 0d c0 3d	ldr	q27, [x15, #0x30]
10117d1c8:	f1 21 01 d1	sub	x17, x15, #0x48
10117d1cc:	37 92 40 0d	ld1.s	{ v23 }[1], [x17]
10117d1d0:	f1 61 00 d1	sub	x17, x15, #0x18
10117d1d4:	39 92 40 0d	ld1.s	{ v25 }[1], [x17]
10117d1d8:	f1 61 00 91	add	x17, x15, #0x18
10117d1dc:	3a 92 40 0d	ld1.s	{ v26 }[1], [x17]
10117d1e0:	f1 21 01 91	add	x17, x15, #0x48
10117d1e4:	3b 92 40 0d	ld1.s	{ v27 }[1], [x17]
10117d1e8:	f7 a6 20 0f	sshll.2d	v23, v23, #0x0
10117d1ec:	f7 da 61 4e	scvtf.2d	v23, v23
10117d1f0:	39 a7 20 0f	sshll.2d	v25, v25, #0x0
10117d1f4:	39 db 61 4e	scvtf.2d	v25, v25
10117d1f8:	5a a7 20 0f	sshll.2d	v26, v26, #0x0
10117d1fc:	5a db 61 4e	scvtf.2d	v26, v26
10117d200:	7b a7 20 0f	sshll.2d	v27, v27, #0x0
10117d204:	7b db 61 4e	scvtf.2d	v27, v27
10117d208:	f7 d6 f8 4e	fsub.2d	v23, v23, v24
10117d20c:	34 d7 f4 4e	fsub.2d	v20, v25, v20
10117d210:	55 d7 f5 4e	fsub.2d	v21, v26, v21
10117d214:	76 d7 f6 4e	fsub.2d	v22, v27, v22
10117d218:	d7 51 3f ad	stp	q23, q20, [x14, #-0x20]
10117d21c:	d5 59 82 ac	stp	q21, q22, [x14], #0x40
10117d220:	e4 d6 64 4e	fadd.2d	v4, v23, v4
10117d224:	91 d6 71 4e	fadd.2d	v17, v20, v17
10117d228:	b2 d6 72 4e	fadd.2d	v18, v21, v18
10117d22c:	d3 d6 73 4e	fadd.2d	v19, v22, v19
10117d230:	21 84 b0 0e	add.2s	v1, v1, v16
10117d234:	ef 01 03 91	add	x15, x15, #0xc0
10117d238:	ad 21 00 f1	subs	x13, x13, #0x8
10117d23c:	21 f9 ff 54	b.ne	0x10117d160
10117d240:	21 d6 64 4e	fadd.2d	v1, v17, v4
10117d244:	41 d6 61 4e	fadd.2d	v1, v18, v1
10117d248:	61 d6 61 4e	fadd.2d	v1, v19, v1
10117d24c:	21 d8 70 7e	faddp.2d	d1, v1
10117d250:	ee 03 0c aa	mov	x14, x12
10117d254:	cc 01 14 4b	sub	w12, w14, w20
10117d258:	cd f1 7d d3	lsl	x13, x14, #3
10117d25c:	6b 01 0d 8b	add	x11, x11, x13
10117d260:	4a 01 0d 8b	add	x10, x10, x13
10117d264:	0d 03 80 52	mov	w13, #0x18
10117d268:	c9 25 0d 9b	madd	x9, x14, x13, x9
10117d26c:	0d 03 0e 4b	sub	w13, w24, w14
10117d270:	ad 05 00 11	add	w13, w13, #0x1
10117d274:	e4 53 c0 3d	ldr	q4, [sp, #0x140]
10117d278:	82 01 62 1e	scvtf	d2, w12
10117d27c:	82 00 42 1f	fmadd	d2, d4, d2, d0
10117d280:	62 85 00 fc	str	d2, [x11], #0x8
10117d284:	2e 85 41 b8	ldr	w14, [x9], #0x18
10117d288:	c3 01 62 1e	scvtf	d3, w14
10117d28c:	62 38 62 1e	fsub	d2, d3, d2
10117d290:	41 28 61 1e	fadd	d1, d2, d1
10117d294:	42 85 00 fc	str	d2, [x10], #0x8
10117d298:	8c 05 00 11	add	w12, w12, #0x1
10117d29c:	ad 05 00 71	subs	w13, w13, #0x1
10117d2a0:	c1 fe ff 54	b.ne	0x10117d278
10117d2a4:	00 01 62 1e	scvtf	d0, w8
10117d2a8:	20 18 60 1e	fdiv	d0, d1, d0
10117d2ac:	02 00 00 14	b	0x10117d2b4
10117d2b0:	00 e4 00 2f	movi	d0, #0000000000000000
10117d2b4:	bf 06 00 71	cmp	w21, #0x1
10117d2b8:	fb 9f 40 f9	ldr	x27, [sp, #0x138]
10117d2bc:	4b 06 00 54	b.lt	0x10117d384
10117d2c0:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
10117d2c4:	08 01 40 f9	ldr	x8, [x8]
10117d2c8:	09 03 80 52	mov	w9, #0x18
10117d2cc:	89 7e 29 9b	smull	x9, w20, w9
10117d2d0:	01 69 69 bc	ldr	s1, [x8, x9]
10117d2d4:	21 a4 20 0f	sshll.2d	v1, v1, #0x0
10117d2d8:	21 d8 61 5e	scvtf	d1, d1
10117d2dc:	c9 3e 40 f9	ldr	x9, [x22, #0x78]
10117d2e0:	2a 01 08 cb	sub	x10, x9, x8
10117d2e4:	e9 f3 01 b2	mov	x9, #-0x5555555555555556
10117d2e8:	69 55 95 f2	movk	x9, #0xaaab
10117d2ec:	49 55 e5 f2	movk	x9, #0x2aaa, lsl #48
10117d2f0:	49 7d 49 9b	smulh	x9, x10, x9
10117d2f4:	2b fd 42 93	asr	x11, x9, #2
10117d2f8:	6b fd 49 8b	add	x11, x11, x9, lsr #63
10117d2fc:	ec e3 41 f9	ldr	x12, [sp, #0x3c0]
10117d300:	e9 df 41 f9	ldr	x9, [sp, #0x3b8]
10117d304:	8c 01 09 cb	sub	x12, x12, x9
10117d308:	8c fd 43 93	asr	x12, x12, #3
10117d30c:	00 28 68 1e	fadd	d0, d0, d8
10117d310:	00 28 61 1e	fadd	d0, d0, d1
10117d314:	4a 5d 00 91	add	x10, x10, #0x17
10117d318:	9f 01 0b eb	cmp	x12, x11
10117d31c:	8b 31 8b 9a	csel	x11, x12, x11, lo
10117d320:	5f bd 00 f1	cmp	x10, #0x2f
10117d324:	ea 33 8b 9a	csel	x10, xzr, x11, lo
10117d328:	ab 7e 40 92	and	x11, x21, #0xffffffff
10117d32c:	ec 03 14 4b	neg	w12, w20
10117d330:	01 10 6c 1e	fmov	d1, #0.50000000
10117d334:	e3 53 c0 3d	ldr	q3, [sp, #0x140]
10117d338:	6a 02 00 b4	cbz	x10, 0x10117d384
10117d33c:	82 01 62 1e	scvtf	d2, w12
10117d340:	62 00 42 1f	fmadd	d2, d3, d2, d0
10117d344:	22 85 00 fc	str	d2, [x9], #0x8
10117d348:	42 28 61 1e	fadd	d2, d2, d1
10117d34c:	ed 03 19 6b	negs	w13, w25
10117d350:	ad 05 00 12	and	w13, w13, #0x3
10117d354:	2e 07 00 12	and	w14, w25, #0x3
10117d358:	cd 45 8d 5a	csneg	w13, w14, w13, mi
10117d35c:	4e 00 78 1e	fcvtzs	w14, d2
10117d360:	ad 05 00 11	add	w13, w13, #0x1
10117d364:	4a 05 00 d1	sub	x10, x10, #0x1
10117d368:	0e 01 00 b9	str	w14, [x8]
10117d36c:	0d 0d 00 b9	str	w13, [x8, #0xc]
10117d370:	39 07 00 11	add	w25, w25, #0x1
10117d374:	8c 05 00 11	add	w12, w12, #0x1
10117d378:	08 61 00 91	add	x8, x8, #0x18
10117d37c:	6b 05 00 f1	subs	x11, x11, #0x1
10117d380:	c1 fd ff 54	b.ne	0x10117d338
10117d384:	e8 63 0c 91	add	x8, sp, #0x318
10117d388:	99 bf bb 97	bl	__ZN6common12PropertyPathEv
10117d38c:	c1 f1 01 b0	adrp	x1, 15929 ; 0x104fb6000
10117d390:	21 24 1e 91	add	x1, x1, #0x789 ; literal pool for: "csv"
10117d394:	e0 23 0e 91	add	x0, sp, #0x388
10117d398:	d1 b3 4c 94	bl	__ZN4juce9StringRefC1EPKc
10117d39c:	e1 c7 41 f9	ldr	x1, [sp, #0x388]
10117d3a0:	e8 83 0d 91	add	x8, sp, #0x360
10117d3a4:	e0 63 0c 91	add	x0, sp, #0x318
10117d3a8:	36 d1 4c 94	bl	__ZNK4juce4File12getChildFileENS_9StringRefE
10117d3ac:	f9 b3 40 f9	ldr	x25, [sp, #0x160]
10117d3b0:	e0 63 0c 91	add	x0, sp, #0x318
10117d3b4:	d2 b4 4c 94	bl	__ZN4juce6StringD1Ev
10117d3b8:	e0 83 0d 91	add	x0, sp, #0x360
10117d3bc:	81 d5 4c 94	bl	__ZNK4juce4File6existsEv
10117d3c0:	c0 00 00 37	tbnz	w0, #0x0, 0x10117d3d8
10117d3c4:	e8 03 0e 91	add	x8, sp, #0x380
10117d3c8:	e0 83 0d 91	add	x0, sp, #0x360
10117d3cc:	26 d7 4c 94	bl	__ZNK4juce4File15createDirectoryEv
10117d3d0:	e0 03 0e 91	add	x0, sp, #0x380
10117d3d4:	ca b4 4c 94	bl	__ZN4juce6StringD1Ev
10117d3d8:	c1 f1 01 b0	adrp	x1, 15929 ; 0x104fb6000
10117d3dc:	21 e8 1e 91	add	x1, x1, #0x7ba ; literal pool for: "interval3.csv"
10117d3e0:	e0 e3 0d 91	add	x0, sp, #0x378
10117d3e4:	be b3 4c 94	bl	__ZN4juce9StringRefC1EPKc
10117d3e8:	e1 bf 41 f9	ldr	x1, [sp, #0x378]
10117d3ec:	e8 63 0c 91	add	x8, sp, #0x318
10117d3f0:	e0 83 0d 91	add	x0, sp, #0x360
10117d3f4:	23 d1 4c 94	bl	__ZNK4juce4File12getChildFileENS_9StringRefE
10117d3f8:	bf 0a 00 71	cmp	w21, #0x2
10117d3fc:	2b 09 00 54	b.lt	0x10117d520
10117d400:	f7 33 01 b9	str	w23, [sp, #0x130]
10117d404:	fc 03 13 aa	mov	x28, x19
10117d408:	14 00 80 d2	mov	x20, #0x0
10117d40c:	13 01 80 52	mov	w19, #0x8
10117d410:	15 00 c8 d2	mov	x21, #0x400000000000
10117d414:	f5 11 e8 f2	movk	x21, #0x408f, lsl #48
10117d418:	d7 f1 01 b0	adrp	x23, 15929 ; 0x104fb6000
10117d41c:	f7 22 1f 91	add	x23, x23, #0x7c8 ; literal pool for: "%.3f, %.3f, %.3d\015\n"
10117d420:	98 ef 01 90	adrp	x24, 15856 ; 0x104f6d000
10117d424:	18 db 1a 91	add	x24, x24, #0x6b6 ; literal pool for: "\015\n"
10117d428:	e8 df 41 f9	ldr	x8, [sp, #0x3b8]
10117d42c:	08 0d 14 8b	add	x8, x8, x20, lsl #3
10117d430:	01 01 40 6d	ldp	d1, d0, [x8]
10117d434:	00 38 61 1e	fsub	d0, d0, d1
10117d438:	61 03 40 bd	ldr	s1, [x27]
10117d43c:	21 a4 20 0f	sshll.2d	v1, v1, #0x0
10117d440:	21 d8 61 5e	scvtf	d1, d1
10117d444:	a2 02 67 9e	fmov	d2, x21
10117d448:	00 08 62 1e	fmul	d0, d0, d2
10117d44c:	00 18 61 1e	fdiv	d0, d0, d1
10117d450:	00 40 62 1e	fcvt	s0, d0
10117d454:	28 03 40 f9	ldr	x8, [x25]
10117d458:	00 69 33 bc	str	s0, [x8, x19]
10117d45c:	e0 a3 0b 91	add	x0, sp, #0x2e8
10117d460:	e1 03 17 aa	mov	x1, x23
10117d464:	f6 c4 4c 94	bl	__ZN4juce6StringC1EPKc
10117d468:	28 03 40 f9	ldr	x8, [x25]
10117d46c:	09 69 73 bc	ldr	s9, [x8, x19]
10117d470:	e8 df 41 f9	ldr	x8, [sp, #0x3b8]
10117d474:	08 0d 14 8b	add	x8, x8, x20, lsl #3
10117d478:	0a 21 40 6d	ldp	d10, d8, [x8]
10117d47c:	e0 a3 0b 91	add	x0, sp, #0x2e8
10117d480:	b2 f8 4c 94	bl	__ZNK4juce6String9toRawUTF8Ev
10117d484:	20 c1 22 1e	fcvt	d0, s9
10117d488:	e8 ab 00 6d	stp	d8, d10, [sp, #0x8]
10117d48c:	e8 03 0c 91	add	x8, sp, #0x300
10117d490:	e0 03 00 fd	str	d0, [sp]
10117d494:	35 66 4d 94	bl	__ZN4juce6String12formattedRawEPKcz
10117d498:	e0 63 0c 91	add	x0, sp, #0x318
10117d49c:	e1 03 0c 91	add	x1, sp, #0x300
10117d4a0:	02 00 80 52	mov	w2, #0x0
10117d4a4:	03 00 80 52	mov	w3, #0x0
10117d4a8:	e4 03 18 aa	mov	x4, x24
10117d4ac:	5c f1 4c 94	bl	__ZNK4juce4File10appendTextERKNS_6StringEbbPKc
10117d4b0:	94 06 00 91	add	x20, x20, #0x1
10117d4b4:	e0 03 0c 91	add	x0, sp, #0x300
10117d4b8:	91 b4 4c 94	bl	__ZN4juce6StringD1Ev
10117d4bc:	e0 a3 0b 91	add	x0, sp, #0x2e8
10117d4c0:	8f b4 4c 94	bl	__ZN4juce6StringD1Ev
10117d4c4:	73 62 00 91	add	x19, x19, #0x18
10117d4c8:	5f 03 14 eb	cmp	x26, x20
10117d4cc:	e1 fa ff 54	b.ne	0x10117d428
10117d4d0:	e0 63 0c 91	add	x0, sp, #0x318
10117d4d4:	8a b4 4c 94	bl	__ZN4juce6StringD1Ev
10117d4d8:	e0 83 0d 91	add	x0, sp, #0x360
10117d4dc:	88 b4 4c 94	bl	__ZN4juce6StringD1Ev
10117d4e0:	c8 26 47 a9	ldp	x8, x9, [x22, #0x70]
10117d4e4:	29 01 08 cb	sub	x9, x9, x8
10117d4e8:	29 fd 43 93	asr	x9, x9, #3
10117d4ec:	ea f3 01 b2	mov	x10, #-0x5555555555555556
10117d4f0:	6a 55 95 f2	movk	x10, #0xaaab
10117d4f4:	29 7d 0a 9b	mul	x9, x9, x10
10117d4f8:	9f 03 09 eb	cmp	x28, x9
10117d4fc:	f5 af 40 f9	ldr	x21, [sp, #0x158]
10117d500:	88 01 00 54	b.hi	0x10117d530
10117d504:	09 03 80 52	mov	w9, #0x18
10117d508:	ea 33 41 b9	ldr	w10, [sp, #0x130]
10117d50c:	4a 21 a9 9b	umaddl	x10, w10, w9, x8
10117d510:	40 09 40 bd	ldr	s0, [x10, #0x8]
10117d514:	48 23 09 9b	madd	x8, x26, x9, x8
10117d518:	00 09 00 bd	str	s0, [x8, #0x8]
10117d51c:	05 00 00 14	b	0x10117d530
10117d520:	e0 63 0c 91	add	x0, sp, #0x318
10117d524:	76 b4 4c 94	bl	__ZN4juce6StringD1Ev
10117d528:	e0 83 0d 91	add	x0, sp, #0x360
10117d52c:	74 b4 4c 94	bl	__ZN4juce6StringD1Ev
10117d530:	bf 02 00 71	cmp	w21, #0x0
10117d534:	4d 02 00 54	b.le	0x10117d57c
10117d538:	c8 26 47 a9	ldp	x8, x9, [x22, #0x70]
10117d53c:	29 01 08 cb	sub	x9, x9, x8
10117d540:	ea f3 01 b2	mov	x10, #-0x5555555555555556
10117d544:	6a 55 95 f2	movk	x10, #0xaaab
10117d548:	4a 55 e5 f2	movk	x10, #0x2aaa, lsl #48
10117d54c:	29 7d 4a 9b	smulh	x9, x9, x10
10117d550:	2a fd 42 93	asr	x10, x9, #2
10117d554:	49 fd 49 8b	add	x9, x10, x9, lsr #63
10117d558:	aa 7e 40 92	and	x10, x21, #0xffffffff
10117d55c:	4b 05 00 d1	sub	x11, x10, #0x1
10117d560:	3f 01 0b eb	cmp	x9, x11
10117d564:	2b 31 8b 9a	csel	x11, x9, x11, lo
10117d568:	6b 05 00 91	add	x11, x11, #0x1
10117d56c:	7f 15 00 f1	cmp	x11, #0x5
10117d570:	42 01 00 54	b.hs	0x10117d598
10117d574:	0b 00 80 d2	mov	x11, #0x0
10117d578:	1e 00 00 14	b	0x10117d5f0
10117d57c:	c8 26 47 a9	ldp	x8, x9, [x22, #0x70]
10117d580:	29 01 08 cb	sub	x9, x9, x8
10117d584:	29 fd 43 93	asr	x9, x9, #3
10117d588:	ea f3 01 b2	mov	x10, #-0x5555555555555556
10117d58c:	6a 55 95 f2	movk	x10, #0xaaab
10117d590:	29 7d 0a 9b	mul	x9, x9, x10
10117d594:	23 00 00 14	b	0x10117d620
10117d598:	6c 05 40 f2	ands	x12, x11, #0x3
10117d59c:	8d 00 80 52	mov	w13, #0x4
10117d5a0:	ac 01 8c 9a	csel	x12, x13, x12, eq
10117d5a4:	6b 01 0c cb	sub	x11, x11, x12
10117d5a8:	cc 52 40 b9	ldr	w12, [x22, #0x50]
10117d5ac:	0d c1 00 91	add	x13, x8, #0x30
10117d5b0:	ee 03 0b aa	mov	x14, x11
10117d5b4:	af 01 5d b8	ldur	w15, [x13, #-0x30]
10117d5b8:	b0 81 5e b8	ldur	w16, [x13, #-0x18]
10117d5bc:	b1 01 40 b9	ldr	w17, [x13]
10117d5c0:	a0 19 40 b9	ldr	w0, [x13, #0x18]
10117d5c4:	ef 01 0c 0b	add	w15, w15, w12
10117d5c8:	10 02 0c 0b	add	w16, w16, w12
10117d5cc:	31 02 0c 0b	add	w17, w17, w12
10117d5d0:	00 00 0c 0b	add	w0, w0, w12
10117d5d4:	af 01 1d b8	stur	w15, [x13, #-0x30]
10117d5d8:	b0 81 1e b8	stur	w16, [x13, #-0x18]
10117d5dc:	b1 01 00 b9	str	w17, [x13]
10117d5e0:	a0 19 00 b9	str	w0, [x13, #0x18]
10117d5e4:	ad 81 01 91	add	x13, x13, #0x60
10117d5e8:	ce 11 00 f1	subs	x14, x14, #0x4
10117d5ec:	41 fe ff 54	b.ne	0x10117d5b4
10117d5f0:	6c 05 0b 8b	add	x12, x11, x11, lsl #1
10117d5f4:	8c f1 7d d3	lsl	x12, x12, #3
10117d5f8:	3f 01 0b eb	cmp	x9, x11
10117d5fc:	20 01 00 54	b.eq	0x10117d620
10117d600:	cd 52 40 b9	ldr	w13, [x22, #0x50]
10117d604:	0e 69 6c b8	ldr	w14, [x8, x12]
10117d608:	cd 01 0d 0b	add	w13, w14, w13
10117d60c:	0d 69 2c b8	str	w13, [x8, x12]
10117d610:	6b 05 00 91	add	x11, x11, #0x1
10117d614:	8c 61 00 91	add	x12, x12, #0x18
10117d618:	5f 01 0b eb	cmp	x10, x11
10117d61c:	e1 fe ff 54	b.ne	0x10117d5f8
10117d620:	00 01 40 bd	ldr	s0, [x8]
10117d624:	00 a4 20 0f	sshll.2d	v0, v0, #0x0
10117d628:	00 d8 61 5e	scvtf	d0, d0
10117d62c:	e1 53 c0 3d	ldr	q1, [sp, #0x140]
10117d630:	00 18 61 1e	fdiv	d0, d0, d1
10117d634:	0a 00 78 1e	fcvtzs	w10, d0
10117d638:	29 05 00 51	sub	w9, w9, #0x1
10117d63c:	5f 03 09 6b	cmp	w26, w9
10117d640:	4b b3 89 1a	csel	w11, w26, w9, lt
10117d644:	c9 1e 40 b9	ldr	w9, [x22, #0x1c]
10117d648:	e9 5b 01 b9	str	w9, [sp, #0x158]
10117d64c:	09 03 80 52	mov	w9, #0x18
10117d650:	6b 7d 29 9b	smull	x11, w11, w9
10117d654:	14 69 6b b8	ldr	w20, [x8, x11]
10117d658:	ff b7 01 f9	str	xzr, [sp, #0x368]
10117d65c:	ff b3 01 f9	str	xzr, [sp, #0x360]
10117d660:	0b 00 80 12	mov	w11, #-0x1
10117d664:	eb 73 03 b9	str	w11, [sp, #0x370]
10117d668:	ff d3 0d 39	strb	wzr, [sp, #0x374]
10117d66c:	5f 05 00 71	cmp	w10, #0x1
10117d670:	6b 0d 00 54	b.lt	0x10117d81c
10117d674:	15 00 80 d2	mov	x21, #0x0
10117d678:	4a 05 00 11	add	w10, w10, #0x1
10117d67c:	eb 05 80 92	mov	x11, #-0x30
10117d680:	5a 2d a9 9b	umaddl	x26, w10, w9, x11
10117d684:	3b 00 80 12	mov	w27, #-0x2
10117d688:	3c 00 80 52	mov	w28, #0x1
10117d68c:	d6 f1 01 b0	adrp	x22, 15929 ; 0x104fb6000
10117d690:	d6 26 1e 91	add	x22, x22, #0x789 ; literal pool for: "csv"
10117d694:	d7 f1 01 b0	adrp	x23, 15929 ; 0x104fb6000
10117d698:	f7 6e 1f 91	add	x23, x23, #0x7db ; literal pool for: "interval4.csv"
10117d69c:	08 10 6c 1e	fmov	d8, #0.50000000
10117d6a0:	13 00 8c 52	mov	w19, #0x6000
10117d6a4:	53 ed a8 72	movk	w19, #0x476a, lsl #16
10117d6a8:	d8 f1 01 b0	adrp	x24, 15929 ; 0x104fb6000
10117d6ac:	18 cf 1e 91	add	x24, x24, #0x7b3 ; literal pool for: "%.3f\015\n"
10117d6b0:	99 ef 01 90	adrp	x25, 15856 ; 0x104f6d000
10117d6b4:	39 db 1a 91	add	x25, x25, #0x6b6 ; literal pool for: "\015\n"
10117d6b8:	08 01 15 8b	add	x8, x8, x21
10117d6bc:	00 01 40 bd	ldr	s0, [x8]
10117d6c0:	00 a4 20 0f	sshll.2d	v0, v0, #0x0
10117d6c4:	81 03 62 1e	scvtf	d1, w28
10117d6c8:	00 d8 61 5e	scvtf	d0, d0
10117d6cc:	e2 53 c0 3d	ldr	q2, [sp, #0x140]
10117d6d0:	41 a0 41 1f	fmsub	d1, d2, d1, d8
10117d6d4:	20 28 60 1e	fadd	d0, d1, d0
10117d6d8:	09 00 78 1e	fcvtzs	w9, d0
10117d6dc:	3f 01 00 71	cmp	w9, #0x0
10117d6e0:	29 c1 9f 1a	csel	w9, w9, wzr, gt
10117d6e4:	e9 63 03 b9	str	w9, [sp, #0x360]
10117d6e8:	08 0d 40 b9	ldr	w8, [x8, #0xc]
10117d6ec:	68 03 08 0b	add	w8, w27, w8
10117d6f0:	e9 03 08 6b	negs	w9, w8
10117d6f4:	08 05 00 12	and	w8, w8, #0x3
10117d6f8:	29 05 00 12	and	w9, w9, #0x3
10117d6fc:	08 45 89 5a	csneg	w8, w8, w9, mi
10117d700:	1f 01 00 71	cmp	w8, #0x0
10117d704:	09 15 00 11	add	w9, w8, #0x5
10117d708:	28 b5 88 1a	csinc	w8, w9, w8, lt
10117d70c:	e8 6f 03 b9	str	w8, [sp, #0x36c]
10117d710:	e8 03 0c 91	add	x8, sp, #0x300
10117d714:	b6 be bb 97	bl	__ZN6common12PropertyPathEv
10117d718:	e0 63 0d 91	add	x0, sp, #0x358
10117d71c:	e1 03 16 aa	mov	x1, x22
10117d720:	ef b2 4c 94	bl	__ZN4juce9StringRefC1EPKc
10117d724:	e1 af 41 f9	ldr	x1, [sp, #0x358]
10117d728:	e8 63 0c 91	add	x8, sp, #0x318
10117d72c:	e0 03 0c 91	add	x0, sp, #0x300
10117d730:	54 d0 4c 94	bl	__ZNK4juce4File12getChildFileENS_9StringRefE
10117d734:	e0 03 0c 91	add	x0, sp, #0x300
10117d738:	f1 b3 4c 94	bl	__ZN4juce6StringD1Ev
10117d73c:	e0 63 0c 91	add	x0, sp, #0x318
10117d740:	a0 d4 4c 94	bl	__ZNK4juce4File6existsEv
10117d744:	c0 00 00 37	tbnz	w0, #0x0, 0x10117d75c
10117d748:	e8 43 0d 91	add	x8, sp, #0x350
10117d74c:	e0 63 0c 91	add	x0, sp, #0x318
10117d750:	45 d6 4c 94	bl	__ZNK4juce4File15createDirectoryEv
10117d754:	e0 43 0d 91	add	x0, sp, #0x350
10117d758:	e9 b3 4c 94	bl	__ZN4juce6StringD1Ev
10117d75c:	e0 23 0d 91	add	x0, sp, #0x348
10117d760:	e1 03 17 aa	mov	x1, x23
10117d764:	de b2 4c 94	bl	__ZN4juce9StringRefC1EPKc
10117d768:	e1 a7 41 f9	ldr	x1, [sp, #0x348]
10117d76c:	e8 03 0c 91	add	x8, sp, #0x300
10117d770:	e0 63 0c 91	add	x0, sp, #0x318
10117d774:	43 d0 4c 94	bl	__ZNK4juce4File12getChildFileENS_9StringRefE
10117d778:	e8 77 40 f9	ldr	x8, [sp, #0xe8]
10117d77c:	00 01 40 bd	ldr	s0, [x8]
10117d780:	61 02 27 1e	fmov	s1, w19
10117d784:	20 18 20 1e	fdiv	s0, s1, s0
10117d788:	e0 6b 03 bd	str	s0, [sp, #0x368]
10117d78c:	e0 43 0b 91	add	x0, sp, #0x2d0
10117d790:	e1 03 18 aa	mov	x1, x24
10117d794:	2a c4 4c 94	bl	__ZN4juce6StringC1EPKc
10117d798:	e9 6b 43 bd	ldr	s9, [sp, #0x368]
10117d79c:	e0 43 0b 91	add	x0, sp, #0x2d0
10117d7a0:	ea f7 4c 94	bl	__ZNK4juce6String9toRawUTF8Ev
10117d7a4:	20 c1 22 1e	fcvt	d0, s9
10117d7a8:	e0 03 00 fd	str	d0, [sp]
10117d7ac:	e8 a3 0b 91	add	x8, sp, #0x2e8
10117d7b0:	6e 65 4d 94	bl	__ZN4juce6String12formattedRawEPKcz
10117d7b4:	e0 03 0c 91	add	x0, sp, #0x300
10117d7b8:	e1 a3 0b 91	add	x1, sp, #0x2e8
10117d7bc:	02 00 80 52	mov	w2, #0x0
10117d7c0:	03 00 80 52	mov	w3, #0x0
10117d7c4:	e4 03 19 aa	mov	x4, x25
10117d7c8:	95 f0 4c 94	bl	__ZNK4juce4File10appendTextERKNS_6StringEbbPKc
10117d7cc:	e0 a3 0b 91	add	x0, sp, #0x2e8
10117d7d0:	cb b3 4c 94	bl	__ZN4juce6StringD1Ev
10117d7d4:	e0 43 0b 91	add	x0, sp, #0x2d0
10117d7d8:	c9 b3 4c 94	bl	__ZN4juce6StringD1Ev
10117d7dc:	e0 03 0c 91	add	x0, sp, #0x300
10117d7e0:	c7 b3 4c 94	bl	__ZN4juce6StringD1Ev
10117d7e4:	e0 63 0c 91	add	x0, sp, #0x318
10117d7e8:	c5 b3 4c 94	bl	__ZN4juce6StringD1Ev
10117d7ec:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
10117d7f0:	01 00 40 f9	ldr	x1, [x0]
10117d7f4:	e2 83 0d 91	add	x2, sp, #0x360
10117d7f8:	88 06 ff 97	bl	__ZNSt3__16vectorIN16BeatAnalyzer_2_06peakss8BeatInfoENS_9allocatorIS3_EEE6insertENS_11__wrap_iterIPKS3_EERS8_
10117d7fc:	5f 03 15 eb	cmp	x26, x21
10117d800:	e0 00 00 54	b.eq	0x10117d81c
10117d804:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
10117d808:	08 01 40 f9	ldr	x8, [x8]
10117d80c:	7b 07 00 51	sub	w27, w27, #0x1
10117d810:	9c 07 00 11	add	w28, w28, #0x1
10117d814:	b5 62 00 91	add	x21, x21, #0x18
10117d818:	a8 ff ff 17	b	0x10117d6b8
10117d81c:	e8 5b 41 b9	ldr	w8, [sp, #0x158]
10117d820:	08 01 14 4b	sub	w8, w8, w20
10117d824:	00 01 62 1e	scvtf	d0, w8
10117d828:	e1 53 c0 3d	ldr	q1, [sp, #0x140]
10117d82c:	00 18 61 1e	fdiv	d0, d0, d1
10117d830:	14 00 78 1e	fcvtzs	w20, d0
10117d834:	9f 06 00 71	cmp	w20, #0x1
10117d838:	fb 77 40 f9	ldr	x27, [sp, #0xe8]
10117d83c:	f8 f3 01 b2	mov	x24, #-0x5555555555555556
10117d840:	58 55 e1 f2	movk	x24, #0xaaa, lsl #48
10117d844:	4b 16 00 54	b.lt	0x10117db0c
10117d848:	e8 97 40 f9	ldr	x8, [sp, #0x128]
10117d84c:	08 25 47 a9	ldp	x8, x9, [x8, #0x70]
10117d850:	29 01 08 cb	sub	x9, x9, x8
10117d854:	29 fd 43 d3	lsr	x9, x9, #3
10117d858:	6a 55 95 52	mov	w10, #0xaaab
10117d85c:	4a 55 b5 72	movk	w10, #0xaaaa, lsl #16
10117d860:	29 7d 0a 1b	mul	w9, w9, w10
10117d864:	29 05 00 51	sub	w9, w9, #0x1
10117d868:	36 7d 40 93	sxtw	x22, w9
10117d86c:	35 00 80 52	mov	w21, #0x1
10117d870:	08 10 6c 1e	fmov	d8, #0.50000000
10117d874:	d3 f1 01 b0	adrp	x19, 15929 ; 0x104fb6000
10117d878:	73 26 1e 91	add	x19, x19, #0x789 ; literal pool for: "csv"
10117d87c:	d7 f1 01 b0	adrp	x23, 15929 ; 0x104fb6000
10117d880:	f7 a6 1f 91	add	x23, x23, #0x7e9 ; literal pool for: "interval5.csv"
10117d884:	19 00 8c 52	mov	w25, #0x6000
10117d888:	59 ed a8 72	movk	w25, #0x476a, lsl #16
10117d88c:	dc f1 01 b0	adrp	x28, 15929 ; 0x104fb6000
10117d890:	9c cf 1e 91	add	x28, x28, #0x7b3 ; literal pool for: "%.3f\015\n"
10117d894:	09 03 80 52	mov	w9, #0x18
10117d898:	c8 22 09 9b	madd	x8, x22, x9, x8
10117d89c:	00 01 40 bd	ldr	s0, [x8]
10117d8a0:	00 a4 20 0f	sshll.2d	v0, v0, #0x0
10117d8a4:	a1 02 62 1e	scvtf	d1, w21
10117d8a8:	00 d8 61 5e	scvtf	d0, d0
10117d8ac:	e2 53 c0 3d	ldr	q2, [sp, #0x140]
10117d8b0:	41 20 41 1f	fmadd	d1, d2, d1, d8
10117d8b4:	20 28 60 1e	fadd	d0, d1, d0
10117d8b8:	09 00 78 1e	fcvtzs	w9, d0
10117d8bc:	ea 97 40 f9	ldr	x10, [sp, #0x128]
10117d8c0:	4a 1d 40 b9	ldr	w10, [x10, #0x1c]
10117d8c4:	5f 01 09 6b	cmp	w10, w9
10117d8c8:	49 b1 89 1a	csel	w9, w10, w9, lt
10117d8cc:	e9 63 03 b9	str	w9, [sp, #0x360]
10117d8d0:	08 0d 40 b9	ldr	w8, [x8, #0xc]
10117d8d4:	a8 02 08 0b	add	w8, w21, w8
10117d8d8:	08 05 00 51	sub	w8, w8, #0x1
10117d8dc:	09 05 00 12	and	w9, w8, #0x3
10117d8e0:	e8 03 08 6b	negs	w8, w8
10117d8e4:	08 05 00 12	and	w8, w8, #0x3
10117d8e8:	28 45 88 5a	csneg	w8, w9, w8, mi
10117d8ec:	08 05 00 11	add	w8, w8, #0x1
10117d8f0:	e8 6f 03 b9	str	w8, [sp, #0x36c]
10117d8f4:	e8 03 0c 91	add	x8, sp, #0x300
10117d8f8:	3d be bb 97	bl	__ZN6common12PropertyPathEv
10117d8fc:	e0 03 0d 91	add	x0, sp, #0x340
10117d900:	e1 03 13 aa	mov	x1, x19
10117d904:	76 b2 4c 94	bl	__ZN4juce9StringRefC1EPKc
10117d908:	e1 a3 41 f9	ldr	x1, [sp, #0x340]
10117d90c:	e8 63 0c 91	add	x8, sp, #0x318
10117d910:	e0 03 0c 91	add	x0, sp, #0x300
10117d914:	db cf 4c 94	bl	__ZNK4juce4File12getChildFileENS_9StringRefE
10117d918:	e0 03 0c 91	add	x0, sp, #0x300
10117d91c:	78 b3 4c 94	bl	__ZN4juce6StringD1Ev
10117d920:	e0 63 0c 91	add	x0, sp, #0x318
10117d924:	27 d4 4c 94	bl	__ZNK4juce4File6existsEv
10117d928:	c0 00 00 37	tbnz	w0, #0x0, 0x10117d940
10117d92c:	e8 e3 0c 91	add	x8, sp, #0x338
10117d930:	e0 63 0c 91	add	x0, sp, #0x318
10117d934:	cc d5 4c 94	bl	__ZNK4juce4File15createDirectoryEv
10117d938:	e0 e3 0c 91	add	x0, sp, #0x338
10117d93c:	70 b3 4c 94	bl	__ZN4juce6StringD1Ev
10117d940:	e0 c3 0c 91	add	x0, sp, #0x330
10117d944:	e1 03 17 aa	mov	x1, x23
10117d948:	65 b2 4c 94	bl	__ZN4juce9StringRefC1EPKc
10117d94c:	e1 9b 41 f9	ldr	x1, [sp, #0x330]
10117d950:	e8 03 0c 91	add	x8, sp, #0x300
10117d954:	e0 63 0c 91	add	x0, sp, #0x318
10117d958:	ca cf 4c 94	bl	__ZNK4juce4File12getChildFileENS_9StringRefE
10117d95c:	60 03 40 bd	ldr	s0, [x27]
10117d960:	21 03 27 1e	fmov	s1, w25
10117d964:	20 18 20 1e	fdiv	s0, s1, s0
10117d968:	e0 6b 03 bd	str	s0, [sp, #0x368]
10117d96c:	e0 43 0b 91	add	x0, sp, #0x2d0
10117d970:	e1 03 1c aa	mov	x1, x28
10117d974:	b2 c3 4c 94	bl	__ZN4juce6StringC1EPKc
10117d978:	e9 6b 43 bd	ldr	s9, [sp, #0x368]
10117d97c:	e0 43 0b 91	add	x0, sp, #0x2d0
10117d980:	72 f7 4c 94	bl	__ZNK4juce6String9toRawUTF8Ev
10117d984:	20 c1 22 1e	fcvt	d0, s9
10117d988:	e0 03 00 fd	str	d0, [sp]
10117d98c:	e8 a3 0b 91	add	x8, sp, #0x2e8
10117d990:	f6 64 4d 94	bl	__ZN4juce6String12formattedRawEPKcz
10117d994:	e0 03 0c 91	add	x0, sp, #0x300
10117d998:	e1 a3 0b 91	add	x1, sp, #0x2e8
10117d99c:	02 00 80 52	mov	w2, #0x0
10117d9a0:	03 00 80 52	mov	w3, #0x0
10117d9a4:	84 ef 01 90	adrp	x4, 15856 ; 0x104f6d000
10117d9a8:	84 d8 1a 91	add	x4, x4, #0x6b6 ; literal pool for: "\015\n"
10117d9ac:	1c f0 4c 94	bl	__ZNK4juce4File10appendTextERKNS_6StringEbbPKc
10117d9b0:	e0 a3 0b 91	add	x0, sp, #0x2e8
10117d9b4:	52 b3 4c 94	bl	__ZN4juce6StringD1Ev
10117d9b8:	e0 43 0b 91	add	x0, sp, #0x2d0
10117d9bc:	50 b3 4c 94	bl	__ZN4juce6StringD1Ev
10117d9c0:	e0 03 0c 91	add	x0, sp, #0x300
10117d9c4:	4e b3 4c 94	bl	__ZN4juce6StringD1Ev
10117d9c8:	e0 63 0c 91	add	x0, sp, #0x318
10117d9cc:	4c b3 4c 94	bl	__ZN4juce6StringD1Ev
10117d9d0:	ea 97 40 f9	ldr	x10, [sp, #0x128]
10117d9d4:	48 a5 47 a9	ldp	x8, x9, [x10, #0x78]
10117d9d8:	1f 01 09 eb	cmp	x8, x9
10117d9dc:	00 01 00 54	b.eq	0x10117d9fc
10117d9e0:	e9 83 0d 91	add	x9, sp, #0x360
10117d9e4:	20 01 c0 3d	ldr	q0, [x9]
10117d9e8:	e9 bb 41 f9	ldr	x9, [sp, #0x370]
10117d9ec:	09 09 00 f9	str	x9, [x8, #0x10]
10117d9f0:	00 85 81 3c	str	q0, [x8], #0x18
10117d9f4:	48 3d 00 f9	str	x8, [x10, #0x78]
10117d9f8:	3f 00 00 14	b	0x10117daf4
10117d9fc:	f5 5b 01 b9	str	w21, [sp, #0x158]
10117da00:	f9 03 13 aa	mov	x25, x19
10117da04:	e9 b3 40 f9	ldr	x9, [sp, #0x160]
10117da08:	3a 01 40 f9	ldr	x26, [x9]
10117da0c:	1b 01 1a cb	sub	x27, x8, x26
10117da10:	68 ff 43 93	asr	x8, x27, #3
10117da14:	e9 f3 01 b2	mov	x9, #-0x5555555555555556
10117da18:	69 55 95 f2	movk	x9, #0xaaab
10117da1c:	13 7d 09 9b	mul	x19, x8, x9
10117da20:	68 06 00 91	add	x8, x19, #0x1
10117da24:	1f 01 18 eb	cmp	x8, x24
10117da28:	e8 af 01 54	b.hi	0x101181024
10117da2c:	f5 03 1c aa	mov	x21, x28
10117da30:	fc 03 14 aa	mov	x28, x20
10117da34:	f4 03 16 aa	mov	x20, x22
10117da38:	f6 03 17 aa	mov	x22, x23
10117da3c:	69 fa 7f d3	lsl	x9, x19, #1
10117da40:	3f 01 08 eb	cmp	x9, x8
10117da44:	28 81 88 9a	csel	x8, x9, x8, hi
10117da48:	e9 f3 00 b2	mov	x9, #0x5555555555555555
10117da4c:	a9 aa e0 f2	movk	x9, #0x555, lsl #48
10117da50:	7f 02 09 eb	cmp	x19, x9
10117da54:	17 31 98 9a	csel	x23, x8, x24, lo
10117da58:	f7 00 00 b4	cbz	x23, 0x10117da74
10117da5c:	ff 02 18 eb	cmp	x23, x24
10117da60:	48 ba 01 54	b.hi	0x1011811a8
10117da64:	e8 06 17 8b	add	x8, x23, x23, lsl #1
10117da68:	00 f1 7d d3	lsl	x0, x8, #3
10117da6c:	19 50 8d 94	bl	0x1034d1ad0 ; symbol stub for: __Znwm
10117da70:	02 00 00 14	b	0x10117da78
10117da74:	00 00 80 d2	mov	x0, #0x0
10117da78:	09 03 80 52	mov	w9, #0x18
10117da7c:	68 02 09 9b	madd	x8, x19, x9, x0
10117da80:	f7 02 09 9b	madd	x23, x23, x9, x0
10117da84:	e9 83 0d 91	add	x9, sp, #0x360
10117da88:	20 01 c0 3d	ldr	q0, [x9]
10117da8c:	00 01 80 3d	str	q0, [x8]
10117da90:	e9 bb 41 f9	ldr	x9, [sp, #0x370]
10117da94:	09 09 00 f9	str	x9, [x8, #0x10]
10117da98:	18 61 00 91	add	x24, x8, #0x18
10117da9c:	13 01 1b cb	sub	x19, x8, x27
10117daa0:	e0 03 13 aa	mov	x0, x19
10117daa4:	e1 03 1a aa	mov	x1, x26
10117daa8:	e2 03 1b aa	mov	x2, x27
10117daac:	e8 52 8d 94	bl	0x1034d264c ; symbol stub for: _memmove
10117dab0:	e8 97 40 f9	ldr	x8, [sp, #0x128]
10117dab4:	13 61 07 a9	stp	x19, x24, [x8, #0x70]
10117dab8:	17 41 00 f9	str	x23, [x8, #0x80]
10117dabc:	fb 77 40 f9	ldr	x27, [sp, #0xe8]
10117dac0:	f8 f3 01 b2	mov	x24, #-0x5555555555555556
10117dac4:	58 55 e1 f2	movk	x24, #0xaaa, lsl #48
10117dac8:	f3 03 19 aa	mov	x19, x25
10117dacc:	f7 03 16 aa	mov	x23, x22
10117dad0:	f6 03 14 aa	mov	x22, x20
10117dad4:	f4 03 1c aa	mov	x20, x28
10117dad8:	19 00 8c 52	mov	w25, #0x6000
10117dadc:	59 ed a8 72	movk	w25, #0x476a, lsl #16
10117dae0:	fc 03 15 aa	mov	x28, x21
10117dae4:	f5 5b 41 b9	ldr	w21, [sp, #0x158]
10117dae8:	7a 00 00 b4	cbz	x26, 0x10117daf4
10117daec:	e0 03 1a aa	mov	x0, x26
10117daf0:	f2 4f 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10117daf4:	9f 02 15 6b	cmp	w20, w21
10117daf8:	a0 00 00 54	b.eq	0x10117db0c
10117dafc:	b5 06 00 11	add	w21, w21, #0x1
10117db00:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
10117db04:	08 01 40 f9	ldr	x8, [x8]
10117db08:	63 ff ff 17	b	0x10117d894
10117db0c:	fa 97 40 f9	ldr	x26, [sp, #0x128]
10117db10:	48 b3 40 39	ldrb	w8, [x26, #0x2c]
10117db14:	a8 00 00 35	cbnz	w8, 0x10117db28
10117db18:	40 43 19 91	add	x0, x26, #0x650
10117db1c:	e1 03 1b aa	mov	x1, x27
10117db20:	e2 b3 40 f9	ldr	x2, [sp, #0x160]
10117db24:	05 f5 fe 97	bl	__ZN16BeatAnalyzer_2_014UnitBeatAdjust7analyzeERfRNSt3__16vectorINS_6peakss8BeatInfoENS2_9allocatorIS5_EEEE
10117db28:	49 23 47 a9	ldp	x9, x8, [x26, #0x70]
10117db2c:	08 01 09 cb	sub	x8, x8, x9
10117db30:	08 fd 43 93	asr	x8, x8, #3
10117db34:	e9 f3 01 b2	mov	x9, #-0x5555555555555556
10117db38:	69 55 95 f2	movk	x9, #0xaaab
10117db3c:	13 7d 09 9b	mul	x19, x8, x9
10117db40:	79 0a 00 11	add	w25, w19, #0x2
10117db44:	e8 03 19 aa	mov	x8, x25
10117db48:	1c 7d 40 93	sxtw	x28, w8
10117db4c:	e0 63 0c 91	add	x0, sp, #0x318
10117db50:	e1 03 1c aa	mov	x1, x28
10117db54:	a7 10 00 94	bl	__ZNSt3__16vectorIdNS_9allocatorIdEEEC1Em
10117db58:	e0 03 0c 91	add	x0, sp, #0x300
10117db5c:	e1 03 1c aa	mov	x1, x28
10117db60:	a4 10 00 94	bl	__ZNSt3__16vectorIdNS_9allocatorIdEEEC1Em
10117db64:	f4 9f 40 f9	ldr	x20, [sp, #0x138]
10117db68:	e0 a3 0b 91	add	x0, sp, #0x2e8
10117db6c:	e1 03 1c aa	mov	x1, x28
10117db70:	a0 10 00 94	bl	__ZNSt3__16vectorIdNS_9allocatorIdEEEC1Em
10117db74:	e0 43 0b 91	add	x0, sp, #0x2d0
10117db78:	e1 03 1c aa	mov	x1, x28
10117db7c:	9d 10 00 94	bl	__ZNSt3__16vectorIdNS_9allocatorIdEEEC1Em
10117db80:	e0 e3 0a 91	add	x0, sp, #0x2b8
10117db84:	e1 03 1c aa	mov	x1, x28
10117db88:	9a 10 00 94	bl	__ZNSt3__16vectorIdNS_9allocatorIdEEEC1Em
10117db8c:	e0 83 0a 91	add	x0, sp, #0x2a0
10117db90:	e1 03 1c aa	mov	x1, x28
10117db94:	97 10 00 94	bl	__ZNSt3__16vectorIdNS_9allocatorIdEEEC1Em
10117db98:	68 06 00 11	add	w8, w19, #0x1
10117db9c:	16 7d 40 93	sxtw	x22, w8
10117dba0:	e0 23 0a 91	add	x0, sp, #0x288
10117dba4:	e1 03 16 aa	mov	x1, x22
10117dba8:	92 10 00 94	bl	__ZNSt3__16vectorIdNS_9allocatorIdEEEC1Em
10117dbac:	e0 c3 09 91	add	x0, sp, #0x270
10117dbb0:	e1 03 16 aa	mov	x1, x22
10117dbb4:	8f 10 00 94	bl	__ZNSt3__16vectorIdNS_9allocatorIdEEEC1Em
10117dbb8:	e0 63 09 91	add	x0, sp, #0x258
10117dbbc:	e1 03 1c aa	mov	x1, x28
10117dbc0:	8c 10 00 94	bl	__ZNSt3__16vectorIdNS_9allocatorIdEEEC1Em
10117dbc4:	e0 03 09 91	add	x0, sp, #0x240
10117dbc8:	e1 03 1c aa	mov	x1, x28
10117dbcc:	e1 10 00 94	bl	__ZNSt3__16vectorIiNS_9allocatorIiEEEC1Em
10117dbd0:	e0 a3 08 91	add	x0, sp, #0x228
10117dbd4:	e1 03 1c aa	mov	x1, x28
10117dbd8:	de 10 00 94	bl	__ZNSt3__16vectorIiNS_9allocatorIiEEEC1Em
10117dbdc:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
10117dbe0:	08 01 40 f9	ldr	x8, [x8]
10117dbe4:	08 01 40 b9	ldr	w8, [x8]
10117dbe8:	01 01 62 1e	scvtf	d1, w8
10117dbec:	80 02 40 bd	ldr	s0, [x20]
10117dbf0:	00 a4 20 0f	sshll.2d	v0, v0, #0x0
10117dbf4:	02 d8 61 5e	scvtf	d2, d0
10117dbf8:	60 03 40 bd	ldr	s0, [x27]
10117dbfc:	03 c0 22 1e	fcvt	d3, s0
10117dc00:	c9 09 e8 d2	mov	x9, #0x404e000000000000
10117dc04:	24 01 67 9e	fmov	d4, x9
10117dc08:	42 08 64 1e	fmul	d2, d2, d4
10117dc0c:	63 08 61 1e	fmul	d3, d3, d1
10117dc10:	69 18 62 1e	fdiv	d9, d3, d2
10117dc14:	03 10 6c 1e	fmov	d3, #0.50000000
10117dc18:	20 21 63 1e	fcmp	d9, d3
10117dc1c:	eb 03 00 54	b.lt	0x10117dc98
10117dc20:	40 18 61 1e	fdiv	d0, d2, d1
10117dc24:	1f 01 00 71	cmp	w8, #0x0
10117dc28:	c8 0b e8 d2	mov	x8, #0x405e000000000000
10117dc2c:	01 01 67 9e	fmov	d1, x8
10117dc30:	2a 0c 60 1e	fcsel	d10, d1, d0, eq
10117dc34:	54 43 19 91	add	x20, x26, #0x650
10117dc38:	48 41 62 1e	fcvt	s8, d10
10117dc3c:	00 10 2c 1e	fmov	s0, #0.50000000
10117dc40:	00 09 20 1e	fmul	s0, s8, s0
10117dc44:	e0 03 14 aa	mov	x0, x20
10117dc48:	01 00 80 52	mov	w1, #0x0
10117dc4c:	c5 fe fe 97	bl	__ZN16BeatAnalyzer_2_014UnitBeatAdjust12calcLowIntegEfi
10117dc50:	00 08 6a 1e	fmul	d0, d0, d10
10117dc54:	61 03 40 bd	ldr	s1, [x27]
10117dc58:	21 c0 22 1e	fcvt	d1, s1
10117dc5c:	00 18 61 1e	fdiv	d0, d0, d1
10117dc60:	e8 8f 41 f9	ldr	x8, [sp, #0x318]
10117dc64:	00 01 00 fd	str	d0, [x8]
10117dc68:	e0 03 14 aa	mov	x0, x20
10117dc6c:	00 41 20 1e	fmov	s0, s8
10117dc70:	01 00 80 52	mov	w1, #0x0
10117dc74:	4e ff fe 97	bl	__ZN16BeatAnalyzer_2_014UnitBeatAdjust12calcAllIntegEfi
10117dc78:	01 08 6a 1e	fmul	d1, d0, d10
10117dc7c:	60 03 40 bd	ldr	s0, [x27]
10117dc80:	02 c0 22 1e	fcvt	d2, s0
10117dc84:	21 18 62 1e	fdiv	d1, d1, d2
10117dc88:	e8 77 41 f9	ldr	x8, [sp, #0x2e8]
10117dc8c:	01 01 00 fd	str	d1, [x8]
10117dc90:	e8 8f 41 f9	ldr	x8, [sp, #0x318]
10117dc94:	05 00 00 14	b	0x10117dca8
10117dc98:	e8 8f 41 f9	ldr	x8, [sp, #0x318]
10117dc9c:	1f 01 00 f9	str	xzr, [x8]
10117dca0:	e9 77 41 f9	ldr	x9, [sp, #0x2e8]
10117dca4:	3f 01 00 f9	str	xzr, [x9]
10117dca8:	1f 79 36 f8	str	xzr, [x8, x22, lsl #3]
10117dcac:	7f 06 00 71	cmp	w19, #0x1
10117dcb0:	6b 03 00 54	b.lt	0x10117dd1c
10117dcb4:	14 00 80 d2	mov	x20, #0x0
10117dcb8:	58 43 19 91	add	x24, x26, #0x650
10117dcbc:	68 7e 40 92	and	x8, x19, #0xffffffff
10117dcc0:	09 03 80 52	mov	w9, #0x18
10117dcc4:	08 7d 09 9b	mul	x8, x8, x9
10117dcc8:	15 61 00 d1	sub	x21, x8, #0x18
10117dccc:	17 01 80 52	mov	w23, #0x8
10117dcd0:	08 10 2c 1e	fmov	s8, #0.50000000
10117dcd4:	0a e4 00 2f	movi	d10, #0000000000000000
10117dcd8:	00 08 28 1e	fmul	s0, s0, s8
10117dcdc:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
10117dce0:	08 01 40 f9	ldr	x8, [x8]
10117dce4:	01 69 74 b8	ldr	w1, [x8, x20]
10117dce8:	e0 03 18 aa	mov	x0, x24
10117dcec:	9d fe fe 97	bl	__ZN16BeatAnalyzer_2_014UnitBeatAdjust12calcLowIntegEfi
10117dcf0:	e8 8f 41 f9	ldr	x8, [sp, #0x318]
10117dcf4:	08 20 60 1e	fcmp	d0, #0.0
10117dcf8:	84 ba 40 fa	ccmp	x20, #0x0, #0x4, lt
10117dcfc:	40 1d 60 1e	fcsel	d0, d10, d0, ne
10117dd00:	00 69 37 fc	str	d0, [x8, x23]
10117dd04:	bf 02 14 eb	cmp	x21, x20
10117dd08:	a0 00 00 54	b.eq	0x10117dd1c
10117dd0c:	60 03 40 bd	ldr	s0, [x27]
10117dd10:	94 62 00 91	add	x20, x20, #0x18
10117dd14:	f7 22 00 91	add	x23, x23, #0x8
10117dd18:	f0 ff ff 17	b	0x10117dcd8
10117dd1c:	e9 8f 41 f9	ldr	x9, [sp, #0x318]
10117dd20:	21 01 40 fd	ldr	d1, [x9]
10117dd24:	e8 83 41 f9	ldr	x8, [sp, #0x300]
10117dd28:	01 01 00 fd	str	d1, [x8]
10117dd2c:	00 e4 00 2f	movi	d0, #0000000000000000
10117dd30:	93 04 f8 37	tbnz	w19, #0x1f, 0x10117ddc0
10117dd34:	4a 00 80 52	mov	w10, #0x2
10117dd38:	3f 0b 00 71	cmp	w25, #0x2
10117dd3c:	2a c3 8a 1a	csel	w10, w25, w10, gt
10117dd40:	4c 05 00 d1	sub	x12, x10, #0x1
10117dd44:	9f 21 00 f1	cmp	x12, #0x8
10117dd48:	23 01 00 54	b.lo	0x10117dd6c
10117dd4c:	0d 21 00 91	add	x13, x8, #0x8
10117dd50:	4b f1 7d d3	lsl	x11, x10, #3
10117dd54:	2e 01 0b 8b	add	x14, x9, x11
10117dd58:	bf 01 0e eb	cmp	x13, x14
10117dd5c:	62 03 00 54	b.hs	0x10117ddc8
10117dd60:	0b 01 0b 8b	add	x11, x8, x11
10117dd64:	3f 01 0b eb	cmp	x9, x11
10117dd68:	02 03 00 54	b.hs	0x10117ddc8
10117dd6c:	2b 00 80 52	mov	w11, #0x1
10117dd70:	6c f1 7d d3	lsl	x12, x11, #3
10117dd74:	29 01 0c 8b	add	x9, x9, x12
10117dd78:	0c 01 0c 8b	add	x12, x8, x12
10117dd7c:	4a 01 0b cb	sub	x10, x10, x11
10117dd80:	23 89 7f 6d	ldp	d3, d2, [x9, #-0x8]
10117dd84:	42 38 63 1e	fsub	d2, d2, d3
10117dd88:	82 85 00 fc	str	d2, [x12], #0x8
10117dd8c:	29 21 00 91	add	x9, x9, #0x8
10117dd90:	4a 05 00 f1	subs	x10, x10, #0x1
10117dd94:	61 ff ff 54	b.ne	0x10117dd80
10117dd98:	53 01 f8 37	tbnz	w19, #0x1f, 0x10117ddc0
10117dd9c:	00 e4 00 2f	movi	d0, #0000000000000000
10117dda0:	20 68 60 1e	fmaxnm	d0, d1, d0
10117dda4:	b3 06 00 34	cbz	w19, 0x10117de78
10117dda8:	c9 7e 40 92	and	x9, x22, #0xffffffff
10117ddac:	2b 05 00 d1	sub	x11, x9, #0x1
10117ddb0:	7f 21 00 f1	cmp	x11, #0x8
10117ddb4:	62 03 00 54	b.hs	0x10117de20
10117ddb8:	2a 00 80 52	mov	w10, #0x1
10117ddbc:	31 00 00 14	b	0x10117de80
10117ddc0:	29 00 80 52	mov	w9, #0x1
10117ddc4:	35 00 00 14	b	0x10117de98
10117ddc8:	8d f1 7d 92	and	x13, x12, #0xfffffffffffffff8
10117ddcc:	ab 01 40 b2	orr	x11, x13, #0x1
10117ddd0:	0e a1 00 91	add	x14, x8, #0x28
10117ddd4:	2f 81 00 91	add	x15, x9, #0x20
10117ddd8:	f0 03 0d aa	mov	x16, x13
10117dddc:	e2 81 de 3c	ldur	q2, [x15, #-0x18]
10117dde0:	e3 81 df 3c	ldur	q3, [x15, #-0x8]
10117dde4:	e4 81 c0 3c	ldur	q4, [x15, #0x8]
10117dde8:	e5 81 c1 3c	ldur	q5, [x15, #0x18]
10117ddec:	e6 1d 7f ad	ldp	q6, q7, [x15, #-0x20]
10117ddf0:	f0 45 c2 ac	ldp	q16, q17, [x15], #0x40
10117ddf4:	42 d4 e6 4e	fsub.2d	v2, v2, v6
10117ddf8:	63 d4 e7 4e	fsub.2d	v3, v3, v7
10117ddfc:	84 d4 f0 4e	fsub.2d	v4, v4, v16
10117de00:	a5 d4 f1 4e	fsub.2d	v5, v5, v17
10117de04:	c2 0d 3f ad	stp	q2, q3, [x14, #-0x20]
10117de08:	c4 15 82 ac	stp	q4, q5, [x14], #0x40
10117de0c:	10 22 00 f1	subs	x16, x16, #0x8
10117de10:	61 fe ff 54	b.ne	0x10117dddc
10117de14:	9f 01 0d eb	cmp	x12, x13
10117de18:	00 fc ff 54	b.eq	0x10117dd98
10117de1c:	d5 ff ff 17	b	0x10117dd70
10117de20:	6c f1 7d 92	and	x12, x11, #0xfffffffffffffff8
10117de24:	8a 01 40 b2	orr	x10, x12, #0x1
10117de28:	0d a1 00 91	add	x13, x8, #0x28
10117de2c:	00 04 08 4e	dup.2d	v0, v0[0]
10117de30:	ee 03 0c aa	mov	x14, x12
10117de34:	02 1c a0 4e	mov.16b	v2, v0
10117de38:	03 1c a0 4e	mov.16b	v3, v0
10117de3c:	04 1c a0 4e	mov.16b	v4, v0
10117de40:	a5 19 7f ad	ldp	q5, q6, [x13, #-0x20]
10117de44:	a7 41 c2 ac	ldp	q7, q16, [x13], #0x40
10117de48:	00 c4 65 4e	fmaxnm.2d	v0, v0, v5
10117de4c:	42 c4 66 4e	fmaxnm.2d	v2, v2, v6
10117de50:	63 c4 67 4e	fmaxnm.2d	v3, v3, v7
10117de54:	84 c4 70 4e	fmaxnm.2d	v4, v4, v16
10117de58:	ce 21 00 f1	subs	x14, x14, #0x8
10117de5c:	21 ff ff 54	b.ne	0x10117de40
10117de60:	00 c4 62 4e	fmaxnm.2d	v0, v0, v2
10117de64:	00 c4 63 4e	fmaxnm.2d	v0, v0, v3
10117de68:	00 c4 64 4e	fmaxnm.2d	v0, v0, v4
10117de6c:	00 c8 70 7e	fmaxnmp.2d	d0, v0
10117de70:	7f 01 0c eb	cmp	x11, x12
10117de74:	61 00 00 54	b.ne	0x10117de80
10117de78:	09 00 80 52	mov	w9, #0x0
10117de7c:	07 00 00 14	b	0x10117de98
10117de80:	29 01 0a cb	sub	x9, x9, x10
10117de84:	0a 0d 0a 8b	add	x10, x8, x10, lsl #3
10117de88:	42 85 40 fc	ldr	d2, [x10], #0x8
10117de8c:	00 68 62 1e	fmaxnm	d0, d0, d2
10117de90:	29 05 00 f1	subs	x9, x9, #0x1
10117de94:	a1 ff ff 54	b.ne	0x10117de88
10117de98:	02 c0 60 1e	fabs	d2, d0
10117de9c:	0a 96 e7 d2	mov	x10, #0x3cb0000000000000
10117dea0:	43 01 67 9e	fmov	d3, x10
10117dea4:	40 20 63 1e	fcmp	d2, d3
10117dea8:	ea d7 9f 1a	cset	w10, gt
10117deac:	35 01 0a 2a	orr	w21, w9, w10
10117deb0:	0d 05 00 54	b.le	0x10117df50
10117deb4:	e2 17 c0 3d	ldr	q2, [sp, #0x50]
10117deb8:	c9 04 00 37	tbnz	w9, #0x0, 0x10117df50
10117debc:	21 18 60 1e	fdiv	d1, d1, d0
10117dec0:	01 01 00 fd	str	d1, [x8]
10117dec4:	53 04 00 34	cbz	w19, 0x10117df4c
10117dec8:	ca 7e 40 92	and	x10, x22, #0xffffffff
10117decc:	4c 05 00 d1	sub	x12, x10, #0x1
10117ded0:	9f 21 00 f1	cmp	x12, #0x8
10117ded4:	62 00 00 54	b.hs	0x10117dee0
10117ded8:	2b 00 80 52	mov	w11, #0x1
10117dedc:	13 00 00 14	b	0x10117df28
10117dee0:	8d f1 7d 92	and	x13, x12, #0xfffffffffffffff8
10117dee4:	ab 01 40 b2	orr	x11, x13, #0x1
10117dee8:	01 04 08 4e	dup.2d	v1, v0[0]
10117deec:	41 fc 61 6e	fdiv.2d	v1, v2, v1
10117def0:	0e a1 00 91	add	x14, x8, #0x28
10117def4:	ef 03 0d aa	mov	x15, x13
10117def8:	c2 0d 7f ad	ldp	q2, q3, [x14, #-0x20]
10117defc:	c4 15 40 ad	ldp	q4, q5, [x14]
10117df00:	42 dc 61 6e	fmul.2d	v2, v2, v1
10117df04:	63 dc 61 6e	fmul.2d	v3, v3, v1
10117df08:	84 dc 61 6e	fmul.2d	v4, v4, v1
10117df0c:	a5 dc 61 6e	fmul.2d	v5, v5, v1
10117df10:	c2 0d 3f ad	stp	q2, q3, [x14, #-0x20]
10117df14:	c4 15 82 ac	stp	q4, q5, [x14], #0x40
10117df18:	ef 21 00 f1	subs	x15, x15, #0x8
10117df1c:	e1 fe ff 54	b.ne	0x10117def8
10117df20:	9f 01 0d eb	cmp	x12, x13
10117df24:	40 01 00 54	b.eq	0x10117df4c
10117df28:	01 10 6e 1e	fmov	d1, #1.00000000
10117df2c:	4a 01 0b cb	sub	x10, x10, x11
10117df30:	08 0d 0b 8b	add	x8, x8, x11, lsl #3
10117df34:	20 18 60 1e	fdiv	d0, d1, d0
10117df38:	01 01 40 fd	ldr	d1, [x8]
10117df3c:	21 08 60 1e	fmul	d1, d1, d0
10117df40:	01 85 00 fc	str	d1, [x8], #0x8
10117df44:	4a 05 00 f1	subs	x10, x10, #0x1
10117df48:	81 ff ff 54	b.ne	0x10117df38
10117df4c:	f5 03 09 aa	mov	x21, x9
10117df50:	e9 77 41 f9	ldr	x9, [sp, #0x2e8]
10117df54:	3f 79 36 f8	str	xzr, [x9, x22, lsl #3]
10117df58:	7f 06 00 71	cmp	w19, #0x1
10117df5c:	f6 a3 00 f9	str	x22, [sp, #0x140]
10117df60:	6b 03 00 54	b.lt	0x10117dfcc
10117df64:	f6 03 15 aa	mov	x22, x21
10117df68:	14 00 80 d2	mov	x20, #0x0
10117df6c:	58 43 19 91	add	x24, x26, #0x650
10117df70:	68 7e 40 92	and	x8, x19, #0xffffffff
10117df74:	08 45 33 8b	add	x8, x8, w19, uxtw #1
10117df78:	15 f1 7d d3	lsl	x21, x8, #3
10117df7c:	17 01 80 52	mov	w23, #0x8
10117df80:	08 e4 00 2f	movi	d8, #0000000000000000
10117df84:	60 03 40 bd	ldr	s0, [x27]
10117df88:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
10117df8c:	08 01 40 f9	ldr	x8, [x8]
10117df90:	01 69 74 b8	ldr	w1, [x8, x20]
10117df94:	e0 03 18 aa	mov	x0, x24
10117df98:	85 fe fe 97	bl	__ZN16BeatAnalyzer_2_014UnitBeatAdjust12calcAllIntegEfi
10117df9c:	e8 77 41 f9	ldr	x8, [sp, #0x2e8]
10117dfa0:	08 20 60 1e	fcmp	d0, #0.0
10117dfa4:	84 ba 40 fa	ccmp	x20, #0x0, #0x4, lt
10117dfa8:	00 1d 60 1e	fcsel	d0, d8, d0, ne
10117dfac:	00 69 37 fc	str	d0, [x8, x23]
10117dfb0:	94 62 00 91	add	x20, x20, #0x18
10117dfb4:	f7 22 00 91	add	x23, x23, #0x8
10117dfb8:	bf 02 14 eb	cmp	x21, x20
10117dfbc:	41 fe ff 54	b.ne	0x10117df84
10117dfc0:	e9 77 41 f9	ldr	x9, [sp, #0x2e8]
10117dfc4:	f5 03 16 aa	mov	x21, x22
10117dfc8:	f6 a3 40 f9	ldr	x22, [sp, #0x140]
10117dfcc:	20 01 40 fd	ldr	d0, [x9]
10117dfd0:	e8 6b 41 f9	ldr	x8, [sp, #0x2d0]
10117dfd4:	00 01 00 fd	str	d0, [x8]
10117dfd8:	53 03 f8 37	tbnz	w19, #0x1f, 0x10117e040
10117dfdc:	4a 00 80 52	mov	w10, #0x2
10117dfe0:	3f 0b 00 71	cmp	w25, #0x2
10117dfe4:	2a c3 8a 1a	csel	w10, w25, w10, gt
10117dfe8:	4c 05 00 d1	sub	x12, x10, #0x1
10117dfec:	9f 21 00 f1	cmp	x12, #0x8
10117dff0:	23 01 00 54	b.lo	0x10117e014
10117dff4:	0d 21 00 91	add	x13, x8, #0x8
10117dff8:	4b f1 7d d3	lsl	x11, x10, #3
10117dffc:	2e 01 0b 8b	add	x14, x9, x11
10117e000:	bf 01 0e eb	cmp	x13, x14
10117e004:	22 03 00 54	b.hs	0x10117e068
10117e008:	0b 01 0b 8b	add	x11, x8, x11
10117e00c:	3f 01 0b eb	cmp	x9, x11
10117e010:	c2 02 00 54	b.hs	0x10117e068
10117e014:	2b 00 80 52	mov	w11, #0x1
10117e018:	6c f1 7d d3	lsl	x12, x11, #3
10117e01c:	29 01 0c 8b	add	x9, x9, x12
10117e020:	0c 01 0c 8b	add	x12, x8, x12
10117e024:	4a 01 0b cb	sub	x10, x10, x11
10117e028:	22 85 7f 6d	ldp	d2, d1, [x9, #-0x8]
10117e02c:	21 38 62 1e	fsub	d1, d1, d2
10117e030:	81 85 00 fc	str	d1, [x12], #0x8
10117e034:	29 21 00 91	add	x9, x9, #0x8
10117e038:	4a 05 00 f1	subs	x10, x10, #0x1
10117e03c:	61 ff ff 54	b.ne	0x10117e028
10117e040:	f5 0c 00 37	tbnz	w21, #0x0, 0x10117e1dc
10117e044:	c9 7e 40 92	and	x9, x22, #0xffffffff
10117e048:	01 e4 00 2f	movi	d1, #0000000000000000
10117e04c:	01 68 61 1e	fmaxnm	d1, d0, d1
10117e050:	13 07 00 34	cbz	w19, 0x10117e130
10117e054:	2b 05 00 d1	sub	x11, x9, #0x1
10117e058:	7f 21 00 f1	cmp	x11, #0x8
10117e05c:	22 03 00 54	b.hs	0x10117e0c0
10117e060:	2a 00 80 52	mov	w10, #0x1
10117e064:	2d 00 00 14	b	0x10117e118
10117e068:	8d f1 7d 92	and	x13, x12, #0xfffffffffffffff8
10117e06c:	ab 01 40 b2	orr	x11, x13, #0x1
10117e070:	0e a1 00 91	add	x14, x8, #0x28
10117e074:	2f 81 00 91	add	x15, x9, #0x20
10117e078:	f0 03 0d aa	mov	x16, x13
10117e07c:	e1 81 de 3c	ldur	q1, [x15, #-0x18]
10117e080:	e2 81 df 3c	ldur	q2, [x15, #-0x8]
10117e084:	e3 81 c0 3c	ldur	q3, [x15, #0x8]
10117e088:	e4 81 c1 3c	ldur	q4, [x15, #0x18]
10117e08c:	e5 19 7f ad	ldp	q5, q6, [x15, #-0x20]
10117e090:	e7 41 c2 ac	ldp	q7, q16, [x15], #0x40
10117e094:	21 d4 e5 4e	fsub.2d	v1, v1, v5
10117e098:	42 d4 e6 4e	fsub.2d	v2, v2, v6
10117e09c:	63 d4 e7 4e	fsub.2d	v3, v3, v7
10117e0a0:	84 d4 f0 4e	fsub.2d	v4, v4, v16
10117e0a4:	c1 09 3f ad	stp	q1, q2, [x14, #-0x20]
10117e0a8:	c3 11 82 ac	stp	q3, q4, [x14], #0x40
10117e0ac:	10 22 00 f1	subs	x16, x16, #0x8
10117e0b0:	61 fe ff 54	b.ne	0x10117e07c
10117e0b4:	9f 01 0d eb	cmp	x12, x13
10117e0b8:	40 fc ff 54	b.eq	0x10117e040
10117e0bc:	d7 ff ff 17	b	0x10117e018
10117e0c0:	6c f1 7d 92	and	x12, x11, #0xfffffffffffffff8
10117e0c4:	8a 01 40 b2	orr	x10, x12, #0x1
10117e0c8:	0d a1 00 91	add	x13, x8, #0x28
10117e0cc:	21 04 08 4e	dup.2d	v1, v1[0]
10117e0d0:	ee 03 0c aa	mov	x14, x12
10117e0d4:	22 1c a1 4e	mov.16b	v2, v1
10117e0d8:	23 1c a1 4e	mov.16b	v3, v1
10117e0dc:	24 1c a1 4e	mov.16b	v4, v1
10117e0e0:	a5 19 7f ad	ldp	q5, q6, [x13, #-0x20]
10117e0e4:	a7 41 c2 ac	ldp	q7, q16, [x13], #0x40
10117e0e8:	21 c4 65 4e	fmaxnm.2d	v1, v1, v5
10117e0ec:	42 c4 66 4e	fmaxnm.2d	v2, v2, v6
10117e0f0:	63 c4 67 4e	fmaxnm.2d	v3, v3, v7
10117e0f4:	84 c4 70 4e	fmaxnm.2d	v4, v4, v16
10117e0f8:	ce 21 00 f1	subs	x14, x14, #0x8
10117e0fc:	21 ff ff 54	b.ne	0x10117e0e0
10117e100:	21 c4 62 4e	fmaxnm.2d	v1, v1, v2
10117e104:	21 c4 63 4e	fmaxnm.2d	v1, v1, v3
10117e108:	21 c4 64 4e	fmaxnm.2d	v1, v1, v4
10117e10c:	21 c8 70 7e	fmaxnmp.2d	d1, v1
10117e110:	7f 01 0c eb	cmp	x11, x12
10117e114:	e0 00 00 54	b.eq	0x10117e130
10117e118:	2b 01 0a cb	sub	x11, x9, x10
10117e11c:	0a 0d 0a 8b	add	x10, x8, x10, lsl #3
10117e120:	42 85 40 fc	ldr	d2, [x10], #0x8
10117e124:	21 68 62 1e	fmaxnm	d1, d1, d2
10117e128:	6b 05 00 f1	subs	x11, x11, #0x1
10117e12c:	a1 ff ff 54	b.ne	0x10117e120
10117e130:	22 c0 60 1e	fabs	d2, d1
10117e134:	0a 96 e7 d2	mov	x10, #0x3cb0000000000000
10117e138:	43 01 67 9e	fmov	d3, x10
10117e13c:	40 20 63 1e	fcmp	d2, d3
10117e140:	ea c7 9f 1a	cset	w10, le
10117e144:	4a 01 15 2a	orr	w10, w10, w21
10117e148:	e2 17 c0 3d	ldr	q2, [sp, #0x50]
10117e14c:	8a 04 00 37	tbnz	w10, #0x0, 0x10117e1dc
10117e150:	00 18 61 1e	fdiv	d0, d0, d1
10117e154:	00 01 00 fd	str	d0, [x8]
10117e158:	33 04 00 34	cbz	w19, 0x10117e1dc
10117e15c:	2b 05 00 d1	sub	x11, x9, #0x1
10117e160:	7f 21 00 f1	cmp	x11, #0x8
10117e164:	62 00 00 54	b.hs	0x10117e170
10117e168:	2a 00 80 52	mov	w10, #0x1
10117e16c:	13 00 00 14	b	0x10117e1b8
10117e170:	6c f1 7d 92	and	x12, x11, #0xfffffffffffffff8
10117e174:	8a 01 40 b2	orr	x10, x12, #0x1
10117e178:	20 04 08 4e	dup.2d	v0, v1[0]
10117e17c:	40 fc 60 6e	fdiv.2d	v0, v2, v0
10117e180:	0d a1 00 91	add	x13, x8, #0x28
10117e184:	ee 03 0c aa	mov	x14, x12
10117e188:	a2 0d 7f ad	ldp	q2, q3, [x13, #-0x20]
10117e18c:	a4 15 40 ad	ldp	q4, q5, [x13]
10117e190:	42 dc 60 6e	fmul.2d	v2, v2, v0
10117e194:	63 dc 60 6e	fmul.2d	v3, v3, v0
10117e198:	84 dc 60 6e	fmul.2d	v4, v4, v0
10117e19c:	a5 dc 60 6e	fmul.2d	v5, v5, v0
10117e1a0:	a2 0d 3f ad	stp	q2, q3, [x13, #-0x20]
10117e1a4:	a4 15 82 ac	stp	q4, q5, [x13], #0x40
10117e1a8:	ce 21 00 f1	subs	x14, x14, #0x8
10117e1ac:	e1 fe ff 54	b.ne	0x10117e188
10117e1b0:	7f 01 0c eb	cmp	x11, x12
10117e1b4:	40 01 00 54	b.eq	0x10117e1dc
10117e1b8:	00 10 6e 1e	fmov	d0, #1.00000000
10117e1bc:	29 01 0a cb	sub	x9, x9, x10
10117e1c0:	0a 0d 0a 8b	add	x10, x8, x10, lsl #3
10117e1c4:	00 18 61 1e	fdiv	d0, d0, d1
10117e1c8:	41 01 40 fd	ldr	d1, [x10]
10117e1cc:	21 08 60 1e	fmul	d1, d1, d0
10117e1d0:	41 85 00 fc	str	d1, [x10], #0x8
10117e1d4:	29 05 00 f1	subs	x9, x9, #0x1
10117e1d8:	81 ff ff 54	b.ne	0x10117e1c8
10117e1dc:	e9 83 41 f9	ldr	x9, [sp, #0x300]
10117e1e0:	cc f2 7d d3	lsl	x12, x22, #3
10117e1e4:	20 69 6c fc	ldr	d0, [x9, x12]
10117e1e8:	00 c0 60 1e	fabs	d0, d0
10117e1ec:	eb 5f 41 f9	ldr	x11, [sp, #0x2b8]
10117e1f0:	60 69 2c fc	str	d0, [x11, x12]
10117e1f4:	00 69 6c fc	ldr	d0, [x8, x12]
10117e1f8:	00 c0 60 1e	fabs	d0, d0
10117e1fc:	ea 53 41 f9	ldr	x10, [sp, #0x2a0]
10117e200:	40 69 2c fc	str	d0, [x10, x12]
10117e204:	93 02 f8 37	tbnz	w19, #0x1f, 0x10117e254
10117e208:	6c 7e 40 92	and	x12, x19, #0xffffffff
10117e20c:	8c f1 7d d3	lsl	x12, x12, #3
10117e210:	4d 21 00 91	add	x13, x10, #0x8
10117e214:	6e 21 00 91	add	x14, x11, #0x8
10117e218:	cf 01 0c 8b	add	x15, x14, x12
10117e21c:	e0 01 40 fd	ldr	d0, [x15]
10117e220:	21 69 6c fc	ldr	d1, [x9, x12]
10117e224:	21 c0 60 1e	fabs	d1, d1
10117e228:	00 68 61 1e	fmaxnm	d0, d0, d1
10117e22c:	e0 81 1f fc	stur	d0, [x15, #-0x8]
10117e230:	af 01 0c 8b	add	x15, x13, x12
10117e234:	00 69 6c fc	ldr	d0, [x8, x12]
10117e238:	e1 01 40 fd	ldr	d1, [x15]
10117e23c:	00 c0 60 1e	fabs	d0, d0
10117e240:	20 68 60 1e	fmaxnm	d0, d1, d0
10117e244:	e0 81 1f fc	stur	d0, [x15, #-0x8]
10117e248:	8c 21 00 d1	sub	x12, x12, #0x8
10117e24c:	9f 21 00 b1	cmn	x12, #0x8
10117e250:	41 fe ff 54	b.ne	0x10117e218
10117e254:	15 03 00 37	tbnz	w21, #0x0, 0x10117e2b4
10117e258:	ee 47 41 f9	ldr	x14, [sp, #0x288]
10117e25c:	ed 3b 41 f9	ldr	x13, [sp, #0x270]
10117e260:	cc 7e 40 92	and	x12, x22, #0xffffffff
10117e264:	df 12 00 71	cmp	w22, #0x4
10117e268:	e2 17 00 54	b.hs	0x10117e564
10117e26c:	0f 00 80 d2	mov	x15, #0x0
10117e270:	e0 f1 7d d3	lsl	x0, x15, #3
10117e274:	11 20 00 91	add	x17, x0, #0x8
10117e278:	70 01 11 8b	add	x16, x11, x17
10117e27c:	ce 01 00 8b	add	x14, x14, x0
10117e280:	51 01 11 8b	add	x17, x10, x17
10117e284:	ad 01 00 8b	add	x13, x13, x0
10117e288:	8c 01 0f cb	sub	x12, x12, x15
10117e28c:	00 86 7f 6d	ldp	d0, d1, [x16, #-0x8]
10117e290:	00 38 61 1e	fsub	d0, d0, d1
10117e294:	c0 85 00 fc	str	d0, [x14], #0x8
10117e298:	20 86 7f 6d	ldp	d0, d1, [x17, #-0x8]
10117e29c:	00 38 61 1e	fsub	d0, d0, d1
10117e2a0:	a0 85 00 fc	str	d0, [x13], #0x8
10117e2a4:	10 22 00 91	add	x16, x16, #0x8
10117e2a8:	31 22 00 91	add	x17, x17, #0x8
10117e2ac:	8c 05 00 f1	subs	x12, x12, #0x1
10117e2b0:	e1 fe ff 54	b.ne	0x10117e28c
10117e2b4:	ff 37 06 f9	str	xzr, [sp, #0xc68]
10117e2b8:	ff 33 06 f9	str	xzr, [sp, #0xc60]
10117e2bc:	ff 2f 06 f9	str	xzr, [sp, #0xc58]
10117e2c0:	ff 2b 06 f9	str	xzr, [sp, #0xc50]
10117e2c4:	7f 06 00 31	cmn	w19, #0x1
10117e2c8:	8b 03 00 54	b.lt	0x10117e338
10117e2cc:	ec 03 19 aa	mov	x12, x25
10117e2d0:	cd 7e 40 92	and	x13, x22, #0xffffffff
10117e2d4:	6e 4d 36 8b	add	x14, x11, w22, uxtw #3
10117e2d8:	ef e7 03 b2	mov	x15, #0x6666666666666666
10117e2dc:	cf fc e7 f2	movk	x15, #0x3fe6, lsl #48
10117e2e0:	eb 03 19 aa	mov	x11, x25
10117e2e4:	c0 01 40 fd	ldr	d0, [x14]
10117e2e8:	e1 01 67 9e	fmov	d1, x15
10117e2ec:	00 20 61 1e	fcmp	d0, d1
10117e2f0:	cc 00 00 54	b.gt	0x10117e308
10117e2f4:	6b 05 00 51	sub	w11, w11, #0x1
10117e2f8:	ce 21 00 d1	sub	x14, x14, #0x8
10117e2fc:	7f 01 00 71	cmp	w11, #0x0
10117e300:	2c ff ff 54	b.gt	0x10117e2e4
10117e304:	0b 00 80 52	mov	w11, #0x0
10117e308:	4a 0d 0d 8b	add	x10, x10, x13, lsl #3
10117e30c:	ed e7 03 b2	mov	x13, #0x6666666666666666
10117e310:	cd fc e7 f2	movk	x13, #0x3fe6, lsl #48
10117e314:	40 01 40 fd	ldr	d0, [x10]
10117e318:	a1 01 67 9e	fmov	d1, x13
10117e31c:	00 20 61 1e	fcmp	d0, d1
10117e320:	0c 01 00 54	b.gt	0x10117e340
10117e324:	8c 05 00 51	sub	w12, w12, #0x1
10117e328:	4a 21 00 d1	sub	x10, x10, #0x8
10117e32c:	9f 01 00 71	cmp	w12, #0x0
10117e330:	2c ff ff 54	b.gt	0x10117e314
10117e334:	02 00 00 14	b	0x10117e33c
10117e338:	0b 00 80 52	mov	w11, #0x0
10117e33c:	0c 00 80 52	mov	w12, #0x0
10117e340:	7a 7e 40 93	sxtw	x26, w19
10117e344:	7f 01 13 6b	cmp	w11, w19
10117e348:	0a 03 00 54	b.ge	0x10117e3a8
10117e34c:	0a 00 80 52	mov	w10, #0x0
10117e350:	ed 47 41 f9	ldr	x13, [sp, #0x288]
10117e354:	ad cd 2b 8b	add	x13, x13, w11, sxtw #3
10117e358:	4e c3 2b cb	sub	x14, x26, w11, sxtw
10117e35c:	6f 8f 82 d2	mov	x15, #0x147b
10117e360:	cf f5 a8 f2	movk	x15, #0x47ae, lsl #16
10117e364:	2f 5c cf f2	movk	x15, #0x7ae1, lsl #32
10117e368:	8f ee e7 f2	movk	x15, #0x3f74, lsl #48
10117e36c:	f0 83 31 91	add	x16, sp, #0xc60
10117e370:	06 00 00 14	b	0x10117e388
10117e374:	4a 05 00 11	add	w10, w10, #0x1
10117e378:	6b 05 00 11	add	w11, w11, #0x1
10117e37c:	ad 21 00 91	add	x13, x13, #0x8
10117e380:	ce 05 00 f1	subs	x14, x14, #0x1
10117e384:	40 01 00 54	b.eq	0x10117e3ac
10117e388:	a0 01 40 fd	ldr	d0, [x13]
10117e38c:	e1 01 67 9e	fmov	d1, x15
10117e390:	00 20 61 1e	fcmp	d0, d1
10117e394:	2d ff ff 54	b.le	0x10117e378
10117e398:	5f 0d 00 71	cmp	w10, #0x3
10117e39c:	cc fe ff 54	b.gt	0x10117e374
10117e3a0:	0b da 2a b8	str	w11, [x16, w10, sxtw #2]
10117e3a4:	f4 ff ff 17	b	0x10117e374
10117e3a8:	0a 00 80 52	mov	w10, #0x0
10117e3ac:	9f 01 13 6b	cmp	w12, w19
10117e3b0:	0a 03 00 54	b.ge	0x10117e410
10117e3b4:	0b 00 80 52	mov	w11, #0x0
10117e3b8:	ed 3b 41 f9	ldr	x13, [sp, #0x270]
10117e3bc:	ad cd 2c 8b	add	x13, x13, w12, sxtw #3
10117e3c0:	4e c3 2c cb	sub	x14, x26, w12, sxtw
10117e3c4:	6f 8f 82 d2	mov	x15, #0x147b
10117e3c8:	cf f5 a8 f2	movk	x15, #0x47ae, lsl #16
10117e3cc:	2f 5c cf f2	movk	x15, #0x7ae1, lsl #32
10117e3d0:	8f ee e7 f2	movk	x15, #0x3f74, lsl #48
10117e3d4:	f0 43 31 91	add	x16, sp, #0xc50
10117e3d8:	06 00 00 14	b	0x10117e3f0
10117e3dc:	6b 05 00 11	add	w11, w11, #0x1
10117e3e0:	8c 05 00 11	add	w12, w12, #0x1
10117e3e4:	ad 21 00 91	add	x13, x13, #0x8
10117e3e8:	ce 05 00 f1	subs	x14, x14, #0x1
10117e3ec:	40 01 00 54	b.eq	0x10117e414
10117e3f0:	a0 01 40 fd	ldr	d0, [x13]
10117e3f4:	e1 01 67 9e	fmov	d1, x15
10117e3f8:	00 20 61 1e	fcmp	d0, d1
10117e3fc:	2d ff ff 54	b.le	0x10117e3e0
10117e400:	7f 0d 00 71	cmp	w11, #0x3
10117e404:	cc fe ff 54	b.gt	0x10117e3dc
10117e408:	0c da 2b b8	str	w12, [x16, w11, sxtw #2]
10117e40c:	f4 ff ff 17	b	0x10117e3dc
10117e410:	0b 00 80 52	mov	w11, #0x0
10117e414:	5f 11 00 71	cmp	w10, #0x4
10117e418:	6d 00 00 54	b.le	0x10117e424
10117e41c:	34 00 80 52	mov	w20, #0x1
10117e420:	10 00 00 14	b	0x10117e460
10117e424:	4a 05 00 51	sub	w10, w10, #0x1
10117e428:	5f 01 00 71	cmp	w10, #0x0
10117e42c:	4d c1 9f 1a	csel	w13, w10, wzr, gt
10117e430:	ea 83 31 91	add	x10, sp, #0xc60
10117e434:	4a 01 7e b2	orr	x10, x10, #0x4
10117e438:	ec 03 0d aa	mov	x12, x13
10117e43c:	ed 00 00 b4	cbz	x13, 0x10117e458
10117e440:	4e b5 7f 29	ldp	w14, w13, [x10, #-0x4]
10117e444:	ae 01 0e 4b	sub	w14, w13, w14
10117e448:	8d 05 00 d1	sub	x13, x12, #0x1
10117e44c:	4a 11 00 91	add	x10, x10, #0x4
10117e450:	df 05 00 71	cmp	w14, #0x1
10117e454:	20 ff ff 54	b.eq	0x10117e438
10117e458:	9f 01 00 f1	cmp	x12, #0x0
10117e45c:	f4 07 9f 1a	cset	w20, ne
10117e460:	7f 11 00 71	cmp	w11, #0x4
10117e464:	6d 00 00 54	b.le	0x10117e470
10117e468:	37 00 80 52	mov	w23, #0x1
10117e46c:	10 00 00 14	b	0x10117e4ac
10117e470:	6a 05 00 51	sub	w10, w11, #0x1
10117e474:	5f 01 00 71	cmp	w10, #0x0
10117e478:	4c c1 9f 1a	csel	w12, w10, wzr, gt
10117e47c:	ea 43 31 91	add	x10, sp, #0xc50
10117e480:	4a 01 7e b2	orr	x10, x10, #0x4
10117e484:	eb 03 0c aa	mov	x11, x12
10117e488:	ec 00 00 b4	cbz	x12, 0x10117e4a4
10117e48c:	4d b1 7f 29	ldp	w13, w12, [x10, #-0x4]
10117e490:	8d 01 0d 4b	sub	w13, w12, w13
10117e494:	6c 05 00 d1	sub	x12, x11, #0x1
10117e498:	4a 11 00 91	add	x10, x10, #0x4
10117e49c:	bf 05 00 71	cmp	w13, #0x1
10117e4a0:	20 ff ff 54	b.eq	0x10117e484
10117e4a4:	7f 01 00 f1	cmp	x11, #0x0
10117e4a8:	f7 07 9f 1a	cset	w23, ne
10117e4ac:	0a 06 80 52	mov	w10, #0x30
10117e4b0:	7f c2 00 71	cmp	w19, #0x30
10117e4b4:	6a b2 8a 1a	csel	w10, w19, w10, lt
10117e4b8:	00 10 6c 1e	fmov	d0, #0.50000000
10117e4bc:	20 21 60 1e	fcmp	d9, d0
10117e4c0:	cb 02 00 54	b.lt	0x10117e518
10117e4c4:	95 01 00 37	tbnz	w21, #0x0, 0x10117e4f4
10117e4c8:	0b 00 80 d2	mov	x11, #0x0
10117e4cc:	cc 7e 40 92	and	x12, x22, #0xffffffff
10117e4d0:	ed e7 03 b2	mov	x13, #0x6666666666666666
10117e4d4:	cd fa e7 f2	movk	x13, #0x3fd6, lsl #48
10117e4d8:	20 79 6b fc	ldr	d0, [x9, x11, lsl #3]
10117e4dc:	a1 01 67 9e	fmov	d1, x13
10117e4e0:	00 20 61 1e	fcmp	d0, d1
10117e4e4:	ac b4 00 54	b.gt	0x10117fb78
10117e4e8:	6b 05 00 91	add	x11, x11, #0x1
10117e4ec:	9f 01 0b eb	cmp	x12, x11
10117e4f0:	41 ff ff 54	b.ne	0x10117e4d8
10117e4f4:	ff 5b 01 b9	str	wzr, [sp, #0x158]
10117e4f8:	4b 05 00 11	add	w11, w10, #0x1
10117e4fc:	60 01 62 1e	scvtf	d0, w11
10117e500:	ca 09 f8 37	tbnz	w10, #0x1f, 0x10117e638
10117e504:	7f 21 00 71	cmp	w11, #0x8
10117e508:	62 0c 00 54	b.hs	0x10117e694
10117e50c:	0c 00 80 d2	mov	x12, #0x0
10117e510:	01 e4 00 2f	movi	d1, #0000000000000000
10117e514:	79 00 00 14	b	0x10117e6f8
10117e518:	7f 06 00 71	cmp	w19, #0x1
10117e51c:	0b 02 00 54	b.lt	0x10117e55c
10117e520:	0b 00 80 d2	mov	x11, #0x0
10117e524:	cd 7e 40 92	and	x13, x22, #0xffffffff
10117e528:	2c 21 00 91	add	x12, x9, #0x8
10117e52c:	ad 05 00 d1	sub	x13, x13, #0x1
10117e530:	ee e7 03 b2	mov	x14, #0x6666666666666666
10117e534:	ce fa e7 f2	movk	x14, #0x3fd6, lsl #48
10117e538:	2f 00 c0 d2	mov	x15, #0x100000000
10117e53c:	80 01 40 fd	ldr	d0, [x12]
10117e540:	c1 01 67 9e	fmov	d1, x14
10117e544:	00 20 61 1e	fcmp	d0, d1
10117e548:	ec 07 00 54	b.gt	0x10117e644
10117e54c:	6b 01 0f 8b	add	x11, x11, x15
10117e550:	8c 21 00 91	add	x12, x12, #0x8
10117e554:	ad 05 00 f1	subs	x13, x13, #0x1
10117e558:	21 ff ff 54	b.ne	0x10117e53c
10117e55c:	ff 5b 01 b9	str	wzr, [sp, #0x158]
10117e560:	40 00 00 14	b	0x10117e660
10117e564:	0f 00 80 d2	mov	x15, #0x0
10117e568:	90 f1 7d d3	lsl	x16, x12, #3
10117e56c:	c2 01 10 8b	add	x2, x14, x16
10117e570:	a3 01 10 8b	add	x3, x13, x16
10117e574:	11 22 00 91	add	x17, x16, #0x8
10117e578:	60 01 11 8b	add	x0, x11, x17
10117e57c:	df 01 00 eb	cmp	x14, x0
10117e580:	62 31 42 fa	ccmp	x11, x2, #0x2, lo
10117e584:	f0 27 9f 1a	cset	w16, lo
10117e588:	41 01 11 8b	add	x1, x10, x17
10117e58c:	df 01 01 eb	cmp	x14, x1
10117e590:	42 31 42 fa	ccmp	x10, x2, #0x2, lo
10117e594:	f1 27 9f 1a	cset	w17, lo
10117e598:	bf 01 00 eb	cmp	x13, x0
10117e59c:	62 31 43 fa	ccmp	x11, x3, #0x2, lo
10117e5a0:	e0 27 9f 1a	cset	w0, lo
10117e5a4:	bf 01 01 eb	cmp	x13, x1
10117e5a8:	42 31 43 fa	ccmp	x10, x3, #0x2, lo
10117e5ac:	e1 27 9f 1a	cset	w1, lo
10117e5b0:	bf 01 02 eb	cmp	x13, x2
10117e5b4:	c2 31 43 fa	ccmp	x14, x3, #0x2, lo
10117e5b8:	c3 e5 ff 54	b.lo	0x10117e270
10117e5bc:	b0 e5 07 37	tbnz	w16, #0x0, 0x10117e270
10117e5c0:	91 e5 07 37	tbnz	w17, #0x0, 0x10117e270
10117e5c4:	60 e5 07 37	tbnz	w0, #0x0, 0x10117e270
10117e5c8:	41 e5 07 37	tbnz	w1, #0x0, 0x10117e270
10117e5cc:	8f 75 7e 92	and	x15, x12, #0xfffffffc
10117e5d0:	b0 41 00 91	add	x16, x13, #0x10
10117e5d4:	d1 41 00 91	add	x17, x14, #0x10
10117e5d8:	40 41 00 91	add	x0, x10, #0x10
10117e5dc:	61 41 00 91	add	x1, x11, #0x10
10117e5e0:	e2 03 0f aa	mov	x2, x15
10117e5e4:	20 84 7f ad	ldp	q0, q1, [x1, #-0x10]
10117e5e8:	22 80 df 3c	ldur	q2, [x1, #-0x8]
10117e5ec:	23 80 c0 3c	ldur	q3, [x1, #0x8]
10117e5f0:	00 d4 e2 4e	fsub.2d	v0, v0, v2
10117e5f4:	21 d4 e3 4e	fsub.2d	v1, v1, v3
10117e5f8:	20 86 3f ad	stp	q0, q1, [x17, #-0x10]
10117e5fc:	00 84 7f ad	ldp	q0, q1, [x0, #-0x10]
10117e600:	02 80 df 3c	ldur	q2, [x0, #-0x8]
10117e604:	03 80 c0 3c	ldur	q3, [x0, #0x8]
10117e608:	00 d4 e2 4e	fsub.2d	v0, v0, v2
10117e60c:	21 d4 e3 4e	fsub.2d	v1, v1, v3
10117e610:	00 86 3f ad	stp	q0, q1, [x16, #-0x10]
10117e614:	10 82 00 91	add	x16, x16, #0x20
10117e618:	31 82 00 91	add	x17, x17, #0x20
10117e61c:	00 80 00 91	add	x0, x0, #0x20
10117e620:	21 80 00 91	add	x1, x1, #0x20
10117e624:	42 10 00 f1	subs	x2, x2, #0x4
10117e628:	e1 fd ff 54	b.ne	0x10117e5e4
10117e62c:	ff 01 0c eb	cmp	x15, x12
10117e630:	01 e2 ff 54	b.ne	0x10117e270
10117e634:	20 ff ff 17	b	0x10117e2b4
10117e638:	01 e4 00 2f	movi	d1, #0000000000000000
10117e63c:	02 e4 00 2f	movi	d2, #0000000000000000
10117e640:	88 00 00 14	b	0x10117e860
10117e644:	6b fd 60 93	asr	x11, x11, #32
10117e648:	ec b3 40 f9	ldr	x12, [sp, #0x160]
10117e64c:	8c 01 40 f9	ldr	x12, [x12]
10117e650:	0d 03 80 52	mov	w13, #0x18
10117e654:	6b 31 0d 9b	madd	x11, x11, x13, x12
10117e658:	6b 0d 40 b9	ldr	w11, [x11, #0xc]
10117e65c:	eb 5b 01 b9	str	w11, [sp, #0x158]
10117e660:	40 01 62 1e	scvtf	d0, w10
10117e664:	5f 01 00 71	cmp	w10, #0x0
10117e668:	0d 01 00 54	b.le	0x10117e688
10117e66c:	4b 05 00 11	add	w11, w10, #0x1
10117e670:	6c 05 00 d1	sub	x12, x11, #0x1
10117e674:	9f 21 00 f1	cmp	x12, #0x8
10117e678:	a2 05 00 54	b.hs	0x10117e72c
10117e67c:	01 e4 00 2f	movi	d1, #0000000000000000
10117e680:	2d 00 80 52	mov	w13, #0x1
10117e684:	44 00 00 14	b	0x10117e794
10117e688:	01 e4 00 2f	movi	d1, #0000000000000000
10117e68c:	02 e4 00 2f	movi	d2, #0000000000000000
10117e690:	a9 00 00 14	b	0x10117e934
10117e694:	6c 71 7d 92	and	x12, x11, #0xfffffff8
10117e698:	0d 81 00 91	add	x13, x8, #0x20
10117e69c:	01 e4 00 6f	movi.2d	v1, #0000000000000000
10117e6a0:	ee 03 0c aa	mov	x14, x12
10117e6a4:	02 e4 00 6f	movi.2d	v2, #0000000000000000
10117e6a8:	03 e4 00 6f	movi.2d	v3, #0000000000000000
10117e6ac:	04 e4 00 6f	movi.2d	v4, #0000000000000000
10117e6b0:	a5 19 7f ad	ldp	q5, q6, [x13, #-0x20]
10117e6b4:	a7 41 c2 ac	ldp	q7, q16, [x13], #0x40
10117e6b8:	a5 f8 e0 4e	fabs.2d	v5, v5
10117e6bc:	c6 f8 e0 4e	fabs.2d	v6, v6
10117e6c0:	e7 f8 e0 4e	fabs.2d	v7, v7
10117e6c4:	10 fa e0 4e	fabs.2d	v16, v16
10117e6c8:	a1 d4 61 4e	fadd.2d	v1, v5, v1
10117e6cc:	c2 d4 62 4e	fadd.2d	v2, v6, v2
10117e6d0:	e3 d4 63 4e	fadd.2d	v3, v7, v3
10117e6d4:	04 d6 64 4e	fadd.2d	v4, v16, v4
10117e6d8:	ce 21 00 f1	subs	x14, x14, #0x8
10117e6dc:	a1 fe ff 54	b.ne	0x10117e6b0
10117e6e0:	41 d4 61 4e	fadd.2d	v1, v2, v1
10117e6e4:	61 d4 61 4e	fadd.2d	v1, v3, v1
10117e6e8:	81 d4 61 4e	fadd.2d	v1, v4, v1
10117e6ec:	21 d8 70 7e	faddp.2d	d1, v1
10117e6f0:	9f 01 0b eb	cmp	x12, x11
10117e6f4:	00 01 00 54	b.eq	0x10117e714
10117e6f8:	0d 0d 0c 8b	add	x13, x8, x12, lsl #3
10117e6fc:	6c 01 0c cb	sub	x12, x11, x12
10117e700:	a2 85 40 fc	ldr	d2, [x13], #0x8
10117e704:	42 c0 60 1e	fabs	d2, d2
10117e708:	41 28 61 1e	fadd	d1, d2, d1
10117e70c:	8c 05 00 f1	subs	x12, x12, #0x1
10117e710:	81 ff ff 54	b.ne	0x10117e700
10117e714:	21 18 60 1e	fdiv	d1, d1, d0
10117e718:	7f 21 00 71	cmp	w11, #0x8
10117e71c:	62 05 00 54	b.hs	0x10117e7c8
10117e720:	0c 00 80 d2	mov	x12, #0x0
10117e724:	02 e4 00 2f	movi	d2, #0000000000000000
10117e728:	46 00 00 14	b	0x10117e840
10117e72c:	8e f1 7d 92	and	x14, x12, #0xfffffffffffffff8
10117e730:	cd 01 40 b2	orr	x13, x14, #0x1
10117e734:	0f a1 00 91	add	x15, x8, #0x28
10117e738:	01 e4 00 6f	movi.2d	v1, #0000000000000000
10117e73c:	f0 03 0e aa	mov	x16, x14
10117e740:	02 e4 00 6f	movi.2d	v2, #0000000000000000
10117e744:	03 e4 00 6f	movi.2d	v3, #0000000000000000
10117e748:	04 e4 00 6f	movi.2d	v4, #0000000000000000
10117e74c:	e5 19 7f ad	ldp	q5, q6, [x15, #-0x20]
10117e750:	e7 41 c2 ac	ldp	q7, q16, [x15], #0x40
10117e754:	a5 f8 e0 4e	fabs.2d	v5, v5
10117e758:	c6 f8 e0 4e	fabs.2d	v6, v6
10117e75c:	e7 f8 e0 4e	fabs.2d	v7, v7
10117e760:	10 fa e0 4e	fabs.2d	v16, v16
10117e764:	a1 d4 61 4e	fadd.2d	v1, v5, v1
10117e768:	c2 d4 62 4e	fadd.2d	v2, v6, v2
10117e76c:	e3 d4 63 4e	fadd.2d	v3, v7, v3
10117e770:	04 d6 64 4e	fadd.2d	v4, v16, v4
10117e774:	10 22 00 f1	subs	x16, x16, #0x8
10117e778:	a1 fe ff 54	b.ne	0x10117e74c
10117e77c:	41 d4 61 4e	fadd.2d	v1, v2, v1
10117e780:	61 d4 61 4e	fadd.2d	v1, v3, v1
10117e784:	81 d4 61 4e	fadd.2d	v1, v4, v1
10117e788:	21 d8 70 7e	faddp.2d	d1, v1
10117e78c:	9f 01 0e eb	cmp	x12, x14
10117e790:	00 01 00 54	b.eq	0x10117e7b0
10117e794:	0e 0d 0d 8b	add	x14, x8, x13, lsl #3
10117e798:	6d 01 0d cb	sub	x13, x11, x13
10117e79c:	c2 85 40 fc	ldr	d2, [x14], #0x8
10117e7a0:	42 c0 60 1e	fabs	d2, d2
10117e7a4:	41 28 61 1e	fadd	d1, d2, d1
10117e7a8:	ad 05 00 f1	subs	x13, x13, #0x1
10117e7ac:	81 ff ff 54	b.ne	0x10117e79c
10117e7b0:	21 18 60 1e	fdiv	d1, d1, d0
10117e7b4:	9f 21 00 f1	cmp	x12, #0x8
10117e7b8:	02 07 00 54	b.hs	0x10117e898
10117e7bc:	02 e4 00 2f	movi	d2, #0000000000000000
10117e7c0:	2d 00 80 52	mov	w13, #0x1
10117e7c4:	54 00 00 14	b	0x10117e914
10117e7c8:	6c 71 7d 92	and	x12, x11, #0xfffffff8
10117e7cc:	22 04 08 4e	dup.2d	v2, v1[0]
10117e7d0:	0d 81 00 91	add	x13, x8, #0x20
10117e7d4:	03 e4 00 6f	movi.2d	v3, #0000000000000000
10117e7d8:	ee 03 0c aa	mov	x14, x12
10117e7dc:	04 e4 00 6f	movi.2d	v4, #0000000000000000
10117e7e0:	05 e4 00 6f	movi.2d	v5, #0000000000000000
10117e7e4:	06 e4 00 6f	movi.2d	v6, #0000000000000000
10117e7e8:	a7 41 7f ad	ldp	q7, q16, [x13, #-0x20]
10117e7ec:	b1 49 c2 ac	ldp	q17, q18, [x13], #0x40
10117e7f0:	e7 f8 e0 4e	fabs.2d	v7, v7
10117e7f4:	10 fa e0 4e	fabs.2d	v16, v16
10117e7f8:	31 fa e0 4e	fabs.2d	v17, v17
10117e7fc:	52 fa e0 4e	fabs.2d	v18, v18
10117e800:	e7 d4 e2 4e	fsub.2d	v7, v7, v2
10117e804:	10 d6 e2 4e	fsub.2d	v16, v16, v2
10117e808:	31 d6 e2 4e	fsub.2d	v17, v17, v2
10117e80c:	52 d6 e2 4e	fsub.2d	v18, v18, v2
10117e810:	e3 cc 67 4e	fmla.2d	v3, v7, v7
10117e814:	04 ce 70 4e	fmla.2d	v4, v16, v16
10117e818:	25 ce 71 4e	fmla.2d	v5, v17, v17
10117e81c:	46 ce 72 4e	fmla.2d	v6, v18, v18
10117e820:	ce 21 00 f1	subs	x14, x14, #0x8
10117e824:	21 fe ff 54	b.ne	0x10117e7e8
10117e828:	82 d4 63 4e	fadd.2d	v2, v4, v3
10117e82c:	a2 d4 62 4e	fadd.2d	v2, v5, v2
10117e830:	c2 d4 62 4e	fadd.2d	v2, v6, v2
10117e834:	42 d8 70 7e	faddp.2d	d2, v2
10117e838:	9f 01 0b eb	cmp	x12, x11
10117e83c:	20 01 00 54	b.eq	0x10117e860
10117e840:	0d 0d 0c 8b	add	x13, x8, x12, lsl #3
10117e844:	6b 01 0c cb	sub	x11, x11, x12
10117e848:	a3 85 40 fc	ldr	d3, [x13], #0x8
10117e84c:	63 c0 60 1e	fabs	d3, d3
10117e850:	63 38 61 1e	fsub	d3, d3, d1
10117e854:	62 08 43 1f	fmadd	d2, d3, d3, d2
10117e858:	6b 05 00 f1	subs	x11, x11, #0x1
10117e85c:	61 ff ff 54	b.ne	0x10117e848
10117e860:	f5 08 00 37	tbnz	w21, #0x0, 0x10117e97c
10117e864:	0b 00 80 d2	mov	x11, #0x0
10117e868:	40 18 60 1e	fdiv	d0, d2, d0
10117e86c:	00 c0 61 1e	fsqrt	d0, d0
10117e870:	02 10 6f 1e	fmov	d2, #1.50000000
10117e874:	00 04 42 1f	fmadd	d0, d0, d2, d1
10117e878:	cc 7e 40 92	and	x12, x22, #0xffffffff
10117e87c:	01 79 6b fc	ldr	d1, [x8, x11, lsl #3]
10117e880:	20 20 60 1e	fcmp	d1, d0
10117e884:	cc 98 00 54	b.gt	0x10117fb9c
10117e888:	6b 05 00 91	add	x11, x11, #0x1
10117e88c:	9f 01 0b eb	cmp	x12, x11
10117e890:	61 ff ff 54	b.ne	0x10117e87c
10117e894:	3a 00 00 14	b	0x10117e97c
10117e898:	8e f1 7d 92	and	x14, x12, #0xfffffffffffffff8
10117e89c:	cd 01 40 b2	orr	x13, x14, #0x1
10117e8a0:	22 04 08 4e	dup.2d	v2, v1[0]
10117e8a4:	0f a1 00 91	add	x15, x8, #0x28
10117e8a8:	03 e4 00 6f	movi.2d	v3, #0000000000000000
10117e8ac:	f0 03 0e aa	mov	x16, x14
10117e8b0:	04 e4 00 6f	movi.2d	v4, #0000000000000000
10117e8b4:	05 e4 00 6f	movi.2d	v5, #0000000000000000
10117e8b8:	06 e4 00 6f	movi.2d	v6, #0000000000000000
10117e8bc:	e7 41 7f ad	ldp	q7, q16, [x15, #-0x20]
10117e8c0:	f1 49 c2 ac	ldp	q17, q18, [x15], #0x40
10117e8c4:	e7 f8 e0 4e	fabs.2d	v7, v7
10117e8c8:	10 fa e0 4e	fabs.2d	v16, v16
10117e8cc:	31 fa e0 4e	fabs.2d	v17, v17
10117e8d0:	52 fa e0 4e	fabs.2d	v18, v18
10117e8d4:	e7 d4 e2 4e	fsub.2d	v7, v7, v2
10117e8d8:	10 d6 e2 4e	fsub.2d	v16, v16, v2
10117e8dc:	31 d6 e2 4e	fsub.2d	v17, v17, v2
10117e8e0:	52 d6 e2 4e	fsub.2d	v18, v18, v2
10117e8e4:	e3 cc 67 4e	fmla.2d	v3, v7, v7
10117e8e8:	04 ce 70 4e	fmla.2d	v4, v16, v16
10117e8ec:	25 ce 71 4e	fmla.2d	v5, v17, v17
10117e8f0:	46 ce 72 4e	fmla.2d	v6, v18, v18
10117e8f4:	10 22 00 f1	subs	x16, x16, #0x8
10117e8f8:	21 fe ff 54	b.ne	0x10117e8bc
10117e8fc:	82 d4 63 4e	fadd.2d	v2, v4, v3
10117e900:	a2 d4 62 4e	fadd.2d	v2, v5, v2
10117e904:	c2 d4 62 4e	fadd.2d	v2, v6, v2
10117e908:	42 d8 70 7e	faddp.2d	d2, v2
10117e90c:	9f 01 0e eb	cmp	x12, x14
10117e910:	20 01 00 54	b.eq	0x10117e934
10117e914:	0c 0d 0d 8b	add	x12, x8, x13, lsl #3
10117e918:	6b 01 0d cb	sub	x11, x11, x13
10117e91c:	83 85 40 fc	ldr	d3, [x12], #0x8
10117e920:	63 c0 60 1e	fabs	d3, d3
10117e924:	63 38 61 1e	fsub	d3, d3, d1
10117e928:	62 08 43 1f	fmadd	d2, d3, d3, d2
10117e92c:	6b 05 00 f1	subs	x11, x11, #0x1
10117e930:	61 ff ff 54	b.ne	0x10117e91c
10117e934:	7f 06 00 71	cmp	w19, #0x1
10117e938:	2b 02 00 54	b.lt	0x10117e97c
10117e93c:	0b 00 80 d2	mov	x11, #0x0
10117e940:	40 18 60 1e	fdiv	d0, d2, d0
10117e944:	00 c0 61 1e	fsqrt	d0, d0
10117e948:	02 10 6f 1e	fmov	d2, #1.50000000
10117e94c:	00 04 42 1f	fmadd	d0, d0, d2, d1
10117e950:	cd 7e 40 92	and	x13, x22, #0xffffffff
10117e954:	0c 21 00 91	add	x12, x8, #0x8
10117e958:	ad 05 00 d1	sub	x13, x13, #0x1
10117e95c:	2e 00 c0 d2	mov	x14, #0x100000000
10117e960:	81 01 40 fd	ldr	d1, [x12]
10117e964:	20 20 60 1e	fcmp	d1, d0
10117e968:	4c 85 00 54	b.gt	0x10117fa10
10117e96c:	6b 01 0e 8b	add	x11, x11, x14
10117e970:	8c 21 00 91	add	x12, x12, #0x8
10117e974:	ad 05 00 f1	subs	x13, x13, #0x1
10117e978:	41 ff ff 54	b.ne	0x10117e960
10117e97c:	18 00 80 52	mov	w24, #0x0
10117e980:	cb 02 0a 4b	sub	w11, w22, w10
10117e984:	7f 01 13 6b	cmp	w11, w19
10117e988:	ad 00 00 54	b.le	0x10117e99c
10117e98c:	40 01 62 1e	scvtf	d0, w10
10117e990:	01 e4 00 2f	movi	d1, #0000000000000000
10117e994:	02 e4 00 2f	movi	d2, #0000000000000000
10117e998:	5f 00 00 14	b	0x10117eb14
10117e99c:	4c 07 00 91	add	x12, x26, #0x1
10117e9a0:	6d 7d 40 93	sxtw	x13, w11
10117e9a4:	8e 01 0d cb	sub	x14, x12, x13
10117e9a8:	01 e4 00 2f	movi	d1, #0000000000000000
10117e9ac:	ef 03 0c aa	mov	x15, x12
10117e9b0:	df 21 00 f1	cmp	x14, #0x8
10117e9b4:	23 04 00 54	b.lo	0x10117ea38
10117e9b8:	d0 f1 7d 92	and	x16, x14, #0xfffffffffffffff8
10117e9bc:	8f 01 10 cb	sub	x15, x12, x16
10117e9c0:	31 0d 1a 8b	add	x17, x9, x26, lsl #3
10117e9c4:	31 42 00 d1	sub	x17, x17, #0x10
10117e9c8:	00 e4 00 6f	movi.2d	v0, #0000000000000000
10117e9cc:	e0 03 10 aa	mov	x0, x16
10117e9d0:	01 e4 00 6f	movi.2d	v1, #0000000000000000
10117e9d4:	02 e4 00 6f	movi.2d	v2, #0000000000000000
10117e9d8:	03 e4 00 6f	movi.2d	v3, #0000000000000000
10117e9dc:	25 12 40 ad	ldp	q5, q4, [x17]
10117e9e0:	84 40 04 6e	ext.16b	v4, v4, v4, #0x8
10117e9e4:	a5 40 05 6e	ext.16b	v5, v5, v5, #0x8
10117e9e8:	27 1a 7f ad	ldp	q7, q6, [x17, #-0x20]
10117e9ec:	c6 40 06 6e	ext.16b	v6, v6, v6, #0x8
10117e9f0:	e7 40 07 6e	ext.16b	v7, v7, v7, #0x8
10117e9f4:	84 f8 e0 4e	fabs.2d	v4, v4
10117e9f8:	a5 f8 e0 4e	fabs.2d	v5, v5
10117e9fc:	c6 f8 e0 4e	fabs.2d	v6, v6
10117ea00:	e7 f8 e0 4e	fabs.2d	v7, v7
10117ea04:	80 d4 60 4e	fadd.2d	v0, v4, v0
10117ea08:	a1 d4 61 4e	fadd.2d	v1, v5, v1
10117ea0c:	c2 d4 62 4e	fadd.2d	v2, v6, v2
10117ea10:	e3 d4 63 4e	fadd.2d	v3, v7, v3
10117ea14:	31 02 01 d1	sub	x17, x17, #0x40
10117ea18:	00 20 00 d1	sub	x0, x0, #0x8
10117ea1c:	00 fe ff b5	cbnz	x0, 0x10117e9dc
10117ea20:	20 d4 60 4e	fadd.2d	v0, v1, v0
10117ea24:	40 d4 60 4e	fadd.2d	v0, v2, v0
10117ea28:	60 d4 60 4e	fadd.2d	v0, v3, v0
10117ea2c:	01 d8 70 7e	faddp.2d	d1, v0
10117ea30:	df 01 10 eb	cmp	x14, x16
10117ea34:	e0 00 00 54	b.eq	0x10117ea50
10117ea38:	20 79 6f fc	ldr	d0, [x9, x15, lsl #3]
10117ea3c:	00 c0 60 1e	fabs	d0, d0
10117ea40:	01 28 61 1e	fadd	d1, d0, d1
10117ea44:	ef 05 00 d1	sub	x15, x15, #0x1
10117ea48:	ff 01 0d eb	cmp	x15, x13
10117ea4c:	6c ff ff 54	b.gt	0x10117ea38
10117ea50:	40 01 62 1e	scvtf	d0, w10
10117ea54:	21 18 60 1e	fdiv	d1, d1, d0
10117ea58:	02 e4 00 2f	movi	d2, #0000000000000000
10117ea5c:	df 21 00 f1	cmp	x14, #0x8
10117ea60:	c3 04 00 54	b.lo	0x10117eaf8
10117ea64:	ca f1 7d 92	and	x10, x14, #0xfffffffffffffff8
10117ea68:	8c 01 0a cb	sub	x12, x12, x10
10117ea6c:	22 04 08 4e	dup.2d	v2, v1[0]
10117ea70:	2f 0d 1a 8b	add	x15, x9, x26, lsl #3
10117ea74:	ef 41 00 d1	sub	x15, x15, #0x10
10117ea78:	03 e4 00 6f	movi.2d	v3, #0000000000000000
10117ea7c:	f0 03 0a aa	mov	x16, x10
10117ea80:	04 e4 00 6f	movi.2d	v4, #0000000000000000
10117ea84:	05 e4 00 6f	movi.2d	v5, #0000000000000000
10117ea88:	06 e4 00 6f	movi.2d	v6, #0000000000000000
10117ea8c:	f0 1d 40 ad	ldp	q16, q7, [x15]
10117ea90:	e7 40 07 6e	ext.16b	v7, v7, v7, #0x8
10117ea94:	10 42 10 6e	ext.16b	v16, v16, v16, #0x8
10117ea98:	f2 45 7f ad	ldp	q18, q17, [x15, #-0x20]
10117ea9c:	31 42 11 6e	ext.16b	v17, v17, v17, #0x8
10117eaa0:	52 42 12 6e	ext.16b	v18, v18, v18, #0x8
10117eaa4:	e7 f8 e0 4e	fabs.2d	v7, v7
10117eaa8:	10 fa e0 4e	fabs.2d	v16, v16
10117eaac:	31 fa e0 4e	fabs.2d	v17, v17
10117eab0:	52 fa e0 4e	fabs.2d	v18, v18
10117eab4:	e7 d4 e2 4e	fsub.2d	v7, v7, v2
10117eab8:	10 d6 e2 4e	fsub.2d	v16, v16, v2
10117eabc:	31 d6 e2 4e	fsub.2d	v17, v17, v2
10117eac0:	52 d6 e2 4e	fsub.2d	v18, v18, v2
10117eac4:	e3 cc 67 4e	fmla.2d	v3, v7, v7
10117eac8:	04 ce 70 4e	fmla.2d	v4, v16, v16
10117eacc:	25 ce 71 4e	fmla.2d	v5, v17, v17
10117ead0:	46 ce 72 4e	fmla.2d	v6, v18, v18
10117ead4:	ef 01 01 d1	sub	x15, x15, #0x40
10117ead8:	10 22 00 d1	sub	x16, x16, #0x8
10117eadc:	90 fd ff b5	cbnz	x16, 0x10117ea8c
10117eae0:	82 d4 63 4e	fadd.2d	v2, v4, v3
10117eae4:	a2 d4 62 4e	fadd.2d	v2, v5, v2
10117eae8:	c2 d4 62 4e	fadd.2d	v2, v6, v2
10117eaec:	42 d8 70 7e	faddp.2d	d2, v2
10117eaf0:	df 01 0a eb	cmp	x14, x10
10117eaf4:	00 01 00 54	b.eq	0x10117eb14
10117eaf8:	23 79 6c fc	ldr	d3, [x9, x12, lsl #3]
10117eafc:	63 c0 60 1e	fabs	d3, d3
10117eb00:	63 38 61 1e	fsub	d3, d3, d1
10117eb04:	62 08 43 1f	fmadd	d2, d3, d3, d2
10117eb08:	8c 05 00 d1	sub	x12, x12, #0x1
10117eb0c:	9f 01 0d eb	cmp	x12, x13
10117eb10:	4c ff ff 54	b.gt	0x10117eaf8
10117eb14:	7f 06 00 71	cmp	w19, #0x1
10117eb18:	0b 02 00 54	b.lt	0x10117eb58
10117eb1c:	42 18 60 1e	fdiv	d2, d2, d0
10117eb20:	42 c0 61 1e	fsqrt	d2, d2
10117eb24:	03 10 7c 1e	fmov	d3, #-0.50000000
10117eb28:	41 84 63 1f	fnmsub	d1, d2, d3, d1
10117eb2c:	cc 7e 40 92	and	x12, x22, #0xffffffff
10117eb30:	2a 00 80 12	mov	w10, #-0x2
10117eb34:	8a 01 0a 8b	add	x10, x12, x10
10117eb38:	22 79 6c fc	ldr	d2, [x9, x12, lsl #3]
10117eb3c:	40 20 61 1e	fcmp	d2, d1
10117eb40:	4b 35 00 54	b.lt	0x10117f1e8
10117eb44:	8d 05 00 d1	sub	x13, x12, #0x1
10117eb48:	4a 05 00 d1	sub	x10, x10, #0x1
10117eb4c:	9f 09 00 f1	cmp	x12, #0x2
10117eb50:	ec 03 0d aa	mov	x12, x13
10117eb54:	28 ff ff 54	b.hi	0x10117eb38
10117eb58:	ff 3b 01 b9	str	wzr, [sp, #0x138]
10117eb5c:	01 e4 00 2f	movi	d1, #0000000000000000
10117eb60:	02 e4 00 2f	movi	d2, #0000000000000000
10117eb64:	7f 01 13 6b	cmp	w11, w19
10117eb68:	cc 0b 00 54	b.gt	0x10117ece0
10117eb6c:	49 07 00 91	add	x9, x26, #0x1
10117eb70:	6a 7d 40 93	sxtw	x10, w11
10117eb74:	2b 01 0a cb	sub	x11, x9, x10
10117eb78:	01 e4 00 2f	movi	d1, #0000000000000000
10117eb7c:	ec 03 09 aa	mov	x12, x9
10117eb80:	7f 21 00 f1	cmp	x11, #0x8
10117eb84:	23 04 00 54	b.lo	0x10117ec08
10117eb88:	6d f1 7d 92	and	x13, x11, #0xfffffffffffffff8
10117eb8c:	2c 01 0d cb	sub	x12, x9, x13
10117eb90:	0e 0d 1a 8b	add	x14, x8, x26, lsl #3
10117eb94:	ce 41 00 d1	sub	x14, x14, #0x10
10117eb98:	01 e4 00 6f	movi.2d	v1, #0000000000000000
10117eb9c:	ef 03 0d aa	mov	x15, x13
10117eba0:	02 e4 00 6f	movi.2d	v2, #0000000000000000
10117eba4:	03 e4 00 6f	movi.2d	v3, #0000000000000000
10117eba8:	04 e4 00 6f	movi.2d	v4, #0000000000000000
10117ebac:	c6 15 40 ad	ldp	q6, q5, [x14]
10117ebb0:	a5 40 05 6e	ext.16b	v5, v5, v5, #0x8
10117ebb4:	c6 40 06 6e	ext.16b	v6, v6, v6, #0x8
10117ebb8:	d0 1d 7f ad	ldp	q16, q7, [x14, #-0x20]
10117ebbc:	e7 40 07 6e	ext.16b	v7, v7, v7, #0x8
10117ebc0:	10 42 10 6e	ext.16b	v16, v16, v16, #0x8
10117ebc4:	a5 f8 e0 4e	fabs.2d	v5, v5
10117ebc8:	c6 f8 e0 4e	fabs.2d	v6, v6
10117ebcc:	e7 f8 e0 4e	fabs.2d	v7, v7
10117ebd0:	10 fa e0 4e	fabs.2d	v16, v16
10117ebd4:	a1 d4 61 4e	fadd.2d	v1, v5, v1
10117ebd8:	c2 d4 62 4e	fadd.2d	v2, v6, v2
10117ebdc:	e3 d4 63 4e	fadd.2d	v3, v7, v3
10117ebe0:	04 d6 64 4e	fadd.2d	v4, v16, v4
10117ebe4:	ce 01 01 d1	sub	x14, x14, #0x40
10117ebe8:	ef 21 00 d1	sub	x15, x15, #0x8
10117ebec:	0f fe ff b5	cbnz	x15, 0x10117ebac
10117ebf0:	41 d4 61 4e	fadd.2d	v1, v2, v1
10117ebf4:	61 d4 61 4e	fadd.2d	v1, v3, v1
10117ebf8:	81 d4 61 4e	fadd.2d	v1, v4, v1
10117ebfc:	21 d8 70 7e	faddp.2d	d1, v1
10117ec00:	7f 01 0d eb	cmp	x11, x13
10117ec04:	e0 00 00 54	b.eq	0x10117ec20
10117ec08:	02 79 6c fc	ldr	d2, [x8, x12, lsl #3]
10117ec0c:	42 c0 60 1e	fabs	d2, d2
10117ec10:	41 28 61 1e	fadd	d1, d2, d1
10117ec14:	8c 05 00 d1	sub	x12, x12, #0x1
10117ec18:	9f 01 0a eb	cmp	x12, x10
10117ec1c:	6c ff ff 54	b.gt	0x10117ec08
10117ec20:	02 e4 00 2f	movi	d2, #0000000000000000
10117ec24:	21 18 60 1e	fdiv	d1, d1, d0
10117ec28:	7f 21 00 f1	cmp	x11, #0x8
10117ec2c:	c3 04 00 54	b.lo	0x10117ecc4
10117ec30:	6c f1 7d 92	and	x12, x11, #0xfffffffffffffff8
10117ec34:	29 01 0c cb	sub	x9, x9, x12
10117ec38:	22 04 08 4e	dup.2d	v2, v1[0]
10117ec3c:	0d 0d 1a 8b	add	x13, x8, x26, lsl #3
10117ec40:	ad 41 00 d1	sub	x13, x13, #0x10
10117ec44:	03 e4 00 6f	movi.2d	v3, #0000000000000000
10117ec48:	ee 03 0c aa	mov	x14, x12
10117ec4c:	04 e4 00 6f	movi.2d	v4, #0000000000000000
10117ec50:	05 e4 00 6f	movi.2d	v5, #0000000000000000
10117ec54:	06 e4 00 6f	movi.2d	v6, #0000000000000000
10117ec58:	b0 1d 40 ad	ldp	q16, q7, [x13]
10117ec5c:	e7 40 07 6e	ext.16b	v7, v7, v7, #0x8
10117ec60:	10 42 10 6e	ext.16b	v16, v16, v16, #0x8
10117ec64:	b2 45 7f ad	ldp	q18, q17, [x13, #-0x20]
10117ec68:	31 42 11 6e	ext.16b	v17, v17, v17, #0x8
10117ec6c:	52 42 12 6e	ext.16b	v18, v18, v18, #0x8
10117ec70:	e7 f8 e0 4e	fabs.2d	v7, v7
10117ec74:	10 fa e0 4e	fabs.2d	v16, v16
10117ec78:	31 fa e0 4e	fabs.2d	v17, v17
10117ec7c:	52 fa e0 4e	fabs.2d	v18, v18
10117ec80:	e7 d4 e2 4e	fsub.2d	v7, v7, v2
10117ec84:	10 d6 e2 4e	fsub.2d	v16, v16, v2
10117ec88:	31 d6 e2 4e	fsub.2d	v17, v17, v2
10117ec8c:	52 d6 e2 4e	fsub.2d	v18, v18, v2
10117ec90:	e3 cc 67 4e	fmla.2d	v3, v7, v7
10117ec94:	04 ce 70 4e	fmla.2d	v4, v16, v16
10117ec98:	25 ce 71 4e	fmla.2d	v5, v17, v17
10117ec9c:	46 ce 72 4e	fmla.2d	v6, v18, v18
10117eca0:	ad 01 01 d1	sub	x13, x13, #0x40
10117eca4:	ce 21 00 d1	sub	x14, x14, #0x8
10117eca8:	8e fd ff b5	cbnz	x14, 0x10117ec58
10117ecac:	82 d4 63 4e	fadd.2d	v2, v4, v3
10117ecb0:	a2 d4 62 4e	fadd.2d	v2, v5, v2
10117ecb4:	c2 d4 62 4e	fadd.2d	v2, v6, v2
10117ecb8:	42 d8 70 7e	faddp.2d	d2, v2
10117ecbc:	7f 01 0c eb	cmp	x11, x12
10117ecc0:	00 01 00 54	b.eq	0x10117ece0
10117ecc4:	03 79 69 fc	ldr	d3, [x8, x9, lsl #3]
10117ecc8:	63 c0 60 1e	fabs	d3, d3
10117eccc:	63 38 61 1e	fsub	d3, d3, d1
10117ecd0:	62 08 43 1f	fmadd	d2, d3, d3, d2
10117ecd4:	29 05 00 d1	sub	x9, x9, #0x1
10117ecd8:	3f 01 0a eb	cmp	x9, x10
10117ecdc:	4c ff ff 54	b.gt	0x10117ecc4
10117ece0:	7f 06 00 71	cmp	w19, #0x1
10117ece4:	0b 02 00 54	b.lt	0x10117ed24
10117ece8:	40 18 60 1e	fdiv	d0, d2, d0
10117ecec:	00 c0 61 1e	fsqrt	d0, d0
10117ecf0:	02 10 7c 1e	fmov	d2, #-0.50000000
10117ecf4:	00 84 62 1f	fnmsub	d0, d0, d2, d1
10117ecf8:	ca 7e 40 92	and	x10, x22, #0xffffffff
10117ecfc:	29 00 80 12	mov	w9, #-0x2
10117ed00:	49 01 09 8b	add	x9, x10, x9
10117ed04:	01 79 6a fc	ldr	d1, [x8, x10, lsl #3]
10117ed08:	20 20 60 1e	fcmp	d1, d0
10117ed0c:	6b 28 00 54	b.lt	0x10117f218
10117ed10:	4b 05 00 d1	sub	x11, x10, #0x1
10117ed14:	29 05 00 d1	sub	x9, x9, #0x1
10117ed18:	5f 09 00 f1	cmp	x10, #0x2
10117ed1c:	ea 03 0b aa	mov	x10, x11
10117ed20:	28 ff ff 54	b.hi	0x10117ed04
10117ed24:	ff 33 01 b9	str	wzr, [sp, #0x130]
10117ed28:	e0 43 08 91	add	x0, sp, #0x210
10117ed2c:	e1 03 16 aa	mov	x1, x22
10117ed30:	88 0c 00 94	bl	__ZNSt3__16vectorIiNS_9allocatorIiEEEC1Em
10117ed34:	e0 e3 07 91	add	x0, sp, #0x1f8
10117ed38:	e1 03 16 aa	mov	x1, x22
10117ed3c:	85 0c 00 94	bl	__ZNSt3__16vectorIiNS_9allocatorIiEEEC1Em
10117ed40:	e0 83 07 91	add	x0, sp, #0x1e0
10117ed44:	e1 03 1c aa	mov	x1, x28
10117ed48:	2a 0c 00 94	bl	__ZNSt3__16vectorIdNS_9allocatorIdEEEC1Em
10117ed4c:	7f 06 00 31	cmn	w19, #0x1
10117ed50:	8b 04 00 54	b.lt	0x10117ede0
10117ed54:	08 00 80 d2	mov	x8, #0x0
10117ed58:	eb 83 41 f9	ldr	x11, [sp, #0x300]
10117ed5c:	ea f3 40 f9	ldr	x10, [sp, #0x1e0]
10117ed60:	3f 07 00 71	cmp	w25, #0x1
10117ed64:	29 c7 9f 1a	csinc	w9, w25, wzr, gt
10117ed68:	3f 21 00 71	cmp	w9, #0x8
10117ed6c:	83 02 00 54	b.lo	0x10117edbc
10117ed70:	4c 01 0b cb	sub	x12, x10, x11
10117ed74:	9f 01 01 f1	cmp	x12, #0x40
10117ed78:	23 02 00 54	b.lo	0x10117edbc
10117ed7c:	28 6d 7d 92	and	x8, x9, #0x7ffffff8
10117ed80:	4c 81 00 91	add	x12, x10, #0x20
10117ed84:	6d 81 00 91	add	x13, x11, #0x20
10117ed88:	ee 03 08 aa	mov	x14, x8
10117ed8c:	a0 05 7f ad	ldp	q0, q1, [x13, #-0x20]
10117ed90:	a2 0d c2 ac	ldp	q2, q3, [x13], #0x40
10117ed94:	00 f8 e0 4e	fabs.2d	v0, v0
10117ed98:	21 f8 e0 4e	fabs.2d	v1, v1
10117ed9c:	42 f8 e0 4e	fabs.2d	v2, v2
10117eda0:	63 f8 e0 4e	fabs.2d	v3, v3
10117eda4:	80 05 3f ad	stp	q0, q1, [x12, #-0x20]
10117eda8:	82 0d 82 ac	stp	q2, q3, [x12], #0x40
10117edac:	ce 21 00 f1	subs	x14, x14, #0x8
10117edb0:	e1 fe ff 54	b.ne	0x10117ed8c
10117edb4:	1f 01 09 eb	cmp	x8, x9
10117edb8:	40 01 00 54	b.eq	0x10117ede0
10117edbc:	0c f1 7d d3	lsl	x12, x8, #3
10117edc0:	6b 01 0c 8b	add	x11, x11, x12
10117edc4:	4a 01 0c 8b	add	x10, x10, x12
10117edc8:	28 01 08 cb	sub	x8, x9, x8
10117edcc:	60 85 40 fc	ldr	d0, [x11], #0x8
10117edd0:	00 c0 60 1e	fabs	d0, d0
10117edd4:	40 85 00 fc	str	d0, [x10], #0x8
10117edd8:	08 05 00 f1	subs	x8, x8, #0x1
10117eddc:	81 ff ff 54	b.ne	0x10117edcc
10117ede0:	15 01 00 36	tbz	w21, #0x0, 0x10117ee00
10117ede4:	2a 07 01 12	and	w10, w25, #0x80000001
10117ede8:	5f 05 00 71	cmp	w10, #0x1
10117edec:	21 04 00 54	b.ne	0x10117ee70
10117edf0:	28 7f 01 53	lsr	w8, w25, #1
10117edf4:	e9 f3 40 f9	ldr	x9, [sp, #0x1e0]
10117edf8:	20 59 68 fc	ldr	d0, [x9, w8, uxtw #3]
10117edfc:	26 00 00 14	b	0x10117ee94
10117ee00:	0c 00 80 d2	mov	x12, #0x0
10117ee04:	e8 f3 40 f9	ldr	x8, [sp, #0x1e0]
10117ee08:	c9 7e 40 92	and	x9, x22, #0xffffffff
10117ee0c:	0a 21 00 91	add	x10, x8, #0x8
10117ee10:	2b 00 80 52	mov	w11, #0x1
10117ee14:	06 00 00 14	b	0x10117ee2c
10117ee18:	6b 05 00 91	add	x11, x11, #0x1
10117ee1c:	4a 21 00 91	add	x10, x10, #0x8
10117ee20:	ec 03 0d aa	mov	x12, x13
10117ee24:	bf 01 09 eb	cmp	x13, x9
10117ee28:	e0 fd ff 54	b.eq	0x10117ede4
10117ee2c:	8d 05 00 91	add	x13, x12, #0x1
10117ee30:	3f 03 0d 6b	cmp	w25, w13
10117ee34:	2d ff ff 54	b.le	0x10117ee18
10117ee38:	ee 03 19 aa	mov	x14, x25
10117ee3c:	ef 03 0a aa	mov	x15, x10
10117ee40:	05 00 00 14	b	0x10117ee54
10117ee44:	ef 21 00 91	add	x15, x15, #0x8
10117ee48:	ce 05 00 d1	sub	x14, x14, #0x1
10117ee4c:	7f 01 0e eb	cmp	x11, x14
10117ee50:	40 fe ff 54	b.eq	0x10117ee18
10117ee54:	00 79 6c fc	ldr	d0, [x8, x12, lsl #3]
10117ee58:	e1 01 40 fd	ldr	d1, [x15]
10117ee5c:	00 20 61 1e	fcmp	d0, d1
10117ee60:	2a ff ff 54	b.ge	0x10117ee44
10117ee64:	01 79 2c fc	str	d1, [x8, x12, lsl #3]
10117ee68:	e0 01 00 fd	str	d0, [x15]
10117ee6c:	f6 ff ff 17	b	0x10117ee44
10117ee70:	3f 03 00 71	cmp	w25, #0x0
10117ee74:	28 a7 99 1a	cinc	w8, w25, lt
10117ee78:	08 7d 01 13	asr	w8, w8, #1
10117ee7c:	e9 f3 40 f9	ldr	x9, [sp, #0x1e0]
10117ee80:	28 cd 28 8b	add	x8, x9, w8, sxtw #3
10117ee84:	00 85 7f 6d	ldp	d0, d1, [x8, #-0x8]
10117ee88:	20 28 60 1e	fadd	d0, d1, d0
10117ee8c:	01 10 6c 1e	fmov	d1, #0.50000000
10117ee90:	00 08 61 1e	fmul	d0, d0, d1
10117ee94:	ea 23 01 b9	str	w10, [sp, #0x120]
10117ee98:	b5 00 00 36	tbz	w21, #0x0, 0x10117eeac
10117ee9c:	fb 03 14 aa	mov	x27, x20
10117eea0:	14 00 80 52	mov	w20, #0x0
10117eea4:	35 00 80 52	mov	w21, #0x1
10117eea8:	34 00 00 14	b	0x10117ef78
10117eeac:	09 00 80 52	mov	w9, #0x0
10117eeb0:	ea 83 41 f9	ldr	x10, [sp, #0x300]
10117eeb4:	e8 e7 01 b2	mov	x8, #-0x6666666666666667
10117eeb8:	48 33 93 f2	movk	x8, #0x999a
10117eebc:	28 f9 e7 f2	movk	x8, #0x3fc9, lsl #48
10117eec0:	01 01 67 9e	fmov	d1, x8
10117eec4:	01 28 61 1e	fadd	d1, d0, d1
10117eec8:	eb 0b 41 f9	ldr	x11, [sp, #0x210]
10117eecc:	ec ff 40 f9	ldr	x12, [sp, #0x1f8]
10117eed0:	df 06 00 71	cmp	w22, #0x1
10117eed4:	c8 c6 9f 1a	csinc	w8, w22, wzr, gt
10117eed8:	ed 03 08 cb	neg	x13, x8
10117eedc:	2e 00 80 52	mov	w14, #0x1
10117eee0:	8f 01 80 52	mov	w15, #0xc
10117eee4:	0b 00 00 14	b	0x10117ef10
10117eee8:	f1 b3 40 f9	ldr	x17, [sp, #0x160]
10117eeec:	31 02 40 f9	ldr	x17, [x17]
10117eef0:	31 6a 6f b8	ldr	w17, [x17, x15]
10117eef4:	91 79 30 b8	str	w17, [x12, x16, lsl #2]
10117eef8:	29 05 00 11	add	w9, w9, #0x1
10117eefc:	ce 05 00 91	add	x14, x14, #0x1
10117ef00:	ef 61 00 91	add	x15, x15, #0x18
10117ef04:	b0 01 0e 8b	add	x16, x13, x14
10117ef08:	1f 06 00 f1	cmp	x16, #0x1
10117ef0c:	40 02 00 54	b.eq	0x10117ef54
10117ef10:	42 79 6e fc	ldr	d2, [x10, x14, lsl #3]
10117ef14:	40 20 61 1e	fcmp	d2, d1
10117ef18:	2d ff ff 54	b.le	0x10117eefc
10117ef1c:	30 7d 40 93	sxtw	x16, w9
10117ef20:	6e d9 29 b8	str	w14, [x11, w9, sxtw #2]
10117ef24:	df 01 1a eb	cmp	x14, x26
10117ef28:	0d fe ff 54	b.le	0x10117eee8
10117ef2c:	f1 b3 40 f9	ldr	x17, [sp, #0x160]
10117ef30:	31 02 40 f9	ldr	x17, [x17]
10117ef34:	31 02 0f 8b	add	x17, x17, x15
10117ef38:	31 82 5e b8	ldur	w17, [x17, #-0x18]
10117ef3c:	20 06 00 11	add	w0, w17, #0x1
10117ef40:	80 79 30 b8	str	w0, [x12, x16, lsl #2]
10117ef44:	3f 12 00 71	cmp	w17, #0x4
10117ef48:	8b fd ff 54	b.lt	0x10117eef8
10117ef4c:	31 0e 00 51	sub	w17, w17, #0x3
10117ef50:	e9 ff ff 17	b	0x10117eef4
10117ef54:	fb 03 14 aa	mov	x27, x20
10117ef58:	3f 15 00 71	cmp	w9, #0x5
10117ef5c:	ea a7 9f 1a	cset	w10, lt
10117ef60:	3f 11 00 71	cmp	w9, #0x4
10117ef64:	34 c1 9f 1a	csel	w20, w9, wzr, gt
10117ef68:	e9 d7 9f 1a	cset	w9, gt
10117ef6c:	29 01 15 2a	orr	w9, w9, w21
10117ef70:	c9 16 00 36	tbz	w9, #0x0, 0x10117f248
10117ef74:	55 01 15 2a	orr	w21, w10, w21
10117ef78:	7f 06 00 31	cmn	w19, #0x1
10117ef7c:	eb 05 00 54	b.lt	0x10117f038
10117ef80:	09 00 80 d2	mov	x9, #0x0
10117ef84:	e8 8f 41 f9	ldr	x8, [sp, #0x318]
10117ef88:	ea 2f 41 f9	ldr	x10, [sp, #0x258]
10117ef8c:	eb 23 41 f9	ldr	x11, [sp, #0x240]
10117ef90:	3f 07 00 71	cmp	w25, #0x1
10117ef94:	2c c7 9f 1a	csinc	w12, w25, wzr, gt
10117ef98:	9f 21 00 71	cmp	w12, #0x8
10117ef9c:	03 04 00 54	b.lo	0x10117f01c
10117efa0:	4d 01 08 cb	sub	x13, x10, x8
10117efa4:	bf 01 01 f1	cmp	x13, #0x40
10117efa8:	a3 03 00 54	b.lo	0x10117f01c
10117efac:	89 6d 7d 92	and	x9, x12, #0x7ffffff8
10117efb0:	6d 41 00 91	add	x13, x11, #0x10
10117efb4:	0e 81 00 91	add	x14, x8, #0x20
10117efb8:	8f 2e 01 f0	adrp	x15, 9683 ; 0x103751000
10117efbc:	e0 45 42 fd	ldr	d0, [x15, #0x488]
10117efc0:	4f 81 00 91	add	x15, x10, #0x20
10117efc4:	41 04 00 0f	movi.2s	v1, #0x2
10117efc8:	82 04 00 0f	movi.2s	v2, #0x4
10117efcc:	c3 04 00 0f	movi.2s	v3, #0x6
10117efd0:	04 05 00 0f	movi.2s	v4, #0x8
10117efd4:	f0 03 09 aa	mov	x16, x9
10117efd8:	05 84 a1 0e	add.2s	v5, v0, v1
10117efdc:	06 84 a2 0e	add.2s	v6, v0, v2
10117efe0:	07 84 a3 0e	add.2s	v7, v0, v3
10117efe4:	d0 45 7f ad	ldp	q16, q17, [x14, #-0x20]
10117efe8:	d2 4d c2 ac	ldp	q18, q19, [x14], #0x40
10117efec:	f0 45 3f ad	stp	q16, q17, [x15, #-0x20]
10117eff0:	f2 4d 82 ac	stp	q18, q19, [x15], #0x40
10117eff4:	a0 01 1f fc	stur	d0, [x13, #-0x10]
10117eff8:	a5 81 1f fc	stur	d5, [x13, #-0x8]
10117effc:	00 84 a4 0e	add.2s	v0, v0, v4
10117f000:	a6 01 00 fd	str	d6, [x13]
10117f004:	a7 05 00 fd	str	d7, [x13, #0x8]
10117f008:	ad 81 00 91	add	x13, x13, #0x20
10117f00c:	10 22 00 f1	subs	x16, x16, #0x8
10117f010:	41 fe ff 54	b.ne	0x10117efd8
10117f014:	3f 01 0c eb	cmp	x9, x12
10117f018:	00 01 00 54	b.eq	0x10117f038
10117f01c:	2d f1 7d d3	lsl	x13, x9, #3
10117f020:	00 69 6d fc	ldr	d0, [x8, x13]
10117f024:	40 69 2d fc	str	d0, [x10, x13]
10117f028:	69 79 29 b8	str	w9, [x11, x9, lsl #2]
10117f02c:	29 05 00 91	add	x9, x9, #0x1
10117f030:	9f 01 09 eb	cmp	x12, x9
10117f034:	41 ff ff 54	b.ne	0x10117f01c
10117f038:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
10117f03c:	09 01 40 f9	ldr	x9, [x8]
10117f040:	e8 17 41 f9	ldr	x8, [sp, #0x228]
10117f044:	7f 06 00 71	cmp	w19, #0x1
10117f048:	0b 01 00 54	b.lt	0x10117f068
10117f04c:	6a 7e 40 92	and	x10, x19, #0xffffffff
10117f050:	2b 31 00 91	add	x11, x9, #0xc
10117f054:	ec 03 08 aa	mov	x12, x8
10117f058:	6d 85 41 b8	ldr	w13, [x11], #0x18
10117f05c:	8d 45 00 b8	str	w13, [x12], #0x4
10117f060:	4a 05 00 f1	subs	x10, x10, #0x1
10117f064:	a1 ff ff 54	b.ne	0x10117f058
10117f068:	6a 7e 60 d3	lsl	x10, x19, #32
10117f06c:	eb 7f 60 b2	mov	x11, #-0x100000000
10117f070:	4a 01 0b 8b	add	x10, x10, x11
10117f074:	4a fd 60 93	asr	x10, x10, #32
10117f078:	0b 03 80 52	mov	w11, #0x18
10117f07c:	49 25 0b 9b	madd	x9, x10, x11, x9
10117f080:	2a 0d 40 b9	ldr	w10, [x9, #0xc]
10117f084:	6b 7e 7e 93	sbfiz	x11, x19, #2, #32
10117f088:	4c 0d 00 71	subs	w12, w10, #0x3
10117f08c:	8a c5 8a 1a	csinc	w10, w12, w10, gt
10117f090:	0a 69 2b b8	str	w10, [x8, x11]
10117f094:	29 0d 40 b9	ldr	w9, [x9, #0xc]
10117f098:	3f 09 00 71	cmp	w9, #0x2
10117f09c:	2a 00 80 12	mov	w10, #-0x2
10117f0a0:	4a c5 8a 5a	cneg	w10, w10, le
10117f0a4:	29 01 0a 0b	add	w9, w9, w10
10117f0a8:	09 79 36 b8	str	w9, [x8, x22, lsl #2]
10117f0ac:	75 02 00 36	tbz	w21, #0x0, 0x10117f0f8
10117f0b0:	09 01 40 b9	ldr	w9, [x8]
10117f0b4:	29 05 00 51	sub	w9, w9, #0x1
10117f0b8:	3f 11 00 71	cmp	w9, #0x4
10117f0bc:	62 07 00 54	b.hs	0x10117f1a8
10117f0c0:	29 7d 7e 93	sbfiz	x9, x9, #2, #32
10117f0c4:	aa 31 01 90	adrp	x10, 9780 ; 0x1037b3000
10117f0c8:	4a c1 3e 91	add	x10, x10, #0xfb0
10117f0cc:	56 69 69 b8	ldr	w22, [x10, x9]
10117f0d0:	ea 2e 01 90	adrp	x10, 9692 ; 0x10375b000
10117f0d4:	4a c1 39 91	add	x10, x10, #0xe70
10117f0d8:	4d 69 69 b8	ldr	w13, [x10, x9]
10117f0dc:	4a 32 01 b0	adrp	x10, 9801 ; 0x1037c8000
10117f0e0:	4a c1 0b 91	add	x10, x10, #0x2f0
10117f0e4:	4e 69 69 b8	ldr	w14, [x10, x9]
10117f0e8:	8a 2f 01 b0	adrp	x10, 9713 ; 0x103770000
10117f0ec:	4a 01 2f 91	add	x10, x10, #0xbc0
10117f0f0:	4f 69 69 b8	ldr	w15, [x10, x9]
10117f0f4:	31 00 00 14	b	0x10117f1b8
10117f0f8:	0e 00 80 d2	mov	x14, #0x0
10117f0fc:	e9 2f 41 f9	ldr	x9, [sp, #0x258]
10117f100:	ca 7e 40 92	and	x10, x22, #0xffffffff
10117f104:	2b 21 00 91	add	x11, x9, #0x8
10117f108:	0c 11 00 91	add	x12, x8, #0x4
10117f10c:	2d 00 80 52	mov	w13, #0x1
10117f110:	07 00 00 14	b	0x10117f12c
10117f114:	ad 05 00 91	add	x13, x13, #0x1
10117f118:	6b 21 00 91	add	x11, x11, #0x8
10117f11c:	8c 11 00 91	add	x12, x12, #0x4
10117f120:	ee 03 0f aa	mov	x14, x15
10117f124:	ff 01 0a eb	cmp	x15, x10
10117f128:	40 fc ff 54	b.eq	0x10117f0b0
10117f12c:	cf 05 00 91	add	x15, x14, #0x1
10117f130:	3f 03 0f 6b	cmp	w25, w15
10117f134:	0d ff ff 54	b.le	0x10117f114
10117f138:	f0 23 41 f9	ldr	x16, [sp, #0x240]
10117f13c:	11 0a 0d 8b	add	x17, x16, x13, lsl #2
10117f140:	e0 03 19 aa	mov	x0, x25
10117f144:	e1 03 0c aa	mov	x1, x12
10117f148:	e2 03 0b aa	mov	x2, x11
10117f14c:	07 00 00 14	b	0x10117f168
10117f150:	42 20 00 91	add	x2, x2, #0x8
10117f154:	31 12 00 91	add	x17, x17, #0x4
10117f158:	21 10 00 91	add	x1, x1, #0x4
10117f15c:	00 04 00 d1	sub	x0, x0, #0x1
10117f160:	bf 01 00 eb	cmp	x13, x0
10117f164:	80 fd ff 54	b.eq	0x10117f114
10117f168:	20 79 6e fc	ldr	d0, [x9, x14, lsl #3]
10117f16c:	41 00 40 fd	ldr	d1, [x2]
10117f170:	00 20 61 1e	fcmp	d0, d1
10117f174:	ea fe ff 54	b.ge	0x10117f150
10117f178:	c3 f5 7e d3	lsl	x3, x14, #2
10117f17c:	04 6a 63 b8	ldr	w4, [x16, x3]
10117f180:	25 02 40 b9	ldr	w5, [x17]
10117f184:	05 6a 23 b8	str	w5, [x16, x3]
10117f188:	24 02 00 b9	str	w4, [x17]
10117f18c:	04 69 63 b8	ldr	w4, [x8, x3]
10117f190:	25 00 40 b9	ldr	w5, [x1]
10117f194:	05 69 23 b8	str	w5, [x8, x3]
10117f198:	24 00 00 b9	str	w4, [x1]
10117f19c:	21 79 2e fc	str	d1, [x9, x14, lsl #3]
10117f1a0:	40 00 00 fd	str	d0, [x2]
10117f1a4:	eb ff ff 17	b	0x10117f150
10117f1a8:	16 00 80 52	mov	w22, #0x0
10117f1ac:	0d 00 80 52	mov	w13, #0x0
10117f1b0:	0e 00 80 52	mov	w14, #0x0
10117f1b4:	0f 00 80 52	mov	w15, #0x0
10117f1b8:	09 05 40 b9	ldr	w9, [x8, #0x4]
10117f1bc:	29 05 00 51	sub	w9, w9, #0x1
10117f1c0:	3f 0d 00 71	cmp	w9, #0x3
10117f1c4:	e8 09 00 54	b.hi	0x10117f300
10117f1c8:	4a 32 01 b0	adrp	x10, 9801 ; 0x1037c8000
10117f1cc:	4a e9 07 91	add	x10, x10, #0x1fa
10117f1d0:	8b 00 00 10	adr	x11, #16
10117f1d4:	4c 69 69 38	ldrb	w12, [x10, x9]
10117f1d8:	6b 09 0c 8b	add	x11, x11, x12, lsl #2
10117f1dc:	60 01 1f d6	br	x11
10117f1e0:	ef 05 00 11	add	w15, w15, #0x1
10117f1e4:	47 00 00 14	b	0x10117f300
10117f1e8:	9f 01 13 6b	cmp	w12, w19
10117f1ec:	0d 42 00 54	b.le	0x10117fa2c
10117f1f0:	49 7d 40 92	and	x9, x10, #0xffffffff
10117f1f4:	ea b3 40 f9	ldr	x10, [sp, #0x160]
10117f1f8:	4a 01 40 f9	ldr	x10, [x10]
10117f1fc:	0c 03 80 52	mov	w12, #0x18
10117f200:	29 29 0c 9b	madd	x9, x9, x12, x10
10117f204:	29 0d 40 b9	ldr	w9, [x9, #0xc]
10117f208:	2a 0d 00 71	subs	w10, w9, #0x3
10117f20c:	49 c5 89 1a	csinc	w9, w10, w9, gt
10117f210:	e9 3b 01 b9	str	w9, [sp, #0x138]
10117f214:	52 fe ff 17	b	0x10117eb5c
10117f218:	5f 01 13 6b	cmp	w10, w19
10117f21c:	8d 41 00 54	b.le	0x10117fa4c
10117f220:	28 7d 40 92	and	x8, x9, #0xffffffff
10117f224:	e9 b3 40 f9	ldr	x9, [sp, #0x160]
10117f228:	29 01 40 f9	ldr	x9, [x9]
10117f22c:	0a 03 80 52	mov	w10, #0x18
10117f230:	08 25 0a 9b	madd	x8, x8, x10, x9
10117f234:	08 0d 40 b9	ldr	w8, [x8, #0xc]
10117f238:	09 0d 00 71	subs	w9, w8, #0x3
10117f23c:	28 c5 88 1a	csinc	w8, w9, w8, gt
10117f240:	e8 33 01 b9	str	w8, [sp, #0x130]
10117f244:	b9 fe ff 17	b	0x10117ed28
10117f248:	0c 00 80 d2	mov	x12, #0x0
10117f24c:	14 00 80 52	mov	w20, #0x0
10117f250:	e9 83 41 f9	ldr	x9, [sp, #0x300]
10117f254:	ea e7 01 b2	mov	x10, #-0x6666666666666667
10117f258:	4a 33 93 f2	movk	x10, #0x999a
10117f25c:	2a f7 e7 f2	movk	x10, #0x3fb9, lsl #48
10117f260:	41 01 67 9e	fmov	d1, x10
10117f264:	00 28 61 1e	fadd	d0, d0, d1
10117f268:	ea 0b 41 f9	ldr	x10, [sp, #0x210]
10117f26c:	eb ff 40 f9	ldr	x11, [sp, #0x1f8]
10117f270:	88 41 28 cb	sub	x8, x12, w8, uxtw
10117f274:	2c 00 80 52	mov	w12, #0x1
10117f278:	8d 01 80 52	mov	w13, #0xc
10117f27c:	0b 00 00 14	b	0x10117f2a8
10117f280:	ef b3 40 f9	ldr	x15, [sp, #0x160]
10117f284:	ef 01 40 f9	ldr	x15, [x15]
10117f288:	ef 69 6d b8	ldr	w15, [x15, x13]
10117f28c:	6f 79 2e b8	str	w15, [x11, x14, lsl #2]
10117f290:	94 06 00 11	add	w20, w20, #0x1
10117f294:	8c 05 00 91	add	x12, x12, #0x1
10117f298:	ad 61 00 91	add	x13, x13, #0x18
10117f29c:	0e 01 0c 8b	add	x14, x8, x12
10117f2a0:	df 05 00 f1	cmp	x14, #0x1
10117f2a4:	a0 e6 ff 54	b.eq	0x10117ef78
10117f2a8:	21 79 6c fc	ldr	d1, [x9, x12, lsl #3]
10117f2ac:	20 20 60 1e	fcmp	d1, d0
10117f2b0:	2d ff ff 54	b.le	0x10117f294
10117f2b4:	8e 7e 40 93	sxtw	x14, w20
10117f2b8:	4c d9 34 b8	str	w12, [x10, w20, sxtw #2]
10117f2bc:	9f 01 1a eb	cmp	x12, x26
10117f2c0:	0d fe ff 54	b.le	0x10117f280
10117f2c4:	ef b3 40 f9	ldr	x15, [sp, #0x160]
10117f2c8:	ef 01 40 f9	ldr	x15, [x15]
10117f2cc:	ef 01 0d 8b	add	x15, x15, x13
10117f2d0:	ef 81 5e b8	ldur	w15, [x15, #-0x18]
10117f2d4:	f0 05 00 11	add	w16, w15, #0x1
10117f2d8:	70 79 2e b8	str	w16, [x11, x14, lsl #2]
10117f2dc:	ff 11 00 71	cmp	w15, #0x4
10117f2e0:	8b fd ff 54	b.lt	0x10117f290
10117f2e4:	ef 0d 00 51	sub	w15, w15, #0x3
10117f2e8:	e9 ff ff 17	b	0x10117f28c
10117f2ec:	ad 05 00 11	add	w13, w13, #0x1
10117f2f0:	04 00 00 14	b	0x10117f300
10117f2f4:	d6 06 00 11	add	w22, w22, #0x1
10117f2f8:	02 00 00 14	b	0x10117f300
10117f2fc:	ce 05 00 11	add	w14, w14, #0x1
10117f300:	09 09 40 b9	ldr	w9, [x8, #0x8]
10117f304:	29 05 00 51	sub	w9, w9, #0x1
10117f308:	3f 0d 00 71	cmp	w9, #0x3
10117f30c:	c8 01 00 54	b.hi	0x10117f344
10117f310:	4a 32 01 b0	adrp	x10, 9801 ; 0x1037c8000
10117f314:	4a f9 07 91	add	x10, x10, #0x1fe
10117f318:	8b 00 00 10	adr	x11, #16
10117f31c:	4c 69 69 38	ldrb	w12, [x10, x9]
10117f320:	6b 09 0c 8b	add	x11, x11, x12, lsl #2
10117f324:	60 01 1f d6	br	x11
10117f328:	ef 05 00 11	add	w15, w15, #0x1
10117f32c:	06 00 00 14	b	0x10117f344
10117f330:	ad 05 00 11	add	w13, w13, #0x1
10117f334:	04 00 00 14	b	0x10117f344
10117f338:	d6 06 00 11	add	w22, w22, #0x1
10117f33c:	02 00 00 14	b	0x10117f344
10117f340:	ce 05 00 11	add	w14, w14, #0x1
10117f344:	09 0d 40 b9	ldr	w9, [x8, #0xc]
10117f348:	29 05 00 51	sub	w9, w9, #0x1
10117f34c:	3f 0d 00 71	cmp	w9, #0x3
10117f350:	c8 01 00 54	b.hi	0x10117f388
10117f354:	4a 32 01 b0	adrp	x10, 9801 ; 0x1037c8000
10117f358:	4a 09 08 91	add	x10, x10, #0x202
10117f35c:	8b 00 00 10	adr	x11, #16
10117f360:	4c 69 69 38	ldrb	w12, [x10, x9]
10117f364:	6b 09 0c 8b	add	x11, x11, x12, lsl #2
10117f368:	60 01 1f d6	br	x11
10117f36c:	ef 05 00 11	add	w15, w15, #0x1
10117f370:	06 00 00 14	b	0x10117f388
10117f374:	ad 05 00 11	add	w13, w13, #0x1
10117f378:	04 00 00 14	b	0x10117f388
10117f37c:	d6 06 00 11	add	w22, w22, #0x1
10117f380:	02 00 00 14	b	0x10117f388
10117f384:	ce 05 00 11	add	w14, w14, #0x1
10117f388:	09 11 40 b9	ldr	w9, [x8, #0x10]
10117f38c:	29 05 00 51	sub	w9, w9, #0x1
10117f390:	3f 0d 00 71	cmp	w9, #0x3
10117f394:	c8 01 00 54	b.hi	0x10117f3cc
10117f398:	4a 32 01 b0	adrp	x10, 9801 ; 0x1037c8000
10117f39c:	4a 19 08 91	add	x10, x10, #0x206
10117f3a0:	8b 00 00 10	adr	x11, #16
10117f3a4:	4c 69 69 38	ldrb	w12, [x10, x9]
10117f3a8:	6b 09 0c 8b	add	x11, x11, x12, lsl #2
10117f3ac:	60 01 1f d6	br	x11
10117f3b0:	ef 05 00 11	add	w15, w15, #0x1
10117f3b4:	06 00 00 14	b	0x10117f3cc
10117f3b8:	ad 05 00 11	add	w13, w13, #0x1
10117f3bc:	04 00 00 14	b	0x10117f3cc
10117f3c0:	d6 06 00 11	add	w22, w22, #0x1
10117f3c4:	02 00 00 14	b	0x10117f3cc
10117f3c8:	ce 05 00 11	add	w14, w14, #0x1
10117f3cc:	09 15 40 b9	ldr	w9, [x8, #0x14]
10117f3d0:	29 05 00 51	sub	w9, w9, #0x1
10117f3d4:	3f 0d 00 71	cmp	w9, #0x3
10117f3d8:	c8 01 00 54	b.hi	0x10117f410
10117f3dc:	4a 32 01 b0	adrp	x10, 9801 ; 0x1037c8000
10117f3e0:	4a 29 08 91	add	x10, x10, #0x20a
10117f3e4:	8b 00 00 10	adr	x11, #16
10117f3e8:	4c 69 69 38	ldrb	w12, [x10, x9]
10117f3ec:	6b 09 0c 8b	add	x11, x11, x12, lsl #2
10117f3f0:	60 01 1f d6	br	x11
10117f3f4:	ef 05 00 11	add	w15, w15, #0x1
10117f3f8:	06 00 00 14	b	0x10117f410
10117f3fc:	ad 05 00 11	add	w13, w13, #0x1
10117f400:	04 00 00 14	b	0x10117f410
10117f404:	d6 06 00 11	add	w22, w22, #0x1
10117f408:	02 00 00 14	b	0x10117f410
10117f40c:	ce 05 00 11	add	w14, w14, #0x1
10117f410:	09 19 40 b9	ldr	w9, [x8, #0x18]
10117f414:	29 05 00 51	sub	w9, w9, #0x1
10117f418:	3f 0d 00 71	cmp	w9, #0x3
10117f41c:	c8 01 00 54	b.hi	0x10117f454
10117f420:	4a 32 01 b0	adrp	x10, 9801 ; 0x1037c8000
10117f424:	4a 39 08 91	add	x10, x10, #0x20e
10117f428:	8b 00 00 10	adr	x11, #16
10117f42c:	4c 69 69 38	ldrb	w12, [x10, x9]
10117f430:	6b 09 0c 8b	add	x11, x11, x12, lsl #2
10117f434:	60 01 1f d6	br	x11
10117f438:	ef 05 00 11	add	w15, w15, #0x1
10117f43c:	06 00 00 14	b	0x10117f454
10117f440:	ad 05 00 11	add	w13, w13, #0x1
10117f444:	04 00 00 14	b	0x10117f454
10117f448:	d6 06 00 11	add	w22, w22, #0x1
10117f44c:	02 00 00 14	b	0x10117f454
10117f450:	ce 05 00 11	add	w14, w14, #0x1
10117f454:	09 1d 40 b9	ldr	w9, [x8, #0x1c]
10117f458:	29 05 00 51	sub	w9, w9, #0x1
10117f45c:	3f 0d 00 71	cmp	w9, #0x3
10117f460:	c8 01 00 54	b.hi	0x10117f498
10117f464:	4a 32 01 b0	adrp	x10, 9801 ; 0x1037c8000
10117f468:	4a 49 08 91	add	x10, x10, #0x212
10117f46c:	8b 00 00 10	adr	x11, #16
10117f470:	4c 69 69 38	ldrb	w12, [x10, x9]
10117f474:	6b 09 0c 8b	add	x11, x11, x12, lsl #2
10117f478:	60 01 1f d6	br	x11
10117f47c:	ef 05 00 11	add	w15, w15, #0x1
10117f480:	06 00 00 14	b	0x10117f498
10117f484:	ad 05 00 11	add	w13, w13, #0x1
10117f488:	04 00 00 14	b	0x10117f498
10117f48c:	d6 06 00 11	add	w22, w22, #0x1
10117f490:	02 00 00 14	b	0x10117f498
10117f494:	ce 05 00 11	add	w14, w14, #0x1
10117f498:	09 21 40 b9	ldr	w9, [x8, #0x20]
10117f49c:	29 05 00 51	sub	w9, w9, #0x1
10117f4a0:	3f 0d 00 71	cmp	w9, #0x3
10117f4a4:	c8 01 00 54	b.hi	0x10117f4dc
10117f4a8:	4a 32 01 b0	adrp	x10, 9801 ; 0x1037c8000
10117f4ac:	4a 59 08 91	add	x10, x10, #0x216
10117f4b0:	8b 00 00 10	adr	x11, #16
10117f4b4:	4c 69 69 38	ldrb	w12, [x10, x9]
10117f4b8:	6b 09 0c 8b	add	x11, x11, x12, lsl #2
10117f4bc:	60 01 1f d6	br	x11
10117f4c0:	ef 05 00 11	add	w15, w15, #0x1
10117f4c4:	06 00 00 14	b	0x10117f4dc
10117f4c8:	ad 05 00 11	add	w13, w13, #0x1
10117f4cc:	04 00 00 14	b	0x10117f4dc
10117f4d0:	d6 06 00 11	add	w22, w22, #0x1
10117f4d4:	02 00 00 14	b	0x10117f4dc
10117f4d8:	ce 05 00 11	add	w14, w14, #0x1
10117f4dc:	09 25 40 b9	ldr	w9, [x8, #0x24]
10117f4e0:	29 05 00 51	sub	w9, w9, #0x1
10117f4e4:	3f 0d 00 71	cmp	w9, #0x3
10117f4e8:	c8 01 00 54	b.hi	0x10117f520
10117f4ec:	4a 32 01 b0	adrp	x10, 9801 ; 0x1037c8000
10117f4f0:	4a 69 08 91	add	x10, x10, #0x21a
10117f4f4:	8b 00 00 10	adr	x11, #16
10117f4f8:	4c 69 69 38	ldrb	w12, [x10, x9]
10117f4fc:	6b 09 0c 8b	add	x11, x11, x12, lsl #2
10117f500:	60 01 1f d6	br	x11
10117f504:	ef 05 00 11	add	w15, w15, #0x1
10117f508:	06 00 00 14	b	0x10117f520
10117f50c:	ad 05 00 11	add	w13, w13, #0x1
10117f510:	04 00 00 14	b	0x10117f520
10117f514:	d6 06 00 11	add	w22, w22, #0x1
10117f518:	02 00 00 14	b	0x10117f520
10117f51c:	ce 05 00 11	add	w14, w14, #0x1
10117f520:	09 29 40 b9	ldr	w9, [x8, #0x28]
10117f524:	29 05 00 51	sub	w9, w9, #0x1
10117f528:	3f 0d 00 71	cmp	w9, #0x3
10117f52c:	c8 01 00 54	b.hi	0x10117f564
10117f530:	4a 32 01 b0	adrp	x10, 9801 ; 0x1037c8000
10117f534:	4a 79 08 91	add	x10, x10, #0x21e
10117f538:	8b 00 00 10	adr	x11, #16
10117f53c:	4c 69 69 38	ldrb	w12, [x10, x9]
10117f540:	6b 09 0c 8b	add	x11, x11, x12, lsl #2
10117f544:	60 01 1f d6	br	x11
10117f548:	ef 05 00 11	add	w15, w15, #0x1
10117f54c:	06 00 00 14	b	0x10117f564
10117f550:	ad 05 00 11	add	w13, w13, #0x1
10117f554:	04 00 00 14	b	0x10117f564
10117f558:	d6 06 00 11	add	w22, w22, #0x1
10117f55c:	02 00 00 14	b	0x10117f564
10117f560:	ce 05 00 11	add	w14, w14, #0x1
10117f564:	09 2d 40 b9	ldr	w9, [x8, #0x2c]
10117f568:	29 05 00 51	sub	w9, w9, #0x1
10117f56c:	3f 0d 00 71	cmp	w9, #0x3
10117f570:	c8 01 00 54	b.hi	0x10117f5a8
10117f574:	4a 32 01 b0	adrp	x10, 9801 ; 0x1037c8000
10117f578:	4a 89 08 91	add	x10, x10, #0x222
10117f57c:	8b 00 00 10	adr	x11, #16
10117f580:	4c 69 69 38	ldrb	w12, [x10, x9]
10117f584:	6b 09 0c 8b	add	x11, x11, x12, lsl #2
10117f588:	60 01 1f d6	br	x11
10117f58c:	ef 05 00 11	add	w15, w15, #0x1
10117f590:	06 00 00 14	b	0x10117f5a8
10117f594:	ad 05 00 11	add	w13, w13, #0x1
10117f598:	04 00 00 14	b	0x10117f5a8
10117f59c:	d6 06 00 11	add	w22, w22, #0x1
10117f5a0:	02 00 00 14	b	0x10117f5a8
10117f5a4:	ce 05 00 11	add	w14, w14, #0x1
10117f5a8:	09 31 40 b9	ldr	w9, [x8, #0x30]
10117f5ac:	29 05 00 51	sub	w9, w9, #0x1
10117f5b0:	3f 0d 00 71	cmp	w9, #0x3
10117f5b4:	c8 01 00 54	b.hi	0x10117f5ec
10117f5b8:	4a 32 01 b0	adrp	x10, 9801 ; 0x1037c8000
10117f5bc:	4a 99 08 91	add	x10, x10, #0x226
10117f5c0:	8b 00 00 10	adr	x11, #16
10117f5c4:	4c 69 69 38	ldrb	w12, [x10, x9]
10117f5c8:	6b 09 0c 8b	add	x11, x11, x12, lsl #2
10117f5cc:	60 01 1f d6	br	x11
10117f5d0:	ef 05 00 11	add	w15, w15, #0x1
10117f5d4:	06 00 00 14	b	0x10117f5ec
10117f5d8:	ad 05 00 11	add	w13, w13, #0x1
10117f5dc:	04 00 00 14	b	0x10117f5ec
10117f5e0:	d6 06 00 11	add	w22, w22, #0x1
10117f5e4:	02 00 00 14	b	0x10117f5ec
10117f5e8:	ce 05 00 11	add	w14, w14, #0x1
10117f5ec:	09 35 40 b9	ldr	w9, [x8, #0x34]
10117f5f0:	29 05 00 51	sub	w9, w9, #0x1
10117f5f4:	3f 0d 00 71	cmp	w9, #0x3
10117f5f8:	c8 01 00 54	b.hi	0x10117f630
10117f5fc:	4a 32 01 b0	adrp	x10, 9801 ; 0x1037c8000
10117f600:	4a a9 08 91	add	x10, x10, #0x22a
10117f604:	8b 00 00 10	adr	x11, #16
10117f608:	4c 69 69 38	ldrb	w12, [x10, x9]
10117f60c:	6b 09 0c 8b	add	x11, x11, x12, lsl #2
10117f610:	60 01 1f d6	br	x11
10117f614:	ef 05 00 11	add	w15, w15, #0x1
10117f618:	06 00 00 14	b	0x10117f630
10117f61c:	ad 05 00 11	add	w13, w13, #0x1
10117f620:	04 00 00 14	b	0x10117f630
10117f624:	d6 06 00 11	add	w22, w22, #0x1
10117f628:	02 00 00 14	b	0x10117f630
10117f62c:	ce 05 00 11	add	w14, w14, #0x1
10117f630:	09 39 40 b9	ldr	w9, [x8, #0x38]
10117f634:	29 05 00 51	sub	w9, w9, #0x1
10117f638:	3f 0d 00 71	cmp	w9, #0x3
10117f63c:	c8 01 00 54	b.hi	0x10117f674
10117f640:	4a 32 01 b0	adrp	x10, 9801 ; 0x1037c8000
10117f644:	4a b9 08 91	add	x10, x10, #0x22e
10117f648:	8b 00 00 10	adr	x11, #16
10117f64c:	4c 69 69 38	ldrb	w12, [x10, x9]
10117f650:	6b 09 0c 8b	add	x11, x11, x12, lsl #2
10117f654:	60 01 1f d6	br	x11
10117f658:	ef 05 00 11	add	w15, w15, #0x1
10117f65c:	06 00 00 14	b	0x10117f674
10117f660:	ad 05 00 11	add	w13, w13, #0x1
10117f664:	04 00 00 14	b	0x10117f674
10117f668:	d6 06 00 11	add	w22, w22, #0x1
10117f66c:	02 00 00 14	b	0x10117f674
10117f670:	ce 05 00 11	add	w14, w14, #0x1
10117f674:	08 3d 40 b9	ldr	w8, [x8, #0x3c]
10117f678:	08 05 00 51	sub	w8, w8, #0x1
10117f67c:	1f 0d 00 71	cmp	w8, #0x3
10117f680:	a8 02 00 54	b.hi	0x10117f6d4
10117f684:	49 32 01 b0	adrp	x9, 9801 ; 0x1037c8000
10117f688:	29 c9 08 91	add	x9, x9, #0x232
10117f68c:	8a 00 00 10	adr	x10, #16
10117f690:	2b 69 68 38	ldrb	w11, [x9, x8]
10117f694:	4a 09 0b 8b	add	x10, x10, x11, lsl #2
10117f698:	40 01 1f d6	br	x10
10117f69c:	ed bb 1b 29	stp	w13, w14, [sp, #0xdc]
10117f6a0:	ef 05 00 11	add	w15, w15, #0x1
10117f6a4:	ef eb 00 b9	str	w15, [sp, #0xe8]
10117f6a8:	0d 00 00 14	b	0x10117f6dc
10117f6ac:	ef eb 00 b9	str	w15, [sp, #0xe8]
10117f6b0:	ad 05 00 11	add	w13, w13, #0x1
10117f6b4:	09 00 00 14	b	0x10117f6d8
10117f6b8:	ef eb 00 b9	str	w15, [sp, #0xe8]
10117f6bc:	ed bb 1b 29	stp	w13, w14, [sp, #0xdc]
10117f6c0:	d6 06 00 11	add	w22, w22, #0x1
10117f6c4:	06 00 00 14	b	0x10117f6dc
10117f6c8:	ef eb 00 b9	str	w15, [sp, #0xe8]
10117f6cc:	ce 05 00 11	add	w14, w14, #0x1
10117f6d0:	02 00 00 14	b	0x10117f6d8
10117f6d4:	ef eb 00 b9	str	w15, [sp, #0xe8]
10117f6d8:	ed bb 1b 29	stp	w13, w14, [sp, #0xdc]
10117f6dc:	e8 03 14 aa	mov	x8, x20
10117f6e0:	01 7d 40 93	sxtw	x1, w8
10117f6e4:	e0 23 07 91	add	x0, sp, #0x1c8
10117f6e8:	1a 0a 00 94	bl	__ZNSt3__16vectorIiNS_9allocatorIiEEEC1Em
10117f6ec:	9f 02 00 71	cmp	w20, #0x0
10117f6f0:	ed 00 00 54	b.le	0x10117f70c
10117f6f4:	e8 ff 40 f9	ldr	x8, [sp, #0x1f8]
10117f6f8:	08 01 40 b9	ldr	w8, [x8]
10117f6fc:	e9 e7 40 f9	ldr	x9, [sp, #0x1c8]
10117f700:	28 01 00 b9	str	w8, [x9]
10117f704:	8a 06 00 71	subs	w10, w20, #0x1
10117f708:	61 04 00 54	b.ne	0x10117f794
10117f70c:	28 00 80 52	mov	w8, #0x1
10117f710:	f1 5b 41 b9	ldr	w17, [sp, #0x158]
10117f714:	29 06 00 51	sub	w9, w17, #0x1
10117f718:	3f 11 00 71	cmp	w9, #0x4
10117f71c:	e2 01 00 54	b.hs	0x10117f758
10117f720:	29 7d 7e 93	sbfiz	x9, x9, #2, #32
10117f724:	8a 2f 01 b0	adrp	x10, 9713 ; 0x103770000
10117f728:	4a 01 2f 91	add	x10, x10, #0xbc0
10117f72c:	50 69 69 b8	ldr	w16, [x10, x9]
10117f730:	4a 32 01 b0	adrp	x10, 9801 ; 0x1037c8000
10117f734:	4a c1 0b 91	add	x10, x10, #0x2f0
10117f738:	4f 69 69 b8	ldr	w15, [x10, x9]
10117f73c:	ea 2e 01 90	adrp	x10, 9692 ; 0x10375b000
10117f740:	4a c1 39 91	add	x10, x10, #0xe70
10117f744:	4e 69 69 b8	ldr	w14, [x10, x9]
10117f748:	aa 31 01 90	adrp	x10, 9780 ; 0x1037b3000
10117f74c:	4a c1 3e 91	add	x10, x10, #0xfb0
10117f750:	4d 69 69 b8	ldr	w13, [x10, x9]
10117f754:	05 00 00 14	b	0x10117f768
10117f758:	10 00 80 52	mov	w16, #0x0
10117f75c:	0f 00 80 52	mov	w15, #0x0
10117f760:	0e 00 80 52	mov	w14, #0x0
10117f764:	0d 00 80 52	mov	w13, #0x0
10117f768:	09 07 00 51	sub	w9, w24, #0x1
10117f76c:	3f 0d 00 71	cmp	w9, #0x3
10117f770:	08 03 00 54	b.hi	0x10117f7d0
10117f774:	4a 32 01 b0	adrp	x10, 9801 ; 0x1037c8000
10117f778:	4a d9 08 91	add	x10, x10, #0x236
10117f77c:	8b 00 00 10	adr	x11, #16
10117f780:	4c 69 69 38	ldrb	w12, [x10, x9]
10117f784:	6b 09 0c 8b	add	x11, x11, x12, lsl #2
10117f788:	60 01 1f d6	br	x11
10117f78c:	10 06 00 11	add	w16, w16, #0x1
10117f790:	10 00 00 14	b	0x10117f7d0
10117f794:	eb ff 40 f9	ldr	x11, [sp, #0x1f8]
10117f798:	e9 e7 40 f9	ldr	x9, [sp, #0x1c8]
10117f79c:	e8 0b 41 f9	ldr	x8, [sp, #0x210]
10117f7a0:	08 31 40 29	ldp	w8, w12, [x8]
10117f7a4:	88 01 08 4b	sub	w8, w12, w8
10117f7a8:	1f 15 00 71	cmp	w8, #0x5
10117f7ac:	f1 5b 41 b9	ldr	w17, [sp, #0x158]
10117f7b0:	ea 15 00 54	b.ge	0x10117fa6c
10117f7b4:	28 00 80 52	mov	w8, #0x1
10117f7b8:	b0 00 00 14	b	0x10117fa78
10117f7bc:	ce 05 00 11	add	w14, w14, #0x1
10117f7c0:	04 00 00 14	b	0x10117f7d0
10117f7c4:	ad 05 00 11	add	w13, w13, #0x1
10117f7c8:	02 00 00 14	b	0x10117f7d0
10117f7cc:	ef 05 00 11	add	w15, w15, #0x1
10117f7d0:	7b 03 00 36	tbz	w27, #0x0, 0x10117f83c
10117f7d4:	f1 5b 01 b9	str	w17, [sp, #0x158]
10117f7d8:	f6 d3 00 b9	str	w22, [sp, #0xd0]
10117f7dc:	97 04 00 36	tbz	w23, #0x0, 0x10117f86c
10117f7e0:	f6 03 15 aa	mov	x22, x21
10117f7e4:	1f 02 0f 6b	cmp	w16, w15
10117f7e8:	09 c2 8f 1a	csel	w9, w16, w15, gt
10117f7ec:	ea 27 9f 1a	cset	w10, lo
10117f7f0:	4b 00 80 52	mov	w11, #0x2
10117f7f4:	3f 01 0e 6b	cmp	w9, w14
10117f7f8:	6a 31 8a 1a	csel	w10, w11, w10, lo
10117f7fc:	37 c1 8e 1a	csel	w23, w9, w14, gt
10117f800:	69 00 80 52	mov	w9, #0x3
10117f804:	bf 01 17 6b	cmp	w13, w23
10117f808:	2c 81 8a 1a	csel	w12, w9, w10, hi
10117f80c:	ff 02 0d 6b	cmp	w23, w13
10117f810:	e9 c2 8d 1a	csel	w9, w23, w13, gt
10117f814:	6c 04 00 34	cbz	w12, 0x10117f8a0
10117f818:	3f 01 10 6b	cmp	w9, w16
10117f81c:	ea 03 8c 1a	csel	w10, wzr, w12, eq
10117f820:	9f 05 00 71	cmp	w12, #0x1
10117f824:	20 04 00 54	b.eq	0x10117f8a8
10117f828:	3f 01 0f 6b	cmp	w9, w15
10117f82c:	4a 15 9f 1a	csinc	w10, w10, wzr, ne
10117f830:	9f 09 00 71	cmp	w12, #0x2
10117f834:	a1 03 00 54	b.ne	0x10117f8a8
10117f838:	1f 00 00 14	b	0x10117f8b4
10117f83c:	e9 3b 41 b9	ldr	w9, [sp, #0x138]
10117f840:	29 05 00 51	sub	w9, w9, #0x1
10117f844:	3f 0d 00 71	cmp	w9, #0x3
10117f848:	68 fc ff 54	b.hi	0x10117f7d4
10117f84c:	4a 32 01 b0	adrp	x10, 9801 ; 0x1037c8000
10117f850:	4a e9 08 91	add	x10, x10, #0x23a
10117f854:	8b 00 00 10	adr	x11, #16
10117f858:	4c 79 69 78	ldrh	w12, [x10, x9, lsl #1]
10117f85c:	6b 09 0c 8b	add	x11, x11, x12, lsl #2
10117f860:	60 01 1f d6	br	x11
10117f864:	10 06 00 11	add	w16, w16, #0x1
10117f868:	db ff ff 17	b	0x10117f7d4
10117f86c:	e9 33 41 b9	ldr	w9, [sp, #0x130]
10117f870:	29 05 00 51	sub	w9, w9, #0x1
10117f874:	3f 0d 00 71	cmp	w9, #0x3
10117f878:	48 fb ff 54	b.hi	0x10117f7e0
10117f87c:	4a 32 01 b0	adrp	x10, 9801 ; 0x1037c8000
10117f880:	4a 09 09 91	add	x10, x10, #0x242
10117f884:	8b 00 00 10	adr	x11, #16
10117f888:	4c 69 69 38	ldrb	w12, [x10, x9]
10117f88c:	6b 09 0c 8b	add	x11, x11, x12, lsl #2
10117f890:	60 01 1f d6	br	x11
10117f894:	f6 03 15 aa	mov	x22, x21
10117f898:	10 06 00 11	add	w16, w16, #0x1
10117f89c:	d2 ff ff 17	b	0x10117f7e4
10117f8a0:	3f 01 0f 6b	cmp	w9, w15
10117f8a4:	8a 15 9f 1a	csinc	w10, w12, wzr, ne
10117f8a8:	4b 00 80 52	mov	w11, #0x2
10117f8ac:	3f 01 0e 6b	cmp	w9, w14
10117f8b0:	6a 01 8a 1a	csel	w10, w11, w10, eq
10117f8b4:	ec 03 01 b9	str	w12, [sp, #0x100]
10117f8b8:	f0 cb 00 b9	str	w16, [sp, #0xc8]
10117f8bc:	ef c3 00 b9	str	w15, [sp, #0xc0]
10117f8c0:	ee bb 00 b9	str	w14, [sp, #0xb8]
10117f8c4:	f8 f3 00 b9	str	w24, [sp, #0xf0]
10117f8c8:	fc 8b 00 f9	str	x28, [sp, #0x110]
10117f8cc:	69 00 80 52	mov	w9, #0x3
10117f8d0:	ed fb 00 b9	str	w13, [sp, #0xf8]
10117f8d4:	bf 01 17 6b	cmp	w13, w23
10117f8d8:	2a 01 8a 1a	csel	w10, w9, w10, eq
10117f8dc:	ea 0b 01 b9	str	w10, [sp, #0x108]
10117f8e0:	1f 05 00 71	cmp	w8, #0x1
10117f8e4:	8d 03 00 54	b.le	0x10117f954
10117f8e8:	14 00 80 52	mov	w20, #0x0
10117f8ec:	1b 00 80 52	mov	w27, #0x0
10117f8f0:	1c 00 80 52	mov	w28, #0x0
10117f8f4:	18 00 80 52	mov	w24, #0x0
10117f8f8:	ea e7 40 f9	ldr	x10, [sp, #0x1c8]
10117f8fc:	e8 03 08 2a	mov	w8, w8
10117f900:	4b 32 01 b0	adrp	x11, 9801 ; 0x1037c8000
10117f904:	6b 19 09 91	add	x11, x11, #0x246
10117f908:	05 00 00 14	b	0x10117f91c
10117f90c:	9c 07 00 11	add	w28, w28, #0x1
10117f910:	4a 11 00 91	add	x10, x10, #0x4
10117f914:	08 05 00 f1	subs	x8, x8, #0x1
10117f918:	60 02 00 54	b.eq	0x10117f964
10117f91c:	4c 01 40 b9	ldr	w12, [x10]
10117f920:	8c 05 00 51	sub	w12, w12, #0x1
10117f924:	9f 0d 00 71	cmp	w12, #0x3
10117f928:	48 ff ff 54	b.hi	0x10117f910
10117f92c:	0d ff ff 10	adr	x13, #-32
10117f930:	6e 69 6c 38	ldrb	w14, [x11, x12]
10117f934:	ad 09 0e 8b	add	x13, x13, x14, lsl #2
10117f938:	a0 01 1f d6	br	x13
10117f93c:	94 06 00 11	add	w20, w20, #0x1
10117f940:	f4 ff ff 17	b	0x10117f910
10117f944:	18 07 00 11	add	w24, w24, #0x1
10117f948:	f2 ff ff 17	b	0x10117f910
10117f94c:	7b 07 00 11	add	w27, w27, #0x1
10117f950:	f0 ff ff 17	b	0x10117f910
10117f954:	14 00 80 52	mov	w20, #0x0
10117f958:	1b 00 80 52	mov	w27, #0x0
10117f95c:	1c 00 80 52	mov	w28, #0x0
10117f960:	18 00 80 52	mov	w24, #0x0
10117f964:	9f 02 00 71	cmp	w20, #0x0
10117f968:	8c c2 9f 1a	csel	w12, w20, wzr, gt
10117f96c:	9f 01 1b 6b	cmp	w12, w27
10117f970:	8b c1 9b 1a	csel	w11, w12, w27, gt
10117f974:	e8 a7 9f 1a	cset	w8, lt
10117f978:	4a 00 80 52	mov	w10, #0x2
10117f97c:	7f 01 1c 6b	cmp	w11, w28
10117f980:	48 b1 88 1a	csel	w8, w10, w8, lt
10117f984:	6a c1 9c 1a	csel	w10, w11, w28, gt
10117f988:	5f 01 18 6b	cmp	w10, w24
10117f98c:	28 b1 88 1a	csel	w8, w9, w8, lt
10117f990:	1f 09 00 71	cmp	w8, #0x2
10117f994:	20 01 00 54	b.eq	0x10117f9b8
10117f998:	1f 05 00 71	cmp	w8, #0x1
10117f99c:	a0 00 00 54	b.eq	0x10117f9b0
10117f9a0:	7f 03 00 71	cmp	w27, #0x0
10117f9a4:	69 c3 9f 1a	csel	w9, w27, wzr, gt
10117f9a8:	1f 01 00 71	cmp	w8, #0x0
10117f9ac:	6c 11 89 1a	csel	w12, w11, w9, ne
10117f9b0:	9f 01 1c 6b	cmp	w12, w28
10117f9b4:	8b c1 9c 1a	csel	w11, w12, w28, gt
10117f9b8:	7f 01 18 6b	cmp	w11, w24
10117f9bc:	69 c1 98 1a	csel	w9, w11, w24, gt
10117f9c0:	5f 01 18 6b	cmp	w10, w24
10117f9c4:	69 b1 89 1a	csel	w9, w11, w9, lt
10117f9c8:	4a c1 98 1a	csel	w10, w10, w24, gt
10117f9cc:	4a 01 09 6b	subs	w10, w10, w9
10117f9d0:	4a 55 8a 5a	cneg	w10, w10, mi
10117f9d4:	5f 29 00 71	cmp	w10, #0xa
10117f9d8:	20 99 44 7a	ccmp	w9, #0x4, #0x0, ls
10117f9dc:	88 00 00 54	b.hi	0x10117f9ec
10117f9e0:	15 05 00 11	add	w21, w8, #0x1
10117f9e4:	f9 b3 40 f9	ldr	x25, [sp, #0x160]
10117f9e8:	f8 01 00 14	b	0x1011801c8
10117f9ec:	d6 18 00 37	tbnz	w22, #0x0, 0x10117fd04
10117f9f0:	e9 8f 41 f9	ldr	x9, [sp, #0x318]
10117f9f4:	ea a3 40 f9	ldr	x10, [sp, #0x140]
10117f9f8:	48 7d 40 92	and	x8, x10, #0xffffffff
10117f9fc:	5f 21 00 71	cmp	w10, #0x8
10117fa00:	e2 0d 00 54	b.hs	0x10117fbbc
10117fa04:	0a 00 80 d2	mov	x10, #0x0
10117fa08:	00 e4 00 2f	movi	d0, #0000000000000000
10117fa0c:	81 00 00 14	b	0x10117fc10
10117fa10:	6b fd 60 93	asr	x11, x11, #32
10117fa14:	ec b3 40 f9	ldr	x12, [sp, #0x160]
10117fa18:	8c 01 40 f9	ldr	x12, [x12]
10117fa1c:	0d 03 80 52	mov	w13, #0x18
10117fa20:	6b 31 0d 9b	madd	x11, x11, x13, x12
10117fa24:	78 0d 40 b9	ldr	w24, [x11, #0xc]
10117fa28:	d6 fb ff 17	b	0x10117e980
10117fa2c:	49 05 00 11	add	w9, w10, #0x1
10117fa30:	ea b3 40 f9	ldr	x10, [sp, #0x160]
10117fa34:	4a 01 40 f9	ldr	x10, [x10]
10117fa38:	0c 03 80 52	mov	w12, #0x18
10117fa3c:	29 29 ac 9b	umaddl	x9, w9, w12, x10
10117fa40:	29 0d 40 b9	ldr	w9, [x9, #0xc]
10117fa44:	e9 3b 01 b9	str	w9, [sp, #0x138]
10117fa48:	45 fc ff 17	b	0x10117eb5c
10117fa4c:	28 05 00 11	add	w8, w9, #0x1
10117fa50:	e9 b3 40 f9	ldr	x9, [sp, #0x160]
10117fa54:	29 01 40 f9	ldr	x9, [x9]
10117fa58:	0a 03 80 52	mov	w10, #0x18
10117fa5c:	08 25 aa 9b	umaddl	x8, w8, w10, x9
10117fa60:	08 0d 40 b9	ldr	w8, [x8, #0xc]
10117fa64:	e8 33 01 b9	str	w8, [sp, #0x130]
10117fa68:	b0 fc ff 17	b	0x10117ed28
10117fa6c:	68 05 40 b9	ldr	w8, [x11, #0x4]
10117fa70:	28 05 00 b9	str	w8, [x9, #0x4]
10117fa74:	48 00 80 52	mov	w8, #0x2
10117fa78:	5f 05 00 71	cmp	w10, #0x1
10117fa7c:	c0 e4 ff 54	b.eq	0x10117f714
10117fa80:	ec 0b 41 f9	ldr	x12, [sp, #0x210]
10117fa84:	8e b5 40 29	ldp	w14, w13, [x12, #0x4]
10117fa88:	ae 01 0e 4b	sub	w14, w13, w14
10117fa8c:	df 15 00 71	cmp	w14, #0x5
10117fa90:	0b 01 00 54	b.lt	0x10117fab0
10117fa94:	8c 01 40 b9	ldr	w12, [x12]
10117fa98:	ac 01 0c 4b	sub	w12, w13, w12
10117fa9c:	9f 15 00 71	cmp	w12, #0x5
10117faa0:	8b 00 00 54	b.lt	0x10117fab0
10117faa4:	6c 09 40 b9	ldr	w12, [x11, #0x8]
10117faa8:	2c 59 28 b8	str	w12, [x9, w8, uxtw #2]
10117faac:	08 05 00 11	add	w8, w8, #0x1
10117fab0:	5f 09 00 71	cmp	w10, #0x2
10117fab4:	00 e3 ff 54	b.eq	0x10117f714
10117fab8:	ec 0b 41 f9	ldr	x12, [sp, #0x210]
10117fabc:	8e 35 41 29	ldp	w14, w13, [x12, #0x8]
10117fac0:	ae 01 0e 4b	sub	w14, w13, w14
10117fac4:	df 15 00 71	cmp	w14, #0x5
10117fac8:	8b 01 00 54	b.lt	0x10117faf8
10117facc:	8e 05 40 b9	ldr	w14, [x12, #0x4]
10117fad0:	ae 01 0e 4b	sub	w14, w13, w14
10117fad4:	df 15 00 71	cmp	w14, #0x5
10117fad8:	0b 01 00 54	b.lt	0x10117faf8
10117fadc:	8c 01 40 b9	ldr	w12, [x12]
10117fae0:	ac 01 0c 4b	sub	w12, w13, w12
10117fae4:	9f 15 00 71	cmp	w12, #0x5
10117fae8:	8b 00 00 54	b.lt	0x10117faf8
10117faec:	6c 0d 40 b9	ldr	w12, [x11, #0xc]
10117faf0:	2c 59 28 b8	str	w12, [x9, w8, uxtw #2]
10117faf4:	08 05 00 11	add	w8, w8, #0x1
10117faf8:	5f 0d 00 71	cmp	w10, #0x3
10117fafc:	c0 e0 ff 54	b.eq	0x10117f714
10117fb00:	0c 00 80 d2	mov	x12, #0x0
10117fb04:	4a 0d 00 d1	sub	x10, x10, #0x3
10117fb08:	6b 41 00 91	add	x11, x11, #0x10
10117fb0c:	04 00 00 14	b	0x10117fb1c
10117fb10:	8c 11 00 91	add	x12, x12, #0x4
10117fb14:	4a 05 00 f1	subs	x10, x10, #0x1
10117fb18:	e0 df ff 54	b.eq	0x10117f714
10117fb1c:	ed 0b 41 f9	ldr	x13, [sp, #0x210]
10117fb20:	af 01 0c 8b	add	x15, x13, x12
10117fb24:	f0 b9 41 29	ldp	w16, w14, [x15, #0xc]
10117fb28:	d0 01 10 4b	sub	w16, w14, w16
10117fb2c:	1f 16 00 71	cmp	w16, #0x5
10117fb30:	0b ff ff 54	b.lt	0x10117fb10
10117fb34:	ef 09 40 b9	ldr	w15, [x15, #0x8]
10117fb38:	cf 01 0f 4b	sub	w15, w14, w15
10117fb3c:	ff 15 00 71	cmp	w15, #0x5
10117fb40:	8b fe ff 54	b.lt	0x10117fb10
10117fb44:	af 01 0c 8b	add	x15, x13, x12
10117fb48:	ef 05 40 b9	ldr	w15, [x15, #0x4]
10117fb4c:	cf 01 0f 4b	sub	w15, w14, w15
10117fb50:	ff 15 00 71	cmp	w15, #0x5
10117fb54:	eb fd ff 54	b.lt	0x10117fb10
10117fb58:	ad 69 6c b8	ldr	w13, [x13, x12]
10117fb5c:	cd 01 0d 4b	sub	w13, w14, w13
10117fb60:	bf 15 00 71	cmp	w13, #0x5
10117fb64:	6b fd ff 54	b.lt	0x10117fb10
10117fb68:	6d 69 6c b8	ldr	w13, [x11, x12]
10117fb6c:	2d d9 28 b8	str	w13, [x9, w8, sxtw #2]
10117fb70:	08 05 00 11	add	w8, w8, #0x1
10117fb74:	e7 ff ff 17	b	0x10117fb10
10117fb78:	2b 42 00 34	cbz	w11, 0x1011803bc
10117fb7c:	6b 05 00 51	sub	w11, w11, #0x1
10117fb80:	ec b3 40 f9	ldr	x12, [sp, #0x160]
10117fb84:	8c 01 40 f9	ldr	x12, [x12]
10117fb88:	0d 03 80 52	mov	w13, #0x18
10117fb8c:	6b 31 ad 9b	umaddl	x11, w11, w13, x12
10117fb90:	6b 0d 40 b9	ldr	w11, [x11, #0xc]
10117fb94:	eb 5b 01 b9	str	w11, [sp, #0x158]
10117fb98:	58 fa ff 17	b	0x10117e4f8
10117fb9c:	2b 42 00 34	cbz	w11, 0x1011803e0
10117fba0:	6b 05 00 51	sub	w11, w11, #0x1
10117fba4:	ec b3 40 f9	ldr	x12, [sp, #0x160]
10117fba8:	8c 01 40 f9	ldr	x12, [x12]
10117fbac:	0d 03 80 52	mov	w13, #0x18
10117fbb0:	6b 31 ad 9b	umaddl	x11, w11, w13, x12
10117fbb4:	78 0d 40 b9	ldr	w24, [x11, #0xc]
10117fbb8:	72 fb ff 17	b	0x10117e980
10117fbbc:	0a 71 7d 92	and	x10, x8, #0xfffffff8
10117fbc0:	2b 81 00 91	add	x11, x9, #0x20
10117fbc4:	00 e4 00 6f	movi.2d	v0, #0000000000000000
10117fbc8:	ec 03 0a aa	mov	x12, x10
10117fbcc:	01 e4 00 6f	movi.2d	v1, #0000000000000000
10117fbd0:	02 e4 00 6f	movi.2d	v2, #0000000000000000
10117fbd4:	03 e4 00 6f	movi.2d	v3, #0000000000000000
10117fbd8:	64 15 7f ad	ldp	q4, q5, [x11, #-0x20]
10117fbdc:	66 1d c2 ac	ldp	q6, q7, [x11], #0x40
10117fbe0:	00 c4 64 4e	fmaxnm.2d	v0, v0, v4
10117fbe4:	21 c4 65 4e	fmaxnm.2d	v1, v1, v5
10117fbe8:	42 c4 66 4e	fmaxnm.2d	v2, v2, v6
10117fbec:	63 c4 67 4e	fmaxnm.2d	v3, v3, v7
10117fbf0:	8c 21 00 f1	subs	x12, x12, #0x8
10117fbf4:	21 ff ff 54	b.ne	0x10117fbd8
10117fbf8:	00 c4 61 4e	fmaxnm.2d	v0, v0, v1
10117fbfc:	00 c4 62 4e	fmaxnm.2d	v0, v0, v2
10117fc00:	00 c4 63 4e	fmaxnm.2d	v0, v0, v3
10117fc04:	00 c8 70 7e	fmaxnmp.2d	d0, v0
10117fc08:	5f 01 08 eb	cmp	x10, x8
10117fc0c:	e0 00 00 54	b.eq	0x10117fc28
10117fc10:	29 0d 0a 8b	add	x9, x9, x10, lsl #3
10117fc14:	0a 01 0a cb	sub	x10, x8, x10
10117fc18:	21 85 40 fc	ldr	d1, [x9], #0x8
10117fc1c:	00 68 61 1e	fmaxnm	d0, d0, d1
10117fc20:	4a 05 00 f1	subs	x10, x10, #0x1
10117fc24:	a1 ff ff 54	b.ne	0x10117fc18
10117fc28:	01 c0 60 1e	fabs	d1, d0
10117fc2c:	09 96 e7 d2	mov	x9, #0x3cb0000000000000
10117fc30:	22 01 67 9e	fmov	d2, x9
10117fc34:	20 20 62 1e	fcmp	d1, d2
10117fc38:	e9 c7 9f 1a	cset	w9, le
10117fc3c:	29 01 16 2a	orr	w9, w9, w22
10117fc40:	e2 17 c0 3d	ldr	q2, [sp, #0x50]
10117fc44:	09 06 00 37	tbnz	w9, #0x0, 0x10117fd04
10117fc48:	e9 8f 41 f9	ldr	x9, [sp, #0x318]
10117fc4c:	ea a3 40 f9	ldr	x10, [sp, #0x140]
10117fc50:	5f 21 00 71	cmp	w10, #0x8
10117fc54:	42 02 00 54	b.hs	0x10117fc9c
10117fc58:	0a 00 80 d2	mov	x10, #0x0
10117fc5c:	21 00 00 14	b	0x10117fce0
10117fc60:	ce 05 00 11	add	w14, w14, #0x1
10117fc64:	dc fe ff 17	b	0x10117f7d4
10117fc68:	f6 03 15 aa	mov	x22, x21
10117fc6c:	ce 05 00 11	add	w14, w14, #0x1
10117fc70:	dd fe ff 17	b	0x10117f7e4
10117fc74:	ad 05 00 11	add	w13, w13, #0x1
10117fc78:	d7 fe ff 17	b	0x10117f7d4
10117fc7c:	f6 03 15 aa	mov	x22, x21
10117fc80:	ad 05 00 11	add	w13, w13, #0x1
10117fc84:	d8 fe ff 17	b	0x10117f7e4
10117fc88:	ef 05 00 11	add	w15, w15, #0x1
10117fc8c:	d2 fe ff 17	b	0x10117f7d4
10117fc90:	f6 03 15 aa	mov	x22, x21
10117fc94:	ef 05 00 11	add	w15, w15, #0x1
10117fc98:	d3 fe ff 17	b	0x10117f7e4
10117fc9c:	0a 71 7d 92	and	x10, x8, #0xfffffff8
10117fca0:	01 04 08 4e	dup.2d	v1, v0[0]
10117fca4:	41 fc 61 6e	fdiv.2d	v1, v2, v1
10117fca8:	2b 81 00 91	add	x11, x9, #0x20
10117fcac:	ec 03 0a aa	mov	x12, x10
10117fcb0:	62 0d 7f ad	ldp	q2, q3, [x11, #-0x20]
10117fcb4:	64 15 40 ad	ldp	q4, q5, [x11]
10117fcb8:	42 dc 61 6e	fmul.2d	v2, v2, v1
10117fcbc:	63 dc 61 6e	fmul.2d	v3, v3, v1
10117fcc0:	84 dc 61 6e	fmul.2d	v4, v4, v1
10117fcc4:	a5 dc 61 6e	fmul.2d	v5, v5, v1
10117fcc8:	62 0d 3f ad	stp	q2, q3, [x11, #-0x20]
10117fccc:	64 15 82 ac	stp	q4, q5, [x11], #0x40
10117fcd0:	8c 21 00 f1	subs	x12, x12, #0x8
10117fcd4:	e1 fe ff 54	b.ne	0x10117fcb0
10117fcd8:	5f 01 08 eb	cmp	x10, x8
10117fcdc:	40 01 00 54	b.eq	0x10117fd04
10117fce0:	01 10 6e 1e	fmov	d1, #1.00000000
10117fce4:	29 0d 0a 8b	add	x9, x9, x10, lsl #3
10117fce8:	08 01 0a cb	sub	x8, x8, x10
10117fcec:	20 18 60 1e	fdiv	d0, d1, d0
10117fcf0:	21 01 40 fd	ldr	d1, [x9]
10117fcf4:	21 08 60 1e	fmul	d1, d1, d0
10117fcf8:	21 85 00 fc	str	d1, [x9], #0x8
10117fcfc:	08 05 00 f1	subs	x8, x8, #0x1
10117fd00:	81 ff ff 54	b.ne	0x10117fcf0
10117fd04:	e0 c3 06 91	add	x0, sp, #0x1b0
10117fd08:	f5 a3 40 f9	ldr	x21, [sp, #0x140]
10117fd0c:	e1 03 15 aa	mov	x1, x21
10117fd10:	90 08 00 94	bl	__ZNSt3__16vectorIiNS_9allocatorIiEEEC1Em
10117fd14:	e0 63 06 91	add	x0, sp, #0x198
10117fd18:	e1 03 15 aa	mov	x1, x21
10117fd1c:	8d 08 00 94	bl	__ZNSt3__16vectorIiNS_9allocatorIiEEEC1Em
10117fd20:	e0 03 06 91	add	x0, sp, #0x180
10117fd24:	e1 8b 40 f9	ldr	x1, [sp, #0x110]
10117fd28:	32 08 00 94	bl	__ZNSt3__16vectorIdNS_9allocatorIdEEEC1Em
10117fd2c:	7f 06 00 31	cmn	w19, #0x1
10117fd30:	8b 04 00 54	b.lt	0x10117fdc0
10117fd34:	08 00 80 d2	mov	x8, #0x0
10117fd38:	eb 8f 41 f9	ldr	x11, [sp, #0x318]
10117fd3c:	ea c3 40 f9	ldr	x10, [sp, #0x180]
10117fd40:	3f 07 00 71	cmp	w25, #0x1
10117fd44:	29 c7 9f 1a	csinc	w9, w25, wzr, gt
10117fd48:	3f 21 00 71	cmp	w9, #0x8
10117fd4c:	83 02 00 54	b.lo	0x10117fd9c
10117fd50:	4c 01 0b cb	sub	x12, x10, x11
10117fd54:	9f 01 01 f1	cmp	x12, #0x40
10117fd58:	23 02 00 54	b.lo	0x10117fd9c
10117fd5c:	28 6d 7d 92	and	x8, x9, #0x7ffffff8
10117fd60:	4c 81 00 91	add	x12, x10, #0x20
10117fd64:	6d 81 00 91	add	x13, x11, #0x20
10117fd68:	ee 03 08 aa	mov	x14, x8
10117fd6c:	a0 05 7f ad	ldp	q0, q1, [x13, #-0x20]
10117fd70:	a2 0d c2 ac	ldp	q2, q3, [x13], #0x40
10117fd74:	00 f8 e0 4e	fabs.2d	v0, v0
10117fd78:	21 f8 e0 4e	fabs.2d	v1, v1
10117fd7c:	42 f8 e0 4e	fabs.2d	v2, v2
10117fd80:	63 f8 e0 4e	fabs.2d	v3, v3
10117fd84:	80 05 3f ad	stp	q0, q1, [x12, #-0x20]
10117fd88:	82 0d 82 ac	stp	q2, q3, [x12], #0x40
10117fd8c:	ce 21 00 f1	subs	x14, x14, #0x8
10117fd90:	e1 fe ff 54	b.ne	0x10117fd6c
10117fd94:	1f 01 09 eb	cmp	x8, x9
10117fd98:	40 01 00 54	b.eq	0x10117fdc0
10117fd9c:	0c f1 7d d3	lsl	x12, x8, #3
10117fda0:	6b 01 0c 8b	add	x11, x11, x12
10117fda4:	4a 01 0c 8b	add	x10, x10, x12
10117fda8:	28 01 08 cb	sub	x8, x9, x8
10117fdac:	60 85 40 fc	ldr	d0, [x11], #0x8
10117fdb0:	00 c0 60 1e	fabs	d0, d0
10117fdb4:	40 85 00 fc	str	d0, [x10], #0x8
10117fdb8:	08 05 00 f1	subs	x8, x8, #0x1
10117fdbc:	81 ff ff 54	b.ne	0x10117fdac
10117fdc0:	16 01 00 36	tbz	w22, #0x0, 0x10117fde0
10117fdc4:	e8 23 41 b9	ldr	w8, [sp, #0x120]
10117fdc8:	1f 05 00 71	cmp	w8, #0x1
10117fdcc:	41 04 00 54	b.ne	0x10117fe54
10117fdd0:	28 7f 01 53	lsr	w8, w25, #1
10117fdd4:	e9 c3 40 f9	ldr	x9, [sp, #0x180]
10117fdd8:	20 59 68 fc	ldr	d0, [x9, w8, uxtw #3]
10117fddc:	27 00 00 14	b	0x10117fe78
10117fde0:	0c 00 80 d2	mov	x12, #0x0
10117fde4:	e8 c3 40 f9	ldr	x8, [sp, #0x180]
10117fde8:	e9 a3 40 f9	ldr	x9, [sp, #0x140]
10117fdec:	29 7d 40 92	and	x9, x9, #0xffffffff
10117fdf0:	0a 21 00 91	add	x10, x8, #0x8
10117fdf4:	2b 00 80 52	mov	w11, #0x1
10117fdf8:	06 00 00 14	b	0x10117fe10
10117fdfc:	6b 05 00 91	add	x11, x11, #0x1
10117fe00:	4a 21 00 91	add	x10, x10, #0x8
10117fe04:	ec 03 0d aa	mov	x12, x13
10117fe08:	bf 01 09 eb	cmp	x13, x9
10117fe0c:	c0 fd ff 54	b.eq	0x10117fdc4
10117fe10:	8d 05 00 91	add	x13, x12, #0x1
10117fe14:	3f 03 0d 6b	cmp	w25, w13
10117fe18:	2d ff ff 54	b.le	0x10117fdfc
10117fe1c:	ee 03 19 aa	mov	x14, x25
10117fe20:	ef 03 0a aa	mov	x15, x10
10117fe24:	05 00 00 14	b	0x10117fe38
10117fe28:	ef 21 00 91	add	x15, x15, #0x8
10117fe2c:	ce 05 00 d1	sub	x14, x14, #0x1
10117fe30:	7f 01 0e eb	cmp	x11, x14
10117fe34:	40 fe ff 54	b.eq	0x10117fdfc
10117fe38:	00 79 6c fc	ldr	d0, [x8, x12, lsl #3]
10117fe3c:	e1 01 40 fd	ldr	d1, [x15]
10117fe40:	00 20 61 1e	fcmp	d0, d1
10117fe44:	2a ff ff 54	b.ge	0x10117fe28
10117fe48:	01 79 2c fc	str	d1, [x8, x12, lsl #3]
10117fe4c:	e0 01 00 fd	str	d0, [x15]
10117fe50:	f6 ff ff 17	b	0x10117fe28
10117fe54:	3f 03 00 71	cmp	w25, #0x0
10117fe58:	28 a7 99 1a	cinc	w8, w25, lt
10117fe5c:	08 7d 01 13	asr	w8, w8, #1
10117fe60:	e9 c3 40 f9	ldr	x9, [sp, #0x180]
10117fe64:	28 cd 28 8b	add	x8, x9, w8, sxtw #3
10117fe68:	00 85 7f 6d	ldp	d0, d1, [x8, #-0x8]
10117fe6c:	20 28 60 1e	fadd	d0, d1, d0
10117fe70:	01 10 6c 1e	fmov	d1, #0.50000000
10117fe74:	00 08 61 1e	fmul	d0, d0, d1
10117fe78:	f9 b3 40 f9	ldr	x25, [sp, #0x160]
10117fe7c:	76 00 00 36	tbz	w22, #0x0, 0x10117fe88
10117fe80:	15 00 80 52	mov	w21, #0x0
10117fe84:	2f 00 00 14	b	0x10117ff40
10117fe88:	09 00 80 52	mov	w9, #0x0
10117fe8c:	ea 8f 41 f9	ldr	x10, [sp, #0x318]
10117fe90:	e8 e7 01 b2	mov	x8, #-0x6666666666666667
10117fe94:	48 33 93 f2	movk	x8, #0x999a
10117fe98:	28 f9 e7 f2	movk	x8, #0x3fc9, lsl #48
10117fe9c:	01 01 67 9e	fmov	d1, x8
10117fea0:	01 28 61 1e	fadd	d1, d0, d1
10117fea4:	eb db 40 f9	ldr	x11, [sp, #0x1b0]
10117fea8:	ec cf 40 f9	ldr	x12, [sp, #0x198]
10117feac:	e8 a3 40 f9	ldr	x8, [sp, #0x140]
10117feb0:	1f 05 00 71	cmp	w8, #0x1
10117feb4:	08 c5 9f 1a	csinc	w8, w8, wzr, gt
10117feb8:	ed 03 08 cb	neg	x13, x8
10117febc:	2e 00 80 52	mov	w14, #0x1
10117fec0:	8f 01 80 52	mov	w15, #0xc
10117fec4:	0a 00 00 14	b	0x10117feec
10117fec8:	31 03 40 f9	ldr	x17, [x25]
10117fecc:	31 6a 6f b8	ldr	w17, [x17, x15]
10117fed0:	91 79 30 b8	str	w17, [x12, x16, lsl #2]
10117fed4:	29 05 00 11	add	w9, w9, #0x1
10117fed8:	ce 05 00 91	add	x14, x14, #0x1
10117fedc:	ef 61 00 91	add	x15, x15, #0x18
10117fee0:	b0 01 0e 8b	add	x16, x13, x14
10117fee4:	1f 06 00 f1	cmp	x16, #0x1
10117fee8:	20 02 00 54	b.eq	0x10117ff2c
10117feec:	42 79 6e fc	ldr	d2, [x10, x14, lsl #3]
10117fef0:	40 20 61 1e	fcmp	d2, d1
10117fef4:	2d ff ff 54	b.le	0x10117fed8
10117fef8:	30 7d 40 93	sxtw	x16, w9
10117fefc:	6e d9 29 b8	str	w14, [x11, w9, sxtw #2]
10117ff00:	df 01 1a eb	cmp	x14, x26
10117ff04:	2d fe ff 54	b.le	0x10117fec8
10117ff08:	31 03 40 f9	ldr	x17, [x25]
10117ff0c:	31 02 0f 8b	add	x17, x17, x15
10117ff10:	31 82 5e b8	ldur	w17, [x17, #-0x18]
10117ff14:	20 06 00 11	add	w0, w17, #0x1
10117ff18:	80 79 30 b8	str	w0, [x12, x16, lsl #2]
10117ff1c:	3f 12 00 71	cmp	w17, #0x4
10117ff20:	ab fd ff 54	b.lt	0x10117fed4
10117ff24:	31 0e 00 51	sub	w17, w17, #0x3
10117ff28:	ea ff ff 17	b	0x10117fed0
10117ff2c:	3f 11 00 71	cmp	w9, #0x4
10117ff30:	35 c1 9f 1a	csel	w21, w9, wzr, gt
10117ff34:	e9 d7 9f 1a	cset	w9, gt
10117ff38:	29 01 16 2a	orr	w9, w9, w22
10117ff3c:	c9 02 00 36	tbz	w9, #0x0, 0x10117ff94
10117ff40:	e8 03 15 aa	mov	x8, x21
10117ff44:	01 7d 40 93	sxtw	x1, w8
10117ff48:	e0 a3 05 91	add	x0, sp, #0x168
10117ff4c:	01 08 00 94	bl	__ZNSt3__16vectorIiNS_9allocatorIiEEEC1Em
10117ff50:	bf 02 00 71	cmp	w21, #0x0
10117ff54:	6d 0f 00 54	b.le	0x101180140
10117ff58:	e8 cf 40 f9	ldr	x8, [sp, #0x198]
10117ff5c:	08 01 40 b9	ldr	w8, [x8]
10117ff60:	e9 b7 40 f9	ldr	x9, [sp, #0x168]
10117ff64:	28 01 00 b9	str	w8, [x9]
10117ff68:	aa 06 00 71	subs	w10, w21, #0x1
10117ff6c:	a0 0e 00 54	b.eq	0x101180140
10117ff70:	eb cf 40 f9	ldr	x11, [sp, #0x198]
10117ff74:	e9 b7 40 f9	ldr	x9, [sp, #0x168]
10117ff78:	e8 db 40 f9	ldr	x8, [sp, #0x1b0]
10117ff7c:	08 31 40 29	ldp	w8, w12, [x8]
10117ff80:	88 01 08 4b	sub	w8, w12, w8
10117ff84:	1f 15 00 71	cmp	w8, #0x5
10117ff88:	4a 05 00 54	b.ge	0x101180030
10117ff8c:	28 00 80 52	mov	w8, #0x1
10117ff90:	2b 00 00 14	b	0x10118003c
10117ff94:	0c 00 80 d2	mov	x12, #0x0
10117ff98:	15 00 80 52	mov	w21, #0x0
10117ff9c:	e9 8f 41 f9	ldr	x9, [sp, #0x318]
10117ffa0:	ea e7 01 b2	mov	x10, #-0x6666666666666667
10117ffa4:	4a 33 93 f2	movk	x10, #0x999a
10117ffa8:	2a f7 e7 f2	movk	x10, #0x3fb9, lsl #48
10117ffac:	41 01 67 9e	fmov	d1, x10
10117ffb0:	00 28 61 1e	fadd	d0, d0, d1
10117ffb4:	ea db 40 f9	ldr	x10, [sp, #0x1b0]
10117ffb8:	eb cf 40 f9	ldr	x11, [sp, #0x198]
10117ffbc:	88 41 28 cb	sub	x8, x12, w8, uxtw
10117ffc0:	2c 00 80 52	mov	w12, #0x1
10117ffc4:	8d 01 80 52	mov	w13, #0xc
10117ffc8:	0a 00 00 14	b	0x10117fff0
10117ffcc:	2f 03 40 f9	ldr	x15, [x25]
10117ffd0:	ef 69 6d b8	ldr	w15, [x15, x13]
10117ffd4:	6f 79 2e b8	str	w15, [x11, x14, lsl #2]
10117ffd8:	b5 06 00 11	add	w21, w21, #0x1
10117ffdc:	8c 05 00 91	add	x12, x12, #0x1
10117ffe0:	ad 61 00 91	add	x13, x13, #0x18
10117ffe4:	0e 01 0c 8b	add	x14, x8, x12
10117ffe8:	df 05 00 f1	cmp	x14, #0x1
10117ffec:	a0 fa ff 54	b.eq	0x10117ff40
10117fff0:	21 79 6c fc	ldr	d1, [x9, x12, lsl #3]
10117fff4:	20 20 60 1e	fcmp	d1, d0
10117fff8:	2d ff ff 54	b.le	0x10117ffdc
10117fffc:	ae 7e 40 93	sxtw	x14, w21
101180000:	4c d9 35 b8	str	w12, [x10, w21, sxtw #2]
101180004:	9f 01 1a eb	cmp	x12, x26
101180008:	2d fe ff 54	b.le	0x10117ffcc
10118000c:	2f 03 40 f9	ldr	x15, [x25]
101180010:	ef 01 0d 8b	add	x15, x15, x13
101180014:	ef 81 5e b8	ldur	w15, [x15, #-0x18]
101180018:	f0 05 00 11	add	w16, w15, #0x1
10118001c:	70 79 2e b8	str	w16, [x11, x14, lsl #2]
101180020:	ff 11 00 71	cmp	w15, #0x4
101180024:	ab fd ff 54	b.lt	0x10117ffd8
101180028:	ef 0d 00 51	sub	w15, w15, #0x3
10118002c:	ea ff ff 17	b	0x10117ffd4
101180030:	68 05 40 b9	ldr	w8, [x11, #0x4]
101180034:	28 05 00 b9	str	w8, [x9, #0x4]
101180038:	48 00 80 52	mov	w8, #0x2
10118003c:	5f 05 00 71	cmp	w10, #0x1
101180040:	20 04 00 54	b.eq	0x1011800c4
101180044:	ec db 40 f9	ldr	x12, [sp, #0x1b0]
101180048:	8e b5 40 29	ldp	w14, w13, [x12, #0x4]
10118004c:	ae 01 0e 4b	sub	w14, w13, w14
101180050:	df 15 00 71	cmp	w14, #0x5
101180054:	0b 01 00 54	b.lt	0x101180074
101180058:	8c 01 40 b9	ldr	w12, [x12]
10118005c:	ac 01 0c 4b	sub	w12, w13, w12
101180060:	9f 15 00 71	cmp	w12, #0x5
101180064:	8b 00 00 54	b.lt	0x101180074
101180068:	6c 09 40 b9	ldr	w12, [x11, #0x8]
10118006c:	2c 59 28 b8	str	w12, [x9, w8, uxtw #2]
101180070:	08 05 00 11	add	w8, w8, #0x1
101180074:	5f 09 00 71	cmp	w10, #0x2
101180078:	60 02 00 54	b.eq	0x1011800c4
10118007c:	ec db 40 f9	ldr	x12, [sp, #0x1b0]
101180080:	8e 35 41 29	ldp	w14, w13, [x12, #0x8]
101180084:	ae 01 0e 4b	sub	w14, w13, w14
101180088:	df 15 00 71	cmp	w14, #0x5
10118008c:	8b 01 00 54	b.lt	0x1011800bc
101180090:	8e 05 40 b9	ldr	w14, [x12, #0x4]
101180094:	ae 01 0e 4b	sub	w14, w13, w14
101180098:	df 15 00 71	cmp	w14, #0x5
10118009c:	0b 01 00 54	b.lt	0x1011800bc
1011800a0:	8c 01 40 b9	ldr	w12, [x12]
1011800a4:	ac 01 0c 4b	sub	w12, w13, w12
1011800a8:	9f 15 00 71	cmp	w12, #0x5
1011800ac:	8b 00 00 54	b.lt	0x1011800bc
1011800b0:	6c 0d 40 b9	ldr	w12, [x11, #0xc]
1011800b4:	2c 59 28 b8	str	w12, [x9, w8, uxtw #2]
1011800b8:	08 05 00 11	add	w8, w8, #0x1
1011800bc:	5f 0d 00 71	cmp	w10, #0x3
1011800c0:	41 34 00 54	b.ne	0x101180748
1011800c4:	1f 05 00 71	cmp	w8, #0x1
1011800c8:	cd 03 00 54	b.le	0x101180140
1011800cc:	0d 00 80 d2	mov	x13, #0x0
1011800d0:	0c 00 80 52	mov	w12, #0x0
1011800d4:	0b 00 80 52	mov	w11, #0x0
1011800d8:	0a 00 80 52	mov	w10, #0x0
1011800dc:	09 00 80 52	mov	w9, #0x0
1011800e0:	e0 b7 40 f9	ldr	x0, [sp, #0x168]
1011800e4:	e8 03 08 2a	mov	w8, w8
1011800e8:	08 f5 7e d3	lsl	x8, x8, #2
1011800ec:	4e 32 01 90	adrp	x14, 9800 ; 0x1037c8000
1011800f0:	ce 29 09 91	add	x14, x14, #0x24a
1011800f4:	05 00 00 14	b	0x101180108
1011800f8:	4a 05 00 11	add	w10, w10, #0x1
1011800fc:	ad 11 00 91	add	x13, x13, #0x4
101180100:	1f 01 0d eb	cmp	x8, x13
101180104:	80 02 00 54	b.eq	0x101180154
101180108:	0f 68 6d b8	ldr	w15, [x0, x13]
10118010c:	ef 05 00 51	sub	w15, w15, #0x1
101180110:	ff 0d 00 71	cmp	w15, #0x3
101180114:	48 ff ff 54	b.hi	0x1011800fc
101180118:	10 ff ff 10	adr	x16, #-32
10118011c:	d1 69 6f 38	ldrb	w17, [x14, x15]
101180120:	10 0a 11 8b	add	x16, x16, x17, lsl #2
101180124:	00 02 1f d6	br	x16
101180128:	8c 05 00 11	add	w12, w12, #0x1
10118012c:	f4 ff ff 17	b	0x1011800fc
101180130:	29 05 00 11	add	w9, w9, #0x1
101180134:	f2 ff ff 17	b	0x1011800fc
101180138:	6b 05 00 11	add	w11, w11, #0x1
10118013c:	f0 ff ff 17	b	0x1011800fc
101180140:	0c 00 80 52	mov	w12, #0x0
101180144:	0b 00 80 52	mov	w11, #0x0
101180148:	0a 00 80 52	mov	w10, #0x0
10118014c:	09 00 80 52	mov	w9, #0x0
101180150:	e0 b7 40 f9	ldr	x0, [sp, #0x168]
101180154:	9f 01 00 71	cmp	w12, #0x0
101180158:	88 c1 9f 1a	csel	w8, w12, wzr, gt
10118015c:	ec d7 9f 1a	cset	w12, gt
101180160:	1f 01 0b 6b	cmp	w8, w11
101180164:	08 c1 8b 1a	csel	w8, w8, w11, gt
101180168:	4b 00 80 52	mov	w11, #0x2
10118016c:	6b b1 8c 1a	csel	w11, w11, w12, lt
101180170:	1f 01 0a 6b	cmp	w8, w10
101180174:	08 c1 8a 1a	csel	w8, w8, w10, gt
101180178:	6a 00 80 52	mov	w10, #0x3
10118017c:	4a b1 8b 1a	csel	w10, w10, w11, lt
101180180:	8b 00 80 52	mov	w11, #0x4
101180184:	1f 01 09 6b	cmp	w8, w9
101180188:	75 b1 8a 1a	csel	w21, w11, w10, lt
10118018c:	60 00 00 b4	cbz	x0, 0x101180198
101180190:	e0 bb 00 f9	str	x0, [sp, #0x170]
101180194:	49 46 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
101180198:	e0 c3 40 f9	ldr	x0, [sp, #0x180]
10118019c:	60 00 00 b4	cbz	x0, 0x1011801a8
1011801a0:	e0 c7 00 f9	str	x0, [sp, #0x188]
1011801a4:	45 46 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
1011801a8:	e0 cf 40 f9	ldr	x0, [sp, #0x198]
1011801ac:	60 00 00 b4	cbz	x0, 0x1011801b8
1011801b0:	e0 d3 00 f9	str	x0, [sp, #0x1a0]
1011801b4:	41 46 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
1011801b8:	e0 db 40 f9	ldr	x0, [sp, #0x1b0]
1011801bc:	60 00 00 b4	cbz	x0, 0x1011801c8
1011801c0:	e0 df 00 f9	str	x0, [sp, #0x1b8]
1011801c4:	3d 46 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
1011801c8:	e8 3b 41 b9	ldr	w8, [sp, #0x138]
1011801cc:	1f 09 00 71	cmp	w8, #0x2
1011801d0:	68 00 80 52	mov	w8, #0x3
1011801d4:	09 b1 9f 5a	csinv	w9, w8, wzr, lt
1011801d8:	ea 33 41 b9	ldr	w10, [sp, #0x130]
1011801dc:	5f 09 00 71	cmp	w10, #0x2
1011801e0:	08 b1 9f 5a	csinv	w8, w8, wzr, lt
1011801e4:	94 00 00 34	cbz	w20, 0x1011801f4
1011801e8:	7b 00 00 35	cbnz	w27, 0x1011801f4
1011801ec:	5c 00 00 35	cbnz	w28, 0x1011801f4
1011801f0:	78 1d 00 34	cbz	w24, 0x10118059c
1011801f4:	94 01 00 35	cbnz	w20, 0x101180224
1011801f8:	7b 01 00 34	cbz	w27, 0x101180224
1011801fc:	5c 01 00 35	cbnz	w28, 0x101180224
101180200:	38 01 00 35	cbnz	w24, 0x101180224
101180204:	7f 06 00 71	cmp	w19, #0x1
101180208:	ab 1c 00 54	b.lt	0x10118059c
10118020c:	29 03 40 f9	ldr	x9, [x25]
101180210:	68 7e 40 92	and	x8, x19, #0xffffffff
101180214:	1f 11 00 f1	cmp	x8, #0x4
101180218:	e2 03 00 54	b.hs	0x101180294
10118021c:	0a 00 80 d2	mov	x10, #0x0
101180220:	3a 00 00 14	b	0x101180308
101180224:	8b 02 1b 2a	orr	w11, w20, w27
101180228:	7f 01 00 71	cmp	w11, #0x0
10118022c:	ea 17 9f 1a	cset	w10, eq
101180230:	6b 01 00 35	cbnz	w11, 0x10118025c
101180234:	5c 01 00 34	cbz	w28, 0x10118025c
101180238:	38 01 00 35	cbnz	w24, 0x10118025c
10118023c:	7f 06 00 71	cmp	w19, #0x1
101180240:	eb 1a 00 54	b.lt	0x10118059c
101180244:	29 03 40 f9	ldr	x9, [x25]
101180248:	68 7e 40 92	and	x8, x19, #0xffffffff
10118024c:	1f 11 00 f1	cmp	x8, #0x4
101180250:	42 10 00 54	b.hs	0x101180458
101180254:	0a 00 80 d2	mov	x10, #0x0
101180258:	9d 00 00 14	b	0x1011804cc
10118025c:	9f 03 00 71	cmp	w28, #0x0
101180260:	eb 17 9f 1a	cset	w11, eq
101180264:	4a 01 0b 0a	and	w10, w10, w11
101180268:	5f 05 00 71	cmp	w10, #0x1
10118026c:	81 06 00 54	b.ne	0x10118033c
101180270:	78 06 00 34	cbz	w24, 0x10118033c
101180274:	7f 06 00 71	cmp	w19, #0x1
101180278:	2b 19 00 54	b.lt	0x10118059c
10118027c:	29 03 40 f9	ldr	x9, [x25]
101180280:	68 7e 40 92	and	x8, x19, #0xffffffff
101180284:	1f 11 00 f1	cmp	x8, #0x4
101180288:	c2 13 00 54	b.hs	0x101180500
10118028c:	0a 00 80 d2	mov	x10, #0x0
101180290:	b8 00 00 14	b	0x101180570
101180294:	6b 06 40 92	and	x11, x19, #0x3
101180298:	0a 01 0b cb	sub	x10, x8, x11
10118029c:	2c f1 00 91	add	x12, x9, #0x3c
1011802a0:	6d 00 80 52	mov	w13, #0x3
1011802a4:	ee 03 0a aa	mov	x14, x10
1011802a8:	8f 01 5d b8	ldur	w15, [x12, #-0x30]
1011802ac:	90 81 5e b8	ldur	w16, [x12, #-0x18]
1011802b0:	91 01 40 b9	ldr	w17, [x12]
1011802b4:	80 19 40 b9	ldr	w0, [x12, #0x18]
1011802b8:	ff 09 00 71	cmp	w15, #0x2
1011802bc:	a1 b1 9f 5a	csinv	w1, w13, wzr, lt
1011802c0:	1f 0a 00 71	cmp	w16, #0x2
1011802c4:	a2 b1 9f 5a	csinv	w2, w13, wzr, lt
1011802c8:	3f 0a 00 71	cmp	w17, #0x2
1011802cc:	a3 b1 9f 5a	csinv	w3, w13, wzr, lt
1011802d0:	1f 08 00 71	cmp	w0, #0x2
1011802d4:	a4 b1 9f 5a	csinv	w4, w13, wzr, lt
1011802d8:	ef 01 01 0b	add	w15, w15, w1
1011802dc:	10 02 02 0b	add	w16, w16, w2
1011802e0:	31 02 03 0b	add	w17, w17, w3
1011802e4:	8f 01 1d b8	stur	w15, [x12, #-0x30]
1011802e8:	90 81 1e b8	stur	w16, [x12, #-0x18]
1011802ec:	0f 00 04 0b	add	w15, w0, w4
1011802f0:	91 01 00 b9	str	w17, [x12]
1011802f4:	8f 19 00 b9	str	w15, [x12, #0x18]
1011802f8:	8c 81 01 91	add	x12, x12, #0x60
1011802fc:	ce 11 00 f1	subs	x14, x14, #0x4
101180300:	41 fd ff 54	b.ne	0x1011802a8
101180304:	cb 14 00 b4	cbz	x11, 0x10118059c
101180308:	0b 03 80 52	mov	w11, #0x18
10118030c:	49 25 0b 9b	madd	x9, x10, x11, x9
101180310:	29 31 00 91	add	x9, x9, #0xc
101180314:	08 01 0a cb	sub	x8, x8, x10
101180318:	6a 00 80 52	mov	w10, #0x3
10118031c:	2b 01 40 b9	ldr	w11, [x9]
101180320:	7f 09 00 71	cmp	w11, #0x2
101180324:	4c b1 9f 5a	csinv	w12, w10, wzr, lt
101180328:	6b 01 0c 0b	add	w11, w11, w12
10118032c:	2b 85 01 b8	str	w11, [x9], #0x18
101180330:	08 05 00 f1	subs	x8, x8, #0x1
101180334:	41 ff ff 54	b.ne	0x10118031c
101180338:	99 00 00 14	b	0x10118059c
10118033c:	ea 0b 41 b9	ldr	w10, [sp, #0x108]
101180340:	5f 01 00 71	cmp	w10, #0x0
101180344:	ea 03 41 b9	ldr	w10, [sp, #0x100]
101180348:	44 19 40 7a	ccmp	w10, #0x0, #0x4, ne
10118034c:	01 01 00 54	b.ne	0x10118036c
101180350:	f4 00 00 34	cbz	w20, 0x10118036c
101180354:	7f 07 00 71	cmp	w27, #0x1
101180358:	ac 00 00 54	b.gt	0x10118036c
10118035c:	9f 07 00 71	cmp	w28, #0x1
101180360:	6c 00 00 54	b.gt	0x10118036c
101180364:	1f 0b 00 71	cmp	w24, #0x2
101180368:	ab 11 00 54	b.lt	0x10118059c
10118036c:	ea 0b 41 b9	ldr	w10, [sp, #0x108]
101180370:	5f 05 00 71	cmp	w10, #0x1
101180374:	ea 03 41 b9	ldr	w10, [sp, #0x100]
101180378:	44 19 41 7a	ccmp	w10, #0x1, #0x4, ne
10118037c:	21 22 00 54	b.ne	0x1011807c0
101180380:	9f 06 00 71	cmp	w20, #0x1
101180384:	ec 21 00 54	b.gt	0x1011807c0
101180388:	db 21 00 34	cbz	w27, 0x1011807c0
10118038c:	9f 07 00 71	cmp	w28, #0x1
101180390:	8c 21 00 54	b.gt	0x1011807c0
101180394:	1f 07 00 71	cmp	w24, #0x1
101180398:	4c 21 00 54	b.gt	0x1011807c0
10118039c:	7f 06 00 71	cmp	w19, #0x1
1011803a0:	eb 0f 00 54	b.lt	0x10118059c
1011803a4:	29 03 40 f9	ldr	x9, [x25]
1011803a8:	68 7e 40 92	and	x8, x19, #0xffffffff
1011803ac:	1f 11 00 f1	cmp	x8, #0x4
1011803b0:	a2 25 00 54	b.hs	0x101180864
1011803b4:	0a 00 80 d2	mov	x10, #0x0
1011803b8:	48 01 00 14	b	0x1011808d8
1011803bc:	eb b3 40 f9	ldr	x11, [sp, #0x160]
1011803c0:	6b 01 40 f9	ldr	x11, [x11]
1011803c4:	6b 0d 40 b9	ldr	w11, [x11, #0xc]
1011803c8:	7f 09 00 71	cmp	w11, #0x2
1011803cc:	6c 00 80 52	mov	w12, #0x3
1011803d0:	8c b1 9f 5a	csinv	w12, w12, wzr, lt
1011803d4:	8b 01 0b 0b	add	w11, w12, w11
1011803d8:	eb 5b 01 b9	str	w11, [sp, #0x158]
1011803dc:	47 f8 ff 17	b	0x10117e4f8
1011803e0:	eb b3 40 f9	ldr	x11, [sp, #0x160]
1011803e4:	6b 01 40 f9	ldr	x11, [x11]
1011803e8:	6b 0d 40 b9	ldr	w11, [x11, #0xc]
1011803ec:	7f 09 00 71	cmp	w11, #0x2
1011803f0:	6c 00 80 52	mov	w12, #0x3
1011803f4:	8c b1 9f 5a	csinv	w12, w12, wzr, lt
1011803f8:	98 01 0b 0b	add	w24, w12, w11
1011803fc:	61 f9 ff 17	b	0x10117e980
101180400:	4b f1 7d 92	and	x11, x10, #0xfffffffffffffff8
101180404:	69 01 40 b2	orr	x9, x11, #0x1
101180408:	0c a0 00 91	add	x12, x0, #0x28
10118040c:	0d 81 00 91	add	x13, x8, #0x20
101180410:	ee 03 0b aa	mov	x14, x11
101180414:	a0 81 de 3c	ldur	q0, [x13, #-0x18]
101180418:	a1 81 df 3c	ldur	q1, [x13, #-0x8]
10118041c:	a2 81 c0 3c	ldur	q2, [x13, #0x8]
101180420:	a3 81 c1 3c	ldur	q3, [x13, #0x18]
101180424:	a4 15 7f ad	ldp	q4, q5, [x13, #-0x20]
101180428:	a6 1d c2 ac	ldp	q6, q7, [x13], #0x40
10118042c:	00 d4 e4 6e	fabd.2d	v0, v0, v4
101180430:	21 d4 e5 6e	fabd.2d	v1, v1, v5
101180434:	42 d4 e6 6e	fabd.2d	v2, v2, v6
101180438:	63 d4 e7 6e	fabd.2d	v3, v3, v7
10118043c:	80 05 3f ad	stp	q0, q1, [x12, #-0x20]
101180440:	82 0d 82 ac	stp	q2, q3, [x12], #0x40
101180444:	ce 21 00 f1	subs	x14, x14, #0x8
101180448:	61 fe ff 54	b.ne	0x101180414
10118044c:	5f 01 0b eb	cmp	x10, x11
101180450:	c0 12 fe 54	b.eq	0x10117c6a8
101180454:	8b f0 ff 17	b	0x10117c680
101180458:	6b 06 40 92	and	x11, x19, #0x3
10118045c:	0a 01 0b cb	sub	x10, x8, x11
101180460:	2c f1 00 91	add	x12, x9, #0x3c
101180464:	2d 00 80 12	mov	w13, #-0x2
101180468:	ee 03 0a aa	mov	x14, x10
10118046c:	8f 01 5d b8	ldur	w15, [x12, #-0x30]
101180470:	90 81 5e b8	ldur	w16, [x12, #-0x18]
101180474:	91 01 40 b9	ldr	w17, [x12]
101180478:	80 19 40 b9	ldr	w0, [x12, #0x18]
10118047c:	ff 09 00 71	cmp	w15, #0x2
101180480:	a1 c5 8d 5a	cneg	w1, w13, le
101180484:	1f 0a 00 71	cmp	w16, #0x2
101180488:	a2 c5 8d 5a	cneg	w2, w13, le
10118048c:	3f 0a 00 71	cmp	w17, #0x2
101180490:	a3 c5 8d 5a	cneg	w3, w13, le
101180494:	1f 08 00 71	cmp	w0, #0x2
101180498:	a4 c5 8d 5a	cneg	w4, w13, le
10118049c:	ef 01 01 0b	add	w15, w15, w1
1011804a0:	10 02 02 0b	add	w16, w16, w2
1011804a4:	31 02 03 0b	add	w17, w17, w3
1011804a8:	8f 01 1d b8	stur	w15, [x12, #-0x30]
1011804ac:	90 81 1e b8	stur	w16, [x12, #-0x18]
1011804b0:	0f 00 04 0b	add	w15, w0, w4
1011804b4:	91 01 00 b9	str	w17, [x12]
1011804b8:	8f 19 00 b9	str	w15, [x12, #0x18]
1011804bc:	8c 81 01 91	add	x12, x12, #0x60
1011804c0:	ce 11 00 f1	subs	x14, x14, #0x4
1011804c4:	41 fd ff 54	b.ne	0x10118046c
1011804c8:	ab 06 00 b4	cbz	x11, 0x10118059c
1011804cc:	0b 03 80 52	mov	w11, #0x18
1011804d0:	49 25 0b 9b	madd	x9, x10, x11, x9
1011804d4:	29 31 00 91	add	x9, x9, #0xc
1011804d8:	08 01 0a cb	sub	x8, x8, x10
1011804dc:	2a 00 80 12	mov	w10, #-0x2
1011804e0:	2b 01 40 b9	ldr	w11, [x9]
1011804e4:	7f 09 00 71	cmp	w11, #0x2
1011804e8:	4c c5 8a 5a	cneg	w12, w10, le
1011804ec:	6b 01 0c 0b	add	w11, w11, w12
1011804f0:	2b 85 01 b8	str	w11, [x9], #0x18
1011804f4:	08 05 00 f1	subs	x8, x8, #0x1
1011804f8:	41 ff ff 54	b.ne	0x1011804e0
1011804fc:	28 00 00 14	b	0x10118059c
101180500:	6b 06 40 92	and	x11, x19, #0x3
101180504:	0a 01 0b cb	sub	x10, x8, x11
101180508:	2c f1 00 91	add	x12, x9, #0x3c
10118050c:	ed 03 0a aa	mov	x13, x10
101180510:	8e 01 5d b8	ldur	w14, [x12, #-0x30]
101180514:	8f 81 5e b8	ldur	w15, [x12, #-0x18]
101180518:	90 01 40 b9	ldr	w16, [x12]
10118051c:	91 19 40 b9	ldr	w17, [x12, #0x18]
101180520:	c0 0d 00 51	sub	w0, w14, #0x3
101180524:	df 11 00 71	cmp	w14, #0x4
101180528:	0e a4 8e 1a	csinc	w14, w0, w14, ge
10118052c:	e0 0d 00 51	sub	w0, w15, #0x3
101180530:	ff 11 00 71	cmp	w15, #0x4
101180534:	0f a4 8f 1a	csinc	w15, w0, w15, ge
101180538:	00 0e 00 51	sub	w0, w16, #0x3
10118053c:	1f 12 00 71	cmp	w16, #0x4
101180540:	10 a4 90 1a	csinc	w16, w0, w16, ge
101180544:	20 0e 00 51	sub	w0, w17, #0x3
101180548:	3f 12 00 71	cmp	w17, #0x4
10118054c:	8e 01 1d b8	stur	w14, [x12, #-0x30]
101180550:	8f 81 1e b8	stur	w15, [x12, #-0x18]
101180554:	0e a4 91 1a	csinc	w14, w0, w17, ge
101180558:	90 01 00 b9	str	w16, [x12]
10118055c:	8e 19 00 b9	str	w14, [x12, #0x18]
101180560:	8c 81 01 91	add	x12, x12, #0x60
101180564:	ad 11 00 f1	subs	x13, x13, #0x4
101180568:	41 fd ff 54	b.ne	0x101180510
10118056c:	8b 01 00 b4	cbz	x11, 0x10118059c
101180570:	0b 03 80 52	mov	w11, #0x18
101180574:	49 25 0b 9b	madd	x9, x10, x11, x9
101180578:	29 31 00 91	add	x9, x9, #0xc
10118057c:	08 01 0a cb	sub	x8, x8, x10
101180580:	2a 01 40 b9	ldr	w10, [x9]
101180584:	4b 0d 00 51	sub	w11, w10, #0x3
101180588:	5f 11 00 71	cmp	w10, #0x4
10118058c:	6a a5 8a 1a	csinc	w10, w11, w10, ge
101180590:	2a 85 01 b8	str	w10, [x9], #0x18
101180594:	08 05 00 f1	subs	x8, x8, #0x1
101180598:	41 ff ff 54	b.ne	0x101180580
10118059c:	e0 e7 40 f9	ldr	x0, [sp, #0x1c8]
1011805a0:	60 00 00 b4	cbz	x0, 0x1011805ac
1011805a4:	e0 eb 00 f9	str	x0, [sp, #0x1d0]
1011805a8:	44 45 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
1011805ac:	e0 f3 40 f9	ldr	x0, [sp, #0x1e0]
1011805b0:	fc 97 40 f9	ldr	x28, [sp, #0x128]
1011805b4:	60 00 00 b4	cbz	x0, 0x1011805c0
1011805b8:	e0 f7 00 f9	str	x0, [sp, #0x1e8]
1011805bc:	3f 45 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
1011805c0:	e0 ff 40 f9	ldr	x0, [sp, #0x1f8]
1011805c4:	60 00 00 b4	cbz	x0, 0x1011805d0
1011805c8:	e0 03 01 f9	str	x0, [sp, #0x200]
1011805cc:	3b 45 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
1011805d0:	e0 0b 41 f9	ldr	x0, [sp, #0x210]
1011805d4:	60 00 00 b4	cbz	x0, 0x1011805e0
1011805d8:	e0 0f 01 f9	str	x0, [sp, #0x218]
1011805dc:	37 45 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
1011805e0:	e0 17 41 f9	ldr	x0, [sp, #0x228]
1011805e4:	60 00 00 b4	cbz	x0, 0x1011805f0
1011805e8:	e0 1b 01 f9	str	x0, [sp, #0x230]
1011805ec:	33 45 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
1011805f0:	e0 23 41 f9	ldr	x0, [sp, #0x240]
1011805f4:	60 00 00 b4	cbz	x0, 0x101180600
1011805f8:	e0 27 01 f9	str	x0, [sp, #0x248]
1011805fc:	2f 45 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
101180600:	e0 2f 41 f9	ldr	x0, [sp, #0x258]
101180604:	60 00 00 b4	cbz	x0, 0x101180610
101180608:	e0 33 01 f9	str	x0, [sp, #0x260]
10118060c:	2b 45 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
101180610:	e0 3b 41 f9	ldr	x0, [sp, #0x270]
101180614:	60 00 00 b4	cbz	x0, 0x101180620
101180618:	e0 3f 01 f9	str	x0, [sp, #0x278]
10118061c:	27 45 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
101180620:	e0 47 41 f9	ldr	x0, [sp, #0x288]
101180624:	60 00 00 b4	cbz	x0, 0x101180630
101180628:	e0 4b 01 f9	str	x0, [sp, #0x290]
10118062c:	23 45 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
101180630:	e0 53 41 f9	ldr	x0, [sp, #0x2a0]
101180634:	60 00 00 b4	cbz	x0, 0x101180640
101180638:	e0 57 01 f9	str	x0, [sp, #0x2a8]
10118063c:	1f 45 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
101180640:	e0 5f 41 f9	ldr	x0, [sp, #0x2b8]
101180644:	60 00 00 b4	cbz	x0, 0x101180650
101180648:	e0 63 01 f9	str	x0, [sp, #0x2c0]
10118064c:	1b 45 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
101180650:	e0 6b 41 f9	ldr	x0, [sp, #0x2d0]
101180654:	60 00 00 b4	cbz	x0, 0x101180660
101180658:	e0 6f 01 f9	str	x0, [sp, #0x2d8]
10118065c:	17 45 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
101180660:	e0 77 41 f9	ldr	x0, [sp, #0x2e8]
101180664:	60 00 00 b4	cbz	x0, 0x101180670
101180668:	e0 7b 01 f9	str	x0, [sp, #0x2f0]
10118066c:	13 45 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
101180670:	e0 83 41 f9	ldr	x0, [sp, #0x300]
101180674:	60 00 00 b4	cbz	x0, 0x101180680
101180678:	e0 87 01 f9	str	x0, [sp, #0x308]
10118067c:	0f 45 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
101180680:	e0 8f 41 f9	ldr	x0, [sp, #0x318]
101180684:	60 00 00 b4	cbz	x0, 0x101180690
101180688:	e0 93 01 f9	str	x0, [sp, #0x320]
10118068c:	0b 45 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
101180690:	e0 df 41 f9	ldr	x0, [sp, #0x3b8]
101180694:	60 00 00 b4	cbz	x0, 0x1011806a0
101180698:	e0 e3 01 f9	str	x0, [sp, #0x3c0]
10118069c:	07 45 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
1011806a0:	e0 eb 41 f9	ldr	x0, [sp, #0x3d0]
1011806a4:	60 00 00 b4	cbz	x0, 0x1011806b0
1011806a8:	e0 ef 01 f9	str	x0, [sp, #0x3d8]
1011806ac:	03 45 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
1011806b0:	e0 f7 41 f9	ldr	x0, [sp, #0x3e8]
1011806b4:	60 00 00 b4	cbz	x0, 0x1011806c0
1011806b8:	e0 fb 01 f9	str	x0, [sp, #0x3f0]
1011806bc:	ff 44 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
1011806c0:	e0 63 0e 91	add	x0, sp, #0x398
1011806c4:	0e a8 4c 94	bl	__ZN4juce6StringD1Ev
1011806c8:	e0 c3 0e 91	add	x0, sp, #0x3b0
1011806cc:	0c a8 4c 94	bl	__ZN4juce6StringD1Ev
1011806d0:	e0 03 42 f9	ldr	x0, [sp, #0x400]
1011806d4:	60 00 00 b4	cbz	x0, 0x1011806e0
1011806d8:	e0 07 02 f9	str	x0, [sp, #0x408]
1011806dc:	f7 44 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
1011806e0:	e0 0f 42 f9	ldr	x0, [sp, #0x418]
1011806e4:	60 00 00 b4	cbz	x0, 0x1011806f0
1011806e8:	e0 13 02 f9	str	x0, [sp, #0x420]
1011806ec:	f3 44 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
1011806f0:	e0 2b 42 f9	ldr	x0, [sp, #0x450]
1011806f4:	60 00 00 b4	cbz	x0, 0x101180700
1011806f8:	e0 2f 02 f9	str	x0, [sp, #0x458]
1011806fc:	ef 44 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
101180700:	e0 2b 43 f9	ldr	x0, [sp, #0x650]
101180704:	60 00 00 b4	cbz	x0, 0x101180710
101180708:	e0 2f 03 f9	str	x0, [sp, #0x658]
10118070c:	eb 44 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
101180710:	e0 2b 44 f9	ldr	x0, [sp, #0x850]
101180714:	60 00 00 b4	cbz	x0, 0x101180720
101180718:	e0 2f 04 f9	str	x0, [sp, #0x858]
10118071c:	e7 44 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
101180720:	e0 2b 45 f9	ldr	x0, [sp, #0xa50]
101180724:	60 00 00 b4	cbz	x0, 0x101180730
101180728:	e0 2f 05 f9	str	x0, [sp, #0xa58]
10118072c:	e3 44 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
101180730:	80 23 02 91	add	x0, x28, #0x88
101180734:	81 0b 47 a9	ldp	x1, x2, [x28, #0x70]
101180738:	68 0c 00 94	bl	__ZNSt3__16vectorIN16BeatAnalyzer_2_06peakss8BeatInfoENS_9allocatorIS3_EEE6assignIPS3_EENS_9enable_ifIXaasr27__is_cpp17_forward_iteratorIT_EE5valuesr16is_constructibleIS3_NS_15iterator_traitsISA_E9referenceEEE5valueEvE4typeESA_SA_
10118073c:	80 4b 40 bd	ldr	s0, [x28, #0x48]
101180740:	80 4f 00 bd	str	s0, [x28, #0x4c]
101180744:	67 ae ff 17	b	0x10116c0e0
101180748:	0c 00 80 d2	mov	x12, #0x0
10118074c:	4a 0d 00 d1	sub	x10, x10, #0x3
101180750:	6b 41 00 91	add	x11, x11, #0x10
101180754:	04 00 00 14	b	0x101180764
101180758:	8c 11 00 91	add	x12, x12, #0x4
10118075c:	4a 05 00 f1	subs	x10, x10, #0x1
101180760:	20 cb ff 54	b.eq	0x1011800c4
101180764:	ed db 40 f9	ldr	x13, [sp, #0x1b0]
101180768:	af 01 0c 8b	add	x15, x13, x12
10118076c:	f0 b9 41 29	ldp	w16, w14, [x15, #0xc]
101180770:	d0 01 10 4b	sub	w16, w14, w16
101180774:	1f 16 00 71	cmp	w16, #0x5
101180778:	0b ff ff 54	b.lt	0x101180758
10118077c:	ef 09 40 b9	ldr	w15, [x15, #0x8]
101180780:	cf 01 0f 4b	sub	w15, w14, w15
101180784:	ff 15 00 71	cmp	w15, #0x5
101180788:	8b fe ff 54	b.lt	0x101180758
10118078c:	af 01 0c 8b	add	x15, x13, x12
101180790:	ef 05 40 b9	ldr	w15, [x15, #0x4]
101180794:	cf 01 0f 4b	sub	w15, w14, w15
101180798:	ff 15 00 71	cmp	w15, #0x5
10118079c:	eb fd ff 54	b.lt	0x101180758
1011807a0:	ad 69 6c b8	ldr	w13, [x13, x12]
1011807a4:	cd 01 0d 4b	sub	w13, w14, w13
1011807a8:	bf 15 00 71	cmp	w13, #0x5
1011807ac:	6b fd ff 54	b.lt	0x101180758
1011807b0:	6d 69 6c b8	ldr	w13, [x11, x12]
1011807b4:	2d d9 28 b8	str	w13, [x9, w8, sxtw #2]
1011807b8:	08 05 00 11	add	w8, w8, #0x1
1011807bc:	e7 ff ff 17	b	0x101180758
1011807c0:	ea 0b 41 b9	ldr	w10, [sp, #0x108]
1011807c4:	5f 09 00 71	cmp	w10, #0x2
1011807c8:	ea 03 41 b9	ldr	w10, [sp, #0x100]
1011807cc:	44 19 42 7a	ccmp	w10, #0x2, #0x4, ne
1011807d0:	01 02 00 54	b.ne	0x101180810
1011807d4:	9f 06 00 71	cmp	w20, #0x1
1011807d8:	cc 01 00 54	b.gt	0x101180810
1011807dc:	7f 07 00 71	cmp	w27, #0x1
1011807e0:	8c 01 00 54	b.gt	0x101180810
1011807e4:	7c 01 00 34	cbz	w28, 0x101180810
1011807e8:	1f 07 00 71	cmp	w24, #0x1
1011807ec:	2c 01 00 54	b.gt	0x101180810
1011807f0:	7f 06 00 71	cmp	w19, #0x1
1011807f4:	4b ed ff 54	b.lt	0x10118059c
1011807f8:	29 03 40 f9	ldr	x9, [x25]
1011807fc:	68 7e 40 92	and	x8, x19, #0xffffffff
101180800:	1f 11 00 f1	cmp	x8, #0x4
101180804:	62 0c 00 54	b.hs	0x101180990
101180808:	0a 00 80 d2	mov	x10, #0x0
10118080c:	7e 00 00 14	b	0x101180a04
101180810:	ea 0b 41 b9	ldr	w10, [sp, #0x108]
101180814:	5f 0d 00 71	cmp	w10, #0x3
101180818:	ea fb 40 b9	ldr	w10, [sp, #0xf8]
10118081c:	42 11 57 7a	ccmp	w10, w23, #0x2, ne
101180820:	69 07 00 54	b.ls	0x10118090c
101180824:	9f 06 00 71	cmp	w20, #0x1
101180828:	2c 07 00 54	b.gt	0x10118090c
10118082c:	7f 07 00 71	cmp	w27, #0x1
101180830:	ec 06 00 54	b.gt	0x10118090c
101180834:	9f 2b 00 71	cmp	w28, #0xa
101180838:	ac 06 00 54	b.gt	0x10118090c
10118083c:	98 06 00 34	cbz	w24, 0x10118090c
101180840:	7f 06 00 71	cmp	w19, #0x1
101180844:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
101180848:	ab ea ff 54	b.lt	0x10118059c
10118084c:	09 01 40 f9	ldr	x9, [x8]
101180850:	68 7e 40 92	and	x8, x19, #0xffffffff
101180854:	1f 11 00 f1	cmp	x8, #0x4
101180858:	e2 11 00 54	b.hs	0x101180a94
10118085c:	0a 00 80 d2	mov	x10, #0x0
101180860:	a9 00 00 14	b	0x101180b04
101180864:	6b 06 40 92	and	x11, x19, #0x3
101180868:	0a 01 0b cb	sub	x10, x8, x11
10118086c:	2c f1 00 91	add	x12, x9, #0x3c
101180870:	6d 00 80 52	mov	w13, #0x3
101180874:	ee 03 0a aa	mov	x14, x10
101180878:	8f 01 5d b8	ldur	w15, [x12, #-0x30]
10118087c:	90 81 5e b8	ldur	w16, [x12, #-0x18]
101180880:	91 01 40 b9	ldr	w17, [x12]
101180884:	80 19 40 b9	ldr	w0, [x12, #0x18]
101180888:	ff 09 00 71	cmp	w15, #0x2
10118088c:	a1 b1 9f 5a	csinv	w1, w13, wzr, lt
101180890:	1f 0a 00 71	cmp	w16, #0x2
101180894:	a2 b1 9f 5a	csinv	w2, w13, wzr, lt
101180898:	3f 0a 00 71	cmp	w17, #0x2
10118089c:	a3 b1 9f 5a	csinv	w3, w13, wzr, lt
1011808a0:	1f 08 00 71	cmp	w0, #0x2
1011808a4:	a4 b1 9f 5a	csinv	w4, w13, wzr, lt
1011808a8:	ef 01 01 0b	add	w15, w15, w1
1011808ac:	10 02 02 0b	add	w16, w16, w2
1011808b0:	31 02 03 0b	add	w17, w17, w3
1011808b4:	8f 01 1d b8	stur	w15, [x12, #-0x30]
1011808b8:	90 81 1e b8	stur	w16, [x12, #-0x18]
1011808bc:	0f 00 04 0b	add	w15, w0, w4
1011808c0:	91 01 00 b9	str	w17, [x12]
1011808c4:	8f 19 00 b9	str	w15, [x12, #0x18]
1011808c8:	8c 81 01 91	add	x12, x12, #0x60
1011808cc:	ce 11 00 f1	subs	x14, x14, #0x4
1011808d0:	41 fd ff 54	b.ne	0x101180878
1011808d4:	4b e6 ff b4	cbz	x11, 0x10118059c
1011808d8:	0b 03 80 52	mov	w11, #0x18
1011808dc:	49 25 0b 9b	madd	x9, x10, x11, x9
1011808e0:	29 31 00 91	add	x9, x9, #0xc
1011808e4:	08 01 0a cb	sub	x8, x8, x10
1011808e8:	6a 00 80 52	mov	w10, #0x3
1011808ec:	2b 01 40 b9	ldr	w11, [x9]
1011808f0:	7f 09 00 71	cmp	w11, #0x2
1011808f4:	4c b1 9f 5a	csinv	w12, w10, wzr, lt
1011808f8:	6b 01 0c 0b	add	w11, w11, w12
1011808fc:	2b 85 01 b8	str	w11, [x9], #0x18
101180900:	08 05 00 f1	subs	x8, x8, #0x1
101180904:	41 ff ff 54	b.ne	0x1011808ec
101180908:	25 ff ff 17	b	0x10118059c
10118090c:	ea 5b 41 b9	ldr	w10, [sp, #0x158]
101180910:	5f 05 00 71	cmp	w10, #0x1
101180914:	21 09 00 54	b.ne	0x101180a38
101180918:	e8 03 41 b9	ldr	w8, [sp, #0x100]
10118091c:	a8 00 00 35	cbnz	w8, 0x101180930
101180920:	e8 0b 41 b9	ldr	w8, [sp, #0x108]
101180924:	68 00 00 35	cbnz	w8, 0x101180930
101180928:	bf 06 00 71	cmp	w21, #0x1
10118092c:	80 e3 ff 54	b.eq	0x10118059c
101180930:	e8 03 41 b9	ldr	w8, [sp, #0x100]
101180934:	a8 00 00 34	cbz	w8, 0x101180948
101180938:	e8 03 41 b9	ldr	w8, [sp, #0x100]
10118093c:	08 05 00 11	add	w8, w8, #0x1
101180940:	1f 01 15 6b	cmp	w8, w21
101180944:	00 01 00 54	b.eq	0x101180964
101180948:	e8 0b 41 b9	ldr	w8, [sp, #0x108]
10118094c:	1f 05 00 71	cmp	w8, #0x1
101180950:	4b 17 00 54	b.lt	0x101180c38
101180954:	e8 0b 41 b9	ldr	w8, [sp, #0x108]
101180958:	08 05 00 11	add	w8, w8, #0x1
10118095c:	1f 01 15 6b	cmp	w8, w21
101180960:	c1 16 00 54	b.ne	0x101180c38
101180964:	7f 06 00 71	cmp	w19, #0x1
101180968:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
10118096c:	8b e1 ff 54	b.lt	0x10118059c
101180970:	09 01 40 f9	ldr	x9, [x8]
101180974:	28 00 80 52	mov	w8, #0x1
101180978:	08 01 15 4b	sub	w8, w8, w21
10118097c:	6a 7e 40 92	and	x10, x19, #0xffffffff
101180980:	5f 11 00 f1	cmp	x10, #0x4
101180984:	42 19 00 54	b.hs	0x101180cac
101180988:	0b 00 80 d2	mov	x11, #0x0
10118098c:	e8 00 00 14	b	0x101180d2c
101180990:	6b 06 40 92	and	x11, x19, #0x3
101180994:	0a 01 0b cb	sub	x10, x8, x11
101180998:	2c f1 00 91	add	x12, x9, #0x3c
10118099c:	2d 00 80 12	mov	w13, #-0x2
1011809a0:	ee 03 0a aa	mov	x14, x10
1011809a4:	8f 01 5d b8	ldur	w15, [x12, #-0x30]
1011809a8:	90 81 5e b8	ldur	w16, [x12, #-0x18]
1011809ac:	91 01 40 b9	ldr	w17, [x12]
1011809b0:	80 19 40 b9	ldr	w0, [x12, #0x18]
1011809b4:	ff 09 00 71	cmp	w15, #0x2
1011809b8:	a1 c5 8d 5a	cneg	w1, w13, le
1011809bc:	1f 0a 00 71	cmp	w16, #0x2
1011809c0:	a2 c5 8d 5a	cneg	w2, w13, le
1011809c4:	3f 0a 00 71	cmp	w17, #0x2
1011809c8:	a3 c5 8d 5a	cneg	w3, w13, le
1011809cc:	1f 08 00 71	cmp	w0, #0x2
1011809d0:	a4 c5 8d 5a	cneg	w4, w13, le
1011809d4:	ef 01 01 0b	add	w15, w15, w1
1011809d8:	10 02 02 0b	add	w16, w16, w2
1011809dc:	31 02 03 0b	add	w17, w17, w3
1011809e0:	8f 01 1d b8	stur	w15, [x12, #-0x30]
1011809e4:	90 81 1e b8	stur	w16, [x12, #-0x18]
1011809e8:	0f 00 04 0b	add	w15, w0, w4
1011809ec:	91 01 00 b9	str	w17, [x12]
1011809f0:	8f 19 00 b9	str	w15, [x12, #0x18]
1011809f4:	8c 81 01 91	add	x12, x12, #0x60
1011809f8:	ce 11 00 f1	subs	x14, x14, #0x4
1011809fc:	41 fd ff 54	b.ne	0x1011809a4
101180a00:	eb dc ff b4	cbz	x11, 0x10118059c
101180a04:	0b 03 80 52	mov	w11, #0x18
101180a08:	49 25 0b 9b	madd	x9, x10, x11, x9
101180a0c:	29 31 00 91	add	x9, x9, #0xc
101180a10:	08 01 0a cb	sub	x8, x8, x10
101180a14:	2a 00 80 12	mov	w10, #-0x2
101180a18:	2b 01 40 b9	ldr	w11, [x9]
101180a1c:	7f 09 00 71	cmp	w11, #0x2
101180a20:	4c c5 8a 5a	cneg	w12, w10, le
101180a24:	6b 01 0c 0b	add	w11, w11, w12
101180a28:	2b 85 01 b8	str	w11, [x9], #0x18
101180a2c:	08 05 00 f1	subs	x8, x8, #0x1
101180a30:	41 ff ff 54	b.ne	0x101180a18
101180a34:	da fe ff 17	b	0x10118059c
101180a38:	ea 5b 41 b9	ldr	w10, [sp, #0x158]
101180a3c:	eb f3 40 b9	ldr	w11, [sp, #0xf0]
101180a40:	5f 01 0b 6b	cmp	w10, w11
101180a44:	eb 3b 41 b9	ldr	w11, [sp, #0x138]
101180a48:	40 01 4b 7a	ccmp	w10, w11, #0x0, eq
101180a4c:	ea 17 9f 1a	cset	w10, eq
101180a50:	21 07 00 54	b.ne	0x101180b34
101180a54:	eb 5b 41 b9	ldr	w11, [sp, #0x158]
101180a58:	ec 33 41 b9	ldr	w12, [sp, #0x130]
101180a5c:	7f 01 0c 6b	cmp	w11, w12
101180a60:	a1 06 00 54	b.ne	0x101180b34
101180a64:	7f 06 00 71	cmp	w19, #0x1
101180a68:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
101180a6c:	8b d9 ff 54	b.lt	0x10118059c
101180a70:	09 01 40 f9	ldr	x9, [x8]
101180a74:	28 00 80 52	mov	w8, #0x1
101180a78:	ea 5b 41 b9	ldr	w10, [sp, #0x158]
101180a7c:	08 01 0a 4b	sub	w8, w8, w10
101180a80:	6a 7e 40 92	and	x10, x19, #0xffffffff
101180a84:	5f 11 00 f1	cmp	x10, #0x4
101180a88:	e2 07 00 54	b.hs	0x101180b84
101180a8c:	0b 00 80 d2	mov	x11, #0x0
101180a90:	5d 00 00 14	b	0x101180c04
101180a94:	6b 06 40 92	and	x11, x19, #0x3
101180a98:	0a 01 0b cb	sub	x10, x8, x11
101180a9c:	2c f1 00 91	add	x12, x9, #0x3c
101180aa0:	ed 03 0a aa	mov	x13, x10
101180aa4:	8e 01 5d b8	ldur	w14, [x12, #-0x30]
101180aa8:	8f 81 5e b8	ldur	w15, [x12, #-0x18]
101180aac:	90 01 40 b9	ldr	w16, [x12]
101180ab0:	91 19 40 b9	ldr	w17, [x12, #0x18]
101180ab4:	c0 0d 00 51	sub	w0, w14, #0x3
101180ab8:	df 11 00 71	cmp	w14, #0x4
101180abc:	0e a4 8e 1a	csinc	w14, w0, w14, ge
101180ac0:	e0 0d 00 51	sub	w0, w15, #0x3
101180ac4:	ff 11 00 71	cmp	w15, #0x4
101180ac8:	0f a4 8f 1a	csinc	w15, w0, w15, ge
101180acc:	00 0e 00 51	sub	w0, w16, #0x3
101180ad0:	1f 12 00 71	cmp	w16, #0x4
101180ad4:	10 a4 90 1a	csinc	w16, w0, w16, ge
101180ad8:	20 0e 00 51	sub	w0, w17, #0x3
101180adc:	3f 12 00 71	cmp	w17, #0x4
101180ae0:	8e 01 1d b8	stur	w14, [x12, #-0x30]
101180ae4:	8f 81 1e b8	stur	w15, [x12, #-0x18]
101180ae8:	0e a4 91 1a	csinc	w14, w0, w17, ge
101180aec:	90 01 00 b9	str	w16, [x12]
101180af0:	8e 19 00 b9	str	w14, [x12, #0x18]
101180af4:	8c 81 01 91	add	x12, x12, #0x60
101180af8:	ad 11 00 f1	subs	x13, x13, #0x4
101180afc:	41 fd ff 54	b.ne	0x101180aa4
101180b00:	eb d4 ff b4	cbz	x11, 0x10118059c
101180b04:	0b 03 80 52	mov	w11, #0x18
101180b08:	49 25 0b 9b	madd	x9, x10, x11, x9
101180b0c:	29 31 00 91	add	x9, x9, #0xc
101180b10:	08 01 0a cb	sub	x8, x8, x10
101180b14:	2a 01 40 b9	ldr	w10, [x9]
101180b18:	4b 0d 00 51	sub	w11, w10, #0x3
101180b1c:	5f 11 00 71	cmp	w10, #0x4
101180b20:	6a a5 8a 1a	csinc	w10, w11, w10, ge
101180b24:	2a 85 01 b8	str	w10, [x9], #0x18
101180b28:	08 05 00 f1	subs	x8, x8, #0x1
101180b2c:	41 ff ff 54	b.ne	0x101180b14
101180b30:	9b fe ff 17	b	0x10118059c
101180b34:	eb 3b 41 b9	ldr	w11, [sp, #0x138]
101180b38:	2b 01 0b 0b	add	w11, w9, w11
101180b3c:	ec 5b 41 b9	ldr	w12, [sp, #0x158]
101180b40:	ee 33 41 b9	ldr	w14, [sp, #0x130]
101180b44:	9f 01 0e 6b	cmp	w12, w14
101180b48:	e9 17 9f 1a	cset	w9, eq
101180b4c:	ed f3 40 b9	ldr	w13, [sp, #0xf0]
101180b50:	9f 01 0d 6b	cmp	w12, w13
101180b54:	80 01 4b 7a	ccmp	w12, w11, #0x0, eq
101180b58:	eb 17 9f 1a	cset	w11, eq
101180b5c:	08 01 0e 0b	add	w8, w8, w14
101180b60:	9f 01 08 6b	cmp	w12, w8
101180b64:	e8 17 9f 1a	cset	w8, eq
101180b68:	6c 01 08 0a	and	w12, w11, w8
101180b6c:	cc f7 07 37	tbnz	w12, #0x0, 0x101180a64
101180b70:	69 01 09 0a	and	w9, w11, w9
101180b74:	89 f7 07 37	tbnz	w9, #0x0, 0x101180a64
101180b78:	48 01 08 0a	and	w8, w10, w8
101180b7c:	e8 ec ff 34	cbz	w8, 0x101180918
101180b80:	b9 ff ff 17	b	0x101180a64
101180b84:	6c 06 40 92	and	x12, x19, #0x3
101180b88:	4b 01 0c cb	sub	x11, x10, x12
101180b8c:	2d f1 00 91	add	x13, x9, #0x3c
101180b90:	ee 03 0b aa	mov	x14, x11
101180b94:	af 01 5d b8	ldur	w15, [x13, #-0x30]
101180b98:	b0 81 5e b8	ldur	w16, [x13, #-0x18]
101180b9c:	b1 01 40 b9	ldr	w17, [x13]
101180ba0:	0f 01 0f 0b	add	w15, w8, w15
101180ba4:	10 01 10 0b	add	w16, w8, w16
101180ba8:	a0 19 40 b9	ldr	w0, [x13, #0x18]
101180bac:	11 01 11 0b	add	w17, w8, w17
101180bb0:	00 01 00 0b	add	w0, w8, w0
101180bb4:	e1 11 00 11	add	w1, w15, #0x4
101180bb8:	02 12 00 11	add	w2, w16, #0x4
101180bbc:	23 12 00 11	add	w3, w17, #0x4
101180bc0:	04 10 00 11	add	w4, w0, #0x4
101180bc4:	ff 05 00 71	cmp	w15, #0x1
101180bc8:	2f b0 8f 1a	csel	w15, w1, w15, lt
101180bcc:	1f 06 00 71	cmp	w16, #0x1
101180bd0:	50 b0 90 1a	csel	w16, w2, w16, lt
101180bd4:	3f 06 00 71	cmp	w17, #0x1
101180bd8:	71 b0 91 1a	csel	w17, w3, w17, lt
101180bdc:	af 01 1d b8	stur	w15, [x13, #-0x30]
101180be0:	b0 81 1e b8	stur	w16, [x13, #-0x18]
101180be4:	1f 04 00 71	cmp	w0, #0x1
101180be8:	8f b0 80 1a	csel	w15, w4, w0, lt
101180bec:	b1 01 00 b9	str	w17, [x13]
101180bf0:	af 19 00 b9	str	w15, [x13, #0x18]
101180bf4:	ad 81 01 91	add	x13, x13, #0x60
101180bf8:	ce 11 00 f1	subs	x14, x14, #0x4
101180bfc:	c1 fc ff 54	b.ne	0x101180b94
101180c00:	ec cc ff b4	cbz	x12, 0x10118059c
101180c04:	0c 03 80 52	mov	w12, #0x18
101180c08:	69 25 0c 9b	madd	x9, x11, x12, x9
101180c0c:	29 31 00 91	add	x9, x9, #0xc
101180c10:	4a 01 0b cb	sub	x10, x10, x11
101180c14:	2b 01 40 b9	ldr	w11, [x9]
101180c18:	0b 01 0b 0b	add	w11, w8, w11
101180c1c:	6c 11 00 11	add	w12, w11, #0x4
101180c20:	7f 05 00 71	cmp	w11, #0x1
101180c24:	8b b1 8b 1a	csel	w11, w12, w11, lt
101180c28:	2b 85 01 b8	str	w11, [x9], #0x18
101180c2c:	4a 05 00 f1	subs	x10, x10, #0x1
101180c30:	21 ff ff 54	b.ne	0x101180c14
101180c34:	5a fe ff 17	b	0x10118059c
101180c38:	e8 cb 40 b9	ldr	w8, [sp, #0xc8]
101180c3c:	28 01 00 34	cbz	w8, 0x101180c60
101180c40:	e8 eb 40 b9	ldr	w8, [sp, #0xe8]
101180c44:	e8 00 00 34	cbz	w8, 0x101180c60
101180c48:	e8 e3 40 b9	ldr	w8, [sp, #0xe0]
101180c4c:	a8 00 00 35	cbnz	w8, 0x101180c60
101180c50:	e8 df 40 b9	ldr	w8, [sp, #0xdc]
101180c54:	68 00 00 35	cbnz	w8, 0x101180c60
101180c58:	e8 d3 40 b9	ldr	w8, [sp, #0xd0]
101180c5c:	08 ca ff 34	cbz	w8, 0x10118059c
101180c60:	e8 c3 40 b9	ldr	w8, [sp, #0xc0]
101180c64:	08 08 00 34	cbz	w8, 0x101180d64
101180c68:	e8 eb 40 b9	ldr	w8, [sp, #0xe8]
101180c6c:	c8 07 00 35	cbnz	w8, 0x101180d64
101180c70:	e8 e3 40 b9	ldr	w8, [sp, #0xe0]
101180c74:	88 07 00 34	cbz	w8, 0x101180d64
101180c78:	e8 df 40 b9	ldr	w8, [sp, #0xdc]
101180c7c:	48 07 00 35	cbnz	w8, 0x101180d64
101180c80:	e8 d3 40 b9	ldr	w8, [sp, #0xd0]
101180c84:	08 07 00 35	cbnz	w8, 0x101180d64
101180c88:	7f 06 00 71	cmp	w19, #0x1
101180c8c:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
101180c90:	6b c8 ff 54	b.lt	0x10118059c
101180c94:	09 01 40 f9	ldr	x9, [x8]
101180c98:	68 7e 40 92	and	x8, x19, #0xffffffff
101180c9c:	1f 11 00 f1	cmp	x8, #0x4
101180ca0:	62 0c 00 54	b.hs	0x101180e2c
101180ca4:	0a 00 80 d2	mov	x10, #0x0
101180ca8:	7e 00 00 14	b	0x101180ea0
101180cac:	6c 06 40 92	and	x12, x19, #0x3
101180cb0:	4b 01 0c cb	sub	x11, x10, x12
101180cb4:	2d f1 00 91	add	x13, x9, #0x3c
101180cb8:	ee 03 0b aa	mov	x14, x11
101180cbc:	af 01 5d b8	ldur	w15, [x13, #-0x30]
101180cc0:	b0 81 5e b8	ldur	w16, [x13, #-0x18]
101180cc4:	b1 01 40 b9	ldr	w17, [x13]
101180cc8:	0f 01 0f 0b	add	w15, w8, w15
101180ccc:	10 01 10 0b	add	w16, w8, w16
101180cd0:	a0 19 40 b9	ldr	w0, [x13, #0x18]
101180cd4:	11 01 11 0b	add	w17, w8, w17
101180cd8:	00 01 00 0b	add	w0, w8, w0
101180cdc:	e1 11 00 11	add	w1, w15, #0x4
101180ce0:	02 12 00 11	add	w2, w16, #0x4
101180ce4:	23 12 00 11	add	w3, w17, #0x4
101180ce8:	04 10 00 11	add	w4, w0, #0x4
101180cec:	ff 05 00 71	cmp	w15, #0x1
101180cf0:	2f b0 8f 1a	csel	w15, w1, w15, lt
101180cf4:	1f 06 00 71	cmp	w16, #0x1
101180cf8:	50 b0 90 1a	csel	w16, w2, w16, lt
101180cfc:	3f 06 00 71	cmp	w17, #0x1
101180d00:	71 b0 91 1a	csel	w17, w3, w17, lt
101180d04:	af 01 1d b8	stur	w15, [x13, #-0x30]
101180d08:	b0 81 1e b8	stur	w16, [x13, #-0x18]
101180d0c:	1f 04 00 71	cmp	w0, #0x1
101180d10:	8f b0 80 1a	csel	w15, w4, w0, lt
101180d14:	b1 01 00 b9	str	w17, [x13]
101180d18:	af 19 00 b9	str	w15, [x13, #0x18]
101180d1c:	ad 81 01 91	add	x13, x13, #0x60
101180d20:	ce 11 00 f1	subs	x14, x14, #0x4
101180d24:	c1 fc ff 54	b.ne	0x101180cbc
101180d28:	ac c3 ff b4	cbz	x12, 0x10118059c
101180d2c:	0c 03 80 52	mov	w12, #0x18
101180d30:	69 25 0c 9b	madd	x9, x11, x12, x9
101180d34:	29 31 00 91	add	x9, x9, #0xc
101180d38:	4a 01 0b cb	sub	x10, x10, x11
101180d3c:	2b 01 40 b9	ldr	w11, [x9]
101180d40:	0b 01 0b 0b	add	w11, w8, w11
101180d44:	6c 11 00 11	add	w12, w11, #0x4
101180d48:	7f 05 00 71	cmp	w11, #0x1
101180d4c:	8b b1 8b 1a	csel	w11, w12, w11, lt
101180d50:	2b 85 01 b8	str	w11, [x9], #0x18
101180d54:	4a 05 00 f1	subs	x10, x10, #0x1
101180d58:	21 ff ff 54	b.ne	0x101180d3c
101180d5c:	10 fe ff 17	b	0x10118059c
101180d60:	bc 43 8d 94	bl	0x1034d1c50 ; symbol stub for: ___stack_chk_fail
101180d64:	e8 bb 40 b9	ldr	w8, [sp, #0xb8]
101180d68:	48 02 00 34	cbz	w8, 0x101180db0
101180d6c:	e8 eb 40 b9	ldr	w8, [sp, #0xe8]
101180d70:	08 02 00 35	cbnz	w8, 0x101180db0
101180d74:	e8 e3 40 b9	ldr	w8, [sp, #0xe0]
101180d78:	c8 01 00 35	cbnz	w8, 0x101180db0
101180d7c:	e8 df 40 b9	ldr	w8, [sp, #0xdc]
101180d80:	88 01 00 34	cbz	w8, 0x101180db0
101180d84:	e8 d3 40 b9	ldr	w8, [sp, #0xd0]
101180d88:	48 01 00 35	cbnz	w8, 0x101180db0
101180d8c:	7f 06 00 71	cmp	w19, #0x1
101180d90:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
101180d94:	4b c0 ff 54	b.lt	0x10118059c
101180d98:	09 01 40 f9	ldr	x9, [x8]
101180d9c:	68 7e 40 92	and	x8, x19, #0xffffffff
101180da0:	1f 11 00 f1	cmp	x8, #0x4
101180da4:	02 0e 00 54	b.hs	0x101180f64
101180da8:	0a 00 80 d2	mov	x10, #0x0
101180dac:	8b 00 00 14	b	0x101180fd8
101180db0:	e8 fb 40 b9	ldr	w8, [sp, #0xf8]
101180db4:	88 09 00 34	cbz	w8, 0x101180ee4
101180db8:	e8 eb 40 b9	ldr	w8, [sp, #0xe8]
101180dbc:	48 09 00 35	cbnz	w8, 0x101180ee4
101180dc0:	e8 e3 40 b9	ldr	w8, [sp, #0xe0]
101180dc4:	08 09 00 35	cbnz	w8, 0x101180ee4
101180dc8:	e8 df 40 b9	ldr	w8, [sp, #0xdc]
101180dcc:	c8 08 00 35	cbnz	w8, 0x101180ee4
101180dd0:	e8 d3 40 b9	ldr	w8, [sp, #0xd0]
101180dd4:	88 08 00 34	cbz	w8, 0x101180ee4
101180dd8:	7f 06 00 71	cmp	w19, #0x1
101180ddc:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
101180de0:	eb bd ff 54	b.lt	0x10118059c
101180de4:	09 01 40 f9	ldr	x9, [x8]
101180de8:	68 7e 40 92	and	x8, x19, #0xffffffff
101180dec:	1f 11 00 f1	cmp	x8, #0x4
101180df0:	02 12 00 54	b.hs	0x101181030
101180df4:	0a 00 80 d2	mov	x10, #0x0
101180df8:	aa 00 00 14	b	0x1011810a0
101180dfc:	e0 03 10 91	add	x0, sp, #0x400
101180e00:	7c b4 d0 97	bl	__ZNKSt3__16vectorIdNS_9allocatorIdEEE20__throw_length_errorB6v15006Ev
101180e04:	10 01 00 14	b	0x101181244
101180e08:	e0 03 10 91	add	x0, sp, #0x400
101180e0c:	79 b4 d0 97	bl	__ZNKSt3__16vectorIdNS_9allocatorIdEEE20__throw_length_errorB6v15006Ev
101180e10:	0d 01 00 14	b	0x101181244
101180e14:	e0 03 10 91	add	x0, sp, #0x400
101180e18:	76 b4 d0 97	bl	__ZNKSt3__16vectorIdNS_9allocatorIdEEE20__throw_length_errorB6v15006Ev
101180e1c:	0a 01 00 14	b	0x101181244
101180e20:	e0 03 10 91	add	x0, sp, #0x400
101180e24:	73 b4 d0 97	bl	__ZNKSt3__16vectorIdNS_9allocatorIdEEE20__throw_length_errorB6v15006Ev
101180e28:	07 01 00 14	b	0x101181244
101180e2c:	6b 06 40 92	and	x11, x19, #0x3
101180e30:	0a 01 0b cb	sub	x10, x8, x11
101180e34:	2c f1 00 91	add	x12, x9, #0x3c
101180e38:	6d 00 80 52	mov	w13, #0x3
101180e3c:	ee 03 0a aa	mov	x14, x10
101180e40:	8f 01 5d b8	ldur	w15, [x12, #-0x30]
101180e44:	90 81 5e b8	ldur	w16, [x12, #-0x18]
101180e48:	91 01 40 b9	ldr	w17, [x12]
101180e4c:	80 19 40 b9	ldr	w0, [x12, #0x18]
101180e50:	ff 09 00 71	cmp	w15, #0x2
101180e54:	a1 b1 9f 5a	csinv	w1, w13, wzr, lt
101180e58:	1f 0a 00 71	cmp	w16, #0x2
101180e5c:	a2 b1 9f 5a	csinv	w2, w13, wzr, lt
101180e60:	3f 0a 00 71	cmp	w17, #0x2
101180e64:	a3 b1 9f 5a	csinv	w3, w13, wzr, lt
101180e68:	1f 08 00 71	cmp	w0, #0x2
101180e6c:	a4 b1 9f 5a	csinv	w4, w13, wzr, lt
101180e70:	ef 01 01 0b	add	w15, w15, w1
101180e74:	10 02 02 0b	add	w16, w16, w2
101180e78:	31 02 03 0b	add	w17, w17, w3
101180e7c:	8f 01 1d b8	stur	w15, [x12, #-0x30]
101180e80:	90 81 1e b8	stur	w16, [x12, #-0x18]
101180e84:	0f 00 04 0b	add	w15, w0, w4
101180e88:	91 01 00 b9	str	w17, [x12]
101180e8c:	8f 19 00 b9	str	w15, [x12, #0x18]
101180e90:	8c 81 01 91	add	x12, x12, #0x60
101180e94:	ce 11 00 f1	subs	x14, x14, #0x4
101180e98:	41 fd ff 54	b.ne	0x101180e40
101180e9c:	0b b8 ff b4	cbz	x11, 0x10118059c
101180ea0:	0b 03 80 52	mov	w11, #0x18
101180ea4:	49 25 0b 9b	madd	x9, x10, x11, x9
101180ea8:	29 31 00 91	add	x9, x9, #0xc
101180eac:	08 01 0a cb	sub	x8, x8, x10
101180eb0:	6a 00 80 52	mov	w10, #0x3
101180eb4:	2b 01 40 b9	ldr	w11, [x9]
101180eb8:	7f 09 00 71	cmp	w11, #0x2
101180ebc:	4c b1 9f 5a	csinv	w12, w10, wzr, lt
101180ec0:	6b 01 0c 0b	add	w11, w11, w12
101180ec4:	2b 85 01 b8	str	w11, [x9], #0x18
101180ec8:	08 05 00 f1	subs	x8, x8, #0x1
101180ecc:	41 ff ff 54	b.ne	0x101180eb4
101180ed0:	b3 fd ff 17	b	0x10118059c
101180ed4:	69 e0 ba 97	bl	__ZSt28__throw_bad_array_new_lengthB6v15006v
101180ed8:	db 00 00 14	b	0x101181244
101180edc:	67 e0 ba 97	bl	__ZSt28__throw_bad_array_new_lengthB6v15006v
101180ee0:	d9 00 00 14	b	0x101181244
101180ee4:	e8 b3 40 f9	ldr	x8, [sp, #0x160]
101180ee8:	e9 03 41 b9	ldr	w9, [sp, #0x100]
101180eec:	89 b5 ff 34	cbz	w9, 0x10118059c
101180ef0:	e9 03 41 b9	ldr	w9, [sp, #0x100]
101180ef4:	ea 0b 41 b9	ldr	w10, [sp, #0x108]
101180ef8:	3f 01 0a 6b	cmp	w9, w10
101180efc:	01 b5 ff 54	b.ne	0x10118059c
101180f00:	7f 06 00 71	cmp	w19, #0x1
101180f04:	cb b4 ff 54	b.lt	0x10118059c
101180f08:	09 01 40 f9	ldr	x9, [x8]
101180f0c:	68 7e 40 92	and	x8, x19, #0xffffffff
101180f10:	1f 11 00 f1	cmp	x8, #0x4
101180f14:	c2 0e 00 54	b.hs	0x1011810ec
101180f18:	0a 00 80 d2	mov	x10, #0x0
101180f1c:	95 00 00 14	b	0x101181170
101180f20:	e0 a3 0f 91	add	x0, sp, #0x3e8
101180f24:	33 b4 d0 97	bl	__ZNKSt3__16vectorIdNS_9allocatorIdEEE20__throw_length_errorB6v15006Ev
101180f28:	c7 00 00 14	b	0x101181244
101180f2c:	e0 63 10 91	add	x0, sp, #0x418
101180f30:	30 b4 d0 97	bl	__ZNKSt3__16vectorIdNS_9allocatorIdEEE20__throw_length_errorB6v15006Ev
101180f34:	e0 03 10 91	add	x0, sp, #0x400
101180f38:	2e b4 d0 97	bl	__ZNKSt3__16vectorIdNS_9allocatorIdEEE20__throw_length_errorB6v15006Ev
101180f3c:	c2 00 00 14	b	0x101181244
101180f40:	4e e0 ba 97	bl	__ZSt28__throw_bad_array_new_lengthB6v15006v
101180f44:	c0 00 00 14	b	0x101181244
101180f48:	4c e0 ba 97	bl	__ZSt28__throw_bad_array_new_lengthB6v15006v
101180f4c:	be 00 00 14	b	0x101181244
101180f50:	e0 a3 40 f9	ldr	x0, [sp, #0x140]
101180f54:	7d f9 fe 97	bl	__ZNKSt3__16vectorIN16BeatAnalyzer_2_06peakss8BeatInfoENS_9allocatorIS3_EEE20__throw_length_errorB6v15006Ev
101180f58:	bb 00 00 14	b	0x101181244
101180f5c:	47 e0 ba 97	bl	__ZSt28__throw_bad_array_new_lengthB6v15006v
101180f60:	b9 00 00 14	b	0x101181244
101180f64:	6b 06 40 92	and	x11, x19, #0x3
101180f68:	0a 01 0b cb	sub	x10, x8, x11
101180f6c:	2c f1 00 91	add	x12, x9, #0x3c
101180f70:	2d 00 80 12	mov	w13, #-0x2
101180f74:	ee 03 0a aa	mov	x14, x10
101180f78:	8f 01 5d b8	ldur	w15, [x12, #-0x30]
101180f7c:	90 81 5e b8	ldur	w16, [x12, #-0x18]
101180f80:	91 01 40 b9	ldr	w17, [x12]
101180f84:	80 19 40 b9	ldr	w0, [x12, #0x18]
101180f88:	ff 09 00 71	cmp	w15, #0x2
101180f8c:	a1 c5 8d 5a	cneg	w1, w13, le
101180f90:	1f 0a 00 71	cmp	w16, #0x2
101180f94:	a2 c5 8d 5a	cneg	w2, w13, le
101180f98:	3f 0a 00 71	cmp	w17, #0x2
101180f9c:	a3 c5 8d 5a	cneg	w3, w13, le
101180fa0:	1f 08 00 71	cmp	w0, #0x2
101180fa4:	a4 c5 8d 5a	cneg	w4, w13, le
101180fa8:	ef 01 01 0b	add	w15, w15, w1
101180fac:	10 02 02 0b	add	w16, w16, w2
101180fb0:	31 02 03 0b	add	w17, w17, w3
101180fb4:	8f 01 1d b8	stur	w15, [x12, #-0x30]
101180fb8:	90 81 1e b8	stur	w16, [x12, #-0x18]
101180fbc:	0f 00 04 0b	add	w15, w0, w4
101180fc0:	91 01 00 b9	str	w17, [x12]
101180fc4:	8f 19 00 b9	str	w15, [x12, #0x18]
101180fc8:	8c 81 01 91	add	x12, x12, #0x60
101180fcc:	ce 11 00 f1	subs	x14, x14, #0x4
101180fd0:	41 fd ff 54	b.ne	0x101180f78
101180fd4:	4b ae ff b4	cbz	x11, 0x10118059c
101180fd8:	0b 03 80 52	mov	w11, #0x18
101180fdc:	49 25 0b 9b	madd	x9, x10, x11, x9
101180fe0:	29 31 00 91	add	x9, x9, #0xc
101180fe4:	08 01 0a cb	sub	x8, x8, x10
101180fe8:	2a 00 80 12	mov	w10, #-0x2
101180fec:	2b 01 40 b9	ldr	w11, [x9]
101180ff0:	7f 09 00 71	cmp	w11, #0x2
101180ff4:	4c c5 8a 5a	cneg	w12, w10, le
101180ff8:	6b 01 0c 0b	add	w11, w11, w12
101180ffc:	2b 85 01 b8	str	w11, [x9], #0x18
101181000:	08 05 00 f1	subs	x8, x8, #0x1
101181004:	41 ff ff 54	b.ne	0x101180fec
101181008:	65 fd ff 17	b	0x10118059c
10118100c:	e0 03 10 91	add	x0, sp, #0x400
101181010:	f8 b3 d0 97	bl	__ZNKSt3__16vectorIdNS_9allocatorIdEEE20__throw_length_errorB6v15006Ev
101181014:	8c 00 00 14	b	0x101181244
101181018:	e0 03 10 91	add	x0, sp, #0x400
10118101c:	f5 b3 d0 97	bl	__ZNKSt3__16vectorIdNS_9allocatorIdEEE20__throw_length_errorB6v15006Ev
101181020:	89 00 00 14	b	0x101181244
101181024:	e0 b3 40 f9	ldr	x0, [sp, #0x160]
101181028:	48 f9 fe 97	bl	__ZNKSt3__16vectorIN16BeatAnalyzer_2_06peakss8BeatInfoENS_9allocatorIS3_EEE20__throw_length_errorB6v15006Ev
10118102c:	86 00 00 14	b	0x101181244
101181030:	6b 06 40 92	and	x11, x19, #0x3
101181034:	0a 01 0b cb	sub	x10, x8, x11
101181038:	2c f1 00 91	add	x12, x9, #0x3c
10118103c:	ed 03 0a aa	mov	x13, x10
101181040:	8e 01 5d b8	ldur	w14, [x12, #-0x30]
101181044:	8f 81 5e b8	ldur	w15, [x12, #-0x18]
101181048:	90 01 40 b9	ldr	w16, [x12]
10118104c:	91 19 40 b9	ldr	w17, [x12, #0x18]
101181050:	c0 0d 00 51	sub	w0, w14, #0x3
101181054:	df 11 00 71	cmp	w14, #0x4
101181058:	0e a4 8e 1a	csinc	w14, w0, w14, ge
10118105c:	e0 0d 00 51	sub	w0, w15, #0x3
101181060:	ff 11 00 71	cmp	w15, #0x4
101181064:	0f a4 8f 1a	csinc	w15, w0, w15, ge
101181068:	00 0e 00 51	sub	w0, w16, #0x3
10118106c:	1f 12 00 71	cmp	w16, #0x4
101181070:	10 a4 90 1a	csinc	w16, w0, w16, ge
101181074:	20 0e 00 51	sub	w0, w17, #0x3
101181078:	3f 12 00 71	cmp	w17, #0x4
10118107c:	8e 01 1d b8	stur	w14, [x12, #-0x30]
101181080:	8f 81 1e b8	stur	w15, [x12, #-0x18]
101181084:	0e a4 91 1a	csinc	w14, w0, w17, ge
101181088:	90 01 00 b9	str	w16, [x12]
10118108c:	8e 19 00 b9	str	w14, [x12, #0x18]
101181090:	8c 81 01 91	add	x12, x12, #0x60
101181094:	ad 11 00 f1	subs	x13, x13, #0x4
101181098:	41 fd ff 54	b.ne	0x101181040
10118109c:	0b a8 ff b4	cbz	x11, 0x10118059c
1011810a0:	0b 03 80 52	mov	w11, #0x18
1011810a4:	49 25 0b 9b	madd	x9, x10, x11, x9
1011810a8:	29 31 00 91	add	x9, x9, #0xc
1011810ac:	08 01 0a cb	sub	x8, x8, x10
1011810b0:	2a 01 40 b9	ldr	w10, [x9]
1011810b4:	4b 0d 00 51	sub	w11, w10, #0x3
1011810b8:	5f 11 00 71	cmp	w10, #0x4
1011810bc:	6a a5 8a 1a	csinc	w10, w11, w10, ge
1011810c0:	2a 85 01 b8	str	w10, [x9], #0x18
1011810c4:	08 05 00 f1	subs	x8, x8, #0x1
1011810c8:	41 ff ff 54	b.ne	0x1011810b0
1011810cc:	34 fd ff 17	b	0x10118059c
1011810d0:	e0 03 16 aa	mov	x0, x22
1011810d4:	1d f9 fe 97	bl	__ZNKSt3__16vectorIN16BeatAnalyzer_2_06peakss8BeatInfoENS_9allocatorIS3_EEE20__throw_length_errorB6v15006Ev
1011810d8:	5b 00 00 14	b	0x101181244
1011810dc:	e7 df ba 97	bl	__ZSt28__throw_bad_array_new_lengthB6v15006v
1011810e0:	59 00 00 14	b	0x101181244
1011810e4:	e5 df ba 97	bl	__ZSt28__throw_bad_array_new_lengthB6v15006v
1011810e8:	57 00 00 14	b	0x101181244
1011810ec:	6b 06 40 92	and	x11, x19, #0x3
1011810f0:	0a 01 0b cb	sub	x10, x8, x11
1011810f4:	2c f1 00 91	add	x12, x9, #0x3c
1011810f8:	ed 03 0a aa	mov	x13, x10
1011810fc:	8e 01 5d b8	ldur	w14, [x12, #-0x30]
101181100:	8f 81 5e b8	ldur	w15, [x12, #-0x18]
101181104:	90 01 40 b9	ldr	w16, [x12]
101181108:	e0 03 41 b9	ldr	w0, [sp, #0x100]
10118110c:	ce 01 00 4b	sub	w14, w14, w0
101181110:	ef 01 00 4b	sub	w15, w15, w0
101181114:	91 19 40 b9	ldr	w17, [x12, #0x18]
101181118:	10 02 00 4b	sub	w16, w16, w0
10118111c:	31 02 00 4b	sub	w17, w17, w0
101181120:	c0 11 00 11	add	w0, w14, #0x4
101181124:	e1 11 00 11	add	w1, w15, #0x4
101181128:	02 12 00 11	add	w2, w16, #0x4
10118112c:	23 12 00 11	add	w3, w17, #0x4
101181130:	df 05 00 71	cmp	w14, #0x1
101181134:	0e b0 8e 1a	csel	w14, w0, w14, lt
101181138:	ff 05 00 71	cmp	w15, #0x1
10118113c:	2f b0 8f 1a	csel	w15, w1, w15, lt
101181140:	1f 06 00 71	cmp	w16, #0x1
101181144:	50 b0 90 1a	csel	w16, w2, w16, lt
101181148:	8e 01 1d b8	stur	w14, [x12, #-0x30]
10118114c:	8f 81 1e b8	stur	w15, [x12, #-0x18]
101181150:	3f 06 00 71	cmp	w17, #0x1
101181154:	6e b0 91 1a	csel	w14, w3, w17, lt
101181158:	90 01 00 b9	str	w16, [x12]
10118115c:	8e 19 00 b9	str	w14, [x12, #0x18]
101181160:	8c 81 01 91	add	x12, x12, #0x60
101181164:	ad 11 00 f1	subs	x13, x13, #0x4
101181168:	a1 fc ff 54	b.ne	0x1011810fc
10118116c:	8b a1 ff b4	cbz	x11, 0x10118059c
101181170:	0b 03 80 52	mov	w11, #0x18
101181174:	49 25 0b 9b	madd	x9, x10, x11, x9
101181178:	29 31 00 91	add	x9, x9, #0xc
10118117c:	08 01 0a cb	sub	x8, x8, x10
101181180:	2a 01 40 b9	ldr	w10, [x9]
101181184:	eb 03 41 b9	ldr	w11, [sp, #0x100]
101181188:	4a 01 0b 4b	sub	w10, w10, w11
10118118c:	4b 11 00 11	add	w11, w10, #0x4
101181190:	5f 05 00 71	cmp	w10, #0x1
101181194:	6a b1 8a 1a	csel	w10, w11, w10, lt
101181198:	2a 85 01 b8	str	w10, [x9], #0x18
10118119c:	08 05 00 f1	subs	x8, x8, #0x1
1011811a0:	01 ff ff 54	b.ne	0x101181180
1011811a4:	fe fc ff 17	b	0x10118059c
1011811a8:	b4 df ba 97	bl	__ZSt28__throw_bad_array_new_lengthB6v15006v
1011811ac:	26 00 00 14	b	0x101181244
1011811b0:	e0 07 40 91	add	x0, sp, #0x1, lsl #12
1011811b4:	00 c0 19 91	add	x0, x0, #0x670
1011811b8:	a4 78 bf 97	bl	__ZNKSt3__16vectorIfNS_9allocatorIfEEE20__throw_length_errorB6v15006Ev
1011811bc:	22 00 00 14	b	0x101181244
1011811c0:	ae df ba 97	bl	__ZSt28__throw_bad_array_new_lengthB6v15006v
1011811c4:	20 00 00 14	b	0x101181244
1011811c8:	ac df ba 97	bl	__ZSt28__throw_bad_array_new_lengthB6v15006v
1011811cc:	1e 00 00 14	b	0x101181244
1011811d0:	e0 03 10 91	add	x0, sp, #0x400
1011811d4:	87 b3 d0 97	bl	__ZNKSt3__16vectorIdNS_9allocatorIdEEE20__throw_length_errorB6v15006Ev
1011811d8:	1b 00 00 14	b	0x101181244
1011811dc:	e0 03 10 91	add	x0, sp, #0x400
1011811e0:	84 b3 d0 97	bl	__ZNKSt3__16vectorIdNS_9allocatorIdEEE20__throw_length_errorB6v15006Ev
1011811e4:	18 00 00 14	b	0x101181244
1011811e8:	a4 df ba 97	bl	__ZSt28__throw_bad_array_new_lengthB6v15006v
1011811ec:	16 00 00 14	b	0x101181244
1011811f0:	a2 df ba 97	bl	__ZSt28__throw_bad_array_new_lengthB6v15006v
1011811f4:	14 00 00 14	b	0x101181244
1011811f8:	e0 03 10 91	add	x0, sp, #0x400
1011811fc:	7d b3 d0 97	bl	__ZNKSt3__16vectorIdNS_9allocatorIdEEE20__throw_length_errorB6v15006Ev
101181200:	11 00 00 14	b	0x101181244
101181204:	e0 03 10 91	add	x0, sp, #0x400
101181208:	7a b3 d0 97	bl	__ZNKSt3__16vectorIdNS_9allocatorIdEEE20__throw_length_errorB6v15006Ev
10118120c:	0e 00 00 14	b	0x101181244
101181210:	e0 03 10 91	add	x0, sp, #0x400
101181214:	77 b3 d0 97	bl	__ZNKSt3__16vectorIdNS_9allocatorIdEEE20__throw_length_errorB6v15006Ev
101181218:	0b 00 00 14	b	0x101181244
10118121c:	e0 03 10 91	add	x0, sp, #0x400
101181220:	74 b3 d0 97	bl	__ZNKSt3__16vectorIdNS_9allocatorIdEEE20__throw_length_errorB6v15006Ev
101181224:	08 00 00 14	b	0x101181244
101181228:	94 df ba 97	bl	__ZSt28__throw_bad_array_new_lengthB6v15006v
10118122c:	06 00 00 14	b	0x101181244
101181230:	92 df ba 97	bl	__ZSt28__throw_bad_array_new_lengthB6v15006v
101181234:	04 00 00 14	b	0x101181244
101181238:	90 df ba 97	bl	__ZSt28__throw_bad_array_new_lengthB6v15006v
10118123c:	02 00 00 14	b	0x101181244
101181240:	8e df ba 97	bl	__ZSt28__throw_bad_array_new_lengthB6v15006v
101181244:	20 00 20 d4	brk	#0x1
101181248:	3a 01 00 14	b	0x101181730
10118124c:	f3 03 00 aa	mov	x19, x0
101181250:	e0 df 41 f9	ldr	x0, [sp, #0x3b8]
101181254:	a0 05 00 b4	cbz	x0, 0x101181308
101181258:	2a 02 00 14	b	0x101181b00
10118125c:	f3 03 00 aa	mov	x19, x0
101181260:	e0 2b 43 f9	ldr	x0, [sp, #0x650]
101181264:	20 2a 00 b4	cbz	x0, 0x1011817a8
101181268:	42 02 00 14	b	0x101181b70
10118126c:	f3 03 00 aa	mov	x19, x0
101181270:	e0 c3 40 f9	ldr	x0, [sp, #0x180]
101181274:	40 05 00 b5	cbnz	x0, 0x10118131c
101181278:	e0 cf 40 f9	ldr	x0, [sp, #0x198]
10118127c:	00 06 00 b5	cbnz	x0, 0x10118133c
101181280:	e0 db 40 f9	ldr	x0, [sp, #0x1b0]
101181284:	c0 06 00 b5	cbnz	x0, 0x10118135c
101181288:	e0 e7 40 f9	ldr	x0, [sp, #0x1c8]
10118128c:	00 07 00 b5	cbnz	x0, 0x10118136c
101181290:	e0 f3 40 f9	ldr	x0, [sp, #0x1e0]
101181294:	40 0d 00 b5	cbnz	x0, 0x10118143c
101181298:	e0 ff 40 f9	ldr	x0, [sp, #0x1f8]
10118129c:	80 0d 00 b5	cbnz	x0, 0x10118144c
1011812a0:	e0 0b 41 f9	ldr	x0, [sp, #0x210]
1011812a4:	c0 0d 00 b5	cbnz	x0, 0x10118145c
1011812a8:	e0 17 41 f9	ldr	x0, [sp, #0x228]
1011812ac:	00 34 00 b5	cbnz	x0, 0x10118192c
1011812b0:	e0 23 41 f9	ldr	x0, [sp, #0x240]
1011812b4:	40 34 00 b5	cbnz	x0, 0x10118193c
1011812b8:	e0 2f 41 f9	ldr	x0, [sp, #0x258]
1011812bc:	80 34 00 b5	cbnz	x0, 0x10118194c
1011812c0:	e0 3b 41 f9	ldr	x0, [sp, #0x270]
1011812c4:	c0 34 00 b5	cbnz	x0, 0x10118195c
1011812c8:	e0 47 41 f9	ldr	x0, [sp, #0x288]
1011812cc:	00 35 00 b5	cbnz	x0, 0x10118196c
1011812d0:	e0 53 41 f9	ldr	x0, [sp, #0x2a0]
1011812d4:	40 35 00 b5	cbnz	x0, 0x10118197c
1011812d8:	e0 5f 41 f9	ldr	x0, [sp, #0x2b8]
1011812dc:	80 35 00 b5	cbnz	x0, 0x10118198c
1011812e0:	e0 6b 41 f9	ldr	x0, [sp, #0x2d0]
1011812e4:	c0 35 00 b5	cbnz	x0, 0x10118199c
1011812e8:	e0 77 41 f9	ldr	x0, [sp, #0x2e8]
1011812ec:	00 36 00 b5	cbnz	x0, 0x1011819ac
1011812f0:	e0 83 41 f9	ldr	x0, [sp, #0x300]
1011812f4:	40 36 00 b5	cbnz	x0, 0x1011819bc
1011812f8:	e0 8f 41 f9	ldr	x0, [sp, #0x318]
1011812fc:	80 36 00 b5	cbnz	x0, 0x1011819cc
101181300:	e0 df 41 f9	ldr	x0, [sp, #0x3b8]
101181304:	e0 3f 00 b5	cbnz	x0, 0x101181b00
101181308:	e0 eb 41 f9	ldr	x0, [sp, #0x3d0]
10118130c:	20 40 00 b5	cbnz	x0, 0x101181b10
101181310:	e0 f7 41 f9	ldr	x0, [sp, #0x3e8]
101181314:	60 40 00 b5	cbnz	x0, 0x101181b20
101181318:	04 02 00 14	b	0x101181b28
10118131c:	e0 c7 00 f9	str	x0, [sp, #0x188]
101181320:	e6 41 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
101181324:	e0 cf 40 f9	ldr	x0, [sp, #0x198]
101181328:	c0 fa ff b4	cbz	x0, 0x101181280
10118132c:	04 00 00 14	b	0x10118133c
101181330:	f3 03 00 aa	mov	x19, x0
101181334:	e0 cf 40 f9	ldr	x0, [sp, #0x198]
101181338:	40 fa ff b4	cbz	x0, 0x101181280
10118133c:	e0 d3 00 f9	str	x0, [sp, #0x1a0]
101181340:	de 41 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
101181344:	e0 db 40 f9	ldr	x0, [sp, #0x1b0]
101181348:	00 fa ff b4	cbz	x0, 0x101181288
10118134c:	04 00 00 14	b	0x10118135c
101181350:	f3 03 00 aa	mov	x19, x0
101181354:	e0 db 40 f9	ldr	x0, [sp, #0x1b0]
101181358:	80 f9 ff b4	cbz	x0, 0x101181288
10118135c:	e0 df 00 f9	str	x0, [sp, #0x1b8]
101181360:	d6 41 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
101181364:	e0 e7 40 f9	ldr	x0, [sp, #0x1c8]
101181368:	40 f9 ff b4	cbz	x0, 0x101181290
10118136c:	e0 eb 00 f9	str	x0, [sp, #0x1d0]
101181370:	d2 41 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
101181374:	e0 f3 40 f9	ldr	x0, [sp, #0x1e0]
101181378:	00 f9 ff b4	cbz	x0, 0x101181298
10118137c:	30 00 00 14	b	0x10118143c
101181380:	f3 03 00 aa	mov	x19, x0
101181384:	e0 e7 40 f9	ldr	x0, [sp, #0x1c8]
101181388:	40 f8 ff b4	cbz	x0, 0x101181290
10118138c:	f8 ff ff 17	b	0x10118136c
101181390:	f3 03 00 aa	mov	x19, x0
101181394:	fb 00 00 14	b	0x101181780
101181398:	f3 03 00 aa	mov	x19, x0
10118139c:	e0 03 42 f9	ldr	x0, [sp, #0x400]
1011813a0:	80 1f 00 b4	cbz	x0, 0x101181790
1011813a4:	e7 01 00 14	b	0x101181b40
1011813a8:	03 00 00 14	b	0x1011813b4
1011813ac:	f3 03 00 aa	mov	x19, x0
1011813b0:	f4 00 00 14	b	0x101181780
1011813b4:	f3 03 00 aa	mov	x19, x0
1011813b8:	e0 df 41 f9	ldr	x0, [sp, #0x3b8]
1011813bc:	20 1e 00 b4	cbz	x0, 0x101181780
1011813c0:	e0 e3 01 f9	str	x0, [sp, #0x3c0]
1011813c4:	ee 00 00 14	b	0x10118177c
1011813c8:	f3 03 00 aa	mov	x19, x0
1011813cc:	e0 03 42 f9	ldr	x0, [sp, #0x400]
1011813d0:	00 1e 00 b4	cbz	x0, 0x101181790
1011813d4:	db 01 00 14	b	0x101181b40
1011813d8:	f3 03 00 aa	mov	x19, x0
1011813dc:	e9 00 00 14	b	0x101181780
1011813e0:	f3 03 00 aa	mov	x19, x0
1011813e4:	e0 03 42 f9	ldr	x0, [sp, #0x400]
1011813e8:	40 1d 00 b4	cbz	x0, 0x101181790
1011813ec:	d5 01 00 14	b	0x101181b40
1011813f0:	f3 03 00 aa	mov	x19, x0
1011813f4:	e0 03 42 f9	ldr	x0, [sp, #0x400]
1011813f8:	c0 1c 00 b4	cbz	x0, 0x101181790
1011813fc:	d1 01 00 14	b	0x101181b40
101181400:	f3 03 00 aa	mov	x19, x0
101181404:	e0 03 42 f9	ldr	x0, [sp, #0x400]
101181408:	40 1c 00 b4	cbz	x0, 0x101181790
10118140c:	cd 01 00 14	b	0x101181b40
101181410:	f3 03 00 aa	mov	x19, x0
101181414:	e0 03 42 f9	ldr	x0, [sp, #0x400]
101181418:	c0 1b 00 b4	cbz	x0, 0x101181790
10118141c:	c9 01 00 14	b	0x101181b40
101181420:	f3 03 00 aa	mov	x19, x0
101181424:	e0 03 42 f9	ldr	x0, [sp, #0x400]
101181428:	40 1b 00 b4	cbz	x0, 0x101181790
10118142c:	c5 01 00 14	b	0x101181b40
101181430:	f3 03 00 aa	mov	x19, x0
101181434:	e0 f3 40 f9	ldr	x0, [sp, #0x1e0]
101181438:	00 f3 ff b4	cbz	x0, 0x101181298
10118143c:	e0 f7 00 f9	str	x0, [sp, #0x1e8]
101181440:	9e 41 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
101181444:	e0 ff 40 f9	ldr	x0, [sp, #0x1f8]
101181448:	c0 f2 ff b4	cbz	x0, 0x1011812a0
10118144c:	e0 03 01 f9	str	x0, [sp, #0x200]
101181450:	9a 41 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
101181454:	e0 0b 41 f9	ldr	x0, [sp, #0x210]
101181458:	80 f2 ff b4	cbz	x0, 0x1011812a8
10118145c:	e0 0f 01 f9	str	x0, [sp, #0x218]
101181460:	96 41 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
101181464:	e0 17 41 f9	ldr	x0, [sp, #0x228]
101181468:	40 f2 ff b4	cbz	x0, 0x1011812b0
10118146c:	30 01 00 14	b	0x10118192c
101181470:	f3 03 00 aa	mov	x19, x0
101181474:	e0 ff 40 f9	ldr	x0, [sp, #0x1f8]
101181478:	40 f1 ff b4	cbz	x0, 0x1011812a0
10118147c:	f4 ff ff 17	b	0x10118144c
101181480:	f3 03 00 aa	mov	x19, x0
101181484:	e0 0b 41 f9	ldr	x0, [sp, #0x210]
101181488:	00 f1 ff b4	cbz	x0, 0x1011812a8
10118148c:	f4 ff ff 17	b	0x10118145c
101181490:	f3 03 00 aa	mov	x19, x0
101181494:	e0 17 41 f9	ldr	x0, [sp, #0x228]
101181498:	c0 f0 ff b4	cbz	x0, 0x1011812b0
10118149c:	24 01 00 14	b	0x10118192c
1011814a0:	f3 03 00 aa	mov	x19, x0
1011814a4:	e0 17 41 f9	ldr	x0, [sp, #0x228]
1011814a8:	40 f0 ff b4	cbz	x0, 0x1011812b0
1011814ac:	20 01 00 14	b	0x10118192c
1011814b0:	f3 03 00 aa	mov	x19, x0
1011814b4:	e0 23 41 f9	ldr	x0, [sp, #0x240]
1011814b8:	00 f0 ff b4	cbz	x0, 0x1011812b8
1011814bc:	20 01 00 14	b	0x10118193c
1011814c0:	f3 03 00 aa	mov	x19, x0
1011814c4:	e0 2f 41 f9	ldr	x0, [sp, #0x258]
1011814c8:	c0 ef ff b4	cbz	x0, 0x1011812c0
1011814cc:	20 01 00 14	b	0x10118194c
1011814d0:	f3 03 00 aa	mov	x19, x0
1011814d4:	e0 3b 41 f9	ldr	x0, [sp, #0x270]
1011814d8:	80 ef ff b4	cbz	x0, 0x1011812c8
1011814dc:	20 01 00 14	b	0x10118195c
1011814e0:	f3 03 00 aa	mov	x19, x0
1011814e4:	e0 47 41 f9	ldr	x0, [sp, #0x288]
1011814e8:	40 ef ff b4	cbz	x0, 0x1011812d0
1011814ec:	20 01 00 14	b	0x10118196c
1011814f0:	f3 03 00 aa	mov	x19, x0
1011814f4:	e0 53 41 f9	ldr	x0, [sp, #0x2a0]
1011814f8:	00 ef ff b4	cbz	x0, 0x1011812d8
1011814fc:	20 01 00 14	b	0x10118197c
101181500:	f3 03 00 aa	mov	x19, x0
101181504:	e0 5f 41 f9	ldr	x0, [sp, #0x2b8]
101181508:	c0 ee ff b4	cbz	x0, 0x1011812e0
10118150c:	20 01 00 14	b	0x10118198c
101181510:	f3 03 00 aa	mov	x19, x0
101181514:	e0 6b 41 f9	ldr	x0, [sp, #0x2d0]
101181518:	80 ee ff b4	cbz	x0, 0x1011812e8
10118151c:	20 01 00 14	b	0x10118199c
101181520:	f3 03 00 aa	mov	x19, x0
101181524:	e0 77 41 f9	ldr	x0, [sp, #0x2e8]
101181528:	40 ee ff b4	cbz	x0, 0x1011812f0
10118152c:	20 01 00 14	b	0x1011819ac
101181530:	f3 03 00 aa	mov	x19, x0
101181534:	e0 83 41 f9	ldr	x0, [sp, #0x300]
101181538:	00 ee ff b4	cbz	x0, 0x1011812f8
10118153c:	20 01 00 14	b	0x1011819bc
101181540:	f3 03 00 aa	mov	x19, x0
101181544:	e0 8f 41 f9	ldr	x0, [sp, #0x318]
101181548:	c0 ed ff b4	cbz	x0, 0x101181300
10118154c:	20 01 00 14	b	0x1011819cc
101181550:	f3 03 00 aa	mov	x19, x0
101181554:	e0 df 41 f9	ldr	x0, [sp, #0x3b8]
101181558:	80 ed ff b4	cbz	x0, 0x101181308
10118155c:	69 01 00 14	b	0x101181b00
101181560:	36 00 00 14	b	0x101181638
101181564:	f3 03 00 aa	mov	x19, x0
101181568:	62 01 00 14	b	0x101181af0
10118156c:	f3 03 00 aa	mov	x19, x0
101181570:	e0 df 41 f9	ldr	x0, [sp, #0x3b8]
101181574:	a0 ec ff b4	cbz	x0, 0x101181308
101181578:	62 01 00 14	b	0x101181b00
10118157c:	f3 03 00 aa	mov	x19, x0
101181580:	e0 eb 41 f9	ldr	x0, [sp, #0x3d0]
101181584:	60 ec ff b4	cbz	x0, 0x101181310
101181588:	62 01 00 14	b	0x101181b10
10118158c:	f3 03 00 aa	mov	x19, x0
101181590:	e0 f7 41 f9	ldr	x0, [sp, #0x3e8]
101181594:	60 2c 00 b5	cbnz	x0, 0x101181b20
101181598:	64 01 00 14	b	0x101181b28
10118159c:	f3 03 00 aa	mov	x19, x0
1011815a0:	62 01 00 14	b	0x101181b28
1011815a4:	f3 03 00 aa	mov	x19, x0
1011815a8:	62 01 00 14	b	0x101181b30
1011815ac:	f3 03 00 aa	mov	x19, x0
1011815b0:	e0 a3 0f 91	add	x0, sp, #0x3e8
1011815b4:	60 01 00 14	b	0x101181b34
1011815b8:	f3 03 00 aa	mov	x19, x0
1011815bc:	e0 03 42 f9	ldr	x0, [sp, #0x400]
1011815c0:	80 0e 00 b4	cbz	x0, 0x101181790
1011815c4:	5f 01 00 14	b	0x101181b40
1011815c8:	f3 03 00 aa	mov	x19, x0
1011815cc:	e0 03 42 f9	ldr	x0, [sp, #0x400]
1011815d0:	00 0e 00 b4	cbz	x0, 0x101181790
1011815d4:	5b 01 00 14	b	0x101181b40
1011815d8:	f3 03 00 aa	mov	x19, x0
1011815dc:	e0 2b 42 f9	ldr	x0, [sp, #0x450]
1011815e0:	00 0e 00 b4	cbz	x0, 0x1011817a0
1011815e4:	5f 01 00 14	b	0x101181b60
1011815e8:	f3 03 00 aa	mov	x19, x0
1011815ec:	e0 2b 43 f9	ldr	x0, [sp, #0x650]
1011815f0:	c0 0d 00 b4	cbz	x0, 0x1011817a8
1011815f4:	5f 01 00 14	b	0x101181b70
1011815f8:	f3 03 00 aa	mov	x19, x0
1011815fc:	e0 2b 44 f9	ldr	x0, [sp, #0x850]
101181600:	80 0d 00 b4	cbz	x0, 0x1011817b0
101181604:	5f 01 00 14	b	0x101181b80
101181608:	f3 03 00 aa	mov	x19, x0
10118160c:	e0 2b 45 f9	ldr	x0, [sp, #0xa50]
101181610:	00 2c 00 b5	cbnz	x0, 0x101181b90
101181614:	9c 01 00 14	b	0x101181c84
101181618:	f3 03 00 aa	mov	x19, x0
10118161c:	e0 03 42 f9	ldr	x0, [sp, #0x400]
101181620:	80 0b 00 b4	cbz	x0, 0x101181790
101181624:	47 01 00 14	b	0x101181b40
101181628:	f3 03 00 aa	mov	x19, x0
10118162c:	e0 03 42 f9	ldr	x0, [sp, #0x400]
101181630:	00 0b 00 b4	cbz	x0, 0x101181790
101181634:	43 01 00 14	b	0x101181b40
101181638:	f3 03 00 aa	mov	x19, x0
10118163c:	1f 01 00 14	b	0x101181ab8
101181640:	f3 03 00 aa	mov	x19, x0
101181644:	3b 01 00 14	b	0x101181b30
101181648:	f3 03 00 aa	mov	x19, x0
10118164c:	e0 03 42 f9	ldr	x0, [sp, #0x400]
101181650:	00 0a 00 b4	cbz	x0, 0x101181790
101181654:	3b 01 00 14	b	0x101181b40
101181658:	f3 03 00 aa	mov	x19, x0
10118165c:	e0 03 42 f9	ldr	x0, [sp, #0x400]
101181660:	80 09 00 b4	cbz	x0, 0x101181790
101181664:	37 01 00 14	b	0x101181b40
101181668:	f3 03 00 aa	mov	x19, x0
10118166c:	e0 03 42 f9	ldr	x0, [sp, #0x400]
101181670:	00 09 00 b4	cbz	x0, 0x101181790
101181674:	33 01 00 14	b	0x101181b40
101181678:	f3 03 00 aa	mov	x19, x0
10118167c:	e0 03 42 f9	ldr	x0, [sp, #0x400]
101181680:	80 08 00 b4	cbz	x0, 0x101181790
101181684:	2f 01 00 14	b	0x101181b40
101181688:	08 00 00 14	b	0x1011816a8
10118168c:	f3 03 00 aa	mov	x19, x0
101181690:	e0 07 40 91	add	x0, sp, #0x1, lsl #12
101181694:	00 c0 11 91	add	x0, x0, #0x470
101181698:	54 01 00 14	b	0x101181be8
10118169c:	6f 01 00 14	b	0x101181c58
1011816a0:	24 00 00 14	b	0x101181730
1011816a4:	6d 01 00 14	b	0x101181c58
1011816a8:	f3 03 00 aa	mov	x19, x0
1011816ac:	4d 01 00 14	b	0x101181be0
1011816b0:	f3 03 00 aa	mov	x19, x0
1011816b4:	e0 03 42 f9	ldr	x0, [sp, #0x400]
1011816b8:	c0 06 00 b4	cbz	x0, 0x101181790
1011816bc:	21 01 00 14	b	0x101181b40
1011816c0:	f3 03 00 aa	mov	x19, x0
1011816c4:	e0 03 42 f9	ldr	x0, [sp, #0x400]
1011816c8:	40 06 00 b4	cbz	x0, 0x101181790
1011816cc:	1d 01 00 14	b	0x101181b40
1011816d0:	62 01 00 14	b	0x101181c58
1011816d4:	f3 03 00 aa	mov	x19, x0
1011816d8:	e0 03 42 f9	ldr	x0, [sp, #0x400]
1011816dc:	a0 05 00 b4	cbz	x0, 0x101181790
1011816e0:	18 01 00 14	b	0x101181b40
1011816e4:	5d 01 00 14	b	0x101181c58
1011816e8:	f3 03 00 aa	mov	x19, x0
1011816ec:	e0 df 41 f9	ldr	x0, [sp, #0x3b8]
1011816f0:	c0 e0 ff b4	cbz	x0, 0x101181308
1011816f4:	03 01 00 14	b	0x101181b00
1011816f8:	58 01 00 14	b	0x101181c58
1011816fc:	57 01 00 14	b	0x101181c58
101181700:	f3 03 00 aa	mov	x19, x0
101181704:	e0 03 42 f9	ldr	x0, [sp, #0x400]
101181708:	40 04 00 b4	cbz	x0, 0x101181790
10118170c:	0d 01 00 14	b	0x101181b40
101181710:	f3 03 00 aa	mov	x19, x0
101181714:	e0 03 42 f9	ldr	x0, [sp, #0x400]
101181718:	c0 03 00 b4	cbz	x0, 0x101181790
10118171c:	09 01 00 14	b	0x101181b40
101181720:	f3 03 00 aa	mov	x19, x0
101181724:	e8 73 40 f9	ldr	x8, [sp, #0xe0]
101181728:	68 2a 00 b4	cbz	x8, 0x101181c74
10118172c:	5f 01 00 14	b	0x101181ca8
101181730:	f3 03 00 aa	mov	x19, x0
101181734:	e0 3b 4b f9	ldr	x0, [sp, #0x1670]
101181738:	60 2a 00 b4	cbz	x0, 0x101181c84
10118173c:	e0 3f 0b f9	str	x0, [sp, #0x1678]
101181740:	de 40 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
101181744:	e0 03 13 aa	mov	x0, x19
101181748:	69 3e 8d 94	bl	0x1034d10ec ; symbol stub for: __Unwind_Resume
10118174c:	43 01 00 14	b	0x101181c58
101181750:	42 01 00 14	b	0x101181c58
101181754:	f3 03 00 aa	mov	x19, x0
101181758:	e0 a3 0f 91	add	x0, sp, #0x3e8
10118175c:	e8 a3 4c 94	bl	__ZN4juce6StringD1Ev
101181760:	35 00 00 14	b	0x101181834
101181764:	f3 03 00 aa	mov	x19, x0
101181768:	f0 00 00 14	b	0x101181b28
10118176c:	f3 03 00 aa	mov	x19, x0
101181770:	e0 eb 41 f9	ldr	x0, [sp, #0x3d0]
101181774:	60 00 00 b4	cbz	x0, 0x101181780
101181778:	e0 ef 01 f9	str	x0, [sp, #0x3d8]
10118177c:	cf 40 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
101181780:	e0 f7 41 f9	ldr	x0, [sp, #0x3e8]
101181784:	c0 01 00 b5	cbnz	x0, 0x1011817bc
101181788:	e0 03 42 f9	ldr	x0, [sp, #0x400]
10118178c:	a0 1d 00 b5	cbnz	x0, 0x101181b40
101181790:	e0 0f 42 f9	ldr	x0, [sp, #0x418]
101181794:	e0 1d 00 b5	cbnz	x0, 0x101181b50
101181798:	e0 2b 42 f9	ldr	x0, [sp, #0x450]
10118179c:	20 1e 00 b5	cbnz	x0, 0x101181b60
1011817a0:	e0 2b 43 f9	ldr	x0, [sp, #0x650]
1011817a4:	60 1e 00 b5	cbnz	x0, 0x101181b70
1011817a8:	e0 2b 44 f9	ldr	x0, [sp, #0x850]
1011817ac:	a0 1e 00 b5	cbnz	x0, 0x101181b80
1011817b0:	e0 2b 45 f9	ldr	x0, [sp, #0xa50]
1011817b4:	e0 1e 00 b5	cbnz	x0, 0x101181b90
1011817b8:	33 01 00 14	b	0x101181c84
1011817bc:	e0 fb 01 f9	str	x0, [sp, #0x3f0]
1011817c0:	be 40 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
1011817c4:	e0 03 42 f9	ldr	x0, [sp, #0x400]
1011817c8:	40 fe ff b4	cbz	x0, 0x101181790
1011817cc:	dd 00 00 14	b	0x101181b40
1011817d0:	22 01 00 14	b	0x101181c58
1011817d4:	21 01 00 14	b	0x101181c58
1011817d8:	f3 03 00 aa	mov	x19, x0
1011817dc:	e0 03 42 f9	ldr	x0, [sp, #0x400]
1011817e0:	80 fd ff b4	cbz	x0, 0x101181790
1011817e4:	d7 00 00 14	b	0x101181b40
1011817e8:	1c 01 00 14	b	0x101181c58
1011817ec:	1b 01 00 14	b	0x101181c58
1011817f0:	f3 03 00 aa	mov	x19, x0
1011817f4:	e0 df 41 f9	ldr	x0, [sp, #0x3b8]
1011817f8:	80 d8 ff b4	cbz	x0, 0x101181308
1011817fc:	c1 00 00 14	b	0x101181b00
101181800:	16 01 00 14	b	0x101181c58
101181804:	15 01 00 14	b	0x101181c58
101181808:	f3 03 00 aa	mov	x19, x0
10118180c:	e0 03 42 f9	ldr	x0, [sp, #0x400]
101181810:	00 fc ff b4	cbz	x0, 0x101181790
101181814:	cb 00 00 14	b	0x101181b40
101181818:	f3 03 00 aa	mov	x19, x0
10118181c:	e0 03 42 f9	ldr	x0, [sp, #0x400]
101181820:	80 fb ff b4	cbz	x0, 0x101181790
101181824:	c7 00 00 14	b	0x101181b40
101181828:	9c 00 00 14	b	0x101181a98
10118182c:	0b 01 00 14	b	0x101181c58
101181830:	f3 03 00 aa	mov	x19, x0
101181834:	e0 43 0f 91	add	x0, sp, #0x3d0
101181838:	b1 a3 4c 94	bl	__ZN4juce6StringD1Ev
10118183c:	bb 00 00 14	b	0x101181b28
101181840:	f3 03 00 aa	mov	x19, x0
101181844:	9b 00 00 14	b	0x101181ab0
101181848:	f3 03 00 aa	mov	x19, x0
10118184c:	e0 03 0c 91	add	x0, sp, #0x300
101181850:	ab a3 4c 94	bl	__ZN4juce6StringD1Ev
101181854:	95 00 00 14	b	0x101181aa8
101181858:	00 01 00 14	b	0x101181c58
10118185c:	ff 00 00 14	b	0x101181c58
101181860:	fe 00 00 14	b	0x101181c58
101181864:	f3 03 00 aa	mov	x19, x0
101181868:	e0 03 42 f9	ldr	x0, [sp, #0x400]
10118186c:	20 f9 ff b4	cbz	x0, 0x101181790
101181870:	b4 00 00 14	b	0x101181b40
101181874:	f3 03 00 aa	mov	x19, x0
101181878:	e0 03 42 f9	ldr	x0, [sp, #0x400]
10118187c:	a0 f8 ff b4	cbz	x0, 0x101181790
101181880:	b0 00 00 14	b	0x101181b40
101181884:	f5 00 00 14	b	0x101181c58
101181888:	f3 03 00 aa	mov	x19, x0
10118188c:	e0 03 42 f9	ldr	x0, [sp, #0x400]
101181890:	60 1f 00 b4	cbz	x0, 0x101181c7c
101181894:	09 01 00 14	b	0x101181cb8
101181898:	f3 03 00 aa	mov	x19, x0
10118189c:	e8 73 40 f9	ldr	x8, [sp, #0xe0]
1011818a0:	a8 1e 00 b4	cbz	x8, 0x101181c74
1011818a4:	01 01 00 14	b	0x101181ca8
1011818a8:	f3 03 00 aa	mov	x19, x0
1011818ac:	e0 0f 42 f9	ldr	x0, [sp, #0x418]
1011818b0:	a0 1e 00 b4	cbz	x0, 0x101181c84
1011818b4:	04 01 00 14	b	0x101181cc4
1011818b8:	f3 03 00 aa	mov	x19, x0
1011818bc:	e0 f7 41 f9	ldr	x0, [sp, #0x3e8]
1011818c0:	60 1d 00 b4	cbz	x0, 0x101181c6c
1011818c4:	f6 00 00 14	b	0x101181c9c
1011818c8:	f3 03 00 aa	mov	x19, x0
1011818cc:	e8 73 40 f9	ldr	x8, [sp, #0xe0]
1011818d0:	28 1d 00 b4	cbz	x8, 0x101181c74
1011818d4:	f5 00 00 14	b	0x101181ca8
1011818d8:	f3 03 00 aa	mov	x19, x0
1011818dc:	e0 0f 42 f9	ldr	x0, [sp, #0x418]
1011818e0:	20 1d 00 b4	cbz	x0, 0x101181c84
1011818e4:	f8 00 00 14	b	0x101181cc4
1011818e8:	f3 03 00 aa	mov	x19, x0
1011818ec:	e0 df 41 f9	ldr	x0, [sp, #0x3b8]
1011818f0:	c0 d0 ff b4	cbz	x0, 0x101181308
1011818f4:	83 00 00 14	b	0x101181b00
1011818f8:	3e 00 00 14	b	0x1011819f0
1011818fc:	f3 03 00 aa	mov	x19, x0
101181900:	7c 00 00 14	b	0x101181af0
101181904:	f3 03 00 aa	mov	x19, x0
101181908:	78 00 00 14	b	0x101181ae8
10118190c:	43 00 00 14	b	0x101181a18
101181910:	f3 03 00 aa	mov	x19, x0
101181914:	e0 17 41 f9	ldr	x0, [sp, #0x228]
101181918:	c0 cc ff b4	cbz	x0, 0x1011812b0
10118191c:	04 00 00 14	b	0x10118192c
101181920:	f3 03 00 aa	mov	x19, x0
101181924:	e0 17 41 f9	ldr	x0, [sp, #0x228]
101181928:	40 cc ff b4	cbz	x0, 0x1011812b0
10118192c:	e0 1b 01 f9	str	x0, [sp, #0x230]
101181930:	62 40 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
101181934:	e0 23 41 f9	ldr	x0, [sp, #0x240]
101181938:	00 cc ff b4	cbz	x0, 0x1011812b8
10118193c:	e0 27 01 f9	str	x0, [sp, #0x248]
101181940:	5e 40 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
101181944:	e0 2f 41 f9	ldr	x0, [sp, #0x258]
101181948:	c0 cb ff b4	cbz	x0, 0x1011812c0
10118194c:	e0 33 01 f9	str	x0, [sp, #0x260]
101181950:	5a 40 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
101181954:	e0 3b 41 f9	ldr	x0, [sp, #0x270]
101181958:	80 cb ff b4	cbz	x0, 0x1011812c8
10118195c:	e0 3f 01 f9	str	x0, [sp, #0x278]
101181960:	56 40 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
101181964:	e0 47 41 f9	ldr	x0, [sp, #0x288]
101181968:	40 cb ff b4	cbz	x0, 0x1011812d0
10118196c:	e0 4b 01 f9	str	x0, [sp, #0x290]
101181970:	52 40 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
101181974:	e0 53 41 f9	ldr	x0, [sp, #0x2a0]
101181978:	00 cb ff b4	cbz	x0, 0x1011812d8
10118197c:	e0 57 01 f9	str	x0, [sp, #0x2a8]
101181980:	4e 40 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
101181984:	e0 5f 41 f9	ldr	x0, [sp, #0x2b8]
101181988:	c0 ca ff b4	cbz	x0, 0x1011812e0
10118198c:	e0 63 01 f9	str	x0, [sp, #0x2c0]
101181990:	4a 40 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
101181994:	e0 6b 41 f9	ldr	x0, [sp, #0x2d0]
101181998:	80 ca ff b4	cbz	x0, 0x1011812e8
10118199c:	e0 6f 01 f9	str	x0, [sp, #0x2d8]
1011819a0:	46 40 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
1011819a4:	e0 77 41 f9	ldr	x0, [sp, #0x2e8]
1011819a8:	40 ca ff b4	cbz	x0, 0x1011812f0
1011819ac:	e0 7b 01 f9	str	x0, [sp, #0x2f0]
1011819b0:	42 40 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
1011819b4:	e0 83 41 f9	ldr	x0, [sp, #0x300]
1011819b8:	00 ca ff b4	cbz	x0, 0x1011812f8
1011819bc:	e0 87 01 f9	str	x0, [sp, #0x308]
1011819c0:	3e 40 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
1011819c4:	e0 8f 41 f9	ldr	x0, [sp, #0x318]
1011819c8:	c0 c9 ff b4	cbz	x0, 0x101181300
1011819cc:	e0 93 01 f9	str	x0, [sp, #0x320]
1011819d0:	3a 40 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
1011819d4:	e0 df 41 f9	ldr	x0, [sp, #0x3b8]
1011819d8:	80 c9 ff b4	cbz	x0, 0x101181308
1011819dc:	49 00 00 14	b	0x101181b00
1011819e0:	f3 03 00 aa	mov	x19, x0
1011819e4:	e0 df 41 f9	ldr	x0, [sp, #0x3b8]
1011819e8:	00 c9 ff b4	cbz	x0, 0x101181308
1011819ec:	45 00 00 14	b	0x101181b00
1011819f0:	f3 03 00 aa	mov	x19, x0
1011819f4:	e0 03 0c 91	add	x0, sp, #0x300
1011819f8:	41 a3 4c 94	bl	__ZN4juce6StringD1Ev
1011819fc:	e0 df 41 f9	ldr	x0, [sp, #0x3b8]
101181a00:	40 c8 ff b4	cbz	x0, 0x101181308
101181a04:	3f 00 00 14	b	0x101181b00
101181a08:	f3 03 00 aa	mov	x19, x0
101181a0c:	39 00 00 14	b	0x101181af0
101181a10:	f3 03 00 aa	mov	x19, x0
101181a14:	35 00 00 14	b	0x101181ae8
101181a18:	f3 03 00 aa	mov	x19, x0
101181a1c:	e0 a3 0b 91	add	x0, sp, #0x2e8
101181a20:	37 a3 4c 94	bl	__ZN4juce6StringD1Ev
101181a24:	2f 00 00 14	b	0x101181ae0
101181a28:	f3 03 00 aa	mov	x19, x0
101181a2c:	e0 df 41 f9	ldr	x0, [sp, #0x3b8]
101181a30:	c0 c6 ff b4	cbz	x0, 0x101181308
101181a34:	33 00 00 14	b	0x101181b00
101181a38:	88 00 00 14	b	0x101181c58
101181a3c:	87 00 00 14	b	0x101181c58
101181a40:	f3 03 00 aa	mov	x19, x0
101181a44:	e0 03 42 f9	ldr	x0, [sp, #0x400]
101181a48:	40 ea ff b4	cbz	x0, 0x101181790
101181a4c:	3d 00 00 14	b	0x101181b40
101181a50:	f3 03 00 aa	mov	x19, x0
101181a54:	e0 03 42 f9	ldr	x0, [sp, #0x400]
101181a58:	c0 e9 ff b4	cbz	x0, 0x101181790
101181a5c:	39 00 00 14	b	0x101181b40
101181a60:	7e 00 00 14	b	0x101181c58
101181a64:	7d 00 00 14	b	0x101181c58
101181a68:	f3 03 00 aa	mov	x19, x0
101181a6c:	e0 07 40 91	add	x0, sp, #0x1, lsl #12
101181a70:	00 c0 09 91	add	x0, x0, #0x270
101181a74:	22 a3 4c 94	bl	__ZN4juce6StringD1Ev
101181a78:	54 00 00 14	b	0x101181bc8
101181a7c:	07 00 00 14	b	0x101181a98
101181a80:	76 00 00 14	b	0x101181c58
101181a84:	75 00 00 14	b	0x101181c58
101181a88:	f3 03 00 aa	mov	x19, x0
101181a8c:	19 00 00 14	b	0x101181af0
101181a90:	f3 03 00 aa	mov	x19, x0
101181a94:	17 00 00 14	b	0x101181af0
101181a98:	f3 03 00 aa	mov	x19, x0
101181a9c:	4e 00 00 14	b	0x101181bd4
101181aa0:	6e 00 00 14	b	0x101181c58
101181aa4:	f3 03 00 aa	mov	x19, x0
101181aa8:	e0 a3 0b 91	add	x0, sp, #0x2e8
101181aac:	14 a3 4c 94	bl	__ZN4juce6StringD1Ev
101181ab0:	e0 63 0c 91	add	x0, sp, #0x318
101181ab4:	12 a3 4c 94	bl	__ZN4juce6StringD1Ev
101181ab8:	e0 83 0d 91	add	x0, sp, #0x360
101181abc:	10 a3 4c 94	bl	__ZN4juce6StringD1Ev
101181ac0:	e0 df 41 f9	ldr	x0, [sp, #0x3b8]
101181ac4:	20 c2 ff b4	cbz	x0, 0x101181308
101181ac8:	0e 00 00 14	b	0x101181b00
101181acc:	63 00 00 14	b	0x101181c58
101181ad0:	62 00 00 14	b	0x101181c58
101181ad4:	61 00 00 14	b	0x101181c58
101181ad8:	01 00 00 14	b	0x101181adc
101181adc:	f3 03 00 aa	mov	x19, x0
101181ae0:	e0 43 0b 91	add	x0, sp, #0x2d0
101181ae4:	06 a3 4c 94	bl	__ZN4juce6StringD1Ev
101181ae8:	e0 03 0c 91	add	x0, sp, #0x300
101181aec:	04 a3 4c 94	bl	__ZN4juce6StringD1Ev
101181af0:	e0 63 0c 91	add	x0, sp, #0x318
101181af4:	02 a3 4c 94	bl	__ZN4juce6StringD1Ev
101181af8:	e0 df 41 f9	ldr	x0, [sp, #0x3b8]
101181afc:	60 c0 ff b4	cbz	x0, 0x101181308
101181b00:	e0 e3 01 f9	str	x0, [sp, #0x3c0]
101181b04:	ed 3f 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
101181b08:	e0 eb 41 f9	ldr	x0, [sp, #0x3d0]
101181b0c:	20 c0 ff b4	cbz	x0, 0x101181310
101181b10:	e0 ef 01 f9	str	x0, [sp, #0x3d8]
101181b14:	e9 3f 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
101181b18:	e0 f7 41 f9	ldr	x0, [sp, #0x3e8]
101181b1c:	60 00 00 b4	cbz	x0, 0x101181b28
101181b20:	e0 fb 01 f9	str	x0, [sp, #0x3f0]
101181b24:	e5 3f 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
101181b28:	e0 63 0e 91	add	x0, sp, #0x398
101181b2c:	f4 a2 4c 94	bl	__ZN4juce6StringD1Ev
101181b30:	e0 c3 0e 91	add	x0, sp, #0x3b0
101181b34:	f2 a2 4c 94	bl	__ZN4juce6StringD1Ev
101181b38:	e0 03 42 f9	ldr	x0, [sp, #0x400]
101181b3c:	a0 e2 ff b4	cbz	x0, 0x101181790
101181b40:	e0 07 02 f9	str	x0, [sp, #0x408]
101181b44:	dd 3f 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
101181b48:	e0 0f 42 f9	ldr	x0, [sp, #0x418]
101181b4c:	60 e2 ff b4	cbz	x0, 0x101181798
101181b50:	e0 13 02 f9	str	x0, [sp, #0x420]
101181b54:	d9 3f 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
101181b58:	e0 2b 42 f9	ldr	x0, [sp, #0x450]
101181b5c:	20 e2 ff b4	cbz	x0, 0x1011817a0
101181b60:	e0 2f 02 f9	str	x0, [sp, #0x458]
101181b64:	d5 3f 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
101181b68:	e0 2b 43 f9	ldr	x0, [sp, #0x650]
101181b6c:	e0 e1 ff b4	cbz	x0, 0x1011817a8
101181b70:	e0 2f 03 f9	str	x0, [sp, #0x658]
101181b74:	d1 3f 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
101181b78:	e0 2b 44 f9	ldr	x0, [sp, #0x850]
101181b7c:	a0 e1 ff b4	cbz	x0, 0x1011817b0
101181b80:	e0 2f 04 f9	str	x0, [sp, #0x858]
101181b84:	cd 3f 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
101181b88:	e0 2b 45 f9	ldr	x0, [sp, #0xa50]
101181b8c:	c0 07 00 b4	cbz	x0, 0x101181c84
101181b90:	e0 2f 05 f9	str	x0, [sp, #0xa58]
101181b94:	c9 3f 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
101181b98:	e0 03 13 aa	mov	x0, x19
101181b9c:	54 3d 8d 94	bl	0x1034d10ec ; symbol stub for: __Unwind_Resume
101181ba0:	2e 00 00 14	b	0x101181c58
101181ba4:	f3 03 00 aa	mov	x19, x0
101181ba8:	e0 03 42 f9	ldr	x0, [sp, #0x400]
101181bac:	20 df ff b4	cbz	x0, 0x101181790
101181bb0:	e4 ff ff 17	b	0x101181b40
101181bb4:	f3 03 00 aa	mov	x19, x0
101181bb8:	e0 03 42 f9	ldr	x0, [sp, #0x400]
101181bbc:	a0 de ff b4	cbz	x0, 0x101181790
101181bc0:	e0 ff ff 17	b	0x101181b40
101181bc4:	f3 03 00 aa	mov	x19, x0
101181bc8:	e0 07 40 91	add	x0, sp, #0x1, lsl #12
101181bcc:	00 c0 01 91	add	x0, x0, #0x70
101181bd0:	cb a2 4c 94	bl	__ZN4juce6StringD1Ev
101181bd4:	e0 07 40 91	add	x0, sp, #0x1, lsl #12
101181bd8:	00 c0 11 91	add	x0, x0, #0x470
101181bdc:	c8 a2 4c 94	bl	__ZN4juce6StringD1Ev
101181be0:	e0 07 40 91	add	x0, sp, #0x1, lsl #12
101181be4:	00 c0 19 91	add	x0, x0, #0x670
101181be8:	c5 a2 4c 94	bl	__ZN4juce6StringD1Ev
101181bec:	26 00 00 14	b	0x101181c84
101181bf0:	1a 00 00 14	b	0x101181c58
101181bf4:	19 00 00 14	b	0x101181c58
101181bf8:	f3 03 00 aa	mov	x19, x0
101181bfc:	e0 03 42 f9	ldr	x0, [sp, #0x400]
101181c00:	80 dc ff b4	cbz	x0, 0x101181790
101181c04:	cf ff ff 17	b	0x101181b40
101181c08:	f3 03 00 aa	mov	x19, x0
101181c0c:	e0 03 42 f9	ldr	x0, [sp, #0x400]
101181c10:	00 dc ff b4	cbz	x0, 0x101181790
101181c14:	cb ff ff 17	b	0x101181b40
101181c18:	10 00 00 14	b	0x101181c58
101181c1c:	0f 00 00 14	b	0x101181c58
101181c20:	0e 00 00 14	b	0x101181c58
101181c24:	0d 00 00 14	b	0x101181c58
101181c28:	0c 00 00 14	b	0x101181c58
101181c2c:	0b 00 00 14	b	0x101181c58
101181c30:	0a 00 00 14	b	0x101181c58
101181c34:	09 00 00 14	b	0x101181c58
101181c38:	08 00 00 14	b	0x101181c58
101181c3c:	07 00 00 14	b	0x101181c58
101181c40:	06 00 00 14	b	0x101181c58
101181c44:	05 00 00 14	b	0x101181c58
101181c48:	04 00 00 14	b	0x101181c58
101181c4c:	03 00 00 14	b	0x101181c58
101181c50:	02 00 00 14	b	0x101181c58
101181c54:	01 00 00 14	b	0x101181c58
101181c58:	f3 03 00 aa	mov	x19, x0
101181c5c:	e8 8b 40 f9	ldr	x8, [sp, #0x110]
101181c60:	68 01 00 b5	cbnz	x8, 0x101181c8c
101181c64:	e0 f7 41 f9	ldr	x0, [sp, #0x3e8]
101181c68:	a0 01 00 b5	cbnz	x0, 0x101181c9c
101181c6c:	e8 73 40 f9	ldr	x8, [sp, #0xe0]
101181c70:	c8 01 00 b5	cbnz	x8, 0x101181ca8
101181c74:	e0 03 42 f9	ldr	x0, [sp, #0x400]
101181c78:	00 02 00 b5	cbnz	x0, 0x101181cb8
101181c7c:	e0 0f 42 f9	ldr	x0, [sp, #0x418]
101181c80:	20 02 00 b5	cbnz	x0, 0x101181cc4
101181c84:	e0 03 13 aa	mov	x0, x19
101181c88:	19 3d 8d 94	bl	0x1034d10ec ; symbol stub for: __Unwind_Resume
101181c8c:	e0 8b 40 f9	ldr	x0, [sp, #0x110]
101181c90:	8a 3f 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
101181c94:	e0 f7 41 f9	ldr	x0, [sp, #0x3e8]
101181c98:	a0 fe ff b4	cbz	x0, 0x101181c6c
101181c9c:	87 3f 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
101181ca0:	e8 73 40 f9	ldr	x8, [sp, #0xe0]
101181ca4:	88 fe ff b4	cbz	x8, 0x101181c74
101181ca8:	e0 73 40 f9	ldr	x0, [sp, #0xe0]
101181cac:	83 3f 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
101181cb0:	e0 03 42 f9	ldr	x0, [sp, #0x400]
101181cb4:	40 fe ff b4	cbz	x0, 0x101181c7c
101181cb8:	80 3f 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
101181cbc:	e0 0f 42 f9	ldr	x0, [sp, #0x418]
101181cc0:	20 fe ff b4	cbz	x0, 0x101181c84
101181cc4:	7d 3f 8d 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
101181cc8:	e0 03 13 aa	mov	x0, x19
101181ccc:	08 3d 8d 94	bl	0x1034d10ec ; symbol stub for: __Unwind_Resume
