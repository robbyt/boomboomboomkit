/Applications/rekordbox 7/rekordbox.app/Contents/MacOS/rekordbox:
(__TEXT,__text) section
__ZN6madmom7analyzeEN4juce6StringES1_PfS2_ixb:
102307f8c:	e9 23 b9 6d	stp	d9, d8, [sp, #-0x70]!
102307f90:	fc 6f 01 a9	stp	x28, x27, [sp, #0x10]
102307f94:	fa 67 02 a9	stp	x26, x25, [sp, #0x20]
102307f98:	f8 5f 03 a9	stp	x24, x23, [sp, #0x30]
102307f9c:	f6 57 04 a9	stp	x22, x21, [sp, #0x40]
102307fa0:	f4 4f 05 a9	stp	x20, x19, [sp, #0x50]
102307fa4:	fd 7b 06 a9	stp	x29, x30, [sp, #0x60]
102307fa8:	fd 83 01 91	add	x29, sp, #0x60
102307fac:	ff 83 0b d1	sub	sp, sp, #0x2e0
102307fb0:	f5 03 05 aa	mov	x21, x5
102307fb4:	f4 03 03 aa	mov	x20, x3
102307fb8:	f6 03 02 aa	mov	x22, x2
102307fbc:	f9 03 08 aa	mov	x25, x8
102307fc0:	b8 83 02 d1	sub	x24, x29, #0xa0
102307fc4:	28 72 01 f0	adrp	x8, 11847 ; 0x10514e000
102307fc8:	08 7d 42 f9	ldr	x8, [x8, #0x4f8] ; literal pool symbol address: ___stack_chk_guard
102307fcc:	08 01 40 f9	ldr	x8, [x8]
102307fd0:	a8 83 18 f8	stur	x8, [x29, #-0x78]
102307fd4:	86 3d 00 34	cbz	w6, 0x102308784
102307fd8:	f7 03 04 aa	mov	x23, x4
102307fdc:	e9 03 00 aa	mov	x9, x0
102307fe0:	e0 a3 02 91	add	x0, sp, #0xa8
102307fe4:	e1 03 09 aa	mov	x1, x9
102307fe8:	1a 8e 06 94	bl	__ZN4juce6StringC1ERKS0_
102307fec:	76 4b 00 b4	cbz	x22, 0x102308958
102307ff0:	55 4b 00 b4	cbz	x21, 0x102308958
102307ff4:	48 a9 00 d0	adrp	x8, 5418 ; 0x103831000
102307ff8:	00 fd c3 3d	ldr	q0, [x8, #0xff0]
102307ffc:	9f 02 00 f1	cmp	x20, #0x0
102308000:	c8 02 94 9a	csel	x8, x22, x20, eq
102308004:	e8 2f 00 f9	str	x8, [sp, #0x58]
102308008:	00 43 80 3c	stur	q0, [x24, #0x4]
10230800c:	bf 83 17 f8	stur	xzr, [x29, #-0x88]
102308010:	bf 03 18 38	sturb	wzr, [x29, #-0x80]
102308014:	e0 e3 05 91	add	x0, sp, #0x178
102308018:	e1 a3 02 91	add	x1, sp, #0xa8
10230801c:	83 99 06 94	bl	__ZN4juce4FileC1ERKNS_6StringE
102308020:	e0 e3 05 91	add	x0, sp, #0x178
102308024:	67 aa 06 94	bl	__ZNK4juce4File6existsEv
102308028:	a0 4b 00 36	tbz	w0, #0x0, 0x10230899c
10230802c:	ff ff 1c a9	stp	xzr, xzr, [sp, #0x1c8]
102308030:	ff ef 00 f9	str	xzr, [sp, #0x1d8]
102308034:	ff 7f 1b a9	stp	xzr, xzr, [sp, #0x1b0]
102308038:	ff e3 00 f9	str	xzr, [sp, #0x1c0]
10230803c:	00 02 80 52	mov	w0, #0x10
102308040:	a4 26 47 94	bl	0x1034d1ad0 ; symbol stub for: __Znwm
102308044:	e0 4b 00 f9	str	x0, [sp, #0x90]
102308048:	e8 83 07 91	add	x8, sp, #0x1e0
10230804c:	e0 a3 02 91	add	x0, sp, #0xa8
102308050:	87 3e 07 94	bl	__ZNK4juce6String11toStdStringEv
102308054:	4e 26 47 94	bl	0x1034d198c ; symbol stub for: __ZNSt3__16thread20hardware_concurrencyEv
102308058:	e3 03 00 aa	mov	x3, x0
10230805c:	e1 83 07 91	add	x1, sp, #0x1e0
102308060:	e0 4b 40 f9	ldr	x0, [sp, #0x90]
102308064:	02 00 80 52	mov	w2, #0x0
102308068:	24 00 80 52	mov	w4, #0x1
10230806c:	a4 f3 43 94	bl	__ZN9TFWrapper5ModelC1ERKNSt3__112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEEbib
102308070:	e8 df c7 39	ldrsb	w8, [sp, #0x1f7]
102308074:	68 00 f8 36	tbz	w8, #0x1f, 0x102308080
102308078:	e0 f3 40 f9	ldr	x0, [sp, #0x1e0]
10230807c:	8f 26 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102308080:	31 26 47 94	bl	0x1034d1944 ; symbol stub for: __ZNSt3__16chrono12system_clock3nowEv
102308084:	28 67 01 b0	adrp	x8, 11493 ; 0x104fed000
102308088:	08 61 1a 91	add	x8, x8, #0x698 ; literal pool for: "serving_default_fltp:0"
10230808c:	00 01 c0 3d	ldr	q0, [x8]
102308090:	e0 67 80 3d	str	q0, [sp, #0x190]
102308094:	08 e1 40 f8	ldur	x8, [x8, #0xe]
102308098:	e9 43 06 91	add	x9, sp, #0x190
10230809c:	28 e1 00 f8	stur	x8, [x9, #0xe]
1023080a0:	08 c0 82 52	mov	w8, #0x1600
1023080a4:	e8 4f 03 79	strh	w8, [sp, #0x1a6]
1023080a8:	88 07 80 52	mov	w8, #0x3c
1023080ac:	e8 7e 08 1b	mul	w8, w23, w8
1023080b0:	a9 0e c8 1a	sdiv	w9, w21, w8
1023080b4:	3f 01 00 71	cmp	w9, #0x0
1023080b8:	0d 67 00 54	b.le	0x102308d98
1023080bc:	2a 05 00 51	sub	w10, w9, #0x1
1023080c0:	ea 43 00 f9	str	x10, [sp, #0x80]
1023080c4:	4e 7d 08 1b	mul	w14, w10, w8
1023080c8:	2a 7d 08 1b	mul	w10, w9, w8
1023080cc:	ab 02 0a 4b	sub	w11, w21, w10
1023080d0:	cc 03 80 52	mov	w12, #0x1e
1023080d4:	ec 7e 0c 1b	mul	w12, w23, w12
1023080d8:	ad 02 0e 4b	sub	w13, w21, w14
1023080dc:	bf 01 00 71	cmp	w13, #0x0
1023080e0:	ad a5 8d 1a	cinc	w13, w13, lt
1023080e4:	ad 7d 01 13	asr	w13, w13, #1
1023080e8:	ee 13 00 f9	str	x14, [sp, #0x20]
1023080ec:	ae 01 0e 0b	add	w14, w13, w14
1023080f0:	af 02 0e 4b	sub	w15, w21, w14
1023080f4:	7f 05 00 71	cmp	w11, #0x1
1023080f8:	60 a1 4c 7a	ccmp	w11, w12, #0x0, ge
1023080fc:	7a a1 8f 1a	csel	w26, w11, w15, ge
102308100:	4a a1 8e 1a	csel	w10, w10, w14, ge
102308104:	ea 0f 00 f9	str	x10, [sp, #0x18]
102308108:	15 a1 8d 1a	csel	w21, w8, w13, ge
10230810c:	3f 09 00 71	cmp	w9, #0x2
102308110:	a3 64 00 54	b.lo	0x102308da4
102308114:	f5 03 00 f9	str	x21, [sp]
102308118:	fa 0f 00 b9	str	w26, [sp, #0xc]
10230811c:	f9 0b 00 f9	str	x25, [sp, #0x10]
102308120:	13 00 80 d2	mov	x19, #0x0
102308124:	09 7d 40 93	sxtw	x9, w8
102308128:	ea 83 07 91	add	x10, sp, #0x1e0
10230812c:	58 61 00 91	add	x24, x10, #0x18
102308130:	f7 77 00 b9	str	w23, [sp, #0x74]
102308134:	e0 02 22 1e	scvtf	s0, w23
102308138:	48 89 8a 52	mov	w8, #0x544a
10230813c:	48 56 a7 72	movk	w8, #0x3ab2, lsl #16
102308140:	01 01 27 1e	fmov	s1, w8
102308144:	08 08 21 1e	fmul	s8, s0, s1
102308148:	48 a1 00 91	add	x8, x10, #0x28
10230814c:	e8 2b 00 f9	str	x8, [sp, #0x50]
102308150:	e8 23 04 91	add	x8, sp, #0x108
102308154:	0b 01 7e b2	orr	x11, x8, #0x4
102308158:	08 61 00 91	add	x8, x8, #0x18
10230815c:	e8 af 03 a9	stp	x8, x11, [sp, #0x38]
102308160:	3f 05 00 f1	cmp	x9, #0x1
102308164:	2b c5 9f 9a	csinc	x11, x9, xzr, gt
102308168:	48 b1 00 91	add	x8, x10, #0x2c
10230816c:	e8 27 00 f9	str	x8, [sp, #0x48]
102308170:	e9 3f 00 f9	str	x9, [sp, #0x78]
102308174:	34 f5 7e d3	lsl	x20, x9, #2
102308178:	eb 47 00 f9	str	x11, [sp, #0x88]
10230817c:	68 e9 7c 92	and	x8, x11, #0x7ffffffffffffff0
102308180:	e8 1b 00 f9	str	x8, [sp, #0x30]
102308184:	d5 82 00 91	add	x21, x22, #0x20
102308188:	f7 2f 40 f9	ldr	x23, [sp, #0x58]
10230818c:	f9 82 00 91	add	x25, x23, #0x20
102308190:	09 10 2c 1e	fmov	s9, #0.50000000
102308194:	48 a9 00 d0	adrp	x8, 5418 ; 0x103832000
102308198:	00 05 c0 3d	ldr	q0, [x8, #0x10]
10230819c:	e0 1b 80 3d	str	q0, [sp, #0x60]
1023081a0:	f6 17 00 f9	str	x22, [sp, #0x28]
1023081a4:	10 00 00 14	b	0x1023081e4
1023081a8:	48 5f c0 39	ldrsb	w8, [x26, #0x17]
1023081ac:	48 1e f8 37	tbnz	w8, #0x1f, 0x102308574
1023081b0:	fa b7 00 f9	str	x26, [sp, #0x168]
1023081b4:	e0 03 1a aa	mov	x0, x26
1023081b8:	40 26 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
1023081bc:	a0 03 03 d1	sub	x0, x29, #0xc0
1023081c0:	04 24 47 94	bl	0x1034d11d0 ; symbol stub for: __ZN10tensorflow6TensorD1Ev
1023081c4:	73 06 00 91	add	x19, x19, #0x1
1023081c8:	b5 02 14 8b	add	x21, x21, x20
1023081cc:	39 03 14 8b	add	x25, x25, x20
1023081d0:	f7 02 14 8b	add	x23, x23, x20
1023081d4:	d6 02 14 8b	add	x22, x22, x20
1023081d8:	e8 43 40 f9	ldr	x8, [sp, #0x80]
1023081dc:	7f 02 08 eb	cmp	x19, x8
1023081e0:	80 81 00 54	b.eq	0x102309210
1023081e4:	29 00 80 52	mov	w9, #0x1
1023081e8:	e8 3f 40 f9	ldr	x8, [sp, #0x78]
1023081ec:	a9 a3 31 a9	stp	x9, x8, [x29, #-0xe8]
1023081f0:	e0 83 07 91	add	x0, sp, #0x1e0
1023081f4:	a1 a3 03 d1	sub	x1, x29, #0xe8
1023081f8:	42 00 80 52	mov	w2, #0x2
1023081fc:	e9 23 47 94	bl	0x1034d11a0 ; symbol stub for: __ZN10tensorflow15TensorShapeBaseINS_11TensorShapeEEC2EN4absl12lts_202308024SpanIKxEE
102308200:	a0 03 03 d1	sub	x0, x29, #0xc0
102308204:	e2 83 07 91	add	x2, sp, #0x1e0
102308208:	21 00 80 52	mov	w1, #0x1
10230820c:	ee 23 47 94	bl	0x1034d11c4 ; symbol stub for: __ZN10tensorflow6TensorC1ENS_8DataTypeERKNS_11TensorShapeE
102308210:	e8 bf 47 39	ldrb	w8, [sp, #0x1ef]
102308214:	1f 09 00 71	cmp	w8, #0x2
102308218:	61 00 00 54	b.ne	0x102308224
10230821c:	e0 83 07 91	add	x0, sp, #0x1e0
102308220:	dd 23 47 94	bl	0x1034d1194 ; symbol stub for: __ZN10tensorflow14TensorShapeRep19DestructorOutOfLineEv
102308224:	a0 03 03 d1	sub	x0, x29, #0xc0
102308228:	38 24 47 94	bl	0x1034d1308 ; symbol stub for: __ZNK10tensorflow6Tensor4dataEv
10230822c:	e8 77 40 b9	ldr	w8, [sp, #0x74]
102308230:	1f 05 00 71	cmp	w8, #0x1
102308234:	2b 02 00 54	b.lt	0x102308278
102308238:	e8 47 40 f9	ldr	x8, [sp, #0x88]
10230823c:	1f 41 00 f1	cmp	x8, #0x10
102308240:	02 1a 00 54	b.hs	0x102308580
102308244:	09 00 80 d2	mov	x9, #0x0
102308248:	e8 47 40 f9	ldr	x8, [sp, #0x88]
10230824c:	08 01 09 cb	sub	x8, x8, x9
102308250:	2a f5 7e d3	lsl	x10, x9, #2
102308254:	e9 02 0a 8b	add	x9, x23, x10
102308258:	ca 02 0a 8b	add	x10, x22, x10
10230825c:	40 45 40 bc	ldr	s0, [x10], #0x4
102308260:	21 45 40 bc	ldr	s1, [x9], #0x4
102308264:	20 28 20 1e	fadd	s0, s1, s0
102308268:	00 08 29 1e	fmul	s0, s0, s9
10230826c:	00 44 00 bc	str	s0, [x0], #0x4
102308270:	08 05 00 f1	subs	x8, x8, #0x1
102308274:	41 ff ff 54	b.ne	0x10230825c
102308278:	fa ef 5c a9	ldp	x26, x27, [sp, #0x1c8]
10230827c:	7f 03 1a eb	cmp	x27, x26
102308280:	61 05 00 54	b.ne	0x10230832c
102308284:	fa eb 00 f9	str	x26, [sp, #0x1d0]
102308288:	e0 83 07 91	add	x0, sp, #0x1e0
10230828c:	e1 43 06 91	add	x1, sp, #0x190
102308290:	bd 24 47 94	bl	0x1034d1584 ; symbol stub for: __ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEEC1ERKS5_
102308294:	a8 03 55 f8	ldur	x8, [x29, #-0xb0]
102308298:	e8 07 01 f9	str	x8, [sp, #0x208]
10230829c:	a8 f3 54 38	ldurb	w8, [x29, #-0xb1]
1023082a0:	1f 09 00 71	cmp	w8, #0x2
1023082a4:	41 05 00 54	b.ne	0x10230834c
1023082a8:	ff 1f 08 39	strb	wzr, [sp, #0x207]
1023082ac:	a1 03 03 d1	sub	x1, x29, #0xc0
1023082b0:	e0 03 18 aa	mov	x0, x24
1023082b4:	b5 23 47 94	bl	0x1034d1188 ; symbol stub for: __ZN10tensorflow14TensorShapeRep12SlowCopyFromERKS0_
1023082b8:	a8 83 55 f8	ldur	x8, [x29, #-0xa8]
1023082bc:	e8 0b 01 f9	str	x8, [sp, #0x210]
1023082c0:	88 00 00 b4	cbz	x8, 0x1023082d0
1023082c4:	08 21 00 91	add	x8, x8, #0x8
1023082c8:	29 00 80 52	mov	w9, #0x1
1023082cc:		.long	0xb8290108
1023082d0:	e8 27 5d a9	ldp	x8, x9, [sp, #0x1d0]
1023082d4:	1f 01 09 eb	cmp	x8, x9
1023082d8:	62 04 00 54	b.hs	0x102308364
1023082dc:	e0 7b c0 3d	ldr	q0, [sp, #0x1e0]
1023082e0:	e9 fb 40 f9	ldr	x9, [sp, #0x1f0]
1023082e4:	09 09 00 f9	str	x9, [x8, #0x10]
1023082e8:	00 01 80 3d	str	q0, [x8]
1023082ec:	ff ff 1e a9	stp	xzr, xzr, [sp, #0x1e8]
1023082f0:	ff f3 00 f9	str	xzr, [sp, #0x1e0]
1023082f4:	e9 07 41 f9	ldr	x9, [sp, #0x208]
1023082f8:	09 15 00 f9	str	x9, [x8, #0x28]
1023082fc:	00 03 c0 3d	ldr	q0, [x24]
102308300:	00 81 81 3c	stur	q0, [x8, #0x18]
102308304:	ff 1f 08 39	strb	wzr, [sp, #0x207]
102308308:	e9 0b 41 f9	ldr	x9, [sp, #0x210]
10230830c:	09 19 00 f9	str	x9, [x8, #0x30]
102308310:	ff 0b 01 f9	str	xzr, [sp, #0x210]
102308314:	08 e1 00 91	add	x8, x8, #0x38
102308318:	e8 eb 00 f9	str	x8, [sp, #0x1d0]
10230831c:	15 00 00 14	b	0x102308370
102308320:	fb 03 1c aa	mov	x27, x28
102308324:	9f 03 1a eb	cmp	x28, x26
102308328:	e0 fa ff 54	b.eq	0x102308284
10230832c:	7c e3 00 d1	sub	x28, x27, #0x38
102308330:	60 83 00 d1	sub	x0, x27, #0x20
102308334:	a7 23 47 94	bl	0x1034d11d0 ; symbol stub for: __ZN10tensorflow6TensorD1Ev
102308338:	68 f3 dd 38	ldursb	w8, [x27, #-0x21]
10230833c:	28 ff ff 36	tbz	w8, #0x1f, 0x102308320
102308340:	60 83 5c f8	ldur	x0, [x27, #-0x38]
102308344:	dd 25 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102308348:	f6 ff ff 17	b	0x102308320
10230834c:	a0 03 d4 3c	ldur	q0, [x29, #-0xc0]
102308350:	00 03 80 3d	str	q0, [x24]
102308354:	a8 83 55 f8	ldur	x8, [x29, #-0xa8]
102308358:	e8 0b 01 f9	str	x8, [sp, #0x210]
10230835c:	48 fb ff b5	cbnz	x8, 0x1023082c4
102308360:	dc ff ff 17	b	0x1023082d0
102308364:	e0 23 07 91	add	x0, sp, #0x1c8
102308368:	e1 83 07 91	add	x1, sp, #0x1e0
10230836c:	66 45 00 94	bl	__ZNSt3__16vectorINS_4pairINS_12basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEEEN10tensorflow6TensorEEENS5_ISA_EEE21__push_back_slow_pathISA_EEvOT_
102308370:	e0 03 18 aa	mov	x0, x24
102308374:	97 23 47 94	bl	0x1034d11d0 ; symbol stub for: __ZN10tensorflow6TensorD1Ev
102308378:	e8 df c7 39	ldrsb	w8, [sp, #0x1f7]
10230837c:	68 00 f8 36	tbz	w8, #0x1f, 0x102308388
102308380:	e0 f3 40 f9	ldr	x0, [sp, #0x1e0]
102308384:	cd 25 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102308388:	00 04 80 52	mov	w0, #0x20
10230838c:	d1 25 47 94	bl	0x1034d1ad0 ; symbol stub for: __Znwm
102308390:	a0 83 11 f8	stur	x0, [x29, #-0xe8]
102308394:	e8 43 06 91	add	x8, sp, #0x190
102308398:	e0 1b c0 3d	ldr	q0, [sp, #0x60]
10230839c:	00 01 8d 3c	stur	q0, [x8, #0xd0]
1023083a0:	28 67 01 b0	adrp	x8, 11493 ; 0x104fed000
1023083a4:	08 bd 1a 91	add	x8, x8, #0x6af ; literal pool for: "StatefulPartitionedCall:1"
1023083a8:	00 01 c0 3d	ldr	q0, [x8]
1023083ac:	00 00 80 3d	str	q0, [x0]
1023083b0:	00 91 c0 3c	ldur	q0, [x8, #0x9]
1023083b4:	00 90 80 3c	stur	q0, [x0, #0x9]
1023083b8:	1f 64 00 39	strb	wzr, [x0, #0x19]
1023083bc:	ff ff 16 a9	stp	xzr, xzr, [sp, #0x168]
1023083c0:	ff b3 00 f9	str	xzr, [sp, #0x160]
1023083c4:	00 03 80 52	mov	w0, #0x18
1023083c8:	c2 25 47 94	bl	0x1034d1ad0 ; symbol stub for: __Znwm
1023083cc:	fa 03 00 aa	mov	x26, x0
1023083d0:	e0 03 16 a9	stp	x0, x0, [sp, #0x160]
1023083d4:	1b 60 00 91	add	x27, x0, #0x18
1023083d8:	fb bb 00 f9	str	x27, [sp, #0x170]
1023083dc:	e0 1b 01 f9	str	x0, [sp, #0x230]
1023083e0:	e0 87 00 f9	str	x0, [sp, #0x108]
1023083e4:	a1 a3 03 d1	sub	x1, x29, #0xe8
1023083e8:	67 24 47 94	bl	0x1034d1584 ; symbol stub for: __ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEEC1ERKS5_
1023083ec:	fb b7 00 f9	str	x27, [sp, #0x168]
1023083f0:	a8 f3 d2 38	ldursb	w8, [x29, #-0xd1]
1023083f4:	68 00 f8 36	tbz	w8, #0x1f, 0x102308400
1023083f8:	a0 83 51 f8	ldur	x0, [x29, #-0xe8]
1023083fc:	af 25 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102308400:	ff 7f 15 a9	stp	xzr, xzr, [sp, #0x150]
102308404:	ff a7 00 f9	str	xzr, [sp, #0x148]
102308408:	00 03 80 52	mov	w0, #0x18
10230840c:	b1 25 47 94	bl	0x1034d1ad0 ; symbol stub for: __Znwm
102308410:	fb 03 00 aa	mov	x27, x0
102308414:	e0 83 14 a9	stp	x0, x0, [sp, #0x148]
102308418:	1c 60 00 91	add	x28, x0, #0x18
10230841c:	fc af 00 f9	str	x28, [sp, #0x158]
102308420:	a0 83 11 f8	stur	x0, [x29, #-0xe8]
102308424:	e0 1b 01 f9	str	x0, [sp, #0x230]
102308428:	e1 03 1a aa	mov	x1, x26
10230842c:	56 24 47 94	bl	0x1034d1584 ; symbol stub for: __ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEEC1ERKS5_
102308430:	fc ab 00 f9	str	x28, [sp, #0x150]
102308434:	e1 23 07 91	add	x1, sp, #0x1c8
102308438:	e2 23 05 91	add	x2, sp, #0x148
10230843c:	e3 c3 06 91	add	x3, sp, #0x1b0
102308440:	e0 4b 40 f9	ldr	x0, [sp, #0x90]
102308444:	f3 f2 43 94	bl	__ZN9TFWrapper5Model3runERKNSt3__16vectorINS1_4pairINS1_12basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEEN10tensorflow6TensorEEENS7_ISC_EEEENS2_IS9_NS7_IS9_EEEERNS2_ISB_NS7_ISB_EEEE
102308448:	fb a7 40 f9	ldr	x27, [sp, #0x148]
10230844c:	5b 02 00 b4	cbz	x27, 0x102308494
102308450:	e8 ab 40 f9	ldr	x8, [sp, #0x150]
102308454:	1f 01 1b eb	cmp	x8, x27
102308458:	c1 00 00 54	b.ne	0x102308470
10230845c:	e0 03 1b aa	mov	x0, x27
102308460:	0b 00 00 14	b	0x10230848c
102308464:	e8 03 1c aa	mov	x8, x28
102308468:	9f 03 1b eb	cmp	x28, x27
10230846c:	e0 00 00 54	b.eq	0x102308488
102308470:	1c 61 00 d1	sub	x28, x8, #0x18
102308474:	09 f1 df 38	ldursb	w9, [x8, #-0x1]
102308478:	69 ff ff 36	tbz	w9, #0x1f, 0x102308464
10230847c:	00 81 5e f8	ldur	x0, [x8, #-0x18]
102308480:	8e 25 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102308484:	f8 ff ff 17	b	0x102308464
102308488:	e0 a7 40 f9	ldr	x0, [sp, #0x148]
10230848c:	fb ab 00 f9	str	x27, [sp, #0x150]
102308490:	8a 25 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102308494:	e0 23 5b a9	ldp	x0, x8, [sp, #0x1b0]
102308498:	1f 01 00 eb	cmp	x8, x0
10230849c:	60 e8 ff 54	b.eq	0x1023081a8
1023084a0:	01 00 80 52	mov	w1, #0x0
1023084a4:	96 23 47 94	bl	0x1034d12fc ; symbol stub for: __ZNK10tensorflow15TensorShapeBaseINS_11TensorShapeEE8dim_sizeEi
1023084a8:	fb 03 00 aa	mov	x27, x0
1023084ac:	e0 db 40 f9	ldr	x0, [sp, #0x1b0]
1023084b0:	21 00 80 52	mov	w1, #0x1
1023084b4:	92 23 47 94	bl	0x1034d12fc ; symbol stub for: __ZNK10tensorflow15TensorShapeBaseINS_11TensorShapeEE8dim_sizeEi
1023084b8:	fc 03 00 aa	mov	x28, x0
1023084bc:	e0 db 40 f9	ldr	x0, [sp, #0x1b0]
1023084c0:	92 23 47 94	bl	0x1034d1308 ; symbol stub for: __ZNK10tensorflow6Tensor4dataEv
1023084c4:	bb f3 23 29	stp	w27, w28, [x29, #-0xe4]
1023084c8:	88 7f 1b 1b	mul	w8, w28, w27
1023084cc:	a8 ff 24 29	stp	w8, wzr, [x29, #-0xdc]
1023084d0:	a0 03 13 f8	stur	x0, [x29, #-0xd0]
1023084d4:	bf 83 13 38	sturb	wzr, [x29, #-0xc8]
1023084d8:	80 00 80 52	mov	w0, #0x4
1023084dc:	7d 25 47 94	bl	0x1034d1ad0 ; symbol stub for: __Znwm
1023084e0:	fb 03 00 aa	mov	x27, x0
1023084e4:	e8 03 00 aa	mov	x8, x0
1023084e8:	89 00 80 52	mov	w9, #0x4
1023084ec:	09 45 00 b8	str	w9, [x8], #0x4
1023084f0:	e8 a3 13 a9	stp	x8, x8, [sp, #0x138]
1023084f4:	e0 9b 00 f9	str	x0, [sp, #0x130]
1023084f8:	08 00 d0 d2	mov	x8, #0x800000000000
1023084fc:	28 0a e8 f2	movk	x8, #0x4051, lsl #48
102308500:	00 01 67 9e	fmov	d0, x8
102308504:	08 00 d0 d2	mov	x8, #0x800000000000
102308508:	c8 0c e8 f2	movk	x8, #0x4066, lsl #48
10230850c:	01 01 67 9e	fmov	d1, x8
102308510:	a8 99 99 52	mov	w8, #0xcccd
102308514:	88 a9 a7 72	movk	w8, #0x3d4c, lsl #16
102308518:	02 01 27 1e	fmov	s2, w8
10230851c:	28 0b e8 d2	mov	x8, #0x4059000000000000
102308520:	03 01 67 9e	fmov	d3, x8
102308524:	e8 c3 08 91	add	x8, sp, #0x230
102308528:	a0 a3 03 d1	sub	x0, x29, #0xe8
10230852c:	e1 c3 04 91	add	x1, sp, #0x130
102308530:	82 07 80 52	mov	w2, #0x3c
102308534:	83 0c 80 52	mov	w3, #0x64
102308538:	04 02 80 52	mov	w4, #0x10
10230853c:	25 00 80 52	mov	w5, #0x1
102308540:	0b e2 ff 97	bl	__ZN6madmom17downbeat_trackingERKN2nc7NdArrayIfNSt3__19allocatorIfEEEERNS2_6vectorIiNS3_IiEEEEddiiifbd
102308544:	e8 43 06 91	add	x8, sp, #0x190
102308548:	08 41 4a f8	ldur	x8, [x8, #0xa4]
10230854c:	1f 05 00 71	cmp	w8, #0x1
102308550:	0b 0a 00 54	b.lt	0x102308690
102308554:	08 7d 40 92	and	x8, x8, #0xffffffff
102308558:	60 02 22 1e	scvtf	s0, w19
10230855c:	00 09 20 1e	fmul	s0, s8, s0
102308560:	e9 27 41 f9	ldr	x9, [sp, #0x248]
102308564:	1f 11 00 f1	cmp	x8, #0x4
102308568:	e2 05 00 54	b.hs	0x102308624
10230856c:	0a 00 80 d2	mov	x10, #0x0
102308570:	41 00 00 14	b	0x102308674
102308574:	40 03 40 f9	ldr	x0, [x26]
102308578:	50 25 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10230857c:	0d ff ff 17	b	0x1023081b0
102308580:	09 00 80 d2	mov	x9, #0x0
102308584:	88 7e 13 9b	mul	x8, x20, x19
102308588:	ea 2f 40 f9	ldr	x10, [sp, #0x58]
10230858c:	0a 01 0a 8b	add	x10, x8, x10
102308590:	0a 00 0a cb	sub	x10, x0, x10
102308594:	5f 01 01 f1	cmp	x10, #0x40
102308598:	83 e5 ff 54	b.lo	0x102308248
10230859c:	ea 17 40 f9	ldr	x10, [sp, #0x28]
1023085a0:	08 01 0a 8b	add	x8, x8, x10
1023085a4:	08 00 08 cb	sub	x8, x0, x8
1023085a8:	1f 01 01 f1	cmp	x8, #0x40
1023085ac:	e3 e4 ff 54	b.lo	0x102308248
1023085b0:	08 80 00 91	add	x8, x0, #0x20
1023085b4:	e9 03 19 aa	mov	x9, x25
1023085b8:	ea 03 15 aa	mov	x10, x21
1023085bc:	ec 1b 40 f9	ldr	x12, [sp, #0x30]
1023085c0:	eb 03 0c aa	mov	x11, x12
1023085c4:	00 08 0c 8b	add	x0, x0, x12, lsl #2
1023085c8:	f0 67 01 4f	movi.4s	v16, #0x3f, lsl #24
1023085cc:	40 05 7f ad	ldp	q0, q1, [x10, #-0x20]
1023085d0:	42 0d c2 ac	ldp	q2, q3, [x10], #0x40
1023085d4:	24 15 7f ad	ldp	q4, q5, [x9, #-0x20]
1023085d8:	26 1d c2 ac	ldp	q6, q7, [x9], #0x40
1023085dc:	80 d4 20 4e	fadd.4s	v0, v4, v0
1023085e0:	a1 d4 21 4e	fadd.4s	v1, v5, v1
1023085e4:	c2 d4 22 4e	fadd.4s	v2, v6, v2
1023085e8:	e3 d4 23 4e	fadd.4s	v3, v7, v3
1023085ec:	00 dc 30 6e	fmul.4s	v0, v0, v16
1023085f0:	21 dc 30 6e	fmul.4s	v1, v1, v16
1023085f4:	42 dc 30 6e	fmul.4s	v2, v2, v16
1023085f8:	63 dc 30 6e	fmul.4s	v3, v3, v16
1023085fc:	00 05 3f ad	stp	q0, q1, [x8, #-0x20]
102308600:	02 0d 82 ac	stp	q2, q3, [x8], #0x40
102308604:	6b 41 00 f1	subs	x11, x11, #0x10
102308608:	21 fe ff 54	b.ne	0x1023085cc
10230860c:	ea 1b 40 f9	ldr	x10, [sp, #0x30]
102308610:	e9 03 0a aa	mov	x9, x10
102308614:	e8 47 40 f9	ldr	x8, [sp, #0x88]
102308618:	1f 01 0a eb	cmp	x8, x10
10230861c:	61 e1 ff 54	b.ne	0x102308248
102308620:	16 ff ff 17	b	0x102308278
102308624:	0b 05 40 92	and	x11, x8, #0x3
102308628:	0a 75 7e 92	and	x10, x8, #0xfffffffc
10230862c:	2c 41 00 91	add	x12, x9, #0x10
102308630:	ed 03 0a aa	mov	x13, x10
102308634:	81 01 5f bc	ldur	s1, [x12, #-0x10]
102308638:	82 81 5f bc	ldur	s2, [x12, #-0x8]
10230863c:	83 01 40 bd	ldr	s3, [x12]
102308640:	84 09 40 bd	ldr	s4, [x12, #0x8]
102308644:	21 28 20 1e	fadd	s1, s1, s0
102308648:	42 28 20 1e	fadd	s2, s2, s0
10230864c:	63 28 20 1e	fadd	s3, s3, s0
102308650:	84 28 20 1e	fadd	s4, s4, s0
102308654:	81 01 1f bc	stur	s1, [x12, #-0x10]
102308658:	82 81 1f bc	stur	s2, [x12, #-0x8]
10230865c:	83 01 00 bd	str	s3, [x12]
102308660:	84 09 00 bd	str	s4, [x12, #0x8]
102308664:	8c 81 00 91	add	x12, x12, #0x20
102308668:	ad 11 00 f1	subs	x13, x13, #0x4
10230866c:	41 fe ff 54	b.ne	0x102308634
102308670:	0b 01 00 b4	cbz	x11, 0x102308690
102308674:	08 01 0a cb	sub	x8, x8, x10
102308678:	29 0d 0a 8b	add	x9, x9, x10, lsl #3
10230867c:	21 01 40 bd	ldr	s1, [x9]
102308680:	21 28 20 1e	fadd	s1, s1, s0
102308684:	21 85 00 bc	str	s1, [x9], #0x8
102308688:	08 05 00 f1	subs	x8, x8, #0x1
10230868c:	81 ff ff 54	b.ne	0x10230867c
102308690:	e0 83 07 91	add	x0, sp, #0x1e0
102308694:	a1 83 02 d1	sub	x1, x29, #0xa0
102308698:	f6 88 96 97	bl	__ZN2nc7NdArrayIfNSt3__19allocatorIfEEEC2ERKS4_
10230869c:	e1 c3 08 91	add	x1, sp, #0x230
1023086a0:	e0 2b 40 f9	ldr	x0, [sp, #0x50]
1023086a4:	f3 88 96 97	bl	__ZN2nc7NdArrayIfNSt3__19allocatorIfEEEC2ERKS4_
1023086a8:	e8 83 07 91	add	x8, sp, #0x1e0
1023086ac:	e8 7b 00 f9	str	x8, [sp, #0xf0]
1023086b0:	48 00 80 52	mov	w8, #0x2
1023086b4:	e8 7f 00 f9	str	x8, [sp, #0xf8]
1023086b8:	e8 23 04 91	add	x8, sp, #0x108
1023086bc:	e0 c3 03 91	add	x0, sp, #0xf0
1023086c0:	82 45 00 94	bl	__ZN2nc9row_stackIfEENS_7NdArrayIT_NSt3__19allocatorIS2_EEEERKSt16initializer_listIS6_E
1023086c4:	a8 03 58 38	ldurb	w8, [x29, #-0x80]
1023086c8:	88 00 00 34	cbz	w8, 0x1023086d8
1023086cc:	a0 83 57 f8	ldur	x0, [x29, #-0x88]
1023086d0:	40 00 00 b4	cbz	x0, 0x1023086d8
1023086d4:	f9 24 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
1023086d8:	e8 37 00 91	add	x8, sp, #0xd
1023086dc:	08 f1 4f f8	ldur	x8, [x8, #0xff]
1023086e0:	a9 83 02 d1	sub	x9, x29, #0xa0
1023086e4:	28 41 00 f8	stur	x8, [x9, #0x4]
1023086e8:	e8 57 00 91	add	x8, sp, #0x15
1023086ec:	00 f1 4f fc	ldur	d0, [x8, #0xff]
1023086f0:	20 c1 00 fc	stur	d0, [x9, #0xc]
1023086f4:	e8 93 40 f9	ldr	x8, [sp, #0x120]
1023086f8:	a8 83 17 f8	stur	x8, [x29, #-0x88]
1023086fc:	e8 a3 44 39	ldrb	w8, [sp, #0x128]
102308700:	a8 03 18 38	sturb	w8, [x29, #-0x80]
102308704:	e8 23 40 f9	ldr	x8, [sp, #0x40]
102308708:	1f 7d 00 a9	stp	xzr, xzr, [x8]
10230870c:	e8 1f 40 f9	ldr	x8, [sp, #0x38]
102308710:	1f 21 00 39	strb	wzr, [x8, #0x8]
102308714:	1f 01 00 f9	str	xzr, [x8]
102308718:	e8 a3 48 39	ldrb	w8, [sp, #0x228]
10230871c:	88 00 00 34	cbz	w8, 0x10230872c
102308720:	e0 13 41 f9	ldr	x0, [sp, #0x220]
102308724:	40 00 00 b4	cbz	x0, 0x10230872c
102308728:	e4 24 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10230872c:	ff 13 01 f9	str	xzr, [sp, #0x220]
102308730:	ff a3 08 39	strb	wzr, [sp, #0x228]
102308734:	e8 27 40 f9	ldr	x8, [sp, #0x48]
102308738:	1f 7d 00 a9	stp	xzr, xzr, [x8]
10230873c:	e8 03 48 39	ldrb	w8, [sp, #0x200]
102308740:	88 00 00 34	cbz	w8, 0x102308750
102308744:	e0 ff 40 f9	ldr	x0, [sp, #0x1f8]
102308748:	40 00 00 b4	cbz	x0, 0x102308750
10230874c:	db 24 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102308750:	e8 43 49 39	ldrb	w8, [sp, #0x250]
102308754:	88 00 00 34	cbz	w8, 0x102308764
102308758:	e0 27 41 f9	ldr	x0, [sp, #0x248]
10230875c:	40 00 00 b4	cbz	x0, 0x102308764
102308760:	d6 24 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102308764:	e0 03 1b aa	mov	x0, x27
102308768:	d4 24 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10230876c:	a8 83 53 38	ldurb	w8, [x29, #-0xc8]
102308770:	c8 d1 ff 34	cbz	w8, 0x1023081a8
102308774:	a0 03 53 f8	ldur	x0, [x29, #-0xd0]
102308778:	80 d1 ff b4	cbz	x0, 0x1023081a8
10230877c:	cf 24 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102308780:	8a fe ff 17	b	0x1023081a8
102308784:	e0 83 02 91	add	x0, sp, #0xa0
102308788:	32 8c 06 94	bl	__ZN4juce6StringC1ERKS0_
10230878c:	76 0f 00 b4	cbz	x22, 0x102308978
102308790:	55 0f 00 b4	cbz	x21, 0x102308978
102308794:	9f 02 00 f1	cmp	x20, #0x0
102308798:	d3 02 94 9a	csel	x19, x22, x20, eq
10230879c:	e0 83 05 91	add	x0, sp, #0x160
1023087a0:	e1 83 02 91	add	x1, sp, #0xa0
1023087a4:	a1 97 06 94	bl	__ZN4juce4FileC1ERKNS_6StringE
1023087a8:	e0 83 05 91	add	x0, sp, #0x160
1023087ac:	85 a8 06 94	bl	__ZNK4juce4File6existsEv
1023087b0:	a0 16 00 36	tbz	w0, #0x0, 0x102308a84
1023087b4:	ff ff 10 a9	stp	xzr, xzr, [sp, #0x108]
1023087b8:	ff 8f 00 f9	str	xzr, [sp, #0x118]
1023087bc:	ff 7f 0b a9	stp	xzr, xzr, [sp, #0xb0]
1023087c0:	ff 63 00 f9	str	xzr, [sp, #0xc0]
1023087c4:	00 02 80 52	mov	w0, #0x10
1023087c8:	c2 24 47 94	bl	0x1034d1ad0 ; symbol stub for: __Znwm
1023087cc:	f4 03 00 aa	mov	x20, x0
1023087d0:	e8 83 07 91	add	x8, sp, #0x1e0
1023087d4:	e0 83 02 91	add	x0, sp, #0xa0
1023087d8:	a5 3c 07 94	bl	__ZNK4juce6String11toStdStringEv
1023087dc:	6c 24 47 94	bl	0x1034d198c ; symbol stub for: __ZNSt3__16thread20hardware_concurrencyEv
1023087e0:	e3 03 00 aa	mov	x3, x0
1023087e4:	e1 83 07 91	add	x1, sp, #0x1e0
1023087e8:	e0 03 14 aa	mov	x0, x20
1023087ec:	02 00 80 52	mov	w2, #0x0
1023087f0:	24 00 80 52	mov	w4, #0x1
1023087f4:	c2 f1 43 94	bl	__ZN9TFWrapper5ModelC1ERKNSt3__112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEEbib
1023087f8:	e8 df c7 39	ldrsb	w8, [sp, #0x1f7]
1023087fc:	68 00 f8 36	tbz	w8, #0x1f, 0x102308808
102308800:	e0 f3 40 f9	ldr	x0, [sp, #0x1e0]
102308804:	ad 24 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102308808:	4f 24 47 94	bl	0x1034d1944 ; symbol stub for: __ZNSt3__16chrono12system_clock3nowEv
10230880c:	28 67 01 b0	adrp	x8, 11493 ; 0x104fed000
102308810:	08 61 1a 91	add	x8, x8, #0x698 ; literal pool for: "serving_default_fltp:0"
102308814:	00 01 c0 3d	ldr	q0, [x8]
102308818:	a0 03 94 3c	stur	q0, [x29, #-0xc0]
10230881c:	08 e1 40 f8	ldur	x8, [x8, #0xe]
102308820:	e9 43 06 91	add	x9, sp, #0x190
102308824:	28 e1 0f f8	stur	x8, [x9, #0xfe]
102308828:	08 c0 82 52	mov	w8, #0x1600
10230882c:	a8 63 15 78	sturh	w8, [x29, #-0xaa]
102308830:	28 00 80 52	mov	w8, #0x1
102308834:	a8 57 36 a9	stp	x8, x21, [x29, #-0xa0]
102308838:	e0 83 07 91	add	x0, sp, #0x1e0
10230883c:	a1 83 02 d1	sub	x1, x29, #0xa0
102308840:	42 00 80 52	mov	w2, #0x2
102308844:	57 22 47 94	bl	0x1034d11a0 ; symbol stub for: __ZN10tensorflow15TensorShapeBaseINS_11TensorShapeEEC2EN4absl12lts_202308024SpanIKxEE
102308848:	e0 c3 08 91	add	x0, sp, #0x230
10230884c:	e2 83 07 91	add	x2, sp, #0x1e0
102308850:	21 00 80 52	mov	w1, #0x1
102308854:	5c 22 47 94	bl	0x1034d11c4 ; symbol stub for: __ZN10tensorflow6TensorC1ENS_8DataTypeERKNS_11TensorShapeE
102308858:	e8 bf 47 39	ldrb	w8, [sp, #0x1ef]
10230885c:	1f 09 00 71	cmp	w8, #0x2
102308860:	61 00 00 54	b.ne	0x10230886c
102308864:	e0 83 07 91	add	x0, sp, #0x1e0
102308868:	4b 22 47 94	bl	0x1034d1194 ; symbol stub for: __ZN10tensorflow14TensorShapeRep19DestructorOutOfLineEv
10230886c:	e0 c3 08 91	add	x0, sp, #0x230
102308870:	a6 22 47 94	bl	0x1034d1308 ; symbol stub for: __ZNK10tensorflow6Tensor4dataEv
102308874:	bf 06 00 f1	cmp	x21, #0x1
102308878:	0b 02 00 54	b.lt	0x1023088b8
10230887c:	bf 42 00 f1	cmp	x21, #0x10
102308880:	82 36 00 54	b.hs	0x102308f50
102308884:	08 00 80 d2	mov	x8, #0x0
102308888:	a9 02 08 cb	sub	x9, x21, x8
10230888c:	0a f5 7e d3	lsl	x10, x8, #2
102308890:	68 02 0a 8b	add	x8, x19, x10
102308894:	ca 02 0a 8b	add	x10, x22, x10
102308898:	00 10 2c 1e	fmov	s0, #0.50000000
10230889c:	41 45 40 bc	ldr	s1, [x10], #0x4
1023088a0:	02 45 40 bc	ldr	s2, [x8], #0x4
1023088a4:	41 28 21 1e	fadd	s1, s2, s1
1023088a8:	21 08 20 1e	fmul	s1, s1, s0
1023088ac:	01 44 00 bc	str	s1, [x0], #0x4
1023088b0:	29 05 00 f1	subs	x9, x9, #0x1
1023088b4:	41 ff ff 54	b.ne	0x10230889c
1023088b8:	f3 83 07 91	add	x19, sp, #0x1e0
1023088bc:	e0 83 07 91	add	x0, sp, #0x1e0
1023088c0:	a1 03 03 d1	sub	x1, x29, #0xc0
1023088c4:	30 23 47 94	bl	0x1034d1584 ; symbol stub for: __ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEEC1ERKS5_
1023088c8:	75 62 00 91	add	x21, x19, #0x18
1023088cc:	e8 23 41 f9	ldr	x8, [sp, #0x240]
1023088d0:	e8 07 01 f9	str	x8, [sp, #0x208]
1023088d4:	e8 ff 48 39	ldrb	w8, [sp, #0x23f]
1023088d8:	1f 09 00 71	cmp	w8, #0x2
1023088dc:	01 14 00 54	b.ne	0x102308b5c
1023088e0:	ff 1f 08 39	strb	wzr, [sp, #0x207]
1023088e4:	e1 c3 08 91	add	x1, sp, #0x230
1023088e8:	e0 03 15 aa	mov	x0, x21
1023088ec:	27 22 47 94	bl	0x1034d1188 ; symbol stub for: __ZN10tensorflow14TensorShapeRep12SlowCopyFromERKS0_
1023088f0:	e8 27 41 f9	ldr	x8, [sp, #0x248]
1023088f4:	e8 0b 01 f9	str	x8, [sp, #0x210]
1023088f8:	88 00 00 b4	cbz	x8, 0x102308908
1023088fc:	08 21 00 91	add	x8, x8, #0x8
102308900:	29 00 80 52	mov	w9, #0x1
102308904:		.long	0xb8290108
102308908:	e8 27 51 a9	ldp	x8, x9, [sp, #0x110]
10230890c:	1f 01 09 eb	cmp	x8, x9
102308910:	22 13 00 54	b.hs	0x102308b74
102308914:	e0 7b c0 3d	ldr	q0, [sp, #0x1e0]
102308918:	e9 fb 40 f9	ldr	x9, [sp, #0x1f0]
10230891c:	09 09 00 f9	str	x9, [x8, #0x10]
102308920:	00 01 80 3d	str	q0, [x8]
102308924:	ff ff 1e a9	stp	xzr, xzr, [sp, #0x1e8]
102308928:	ff f3 00 f9	str	xzr, [sp, #0x1e0]
10230892c:	e9 07 41 f9	ldr	x9, [sp, #0x208]
102308930:	09 15 00 f9	str	x9, [x8, #0x28]
102308934:	a0 02 c0 3d	ldr	q0, [x21]
102308938:	00 81 81 3c	stur	q0, [x8, #0x18]
10230893c:	ff 1f 08 39	strb	wzr, [sp, #0x207]
102308940:	e9 0b 41 f9	ldr	x9, [sp, #0x210]
102308944:	09 19 00 f9	str	x9, [x8, #0x30]
102308948:	ff 0b 01 f9	str	xzr, [sp, #0x210]
10230894c:	08 e1 00 91	add	x8, x8, #0x38
102308950:	e8 8b 00 f9	str	x8, [sp, #0x110]
102308954:	8b 00 00 14	b	0x102308b80
102308958:	15 00 80 d2	mov	x21, #0x0
10230895c:	13 00 80 52	mov	w19, #0x0
102308960:	48 a9 00 b0	adrp	x8, 5417 ; 0x103831000
102308964:	00 fd c3 3d	ldr	q0, [x8, #0xff0]
102308968:	e0 43 8b 3c	stur	q0, [sp, #0xb4]
10230896c:	ff 67 00 f9	str	xzr, [sp, #0xc8]
102308970:	ff 43 03 39	strb	wzr, [sp, #0xd0]
102308974:	23 05 00 14	b	0x102309e00
102308978:	16 00 80 d2	mov	x22, #0x0
10230897c:	13 00 80 52	mov	w19, #0x0
102308980:	48 a9 00 b0	adrp	x8, 5417 ; 0x103831000
102308984:	00 fd c3 3d	ldr	q0, [x8, #0xff0]
102308988:	e8 43 06 91	add	x8, sp, #0x190
10230898c:	00 c1 8c 3c	stur	q0, [x8, #0xcc]
102308990:	bf 03 13 f8	stur	xzr, [x29, #-0xd0]
102308994:	bf 83 13 38	sturb	wzr, [x29, #-0xc8]
102308998:	85 02 00 14	b	0x1023093ac
10230899c:	20 72 01 b0	adrp	x0, 11845 ; 0x10514d000
1023089a0:	00 94 45 f9	ldr	x0, [x0, #0xb28] ; literal pool symbol address: __ZNSt3__14cerrE
1023089a4:	21 67 01 b0	adrp	x1, 11493 ; 0x104fed000
1023089a8:	21 f8 19 91	add	x1, x1, #0x67e ; literal pool for: "\015\033[31m"
1023089ac:	c2 00 80 52	mov	w2, #0x6
1023089b0:	0d 21 75 97	bl	__ZNSt3__124__put_character_sequenceIcNS_11char_traitsIcEEEERNS_13basic_ostreamIT_T0_EES7_PKS4_m
1023089b4:	f4 03 00 aa	mov	x20, x0
1023089b8:	e0 a3 02 91	add	x0, sp, #0xa8
1023089bc:	63 cb 06 94	bl	__ZNK4juce6String9toRawUTF8Ev
1023089c0:	f5 03 00 aa	mov	x21, x0
1023089c4:	11 29 47 94	bl	0x1034d2e08 ; symbol stub for: _strlen
1023089c8:	e2 03 00 aa	mov	x2, x0
1023089cc:	e0 03 14 aa	mov	x0, x20
1023089d0:	e1 03 15 aa	mov	x1, x21
1023089d4:	04 21 75 97	bl	__ZNSt3__124__put_character_sequenceIcNS_11char_traitsIcEEEERNS_13basic_ostreamIT_T0_EES7_PKS4_m
1023089d8:	21 67 01 b0	adrp	x1, 11493 ; 0x104fed000
1023089dc:	21 14 1a 91	add	x1, x1, #0x685 ; literal pool for: ": models not found"
1023089e0:	42 02 80 52	mov	w2, #0x12
1023089e4:	00 21 75 97	bl	__ZNSt3__124__put_character_sequenceIcNS_11char_traitsIcEEEERNS_13basic_ostreamIT_T0_EES7_PKS4_m
1023089e8:	61 64 01 90	adrp	x1, 11404 ; 0x104f94000
1023089ec:	21 44 00 91	add	x1, x1, #0x11 ; literal pool for: "\033[0m"
1023089f0:	82 00 80 52	mov	w2, #0x4
1023089f4:	fc 20 75 97	bl	__ZNSt3__124__put_character_sequenceIcNS_11char_traitsIcEEEERNS_13basic_ostreamIT_T0_EES7_PKS4_m
1023089f8:	f4 03 00 aa	mov	x20, x0
1023089fc:	08 00 40 f9	ldr	x8, [x0]
102308a00:	08 81 5e f8	ldur	x8, [x8, #-0x18]
102308a04:	00 00 08 8b	add	x0, x0, x8
102308a08:	e8 83 07 91	add	x8, sp, #0x1e0
102308a0c:	6c 22 47 94	bl	0x1034d13bc ; symbol stub for: __ZNKSt3__18ios_base6getlocEv
102308a10:	21 72 01 b0	adrp	x1, 11845 ; 0x10514d000
102308a14:	21 a4 45 f9	ldr	x1, [x1, #0xb48] ; literal pool symbol address: __ZNSt3__15ctypeIcE2idE
102308a18:	e0 83 07 91	add	x0, sp, #0x1e0
102308a1c:	65 22 47 94	bl	0x1034d13b0 ; symbol stub for: __ZNKSt3__16locale9use_facetERNS0_2idE
102308a20:	08 00 40 f9	ldr	x8, [x0]
102308a24:	08 1d 40 f9	ldr	x8, [x8, #0x38]
102308a28:	41 01 80 52	mov	w1, #0xa
102308a2c:	00 01 3f d6	blr	x8
102308a30:	f5 03 00 aa	mov	x21, x0
102308a34:	e0 83 07 91	add	x0, sp, #0x1e0
102308a38:	d2 23 47 94	bl	0x1034d1980 ; symbol stub for: __ZNSt3__16localeD1Ev
102308a3c:	e0 03 14 aa	mov	x0, x20
102308a40:	e1 03 15 aa	mov	x1, x21
102308a44:	1b 23 47 94	bl	0x1034d16b0 ; symbol stub for: __ZNSt3__113basic_ostreamIcNS_11char_traitsIcEEE3putEc
102308a48:	e0 03 14 aa	mov	x0, x20
102308a4c:	1c 23 47 94	bl	0x1034d16bc ; symbol stub for: __ZNSt3__113basic_ostreamIcNS_11char_traitsIcEEE5flushEv
102308a50:	08 43 40 f8	ldur	x8, [x24, #0x4]
102308a54:	e8 43 0b f8	stur	x8, [sp, #0xb4]
102308a58:	00 c3 40 fc	ldur	d0, [x24, #0xc]
102308a5c:	e0 c3 0b fc	stur	d0, [sp, #0xbc]
102308a60:	b5 83 57 f8	ldur	x21, [x29, #-0x88]
102308a64:	f5 67 00 f9	str	x21, [sp, #0xc8]
102308a68:	b3 03 58 38	ldurb	w19, [x29, #-0x80]
102308a6c:	f3 43 03 39	strb	w19, [sp, #0xd0]
102308a70:	bf 43 16 f8	stur	xzr, [x29, #-0x9c]
102308a74:	bf c3 16 b8	stur	wzr, [x29, #-0x94]
102308a78:	bf 03 18 38	sturb	wzr, [x29, #-0x80]
102308a7c:	bf 83 17 f8	stur	xzr, [x29, #-0x88]
102308a80:	d9 04 00 14	b	0x102309de4
102308a84:	20 72 01 b0	adrp	x0, 11845 ; 0x10514d000
102308a88:	00 94 45 f9	ldr	x0, [x0, #0xb28] ; literal pool symbol address: __ZNSt3__14cerrE
102308a8c:	21 67 01 b0	adrp	x1, 11493 ; 0x104fed000
102308a90:	21 f8 19 91	add	x1, x1, #0x67e ; literal pool for: "\015\033[31m"
102308a94:	c2 00 80 52	mov	w2, #0x6
102308a98:	d3 20 75 97	bl	__ZNSt3__124__put_character_sequenceIcNS_11char_traitsIcEEEERNS_13basic_ostreamIT_T0_EES7_PKS4_m
102308a9c:	f4 03 00 aa	mov	x20, x0
102308aa0:	e0 83 02 91	add	x0, sp, #0xa0
102308aa4:	29 cb 06 94	bl	__ZNK4juce6String9toRawUTF8Ev
102308aa8:	f5 03 00 aa	mov	x21, x0
102308aac:	d7 28 47 94	bl	0x1034d2e08 ; symbol stub for: _strlen
102308ab0:	e2 03 00 aa	mov	x2, x0
102308ab4:	e0 03 14 aa	mov	x0, x20
102308ab8:	e1 03 15 aa	mov	x1, x21
102308abc:	ca 20 75 97	bl	__ZNSt3__124__put_character_sequenceIcNS_11char_traitsIcEEEERNS_13basic_ostreamIT_T0_EES7_PKS4_m
102308ac0:	21 67 01 b0	adrp	x1, 11493 ; 0x104fed000
102308ac4:	21 14 1a 91	add	x1, x1, #0x685 ; literal pool for: ": models not found"
102308ac8:	42 02 80 52	mov	w2, #0x12
102308acc:	c6 20 75 97	bl	__ZNSt3__124__put_character_sequenceIcNS_11char_traitsIcEEEERNS_13basic_ostreamIT_T0_EES7_PKS4_m
102308ad0:	61 64 01 90	adrp	x1, 11404 ; 0x104f94000
102308ad4:	21 44 00 91	add	x1, x1, #0x11 ; literal pool for: "\033[0m"
102308ad8:	82 00 80 52	mov	w2, #0x4
102308adc:	c2 20 75 97	bl	__ZNSt3__124__put_character_sequenceIcNS_11char_traitsIcEEEERNS_13basic_ostreamIT_T0_EES7_PKS4_m
102308ae0:	f4 03 00 aa	mov	x20, x0
102308ae4:	08 00 40 f9	ldr	x8, [x0]
102308ae8:	08 81 5e f8	ldur	x8, [x8, #-0x18]
102308aec:	00 00 08 8b	add	x0, x0, x8
102308af0:	e8 83 07 91	add	x8, sp, #0x1e0
102308af4:	32 22 47 94	bl	0x1034d13bc ; symbol stub for: __ZNKSt3__18ios_base6getlocEv
102308af8:	21 72 01 b0	adrp	x1, 11845 ; 0x10514d000
102308afc:	21 a4 45 f9	ldr	x1, [x1, #0xb48] ; literal pool symbol address: __ZNSt3__15ctypeIcE2idE
102308b00:	e0 83 07 91	add	x0, sp, #0x1e0
102308b04:	2b 22 47 94	bl	0x1034d13b0 ; symbol stub for: __ZNKSt3__16locale9use_facetERNS0_2idE
102308b08:	08 00 40 f9	ldr	x8, [x0]
102308b0c:	08 1d 40 f9	ldr	x8, [x8, #0x38]
102308b10:	41 01 80 52	mov	w1, #0xa
102308b14:	00 01 3f d6	blr	x8
102308b18:	f5 03 00 aa	mov	x21, x0
102308b1c:	e0 83 07 91	add	x0, sp, #0x1e0
102308b20:	98 23 47 94	bl	0x1034d1980 ; symbol stub for: __ZNSt3__16localeD1Ev
102308b24:	e0 03 14 aa	mov	x0, x20
102308b28:	e1 03 15 aa	mov	x1, x21
102308b2c:	e1 22 47 94	bl	0x1034d16b0 ; symbol stub for: __ZNSt3__113basic_ostreamIcNS_11char_traitsIcEEE3putEc
102308b30:	e0 03 14 aa	mov	x0, x20
102308b34:	e2 22 47 94	bl	0x1034d16bc ; symbol stub for: __ZNSt3__113basic_ostreamIcNS_11char_traitsIcEEE5flushEv
102308b38:	16 00 80 d2	mov	x22, #0x0
102308b3c:	13 00 80 52	mov	w19, #0x0
102308b40:	48 00 c0 d2	mov	x8, #0x200000000
102308b44:	e9 43 06 91	add	x9, sp, #0x190
102308b48:	28 c1 0c f8	stur	x8, [x9, #0xcc]
102308b4c:	bf 43 12 f8	stur	xzr, [x29, #-0xdc]
102308b50:	bf 03 13 f8	stur	xzr, [x29, #-0xd0]
102308b54:	bf 83 13 38	sturb	wzr, [x29, #-0xc8]
102308b58:	13 02 00 14	b	0x1023093a4
102308b5c:	e0 8f c0 3d	ldr	q0, [sp, #0x230]
102308b60:	a0 02 80 3d	str	q0, [x21]
102308b64:	e8 27 41 f9	ldr	x8, [sp, #0x248]
102308b68:	e8 0b 01 f9	str	x8, [sp, #0x210]
102308b6c:	88 ec ff b5	cbnz	x8, 0x1023088fc
102308b70:	66 ff ff 17	b	0x102308908
102308b74:	e0 23 04 91	add	x0, sp, #0x108
102308b78:	e1 83 07 91	add	x1, sp, #0x1e0
102308b7c:	62 43 00 94	bl	__ZNSt3__16vectorINS_4pairINS_12basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEEEN10tensorflow6TensorEEENS5_ISA_EEE21__push_back_slow_pathISA_EEvOT_
102308b80:	e0 03 15 aa	mov	x0, x21
102308b84:	93 21 47 94	bl	0x1034d11d0 ; symbol stub for: __ZN10tensorflow6TensorD1Ev
102308b88:	e8 df c7 39	ldrsb	w8, [sp, #0x1f7]
102308b8c:	68 00 f8 36	tbz	w8, #0x1f, 0x102308b98
102308b90:	e0 f3 40 f9	ldr	x0, [sp, #0x1e0]
102308b94:	c9 23 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102308b98:	00 04 80 52	mov	w0, #0x20
102308b9c:	cd 23 47 94	bl	0x1034d1ad0 ; symbol stub for: __Znwm
102308ba0:	a0 03 16 f8	stur	x0, [x29, #-0xa0]
102308ba4:	48 a9 00 d0	adrp	x8, 5418 ; 0x103832000
102308ba8:	00 05 c0 3d	ldr	q0, [x8, #0x10]
102308bac:	00 83 80 3c	stur	q0, [x24, #0x8]
102308bb0:	28 67 01 b0	adrp	x8, 11493 ; 0x104fed000
102308bb4:	08 bd 1a 91	add	x8, x8, #0x6af ; literal pool for: "StatefulPartitionedCall:1"
102308bb8:	00 01 c0 3d	ldr	q0, [x8]
102308bbc:	00 00 80 3d	str	q0, [x0]
102308bc0:	00 91 c0 3c	ldur	q0, [x8, #0x9]
102308bc4:	00 90 80 3c	stur	q0, [x0, #0x9]
102308bc8:	1f 64 00 39	strb	wzr, [x0, #0x19]
102308bcc:	ff 7f 1d a9	stp	xzr, xzr, [sp, #0x1d0]
102308bd0:	ff e7 00 f9	str	xzr, [sp, #0x1c8]
102308bd4:	00 03 80 52	mov	w0, #0x18
102308bd8:	be 23 47 94	bl	0x1034d1ad0 ; symbol stub for: __Znwm
102308bdc:	f5 03 00 aa	mov	x21, x0
102308be0:	e0 83 1c a9	stp	x0, x0, [sp, #0x1c8]
102308be4:	13 60 00 91	add	x19, x0, #0x18
102308be8:	f3 ef 00 f9	str	x19, [sp, #0x1d8]
102308bec:	e0 db 00 f9	str	x0, [sp, #0x1b0]
102308bf0:	e0 cb 00 f9	str	x0, [sp, #0x190]
102308bf4:	a1 83 02 d1	sub	x1, x29, #0xa0
102308bf8:	63 22 47 94	bl	0x1034d1584 ; symbol stub for: __ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEEC1ERKS5_
102308bfc:	f3 eb 00 f9	str	x19, [sp, #0x1d0]
102308c00:	a8 73 d7 38	ldursb	w8, [x29, #-0x89]
102308c04:	68 00 f8 36	tbz	w8, #0x1f, 0x102308c10
102308c08:	a0 03 56 f8	ldur	x0, [x29, #-0xa0]
102308c0c:	ab 23 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102308c10:	ff ff 1b a9	stp	xzr, xzr, [sp, #0x1b8]
102308c14:	ff db 00 f9	str	xzr, [sp, #0x1b0]
102308c18:	00 03 80 52	mov	w0, #0x18
102308c1c:	ad 23 47 94	bl	0x1034d1ad0 ; symbol stub for: __Znwm
102308c20:	f6 03 00 aa	mov	x22, x0
102308c24:	e0 03 1b a9	stp	x0, x0, [sp, #0x1b0]
102308c28:	13 60 00 91	add	x19, x0, #0x18
102308c2c:	f3 e3 00 f9	str	x19, [sp, #0x1c0]
102308c30:	a0 03 16 f8	stur	x0, [x29, #-0xa0]
102308c34:	e0 cb 00 f9	str	x0, [sp, #0x190]
102308c38:	e1 03 15 aa	mov	x1, x21
102308c3c:	52 22 47 94	bl	0x1034d1584 ; symbol stub for: __ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEEC1ERKS5_
102308c40:	f3 df 00 f9	str	x19, [sp, #0x1b8]
102308c44:	e1 23 04 91	add	x1, sp, #0x108
102308c48:	e2 c3 06 91	add	x2, sp, #0x1b0
102308c4c:	e3 c3 02 91	add	x3, sp, #0xb0
102308c50:	e0 03 14 aa	mov	x0, x20
102308c54:	ef f0 43 94	bl	__ZN9TFWrapper5Model3runERKNSt3__16vectorINS1_4pairINS1_12basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEEN10tensorflow6TensorEEENS7_ISC_EEEENS2_IS9_NS7_IS9_EEEERNS2_ISB_NS7_ISB_EEEE
102308c58:	f3 db 40 f9	ldr	x19, [sp, #0x1b0]
102308c5c:	53 02 00 b4	cbz	x19, 0x102308ca4
102308c60:	e8 df 40 f9	ldr	x8, [sp, #0x1b8]
102308c64:	1f 01 13 eb	cmp	x8, x19
102308c68:	c1 00 00 54	b.ne	0x102308c80
102308c6c:	e0 03 13 aa	mov	x0, x19
102308c70:	0b 00 00 14	b	0x102308c9c
102308c74:	e8 03 16 aa	mov	x8, x22
102308c78:	df 02 13 eb	cmp	x22, x19
102308c7c:	e0 00 00 54	b.eq	0x102308c98
102308c80:	16 61 00 d1	sub	x22, x8, #0x18
102308c84:	09 f1 df 38	ldursb	w9, [x8, #-0x1]
102308c88:	69 ff ff 36	tbz	w9, #0x1f, 0x102308c74
102308c8c:	00 81 5e f8	ldur	x0, [x8, #-0x18]
102308c90:	8a 23 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102308c94:	f8 ff ff 17	b	0x102308c74
102308c98:	e0 db 40 f9	ldr	x0, [sp, #0x1b0]
102308c9c:	f3 df 00 f9	str	x19, [sp, #0x1b8]
102308ca0:	86 23 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102308ca4:	e0 23 4b a9	ldp	x0, x8, [sp, #0xb0]
102308ca8:	1f 01 00 eb	cmp	x8, x0
102308cac:	80 10 00 54	b.eq	0x102308ebc
102308cb0:	01 00 80 52	mov	w1, #0x0
102308cb4:	92 21 47 94	bl	0x1034d12fc ; symbol stub for: __ZNK10tensorflow15TensorShapeBaseINS_11TensorShapeEE8dim_sizeEi
102308cb8:	f6 03 00 aa	mov	x22, x0
102308cbc:	e0 5b 40 f9	ldr	x0, [sp, #0xb0]
102308cc0:	21 00 80 52	mov	w1, #0x1
102308cc4:	8e 21 47 94	bl	0x1034d12fc ; symbol stub for: __ZNK10tensorflow15TensorShapeBaseINS_11TensorShapeEE8dim_sizeEi
102308cc8:	f7 03 00 aa	mov	x23, x0
102308ccc:	e0 5b 40 f9	ldr	x0, [sp, #0xb0]
102308cd0:	8e 21 47 94	bl	0x1034d1308 ; symbol stub for: __ZNK10tensorflow6Tensor4dataEv
102308cd4:	f6 e7 01 b9	str	w22, [sp, #0x1e4]
102308cd8:	f7 eb 01 b9	str	w23, [sp, #0x1e8]
102308cdc:	e8 7e 16 1b	mul	w8, w23, w22
102308ce0:	e8 ef 01 b9	str	w8, [sp, #0x1ec]
102308ce4:	ff f3 01 b9	str	wzr, [sp, #0x1f0]
102308ce8:	e0 ff 00 f9	str	x0, [sp, #0x1f8]
102308cec:	ff 03 08 39	strb	wzr, [sp, #0x200]
102308cf0:	93 00 80 52	mov	w19, #0x4
102308cf4:	80 00 80 52	mov	w0, #0x4
102308cf8:	76 23 47 94	bl	0x1034d1ad0 ; symbol stub for: __Znwm
102308cfc:	f7 03 00 aa	mov	x23, x0
102308d00:	e8 03 00 aa	mov	x8, x0
102308d04:	13 45 00 b8	str	w19, [x8], #0x4
102308d08:	e8 a3 19 a9	stp	x8, x8, [sp, #0x198]
102308d0c:	e0 cb 00 f9	str	x0, [sp, #0x190]
102308d10:	08 00 d0 d2	mov	x8, #0x800000000000
102308d14:	28 0a e8 f2	movk	x8, #0x4051, lsl #48
102308d18:	00 01 67 9e	fmov	d0, x8
102308d1c:	08 00 d0 d2	mov	x8, #0x800000000000
102308d20:	c8 0c e8 f2	movk	x8, #0x4066, lsl #48
102308d24:	01 01 67 9e	fmov	d1, x8
102308d28:	a8 99 99 52	mov	w8, #0xcccd
102308d2c:	88 a9 a7 72	movk	w8, #0x3d4c, lsl #16
102308d30:	02 01 27 1e	fmov	s2, w8
102308d34:	28 0b e8 d2	mov	x8, #0x4059000000000000
102308d38:	03 01 67 9e	fmov	d3, x8
102308d3c:	a8 83 02 d1	sub	x8, x29, #0xa0
102308d40:	e0 83 07 91	add	x0, sp, #0x1e0
102308d44:	e1 43 06 91	add	x1, sp, #0x190
102308d48:	82 07 80 52	mov	w2, #0x3c
102308d4c:	83 0c 80 52	mov	w3, #0x64
102308d50:	04 02 80 52	mov	w4, #0x10
102308d54:	25 00 80 52	mov	w5, #0x1
102308d58:	05 e0 ff 97	bl	__ZN6madmom17downbeat_trackingERKN2nc7NdArrayIfNSt3__19allocatorIfEEEERNS2_6vectorIiNS3_IiEEEEddiiifbd
102308d5c:	a8 83 02 d1	sub	x8, x29, #0xa0
102308d60:	18 41 40 f8	ldur	x24, [x8, #0x4]
102308d64:	00 c1 40 fc	ldur	d0, [x8, #0xc]
102308d68:	e0 27 80 3d	str	q0, [sp, #0x90]
102308d6c:	b6 83 57 f8	ldur	x22, [x29, #-0x88]
102308d70:	b3 03 58 38	ldurb	w19, [x29, #-0x80]
102308d74:	e0 03 17 aa	mov	x0, x23
102308d78:	50 23 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102308d7c:	e8 03 48 39	ldrb	w8, [sp, #0x200]
102308d80:	88 00 00 34	cbz	w8, 0x102308d90
102308d84:	e0 ff 40 f9	ldr	x0, [sp, #0x1f8]
102308d88:	40 00 00 b4	cbz	x0, 0x102308d90
102308d8c:	4b 23 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102308d90:	e0 27 c0 3d	ldr	q0, [sp, #0x90]
102308d94:	4e 00 00 14	b	0x102308ecc
102308d98:	1a 00 80 52	mov	w26, #0x0
102308d9c:	e8 03 15 aa	mov	x8, x21
102308da0:	e8 ff 01 a9	stp	x8, xzr, [sp, #0x18]
102308da4:	bf 06 00 71	cmp	w21, #0x1
102308da8:	2b 24 00 54	b.lt	0x10230922c
102308dac:	28 00 80 52	mov	w8, #0x1
102308db0:	f3 03 15 2a	mov	w19, w21
102308db4:	a8 cf 31 a9	stp	x8, x19, [x29, #-0xe8]
102308db8:	e0 83 07 91	add	x0, sp, #0x1e0
102308dbc:	a1 a3 03 d1	sub	x1, x29, #0xe8
102308dc0:	42 00 80 52	mov	w2, #0x2
102308dc4:	f7 20 47 94	bl	0x1034d11a0 ; symbol stub for: __ZN10tensorflow15TensorShapeBaseINS_11TensorShapeEEC2EN4absl12lts_202308024SpanIKxEE
102308dc8:	a0 03 03 d1	sub	x0, x29, #0xc0
102308dcc:	e2 83 07 91	add	x2, sp, #0x1e0
102308dd0:	21 00 80 52	mov	w1, #0x1
102308dd4:	fc 20 47 94	bl	0x1034d11c4 ; symbol stub for: __ZN10tensorflow6TensorC1ENS_8DataTypeERKNS_11TensorShapeE
102308dd8:	e8 bf 47 39	ldrb	w8, [sp, #0x1ef]
102308ddc:	1f 09 00 71	cmp	w8, #0x2
102308de0:	61 00 00 54	b.ne	0x102308dec
102308de4:	e0 83 07 91	add	x0, sp, #0x1e0
102308de8:	eb 20 47 94	bl	0x1034d1194 ; symbol stub for: __ZN10tensorflow14TensorShapeRep19DestructorOutOfLineEv
102308dec:	a0 03 03 d1	sub	x0, x29, #0xc0
102308df0:	46 21 47 94	bl	0x1034d1308 ; symbol stub for: __ZNK10tensorflow6Tensor4dataEv
102308df4:	e8 13 40 f9	ldr	x8, [sp, #0x20]
102308df8:	08 7d 40 93	sxtw	x8, w8
102308dfc:	bf 42 00 71	cmp	w21, #0x10
102308e00:	c2 0e 00 54	b.hs	0x102308fd8
102308e04:	09 00 80 d2	mov	x9, #0x0
102308e08:	6a 02 09 cb	sub	x10, x19, x9
102308e0c:	28 01 08 8b	add	x8, x9, x8
102308e10:	09 f5 7e d3	lsl	x9, x8, #2
102308e14:	e8 2f 40 f9	ldr	x8, [sp, #0x58]
102308e18:	08 01 09 8b	add	x8, x8, x9
102308e1c:	c9 02 09 8b	add	x9, x22, x9
102308e20:	00 10 2c 1e	fmov	s0, #0.50000000
102308e24:	21 45 40 bc	ldr	s1, [x9], #0x4
102308e28:	02 45 40 bc	ldr	s2, [x8], #0x4
102308e2c:	41 28 21 1e	fadd	s1, s2, s1
102308e30:	21 08 20 1e	fmul	s1, s1, s0
102308e34:	01 44 00 bc	str	s1, [x0], #0x4
102308e38:	4a 05 00 f1	subs	x10, x10, #0x1
102308e3c:	41 ff ff 54	b.ne	0x102308e24
102308e40:	f3 d3 5c a9	ldp	x19, x20, [sp, #0x1c8]
102308e44:	9f 02 13 eb	cmp	x20, x19
102308e48:	a1 02 00 54	b.ne	0x102308e9c
102308e4c:	f5 03 16 aa	mov	x21, x22
102308e50:	f3 eb 00 f9	str	x19, [sp, #0x1d0]
102308e54:	f3 83 07 91	add	x19, sp, #0x1e0
102308e58:	e0 83 07 91	add	x0, sp, #0x1e0
102308e5c:	e1 43 06 91	add	x1, sp, #0x190
102308e60:	c9 21 47 94	bl	0x1034d1584 ; symbol stub for: __ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEEC1ERKS5_
102308e64:	76 62 00 91	add	x22, x19, #0x18
102308e68:	a8 03 55 f8	ldur	x8, [x29, #-0xb0]
102308e6c:	e8 07 01 f9	str	x8, [sp, #0x208]
102308e70:	a8 f3 54 38	ldurb	w8, [x29, #-0xb1]
102308e74:	1f 09 00 71	cmp	w8, #0x2
102308e78:	01 10 00 54	b.ne	0x102309078
102308e7c:	ff 1f 08 39	strb	wzr, [sp, #0x207]
102308e80:	a1 03 03 d1	sub	x1, x29, #0xc0
102308e84:	e0 03 16 aa	mov	x0, x22
102308e88:	c0 20 47 94	bl	0x1034d1188 ; symbol stub for: __ZN10tensorflow14TensorShapeRep12SlowCopyFromERKS0_
102308e8c:	7d 00 00 14	b	0x102309080
102308e90:	f4 03 15 aa	mov	x20, x21
102308e94:	bf 02 13 eb	cmp	x21, x19
102308e98:	a0 fd ff 54	b.eq	0x102308e4c
102308e9c:	95 e2 00 d1	sub	x21, x20, #0x38
102308ea0:	80 82 00 d1	sub	x0, x20, #0x20
102308ea4:	cb 20 47 94	bl	0x1034d11d0 ; symbol stub for: __ZN10tensorflow6TensorD1Ev
102308ea8:	88 f2 dd 38	ldursb	w8, [x20, #-0x21]
102308eac:	28 ff ff 36	tbz	w8, #0x1f, 0x102308e90
102308eb0:	80 82 5c f8	ldur	x0, [x20, #-0x38]
102308eb4:	01 23 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102308eb8:	f6 ff ff 17	b	0x102308e90
102308ebc:	13 00 80 52	mov	w19, #0x0
102308ec0:	16 00 80 d2	mov	x22, #0x0
102308ec4:	00 e4 00 6f	movi.2d	v0, #0000000000000000
102308ec8:	58 00 c0 d2	mov	x24, #0x200000000
102308ecc:	e8 43 06 91	add	x8, sp, #0x190
102308ed0:	18 c1 0c f8	stur	x24, [x8, #0xcc]
102308ed4:	00 41 0d fc	stur	d0, [x8, #0xd4]
102308ed8:	b6 03 13 f8	stur	x22, [x29, #-0xd0]
102308edc:	b3 83 13 38	sturb	w19, [x29, #-0xc8]
102308ee0:	a8 5e c0 39	ldrsb	w8, [x21, #0x17]
102308ee4:	68 00 f8 36	tbz	w8, #0x1f, 0x102308ef0
102308ee8:	a0 02 40 f9	ldr	x0, [x21]
102308eec:	f3 22 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102308ef0:	f5 eb 00 f9	str	x21, [sp, #0x1d0]
102308ef4:	e0 03 15 aa	mov	x0, x21
102308ef8:	f0 22 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102308efc:	e0 c3 08 91	add	x0, sp, #0x230
102308f00:	b4 20 47 94	bl	0x1034d11d0 ; symbol stub for: __ZN10tensorflow6TensorD1Ev
102308f04:	a8 73 d5 38	ldursb	w8, [x29, #-0xa9]
102308f08:	68 00 f8 36	tbz	w8, #0x1f, 0x102308f14
102308f0c:	a0 03 54 f8	ldur	x0, [x29, #-0xc0]
102308f10:	ea 22 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102308f14:	88 02 40 f9	ldr	x8, [x20]
102308f18:	08 05 40 f9	ldr	x8, [x8, #0x8]
102308f1c:	e0 03 14 aa	mov	x0, x20
102308f20:	00 01 3f d6	blr	x8
102308f24:	f4 5b 40 f9	ldr	x20, [sp, #0xb0]
102308f28:	54 21 00 b4	cbz	x20, 0x102309350
102308f2c:	e0 5f 40 f9	ldr	x0, [sp, #0xb8]
102308f30:	1f 00 14 eb	cmp	x0, x20
102308f34:	80 20 00 54	b.eq	0x102309344
102308f38:	00 80 00 d1	sub	x0, x0, #0x20
102308f3c:	a5 20 47 94	bl	0x1034d11d0 ; symbol stub for: __ZN10tensorflow6TensorD1Ev
102308f40:	1f 00 14 eb	cmp	x0, x20
102308f44:	a1 ff ff 54	b.ne	0x102308f38
102308f48:	e0 5b 40 f9	ldr	x0, [sp, #0xb0]
102308f4c:	ff 00 00 14	b	0x102309348
102308f50:	08 00 80 d2	mov	x8, #0x0
102308f54:	09 00 13 cb	sub	x9, x0, x19
102308f58:	3f 01 01 f1	cmp	x9, #0x40
102308f5c:	63 c9 ff 54	b.lo	0x102308888
102308f60:	09 00 16 cb	sub	x9, x0, x22
102308f64:	3f 01 01 f1	cmp	x9, #0x40
102308f68:	03 c9 ff 54	b.lo	0x102308888
102308f6c:	a8 ee 7c 92	and	x8, x21, #0xfffffffffffffff0
102308f70:	09 08 08 8b	add	x9, x0, x8, lsl #2
102308f74:	ca 82 00 91	add	x10, x22, #0x20
102308f78:	0b 80 00 91	add	x11, x0, #0x20
102308f7c:	6c 82 00 91	add	x12, x19, #0x20
102308f80:	e0 67 01 4f	movi.4s	v0, #0x3f, lsl #24
102308f84:	ed 03 08 aa	mov	x13, x8
102308f88:	41 09 7f ad	ldp	q1, q2, [x10, #-0x20]
102308f8c:	43 11 c2 ac	ldp	q3, q4, [x10], #0x40
102308f90:	85 19 7f ad	ldp	q5, q6, [x12, #-0x20]
102308f94:	87 41 c2 ac	ldp	q7, q16, [x12], #0x40
102308f98:	a1 d4 21 4e	fadd.4s	v1, v5, v1
102308f9c:	c2 d4 22 4e	fadd.4s	v2, v6, v2
102308fa0:	e3 d4 23 4e	fadd.4s	v3, v7, v3
102308fa4:	04 d6 24 4e	fadd.4s	v4, v16, v4
102308fa8:	21 dc 20 6e	fmul.4s	v1, v1, v0
102308fac:	42 dc 20 6e	fmul.4s	v2, v2, v0
102308fb0:	63 dc 20 6e	fmul.4s	v3, v3, v0
102308fb4:	84 dc 20 6e	fmul.4s	v4, v4, v0
102308fb8:	61 09 3f ad	stp	q1, q2, [x11, #-0x20]
102308fbc:	63 11 82 ac	stp	q3, q4, [x11], #0x40
102308fc0:	ad 41 00 f1	subs	x13, x13, #0x10
102308fc4:	21 fe ff 54	b.ne	0x102308f88
102308fc8:	e0 03 09 aa	mov	x0, x9
102308fcc:	1f 01 15 eb	cmp	x8, x21
102308fd0:	c1 c5 ff 54	b.ne	0x102308888
102308fd4:	39 fe ff 17	b	0x1023088b8
102308fd8:	09 00 80 d2	mov	x9, #0x0
102308fdc:	0c f5 7e d3	lsl	x12, x8, #2
102308fe0:	ea 2f 40 f9	ldr	x10, [sp, #0x58]
102308fe4:	8a 01 0a 8b	add	x10, x12, x10
102308fe8:	0a 00 0a cb	sub	x10, x0, x10
102308fec:	5f 01 01 f1	cmp	x10, #0x40
102308ff0:	c3 f0 ff 54	b.lo	0x102308e08
102308ff4:	8a 01 16 8b	add	x10, x12, x22
102308ff8:	0a 00 0a cb	sub	x10, x0, x10
102308ffc:	5f 01 01 f1	cmp	x10, #0x40
102309000:	43 f0 ff 54	b.lo	0x102308e08
102309004:	69 6e 7c 92	and	x9, x19, #0xfffffff0
102309008:	0a 08 09 8b	add	x10, x0, x9, lsl #2
10230900c:	0b 80 00 91	add	x11, x0, #0x20
102309010:	8d 81 00 91	add	x13, x12, #0x20
102309014:	cc 02 0d 8b	add	x12, x22, x13
102309018:	ee 2f 40 f9	ldr	x14, [sp, #0x58]
10230901c:	cd 01 0d 8b	add	x13, x14, x13
102309020:	e0 67 01 4f	movi.4s	v0, #0x3f, lsl #24
102309024:	ee 03 09 aa	mov	x14, x9
102309028:	81 09 7f ad	ldp	q1, q2, [x12, #-0x20]
10230902c:	83 11 c2 ac	ldp	q3, q4, [x12], #0x40
102309030:	a5 19 7f ad	ldp	q5, q6, [x13, #-0x20]
102309034:	a7 41 c2 ac	ldp	q7, q16, [x13], #0x40
102309038:	a1 d4 21 4e	fadd.4s	v1, v5, v1
10230903c:	c2 d4 22 4e	fadd.4s	v2, v6, v2
102309040:	e3 d4 23 4e	fadd.4s	v3, v7, v3
102309044:	04 d6 24 4e	fadd.4s	v4, v16, v4
102309048:	21 dc 20 6e	fmul.4s	v1, v1, v0
10230904c:	42 dc 20 6e	fmul.4s	v2, v2, v0
102309050:	63 dc 20 6e	fmul.4s	v3, v3, v0
102309054:	84 dc 20 6e	fmul.4s	v4, v4, v0
102309058:	61 09 3f ad	stp	q1, q2, [x11, #-0x20]
10230905c:	63 11 82 ac	stp	q3, q4, [x11], #0x40
102309060:	ce 41 00 f1	subs	x14, x14, #0x10
102309064:	21 fe ff 54	b.ne	0x102309028
102309068:	e0 03 0a aa	mov	x0, x10
10230906c:	3f 01 13 eb	cmp	x9, x19
102309070:	c1 ec ff 54	b.ne	0x102308e08
102309074:	73 ff ff 17	b	0x102308e40
102309078:	a0 03 d4 3c	ldur	q0, [x29, #-0xc0]
10230907c:	c0 02 80 3d	str	q0, [x22]
102309080:	a8 83 55 f8	ldur	x8, [x29, #-0xa8]
102309084:	e8 0b 01 f9	str	x8, [sp, #0x210]
102309088:	88 00 00 b4	cbz	x8, 0x102309098
10230908c:	08 21 00 91	add	x8, x8, #0x8
102309090:	29 00 80 52	mov	w9, #0x1
102309094:		.long	0xb8290108
102309098:	e8 27 5d a9	ldp	x8, x9, [sp, #0x1d0]
10230909c:	1f 01 09 eb	cmp	x8, x9
1023090a0:	42 02 00 54	b.hs	0x1023090e8
1023090a4:	e0 7b c0 3d	ldr	q0, [sp, #0x1e0]
1023090a8:	e9 fb 40 f9	ldr	x9, [sp, #0x1f0]
1023090ac:	09 09 00 f9	str	x9, [x8, #0x10]
1023090b0:	00 01 80 3d	str	q0, [x8]
1023090b4:	ff ff 1e a9	stp	xzr, xzr, [sp, #0x1e8]
1023090b8:	ff f3 00 f9	str	xzr, [sp, #0x1e0]
1023090bc:	e9 07 41 f9	ldr	x9, [sp, #0x208]
1023090c0:	09 15 00 f9	str	x9, [x8, #0x28]
1023090c4:	c0 02 c0 3d	ldr	q0, [x22]
1023090c8:	00 81 81 3c	stur	q0, [x8, #0x18]
1023090cc:	ff 1f 08 39	strb	wzr, [sp, #0x207]
1023090d0:	e9 0b 41 f9	ldr	x9, [sp, #0x210]
1023090d4:	09 19 00 f9	str	x9, [x8, #0x30]
1023090d8:	ff 0b 01 f9	str	xzr, [sp, #0x210]
1023090dc:	08 e1 00 91	add	x8, x8, #0x38
1023090e0:	e8 eb 00 f9	str	x8, [sp, #0x1d0]
1023090e4:	04 00 00 14	b	0x1023090f4
1023090e8:	e0 23 07 91	add	x0, sp, #0x1c8
1023090ec:	e1 83 07 91	add	x1, sp, #0x1e0
1023090f0:	05 42 00 94	bl	__ZNSt3__16vectorINS_4pairINS_12basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEEEN10tensorflow6TensorEEENS5_ISA_EEE21__push_back_slow_pathISA_EEvOT_
1023090f4:	e0 03 16 aa	mov	x0, x22
1023090f8:	36 20 47 94	bl	0x1034d11d0 ; symbol stub for: __ZN10tensorflow6TensorD1Ev
1023090fc:	e8 df c7 39	ldrsb	w8, [sp, #0x1f7]
102309100:	68 00 f8 36	tbz	w8, #0x1f, 0x10230910c
102309104:	e0 f3 40 f9	ldr	x0, [sp, #0x1e0]
102309108:	6c 22 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10230910c:	00 04 80 52	mov	w0, #0x20
102309110:	70 22 47 94	bl	0x1034d1ad0 ; symbol stub for: __Znwm
102309114:	a0 83 11 f8	stur	x0, [x29, #-0xe8]
102309118:	48 a9 00 b0	adrp	x8, 5417 ; 0x103832000
10230911c:	00 05 c0 3d	ldr	q0, [x8, #0x10]
102309120:	e8 43 06 91	add	x8, sp, #0x190
102309124:	00 01 8d 3c	stur	q0, [x8, #0xd0]
102309128:	28 67 01 90	adrp	x8, 11492 ; 0x104fed000
10230912c:	08 bd 1a 91	add	x8, x8, #0x6af ; literal pool for: "StatefulPartitionedCall:1"
102309130:	00 01 c0 3d	ldr	q0, [x8]
102309134:	00 00 80 3d	str	q0, [x0]
102309138:	00 91 c0 3c	ldur	q0, [x8, #0x9]
10230913c:	00 90 80 3c	stur	q0, [x0, #0x9]
102309140:	1f 64 00 39	strb	wzr, [x0, #0x19]
102309144:	ff ff 16 a9	stp	xzr, xzr, [sp, #0x168]
102309148:	ff b3 00 f9	str	xzr, [sp, #0x160]
10230914c:	00 03 80 52	mov	w0, #0x18
102309150:	60 22 47 94	bl	0x1034d1ad0 ; symbol stub for: __Znwm
102309154:	f6 03 00 aa	mov	x22, x0
102309158:	e0 03 16 a9	stp	x0, x0, [sp, #0x160]
10230915c:	13 60 00 91	add	x19, x0, #0x18
102309160:	f3 bb 00 f9	str	x19, [sp, #0x170]
102309164:	e0 1b 01 f9	str	x0, [sp, #0x230]
102309168:	e0 87 00 f9	str	x0, [sp, #0x108]
10230916c:	a1 a3 03 d1	sub	x1, x29, #0xe8
102309170:	05 21 47 94	bl	0x1034d1584 ; symbol stub for: __ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEEC1ERKS5_
102309174:	f3 b7 00 f9	str	x19, [sp, #0x168]
102309178:	a8 f3 d2 38	ldursb	w8, [x29, #-0xd1]
10230917c:	68 00 f8 36	tbz	w8, #0x1f, 0x102309188
102309180:	a0 83 51 f8	ldur	x0, [x29, #-0xe8]
102309184:	4d 22 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102309188:	ff ff 13 a9	stp	xzr, xzr, [sp, #0x138]
10230918c:	ff 9b 00 f9	str	xzr, [sp, #0x130]
102309190:	00 03 80 52	mov	w0, #0x18
102309194:	4f 22 47 94	bl	0x1034d1ad0 ; symbol stub for: __Znwm
102309198:	f7 03 00 aa	mov	x23, x0
10230919c:	e0 03 13 a9	stp	x0, x0, [sp, #0x130]
1023091a0:	13 60 00 91	add	x19, x0, #0x18
1023091a4:	f3 a3 00 f9	str	x19, [sp, #0x140]
1023091a8:	a0 83 11 f8	stur	x0, [x29, #-0xe8]
1023091ac:	e0 1b 01 f9	str	x0, [sp, #0x230]
1023091b0:	e1 03 16 aa	mov	x1, x22
1023091b4:	f4 20 47 94	bl	0x1034d1584 ; symbol stub for: __ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEEC1ERKS5_
1023091b8:	f3 9f 00 f9	str	x19, [sp, #0x138]
1023091bc:	e1 23 07 91	add	x1, sp, #0x1c8
1023091c0:	e2 c3 04 91	add	x2, sp, #0x130
1023091c4:	e3 c3 06 91	add	x3, sp, #0x1b0
1023091c8:	e0 4b 40 f9	ldr	x0, [sp, #0x90]
1023091cc:	91 ef 43 94	bl	__ZN9TFWrapper5Model3runERKNSt3__16vectorINS1_4pairINS1_12basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEEN10tensorflow6TensorEEENS7_ISC_EEEENS2_IS9_NS7_IS9_EEEERNS2_ISB_NS7_ISB_EEEE
1023091d0:	f3 9b 40 f9	ldr	x19, [sp, #0x130]
1023091d4:	93 03 00 b4	cbz	x19, 0x102309244
1023091d8:	e8 9f 40 f9	ldr	x8, [sp, #0x138]
1023091dc:	1f 01 13 eb	cmp	x8, x19
1023091e0:	c1 00 00 54	b.ne	0x1023091f8
1023091e4:	e0 03 13 aa	mov	x0, x19
1023091e8:	15 00 00 14	b	0x10230923c
1023091ec:	e8 03 14 aa	mov	x8, x20
1023091f0:	9f 02 13 eb	cmp	x20, x19
1023091f4:	20 02 00 54	b.eq	0x102309238
1023091f8:	14 61 00 d1	sub	x20, x8, #0x18
1023091fc:	09 f1 df 38	ldursb	w9, [x8, #-0x1]
102309200:	69 ff ff 36	tbz	w9, #0x1f, 0x1023091ec
102309204:	00 81 5e f8	ldur	x0, [x8, #-0x18]
102309208:	2c 22 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10230920c:	f8 ff ff 17	b	0x1023091ec
102309210:	f9 0b 40 f9	ldr	x25, [sp, #0x10]
102309214:	b8 83 02 d1	sub	x24, x29, #0xa0
102309218:	f6 17 40 f9	ldr	x22, [sp, #0x28]
10230921c:	fa 0f 40 b9	ldr	w26, [sp, #0xc]
102309220:	f5 03 40 f9	ldr	x21, [sp]
102309224:	bf 06 00 71	cmp	w21, #0x1
102309228:	2a dc ff 54	b.ge	0x102308dac
10230922c:	5f 07 00 71	cmp	w26, #0x1
102309230:	ea 20 00 54	b.ge	0x10230964c
102309234:	b5 02 00 14	b	0x102309d08
102309238:	e0 9b 40 f9	ldr	x0, [sp, #0x130]
10230923c:	f3 9f 00 f9	str	x19, [sp, #0x138]
102309240:	1e 22 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102309244:	e0 23 5b a9	ldp	x0, x8, [sp, #0x1b0]
102309248:	1f 01 00 eb	cmp	x8, x0
10230924c:	80 1e 00 54	b.eq	0x10230961c
102309250:	01 00 80 52	mov	w1, #0x0
102309254:	2a 20 47 94	bl	0x1034d12fc ; symbol stub for: __ZNK10tensorflow15TensorShapeBaseINS_11TensorShapeEE8dim_sizeEi
102309258:	f7 03 00 aa	mov	x23, x0
10230925c:	e0 db 40 f9	ldr	x0, [sp, #0x1b0]
102309260:	21 00 80 52	mov	w1, #0x1
102309264:	26 20 47 94	bl	0x1034d12fc ; symbol stub for: __ZNK10tensorflow15TensorShapeBaseINS_11TensorShapeEE8dim_sizeEi
102309268:	f8 03 00 aa	mov	x24, x0
10230926c:	e0 db 40 f9	ldr	x0, [sp, #0x1b0]
102309270:	26 20 47 94	bl	0x1034d1308 ; symbol stub for: __ZNK10tensorflow6Tensor4dataEv
102309274:	b7 e3 23 29	stp	w23, w24, [x29, #-0xe4]
102309278:	08 7f 17 1b	mul	w8, w24, w23
10230927c:	a8 ff 24 29	stp	w8, wzr, [x29, #-0xdc]
102309280:	a0 03 13 f8	stur	x0, [x29, #-0xd0]
102309284:	bf 83 13 38	sturb	wzr, [x29, #-0xc8]
102309288:	93 00 80 52	mov	w19, #0x4
10230928c:	80 00 80 52	mov	w0, #0x4
102309290:	10 22 47 94	bl	0x1034d1ad0 ; symbol stub for: __Znwm
102309294:	f7 03 00 aa	mov	x23, x0
102309298:	e8 03 00 aa	mov	x8, x0
10230929c:	13 45 00 b8	str	w19, [x8], #0x4
1023092a0:	e8 a3 0f a9	stp	x8, x8, [sp, #0xf8]
1023092a4:	e0 7b 00 f9	str	x0, [sp, #0xf0]
1023092a8:	08 00 d0 d2	mov	x8, #0x800000000000
1023092ac:	28 0a e8 f2	movk	x8, #0x4051, lsl #48
1023092b0:	00 01 67 9e	fmov	d0, x8
1023092b4:	08 00 d0 d2	mov	x8, #0x800000000000
1023092b8:	c8 0c e8 f2	movk	x8, #0x4066, lsl #48
1023092bc:	01 01 67 9e	fmov	d1, x8
1023092c0:	a8 99 99 52	mov	w8, #0xcccd
1023092c4:	88 a9 a7 72	movk	w8, #0x3d4c, lsl #16
1023092c8:	02 01 27 1e	fmov	s2, w8
1023092cc:	28 0b e8 d2	mov	x8, #0x4059000000000000
1023092d0:	03 01 67 9e	fmov	d3, x8
1023092d4:	e8 c3 08 91	add	x8, sp, #0x230
1023092d8:	a0 a3 03 d1	sub	x0, x29, #0xe8
1023092dc:	e1 c3 03 91	add	x1, sp, #0xf0
1023092e0:	82 07 80 52	mov	w2, #0x3c
1023092e4:	83 0c 80 52	mov	w3, #0x64
1023092e8:	04 02 80 52	mov	w4, #0x10
1023092ec:	25 00 80 52	mov	w5, #0x1
1023092f0:	9f de ff 97	bl	__ZN6madmom17downbeat_trackingERKN2nc7NdArrayIfNSt3__19allocatorIfEEEERNS2_6vectorIiNS3_IiEEEEddiiifbd
1023092f4:	b8 83 02 d1	sub	x24, x29, #0xa0
1023092f8:	e8 13 40 f9	ldr	x8, [sp, #0x20]
1023092fc:	1f 05 00 71	cmp	w8, #0x1
102309300:	8b 06 00 54	b.lt	0x1023093d0
102309304:	e8 43 06 91	add	x8, sp, #0x190
102309308:	08 41 4a f8	ldur	x8, [x8, #0xa4]
10230930c:	0a 05 00 71	subs	w10, w8, #0x1
102309310:	eb 16 00 54	b.lt	0x1023095ec
102309314:	e9 13 40 f9	ldr	x9, [sp, #0x20]
102309318:	20 01 22 1e	scvtf	s0, w9
10230931c:	09 7d 40 92	and	x9, x8, #0xffffffff
102309320:	cb f8 86 52	mov	w11, #0x37c6
102309324:	cb f7 a6 72	movk	w11, #0x37be, lsl #16
102309328:	61 01 27 1e	fmov	s1, w11
10230932c:	00 08 21 1e	fmul	s0, s0, s1
102309330:	eb 27 41 f9	ldr	x11, [sp, #0x248]
102309334:	3f 11 00 f1	cmp	x9, #0x4
102309338:	42 05 00 54	b.hs	0x1023093e0
10230933c:	0c 00 80 d2	mov	x12, #0x0
102309340:	3c 00 00 14	b	0x102309430
102309344:	e0 03 14 aa	mov	x0, x20
102309348:	f4 5f 00 f9	str	x20, [sp, #0xb8]
10230934c:	db 21 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102309350:	f4 87 40 f9	ldr	x20, [sp, #0x108]
102309354:	94 02 00 b4	cbz	x20, 0x1023093a4
102309358:	f5 8b 40 f9	ldr	x21, [sp, #0x110]
10230935c:	bf 02 14 eb	cmp	x21, x20
102309360:	c1 00 00 54	b.ne	0x102309378
102309364:	e0 03 14 aa	mov	x0, x20
102309368:	0d 00 00 14	b	0x10230939c
10230936c:	f5 03 17 aa	mov	x21, x23
102309370:	ff 02 14 eb	cmp	x23, x20
102309374:	20 01 00 54	b.eq	0x102309398
102309378:	b7 e2 00 d1	sub	x23, x21, #0x38
10230937c:	a0 82 00 d1	sub	x0, x21, #0x20
102309380:	94 1f 47 94	bl	0x1034d11d0 ; symbol stub for: __ZN10tensorflow6TensorD1Ev
102309384:	a8 f2 dd 38	ldursb	w8, [x21, #-0x21]
102309388:	28 ff ff 36	tbz	w8, #0x1f, 0x10230936c
10230938c:	a0 82 5c f8	ldur	x0, [x21, #-0x38]
102309390:	ca 21 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102309394:	f6 ff ff 17	b	0x10230936c
102309398:	e0 87 40 f9	ldr	x0, [sp, #0x108]
10230939c:	f4 8b 00 f9	str	x20, [sp, #0x110]
1023093a0:	c6 21 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
1023093a4:	e0 83 05 91	add	x0, sp, #0x160
1023093a8:	d5 84 06 94	bl	__ZN4juce6StringD1Ev
1023093ac:	a1 a3 03 d1	sub	x1, x29, #0xe8
1023093b0:	e0 03 19 aa	mov	x0, x25
1023093b4:	88 04 00 94	bl	__ZN6madmomL9to_vectorERKN2nc7NdArrayIfNSt3__19allocatorIfEEEE
1023093b8:	93 00 00 34	cbz	w19, 0x1023093c8
1023093bc:	76 00 00 b4	cbz	x22, 0x1023093c8
1023093c0:	e0 03 16 aa	mov	x0, x22
1023093c4:	bd 21 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
1023093c8:	e0 83 02 91	add	x0, sp, #0xa0
1023093cc:	95 02 00 14	b	0x102309e20
1023093d0:	a0 83 02 d1	sub	x0, x29, #0xa0
1023093d4:	e1 c3 08 91	add	x1, sp, #0x230
1023093d8:	83 54 96 97	bl	__ZN2nc7NdArrayIfNSt3__19allocatorIfEEEaSERKS4_
1023093dc:	84 00 00 14	b	0x1023095ec
1023093e0:	2d 05 40 92	and	x13, x9, #0x3
1023093e4:	2c 75 7e 92	and	x12, x9, #0xfffffffc
1023093e8:	6e 41 00 91	add	x14, x11, #0x10
1023093ec:	ef 03 0c aa	mov	x15, x12
1023093f0:	c1 01 5f bc	ldur	s1, [x14, #-0x10]
1023093f4:	c2 81 5f bc	ldur	s2, [x14, #-0x8]
1023093f8:	c3 01 40 bd	ldr	s3, [x14]
1023093fc:	c4 09 40 bd	ldr	s4, [x14, #0x8]
102309400:	21 28 20 1e	fadd	s1, s1, s0
102309404:	42 28 20 1e	fadd	s2, s2, s0
102309408:	63 28 20 1e	fadd	s3, s3, s0
10230940c:	84 28 20 1e	fadd	s4, s4, s0
102309410:	c1 01 1f bc	stur	s1, [x14, #-0x10]
102309414:	c2 81 1f bc	stur	s2, [x14, #-0x8]
102309418:	c3 01 00 bd	str	s3, [x14]
10230941c:	c4 09 00 bd	str	s4, [x14, #0x8]
102309420:	ce 81 00 91	add	x14, x14, #0x20
102309424:	ef 11 00 f1	subs	x15, x15, #0x4
102309428:	41 fe ff 54	b.ne	0x1023093f0
10230942c:	0d 01 00 b4	cbz	x13, 0x10230944c
102309430:	2d 01 0c cb	sub	x13, x9, x12
102309434:	6c 0d 0c 8b	add	x12, x11, x12, lsl #3
102309438:	81 01 40 bd	ldr	s1, [x12]
10230943c:	21 28 20 1e	fadd	s1, s1, s0
102309440:	81 85 00 bc	str	s1, [x12], #0x8
102309444:	ad 05 00 f1	subs	x13, x13, #0x1
102309448:	81 ff ff 54	b.ne	0x102309438
10230944c:	ac c3 56 b8	ldur	w12, [x29, #-0x94]
102309450:	9f 05 00 71	cmp	w12, #0x1
102309454:	69 03 00 54	b.ls	0x1023094c0
102309458:	1f 09 00 71	cmp	w8, #0x2
10230945c:	eb 04 00 54	b.lt	0x1023094f8
102309460:	8d 09 00 51	sub	w13, w12, #0x2
102309464:	8c 7d 8d 0a	and	w12, w12, w13, asr #31
102309468:	8c 01 0d 0b	add	w12, w12, w13
10230946c:	ad 83 57 f8	ldur	x13, [x29, #-0x88]
102309470:	a0 d9 6c bc	ldr	s0, [x13, w12, sxtw #2]
102309474:	61 01 40 bd	ldr	s1, [x11]
102309478:	02 d4 a1 7e	fabd	s2, s0, s1
10230947c:	61 09 40 bd	ldr	s1, [x11, #0x8]
102309480:	01 d4 a1 7e	fabd	s1, s0, s1
102309484:	40 20 21 1e	fcmp	s2, s1
102309488:	8d 03 00 54	b.le	0x1023094f8
10230948c:	0c 00 80 d2	mov	x12, #0x0
102309490:	6b 41 00 91	add	x11, x11, #0x10
102309494:	2d 09 00 d1	sub	x13, x9, #0x2
102309498:	bf 01 0c eb	cmp	x13, x12
10230949c:	00 03 00 54	b.eq	0x1023094fc
1023094a0:	62 85 40 bc	ldr	s2, [x11], #0x8
1023094a4:	02 d4 a2 7e	fabd	s2, s0, s2
1023094a8:	8c 05 00 91	add	x12, x12, #0x1
1023094ac:	20 20 22 1e	fcmp	s1, s2
1023094b0:	41 40 20 1e	fmov	s1, s2
1023094b4:	2c ff ff 54	b.gt	0x102309498
1023094b8:	ea 03 0c aa	mov	x10, x12
1023094bc:	10 00 00 14	b	0x1023094fc
1023094c0:	f3 83 07 91	add	x19, sp, #0x1e0
1023094c4:	e0 83 07 91	add	x0, sp, #0x1e0
1023094c8:	a1 83 02 d1	sub	x1, x29, #0xa0
1023094cc:	69 85 96 97	bl	__ZN2nc7NdArrayIfNSt3__19allocatorIfEEEC2ERKS4_
1023094d0:	60 a2 00 91	add	x0, x19, #0x28
1023094d4:	e1 c3 08 91	add	x1, sp, #0x230
1023094d8:	66 85 96 97	bl	__ZN2nc7NdArrayIfNSt3__19allocatorIfEEEC2ERKS4_
1023094dc:	e8 83 07 91	add	x8, sp, #0x1e0
1023094e0:	49 00 80 52	mov	w9, #0x2
1023094e4:	e8 a7 0d a9	stp	x8, x9, [sp, #0xd8]
1023094e8:	e8 23 04 91	add	x8, sp, #0x108
1023094ec:	e0 63 03 91	add	x0, sp, #0xd8
1023094f0:	f6 41 00 94	bl	__ZN2nc9row_stackIfEENS_7NdArrayIT_NSt3__19allocatorIS2_EEEERKSt16initializer_listIS6_E
1023094f4:	21 00 00 14	b	0x102309578
1023094f8:	0a 00 80 52	mov	w10, #0x0
1023094fc:	41 05 00 11	add	w1, w10, #0x1
102309500:	3f 00 08 6b	cmp	w1, w8
102309504:	4a 07 00 54	b.ge	0x1023095ec
102309508:	21 7d 60 b3	bfi	x1, x9, #32, #32
10230950c:	e8 83 07 91	add	x8, sp, #0x1e0
102309510:	e0 c3 08 91	add	x0, sp, #0x230
102309514:	22 00 80 52	mov	w2, #0x1
102309518:	43 00 c0 d2	mov	x3, #0x200000000
10230951c:	24 00 80 52	mov	w4, #0x1
102309520:	40 87 96 97	bl	__ZNK2nc7NdArrayIfNSt3__19allocatorIfEEEclENS_5SliceES5_
102309524:	e0 c3 08 91	add	x0, sp, #0x230
102309528:	e1 83 07 91	add	x1, sp, #0x1e0
10230952c:	a1 40 00 94	bl	__ZN2nc7NdArrayIfNSt3__19allocatorIfEEEaSEOS4_
102309530:	e8 03 48 39	ldrb	w8, [sp, #0x200]
102309534:	88 00 00 34	cbz	w8, 0x102309544
102309538:	e0 ff 40 f9	ldr	x0, [sp, #0x1f8]
10230953c:	40 00 00 b4	cbz	x0, 0x102309544
102309540:	5e 21 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102309544:	f3 83 07 91	add	x19, sp, #0x1e0
102309548:	e0 83 07 91	add	x0, sp, #0x1e0
10230954c:	a1 83 02 d1	sub	x1, x29, #0xa0
102309550:	48 85 96 97	bl	__ZN2nc7NdArrayIfNSt3__19allocatorIfEEEC2ERKS4_
102309554:	60 a2 00 91	add	x0, x19, #0x28
102309558:	e1 c3 08 91	add	x1, sp, #0x230
10230955c:	45 85 96 97	bl	__ZN2nc7NdArrayIfNSt3__19allocatorIfEEEC2ERKS4_
102309560:	e8 83 07 91	add	x8, sp, #0x1e0
102309564:	49 00 80 52	mov	w9, #0x2
102309568:	e8 a7 0d a9	stp	x8, x9, [sp, #0xd8]
10230956c:	e8 23 04 91	add	x8, sp, #0x108
102309570:	e0 63 03 91	add	x0, sp, #0xd8
102309574:	d5 41 00 94	bl	__ZN2nc9row_stackIfEENS_7NdArrayIT_NSt3__19allocatorIS2_EEEERKSt16initializer_listIS6_E
102309578:	a0 83 02 d1	sub	x0, x29, #0xa0
10230957c:	e1 23 04 91	add	x1, sp, #0x108
102309580:	8c 40 00 94	bl	__ZN2nc7NdArrayIfNSt3__19allocatorIfEEEaSEOS4_
102309584:	e8 a3 44 39	ldrb	w8, [sp, #0x128]
102309588:	88 00 00 34	cbz	w8, 0x102309598
10230958c:	e0 93 40 f9	ldr	x0, [sp, #0x120]
102309590:	40 00 00 b4	cbz	x0, 0x102309598
102309594:	49 21 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102309598:	ff 93 00 f9	str	xzr, [sp, #0x120]
10230959c:	ff a3 04 39	strb	wzr, [sp, #0x128]
1023095a0:	e8 57 00 91	add	x8, sp, #0x15
1023095a4:	1f f1 0f f8	stur	xzr, [x8, #0xff]
1023095a8:	e8 37 00 91	add	x8, sp, #0xd
1023095ac:	1f f1 0f f8	stur	xzr, [x8, #0xff]
1023095b0:	e8 a3 48 39	ldrb	w8, [sp, #0x228]
1023095b4:	88 00 00 34	cbz	w8, 0x1023095c4
1023095b8:	e0 13 41 f9	ldr	x0, [sp, #0x220]
1023095bc:	40 00 00 b4	cbz	x0, 0x1023095c4
1023095c0:	3e 21 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
1023095c4:	ff 13 01 f9	str	xzr, [sp, #0x220]
1023095c8:	ff a3 08 39	strb	wzr, [sp, #0x228]
1023095cc:	e8 43 06 91	add	x8, sp, #0x190
1023095d0:	1f 41 08 f8	stur	xzr, [x8, #0x84]
1023095d4:	1f c1 07 f8	stur	xzr, [x8, #0x7c]
1023095d8:	e8 03 48 39	ldrb	w8, [sp, #0x200]
1023095dc:	88 00 00 34	cbz	w8, 0x1023095ec
1023095e0:	e0 ff 40 f9	ldr	x0, [sp, #0x1f8]
1023095e4:	40 00 00 b4	cbz	x0, 0x1023095ec
1023095e8:	34 21 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
1023095ec:	e8 43 49 39	ldrb	w8, [sp, #0x250]
1023095f0:	88 00 00 34	cbz	w8, 0x102309600
1023095f4:	e0 27 41 f9	ldr	x0, [sp, #0x248]
1023095f8:	40 00 00 b4	cbz	x0, 0x102309600
1023095fc:	2f 21 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102309600:	e0 03 17 aa	mov	x0, x23
102309604:	2d 21 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102309608:	a8 83 53 38	ldurb	w8, [x29, #-0xc8]
10230960c:	88 00 00 34	cbz	w8, 0x10230961c
102309610:	a0 03 53 f8	ldur	x0, [x29, #-0xd0]
102309614:	40 00 00 b4	cbz	x0, 0x10230961c
102309618:	28 21 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10230961c:	c8 5e c0 39	ldrsb	w8, [x22, #0x17]
102309620:	68 00 f8 36	tbz	w8, #0x1f, 0x10230962c
102309624:	c0 02 40 f9	ldr	x0, [x22]
102309628:	24 21 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10230962c:	f6 b7 00 f9	str	x22, [sp, #0x168]
102309630:	e0 03 16 aa	mov	x0, x22
102309634:	21 21 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102309638:	a0 03 03 d1	sub	x0, x29, #0xc0
10230963c:	e5 1e 47 94	bl	0x1034d11d0 ; symbol stub for: __ZN10tensorflow6TensorD1Ev
102309640:	f6 03 15 aa	mov	x22, x21
102309644:	5f 07 00 71	cmp	w26, #0x1
102309648:	0b 36 00 54	b.lt	0x102309d08
10230964c:	28 00 80 52	mov	w8, #0x1
102309650:	f3 03 1a 2a	mov	w19, w26
102309654:	a8 cf 31 a9	stp	x8, x19, [x29, #-0xe8]
102309658:	e0 83 07 91	add	x0, sp, #0x1e0
10230965c:	a1 a3 03 d1	sub	x1, x29, #0xe8
102309660:	42 00 80 52	mov	w2, #0x2
102309664:	cf 1e 47 94	bl	0x1034d11a0 ; symbol stub for: __ZN10tensorflow15TensorShapeBaseINS_11TensorShapeEEC2EN4absl12lts_202308024SpanIKxEE
102309668:	a0 03 03 d1	sub	x0, x29, #0xc0
10230966c:	e2 83 07 91	add	x2, sp, #0x1e0
102309670:	21 00 80 52	mov	w1, #0x1
102309674:	d4 1e 47 94	bl	0x1034d11c4 ; symbol stub for: __ZN10tensorflow6TensorC1ENS_8DataTypeERKNS_11TensorShapeE
102309678:	e8 bf 47 39	ldrb	w8, [sp, #0x1ef]
10230967c:	1f 09 00 71	cmp	w8, #0x2
102309680:	61 00 00 54	b.ne	0x10230968c
102309684:	e0 83 07 91	add	x0, sp, #0x1e0
102309688:	c3 1e 47 94	bl	0x1034d1194 ; symbol stub for: __ZN10tensorflow14TensorShapeRep19DestructorOutOfLineEv
10230968c:	a0 03 03 d1	sub	x0, x29, #0xc0
102309690:	1e 1f 47 94	bl	0x1034d1308 ; symbol stub for: __ZNK10tensorflow6Tensor4dataEv
102309694:	e8 0f 40 f9	ldr	x8, [sp, #0x18]
102309698:	08 7d 40 93	sxtw	x8, w8
10230969c:	5f 43 00 71	cmp	w26, #0x10
1023096a0:	c2 05 00 54	b.hs	0x102309758
1023096a4:	09 00 80 d2	mov	x9, #0x0
1023096a8:	6a 02 09 cb	sub	x10, x19, x9
1023096ac:	28 01 08 8b	add	x8, x9, x8
1023096b0:	09 f5 7e d3	lsl	x9, x8, #2
1023096b4:	e8 2f 40 f9	ldr	x8, [sp, #0x58]
1023096b8:	08 01 09 8b	add	x8, x8, x9
1023096bc:	c9 02 09 8b	add	x9, x22, x9
1023096c0:	00 10 2c 1e	fmov	s0, #0.50000000
1023096c4:	21 45 40 bc	ldr	s1, [x9], #0x4
1023096c8:	02 45 40 bc	ldr	s2, [x8], #0x4
1023096cc:	41 28 21 1e	fadd	s1, s2, s1
1023096d0:	21 08 20 1e	fmul	s1, s1, s0
1023096d4:	01 44 00 bc	str	s1, [x0], #0x4
1023096d8:	4a 05 00 f1	subs	x10, x10, #0x1
1023096dc:	41 ff ff 54	b.ne	0x1023096c4
1023096e0:	f3 d3 5c a9	ldp	x19, x20, [sp, #0x1c8]
1023096e4:	9f 02 13 eb	cmp	x20, x19
1023096e8:	81 02 00 54	b.ne	0x102309738
1023096ec:	f3 eb 00 f9	str	x19, [sp, #0x1d0]
1023096f0:	f3 83 07 91	add	x19, sp, #0x1e0
1023096f4:	e0 83 07 91	add	x0, sp, #0x1e0
1023096f8:	e1 43 06 91	add	x1, sp, #0x190
1023096fc:	a2 1f 47 94	bl	0x1034d1584 ; symbol stub for: __ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEEC1ERKS5_
102309700:	75 62 00 91	add	x21, x19, #0x18
102309704:	a8 03 55 f8	ldur	x8, [x29, #-0xb0]
102309708:	e8 07 01 f9	str	x8, [sp, #0x208]
10230970c:	a8 f3 54 38	ldurb	w8, [x29, #-0xb1]
102309710:	1f 09 00 71	cmp	w8, #0x2
102309714:	21 07 00 54	b.ne	0x1023097f8
102309718:	ff 1f 08 39	strb	wzr, [sp, #0x207]
10230971c:	a1 03 03 d1	sub	x1, x29, #0xc0
102309720:	e0 03 15 aa	mov	x0, x21
102309724:	99 1e 47 94	bl	0x1034d1188 ; symbol stub for: __ZN10tensorflow14TensorShapeRep12SlowCopyFromERKS0_
102309728:	36 00 00 14	b	0x102309800
10230972c:	f4 03 15 aa	mov	x20, x21
102309730:	bf 02 13 eb	cmp	x21, x19
102309734:	c0 fd ff 54	b.eq	0x1023096ec
102309738:	95 e2 00 d1	sub	x21, x20, #0x38
10230973c:	80 82 00 d1	sub	x0, x20, #0x20
102309740:	a4 1e 47 94	bl	0x1034d11d0 ; symbol stub for: __ZN10tensorflow6TensorD1Ev
102309744:	88 f2 dd 38	ldursb	w8, [x20, #-0x21]
102309748:	28 ff ff 36	tbz	w8, #0x1f, 0x10230972c
10230974c:	80 82 5c f8	ldur	x0, [x20, #-0x38]
102309750:	da 20 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102309754:	f6 ff ff 17	b	0x10230972c
102309758:	09 00 80 d2	mov	x9, #0x0
10230975c:	0c f5 7e d3	lsl	x12, x8, #2
102309760:	ea 2f 40 f9	ldr	x10, [sp, #0x58]
102309764:	8a 01 0a 8b	add	x10, x12, x10
102309768:	0a 00 0a cb	sub	x10, x0, x10
10230976c:	5f 01 01 f1	cmp	x10, #0x40
102309770:	c3 f9 ff 54	b.lo	0x1023096a8
102309774:	8a 01 16 8b	add	x10, x12, x22
102309778:	0a 00 0a cb	sub	x10, x0, x10
10230977c:	5f 01 01 f1	cmp	x10, #0x40
102309780:	43 f9 ff 54	b.lo	0x1023096a8
102309784:	69 6e 7c 92	and	x9, x19, #0xfffffff0
102309788:	0a 08 09 8b	add	x10, x0, x9, lsl #2
10230978c:	0b 80 00 91	add	x11, x0, #0x20
102309790:	8d 81 00 91	add	x13, x12, #0x20
102309794:	cc 02 0d 8b	add	x12, x22, x13
102309798:	ee 2f 40 f9	ldr	x14, [sp, #0x58]
10230979c:	cd 01 0d 8b	add	x13, x14, x13
1023097a0:	e0 67 01 4f	movi.4s	v0, #0x3f, lsl #24
1023097a4:	ee 03 09 aa	mov	x14, x9
1023097a8:	81 09 7f ad	ldp	q1, q2, [x12, #-0x20]
1023097ac:	83 11 c2 ac	ldp	q3, q4, [x12], #0x40
1023097b0:	a5 19 7f ad	ldp	q5, q6, [x13, #-0x20]
1023097b4:	a7 41 c2 ac	ldp	q7, q16, [x13], #0x40
1023097b8:	a1 d4 21 4e	fadd.4s	v1, v5, v1
1023097bc:	c2 d4 22 4e	fadd.4s	v2, v6, v2
1023097c0:	e3 d4 23 4e	fadd.4s	v3, v7, v3
1023097c4:	04 d6 24 4e	fadd.4s	v4, v16, v4
1023097c8:	21 dc 20 6e	fmul.4s	v1, v1, v0
1023097cc:	42 dc 20 6e	fmul.4s	v2, v2, v0
1023097d0:	63 dc 20 6e	fmul.4s	v3, v3, v0
1023097d4:	84 dc 20 6e	fmul.4s	v4, v4, v0
1023097d8:	61 09 3f ad	stp	q1, q2, [x11, #-0x20]
1023097dc:	63 11 82 ac	stp	q3, q4, [x11], #0x40
1023097e0:	ce 41 00 f1	subs	x14, x14, #0x10
1023097e4:	21 fe ff 54	b.ne	0x1023097a8
1023097e8:	e0 03 0a aa	mov	x0, x10
1023097ec:	3f 01 13 eb	cmp	x9, x19
1023097f0:	c1 f5 ff 54	b.ne	0x1023096a8
1023097f4:	bb ff ff 17	b	0x1023096e0
1023097f8:	a0 03 d4 3c	ldur	q0, [x29, #-0xc0]
1023097fc:	a0 02 80 3d	str	q0, [x21]
102309800:	a8 83 55 f8	ldur	x8, [x29, #-0xa8]
102309804:	e8 0b 01 f9	str	x8, [sp, #0x210]
102309808:	88 00 00 b4	cbz	x8, 0x102309818
10230980c:	08 21 00 91	add	x8, x8, #0x8
102309810:	29 00 80 52	mov	w9, #0x1
102309814:		.long	0xb8290108
102309818:	e8 27 5d a9	ldp	x8, x9, [sp, #0x1d0]
10230981c:	1f 01 09 eb	cmp	x8, x9
102309820:	42 02 00 54	b.hs	0x102309868
102309824:	e0 7b c0 3d	ldr	q0, [sp, #0x1e0]
102309828:	e9 fb 40 f9	ldr	x9, [sp, #0x1f0]
10230982c:	09 09 00 f9	str	x9, [x8, #0x10]
102309830:	00 01 80 3d	str	q0, [x8]
102309834:	ff ff 1e a9	stp	xzr, xzr, [sp, #0x1e8]
102309838:	ff f3 00 f9	str	xzr, [sp, #0x1e0]
10230983c:	e9 07 41 f9	ldr	x9, [sp, #0x208]
102309840:	09 15 00 f9	str	x9, [x8, #0x28]
102309844:	a0 02 c0 3d	ldr	q0, [x21]
102309848:	00 81 81 3c	stur	q0, [x8, #0x18]
10230984c:	ff 1f 08 39	strb	wzr, [sp, #0x207]
102309850:	e9 0b 41 f9	ldr	x9, [sp, #0x210]
102309854:	09 19 00 f9	str	x9, [x8, #0x30]
102309858:	ff 0b 01 f9	str	xzr, [sp, #0x210]
10230985c:	08 e1 00 91	add	x8, x8, #0x38
102309860:	e8 eb 00 f9	str	x8, [sp, #0x1d0]
102309864:	04 00 00 14	b	0x102309874
102309868:	e0 23 07 91	add	x0, sp, #0x1c8
10230986c:	e1 83 07 91	add	x1, sp, #0x1e0
102309870:	25 40 00 94	bl	__ZNSt3__16vectorINS_4pairINS_12basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEEEN10tensorflow6TensorEEENS5_ISA_EEE21__push_back_slow_pathISA_EEvOT_
102309874:	e0 03 15 aa	mov	x0, x21
102309878:	56 1e 47 94	bl	0x1034d11d0 ; symbol stub for: __ZN10tensorflow6TensorD1Ev
10230987c:	e8 df c7 39	ldrsb	w8, [sp, #0x1f7]
102309880:	68 00 f8 36	tbz	w8, #0x1f, 0x10230988c
102309884:	e0 f3 40 f9	ldr	x0, [sp, #0x1e0]
102309888:	8c 20 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10230988c:	00 04 80 52	mov	w0, #0x20
102309890:	90 20 47 94	bl	0x1034d1ad0 ; symbol stub for: __Znwm
102309894:	a0 83 11 f8	stur	x0, [x29, #-0xe8]
102309898:	48 a9 00 b0	adrp	x8, 5417 ; 0x103832000
10230989c:	00 05 c0 3d	ldr	q0, [x8, #0x10]
1023098a0:	e8 43 06 91	add	x8, sp, #0x190
1023098a4:	00 01 8d 3c	stur	q0, [x8, #0xd0]
1023098a8:	28 67 01 90	adrp	x8, 11492 ; 0x104fed000
1023098ac:	08 bd 1a 91	add	x8, x8, #0x6af ; literal pool for: "StatefulPartitionedCall:1"
1023098b0:	00 01 c0 3d	ldr	q0, [x8]
1023098b4:	00 00 80 3d	str	q0, [x0]
1023098b8:	00 91 c0 3c	ldur	q0, [x8, #0x9]
1023098bc:	00 90 80 3c	stur	q0, [x0, #0x9]
1023098c0:	1f 64 00 39	strb	wzr, [x0, #0x19]
1023098c4:	ff ff 16 a9	stp	xzr, xzr, [sp, #0x168]
1023098c8:	ff b3 00 f9	str	xzr, [sp, #0x160]
1023098cc:	00 03 80 52	mov	w0, #0x18
1023098d0:	80 20 47 94	bl	0x1034d1ad0 ; symbol stub for: __Znwm
1023098d4:	f5 03 00 aa	mov	x21, x0
1023098d8:	e0 03 16 a9	stp	x0, x0, [sp, #0x160]
1023098dc:	13 60 00 91	add	x19, x0, #0x18
1023098e0:	f3 bb 00 f9	str	x19, [sp, #0x170]
1023098e4:	e0 1b 01 f9	str	x0, [sp, #0x230]
1023098e8:	e0 87 00 f9	str	x0, [sp, #0x108]
1023098ec:	a1 a3 03 d1	sub	x1, x29, #0xe8
1023098f0:	25 1f 47 94	bl	0x1034d1584 ; symbol stub for: __ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEEC1ERKS5_
1023098f4:	f3 b7 00 f9	str	x19, [sp, #0x168]
1023098f8:	a8 f3 d2 38	ldursb	w8, [x29, #-0xd1]
1023098fc:	68 00 f8 36	tbz	w8, #0x1f, 0x102309908
102309900:	a0 83 51 f8	ldur	x0, [x29, #-0xe8]
102309904:	6d 20 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102309908:	ff ff 0f a9	stp	xzr, xzr, [sp, #0xf8]
10230990c:	ff 7b 00 f9	str	xzr, [sp, #0xf0]
102309910:	00 03 80 52	mov	w0, #0x18
102309914:	6f 20 47 94	bl	0x1034d1ad0 ; symbol stub for: __Znwm
102309918:	f6 03 00 aa	mov	x22, x0
10230991c:	e0 03 0f a9	stp	x0, x0, [sp, #0xf0]
102309920:	13 60 00 91	add	x19, x0, #0x18
102309924:	f3 83 00 f9	str	x19, [sp, #0x100]
102309928:	a0 83 11 f8	stur	x0, [x29, #-0xe8]
10230992c:	e0 1b 01 f9	str	x0, [sp, #0x230]
102309930:	e1 03 15 aa	mov	x1, x21
102309934:	14 1f 47 94	bl	0x1034d1584 ; symbol stub for: __ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEEC1ERKS5_
102309938:	f3 7f 00 f9	str	x19, [sp, #0xf8]
10230993c:	e1 23 07 91	add	x1, sp, #0x1c8
102309940:	e2 c3 03 91	add	x2, sp, #0xf0
102309944:	e3 c3 06 91	add	x3, sp, #0x1b0
102309948:	e0 4b 40 f9	ldr	x0, [sp, #0x90]
10230994c:	b1 ed 43 94	bl	__ZN9TFWrapper5Model3runERKNSt3__16vectorINS1_4pairINS1_12basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEEN10tensorflow6TensorEEENS7_ISC_EEEENS2_IS9_NS7_IS9_EEEERNS2_ISB_NS7_ISB_EEEE
102309950:	f3 7b 40 f9	ldr	x19, [sp, #0xf0]
102309954:	53 02 00 b4	cbz	x19, 0x10230999c
102309958:	e8 7f 40 f9	ldr	x8, [sp, #0xf8]
10230995c:	1f 01 13 eb	cmp	x8, x19
102309960:	c1 00 00 54	b.ne	0x102309978
102309964:	e0 03 13 aa	mov	x0, x19
102309968:	0b 00 00 14	b	0x102309994
10230996c:	e8 03 14 aa	mov	x8, x20
102309970:	9f 02 13 eb	cmp	x20, x19
102309974:	e0 00 00 54	b.eq	0x102309990
102309978:	14 61 00 d1	sub	x20, x8, #0x18
10230997c:	09 f1 df 38	ldursb	w9, [x8, #-0x1]
102309980:	69 ff ff 36	tbz	w9, #0x1f, 0x10230996c
102309984:	00 81 5e f8	ldur	x0, [x8, #-0x18]
102309988:	4c 20 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10230998c:	f8 ff ff 17	b	0x10230996c
102309990:	e0 7b 40 f9	ldr	x0, [sp, #0xf0]
102309994:	f3 7f 00 f9	str	x19, [sp, #0xf8]
102309998:	48 20 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10230999c:	e0 23 5b a9	ldp	x0, x8, [sp, #0x1b0]
1023099a0:	1f 01 00 eb	cmp	x8, x0
1023099a4:	00 1a 00 54	b.eq	0x102309ce4
1023099a8:	01 00 80 52	mov	w1, #0x0
1023099ac:	54 1e 47 94	bl	0x1034d12fc ; symbol stub for: __ZNK10tensorflow15TensorShapeBaseINS_11TensorShapeEE8dim_sizeEi
1023099b0:	f6 03 00 aa	mov	x22, x0
1023099b4:	e0 db 40 f9	ldr	x0, [sp, #0x1b0]
1023099b8:	21 00 80 52	mov	w1, #0x1
1023099bc:	50 1e 47 94	bl	0x1034d12fc ; symbol stub for: __ZNK10tensorflow15TensorShapeBaseINS_11TensorShapeEE8dim_sizeEi
1023099c0:	f7 03 00 aa	mov	x23, x0
1023099c4:	e0 db 40 f9	ldr	x0, [sp, #0x1b0]
1023099c8:	50 1e 47 94	bl	0x1034d1308 ; symbol stub for: __ZNK10tensorflow6Tensor4dataEv
1023099cc:	b6 df 23 29	stp	w22, w23, [x29, #-0xe4]
1023099d0:	e8 7e 16 1b	mul	w8, w23, w22
1023099d4:	a8 ff 24 29	stp	w8, wzr, [x29, #-0xdc]
1023099d8:	a0 03 13 f8	stur	x0, [x29, #-0xd0]
1023099dc:	bf 83 13 38	sturb	wzr, [x29, #-0xc8]
1023099e0:	93 00 80 52	mov	w19, #0x4
1023099e4:	80 00 80 52	mov	w0, #0x4
1023099e8:	3a 20 47 94	bl	0x1034d1ad0 ; symbol stub for: __Znwm
1023099ec:	f6 03 00 aa	mov	x22, x0
1023099f0:	e8 03 00 aa	mov	x8, x0
1023099f4:	13 45 00 b8	str	w19, [x8], #0x4
1023099f8:	e8 23 0e a9	stp	x8, x8, [sp, #0xe0]
1023099fc:	e0 6f 00 f9	str	x0, [sp, #0xd8]
102309a00:	08 00 d0 d2	mov	x8, #0x800000000000
102309a04:	28 0a e8 f2	movk	x8, #0x4051, lsl #48
102309a08:	00 01 67 9e	fmov	d0, x8
102309a0c:	08 00 d0 d2	mov	x8, #0x800000000000
102309a10:	c8 0c e8 f2	movk	x8, #0x4066, lsl #48
102309a14:	01 01 67 9e	fmov	d1, x8
102309a18:	a8 99 99 52	mov	w8, #0xcccd
102309a1c:	88 a9 a7 72	movk	w8, #0x3d4c, lsl #16
102309a20:	02 01 27 1e	fmov	s2, w8
102309a24:	28 0b e8 d2	mov	x8, #0x4059000000000000
102309a28:	03 01 67 9e	fmov	d3, x8
102309a2c:	e8 c3 08 91	add	x8, sp, #0x230
102309a30:	a0 a3 03 d1	sub	x0, x29, #0xe8
102309a34:	e1 63 03 91	add	x1, sp, #0xd8
102309a38:	82 07 80 52	mov	w2, #0x3c
102309a3c:	83 0c 80 52	mov	w3, #0x64
102309a40:	04 02 80 52	mov	w4, #0x10
102309a44:	25 00 80 52	mov	w5, #0x1
102309a48:	c9 dc ff 97	bl	__ZN6madmom17downbeat_trackingERKN2nc7NdArrayIfNSt3__19allocatorIfEEEERNS2_6vectorIiNS3_IiEEEEddiiifbd
102309a4c:	e8 0f 40 f9	ldr	x8, [sp, #0x18]
102309a50:	1f 05 00 71	cmp	w8, #0x1
102309a54:	2b 02 00 54	b.lt	0x102309a98
102309a58:	e8 43 06 91	add	x8, sp, #0x190
102309a5c:	08 41 4a f8	ldur	x8, [x8, #0xa4]
102309a60:	0a 05 00 71	subs	w10, w8, #0x1
102309a64:	8b 12 00 54	b.lt	0x102309cb4
102309a68:	e9 0f 40 f9	ldr	x9, [sp, #0x18]
102309a6c:	20 01 22 1e	scvtf	s0, w9
102309a70:	09 7d 40 92	and	x9, x8, #0xffffffff
102309a74:	cb f8 86 52	mov	w11, #0x37c6
102309a78:	cb f7 a6 72	movk	w11, #0x37be, lsl #16
102309a7c:	61 01 27 1e	fmov	s1, w11
102309a80:	00 08 21 1e	fmul	s0, s0, s1
102309a84:	eb 27 41 f9	ldr	x11, [sp, #0x248]
102309a88:	3f 11 00 f1	cmp	x9, #0x4
102309a8c:	e2 00 00 54	b.hs	0x102309aa8
102309a90:	0c 00 80 d2	mov	x12, #0x0
102309a94:	19 00 00 14	b	0x102309af8
102309a98:	a0 83 02 d1	sub	x0, x29, #0xa0
102309a9c:	e1 c3 08 91	add	x1, sp, #0x230
102309aa0:	d1 52 96 97	bl	__ZN2nc7NdArrayIfNSt3__19allocatorIfEEEaSERKS4_
102309aa4:	84 00 00 14	b	0x102309cb4
102309aa8:	2d 05 40 92	and	x13, x9, #0x3
102309aac:	2c 75 7e 92	and	x12, x9, #0xfffffffc
102309ab0:	6e 41 00 91	add	x14, x11, #0x10
102309ab4:	ef 03 0c aa	mov	x15, x12
102309ab8:	c1 01 5f bc	ldur	s1, [x14, #-0x10]
102309abc:	c2 81 5f bc	ldur	s2, [x14, #-0x8]
102309ac0:	c3 01 40 bd	ldr	s3, [x14]
102309ac4:	c4 09 40 bd	ldr	s4, [x14, #0x8]
102309ac8:	21 28 20 1e	fadd	s1, s1, s0
102309acc:	42 28 20 1e	fadd	s2, s2, s0
102309ad0:	63 28 20 1e	fadd	s3, s3, s0
102309ad4:	84 28 20 1e	fadd	s4, s4, s0
102309ad8:	c1 01 1f bc	stur	s1, [x14, #-0x10]
102309adc:	c2 81 1f bc	stur	s2, [x14, #-0x8]
102309ae0:	c3 01 00 bd	str	s3, [x14]
102309ae4:	c4 09 00 bd	str	s4, [x14, #0x8]
102309ae8:	ce 81 00 91	add	x14, x14, #0x20
102309aec:	ef 11 00 f1	subs	x15, x15, #0x4
102309af0:	41 fe ff 54	b.ne	0x102309ab8
102309af4:	0d 01 00 b4	cbz	x13, 0x102309b14
102309af8:	2d 01 0c cb	sub	x13, x9, x12
102309afc:	6c 0d 0c 8b	add	x12, x11, x12, lsl #3
102309b00:	81 01 40 bd	ldr	s1, [x12]
102309b04:	21 28 20 1e	fadd	s1, s1, s0
102309b08:	81 85 00 bc	str	s1, [x12], #0x8
102309b0c:	ad 05 00 f1	subs	x13, x13, #0x1
102309b10:	81 ff ff 54	b.ne	0x102309b00
102309b14:	ac c3 56 b8	ldur	w12, [x29, #-0x94]
102309b18:	9f 05 00 71	cmp	w12, #0x1
102309b1c:	69 03 00 54	b.ls	0x102309b88
102309b20:	1f 09 00 71	cmp	w8, #0x2
102309b24:	eb 04 00 54	b.lt	0x102309bc0
102309b28:	8d 09 00 51	sub	w13, w12, #0x2
102309b2c:	8c 7d 8d 0a	and	w12, w12, w13, asr #31
102309b30:	8c 01 0d 0b	add	w12, w12, w13
102309b34:	ad 83 57 f8	ldur	x13, [x29, #-0x88]
102309b38:	a0 d9 6c bc	ldr	s0, [x13, w12, sxtw #2]
102309b3c:	61 01 40 bd	ldr	s1, [x11]
102309b40:	02 d4 a1 7e	fabd	s2, s0, s1
102309b44:	61 09 40 bd	ldr	s1, [x11, #0x8]
102309b48:	01 d4 a1 7e	fabd	s1, s0, s1
102309b4c:	40 20 21 1e	fcmp	s2, s1
102309b50:	8d 03 00 54	b.le	0x102309bc0
102309b54:	0c 00 80 d2	mov	x12, #0x0
102309b58:	6b 41 00 91	add	x11, x11, #0x10
102309b5c:	2d 09 00 d1	sub	x13, x9, #0x2
102309b60:	bf 01 0c eb	cmp	x13, x12
102309b64:	00 03 00 54	b.eq	0x102309bc4
102309b68:	62 85 40 bc	ldr	s2, [x11], #0x8
102309b6c:	02 d4 a2 7e	fabd	s2, s0, s2
102309b70:	8c 05 00 91	add	x12, x12, #0x1
102309b74:	20 20 22 1e	fcmp	s1, s2
102309b78:	41 40 20 1e	fmov	s1, s2
102309b7c:	2c ff ff 54	b.gt	0x102309b60
102309b80:	ea 03 0c aa	mov	x10, x12
102309b84:	10 00 00 14	b	0x102309bc4
102309b88:	f3 83 07 91	add	x19, sp, #0x1e0
102309b8c:	e0 83 07 91	add	x0, sp, #0x1e0
102309b90:	a1 83 02 d1	sub	x1, x29, #0xa0
102309b94:	b7 83 96 97	bl	__ZN2nc7NdArrayIfNSt3__19allocatorIfEEEC2ERKS4_
102309b98:	60 a2 00 91	add	x0, x19, #0x28
102309b9c:	e1 c3 08 91	add	x1, sp, #0x230
102309ba0:	b4 83 96 97	bl	__ZN2nc7NdArrayIfNSt3__19allocatorIfEEEC2ERKS4_
102309ba4:	e8 83 07 91	add	x8, sp, #0x1e0
102309ba8:	49 00 80 52	mov	w9, #0x2
102309bac:	e8 27 18 a9	stp	x8, x9, [sp, #0x180]
102309bb0:	e8 23 04 91	add	x8, sp, #0x108
102309bb4:	e0 03 06 91	add	x0, sp, #0x180
102309bb8:	44 40 00 94	bl	__ZN2nc9row_stackIfEENS_7NdArrayIT_NSt3__19allocatorIS2_EEEERKSt16initializer_listIS6_E
102309bbc:	21 00 00 14	b	0x102309c40
102309bc0:	0a 00 80 52	mov	w10, #0x0
102309bc4:	41 05 00 11	add	w1, w10, #0x1
102309bc8:	3f 00 08 6b	cmp	w1, w8
102309bcc:	4a 07 00 54	b.ge	0x102309cb4
102309bd0:	21 7d 60 b3	bfi	x1, x9, #32, #32
102309bd4:	e8 83 07 91	add	x8, sp, #0x1e0
102309bd8:	e0 c3 08 91	add	x0, sp, #0x230
102309bdc:	22 00 80 52	mov	w2, #0x1
102309be0:	43 00 c0 d2	mov	x3, #0x200000000
102309be4:	24 00 80 52	mov	w4, #0x1
102309be8:	8e 85 96 97	bl	__ZNK2nc7NdArrayIfNSt3__19allocatorIfEEEclENS_5SliceES5_
102309bec:	e0 c3 08 91	add	x0, sp, #0x230
102309bf0:	e1 83 07 91	add	x1, sp, #0x1e0
102309bf4:	ef 3e 00 94	bl	__ZN2nc7NdArrayIfNSt3__19allocatorIfEEEaSEOS4_
102309bf8:	e8 03 48 39	ldrb	w8, [sp, #0x200]
102309bfc:	88 00 00 34	cbz	w8, 0x102309c0c
102309c00:	e0 ff 40 f9	ldr	x0, [sp, #0x1f8]
102309c04:	40 00 00 b4	cbz	x0, 0x102309c0c
102309c08:	ac 1f 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102309c0c:	f3 83 07 91	add	x19, sp, #0x1e0
102309c10:	e0 83 07 91	add	x0, sp, #0x1e0
102309c14:	a1 83 02 d1	sub	x1, x29, #0xa0
102309c18:	96 83 96 97	bl	__ZN2nc7NdArrayIfNSt3__19allocatorIfEEEC2ERKS4_
102309c1c:	60 a2 00 91	add	x0, x19, #0x28
102309c20:	e1 c3 08 91	add	x1, sp, #0x230
102309c24:	93 83 96 97	bl	__ZN2nc7NdArrayIfNSt3__19allocatorIfEEEC2ERKS4_
102309c28:	e8 83 07 91	add	x8, sp, #0x1e0
102309c2c:	49 00 80 52	mov	w9, #0x2
102309c30:	e8 27 18 a9	stp	x8, x9, [sp, #0x180]
102309c34:	e8 23 04 91	add	x8, sp, #0x108
102309c38:	e0 03 06 91	add	x0, sp, #0x180
102309c3c:	23 40 00 94	bl	__ZN2nc9row_stackIfEENS_7NdArrayIT_NSt3__19allocatorIS2_EEEERKSt16initializer_listIS6_E
102309c40:	a0 83 02 d1	sub	x0, x29, #0xa0
102309c44:	e1 23 04 91	add	x1, sp, #0x108
102309c48:	da 3e 00 94	bl	__ZN2nc7NdArrayIfNSt3__19allocatorIfEEEaSEOS4_
102309c4c:	e8 a3 44 39	ldrb	w8, [sp, #0x128]
102309c50:	88 00 00 34	cbz	w8, 0x102309c60
102309c54:	e0 93 40 f9	ldr	x0, [sp, #0x120]
102309c58:	40 00 00 b4	cbz	x0, 0x102309c60
102309c5c:	97 1f 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102309c60:	ff 93 00 f9	str	xzr, [sp, #0x120]
102309c64:	ff a3 04 39	strb	wzr, [sp, #0x128]
102309c68:	e8 57 00 91	add	x8, sp, #0x15
102309c6c:	1f f1 0f f8	stur	xzr, [x8, #0xff]
102309c70:	e8 37 00 91	add	x8, sp, #0xd
102309c74:	1f f1 0f f8	stur	xzr, [x8, #0xff]
102309c78:	e8 a3 48 39	ldrb	w8, [sp, #0x228]
102309c7c:	88 00 00 34	cbz	w8, 0x102309c8c
102309c80:	e0 13 41 f9	ldr	x0, [sp, #0x220]
102309c84:	40 00 00 b4	cbz	x0, 0x102309c8c
102309c88:	8c 1f 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102309c8c:	ff 13 01 f9	str	xzr, [sp, #0x220]
102309c90:	ff a3 08 39	strb	wzr, [sp, #0x228]
102309c94:	e8 43 06 91	add	x8, sp, #0x190
102309c98:	1f 41 08 f8	stur	xzr, [x8, #0x84]
102309c9c:	1f c1 07 f8	stur	xzr, [x8, #0x7c]
102309ca0:	e8 03 48 39	ldrb	w8, [sp, #0x200]
102309ca4:	88 00 00 34	cbz	w8, 0x102309cb4
102309ca8:	e0 ff 40 f9	ldr	x0, [sp, #0x1f8]
102309cac:	40 00 00 b4	cbz	x0, 0x102309cb4
102309cb0:	82 1f 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102309cb4:	e8 43 49 39	ldrb	w8, [sp, #0x250]
102309cb8:	88 00 00 34	cbz	w8, 0x102309cc8
102309cbc:	e0 27 41 f9	ldr	x0, [sp, #0x248]
102309cc0:	40 00 00 b4	cbz	x0, 0x102309cc8
102309cc4:	7d 1f 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102309cc8:	e0 03 16 aa	mov	x0, x22
102309ccc:	7b 1f 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102309cd0:	a8 83 53 38	ldurb	w8, [x29, #-0xc8]
102309cd4:	88 00 00 34	cbz	w8, 0x102309ce4
102309cd8:	a0 03 53 f8	ldur	x0, [x29, #-0xd0]
102309cdc:	40 00 00 b4	cbz	x0, 0x102309ce4
102309ce0:	76 1f 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102309ce4:	a8 5e c0 39	ldrsb	w8, [x21, #0x17]
102309ce8:	68 00 f8 36	tbz	w8, #0x1f, 0x102309cf4
102309cec:	a0 02 40 f9	ldr	x0, [x21]
102309cf0:	72 1f 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102309cf4:	f5 b7 00 f9	str	x21, [sp, #0x168]
102309cf8:	e0 03 15 aa	mov	x0, x21
102309cfc:	6f 1f 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102309d00:	a0 03 03 d1	sub	x0, x29, #0xc0
102309d04:	33 1d 47 94	bl	0x1034d11d0 ; symbol stub for: __ZN10tensorflow6TensorD1Ev
102309d08:	08 43 40 f8	ldur	x8, [x24, #0x4]
102309d0c:	e8 43 0b f8	stur	x8, [sp, #0xb4]
102309d10:	00 c3 40 fc	ldur	d0, [x24, #0xc]
102309d14:	e0 c3 0b fc	stur	d0, [sp, #0xbc]
102309d18:	b5 83 57 f8	ldur	x21, [x29, #-0x88]
102309d1c:	f5 67 00 f9	str	x21, [sp, #0xc8]
102309d20:	b3 03 58 38	ldurb	w19, [x29, #-0x80]
102309d24:	f3 43 03 39	strb	w19, [sp, #0xd0]
102309d28:	bf 43 16 f8	stur	xzr, [x29, #-0x9c]
102309d2c:	bf c3 16 b8	stur	wzr, [x29, #-0x94]
102309d30:	bf 03 18 38	sturb	wzr, [x29, #-0x80]
102309d34:	bf 83 17 f8	stur	xzr, [x29, #-0x88]
102309d38:	e8 9f c6 39	ldrsb	w8, [sp, #0x1a7]
102309d3c:	68 00 f8 36	tbz	w8, #0x1f, 0x102309d48
102309d40:	e0 cb 40 f9	ldr	x0, [sp, #0x190]
102309d44:	5d 1f 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102309d48:	e0 4b 40 f9	ldr	x0, [sp, #0x90]
102309d4c:	08 00 40 f9	ldr	x8, [x0]
102309d50:	08 05 40 f9	ldr	x8, [x8, #0x8]
102309d54:	00 01 3f d6	blr	x8
102309d58:	f4 db 40 f9	ldr	x20, [sp, #0x1b0]
102309d5c:	b4 01 00 b4	cbz	x20, 0x102309d90
102309d60:	e0 df 40 f9	ldr	x0, [sp, #0x1b8]
102309d64:	1f 00 14 eb	cmp	x0, x20
102309d68:	e0 00 00 54	b.eq	0x102309d84
102309d6c:	00 80 00 d1	sub	x0, x0, #0x20
102309d70:	18 1d 47 94	bl	0x1034d11d0 ; symbol stub for: __ZN10tensorflow6TensorD1Ev
102309d74:	1f 00 14 eb	cmp	x0, x20
102309d78:	a1 ff ff 54	b.ne	0x102309d6c
102309d7c:	e0 db 40 f9	ldr	x0, [sp, #0x1b0]
102309d80:	02 00 00 14	b	0x102309d88
102309d84:	e0 03 14 aa	mov	x0, x20
102309d88:	f4 df 00 f9	str	x20, [sp, #0x1b8]
102309d8c:	4b 1f 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102309d90:	f4 e7 40 f9	ldr	x20, [sp, #0x1c8]
102309d94:	94 02 00 b4	cbz	x20, 0x102309de4
102309d98:	f6 eb 40 f9	ldr	x22, [sp, #0x1d0]
102309d9c:	df 02 14 eb	cmp	x22, x20
102309da0:	c1 00 00 54	b.ne	0x102309db8
102309da4:	e0 03 14 aa	mov	x0, x20
102309da8:	0d 00 00 14	b	0x102309ddc
102309dac:	f6 03 17 aa	mov	x22, x23
102309db0:	ff 02 14 eb	cmp	x23, x20
102309db4:	20 01 00 54	b.eq	0x102309dd8
102309db8:	d7 e2 00 d1	sub	x23, x22, #0x38
102309dbc:	c0 82 00 d1	sub	x0, x22, #0x20
102309dc0:	04 1d 47 94	bl	0x1034d11d0 ; symbol stub for: __ZN10tensorflow6TensorD1Ev
102309dc4:	c8 f2 dd 38	ldursb	w8, [x22, #-0x21]
102309dc8:	28 ff ff 36	tbz	w8, #0x1f, 0x102309dac
102309dcc:	c0 82 5c f8	ldur	x0, [x22, #-0x38]
102309dd0:	3a 1f 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102309dd4:	f6 ff ff 17	b	0x102309dac
102309dd8:	e0 e7 40 f9	ldr	x0, [sp, #0x1c8]
102309ddc:	f4 eb 00 f9	str	x20, [sp, #0x1d0]
102309de0:	36 1f 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102309de4:	e0 e3 05 91	add	x0, sp, #0x178
102309de8:	45 82 06 94	bl	__ZN4juce6StringD1Ev
102309dec:	a8 03 58 38	ldurb	w8, [x29, #-0x80]
102309df0:	88 00 00 34	cbz	w8, 0x102309e00
102309df4:	a0 83 57 f8	ldur	x0, [x29, #-0x88]
102309df8:	40 00 00 b4	cbz	x0, 0x102309e00
102309dfc:	2f 1f 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102309e00:	e1 c3 02 91	add	x1, sp, #0xb0
102309e04:	e0 03 19 aa	mov	x0, x25
102309e08:	f3 01 00 94	bl	__ZN6madmomL9to_vectorERKN2nc7NdArrayIfNSt3__19allocatorIfEEEE
102309e0c:	93 00 00 34	cbz	w19, 0x102309e1c
102309e10:	75 00 00 b4	cbz	x21, 0x102309e1c
102309e14:	e0 03 15 aa	mov	x0, x21
102309e18:	28 1f 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102309e1c:	e0 a3 02 91	add	x0, sp, #0xa8
102309e20:	37 82 06 94	bl	__ZN4juce6StringD1Ev
102309e24:	a8 83 58 f8	ldur	x8, [x29, #-0x78]
102309e28:	29 72 01 b0	adrp	x9, 11845 ; 0x10514e000
102309e2c:	29 7d 42 f9	ldr	x9, [x9, #0x4f8] ; literal pool symbol address: ___stack_chk_guard
102309e30:	29 01 40 f9	ldr	x9, [x9]
102309e34:	3f 01 08 eb	cmp	x9, x8
102309e38:	41 01 00 54	b.ne	0x102309e60
102309e3c:	ff 83 0b 91	add	sp, sp, #0x2e0
102309e40:	fd 7b 46 a9	ldp	x29, x30, [sp, #0x60]
102309e44:	f4 4f 45 a9	ldp	x20, x19, [sp, #0x50]
102309e48:	f6 57 44 a9	ldp	x22, x21, [sp, #0x40]
102309e4c:	f8 5f 43 a9	ldp	x24, x23, [sp, #0x30]
102309e50:	fa 67 42 a9	ldp	x26, x25, [sp, #0x20]
102309e54:	fc 6f 41 a9	ldp	x28, x27, [sp, #0x10]
102309e58:	e9 23 c7 6c	ldp	d9, d8, [sp], #0x70
102309e5c:	c0 03 5f d6	ret
102309e60:	7c 1f 47 94	bl	0x1034d1c50 ; symbol stub for: ___stack_chk_fail
102309e64:	f8 03 00 aa	mov	x24, x0
102309e68:	e8 a3 48 39	ldrb	w8, [sp, #0x228]
102309e6c:	48 02 00 34	cbz	w8, 0x102309eb4
102309e70:	0e 00 00 14	b	0x102309ea8
102309e74:	16 00 00 14	b	0x102309ecc
102309e78:	31 00 00 14	b	0x102309f3c
102309e7c:	30 00 00 14	b	0x102309f3c
102309e80:	f8 03 00 aa	mov	x24, x0
102309e84:	e8 a3 48 39	ldrb	w8, [sp, #0x228]
102309e88:	e8 03 00 34	cbz	w8, 0x102309f04
102309e8c:	1b 00 00 14	b	0x102309ef8
102309e90:	23 00 00 14	b	0x102309f1c
102309e94:	31 00 00 14	b	0x102309f58
102309e98:	30 00 00 14	b	0x102309f58
102309e9c:	f8 03 00 aa	mov	x24, x0
102309ea0:	e8 a3 48 39	ldrb	w8, [sp, #0x228]
102309ea4:	88 00 00 34	cbz	w8, 0x102309eb4
102309ea8:	e0 13 41 f9	ldr	x0, [sp, #0x220]
102309eac:	40 00 00 b4	cbz	x0, 0x102309eb4
102309eb0:	02 1f 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102309eb4:	ff 13 01 f9	str	xzr, [sp, #0x220]
102309eb8:	ff a3 08 39	strb	wzr, [sp, #0x228]
102309ebc:	e8 43 06 91	add	x8, sp, #0x190
102309ec0:	1f 41 08 f8	stur	xzr, [x8, #0x84]
102309ec4:	1f c1 07 f8	stur	xzr, [x8, #0x7c]
102309ec8:	02 00 00 14	b	0x102309ed0
102309ecc:	f8 03 00 aa	mov	x24, x0
102309ed0:	e8 03 48 39	ldrb	w8, [sp, #0x200]
102309ed4:	68 03 00 34	cbz	w8, 0x102309f40
102309ed8:	e0 ff 40 f9	ldr	x0, [sp, #0x1f8]
102309edc:	20 03 00 b4	cbz	x0, 0x102309f40
102309ee0:	f6 1e 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102309ee4:	17 00 00 14	b	0x102309f40
102309ee8:	15 00 00 14	b	0x102309f3c
102309eec:	f8 03 00 aa	mov	x24, x0
102309ef0:	e8 a3 48 39	ldrb	w8, [sp, #0x228]
102309ef4:	88 00 00 34	cbz	w8, 0x102309f04
102309ef8:	e0 13 41 f9	ldr	x0, [sp, #0x220]
102309efc:	40 00 00 b4	cbz	x0, 0x102309f04
102309f00:	ee 1e 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102309f04:	ff 13 01 f9	str	xzr, [sp, #0x220]
102309f08:	ff a3 08 39	strb	wzr, [sp, #0x228]
102309f0c:	e8 43 06 91	add	x8, sp, #0x190
102309f10:	1f 41 08 f8	stur	xzr, [x8, #0x84]
102309f14:	1f c1 07 f8	stur	xzr, [x8, #0x7c]
102309f18:	02 00 00 14	b	0x102309f20
102309f1c:	f8 03 00 aa	mov	x24, x0
102309f20:	e8 03 48 39	ldrb	w8, [sp, #0x200]
102309f24:	c8 01 00 34	cbz	w8, 0x102309f5c
102309f28:	e0 ff 40 f9	ldr	x0, [sp, #0x1f8]
102309f2c:	80 01 00 b4	cbz	x0, 0x102309f5c
102309f30:	e2 1e 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102309f34:	0a 00 00 14	b	0x102309f5c
102309f38:	08 00 00 14	b	0x102309f58
102309f3c:	f8 03 00 aa	mov	x24, x0
102309f40:	e8 43 49 39	ldrb	w8, [sp, #0x250]
102309f44:	68 02 00 34	cbz	w8, 0x102309f90
102309f48:	e0 27 41 f9	ldr	x0, [sp, #0x248]
102309f4c:	20 02 00 b4	cbz	x0, 0x102309f90
102309f50:	da 1e 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102309f54:	0f 00 00 14	b	0x102309f90
102309f58:	f8 03 00 aa	mov	x24, x0
102309f5c:	e8 43 49 39	ldrb	w8, [sp, #0x250]
102309f60:	c8 02 00 34	cbz	w8, 0x102309fb8
102309f64:	e0 27 41 f9	ldr	x0, [sp, #0x248]
102309f68:	80 02 00 b4	cbz	x0, 0x102309fb8
102309f6c:	d3 1e 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102309f70:	12 00 00 14	b	0x102309fb8
102309f74:	0b 01 00 14	b	0x10230a3a0
102309f78:	0e 01 00 14	b	0x10230a3b0
102309f7c:	99 06 74 97	bl	___clang_call_terminate
102309f80:	08 01 00 14	b	0x10230a3a0
102309f84:	0b 01 00 14	b	0x10230a3b0
102309f88:	96 06 74 97	bl	___clang_call_terminate
102309f8c:	f8 03 00 aa	mov	x24, x0
102309f90:	e0 03 16 aa	mov	x0, x22
102309f94:	c9 1e 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102309f98:	a8 83 53 38	ldurb	w8, [x29, #-0xc8]
102309f9c:	a8 25 00 35	cbnz	w8, 0x10230a450
102309fa0:	69 01 00 14	b	0x10230a544
102309fa4:	52 01 00 14	b	0x10230a4ec
102309fa8:	51 01 00 14	b	0x10230a4ec
102309fac:	50 01 00 14	b	0x10230a4ec
102309fb0:	4f 01 00 14	b	0x10230a4ec
102309fb4:	f8 03 00 aa	mov	x24, x0
102309fb8:	e0 03 17 aa	mov	x0, x23
102309fbc:	bf 1e 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102309fc0:	a8 83 53 38	ldurb	w8, [x29, #-0xc8]
102309fc4:	68 24 00 35	cbnz	w8, 0x10230a450
102309fc8:	5f 01 00 14	b	0x10230a544
102309fcc:	48 01 00 14	b	0x10230a4ec
102309fd0:	47 01 00 14	b	0x10230a4ec
102309fd4:	46 01 00 14	b	0x10230a4ec
102309fd8:	45 01 00 14	b	0x10230a4ec
102309fdc:	f8 03 00 aa	mov	x24, x0
102309fe0:	e0 83 07 91	add	x0, sp, #0x1e0
102309fe4:	e1 3d 00 94	bl	__ZNSt3__14pairINS_12basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEEEN10tensorflow6TensorEED1Ev
102309fe8:	8b 00 00 14	b	0x10230a214
102309fec:	f8 03 00 aa	mov	x24, x0
102309ff0:	e8 df c7 39	ldrsb	w8, [sp, #0x1f7]
102309ff4:	08 11 f8 36	tbz	w8, #0x1f, 0x10230a214
102309ff8:	e0 f3 40 f9	ldr	x0, [sp, #0x1e0]
102309ffc:	af 1e 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10230a000:	85 00 00 14	b	0x10230a214
10230a004:	77 06 74 97	bl	___clang_call_terminate
10230a008:	f8 03 00 aa	mov	x24, x0
10230a00c:	e0 c3 03 91	add	x0, sp, #0xf0
10230a010:	4c 01 00 14	b	0x10230a540
10230a014:	e8 c3 03 91	add	x8, sp, #0xf0
10230a018:	13 41 00 91	add	x19, x8, #0x10
10230a01c:	c2 1e 47 94	bl	0x1034d1b24 ; symbol stub for: ___cxa_begin_catch
10230a020:	e8 c3 08 91	add	x8, sp, #0x230
10230a024:	f3 23 1e a9	stp	x19, x8, [sp, #0x1e0]
10230a028:	a8 a3 03 d1	sub	x8, x29, #0xe8
10230a02c:	e8 fb 00 f9	str	x8, [sp, #0x1f0]
10230a030:	e0 83 07 91	add	x0, sp, #0x1e0
10230a034:	3c 79 bf 97	bl	__ZNKSt3__129_AllocatorDestroyRangeReverseINS_9allocatorINS_12basic_stringIcNS_11char_traitsIcEENS1_IcEEEEEEPS6_EclB6v15006Ev
10230a038:	d3 1e 47 94	bl	0x1034d1b84 ; symbol stub for: ___cxa_rethrow
10230a03c:	38 01 00 14	b	0x10230a51c
10230a040:	01 00 00 14	b	0x10230a044
10230a044:	f8 03 00 aa	mov	x24, x0
10230a048:	bd 1e 47 94	bl	0x1034d1b3c ; symbol stub for: ___cxa_end_catch
10230a04c:	f6 7f 00 f9	str	x22, [sp, #0xf8]
10230a050:	3d 01 00 14	b	0x10230a544
10230a054:	63 06 74 97	bl	___clang_call_terminate
10230a058:	25 01 00 14	b	0x10230a4ec
10230a05c:	e8 83 05 91	add	x8, sp, #0x160
10230a060:	13 41 00 91	add	x19, x8, #0x10
10230a064:	b0 1e 47 94	bl	0x1034d1b24 ; symbol stub for: ___cxa_begin_catch
10230a068:	e8 23 04 91	add	x8, sp, #0x108
10230a06c:	f3 23 1e a9	stp	x19, x8, [sp, #0x1e0]
10230a070:	e8 c3 08 91	add	x8, sp, #0x230
10230a074:	e8 fb 00 f9	str	x8, [sp, #0x1f0]
10230a078:	e0 83 07 91	add	x0, sp, #0x1e0
10230a07c:	2a 79 bf 97	bl	__ZNKSt3__129_AllocatorDestroyRangeReverseINS_9allocatorINS_12basic_stringIcNS_11char_traitsIcEENS1_IcEEEEEEPS6_EclB6v15006Ev
10230a080:	c1 1e 47 94	bl	0x1034d1b84 ; symbol stub for: ___cxa_rethrow
10230a084:	26 01 00 14	b	0x10230a51c
10230a088:	01 00 00 14	b	0x10230a08c
10230a08c:	f8 03 00 aa	mov	x24, x0
10230a090:	ab 1e 47 94	bl	0x1034d1b3c ; symbol stub for: ___cxa_end_catch
10230a094:	f5 b7 00 f9	str	x21, [sp, #0x168]
10230a098:	11 01 00 14	b	0x10230a4dc
10230a09c:	51 06 74 97	bl	___clang_call_terminate
10230a0a0:	fc 00 00 14	b	0x10230a490
10230a0a4:	f8 03 00 aa	mov	x24, x0
10230a0a8:	29 01 00 14	b	0x10230a54c
10230a0ac:	f8 03 00 aa	mov	x24, x0
10230a0b0:	27 01 00 14	b	0x10230a54c
10230a0b4:	f8 03 00 aa	mov	x24, x0
10230a0b8:	25 01 00 14	b	0x10230a54c
10230a0bc:	eb 00 00 14	b	0x10230a468
10230a0c0:	f8 03 00 aa	mov	x24, x0
10230a0c4:	e0 c3 04 91	add	x0, sp, #0x130
10230a0c8:	1e 01 00 14	b	0x10230a540
10230a0cc:	e5 00 00 14	b	0x10230a460
10230a0d0:	e8 c3 04 91	add	x8, sp, #0x130
10230a0d4:	13 41 00 91	add	x19, x8, #0x10
10230a0d8:	93 1e 47 94	bl	0x1034d1b24 ; symbol stub for: ___cxa_begin_catch
10230a0dc:	e8 c3 08 91	add	x8, sp, #0x230
10230a0e0:	f3 23 1e a9	stp	x19, x8, [sp, #0x1e0]
10230a0e4:	a8 a3 03 d1	sub	x8, x29, #0xe8
10230a0e8:	e8 fb 00 f9	str	x8, [sp, #0x1f0]
10230a0ec:	e0 83 07 91	add	x0, sp, #0x1e0
10230a0f0:	0d 79 bf 97	bl	__ZNKSt3__129_AllocatorDestroyRangeReverseINS_9allocatorINS_12basic_stringIcNS_11char_traitsIcEENS1_IcEEEEEEPS6_EclB6v15006Ev
10230a0f4:	a4 1e 47 94	bl	0x1034d1b84 ; symbol stub for: ___cxa_rethrow
10230a0f8:	09 01 00 14	b	0x10230a51c
10230a0fc:	01 00 00 14	b	0x10230a100
10230a100:	f8 03 00 aa	mov	x24, x0
10230a104:	8e 1e 47 94	bl	0x1034d1b3c ; symbol stub for: ___cxa_end_catch
10230a108:	f7 9f 00 f9	str	x23, [sp, #0x138]
10230a10c:	0e 01 00 14	b	0x10230a544
10230a110:	34 06 74 97	bl	___clang_call_terminate
10230a114:	f6 00 00 14	b	0x10230a4ec
10230a118:	e8 83 05 91	add	x8, sp, #0x160
10230a11c:	13 41 00 91	add	x19, x8, #0x10
10230a120:	81 1e 47 94	bl	0x1034d1b24 ; symbol stub for: ___cxa_begin_catch
10230a124:	e8 23 04 91	add	x8, sp, #0x108
10230a128:	f3 23 1e a9	stp	x19, x8, [sp, #0x1e0]
10230a12c:	e8 c3 08 91	add	x8, sp, #0x230
10230a130:	e8 fb 00 f9	str	x8, [sp, #0x1f0]
10230a134:	e0 83 07 91	add	x0, sp, #0x1e0
10230a138:	fb 78 bf 97	bl	__ZNKSt3__129_AllocatorDestroyRangeReverseINS_9allocatorINS_12basic_stringIcNS_11char_traitsIcEENS1_IcEEEEEEPS6_EclB6v15006Ev
10230a13c:	92 1e 47 94	bl	0x1034d1b84 ; symbol stub for: ___cxa_rethrow
10230a140:	f7 00 00 14	b	0x10230a51c
10230a144:	01 00 00 14	b	0x10230a148
10230a148:	f8 03 00 aa	mov	x24, x0
10230a14c:	7c 1e 47 94	bl	0x1034d1b3c ; symbol stub for: ___cxa_end_catch
10230a150:	f6 b7 00 f9	str	x22, [sp, #0x168]
10230a154:	e2 00 00 14	b	0x10230a4dc
10230a158:	22 06 74 97	bl	___clang_call_terminate
10230a15c:	cd 00 00 14	b	0x10230a490
10230a160:	f8 03 00 aa	mov	x24, x0
10230a164:	fa 00 00 14	b	0x10230a54c
10230a168:	f8 03 00 aa	mov	x24, x0
10230a16c:	f8 00 00 14	b	0x10230a54c
10230a170:	f8 03 00 aa	mov	x24, x0
10230a174:	f6 00 00 14	b	0x10230a54c
10230a178:	bc 00 00 14	b	0x10230a468
10230a17c:	b9 00 00 14	b	0x10230a460
10230a180:	f8 03 00 aa	mov	x24, x0
10230a184:	e0 03 17 aa	mov	x0, x23
10230a188:	4c 1e 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10230a18c:	e8 03 48 39	ldrb	w8, [sp, #0x200]
10230a190:	e8 03 00 34	cbz	w8, 0x10230a20c
10230a194:	e0 ff 40 f9	ldr	x0, [sp, #0x1f8]
10230a198:	a0 03 00 b4	cbz	x0, 0x10230a20c
10230a19c:	47 1e 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10230a1a0:	1b 00 00 14	b	0x10230a20c
10230a1a4:	19 00 00 14	b	0x10230a208
10230a1a8:	18 00 00 14	b	0x10230a208
10230a1ac:	17 00 00 14	b	0x10230a208
10230a1b0:	16 00 00 14	b	0x10230a208
10230a1b4:	f8 03 00 aa	mov	x24, x0
10230a1b8:	e0 c3 06 91	add	x0, sp, #0x1b0
10230a1bc:	d1 7e 8c 97	bl	__ZNSt3__16vectorINS_12basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEEENS4_IS6_EEED1B6v15006Ev
10230a1c0:	13 00 00 14	b	0x10230a20c
10230a1c4:	e8 c3 06 91	add	x8, sp, #0x1b0
10230a1c8:	13 41 00 91	add	x19, x8, #0x10
10230a1cc:	56 1e 47 94	bl	0x1034d1b24 ; symbol stub for: ___cxa_begin_catch
10230a1d0:	e8 43 06 91	add	x8, sp, #0x190
10230a1d4:	f3 23 1e a9	stp	x19, x8, [sp, #0x1e0]
10230a1d8:	a8 83 02 d1	sub	x8, x29, #0xa0
10230a1dc:	e8 fb 00 f9	str	x8, [sp, #0x1f0]
10230a1e0:	e0 83 07 91	add	x0, sp, #0x1e0
10230a1e4:	d0 78 bf 97	bl	__ZNKSt3__129_AllocatorDestroyRangeReverseINS_9allocatorINS_12basic_stringIcNS_11char_traitsIcEENS1_IcEEEEEEPS6_EclB6v15006Ev
10230a1e8:	67 1e 47 94	bl	0x1034d1b84 ; symbol stub for: ___cxa_rethrow
10230a1ec:	cc 00 00 14	b	0x10230a51c
10230a1f0:	01 00 00 14	b	0x10230a1f4
10230a1f4:	f8 03 00 aa	mov	x24, x0
10230a1f8:	51 1e 47 94	bl	0x1034d1b3c ; symbol stub for: ___cxa_end_catch
10230a1fc:	f6 df 00 f9	str	x22, [sp, #0x1b8]
10230a200:	03 00 00 14	b	0x10230a20c
10230a204:	f7 05 74 97	bl	___clang_call_terminate
10230a208:	f8 03 00 aa	mov	x24, x0
10230a20c:	e0 23 07 91	add	x0, sp, #0x1c8
10230a210:	bc 7e 8c 97	bl	__ZNSt3__16vectorINS_12basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEEENS4_IS6_EEED1B6v15006Ev
10230a214:	e0 c3 08 91	add	x0, sp, #0x230
10230a218:	ee 1b 47 94	bl	0x1034d11d0 ; symbol stub for: __ZN10tensorflow6TensorD1Ev
10230a21c:	a8 73 d5 38	ldursb	w8, [x29, #-0xa9]
10230a220:	68 00 f8 36	tbz	w8, #0x1f, 0x10230a22c
10230a224:	a0 03 54 f8	ldur	x0, [x29, #-0xc0]
10230a228:	24 1e 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10230a22c:	88 02 40 f9	ldr	x8, [x20]
10230a230:	08 05 40 f9	ldr	x8, [x8, #0x8]
10230a234:	e0 03 14 aa	mov	x0, x20
10230a238:	00 01 3f d6	blr	x8
10230a23c:	e0 c3 02 91	add	x0, sp, #0xb0
10230a240:	7c 3d 00 94	bl	__ZNSt3__16vectorIN10tensorflow6TensorENS_9allocatorIS2_EEED1B6v15006Ev
10230a244:	e0 23 04 91	add	x0, sp, #0x108
10230a248:	90 3d 00 94	bl	__ZNSt3__16vectorINS_4pairINS_12basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEEEN10tensorflow6TensorEEENS5_ISA_EEED1B6v15006Ev
10230a24c:	da 00 00 14	b	0x10230a5b4
10230a250:	e8 23 07 91	add	x8, sp, #0x1c8
10230a254:	13 41 00 91	add	x19, x8, #0x10
10230a258:	33 1e 47 94	bl	0x1034d1b24 ; symbol stub for: ___cxa_begin_catch
10230a25c:	e8 43 06 91	add	x8, sp, #0x190
10230a260:	f3 23 1e a9	stp	x19, x8, [sp, #0x1e0]
10230a264:	e8 c3 06 91	add	x8, sp, #0x1b0
10230a268:	e8 fb 00 f9	str	x8, [sp, #0x1f0]
10230a26c:	e0 83 07 91	add	x0, sp, #0x1e0
10230a270:	ad 78 bf 97	bl	__ZNKSt3__129_AllocatorDestroyRangeReverseINS_9allocatorINS_12basic_stringIcNS_11char_traitsIcEENS1_IcEEEEEEPS6_EclB6v15006Ev
10230a274:	44 1e 47 94	bl	0x1034d1b84 ; symbol stub for: ___cxa_rethrow
10230a278:	a9 00 00 14	b	0x10230a51c
10230a27c:	01 00 00 14	b	0x10230a280
10230a280:	f8 03 00 aa	mov	x24, x0
10230a284:	2e 1e 47 94	bl	0x1034d1b3c ; symbol stub for: ___cxa_end_catch
10230a288:	f5 eb 00 f9	str	x21, [sp, #0x1d0]
10230a28c:	a8 73 d7 38	ldursb	w8, [x29, #-0x89]
10230a290:	28 fc ff 36	tbz	w8, #0x1f, 0x10230a214
10230a294:	03 00 00 14	b	0x10230a2a0
10230a298:	d2 05 74 97	bl	___clang_call_terminate
10230a29c:	f8 03 00 aa	mov	x24, x0
10230a2a0:	a0 03 56 f8	ldur	x0, [x29, #-0xa0]
10230a2a4:	05 1e 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10230a2a8:	db ff ff 17	b	0x10230a214
10230a2ac:	f8 03 00 aa	mov	x24, x0
10230a2b0:	d9 ff ff 17	b	0x10230a214
10230a2b4:	f8 03 00 aa	mov	x24, x0
10230a2b8:	d7 ff ff 17	b	0x10230a214
10230a2bc:	f8 03 00 aa	mov	x24, x0
10230a2c0:	d5 ff ff 17	b	0x10230a214
10230a2c4:	f8 03 00 aa	mov	x24, x0
10230a2c8:	e0 83 07 91	add	x0, sp, #0x1e0
10230a2cc:	19 3d 00 94	bl	__ZN10tensorflow11TensorShapeD1Ev
10230a2d0:	d3 ff ff 17	b	0x10230a21c
10230a2d4:	f8 03 00 aa	mov	x24, x0
10230a2d8:	d1 ff ff 17	b	0x10230a21c
10230a2dc:	f8 03 00 aa	mov	x24, x0
10230a2e0:	e8 df c7 39	ldrsb	w8, [sp, #0x1f7]
10230a2e4:	68 01 f8 36	tbz	w8, #0x1f, 0x10230a310
10230a2e8:	e0 f3 40 f9	ldr	x0, [sp, #0x1e0]
10230a2ec:	f3 1d 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10230a2f0:	08 00 00 14	b	0x10230a310
10230a2f4:	f8 03 00 aa	mov	x24, x0
10230a2f8:	e8 df c7 39	ldrsb	w8, [sp, #0x1f7]
10230a2fc:	28 01 f8 36	tbz	w8, #0x1f, 0x10230a320
10230a300:	e0 f3 40 f9	ldr	x0, [sp, #0x1e0]
10230a304:	ed 1d 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10230a308:	06 00 00 14	b	0x10230a320
10230a30c:	f8 03 00 aa	mov	x24, x0
10230a310:	e0 03 14 aa	mov	x0, x20
10230a314:	e9 1d 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10230a318:	c9 ff ff 17	b	0x10230a23c
10230a31c:	f8 03 00 aa	mov	x24, x0
10230a320:	e0 4b 40 f9	ldr	x0, [sp, #0x90]
10230a324:	e5 1d 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10230a328:	93 00 00 14	b	0x10230a574
10230a32c:	f8 03 00 aa	mov	x24, x0
10230a330:	c3 ff ff 17	b	0x10230a23c
10230a334:	f8 03 00 aa	mov	x24, x0
10230a338:	8f 00 00 14	b	0x10230a574
10230a33c:	f8 03 00 aa	mov	x24, x0
10230a340:	e0 83 07 91	add	x0, sp, #0x1e0
10230a344:	8f 1d 47 94	bl	0x1034d1980 ; symbol stub for: __ZNSt3__16localeD1Ev
10230a348:	9b 00 00 14	b	0x10230a5b4
10230a34c:	f8 03 00 aa	mov	x24, x0
10230a350:	e0 83 07 91	add	x0, sp, #0x1e0
10230a354:	8b 1d 47 94	bl	0x1034d1980 ; symbol stub for: __ZNSt3__16localeD1Ev
10230a358:	8b 00 00 14	b	0x10230a584
10230a35c:	f8 03 00 aa	mov	x24, x0
10230a360:	97 00 00 14	b	0x10230a5bc
10230a364:	f8 03 00 aa	mov	x24, x0
10230a368:	89 00 00 14	b	0x10230a58c
10230a36c:	f8 03 00 aa	mov	x24, x0
10230a370:	93 11 00 34	cbz	w19, 0x10230a5a0
10230a374:	75 11 00 b4	cbz	x21, 0x10230a5a0
10230a378:	e0 03 15 aa	mov	x0, x21
10230a37c:	88 00 00 14	b	0x10230a59c
10230a380:	f8 03 00 aa	mov	x24, x0
10230a384:	93 00 00 34	cbz	w19, 0x10230a394
10230a388:	76 00 00 b4	cbz	x22, 0x10230a394
10230a38c:	e0 03 16 aa	mov	x0, x22
10230a390:	ca 1d 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10230a394:	bf 03 13 f8	stur	xzr, [x29, #-0xd0]
10230a398:	89 00 00 14	b	0x10230a5bc
10230a39c:	91 05 74 97	bl	___clang_call_terminate
10230a3a0:	f8 03 00 aa	mov	x24, x0
10230a3a4:	e0 83 07 91	add	x0, sp, #0x1e0
10230a3a8:	f0 3c 00 94	bl	__ZNSt3__14pairINS_12basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEEEN10tensorflow6TensorEED1Ev
10230a3ac:	68 00 00 14	b	0x10230a54c
10230a3b0:	f8 03 00 aa	mov	x24, x0
10230a3b4:	e8 df c7 39	ldrsb	w8, [sp, #0x1f7]
10230a3b8:	a8 0c f8 36	tbz	w8, #0x1f, 0x10230a54c
10230a3bc:	e0 f3 40 f9	ldr	x0, [sp, #0x1e0]
10230a3c0:	be 1d 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10230a3c4:	62 00 00 14	b	0x10230a54c
10230a3c8:	49 00 00 14	b	0x10230a4ec
10230a3cc:	f8 03 00 aa	mov	x24, x0
10230a3d0:	14 00 00 14	b	0x10230a420
10230a3d4:	46 00 00 14	b	0x10230a4ec
10230a3d8:	f8 03 00 aa	mov	x24, x0
10230a3dc:	0c 00 00 14	b	0x10230a40c
10230a3e0:	43 00 00 14	b	0x10230a4ec
10230a3e4:	f8 03 00 aa	mov	x24, x0
10230a3e8:	e8 a3 48 39	ldrb	w8, [sp, #0x228]
10230a3ec:	88 00 00 34	cbz	w8, 0x10230a3fc
10230a3f0:	e0 13 41 f9	ldr	x0, [sp, #0x220]
10230a3f4:	40 00 00 b4	cbz	x0, 0x10230a3fc
10230a3f8:	b0 1d 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10230a3fc:	ff 13 01 f9	str	xzr, [sp, #0x220]
10230a400:	ff a3 08 39	strb	wzr, [sp, #0x228]
10230a404:	e8 27 40 f9	ldr	x8, [sp, #0x48]
10230a408:	1f 7d 00 a9	stp	xzr, xzr, [x8]
10230a40c:	e8 03 48 39	ldrb	w8, [sp, #0x200]
10230a410:	88 00 00 34	cbz	w8, 0x10230a420
10230a414:	e0 ff 40 f9	ldr	x0, [sp, #0x1f8]
10230a418:	40 00 00 b4	cbz	x0, 0x10230a420
10230a41c:	a7 1d 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10230a420:	e8 43 49 39	ldrb	w8, [sp, #0x250]
10230a424:	e8 00 00 34	cbz	w8, 0x10230a440
10230a428:	e0 27 41 f9	ldr	x0, [sp, #0x248]
10230a42c:	a0 00 00 b4	cbz	x0, 0x10230a440
10230a430:	a2 1d 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10230a434:	03 00 00 14	b	0x10230a440
10230a438:	2d 00 00 14	b	0x10230a4ec
10230a43c:	f8 03 00 aa	mov	x24, x0
10230a440:	e0 03 1b aa	mov	x0, x27
10230a444:	9d 1d 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10230a448:	a8 83 53 38	ldurb	w8, [x29, #-0xc8]
10230a44c:	c8 07 00 34	cbz	w8, 0x10230a544
10230a450:	a0 03 53 f8	ldur	x0, [x29, #-0xd0]
10230a454:	80 07 00 b4	cbz	x0, 0x10230a544
10230a458:	98 1d 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10230a45c:	3a 00 00 14	b	0x10230a544
10230a460:	f8 03 00 aa	mov	x24, x0
10230a464:	3c 00 00 14	b	0x10230a554
10230a468:	f8 03 00 aa	mov	x24, x0
10230a46c:	e0 83 07 91	add	x0, sp, #0x1e0
10230a470:	b0 3c 00 94	bl	__ZN10tensorflow11TensorShapeD1Ev
10230a474:	38 00 00 14	b	0x10230a554
10230a478:	f8 03 00 aa	mov	x24, x0
10230a47c:	34 00 00 14	b	0x10230a54c
10230a480:	f8 03 00 aa	mov	x24, x0
10230a484:	32 00 00 14	b	0x10230a54c
10230a488:	f8 03 00 aa	mov	x24, x0
10230a48c:	30 00 00 14	b	0x10230a54c
10230a490:	f8 03 00 aa	mov	x24, x0
10230a494:	a0 83 51 f8	ldur	x0, [x29, #-0xe8]
10230a498:	88 1d 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10230a49c:	2c 00 00 14	b	0x10230a54c
10230a4a0:	e8 83 05 91	add	x8, sp, #0x160
10230a4a4:	13 41 00 91	add	x19, x8, #0x10
10230a4a8:	9f 1d 47 94	bl	0x1034d1b24 ; symbol stub for: ___cxa_begin_catch
10230a4ac:	e8 23 04 91	add	x8, sp, #0x108
10230a4b0:	f3 23 1e a9	stp	x19, x8, [sp, #0x1e0]
10230a4b4:	e8 c3 08 91	add	x8, sp, #0x230
10230a4b8:	e8 fb 00 f9	str	x8, [sp, #0x1f0]
10230a4bc:	e0 83 07 91	add	x0, sp, #0x1e0
10230a4c0:	19 78 bf 97	bl	__ZNKSt3__129_AllocatorDestroyRangeReverseINS_9allocatorINS_12basic_stringIcNS_11char_traitsIcEENS1_IcEEEEEEPS6_EclB6v15006Ev
10230a4c4:	b0 1d 47 94	bl	0x1034d1b84 ; symbol stub for: ___cxa_rethrow
10230a4c8:	15 00 00 14	b	0x10230a51c
10230a4cc:	01 00 00 14	b	0x10230a4d0
10230a4d0:	f8 03 00 aa	mov	x24, x0
10230a4d4:	9a 1d 47 94	bl	0x1034d1b3c ; symbol stub for: ___cxa_end_catch
10230a4d8:	fa b7 00 f9	str	x26, [sp, #0x168]
10230a4dc:	a8 f3 d2 38	ldursb	w8, [x29, #-0xd1]
10230a4e0:	a8 fd ff 37	tbnz	w8, #0x1f, 0x10230a494
10230a4e4:	1a 00 00 14	b	0x10230a54c
10230a4e8:	3e 05 74 97	bl	___clang_call_terminate
10230a4ec:	f8 03 00 aa	mov	x24, x0
10230a4f0:	15 00 00 14	b	0x10230a544
10230a4f4:	e8 23 05 91	add	x8, sp, #0x148
10230a4f8:	13 41 00 91	add	x19, x8, #0x10
10230a4fc:	8a 1d 47 94	bl	0x1034d1b24 ; symbol stub for: ___cxa_begin_catch
10230a500:	e8 c3 08 91	add	x8, sp, #0x230
10230a504:	f3 23 1e a9	stp	x19, x8, [sp, #0x1e0]
10230a508:	a8 a3 03 d1	sub	x8, x29, #0xe8
10230a50c:	e8 fb 00 f9	str	x8, [sp, #0x1f0]
10230a510:	e0 83 07 91	add	x0, sp, #0x1e0
10230a514:	04 78 bf 97	bl	__ZNKSt3__129_AllocatorDestroyRangeReverseINS_9allocatorINS_12basic_stringIcNS_11char_traitsIcEENS1_IcEEEEEEPS6_EclB6v15006Ev
10230a518:	9b 1d 47 94	bl	0x1034d1b84 ; symbol stub for: ___cxa_rethrow
10230a51c:	20 00 20 d4	brk	#0x1
10230a520:	01 00 00 14	b	0x10230a524
10230a524:	f8 03 00 aa	mov	x24, x0
10230a528:	85 1d 47 94	bl	0x1034d1b3c ; symbol stub for: ___cxa_end_catch
10230a52c:	fb ab 00 f9	str	x27, [sp, #0x150]
10230a530:	05 00 00 14	b	0x10230a544
10230a534:	2b 05 74 97	bl	___clang_call_terminate
10230a538:	f8 03 00 aa	mov	x24, x0
10230a53c:	e0 23 05 91	add	x0, sp, #0x148
10230a540:	f0 7d 8c 97	bl	__ZNSt3__16vectorINS_12basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEEENS4_IS6_EEED1B6v15006Ev
10230a544:	e0 83 05 91	add	x0, sp, #0x160
10230a548:	ee 7d 8c 97	bl	__ZNSt3__16vectorINS_12basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEEENS4_IS6_EEED1B6v15006Ev
10230a54c:	a0 03 03 d1	sub	x0, x29, #0xc0
10230a550:	20 1b 47 94	bl	0x1034d11d0 ; symbol stub for: __ZN10tensorflow6TensorD1Ev
10230a554:	e8 9f c6 39	ldrsb	w8, [sp, #0x1a7]
10230a558:	68 00 f8 36	tbz	w8, #0x1f, 0x10230a564
10230a55c:	e0 cb 40 f9	ldr	x0, [sp, #0x190]
10230a560:	56 1d 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10230a564:	e0 4b 40 f9	ldr	x0, [sp, #0x90]
10230a568:	08 00 40 f9	ldr	x8, [x0]
10230a56c:	08 05 40 f9	ldr	x8, [x8, #0x8]
10230a570:	00 01 3f d6	blr	x8
10230a574:	e0 c3 06 91	add	x0, sp, #0x1b0
10230a578:	ae 3c 00 94	bl	__ZNSt3__16vectorIN10tensorflow6TensorENS_9allocatorIS2_EEED1B6v15006Ev
10230a57c:	e0 23 07 91	add	x0, sp, #0x1c8
10230a580:	c2 3c 00 94	bl	__ZNSt3__16vectorINS_4pairINS_12basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEEEN10tensorflow6TensorEEENS5_ISA_EEED1B6v15006Ev
10230a584:	e0 e3 05 91	add	x0, sp, #0x178
10230a588:	5d 80 06 94	bl	__ZN4juce6StringD1Ev
10230a58c:	a8 03 58 38	ldurb	w8, [x29, #-0x80]
10230a590:	88 00 00 34	cbz	w8, 0x10230a5a0
10230a594:	a0 83 57 f8	ldur	x0, [x29, #-0x88]
10230a598:	40 00 00 b4	cbz	x0, 0x10230a5a0
10230a59c:	47 1d 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10230a5a0:	e0 a3 02 91	add	x0, sp, #0xa8
10230a5a4:	56 80 06 94	bl	__ZN4juce6StringD1Ev
10230a5a8:	e0 03 18 aa	mov	x0, x24
10230a5ac:	d0 1a 47 94	bl	0x1034d10ec ; symbol stub for: __Unwind_Resume
10230a5b0:	f8 03 00 aa	mov	x24, x0
10230a5b4:	e0 83 05 91	add	x0, sp, #0x160
10230a5b8:	51 80 06 94	bl	__ZN4juce6StringD1Ev
10230a5bc:	e0 83 02 91	add	x0, sp, #0xa0
10230a5c0:	4f 80 06 94	bl	__ZN4juce6StringD1Ev
10230a5c4:	e0 03 18 aa	mov	x0, x24
10230a5c8:	c9 1a 47 94	bl	0x1034d10ec ; symbol stub for: __Unwind_Resume
10230a5cc:	f8 03 00 aa	mov	x24, x0
10230a5d0:	ed ff ff 17	b	0x10230a584
