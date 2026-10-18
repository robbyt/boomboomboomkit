    r0 = arg1;
    d0 = 0xbff0000000000000;
    if (Abs(arg0) > s3 && r1 >= -0x3) {
            asm { fcvt       d1, s1 };
            asm { sshll      v2.2d, v2.2s, #0x0 };
            r8 = 0x404e000000000000;
            asm { fcvtzs     w8, d1 };
            asm { fmadd      d1, d1, d3, d2 };
            asm { fcvtzs     w10, d1 };
            if (r10 + r8 - 0x1 <= r0[0x7] && 0x404e000000000000 >= 0x1) {
                    r8 = 0x404e000000000000;
                    r9 = r0[0x10];
                    asm { sxtw       x10, w10 };
                    if (r8 < 0x10) {
                            d0 = 0x0;
                            r9 = r9 + (0x0 + r10) * 0x2;
                            r8 = 0x404e000000000000;
                            do {
                                    r10 = sign_extend_64(*(int16_t *)r9);
                                    r9 = r9 + 0x2;
                                    d0 = d0 + r10;
                                    r8 = r8 - 0x1;
                            } while (r8 != 0x0);
                    }
                    else {
                            r11 = r8 & 0xfffffff0;
                            v0 = 0x0;
                            v2 = 0x0;
                            r12 = r9 + r10 * 0x2 + 0x10;
                            r13 = r11;
                            v1 = 0x0;
                            v4 = 0x0;
                            v3 = 0x0;
                            v6 = 0x0;
                            v5 = 0x0;
                            v7 = 0x0;
                            do {
                                    asm { ext        v17.16b, v19.16b, v19.16b, #0x8 };
                                    asm { umov       w14, v17.h[0] };
                                    asm { umov       w14, v17.h[1] };
                                    v18 = r14;
                                    asm { shl        v18.2s, v18.2s, #0x10 };
                                    asm { sshr       v18.2s, v18.2s, #0x10 };
                                    asm { sshll      v18.2d, v18.2s, #0x0 };
                                    asm { umov       w14, v17.h[2] };
                                    asm { umov       w14, v17.h[3] };
                                    v17 = v18;
                                    asm { shl        v18.2s, v20.2s, #0x10 };
                                    asm { sshr       v18.2s, v18.2s, #0x10 };
                                    asm { sshll      v18.2d, v18.2s, #0x0 };
                                    asm { umov       w14, v19.h[0] };
                                    asm { umov       w14, v19.h[1] };
                                    v20 = r14;
                                    asm { shl        v20.2s, v20.2s, #0x10 };
                                    asm { sshr       v20.2s, v20.2s, #0x10 };
                                    asm { umov       w14, v19.h[2] };
                                    asm { sshll      v20.2d, v20.2s, #0x0 };
                                    asm { umov       w14, v19.h[3] };
                                    v21 = r14;
                                    v19 = v20;
                                    asm { shl        v20.2s, v21.2s, #0x10 };
                                    asm { sshr       v20.2s, v20.2s, #0x10 };
                                    asm { ext        v21.16b, v16.16b, v16.16b, #0x8 };
                                    asm { umov       w14, v21.h[0] };
                                    asm { sshll      v20.2d, v20.2s, #0x0 };
                                    asm { umov       w14, v21.h[1] };
                                    v22 = r14;
                                    asm { shl        v22.2s, v22.2s, #0x10 };
                                    asm { sshr       v22.2s, v22.2s, #0x10 };
                                    asm { sshll      v22.2d, v22.2s, #0x0 };
                                    asm { umov       w14, v21.h[2] };
                                    asm { umov       w14, v21.h[3] };
                                    asm { shl        v21.2s, v23.2s, #0x10 };
                                    asm { sshr       v21.2s, v21.2s, #0x10 };
                                    asm { sshll      v21.2d, v21.2s, #0x0 };
                                    asm { umov       w14, v16.h[0] };
                                    asm { umov       w14, v16.h[1] };
                                    v23 = r14;
                                    asm { shl        v23.2s, v23.2s, #0x10 };
                                    asm { sshr       v23.2s, v23.2s, #0x10 };
                                    asm { sshll      v23.2d, v23.2s, #0x0 };
                                    asm { umov       w14, v16.h[2] };
                                    asm { umov       w14, v16.h[3] };
                                    asm { shl        v16.2s, v24.2s, #0x10 };
                                    asm { sshr       v16.2s, v16.2s, #0x10 };
                                    asm { sshll      v16.2d, v16.2s, #0x0 };
                                    v4 = v4 + v18;
                                    v1 = v1 + v17;
                                    v2 = v2 + v20;
                                    v0 = v0 + v19;
                                    v7 = v7 + v21;
                                    v5 = v5 + v22;
                                    v6 = v6 + v16;
                                    v3 = v3 + v23;
                                    r12 = r12 + 0x20;
                                    r13 = r13 - 0x10;
                            } while (r13 != 0x0);
                            asm { faddp      d0, v0.2d };
                            if (r11 != r8) {
                                    r9 = r9 + (r11 + r10) * 0x2;
                                    r8 = 0x404e000000000000 - r11;
                                    do {
                                            r10 = sign_extend_64(*(int16_t *)r9);
                                            r9 = r9 + 0x2;
                                            d0 = d0 + r10;
                                            r8 = r8 - 0x1;
                                    } while (r8 != 0x0);
                            }
                    }
            }
    }
    return r0;
