/Applications/rekordbox 7/rekordbox.app/Contents/MacOS/rekordbox:
(__TEXT,__text) section
__ZN8analyzer22AnalyzeJobBeatDetector24highPrecisionBeatAnalyzeEv:
102327e50:	ff 83 04 d1	sub	sp, sp, #0x120
102327e54:	fc 6f 0c a9	stp	x28, x27, [sp, #0xc0]
102327e58:	fa 67 0d a9	stp	x26, x25, [sp, #0xd0]
102327e5c:	f8 5f 0e a9	stp	x24, x23, [sp, #0xe0]
102327e60:	f6 57 0f a9	stp	x22, x21, [sp, #0xf0]
102327e64:	f4 4f 10 a9	stp	x20, x19, [sp, #0x100]
102327e68:	fd 7b 11 a9	stp	x29, x30, [sp, #0x110]
102327e6c:	fd 43 04 91	add	x29, sp, #0x110
102327e70:	f3 03 00 aa	mov	x19, x0
102327e74:	21 66 01 d0	adrp	x1, 11462 ; 0x104fed000
102327e78:	21 18 35 91	add	x1, x1, #0xd46 ; literal pool for: "analyzer::AnalyzeJobStatus analyzer::AnalyzeJobBeatDetector::highPrecisionBeatAnalyze()"
102327e7c:	a0 83 01 d1	sub	x0, x29, #0x60
102327e80:	6f 1a 06 94	bl	__ZN4juce6StringC1EPKc
102327e84:	68 02 40 f9	ldr	x8, [x19]
102327e88:	08 21 40 f9	ldr	x8, [x8, #0x40]
102327e8c:	a2 83 01 d1	sub	x2, x29, #0x60
102327e90:	e0 03 13 aa	mov	x0, x19
102327e94:	01 00 80 52	mov	w1, #0x0
102327e98:	a3 10 80 52	mov	w3, #0x85
102327e9c:	00 01 3f d6	blr	x8
102327ea0:	a0 83 01 d1	sub	x0, x29, #0x60
102327ea4:	16 0a 06 94	bl	__ZN4juce6StringD1Ev
102327ea8:	bf 03 19 38	sturb	wzr, [x29, #-0x70]
102327eac:	bf 83 19 f8	stur	xzr, [x29, #-0x68]
102327eb0:	60 4e 40 f9	ldr	x0, [x19, #0x98]
102327eb4:	eb b1 f0 97	bl	__ZN8analyzer12BALibWrapper6GetBpmEv
102327eb8:	f8 03 00 aa	mov	x24, x0
102327ebc:	60 4e 40 f9	ldr	x0, [x19, #0x98]
102327ec0:	f4 b1 f0 97	bl	__ZN8analyzer12BALibWrapper10GetBeatNumEv
102327ec4:	f9 03 00 aa	mov	x25, x0
102327ec8:	1f 00 00 71	cmp	w0, #0x0
102327ecc:	2d 02 00 54	b.le	0x102327f10
102327ed0:	68 16 40 f9	ldr	x8, [x19, #0x28]
102327ed4:	15 21 40 b9	ldr	w21, [x8, #0x20]
102327ed8:	17 15 40 f9	ldr	x23, [x8, #0x28]
102327edc:	60 4e 40 f9	ldr	x0, [x19, #0x98]
102327ee0:	10 b2 f0 97	bl	__ZN8analyzer12BALibWrapper13GetOffsetCalcEv
102327ee4:	f6 03 00 aa	mov	x22, x0
102327ee8:	68 0e 40 f9	ldr	x8, [x19, #0x18]
102327eec:	08 71 40 b9	ldr	w8, [x8, #0x70]
102327ef0:	1f 11 00 71	cmp	w8, #0x4
102327ef4:	80 04 00 54	b.eq	0x102327f84
102327ef8:	1f 09 00 71	cmp	w8, #0x2
102327efc:	81 04 00 54	b.ne	0x102327f8c
102327f00:	60 4e 40 f9	ldr	x0, [x19, #0x98]
102327f04:	18 b2 f0 97	bl	__ZN8analyzer12BALibWrapper12GetBpmHendouEv
102327f08:	f4 03 00 aa	mov	x20, x0
102327f0c:	21 00 00 14	b	0x102327f90
102327f10:	7f 66 00 b9	str	wzr, [x19, #0x64]
102327f14:	68 62 40 b9	ldr	w8, [x19, #0x60]
102327f18:	88 00 00 34	cbz	w8, 0x102327f28
102327f1c:	60 2e 40 f9	ldr	x0, [x19, #0x58]
102327f20:	90 a8 46 94	bl	0x1034d2160 ; symbol stub for: _free
102327f24:	7f 2e 00 f9	str	xzr, [x19, #0x58]
102327f28:	7f 62 00 b9	str	wzr, [x19, #0x60]
102327f2c:	62 42 01 91	add	x2, x19, #0x50
102327f30:	7f 76 00 b9	str	wzr, [x19, #0x74]
102327f34:	60 0a 40 f9	ldr	x0, [x19, #0x10]
102327f38:	08 00 40 f9	ldr	x8, [x0]
102327f3c:	08 09 40 f9	ldr	x8, [x8, #0x10]
102327f40:	61 00 80 52	mov	w1, #0x3
102327f44:	00 01 3f d6	blr	x8
102327f48:	21 66 01 d0	adrp	x1, 11462 ; 0x104fed000
102327f4c:	21 18 35 91	add	x1, x1, #0xd46 ; literal pool for: "analyzer::AnalyzeJobStatus analyzer::AnalyzeJobBeatDetector::highPrecisionBeatAnalyze()"
102327f50:	a0 e3 01 d1	sub	x0, x29, #0x78
102327f54:	3a 1a 06 94	bl	__ZN4juce6StringC1EPKc
102327f58:	68 02 40 f9	ldr	x8, [x19]
102327f5c:	08 21 40 f9	ldr	x8, [x8, #0x40]
102327f60:	a2 e3 01 d1	sub	x2, x29, #0x78
102327f64:	e0 03 13 aa	mov	x0, x19
102327f68:	81 00 80 52	mov	w1, #0x4
102327f6c:	e3 11 80 52	mov	w3, #0x8f
102327f70:	00 01 3f d6	blr	x8
102327f74:	f3 03 00 aa	mov	x19, x0
102327f78:	a0 e3 01 d1	sub	x0, x29, #0x78
102327f7c:	e0 09 06 94	bl	__ZN4juce6StringD1Ev
102327f80:	74 00 00 14	b	0x102328150
102327f84:	34 00 80 52	mov	w20, #0x1
102327f88:	02 00 00 14	b	0x102327f90
102327f8c:	14 00 80 52	mov	w20, #0x0
102327f90:	60 4e 40 f9	ldr	x0, [x19, #0x98]
102327f94:	e1 03 14 aa	mov	x1, x20
102327f98:	eb b1 f0 97	bl	__ZN8analyzer12BALibWrapper12SetBpmHendouEb
102327f9c:	68 16 40 f9	ldr	x8, [x19, #0x28]
102327fa0:	14 c1 00 39	strb	w20, [x8, #0x30]
102327fa4:	00 21 41 a9	ldp	x0, x8, [x8, #0x10]
102327fa8:	e0 23 07 a9	stp	x0, x8, [sp, #0x70]
102327fac:	88 00 00 b4	cbz	x8, 0x102327fbc
102327fb0:	08 21 00 91	add	x8, x8, #0x8
102327fb4:	29 00 80 52	mov	w9, #0x1
102327fb8:		.long	0xf8290108
102327fbc:	08 00 40 f9	ldr	x8, [x0]
102327fc0:	08 15 40 f9	ldr	x8, [x8, #0x28]
102327fc4:	00 01 3f d6	blr	x8
102327fc8:	e8 03 02 91	add	x8, sp, #0x80
102327fcc:	a8 be 06 94	bl	__ZNK4juce6String11toStdStringEv
102327fd0:	f4 3f 40 f9	ldr	x20, [sp, #0x78]
102327fd4:	74 01 00 b4	cbz	x20, 0x102328000
102327fd8:	88 22 00 91	add	x8, x20, #0x8
102327fdc:	09 00 80 92	mov	x9, #-0x1
102327fe0:		.long	0xf8e90108
102327fe4:	e8 00 00 b5	cbnz	x8, 0x102328000
102327fe8:	88 02 40 f9	ldr	x8, [x20]
102327fec:	08 09 40 f9	ldr	x8, [x8, #0x10]
102327ff0:	e0 03 14 aa	mov	x0, x20
102327ff4:	00 01 3f d6	blr	x8
102327ff8:	e0 03 14 aa	mov	x0, x20
102327ffc:	19 a6 46 94	bl	0x1034d1860 ; symbol stub for: __ZNSt3__119__shared_weak_count14__release_weakEv
102328000:	61 1a 40 f9	ldr	x1, [x19, #0x30]
102328004:	e0 a3 01 91	add	x0, sp, #0x68
102328008:	12 0e 06 94	bl	__ZN4juce6StringC1ERKS0_
10232800c:	68 1a 40 f9	ldr	x8, [x19, #0x30]
102328010:	01 21 00 91	add	x1, x8, #0x8
102328014:	e0 83 01 91	add	x0, sp, #0x60
102328018:	0e 0e 06 94	bl	__ZN4juce6StringC1ERKS0_
10232801c:	68 16 40 f9	ldr	x8, [x19, #0x28]
102328020:	05 c1 40 39	ldrb	w5, [x8, #0x30]
102328024:	e0 a3 01 91	add	x0, sp, #0x68
102328028:	e1 83 01 91	add	x1, sp, #0x60
10232802c:	e2 03 02 91	add	x2, sp, #0x80
102328030:	a6 c3 01 d1	sub	x6, x29, #0x70
102328034:	e3 03 15 aa	mov	x3, x21
102328038:	e4 03 16 aa	mov	x4, x22
10232803c:	f9 89 ff 97	bl	__ZN6madmom7analyzeEN4juce6StringES1_RKNSt3__112basic_stringIcNS2_11char_traitsIcEENS2_9allocatorIcEEEEiibRN8nlohmann10basic_jsonINSB_11ordered_mapENS2_6vectorES8_bxydS6_NSB_14adl_serializerENSE_IhNS6_IhEEEEEE
102328040:	f4 03 00 aa	mov	x20, x0
102328044:	e0 83 01 91	add	x0, sp, #0x60
102328048:	ad 09 06 94	bl	__ZN4juce6StringD1Ev
10232804c:	e0 a3 01 91	add	x0, sp, #0x68
102328050:	ab 09 06 94	bl	__ZN4juce6StringD1Ev
102328054:	f4 03 00 36	tbz	w20, #0x0, 0x1023280d0
102328058:	a1 62 01 b0	adrp	x1, 11349 ; 0x104f7d000
10232805c:	21 18 3e 91	add	x1, x1, #0xf86 ; literal pool for: "bpm"
102328060:	a0 c3 01 d1	sub	x0, x29, #0x70
102328064:	cb ca 78 97	bl	__ZN8nlohmann10basic_jsonINS_11ordered_mapENSt3__16vectorENS2_12basic_stringIcNS2_11char_traitsIcEENS2_9allocatorIcEEEEbxydS7_NS_14adl_serializerENS3_IhNS7_IhEEEEEixIKcEERSD_PT_
102328068:	ff 73 00 b9	str	wzr, [sp, #0x70]
10232806c:	e1 c3 01 91	add	x1, sp, #0x70
102328070:	ab 19 96 97	bl	__ZN8nlohmann6detail9from_jsonINS_10basic_jsonINS_11ordered_mapENSt3__16vectorENS4_12basic_stringIcNS4_11char_traitsIcEENS4_9allocatorIcEEEEbxydS9_NS_14adl_serializerENS5_IhNS9_IhEEEEEEiLi0EEEvRKT_RT0_
102328074:	e8 73 40 b9	ldr	w8, [sp, #0x70]
102328078:	e9 03 13 aa	mov	x9, x19
10232807c:	28 8d 06 b8	str	w8, [x9, #0x68]!
102328080:	e9 0f 00 f9	str	x9, [sp, #0x18]
102328084:	61 65 01 90	adrp	x1, 11436 ; 0x104fd4000
102328088:	21 d4 30 91	add	x1, x1, #0xc35 ; literal pool for: "beatList"
10232808c:	a0 c3 01 d1	sub	x0, x29, #0x70
102328090:	c0 ca 78 97	bl	__ZN8nlohmann10basic_jsonINS_11ordered_mapENSt3__16vectorENS2_12basic_stringIcNS2_11char_traitsIcEENS2_9allocatorIcEEEEbxydS7_NS_14adl_serializerENS3_IhNS7_IhEEEEEixIKcEERSD_PT_
102328094:	fa 03 00 aa	mov	x26, x0
102328098:	08 00 40 39	ldrb	w8, [x0]
10232809c:	f5 0b 00 b9	str	w21, [sp, #0x8]
1023280a0:	f7 03 00 f9	str	x23, [sp]
1023280a4:	f9 63 02 29	stp	w25, w24, [sp, #0x10]
1023280a8:	a8 06 00 34	cbz	w8, 0x10232817c
1023280ac:	1f 05 00 71	cmp	w8, #0x1
1023280b0:	a0 06 00 54	b.eq	0x102328184
1023280b4:	1f 09 00 71	cmp	w8, #0x2
1023280b8:	61 07 00 54	b.ne	0x1023281a4
1023280bc:	48 07 40 f9	ldr	x8, [x26, #0x8]
1023280c0:	08 25 40 a9	ldp	x8, x9, [x8]
1023280c4:	28 01 08 cb	sub	x8, x9, x8
1023280c8:	1b fd 44 93	asr	x27, x8, #4
1023280cc:	37 00 00 14	b	0x1023281a8
1023280d0:	7f 66 00 b9	str	wzr, [x19, #0x64]
1023280d4:	68 62 40 b9	ldr	w8, [x19, #0x60]
1023280d8:	88 00 00 34	cbz	w8, 0x1023280e8
1023280dc:	60 2e 40 f9	ldr	x0, [x19, #0x58]
1023280e0:	20 a8 46 94	bl	0x1034d2160 ; symbol stub for: _free
1023280e4:	7f 2e 00 f9	str	xzr, [x19, #0x58]
1023280e8:	7f 62 00 b9	str	wzr, [x19, #0x60]
1023280ec:	62 42 01 91	add	x2, x19, #0x50
1023280f0:	7f 76 00 b9	str	wzr, [x19, #0x74]
1023280f4:	60 0a 40 f9	ldr	x0, [x19, #0x10]
1023280f8:	08 00 40 f9	ldr	x8, [x0]
1023280fc:	08 09 40 f9	ldr	x8, [x8, #0x10]
102328100:	61 00 80 52	mov	w1, #0x3
102328104:	00 01 3f d6	blr	x8
102328108:	21 66 01 b0	adrp	x1, 11461 ; 0x104fed000
10232810c:	21 18 35 91	add	x1, x1, #0xd46 ; literal pool for: "analyzer::AnalyzeJobStatus analyzer::AnalyzeJobBeatDetector::highPrecisionBeatAnalyze()"
102328110:	e0 63 01 91	add	x0, sp, #0x58
102328114:	ca 19 06 94	bl	__ZN4juce6StringC1EPKc
102328118:	68 02 40 f9	ldr	x8, [x19]
10232811c:	08 21 40 f9	ldr	x8, [x8, #0x40]
102328120:	e2 63 01 91	add	x2, sp, #0x58
102328124:	e0 03 13 aa	mov	x0, x19
102328128:	61 00 80 52	mov	w1, #0x3
10232812c:	e3 15 80 52	mov	w3, #0xaf
102328130:	00 01 3f d6	blr	x8
102328134:	f3 03 00 aa	mov	x19, x0
102328138:	e0 63 01 91	add	x0, sp, #0x58
10232813c:	70 09 06 94	bl	__ZN4juce6StringD1Ev
102328140:	e8 5f c2 39	ldrsb	w8, [sp, #0x97]
102328144:	68 00 f8 36	tbz	w8, #0x1f, 0x102328150
102328148:	e0 43 40 f9	ldr	x0, [sp, #0x80]
10232814c:	5b a6 46 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102328150:	a0 c3 01 d1	sub	x0, x29, #0x70
102328154:	33 c9 78 97	bl	__ZN8nlohmann10basic_jsonINS_11ordered_mapENSt3__16vectorENS2_12basic_stringIcNS2_11char_traitsIcEENS2_9allocatorIcEEEEbxydS7_NS_14adl_serializerENS3_IhNS7_IhEEEEED1Ev
102328158:	e0 03 13 aa	mov	x0, x19
10232815c:	fd 7b 51 a9	ldp	x29, x30, [sp, #0x110]
102328160:	f4 4f 50 a9	ldp	x20, x19, [sp, #0x100]
102328164:	f6 57 4f a9	ldp	x22, x21, [sp, #0xf0]
102328168:	f8 5f 4e a9	ldp	x24, x23, [sp, #0xe0]
10232816c:	fa 67 4d a9	ldp	x26, x25, [sp, #0xd0]
102328170:	fc 6f 4c a9	ldp	x28, x27, [sp, #0xc0]
102328174:	ff 83 04 91	add	sp, sp, #0x120
102328178:	c0 03 5f d6	ret
10232817c:	1b 00 80 d2	mov	x27, #0x0
102328180:	0a 00 00 14	b	0x1023281a8
102328184:	48 07 40 f9	ldr	x8, [x26, #0x8]
102328188:	08 25 40 a9	ldp	x8, x9, [x8]
10232818c:	28 01 08 cb	sub	x8, x9, x8
102328190:	08 fd 43 93	asr	x8, x8, #3
102328194:	e9 e7 02 b2	mov	x9, #-0x3333333333333334
102328198:	a9 99 99 f2	movk	x9, #0xcccd
10232819c:	1b 7d 09 9b	mul	x27, x8, x9
1023281a0:	02 00 00 14	b	0x1023281a8
1023281a4:	3b 00 80 52	mov	w27, #0x1
1023281a8:	e8 0f 40 f9	ldr	x8, [sp, #0x18]
1023281ac:	08 01 40 b9	ldr	w8, [x8]
1023281b0:	e8 0f 00 b9	str	w8, [sp, #0xc]
1023281b4:	68 7f 40 93	sxtw	x8, w27
1023281b8:	09 c5 3b 8b	add	x9, x8, w27, sxtw #1
1023281bc:	29 f5 7e d3	lsl	x9, x9, #2
1023281c0:	8a 01 80 52	mov	w10, #0xc
1023281c4:	08 7d ca 9b	umulh	x8, x8, x10
1023281c8:	ff 03 08 eb	cmp	xzr, x8
1023281cc:	20 01 9f da	csinv	x0, x9, xzr, eq
1023281d0:	3d a6 46 94	bl	0x1034d1ac4 ; symbol stub for: __Znam
1023281d4:	e0 13 00 f9	str	x0, [sp, #0x20]
1023281d8:	7f 07 00 71	cmp	w27, #0x1
1023281dc:	ab 05 00 54	b.lt	0x102328290
1023281e0:	60 12 40 f9	ldr	x0, [x19, #0x20]
1023281e4:	01 00 80 52	mov	w1, #0x0
1023281e8:	90 4b ff 97	bl	__ZN8analyzer17AnalyzeJobManager10SetUrahakuEb
1023281ec:	15 00 80 d2	mov	x21, #0x0
1023281f0:	79 7f 40 92	and	x25, x27, #0xffffffff
1023281f4:	e8 13 40 f9	ldr	x8, [sp, #0x20]
1023281f8:	18 21 00 91	add	x24, x8, #0x8
1023281fc:	b6 62 01 b0	adrp	x22, 11349 ; 0x104f7d000
102328200:	d6 1a 3e 91	add	x22, x22, #0xf86 ; literal pool for: "bpm"
102328204:	74 65 01 90	adrp	x20, 11436 ; 0x104fd4000
102328208:	94 fa 30 91	add	x20, x20, #0xc3e ; literal pool for: "pos"
10232820c:	37 66 01 b0	adrp	x23, 11461 ; 0x104fed000
102328210:	f7 12 11 91	add	x23, x23, #0x444 ; literal pool for: "numBar"
102328214:	e0 03 1a aa	mov	x0, x26
102328218:	e1 03 15 aa	mov	x1, x21
10232821c:	c4 d8 78 97	bl	__ZNK8nlohmann10basic_jsonINS_11ordered_mapENSt3__16vectorENS2_12basic_stringIcNS2_11char_traitsIcEENS2_9allocatorIcEEEEbxydS7_NS_14adl_serializerENS3_IhNS7_IhEEEEEixEm
102328220:	fc 03 00 aa	mov	x28, x0
102328224:	e1 03 16 aa	mov	x1, x22
102328228:	54 e6 95 97	bl	__ZNK8nlohmann10basic_jsonINS_11ordered_mapENSt3__16vectorENS2_12basic_stringIcNS2_11char_traitsIcEENS2_9allocatorIcEEEEbxydS7_NS_14adl_serializerENS3_IhNS7_IhEEEEEixIKcEERKSD_PT_
10232822c:	ff 73 00 b9	str	wzr, [sp, #0x70]
102328230:	e1 c3 01 91	add	x1, sp, #0x70
102328234:	3a 19 96 97	bl	__ZN8nlohmann6detail9from_jsonINS_10basic_jsonINS_11ordered_mapENSt3__16vectorENS4_12basic_stringIcNS4_11char_traitsIcEENS4_9allocatorIcEEEEbxydS9_NS_14adl_serializerENS5_IhNS9_IhEEEEEEiLi0EEEvRKT_RT0_
102328238:	e8 73 40 b9	ldr	w8, [sp, #0x70]
10232823c:	08 03 00 b9	str	w8, [x24]
102328240:	e0 03 1c aa	mov	x0, x28
102328244:	e1 03 14 aa	mov	x1, x20
102328248:	4c e6 95 97	bl	__ZNK8nlohmann10basic_jsonINS_11ordered_mapENSt3__16vectorENS2_12basic_stringIcNS2_11char_traitsIcEENS2_9allocatorIcEEEEbxydS7_NS_14adl_serializerENS3_IhNS7_IhEEEEEixIKcEERKSD_PT_
10232824c:	ff 73 00 b9	str	wzr, [sp, #0x70]
102328250:	e1 c3 01 91	add	x1, sp, #0x70
102328254:	32 19 96 97	bl	__ZN8nlohmann6detail9from_jsonINS_10basic_jsonINS_11ordered_mapENSt3__16vectorENS4_12basic_stringIcNS4_11char_traitsIcEENS4_9allocatorIcEEEEbxydS9_NS_14adl_serializerENS5_IhNS9_IhEEEEEEiLi0EEEvRKT_RT0_
102328258:	e8 73 40 b9	ldr	w8, [sp, #0x70]
10232825c:	08 83 1f b8	stur	w8, [x24, #-0x8]
102328260:	e0 03 1c aa	mov	x0, x28
102328264:	e1 03 17 aa	mov	x1, x23
102328268:	44 e6 95 97	bl	__ZNK8nlohmann10basic_jsonINS_11ordered_mapENSt3__16vectorENS2_12basic_stringIcNS2_11char_traitsIcEENS2_9allocatorIcEEEEbxydS7_NS_14adl_serializerENS3_IhNS7_IhEEEEEixIKcEERKSD_PT_
10232826c:	ff 73 00 b9	str	wzr, [sp, #0x70]
102328270:	e1 c3 01 91	add	x1, sp, #0x70
102328274:	2a 19 96 97	bl	__ZN8nlohmann6detail9from_jsonINS_10basic_jsonINS_11ordered_mapENSt3__16vectorENS4_12basic_stringIcNS4_11char_traitsIcEENS4_9allocatorIcEEEEbxydS9_NS_14adl_serializerENS5_IhNS9_IhEEEEEEiLi0EEEvRKT_RT0_
102328278:	e8 73 40 b9	ldr	w8, [sp, #0x70]
10232827c:	08 c3 1f b8	stur	w8, [x24, #-0x4]
102328280:	b5 06 00 91	add	x21, x21, #0x1
102328284:	18 33 00 91	add	x24, x24, #0xc
102328288:	3f 03 15 eb	cmp	x25, x21
10232828c:	41 fc ff 54	b.ne	0x102328214
102328290:	60 4e 40 f9	ldr	x0, [x19, #0x98]
102328294:	01 00 80 d2	mov	x1, #0x0
102328298:	e2 0f 42 29	ldp	w2, w3, [sp, #0x10]
10232829c:	e4 13 40 f9	ldr	x4, [sp, #0x20]
1023282a0:	e5 03 1b aa	mov	x5, x27
1023282a4:	e6 0f 40 b9	ldr	w6, [sp, #0xc]
1023282a8:	38 b1 f0 97	bl	__ZN8analyzer12BALibWrapper17CalcBeatPos_FocusEP11BA_BeatInfoiiS2_ii
1023282ac:	60 4e 40 f9	ldr	x0, [x19, #0x98]
1023282b0:	47 b1 f0 97	bl	__ZN8analyzer12BALibWrapper12GetBpm_FocusEv
1023282b4:	60 6a 00 b9	str	w0, [x19, #0x68]
1023282b8:	60 4e 40 f9	ldr	x0, [x19, #0x98]
1023282bc:	4d b1 f0 97	bl	__ZN8analyzer12BALibWrapper16GetBeatNum_FocusEv
1023282c0:	f6 0b 40 b9	ldr	w22, [sp, #0x8]
1023282c4:	f9 03 40 f9	ldr	x25, [sp]
1023282c8:	f8 03 00 aa	mov	x24, x0
1023282cc:	e8 0f 40 f9	ldr	x8, [sp, #0x18]
1023282d0:	17 61 00 d1	sub	x23, x8, #0x18
1023282d4:	1f 00 00 71	cmp	w0, #0x0
1023282d8:	0d 0d 00 54	b.le	0x102328478
1023282dc:	88 01 80 52	mov	w8, #0xc
1023282e0:	00 7f a8 9b	umull	x0, w24, w8
1023282e4:	f8 a5 46 94	bl	0x1034d1ac4 ; symbol stub for: __Znam
1023282e8:	f4 03 00 aa	mov	x20, x0
1023282ec:	00 04 80 52	mov	w0, #0x20
1023282f0:	f8 a5 46 94	bl	0x1034d1ad0 ; symbol stub for: __Znwm
1023282f4:	68 7e 01 f0	adrp	x8, 12239 ; 0x1052f7000
1023282f8:	08 81 30 91	add	x8, x8, #0xc20
1023282fc:	08 7c 00 a9	stp	x8, xzr, [x0]
102328300:	1f 50 01 a9	stp	xzr, x20, [x0, #0x10]
102328304:	75 42 40 f9	ldr	x21, [x19, #0x80]
102328308:	74 82 07 a9	stp	x20, x0, [x19, #0x78]
10232830c:	b5 01 00 b4	cbz	x21, 0x102328340
102328310:	a8 22 00 91	add	x8, x21, #0x8
102328314:	09 00 80 92	mov	x9, #-0x1
102328318:		.long	0xf8e90108
10232831c:	e8 00 00 b5	cbnz	x8, 0x102328338
102328320:	a8 02 40 f9	ldr	x8, [x21]
102328324:	08 09 40 f9	ldr	x8, [x8, #0x10]
102328328:	e0 03 15 aa	mov	x0, x21
10232832c:	00 01 3f d6	blr	x8
102328330:	e0 03 15 aa	mov	x0, x21
102328334:	4b a5 46 94	bl	0x1034d1860 ; symbol stub for: __ZNSt3__119__shared_weak_count14__release_weakEv
102328338:	74 3e 40 f9	ldr	x20, [x19, #0x78]
10232833c:	54 0d 00 b4	cbz	x20, 0x1023284e4
102328340:	60 4e 40 f9	ldr	x0, [x19, #0x98]
102328344:	e1 03 14 aa	mov	x1, x20
102328348:	33 b1 f0 97	bl	__ZN8analyzer12BALibWrapper16GetBeatPos_FocusEP11BA_BeatInfo
10232834c:	e0 03 13 aa	mov	x0, x19
102328350:	ac 01 00 94	bl	__ZN8analyzer22AnalyzeJobBeatDetector15getFirstBeatPosEv
102328354:	f4 03 00 aa	mov	x20, x0
102328358:	21 66 01 b0	adrp	x1, 11461 ; 0x104fed000
10232835c:	21 18 35 91	add	x1, x1, #0xd46 ; literal pool for: "analyzer::AnalyzeJobStatus analyzer::AnalyzeJobBeatDetector::highPrecisionBeatAnalyze()"
102328360:	e0 03 01 91	add	x0, sp, #0x40
102328364:	36 19 06 94	bl	__ZN4juce6StringC1EPKc
102328368:	68 02 40 f9	ldr	x8, [x19]
10232836c:	08 21 40 f9	ldr	x8, [x8, #0x40]
102328370:	e2 03 01 91	add	x2, sp, #0x40
102328374:	e0 03 13 aa	mov	x0, x19
102328378:	e1 03 14 aa	mov	x1, x20
10232837c:	23 1b 80 52	mov	w3, #0xd9
102328380:	00 01 3f d6	blr	x8
102328384:	e0 03 01 91	add	x0, sp, #0x40
102328388:	dd 08 06 94	bl	__ZN4juce6StringD1Ev
10232838c:	69 a2 47 a9	ldp	x9, x8, [x19, #0x78]
102328390:	e9 23 03 a9	stp	x9, x8, [sp, #0x30]
102328394:	88 00 00 b4	cbz	x8, 0x1023283a4
102328398:	08 21 00 91	add	x8, x8, #0x8
10232839c:	29 00 80 52	mov	w9, #0x1
1023283a0:		.long	0xf8290108
1023283a4:	66 62 01 91	add	x6, x19, #0x58
1023283a8:	e1 c3 00 91	add	x1, sp, #0x30
1023283ac:	e0 03 13 aa	mov	x0, x19
1023283b0:	e2 03 18 aa	mov	x2, x24
1023283b4:	e3 03 16 aa	mov	x3, x22
1023283b8:	e4 03 19 aa	mov	x4, x25
1023283bc:	e5 0f 40 f9	ldr	x5, [sp, #0x18]
1023283c0:	d8 01 00 94	bl	__ZN8analyzer22AnalyzeJobBeatDetector17convertToMicrosecENSt3__110shared_ptrIA_11BA_BeatInfoEEiiiRiRN4juce5ArrayINS_16DetailedBeatInfoENS7_20DummyCriticalSectionELi0EEE
1023283c4:	f4 1f 40 f9	ldr	x20, [sp, #0x38]
1023283c8:	74 01 00 b4	cbz	x20, 0x1023283f4
1023283cc:	88 22 00 91	add	x8, x20, #0x8
1023283d0:	09 00 80 92	mov	x9, #-0x1
1023283d4:		.long	0xf8e90108
1023283d8:	e8 00 00 b5	cbnz	x8, 0x1023283f4
1023283dc:	88 02 40 f9	ldr	x8, [x20]
1023283e0:	08 09 40 f9	ldr	x8, [x8, #0x10]
1023283e4:	e0 03 14 aa	mov	x0, x20
1023283e8:	00 01 3f d6	blr	x8
1023283ec:	e0 03 14 aa	mov	x0, x20
1023283f0:	1c a5 46 94	bl	0x1034d1860 ; symbol stub for: __ZNSt3__119__shared_weak_count14__release_weakEv
1023283f4:	60 0a 40 f9	ldr	x0, [x19, #0x10]
1023283f8:	08 00 40 f9	ldr	x8, [x0]
1023283fc:	08 09 40 f9	ldr	x8, [x8, #0x10]
102328400:	61 00 80 52	mov	w1, #0x3
102328404:	e2 03 17 aa	mov	x2, x23
102328408:	00 01 3f d6	blr	x8
10232840c:	74 42 40 f9	ldr	x20, [x19, #0x80]
102328410:	7f fe 07 a9	stp	xzr, xzr, [x19, #0x78]
102328414:	74 01 00 b4	cbz	x20, 0x102328440
102328418:	88 22 00 91	add	x8, x20, #0x8
10232841c:	09 00 80 92	mov	x9, #-0x1
102328420:		.long	0xf8e90108
102328424:	e8 00 00 b5	cbnz	x8, 0x102328440
102328428:	88 02 40 f9	ldr	x8, [x20]
10232842c:	08 09 40 f9	ldr	x8, [x8, #0x10]
102328430:	e0 03 14 aa	mov	x0, x20
102328434:	00 01 3f d6	blr	x8
102328438:	e0 03 14 aa	mov	x0, x20
10232843c:	09 a5 46 94	bl	0x1034d1860 ; symbol stub for: __ZNSt3__119__shared_weak_count14__release_weakEv
102328440:	76 e6 0d 29	stp	w22, w25, [x19, #0x6c]
102328444:	21 66 01 b0	adrp	x1, 11461 ; 0x104fed000
102328448:	21 18 35 91	add	x1, x1, #0xd46 ; literal pool for: "analyzer::AnalyzeJobStatus analyzer::AnalyzeJobBeatDetector::highPrecisionBeatAnalyze()"
10232844c:	e0 a3 00 91	add	x0, sp, #0x28
102328450:	fb 18 06 94	bl	__ZN4juce6StringC1EPKc
102328454:	68 02 40 f9	ldr	x8, [x19]
102328458:	08 21 40 f9	ldr	x8, [x8, #0x40]
10232845c:	f4 a3 00 91	add	x20, sp, #0x28
102328460:	e2 a3 00 91	add	x2, sp, #0x28
102328464:	e0 03 13 aa	mov	x0, x19
102328468:	01 00 80 52	mov	w1, #0x0
10232846c:	03 1d 80 52	mov	w3, #0xe8
102328470:	00 01 3f d6	blr	x8
102328474:	36 00 00 14	b	0x10232854c
102328478:	7f 66 00 b9	str	wzr, [x19, #0x64]
10232847c:	68 62 40 b9	ldr	w8, [x19, #0x60]
102328480:	88 00 00 34	cbz	w8, 0x102328490
102328484:	60 2e 40 f9	ldr	x0, [x19, #0x58]
102328488:	36 a7 46 94	bl	0x1034d2160 ; symbol stub for: _free
10232848c:	7f 2e 00 f9	str	xzr, [x19, #0x58]
102328490:	7f 62 00 b9	str	wzr, [x19, #0x60]
102328494:	7f 76 00 b9	str	wzr, [x19, #0x74]
102328498:	60 0a 40 f9	ldr	x0, [x19, #0x10]
10232849c:	08 00 40 f9	ldr	x8, [x0]
1023284a0:	08 09 40 f9	ldr	x8, [x8, #0x10]
1023284a4:	61 00 80 52	mov	w1, #0x3
1023284a8:	e2 03 17 aa	mov	x2, x23
1023284ac:	00 01 3f d6	blr	x8
1023284b0:	21 66 01 b0	adrp	x1, 11461 ; 0x104fed000
1023284b4:	21 18 35 91	add	x1, x1, #0xd46 ; literal pool for: "analyzer::AnalyzeJobStatus analyzer::AnalyzeJobBeatDetector::highPrecisionBeatAnalyze()"
1023284b8:	e0 43 01 91	add	x0, sp, #0x50
1023284bc:	e0 18 06 94	bl	__ZN4juce6StringC1EPKc
1023284c0:	68 02 40 f9	ldr	x8, [x19]
1023284c4:	08 21 40 f9	ldr	x8, [x8, #0x40]
1023284c8:	f4 43 01 91	add	x20, sp, #0x50
1023284cc:	e2 43 01 91	add	x2, sp, #0x50
1023284d0:	e0 03 13 aa	mov	x0, x19
1023284d4:	81 00 80 52	mov	w1, #0x4
1023284d8:	a3 19 80 52	mov	w3, #0xcd
1023284dc:	00 01 3f d6	blr	x8
1023284e0:	1b 00 00 14	b	0x10232854c
1023284e4:	7f 66 00 b9	str	wzr, [x19, #0x64]
1023284e8:	68 62 40 b9	ldr	w8, [x19, #0x60]
1023284ec:	88 00 00 34	cbz	w8, 0x1023284fc
1023284f0:	60 2e 40 f9	ldr	x0, [x19, #0x58]
1023284f4:	1b a7 46 94	bl	0x1034d2160 ; symbol stub for: _free
1023284f8:	7f 2e 00 f9	str	xzr, [x19, #0x58]
1023284fc:	7f 62 00 b9	str	wzr, [x19, #0x60]
102328500:	7f 76 00 b9	str	wzr, [x19, #0x74]
102328504:	60 0a 40 f9	ldr	x0, [x19, #0x10]
102328508:	08 00 40 f9	ldr	x8, [x0]
10232850c:	08 09 40 f9	ldr	x8, [x8, #0x10]
102328510:	61 00 80 52	mov	w1, #0x3
102328514:	e2 03 17 aa	mov	x2, x23
102328518:	00 01 3f d6	blr	x8
10232851c:	21 66 01 b0	adrp	x1, 11461 ; 0x104fed000
102328520:	21 18 35 91	add	x1, x1, #0xd46 ; literal pool for: "analyzer::AnalyzeJobStatus analyzer::AnalyzeJobBeatDetector::highPrecisionBeatAnalyze()"
102328524:	e0 23 01 91	add	x0, sp, #0x48
102328528:	c5 18 06 94	bl	__ZN4juce6StringC1EPKc
10232852c:	68 02 40 f9	ldr	x8, [x19]
102328530:	08 21 40 f9	ldr	x8, [x8, #0x40]
102328534:	f4 23 01 91	add	x20, sp, #0x48
102328538:	e2 23 01 91	add	x2, sp, #0x48
10232853c:	e0 03 13 aa	mov	x0, x19
102328540:	81 00 80 52	mov	w1, #0x4
102328544:	c3 1a 80 52	mov	w3, #0xd6
102328548:	00 01 3f d6	blr	x8
10232854c:	f3 03 00 aa	mov	x19, x0
102328550:	e0 03 14 aa	mov	x0, x20
102328554:	6a 08 06 94	bl	__ZN4juce6StringD1Ev
102328558:	e0 13 40 f9	ldr	x0, [sp, #0x20]
10232855c:	54 a5 46 94	bl	0x1034d1aac ; symbol stub for: __ZdaPv
102328560:	e8 5f c2 39	ldrsb	w8, [sp, #0x97]
102328564:	68 df ff 36	tbz	w8, #0x1f, 0x102328150
102328568:	f8 fe ff 17	b	0x102328148
10232856c:	f3 03 00 aa	mov	x19, x0
102328570:	e0 23 01 91	add	x0, sp, #0x48
102328574:	62 08 06 94	bl	__ZN4juce6StringD1Ev
102328578:	39 00 00 14	b	0x10232865c
10232857c:	f3 03 00 aa	mov	x19, x0
102328580:	e0 43 01 91	add	x0, sp, #0x50
102328584:	5e 08 06 94	bl	__ZN4juce6StringD1Ev
102328588:	35 00 00 14	b	0x10232865c
10232858c:	f3 03 00 aa	mov	x19, x0
102328590:	e0 a3 00 91	add	x0, sp, #0x28
102328594:	5a 08 06 94	bl	__ZN4juce6StringD1Ev
102328598:	31 00 00 14	b	0x10232865c
10232859c:	f3 03 00 aa	mov	x19, x0
1023285a0:	e0 c3 00 91	add	x0, sp, #0x30
1023285a4:	97 02 00 94	bl	__ZNSt3__110shared_ptrIA_11BA_BeatInfoED1B6v15006Ev
1023285a8:	2d 00 00 14	b	0x10232865c
1023285ac:	f3 03 00 aa	mov	x19, x0
1023285b0:	e0 03 01 91	add	x0, sp, #0x40
1023285b4:	52 08 06 94	bl	__ZN4juce6StringD1Ev
1023285b8:	29 00 00 14	b	0x10232865c
1023285bc:	f3 03 00 aa	mov	x19, x0
1023285c0:	e0 03 14 aa	mov	x0, x20
1023285c4:	3d a5 46 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
1023285c8:	25 00 00 14	b	0x10232865c
1023285cc:	f3 03 00 aa	mov	x19, x0
1023285d0:	25 00 00 14	b	0x102328664
1023285d4:	f3 03 00 aa	mov	x19, x0
1023285d8:	e0 63 01 91	add	x0, sp, #0x58
1023285dc:	0b 00 00 14	b	0x102328608
1023285e0:	f3 03 00 aa	mov	x19, x0
1023285e4:	20 00 00 14	b	0x102328664
1023285e8:	f3 03 00 aa	mov	x19, x0
1023285ec:	a0 e3 01 d1	sub	x0, x29, #0x78
1023285f0:	43 08 06 94	bl	__ZN4juce6StringD1Ev
1023285f4:	20 00 00 14	b	0x102328674
1023285f8:	f3 03 00 aa	mov	x19, x0
1023285fc:	e0 83 01 91	add	x0, sp, #0x60
102328600:	3f 08 06 94	bl	__ZN4juce6StringD1Ev
102328604:	e0 a3 01 91	add	x0, sp, #0x68
102328608:	3d 08 06 94	bl	__ZN4juce6StringD1Ev
10232860c:	16 00 00 14	b	0x102328664
102328610:	10 00 00 14	b	0x102328650
102328614:	11 00 00 14	b	0x102328658
102328618:	0e 00 00 14	b	0x102328650
10232861c:	0d 00 00 14	b	0x102328650
102328620:	f3 03 00 aa	mov	x19, x0
102328624:	a0 83 01 d1	sub	x0, x29, #0x60
102328628:	35 08 06 94	bl	__ZN4juce6StringD1Ev
10232862c:	e0 03 13 aa	mov	x0, x19
102328630:	af a2 46 94	bl	0x1034d10ec ; symbol stub for: __Unwind_Resume
102328634:	f3 03 00 aa	mov	x19, x0
102328638:	0b 00 00 14	b	0x102328664
10232863c:	f3 03 00 aa	mov	x19, x0
102328640:	e0 c3 01 91	add	x0, sp, #0x70
102328644:	fe a4 78 97	bl	__ZNSt3__110shared_ptrIN8analyzer10DataSourceEED1B6v15006Ev
102328648:	0b 00 00 14	b	0x102328674
10232864c:	03 00 00 14	b	0x102328658
102328650:	f3 03 00 aa	mov	x19, x0
102328654:	08 00 00 14	b	0x102328674
102328658:	f3 03 00 aa	mov	x19, x0
10232865c:	e0 13 40 f9	ldr	x0, [sp, #0x20]
102328660:	13 a5 46 94	bl	0x1034d1aac ; symbol stub for: __ZdaPv
102328664:	e8 5f c2 39	ldrsb	w8, [sp, #0x97]
102328668:	68 00 f8 36	tbz	w8, #0x1f, 0x102328674
10232866c:	e0 43 40 f9	ldr	x0, [sp, #0x80]
102328670:	12 a5 46 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102328674:	a0 c3 01 d1	sub	x0, x29, #0x70
102328678:	ea c7 78 97	bl	__ZN8nlohmann10basic_jsonINS_11ordered_mapENSt3__16vectorENS2_12basic_stringIcNS2_11char_traitsIcEENS2_9allocatorIcEEEEbxydS7_NS_14adl_serializerENS3_IhNS7_IhEEEEED1Ev
10232867c:	e0 03 13 aa	mov	x0, x19
102328680:	9b a2 46 94	bl	0x1034d10ec ; symbol stub for: __Unwind_Resume
