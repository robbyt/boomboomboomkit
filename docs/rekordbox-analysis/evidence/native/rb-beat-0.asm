/Applications/rekordbox 7/rekordbox.app/Contents/MacOS/rekordbox:
(__TEXT,__text) section
__ZN6madmom17downbeat_trackingERKN2nc7NdArrayIfNSt3__19allocatorIfEEEERNS2_6vectorIiNS3_IiEEEEddiiifbd:
102300d6c:	eb 2b b8 6d	stp	d11, d10, [sp, #-0x80]!
102300d70:	e9 23 01 6d	stp	d9, d8, [sp, #0x10]
102300d74:	fc 6f 02 a9	stp	x28, x27, [sp, #0x20]
102300d78:	fa 67 03 a9	stp	x26, x25, [sp, #0x30]
102300d7c:	f8 5f 04 a9	stp	x24, x23, [sp, #0x40]
102300d80:	f6 57 05 a9	stp	x22, x21, [sp, #0x50]
102300d84:	f4 4f 06 a9	stp	x20, x19, [sp, #0x60]
102300d88:	fd 7b 07 a9	stp	x29, x30, [sp, #0x70]
102300d8c:	fd c3 01 91	add	x29, sp, #0x70
102300d90:	ff 83 1f d1	sub	sp, sp, #0x7e0
102300d94:	fb 03 05 aa	mov	x27, x5
102300d98:	f8 03 04 aa	mov	x24, x4
102300d9c:	f9 03 03 aa	mov	x25, x3
102300da0:	fa 03 02 aa	mov	x26, x2
102300da4:	e3 0f 80 3d	str	q3, [sp, #0x30]
102300da8:	48 40 20 1e	fmov	s8, s2
102300dac:	29 40 60 1e	fmov	d9, d1
102300db0:	0a 40 60 1e	fmov	d10, d0
102300db4:	f3 03 00 aa	mov	x19, x0
102300db8:	e8 17 00 f9	str	x8, [sp, #0x28]
102300dbc:	f7 c3 10 91	add	x23, sp, #0x430
102300dc0:	68 72 01 d0	adrp	x8, 11854 ; 0x10514e000
102300dc4:	08 7d 42 f9	ldr	x8, [x8, #0x4f8] ; literal pool symbol address: ___stack_chk_guard
102300dc8:	08 01 40 f9	ldr	x8, [x8]
102300dcc:	a8 83 17 f8	stur	x8, [x29, #-0x88]
102300dd0:	36 50 40 a9	ldp	x22, x20, [x1]
102300dd4:	95 02 16 cb	sub	x21, x20, x22
102300dd8:	a8 fe 42 d3	lsr	x8, x21, #2
102300ddc:	e8 27 00 f9	str	x8, [sp, #0x48]
102300de0:	28 04 00 34	cbz	w8, 0x102300e64
102300de4:	a0 7e 7e 92	and	x0, x21, #0x3fffffffc
102300de8:	3a 43 47 94	bl	0x1034d1ad0 ; symbol stub for: __Znwm
102300dec:	df 02 14 eb	cmp	x22, x20
102300df0:	e0 37 00 f9	str	x0, [sp, #0x68]
102300df4:	60 04 00 54	b.eq	0x102300e80
102300df8:	a9 12 00 d1	sub	x9, x21, #0x4
102300dfc:	3f f1 00 f1	cmp	x9, #0x3c
102300e00:	63 03 00 54	b.lo	0x102300e6c
102300e04:	0a 00 16 cb	sub	x10, x0, x22
102300e08:	e8 03 00 aa	mov	x8, x0
102300e0c:	5f 01 01 f1	cmp	x10, #0x40
102300e10:	03 03 00 54	b.lo	0x102300e70
102300e14:	28 fd 42 d3	lsr	x8, x9, #2
102300e18:	09 05 00 91	add	x9, x8, #0x1
102300e1c:	2a e9 7c 92	and	x10, x9, #0x7ffffffffffffff0
102300e20:	48 f5 7e d3	lsl	x8, x10, #2
102300e24:	cb 02 08 8b	add	x11, x22, x8
102300e28:	ed 37 40 f9	ldr	x13, [sp, #0x68]
102300e2c:	a8 01 08 8b	add	x8, x13, x8
102300e30:	cc 82 00 91	add	x12, x22, #0x20
102300e34:	ad 81 00 91	add	x13, x13, #0x20
102300e38:	ee 03 0a aa	mov	x14, x10
102300e3c:	80 05 7f ad	ldp	q0, q1, [x12, #-0x20]
102300e40:	82 0d c2 ac	ldp	q2, q3, [x12], #0x40
102300e44:	a0 05 3f ad	stp	q0, q1, [x13, #-0x20]
102300e48:	a2 0d 82 ac	stp	q2, q3, [x13], #0x40
102300e4c:	ce 41 00 f1	subs	x14, x14, #0x10
102300e50:	61 ff ff 54	b.ne	0x102300e3c
102300e54:	f6 03 0b aa	mov	x22, x11
102300e58:	3f 01 0a eb	cmp	x9, x10
102300e5c:	a1 00 00 54	b.ne	0x102300e70
102300e60:	08 00 00 14	b	0x102300e80
102300e64:	ff 37 00 f9	str	xzr, [sp, #0x68]
102300e68:	06 00 00 14	b	0x102300e80
102300e6c:	e8 03 00 aa	mov	x8, x0
102300e70:	c9 46 40 b8	ldr	w9, [x22], #0x4
102300e74:	09 45 00 b8	str	w9, [x8], #0x4
102300e78:	df 02 14 eb	cmp	x22, x20
102300e7c:	a1 ff ff 54	b.ne	0x102300e70
102300e80:	a8 a4 00 f0	adrp	x8, 5271 ; 0x103797000
102300e84:	00 1d c1 3d	ldr	q0, [x8, #0x470]
102300e88:	e0 17 80 3d	str	q0, [sp, #0x50]
102300e8c:	e0 c2 87 3c	stur	q0, [x23, #0x7c]
102300e90:	00 01 80 52	mov	w0, #0x8
102300e94:	0f 43 47 94	bl	0x1034d1ad0 ; symbol stub for: __Znwm
102300e98:	e0 63 02 f9	str	x0, [sp, #0x4c0]
102300e9c:	34 00 80 52	mov	w20, #0x1
102300ea0:	f4 23 13 39	strb	w20, [sp, #0x4c8]
102300ea4:	0a 00 00 fd	str	d10, [x0]
102300ea8:	e0 17 c0 3d	ldr	q0, [sp, #0x50]
102300eac:	e0 42 85 3c	stur	q0, [x23, #0x54]
102300eb0:	00 01 80 52	mov	w0, #0x8
102300eb4:	07 43 47 94	bl	0x1034d1ad0 ; symbol stub for: __Znwm
102300eb8:	e0 4f 02 f9	str	x0, [sp, #0x498]
102300ebc:	f4 83 12 39	strb	w20, [sp, #0x4a0]
102300ec0:	09 00 00 fd	str	d9, [x0]
102300ec4:	e0 17 c0 3d	ldr	q0, [sp, #0x50]
102300ec8:	e0 c2 82 3c	stur	q0, [x23, #0x2c]
102300ecc:	80 00 80 52	mov	w0, #0x4
102300ed0:	00 43 47 94	bl	0x1034d1ad0 ; symbol stub for: __Znwm
102300ed4:	e0 3b 02 f9	str	x0, [sp, #0x470]
102300ed8:	34 00 80 52	mov	w20, #0x1
102300edc:	f4 e3 11 39	strb	w20, [sp, #0x478]
102300ee0:	1a 00 00 b9	str	w26, [x0]
102300ee4:	e0 17 c0 3d	ldr	q0, [sp, #0x50]
102300ee8:	e0 42 80 3c	stur	q0, [x23, #0x4]
102300eec:	80 00 80 52	mov	w0, #0x4
102300ef0:	f8 42 47 94	bl	0x1034d1ad0 ; symbol stub for: __Znwm
102300ef4:	e0 27 02 f9	str	x0, [sp, #0x448]
102300ef8:	f4 43 11 39	strb	w20, [sp, #0x450]
102300efc:	19 00 00 b9	str	w25, [x0]
102300f00:	e2 27 40 f9	ldr	x2, [sp, #0x48]
102300f04:	5f 04 00 71	cmp	w2, #0x1
102300f08:	a0 02 00 54	b.eq	0x102300f5c
102300f0c:	e8 83 13 91	add	x8, sp, #0x4e0
102300f10:	e0 a3 12 91	add	x0, sp, #0x4a8
102300f14:	21 00 80 52	mov	w1, #0x1
102300f18:	f4 03 02 aa	mov	x20, x2
102300f1c:	c8 68 00 94	bl	__ZNK2nc7NdArrayIdNSt3__19allocatorIdEEE6repeatEjj
102300f20:	e8 23 53 39	ldrb	w8, [sp, #0x4c8]
102300f24:	88 00 00 34	cbz	w8, 0x102300f34
102300f28:	e0 63 42 f9	ldr	x0, [sp, #0x4c0]
102300f2c:	40 00 00 b4	cbz	x0, 0x102300f34
102300f30:	e2 42 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102300f34:	e8 42 4b f8	ldur	x8, [x23, #0xb4]
102300f38:	e8 c2 07 f8	stur	x8, [x23, #0x7c]
102300f3c:	e0 c2 4b fc	ldur	d0, [x23, #0xbc]
102300f40:	e0 42 08 fc	stur	d0, [x23, #0x84]
102300f44:	e8 7f 42 f9	ldr	x8, [sp, #0x4f8]
102300f48:	e8 63 02 f9	str	x8, [sp, #0x4c0]
102300f4c:	e8 03 54 39	ldrb	w8, [sp, #0x500]
102300f50:	e8 23 13 39	strb	w8, [sp, #0x4c8]
102300f54:	f4 8f 44 b9	ldr	w20, [sp, #0x48c]
102300f58:	e2 27 40 f9	ldr	x2, [sp, #0x48]
102300f5c:	9f 02 02 6b	cmp	w20, w2
102300f60:	f4 03 02 aa	mov	x20, x2
102300f64:	60 02 00 54	b.eq	0x102300fb0
102300f68:	e8 83 13 91	add	x8, sp, #0x4e0
102300f6c:	e0 03 12 91	add	x0, sp, #0x480
102300f70:	21 00 80 52	mov	w1, #0x1
102300f74:	e2 03 14 aa	mov	x2, x20
102300f78:	b1 68 00 94	bl	__ZNK2nc7NdArrayIdNSt3__19allocatorIdEEE6repeatEjj
102300f7c:	e8 83 52 39	ldrb	w8, [sp, #0x4a0]
102300f80:	88 00 00 34	cbz	w8, 0x102300f90
102300f84:	e0 4f 42 f9	ldr	x0, [sp, #0x498]
102300f88:	40 00 00 b4	cbz	x0, 0x102300f90
102300f8c:	cb 42 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102300f90:	e8 42 4b f8	ldur	x8, [x23, #0xb4]
102300f94:	e8 42 05 f8	stur	x8, [x23, #0x54]
102300f98:	e0 c2 4b fc	ldur	d0, [x23, #0xbc]
102300f9c:	e0 c2 05 fc	stur	d0, [x23, #0x5c]
102300fa0:	e8 7f 42 f9	ldr	x8, [sp, #0x4f8]
102300fa4:	e8 4f 02 f9	str	x8, [sp, #0x498]
102300fa8:	e8 03 54 39	ldrb	w8, [sp, #0x500]
102300fac:	e8 83 12 39	strb	w8, [sp, #0x4a0]
102300fb0:	e8 67 44 b9	ldr	w8, [sp, #0x464]
102300fb4:	1f 01 14 6b	cmp	w8, w20
102300fb8:	60 02 00 54	b.eq	0x102301004
102300fbc:	e8 83 13 91	add	x8, sp, #0x4e0
102300fc0:	e0 63 11 91	add	x0, sp, #0x458
102300fc4:	21 00 80 52	mov	w1, #0x1
102300fc8:	e2 03 14 aa	mov	x2, x20
102300fcc:	c2 67 00 94	bl	__ZNK2nc7NdArrayIiNSt3__19allocatorIiEEE6repeatEjj
102300fd0:	e8 e3 51 39	ldrb	w8, [sp, #0x478]
102300fd4:	88 00 00 34	cbz	w8, 0x102300fe4
102300fd8:	e0 3b 42 f9	ldr	x0, [sp, #0x470]
102300fdc:	40 00 00 b4	cbz	x0, 0x102300fe4
102300fe0:	b6 42 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102300fe4:	e8 42 4b f8	ldur	x8, [x23, #0xb4]
102300fe8:	e8 c2 02 f8	stur	x8, [x23, #0x2c]
102300fec:	e0 c2 4b fc	ldur	d0, [x23, #0xbc]
102300ff0:	e0 42 03 fc	stur	d0, [x23, #0x34]
102300ff4:	e8 7f 42 f9	ldr	x8, [sp, #0x4f8]
102300ff8:	e8 3b 02 f9	str	x8, [sp, #0x470]
102300ffc:	e8 03 54 39	ldrb	w8, [sp, #0x500]
102301000:	e8 e3 11 39	strb	w8, [sp, #0x478]
102301004:	e8 3f 44 b9	ldr	w8, [sp, #0x43c]
102301008:	1f 01 14 6b	cmp	w8, w20
10230100c:	60 02 00 54	b.eq	0x102301058
102301010:	e8 83 13 91	add	x8, sp, #0x4e0
102301014:	e0 c3 10 91	add	x0, sp, #0x430
102301018:	21 00 80 52	mov	w1, #0x1
10230101c:	e2 03 14 aa	mov	x2, x20
102301020:	ad 67 00 94	bl	__ZNK2nc7NdArrayIiNSt3__19allocatorIiEEE6repeatEjj
102301024:	e8 43 51 39	ldrb	w8, [sp, #0x450]
102301028:	88 00 00 34	cbz	w8, 0x102301038
10230102c:	e0 27 42 f9	ldr	x0, [sp, #0x448]
102301030:	40 00 00 b4	cbz	x0, 0x102301038
102301034:	a1 42 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102301038:	e8 42 4b f8	ldur	x8, [x23, #0xb4]
10230103c:	e8 42 00 f8	stur	x8, [x23, #0x4]
102301040:	e0 c2 4b fc	ldur	d0, [x23, #0xbc]
102301044:	e0 c2 00 fc	stur	d0, [x23, #0xc]
102301048:	e8 7f 42 f9	ldr	x8, [sp, #0x4f8]
10230104c:	e8 27 02 f9	str	x8, [sp, #0x448]
102301050:	e8 03 54 39	ldrb	w8, [sp, #0x500]
102301054:	e8 43 11 39	strb	w8, [sp, #0x450]
102301058:	c8 09 e8 d2	mov	x8, #0x404e000000000000
10230105c:	00 01 67 9e	fmov	d0, x8
102301060:	e1 0f c0 3d	ldr	q1, [sp, #0x30]
102301064:	29 08 60 1e	fmul	d9, d1, d0
102301068:	e8 23 10 91	add	x8, sp, #0x408
10230106c:	e0 03 12 91	add	x0, sp, #0x480
102301070:	20 41 60 1e	fmov	d0, d9
102301074:	09 07 00 94	bl	__ZN2ncdvIdEENS_7NdArrayIT_NSt3__19allocatorIS2_EEEES2_RKS6_
102301078:	fb 23 00 b9	str	w27, [sp, #0x20]
10230107c:	e8 83 0f 91	add	x8, sp, #0x3e0
102301080:	e0 a3 12 91	add	x0, sp, #0x4a8
102301084:	20 41 60 1e	fmov	d0, d9
102301088:	04 07 00 94	bl	__ZN2ncdvIdEENS_7NdArrayIT_NSt3__19allocatorIS2_EEEES2_RKS6_
10230108c:	ff eb 01 f9	str	xzr, [sp, #0x3d0]
102301090:	ff e7 01 f9	str	xzr, [sp, #0x3c8]
102301094:	ff ef 01 f9	str	xzr, [sp, #0x3d8]
102301098:	f4 0c 00 34	cbz	w20, 0x102301234
10230109c:	1c 00 80 d2	mov	x28, #0x0
1023010a0:	e8 63 1a 91	add	x8, sp, #0x698
1023010a4:	14 31 04 91	add	x20, x8, #0x10c
1023010a8:	19 e1 01 91	add	x25, x8, #0x78
1023010ac:	1b 51 01 91	add	x27, x8, #0x54
1023010b0:	17 b1 00 91	add	x23, x8, #0x2c
1023010b4:	b5 86 42 d3	ubfx	x21, x21, #2, #32
1023010b8:	b6 7f 01 d0	adrp	x22, 12278 ; 0x1052f7000
1023010bc:	d6 c2 26 91	add	x22, x22, #0x9b0
1023010c0:	06 00 00 14	b	0x1023010d8
1023010c4:	e0 e3 0c 91	add	x0, sp, #0x338
1023010c8:	fa 60 00 94	bl	__ZN6madmom13BarStateSpaceD2Ev
1023010cc:	9c 07 00 91	add	x28, x28, #0x1
1023010d0:	bf 02 1c eb	cmp	x21, x28
1023010d4:	00 0b 00 54	b.eq	0x102301234
1023010d8:	88 f7 7e d3	lsl	x8, x28, #2
1023010dc:	e9 37 40 f9	ldr	x9, [sp, #0x68]
1023010e0:	21 69 68 b8	ldr	w1, [x9, x8]
1023010e4:	e9 13 42 f9	ldr	x9, [sp, #0x420]
1023010e8:	8a f3 7d d3	lsl	x10, x28, #3
1023010ec:	20 69 6a fc	ldr	d0, [x9, x10]
1023010f0:	e9 ff 41 f9	ldr	x9, [sp, #0x3f8]
1023010f4:	21 69 6a fc	ldr	d1, [x9, x10]
1023010f8:	e9 3b 42 f9	ldr	x9, [sp, #0x470]
1023010fc:	22 69 68 b8	ldr	w2, [x9, x8]
102301100:	e0 e3 0c 91	add	x0, sp, #0x338
102301104:	1b 2c 00 94	bl	__ZN6madmom13BarStateSpaceC2Eiddi
102301108:	e8 27 42 f9	ldr	x8, [sp, #0x448]
10230110c:	02 79 7c b8	ldr	w2, [x8, x28, lsl #2]
102301110:	e0 63 1a 91	add	x0, sp, #0x698
102301114:	e1 e3 0c 91	add	x1, sp, #0x338
102301118:	8c 3d 00 94	bl	__ZN6madmom18BarTransitionModelC2ERKNS_13BarStateSpaceEi
10230111c:	e0 03 0c 91	add	x0, sp, #0x300
102301120:	e1 e3 0c 91	add	x1, sp, #0x338
102301124:	e2 03 18 aa	mov	x2, x24
102301128:	0a 56 00 94	bl	__ZN6madmom35RNNDownBeatTrackingObservationModelC2ERKNS_13BarStateSpaceEi
10230112c:	ff 7b 01 f9	str	xzr, [sp, #0x2f0]
102301130:	00 e4 00 6f	movi.2d	v0, #0000000000000000
102301134:	e0 83 16 ad	stp	q0, q0, [sp, #0x2d0]
102301138:	e0 83 13 91	add	x0, sp, #0x4e0
10230113c:	e1 63 1a 91	add	x1, sp, #0x698
102301140:	e2 03 0c 91	add	x2, sp, #0x300
102301144:	e3 43 0b 91	add	x3, sp, #0x2d0
102301148:	3b 6d 00 94	bl	__ZN6madmom17HiddenMarkovModelINS_18BarTransitionModelENS_35RNNDownBeatTrackingObservationModelEEC2ERKS1_RKS2_RKN2nc7NdArrayIdNSt3__19allocatorIdEEEE
10230114c:	fa eb 41 f9	ldr	x26, [sp, #0x3d0]
102301150:	e8 ef 41 f9	ldr	x8, [sp, #0x3d8]
102301154:	5f 03 08 eb	cmp	x26, x8
102301158:	e2 00 00 54	b.hs	0x102301174
10230115c:	e1 83 13 91	add	x1, sp, #0x4e0
102301160:	e0 03 1a aa	mov	x0, x26
102301164:	93 6f 00 94	bl	__ZN6madmom17HiddenMarkovModelINS_18BarTransitionModelENS_35RNNDownBeatTrackingObservationModelEEC1EOS3_
102301168:	48 e3 06 91	add	x8, x26, #0x1b8
10230116c:	e8 eb 01 f9	str	x8, [sp, #0x3d0]
102301170:	04 00 00 14	b	0x102301180
102301174:	e0 23 0f 91	add	x0, sp, #0x3c8
102301178:	e1 83 13 91	add	x1, sp, #0x4e0
10230117c:	38 6f 00 94	bl	__ZNSt3__16vectorIN6madmom17HiddenMarkovModelINS1_18BarTransitionModelENS1_35RNNDownBeatTrackingObservationModelEEENS_9allocatorIS5_EEE21__push_back_slow_pathIS5_EEvOT_
102301180:	e0 83 13 91	add	x0, sp, #0x4e0
102301184:	77 60 00 94	bl	__ZN6madmom17HiddenMarkovModelINS_18BarTransitionModelENS_35RNNDownBeatTrackingObservationModelEED2Ev
102301188:	e8 c3 4b 39	ldrb	w8, [sp, #0x2f0]
10230118c:	88 00 00 34	cbz	w8, 0x10230119c
102301190:	e0 77 41 f9	ldr	x0, [sp, #0x2e8]
102301194:	40 00 00 b4	cbz	x0, 0x10230119c
102301198:	48 42 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10230119c:	f6 83 01 f9	str	x22, [sp, #0x300]
1023011a0:	e8 a3 4c 39	ldrb	w8, [sp, #0x328]
1023011a4:	88 00 00 34	cbz	w8, 0x1023011b4
1023011a8:	e0 93 41 f9	ldr	x0, [sp, #0x320]
1023011ac:	40 00 00 b4	cbz	x0, 0x1023011b4
1023011b0:	42 42 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
1023011b4:	e8 03 5f 39	ldrb	w8, [sp, #0x7c0]
1023011b8:	88 00 00 34	cbz	w8, 0x1023011c8
1023011bc:	e0 df 43 f9	ldr	x0, [sp, #0x7b8]
1023011c0:	40 00 00 b4	cbz	x0, 0x1023011c8
1023011c4:	3d 42 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
1023011c8:	ff df 03 f9	str	xzr, [sp, #0x7b8]
1023011cc:	ff 03 1f 39	strb	wzr, [sp, #0x7c0]
1023011d0:	9f 7e 00 a9	stp	xzr, xzr, [x20]
1023011d4:	e0 03 19 aa	mov	x0, x25
1023011d8:	b6 60 00 94	bl	__ZN6madmom13BarStateSpaceD2Ev
1023011dc:	e8 23 5c 39	ldrb	w8, [sp, #0x708]
1023011e0:	88 00 00 34	cbz	w8, 0x1023011f0
1023011e4:	e0 83 43 f9	ldr	x0, [sp, #0x700]
1023011e8:	40 00 00 b4	cbz	x0, 0x1023011f0
1023011ec:	33 42 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
1023011f0:	ff 83 03 f9	str	xzr, [sp, #0x700]
1023011f4:	ff 23 1c 39	strb	wzr, [sp, #0x708]
1023011f8:	7f 7f 00 a9	stp	xzr, xzr, [x27]
1023011fc:	e8 83 5b 39	ldrb	w8, [sp, #0x6e0]
102301200:	88 00 00 34	cbz	w8, 0x102301210
102301204:	e0 6f 43 f9	ldr	x0, [sp, #0x6d8]
102301208:	40 00 00 b4	cbz	x0, 0x102301210
10230120c:	2b 42 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102301210:	ff 6f 03 f9	str	xzr, [sp, #0x6d8]
102301214:	ff 83 1b 39	strb	wzr, [sp, #0x6e0]
102301218:	ff 7e 00 a9	stp	xzr, xzr, [x23]
10230121c:	e8 e3 5a 39	ldrb	w8, [sp, #0x6b8]
102301220:	28 f5 ff 34	cbz	w8, 0x1023010c4
102301224:	e0 5b 43 f9	ldr	x0, [sp, #0x6b0]
102301228:	e0 f4 ff b4	cbz	x0, 0x1023010c4
10230122c:	23 42 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102301230:	a5 ff ff 17	b	0x1023010c4
102301234:	e0 e3 0c 91	add	x0, sp, #0x338
102301238:	e1 03 13 aa	mov	x1, x19
10230123c:	0d a6 96 97	bl	__ZN2nc7NdArrayIfNSt3__19allocatorIfEEEC2ERKS4_
102301240:	08 21 20 1e	fcmp	s8, #0.0
102301244:	00 02 00 54	b.eq	0x102301284
102301248:	e8 83 13 91	add	x8, sp, #0x4e0
10230124c:	e0 03 13 aa	mov	x0, x19
102301250:	00 41 20 1e	fmov	s0, s8
102301254:	2b 07 00 94	bl	__ZN6madmom21threshold_activationsIfEENSt3__15tupleIJN2nc7NdArrayIT_NS1_9allocatorIS5_EEEEiEEERKS8_S5_
102301258:	e0 e3 0c 91	add	x0, sp, #0x338
10230125c:	e1 83 13 91	add	x1, sp, #0x4e0
102301260:	e1 74 96 97	bl	__ZN2nc7NdArrayIfNSt3__19allocatorIfEEEaSERKS4_
102301264:	fc c3 10 91	add	x28, sp, #0x430
102301268:	f5 0b 45 b9	ldr	w21, [sp, #0x508]
10230126c:	e8 03 54 39	ldrb	w8, [sp, #0x500]
102301270:	e8 00 00 34	cbz	w8, 0x10230128c
102301274:	e0 7f 42 f9	ldr	x0, [sp, #0x4f8]
102301278:	a0 00 00 b4	cbz	x0, 0x10230128c
10230127c:	0f 42 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102301280:	03 00 00 14	b	0x10230128c
102301284:	15 00 80 52	mov	w21, #0x0
102301288:	fc c3 10 91	add	x28, sp, #0x430
10230128c:	e8 83 13 91	add	x8, sp, #0x4e0
102301290:	e0 e3 0c 91	add	x0, sp, #0x338
102301294:	01 00 80 52	mov	w1, #0x0
102301298:	d3 07 00 94	bl	__ZNK2nc7NdArrayIfNSt3__19allocatorIfEEE3anyENS_4AxisE
10230129c:	e0 7f 42 f9	ldr	x0, [sp, #0x4f8]
1023012a0:	14 00 40 39	ldrb	w20, [x0]
1023012a4:	e8 03 54 39	ldrb	w8, [sp, #0x500]
1023012a8:	48 00 00 34	cbz	w8, 0x1023012b0
1023012ac:	03 42 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
1023012b0:	f4 0a 00 34	cbz	w20, 0x10230140c
1023012b4:	f5 1f 00 b9	str	w21, [sp, #0x1c]
1023012b8:	ff 63 01 f9	str	xzr, [sp, #0x2c0]
1023012bc:	ff 5f 01 f9	str	xzr, [sp, #0x2b8]
1023012c0:	ff 67 01 f9	str	xzr, [sp, #0x2c8]
1023012c4:	ff 57 01 f9	str	xzr, [sp, #0x2a8]
1023012c8:	ff 53 01 f9	str	xzr, [sp, #0x2a0]
1023012cc:	ff 5b 01 f9	str	xzr, [sp, #0x2b0]
1023012d0:	f7 e7 41 f9	ldr	x23, [sp, #0x3c8]
1023012d4:	f4 eb 41 f9	ldr	x20, [sp, #0x3d0]
1023012d8:	ff 02 14 eb	cmp	x23, x20
1023012dc:	60 0a 00 54	b.eq	0x102301428
1023012e0:	f5 ef 7d b2	mov	x21, #0x7ffffffffffffff8
1023012e4:	16 00 fc 92	mov	x22, #0x1fffffffffffffff
1023012e8:	04 00 00 14	b	0x1023012f8
1023012ec:	f7 e2 06 91	add	x23, x23, #0x1b8
1023012f0:	ff 02 14 eb	cmp	x23, x20
1023012f4:	60 08 00 54	b.eq	0x102301400
1023012f8:	e8 83 13 91	add	x8, sp, #0x4e0
1023012fc:	e1 e3 0c 91	add	x1, sp, #0x338
102301300:	e0 03 17 aa	mov	x0, x23
102301304:	b0 08 00 94	bl	__ZN6madmom17HiddenMarkovModelINS_18BarTransitionModelENS_35RNNDownBeatTrackingObservationModelEE7viterbiERKN2nc7NdArrayIfNSt3__19allocatorIfEEEE
102301308:	f8 63 41 f9	ldr	x24, [sp, #0x2c0]
10230130c:	e8 67 41 f9	ldr	x8, [sp, #0x2c8]
102301310:	1f 03 08 eb	cmp	x24, x8
102301314:	e0 00 00 54	b.eq	0x102301330
102301318:	e1 83 13 91	add	x1, sp, #0x4e0
10230131c:	e0 03 18 aa	mov	x0, x24
102301320:	15 65 00 94	bl	__ZN2nc7NdArrayIjNSt3__19allocatorIjEEEC2ERKS4_
102301324:	08 a3 00 91	add	x8, x24, #0x28
102301328:	e8 63 01 f9	str	x8, [sp, #0x2c0]
10230132c:	04 00 00 14	b	0x10230133c
102301330:	e0 e3 0a 91	add	x0, sp, #0x2b8
102301334:	e1 83 13 91	add	x1, sp, #0x4e0
102301338:	57 76 00 94	bl	__ZNSt3__16vectorIN2nc7NdArrayIjNS_9allocatorIjEEEENS3_IS5_EEE21__push_back_slow_pathIRKS5_EEvOT_
10230133c:	e8 57 41 f9	ldr	x8, [sp, #0x2a8]
102301340:	e9 5b 41 f9	ldr	x9, [sp, #0x2b0]
102301344:	1f 01 09 eb	cmp	x8, x9
102301348:	c0 00 00 54	b.eq	0x102301360
10230134c:	e0 87 42 fd	ldr	d0, [sp, #0x508]
102301350:	00 85 00 fc	str	d0, [x8], #0x8
102301354:	e8 57 01 f9	str	x8, [sp, #0x2a8]
102301358:	fc c3 10 91	add	x28, sp, #0x430
10230135c:	23 00 00 14	b	0x1023013e8
102301360:	f8 53 41 f9	ldr	x24, [sp, #0x2a0]
102301364:	19 01 18 cb	sub	x25, x8, x24
102301368:	3b ff 43 93	asr	x27, x25, #3
10230136c:	68 07 00 91	add	x8, x27, #0x1
102301370:	09 fd 7d d3	lsr	x9, x8, #61
102301374:	29 94 00 b5	cbnz	x9, 0x1023025f8
102301378:	29 ff 42 93	asr	x9, x25, #2
10230137c:	3f 01 08 eb	cmp	x9, x8
102301380:	28 81 88 9a	csel	x8, x9, x8, hi
102301384:	3f 03 15 eb	cmp	x25, x21
102301388:	1c 31 96 9a	csel	x28, x8, x22, lo
10230138c:	fc 00 00 b4	cbz	x28, 0x1023013a8
102301390:	88 ff 7d d3	lsr	x8, x28, #61
102301394:	88 93 00 b5	cbnz	x8, 0x102302604
102301398:	80 f3 7d d3	lsl	x0, x28, #3
10230139c:	cd 41 47 94	bl	0x1034d1ad0 ; symbol stub for: __Znwm
1023013a0:	fa 03 00 aa	mov	x26, x0
1023013a4:	02 00 00 14	b	0x1023013ac
1023013a8:	1a 00 80 d2	mov	x26, #0x0
1023013ac:	5b 0f 1b 8b	add	x27, x26, x27, lsl #3
1023013b0:	5c 0f 1c 8b	add	x28, x26, x28, lsl #3
1023013b4:	e0 87 42 fd	ldr	d0, [sp, #0x508]
1023013b8:	60 87 00 fc	str	d0, [x27], #0x8
1023013bc:	e0 03 1a aa	mov	x0, x26
1023013c0:	e1 03 18 aa	mov	x1, x24
1023013c4:	e2 03 19 aa	mov	x2, x25
1023013c8:	a1 44 47 94	bl	0x1034d264c ; symbol stub for: _memmove
1023013cc:	fa 53 01 f9	str	x26, [sp, #0x2a0]
1023013d0:	fb 57 01 f9	str	x27, [sp, #0x2a8]
1023013d4:	fc 5b 01 f9	str	x28, [sp, #0x2b0]
1023013d8:	fc c3 10 91	add	x28, sp, #0x430
1023013dc:	78 00 00 b4	cbz	x24, 0x1023013e8
1023013e0:	e0 03 18 aa	mov	x0, x24
1023013e4:	b5 41 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
1023013e8:	e8 03 54 39	ldrb	w8, [sp, #0x500]
1023013ec:	08 f8 ff 34	cbz	w8, 0x1023012ec
1023013f0:	e0 7f 42 f9	ldr	x0, [sp, #0x4f8]
1023013f4:	c0 f7 ff b4	cbz	x0, 0x1023012ec
1023013f8:	b0 41 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
1023013fc:	bc ff ff 17	b	0x1023012ec
102301400:	f4 57 41 f9	ldr	x20, [sp, #0x2a8]
102301404:	f5 53 41 f9	ldr	x21, [sp, #0x2a0]
102301408:	0a 00 00 14	b	0x102301430
10230140c:	88 a9 00 90	adrp	x8, 5424 ; 0x103831000
102301410:	00 fd c3 3d	ldr	q0, [x8, #0xff0]
102301414:	e8 17 40 f9	ldr	x8, [sp, #0x28]
102301418:	00 41 80 3c	stur	q0, [x8, #0x4]
10230141c:	1f 0d 00 f9	str	xzr, [x8, #0x18]
102301420:	1f 81 00 39	strb	wzr, [x8, #0x20]
102301424:	2f 04 00 14	b	0x1023024e0
102301428:	15 00 80 d2	mov	x21, #0x0
10230142c:	14 00 80 d2	mov	x20, #0x0
102301430:	96 02 15 cb	sub	x22, x20, x21
102301434:	c8 fe 43 d3	lsr	x8, x22, #3
102301438:	29 00 80 52	mov	w9, #0x1
10230143c:	e9 9f 06 b9	str	w9, [sp, #0x69c]
102301440:	e8 a3 06 b9	str	w8, [sp, #0x6a0]
102301444:	e8 a7 06 b9	str	w8, [sp, #0x6a4]
102301448:	ff ab 06 b9	str	wzr, [sp, #0x6a8]
10230144c:	ff 5b 03 f9	str	xzr, [sp, #0x6b0]
102301450:	ff e3 1a 39	strb	wzr, [sp, #0x6b8]
102301454:	c8 04 00 34	cbz	w8, 0x1023014ec
102301458:	c0 7e 7d 92	and	x0, x22, #0x7fffffff8
10230145c:	9d 41 47 94	bl	0x1034d1ad0 ; symbol stub for: __Znwm
102301460:	e0 5b 03 f9	str	x0, [sp, #0x6b0]
102301464:	28 00 80 52	mov	w8, #0x1
102301468:	e8 e3 1a 39	strb	w8, [sp, #0x6b8]
10230146c:	bf 02 14 eb	cmp	x21, x20
102301470:	e0 03 00 54	b.eq	0x1023014ec
102301474:	c8 22 00 d1	sub	x8, x22, #0x8
102301478:	1f e1 00 f1	cmp	x8, #0x38
10230147c:	c3 02 00 54	b.lo	0x1023014d4
102301480:	09 00 15 cb	sub	x9, x0, x21
102301484:	3f 01 01 f1	cmp	x9, #0x40
102301488:	63 02 00 54	b.lo	0x1023014d4
10230148c:	08 fd 43 d3	lsr	x8, x8, #3
102301490:	0a 05 00 91	add	x10, x8, #0x1
102301494:	4b e9 7d 92	and	x11, x10, #0x3ffffffffffffff8
102301498:	69 f1 7d d3	lsl	x9, x11, #3
10230149c:	a8 02 09 8b	add	x8, x21, x9
1023014a0:	09 00 09 8b	add	x9, x0, x9
1023014a4:	ac 82 00 91	add	x12, x21, #0x20
1023014a8:	0d 80 00 91	add	x13, x0, #0x20
1023014ac:	ee 03 0b aa	mov	x14, x11
1023014b0:	80 05 7f ad	ldp	q0, q1, [x12, #-0x20]
1023014b4:	82 0d c2 ac	ldp	q2, q3, [x12], #0x40
1023014b8:	a0 05 3f ad	stp	q0, q1, [x13, #-0x20]
1023014bc:	a2 0d 82 ac	stp	q2, q3, [x13], #0x40
1023014c0:	ce 21 00 f1	subs	x14, x14, #0x8
1023014c4:	61 ff ff 54	b.ne	0x1023014b0
1023014c8:	5f 01 0b eb	cmp	x10, x11
1023014cc:	81 00 00 54	b.ne	0x1023014dc
1023014d0:	07 00 00 14	b	0x1023014ec
1023014d4:	e8 03 15 aa	mov	x8, x21
1023014d8:	e9 03 00 aa	mov	x9, x0
1023014dc:	00 85 40 fc	ldr	d0, [x8], #0x8
1023014e0:	20 85 00 fc	str	d0, [x9], #0x8
1023014e4:	1f 01 14 eb	cmp	x8, x20
1023014e8:	a1 ff ff 54	b.ne	0x1023014dc
1023014ec:	e8 83 13 91	add	x8, sp, #0x4e0
1023014f0:	e0 63 1a 91	add	x0, sp, #0x698
1023014f4:	01 00 80 52	mov	w1, #0x0
1023014f8:	c6 62 00 94	bl	__ZNK2nc7NdArrayIdNSt3__19allocatorIdEEE6argmaxENS_4AxisE
1023014fc:	e0 7f 42 f9	ldr	x0, [sp, #0x4f8]
102301500:	14 00 40 b9	ldr	w20, [x0]
102301504:	e8 03 54 39	ldrb	w8, [sp, #0x500]
102301508:	48 00 00 34	cbz	w8, 0x102301510
10230150c:	6b 41 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102301510:	ff 7f 02 f9	str	xzr, [sp, #0x4f8]
102301514:	ff 03 14 39	strb	wzr, [sp, #0x500]
102301518:	9f c3 0b f8	stur	xzr, [x28, #0xbc]
10230151c:	9f 43 0b f8	stur	xzr, [x28, #0xb4]
102301520:	e8 e3 5a 39	ldrb	w8, [sp, #0x6b8]
102301524:	88 00 00 34	cbz	w8, 0x102301534
102301528:	e0 5b 43 f9	ldr	x0, [sp, #0x6b0]
10230152c:	40 00 00 b4	cbz	x0, 0x102301534
102301530:	62 41 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102301534:	e8 5f 41 f9	ldr	x8, [sp, #0x2b8]
102301538:	09 05 80 52	mov	w9, #0x28
10230153c:	97 22 09 9b	madd	x23, x20, x9, x8
102301540:	e8 0e 40 b9	ldr	w8, [x23, #0xc]
102301544:	28 42 00 34	cbz	w8, 0x102301d88
102301548:	f5 e7 41 f9	ldr	x21, [sp, #0x3c8]
10230154c:	08 37 80 52	mov	w8, #0x1b8
102301550:	88 56 08 9b	madd	x8, x20, x8, x21
102301554:	00 01 02 91	add	x0, x8, #0x80
102301558:	e8 03 0c 91	add	x8, sp, #0x300
10230155c:	e1 03 17 aa	mov	x1, x23
102301560:	d3 09 00 94	bl	__ZNK2nc7NdArrayIdNSt3__19allocatorIdEEEixINS0_IjNS2_IjEEEELi0EEES4_RKT_
102301564:	f8 e3 09 91	add	x24, sp, #0x278
102301568:	e8 e3 09 91	add	x8, sp, #0x278
10230156c:	e0 03 0c 91	add	x0, sp, #0x300
102301570:	0a 0a 00 94	bl	__ZNK2nc7NdArrayIdNSt3__19allocatorIdEEE6astypeIidLi0ELi0ELi0EEENS0_IT_NS2_IS6_EEEEv
102301574:	e1 4b 41 f9	ldr	x1, [sp, #0x290]
102301578:	e0 83 13 91	add	x0, sp, #0x4e0
10230157c:	6f b6 96 97	bl	__ZN2nc20NdArrayConstIteratorIiPilEC2ES1_
102301580:	f6 73 42 f9	ldr	x22, [sp, #0x4e0]
102301584:	f9 87 42 b9	ldr	w25, [sp, #0x284]
102301588:	e1 4b 41 f9	ldr	x1, [sp, #0x290]
10230158c:	e0 83 13 91	add	x0, sp, #0x4e0
102301590:	6a b6 96 97	bl	__ZN2nc20NdArrayConstIteratorIiPilEC2ES1_
102301594:	fa 03 08 91	add	x26, sp, #0x200
102301598:	08 63 00 91	add	x8, x24, #0x18
10230159c:	e9 73 42 f9	ldr	x9, [sp, #0x4e0]
1023015a0:	29 09 19 8b	add	x9, x9, x25, lsl #2
1023015a4:	df 02 09 eb	cmp	x22, x9
1023015a8:	c0 03 00 54	b.eq	0x102301620
1023015ac:	2a 01 16 cb	sub	x10, x9, x22
1023015b0:	4b 11 00 d1	sub	x11, x10, #0x4
1023015b4:	ea 03 16 aa	mov	x10, x22
1023015b8:	7f f1 00 f1	cmp	x11, #0x3c
1023015bc:	83 02 00 54	b.lo	0x10230160c
1023015c0:	6a fd 42 d3	lsr	x10, x11, #2
1023015c4:	4b 05 00 91	add	x11, x10, #0x1
1023015c8:	6c e9 7c 92	and	x12, x11, #0x7ffffffffffffff0
1023015cc:	ca 0a 0c 8b	add	x10, x22, x12, lsl #2
1023015d0:	cd 82 00 91	add	x13, x22, #0x20
1023015d4:	20 04 00 4f	movi.4s	v0, #0x1
1023015d8:	ee 03 0c aa	mov	x14, x12
1023015dc:	a1 09 7f ad	ldp	q1, q2, [x13, #-0x20]
1023015e0:	a3 11 40 ad	ldp	q3, q4, [x13]
1023015e4:	21 84 a0 4e	add.4s	v1, v1, v0
1023015e8:	42 84 a0 4e	add.4s	v2, v2, v0
1023015ec:	63 84 a0 4e	add.4s	v3, v3, v0
1023015f0:	84 84 a0 4e	add.4s	v4, v4, v0
1023015f4:	a1 09 3f ad	stp	q1, q2, [x13, #-0x20]
1023015f8:	a3 11 82 ac	stp	q3, q4, [x13], #0x40
1023015fc:	ce 41 00 f1	subs	x14, x14, #0x10
102301600:	e1 fe ff 54	b.ne	0x1023015dc
102301604:	7f 01 0c eb	cmp	x11, x12
102301608:	c0 00 00 54	b.eq	0x102301620
10230160c:	4b 01 40 b9	ldr	w11, [x10]
102301610:	6b 05 00 11	add	w11, w11, #0x1
102301614:	4b 45 00 b8	str	w11, [x10], #0x4
102301618:	5f 01 09 eb	cmp	x10, x9
10230161c:	81 ff ff 54	b.ne	0x10230160c
102301620:	f9 a3 03 91	add	x25, sp, #0xe8
102301624:	49 c3 47 f8	ldur	x9, [x26, #0x7c]
102301628:	49 43 0d f8	stur	x9, [x26, #0xd4]
10230162c:	40 43 48 fc	ldur	d0, [x26, #0x84]
102301630:	40 c3 0d fc	stur	d0, [x26, #0xdc]
102301634:	e9 4b 41 f9	ldr	x9, [sp, #0x290]
102301638:	e9 77 01 f9	str	x9, [sp, #0x2e8]
10230163c:	e9 63 4a 39	ldrb	w9, [sp, #0x298]
102301640:	e9 c3 0b 39	strb	w9, [sp, #0x2f0]
102301644:	5f 43 08 f8	stur	xzr, [x26, #0x84]
102301648:	5f c3 07 f8	stur	xzr, [x26, #0x7c]
10230164c:	1f 21 00 39	strb	wzr, [x8, #0x8]
102301650:	1f 01 00 f9	str	xzr, [x8]
102301654:	ff 37 01 f9	str	xzr, [sp, #0x268]
102301658:	ff c3 09 39	strb	wzr, [sp, #0x270]
10230165c:	5f c3 05 f8	stur	xzr, [x26, #0x5c]
102301660:	5f 43 05 f8	stur	xzr, [x26, #0x54]
102301664:	e8 23 40 b9	ldr	w8, [sp, #0x20]
102301668:	e8 39 00 34	cbz	w8, 0x102301da4
10230166c:	08 37 80 52	mov	w8, #0x1b8
102301670:	88 7e 08 9b	mul	x8, x20, x8
102301674:	a8 02 08 8b	add	x8, x21, x8
102301678:	00 e1 04 91	add	x0, x8, #0x138
10230167c:	e8 83 13 91	add	x8, sp, #0x4e0
102301680:	e1 03 17 aa	mov	x1, x23
102301684:	95 0a 00 94	bl	__ZNK2nc7NdArrayIjNSt3__19allocatorIjEEEixIS4_Li0EEES4_RKT_
102301688:	e8 a3 08 91	add	x8, sp, #0x228
10230168c:	e0 83 13 91	add	x0, sp, #0x4e0
102301690:	21 00 80 52	mov	w1, #0x1
102301694:	15 0a 00 94	bl	__ZN2ncgeIjEENS_7NdArrayIbNSt3__19allocatorIbEEEERKNS1_IT_NS3_IS6_EEEES6_
102301698:	e8 03 54 39	ldrb	w8, [sp, #0x500]
10230169c:	88 00 00 34	cbz	w8, 0x1023016ac
1023016a0:	e0 7f 42 f9	ldr	x0, [sp, #0x4f8]
1023016a4:	40 00 00 b4	cbz	x0, 0x1023016ac
1023016a8:	04 41 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
1023016ac:	e1 23 41 f9	ldr	x1, [sp, #0x240]
1023016b0:	e0 83 13 91	add	x0, sp, #0x4e0
1023016b4:	7e 4f 00 94	bl	__ZN2nc20NdArrayConstIteratorIbPKblEC2ES2_
1023016b8:	f4 73 42 f9	ldr	x20, [sp, #0x4e0]
1023016bc:	f5 37 42 b9	ldr	w21, [sp, #0x234]
1023016c0:	e1 23 41 f9	ldr	x1, [sp, #0x240]
1023016c4:	e0 83 13 91	add	x0, sp, #0x4e0
1023016c8:	79 4f 00 94	bl	__ZN2nc20NdArrayConstIteratorIbPKblEC2ES2_
1023016cc:	e8 73 42 f9	ldr	x8, [sp, #0x4e0]
1023016d0:	08 01 15 8b	add	x8, x8, x21
1023016d4:	9f 02 08 eb	cmp	x20, x8
1023016d8:	20 43 00 54	b.eq	0x102301f3c
1023016dc:	f5 63 1a 91	add	x21, sp, #0x698
1023016e0:	89 06 00 91	add	x9, x20, #0x1
1023016e4:	2a f1 5f 38	ldurb	w10, [x9, #-0x1]
1023016e8:	5f 01 00 71	cmp	w10, #0x0
1023016ec:	24 01 48 fa	ccmp	x9, x8, #0x4, eq
1023016f0:	29 05 00 91	add	x9, x9, #0x1
1023016f4:	81 ff ff 54	b.ne	0x1023016e4
1023016f8:	2a 42 00 34	cbz	w10, 0x102301f3c
1023016fc:	e8 83 13 91	add	x8, sp, #0x4e0
102301700:	e0 a3 08 91	add	x0, sp, #0x228
102301704:	48 0c 00 94	bl	__ZNK2nc7NdArrayIbNSt3__19allocatorIbEEE6astypeIibLi0ELi0ELi0EEENS0_IT_NS2_IS6_EEEEv
102301708:	e8 03 08 91	add	x8, sp, #0x200
10230170c:	e0 83 13 91	add	x0, sp, #0x4e0
102301710:	01 00 80 52	mov	w1, #0x0
102301714:	ac 0a 00 94	bl	__ZN2nc4diffIiEENS_7NdArrayIT_NSt3__19allocatorIS2_EEEERKS6_NS_4AxisE
102301718:	e8 03 54 39	ldrb	w8, [sp, #0x500]
10230171c:	88 00 00 34	cbz	w8, 0x10230172c
102301720:	e0 7f 42 f9	ldr	x0, [sp, #0x4f8]
102301724:	40 00 00 b4	cbz	x0, 0x10230172c
102301728:	e4 40 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10230172c:	e8 83 13 91	add	x8, sp, #0x4e0
102301730:	e0 03 08 91	add	x0, sp, #0x200
102301734:	f7 75 00 94	bl	__ZNK2nc7NdArrayIiNSt3__19allocatorIiEEE7nonzeroEv
102301738:	e8 ef 44 b9	ldr	w8, [sp, #0x4ec]
10230173c:	e8 41 00 34	cbz	w8, 0x102301f78
102301740:	e8 17 45 b9	ldr	w8, [sp, #0x514]
102301744:	a8 41 00 34	cbz	w8, 0x102301f78
102301748:	e8 83 13 91	add	x8, sp, #0x4e0
10230174c:	01 a1 00 91	add	x1, x8, #0x28
102301750:	f6 c3 06 91	add	x22, sp, #0x1b0
102301754:	e0 c3 06 91	add	x0, sp, #0x1b0
102301758:	07 64 00 94	bl	__ZN2nc7NdArrayIjNSt3__19allocatorIjEEEC2ERKS4_
10230175c:	e1 e7 40 f9	ldr	x1, [sp, #0x1c8]
102301760:	e0 63 1a 91	add	x0, sp, #0x698
102301764:	74 d9 96 97	bl	__ZN2nc20NdArrayConstIteratorIjPjlEC2ES1_
102301768:	f4 4f 43 f9	ldr	x20, [sp, #0x698]
10230176c:	f7 bf 41 b9	ldr	w23, [sp, #0x1bc]
102301770:	e1 e7 40 f9	ldr	x1, [sp, #0x1c8]
102301774:	e0 63 1a 91	add	x0, sp, #0x698
102301778:	6f d9 96 97	bl	__ZN2nc20NdArrayConstIteratorIjPjlEC2ES1_
10230177c:	c8 62 00 91	add	x8, x22, #0x18
102301780:	e9 4f 43 f9	ldr	x9, [sp, #0x698]
102301784:	29 09 17 8b	add	x9, x9, x23, lsl #2
102301788:	9f 02 09 eb	cmp	x20, x9
10230178c:	c0 03 00 54	b.eq	0x102301804
102301790:	2a 01 14 cb	sub	x10, x9, x20
102301794:	4b 11 00 d1	sub	x11, x10, #0x4
102301798:	ea 03 14 aa	mov	x10, x20
10230179c:	7f f1 00 f1	cmp	x11, #0x3c
1023017a0:	83 02 00 54	b.lo	0x1023017f0
1023017a4:	6a fd 42 d3	lsr	x10, x11, #2
1023017a8:	4b 05 00 91	add	x11, x10, #0x1
1023017ac:	6c e9 7c 92	and	x12, x11, #0x7ffffffffffffff0
1023017b0:	8a 0a 0c 8b	add	x10, x20, x12, lsl #2
1023017b4:	8d 82 00 91	add	x13, x20, #0x20
1023017b8:	20 04 00 4f	movi.4s	v0, #0x1
1023017bc:	ee 03 0c aa	mov	x14, x12
1023017c0:	a1 09 7f ad	ldp	q1, q2, [x13, #-0x20]
1023017c4:	a3 11 40 ad	ldp	q3, q4, [x13]
1023017c8:	21 84 a0 4e	add.4s	v1, v1, v0
1023017cc:	42 84 a0 4e	add.4s	v2, v2, v0
1023017d0:	63 84 a0 4e	add.4s	v3, v3, v0
1023017d4:	84 84 a0 4e	add.4s	v4, v4, v0
1023017d8:	a1 09 3f ad	stp	q1, q2, [x13, #-0x20]
1023017dc:	a3 11 82 ac	stp	q3, q4, [x13], #0x40
1023017e0:	ce 41 00 f1	subs	x14, x14, #0x10
1023017e4:	e1 fe ff 54	b.ne	0x1023017c0
1023017e8:	7f 01 0c eb	cmp	x11, x12
1023017ec:	c0 00 00 54	b.eq	0x102301804
1023017f0:	4b 01 40 b9	ldr	w11, [x10]
1023017f4:	6b 05 00 11	add	w11, w11, #0x1
1023017f8:	4b 45 00 b8	str	w11, [x10], #0x4
1023017fc:	5f 01 09 eb	cmp	x10, x9
102301800:	81 ff ff 54	b.ne	0x1023017f0
102301804:	29 c3 4c f8	ldur	x9, [x25, #0xcc]
102301808:	29 43 0f f8	stur	x9, [x25, #0xf4]
10230180c:	20 43 4d fc	ldur	d0, [x25, #0xd4]
102301810:	20 c3 0f fc	stur	d0, [x25, #0xfc]
102301814:	e9 e7 40 f9	ldr	x9, [sp, #0x1c8]
102301818:	e9 fb 00 f9	str	x9, [sp, #0x1f0]
10230181c:	e9 43 47 39	ldrb	w9, [sp, #0x1d0]
102301820:	e9 e3 07 39	strb	w9, [sp, #0x1f8]
102301824:	3f 43 0d f8	stur	xzr, [x25, #0xd4]
102301828:	3f c3 0c f8	stur	xzr, [x25, #0xcc]
10230182c:	1f 21 00 39	strb	wzr, [x8, #0x8]
102301830:	1f 01 00 f9	str	xzr, [x8]
102301834:	e8 23 41 f9	ldr	x8, [sp, #0x240]
102301838:	09 01 40 39	ldrb	w9, [x8]
10230183c:	69 06 00 34	cbz	w9, 0x102301908
102301840:	e0 17 c0 3d	ldr	q0, [sp, #0x50]
102301844:	a0 42 80 3c	stur	q0, [x21, #0x4]
102301848:	80 00 80 52	mov	w0, #0x4
10230184c:	a1 40 47 94	bl	0x1034d1ad0 ; symbol stub for: __Znwm
102301850:	e0 5b 03 f9	str	x0, [sp, #0x6b0]
102301854:	28 00 80 52	mov	w8, #0x1
102301858:	e8 e3 1a 39	strb	w8, [sp, #0x6b8]
10230185c:	1f 00 00 b9	str	wzr, [x0]
102301860:	f4 63 1a 91	add	x20, sp, #0x698
102301864:	97 a2 00 91	add	x23, x20, #0x28
102301868:	e1 63 07 91	add	x1, sp, #0x1d8
10230186c:	e0 03 17 aa	mov	x0, x23
102301870:	c1 63 00 94	bl	__ZN2nc7NdArrayIjNSt3__19allocatorIjEEEC2ERKS4_
102301874:	48 00 80 52	mov	w8, #0x2
102301878:	f4 23 16 a9	stp	x20, x8, [sp, #0x160]
10230187c:	e8 23 06 91	add	x8, sp, #0x188
102301880:	e0 83 05 91	add	x0, sp, #0x160
102301884:	9d 6a 00 94	bl	__ZN2nc12column_stackIjEENS_7NdArrayIT_NSt3__19allocatorIS2_EEEERKSt16initializer_listIS6_E
102301888:	e8 e3 47 39	ldrb	w8, [sp, #0x1f8]
10230188c:	88 00 00 34	cbz	w8, 0x10230189c
102301890:	e0 fb 40 f9	ldr	x0, [sp, #0x1f0]
102301894:	40 00 00 b4	cbz	x0, 0x10230189c
102301898:	88 40 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10230189c:	28 43 4a f8	ldur	x8, [x25, #0xa4]
1023018a0:	28 43 0f f8	stur	x8, [x25, #0xf4]
1023018a4:	20 c3 4a fc	ldur	d0, [x25, #0xac]
1023018a8:	20 c3 0f fc	stur	d0, [x25, #0xfc]
1023018ac:	e8 d3 40 f9	ldr	x8, [sp, #0x1a0]
1023018b0:	e8 fb 00 f9	str	x8, [sp, #0x1f0]
1023018b4:	e8 a3 46 39	ldrb	w8, [sp, #0x1a8]
1023018b8:	e8 e3 07 39	strb	w8, [sp, #0x1f8]
1023018bc:	3f c3 0a f8	stur	xzr, [x25, #0xac]
1023018c0:	3f 43 0a f8	stur	xzr, [x25, #0xa4]
1023018c4:	ff d3 00 f9	str	xzr, [sp, #0x1a0]
1023018c8:	ff a3 06 39	strb	wzr, [sp, #0x1a8]
1023018cc:	e8 83 5b 39	ldrb	w8, [sp, #0x6e0]
1023018d0:	88 00 00 34	cbz	w8, 0x1023018e0
1023018d4:	e0 6f 43 f9	ldr	x0, [sp, #0x6d8]
1023018d8:	40 00 00 b4	cbz	x0, 0x1023018e0
1023018dc:	77 40 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
1023018e0:	ff 6f 03 f9	str	xzr, [sp, #0x6d8]
1023018e4:	ff 83 1b 39	strb	wzr, [sp, #0x6e0]
1023018e8:	bf 42 03 f8	stur	xzr, [x21, #0x34]
1023018ec:	bf c2 02 f8	stur	xzr, [x21, #0x2c]
1023018f0:	e8 e3 5a 39	ldrb	w8, [sp, #0x6b8]
1023018f4:	88 00 00 34	cbz	w8, 0x102301904
1023018f8:	e0 5b 43 f9	ldr	x0, [sp, #0x6b0]
1023018fc:	40 00 00 b4	cbz	x0, 0x102301904
102301900:	6e 40 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102301904:	e8 23 41 f9	ldr	x8, [sp, #0x240]
102301908:	e9 37 42 b9	ldr	w9, [sp, #0x234]
10230190c:	29 05 00 51	sub	w9, w9, #0x1
102301910:	08 c9 69 38	ldrb	w8, [x8, w9, sxtw]
102301914:	a8 06 00 34	cbz	w8, 0x1023019e8
102301918:	f4 63 1a 91	add	x20, sp, #0x698
10230191c:	e0 63 1a 91	add	x0, sp, #0x698
102301920:	e1 63 07 91	add	x1, sp, #0x1d8
102301924:	94 63 00 94	bl	__ZN2nc7NdArrayIjNSt3__19allocatorIjEEEC2ERKS4_
102301928:	f6 37 42 b9	ldr	w22, [sp, #0x234]
10230192c:	e0 17 c0 3d	ldr	q0, [sp, #0x50]
102301930:	a0 c2 82 3c	stur	q0, [x21, #0x2c]
102301934:	ff 6f 03 f9	str	xzr, [sp, #0x6d8]
102301938:	ff 83 1b 39	strb	wzr, [sp, #0x6e0]
10230193c:	80 00 80 52	mov	w0, #0x4
102301940:	64 40 47 94	bl	0x1034d1ad0 ; symbol stub for: __Znwm
102301944:	e0 6f 03 f9	str	x0, [sp, #0x6d8]
102301948:	28 00 80 52	mov	w8, #0x1
10230194c:	e8 83 1b 39	strb	w8, [sp, #0x6e0]
102301950:	16 00 00 b9	str	w22, [x0]
102301954:	f6 63 1a 91	add	x22, sp, #0x698
102301958:	48 00 80 52	mov	w8, #0x2
10230195c:	f6 23 16 a9	stp	x22, x8, [sp, #0x160]
102301960:	e8 23 06 91	add	x8, sp, #0x188
102301964:	e0 83 05 91	add	x0, sp, #0x160
102301968:	64 6a 00 94	bl	__ZN2nc12column_stackIjEENS_7NdArrayIT_NSt3__19allocatorIS2_EEEERKSt16initializer_listIS6_E
10230196c:	e8 e3 47 39	ldrb	w8, [sp, #0x1f8]
102301970:	88 00 00 34	cbz	w8, 0x102301980
102301974:	e0 fb 40 f9	ldr	x0, [sp, #0x1f0]
102301978:	40 00 00 b4	cbz	x0, 0x102301980
10230197c:	4f 40 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102301980:	94 b2 00 91	add	x20, x20, #0x2c
102301984:	28 43 4a f8	ldur	x8, [x25, #0xa4]
102301988:	28 43 0f f8	stur	x8, [x25, #0xf4]
10230198c:	20 c3 4a fc	ldur	d0, [x25, #0xac]
102301990:	20 c3 0f fc	stur	d0, [x25, #0xfc]
102301994:	e8 d3 40 f9	ldr	x8, [sp, #0x1a0]
102301998:	e8 fb 00 f9	str	x8, [sp, #0x1f0]
10230199c:	e8 a3 46 39	ldrb	w8, [sp, #0x1a8]
1023019a0:	e8 e3 07 39	strb	w8, [sp, #0x1f8]
1023019a4:	3f c3 0a f8	stur	xzr, [x25, #0xac]
1023019a8:	3f 43 0a f8	stur	xzr, [x25, #0xa4]
1023019ac:	ff d3 00 f9	str	xzr, [sp, #0x1a0]
1023019b0:	ff a3 06 39	strb	wzr, [sp, #0x1a8]
1023019b4:	e8 83 5b 39	ldrb	w8, [sp, #0x6e0]
1023019b8:	88 00 00 34	cbz	w8, 0x1023019c8
1023019bc:	e0 6f 43 f9	ldr	x0, [sp, #0x6d8]
1023019c0:	40 00 00 b4	cbz	x0, 0x1023019c8
1023019c4:	3d 40 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
1023019c8:	ff 6f 03 f9	str	xzr, [sp, #0x6d8]
1023019cc:	ff 83 1b 39	strb	wzr, [sp, #0x6e0]
1023019d0:	9f 7e 00 a9	stp	xzr, xzr, [x20]
1023019d4:	e8 e3 5a 39	ldrb	w8, [sp, #0x6b8]
1023019d8:	88 00 00 34	cbz	w8, 0x1023019e8
1023019dc:	e0 5b 43 f9	ldr	x0, [sp, #0x6b0]
1023019e0:	40 00 00 b4	cbz	x0, 0x1023019e8
1023019e4:	35 40 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
1023019e8:	e1 fb 40 f9	ldr	x1, [sp, #0x1f0]
1023019ec:	e0 63 1a 91	add	x0, sp, #0x698
1023019f0:	51 aa 96 97	bl	__ZN2nc20NdArrayConstIteratorIjPKjlEC2ES2_
1023019f4:	f4 4f 43 f9	ldr	x20, [sp, #0x698]
1023019f8:	f5 e7 41 b9	ldr	w21, [sp, #0x1e4]
1023019fc:	e1 fb 40 f9	ldr	x1, [sp, #0x1f0]
102301a00:	e0 63 1a 91	add	x0, sp, #0x698
102301a04:	4c aa 96 97	bl	__ZN2nc20NdArrayConstIteratorIjPKjlEC2ES2_
102301a08:	e8 4f 43 f9	ldr	x8, [sp, #0x698]
102301a0c:	08 09 15 8b	add	x8, x8, x21, lsl #2
102301a10:	9f 02 08 eb	cmp	x20, x8
102301a14:	c0 2c 00 54	b.eq	0x102301fac
102301a18:	89 12 00 91	add	x9, x20, #0x4
102301a1c:	2a c1 5f b8	ldur	w10, [x9, #-0x4]
102301a20:	5f 01 00 71	cmp	w10, #0x0
102301a24:	24 01 48 fa	ccmp	x9, x8, #0x4, eq
102301a28:	29 11 00 91	add	x9, x9, #0x4
102301a2c:	81 ff ff 54	b.ne	0x102301a1c
102301a30:	ea 2b 00 34	cbz	w10, 0x102301fac
102301a34:	e0 63 07 91	add	x0, sp, #0x1d8
102301a38:	01 00 80 12	mov	w1, #-0x1
102301a3c:	42 00 80 52	mov	w2, #0x2
102301a40:	f7 0b 00 94	bl	__ZN2nc7NdArrayIjNSt3__19allocatorIjEEE7reshapeEii
102301a44:	e1 03 00 aa	mov	x1, x0
102301a48:	e0 23 06 91	add	x0, sp, #0x188
102301a4c:	4a 63 00 94	bl	__ZN2nc7NdArrayIjNSt3__19allocatorIjEEEC2ERKS4_
102301a50:	e8 8f 41 b9	ldr	w8, [sp, #0x18c]
102301a54:	28 2a 00 34	cbz	w8, 0x102301f98
102301a58:	15 00 80 52	mov	w21, #0x0
102301a5c:	e8 e3 04 91	add	x8, sp, #0x138
102301a60:	0b 01 7e b2	orr	x11, x8, #0x4
102301a64:	e9 63 1a 91	add	x9, sp, #0x698
102301a68:	28 a1 00 91	add	x8, x9, #0x28
102301a6c:	e8 13 00 f9	str	x8, [sp, #0x20]
102301a70:	e8 43 04 91	add	x8, sp, #0x110
102301a74:	0a 01 7e b2	orr	x10, x8, #0x4
102301a78:	ea af 00 a9	stp	x10, x11, [sp, #0x8]
102301a7c:	08 61 00 91	add	x8, x8, #0x18
102301a80:	e8 03 00 f9	str	x8, [sp]
102301a84:	33 b1 00 91	add	x19, x9, #0x2c
102301a88:	05 00 00 14	b	0x102301a9c
102301a8c:	b5 06 00 11	add	w21, w21, #0x1
102301a90:	e8 8f 41 b9	ldr	w8, [sp, #0x18c]
102301a94:	bf 02 08 6b	cmp	w21, w8
102301a98:	02 28 00 54	b.hs	0x102301f98
102301a9c:	e8 93 41 b9	ldr	w8, [sp, #0x190]
102301aa0:	e9 d3 40 f9	ldr	x9, [sp, #0x1a0]
102301aa4:	08 7d 15 1b	mul	w8, w8, w21
102301aa8:	3a 59 68 b8	ldr	w26, [x9, w8, uxtw #2]
102301aac:	08 05 00 11	add	w8, w8, #0x1
102301ab0:	28 59 68 b8	ldr	w8, [x9, w8, uxtw #2]
102301ab4:	e9 43 43 b9	ldr	w9, [sp, #0x340]
102301ab8:	23 7d 60 d3	lsl	x3, x9, #32
102301abc:	e1 03 1a aa	mov	x1, x26
102301ac0:	01 7d 60 b3	bfi	x1, x8, #32, #32
102301ac4:	08 7f 60 92	and	x8, x24, #0xffffffff00000000
102301ac8:	18 01 40 b2	orr	x24, x8, #0x1
102301acc:	e8 7e 60 92	and	x8, x23, #0xffffffff00000000
102301ad0:	17 01 40 b2	orr	x23, x8, #0x1
102301ad4:	e8 63 1a 91	add	x8, sp, #0x698
102301ad8:	e0 e3 0c 91	add	x0, sp, #0x338
102301adc:	e2 03 18 aa	mov	x2, x24
102301ae0:	e4 03 17 aa	mov	x4, x23
102301ae4:	cf a5 96 97	bl	__ZNK2nc7NdArrayIfNSt3__19allocatorIfEEEclENS_5SliceES5_
102301ae8:	e8 e3 04 91	add	x8, sp, #0x138
102301aec:	e0 63 1a 91	add	x0, sp, #0x698
102301af0:	01 00 80 52	mov	w1, #0x0
102301af4:	70 76 00 94	bl	__ZNK2nc7NdArrayIfNSt3__19allocatorIfEEE6argmaxENS_4AxisE
102301af8:	e1 ab 40 f9	ldr	x1, [sp, #0x150]
102301afc:	e0 43 04 91	add	x0, sp, #0x110
102301b00:	8d d8 96 97	bl	__ZN2nc20NdArrayConstIteratorIjPjlEC2ES1_
102301b04:	f4 8b 40 f9	ldr	x20, [sp, #0x110]
102301b08:	f6 47 41 b9	ldr	w22, [sp, #0x144]
102301b0c:	e1 ab 40 f9	ldr	x1, [sp, #0x150]
102301b10:	e0 43 04 91	add	x0, sp, #0x110
102301b14:	88 d8 96 97	bl	__ZN2nc20NdArrayConstIteratorIjPjlEC2ES1_
102301b18:	e8 8b 40 f9	ldr	x8, [sp, #0x110]
102301b1c:	08 09 16 8b	add	x8, x8, x22, lsl #2
102301b20:	9f 02 08 eb	cmp	x20, x8
102301b24:	a0 03 00 54	b.eq	0x102301b98
102301b28:	09 01 14 cb	sub	x9, x8, x20
102301b2c:	2a 11 00 d1	sub	x10, x9, #0x4
102301b30:	e9 03 14 aa	mov	x9, x20
102301b34:	5f f1 00 f1	cmp	x10, #0x3c
102301b38:	63 02 00 54	b.lo	0x102301b84
102301b3c:	49 fd 42 d3	lsr	x9, x10, #2
102301b40:	2a 05 00 91	add	x10, x9, #0x1
102301b44:	4b e9 7c 92	and	x11, x10, #0x7ffffffffffffff0
102301b48:	89 0a 0b 8b	add	x9, x20, x11, lsl #2
102301b4c:	8c 82 00 91	add	x12, x20, #0x20
102301b50:	ed 03 0b aa	mov	x13, x11
102301b54:	80 05 7f ad	ldp	q0, q1, [x12, #-0x20]
102301b58:	82 0d 40 ad	ldp	q2, q3, [x12]
102301b5c:	00 04 3f 6f	ushr.4s	v0, v0, #0x1
102301b60:	21 04 3f 6f	ushr.4s	v1, v1, #0x1
102301b64:	42 04 3f 6f	ushr.4s	v2, v2, #0x1
102301b68:	63 04 3f 6f	ushr.4s	v3, v3, #0x1
102301b6c:	80 05 3f ad	stp	q0, q1, [x12, #-0x20]
102301b70:	82 0d 82 ac	stp	q2, q3, [x12], #0x40
102301b74:	ad 41 00 f1	subs	x13, x13, #0x10
102301b78:	e1 fe ff 54	b.ne	0x102301b54
102301b7c:	5f 01 0b eb	cmp	x10, x11
102301b80:	c0 00 00 54	b.eq	0x102301b98
102301b84:	2a 01 40 b9	ldr	w10, [x9]
102301b88:	4a 7d 01 53	lsr	w10, w10, #1
102301b8c:	2a 45 00 b8	str	w10, [x9], #0x4
102301b90:	3f 01 08 eb	cmp	x9, x8
102301b94:	81 ff ff 54	b.ne	0x102301b84
102301b98:	34 43 45 f8	ldur	x20, [x25, #0x54]
102301b9c:	20 c3 45 fc	ldur	d0, [x25, #0x5c]
102301ba0:	e0 17 80 3d	str	q0, [sp, #0x50]
102301ba4:	f9 ab 40 f9	ldr	x25, [sp, #0x150]
102301ba8:	fb 63 45 39	ldrb	w27, [sp, #0x158]
102301bac:	ff a3 00 f9	str	xzr, [sp, #0x140]
102301bb0:	ff 3f 01 b9	str	wzr, [sp, #0x13c]
102301bb4:	ff 63 05 39	strb	wzr, [sp, #0x158]
102301bb8:	ff ab 00 f9	str	xzr, [sp, #0x150]
102301bbc:	e0 43 04 91	add	x0, sp, #0x110
102301bc0:	e1 03 19 aa	mov	x1, x25
102301bc4:	5c d8 96 97	bl	__ZN2nc20NdArrayConstIteratorIjPjlEC2ES1_
102301bc8:	f6 8b 40 f9	ldr	x22, [sp, #0x110]
102301bcc:	e0 43 04 91	add	x0, sp, #0x110
102301bd0:	e1 03 19 aa	mov	x1, x25
102301bd4:	58 d8 96 97	bl	__ZN2nc20NdArrayConstIteratorIjPjlEC2ES1_
102301bd8:	e5 17 c0 3d	ldr	q5, [sp, #0x50]
102301bdc:	a9 00 26 1e	fmov	w9, s5
102301be0:	ea 8b 40 f9	ldr	x10, [sp, #0x110]
102301be4:	48 49 29 8b	add	x8, x10, w9, uxtw #2
102301be8:	df 02 08 eb	cmp	x22, x8
102301bec:	e0 03 00 54	b.eq	0x102301c68
102301bf0:	49 09 09 8b	add	x9, x10, x9, lsl #2
102301bf4:	29 01 16 cb	sub	x9, x9, x22
102301bf8:	2a 11 00 d1	sub	x10, x9, #0x4
102301bfc:	e9 03 16 aa	mov	x9, x22
102301c00:	5f f1 00 f1	cmp	x10, #0x3c
102301c04:	83 02 00 54	b.lo	0x102301c54
102301c08:	49 fd 42 d3	lsr	x9, x10, #2
102301c0c:	2a 05 00 91	add	x10, x9, #0x1
102301c10:	4b e9 7c 92	and	x11, x10, #0x7ffffffffffffff0
102301c14:	c9 0a 0b 8b	add	x9, x22, x11, lsl #2
102301c18:	40 0f 04 4e	dup.4s	v0, w26
102301c1c:	cc 82 00 91	add	x12, x22, #0x20
102301c20:	ed 03 0b aa	mov	x13, x11
102301c24:	81 09 7f ad	ldp	q1, q2, [x12, #-0x20]
102301c28:	83 11 40 ad	ldp	q3, q4, [x12]
102301c2c:	21 84 a0 4e	add.4s	v1, v1, v0
102301c30:	42 84 a0 4e	add.4s	v2, v2, v0
102301c34:	63 84 a0 4e	add.4s	v3, v3, v0
102301c38:	84 84 a0 4e	add.4s	v4, v4, v0
102301c3c:	81 09 3f ad	stp	q1, q2, [x12, #-0x20]
102301c40:	83 11 82 ac	stp	q3, q4, [x12], #0x40
102301c44:	ad 41 00 f1	subs	x13, x13, #0x10
102301c48:	e1 fe ff 54	b.ne	0x102301c24
102301c4c:	5f 01 0b eb	cmp	x10, x11
102301c50:	c0 00 00 54	b.eq	0x102301c68
102301c54:	2a 01 40 b9	ldr	w10, [x9]
102301c58:	4a 01 1a 0b	add	w10, w10, w26
102301c5c:	2a 45 00 b8	str	w10, [x9], #0x4
102301c60:	3f 01 08 eb	cmp	x9, x8
102301c64:	81 ff ff 54	b.ne	0x102301c54
102301c68:	e8 a3 03 91	add	x8, sp, #0xe8
102301c6c:	14 c1 07 f8	stur	x20, [x8, #0x7c]
102301c70:	05 41 08 fc	stur	d5, [x8, #0x84]
102301c74:	f9 bf 00 f9	str	x25, [sp, #0x178]
102301c78:	fb 03 06 39	strb	w27, [sp, #0x180]
102301c7c:	e8 63 45 39	ldrb	w8, [sp, #0x158]
102301c80:	88 00 00 34	cbz	w8, 0x102301c90
102301c84:	e0 ab 40 f9	ldr	x0, [sp, #0x150]
102301c88:	40 00 00 b4	cbz	x0, 0x102301c90
102301c8c:	8b 3f 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102301c90:	ff ab 00 f9	str	xzr, [sp, #0x150]
102301c94:	ff 63 05 39	strb	wzr, [sp, #0x158]
102301c98:	e8 0b 40 f9	ldr	x8, [sp, #0x10]
102301c9c:	1f 7d 00 a9	stp	xzr, xzr, [x8]
102301ca0:	e8 e3 5a 39	ldrb	w8, [sp, #0x6b8]
102301ca4:	fa 03 08 91	add	x26, sp, #0x200
102301ca8:	88 00 00 34	cbz	w8, 0x102301cb8
102301cac:	e0 5b 43 f9	ldr	x0, [sp, #0x6b0]
102301cb0:	40 00 00 b4	cbz	x0, 0x102301cb8
102301cb4:	81 3f 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102301cb8:	e0 63 1a 91	add	x0, sp, #0x698
102301cbc:	e1 43 09 91	add	x1, sp, #0x250
102301cc0:	dc b7 96 97	bl	__ZN2nc7NdArrayIiNSt3__19allocatorIiEEEC2ERKS4_
102301cc4:	f9 a3 03 91	add	x25, sp, #0xe8
102301cc8:	e0 83 05 91	add	x0, sp, #0x160
102301ccc:	e8 13 40 f9	ldr	x8, [sp, #0x20]
102301cd0:	cc 0d 00 94	bl	__ZNK2nc7NdArrayIjNSt3__19allocatorIjEEE6astypeIijLi0ELi0ELi0EEENS0_IT_NS2_IS6_EEEEv
102301cd4:	e8 63 1a 91	add	x8, sp, #0x698
102301cd8:	e8 6b 02 f9	str	x8, [sp, #0x4d0]
102301cdc:	48 00 80 52	mov	w8, #0x2
102301ce0:	e8 6f 02 f9	str	x8, [sp, #0x4d8]
102301ce4:	e8 43 04 91	add	x8, sp, #0x110
102301ce8:	e0 43 13 91	add	x0, sp, #0x4d0
102301cec:	d3 61 00 94	bl	__ZN2nc12column_stackIiEENS_7NdArrayIT_NSt3__19allocatorIS2_EEEERKSt16initializer_listIS6_E
102301cf0:	e8 c3 49 39	ldrb	w8, [sp, #0x270]
102301cf4:	88 00 00 34	cbz	w8, 0x102301d04
102301cf8:	e0 37 41 f9	ldr	x0, [sp, #0x268]
102301cfc:	40 00 00 b4	cbz	x0, 0x102301d04
102301d00:	6e 3f 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102301d04:	28 c3 42 f8	ldur	x8, [x25, #0x2c]
102301d08:	48 43 05 f8	stur	x8, [x26, #0x54]
102301d0c:	20 43 43 fc	ldur	d0, [x25, #0x34]
102301d10:	40 c3 05 fc	stur	d0, [x26, #0x5c]
102301d14:	e8 97 40 f9	ldr	x8, [sp, #0x128]
102301d18:	e8 37 01 f9	str	x8, [sp, #0x268]
102301d1c:	e8 c3 44 39	ldrb	w8, [sp, #0x130]
102301d20:	e8 c3 09 39	strb	w8, [sp, #0x270]
102301d24:	e8 07 40 f9	ldr	x8, [sp, #0x8]
102301d28:	1f 7d 00 a9	stp	xzr, xzr, [x8]
102301d2c:	e8 03 40 f9	ldr	x8, [sp]
102301d30:	1f 21 00 39	strb	wzr, [x8, #0x8]
102301d34:	1f 01 00 f9	str	xzr, [x8]
102301d38:	e8 83 5b 39	ldrb	w8, [sp, #0x6e0]
102301d3c:	88 00 00 34	cbz	w8, 0x102301d4c
102301d40:	e0 6f 43 f9	ldr	x0, [sp, #0x6d8]
102301d44:	40 00 00 b4	cbz	x0, 0x102301d4c
102301d48:	5c 3f 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102301d4c:	ff 6f 03 f9	str	xzr, [sp, #0x6d8]
102301d50:	ff 83 1b 39	strb	wzr, [sp, #0x6e0]
102301d54:	e8 03 13 aa	mov	x8, x19
102301d58:	7f 7e 00 a9	stp	xzr, xzr, [x19]
102301d5c:	e8 e3 5a 39	ldrb	w8, [sp, #0x6b8]
102301d60:	88 00 00 34	cbz	w8, 0x102301d70
102301d64:	e0 5b 43 f9	ldr	x0, [sp, #0x6b0]
102301d68:	40 00 00 b4	cbz	x0, 0x102301d70
102301d6c:	53 3f 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102301d70:	e8 03 46 39	ldrb	w8, [sp, #0x180]
102301d74:	c8 e8 ff 34	cbz	w8, 0x102301a8c
102301d78:	e0 bf 40 f9	ldr	x0, [sp, #0x178]
102301d7c:	80 e8 ff b4	cbz	x0, 0x102301a8c
102301d80:	4e 3f 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102301d84:	42 ff ff 17	b	0x102301a8c
102301d88:	88 a9 00 90	adrp	x8, 5424 ; 0x103831000
102301d8c:	00 fd c3 3d	ldr	q0, [x8, #0xff0]
102301d90:	e8 17 40 f9	ldr	x8, [sp, #0x28]
102301d94:	00 41 80 3c	stur	q0, [x8, #0x4]
102301d98:	1f 0d 00 f9	str	xzr, [x8, #0x18]
102301d9c:	1f 81 00 39	strb	wzr, [x8, #0x20]
102301da0:	b4 01 00 14	b	0x102302470
102301da4:	e8 63 1a 91	add	x8, sp, #0x698
102301da8:	e0 43 0b 91	add	x0, sp, #0x2d0
102301dac:	01 00 80 52	mov	w1, #0x0
102301db0:	05 09 00 94	bl	__ZN2nc4diffIiEENS_7NdArrayIT_NSt3__19allocatorIS2_EEEERKS6_NS_4AxisE
102301db4:	f4 83 13 91	add	x20, sp, #0x4e0
102301db8:	e8 83 13 91	add	x8, sp, #0x4e0
102301dbc:	e0 63 1a 91	add	x0, sp, #0x698
102301dc0:	54 74 00 94	bl	__ZNK2nc7NdArrayIiNSt3__19allocatorIiEEE7nonzeroEv
102301dc4:	80 a2 00 91	add	x0, x20, #0x28
102301dc8:	e8 a3 03 91	add	x8, sp, #0xe8
102301dcc:	8d 0d 00 94	bl	__ZNK2nc7NdArrayIjNSt3__19allocatorIjEEE6astypeIijLi0ELi0ELi0EEENS0_IT_NS2_IS6_EEEEv
102301dd0:	e1 83 40 f9	ldr	x1, [sp, #0x100]
102301dd4:	e0 a3 08 91	add	x0, sp, #0x228
102301dd8:	58 b4 96 97	bl	__ZN2nc20NdArrayConstIteratorIiPilEC2ES1_
102301ddc:	f4 17 41 f9	ldr	x20, [sp, #0x228]
102301de0:	f5 f7 40 b9	ldr	w21, [sp, #0xf4]
102301de4:	e1 83 40 f9	ldr	x1, [sp, #0x100]
102301de8:	e0 a3 08 91	add	x0, sp, #0x228
102301dec:	53 b4 96 97	bl	__ZN2nc20NdArrayConstIteratorIiPilEC2ES1_
102301df0:	e8 17 41 f9	ldr	x8, [sp, #0x228]
102301df4:	08 09 15 8b	add	x8, x8, x21, lsl #2
102301df8:	9f 02 08 eb	cmp	x20, x8
102301dfc:	c0 03 00 54	b.eq	0x102301e74
102301e00:	09 01 14 cb	sub	x9, x8, x20
102301e04:	2a 11 00 d1	sub	x10, x9, #0x4
102301e08:	e9 03 14 aa	mov	x9, x20
102301e0c:	5f f1 00 f1	cmp	x10, #0x3c
102301e10:	83 02 00 54	b.lo	0x102301e60
102301e14:	49 fd 42 d3	lsr	x9, x10, #2
102301e18:	2a 05 00 91	add	x10, x9, #0x1
102301e1c:	4b e9 7c 92	and	x11, x10, #0x7ffffffffffffff0
102301e20:	89 0a 0b 8b	add	x9, x20, x11, lsl #2
102301e24:	8c 82 00 91	add	x12, x20, #0x20
102301e28:	20 04 00 4f	movi.4s	v0, #0x1
102301e2c:	ed 03 0b aa	mov	x13, x11
102301e30:	81 09 7f ad	ldp	q1, q2, [x12, #-0x20]
102301e34:	83 11 40 ad	ldp	q3, q4, [x12]
102301e38:	21 84 a0 4e	add.4s	v1, v1, v0
102301e3c:	42 84 a0 4e	add.4s	v2, v2, v0
102301e40:	63 84 a0 4e	add.4s	v3, v3, v0
102301e44:	84 84 a0 4e	add.4s	v4, v4, v0
102301e48:	81 09 3f ad	stp	q1, q2, [x12, #-0x20]
102301e4c:	83 11 82 ac	stp	q3, q4, [x12], #0x40
102301e50:	ad 41 00 f1	subs	x13, x13, #0x10
102301e54:	e1 fe ff 54	b.ne	0x102301e30
102301e58:	5f 01 0b eb	cmp	x10, x11
102301e5c:	c0 00 00 54	b.eq	0x102301e74
102301e60:	2a 01 40 b9	ldr	w10, [x9]
102301e64:	4a 05 00 11	add	w10, w10, #0x1
102301e68:	2a 45 00 b8	str	w10, [x9], #0x4
102301e6c:	3f 01 08 eb	cmp	x9, x8
102301e70:	81 ff ff 54	b.ne	0x102301e60
102301e74:	f4 c3 4e f8	ldur	x20, [sp, #0xec]
102301e78:	28 c3 40 fc	ldur	d8, [x25, #0xc]
102301e7c:	f5 83 40 f9	ldr	x21, [sp, #0x100]
102301e80:	f6 23 44 39	ldrb	w22, [sp, #0x108]
102301e84:	ff 7b 00 f9	str	xzr, [sp, #0xf0]
102301e88:	ff ef 00 b9	str	wzr, [sp, #0xec]
102301e8c:	ff 23 04 39	strb	wzr, [sp, #0x108]
102301e90:	ff 83 00 f9	str	xzr, [sp, #0x100]
102301e94:	e8 c3 49 39	ldrb	w8, [sp, #0x270]
102301e98:	a8 00 00 34	cbz	w8, 0x102301eac
102301e9c:	e0 37 41 f9	ldr	x0, [sp, #0x268]
102301ea0:	e0 05 00 b4	cbz	x0, 0x102301f5c
102301ea4:	05 3f 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102301ea8:	e8 23 44 39	ldrb	w8, [sp, #0x108]
102301eac:	54 43 05 f8	stur	x20, [x26, #0x54]
102301eb0:	48 c3 05 fc	stur	d8, [x26, #0x5c]
102301eb4:	f5 37 01 f9	str	x21, [sp, #0x268]
102301eb8:	f6 c3 09 39	strb	w22, [sp, #0x270]
102301ebc:	88 00 00 34	cbz	w8, 0x102301ecc
102301ec0:	e0 83 40 f9	ldr	x0, [sp, #0x100]
102301ec4:	40 00 00 b4	cbz	x0, 0x102301ecc
102301ec8:	fc 3e 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102301ecc:	ff 83 00 f9	str	xzr, [sp, #0x100]
102301ed0:	ff 23 04 39	strb	wzr, [sp, #0x108]
102301ed4:	3f c3 00 f8	stur	xzr, [x25, #0xc]
102301ed8:	ff c3 0e f8	stur	xzr, [sp, #0xec]
102301edc:	e8 a3 54 39	ldrb	w8, [sp, #0x528]
102301ee0:	88 00 00 34	cbz	w8, 0x102301ef0
102301ee4:	e0 93 42 f9	ldr	x0, [sp, #0x520]
102301ee8:	40 00 00 b4	cbz	x0, 0x102301ef0
102301eec:	f3 3e 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102301ef0:	ff 93 02 f9	str	xzr, [sp, #0x520]
102301ef4:	ff a3 14 39	strb	wzr, [sp, #0x528]
102301ef8:	9f 43 0e f8	stur	xzr, [x28, #0xe4]
102301efc:	9f c3 0d f8	stur	xzr, [x28, #0xdc]
102301f00:	e8 03 54 39	ldrb	w8, [sp, #0x500]
102301f04:	88 00 00 34	cbz	w8, 0x102301f14
102301f08:	e0 7f 42 f9	ldr	x0, [sp, #0x4f8]
102301f0c:	40 00 00 b4	cbz	x0, 0x102301f14
102301f10:	ea 3e 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102301f14:	ff 7f 02 f9	str	xzr, [sp, #0x4f8]
102301f18:	ff 03 14 39	strb	wzr, [sp, #0x500]
102301f1c:	9f c3 0b f8	stur	xzr, [x28, #0xbc]
102301f20:	9f 43 0b f8	stur	xzr, [x28, #0xb4]
102301f24:	e8 e3 5a 39	ldrb	w8, [sp, #0x6b8]
102301f28:	08 08 00 34	cbz	w8, 0x102302028
102301f2c:	e0 5b 43 f9	ldr	x0, [sp, #0x6b0]
102301f30:	c0 07 00 b4	cbz	x0, 0x102302028
102301f34:	e1 3e 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102301f38:	3c 00 00 14	b	0x102302028
102301f3c:	88 a9 00 90	adrp	x8, 5424 ; 0x103831000
102301f40:	00 fd c3 3d	ldr	q0, [x8, #0xff0]
102301f44:	e8 17 40 f9	ldr	x8, [sp, #0x28]
102301f48:	00 41 80 3c	stur	q0, [x8, #0x4]
102301f4c:	1f 0d 00 f9	str	xzr, [x8, #0x18]
102301f50:	1f 81 00 39	strb	wzr, [x8, #0x20]
102301f54:	34 00 80 52	mov	w20, #0x1
102301f58:	2e 00 00 14	b	0x102302010
102301f5c:	08 00 80 52	mov	w8, #0x0
102301f60:	54 43 05 f8	stur	x20, [x26, #0x54]
102301f64:	48 c3 05 fc	stur	d8, [x26, #0x5c]
102301f68:	f5 37 01 f9	str	x21, [sp, #0x268]
102301f6c:	f6 c3 09 39	strb	w22, [sp, #0x270]
102301f70:	88 fa ff 35	cbnz	w8, 0x102301ec0
102301f74:	d6 ff ff 17	b	0x102301ecc
102301f78:	88 a9 00 90	adrp	x8, 5424 ; 0x103831000
102301f7c:	00 fd c3 3d	ldr	q0, [x8, #0xff0]
102301f80:	e8 17 40 f9	ldr	x8, [sp, #0x28]
102301f84:	00 41 80 3c	stur	q0, [x8, #0x4]
102301f88:	1f 0d 00 f9	str	xzr, [x8, #0x18]
102301f8c:	1f 81 00 39	strb	wzr, [x8, #0x20]
102301f90:	34 00 80 52	mov	w20, #0x1
102301f94:	0c 00 00 14	b	0x102301fc4
102301f98:	e8 a3 46 39	ldrb	w8, [sp, #0x1a8]
102301f9c:	88 00 00 34	cbz	w8, 0x102301fac
102301fa0:	e0 d3 40 f9	ldr	x0, [sp, #0x1a0]
102301fa4:	40 00 00 b4	cbz	x0, 0x102301fac
102301fa8:	c4 3e 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102301fac:	e8 e3 47 39	ldrb	w8, [sp, #0x1f8]
102301fb0:	88 00 00 34	cbz	w8, 0x102301fc0
102301fb4:	e0 fb 40 f9	ldr	x0, [sp, #0x1f0]
102301fb8:	40 00 00 b4	cbz	x0, 0x102301fc0
102301fbc:	bf 3e 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102301fc0:	14 00 80 52	mov	w20, #0x0
102301fc4:	e8 a3 54 39	ldrb	w8, [sp, #0x528]
102301fc8:	88 00 00 34	cbz	w8, 0x102301fd8
102301fcc:	e0 93 42 f9	ldr	x0, [sp, #0x520]
102301fd0:	40 00 00 b4	cbz	x0, 0x102301fd8
102301fd4:	b9 3e 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102301fd8:	ff 93 02 f9	str	xzr, [sp, #0x520]
102301fdc:	ff a3 14 39	strb	wzr, [sp, #0x528]
102301fe0:	9f 43 0e f8	stur	xzr, [x28, #0xe4]
102301fe4:	9f c3 0d f8	stur	xzr, [x28, #0xdc]
102301fe8:	e8 03 54 39	ldrb	w8, [sp, #0x500]
102301fec:	88 00 00 34	cbz	w8, 0x102301ffc
102301ff0:	e0 7f 42 f9	ldr	x0, [sp, #0x4f8]
102301ff4:	40 00 00 b4	cbz	x0, 0x102301ffc
102301ff8:	b0 3e 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102301ffc:	e8 83 48 39	ldrb	w8, [sp, #0x220]
102302000:	88 00 00 34	cbz	w8, 0x102302010
102302004:	e0 0f 41 f9	ldr	x0, [sp, #0x218]
102302008:	40 00 00 b4	cbz	x0, 0x102302010
10230200c:	ab 3e 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102302010:	e8 23 49 39	ldrb	w8, [sp, #0x248]
102302014:	88 00 00 34	cbz	w8, 0x102302024
102302018:	e0 23 41 f9	ldr	x0, [sp, #0x240]
10230201c:	40 00 00 b4	cbz	x0, 0x102302024
102302020:	a6 3e 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102302024:	94 20 00 35	cbnz	w20, 0x102302434
102302028:	e0 c3 01 91	add	x0, sp, #0x70
10230202c:	e1 43 09 91	add	x1, sp, #0x250
102302030:	00 b7 96 97	bl	__ZN2nc7NdArrayIiNSt3__19allocatorIiEEEC2ERKS4_
102302034:	e1 47 40 f9	ldr	x1, [sp, #0x88]
102302038:	e0 03 08 91	add	x0, sp, #0x200
10230203c:	bf b3 96 97	bl	__ZN2nc20NdArrayConstIteratorIiPilEC2ES1_
102302040:	f4 03 41 f9	ldr	x20, [sp, #0x200]
102302044:	f5 7f 40 b9	ldr	w21, [sp, #0x7c]
102302048:	e1 47 40 f9	ldr	x1, [sp, #0x88]
10230204c:	e0 03 08 91	add	x0, sp, #0x200
102302050:	ba b3 96 97	bl	__ZN2nc20NdArrayConstIteratorIiPilEC2ES1_
102302054:	e8 03 41 f9	ldr	x8, [sp, #0x200]
102302058:	08 09 15 8b	add	x8, x8, x21, lsl #2
10230205c:	9f 02 08 eb	cmp	x20, x8
102302060:	ee 1f 40 b9	ldr	w14, [sp, #0x1c]
102302064:	c0 03 00 54	b.eq	0x1023020dc
102302068:	09 01 14 cb	sub	x9, x8, x20
10230206c:	2a 11 00 d1	sub	x10, x9, #0x4
102302070:	e9 03 14 aa	mov	x9, x20
102302074:	5f f1 00 f1	cmp	x10, #0x3c
102302078:	83 02 00 54	b.lo	0x1023020c8
10230207c:	49 fd 42 d3	lsr	x9, x10, #2
102302080:	2a 05 00 91	add	x10, x9, #0x1
102302084:	4b e9 7c 92	and	x11, x10, #0x7ffffffffffffff0
102302088:	89 0a 0b 8b	add	x9, x20, x11, lsl #2
10230208c:	c0 0d 04 4e	dup.4s	v0, w14
102302090:	8c 82 00 91	add	x12, x20, #0x20
102302094:	ed 03 0b aa	mov	x13, x11
102302098:	81 09 7f ad	ldp	q1, q2, [x12, #-0x20]
10230209c:	83 11 40 ad	ldp	q3, q4, [x12]
1023020a0:	21 84 a0 4e	add.4s	v1, v1, v0
1023020a4:	42 84 a0 4e	add.4s	v2, v2, v0
1023020a8:	63 84 a0 4e	add.4s	v3, v3, v0
1023020ac:	84 84 a0 4e	add.4s	v4, v4, v0
1023020b0:	81 09 3f ad	stp	q1, q2, [x12, #-0x20]
1023020b4:	83 11 82 ac	stp	q3, q4, [x12], #0x40
1023020b8:	ad 41 00 f1	subs	x13, x13, #0x10
1023020bc:	e1 fe ff 54	b.ne	0x102302098
1023020c0:	5f 01 0b eb	cmp	x10, x11
1023020c4:	c0 00 00 54	b.eq	0x1023020dc
1023020c8:	2a 01 40 b9	ldr	w10, [x9]
1023020cc:	4a 01 0e 0b	add	w10, w10, w14
1023020d0:	2a 45 00 b8	str	w10, [x9], #0x4
1023020d4:	3f 01 08 eb	cmp	x9, x8
1023020d8:	81 ff ff 54	b.ne	0x1023020c8
1023020dc:	e8 43 47 f8	ldur	x8, [sp, #0x74]
1023020e0:	e8 c3 09 f8	stur	x8, [sp, #0x9c]
1023020e4:	e0 c3 47 fc	ldur	d0, [sp, #0x7c]
1023020e8:	e0 43 0a fc	stur	d0, [sp, #0xa4]
1023020ec:	e8 47 40 f9	ldr	x8, [sp, #0x88]
1023020f0:	e8 5b 00 f9	str	x8, [sp, #0xb0]
1023020f4:	e8 43 42 39	ldrb	w8, [sp, #0x90]
1023020f8:	e8 e3 02 39	strb	w8, [sp, #0xb8]
1023020fc:	ff 3f 00 f9	str	xzr, [sp, #0x78]
102302100:	ff 77 00 b9	str	wzr, [sp, #0x74]
102302104:	ff 43 02 39	strb	wzr, [sp, #0x90]
102302108:	ff 47 00 f9	str	xzr, [sp, #0x88]
10230210c:	e8 03 03 91	add	x8, sp, #0xc0
102302110:	e0 63 02 91	add	x0, sp, #0x98
102302114:	71 0d 00 94	bl	__ZNK2nc7NdArrayIiNSt3__19allocatorIiEEE6astypeIdiLi0ELi0ELi0EEENS0_IT_NS2_IS6_EEEEv
102302118:	e1 6f 40 f9	ldr	x1, [sp, #0xd8]
10230211c:	e0 03 08 91	add	x0, sp, #0x200
102302120:	2b a7 96 97	bl	__ZN2nc20NdArrayConstIteratorIdPdlEC2ES1_
102302124:	f4 03 41 f9	ldr	x20, [sp, #0x200]
102302128:	f5 cf 40 b9	ldr	w21, [sp, #0xcc]
10230212c:	e1 6f 40 f9	ldr	x1, [sp, #0xd8]
102302130:	e0 03 08 91	add	x0, sp, #0x200
102302134:	26 a7 96 97	bl	__ZN2nc20NdArrayConstIteratorIdPdlEC2ES1_
102302138:	e8 03 41 f9	ldr	x8, [sp, #0x200]
10230213c:	08 0d 15 8b	add	x8, x8, x21, lsl #3
102302140:	9f 02 08 eb	cmp	x20, x8
102302144:	80 04 00 54	b.eq	0x1023021d4
102302148:	09 01 14 cb	sub	x9, x8, x20
10230214c:	2a 21 00 d1	sub	x10, x9, #0x8
102302150:	e9 03 14 aa	mov	x9, x20
102302154:	5f e1 00 f1	cmp	x10, #0x38
102302158:	e3 02 00 54	b.lo	0x1023021b4
10230215c:	49 fd 43 d3	lsr	x9, x10, #3
102302160:	2a 05 00 91	add	x10, x9, #0x1
102302164:	4b e9 7d 92	and	x11, x10, #0x3ffffffffffffff8
102302168:	89 0e 0b 8b	add	x9, x20, x11, lsl #3
10230216c:	e0 0f c0 3d	ldr	q0, [sp, #0x30]
102302170:	00 04 08 4e	dup.2d	v0, v0[0]
102302174:	01 f6 03 6f	fmov.2d	v1, #1.00000000
102302178:	20 fc 60 6e	fdiv.2d	v0, v1, v0
10230217c:	8c 82 00 91	add	x12, x20, #0x20
102302180:	ed 03 0b aa	mov	x13, x11
102302184:	81 09 7f ad	ldp	q1, q2, [x12, #-0x20]
102302188:	83 11 40 ad	ldp	q3, q4, [x12]
10230218c:	21 dc 60 6e	fmul.2d	v1, v1, v0
102302190:	42 dc 60 6e	fmul.2d	v2, v2, v0
102302194:	63 dc 60 6e	fmul.2d	v3, v3, v0
102302198:	84 dc 60 6e	fmul.2d	v4, v4, v0
10230219c:	81 09 3f ad	stp	q1, q2, [x12, #-0x20]
1023021a0:	83 11 82 ac	stp	q3, q4, [x12], #0x40
1023021a4:	ad 21 00 f1	subs	x13, x13, #0x8
1023021a8:	e1 fe ff 54	b.ne	0x102302184
1023021ac:	5f 01 0b eb	cmp	x10, x11
1023021b0:	20 01 00 54	b.eq	0x1023021d4
1023021b4:	00 10 6e 1e	fmov	d0, #1.00000000
1023021b8:	e1 0f c0 3d	ldr	q1, [sp, #0x30]
1023021bc:	00 18 61 1e	fdiv	d0, d0, d1
1023021c0:	21 01 40 fd	ldr	d1, [x9]
1023021c4:	21 08 60 1e	fmul	d1, d1, d0
1023021c8:	21 85 00 fc	str	d1, [x9], #0x8
1023021cc:	3f 01 08 eb	cmp	x9, x8
1023021d0:	81 ff ff 54	b.ne	0x1023021c0
1023021d4:	e8 43 4c f8	ldur	x8, [sp, #0xc4]
1023021d8:	88 43 0b f8	stur	x8, [x28, #0xb4]
1023021dc:	e0 c3 4c fc	ldur	d0, [sp, #0xcc]
1023021e0:	80 c3 0b fc	stur	d0, [x28, #0xbc]
1023021e4:	e8 6f 40 f9	ldr	x8, [sp, #0xd8]
1023021e8:	e8 7f 02 f9	str	x8, [sp, #0x4f8]
1023021ec:	e8 83 43 39	ldrb	w8, [sp, #0xe0]
1023021f0:	e8 03 14 39	strb	w8, [sp, #0x500]
1023021f4:	ff 67 00 f9	str	xzr, [sp, #0xc8]
1023021f8:	ff c7 00 b9	str	wzr, [sp, #0xc4]
1023021fc:	ff 83 03 39	strb	wzr, [sp, #0xe0]
102302200:	e8 83 13 91	add	x8, sp, #0x4e0
102302204:	16 a1 00 91	add	x22, x8, #0x28
102302208:	ff 6f 00 f9	str	xzr, [sp, #0xd8]
10230220c:	e8 63 07 91	add	x8, sp, #0x1d8
102302210:	e0 43 09 91	add	x0, sp, #0x250
102302214:	e3 0c 00 94	bl	__ZNK2nc7NdArrayIiNSt3__19allocatorIiEEE6astypeIjiLi0ELi0ELi0EEENS0_IT_NS2_IS6_EEEEv
102302218:	e8 03 08 91	add	x8, sp, #0x200
10230221c:	e0 43 0b 91	add	x0, sp, #0x2d0
102302220:	e1 63 07 91	add	x1, sp, #0x1d8
102302224:	84 e0 96 97	bl	__ZNK2nc7NdArrayIiNSt3__19allocatorIiEEEixINS0_IjNS2_IjEEEELi0EEES4_RKT_
102302228:	e0 03 08 91	add	x0, sp, #0x200
10230222c:	e8 03 16 aa	mov	x8, x22
102302230:	2a 0d 00 94	bl	__ZNK2nc7NdArrayIiNSt3__19allocatorIiEEE6astypeIdiLi0ELi0ELi0EEENS0_IT_NS2_IS6_EEEEv
102302234:	e8 83 13 91	add	x8, sp, #0x4e0
102302238:	49 00 80 52	mov	w9, #0x2
10230223c:	e8 a7 18 a9	stp	x8, x9, [sp, #0x188]
102302240:	f4 a3 08 91	add	x20, sp, #0x228
102302244:	e8 a3 08 91	add	x8, sp, #0x228
102302248:	e0 23 06 91	add	x0, sp, #0x188
10230224c:	a4 75 00 94	bl	__ZN2nc9row_stackIdEENS_7NdArrayIT_NSt3__19allocatorIS2_EEEERKSt16initializer_listIS6_E
102302250:	94 02 7e b2	orr	x20, x20, #0x4
102302254:	f5 33 42 b9	ldr	w21, [sp, #0x230]
102302258:	f7 2f 42 b9	ldr	w23, [sp, #0x22c]
10230225c:	f5 9f 06 b9	str	w21, [sp, #0x69c]
102302260:	f7 a3 06 b9	str	w23, [sp, #0x6a0]
102302264:	e8 7e 15 1b	mul	w8, w23, w21
102302268:	e8 a7 06 b9	str	w8, [sp, #0x6a4]
10230226c:	ff ab 06 b9	str	wzr, [sp, #0x6a8]
102302270:	ff 5b 03 f9	str	xzr, [sp, #0x6b0]
102302274:	ff e3 1a 39	strb	wzr, [sp, #0x6b8]
102302278:	28 01 00 34	cbz	w8, 0x10230229c
10230227c:	00 f1 7d d3	lsl	x0, x8, #3
102302280:	14 3e 47 94	bl	0x1034d1ad0 ; symbol stub for: __Znwm
102302284:	e0 5b 03 f9	str	x0, [sp, #0x6b0]
102302288:	28 00 80 52	mov	w8, #0x1
10230228c:	e8 e3 1a 39	strb	w8, [sp, #0x6b8]
102302290:	e8 63 1a 91	add	x8, sp, #0x698
102302294:	b7 00 00 35	cbnz	w23, 0x1023022a8
102302298:	18 00 00 14	b	0x1023022f8
10230229c:	00 00 80 d2	mov	x0, #0x0
1023022a0:	e8 63 1a 91	add	x8, sp, #0x698
1023022a4:	b7 02 00 34	cbz	w23, 0x1023022f8
1023022a8:	95 02 00 34	cbz	w21, 0x1023022f8
1023022ac:	09 00 80 52	mov	w9, #0x0
1023022b0:	ea 23 41 f9	ldr	x10, [sp, #0x240]
1023022b4:	0b 00 80 52	mov	w11, #0x0
1023022b8:	ec 7e 89 0a	and	w12, w23, w9, asr #31
1023022bc:	8c 01 09 0b	add	w12, w12, w9
1023022c0:	ad 7e 0c 1b	mul	w13, w21, w12
1023022c4:	ae 7e 8b 0a	and	w14, w21, w11, asr #31
1023022c8:	af 01 0e 0b	add	w15, w13, w14
1023022cc:	ef 01 0b 0b	add	w15, w15, w11
1023022d0:	40 59 6f fc	ldr	d0, [x10, w15, uxtw #3]
1023022d4:	ce 01 0b 0b	add	w14, w14, w11
1023022d8:	ce 31 17 1b	madd	w14, w14, w23, w12
1023022dc:	00 58 2e fc	str	d0, [x0, w14, uxtw #3]
1023022e0:	6b 05 00 11	add	w11, w11, #0x1
1023022e4:	bf 02 0b 6b	cmp	w21, w11
1023022e8:	e1 fe ff 54	b.ne	0x1023022c4
1023022ec:	29 05 00 11	add	w9, w9, #0x1
1023022f0:	3f 01 17 6b	cmp	w9, w23
1023022f4:	01 fe ff 54	b.ne	0x1023022b4
1023022f8:	17 01 7e b2	orr	x23, x8, #0x4
1023022fc:	e0 63 1a 91	add	x0, sp, #0x698
102302300:	e8 17 40 f9	ldr	x8, [sp, #0x28]
102302304:	a1 a4 96 97	bl	__ZNK2nc7NdArrayIdNSt3__19allocatorIdEEE6astypeIfdLi0ELi0ELi0EEENS0_IT_NS2_IS6_EEEEv
102302308:	e8 e3 5a 39	ldrb	w8, [sp, #0x6b8]
10230230c:	88 00 00 34	cbz	w8, 0x10230231c
102302310:	e0 5b 43 f9	ldr	x0, [sp, #0x6b0]
102302314:	40 00 00 b4	cbz	x0, 0x10230231c
102302318:	e8 3d 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10230231c:	ff 5b 03 f9	str	xzr, [sp, #0x6b0]
102302320:	ff e3 1a 39	strb	wzr, [sp, #0x6b8]
102302324:	ff 7e 00 a9	stp	xzr, xzr, [x23]
102302328:	e8 23 49 39	ldrb	w8, [sp, #0x248]
10230232c:	88 00 00 34	cbz	w8, 0x10230233c
102302330:	e0 23 41 f9	ldr	x0, [sp, #0x240]
102302334:	40 00 00 b4	cbz	x0, 0x10230233c
102302338:	e0 3d 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10230233c:	ff 23 01 f9	str	xzr, [sp, #0x240]
102302340:	ff 23 09 39	strb	wzr, [sp, #0x248]
102302344:	9f 7e 00 a9	stp	xzr, xzr, [x20]
102302348:	e8 a3 54 39	ldrb	w8, [sp, #0x528]
10230234c:	88 00 00 34	cbz	w8, 0x10230235c
102302350:	e0 93 42 f9	ldr	x0, [sp, #0x520]
102302354:	40 00 00 b4	cbz	x0, 0x10230235c
102302358:	d8 3d 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10230235c:	ff 93 02 f9	str	xzr, [sp, #0x520]
102302360:	ff a3 14 39	strb	wzr, [sp, #0x528]
102302364:	9f 43 0e f8	stur	xzr, [x28, #0xe4]
102302368:	9f c3 0d f8	stur	xzr, [x28, #0xdc]
10230236c:	e8 03 54 39	ldrb	w8, [sp, #0x500]
102302370:	88 00 00 34	cbz	w8, 0x102302380
102302374:	e0 7f 42 f9	ldr	x0, [sp, #0x4f8]
102302378:	40 00 00 b4	cbz	x0, 0x102302380
10230237c:	cf 3d 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102302380:	ff 7f 02 f9	str	xzr, [sp, #0x4f8]
102302384:	ff 03 14 39	strb	wzr, [sp, #0x500]
102302388:	9f c3 0b f8	stur	xzr, [x28, #0xbc]
10230238c:	9f 43 0b f8	stur	xzr, [x28, #0xb4]
102302390:	e8 83 48 39	ldrb	w8, [sp, #0x220]
102302394:	88 00 00 34	cbz	w8, 0x1023023a4
102302398:	e0 0f 41 f9	ldr	x0, [sp, #0x218]
10230239c:	40 00 00 b4	cbz	x0, 0x1023023a4
1023023a0:	c6 3d 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
1023023a4:	ff 0f 01 f9	str	xzr, [sp, #0x218]
1023023a8:	ff 83 08 39	strb	wzr, [sp, #0x220]
1023023ac:	5f c3 00 f8	stur	xzr, [x26, #0xc]
1023023b0:	5f 43 00 f8	stur	xzr, [x26, #0x4]
1023023b4:	e8 e3 47 39	ldrb	w8, [sp, #0x1f8]
1023023b8:	88 00 00 34	cbz	w8, 0x1023023c8
1023023bc:	e0 fb 40 f9	ldr	x0, [sp, #0x1f0]
1023023c0:	40 00 00 b4	cbz	x0, 0x1023023c8
1023023c4:	bd 3d 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
1023023c8:	e8 83 43 39	ldrb	w8, [sp, #0xe0]
1023023cc:	88 00 00 34	cbz	w8, 0x1023023dc
1023023d0:	e0 6f 40 f9	ldr	x0, [sp, #0xd8]
1023023d4:	40 00 00 b4	cbz	x0, 0x1023023dc
1023023d8:	b8 3d 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
1023023dc:	ff 6f 00 f9	str	xzr, [sp, #0xd8]
1023023e0:	ff 83 03 39	strb	wzr, [sp, #0xe0]
1023023e4:	ff c3 0c f8	stur	xzr, [sp, #0xcc]
1023023e8:	ff 43 0c f8	stur	xzr, [sp, #0xc4]
1023023ec:	e8 e3 42 39	ldrb	w8, [sp, #0xb8]
1023023f0:	88 00 00 34	cbz	w8, 0x102302400
1023023f4:	e0 5b 40 f9	ldr	x0, [sp, #0xb0]
1023023f8:	40 00 00 b4	cbz	x0, 0x102302400
1023023fc:	af 3d 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102302400:	ff 5b 00 f9	str	xzr, [sp, #0xb0]
102302404:	ff e3 02 39	strb	wzr, [sp, #0xb8]
102302408:	ff 43 0a f8	stur	xzr, [sp, #0xa4]
10230240c:	ff c3 09 f8	stur	xzr, [sp, #0x9c]
102302410:	e8 43 42 39	ldrb	w8, [sp, #0x90]
102302414:	88 00 00 34	cbz	w8, 0x102302424
102302418:	e0 47 40 f9	ldr	x0, [sp, #0x88]
10230241c:	40 00 00 b4	cbz	x0, 0x102302424
102302420:	a6 3d 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102302424:	ff 47 00 f9	str	xzr, [sp, #0x88]
102302428:	ff 43 02 39	strb	wzr, [sp, #0x90]
10230242c:	ff c3 07 f8	stur	xzr, [sp, #0x7c]
102302430:	ff 43 07 f8	stur	xzr, [sp, #0x74]
102302434:	e8 c3 49 39	ldrb	w8, [sp, #0x270]
102302438:	88 00 00 34	cbz	w8, 0x102302448
10230243c:	e0 37 41 f9	ldr	x0, [sp, #0x268]
102302440:	40 00 00 b4	cbz	x0, 0x102302448
102302444:	9d 3d 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102302448:	e8 c3 4b 39	ldrb	w8, [sp, #0x2f0]
10230244c:	88 00 00 34	cbz	w8, 0x10230245c
102302450:	e0 77 41 f9	ldr	x0, [sp, #0x2e8]
102302454:	40 00 00 b4	cbz	x0, 0x10230245c
102302458:	98 3d 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10230245c:	e8 83 4c 39	ldrb	w8, [sp, #0x320]
102302460:	88 00 00 34	cbz	w8, 0x102302470
102302464:	e0 8f 41 f9	ldr	x0, [sp, #0x318]
102302468:	40 00 00 b4	cbz	x0, 0x102302470
10230246c:	93 3d 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102302470:	e0 53 41 f9	ldr	x0, [sp, #0x2a0]
102302474:	60 00 00 b4	cbz	x0, 0x102302480
102302478:	e0 57 01 f9	str	x0, [sp, #0x2a8]
10230247c:	8f 3d 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102302480:	f4 5f 41 f9	ldr	x20, [sp, #0x2b8]
102302484:	f4 02 00 b4	cbz	x20, 0x1023024e0
102302488:	f5 63 41 f9	ldr	x21, [sp, #0x2c0]
10230248c:	e0 03 14 aa	mov	x0, x20
102302490:	bf 02 14 eb	cmp	x21, x20
102302494:	21 01 00 54	b.ne	0x1023024b8
102302498:	10 00 00 14	b	0x1023024d8
10230249c:	bf 02 1f f8	stur	xzr, [x21, #-0x10]
1023024a0:	bf 82 1f 38	sturb	wzr, [x21, #-0x8]
1023024a4:	bf 42 1e f8	stur	xzr, [x21, #-0x1c]
1023024a8:	bf c2 1d f8	stur	xzr, [x21, #-0x24]
1023024ac:	f5 03 16 aa	mov	x21, x22
1023024b0:	df 02 14 eb	cmp	x22, x20
1023024b4:	00 01 00 54	b.eq	0x1023024d4
1023024b8:	b6 a2 00 d1	sub	x22, x21, #0x28
1023024bc:	a8 82 5f 38	ldurb	w8, [x21, #-0x8]
1023024c0:	e8 fe ff 34	cbz	w8, 0x10230249c
1023024c4:	a0 02 5f f8	ldur	x0, [x21, #-0x10]
1023024c8:	a0 fe ff b4	cbz	x0, 0x10230249c
1023024cc:	7b 3d 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
1023024d0:	f3 ff ff 17	b	0x10230249c
1023024d4:	e0 5f 41 f9	ldr	x0, [sp, #0x2b8]
1023024d8:	f4 63 01 f9	str	x20, [sp, #0x2c0]
1023024dc:	77 3d 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
1023024e0:	e8 63 4d 39	ldrb	w8, [sp, #0x358]
1023024e4:	88 00 00 34	cbz	w8, 0x1023024f4
1023024e8:	e0 ab 41 f9	ldr	x0, [sp, #0x350]
1023024ec:	40 00 00 b4	cbz	x0, 0x1023024f4
1023024f0:	72 3d 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
1023024f4:	f4 e7 41 f9	ldr	x20, [sp, #0x3c8]
1023024f8:	b4 01 00 b4	cbz	x20, 0x10230252c
1023024fc:	e0 eb 41 f9	ldr	x0, [sp, #0x3d0]
102302500:	e8 03 14 aa	mov	x8, x20
102302504:	1f 00 14 eb	cmp	x0, x20
102302508:	c0 00 00 54	b.eq	0x102302520
10230250c:	00 e0 06 d1	sub	x0, x0, #0x1b8
102302510:	94 5b 00 94	bl	__ZN6madmom17HiddenMarkovModelINS_18BarTransitionModelENS_35RNNDownBeatTrackingObservationModelEED2Ev
102302514:	1f 00 14 eb	cmp	x0, x20
102302518:	a1 ff ff 54	b.ne	0x10230250c
10230251c:	e8 e7 41 f9	ldr	x8, [sp, #0x3c8]
102302520:	f4 eb 01 f9	str	x20, [sp, #0x3d0]
102302524:	e0 03 08 aa	mov	x0, x8
102302528:	64 3d 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10230252c:	e8 03 50 39	ldrb	w8, [sp, #0x400]
102302530:	88 00 00 34	cbz	w8, 0x102302540
102302534:	e0 ff 41 f9	ldr	x0, [sp, #0x3f8]
102302538:	40 00 00 b4	cbz	x0, 0x102302540
10230253c:	5f 3d 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102302540:	e8 a3 50 39	ldrb	w8, [sp, #0x428]
102302544:	f4 27 40 f9	ldr	x20, [sp, #0x48]
102302548:	88 00 00 34	cbz	w8, 0x102302558
10230254c:	e0 13 42 f9	ldr	x0, [sp, #0x420]
102302550:	40 00 00 b4	cbz	x0, 0x102302558
102302554:	59 3d 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102302558:	e8 43 51 39	ldrb	w8, [sp, #0x450]
10230255c:	88 00 00 34	cbz	w8, 0x10230256c
102302560:	e0 27 42 f9	ldr	x0, [sp, #0x448]
102302564:	40 00 00 b4	cbz	x0, 0x10230256c
102302568:	54 3d 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10230256c:	e8 e3 51 39	ldrb	w8, [sp, #0x478]
102302570:	88 00 00 34	cbz	w8, 0x102302580
102302574:	e0 3b 42 f9	ldr	x0, [sp, #0x470]
102302578:	40 00 00 b4	cbz	x0, 0x102302580
10230257c:	4f 3d 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102302580:	e8 83 52 39	ldrb	w8, [sp, #0x4a0]
102302584:	88 00 00 34	cbz	w8, 0x102302594
102302588:	e0 4f 42 f9	ldr	x0, [sp, #0x498]
10230258c:	40 00 00 b4	cbz	x0, 0x102302594
102302590:	4a 3d 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102302594:	e8 23 53 39	ldrb	w8, [sp, #0x4c8]
102302598:	88 00 00 34	cbz	w8, 0x1023025a8
10230259c:	e0 63 42 f9	ldr	x0, [sp, #0x4c0]
1023025a0:	40 00 00 b4	cbz	x0, 0x1023025a8
1023025a4:	45 3d 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
1023025a8:	e0 37 40 f9	ldr	x0, [sp, #0x68]
1023025ac:	74 00 00 34	cbz	w20, 0x1023025b8
1023025b0:	40 00 00 b4	cbz	x0, 0x1023025b8
1023025b4:	41 3d 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
1023025b8:	a8 83 57 f8	ldur	x8, [x29, #-0x88]
1023025bc:	69 72 01 90	adrp	x9, 11852 ; 0x10514e000
1023025c0:	29 7d 42 f9	ldr	x9, [x9, #0x4f8] ; literal pool symbol address: ___stack_chk_guard
1023025c4:	29 01 40 f9	ldr	x9, [x9]
1023025c8:	3f 01 08 eb	cmp	x9, x8
1023025cc:	01 02 00 54	b.ne	0x10230260c
1023025d0:	ff 83 1f 91	add	sp, sp, #0x7e0
1023025d4:	fd 7b 47 a9	ldp	x29, x30, [sp, #0x70]
1023025d8:	f4 4f 46 a9	ldp	x20, x19, [sp, #0x60]
1023025dc:	f6 57 45 a9	ldp	x22, x21, [sp, #0x50]
1023025e0:	f8 5f 44 a9	ldp	x24, x23, [sp, #0x40]
1023025e4:	fa 67 43 a9	ldp	x26, x25, [sp, #0x30]
1023025e8:	fc 6f 42 a9	ldp	x28, x27, [sp, #0x20]
1023025ec:	e9 23 41 6d	ldp	d9, d8, [sp, #0x10]
1023025f0:	eb 2b c8 6c	ldp	d11, d10, [sp], #0x80
1023025f4:	c0 03 5f d6	ret
1023025f8:	e0 83 0a 91	add	x0, sp, #0x2a0
1023025fc:	7d ae 8a 97	bl	__ZNKSt3__16vectorIdNS_9allocatorIdEEE20__throw_length_errorB6v15006Ev
102302600:	02 00 00 14	b	0x102302608
102302604:	9d da 74 97	bl	__ZSt28__throw_bad_array_new_lengthB6v15006v
102302608:	20 00 20 d4	brk	#0x1
10230260c:	91 3d 47 94	bl	0x1034d1c50 ; symbol stub for: ___stack_chk_fail
102302610:	f5 03 00 aa	mov	x21, x0
102302614:	c0 a2 00 91	add	x0, x22, #0x28
102302618:	28 92 96 97	bl	__ZN2nc7NdArrayIjNSt3__19allocatorIjEEED1Ev
10230261c:	08 00 00 14	b	0x10230263c
102302620:	06 00 00 14	b	0x102302638
102302624:	f5 03 00 aa	mov	x21, x0
102302628:	e0 03 17 aa	mov	x0, x23
10230262c:	23 92 96 97	bl	__ZN2nc7NdArrayIjNSt3__19allocatorIjEEED1Ev
102302630:	03 00 00 14	b	0x10230263c
102302634:	06 00 00 14	b	0x10230264c
102302638:	f5 03 00 aa	mov	x21, x0
10230263c:	e0 63 1a 91	add	x0, sp, #0x698
102302640:	1e 92 96 97	bl	__ZN2nc7NdArrayIjNSt3__19allocatorIjEEED1Ev
102302644:	af 00 00 14	b	0x102302900
102302648:	01 00 00 14	b	0x10230264c
10230264c:	f5 03 00 aa	mov	x21, x0
102302650:	ac 00 00 14	b	0x102302900
102302654:	e3 24 74 97	bl	___clang_call_terminate
102302658:	e2 24 74 97	bl	___clang_call_terminate
10230265c:	e1 24 74 97	bl	___clang_call_terminate
102302660:	e0 24 74 97	bl	___clang_call_terminate
102302664:	f5 03 00 aa	mov	x21, x0
102302668:	ab 00 00 14	b	0x102302914
10230266c:	f5 03 00 aa	mov	x21, x0
102302670:	ab 00 00 14	b	0x10230291c
102302674:	f5 03 00 aa	mov	x21, x0
102302678:	e8 03 54 39	ldrb	w8, [sp, #0x500]
10230267c:	a8 15 00 34	cbz	w8, 0x102302930
102302680:	e0 7f 42 f9	ldr	x0, [sp, #0x4f8]
102302684:	40 15 00 b5	cbnz	x0, 0x10230292c
102302688:	aa 00 00 14	b	0x102302930
10230268c:	f5 03 00 aa	mov	x21, x0
102302690:	a8 00 00 14	b	0x102302930
102302694:	f5 03 00 aa	mov	x21, x0
102302698:	22 00 00 14	b	0x102302720
10230269c:	d1 24 74 97	bl	___clang_call_terminate
1023026a0:	d0 24 74 97	bl	___clang_call_terminate
1023026a4:	cf 24 74 97	bl	___clang_call_terminate
1023026a8:	f5 03 00 aa	mov	x21, x0
1023026ac:	e0 83 13 91	add	x0, sp, #0x4e0
1023026b0:	a2 0b 00 94	bl	__ZNSt3__14pairIN2nc7NdArrayIjNS_9allocatorIjEEEES5_ED1Ev
1023026b4:	03 00 00 14	b	0x1023026c0
1023026b8:	ca 24 74 97	bl	___clang_call_terminate
1023026bc:	f5 03 00 aa	mov	x21, x0
1023026c0:	e8 e3 5a 39	ldrb	w8, [sp, #0x6b8]
1023026c4:	08 14 00 34	cbz	w8, 0x102302944
1023026c8:	e0 5b 43 f9	ldr	x0, [sp, #0x6b0]
1023026cc:	a0 13 00 b5	cbnz	x0, 0x102302940
1023026d0:	9d 00 00 14	b	0x102302944
1023026d4:	f5 03 00 aa	mov	x21, x0
1023026d8:	e8 03 54 39	ldrb	w8, [sp, #0x500]
1023026dc:	48 13 00 34	cbz	w8, 0x102302944
1023026e0:	e0 7f 42 f9	ldr	x0, [sp, #0x4f8]
1023026e4:	e0 12 00 b5	cbnz	x0, 0x102302940
1023026e8:	97 00 00 14	b	0x102302944
1023026ec:	f5 03 00 aa	mov	x21, x0
1023026f0:	95 00 00 14	b	0x102302944
1023026f4:	f5 03 00 aa	mov	x21, x0
1023026f8:	93 00 00 14	b	0x102302944
1023026fc:	f5 03 00 aa	mov	x21, x0
102302700:	e8 e3 5a 39	ldrb	w8, [sp, #0x6b8]
102302704:	88 00 00 34	cbz	w8, 0x102302714
102302708:	e0 5b 43 f9	ldr	x0, [sp, #0x6b0]
10230270c:	40 00 00 b4	cbz	x0, 0x102302714
102302710:	ea 3c 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102302714:	ff 5b 03 f9	str	xzr, [sp, #0x6b0]
102302718:	ff e3 1a 39	strb	wzr, [sp, #0x6b8]
10230271c:	ff 7e 00 a9	stp	xzr, xzr, [x23]
102302720:	e8 23 49 39	ldrb	w8, [sp, #0x248]
102302724:	88 00 00 34	cbz	w8, 0x102302734
102302728:	e0 23 41 f9	ldr	x0, [sp, #0x240]
10230272c:	40 00 00 b4	cbz	x0, 0x102302734
102302730:	e2 3c 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102302734:	ff 23 01 f9	str	xzr, [sp, #0x240]
102302738:	ff 23 09 39	strb	wzr, [sp, #0x248]
10230273c:	9f 7e 00 a9	stp	xzr, xzr, [x20]
102302740:	02 00 00 14	b	0x102302748
102302744:	f5 03 00 aa	mov	x21, x0
102302748:	e0 03 16 aa	mov	x0, x22
10230274c:	97 90 96 97	bl	__ZN2nc7NdArrayIdNSt3__19allocatorIdEEED1Ev
102302750:	e0 83 13 91	add	x0, sp, #0x4e0
102302754:	95 90 96 97	bl	__ZN2nc7NdArrayIdNSt3__19allocatorIdEEED1Ev
102302758:	14 00 80 52	mov	w20, #0x0
10230275c:	03 00 00 14	b	0x102302768
102302760:	f5 03 00 aa	mov	x21, x0
102302764:	34 00 80 52	mov	w20, #0x1
102302768:	e8 83 48 39	ldrb	w8, [sp, #0x220]
10230276c:	88 00 00 34	cbz	w8, 0x10230277c
102302770:	e0 0f 41 f9	ldr	x0, [sp, #0x218]
102302774:	40 00 00 b4	cbz	x0, 0x10230277c
102302778:	d0 3c 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10230277c:	ff 0f 01 f9	str	xzr, [sp, #0x218]
102302780:	ff 83 08 39	strb	wzr, [sp, #0x220]
102302784:	e8 03 08 91	add	x8, sp, #0x200
102302788:	1f c1 00 f8	stur	xzr, [x8, #0xc]
10230278c:	1f 41 00 f8	stur	xzr, [x8, #0x4]
102302790:	03 00 00 14	b	0x10230279c
102302794:	f5 03 00 aa	mov	x21, x0
102302798:	34 00 80 52	mov	w20, #0x1
10230279c:	e8 e3 47 39	ldrb	w8, [sp, #0x1f8]
1023027a0:	e8 00 00 34	cbz	w8, 0x1023027bc
1023027a4:	e0 fb 40 f9	ldr	x0, [sp, #0x1f0]
1023027a8:	a0 00 00 b4	cbz	x0, 0x1023027bc
1023027ac:	c3 3c 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
1023027b0:	03 00 00 14	b	0x1023027bc
1023027b4:	f5 03 00 aa	mov	x21, x0
1023027b8:	34 00 80 52	mov	w20, #0x1
1023027bc:	e8 83 43 39	ldrb	w8, [sp, #0xe0]
1023027c0:	88 00 00 34	cbz	w8, 0x1023027d0
1023027c4:	e0 6f 40 f9	ldr	x0, [sp, #0xd8]
1023027c8:	40 00 00 b4	cbz	x0, 0x1023027d0
1023027cc:	bb 3c 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
1023027d0:	ff 6f 00 f9	str	xzr, [sp, #0xd8]
1023027d4:	ff 83 03 39	strb	wzr, [sp, #0xe0]
1023027d8:	ff c3 0c f8	stur	xzr, [sp, #0xcc]
1023027dc:	ff 43 0c f8	stur	xzr, [sp, #0xc4]
1023027e0:	e8 e3 42 39	ldrb	w8, [sp, #0xb8]
1023027e4:	88 01 00 34	cbz	w8, 0x102302814
1023027e8:	e0 5b 40 f9	ldr	x0, [sp, #0xb0]
1023027ec:	40 01 00 b4	cbz	x0, 0x102302814
1023027f0:	b2 3c 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
1023027f4:	08 00 00 14	b	0x102302814
1023027f8:	7a 24 74 97	bl	___clang_call_terminate
1023027fc:	79 24 74 97	bl	___clang_call_terminate
102302800:	f5 03 00 aa	mov	x21, x0
102302804:	34 00 80 52	mov	w20, #0x1
102302808:	f6 83 13 91	add	x22, sp, #0x4e0
10230280c:	e8 e3 42 39	ldrb	w8, [sp, #0xb8]
102302810:	c8 fe ff 35	cbnz	w8, 0x1023027e8
102302814:	ff 5b 00 f9	str	xzr, [sp, #0xb0]
102302818:	ff e3 02 39	strb	wzr, [sp, #0xb8]
10230281c:	ff 43 0a f8	stur	xzr, [sp, #0xa4]
102302820:	ff c3 09 f8	stur	xzr, [sp, #0x9c]
102302824:	e8 43 42 39	ldrb	w8, [sp, #0x90]
102302828:	88 00 00 34	cbz	w8, 0x102302838
10230282c:	e0 47 40 f9	ldr	x0, [sp, #0x88]
102302830:	40 00 00 b4	cbz	x0, 0x102302838
102302834:	a1 3c 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102302838:	ff 47 00 f9	str	xzr, [sp, #0x88]
10230283c:	ff 43 02 39	strb	wzr, [sp, #0x90]
102302840:	ff c3 07 f8	stur	xzr, [sp, #0x7c]
102302844:	ff 43 07 f8	stur	xzr, [sp, #0x74]
102302848:	f4 07 00 34	cbz	w20, 0x102302944
10230284c:	e8 83 13 91	add	x8, sp, #0x4e0
102302850:	1f 01 16 eb	cmp	x8, x22
102302854:	80 07 00 54	b.eq	0x102302944
102302858:	f4 83 13 91	add	x20, sp, #0x4e0
10230285c:	d6 a2 00 d1	sub	x22, x22, #0x28
102302860:	e0 03 16 aa	mov	x0, x22
102302864:	51 90 96 97	bl	__ZN2nc7NdArrayIdNSt3__19allocatorIdEEED1Ev
102302868:	df 02 14 eb	cmp	x22, x20
10230286c:	81 ff ff 54	b.ne	0x10230285c
102302870:	35 00 00 14	b	0x102302944
102302874:	5b 24 74 97	bl	___clang_call_terminate
102302878:	5a 24 74 97	bl	___clang_call_terminate
10230287c:	f5 03 00 aa	mov	x21, x0
102302880:	31 00 00 14	b	0x102302944
102302884:	f5 03 00 aa	mov	x21, x0
102302888:	19 00 00 14	b	0x1023028ec
10230288c:	f5 03 00 aa	mov	x21, x0
102302890:	e8 e3 5a 39	ldrb	w8, [sp, #0x6b8]
102302894:	c8 02 00 34	cbz	w8, 0x1023028ec
102302898:	e0 5b 43 f9	ldr	x0, [sp, #0x6b0]
10230289c:	60 02 00 b5	cbnz	x0, 0x1023028e8
1023028a0:	13 00 00 14	b	0x1023028ec
1023028a4:	4f 24 74 97	bl	___clang_call_terminate
1023028a8:	4e 24 74 97	bl	___clang_call_terminate
1023028ac:	4d 24 74 97	bl	___clang_call_terminate
1023028b0:	4c 24 74 97	bl	___clang_call_terminate
1023028b4:	f5 03 00 aa	mov	x21, x0
1023028b8:	08 00 00 14	b	0x1023028d8
1023028bc:	f5 03 00 aa	mov	x21, x0
1023028c0:	04 00 00 14	b	0x1023028d0
1023028c4:	f5 03 00 aa	mov	x21, x0
1023028c8:	e0 13 40 f9	ldr	x0, [sp, #0x20]
1023028cc:	39 f4 ff 97	bl	__ZN2nc7NdArrayIiNSt3__19allocatorIiEEED1Ev
1023028d0:	e0 63 1a 91	add	x0, sp, #0x698
1023028d4:	37 f4 ff 97	bl	__ZN2nc7NdArrayIiNSt3__19allocatorIiEEED1Ev
1023028d8:	e8 03 46 39	ldrb	w8, [sp, #0x180]
1023028dc:	88 00 00 34	cbz	w8, 0x1023028ec
1023028e0:	e0 bf 40 f9	ldr	x0, [sp, #0x178]
1023028e4:	40 00 00 b4	cbz	x0, 0x1023028ec
1023028e8:	74 3c 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
1023028ec:	e8 a3 46 39	ldrb	w8, [sp, #0x1a8]
1023028f0:	88 00 00 34	cbz	w8, 0x102302900
1023028f4:	e0 d3 40 f9	ldr	x0, [sp, #0x1a0]
1023028f8:	40 00 00 b4	cbz	x0, 0x102302900
1023028fc:	6f 3c 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102302900:	e8 e3 47 39	ldrb	w8, [sp, #0x1f8]
102302904:	88 00 00 34	cbz	w8, 0x102302914
102302908:	e0 fb 40 f9	ldr	x0, [sp, #0x1f0]
10230290c:	40 00 00 b4	cbz	x0, 0x102302914
102302910:	6a 3c 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102302914:	e0 83 13 91	add	x0, sp, #0x4e0
102302918:	08 0b 00 94	bl	__ZNSt3__14pairIN2nc7NdArrayIjNS_9allocatorIjEEEES5_ED1Ev
10230291c:	e8 83 48 39	ldrb	w8, [sp, #0x220]
102302920:	88 00 00 34	cbz	w8, 0x102302930
102302924:	e0 0f 41 f9	ldr	x0, [sp, #0x218]
102302928:	40 00 00 b4	cbz	x0, 0x102302930
10230292c:	63 3c 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102302930:	e8 23 49 39	ldrb	w8, [sp, #0x248]
102302934:	88 00 00 34	cbz	w8, 0x102302944
102302938:	e0 23 41 f9	ldr	x0, [sp, #0x240]
10230293c:	40 00 00 b4	cbz	x0, 0x102302944
102302940:	5e 3c 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102302944:	e8 c3 49 39	ldrb	w8, [sp, #0x270]
102302948:	88 00 00 34	cbz	w8, 0x102302958
10230294c:	e0 37 41 f9	ldr	x0, [sp, #0x268]
102302950:	40 00 00 b4	cbz	x0, 0x102302958
102302954:	59 3c 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102302958:	e8 c3 4b 39	ldrb	w8, [sp, #0x2f0]
10230295c:	08 01 00 34	cbz	w8, 0x10230297c
102302960:	e0 77 41 f9	ldr	x0, [sp, #0x2e8]
102302964:	c0 00 00 b4	cbz	x0, 0x10230297c
102302968:	54 3c 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10230296c:	04 00 00 14	b	0x10230297c
102302970:	1c 24 74 97	bl	___clang_call_terminate
102302974:	1b 24 74 97	bl	___clang_call_terminate
102302978:	f5 03 00 aa	mov	x21, x0
10230297c:	e8 83 4c 39	ldrb	w8, [sp, #0x320]
102302980:	68 08 00 34	cbz	w8, 0x102302a8c
102302984:	e0 8f 41 f9	ldr	x0, [sp, #0x318]
102302988:	e0 06 00 b5	cbnz	x0, 0x102302a64
10230298c:	40 00 00 14	b	0x102302a8c
102302990:	3e 00 00 14	b	0x102302a88
102302994:	3d 00 00 14	b	0x102302a88
102302998:	f5 03 00 aa	mov	x21, x0
10230299c:	6b 00 00 14	b	0x102302b48
1023029a0:	f5 03 00 aa	mov	x21, x0
1023029a4:	69 00 00 14	b	0x102302b48
1023029a8:	f5 03 00 aa	mov	x21, x0
1023029ac:	67 00 00 14	b	0x102302b48
1023029b0:	f5 03 00 aa	mov	x21, x0
1023029b4:	65 00 00 14	b	0x102302b48
1023029b8:	f5 03 00 aa	mov	x21, x0
1023029bc:	e8 e3 5a 39	ldrb	w8, [sp, #0x6b8]
1023029c0:	68 06 00 34	cbz	w8, 0x102302a8c
1023029c4:	e0 5b 43 f9	ldr	x0, [sp, #0x6b0]
1023029c8:	e0 04 00 b5	cbnz	x0, 0x102302a64
1023029cc:	30 00 00 14	b	0x102302a8c
1023029d0:	f5 03 00 aa	mov	x21, x0
1023029d4:	e8 03 54 39	ldrb	w8, [sp, #0x500]
1023029d8:	68 06 00 34	cbz	w8, 0x102302aa4
1023029dc:	e0 7f 42 f9	ldr	x0, [sp, #0x4f8]
1023029e0:	20 06 00 b4	cbz	x0, 0x102302aa4
1023029e4:	35 3c 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
1023029e8:	2f 00 00 14	b	0x102302aa4
1023029ec:	01 00 00 14	b	0x1023029f0
1023029f0:	f5 03 00 aa	mov	x21, x0
1023029f4:	2c 00 00 14	b	0x102302aa4
1023029f8:	f5 03 00 aa	mov	x21, x0
1023029fc:	46 00 00 14	b	0x102302b14
102302a00:	f5 03 00 aa	mov	x21, x0
102302a04:	4b 00 00 14	b	0x102302b30
102302a08:	f5 03 00 aa	mov	x21, x0
102302a0c:	4f 00 00 14	b	0x102302b48
102302a10:	f5 03 00 aa	mov	x21, x0
102302a14:	f4 27 40 f9	ldr	x20, [sp, #0x48]
102302a18:	53 00 00 14	b	0x102302b64
102302a1c:	f5 03 00 aa	mov	x21, x0
102302a20:	f4 27 40 f9	ldr	x20, [sp, #0x48]
102302a24:	55 00 00 14	b	0x102302b78
102302a28:	f5 03 00 aa	mov	x21, x0
102302a2c:	f4 27 40 f9	ldr	x20, [sp, #0x48]
102302a30:	57 00 00 14	b	0x102302b8c
102302a34:	f5 03 00 aa	mov	x21, x0
102302a38:	f4 27 40 f9	ldr	x20, [sp, #0x48]
102302a3c:	57 00 00 14	b	0x102302b98
102302a40:	01 00 00 14	b	0x102302a44
102302a44:	f5 03 00 aa	mov	x21, x0
102302a48:	03 00 00 14	b	0x102302a54
102302a4c:	f5 03 00 aa	mov	x21, x0
102302a50:	f8 63 01 f9	str	x24, [sp, #0x2c0]
102302a54:	e8 03 54 39	ldrb	w8, [sp, #0x500]
102302a58:	a8 01 00 34	cbz	w8, 0x102302a8c
102302a5c:	e0 7f 42 f9	ldr	x0, [sp, #0x4f8]
102302a60:	60 01 00 b4	cbz	x0, 0x102302a8c
102302a64:	15 3c 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102302a68:	09 00 00 14	b	0x102302a8c
102302a6c:	f5 03 00 aa	mov	x21, x0
102302a70:	03 00 00 14	b	0x102302a7c
102302a74:	f5 03 00 aa	mov	x21, x0
102302a78:	fa eb 01 f9	str	x26, [sp, #0x3d0]
102302a7c:	e0 83 13 91	add	x0, sp, #0x4e0
102302a80:	38 5a 00 94	bl	__ZN6madmom17HiddenMarkovModelINS_18BarTransitionModelENS_35RNNDownBeatTrackingObservationModelEED2Ev
102302a84:	15 00 00 14	b	0x102302ad8
102302a88:	f5 03 00 aa	mov	x21, x0
102302a8c:	e0 53 41 f9	ldr	x0, [sp, #0x2a0]
102302a90:	60 00 00 b4	cbz	x0, 0x102302a9c
102302a94:	e0 57 01 f9	str	x0, [sp, #0x2a8]
102302a98:	08 3c 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102302a9c:	e0 e3 0a 91	add	x0, sp, #0x2b8
102302aa0:	62 0b 00 94	bl	__ZNSt3__16vectorIN2nc7NdArrayIjNS_9allocatorIjEEEENS3_IS5_EEED1B6v15006Ev
102302aa4:	e8 63 4d 39	ldrb	w8, [sp, #0x358]
102302aa8:	68 03 00 34	cbz	w8, 0x102302b14
102302aac:	e0 ab 41 f9	ldr	x0, [sp, #0x350]
102302ab0:	20 03 00 b4	cbz	x0, 0x102302b14
102302ab4:	01 3c 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102302ab8:	17 00 00 14	b	0x102302b14
102302abc:	f5 03 00 aa	mov	x21, x0
102302ac0:	15 00 00 14	b	0x102302b14
102302ac4:	f5 03 00 aa	mov	x21, x0
102302ac8:	11 00 00 14	b	0x102302b0c
102302acc:	f5 03 00 aa	mov	x21, x0
102302ad0:	0d 00 00 14	b	0x102302b04
102302ad4:	f5 03 00 aa	mov	x21, x0
102302ad8:	e8 c3 4b 39	ldrb	w8, [sp, #0x2f0]
102302adc:	88 00 00 34	cbz	w8, 0x102302aec
102302ae0:	e0 77 41 f9	ldr	x0, [sp, #0x2e8]
102302ae4:	40 00 00 b4	cbz	x0, 0x102302aec
102302ae8:	f4 3b 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102302aec:	f6 83 01 f9	str	x22, [sp, #0x300]
102302af0:	e8 a3 4c 39	ldrb	w8, [sp, #0x328]
102302af4:	88 00 00 34	cbz	w8, 0x102302b04
102302af8:	e0 93 41 f9	ldr	x0, [sp, #0x320]
102302afc:	40 00 00 b4	cbz	x0, 0x102302b04
102302b00:	ee 3b 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102302b04:	e0 63 1a 91	add	x0, sp, #0x698
102302b08:	ce 00 00 94	bl	__ZN6madmom18BarTransitionModelD1Ev
102302b0c:	e0 e3 0c 91	add	x0, sp, #0x338
102302b10:	68 5a 00 94	bl	__ZN6madmom13BarStateSpaceD2Ev
102302b14:	e0 23 0f 91	add	x0, sp, #0x3c8
102302b18:	66 0b 00 94	bl	__ZNSt3__16vectorIN6madmom17HiddenMarkovModelINS1_18BarTransitionModelENS1_35RNNDownBeatTrackingObservationModelEEENS_9allocatorIS5_EEED1B6v15006Ev
102302b1c:	e8 03 50 39	ldrb	w8, [sp, #0x400]
102302b20:	88 00 00 34	cbz	w8, 0x102302b30
102302b24:	e0 ff 41 f9	ldr	x0, [sp, #0x3f8]
102302b28:	40 00 00 b4	cbz	x0, 0x102302b30
102302b2c:	e3 3b 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102302b30:	e8 a3 50 39	ldrb	w8, [sp, #0x428]
102302b34:	88 00 00 34	cbz	w8, 0x102302b44
102302b38:	e0 13 42 f9	ldr	x0, [sp, #0x420]
102302b3c:	40 00 00 b4	cbz	x0, 0x102302b44
102302b40:	de 3b 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102302b44:	f4 27 40 f9	ldr	x20, [sp, #0x48]
102302b48:	e8 43 51 39	ldrb	w8, [sp, #0x450]
102302b4c:	88 00 00 34	cbz	w8, 0x102302b5c
102302b50:	e0 27 42 f9	ldr	x0, [sp, #0x448]
102302b54:	40 00 00 b4	cbz	x0, 0x102302b5c
102302b58:	d8 3b 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102302b5c:	e8 e3 51 39	ldrb	w8, [sp, #0x478]
102302b60:	88 00 00 34	cbz	w8, 0x102302b70
102302b64:	e0 3b 42 f9	ldr	x0, [sp, #0x470]
102302b68:	40 00 00 b4	cbz	x0, 0x102302b70
102302b6c:	d3 3b 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102302b70:	e8 83 52 39	ldrb	w8, [sp, #0x4a0]
102302b74:	88 00 00 34	cbz	w8, 0x102302b84
102302b78:	e0 4f 42 f9	ldr	x0, [sp, #0x498]
102302b7c:	40 00 00 b4	cbz	x0, 0x102302b84
102302b80:	ce 3b 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102302b84:	e8 23 53 39	ldrb	w8, [sp, #0x4c8]
102302b88:	88 00 00 34	cbz	w8, 0x102302b98
102302b8c:	e0 63 42 f9	ldr	x0, [sp, #0x4c0]
102302b90:	40 00 00 b4	cbz	x0, 0x102302b98
102302b94:	c9 3b 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102302b98:	9f 02 00 71	cmp	w20, #0x0
102302b9c:	e0 37 40 f9	ldr	x0, [sp, #0x68]
102302ba0:	04 18 40 fa	ccmp	x0, #0x0, #0x4, ne
102302ba4:	40 00 00 54	b.eq	0x102302bac
102302ba8:	c4 3b 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102302bac:	e0 03 15 aa	mov	x0, x21
102302bb0:	4f 39 47 94	bl	0x1034d10ec ; symbol stub for: __Unwind_Resume
