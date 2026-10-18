/Applications/rekordbox 7/rekordbox.app/Contents/MacOS/rekordbox:
(__TEXT,__text) section
__ZNK6madmom35RNNDownBeatTrackingObservationModel13log_densitiesERKN2nc7NdArrayIfNSt3__19allocatorIfEEEE:
10231725c:	ff 43 04 d1	sub	sp, sp, #0x110
102317260:	e9 23 0c 6d	stp	d9, d8, [sp, #0xc0]
102317264:	fc 6f 0d a9	stp	x28, x27, [sp, #0xd0]
102317268:	f6 57 0e a9	stp	x22, x21, [sp, #0xe0]
10231726c:	f4 4f 0f a9	stp	x20, x19, [sp, #0xf0]
102317270:	fd 7b 10 a9	stp	x29, x30, [sp, #0x100]
102317274:	fd 03 04 91	add	x29, sp, #0x100
102317278:	f4 03 01 aa	mov	x20, x1
10231727c:	f5 03 00 aa	mov	x21, x0
102317280:	f3 03 08 aa	mov	x19, x8
102317284:	36 04 40 b9	ldr	w22, [x1, #0x4]
102317288:	68 00 80 52	mov	w8, #0x3
10231728c:	76 a2 00 29	stp	w22, w8, [x19, #0x4]
102317290:	c8 06 16 2b	adds	w8, w22, w22, lsl #1
102317294:	68 fe 01 29	stp	w8, wzr, [x19, #0xc]
102317298:	7f 0e 00 f9	str	xzr, [x19, #0x18]
10231729c:	7f 82 00 39	strb	wzr, [x19, #0x20]
1023172a0:	c0 00 00 54	b.eq	0x1023172b8
1023172a4:	00 f5 7e d3	lsl	x0, x8, #2
1023172a8:	0a ea 46 94	bl	0x1034d1ad0 ; symbol stub for: __Znwm
1023172ac:	60 0e 00 f9	str	x0, [x19, #0x18]
1023172b0:	28 00 80 52	mov	w8, #0x1
1023172b4:	68 82 00 39	strb	w8, [x19, #0x20]
1023172b8:	c8 7e 60 d3	lsl	x8, x22, #32
1023172bc:	a8 83 1a f8	stur	x8, [x29, #-0x58]
1023172c0:	28 00 80 52	mov	w8, #0x1
1023172c4:	a8 03 1b b8	stur	w8, [x29, #-0x50]
1023172c8:	e8 23 00 91	add	x8, sp, #0x8
1023172cc:	e0 03 14 aa	mov	x0, x20
1023172d0:	41 00 80 52	mov	w1, #0x2
1023172d4:	08 06 00 94	bl	__ZNK2nc7NdArrayIfNSt3__19allocatorIfEEE3sumENS_4AxisE
1023172d8:	e8 c3 00 91	add	x8, sp, #0x30
1023172dc:	00 10 2e 1e	fmov	s0, #1.00000000
1023172e0:	e0 23 00 91	add	x0, sp, #0x8
1023172e4:	78 02 00 94	bl	__ZN2ncmiIfEENS_7NdArrayIT_NSt3__19allocatorIS2_EEEES2_RKS6_
1023172e8:	a8 32 40 bd	ldr	s8, [x21, #0x30]
1023172ec:	e1 27 40 f9	ldr	x1, [sp, #0x48]
1023172f0:	a0 23 01 d1	sub	x0, x29, #0x48
1023172f4:	e5 42 96 97	bl	__ZN2nc20NdArrayConstIteratorIfPflEC2ES1_
1023172f8:	b5 83 5b f8	ldur	x21, [x29, #-0x48]
1023172fc:	f6 3f 40 b9	ldr	w22, [sp, #0x3c]
102317300:	e1 27 40 f9	ldr	x1, [sp, #0x48]
102317304:	a0 23 01 d1	sub	x0, x29, #0x48
102317308:	e0 42 96 97	bl	__ZN2nc20NdArrayConstIteratorIfPflEC2ES1_
10231730c:	a8 83 5b f8	ldur	x8, [x29, #-0x48]
102317310:	08 09 16 8b	add	x8, x8, x22, lsl #2
102317314:	bf 02 08 eb	cmp	x21, x8
102317318:	a0 04 00 54	b.eq	0x1023173ac
10231731c:	00 d9 21 5e	scvtf	s0, s8
102317320:	01 10 3e 1e	fmov	s1, #-1.00000000
102317324:	00 28 21 1e	fadd	s0, s0, s1
102317328:	09 01 15 cb	sub	x9, x8, x21
10231732c:	2a 11 00 d1	sub	x10, x9, #0x4
102317330:	e9 03 15 aa	mov	x9, x21
102317334:	5f f1 00 f1	cmp	x10, #0x3c
102317338:	c3 02 00 54	b.lo	0x102317390
10231733c:	49 fd 42 d3	lsr	x9, x10, #2
102317340:	2a 05 00 91	add	x10, x9, #0x1
102317344:	4b e9 7c 92	and	x11, x10, #0x7ffffffffffffff0
102317348:	a9 0a 0b 8b	add	x9, x21, x11, lsl #2
10231734c:	01 04 04 4e	dup.4s	v1, v0[0]
102317350:	02 f6 03 4f	fmov.4s	v2, #1.00000000
102317354:	41 fc 21 6e	fdiv.4s	v1, v2, v1
102317358:	ac 82 00 91	add	x12, x21, #0x20
10231735c:	ed 03 0b aa	mov	x13, x11
102317360:	82 0d 7f ad	ldp	q2, q3, [x12, #-0x20]
102317364:	84 15 40 ad	ldp	q4, q5, [x12]
102317368:	42 dc 21 6e	fmul.4s	v2, v2, v1
10231736c:	63 dc 21 6e	fmul.4s	v3, v3, v1
102317370:	84 dc 21 6e	fmul.4s	v4, v4, v1
102317374:	a5 dc 21 6e	fmul.4s	v5, v5, v1
102317378:	82 0d 3f ad	stp	q2, q3, [x12, #-0x20]
10231737c:	84 15 82 ac	stp	q4, q5, [x12], #0x40
102317380:	ad 41 00 f1	subs	x13, x13, #0x10
102317384:	e1 fe ff 54	b.ne	0x102317360
102317388:	5f 01 0b eb	cmp	x10, x11
10231738c:	00 01 00 54	b.eq	0x1023173ac
102317390:	01 10 2e 1e	fmov	s1, #1.00000000
102317394:	20 18 20 1e	fdiv	s0, s1, s0
102317398:	21 01 40 bd	ldr	s1, [x9]
10231739c:	21 08 20 1e	fmul	s1, s1, s0
1023173a0:	21 45 00 bc	str	s1, [x9], #0x4
1023173a4:	3f 01 08 eb	cmp	x9, x8
1023173a8:	81 ff ff 54	b.ne	0x102317398
1023173ac:	e8 43 43 f8	ldur	x8, [sp, #0x34]
1023173b0:	e8 c3 05 f8	stur	x8, [sp, #0x5c]
1023173b4:	e0 c3 43 fc	ldur	d0, [sp, #0x3c]
1023173b8:	e0 43 06 fc	stur	d0, [sp, #0x64]
1023173bc:	e8 27 40 f9	ldr	x8, [sp, #0x48]
1023173c0:	e8 3b 00 f9	str	x8, [sp, #0x70]
1023173c4:	e8 43 41 39	ldrb	w8, [sp, #0x50]
1023173c8:	e8 e3 01 39	strb	w8, [sp, #0x78]
1023173cc:	ff 1f 00 f9	str	xzr, [sp, #0x38]
1023173d0:	ff 37 00 b9	str	wzr, [sp, #0x34]
1023173d4:	ff 43 01 39	strb	wzr, [sp, #0x50]
1023173d8:	ff 27 00 f9	str	xzr, [sp, #0x48]
1023173dc:	e8 03 02 91	add	x8, sp, #0x80
1023173e0:	e0 63 01 91	add	x0, sp, #0x58
1023173e4:	d9 01 00 94	bl	__ZN2nc3logIfEEDaRKNS_7NdArrayIT_NSt3__19allocatorIS3_EEEE
1023173e8:	f5 03 02 91	add	x21, sp, #0x80
1023173ec:	a1 63 01 d1	sub	x1, x29, #0x58
1023173f0:	e3 03 02 91	add	x3, sp, #0x80
1023173f4:	e0 03 13 aa	mov	x0, x19
1023173f8:	02 00 80 52	mov	w2, #0x0
1023173fc:	6a 01 00 94	bl	__ZN2nc7NdArrayIfNSt3__19allocatorIfEEE3putERKNS_5SliceEiRKS4_
102317400:	e8 83 42 39	ldrb	w8, [sp, #0xa0]
102317404:	88 00 00 34	cbz	w8, 0x102317414
102317408:	e0 4f 40 f9	ldr	x0, [sp, #0x98]
10231740c:	40 00 00 b4	cbz	x0, 0x102317414
102317410:	aa e9 46 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102317414:	ff 4f 00 f9	str	xzr, [sp, #0x98]
102317418:	ff 83 02 39	strb	wzr, [sp, #0xa0]
10231741c:	bf c2 00 f8	stur	xzr, [x21, #0xc]
102317420:	ff 43 08 f8	stur	xzr, [sp, #0x84]
102317424:	e8 e3 41 39	ldrb	w8, [sp, #0x78]
102317428:	88 00 00 34	cbz	w8, 0x102317438
10231742c:	e0 3b 40 f9	ldr	x0, [sp, #0x70]
102317430:	40 00 00 b4	cbz	x0, 0x102317438
102317434:	a1 e9 46 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102317438:	ff 3b 00 f9	str	xzr, [sp, #0x70]
10231743c:	ff e3 01 39	strb	wzr, [sp, #0x78]
102317440:	ff 43 06 f8	stur	xzr, [sp, #0x64]
102317444:	ff c3 05 f8	stur	xzr, [sp, #0x5c]
102317448:	e8 43 41 39	ldrb	w8, [sp, #0x50]
10231744c:	88 00 00 34	cbz	w8, 0x10231745c
102317450:	e0 27 40 f9	ldr	x0, [sp, #0x48]
102317454:	40 00 00 b4	cbz	x0, 0x10231745c
102317458:	98 e9 46 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10231745c:	ff 27 00 f9	str	xzr, [sp, #0x48]
102317460:	ff 43 01 39	strb	wzr, [sp, #0x50]
102317464:	ff c3 03 f8	stur	xzr, [sp, #0x3c]
102317468:	ff 43 03 f8	stur	xzr, [sp, #0x34]
10231746c:	e8 a3 40 39	ldrb	w8, [sp, #0x28]
102317470:	88 00 00 34	cbz	w8, 0x102317480
102317474:	e0 13 40 f9	ldr	x0, [sp, #0x20]
102317478:	40 00 00 b4	cbz	x0, 0x102317480
10231747c:	8f e9 46 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102317480:	68 06 40 b9	ldr	w8, [x19, #0x4]
102317484:	08 7d 60 d3	lsl	x8, x8, #32
102317488:	e8 07 00 f9	str	x8, [sp, #0x8]
10231748c:	28 00 80 52	mov	w8, #0x1
102317490:	e8 13 00 b9	str	w8, [sp, #0x10]
102317494:	88 06 40 b9	ldr	w8, [x20, #0x4]
102317498:	01 7d 60 d3	lsl	x1, x8, #32
10231749c:	e8 63 01 91	add	x8, sp, #0x58
1023174a0:	e0 03 14 aa	mov	x0, x20
1023174a4:	22 00 80 52	mov	w2, #0x1
1023174a8:	03 00 80 52	mov	w3, #0x0
1023174ac:	5c 02 00 94	bl	__ZNK2nc7NdArrayIfNSt3__19allocatorIfEEEclENS_5SliceEi
1023174b0:	e8 03 02 91	add	x8, sp, #0x80
1023174b4:	e0 63 01 91	add	x0, sp, #0x58
1023174b8:	a4 01 00 94	bl	__ZN2nc3logIfEEDaRKNS_7NdArrayIT_NSt3__19allocatorIS3_EEEE
1023174bc:	e1 23 00 91	add	x1, sp, #0x8
1023174c0:	e3 03 02 91	add	x3, sp, #0x80
1023174c4:	e0 03 13 aa	mov	x0, x19
1023174c8:	22 00 80 52	mov	w2, #0x1
1023174cc:	36 01 00 94	bl	__ZN2nc7NdArrayIfNSt3__19allocatorIfEEE3putERKNS_5SliceEiRKS4_
1023174d0:	e8 83 42 39	ldrb	w8, [sp, #0xa0]
1023174d4:	88 00 00 34	cbz	w8, 0x1023174e4
1023174d8:	e0 4f 40 f9	ldr	x0, [sp, #0x98]
1023174dc:	40 00 00 b4	cbz	x0, 0x1023174e4
1023174e0:	76 e9 46 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
1023174e4:	ff 4f 00 f9	str	xzr, [sp, #0x98]
1023174e8:	ff 83 02 39	strb	wzr, [sp, #0xa0]
1023174ec:	bf c2 00 f8	stur	xzr, [x21, #0xc]
1023174f0:	ff 43 08 f8	stur	xzr, [sp, #0x84]
1023174f4:	e8 e3 41 39	ldrb	w8, [sp, #0x78]
1023174f8:	88 00 00 34	cbz	w8, 0x102317508
1023174fc:	e0 3b 40 f9	ldr	x0, [sp, #0x70]
102317500:	40 00 00 b4	cbz	x0, 0x102317508
102317504:	6d e9 46 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102317508:	68 06 40 b9	ldr	w8, [x19, #0x4]
10231750c:	08 7d 60 d3	lsl	x8, x8, #32
102317510:	e8 07 00 f9	str	x8, [sp, #0x8]
102317514:	28 00 80 52	mov	w8, #0x1
102317518:	e8 13 00 b9	str	w8, [sp, #0x10]
10231751c:	88 06 40 b9	ldr	w8, [x20, #0x4]
102317520:	01 7d 60 d3	lsl	x1, x8, #32
102317524:	e8 63 01 91	add	x8, sp, #0x58
102317528:	e0 03 14 aa	mov	x0, x20
10231752c:	22 00 80 52	mov	w2, #0x1
102317530:	23 00 80 52	mov	w3, #0x1
102317534:	3a 02 00 94	bl	__ZNK2nc7NdArrayIfNSt3__19allocatorIfEEEclENS_5SliceEi
102317538:	e8 03 02 91	add	x8, sp, #0x80
10231753c:	e0 63 01 91	add	x0, sp, #0x58
102317540:	82 01 00 94	bl	__ZN2nc3logIfEEDaRKNS_7NdArrayIT_NSt3__19allocatorIS3_EEEE
102317544:	e1 23 00 91	add	x1, sp, #0x8
102317548:	e3 03 02 91	add	x3, sp, #0x80
10231754c:	e0 03 13 aa	mov	x0, x19
102317550:	42 00 80 52	mov	w2, #0x2
102317554:	14 01 00 94	bl	__ZN2nc7NdArrayIfNSt3__19allocatorIfEEE3putERKNS_5SliceEiRKS4_
102317558:	e8 83 42 39	ldrb	w8, [sp, #0xa0]
10231755c:	88 00 00 34	cbz	w8, 0x10231756c
102317560:	e0 4f 40 f9	ldr	x0, [sp, #0x98]
102317564:	40 00 00 b4	cbz	x0, 0x10231756c
102317568:	54 e9 46 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10231756c:	ff 4f 00 f9	str	xzr, [sp, #0x98]
102317570:	ff 83 02 39	strb	wzr, [sp, #0xa0]
102317574:	bf c2 00 f8	stur	xzr, [x21, #0xc]
102317578:	ff 43 08 f8	stur	xzr, [sp, #0x84]
10231757c:	e8 e3 41 39	ldrb	w8, [sp, #0x78]
102317580:	88 00 00 34	cbz	w8, 0x102317590
102317584:	e0 3b 40 f9	ldr	x0, [sp, #0x70]
102317588:	40 00 00 b4	cbz	x0, 0x102317590
10231758c:	4b e9 46 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102317590:	fd 7b 50 a9	ldp	x29, x30, [sp, #0x100]
102317594:	f4 4f 4f a9	ldp	x20, x19, [sp, #0xf0]
102317598:	f6 57 4e a9	ldp	x22, x21, [sp, #0xe0]
10231759c:	fc 6f 4d a9	ldp	x28, x27, [sp, #0xd0]
1023175a0:	e9 23 4c 6d	ldp	d9, d8, [sp, #0xc0]
1023175a4:	ff 43 04 91	add	sp, sp, #0x110
1023175a8:	c0 03 5f d6	ret
1023175ac:	03 00 00 14	b	0x1023175b8
1023175b0:	0d 00 00 14	b	0x1023175e4
1023175b4:	3b 00 00 14	b	0x1023176a0
1023175b8:	f4 03 00 aa	mov	x20, x0
1023175bc:	e8 83 42 39	ldrb	w8, [sp, #0xa0]
1023175c0:	88 00 00 34	cbz	w8, 0x1023175d0
1023175c4:	e0 4f 40 f9	ldr	x0, [sp, #0x98]
1023175c8:	40 00 00 b4	cbz	x0, 0x1023175d0
1023175cc:	3b e9 46 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
1023175d0:	ff 4f 00 f9	str	xzr, [sp, #0x98]
1023175d4:	ff 83 02 39	strb	wzr, [sp, #0xa0]
1023175d8:	bf c2 00 f8	stur	xzr, [x21, #0xc]
1023175dc:	ff 43 08 f8	stur	xzr, [sp, #0x84]
1023175e0:	02 00 00 14	b	0x1023175e8
1023175e4:	f4 03 00 aa	mov	x20, x0
1023175e8:	e8 e3 41 39	ldrb	w8, [sp, #0x78]
1023175ec:	c8 05 00 34	cbz	w8, 0x1023176a4
1023175f0:	e0 3b 40 f9	ldr	x0, [sp, #0x70]
1023175f4:	20 05 00 b5	cbnz	x0, 0x102317698
1023175f8:	2b 00 00 14	b	0x1023176a4
1023175fc:	29 00 00 14	b	0x1023176a0
102317600:	f4 03 00 aa	mov	x20, x0
102317604:	e8 83 42 39	ldrb	w8, [sp, #0xa0]
102317608:	88 00 00 34	cbz	w8, 0x102317618
10231760c:	e0 4f 40 f9	ldr	x0, [sp, #0x98]
102317610:	40 00 00 b4	cbz	x0, 0x102317618
102317614:	29 e9 46 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102317618:	ff 4f 00 f9	str	xzr, [sp, #0x98]
10231761c:	ff 83 02 39	strb	wzr, [sp, #0xa0]
102317620:	bf c2 00 f8	stur	xzr, [x21, #0xc]
102317624:	ff 43 08 f8	stur	xzr, [sp, #0x84]
102317628:	02 00 00 14	b	0x102317630
10231762c:	f4 03 00 aa	mov	x20, x0
102317630:	e8 e3 41 39	ldrb	w8, [sp, #0x78]
102317634:	88 00 00 34	cbz	w8, 0x102317644
102317638:	e0 3b 40 f9	ldr	x0, [sp, #0x70]
10231763c:	40 00 00 b4	cbz	x0, 0x102317644
102317640:	1e e9 46 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102317644:	ff 3b 00 f9	str	xzr, [sp, #0x70]
102317648:	ff e3 01 39	strb	wzr, [sp, #0x78]
10231764c:	ff 43 06 f8	stur	xzr, [sp, #0x64]
102317650:	ff c3 05 f8	stur	xzr, [sp, #0x5c]
102317654:	e8 43 41 39	ldrb	w8, [sp, #0x50]
102317658:	88 00 00 34	cbz	w8, 0x102317668
10231765c:	e0 27 40 f9	ldr	x0, [sp, #0x48]
102317660:	40 00 00 b4	cbz	x0, 0x102317668
102317664:	15 e9 46 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102317668:	ff 27 00 f9	str	xzr, [sp, #0x48]
10231766c:	ff 43 01 39	strb	wzr, [sp, #0x50]
102317670:	ff c3 03 f8	stur	xzr, [sp, #0x3c]
102317674:	ff 43 03 f8	stur	xzr, [sp, #0x34]
102317678:	04 00 00 14	b	0x102317688
10231767c:	d9 d0 73 97	bl	___clang_call_terminate
102317680:	d8 d0 73 97	bl	___clang_call_terminate
102317684:	f4 03 00 aa	mov	x20, x0
102317688:	e8 a3 40 39	ldrb	w8, [sp, #0x28]
10231768c:	c8 00 00 34	cbz	w8, 0x1023176a4
102317690:	e0 13 40 f9	ldr	x0, [sp, #0x20]
102317694:	80 00 00 b4	cbz	x0, 0x1023176a4
102317698:	08 e9 46 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10231769c:	02 00 00 14	b	0x1023176a4
1023176a0:	f4 03 00 aa	mov	x20, x0
1023176a4:	e0 03 13 aa	mov	x0, x19
1023176a8:	24 10 96 97	bl	__ZN2nc7NdArrayIfNSt3__19allocatorIfEEED1Ev
1023176ac:	e0 03 14 aa	mov	x0, x20
1023176b0:	8f e6 46 94	bl	0x1034d10ec ; symbol stub for: __Unwind_Resume
