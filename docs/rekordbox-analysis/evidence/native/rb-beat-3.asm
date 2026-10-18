/Applications/rekordbox 7/rekordbox.app/Contents/MacOS/rekordbox:
(__TEXT,__text) section
__ZN6madmom7get_bpmERKN8nlohmann10basic_jsonINS0_11ordered_mapENSt3__16vectorENS3_12basic_stringIcNS3_11char_traitsIcEENS3_9allocatorIcEEEEbxydS8_NS0_14adl_serializerENS4_IhNS8_IhEEEEEEb:
102306b34:	ff c3 03 d1	sub	sp, sp, #0xf0
102306b38:	e9 23 08 6d	stp	d9, d8, [sp, #0x80]
102306b3c:	fc 6f 09 a9	stp	x28, x27, [sp, #0x90]
102306b40:	fa 67 0a a9	stp	x26, x25, [sp, #0xa0]
102306b44:	f8 5f 0b a9	stp	x24, x23, [sp, #0xb0]
102306b48:	f6 57 0c a9	stp	x22, x21, [sp, #0xc0]
102306b4c:	f4 4f 0d a9	stp	x20, x19, [sp, #0xd0]
102306b50:	fd 7b 0e a9	stp	x29, x30, [sp, #0xe0]
102306b54:	fd 83 03 91	add	x29, sp, #0xe0
102306b58:	08 00 40 39	ldrb	w8, [x0]
102306b5c:	08 e4 00 2f	movi	d8, #0000000000000000
102306b60:	c8 29 00 34	cbz	w8, 0x102307098
102306b64:	f4 03 01 aa	mov	x20, x1
102306b68:	1f 05 00 71	cmp	w8, #0x1
102306b6c:	20 01 00 54	b.eq	0x102306b90
102306b70:	1f 09 00 71	cmp	w8, #0x2
102306b74:	e1 01 00 54	b.ne	0x102306bb0
102306b78:	09 04 40 f9	ldr	x9, [x0, #0x8]
102306b7c:	29 29 40 a9	ldp	x9, x10, [x9]
102306b80:	49 01 09 cb	sub	x9, x10, x9
102306b84:	29 fd 44 93	asr	x9, x9, #4
102306b88:	49 01 00 b5	cbnz	x9, 0x102306bb0
102306b8c:	43 01 00 14	b	0x102307098
102306b90:	09 04 40 f9	ldr	x9, [x0, #0x8]
102306b94:	29 29 40 a9	ldp	x9, x10, [x9]
102306b98:	49 01 09 cb	sub	x9, x10, x9
102306b9c:	29 fd 43 93	asr	x9, x9, #3
102306ba0:	ea e7 02 b2	mov	x10, #-0x3333333333333334
102306ba4:	aa 99 99 f2	movk	x10, #0xcccd
102306ba8:	29 7d 0a 9b	mul	x9, x9, x10
102306bac:	69 27 00 b4	cbz	x9, 0x102307098
102306bb0:	ff ff 06 a9	stp	xzr, xzr, [sp, #0x68]
102306bb4:	ff 3f 00 f9	str	xzr, [sp, #0x78]
102306bb8:	e0 7f 04 a9	stp	x0, xzr, [sp, #0x40]
102306bbc:	09 00 f0 d2	mov	x9, #-0x8000000000000000
102306bc0:	ff 27 05 a9	stp	xzr, x9, [sp, #0x50]
102306bc4:	e8 02 00 34	cbz	w8, 0x102306c20
102306bc8:	1f 09 00 71	cmp	w8, #0x2
102306bcc:	80 01 00 54	b.eq	0x102306bfc
102306bd0:	1f 05 00 71	cmp	w8, #0x1
102306bd4:	c1 02 00 54	b.ne	0x102306c2c
102306bd8:	08 04 40 f9	ldr	x8, [x0, #0x8]
102306bdc:	09 01 40 f9	ldr	x9, [x8]
102306be0:	e9 27 00 f9	str	x9, [sp, #0x48]
102306be4:	e0 ff 01 a9	stp	x0, xzr, [sp, #0x18]
102306be8:	09 00 f0 d2	mov	x9, #-0x8000000000000000
102306bec:	ff a7 02 a9	stp	xzr, x9, [sp, #0x28]
102306bf0:	08 05 40 f9	ldr	x8, [x8, #0x8]
102306bf4:	e8 13 00 f9	str	x8, [sp, #0x20]
102306bf8:	11 00 00 14	b	0x102306c3c
102306bfc:	08 04 40 f9	ldr	x8, [x0, #0x8]
102306c00:	09 01 40 f9	ldr	x9, [x8]
102306c04:	e9 2b 00 f9	str	x9, [sp, #0x50]
102306c08:	e0 ff 01 a9	stp	x0, xzr, [sp, #0x18]
102306c0c:	09 00 f0 d2	mov	x9, #-0x8000000000000000
102306c10:	ff a7 02 a9	stp	xzr, x9, [sp, #0x28]
102306c14:	08 05 40 f9	ldr	x8, [x8, #0x8]
102306c18:	e8 17 00 f9	str	x8, [sp, #0x28]
102306c1c:	08 00 00 14	b	0x102306c3c
102306c20:	28 00 80 52	mov	w8, #0x1
102306c24:	e8 2f 00 f9	str	x8, [sp, #0x58]
102306c28:	02 00 00 14	b	0x102306c30
102306c2c:	ff 2f 00 f9	str	xzr, [sp, #0x58]
102306c30:	e0 ff 01 a9	stp	x0, xzr, [sp, #0x18]
102306c34:	28 00 80 52	mov	w8, #0x1
102306c38:	ff a3 02 a9	stp	xzr, x8, [sp, #0x28]
102306c3c:	13 00 80 d2	mov	x19, #0x0
102306c40:	1b 00 80 d2	mov	x27, #0x0
102306c44:	18 00 80 d2	mov	x24, #0x0
102306c48:	f9 f3 7e b2	mov	x25, #0x7ffffffffffffffc
102306c4c:	1a 00 f8 92	mov	x26, #0x3fffffffffffffff
102306c50:	b5 63 01 f0	adrp	x21, 11383 ; 0x104f7d000
102306c54:	b5 1a 3e 91	add	x21, x21, #0xf86 ; literal pool for: "bpm"
102306c58:	04 00 00 14	b	0x102306c68
102306c5c:	e8 2b 40 f9	ldr	x8, [sp, #0x50]
102306c60:	08 41 00 91	add	x8, x8, #0x10
102306c64:	e8 2b 00 f9	str	x8, [sp, #0x50]
102306c68:	e0 03 01 91	add	x0, sp, #0x40
102306c6c:	e1 63 00 91	add	x1, sp, #0x18
102306c70:	8f ab 96 97	bl	__ZNK8nlohmann6detail9iter_implIKNS_10basic_jsonINS_11ordered_mapENSt3__16vectorENS4_12basic_stringIcNS4_11char_traitsIcEENS4_9allocatorIcEEEEbxydS9_NS_14adl_serializerENS5_IhNS9_IhEEEEEEEeqISH_LDn0EEEbRKT_
102306c74:	00 08 00 35	cbnz	w0, 0x102306d74
102306c78:	e0 03 01 91	add	x0, sp, #0x40
102306c7c:	63 6b 96 97	bl	__ZNK8nlohmann6detail9iter_implIKNS_10basic_jsonINS_11ordered_mapENSt3__16vectorENS4_12basic_stringIcNS4_11char_traitsIcEENS4_9allocatorIcEEEEbxydS9_NS_14adl_serializerENS5_IhNS9_IhEEEEEEEdeEv
102306c80:	e1 03 15 aa	mov	x1, x21
102306c84:	bd 6b 96 97	bl	__ZNK8nlohmann10basic_jsonINS_11ordered_mapENSt3__16vectorENS2_12basic_stringIcNS2_11char_traitsIcEENS2_9allocatorIcEEEEbxydS7_NS_14adl_serializerENS3_IhNS7_IhEEEEEixIKcEERKSD_PT_
102306c88:	ff 03 00 b9	str	wzr, [sp]
102306c8c:	e1 03 00 91	mov	x1, sp
102306c90:	a3 9e 96 97	bl	__ZN8nlohmann6detail9from_jsonINS_10basic_jsonINS_11ordered_mapENSt3__16vectorENS4_12basic_stringIcNS4_11char_traitsIcEENS4_9allocatorIcEEEEbxydS9_NS_14adl_serializerENS5_IhNS9_IhEEEEEEiLi0EEEvRKT_RT0_
102306c94:	fc 03 40 b9	ldr	w28, [sp]
102306c98:	1f 03 1b eb	cmp	x24, x27
102306c9c:	02 01 00 54	b.hs	0x102306cbc
102306ca0:	1c 47 00 b8	str	w28, [x24], #0x4
102306ca4:	f8 3b 00 f9	str	x24, [sp, #0x70]
102306ca8:	e8 23 40 f9	ldr	x8, [sp, #0x40]
102306cac:	08 01 40 39	ldrb	w8, [x8]
102306cb0:	1f 09 00 71	cmp	w8, #0x2
102306cb4:	c1 04 00 54	b.ne	0x102306d4c
102306cb8:	e9 ff ff 17	b	0x102306c5c
102306cbc:	16 03 13 cb	sub	x22, x24, x19
102306cc0:	d8 fe 42 93	asr	x24, x22, #2
102306cc4:	08 07 00 91	add	x8, x24, #0x1
102306cc8:	09 fd 7e d3	lsr	x9, x8, #62
102306ccc:	a9 1f 00 b5	cbnz	x9, 0x1023070c0
102306cd0:	69 03 13 cb	sub	x9, x27, x19
102306cd4:	2a fd 41 93	asr	x10, x9, #1
102306cd8:	5f 01 08 eb	cmp	x10, x8
102306cdc:	48 81 88 9a	csel	x8, x10, x8, hi
102306ce0:	3f 01 19 eb	cmp	x9, x25
102306ce4:	1b 31 9a 9a	csel	x27, x8, x26, lo
102306ce8:	fb 00 00 b4	cbz	x27, 0x102306d04
102306cec:	68 ff 7e d3	lsr	x8, x27, #62
102306cf0:	e8 1e 00 b5	cbnz	x8, 0x1023070cc
102306cf4:	60 f7 7e d3	lsl	x0, x27, #2
102306cf8:	76 2b 47 94	bl	0x1034d1ad0 ; symbol stub for: __Znwm
102306cfc:	f7 03 00 aa	mov	x23, x0
102306d00:	02 00 00 14	b	0x102306d08
102306d04:	17 00 80 d2	mov	x23, #0x0
102306d08:	f8 0a 18 8b	add	x24, x23, x24, lsl #2
102306d0c:	fb 0a 1b 8b	add	x27, x23, x27, lsl #2
102306d10:	1c 47 00 b8	str	w28, [x24], #0x4
102306d14:	e0 03 17 aa	mov	x0, x23
102306d18:	e1 03 13 aa	mov	x1, x19
102306d1c:	e2 03 16 aa	mov	x2, x22
102306d20:	4b 2e 47 94	bl	0x1034d264c ; symbol stub for: _memmove
102306d24:	f7 e3 06 a9	stp	x23, x24, [sp, #0x68]
102306d28:	fb 3f 00 f9	str	x27, [sp, #0x78]
102306d2c:	73 00 00 b4	cbz	x19, 0x102306d38
102306d30:	e0 03 13 aa	mov	x0, x19
102306d34:	61 2b 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102306d38:	f3 03 17 aa	mov	x19, x23
102306d3c:	e8 23 40 f9	ldr	x8, [sp, #0x40]
102306d40:	08 01 40 39	ldrb	w8, [x8]
102306d44:	1f 09 00 71	cmp	w8, #0x2
102306d48:	a0 f8 ff 54	b.eq	0x102306c5c
102306d4c:	1f 05 00 71	cmp	w8, #0x1
102306d50:	a1 00 00 54	b.ne	0x102306d64
102306d54:	e8 27 40 f9	ldr	x8, [sp, #0x48]
102306d58:	08 a1 00 91	add	x8, x8, #0x28
102306d5c:	e8 27 00 f9	str	x8, [sp, #0x48]
102306d60:	c2 ff ff 17	b	0x102306c68
102306d64:	e8 2f 40 f9	ldr	x8, [sp, #0x58]
102306d68:	08 05 00 91	add	x8, x8, #0x1
102306d6c:	e8 2f 00 f9	str	x8, [sp, #0x58]
102306d70:	be ff ff 17	b	0x102306c68
102306d74:	54 05 00 36	tbz	w20, #0x0, 0x102306e1c
102306d78:	15 03 13 cb	sub	x21, x24, x19
102306d7c:	a8 fe 42 d3	lsr	x8, x21, #2
102306d80:	29 00 80 52	mov	w9, #0x1
102306d84:	e9 a3 03 29	stp	w9, w8, [sp, #0x1c]
102306d88:	e8 ff 04 29	stp	w8, wzr, [sp, #0x24]
102306d8c:	ff 1b 00 f9	str	xzr, [sp, #0x30]
102306d90:	ff e3 00 39	strb	wzr, [sp, #0x38]
102306d94:	88 09 00 34	cbz	w8, 0x102306ec4
102306d98:	a0 7e 7e 92	and	x0, x21, #0x3fffffffc
102306d9c:	4d 2b 47 94	bl	0x1034d1ad0 ; symbol stub for: __Znwm
102306da0:	e0 1b 00 f9	str	x0, [sp, #0x30]
102306da4:	28 00 80 52	mov	w8, #0x1
102306da8:	e8 e3 00 39	strb	w8, [sp, #0x38]
102306dac:	7f 02 18 eb	cmp	x19, x24
102306db0:	a0 08 00 54	b.eq	0x102306ec4
102306db4:	a9 12 00 d1	sub	x9, x21, #0x4
102306db8:	3f f1 00 f1	cmp	x9, #0x3c
102306dbc:	a3 07 00 54	b.lo	0x102306eb0
102306dc0:	0a 00 13 cb	sub	x10, x0, x19
102306dc4:	e8 03 13 aa	mov	x8, x19
102306dc8:	5f 01 01 f1	cmp	x10, #0x40
102306dcc:	43 07 00 54	b.lo	0x102306eb4
102306dd0:	28 fd 42 d3	lsr	x8, x9, #2
102306dd4:	09 05 00 91	add	x9, x8, #0x1
102306dd8:	2a e9 7c 92	and	x10, x9, #0x7ffffffffffffff0
102306ddc:	4b f5 7e d3	lsl	x11, x10, #2
102306de0:	68 02 0b 8b	add	x8, x19, x11
102306de4:	0b 00 0b 8b	add	x11, x0, x11
102306de8:	6c 82 00 91	add	x12, x19, #0x20
102306dec:	0d 80 00 91	add	x13, x0, #0x20
102306df0:	ee 03 0a aa	mov	x14, x10
102306df4:	80 05 7f ad	ldp	q0, q1, [x12, #-0x20]
102306df8:	82 0d c2 ac	ldp	q2, q3, [x12], #0x40
102306dfc:	a0 05 3f ad	stp	q0, q1, [x13, #-0x20]
102306e00:	a2 0d 82 ac	stp	q2, q3, [x13], #0x40
102306e04:	ce 41 00 f1	subs	x14, x14, #0x10
102306e08:	61 ff ff 54	b.ne	0x102306df4
102306e0c:	e0 03 0b aa	mov	x0, x11
102306e10:	3f 01 0a eb	cmp	x9, x10
102306e14:	01 05 00 54	b.ne	0x102306eb4
102306e18:	2b 00 00 14	b	0x102306ec4
102306e1c:	19 03 13 cb	sub	x25, x24, x19
102306e20:	37 ff 42 d3	lsr	x23, x25, #2
102306e24:	17 04 00 34	cbz	w23, 0x102306ea4
102306e28:	20 7f 7e 92	and	x0, x25, #0x3fffffffc
102306e2c:	29 2b 47 94	bl	0x1034d1ad0 ; symbol stub for: __Znwm
102306e30:	f5 03 00 aa	mov	x21, x0
102306e34:	7f 02 18 eb	cmp	x19, x24
102306e38:	a0 09 00 54	b.eq	0x102306f6c
102306e3c:	2a 13 00 d1	sub	x10, x25, #0x4
102306e40:	5f f1 00 f1	cmp	x10, #0x3c
102306e44:	83 08 00 54	b.lo	0x102306f54
102306e48:	ab 02 13 cb	sub	x11, x21, x19
102306e4c:	e8 03 13 aa	mov	x8, x19
102306e50:	e9 03 15 aa	mov	x9, x21
102306e54:	7f 01 01 f1	cmp	x11, #0x40
102306e58:	23 08 00 54	b.lo	0x102306f5c
102306e5c:	48 fd 42 d3	lsr	x8, x10, #2
102306e60:	0a 05 00 91	add	x10, x8, #0x1
102306e64:	4b e9 7c 92	and	x11, x10, #0x7ffffffffffffff0
102306e68:	69 f5 7e d3	lsl	x9, x11, #2
102306e6c:	68 02 09 8b	add	x8, x19, x9
102306e70:	a9 02 09 8b	add	x9, x21, x9
102306e74:	6c 82 00 91	add	x12, x19, #0x20
102306e78:	ad 82 00 91	add	x13, x21, #0x20
102306e7c:	ee 03 0b aa	mov	x14, x11
102306e80:	80 05 7f ad	ldp	q0, q1, [x12, #-0x20]
102306e84:	82 0d c2 ac	ldp	q2, q3, [x12], #0x40
102306e88:	a0 05 3f ad	stp	q0, q1, [x13, #-0x20]
102306e8c:	a2 0d 82 ac	stp	q2, q3, [x13], #0x40
102306e90:	ce 41 00 f1	subs	x14, x14, #0x10
102306e94:	61 ff ff 54	b.ne	0x102306e80
102306e98:	5f 01 0b eb	cmp	x10, x11
102306e9c:	01 06 00 54	b.ne	0x102306f5c
102306ea0:	33 00 00 14	b	0x102306f6c
102306ea4:	16 00 80 52	mov	w22, #0x0
102306ea8:	15 00 80 d2	mov	x21, #0x0
102306eac:	31 00 00 14	b	0x102306f70
102306eb0:	e8 03 13 aa	mov	x8, x19
102306eb4:	09 45 40 b8	ldr	w9, [x8], #0x4
102306eb8:	09 44 00 b8	str	w9, [x0], #0x4
102306ebc:	1f 01 18 eb	cmp	x8, x24
102306ec0:	a1 ff ff 54	b.ne	0x102306eb4
102306ec4:	c8 00 80 52	mov	w8, #0x6
102306ec8:	e8 5f 00 39	strb	w8, [sp, #0x17]
102306ecc:	88 2d 8d 52	mov	w8, #0x696c
102306ed0:	c8 ad ac 72	movk	w8, #0x656e, lsl #16
102306ed4:	e8 03 00 b9	str	w8, [sp]
102306ed8:	28 4c 8e 52	mov	w8, #0x7261
102306edc:	e8 0b 00 79	strh	w8, [sp, #0x4]
102306ee0:	ff 1b 00 39	strb	wzr, [sp, #0x6]
102306ee4:	28 09 e8 d2	mov	x8, #0x4049000000000000
102306ee8:	00 01 67 9e	fmov	d0, x8
102306eec:	e8 03 01 91	add	x8, sp, #0x40
102306ef0:	e0 63 00 91	add	x0, sp, #0x18
102306ef4:	e2 03 00 91	mov	x2, sp
102306ef8:	01 00 80 52	mov	w1, #0x0
102306efc:	98 00 00 94	bl	__ZN2nc10percentileIiEENS_7NdArrayIdNSt3__19allocatorIdEEEERKNS1_IT_NS3_IS6_EEEEdNS_4AxisERKNS2_12basic_stringIcNS2_11char_traitsIcEENS3_IcEEEE
102306f00:	e8 2f 40 f9	ldr	x8, [sp, #0x58]
102306f04:	08 01 40 fd	ldr	d8, [x8]
102306f08:	74 0b 00 36	tbz	w20, #0x0, 0x102307074
102306f0c:	e8 83 41 39	ldrb	w8, [sp, #0x60]
102306f10:	88 00 00 34	cbz	w8, 0x102306f20
102306f14:	e0 2f 40 f9	ldr	x0, [sp, #0x58]
102306f18:	40 00 00 b4	cbz	x0, 0x102306f20
102306f1c:	e7 2a 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102306f20:	ff 2f 00 f9	str	xzr, [sp, #0x58]
102306f24:	ff 83 01 39	strb	wzr, [sp, #0x60]
102306f28:	ff c3 04 f8	stur	xzr, [sp, #0x4c]
102306f2c:	ff 43 04 f8	stur	xzr, [sp, #0x44]
102306f30:	e8 5f c0 39	ldrsb	w8, [sp, #0x17]
102306f34:	68 00 f8 36	tbz	w8, #0x1f, 0x102306f40
102306f38:	e0 03 40 f9	ldr	x0, [sp]
102306f3c:	df 2a 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102306f40:	e8 e3 40 39	ldrb	w8, [sp, #0x38]
102306f44:	48 0a 00 34	cbz	w8, 0x10230708c
102306f48:	e0 1b 40 f9	ldr	x0, [sp, #0x30]
102306f4c:	e0 09 00 b5	cbnz	x0, 0x102307088
102306f50:	4f 00 00 14	b	0x10230708c
102306f54:	e8 03 13 aa	mov	x8, x19
102306f58:	e9 03 15 aa	mov	x9, x21
102306f5c:	0a 45 40 b8	ldr	w10, [x8], #0x4
102306f60:	2a 45 00 b8	str	w10, [x9], #0x4
102306f64:	1f 01 18 eb	cmp	x8, x24
102306f68:	a1 ff ff 54	b.ne	0x102306f5c
102306f6c:	36 00 80 52	mov	w22, #0x1
102306f70:	e0 03 01 91	add	x0, sp, #0x40
102306f74:	e1 03 15 aa	mov	x1, x21
102306f78:	c3 a1 96 97	bl	__ZN2nc20NdArrayConstIteratorIiPKilEC2ES2_
102306f7c:	f8 23 40 f9	ldr	x24, [sp, #0x40]
102306f80:	e0 03 01 91	add	x0, sp, #0x40
102306f84:	e1 03 15 aa	mov	x1, x21
102306f88:	bf a1 96 97	bl	__ZN2nc20NdArrayConstIteratorIiPKilEC2ES2_
102306f8c:	e9 23 40 f9	ldr	x9, [sp, #0x40]
102306f90:	28 49 37 8b	add	x8, x9, w23, uxtw #2
102306f94:	1f 03 08 eb	cmp	x24, x8
102306f98:	40 01 00 54	b.eq	0x102306fc0
102306f9c:	2a 87 42 d3	ubfx	x10, x25, #2, #32
102306fa0:	29 09 0a 8b	add	x9, x9, x10, lsl #2
102306fa4:	29 01 18 cb	sub	x9, x9, x24
102306fa8:	29 11 00 d1	sub	x9, x9, #0x4
102306fac:	3f 71 00 f1	cmp	x9, #0x1c
102306fb0:	c2 00 00 54	b.hs	0x102306fc8
102306fb4:	08 e4 00 2f	movi	d8, #0000000000000000
102306fb8:	e9 03 18 aa	mov	x9, x24
102306fbc:	23 00 00 14	b	0x102307048
102306fc0:	08 e4 00 2f	movi	d8, #0000000000000000
102306fc4:	26 00 00 14	b	0x10230705c
102306fc8:	29 fd 42 d3	lsr	x9, x9, #2
102306fcc:	2a 05 00 91	add	x10, x9, #0x1
102306fd0:	4b ed 7d 92	and	x11, x10, #0x7ffffffffffffff8
102306fd4:	09 0b 0b 8b	add	x9, x24, x11, lsl #2
102306fd8:	0c 43 00 91	add	x12, x24, #0x10
102306fdc:	00 e4 00 6f	movi.2d	v0, #0000000000000000
102306fe0:	ed 03 0b aa	mov	x13, x11
102306fe4:	01 e4 00 6f	movi.2d	v1, #0000000000000000
102306fe8:	02 e4 00 6f	movi.2d	v2, #0000000000000000
102306fec:	03 e4 00 6f	movi.2d	v3, #0000000000000000
102306ff0:	84 15 7f 6d	ldp	d4, d5, [x12, #-0x10]
102306ff4:	86 1d c2 6c	ldp	d6, d7, [x12], #0x20
102306ff8:	84 a4 20 0f	sshll.2d	v4, v4, #0x0
102306ffc:	84 d8 61 4e	scvtf.2d	v4, v4
102307000:	a5 a4 20 0f	sshll.2d	v5, v5, #0x0
102307004:	a5 d8 61 4e	scvtf.2d	v5, v5
102307008:	c6 a4 20 0f	sshll.2d	v6, v6, #0x0
10230700c:	c6 d8 61 4e	scvtf.2d	v6, v6
102307010:	e7 a4 20 0f	sshll.2d	v7, v7, #0x0
102307014:	e7 d8 61 4e	scvtf.2d	v7, v7
102307018:	00 d4 64 4e	fadd.2d	v0, v0, v4
10230701c:	21 d4 65 4e	fadd.2d	v1, v1, v5
102307020:	42 d4 66 4e	fadd.2d	v2, v2, v6
102307024:	63 d4 67 4e	fadd.2d	v3, v3, v7
102307028:	ad 21 00 f1	subs	x13, x13, #0x8
10230702c:	21 fe ff 54	b.ne	0x102306ff0
102307030:	20 d4 60 4e	fadd.2d	v0, v1, v0
102307034:	40 d4 60 4e	fadd.2d	v0, v2, v0
102307038:	60 d4 60 4e	fadd.2d	v0, v3, v0
10230703c:	08 d8 70 7e	faddp.2d	d8, v0
102307040:	5f 01 0b eb	cmp	x10, x11
102307044:	c0 00 00 54	b.eq	0x10230705c
102307048:	2a 45 40 b8	ldr	w10, [x9], #0x4
10230704c:	40 01 62 1e	scvtf	d0, w10
102307050:	08 29 60 1e	fadd	d8, d8, d0
102307054:	3f 01 08 eb	cmp	x9, x8
102307058:	81 ff ff 54	b.ne	0x102307048
10230705c:	00 01 80 52	mov	w0, #0x8
102307060:	9c 2a 47 94	bl	0x1034d1ad0 ; symbol stub for: __Znwm
102307064:	e0 02 63 1e	ucvtf	d0, w23
102307068:	08 19 60 1e	fdiv	d8, d8, d0
10230706c:	08 00 00 fd	str	d8, [x0]
102307070:	f4 f4 07 37	tbnz	w20, #0x0, 0x102306f0c
102307074:	40 00 00 b4	cbz	x0, 0x10230707c
102307078:	90 2a 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10230707c:	96 00 00 34	cbz	w22, 0x10230708c
102307080:	75 00 00 b4	cbz	x21, 0x10230708c
102307084:	e0 03 15 aa	mov	x0, x21
102307088:	8c 2a 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
10230708c:	73 00 00 b4	cbz	x19, 0x102307098
102307090:	e0 03 13 aa	mov	x0, x19
102307094:	89 2a 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102307098:	00 41 60 1e	fmov	d0, d8
10230709c:	fd 7b 4e a9	ldp	x29, x30, [sp, #0xe0]
1023070a0:	f4 4f 4d a9	ldp	x20, x19, [sp, #0xd0]
1023070a4:	f6 57 4c a9	ldp	x22, x21, [sp, #0xc0]
1023070a8:	f8 5f 4b a9	ldp	x24, x23, [sp, #0xb0]
1023070ac:	fa 67 4a a9	ldp	x26, x25, [sp, #0xa0]
1023070b0:	fc 6f 49 a9	ldp	x28, x27, [sp, #0x90]
1023070b4:	e9 23 48 6d	ldp	d9, d8, [sp, #0x80]
1023070b8:	ff c3 03 91	add	sp, sp, #0xf0
1023070bc:	c0 03 5f d6	ret
1023070c0:	e0 a3 01 91	add	x0, sp, #0x68
1023070c4:	71 62 79 97	bl	__ZNKSt3__16vectorIiNS_9allocatorIiEEE20__throw_length_errorB6v15006Ev
1023070c8:	02 00 00 14	b	0x1023070d0
1023070cc:	eb c7 74 97	bl	__ZSt28__throw_bad_array_new_lengthB6v15006v
1023070d0:	20 00 20 d4	brk	#0x1
1023070d4:	1b 00 00 14	b	0x102307140
1023070d8:	1a 00 00 14	b	0x102307140
1023070dc:	f6 03 00 aa	mov	x22, x0
1023070e0:	17 01 00 34	cbz	w23, 0x102307100
1023070e4:	f5 00 00 b4	cbz	x21, 0x102307100
1023070e8:	e0 03 15 aa	mov	x0, x21
1023070ec:	73 2a 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
1023070f0:	04 00 00 14	b	0x102307100
1023070f4:	3b 12 74 97	bl	___clang_call_terminate
1023070f8:	3a 12 74 97	bl	___clang_call_terminate
1023070fc:	f6 03 00 aa	mov	x22, x0
102307100:	34 02 00 34	cbz	w20, 0x102307144
102307104:	e8 5f c0 39	ldrsb	w8, [sp, #0x17]
102307108:	68 00 f8 36	tbz	w8, #0x1f, 0x102307114
10230710c:	e0 03 40 f9	ldr	x0, [sp]
102307110:	6a 2a 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102307114:	e8 e3 40 39	ldrb	w8, [sp, #0x38]
102307118:	68 01 00 34	cbz	w8, 0x102307144
10230711c:	e0 1b 40 f9	ldr	x0, [sp, #0x30]
102307120:	20 01 00 b4	cbz	x0, 0x102307144
102307124:	65 2a 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102307128:	07 00 00 14	b	0x102307144
10230712c:	f6 03 00 aa	mov	x22, x0
102307130:	f3 37 40 f9	ldr	x19, [sp, #0x68]
102307134:	04 00 00 14	b	0x102307144
102307138:	02 00 00 14	b	0x102307140
10230713c:	01 00 00 14	b	0x102307140
102307140:	f6 03 00 aa	mov	x22, x0
102307144:	93 00 00 b4	cbz	x19, 0x102307154
102307148:	f3 3b 00 f9	str	x19, [sp, #0x70]
10230714c:	e0 03 13 aa	mov	x0, x19
102307150:	5a 2a 47 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102307154:	e0 03 16 aa	mov	x0, x22
102307158:	e5 27 47 94	bl	0x1034d10ec ; symbol stub for: __Unwind_Resume
