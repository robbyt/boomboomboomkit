    r6 = arg7;
    r5 = arg6;
    r4 = arg5;
    r3 = arg4;
    r2 = arg3;
    r1 = arg2;
    r0 = arg1;
    s0 = arg0;
    r31 = r31 - 0x130;
    var_60 = d9;
    decomp_var_58 = d8;
    var_50 = r28;
    decomp_var_48 = r27;
    var_40 = r26;
    decomp_var_38 = r25;
    var_30 = r24;
    decomp_var_28 = r23;
    var_20 = r22;
    decomp_var_18 = r21;
    var_10 = r20;
    decomp_var_8 = r19;
    saved_fp = r29;
    decomp_var_m8 = r30;
    if ((r2 & 0xffffffff80000000) == 0x0) {
            d8 = d0;
            if (d0 > 0x0 && r1 - 0x34 >= -0x33) {
                    r28 = r3;
                    if (r3 >= 0x1) {
                            r20 = r2;
                            r23 = r0;
                            if (r0[0x7] > r2) {
                                    r27 = r6;
                                    r22 = r5;
                                    var_F8 = r4;
                                    var_118 = r7;
                                    var_70 = 0x0;
                                    r24 = r1 << 0x5;
                                    r0 = operator new(r24 << 0x3);
                                    var_F0 = r0;
                                    bzero(r0, r24 << 0x3);
                                    var_100 = r24 << 0x3;
                                    r0 = operator new(r24 << 0x3);
                                    var_88 = r0;
                                    var_108 = ((r24 - 0x1 & 0x1fffffffffffffff) << 0x3) + 0x8;
                                    bzero(r0, ((r24 - 0x1 & 0x1fffffffffffffff) << 0x3) + 0x8);
                                    r25 = 0x0;
                                    var_110 = (r24 - 0x1 & 0x1fffffffffffffff) + 0x1;
                                    do {
                                            asm { fmadd      d0, d0, d1, d8 };
                                            asm { fmaxnm     d0, d0, d1 };
                                            asm { fminnm     d9, d0, d1 };
                                            BeatAnalyzer_2_0::UnitBeatAdjust::createBeatData(s0, r23);
                                            BeatAnalyzer_2_0::UnitBeatAdjust::manageWave(r23, r28, r23[0x6]);
                                            *(var_F0 + (r25 << 0x3)) = d9;
                                            d0 = var_70;
                                            *(var_88 + (r25 << 0x3)) = d0;
                                            if (*r22 < d0) {
                                                    *r22 = d0;
                                                    *var_F8 = d9;
                                                    *(int32_t *)r27 = r23[0x6];
                                            }
                                            r8 = r23[0x6];
                                            r23[0x6] = r8 + 0x1;
                                            if ((r8 + 0x1 & 0x3) == 0x0) {
                                                    var_A0 = 0x0;
                                                    nanosleep(&var_A0, 0x0);
                                            }
                                            r25 = r25 + 0x1;
                                    } while (r24 != r25);
                                    r0 = operator new(r24 << 0x2);
                                    var_A0 = r0;
                                    bzero(r0, r24 << 0x2);
                                    r0 = operator new(var_100);
                                    var_B8 = r0;
                                    bzero(r0, var_108);
                                    r0 = operator new(var_100);
                                    var_D0 = r0;
                                    bzero(r0, var_108);
                                    r0 = operator new(var_100);
                                    var_E8 = r0;
                                    bzero(r0, var_108);
                                    r0 = BeatAnalyzer_2_0::UnitBeatAdjust::findpeaks_x(r23, r24, &var_88, &var_A0, &var_B8, &var_D0);
                                    r9 = var_A0;
                                    if (r24 <= 0x1) {
                                            r8 = 0x1;
                                    }
                                    else {
                                            r8 = r24;
                                    }
                                    r10 = 0xfffffff6;
                                    r11 = r9;
                                    r14 = var_118;
                                    r15 = var_F8;
                                    while (true) {
                                            r12 = *(int32_t *)r11;
                                            if (r12 == 0x0) {
                                                    r8 = r10 + 0xa;
                                                    r11 = 0x1;
                                                    *(int8_t *)r14 = 0x1;
                                                    if (r8 >= 0x15) {
                                                            d0 = *r22;
                                                            d0 = d0 * 0x3fb3333333333333;
                                                            r11 = var_D0 + 0x50;
                                                            r10 = r10 - 0xa;
                                                            r12 = 0x1;
                                                            do {
                                                                    if (*r11 > d0) {
                                                                            r12 = 0x0;
                                                                            *(int8_t *)r14 = 0x0;
                                                                    }
                                                                    r11 = r11 + 0x8;
                                                                    r10 = r10 - 0x1;
                                                            } while (r10 != 0x0);
                                                            if (r12 == 0x0) {
                                                                    r11 = 0x0;
                                                                    r12 = var_D0;
                                                                    if (r8 <= 0x1) {
                                                                            r10 = 0x1;
                                                                            temp_0 = 0x2;
                                                                    }
                                                                    else {
                                                                            r10 = r8;
                                                                            temp_0 = 0x2;
                                                                    }
                                                            }
                                                            else {
                                                                    temp_0 = 0x1;
                                                            }
                                                    }
                                                    else {
                                                            temp_0 = 0x0;
                                                    }
                                                    break;
                                            }
                                            r10 = r10 + 0x1;
                                            r11 = r11 + 0x4;
                                            r8 = r8 - 0x1;
                                            if (r8 != 0x0) {
                                                    continue;
                                            }
                                            temp_0 = 0x3;
                                            break;
                                    }
                                    if (temp_0 != 0x0 && temp_0 != 0x1) {
                                            if (temp_0 != 0x2) {
                                                    *(int8_t *)r14 = 0x1;
                                            }
                                            else {
                                                    d0 = 0x0;
                                                    r13 = r10;
                                                    do {
                                                            d1 = *r12;
                                                            if (d0 < d1) {
                                                                    r11 = *(int32_t *)r9;
                                                                    r11 = r11 - 0x1;
                                                                    d0 = d1;
                                                            }
                                                            r12 = r12 + 0x8;
                                                            r9 = r9 + 0x4;
                                                            r13 = r13 - 0x1;
                                                    } while (r13 != 0x0);
                                                    d1 = *r15;
                                                    d0 = *(var_F0 + r11 * 0x8);
                                                    if (d1 != d0) {
                                                            *r15 = d0;
                                                    }
                                                    r9 = var_B8;
                                                    if (r10 < 0x8) {
                                                            r12 = 0x0;
                                                            r9 = r9 + 0x0;
                                                            if (r8 <= 0x1) {
                                                                    r10 = 0x1;
                                                                    do {
                                                                            r9 = r9 + 0x8;
                                                                            asm { cinc       w12, w12, gt };
                                                                            r10 = r10 - 0x1;
                                                                    } while (r10 != 0x0);
                                                            }
                                                            else {
                                                                    r10 = r8;
                                                                    r10 = r10 - 0x0;
                                                                    do {
                                                                            r9 = r9 + 0x8;
                                                                            asm { cinc       w12, w12, gt };
                                                                            r10 = r10 - 0x1;
                                                                    } while (r10 != 0x0);
                                                            }
                                                    }
                                                    else {
                                                            r11 = r10 & 0xfffffff8;
                                                            asm { dup        v1.2d, v0.d[0] };
                                                            r12 = r9 + 0x20;
                                                            if (r8 <= 0x1) {
                                                                    r13 = 0x1;
                                                            }
                                                            else {
                                                                    r13 = r8;
                                                            }
                                                            r13 = r13 & 0xfffffff8;
                                                            v2 = 0x0;
                                                            v3 = 0x0;
                                                            v4 = 0x0;
                                                            v5 = 0x0;
                                                            do {
                                                                    r12 = r12 + 0x40;
                                                                    asm { fcmgt      v6.2d, v6.2d, v1.2d };
                                                                    asm { xtn        v6.2s, v6.2d };
                                                                    asm { fcmgt      v7.2d, v7.2d, v1.2d };
                                                                    asm { xtn        v7.2s, v7.2d };
                                                                    asm { fcmgt      v16.2d, v16.2d, v1.2d };
                                                                    asm { xtn        v16.2s, v16.2d };
                                                                    asm { fcmgt      v17.2d, v17.2d, v1.2d };
                                                                    asm { xtn        v17.2s, v17.2d };
                                                                    v2 = v2 - v6;
                                                                    v3 = v3 - v7;
                                                                    v4 = v4 - v16;
                                                                    v5 = v5 - v17;
                                                                    r13 = r13 - 0x8;
                                                            } while (r13 != 0x0);
                                                            asm { addp       v1.2s, v1.2s, v1.2s };
                                                            r12 = s1;
                                                            if (r11 != r10) {
                                                                    r9 = r9 + r11 * 0x8;
                                                                    if (r8 <= 0x1) {
                                                                            r10 = 0x1;
                                                                    }
                                                                    else {
                                                                            r10 = r8;
                                                                    }
                                                                    r10 = r10 - r11;
                                                                    do {
                                                                            r9 = r9 + 0x8;
                                                                            asm { cinc       w12, w12, gt };
                                                                            r10 = r10 - 0x1;
                                                                    } while (r10 != 0x0);
                                                            }
                                                    }
                                                    if (r12 / r8 > 0x3fe0000000000000) {
                                                            *(int8_t *)r14 = 0x1;
                                                    }
                                            }
                                    }
                                    asm { frinta     d0, d0 };
                                    asm { fccmp      d0, d1, #0x0, ge };
                                    if (!asm { fccmp      d0, d1, #0x0, ge }) {
                                            *(int8_t *)r14 = 0x0;
                                    }
                                    asm { fccmp      d0, d1, #0x0, gt };
                                    if (!asm { fccmp      d0, d1, #0x0, gt }) {
                                            *(int8_t *)r14 = 0x0;
                                    }
                                    r0 = var_E8;
                                    if (r0 != 0x0) {
                                            operator delete(r0);
                                    }
                                    r0 = var_D0;
                                    if (r0 != 0x0) {
                                            operator delete(r0);
                                    }
                                    r0 = var_B8;
                                    if (r0 != 0x0) {
                                            operator delete(r0);
                                    }
                                    r0 = var_A0;
                                    if (r0 != 0x0) {
                                            operator delete(r0);
                                    }
                                    r0 = var_88;
                                    if (r0 != 0x0) {
                                            operator delete(r0);
                                    }
                                    r0 = operator delete(var_F0);
                            }
                    }
            }
    }
    return r0;
