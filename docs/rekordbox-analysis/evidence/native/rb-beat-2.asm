/Applications/rekordbox 7/rekordbox.app/Contents/MacOS/rekordbox:
(__TEXT,__text) section
__ZN6madmom7analyzeEN4juce6StringES1_RKNSt3__112basic_stringIcNS2_11char_traitsIcEENS2_9allocatorIcEEEEiibRN8nlohmann10basic_jsonINSB_11ordered_mapENS2_6vectorES8_bxydS6_NSB_14adl_serializerENSE_IhNS6_IhEEEEEE:
10230a820:	ef 3b b6 6d	stp	d15, d14, [sp, #-0xa0]!
10230a824:	ed 33 01 6d	stp	d13, d12, [sp, #0x10]
10230a828:	eb 2b 02 6d	stp	d11, d10, [sp, #0x20]
10230a82c:	e9 23 03 6d	stp	d9, d8, [sp, #0x30]
10230a830:	fc 6f 04 a9	stp	x28, x27, [sp, #0x40]
10230a834:	fa 67 05 a9	stp	x26, x25, [sp, #0x50]
10230a838:	f8 5f 06 a9	stp	x24, x23, [sp, #0x60]
10230a83c:	f6 57 07 a9	stp	x22, x21, [sp, #0x70]
10230a840:	f4 4f 08 a9	stp	x20, x19, [sp, #0x80]
10230a844:	fd 7b 09 a9	stp	x29, x30, [sp, #0x90]
10230a848:	fd 43 02 91	add	x29, sp, #0x90
10230a84c:	ff 83 05 d1	sub	sp, sp, #0x160
10230a850:	e6 13 00 f9	str	x6, [sp, #0x20]
10230a854:	f9 03 05 aa	mov	x25, x5
10230a858:	f5 03 04 aa	mov	x21, x4
10230a85c:	f4 03 03 aa	mov	x20, x3
10230a860:	f3 03 02 aa	mov	x19, x2
10230a864:	fb 03 01 aa	mov	x27, x1
10230a868:	fa 03 00 aa	mov	x26, x0
10230a86c:	28 72 01 90	adrp	x8, 11844 ; 0x10514e000
10230a870:	08 7d 42 f9	ldr	x8, [x8, #0x4f8] ; literal pool symbol address: ___stack_chk_guard
10230a874:	08 01 40 f9	ldr	x8, [x8]
10230a878:	a8 03 16 f8	stur	x8, [x29, #-0xa0]
10230a87c:	a0 23 03 d1	sub	x0, x29, #0xc8
10230a880:	e1 03 02 aa	mov	x1, x2
10230a884:	40 1b 47 94	bl	0x1034d1584 ; symbol stub for: __ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEEC1ERKS5_
10230a888:	68 5e c0 39	ldrsb	w8, [x19, #0x17]
10230a88c:	69 02 40 f9	ldr	x9, [x19]
10230a890:	1f 01 00 71	cmp	w8, #0x0
10230a894:	28 b1 93 9a	csel	x8, x9, x19, lt
10230a898:	08 01 40 39	ldrb	w8, [x8]
10230a89c:	1f f9 01 71	cmp	w8, #0x7e
10230a8a0:	f4 1f 00 f9	str	x20, [sp, #0x38]
10230a8a4:	41 08 00 54	b.ne	0x10230a9ac
10230a8a8:	00 67 01 f0	adrp	x0, 11491 ; 0x104fed000
10230a8ac:	00 48 11 91	add	x0, x0, #0x452 ; literal pool for: "HOME"
10230a8b0:	6b 1e 47 94	bl	0x1034d225c ; symbol stub for: _getenv
10230a8b4:	f4 03 00 aa	mov	x20, x0
10230a8b8:	54 21 47 94	bl	0x1034d2e08 ; symbol stub for: _strlen
10230a8bc:	e8 eb 7c b2	mov	x8, #0x7ffffffffffffff0
10230a8c0:	1f 00 08 eb	cmp	x0, x8
10230a8c4:	22 90 00 54	b.hs	0x10230bac8
10230a8c8:	f6 03 00 aa	mov	x22, x0
10230a8cc:	1f 5c 00 f1	cmp	x0, #0x17
10230a8d0:	a2 00 00 54	b.hs	0x10230a8e4
10230a8d4:	b7 83 03 d1	sub	x23, x29, #0xe0
10230a8d8:	b6 73 13 38	sturb	w22, [x29, #-0xc9]
10230a8dc:	56 01 00 b5	cbnz	x22, 0x10230a904
10230a8e0:	0d 00 00 14	b	0x10230a914
10230a8e4:	c8 42 00 91	add	x8, x22, #0x10
10230a8e8:	18 ed 7c 92	and	x24, x8, #0xfffffffffffffff0
10230a8ec:	e0 03 18 aa	mov	x0, x24
10230a8f0:	78 1c 47 94	bl	0x1034d1ad0 ; symbol stub for: __Znwm
10230a8f4:	f7 03 00 aa	mov	x23, x0
10230a8f8:	08 03 41 b2	orr	x8, x24, #0x8000000000000000
10230a8fc:	b6 a3 32 a9	stp	x22, x8, [x29, #-0xd8]
10230a900:	a0 03 12 f8	stur	x0, [x29, #-0xe0]
10230a904:	e0 03 17 aa	mov	x0, x23
10230a908:	e1 03 14 aa	mov	x1, x20
10230a90c:	e2 03 16 aa	mov	x2, x22
10230a910:	4f 1f 47 94	bl	0x1034d264c ; symbol stub for: _memmove
10230a914:	ff 6a 36 38	strb	wzr, [x23, x22]
10230a918:	f4 e3 03 91	add	x20, sp, #0xf8
10230a91c:	e0 e3 03 91	add	x0, sp, #0xf8
10230a920:	e1 03 13 aa	mov	x1, x19
10230a924:	22 00 80 52	mov	w2, #0x1
10230a928:	03 00 80 92	mov	x3, #-0x1
10230a92c:	e4 03 13 aa	mov	x4, x19
10230a930:	18 1b 47 94	bl	0x1034d1590 ; symbol stub for: __ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEEC1ERKS5_mmRKS4_
10230a934:	e8 3f 44 39	ldrb	w8, [sp, #0x10f]
10230a938:	09 1d 00 13	sxtb	w9, w8
10230a93c:	ea af 4f a9	ldp	x10, x11, [sp, #0xf8]
10230a940:	3f 01 00 71	cmp	w9, #0x0
10230a944:	41 b1 94 9a	csel	x1, x10, x20, lt
10230a948:	62 b1 88 9a	csel	x2, x11, x8, lt
10230a94c:	a0 83 03 d1	sub	x0, x29, #0xe0
10230a950:	e9 1a 47 94	bl	0x1034d14f4 ; symbol stub for: __ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKcm
10230a954:	b3 23 03 d1	sub	x19, x29, #0xc8
10230a958:	14 20 40 a9	ldp	x20, x8, [x0]
10230a95c:	a8 03 15 f8	stur	x8, [x29, #-0xb0]
10230a960:	08 f0 40 f8	ldur	x8, [x0, #0xf]
10230a964:	68 f2 01 f8	stur	x8, [x19, #0x1f]
10230a968:	16 5c 40 39	ldrb	w22, [x0, #0x17]
10230a96c:	1f fc 00 a9	stp	xzr, xzr, [x0, #0x8]
10230a970:	1f 00 00 f9	str	xzr, [x0]
10230a974:	a8 f3 d4 38	ldursb	w8, [x29, #-0xb1]
10230a978:	68 00 f8 36	tbz	w8, #0x1f, 0x10230a984
10230a97c:	a0 83 53 f8	ldur	x0, [x29, #-0xc8]
10230a980:	4e 1c 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10230a984:	a8 03 55 f8	ldur	x8, [x29, #-0xb0]
10230a988:	b4 a3 33 a9	stp	x20, x8, [x29, #-0xc8]
10230a98c:	68 f2 41 f8	ldur	x8, [x19, #0x1f]
10230a990:	68 f2 00 f8	stur	x8, [x19, #0xf]
10230a994:	b6 f3 14 38	sturb	w22, [x29, #-0xb1]
10230a998:	e8 3f c4 39	ldrsb	w8, [sp, #0x10f]
10230a99c:	08 13 f8 37	tbnz	w8, #0x1f, 0x10230abfc
10230a9a0:	a8 73 d3 38	ldursb	w8, [x29, #-0xc9]
10230a9a4:	f4 1f 40 f9	ldr	x20, [sp, #0x38]
10230a9a8:	48 13 f8 37	tbnz	w8, #0x1f, 0x10230ac10
10230a9ac:	a0 c3 02 d1	sub	x0, x29, #0xb0
10230a9b0:	a1 23 03 d1	sub	x1, x29, #0xc8
10230a9b4:	ea 1b 07 94	bl	__ZN4juce6StringC1ERKNSt3__112basic_stringIcNS1_11char_traitsIcEENS1_9allocatorIcEEEE
10230a9b8:	00 55 80 52	mov	w0, #0x2a8
10230a9bc:	45 1c 47 94	bl	0x1034d1ad0 ; symbol stub for: __Znwm
10230a9c0:	fc 03 00 aa	mov	x28, x0
10230a9c4:	fa ef 02 a9	stp	x26, x27, [sp, #0x28]
10230a9c8:	a1 c3 02 d1	sub	x1, x29, #0xb0
10230a9cc:	e2 03 14 aa	mov	x2, x20
10230a9d0:	03 00 80 12	mov	w3, #-0x1
10230a9d4:	a4 aa 81 52	mov	w4, #0xd55
10230a9d8:	05 00 80 52	mov	w5, #0x0
10230a9dc:	06 00 80 d2	mov	x6, #0x0
10230a9e0:	94 18 15 94	bl	__ZN6rbxfrm17PcmReaderTemplateINS_6Float2EEC1ERKN4juce6StringEiNS3_6Thread8PriorityEiiPKNS_18AudioReaderFactoryE
10230a9e4:	96 63 07 91	add	x22, x28, #0x1d8
10230a9e8:	88 fb 81 b9	ldrsw	x8, [x28, #0x1f8]
10230a9ec:	09 05 00 d1	sub	x9, x8, #0x1
10230a9f0:	8a 07 80 52	mov	w10, #0x3c
10230a9f4:	8a 7e 0a 1b	mul	w10, w20, w10
10230a9f8:	2b c1 35 cb	sub	x11, x9, w21, sxtw
10230a9fc:	4a 7d 40 93	sxtw	x10, w10
10230aa00:	2c 01 0a 4b	sub	w12, w9, w10
10230aa04:	3f 01 0a eb	cmp	x9, x10
10230aa08:	2d 91 8a 9a	csel	x13, x9, x10, ls
10230aa0c:	ec 93 8c 1a	csel	w12, wzr, w12, ls
10230aa10:	7f 01 0a eb	cmp	x11, x10
10230aa14:	4a 81 8d 9a	csel	x10, x10, x13, hi
10230aa18:	ab 82 8c 1a	csel	w11, w21, w12, hi
10230aa1c:	3f 03 00 72	tst	w25, #0x1
10230aa20:	29 11 8a 9a	csel	x9, x9, x10, ne
10230aa24:	ea 13 8b 1a	csel	w10, wzr, w11, ne
10230aa28:	1f 01 00 71	cmp	w8, #0x0
10230aa2c:	b5 02 8a 1a	csel	w21, w21, w10, eq
10230aa30:	fa 03 89 9a	csel	x26, xzr, x9, eq
10230aa34:	fb 03 19 aa	mov	x27, x25
10230aa38:	e0 03 16 aa	mov	x0, x22
10230aa3c:	fc 23 00 f9	str	x28, [sp, #0x40]
10230aa40:	eb 38 15 94	bl	__ZNK6rbxfrm15ReaderOwnerTmplINS_6Float2EE13getChannelNumEv
10230aa44:	e0 4f 00 b9	str	w0, [sp, #0x4c]
10230aa48:	e0 03 16 aa	mov	x0, x22
10230aa4c:	b3 37 15 94	bl	__ZNK6rbxfrm15ReaderOwnerTmplINS_6Float2EE17getFileSampleRateEv
10230aa50:	e0 0f 00 f9	str	x0, [sp, #0x18]
10230aa54:	e0 03 16 aa	mov	x0, x22
10230aa58:	95 38 15 94	bl	__ZNK6rbxfrm15ReaderOwnerTmplINS_6Float2EE10getBitRateEv
10230aa5c:	f7 03 00 aa	mov	x23, x0
10230aa60:	e0 03 16 aa	mov	x0, x22
10230aa64:	42 38 15 94	bl	__ZNK6rbxfrm15ReaderOwnerTmplINS_6Float2EE10getBitSizeEv
10230aa68:	f3 03 00 aa	mov	x19, x0
10230aa6c:	48 f7 7e d3	lsl	x8, x26, #2
10230aa70:	ff fb 5a eb	cmp	xzr, x26, lsr #62
10230aa74:	14 01 9f da	csinv	x20, x8, xzr, eq
10230aa78:	e0 03 14 aa	mov	x0, x20
10230aa7c:	12 1c 47 94	bl	0x1034d1ac4 ; symbol stub for: __Znam
10230aa80:	e0 2f 00 f9	str	x0, [sp, #0x58]
10230aa84:	f7 0b 00 f9	str	x23, [sp, #0x10]
10230aa88:	f3 0f 00 b9	str	w19, [sp, #0xc]
10230aa8c:	e0 03 14 aa	mov	x0, x20
10230aa90:	0d 1c 47 94	bl	0x1034d1ac4 ; symbol stub for: __Znam
10230aa94:	e0 2b 00 f9	str	x0, [sp, #0x50]
10230aa98:	13 40 80 52	mov	w19, #0x200
10230aa9c:	00 40 80 52	mov	w0, #0x200
10230aaa0:	81 00 80 52	mov	w1, #0x4
10230aaa4:	ce 1c 47 94	bl	0x1034d1ddc ; symbol stub for: _calloc
10230aaa8:	f7 03 00 aa	mov	x23, x0
10230aaac:	00 40 80 52	mov	w0, #0x200
10230aab0:	81 00 80 52	mov	w1, #0x4
10230aab4:	ca 1c 47 94	bl	0x1034d1ddc ; symbol stub for: _calloc
10230aab8:	e0 33 00 f9	str	x0, [sp, #0x60]
10230aabc:	16 00 80 52	mov	w22, #0x0
10230aac0:	04 40 80 52	mov	w4, #0x200
10230aac4:	12 00 00 14	b	0x10230ab0c
10230aac8:	e9 2b 40 f9	ldr	x9, [sp, #0x50]
10230aacc:	20 01 18 8b	add	x0, x9, x24
10230aad0:	19 f5 7e d3	lsl	x25, x8, #2
10230aad4:	e1 03 17 aa	mov	x1, x23
10230aad8:	e2 03 19 aa	mov	x2, x25
10230aadc:	d9 1e 47 94	bl	0x1034d2640 ; symbol stub for: _memcpy
10230aae0:	e8 2f 40 f9	ldr	x8, [sp, #0x58]
10230aae4:	00 01 18 8b	add	x0, x8, x24
10230aae8:	e1 03 17 aa	mov	x1, x23
10230aaec:	e2 03 19 aa	mov	x2, x25
10230aaf0:	d4 1e 47 94	bl	0x1034d2640 ; symbol stub for: _memcpy
10230aaf4:	96 02 16 0b	add	w22, w20, w22
10230aaf8:	df 02 1a 6b	cmp	w22, w26
10230aafc:	ea 03 00 54	b.ge	0x10230ab78
10230ab00:	48 c3 36 cb	sub	x8, x26, w22, sxtw
10230ab04:	1f 01 08 f1	cmp	x8, #0x200
10230ab08:	04 31 93 9a	csel	x4, x8, x19, lo
10230ab0c:	c1 02 15 0b	add	w1, w22, w21
10230ab10:	e0 03 1c aa	mov	x0, x28
10230ab14:	e2 03 17 aa	mov	x2, x23
10230ab18:	e3 33 40 f9	ldr	x3, [sp, #0x60]
10230ab1c:	5f 25 15 94	bl	__ZN6rbxfrm17PcmReaderTemplateINS_6Float2EE11getStreamAtEiPfS3_i
10230ab20:	f4 03 00 aa	mov	x20, x0
10230ab24:	1f 04 00 71	cmp	w0, #0x1
10230ab28:	8b 02 00 54	b.lt	0x10230ab78
10230ab2c:	d8 7e 7e 93	sbfiz	x24, x22, #2, #32
10230ab30:	e8 03 14 2a	mov	w8, w20
10230ab34:	e9 4f 40 b9	ldr	w9, [sp, #0x4c]
10230ab38:	3f 09 00 71	cmp	w9, #0x2
10230ab3c:	61 fc ff 54	b.ne	0x10230aac8
10230ab40:	e9 2f 40 f9	ldr	x9, [sp, #0x58]
10230ab44:	20 01 18 8b	add	x0, x9, x24
10230ab48:	19 f5 7e d3	lsl	x25, x8, #2
10230ab4c:	e1 03 17 aa	mov	x1, x23
10230ab50:	e2 03 19 aa	mov	x2, x25
10230ab54:	bb 1e 47 94	bl	0x1034d2640 ; symbol stub for: _memcpy
10230ab58:	e8 2b 40 f9	ldr	x8, [sp, #0x50]
10230ab5c:	00 01 18 8b	add	x0, x8, x24
10230ab60:	e1 33 40 f9	ldr	x1, [sp, #0x60]
10230ab64:	e2 03 19 aa	mov	x2, x25
10230ab68:	b6 1e 47 94	bl	0x1034d2640 ; symbol stub for: _memcpy
10230ab6c:	96 02 16 0b	add	w22, w20, w22
10230ab70:	df 02 1a 6b	cmp	w22, w26
10230ab74:	6b fc ff 54	b.lt	0x10230ab00
10230ab78:	e0 c3 03 91	add	x0, sp, #0xf0
10230ab7c:	e1 17 40 f9	ldr	x1, [sp, #0x28]
10230ab80:	34 83 06 94	bl	__ZN4juce6StringC1ERKS0_
10230ab84:	e0 a3 03 91	add	x0, sp, #0xe8
10230ab88:	e1 1b 40 f9	ldr	x1, [sp, #0x30]
10230ab8c:	31 83 06 94	bl	__ZN4juce6StringC1ERKS0_
10230ab90:	a8 83 03 d1	sub	x8, x29, #0xe0
10230ab94:	e0 c3 03 91	add	x0, sp, #0xf0
10230ab98:	e1 a3 03 91	add	x1, sp, #0xe8
10230ab9c:	e3 0b 45 a9	ldp	x3, x2, [sp, #0x50]
10230aba0:	f3 1f 40 f9	ldr	x19, [sp, #0x38]
10230aba4:	e4 03 13 aa	mov	x4, x19
10230aba8:	e5 03 1a aa	mov	x5, x26
10230abac:	e6 03 1b aa	mov	x6, x27
10230abb0:	f7 f4 ff 97	bl	__ZN6madmom7analyzeEN4juce6StringES1_PfS2_ixb
10230abb4:	e0 a3 03 91	add	x0, sp, #0xe8
10230abb8:	d1 7e 06 94	bl	__ZN4juce6StringD1Ev
10230abbc:	e0 c3 03 91	add	x0, sp, #0xf0
10230abc0:	cf 7e 06 94	bl	__ZN4juce6StringD1Ev
10230abc4:	88 88 95 52	mov	w8, #0xac44
10230abc8:	7f 02 08 6b	cmp	w19, w8
10230abcc:	00 07 00 54	b.eq	0x10230acac
10230abd0:	a8 27 72 a9	ldp	x8, x9, [x29, #-0xe0]
10230abd4:	29 01 08 eb	subs	x9, x9, x8
10230abd8:	a0 06 00 54	b.eq	0x10230acac
10230abdc:	29 fd 43 93	asr	x9, x9, #3
10230abe0:	60 02 22 1e	scvtf	s0, w19
10230abe4:	3f 05 00 f1	cmp	x9, #0x1
10230abe8:	29 85 9f 9a	csinc	x9, x9, xzr, hi
10230abec:	3f 11 00 f1	cmp	x9, #0x4
10230abf0:	68 01 00 54	b.hi	0x10230ac1c
10230abf4:	0a 00 80 d2	mov	x10, #0x0
10230abf8:	20 00 00 14	b	0x10230ac78
10230abfc:	e0 7f 40 f9	ldr	x0, [sp, #0xf8]
10230ac00:	ae 1b 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10230ac04:	a8 73 d3 38	ldursb	w8, [x29, #-0xc9]
10230ac08:	f4 1f 40 f9	ldr	x20, [sp, #0x38]
10230ac0c:	08 ed ff 36	tbz	w8, #0x1f, 0x10230a9ac
10230ac10:	a0 03 52 f8	ldur	x0, [x29, #-0xe0]
10230ac14:	a9 1b 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10230ac18:	65 ff ff 17	b	0x10230a9ac
10230ac1c:	2a 05 40 f2	ands	x10, x9, #0x3
10230ac20:	8b 00 80 52	mov	w11, #0x4
10230ac24:	6a 01 8a 9a	csel	x10, x11, x10, eq
10230ac28:	2a 01 0a cb	sub	x10, x9, x10
10230ac2c:	0b 80 88 52	mov	w11, #0x4400
10230ac30:	8b e5 a8 72	movk	w11, #0x472c, lsl #16
10230ac34:	61 01 27 1e	fmov	s1, w11
10230ac38:	eb 03 0a aa	mov	x11, x10
10230ac3c:	ed 03 08 aa	mov	x13, x8
10230ac40:	ec 03 08 aa	mov	x12, x8
10230ac44:	21 18 20 1e	fdiv	s1, s1, s0
10230ac48:	ae 21 00 91	add	x14, x13, #0x8
10230ac4c:	82 89 df 4c	ld2.4s	{ v2, v3 }, [x12], #32
10230ac50:	af 41 00 91	add	x15, x13, #0x10
10230ac54:	b0 61 00 91	add	x16, x13, #0x18
10230ac58:	42 90 81 4f	fmul.4s	v2, v2, v1[0]
10230ac5c:	a2 01 00 bd	str	s2, [x13]
10230ac60:	c2 91 00 0d	st1.s	{ v2 }[1], [x14]
10230ac64:	e2 81 00 4d	st1.s	{ v2 }[2], [x15]
10230ac68:	02 92 00 4d	st1.s	{ v2 }[3], [x16]
10230ac6c:	ed 03 0c aa	mov	x13, x12
10230ac70:	6b 11 00 f1	subs	x11, x11, #0x4
10230ac74:	a1 fe ff 54	b.ne	0x10230ac48
10230ac78:	01 10 2e 1e	fmov	s1, #1.00000000
10230ac7c:	08 0d 0a 8b	add	x8, x8, x10, lsl #3
10230ac80:	29 01 0a cb	sub	x9, x9, x10
10230ac84:	0a 80 88 52	mov	w10, #0x4400
10230ac88:	8a e5 a8 72	movk	w10, #0x472c, lsl #16
10230ac8c:	20 18 20 1e	fdiv	s0, s1, s0
10230ac90:	01 01 40 bd	ldr	s1, [x8]
10230ac94:	42 01 27 1e	fmov	s2, w10
10230ac98:	21 08 22 1e	fmul	s1, s1, s2
10230ac9c:	21 08 20 1e	fmul	s1, s1, s0
10230aca0:	01 85 00 bc	str	s1, [x8], #0x8
10230aca4:	29 05 00 f1	subs	x9, x9, #0x1
10230aca8:	41 ff ff 54	b.ne	0x10230ac90
10230acac:	5b 52 00 34	cbz	w27, 0x10230b6f4
10230acb0:	88 07 80 52	mov	w8, #0x3c
10230acb4:	ec 1f 40 f9	ldr	x12, [sp, #0x38]
10230acb8:	88 7d 08 1b	mul	w8, w12, w8
10230acbc:	09 7d 40 93	sxtw	x9, w8
10230acc0:	49 0b c9 9a	udiv	x9, x26, x9
10230acc4:	39 05 00 51	sub	w25, w9, #0x1
10230acc8:	2a 7f 08 1b	mul	w10, w25, w8
10230accc:	3f 01 00 71	cmp	w9, #0x0
10230acd0:	08 c1 9a 1a	csel	w8, w8, w26, gt
10230acd4:	58 c1 9f 1a	csel	w24, w10, wzr, gt
10230acd8:	0a 01 18 0b	add	w10, w8, w24
10230acdc:	4a 03 0a 4b	sub	w10, w26, w10
10230ace0:	cb 03 80 52	mov	w11, #0x1e
10230ace4:	8b 7d 0b 1b	mul	w11, w12, w11
10230ace8:	4c c3 38 cb	sub	x12, x26, w24, sxtw
10230acec:	5f 01 0b 6b	cmp	w10, w11
10230acf0:	44 b9 40 7a	ccmp	w10, #0x0, #0x4, lt
10230acf4:	24 c9 40 7a	ccmp	w9, #0x0, #0x4, gt
10230acf8:	8a fd 41 d3	lsr	x10, x12, #1
10230acfc:	48 c1 88 1a	csel	w8, w10, w8, gt
10230ad00:	e8 33 00 b9	str	w8, [sp, #0x30]
10230ad04:	3f 05 00 71	cmp	w9, #0x1
10230ad08:	ad 20 00 54	b.le	0x10230b11c
10230ad0c:	1b 00 80 52	mov	w27, #0x0
10230ad10:	88 66 01 0f	movi.2s	v8, #0x34, lsl #24
10230ad14:	09 e4 00 2f	movi	d9, #0000000000000000
10230ad18:	0a 10 2c 1e	fmov	s10, #0.50000000
10230ad1c:	0b 90 21 1e	fmov	s11, #3.50000000
10230ad20:	0d 10 2d 1e	fmov	s13, #0.75000000
10230ad24:	34 00 80 52	mov	w20, #0x1
10230ad28:	0a 00 00 14	b	0x10230ad50
10230ad2c:	ef 03 0d aa	mov	x15, x13
10230ad30:	e8 01 0d cb	sub	x8, x15, x13
10230ad34:	2a 00 80 52	mov	w10, #0x1
10230ad38:	29 0d 0a 8b	add	x9, x9, x10, lsl #3
10230ad3c:	28 01 08 8b	add	x8, x9, x8
10230ad40:	a8 83 12 f8	stur	x8, [x29, #-0xd8]
10230ad44:	7b 07 00 11	add	w27, w27, #0x1
10230ad48:	7f 03 19 6b	cmp	w27, w25
10230ad4c:	80 1e 00 54	b.eq	0x10230b11c
10230ad50:	aa 23 72 a9	ldp	x10, x8, [x29, #-0xe0]
10230ad54:	0b 01 0a eb	subs	x11, x8, x10
10230ad58:	60 ff ff 54	b.eq	0x10230ad44
10230ad5c:	0e 00 80 d2	mov	x14, #0x0
10230ad60:	69 fd 43 93	asr	x9, x11, #3
10230ad64:	6c 07 00 11	add	w12, w27, #0x1
10230ad68:	80 01 22 1e	scvtf	s0, w12
10230ad6c:	0c 4e a8 52	mov	w12, #0x42700000
10230ad70:	81 01 27 1e	fmov	s1, w12
10230ad74:	3f 05 00 f1	cmp	x9, #0x1
10230ad78:	00 08 21 1e	fmul	s0, s0, s1
10230ad7c:	2f 85 9f 9a	csinc	x15, x9, xzr, hi
10230ad80:	0c 00 80 12	mov	w12, #-0x1
10230ad84:	f0 03 0a aa	mov	x16, x10
10230ad88:	0d 00 80 12	mov	w13, #-0x1
10230ad8c:	01 02 40 bd	ldr	s1, [x16]
10230ad90:	20 20 20 1e	fcmp	s1, s0
10230ad94:	0a 01 00 54	b.ge	0x10230adb4
10230ad98:	ce 05 00 91	add	x14, x14, #0x1
10230ad9c:	ad 05 00 91	add	x13, x13, #0x1
10230ada0:	10 22 00 91	add	x16, x16, #0x8
10230ada4:	8c 05 00 11	add	w12, w12, #0x1
10230ada8:	ff 01 0e eb	cmp	x15, x14
10230adac:	01 ff ff 54	b.ne	0x10230ad8c
10230adb0:	e5 ff ff 17	b	0x10230ad44
10230adb4:	df 09 00 71	cmp	w14, #0x2
10230adb8:	6b fc ff 54	b.lt	0x10230ad44
10230adbc:	cf 05 00 11	add	w15, w14, #0x1
10230adc0:	3f 01 0f eb	cmp	x9, x15
10230adc4:	09 fc ff 54	b.ls	0x10230ad44
10230adc8:	a9 05 00 51	sub	w9, w13, #0x1
10230adcc:	29 f1 7d d3	lsl	x9, x9, #3
10230add0:	40 69 69 bc	ldr	s0, [x10, x9]
10230add4:	49 4d 2d 8b	add	x9, x10, w13, uxtw #3
10230add8:	2e 01 40 bd	ldr	s14, [x9]
10230addc:	ce 7d 40 92	and	x14, x14, #0xffffffff
10230ade0:	ce f1 7d d3	lsl	x14, x14, #3
10230ade4:	4f 69 6e bc	ldr	s15, [x10, x14]
10230ade8:	ee f1 7d d3	lsl	x14, x15, #3
10230adec:	4e 69 6e b8	ldr	w14, [x10, x14]
10230adf0:	c0 39 20 1e	fsub	s0, s14, s0
10230adf4:	ec 39 2e 1e	fsub	s12, s15, s14
10230adf8:	81 19 20 1e	fdiv	s1, s12, s0
10230adfc:	00 20 28 1e	fcmp	s0, s8
10230ae00:	20 cc 29 1e	fcsel	s0, s1, s9, gt
10230ae04:	80 21 28 1e	fcmp	s12, s8
10230ae08:	c1 01 27 1e	fmov	s1, w14
10230ae0c:	21 38 2f 1e	fsub	s1, s1, s15
10230ae10:	21 18 2c 1e	fdiv	s1, s1, s12
10230ae14:	21 dd 21 1e	fcsel	s1, s9, s1, le
10230ae18:	02 28 2a 1e	fadd	s2, s0, s10
10230ae1c:	4f 00 38 1e	fcvtzs	w15, s2
10230ae20:	ff 09 00 71	cmp	w15, #0x2
10230ae24:	b0 99 99 52	mov	w16, #0xcccd
10230ae28:	90 f5 a7 72	movk	w16, #0x3fac, lsl #16
10230ae2c:	02 02 27 1e	fmov	s2, w16
10230ae30:	08 a4 22 1e	fccmp	s0, s2, #0x8, ge
10230ae34:	00 a4 2b 1e	fccmp	s0, s11, #0x0, ge
10230ae38:	02 10 2a 1e	fmov	s2, #0.25000000
10230ae3c:	28 d4 22 1e	fccmp	s1, s2, #0x8, le
10230ae40:	20 a4 2d 1e	fccmp	s1, s13, #0x0, ge
10230ae44:	8d 05 00 54	b.le	0x10230aef4
10230ae48:	22 28 2a 1e	fadd	s2, s1, s10
10230ae4c:	4f 00 38 1e	fcvtzs	w15, s2
10230ae50:	ff 09 00 71	cmp	w15, #0x2
10230ae54:	eb 07 00 54	b.lt	0x10230af50
10230ae58:	d0 cc 8c 52	mov	w16, #0x6666
10230ae5c:	d0 ec a7 72	movk	w16, #0x3f66, lsl #16
10230ae60:	02 02 27 1e	fmov	s2, w16
10230ae64:	00 20 22 1e	fcmp	s0, s2
10230ae68:	b0 99 99 52	mov	w16, #0xcccd
10230ae6c:	90 f1 a7 72	movk	w16, #0x3f8c, lsl #16
10230ae70:	02 02 27 1e	fmov	s2, w16
10230ae74:	00 a4 22 1e	fccmp	s0, s2, #0x0, ge
10230ae78:	b0 99 99 52	mov	w16, #0xcccd
10230ae7c:	90 f5 a7 72	movk	w16, #0x3fac, lsl #16
10230ae80:	02 02 27 1e	fmov	s2, w16
10230ae84:	28 d4 22 1e	fccmp	s1, s2, #0x8, le
10230ae88:	20 a4 2b 1e	fccmp	s1, s11, #0x0, ge
10230ae8c:	2c 06 00 54	b.gt	0x10230af50
10230ae90:	c0 01 27 1e	fmov	s0, w14
10230ae94:	0c 38 2f 1e	fsub	s12, s0, s15
10230ae98:	e0 01 22 1e	scvtf	s0, w15
10230ae9c:	f3 05 00 51	sub	w19, w15, #0x1
10230aea0:	01 10 2e 1e	fmov	s1, #1.00000000
10230aea4:	2e 18 20 1e	fdiv	s14, s1, s0
10230aea8:	e8 03 0c 2a	mov	w8, w12
10230aeac:	08 f1 7d d3	lsl	x8, x8, #3
10230aeb0:	15 41 00 91	add	x21, x8, #0x10
10230aeb4:	36 00 80 52	mov	w22, #0x1
10230aeb8:	c0 02 22 1e	scvtf	s0, w22
10230aebc:	80 09 20 1e	fmul	s0, s12, s0
10230aec0:	00 3c 0e 1f	fmadd	s0, s0, s14, s15
10230aec4:	e0 fb 00 bd	str	s0, [sp, #0xf8]
10230aec8:	f4 ff 00 b9	str	w20, [sp, #0xfc]
10230aecc:	a1 02 0a 8b	add	x1, x21, x10
10230aed0:	a0 83 03 d1	sub	x0, x29, #0xe0
10230aed4:	e2 e3 03 91	add	x2, sp, #0xf8
10230aed8:	74 03 00 94	bl	__ZNSt3__16vectorINS_4pairIfiEENS_9allocatorIS2_EEE6insertENS_11__wrap_iterIPKS2_EERS7_
10230aedc:	7f 02 16 eb	cmp	x19, x22
10230aee0:	20 f3 ff 54	b.eq	0x10230ad44
10230aee4:	aa 03 52 f8	ldur	x10, [x29, #-0xe0]
10230aee8:	b5 22 00 91	add	x21, x21, #0x8
10230aeec:	d6 06 00 91	add	x22, x22, #0x1
10230aef0:	f2 ff ff 17	b	0x10230aeb8
10230aef4:	e0 01 22 1e	scvtf	s0, w15
10230aef8:	f3 05 00 51	sub	w19, w15, #0x1
10230aefc:	01 10 2e 1e	fmov	s1, #1.00000000
10230af00:	2f 18 20 1e	fdiv	s15, s1, s0
10230af04:	e8 03 0c 2a	mov	w8, w12
10230af08:	08 f1 7d d3	lsl	x8, x8, #3
10230af0c:	15 21 00 91	add	x21, x8, #0x8
10230af10:	36 00 80 52	mov	w22, #0x1
10230af14:	c0 02 22 1e	scvtf	s0, w22
10230af18:	80 09 20 1e	fmul	s0, s12, s0
10230af1c:	00 38 0f 1f	fmadd	s0, s0, s15, s14
10230af20:	e0 fb 00 bd	str	s0, [sp, #0xf8]
10230af24:	f4 ff 00 b9	str	w20, [sp, #0xfc]
10230af28:	a1 02 0a 8b	add	x1, x21, x10
10230af2c:	a0 83 03 d1	sub	x0, x29, #0xe0
10230af30:	e2 e3 03 91	add	x2, sp, #0xf8
10230af34:	5d 03 00 94	bl	__ZNSt3__16vectorINS_4pairIfiEENS_9allocatorIS2_EEE6insertENS_11__wrap_iterIPKS2_EERS7_
10230af38:	7f 02 16 eb	cmp	x19, x22
10230af3c:	40 f0 ff 54	b.eq	0x10230ad44
10230af40:	aa 03 52 f8	ldur	x10, [x29, #-0xe0]
10230af44:	b5 22 00 91	add	x21, x21, #0x8
10230af48:	d6 06 00 91	add	x22, x22, #0x1
10230af4c:	f2 ff ff 17	b	0x10230af14
10230af50:	af 7d 40 92	and	x15, x13, #0xffffffff
10230af54:	4d 33 93 52	mov	w13, #0x999a
10230af58:	2d d3 a7 72	movk	w13, #0x3e99, lsl #16
10230af5c:	a2 01 27 1e	fmov	s2, w13
10230af60:	00 20 22 1e	fcmp	s0, s2
10230af64:	6a 01 00 54	b.ge	0x10230af90
10230af68:	2d 21 00 91	add	x13, x9, #0x8
10230af6c:	2e 41 00 91	add	x14, x9, #0x10
10230af70:	df 01 08 eb	cmp	x14, x8
10230af74:	c0 ed ff 54	b.eq	0x10230ad2c
10230af78:	6f 0d 0f cb	sub	x15, x11, x15, lsl #3
10230af7c:	ef 61 00 d1	sub	x15, x15, #0x18
10230af80:	ff e1 01 f1	cmp	x15, #0x78
10230af84:	02 02 00 54	b.hs	0x10230afc4
10230af88:	ef 03 0d aa	mov	x15, x13
10230af8c:	2e 00 00 14	b	0x10230b044
10230af90:	a0 01 27 1e	fmov	s0, w13
10230af94:	20 20 20 1e	fcmp	s1, s0
10230af98:	6a ed ff 54	b.ge	0x10230ad44
10230af9c:	2d 41 00 91	add	x13, x9, #0x10
10230afa0:	2e 61 00 91	add	x14, x9, #0x18
10230afa4:	df 01 08 eb	cmp	x14, x8
10230afa8:	00 06 00 54	b.eq	0x10230b068
10230afac:	6f 0d 0f cb	sub	x15, x11, x15, lsl #3
10230afb0:	ef 81 00 d1	sub	x15, x15, #0x20
10230afb4:	ff e1 01 f1	cmp	x15, #0x78
10230afb8:	c2 05 00 54	b.hs	0x10230b070
10230afbc:	ef 03 0d aa	mov	x15, x13
10230afc0:	4c 00 00 14	b	0x10230b0f0
10230afc4:	ef fd 43 d3	lsr	x15, x15, #3
10230afc8:	f0 05 00 91	add	x16, x15, #0x1
10230afcc:	11 e6 7c 92	and	x17, x16, #0x3ffffffffffffff0
10230afd0:	20 f2 7d d3	lsl	x0, x17, #3
10230afd4:	af 01 00 8b	add	x15, x13, x0
10230afd8:	ce 01 00 8b	add	x14, x14, x0
10230afdc:	ec 03 0c 2a	mov	w12, w12
10230afe0:	8c f1 7d d3	lsl	x12, x12, #3
10230afe4:	6b 01 0c cb	sub	x11, x11, x12
10230afe8:	6b 61 00 d1	sub	x11, x11, #0x18
10230afec:	6b fd 43 d3	lsr	x11, x11, #3
10230aff0:	6b 05 00 91	add	x11, x11, #0x1
10230aff4:	6b e5 7c 92	and	x11, x11, #0x3ffffffffffffff0
10230aff8:	4a 01 0c 8b	add	x10, x10, x12
10230affc:	4a 21 01 91	add	x10, x10, #0x48
10230b000:	40 81 dd 3c	ldur	q0, [x10, #-0x28]
10230b004:	41 81 dc 3c	ldur	q1, [x10, #-0x38]
10230b008:	42 81 df 3c	ldur	q2, [x10, #-0x8]
10230b00c:	43 81 de 3c	ldur	q3, [x10, #-0x18]
10230b010:	44 81 c1 3c	ldur	q4, [x10, #0x18]
10230b014:	45 81 c0 3c	ldur	q5, [x10, #0x8]
10230b018:	46 81 c3 3c	ldur	q6, [x10, #0x38]
10230b01c:	47 81 c2 3c	ldur	q7, [x10, #0x28]
10230b020:	41 01 3e ad	stp	q1, q0, [x10, #-0x40]
10230b024:	43 09 3f ad	stp	q3, q2, [x10, #-0x20]
10230b028:	45 11 00 ad	stp	q5, q4, [x10]
10230b02c:	47 19 01 ad	stp	q7, q6, [x10, #0x20]
10230b030:	4a 01 02 91	add	x10, x10, #0x80
10230b034:	6b 41 00 f1	subs	x11, x11, #0x10
10230b038:	41 fe ff 54	b.ne	0x10230b000
10230b03c:	1f 02 11 eb	cmp	x16, x17
10230b040:	80 e7 ff 54	b.eq	0x10230ad30
10230b044:	c0 01 40 bd	ldr	s0, [x14]
10230b048:	e0 01 00 bd	str	s0, [x15]
10230b04c:	ca 05 40 b9	ldr	w10, [x14, #0x4]
10230b050:	ea 05 00 b9	str	w10, [x15, #0x4]
10230b054:	ef 21 00 91	add	x15, x15, #0x8
10230b058:	ce 21 00 91	add	x14, x14, #0x8
10230b05c:	df 01 08 eb	cmp	x14, x8
10230b060:	21 ff ff 54	b.ne	0x10230b044
10230b064:	33 ff ff 17	b	0x10230ad30
10230b068:	ef 03 0d aa	mov	x15, x13
10230b06c:	29 00 00 14	b	0x10230b110
10230b070:	ef fd 43 d3	lsr	x15, x15, #3
10230b074:	f0 05 00 91	add	x16, x15, #0x1
10230b078:	11 e6 7c 92	and	x17, x16, #0x3ffffffffffffff0
10230b07c:	20 f2 7d d3	lsl	x0, x17, #3
10230b080:	af 01 00 8b	add	x15, x13, x0
10230b084:	ce 01 00 8b	add	x14, x14, x0
10230b088:	ec 03 0c 2a	mov	w12, w12
10230b08c:	8c f1 7d d3	lsl	x12, x12, #3
10230b090:	6b 01 0c cb	sub	x11, x11, x12
10230b094:	6b 81 00 d1	sub	x11, x11, #0x20
10230b098:	6b fd 43 d3	lsr	x11, x11, #3
10230b09c:	6b 05 00 91	add	x11, x11, #0x1
10230b0a0:	6b e5 7c 92	and	x11, x11, #0x3ffffffffffffff0
10230b0a4:	4a 01 0c 8b	add	x10, x10, x12
10230b0a8:	4a 41 01 91	add	x10, x10, #0x50
10230b0ac:	40 81 dd 3c	ldur	q0, [x10, #-0x28]
10230b0b0:	41 81 dc 3c	ldur	q1, [x10, #-0x38]
10230b0b4:	42 81 df 3c	ldur	q2, [x10, #-0x8]
10230b0b8:	43 81 de 3c	ldur	q3, [x10, #-0x18]
10230b0bc:	44 81 c1 3c	ldur	q4, [x10, #0x18]
10230b0c0:	45 81 c0 3c	ldur	q5, [x10, #0x8]
10230b0c4:	46 81 c3 3c	ldur	q6, [x10, #0x38]
10230b0c8:	47 81 c2 3c	ldur	q7, [x10, #0x28]
10230b0cc:	41 01 3e ad	stp	q1, q0, [x10, #-0x40]
10230b0d0:	43 09 3f ad	stp	q3, q2, [x10, #-0x20]
10230b0d4:	45 11 00 ad	stp	q5, q4, [x10]
10230b0d8:	47 19 01 ad	stp	q7, q6, [x10, #0x20]
10230b0dc:	4a 01 02 91	add	x10, x10, #0x80
10230b0e0:	6b 41 00 f1	subs	x11, x11, #0x10
10230b0e4:	41 fe ff 54	b.ne	0x10230b0ac
10230b0e8:	1f 02 11 eb	cmp	x16, x17
10230b0ec:	20 01 00 54	b.eq	0x10230b110
10230b0f0:	c0 01 40 bd	ldr	s0, [x14]
10230b0f4:	e0 01 00 bd	str	s0, [x15]
10230b0f8:	ca 05 40 b9	ldr	w10, [x14, #0x4]
10230b0fc:	ea 05 00 b9	str	w10, [x15, #0x4]
10230b100:	ef 21 00 91	add	x15, x15, #0x8
10230b104:	ce 21 00 91	add	x14, x14, #0x8
10230b108:	df 01 08 eb	cmp	x14, x8
10230b10c:	21 ff ff 54	b.ne	0x10230b0f0
10230b110:	e8 01 0d cb	sub	x8, x15, x13
10230b114:	4a 00 80 52	mov	w10, #0x2
10230b118:	08 ff ff 17	b	0x10230ad38
10230b11c:	e9 33 40 b9	ldr	w9, [sp, #0x30]
10230b120:	3f 05 00 71	cmp	w9, #0x1
10230b124:	4b 20 00 54	b.lt	0x10230b52c
10230b128:	aa 23 72 a9	ldp	x10, x8, [x29, #-0xe0]
10230b12c:	0b 01 0a eb	subs	x11, x8, x10
10230b130:	e0 1f 00 54	b.eq	0x10230b52c
10230b134:	0d 00 80 d2	mov	x13, #0x0
10230b138:	29 01 18 0b	add	w9, w9, w24
10230b13c:	20 01 22 1e	scvtf	s0, w9
10230b140:	e9 1f 40 f9	ldr	x9, [sp, #0x38]
10230b144:	21 01 22 1e	scvtf	s1, w9
10230b148:	69 fd 43 93	asr	x9, x11, #3
10230b14c:	00 18 21 1e	fdiv	s0, s0, s1
10230b150:	3f 05 00 f1	cmp	x9, #0x1
10230b154:	2e 85 9f 9a	csinc	x14, x9, xzr, hi
10230b158:	0c 00 80 12	mov	w12, #-0x1
10230b15c:	ef 03 0a aa	mov	x15, x10
10230b160:	e1 01 40 bd	ldr	s1, [x15]
10230b164:	20 20 20 1e	fcmp	s1, s0
10230b168:	ea 00 00 54	b.ge	0x10230b184
10230b16c:	ad 05 00 91	add	x13, x13, #0x1
10230b170:	8c 05 00 91	add	x12, x12, #0x1
10230b174:	ef 21 00 91	add	x15, x15, #0x8
10230b178:	df 01 0d eb	cmp	x14, x13
10230b17c:	21 ff ff 54	b.ne	0x10230b160
10230b180:	eb 00 00 14	b	0x10230b52c
10230b184:	bf 09 00 71	cmp	w13, #0x2
10230b188:	2b 1d 00 54	b.lt	0x10230b52c
10230b18c:	ae 05 00 11	add	w14, w13, #0x1
10230b190:	3f 01 0e eb	cmp	x9, x14
10230b194:	c9 1c 00 54	b.ls	0x10230b52c
10230b198:	89 05 00 51	sub	w9, w12, #0x1
10230b19c:	29 f1 7d d3	lsl	x9, x9, #3
10230b1a0:	40 69 69 bc	ldr	s0, [x10, x9]
10230b1a4:	49 4d 2c 8b	add	x9, x10, w12, uxtw #3
10230b1a8:	ad 7d 40 92	and	x13, x13, #0xffffffff
10230b1ac:	ad f1 7d d3	lsl	x13, x13, #3
10230b1b0:	48 69 6d bc	ldr	s8, [x10, x13]
10230b1b4:	29 01 40 bd	ldr	s9, [x9]
10230b1b8:	cd f1 7d d3	lsl	x13, x14, #3
10230b1bc:	4d 69 6d b8	ldr	w13, [x10, x13]
10230b1c0:	20 39 20 1e	fsub	s0, s9, s0
10230b1c4:	0a 39 29 1e	fsub	s10, s8, s9
10230b1c8:	41 19 20 1e	fdiv	s1, s10, s0
10230b1cc:	82 66 01 0f	movi.2s	v2, #0x34, lsl #24
10230b1d0:	00 20 22 1e	fcmp	s0, s2
10230b1d4:	00 e4 00 2f	movi	d0, #0000000000000000
10230b1d8:	21 cc 20 1e	fcsel	s1, s1, s0, gt
10230b1dc:	40 21 22 1e	fcmp	s10, s2
10230b1e0:	a2 01 27 1e	fmov	s2, w13
10230b1e4:	42 38 28 1e	fsub	s2, s2, s8
10230b1e8:	42 18 2a 1e	fdiv	s2, s2, s10
10230b1ec:	00 dc 22 1e	fcsel	s0, s0, s2, le
10230b1f0:	02 10 2c 1e	fmov	s2, #0.50000000
10230b1f4:	23 28 22 1e	fadd	s3, s1, s2
10230b1f8:	6e 00 38 1e	fcvtzs	w14, s3
10230b1fc:	df 09 00 71	cmp	w14, #0x2
10230b200:	af 99 99 52	mov	w15, #0xcccd
10230b204:	8f f5 a7 72	movk	w15, #0x3fac, lsl #16
10230b208:	e3 01 27 1e	fmov	s3, w15
10230b20c:	28 a4 23 1e	fccmp	s1, s3, #0x8, ge
10230b210:	03 90 21 1e	fmov	s3, #3.50000000
10230b214:	20 a4 23 1e	fccmp	s1, s3, #0x0, ge
10230b218:	03 10 2a 1e	fmov	s3, #0.25000000
10230b21c:	08 d4 23 1e	fccmp	s0, s3, #0x8, le
10230b220:	03 10 2d 1e	fmov	s3, #0.75000000
10230b224:	00 a4 23 1e	fccmp	s0, s3, #0x0, ge
10230b228:	cd 05 00 54	b.le	0x10230b2e0
10230b22c:	02 28 22 1e	fadd	s2, s0, s2
10230b230:	4e 00 38 1e	fcvtzs	w14, s2
10230b234:	df 09 00 71	cmp	w14, #0x2
10230b238:	4b 08 00 54	b.lt	0x10230b340
10230b23c:	cf cc 8c 52	mov	w15, #0x6666
10230b240:	cf ec a7 72	movk	w15, #0x3f66, lsl #16
10230b244:	e2 01 27 1e	fmov	s2, w15
10230b248:	20 20 22 1e	fcmp	s1, s2
10230b24c:	af 99 99 52	mov	w15, #0xcccd
10230b250:	8f f1 a7 72	movk	w15, #0x3f8c, lsl #16
10230b254:	e2 01 27 1e	fmov	s2, w15
10230b258:	20 a4 22 1e	fccmp	s1, s2, #0x0, ge
10230b25c:	af 99 99 52	mov	w15, #0xcccd
10230b260:	8f f5 a7 72	movk	w15, #0x3fac, lsl #16
10230b264:	e2 01 27 1e	fmov	s2, w15
10230b268:	08 d4 22 1e	fccmp	s0, s2, #0x8, le
10230b26c:	02 90 21 1e	fmov	s2, #3.50000000
10230b270:	00 a4 22 1e	fccmp	s0, s2, #0x0, ge
10230b274:	6c 06 00 54	b.gt	0x10230b340
10230b278:	a0 01 27 1e	fmov	s0, w13
10230b27c:	09 38 28 1e	fsub	s9, s0, s8
10230b280:	c0 01 22 1e	scvtf	s0, w14
10230b284:	d3 05 00 51	sub	w19, w14, #0x1
10230b288:	01 10 2e 1e	fmov	s1, #1.00000000
10230b28c:	2a 18 20 1e	fdiv	s10, s1, s0
10230b290:	e8 03 0c 2a	mov	w8, w12
10230b294:	08 f1 7d d3	lsl	x8, x8, #3
10230b298:	14 41 00 91	add	x20, x8, #0x10
10230b29c:	35 00 80 52	mov	w21, #0x1
10230b2a0:	36 00 80 52	mov	w22, #0x1
10230b2a4:	c0 02 22 1e	scvtf	s0, w22
10230b2a8:	20 09 20 1e	fmul	s0, s9, s0
10230b2ac:	00 20 0a 1f	fmadd	s0, s0, s10, s8
10230b2b0:	e0 fb 00 bd	str	s0, [sp, #0xf8]
10230b2b4:	f5 ff 00 b9	str	w21, [sp, #0xfc]
10230b2b8:	81 02 0a 8b	add	x1, x20, x10
10230b2bc:	a0 83 03 d1	sub	x0, x29, #0xe0
10230b2c0:	e2 e3 03 91	add	x2, sp, #0xf8
10230b2c4:	79 02 00 94	bl	__ZNSt3__16vectorINS_4pairIfiEENS_9allocatorIS2_EEE6insertENS_11__wrap_iterIPKS2_EERS7_
10230b2c8:	7f 02 16 eb	cmp	x19, x22
10230b2cc:	00 13 00 54	b.eq	0x10230b52c
10230b2d0:	aa 03 52 f8	ldur	x10, [x29, #-0xe0]
10230b2d4:	94 22 00 91	add	x20, x20, #0x8
10230b2d8:	d6 06 00 91	add	x22, x22, #0x1
10230b2dc:	f2 ff ff 17	b	0x10230b2a4
10230b2e0:	c0 01 22 1e	scvtf	s0, w14
10230b2e4:	d3 05 00 51	sub	w19, w14, #0x1
10230b2e8:	01 10 2e 1e	fmov	s1, #1.00000000
10230b2ec:	28 18 20 1e	fdiv	s8, s1, s0
10230b2f0:	e8 03 0c 2a	mov	w8, w12
10230b2f4:	08 f1 7d d3	lsl	x8, x8, #3
10230b2f8:	14 21 00 91	add	x20, x8, #0x8
10230b2fc:	35 00 80 52	mov	w21, #0x1
10230b300:	36 00 80 52	mov	w22, #0x1
10230b304:	c0 02 22 1e	scvtf	s0, w22
10230b308:	40 09 20 1e	fmul	s0, s10, s0
10230b30c:	00 24 08 1f	fmadd	s0, s0, s8, s9
10230b310:	e0 fb 00 bd	str	s0, [sp, #0xf8]
10230b314:	f5 ff 00 b9	str	w21, [sp, #0xfc]
10230b318:	81 02 0a 8b	add	x1, x20, x10
10230b31c:	a0 83 03 d1	sub	x0, x29, #0xe0
10230b320:	e2 e3 03 91	add	x2, sp, #0xf8
10230b324:	61 02 00 94	bl	__ZNSt3__16vectorINS_4pairIfiEENS_9allocatorIS2_EEE6insertENS_11__wrap_iterIPKS2_EERS7_
10230b328:	7f 02 16 eb	cmp	x19, x22
10230b32c:	00 10 00 54	b.eq	0x10230b52c
10230b330:	aa 03 52 f8	ldur	x10, [x29, #-0xe0]
10230b334:	94 22 00 91	add	x20, x20, #0x8
10230b338:	d6 06 00 91	add	x22, x22, #0x1
10230b33c:	f2 ff ff 17	b	0x10230b304
10230b340:	8f 7d 40 92	and	x15, x12, #0xffffffff
10230b344:	4d 33 93 52	mov	w13, #0x999a
10230b348:	2d d3 a7 72	movk	w13, #0x3e99, lsl #16
10230b34c:	a2 01 27 1e	fmov	s2, w13
10230b350:	20 20 22 1e	fcmp	s1, s2
10230b354:	6a 01 00 54	b.ge	0x10230b380
10230b358:	2d 21 00 91	add	x13, x9, #0x8
10230b35c:	2e 41 00 91	add	x14, x9, #0x10
10230b360:	df 01 08 eb	cmp	x14, x8
10230b364:	c0 02 00 54	b.eq	0x10230b3bc
10230b368:	6f 0d 0f cb	sub	x15, x11, x15, lsl #3
10230b36c:	ef 61 00 d1	sub	x15, x15, #0x18
10230b370:	ff e1 01 f1	cmp	x15, #0x78
10230b374:	82 02 00 54	b.hs	0x10230b3c4
10230b378:	ef 03 0d aa	mov	x15, x13
10230b37c:	32 00 00 14	b	0x10230b444
10230b380:	4d 33 93 52	mov	w13, #0x999a
10230b384:	2d d3 a7 72	movk	w13, #0x3e99, lsl #16
10230b388:	a1 01 27 1e	fmov	s1, w13
10230b38c:	00 20 21 1e	fcmp	s0, s1
10230b390:	ea 0c 00 54	b.ge	0x10230b52c
10230b394:	2d 41 00 91	add	x13, x9, #0x10
10230b398:	2e 61 00 91	add	x14, x9, #0x18
10230b39c:	df 01 08 eb	cmp	x14, x8
10230b3a0:	80 06 00 54	b.eq	0x10230b470
10230b3a4:	6f 0d 0f cb	sub	x15, x11, x15, lsl #3
10230b3a8:	ef 81 00 d1	sub	x15, x15, #0x20
10230b3ac:	ff e1 01 f1	cmp	x15, #0x78
10230b3b0:	42 06 00 54	b.hs	0x10230b478
10230b3b4:	ef 03 0d aa	mov	x15, x13
10230b3b8:	50 00 00 14	b	0x10230b4f8
10230b3bc:	ef 03 0d aa	mov	x15, x13
10230b3c0:	29 00 00 14	b	0x10230b464
10230b3c4:	ef fd 43 d3	lsr	x15, x15, #3
10230b3c8:	f0 05 00 91	add	x16, x15, #0x1
10230b3cc:	11 e6 7c 92	and	x17, x16, #0x3ffffffffffffff0
10230b3d0:	20 f2 7d d3	lsl	x0, x17, #3
10230b3d4:	af 01 00 8b	add	x15, x13, x0
10230b3d8:	ce 01 00 8b	add	x14, x14, x0
10230b3dc:	ec 03 0c 2a	mov	w12, w12
10230b3e0:	8c f1 7d d3	lsl	x12, x12, #3
10230b3e4:	6b 01 0c cb	sub	x11, x11, x12
10230b3e8:	6b 61 00 d1	sub	x11, x11, #0x18
10230b3ec:	6b fd 43 d3	lsr	x11, x11, #3
10230b3f0:	6b 05 00 91	add	x11, x11, #0x1
10230b3f4:	6b e5 7c 92	and	x11, x11, #0x3ffffffffffffff0
10230b3f8:	4a 01 0c 8b	add	x10, x10, x12
10230b3fc:	4a 21 01 91	add	x10, x10, #0x48
10230b400:	40 81 dd 3c	ldur	q0, [x10, #-0x28]
10230b404:	41 81 dc 3c	ldur	q1, [x10, #-0x38]
10230b408:	42 81 df 3c	ldur	q2, [x10, #-0x8]
10230b40c:	43 81 de 3c	ldur	q3, [x10, #-0x18]
10230b410:	44 81 c1 3c	ldur	q4, [x10, #0x18]
10230b414:	45 81 c0 3c	ldur	q5, [x10, #0x8]
10230b418:	46 81 c3 3c	ldur	q6, [x10, #0x38]
10230b41c:	47 81 c2 3c	ldur	q7, [x10, #0x28]
10230b420:	41 01 3e ad	stp	q1, q0, [x10, #-0x40]
10230b424:	43 09 3f ad	stp	q3, q2, [x10, #-0x20]
10230b428:	45 11 00 ad	stp	q5, q4, [x10]
10230b42c:	47 19 01 ad	stp	q7, q6, [x10, #0x20]
10230b430:	4a 01 02 91	add	x10, x10, #0x80
10230b434:	6b 41 00 f1	subs	x11, x11, #0x10
10230b438:	41 fe ff 54	b.ne	0x10230b400
10230b43c:	1f 02 11 eb	cmp	x16, x17
10230b440:	20 01 00 54	b.eq	0x10230b464
10230b444:	c0 01 40 bd	ldr	s0, [x14]
10230b448:	e0 01 00 bd	str	s0, [x15]
10230b44c:	ca 05 40 b9	ldr	w10, [x14, #0x4]
10230b450:	ea 05 00 b9	str	w10, [x15, #0x4]
10230b454:	ef 21 00 91	add	x15, x15, #0x8
10230b458:	ce 21 00 91	add	x14, x14, #0x8
10230b45c:	df 01 08 eb	cmp	x14, x8
10230b460:	21 ff ff 54	b.ne	0x10230b444
10230b464:	e8 01 0d cb	sub	x8, x15, x13
10230b468:	2a 00 80 52	mov	w10, #0x1
10230b46c:	2d 00 00 14	b	0x10230b520
10230b470:	ef 03 0d aa	mov	x15, x13
10230b474:	29 00 00 14	b	0x10230b518
10230b478:	ef fd 43 d3	lsr	x15, x15, #3
10230b47c:	f0 05 00 91	add	x16, x15, #0x1
10230b480:	11 e6 7c 92	and	x17, x16, #0x3ffffffffffffff0
10230b484:	20 f2 7d d3	lsl	x0, x17, #3
10230b488:	af 01 00 8b	add	x15, x13, x0
10230b48c:	ce 01 00 8b	add	x14, x14, x0
10230b490:	ec 03 0c 2a	mov	w12, w12
10230b494:	8c f1 7d d3	lsl	x12, x12, #3
10230b498:	6b 01 0c cb	sub	x11, x11, x12
10230b49c:	6b 81 00 d1	sub	x11, x11, #0x20
10230b4a0:	6b fd 43 d3	lsr	x11, x11, #3
10230b4a4:	6b 05 00 91	add	x11, x11, #0x1
10230b4a8:	6b e5 7c 92	and	x11, x11, #0x3ffffffffffffff0
10230b4ac:	4a 01 0c 8b	add	x10, x10, x12
10230b4b0:	4a 41 01 91	add	x10, x10, #0x50
10230b4b4:	40 81 dd 3c	ldur	q0, [x10, #-0x28]
10230b4b8:	41 81 dc 3c	ldur	q1, [x10, #-0x38]
10230b4bc:	42 81 df 3c	ldur	q2, [x10, #-0x8]
10230b4c0:	43 81 de 3c	ldur	q3, [x10, #-0x18]
10230b4c4:	44 81 c1 3c	ldur	q4, [x10, #0x18]
10230b4c8:	45 81 c0 3c	ldur	q5, [x10, #0x8]
10230b4cc:	46 81 c3 3c	ldur	q6, [x10, #0x38]
10230b4d0:	47 81 c2 3c	ldur	q7, [x10, #0x28]
10230b4d4:	41 01 3e ad	stp	q1, q0, [x10, #-0x40]
10230b4d8:	43 09 3f ad	stp	q3, q2, [x10, #-0x20]
10230b4dc:	45 11 00 ad	stp	q5, q4, [x10]
10230b4e0:	47 19 01 ad	stp	q7, q6, [x10, #0x20]
10230b4e4:	4a 01 02 91	add	x10, x10, #0x80
10230b4e8:	6b 41 00 f1	subs	x11, x11, #0x10
10230b4ec:	41 fe ff 54	b.ne	0x10230b4b4
10230b4f0:	1f 02 11 eb	cmp	x16, x17
10230b4f4:	20 01 00 54	b.eq	0x10230b518
10230b4f8:	c0 01 40 bd	ldr	s0, [x14]
10230b4fc:	e0 01 00 bd	str	s0, [x15]
10230b500:	ca 05 40 b9	ldr	w10, [x14, #0x4]
10230b504:	ea 05 00 b9	str	w10, [x15, #0x4]
10230b508:	ef 21 00 91	add	x15, x15, #0x8
10230b50c:	ce 21 00 91	add	x14, x14, #0x8
10230b510:	df 01 08 eb	cmp	x14, x8
10230b514:	21 ff ff 54	b.ne	0x10230b4f8
10230b518:	e8 01 0d cb	sub	x8, x15, x13
10230b51c:	4a 00 80 52	mov	w10, #0x2
10230b520:	29 0d 0a 8b	add	x9, x9, x10, lsl #3
10230b524:	28 01 08 8b	add	x8, x9, x8
10230b528:	a8 83 12 f8	stur	x8, [x29, #-0xd8]
10230b52c:	a9 23 72 a9	ldp	x9, x8, [x29, #-0xe0]
10230b530:	08 01 09 cb	sub	x8, x8, x9
10230b534:	09 fd 43 d3	lsr	x9, x8, #3
10230b538:	3f 09 00 71	cmp	w9, #0x2
10230b53c:	cd 0d 00 54	b.le	0x10230b6f4
10230b540:	34 05 00 51	sub	w20, w9, #0x1
10230b544:	e9 7b 5f b2	mov	x9, #-0x200000000
10230b548:	28 75 08 8b	add	x8, x9, x8, lsl #29
10230b54c:	19 fd 60 93	asr	x25, x8, #32
10230b550:	3b 00 80 52	mov	w27, #0x1
10230b554:	18 02 80 52	mov	w24, #0x10
10230b558:	88 66 01 0f	movi.2s	v8, #0x34, lsl #24
10230b55c:	09 10 2c 1e	fmov	s9, #0.50000000
10230b560:	0a 10 2e 1e	fmov	s10, #1.00000000
10230b564:	29 00 80 52	mov	w9, #0x1
10230b568:	13 00 00 14	b	0x10230b5b4
10230b56c:	22 28 29 1e	fadd	s2, s1, s9
10230b570:	5c 00 38 1e	fcvtzs	w28, s2
10230b574:	02 28 29 1e	fadd	s2, s0, s9
10230b578:	49 00 38 1e	fcvtzs	w9, s2
10230b57c:	9f 07 00 71	cmp	w28, #0x1
10230b580:	28 a9 41 7a	ccmp	w9, #0x1, #0x8, ge
10230b584:	c9 cc 8c 52	mov	w9, #0x6666
10230b588:	c9 fc a7 72	movk	w9, #0x3fe6, lsl #16
10230b58c:	22 01 27 1e	fmov	s2, w9
10230b590:	24 a4 22 1e	fccmp	s1, s2, #0x4, ge
10230b594:	04 c4 22 1e	fccmp	s0, s2, #0x4, gt
10230b598:	80 cb 42 7a	ccmp	w28, #0x2, #0x0, gt
10230b59c:	42 08 00 54	b.hs	0x10230b6a4
10230b5a0:	18 23 00 91	add	x24, x24, #0x8
10230b5a4:	e9 03 13 aa	mov	x9, x19
10230b5a8:	7f 02 14 eb	cmp	x19, x20
10230b5ac:	fc 23 40 f9	ldr	x28, [sp, #0x40]
10230b5b0:	20 0a 00 54	b.eq	0x10230b6f4
10230b5b4:	a8 03 52 f8	ldur	x8, [x29, #-0xe0]
10230b5b8:	0a 0d 09 8b	add	x10, x8, x9, lsl #3
10230b5bc:	40 81 5f bc	ldur	s0, [x10, #-0x8]
10230b5c0:	4b 01 40 bd	ldr	s11, [x10]
10230b5c4:	33 05 00 91	add	x19, x9, #0x1
10230b5c8:	3f 01 19 eb	cmp	x9, x25
10230b5cc:	4a 02 00 54	b.ge	0x10230b614
10230b5d0:	6a f2 7d d3	lsl	x10, x19, #3
10230b5d4:	02 69 6a bc	ldr	s2, [x8, x10]
10230b5d8:	63 39 20 1e	fsub	s3, s11, s0
10230b5dc:	00 e4 00 2f	movi	d0, #0000000000000000
10230b5e0:	60 20 28 1e	fcmp	s3, s8
10230b5e4:	4c 38 2b 1e	fsub	s12, s2, s11
10230b5e8:	01 e4 00 2f	movi	d1, #0000000000000000
10230b5ec:	4d 00 00 54	b.le	0x10230b5f4
10230b5f0:	81 19 23 1e	fdiv	s1, s12, s3
10230b5f4:	29 09 00 11	add	w9, w9, #0x2
10230b5f8:	29 f1 7d d3	lsl	x9, x9, #3
10230b5fc:	03 69 69 bc	ldr	s3, [x8, x9]
10230b600:	62 38 22 1e	fsub	s2, s3, s2
10230b604:	40 20 28 1e	fcmp	s2, s8
10230b608:	2d fb ff 54	b.le	0x10230b56c
10230b60c:	80 19 22 1e	fdiv	s0, s12, s2
10230b610:	d7 ff ff 17	b	0x10230b56c
10230b614:	60 39 20 1e	fsub	s0, s11, s0
10230b618:	00 20 28 1e	fcmp	s0, s8
10230b61c:	2d fc ff 54	b.le	0x10230b5a0
10230b620:	69 f2 7d d3	lsl	x9, x19, #3
10230b624:	01 69 69 bc	ldr	s1, [x8, x9]
10230b628:	2c 38 2b 1e	fsub	s12, s1, s11
10230b62c:	80 19 20 1e	fdiv	s0, s12, s0
10230b630:	01 28 29 1e	fadd	s1, s0, s9
10230b634:	3c 00 38 1e	fcvtzs	w28, s1
10230b638:	9f 07 00 71	cmp	w28, #0x1
10230b63c:	c9 cc 8c 52	mov	w9, #0x6666
10230b640:	c9 fc a7 72	movk	w9, #0x3fe6, lsl #16
10230b644:	21 01 27 1e	fmov	s1, w9
10230b648:	04 a4 21 1e	fccmp	s0, s1, #0x4, ge
10230b64c:	80 cb 42 7a	ccmp	w28, #0x2, #0x0, gt
10230b650:	83 fa ff 54	b.lo	0x10230b5a0
10230b654:	80 03 22 1e	scvtf	s0, w28
10230b658:	4d 19 20 1e	fdiv	s13, s10, s0
10230b65c:	f5 03 18 aa	mov	x21, x24
10230b660:	56 00 80 52	mov	w22, #0x2
10230b664:	c9 06 00 51	sub	w9, w22, #0x1
10230b668:	20 01 22 1e	scvtf	s0, w9
10230b66c:	80 09 20 1e	fmul	s0, s12, s0
10230b670:	00 2c 0d 1f	fmadd	s0, s0, s13, s11
10230b674:	e0 fb 00 bd	str	s0, [sp, #0xf8]
10230b678:	fb ff 00 b9	str	w27, [sp, #0xfc]
10230b67c:	a1 02 08 8b	add	x1, x21, x8
10230b680:	a0 83 03 d1	sub	x0, x29, #0xe0
10230b684:	e2 e3 03 91	add	x2, sp, #0xf8
10230b688:	88 01 00 94	bl	__ZNSt3__16vectorINS_4pairIfiEENS_9allocatorIS2_EEE6insertENS_11__wrap_iterIPKS2_EERS7_
10230b68c:	9f 03 16 eb	cmp	x28, x22
10230b690:	80 f8 ff 54	b.eq	0x10230b5a0
10230b694:	a8 03 52 f8	ldur	x8, [x29, #-0xe0]
10230b698:	d6 06 00 91	add	x22, x22, #0x1
10230b69c:	b5 22 00 91	add	x21, x21, #0x8
10230b6a0:	f1 ff ff 17	b	0x10230b664
10230b6a4:	80 03 22 1e	scvtf	s0, w28
10230b6a8:	4d 19 20 1e	fdiv	s13, s10, s0
10230b6ac:	f5 03 18 aa	mov	x21, x24
10230b6b0:	56 00 80 52	mov	w22, #0x2
10230b6b4:	c9 06 00 51	sub	w9, w22, #0x1
10230b6b8:	20 01 22 1e	scvtf	s0, w9
10230b6bc:	80 09 20 1e	fmul	s0, s12, s0
10230b6c0:	00 2c 0d 1f	fmadd	s0, s0, s13, s11
10230b6c4:	e0 fb 00 bd	str	s0, [sp, #0xf8]
10230b6c8:	fb ff 00 b9	str	w27, [sp, #0xfc]
10230b6cc:	a1 02 08 8b	add	x1, x21, x8
10230b6d0:	a0 83 03 d1	sub	x0, x29, #0xe0
10230b6d4:	e2 e3 03 91	add	x2, sp, #0xf8
10230b6d8:	74 01 00 94	bl	__ZNSt3__16vectorINS_4pairIfiEENS_9allocatorIS2_EEE6insertENS_11__wrap_iterIPKS2_EERS7_
10230b6dc:	9f 03 16 eb	cmp	x28, x22
10230b6e0:	00 f6 ff 54	b.eq	0x10230b5a0
10230b6e4:	a8 03 52 f8	ldur	x8, [x29, #-0xe0]
10230b6e8:	d6 06 00 91	add	x22, x22, #0x1
10230b6ec:	b5 22 00 91	add	x21, x21, #0x8
10230b6f0:	f1 ff ff 17	b	0x10230b6b4
10230b6f4:	e8 e3 03 91	add	x8, sp, #0xf8
10230b6f8:	a0 83 03 d1	sub	x0, x29, #0xe0
10230b6fc:	e1 03 1a aa	mov	x1, x26
10230b700:	f4 1f 40 f9	ldr	x20, [sp, #0x38]
10230b704:	e2 03 14 aa	mov	x2, x20
10230b708:	83 00 80 52	mov	w3, #0x4
10230b70c:	7f e8 ff 97	bl	__ZN6madmom13get_beat_listERKNSt3__16vectorINS0_4pairIfiEENS0_9allocatorIS3_EEEExii
10230b710:	e0 e3 03 91	add	x0, sp, #0xf8
10230b714:	21 00 80 52	mov	w1, #0x1
10230b718:	07 ed ff 97	bl	__ZN6madmom7get_bpmERKN8nlohmann10basic_jsonINS0_11ordered_mapENSt3__16vectorENS3_12basic_stringIcNS3_11char_traitsIcEENS3_9allocatorIcEEEEbxydS8_NS0_14adl_serializerENS4_IhNS8_IhEEEEEEb
10230b71c:	f3 13 40 f9	ldr	x19, [sp, #0x20]
10230b720:	08 40 60 1e	fmov	d8, d0
10230b724:	ff 63 03 39	strb	wzr, [sp, #0xd8]
10230b728:	e8 63 03 91	add	x8, sp, #0xd8
10230b72c:	00 21 00 91	add	x0, x8, #0x8
10230b730:	ff 73 00 f9	str	xzr, [sp, #0xe0]
10230b734:	01 00 80 52	mov	w1, #0x0
10230b738:	aa 4c 79 97	bl	__ZN8nlohmann10basic_jsonINS_11ordered_mapENSt3__16vectorENS2_12basic_stringIcNS2_11char_traitsIcEENS2_9allocatorIcEEEEbxydS7_NS_14adl_serializerENS3_IhNS7_IhEEEEE10json_value7destroyENS_6detail7value_tE
10230b73c:	e8 4f 40 b9	ldr	w8, [sp, #0x4c]
10230b740:	e8 03 08 2a	mov	w8, w8
10230b744:	a9 00 80 52	mov	w9, #0x5
10230b748:	e9 63 03 39	strb	w9, [sp, #0xd8]
10230b74c:	e8 73 00 f9	str	x8, [sp, #0xe0]
10230b750:	01 67 01 d0	adrp	x1, 11490 ; 0x104fed000
10230b754:	21 5c 11 91	add	x1, x1, #0x457 ; literal pool for: "numChannels"
10230b758:	e0 03 13 aa	mov	x0, x19
10230b75c:	0d 3d 79 97	bl	__ZN8nlohmann10basic_jsonINS_11ordered_mapENSt3__16vectorENS2_12basic_stringIcNS2_11char_traitsIcEENS2_9allocatorIcEEEEbxydS7_NS_14adl_serializerENS3_IhNS7_IhEEEEEixIKcEERSD_PT_
10230b760:	08 00 40 39	ldrb	w8, [x0]
10230b764:	e9 63 43 39	ldrb	w9, [sp, #0xd8]
10230b768:	09 00 00 39	strb	w9, [x0]
10230b76c:	e8 63 03 39	strb	w8, [sp, #0xd8]
10230b770:	08 04 40 f9	ldr	x8, [x0, #0x8]
10230b774:	e9 73 40 f9	ldr	x9, [sp, #0xe0]
10230b778:	09 04 00 f9	str	x9, [x0, #0x8]
10230b77c:	e8 73 00 f9	str	x8, [sp, #0xe0]
10230b780:	e0 63 03 91	add	x0, sp, #0xd8
10230b784:	a7 3b 79 97	bl	__ZN8nlohmann10basic_jsonINS_11ordered_mapENSt3__16vectorENS2_12basic_stringIcNS2_11char_traitsIcEENS2_9allocatorIcEEEEbxydS7_NS_14adl_serializerENS3_IhNS7_IhEEEEED1Ev
10230b788:	ff 23 03 39	strb	wzr, [sp, #0xc8]
10230b78c:	e8 23 03 91	add	x8, sp, #0xc8
10230b790:	00 21 00 91	add	x0, x8, #0x8
10230b794:	ff 6b 00 f9	str	xzr, [sp, #0xd0]
10230b798:	01 00 80 52	mov	w1, #0x0
10230b79c:	91 4c 79 97	bl	__ZN8nlohmann10basic_jsonINS_11ordered_mapENSt3__16vectorENS2_12basic_stringIcNS2_11char_traitsIcEENS2_9allocatorIcEEEEbxydS7_NS_14adl_serializerENS3_IhNS7_IhEEEEE10json_value7destroyENS_6detail7value_tE
10230b7a0:	e8 0f 40 f9	ldr	x8, [sp, #0x18]
10230b7a4:	08 7d 40 93	sxtw	x8, w8
10230b7a8:	a9 00 80 52	mov	w9, #0x5
10230b7ac:	e9 23 03 39	strb	w9, [sp, #0xc8]
10230b7b0:	e8 6b 00 f9	str	x8, [sp, #0xd0]
10230b7b4:	01 64 01 d0	adrp	x1, 11394 ; 0x104f8d000
10230b7b8:	21 a0 3b 91	add	x1, x1, #0xee8 ; literal pool for: "sampleRate"
10230b7bc:	e0 03 13 aa	mov	x0, x19
10230b7c0:	f4 3c 79 97	bl	__ZN8nlohmann10basic_jsonINS_11ordered_mapENSt3__16vectorENS2_12basic_stringIcNS2_11char_traitsIcEENS2_9allocatorIcEEEEbxydS7_NS_14adl_serializerENS3_IhNS7_IhEEEEEixIKcEERSD_PT_
10230b7c4:	08 00 40 39	ldrb	w8, [x0]
10230b7c8:	e9 23 43 39	ldrb	w9, [sp, #0xc8]
10230b7cc:	09 00 00 39	strb	w9, [x0]
10230b7d0:	e8 23 03 39	strb	w8, [sp, #0xc8]
10230b7d4:	08 04 40 f9	ldr	x8, [x0, #0x8]
10230b7d8:	e9 6b 40 f9	ldr	x9, [sp, #0xd0]
10230b7dc:	09 04 00 f9	str	x9, [x0, #0x8]
10230b7e0:	e8 6b 00 f9	str	x8, [sp, #0xd0]
10230b7e4:	e0 23 03 91	add	x0, sp, #0xc8
10230b7e8:	8e 3b 79 97	bl	__ZN8nlohmann10basic_jsonINS_11ordered_mapENSt3__16vectorENS2_12basic_stringIcNS2_11char_traitsIcEENS2_9allocatorIcEEEEbxydS7_NS_14adl_serializerENS3_IhNS7_IhEEEEED1Ev
10230b7ec:	ff e3 02 39	strb	wzr, [sp, #0xb8]
10230b7f0:	e8 e3 02 91	add	x8, sp, #0xb8
10230b7f4:	00 21 00 91	add	x0, x8, #0x8
10230b7f8:	ff 63 00 f9	str	xzr, [sp, #0xc0]
10230b7fc:	01 00 80 52	mov	w1, #0x0
10230b800:	78 4c 79 97	bl	__ZN8nlohmann10basic_jsonINS_11ordered_mapENSt3__16vectorENS2_12basic_stringIcNS2_11char_traitsIcEENS2_9allocatorIcEEEEbxydS7_NS_14adl_serializerENS3_IhNS7_IhEEEEE10json_value7destroyENS_6detail7value_tE
10230b804:	88 7e 40 93	sxtw	x8, w20
10230b808:	a9 00 80 52	mov	w9, #0x5
10230b80c:	e9 e3 02 39	strb	w9, [sp, #0xb8]
10230b810:	e8 63 00 f9	str	x8, [sp, #0xc0]
10230b814:	01 67 01 d0	adrp	x1, 11490 ; 0x104fed000
10230b818:	21 8c 11 91	add	x1, x1, #0x463 ; literal pool for: "decodeSampleRate"
10230b81c:	e0 03 13 aa	mov	x0, x19
10230b820:	dc 3c 79 97	bl	__ZN8nlohmann10basic_jsonINS_11ordered_mapENSt3__16vectorENS2_12basic_stringIcNS2_11char_traitsIcEENS2_9allocatorIcEEEEbxydS7_NS_14adl_serializerENS3_IhNS7_IhEEEEEixIKcEERSD_PT_
10230b824:	08 00 40 39	ldrb	w8, [x0]
10230b828:	e9 e3 42 39	ldrb	w9, [sp, #0xb8]
10230b82c:	09 00 00 39	strb	w9, [x0]
10230b830:	e8 e3 02 39	strb	w8, [sp, #0xb8]
10230b834:	08 04 40 f9	ldr	x8, [x0, #0x8]
10230b838:	e9 63 40 f9	ldr	x9, [sp, #0xc0]
10230b83c:	09 04 00 f9	str	x9, [x0, #0x8]
10230b840:	e8 63 00 f9	str	x8, [sp, #0xc0]
10230b844:	e0 e3 02 91	add	x0, sp, #0xb8
10230b848:	76 3b 79 97	bl	__ZN8nlohmann10basic_jsonINS_11ordered_mapENSt3__16vectorENS2_12basic_stringIcNS2_11char_traitsIcEENS2_9allocatorIcEEEEbxydS7_NS_14adl_serializerENS3_IhNS7_IhEEEEED1Ev
10230b84c:	ff a3 02 39	strb	wzr, [sp, #0xa8]
10230b850:	e8 a3 02 91	add	x8, sp, #0xa8
10230b854:	00 21 00 91	add	x0, x8, #0x8
10230b858:	ff 5b 00 f9	str	xzr, [sp, #0xb0]
10230b85c:	01 00 80 52	mov	w1, #0x0
10230b860:	60 4c 79 97	bl	__ZN8nlohmann10basic_jsonINS_11ordered_mapENSt3__16vectorENS2_12basic_stringIcNS2_11char_traitsIcEENS2_9allocatorIcEEEEbxydS7_NS_14adl_serializerENS3_IhNS7_IhEEEEE10json_value7destroyENS_6detail7value_tE
10230b864:	e8 0b 40 f9	ldr	x8, [sp, #0x10]
10230b868:	08 7d 40 93	sxtw	x8, w8
10230b86c:	a9 00 80 52	mov	w9, #0x5
10230b870:	e9 a3 02 39	strb	w9, [sp, #0xa8]
10230b874:	e8 5b 00 f9	str	x8, [sp, #0xb0]
10230b878:	01 67 01 d0	adrp	x1, 11490 ; 0x104fed000
10230b87c:	21 d0 11 91	add	x1, x1, #0x474 ; literal pool for: "bitRate"
10230b880:	e0 03 13 aa	mov	x0, x19
10230b884:	c3 3c 79 97	bl	__ZN8nlohmann10basic_jsonINS_11ordered_mapENSt3__16vectorENS2_12basic_stringIcNS2_11char_traitsIcEENS2_9allocatorIcEEEEbxydS7_NS_14adl_serializerENS3_IhNS7_IhEEEEEixIKcEERSD_PT_
10230b888:	08 00 40 39	ldrb	w8, [x0]
10230b88c:	e9 a3 42 39	ldrb	w9, [sp, #0xa8]
10230b890:	09 00 00 39	strb	w9, [x0]
10230b894:	e8 a3 02 39	strb	w8, [sp, #0xa8]
10230b898:	08 04 40 f9	ldr	x8, [x0, #0x8]
10230b89c:	e9 5b 40 f9	ldr	x9, [sp, #0xb0]
10230b8a0:	09 04 00 f9	str	x9, [x0, #0x8]
10230b8a4:	e8 5b 00 f9	str	x8, [sp, #0xb0]
10230b8a8:	e0 a3 02 91	add	x0, sp, #0xa8
10230b8ac:	5d 3b 79 97	bl	__ZN8nlohmann10basic_jsonINS_11ordered_mapENSt3__16vectorENS2_12basic_stringIcNS2_11char_traitsIcEENS2_9allocatorIcEEEEbxydS7_NS_14adl_serializerENS3_IhNS7_IhEEEEED1Ev
10230b8b0:	ff 63 02 39	strb	wzr, [sp, #0x98]
10230b8b4:	e8 63 02 91	add	x8, sp, #0x98
10230b8b8:	00 21 00 91	add	x0, x8, #0x8
10230b8bc:	ff 53 00 f9	str	xzr, [sp, #0xa0]
10230b8c0:	01 00 80 52	mov	w1, #0x0
10230b8c4:	47 4c 79 97	bl	__ZN8nlohmann10basic_jsonINS_11ordered_mapENSt3__16vectorENS2_12basic_stringIcNS2_11char_traitsIcEENS2_9allocatorIcEEEEbxydS7_NS_14adl_serializerENS3_IhNS7_IhEEEEE10json_value7destroyENS_6detail7value_tE
10230b8c8:	e8 0f 40 b9	ldr	w8, [sp, #0xc]
10230b8cc:	e8 03 08 2a	mov	w8, w8
10230b8d0:	a9 00 80 52	mov	w9, #0x5
10230b8d4:	e9 63 02 39	strb	w9, [sp, #0x98]
10230b8d8:	e8 53 00 f9	str	x8, [sp, #0xa0]
10230b8dc:	21 64 01 90	adrp	x1, 11396 ; 0x104f8f000
10230b8e0:	21 68 2c 91	add	x1, x1, #0xb1a ; literal pool for: "bitDepth"
10230b8e4:	e0 03 13 aa	mov	x0, x19
10230b8e8:	aa 3c 79 97	bl	__ZN8nlohmann10basic_jsonINS_11ordered_mapENSt3__16vectorENS2_12basic_stringIcNS2_11char_traitsIcEENS2_9allocatorIcEEEEbxydS7_NS_14adl_serializerENS3_IhNS7_IhEEEEEixIKcEERSD_PT_
10230b8ec:	08 00 40 39	ldrb	w8, [x0]
10230b8f0:	e9 63 42 39	ldrb	w9, [sp, #0x98]
10230b8f4:	09 00 00 39	strb	w9, [x0]
10230b8f8:	e8 63 02 39	strb	w8, [sp, #0x98]
10230b8fc:	08 04 40 f9	ldr	x8, [x0, #0x8]
10230b900:	e9 53 40 f9	ldr	x9, [sp, #0xa0]
10230b904:	09 04 00 f9	str	x9, [x0, #0x8]
10230b908:	e8 53 00 f9	str	x8, [sp, #0xa0]
10230b90c:	e0 63 02 91	add	x0, sp, #0x98
10230b910:	44 3b 79 97	bl	__ZN8nlohmann10basic_jsonINS_11ordered_mapENSt3__16vectorENS2_12basic_stringIcNS2_11char_traitsIcEENS2_9allocatorIcEEEEbxydS7_NS_14adl_serializerENS3_IhNS7_IhEEEEED1Ev
10230b914:	ff 23 02 39	strb	wzr, [sp, #0x88]
10230b918:	e8 23 02 91	add	x8, sp, #0x88
10230b91c:	00 21 00 91	add	x0, x8, #0x8
10230b920:	ff 4b 00 f9	str	xzr, [sp, #0x90]
10230b924:	01 00 80 52	mov	w1, #0x0
10230b928:	2e 4c 79 97	bl	__ZN8nlohmann10basic_jsonINS_11ordered_mapENSt3__16vectorENS2_12basic_stringIcNS2_11char_traitsIcEENS2_9allocatorIcEEEEbxydS7_NS_14adl_serializerENS3_IhNS7_IhEEEEE10json_value7destroyENS_6detail7value_tE
10230b92c:	a8 00 80 52	mov	w8, #0x5
10230b930:	e8 23 02 39	strb	w8, [sp, #0x88]
10230b934:	fa 4b 00 f9	str	x26, [sp, #0x90]
10230b938:	01 67 01 d0	adrp	x1, 11490 ; 0x104fed000
10230b93c:	21 f0 11 91	add	x1, x1, #0x47c ; literal pool for: "decodeSamples"
10230b940:	e0 03 13 aa	mov	x0, x19
10230b944:	93 3c 79 97	bl	__ZN8nlohmann10basic_jsonINS_11ordered_mapENSt3__16vectorENS2_12basic_stringIcNS2_11char_traitsIcEENS2_9allocatorIcEEEEbxydS7_NS_14adl_serializerENS3_IhNS7_IhEEEEEixIKcEERSD_PT_
10230b948:	08 00 40 39	ldrb	w8, [x0]
10230b94c:	e9 23 42 39	ldrb	w9, [sp, #0x88]
10230b950:	09 00 00 39	strb	w9, [x0]
10230b954:	e8 23 02 39	strb	w8, [sp, #0x88]
10230b958:	08 04 40 f9	ldr	x8, [x0, #0x8]
10230b95c:	e9 4b 40 f9	ldr	x9, [sp, #0x90]
10230b960:	09 04 00 f9	str	x9, [x0, #0x8]
10230b964:	e8 4b 00 f9	str	x8, [sp, #0x90]
10230b968:	e0 23 02 91	add	x0, sp, #0x88
10230b96c:	2d 3b 79 97	bl	__ZN8nlohmann10basic_jsonINS_11ordered_mapENSt3__16vectorENS2_12basic_stringIcNS2_11char_traitsIcEENS2_9allocatorIcEEEEbxydS7_NS_14adl_serializerENS3_IhNS7_IhEEEEED1Ev
10230b970:	ff e3 01 39	strb	wzr, [sp, #0x78]
10230b974:	e8 e3 01 91	add	x8, sp, #0x78
10230b978:	00 21 00 91	add	x0, x8, #0x8
10230b97c:	ff 43 00 f9	str	xzr, [sp, #0x80]
10230b980:	01 00 80 52	mov	w1, #0x0
10230b984:	17 4c 79 97	bl	__ZN8nlohmann10basic_jsonINS_11ordered_mapENSt3__16vectorENS2_12basic_stringIcNS2_11char_traitsIcEENS2_9allocatorIcEEEEbxydS7_NS_14adl_serializerENS3_IhNS7_IhEEEEE10json_value7destroyENS_6detail7value_tE
10230b988:	08 01 78 1e	fcvtzs	w8, d8
10230b98c:	08 7d 40 93	sxtw	x8, w8
10230b990:	a9 00 80 52	mov	w9, #0x5
10230b994:	e9 e3 01 39	strb	w9, [sp, #0x78]
10230b998:	e8 43 00 f9	str	x8, [sp, #0x80]
10230b99c:	81 63 01 d0	adrp	x1, 11378 ; 0x104f7d000
10230b9a0:	21 18 3e 91	add	x1, x1, #0xf86 ; literal pool for: "bpm"
10230b9a4:	e0 03 13 aa	mov	x0, x19
10230b9a8:	7a 3c 79 97	bl	__ZN8nlohmann10basic_jsonINS_11ordered_mapENSt3__16vectorENS2_12basic_stringIcNS2_11char_traitsIcEENS2_9allocatorIcEEEEbxydS7_NS_14adl_serializerENS3_IhNS7_IhEEEEEixIKcEERSD_PT_
10230b9ac:	08 00 40 39	ldrb	w8, [x0]
10230b9b0:	e9 e3 41 39	ldrb	w9, [sp, #0x78]
10230b9b4:	09 00 00 39	strb	w9, [x0]
10230b9b8:	e8 e3 01 39	strb	w8, [sp, #0x78]
10230b9bc:	08 04 40 f9	ldr	x8, [x0, #0x8]
10230b9c0:	e9 43 40 f9	ldr	x9, [sp, #0x80]
10230b9c4:	09 04 00 f9	str	x9, [x0, #0x8]
10230b9c8:	e8 43 00 f9	str	x8, [sp, #0x80]
10230b9cc:	e0 e3 01 91	add	x0, sp, #0x78
10230b9d0:	14 3b 79 97	bl	__ZN8nlohmann10basic_jsonINS_11ordered_mapENSt3__16vectorENS2_12basic_stringIcNS2_11char_traitsIcEENS2_9allocatorIcEEEEbxydS7_NS_14adl_serializerENS3_IhNS7_IhEEEEED1Ev
10230b9d4:	e0 a3 01 91	add	x0, sp, #0x68
10230b9d8:	e1 e3 03 91	add	x1, sp, #0xf8
10230b9dc:	52 45 79 97	bl	__ZN8nlohmann10basic_jsonINS_11ordered_mapENSt3__16vectorENS2_12basic_stringIcNS2_11char_traitsIcEENS2_9allocatorIcEEEEbxydS7_NS_14adl_serializerENS3_IhNS7_IhEEEEEC2ERKSD_
10230b9e0:	41 66 01 b0	adrp	x1, 11465 ; 0x104fd4000
10230b9e4:	21 d4 30 91	add	x1, x1, #0xc35 ; literal pool for: "beatList"
10230b9e8:	e0 03 13 aa	mov	x0, x19
10230b9ec:	69 3c 79 97	bl	__ZN8nlohmann10basic_jsonINS_11ordered_mapENSt3__16vectorENS2_12basic_stringIcNS2_11char_traitsIcEENS2_9allocatorIcEEEEbxydS7_NS_14adl_serializerENS3_IhNS7_IhEEEEEixIKcEERSD_PT_
10230b9f0:	08 00 40 39	ldrb	w8, [x0]
10230b9f4:	e9 a3 41 39	ldrb	w9, [sp, #0x68]
10230b9f8:	09 00 00 39	strb	w9, [x0]
10230b9fc:	e8 a3 01 39	strb	w8, [sp, #0x68]
10230ba00:	08 04 40 f9	ldr	x8, [x0, #0x8]
10230ba04:	e9 3b 40 f9	ldr	x9, [sp, #0x70]
10230ba08:	09 04 00 f9	str	x9, [x0, #0x8]
10230ba0c:	e8 3b 00 f9	str	x8, [sp, #0x70]
10230ba10:	e0 a3 01 91	add	x0, sp, #0x68
10230ba14:	03 3b 79 97	bl	__ZN8nlohmann10basic_jsonINS_11ordered_mapENSt3__16vectorENS2_12basic_stringIcNS2_11char_traitsIcEENS2_9allocatorIcEEEEbxydS7_NS_14adl_serializerENS3_IhNS7_IhEEEEED1Ev
10230ba18:	e0 e3 03 91	add	x0, sp, #0xf8
10230ba1c:	01 3b 79 97	bl	__ZN8nlohmann10basic_jsonINS_11ordered_mapENSt3__16vectorENS2_12basic_stringIcNS2_11char_traitsIcEENS2_9allocatorIcEEEEbxydS7_NS_14adl_serializerENS3_IhNS7_IhEEEEED1Ev
10230ba20:	a0 03 52 f8	ldur	x0, [x29, #-0xe0]
10230ba24:	60 00 00 b4	cbz	x0, 0x10230ba30
10230ba28:	a0 83 12 f8	stur	x0, [x29, #-0xd8]
10230ba2c:	23 18 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10230ba30:	e0 33 40 f9	ldr	x0, [sp, #0x60]
10230ba34:	cb 19 47 94	bl	0x1034d2160 ; symbol stub for: _free
10230ba38:	e0 03 17 aa	mov	x0, x23
10230ba3c:	c9 19 47 94	bl	0x1034d2160 ; symbol stub for: _free
10230ba40:	e0 2b 40 f9	ldr	x0, [sp, #0x50]
10230ba44:	1a 18 47 94	bl	0x1034d1aac ; symbol stub for: __ZdaPv
10230ba48:	e0 2f 40 f9	ldr	x0, [sp, #0x58]
10230ba4c:	18 18 47 94	bl	0x1034d1aac ; symbol stub for: __ZdaPv
10230ba50:	88 03 40 f9	ldr	x8, [x28]
10230ba54:	08 05 40 f9	ldr	x8, [x8, #0x8]
10230ba58:	e0 03 1c aa	mov	x0, x28
10230ba5c:	00 01 3f d6	blr	x8
10230ba60:	a0 c3 02 d1	sub	x0, x29, #0xb0
10230ba64:	26 7b 06 94	bl	__ZN4juce6StringD1Ev
10230ba68:	a8 f3 d4 38	ldursb	w8, [x29, #-0xb1]
10230ba6c:	68 00 f8 36	tbz	w8, #0x1f, 0x10230ba78
10230ba70:	a0 83 53 f8	ldur	x0, [x29, #-0xc8]
10230ba74:	11 18 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10230ba78:	a8 03 56 f8	ldur	x8, [x29, #-0xa0]
10230ba7c:	09 72 01 f0	adrp	x9, 11843 ; 0x10514e000
10230ba80:	29 7d 42 f9	ldr	x9, [x9, #0x4f8] ; literal pool symbol address: ___stack_chk_guard
10230ba84:	29 01 40 f9	ldr	x9, [x9]
10230ba88:	3f 01 08 eb	cmp	x9, x8
10230ba8c:	c1 01 00 54	b.ne	0x10230bac4
10230ba90:	20 00 80 52	mov	w0, #0x1
10230ba94:	ff 83 05 91	add	sp, sp, #0x160
10230ba98:	fd 7b 49 a9	ldp	x29, x30, [sp, #0x90]
10230ba9c:	f4 4f 48 a9	ldp	x20, x19, [sp, #0x80]
10230baa0:	f6 57 47 a9	ldp	x22, x21, [sp, #0x70]
10230baa4:	f8 5f 46 a9	ldp	x24, x23, [sp, #0x60]
10230baa8:	fa 67 45 a9	ldp	x26, x25, [sp, #0x50]
10230baac:	fc 6f 44 a9	ldp	x28, x27, [sp, #0x40]
10230bab0:	e9 23 43 6d	ldp	d9, d8, [sp, #0x30]
10230bab4:	eb 2b 42 6d	ldp	d11, d10, [sp, #0x20]
10230bab8:	ed 33 41 6d	ldp	d13, d12, [sp, #0x10]
10230babc:	ef 3b ca 6c	ldp	d15, d14, [sp], #0xa0
10230bac0:	c0 03 5f d6	ret
10230bac4:	63 18 47 94	bl	0x1034d1c50 ; symbol stub for: ___stack_chk_fail
10230bac8:	a0 83 03 d1	sub	x0, x29, #0xe0
10230bacc:	83 14 75 97	bl	__ZNKSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE20__throw_length_errorB6v15006Ev
10230bad0:	20 00 20 d4	brk	#0x1
10230bad4:	5e 00 00 14	b	0x10230bc4c
10230bad8:	5d 00 00 14	b	0x10230bc4c
10230badc:	f4 03 00 aa	mov	x20, x0
10230bae0:	e8 3f c4 39	ldrsb	w8, [sp, #0x10f]
10230bae4:	c8 00 f8 36	tbz	w8, #0x1f, 0x10230bafc
10230bae8:	e0 7f 40 f9	ldr	x0, [sp, #0xf8]
10230baec:	f3 17 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10230baf0:	a8 73 d3 38	ldursb	w8, [x29, #-0xc9]
10230baf4:	88 01 f8 36	tbz	w8, #0x1f, 0x10230bb24
10230baf8:	03 00 00 14	b	0x10230bb04
10230bafc:	a8 73 d3 38	ldursb	w8, [x29, #-0xc9]
10230bb00:	28 01 f8 36	tbz	w8, #0x1f, 0x10230bb24
10230bb04:	a0 03 52 f8	ldur	x0, [x29, #-0xe0]
10230bb08:	ec 17 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10230bb0c:	a8 f3 d4 38	ldursb	w8, [x29, #-0xb1]
10230bb10:	88 0c f8 36	tbz	w8, #0x1f, 0x10230bca0
10230bb14:	06 00 00 14	b	0x10230bb2c
10230bb18:	f4 03 00 aa	mov	x20, x0
10230bb1c:	a8 73 d3 38	ldursb	w8, [x29, #-0xc9]
10230bb20:	28 ff ff 37	tbnz	w8, #0x1f, 0x10230bb04
10230bb24:	a8 f3 d4 38	ldursb	w8, [x29, #-0xb1]
10230bb28:	c8 0b f8 36	tbz	w8, #0x1f, 0x10230bca0
10230bb2c:	a0 83 53 f8	ldur	x0, [x29, #-0xc8]
10230bb30:	e2 17 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10230bb34:	e0 03 14 aa	mov	x0, x20
10230bb38:	6d 15 47 94	bl	0x1034d10ec ; symbol stub for: __Unwind_Resume
10230bb3c:	f4 03 00 aa	mov	x20, x0
10230bb40:	a8 f3 d4 38	ldursb	w8, [x29, #-0xb1]
10230bb44:	e8 0a f8 36	tbz	w8, #0x1f, 0x10230bca0
10230bb48:	f9 ff ff 17	b	0x10230bb2c
10230bb4c:	f4 03 00 aa	mov	x20, x0
10230bb50:	e0 a3 01 91	add	x0, sp, #0x68
10230bb54:	1b 00 00 14	b	0x10230bbc0
10230bb58:	f4 03 00 aa	mov	x20, x0
10230bb5c:	e0 e3 01 91	add	x0, sp, #0x78
10230bb60:	18 00 00 14	b	0x10230bbc0
10230bb64:	9f ff 73 97	bl	___clang_call_terminate
10230bb68:	f4 03 00 aa	mov	x20, x0
10230bb6c:	e0 23 02 91	add	x0, sp, #0x88
10230bb70:	14 00 00 14	b	0x10230bbc0
10230bb74:	9b ff 73 97	bl	___clang_call_terminate
10230bb78:	f4 03 00 aa	mov	x20, x0
10230bb7c:	e0 63 02 91	add	x0, sp, #0x98
10230bb80:	10 00 00 14	b	0x10230bbc0
10230bb84:	97 ff 73 97	bl	___clang_call_terminate
10230bb88:	f4 03 00 aa	mov	x20, x0
10230bb8c:	e0 a3 02 91	add	x0, sp, #0xa8
10230bb90:	0c 00 00 14	b	0x10230bbc0
10230bb94:	93 ff 73 97	bl	___clang_call_terminate
10230bb98:	f4 03 00 aa	mov	x20, x0
10230bb9c:	e0 e3 02 91	add	x0, sp, #0xb8
10230bba0:	08 00 00 14	b	0x10230bbc0
10230bba4:	8f ff 73 97	bl	___clang_call_terminate
10230bba8:	f4 03 00 aa	mov	x20, x0
10230bbac:	e0 23 03 91	add	x0, sp, #0xc8
10230bbb0:	04 00 00 14	b	0x10230bbc0
10230bbb4:	8b ff 73 97	bl	___clang_call_terminate
10230bbb8:	f4 03 00 aa	mov	x20, x0
10230bbbc:	e0 63 03 91	add	x0, sp, #0xd8
10230bbc0:	98 3a 79 97	bl	__ZN8nlohmann10basic_jsonINS_11ordered_mapENSt3__16vectorENS2_12basic_stringIcNS2_11char_traitsIcEENS2_9allocatorIcEEEEbxydS7_NS_14adl_serializerENS3_IhNS7_IhEEEEED1Ev
10230bbc4:	18 00 00 14	b	0x10230bc24
10230bbc8:	86 ff 73 97	bl	___clang_call_terminate
10230bbcc:	20 00 00 14	b	0x10230bc4c
10230bbd0:	f4 03 00 aa	mov	x20, x0
10230bbd4:	e0 a3 03 91	add	x0, sp, #0xe8
10230bbd8:	c9 7a 06 94	bl	__ZN4juce6StringD1Ev
10230bbdc:	e0 c3 03 91	add	x0, sp, #0xf0
10230bbe0:	c7 7a 06 94	bl	__ZN4juce6StringD1Ev
10230bbe4:	1f 00 00 14	b	0x10230bc60
10230bbe8:	f4 03 00 aa	mov	x20, x0
10230bbec:	23 00 00 14	b	0x10230bc78
10230bbf0:	f4 03 00 aa	mov	x20, x0
10230bbf4:	23 00 00 14	b	0x10230bc80
10230bbf8:	f4 03 00 aa	mov	x20, x0
10230bbfc:	e0 03 1c aa	mov	x0, x28
10230bc00:	ae 17 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10230bc04:	23 00 00 14	b	0x10230bc90
10230bc08:	f4 03 00 aa	mov	x20, x0
10230bc0c:	21 00 00 14	b	0x10230bc90
10230bc10:	f4 03 00 aa	mov	x20, x0
10230bc14:	a8 f3 d4 38	ldursb	w8, [x29, #-0xb1]
10230bc18:	48 04 f8 36	tbz	w8, #0x1f, 0x10230bca0
10230bc1c:	c4 ff ff 17	b	0x10230bb2c
10230bc20:	f4 03 00 aa	mov	x20, x0
10230bc24:	e0 e3 03 91	add	x0, sp, #0xf8
10230bc28:	7e 3a 79 97	bl	__ZN8nlohmann10basic_jsonINS_11ordered_mapENSt3__16vectorENS2_12basic_stringIcNS2_11char_traitsIcEENS2_9allocatorIcEEEEbxydS7_NS_14adl_serializerENS3_IhNS7_IhEEEEED1Ev
10230bc2c:	09 00 00 14	b	0x10230bc50
10230bc30:	f4 03 00 aa	mov	x20, x0
10230bc34:	13 00 00 14	b	0x10230bc80
10230bc38:	05 00 00 14	b	0x10230bc4c
10230bc3c:	04 00 00 14	b	0x10230bc4c
10230bc40:	f4 03 00 aa	mov	x20, x0
10230bc44:	07 00 00 14	b	0x10230bc60
10230bc48:	01 00 00 14	b	0x10230bc4c
10230bc4c:	f4 03 00 aa	mov	x20, x0
10230bc50:	a0 03 52 f8	ldur	x0, [x29, #-0xe0]
10230bc54:	60 00 00 b4	cbz	x0, 0x10230bc60
10230bc58:	a0 83 12 f8	stur	x0, [x29, #-0xd8]
10230bc5c:	97 17 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10230bc60:	e0 33 40 f9	ldr	x0, [sp, #0x60]
10230bc64:	3f 19 47 94	bl	0x1034d2160 ; symbol stub for: _free
10230bc68:	e0 03 17 aa	mov	x0, x23
10230bc6c:	3d 19 47 94	bl	0x1034d2160 ; symbol stub for: _free
10230bc70:	e0 2b 40 f9	ldr	x0, [sp, #0x50]
10230bc74:	8e 17 47 94	bl	0x1034d1aac ; symbol stub for: __ZdaPv
10230bc78:	e0 2f 40 f9	ldr	x0, [sp, #0x58]
10230bc7c:	8c 17 47 94	bl	0x1034d1aac ; symbol stub for: __ZdaPv
10230bc80:	e0 23 40 f9	ldr	x0, [sp, #0x40]
10230bc84:	08 00 40 f9	ldr	x8, [x0]
10230bc88:	08 05 40 f9	ldr	x8, [x8, #0x8]
10230bc8c:	00 01 3f d6	blr	x8
10230bc90:	a0 c3 02 d1	sub	x0, x29, #0xb0
10230bc94:	9a 7a 06 94	bl	__ZN4juce6StringD1Ev
10230bc98:	a8 f3 d4 38	ldursb	w8, [x29, #-0xb1]
10230bc9c:	88 f4 ff 37	tbnz	w8, #0x1f, 0x10230bb2c
10230bca0:	e0 03 14 aa	mov	x0, x20
10230bca4:	12 15 47 94	bl	0x1034d10ec ; symbol stub for: __Unwind_Resume
