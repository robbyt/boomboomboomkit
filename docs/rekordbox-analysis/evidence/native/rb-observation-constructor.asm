/Applications/rekordbox 7/rekordbox.app/Contents/MacOS/rekordbox:
(__TEXT,__text) section
__ZN6madmom35RNNDownBeatTrackingObservationModelC2ERKNS_13BarStateSpaceEi:
102316950:	ff c3 05 d1	sub	sp, sp, #0x170
102316954:	e9 23 10 6d	stp	d9, d8, [sp, #0x100]
102316958:	fc 6f 11 a9	stp	x28, x27, [sp, #0x110]
10231695c:	fa 67 12 a9	stp	x26, x25, [sp, #0x120]
102316960:	f8 5f 13 a9	stp	x24, x23, [sp, #0x130]
102316964:	f6 57 14 a9	stp	x22, x21, [sp, #0x140]
102316968:	f4 4f 15 a9	stp	x20, x19, [sp, #0x150]
10231696c:	fd 7b 16 a9	stp	x29, x30, [sp, #0x160]
102316970:	fd 83 05 91	add	x29, sp, #0x160
102316974:	f5 03 02 aa	mov	x21, x2
102316978:	f4 03 01 aa	mov	x20, x1
10231697c:	f3 03 00 aa	mov	x19, x0
102316980:	1f 10 00 f9	str	xzr, [x0, #0x20]
102316984:	1f a0 00 39	strb	wzr, [x0, #0x28]
102316988:	1f 40 01 f8	stur	xzr, [x0, #0x14]
10231698c:	1f c0 00 f8	stur	xzr, [x0, #0xc]
102316990:	08 7f 01 b0	adrp	x8, 12257 ; 0x1052f7000
102316994:	08 c1 25 91	add	x8, x8, #0x970
102316998:	08 00 00 f9	str	x8, [x0]
10231699c:	02 30 00 b9	str	w2, [x0, #0x30]
1023169a0:	38 58 40 b9	ldr	w24, [x1, #0x58]
1023169a4:	28 00 80 52	mov	w8, #0x1
1023169a8:	a8 e3 2e 29	stp	w8, w24, [x29, #-0x8c]
1023169ac:	b8 ff 2f 29	stp	w24, wzr, [x29, #-0x84]
1023169b0:	bf 83 18 f8	stur	xzr, [x29, #-0x78]
1023169b4:	bf 03 19 38	sturb	wzr, [x29, #-0x70]
1023169b8:	18 01 00 34	cbz	w24, 0x1023169d8
1023169bc:	00 f7 7e d3	lsl	x0, x24, #2
1023169c0:	44 ec 46 94	bl	0x1034d1ad0 ; symbol stub for: __Znwm
1023169c4:	f6 03 00 aa	mov	x22, x0
1023169c8:	a0 83 18 f8	stur	x0, [x29, #-0x78]
1023169cc:	28 00 80 52	mov	w8, #0x1
1023169d0:	a8 03 19 38	sturb	w8, [x29, #-0x70]
1023169d4:	02 00 00 14	b	0x1023169dc
1023169d8:	16 00 80 d2	mov	x22, #0x0
1023169dc:	e0 a3 02 91	add	x0, sp, #0xa8
1023169e0:	e1 03 16 aa	mov	x1, x22
1023169e4:	d4 84 96 97	bl	__ZN2nc20NdArrayConstIteratorIjPjlEC2ES1_
1023169e8:	f7 57 40 f9	ldr	x23, [sp, #0xa8]
1023169ec:	e0 a3 02 91	add	x0, sp, #0xa8
1023169f0:	e1 03 16 aa	mov	x1, x22
1023169f4:	d0 84 96 97	bl	__ZN2nc20NdArrayConstIteratorIjPjlEC2ES1_
1023169f8:	e8 57 40 f9	ldr	x8, [sp, #0xa8]
1023169fc:	08 09 18 8b	add	x8, x8, x24, lsl #2
102316a00:	08 01 17 cb	sub	x8, x8, x23
102316a04:	1f 05 00 f1	cmp	x8, #0x1
102316a08:	2b 01 00 54	b.lt	0x102316a2c
102316a0c:	09 fd 42 d3	lsr	x9, x8, #2
102316a10:	1f 0d 00 f1	cmp	x8, #0x3
102316a14:	e8 97 9f 1a	cset	w8, hi
102316a18:	28 01 08 cb	sub	x8, x9, x8
102316a1c:	08 f5 7e d3	lsl	x8, x8, #2
102316a20:	01 11 00 91	add	x1, x8, #0x4
102316a24:	e0 03 17 aa	mov	x0, x23
102316a28:	ea ec 46 94	bl	0x1034d1dd0 ; symbol stub for: _bzero
102316a2c:	94 22 00 91	add	x20, x20, #0x8
102316a30:	e0 63 01 91	add	x0, sp, #0x58
102316a34:	e1 03 14 aa	mov	x1, x20
102316a38:	d2 8a 96 97	bl	__ZN2nc7NdArrayIdNSt3__19allocatorIdEEEC2ERKS4_
102316a3c:	e1 3b 40 f9	ldr	x1, [sp, #0x70]
102316a40:	a0 a3 01 d1	sub	x0, x29, #0x68
102316a44:	e2 54 96 97	bl	__ZN2nc20NdArrayConstIteratorIdPdlEC2ES1_
102316a48:	b9 83 59 f8	ldur	x25, [x29, #-0x68]
102316a4c:	f6 67 40 b9	ldr	w22, [sp, #0x64]
102316a50:	e1 3b 40 f9	ldr	x1, [sp, #0x70]
102316a54:	a0 a3 01 d1	sub	x0, x29, #0x68
102316a58:	dd 54 96 97	bl	__ZN2nc20NdArrayConstIteratorIdPdlEC2ES1_
102316a5c:	a0 02 62 1e	scvtf	d0, w21
102316a60:	01 10 6e 1e	fmov	d1, #1.00000000
102316a64:	28 18 60 1e	fdiv	d8, d1, d0
102316a68:	a8 83 59 f8	ldur	x8, [x29, #-0x68]
102316a6c:	15 0d 16 8b	add	x21, x8, x22, lsl #3
102316a70:	3f 03 15 eb	cmp	x25, x21
102316a74:	40 09 00 54	b.eq	0x102316b9c
102316a78:	a8 02 19 cb	sub	x8, x21, x25
102316a7c:	08 21 00 d1	sub	x8, x8, #0x8
102316a80:	f6 03 19 aa	mov	x22, x25
102316a84:	1f e1 00 f1	cmp	x8, #0x38
102316a88:	e3 07 00 54	b.lo	0x102316b84
102316a8c:	08 fd 43 d3	lsr	x8, x8, #3
102316a90:	17 05 00 91	add	x23, x8, #0x1
102316a94:	f8 ea 7d 92	and	x24, x23, #0x3ffffffffffffff8
102316a98:	36 0f 18 8b	add	x22, x25, x24, lsl #3
102316a9c:	39 83 00 91	add	x25, x25, #0x20
102316aa0:	fa 03 18 aa	mov	x26, x24
102316aa4:	21 0b 7f ad	ldp	q1, q2, [x25, #-0x20]
102316aa8:	e1 03 80 3d	str	q1, [sp]
102316aac:	20 03 c0 3d	ldr	q0, [x25]
102316ab0:	e2 03 01 ad	stp	q2, q0, [sp, #0x20]
102316ab4:	20 07 c0 3d	ldr	q0, [x25, #0x10]
102316ab8:	e0 13 80 3d	str	q0, [sp, #0x40]
102316abc:	20 04 18 5e	mov	d0, v1[1]
102316ac0:	01 10 6e 1e	fmov	d1, #1.00000000
102316ac4:	8c ed 46 94	bl	0x1034d20f4 ; symbol stub for: _fmod
102316ac8:	e0 07 80 3d	str	q0, [sp, #0x10]
102316acc:	01 10 6e 1e	fmov	d1, #1.00000000
102316ad0:	e0 03 c0 3d	ldr	q0, [sp]
102316ad4:	88 ed 46 94	bl	0x1034d20f4 ; symbol stub for: _fmod
102316ad8:	e1 07 c0 3d	ldr	q1, [sp, #0x10]
102316adc:	20 04 18 6e	mov.d	v0[1], v1[0]
102316ae0:	e0 07 80 3d	str	q0, [sp, #0x10]
102316ae4:	e0 0b c0 3d	ldr	q0, [sp, #0x20]
102316ae8:	00 04 18 5e	mov	d0, v0[1]
102316aec:	01 10 6e 1e	fmov	d1, #1.00000000
102316af0:	81 ed 46 94	bl	0x1034d20f4 ; symbol stub for: _fmod
102316af4:	e0 03 80 3d	str	q0, [sp]
102316af8:	01 10 6e 1e	fmov	d1, #1.00000000
102316afc:	e0 0b c0 3d	ldr	q0, [sp, #0x20]
102316b00:	7d ed 46 94	bl	0x1034d20f4 ; symbol stub for: _fmod
102316b04:	e1 03 c0 3d	ldr	q1, [sp]
102316b08:	20 04 18 6e	mov.d	v0[1], v1[0]
102316b0c:	e0 0b 80 3d	str	q0, [sp, #0x20]
102316b10:	e0 0f c0 3d	ldr	q0, [sp, #0x30]
102316b14:	00 04 18 5e	mov	d0, v0[1]
102316b18:	01 10 6e 1e	fmov	d1, #1.00000000
102316b1c:	76 ed 46 94	bl	0x1034d20f4 ; symbol stub for: _fmod
102316b20:	e0 03 80 3d	str	q0, [sp]
102316b24:	01 10 6e 1e	fmov	d1, #1.00000000
102316b28:	e0 0f c0 3d	ldr	q0, [sp, #0x30]
102316b2c:	72 ed 46 94	bl	0x1034d20f4 ; symbol stub for: _fmod
102316b30:	e1 03 c0 3d	ldr	q1, [sp]
102316b34:	20 04 18 6e	mov.d	v0[1], v1[0]
102316b38:	e0 0f 80 3d	str	q0, [sp, #0x30]
102316b3c:	e0 13 c0 3d	ldr	q0, [sp, #0x40]
102316b40:	00 04 18 5e	mov	d0, v0[1]
102316b44:	01 10 6e 1e	fmov	d1, #1.00000000
102316b48:	6b ed 46 94	bl	0x1034d20f4 ; symbol stub for: _fmod
102316b4c:	e0 03 80 3d	str	q0, [sp]
102316b50:	01 10 6e 1e	fmov	d1, #1.00000000
102316b54:	e0 13 c0 3d	ldr	q0, [sp, #0x40]
102316b58:	67 ed 46 94	bl	0x1034d20f4 ; symbol stub for: _fmod
102316b5c:	e1 0b 40 ad	ldp	q1, q2, [sp]
102316b60:	20 04 18 6e	mov.d	v0[1], v1[0]
102316b64:	e1 0b c0 3d	ldr	q1, [sp, #0x20]
102316b68:	22 07 3f ad	stp	q2, q1, [x25, #-0x20]
102316b6c:	e1 0f c0 3d	ldr	q1, [sp, #0x30]
102316b70:	21 03 82 ac	stp	q1, q0, [x25], #0x40
102316b74:	5a 23 00 f1	subs	x26, x26, #0x8
102316b78:	61 f9 ff 54	b.ne	0x102316aa4
102316b7c:	ff 02 18 eb	cmp	x23, x24
102316b80:	e0 00 00 54	b.eq	0x102316b9c
102316b84:	c0 02 40 fd	ldr	d0, [x22]
102316b88:	01 10 6e 1e	fmov	d1, #1.00000000
102316b8c:	5a ed 46 94	bl	0x1034d20f4 ; symbol stub for: _fmod
102316b90:	c0 86 00 fc	str	d0, [x22], #0x8
102316b94:	df 02 15 eb	cmp	x22, x21
102316b98:	61 ff ff 54	b.ne	0x102316b84
102316b9c:	e8 c3 45 f8	ldur	x8, [sp, #0x5c]
102316ba0:	e8 43 08 f8	stur	x8, [sp, #0x84]
102316ba4:	e0 43 46 fc	ldur	d0, [sp, #0x64]
102316ba8:	e0 c3 08 fc	stur	d0, [sp, #0x8c]
102316bac:	e8 3b 40 f9	ldr	x8, [sp, #0x70]
102316bb0:	e8 4f 00 f9	str	x8, [sp, #0x98]
102316bb4:	e8 e3 41 39	ldrb	w8, [sp, #0x78]
102316bb8:	e8 83 02 39	strb	w8, [sp, #0xa0]
102316bbc:	ff 33 00 f9	str	xzr, [sp, #0x60]
102316bc0:	ff 5f 00 b9	str	wzr, [sp, #0x5c]
102316bc4:	ff e3 01 39	strb	wzr, [sp, #0x78]
102316bc8:	ff 3b 00 f9	str	xzr, [sp, #0x70]
102316bcc:	e8 a3 02 91	add	x8, sp, #0xa8
102316bd0:	e0 03 02 91	add	x0, sp, #0x80
102316bd4:	00 41 60 1e	fmov	d0, d8
102316bd8:	0e 01 00 94	bl	__ZN2ncltIdEENS_7NdArrayIbNSt3__19allocatorIbEEEERKNS1_IT_NS3_IS6_EEEES6_
102316bdc:	28 00 80 52	mov	w8, #0x1
102316be0:	a8 83 19 b8	stur	w8, [x29, #-0x68]
102316be4:	a0 43 02 d1	sub	x0, x29, #0x90
102316be8:	e1 a3 02 91	add	x1, sp, #0xa8
102316bec:	a2 a3 01 d1	sub	x2, x29, #0x68
102316bf0:	75 00 00 94	bl	__ZN2nc7NdArrayIjNSt3__19allocatorIjEEE7putMaskERKNS0_IbNS2_IbEEEERKj
102316bf4:	e8 23 43 39	ldrb	w8, [sp, #0xc8]
102316bf8:	88 00 00 34	cbz	w8, 0x102316c08
102316bfc:	e0 63 40 f9	ldr	x0, [sp, #0xc0]
102316c00:	40 00 00 b4	cbz	x0, 0x102316c08
102316c04:	ad eb 46 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102316c08:	ff 63 00 f9	str	xzr, [sp, #0xc0]
102316c0c:	ff 23 03 39	strb	wzr, [sp, #0xc8]
102316c10:	ff 43 0b f8	stur	xzr, [sp, #0xb4]
102316c14:	ff c3 0a f8	stur	xzr, [sp, #0xac]
102316c18:	e8 83 42 39	ldrb	w8, [sp, #0xa0]
102316c1c:	88 00 00 34	cbz	w8, 0x102316c2c
102316c20:	e0 4f 40 f9	ldr	x0, [sp, #0x98]
102316c24:	40 00 00 b4	cbz	x0, 0x102316c2c
102316c28:	a4 eb 46 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102316c2c:	ff 4f 00 f9	str	xzr, [sp, #0x98]
102316c30:	ff 83 02 39	strb	wzr, [sp, #0xa0]
102316c34:	ff c3 08 f8	stur	xzr, [sp, #0x8c]
102316c38:	ff 43 08 f8	stur	xzr, [sp, #0x84]
102316c3c:	e8 e3 41 39	ldrb	w8, [sp, #0x78]
102316c40:	88 00 00 34	cbz	w8, 0x102316c50
102316c44:	e0 3b 40 f9	ldr	x0, [sp, #0x70]
102316c48:	40 00 00 b4	cbz	x0, 0x102316c50
102316c4c:	9b eb 46 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102316c50:	ff 3b 00 f9	str	xzr, [sp, #0x70]
102316c54:	ff e3 01 39	strb	wzr, [sp, #0x78]
102316c58:	ff 43 06 f8	stur	xzr, [sp, #0x64]
102316c5c:	ff c3 05 f8	stur	xzr, [sp, #0x5c]
102316c60:	e8 a3 02 91	add	x8, sp, #0xa8
102316c64:	e0 03 14 aa	mov	x0, x20
102316c68:	00 41 60 1e	fmov	d0, d8
102316c6c:	e9 00 00 94	bl	__ZN2ncltIdEENS_7NdArrayIbNSt3__19allocatorIbEEEERKNS1_IT_NS3_IS6_EEEES6_
102316c70:	48 00 80 52	mov	w8, #0x2
102316c74:	e8 83 00 b9	str	w8, [sp, #0x80]
102316c78:	a0 43 02 d1	sub	x0, x29, #0x90
102316c7c:	e1 a3 02 91	add	x1, sp, #0xa8
102316c80:	e2 03 02 91	add	x2, sp, #0x80
102316c84:	50 00 00 94	bl	__ZN2nc7NdArrayIjNSt3__19allocatorIjEEE7putMaskERKNS0_IbNS2_IbEEEERKj
102316c88:	e8 23 43 39	ldrb	w8, [sp, #0xc8]
102316c8c:	88 00 00 34	cbz	w8, 0x102316c9c
102316c90:	e0 63 40 f9	ldr	x0, [sp, #0xc0]
102316c94:	40 00 00 b4	cbz	x0, 0x102316c9c
102316c98:	88 eb 46 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102316c9c:	60 22 00 91	add	x0, x19, #0x8
102316ca0:	a1 43 02 d1	sub	x1, x29, #0x90
102316ca4:	0d ed ff 97	bl	__ZN2nc7NdArrayIjNSt3__19allocatorIjEEEaSERKS4_
102316ca8:	a8 03 59 38	ldurb	w8, [x29, #-0x70]
102316cac:	88 00 00 34	cbz	w8, 0x102316cbc
102316cb0:	a0 83 58 f8	ldur	x0, [x29, #-0x78]
102316cb4:	40 00 00 b4	cbz	x0, 0x102316cbc
102316cb8:	80 eb 46 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102316cbc:	e0 03 13 aa	mov	x0, x19
102316cc0:	fd 7b 56 a9	ldp	x29, x30, [sp, #0x160]
102316cc4:	f4 4f 55 a9	ldp	x20, x19, [sp, #0x150]
102316cc8:	f6 57 54 a9	ldp	x22, x21, [sp, #0x140]
102316ccc:	f8 5f 53 a9	ldp	x24, x23, [sp, #0x130]
102316cd0:	fa 67 52 a9	ldp	x26, x25, [sp, #0x120]
102316cd4:	fc 6f 51 a9	ldp	x28, x27, [sp, #0x110]
102316cd8:	e9 23 50 6d	ldp	d9, d8, [sp, #0x100]
102316cdc:	ff c3 05 91	add	sp, sp, #0x170
102316ce0:	c0 03 5f d6	ret
102316ce4:	f4 03 00 aa	mov	x20, x0
102316ce8:	31 00 00 14	b	0x102316dac
102316cec:	2a 00 00 14	b	0x102316d94
102316cf0:	f4 03 00 aa	mov	x20, x0
102316cf4:	e8 23 43 39	ldrb	w8, [sp, #0xc8]
102316cf8:	08 05 00 34	cbz	w8, 0x102316d98
102316cfc:	e0 63 40 f9	ldr	x0, [sp, #0xc0]
102316d00:	c0 04 00 b4	cbz	x0, 0x102316d98
102316d04:	6d eb 46 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102316d08:	24 00 00 14	b	0x102316d98
102316d0c:	22 00 00 14	b	0x102316d94
102316d10:	f4 03 00 aa	mov	x20, x0
102316d14:	e8 23 43 39	ldrb	w8, [sp, #0xc8]
102316d18:	88 00 00 34	cbz	w8, 0x102316d28
102316d1c:	e0 63 40 f9	ldr	x0, [sp, #0xc0]
102316d20:	40 00 00 b4	cbz	x0, 0x102316d28
102316d24:	65 eb 46 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102316d28:	ff 63 00 f9	str	xzr, [sp, #0xc0]
102316d2c:	ff 23 03 39	strb	wzr, [sp, #0xc8]
102316d30:	ff 43 0b f8	stur	xzr, [sp, #0xb4]
102316d34:	ff c3 0a f8	stur	xzr, [sp, #0xac]
102316d38:	02 00 00 14	b	0x102316d40
102316d3c:	f4 03 00 aa	mov	x20, x0
102316d40:	e8 83 42 39	ldrb	w8, [sp, #0xa0]
102316d44:	88 00 00 34	cbz	w8, 0x102316d54
102316d48:	e0 4f 40 f9	ldr	x0, [sp, #0x98]
102316d4c:	40 00 00 b4	cbz	x0, 0x102316d54
102316d50:	5a eb 46 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102316d54:	ff 4f 00 f9	str	xzr, [sp, #0x98]
102316d58:	ff 83 02 39	strb	wzr, [sp, #0xa0]
102316d5c:	ff c3 08 f8	stur	xzr, [sp, #0x8c]
102316d60:	ff 43 08 f8	stur	xzr, [sp, #0x84]
102316d64:	e8 e3 41 39	ldrb	w8, [sp, #0x78]
102316d68:	88 00 00 34	cbz	w8, 0x102316d78
102316d6c:	e0 3b 40 f9	ldr	x0, [sp, #0x70]
102316d70:	40 00 00 b4	cbz	x0, 0x102316d78
102316d74:	51 eb 46 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102316d78:	ff 3b 00 f9	str	xzr, [sp, #0x70]
102316d7c:	ff e3 01 39	strb	wzr, [sp, #0x78]
102316d80:	ff 43 06 f8	stur	xzr, [sp, #0x64]
102316d84:	ff c3 05 f8	stur	xzr, [sp, #0x5c]
102316d88:	04 00 00 14	b	0x102316d98
102316d8c:	15 d3 73 97	bl	___clang_call_terminate
102316d90:	14 d3 73 97	bl	___clang_call_terminate
102316d94:	f4 03 00 aa	mov	x20, x0
102316d98:	a8 03 59 38	ldurb	w8, [x29, #-0x70]
102316d9c:	88 00 00 34	cbz	w8, 0x102316dac
102316da0:	a0 83 58 f8	ldur	x0, [x29, #-0x78]
102316da4:	40 00 00 b4	cbz	x0, 0x102316dac
102316da8:	44 eb 46 94	bl	0x1034d1ab8 ; symbol stub for: __ZdlPv
102316dac:	e0 03 13 aa	mov	x0, x19
102316db0:	17 01 00 94	bl	__ZN6madmom16ObservationModelD2Ev
102316db4:	e0 03 14 aa	mov	x0, x20
102316db8:	cd e8 46 94	bl	0x1034d10ec ; symbol stub for: __Unwind_Resume
102316dbc:	09 d3 73 97	bl	___clang_call_terminate
102316dc0:	08 d3 73 97	bl	___clang_call_terminate
