    r4 = arg4;
    r0 = arg0;
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
    r31 = r31 + 0xffffffffffffff90 - 0x2e0;
    r21 = arg5;
    r20 = arg3;
    r22 = arg2;
    r25 = r8;
    r24 = &var_A0;
    var_78 = **___stack_chk_guard;
    if (arg6 != 0x0) {
            r23 = r4;
            juce::String::String();
            if (r22 != 0x0) {
                    if (r21 != 0x0) {
                            q0 = *(int128_t *)("Window9showAsyncERKN4juce6StringEE3$_0" + 0xff0);
                            if (r20 != 0x0) {
                                    r8 = r20;
                            }
                            else {
                                    r8 = r22;
                            }
                            var_2E8 = r8;
                            *(int128_t *)(r24 + 0x4) = q0;
                            var_88 = 0x0;
                            var_80 = 0x0;
                            r0 = juce::File::File(&decomp_var_1c8);
                            if ((juce::File::exists() & 0x1) != 0x0) {
                                    var_178 = 0x0;
                                    var_170 = 0x0;
                                    var_168 = 0x0;
                                    var_190 = 0x0;
                                    var_188 = 0x0;
                                    var_2B0 = operator new(0x10);
                                    juce::String::toStdString();
                                    r0 = std::__1::thread::hardware_concurrency();
                                    r0 = TFWrapper::Model::Model(var_2B0, &var_160, 0x0, r0);
                                    if ((sign_extend_64(var_149) & 0xffffffff80000000) != 0x0) {
                                            operator delete(var_160);
                                    }
                                    std::__1::chrono::system_clock::now();
                                    var_1B0 = *(int128_t *)"serving_default_fltp:0";
                                    r8 = r23 * 0x3c;
                                    r9 = r21 / r8;
                                    if (r9 > 0x0) {
                                            var_2C0 = r9 - 0x1;
                                            r14 = (r9 - 0x1) * r8;
                                            r10 = r9 * r8;
                                            r11 = r21 - r10;
                                            r13 = r21 - r14;
                                            asm { cinc       w13, w13, lt };
                                            r13 = SAR(r13, 0x1);
                                            var_320 = r14;
                                            r14 = r13 + r14;
                                            r15 = r21 - r14;
                                            asm { ccmp       w11, w12, #0x0, ge };
                                            bool_271 = asm { ccmp       w11, w12, #0x0, ge };
                                            bool_270 = asm { ccmp       w11, w12, #0x0, ge };
                                            if (!asm { ccmp       w11, w12, #0x0, ge }) {
                                                    r26 = r15;
                                            }
                                            else {
                                                    r26 = r11;
                                            }
                                            if (!bool_270) {
                                                    r10 = r14;
                                            }
                                            var_328 = r10;
                                            if (!bool_271) {
                                                    r21 = r13;
                                            }
                                            else {
                                                    r21 = r8;
                                            }
                                            if (r9 >= 0x2) {
                                                    var_340 = r21;
                                                    var_334 = r26;
                                                    var_330 = r25;
                                                    r19 = 0x0;
                                                    asm { sxtw       x9, w8 };
                                                    r10 = &var_160;
                                                    r24 = r10 + 0x18;
                                                    var_2CC = r23;
                                                    s0 = r23;
                                                    s1 = 0x3ab2544a;
                                                    s8 = s0 * 0x3ab2544a;
                                                    var_2F0 = r10 + 0x28;
                                                    var_308 = &var_238 + 0x18;
                                                    var_300 = &var_238 | 0x4;
                                                    if (r9 <= 0x1) {
                                                            r11 = 0x1;
                                                    }
                                                    else {
                                                            r11 = r9;
                                                    }
                                                    var_2F8 = r10 + 0x2c;
                                                    var_2C8 = r9;
                                                    r20 = r9 << 0x2;
                                                    var_2B8 = r11;
                                                    var_310 = r11 & 0x7ffffffffffffff0;
                                                    r21 = r22 + 0x20;
                                                    r23 = var_2E8;
                                                    r25 = r23 + 0x20;
                                                    s9 = 0x3fe0000000000000;
                                                    var_2E0 = 1.23516e-322;
                                                    var_318 = r22;
                                                    do {
                                                            r0 = tensorflow::TensorShapeBase<tensorflow::TensorShape>::TensorShapeBase(&var_160);
                                                            r0 = tensorflow::Tensor::Tensor(&var_C0, 0x1);
                                                            if (var_151 == 0x2) {
                                                                    tensorflow::TensorShapeRep::DestructorOutOfLine();
                                                            }
                                                            r0 = tensorflow::Tensor::data();
                                                            if (var_2CC >= 0x1) {
                                                                    if (var_2B8 < 0x10) {
                                                                            r8 = var_2B8 - 0x0;
                                                                            r9 = r23 + (0x0 << 0x2);
                                                                            r10 = r22 + (0x0 << 0x2);
                                                                            do {
                                                                                    s0 = *(int32_t *)r10;
                                                                                    r10 = r10 + 0x4;
                                                                                    s1 = *(int32_t *)r9;
                                                                                    r9 = r9 + 0x4;
                                                                                    s0 = (s1 + s0) * s9;
                                                                                    *(int32_t *)r0 = s0;
                                                                                    r0 = r0 + 0x4;
                                                                                    r8 = r8 - 0x1;
                                                                            } while (r8 != 0x0);
                                                                    }
                                                                    else {
                                                                            r8 = r20 * r19;
                                                                            if (r0 - r8 + var_2E8 >= 0x40) {
                                                                                    if (r0 - r8 + var_318 >= 0x40) {
                                                                                            r8 = r0 + 0x20;
                                                                                            r9 = r25;
                                                                                            r10 = r21;
                                                                                            r11 = var_310;
                                                                                            r0 = r0 + var_310 * 0x4;
                                                                                            v16 = 0x3f000000;
                                                                                            do {
                                                                                                    q0 = r10[0xfffffffffffffffc];
                                                                                                    q1 = r10[0xfffffffffffffffe];
                                                                                                    q2 = *r10;
                                                                                                    q3 = r10[0x2];
                                                                                                    r10 = r10 + 0x40;
                                                                                                    r9 = r9 + 0x40;
                                                                                                    v0 = (v4 + v0) * v16;
                                                                                                    v1 = (v5 + v1) * v16;
                                                                                                    v2 = (v6 + v2) * v16;
                                                                                                    v3 = (v7 + v3) * v16;
                                                                                                    r8[0xfffffffffffffffc] = q0;
                                                                                                    r8[0xfffffffffffffffe] = q1;
                                                                                                    *r8 = q2;
                                                                                                    r8[0x2] = q3;
                                                                                                    r8 = r8 + 0x40;
                                                                                                    r11 = r11 - 0x10;
                                                                                            } while (r11 != 0x0);
                                                                                            r9 = var_310;
                                                                                            if (var_2B8 != var_310) {
                                                                                                    r8 = var_2B8 - r9;
                                                                                                    r10 = r9 << 0x2;
                                                                                                    r9 = r23 + r10;
                                                                                                    r10 = r22 + r10;
                                                                                                    do {
                                                                                                            s0 = *(int32_t *)r10;
                                                                                                            r10 = r10 + 0x4;
                                                                                                            s1 = *(int32_t *)r9;
                                                                                                            r9 = r9 + 0x4;
                                                                                                            s0 = (s1 + s0) * s9;
                                                                                                            *(int32_t *)r0 = s0;
                                                                                                            r0 = r0 + 0x4;
                                                                                                            r8 = r8 - 0x1;
                                                                                                    } while (r8 != 0x0);
                                                                                            }
                                                                                    }
                                                                                    else {
                                                                                            r8 = var_2B8 - 0x0;
                                                                                            r9 = r23 + (0x0 << 0x2);
                                                                                            r10 = r22 + (0x0 << 0x2);
                                                                                            do {
                                                                                                    s0 = *(int32_t *)r10;
                                                                                                    r10 = r10 + 0x4;
                                                                                                    s1 = *(int32_t *)r9;
                                                                                                    r9 = r9 + 0x4;
                                                                                                    s0 = (s1 + s0) * s9;
                                                                                                    *(int32_t *)r0 = s0;
                                                                                                    r0 = r0 + 0x4;
                                                                                                    r8 = r8 - 0x1;
                                                                                            } while (r8 != 0x0);
                                                                                    }
                                                                            }
                                                                            else {
                                                                                    r8 = var_2B8 - 0x0;
                                                                                    r9 = r23 + (0x0 << 0x2);
                                                                                    r10 = r22 + (0x0 << 0x2);
                                                                                    do {
                                                                                            s0 = *(int32_t *)r10;
                                                                                            r10 = r10 + 0x4;
                                                                                            s1 = *(int32_t *)r9;
                                                                                            r9 = r9 + 0x4;
                                                                                            s0 = (s1 + s0) * s9;
                                                                                            *(int32_t *)r0 = s0;
                                                                                            r0 = r0 + 0x4;
                                                                                            r8 = r8 - 0x1;
                                                                                    } while (r8 != 0x0);
                                                                            }
                                                                    }
                                                            }
                                                            r26 = var_178;
                                                            r27 = var_170;
                                                            if (r27 != r26) {
                                                                    r28 = r27 - 0x38;
                                                                    tensorflow::Tensor::~Tensor();
                                                                    if ((sign_extend_64(*(int32_t *)(r27 + 0xffffffffffffffdf)) & 0xffffffff80000000) != 0x0) {
                                                                            operator delete(r27[0xfffffffffffffff9]);
                                                                    }
                                                                    r27 = r28;
                                                                    if (r28 != r26) {
                                                                            continue;
                                                                    }
                                                                    break;
                                                            }
                                                            var_170 = r26;
                                                            r0 = std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >::basic_string(&var_160);
                                                            var_138 = var_B0;
                                                            if (var_B1 == 0x2) {
                                                                    tensorflow::TensorShapeRep::SlowCopyFrom(r24);
                                                                    r8 = var_A8;
                                                                    var_130 = r8;
                                                                    if (r8 != 0x0) {
                                                                            asm { ldadd      w9, w8, [x8] };
                                                                    }
                                                            }
                                                            else {
                                                                    *(int128_t *)r24 = var_C0;
                                                                    r8 = var_A8;
                                                                    var_130 = r8;
                                                                    if (r8 != 0x0) {
                                                                            asm { ldadd      w9, w8, [x8] };
                                                                    }
                                                            }
                                                            r8 = var_170;
                                                            if (r8 < var_168) {
                                                                    r8[0x2] = var_150;
                                                                    *(int128_t *)r8 = var_160;
                                                                    var_150 = 0x0;
                                                                    var_160 = 0x0;
                                                                    r8[0x5] = var_138;
                                                                    *(int128_t *)(r8 + 0x18) = *(int128_t *)r24;
                                                                    r8[0x6] = var_130;
                                                                    var_170 = r8 + 0x38;
                                                            }
                                                            else {
                                                                    r0 = void std::__1::vector<std::__1::pair<std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, tensorflow::Tensor>, std::__1::allocator<std::__1::pair<std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, tensorflow::Tensor> > >::__push_back_slow_path<std::__1::pair<std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, tensorflow::Tensor> >(&var_178);
                                                            }
                                                            tensorflow::Tensor::~Tensor();
                                                            if ((sign_extend_64(var_149) & 0xffffffff80000000) != 0x0) {
                                                                    operator delete(var_160);
                                                            }
                                                            r0 = operator new(0x20);
                                                            var_E8 = r0;
                                                            *(int128_t *)r0 = *(int128_t *)"StatefulPartitionedCall:1";
                                                            *(int128_t *)(r0 + 0x9) = *(int128_t *)"artitionedCall:1";
                                                            r0[0x19] = 0x0;
                                                            r0 = operator new(0x18);
                                                            r26 = r0;
                                                            var_238 = r0;
                                                            std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >::basic_string(r0);
                                                            if ((sign_extend_64(var_D1) & 0xffffffff80000000) != 0x0) {
                                                                    operator delete(var_E8);
                                                            }
                                                            r0 = operator new(0x18);
                                                            var_1F8 = r0;
                                                            r28 = r0 + 0x18;
                                                            var_E8 = r0;
                                                            var_110 = r0;
                                                            std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >::basic_string(r0);
                                                            var_1F0 = r28;
                                                            r0 = TFWrapper::Model::run(var_2B0, &var_178, &var_1F8);
                                                            r27 = var_1F8;
                                                            if (r27 != 0x0) {
                                                                    r8 = var_1F0;
                                                                    if (r8 == r27) {
                                                                            r0 = r27;
                                                                    }
                                                                    else {
                                                                            do {
                                                                                    r28 = r8 - 0x18;
                                                                                    if ((sign_extend_64(*(int32_t *)(r8 + 0xffffffffffffffff)) & 0xffffffff80000000) != 0x0) {
                                                                                            operator delete(r8[0xfffffffffffffffd]);
                                                                                    }
                                                                                    r8 = r28;
                                                                            } while (r28 != r27);
                                                                            r0 = var_1F8;
                                                                    }
                                                                    operator delete(r0);
                                                            }
                                                            r0 = var_190;
                                                            if (var_188 != r0) {
                                                                    tensorflow::TensorShapeBase<tensorflow::TensorShape>::dim_size(r0);
                                                                    tensorflow::TensorShapeBase<tensorflow::TensorShape>::dim_size(var_190);
                                                                    var_D0 = tensorflow::Tensor::data();
                                                                    var_C8 = 0x0;
                                                                    r0 = operator new(0x4);
                                                                    r27 = r0;
                                                                    *(int32_t *)r0 = 0x4;
                                                                    var_210 = r0;
                                                                    madmom::downbeat_tracking(&var_E8, &var_210, s0, s1, 0x3c, 0x64, 0x10, 0x3d4ccccd, 0x1, s3);
                                                                    r8 = var_110;
                                                                    if (r8 >= 0x1) {
                                                                            r8 = r8 & 0xffffffff;
                                                                            s0 = s8 * r19;
                                                                            r9 = var_F8;
                                                                            if (r8 < 0x4) {
                                                                                    r8 = r8 - 0x0;
                                                                                    r9 = r9 + 0x0;
                                                                                    do {
                                                                                            s1 = *(int32_t *)r9;
                                                                                            s1 = s1 + s0;
                                                                                            *(int32_t *)r9 = s1;
                                                                                            r9 = r9 + 0x8;
                                                                                            r8 = r8 - 0x1;
                                                                                    } while (r8 != 0x0);
                                                                            }
                                                                            else {
                                                                                    r11 = r8 & 0x3;
                                                                                    r10 = r8 & 0xfffffffc;
                                                                                    r12 = r9 + 0x10;
                                                                                    r13 = r10;
                                                                                    do {
                                                                                            s1 = r12[0xfffffffffffffffc];
                                                                                            s2 = r12[0xfffffffffffffffe];
                                                                                            s3 = *(int32_t *)r12;
                                                                                            s4 = r12[0x2];
                                                                                            s1 = s1 + s0;
                                                                                            s3 = s3 + s0;
                                                                                            r12[0xfffffffffffffffc] = s1;
                                                                                            r12[0xfffffffffffffffe] = s2 + s0;
                                                                                            *(int32_t *)r12 = s3;
                                                                                            r12[0x2] = s4 + s0;
                                                                                            r12 = r12 + 0x20;
                                                                                            r13 = r13 - 0x4;
                                                                                    } while (r13 != 0x0);
                                                                                    if (r11 != 0x0) {
                                                                                            r8 = r8 - r10;
                                                                                            r9 = r9 + r10 * 0x8;
                                                                                            do {
                                                                                                    s1 = *(int32_t *)r9;
                                                                                                    s1 = s1 + s0;
                                                                                                    *(int32_t *)r9 = s1;
                                                                                                    r9 = r9 + 0x8;
                                                                                                    r8 = r8 - 0x1;
                                                                                            } while (r8 != 0x0);
                                                                                    }
                                                                            }
                                                                    }
                                                                    r0 = nc::NdArray<float, std::__1::allocator<float> >::NdArray(&var_160);
                                                                    nc::NdArray<float, std::__1::allocator<float> >::NdArray(var_2F0);
                                                                    var_250 = &var_160;
                                                                    nc::NdArray<float, std::__1::allocator<float> > nc::row_stack<float>(&var_250);
                                                                    if (var_80 != 0x0) {
                                                                            r0 = var_88;
                                                                            if (r0 != 0x0) {
                                                                                    operator delete(r0);
                                                                            }
                                                                    }
                                                                    var_94 = var_230;
                                                                    var_88 = var_220;
                                                                    var_80 = var_218;
                                                                    *var_300 = 0x0;
                                                                    var_300[0x1] = 0x0;
                                                                    var_308[0x8] = 0x0;
                                                                    *var_308 = 0x0;
                                                                    if (var_118 != 0x0) {
                                                                            r0 = var_120;
                                                                            if (r0 != 0x0) {
                                                                                    operator delete(r0);
                                                                            }
                                                                    }
                                                                    var_120 = 0x0;
                                                                    var_118 = 0x0;
                                                                    *var_2F8 = 0x0;
                                                                    var_2F8[0x1] = 0x0;
                                                                    if (var_140 != 0x0) {
                                                                            r0 = var_148;
                                                                            if (r0 != 0x0) {
                                                                                    operator delete(r0);
                                                                            }
                                                                    }
                                                                    if (var_F0 != 0x0) {
                                                                            r0 = var_F8;
                                                                            if (r0 != 0x0) {
                                                                                    operator delete(r0);
                                                                            }
                                                                    }
                                                                    operator delete(r27);
                                                                    if (var_C8 != 0x0) {
                                                                            r0 = var_D0;
                                                                            if (r0 != 0x0) {
                                                                                    operator delete(r0);
                                                                            }
                                                                    }
                                                            }
                                                            if ((sign_extend_64(r26[0x17]) & 0xffffffff80000000) != 0x0) {
                                                                    operator delete(*r26);
                                                            }
                                                            operator delete(r26);
                                                            tensorflow::Tensor::~Tensor();
                                                            r19 = r19 + 0x1;
                                                            r21 = r21 + r20;
                                                            r25 = r25 + r20;
                                                            r23 = r23 + r20;
                                                            r22 = r22 + r20;
                                                    } while (r19 != var_2C0);
                                                    r25 = var_330;
                                                    r24 = &var_A0;
                                                    r22 = var_318;
                                                    r26 = var_334;
                                                    r21 = var_340;
                                                    if (r21 < 0x1) {
                                                            if (r26 < 0x1) {
                                                                    r21 = var_88;
                                                                    r19 = var_80;
                                                                    var_80 = 0x0;
                                                                    var_88 = 0x0;
                                                                    if ((sign_extend_64(var_199) & 0xffffffff80000000) != 0x0) {
                                                                            operator delete(var_1B0);
                                                                    }
                                                                    (*(*var_2B0 + 0x8))(var_2B0);
                                                                    r20 = var_190;
                                                                    if (r20 != 0x0) {
                                                                            r0 = var_188;
                                                                            if (r0 != r20) {
                                                                                    do {
                                                                                            r0 = tensorflow::Tensor::~Tensor();
                                                                                    } while (r0 != r20);
                                                                                    r0 = var_190;
                                                                            }
                                                                            else {
                                                                                    r0 = r20;
                                                                            }
                                                                            operator delete(r0);
                                                                    }
                                                                    r20 = var_178;
                                                                    if (r20 != 0x0) {
                                                                            r22 = var_170;
                                                                            if (r22 == r20) {
                                                                                    r0 = r20;
                                                                            }
                                                                            else {
                                                                                    do {
                                                                                            r23 = r22 - 0x38;
                                                                                            tensorflow::Tensor::~Tensor();
                                                                                            if ((sign_extend_64(*(int32_t *)(r22 + 0xffffffffffffffdf)) & 0xffffffff80000000) != 0x0) {
                                                                                                    operator delete(r22[0xfffffffffffffff9]);
                                                                                            }
                                                                                            r22 = r23;
                                                                                    } while (r23 != r20);
                                                                                    r0 = var_178;
                                                                            }
                                                                            operator delete(r0);
                                                                    }
                                                                    juce::String::~String();
                                                                    if (var_80 != 0x0) {
                                                                            r0 = var_88;
                                                                            if (r0 != 0x0) {
                                                                                    operator delete(r0);
                                                                            }
                                                                    }
                                                                    madmom::to_vector(r25);
                                                                    if (r19 != 0x0 && r21 != 0x0) {
                                                                            operator delete(r21);
                                                                    }
                                                                    r0 = juce::String::~String();
                                                                    if (**___stack_chk_guard != var_78) {
                                                                            __stack_chk_fail();
                                                                    }
                                                            }
                                                            else {
                                                                    r19 = r26;
                                                                    r0 = tensorflow::TensorShapeBase<tensorflow::TensorShape>::TensorShapeBase(&var_160);
                                                                    r0 = tensorflow::Tensor::Tensor(&var_C0, 0x1);
                                                                    if (var_151 == 0x2) {
                                                                            tensorflow::TensorShapeRep::DestructorOutOfLine();
                                                                    }
                                                                    r0 = tensorflow::Tensor::data();
                                                                    r8 = var_328;
                                                                    asm { sxtw       x8, w8 };
                                                                    if (r26 < 0x10) {
                                                                            r10 = r19 - 0x0;
                                                                            r9 = 0x0 + r8 << 0x2;
                                                                            r8 = var_2E8 + r9;
                                                                            r9 = r22 + r9;
                                                                            s0 = 0x3fe0000000000000;
                                                                            do {
                                                                                    s1 = *(int32_t *)r9;
                                                                                    r9 = r9 + 0x4;
                                                                                    s2 = *(int32_t *)r8;
                                                                                    r8 = r8 + 0x4;
                                                                                    s1 = (s2 + s1) * s0;
                                                                                    *(int32_t *)r0 = s1;
                                                                                    r0 = r0 + 0x4;
                                                                                    r10 = r10 - 0x1;
                                                                            } while (r10 != 0x0);
                                                                    }
                                                                    else {
                                                                            r12 = r8 << 0x2;
                                                                            if (r0 - r12 + var_2E8 >= 0x40) {
                                                                                    if (r0 - r12 + r22 >= 0x40) {
                                                                                            r9 = r19 & 0xfffffff0;
                                                                                            r10 = r0 + r9 * 0x4;
                                                                                            r11 = r0 + 0x20;
                                                                                            r13 = r12 + 0x20;
                                                                                            r12 = r22 + r13;
                                                                                            r13 = var_2E8 + r13;
                                                                                            v0 = 0x3f000000;
                                                                                            r14 = r9;
                                                                                            do {
                                                                                                    q1 = r12[0xfffffffffffffffc];
                                                                                                    q2 = r12[0xfffffffffffffffe];
                                                                                                    q3 = *r12;
                                                                                                    q4 = r12[0x2];
                                                                                                    r12 = r12 + 0x40;
                                                                                                    r13 = r13 + 0x40;
                                                                                                    v1 = (v5 + v1) * v0;
                                                                                                    v2 = (v6 + v2) * v0;
                                                                                                    v3 = (v7 + v3) * v0;
                                                                                                    v4 = (v16 + v4) * v0;
                                                                                                    r11[0xfffffffffffffffc] = q1;
                                                                                                    r11[0xfffffffffffffffe] = q2;
                                                                                                    *r11 = q3;
                                                                                                    r11[0x2] = q4;
                                                                                                    r11 = r11 + 0x40;
                                                                                                    r14 = r14 - 0x10;
                                                                                            } while (r14 != 0x0);
                                                                                            r0 = r10;
                                                                                            if (r9 != r19) {
                                                                                                    r10 = r19 - r9;
                                                                                                    r9 = r9 + r8 << 0x2;
                                                                                                    r8 = var_2E8 + r9;
                                                                                                    r9 = r22 + r9;
                                                                                                    s0 = 0x3fe0000000000000;
                                                                                                    do {
                                                                                                            s1 = *(int32_t *)r9;
                                                                                                            r9 = r9 + 0x4;
                                                                                                            s2 = *(int32_t *)r8;
                                                                                                            r8 = r8 + 0x4;
                                                                                                            s1 = (s2 + s1) * s0;
                                                                                                            *(int32_t *)r0 = s1;
                                                                                                            r0 = r0 + 0x4;
                                                                                                            r10 = r10 - 0x1;
                                                                                                    } while (r10 != 0x0);
                                                                                            }
                                                                                    }
                                                                                    else {
                                                                                            r10 = r19 - 0x0;
                                                                                            r9 = 0x0 + r8 << 0x2;
                                                                                            r8 = var_2E8 + r9;
                                                                                            r9 = r22 + r9;
                                                                                            s0 = 0x3fe0000000000000;
                                                                                            do {
                                                                                                    s1 = *(int32_t *)r9;
                                                                                                    r9 = r9 + 0x4;
                                                                                                    s2 = *(int32_t *)r8;
                                                                                                    r8 = r8 + 0x4;
                                                                                                    s1 = (s2 + s1) * s0;
                                                                                                    *(int32_t *)r0 = s1;
                                                                                                    r0 = r0 + 0x4;
                                                                                                    r10 = r10 - 0x1;
                                                                                            } while (r10 != 0x0);
                                                                                    }
                                                                            }
                                                                            else {
                                                                                    r10 = r19 - 0x0;
                                                                                    r9 = 0x0 + r8 << 0x2;
                                                                                    r8 = var_2E8 + r9;
                                                                                    r9 = r22 + r9;
                                                                                    s0 = 0x3fe0000000000000;
                                                                                    do {
                                                                                            s1 = *(int32_t *)r9;
                                                                                            r9 = r9 + 0x4;
                                                                                            s2 = *(int32_t *)r8;
                                                                                            r8 = r8 + 0x4;
                                                                                            s1 = (s2 + s1) * s0;
                                                                                            *(int32_t *)r0 = s1;
                                                                                            r0 = r0 + 0x4;
                                                                                            r10 = r10 - 0x1;
                                                                                    } while (r10 != 0x0);
                                                                            }
                                                                    }
                                                                    r19 = var_178;
                                                                    r20 = var_170;
                                                                    if (r20 != r19) {
                                                                            r21 = r20 - 0x38;
                                                                            tensorflow::Tensor::~Tensor();
                                                                            if ((sign_extend_64(*(int32_t *)(r20 + 0xffffffffffffffdf)) & 0xffffffff80000000) != 0x0) {
                                                                                    operator delete(r20[0xfffffffffffffff9]);
                                                                            }
                                                                            r20 = r21;
                                                                            if (r21 != r19) {
                                                                                    continue;
                                                                            }
                                                                            break;
                                                                    }
                                                                    var_170 = r19;
                                                                    r0 = std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >::basic_string(&var_160);
                                                                    r21 = &var_160 + 0x18;
                                                                    var_138 = var_B0;
                                                                    if (var_B1 == 0x2) {
                                                                            tensorflow::TensorShapeRep::SlowCopyFrom(r21);
                                                                    }
                                                                    else {
                                                                            *(int128_t *)r21 = var_C0;
                                                                    }
                                                                    r8 = var_A8;
                                                                    var_130 = r8;
                                                                    if (r8 != 0x0) {
                                                                            asm { ldadd      w9, w8, [x8] };
                                                                    }
                                                                    r8 = var_170;
                                                                    if (r8 < var_168) {
                                                                            r8[0x2] = var_150;
                                                                            *(int128_t *)r8 = var_160;
                                                                            var_160 = 0x0;
                                                                            r8[0x5] = var_138;
                                                                            *(int128_t *)(r8 + 0x18) = *(int128_t *)r21;
                                                                            r8[0x6] = var_130;
                                                                            var_170 = r8 + 0x38;
                                                                    }
                                                                    else {
                                                                            r0 = void std::__1::vector<std::__1::pair<std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, tensorflow::Tensor>, std::__1::allocator<std::__1::pair<std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, tensorflow::Tensor> > >::__push_back_slow_path<std::__1::pair<std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, tensorflow::Tensor> >(&var_178);
                                                                    }
                                                                    tensorflow::Tensor::~Tensor();
                                                                    if ((sign_extend_64(var_149) & 0xffffffff80000000) != 0x0) {
                                                                            operator delete(var_160);
                                                                    }
                                                                    r0 = operator new(0x20);
                                                                    var_E8 = r0;
                                                                    *(int128_t *)r0 = *(int128_t *)"StatefulPartitionedCall:1";
                                                                    *(int128_t *)(r0 + 0x9) = *(int128_t *)"artitionedCall:1";
                                                                    r0[0x19] = 0x0;
                                                                    r0 = operator new(0x18);
                                                                    r21 = r0;
                                                                    var_238 = r0;
                                                                    std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >::basic_string(r0);
                                                                    if ((sign_extend_64(var_D1) & 0xffffffff80000000) != 0x0) {
                                                                            operator delete(var_E8);
                                                                    }
                                                                    r0 = operator new(0x18);
                                                                    var_250 = r0;
                                                                    r19 = r0 + 0x18;
                                                                    var_E8 = r0;
                                                                    var_110 = r0;
                                                                    std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >::basic_string(r0);
                                                                    var_248 = r19;
                                                                    r0 = TFWrapper::Model::run(var_2B0, &var_178, &var_250);
                                                                    r19 = var_250;
                                                                    if (r19 != 0x0) {
                                                                            r8 = var_248;
                                                                            if (r8 == r19) {
                                                                                    r0 = r19;
                                                                            }
                                                                            else {
                                                                                    do {
                                                                                            r20 = r8 - 0x18;
                                                                                            if ((sign_extend_64(*(int32_t *)(r8 + 0xffffffffffffffff)) & 0xffffffff80000000) != 0x0) {
                                                                                                    operator delete(r8[0xfffffffffffffffd]);
                                                                                            }
                                                                                            r8 = r20;
                                                                                    } while (r20 != r19);
                                                                                    r0 = var_250;
                                                                            }
                                                                            operator delete(r0);
                                                                    }
                                                                    r0 = var_190;
                                                                    if (var_188 != r0) {
                                                                            tensorflow::TensorShapeBase<tensorflow::TensorShape>::dim_size(r0);
                                                                            tensorflow::TensorShapeBase<tensorflow::TensorShape>::dim_size(var_190);
                                                                            var_D0 = tensorflow::Tensor::data();
                                                                            var_C8 = 0x0;
                                                                            r0 = operator new(0x4);
                                                                            r22 = r0;
                                                                            *(int32_t *)r0 = 0x4;
                                                                            var_268 = r0;
                                                                            s2 = 0x3d4ccccd;
                                                                            madmom::downbeat_tracking(&var_E8, &var_268, s0, s1, 0x3c, 0x64, 0x10, 0x3d4ccccd, 0x1, s3);
                                                                            if (var_328 >= 0x1) {
                                                                                    r8 = var_110;
                                                                                    r10 = r8 - 0x1;
                                                                                    if (r10 >= 0x0) {
                                                                                            r9 = r8 & 0xffffffff;
                                                                                            s0 = var_328 * 0x37be37c6;
                                                                                            r11 = var_F8;
                                                                                            if (r9 < 0x4) {
                                                                                                    r13 = r9 - 0x0;
                                                                                                    r12 = r11 + 0x0;
                                                                                                    do {
                                                                                                            *(int32_t *)r12 = *(int32_t *)r12 + s0;
                                                                                                            r12 = r12 + 0x8;
                                                                                                            r13 = r13 - 0x1;
                                                                                                    } while (r13 != 0x0);
                                                                                            }
                                                                                            else {
                                                                                                    r13 = r9 & 0x3;
                                                                                                    r12 = r9 & 0xfffffffc;
                                                                                                    r14 = r11 + 0x10;
                                                                                                    r15 = r12;
                                                                                                    do {
                                                                                                            s1 = r14[0xfffffffffffffffc];
                                                                                                            s2 = r14[0xfffffffffffffffe];
                                                                                                            s3 = *(int32_t *)r14;
                                                                                                            s4 = r14[0x2];
                                                                                                            s2 = s2 + s0;
                                                                                                            r14[0xfffffffffffffffc] = s1 + s0;
                                                                                                            r14[0xfffffffffffffffe] = s2;
                                                                                                            *(int32_t *)r14 = s3 + s0;
                                                                                                            r14[0x2] = s4 + s0;
                                                                                                            r14 = r14 + 0x20;
                                                                                                            r15 = r15 - 0x4;
                                                                                                    } while (r15 != 0x0);
                                                                                                    if (r13 != 0x0) {
                                                                                                            r13 = r9 - r12;
                                                                                                            r12 = r11 + r12 * 0x8;
                                                                                                            do {
                                                                                                                    *(int32_t *)r12 = *(int32_t *)r12 + s0;
                                                                                                                    r12 = r12 + 0x8;
                                                                                                                    r13 = r13 - 0x1;
                                                                                                            } while (r13 != 0x0);
                                                                                                    }
                                                                                            }
                                                                                            r12 = var_94;
                                                                                            if (r12 >= 0x1) {
                                                                                                    if (r8 >= 0x2) {
                                                                                                            asm { fabd       s2, s0, s1 };
                                                                                                            s1 = r11[0x2];
                                                                                                            asm { fabd       s1, s0, s1 };
                                                                                                            if (s2 > s1) {
                                                                                                                    r12 = 0x0;
                                                                                                                    r11 = r11 + 0x10;
                                                                                                                    r13 = r9 - 0x2;
                                                                                                                    while (r13 != r12) {
                                                                                                                            s2 = *(int32_t *)r11;
                                                                                                                            r11 = r11 + 0x8;
                                                                                                                            asm { fabd       s2, s0, s2 };
                                                                                                                            r12 = r12 + 0x1;
                                                                                                                            bool_676 = s1 > s2;
                                                                                                                            s1 = s2;
                                                                                                                            if (bool_676) {
                                                                                                                                    continue;
                                                                                                                            }
                                                                                                                            r10 = r12;
                                                                                                                            break;
                                                                                                                    }
                                                                                                            }
                                                                                                            else {
                                                                                                                    r10 = 0x0;
                                                                                                            }
                                                                                                    }
                                                                                                    else {
                                                                                                            r10 = 0x0;
                                                                                                    }
                                                                                                    r1 = r10 + 0x1;
                                                                                                    if (r1 < r8) {
                                                                                                            asm { bfi        x1, x9, #0x20, #0x20 };
                                                                                                            nc::NdArray<float, std::__1::allocator<float> >::operator(&var_110, r1);
                                                                                                            r0 = nc::NdArray<float, std::__1::allocator<float> >::operator=(&var_110);
                                                                                                            if (var_140 != 0x0) {
                                                                                                                    r0 = var_148;
                                                                                                                    if (r0 != 0x0) {
                                                                                                                            operator delete(r0);
                                                                                                                    }
                                                                                                            }
                                                                                                            nc::NdArray<float, std::__1::allocator<float> >::NdArray(&var_160);
                                                                                                            nc::NdArray<float, std::__1::allocator<float> >::NdArray(&var_160 + 0x28);
                                                                                                            var_1C0 = &var_160;
                                                                                                            nc::NdArray<float, std::__1::allocator<float> > nc::row_stack<float>(&var_1C0);
                                                                                                            nc::NdArray<float, std::__1::allocator<float> >::operator=(&var_A0);
                                                                                                            if (var_218 != 0x0) {
                                                                                                                    r0 = var_220;
                                                                                                                    if (r0 != 0x0) {
                                                                                                                            operator delete(r0);
                                                                                                                    }
                                                                                                            }
                                                                                                            if (var_118 != 0x0) {
                                                                                                                    r0 = var_120;
                                                                                                                    if (r0 != 0x0) {
                                                                                                                            operator delete(r0);
                                                                                                                    }
                                                                                                            }
                                                                                                            if (var_140 != 0x0) {
                                                                                                                    r0 = var_148;
                                                                                                                    if (r0 != 0x0) {
                                                                                                                            operator delete(r0);
                                                                                                                    }
                                                                                                            }
                                                                                                    }
                                                                                            }
                                                                                            else {
                                                                                                    nc::NdArray<float, std::__1::allocator<float> >::NdArray(&var_160);
                                                                                                    nc::NdArray<float, std::__1::allocator<float> >::NdArray(&var_160 + 0x28);
                                                                                                    var_1C0 = &var_160;
                                                                                                    nc::NdArray<float, std::__1::allocator<float> > nc::row_stack<float>(&var_1C0);
                                                                                                    nc::NdArray<float, std::__1::allocator<float> >::operator=(&var_A0);
                                                                                                    if (var_218 != 0x0) {
                                                                                                            r0 = var_220;
                                                                                                            if (r0 != 0x0) {
                                                                                                                    operator delete(r0);
                                                                                                            }
                                                                                                    }
                                                                                                    if (var_118 != 0x0) {
                                                                                                            r0 = var_120;
                                                                                                            if (r0 != 0x0) {
                                                                                                                    operator delete(r0);
                                                                                                            }
                                                                                                    }
                                                                                                    if (var_140 != 0x0) {
                                                                                                            r0 = var_148;
                                                                                                            if (r0 != 0x0) {
                                                                                                                    operator delete(r0);
                                                                                                            }
                                                                                                    }
                                                                                            }
                                                                                    }
                                                                            }
                                                                            else {
                                                                                    nc::NdArray<float, std::__1::allocator<float> >::operator=(&var_A0);
                                                                            }
                                                                            if (var_F0 != 0x0) {
                                                                                    r0 = var_F8;
                                                                                    if (r0 != 0x0) {
                                                                                            operator delete(r0);
                                                                                    }
                                                                            }
                                                                            operator delete(r22);
                                                                            if (var_C8 != 0x0) {
                                                                                    r0 = var_D0;
                                                                                    if (r0 != 0x0) {
                                                                                            operator delete(r0);
                                                                                    }
                                                                            }
                                                                    }
                                                                    if ((sign_extend_64(r21[0x17]) & 0xffffffff80000000) != 0x0) {
                                                                            operator delete(*r21);
                                                                    }
                                                                    operator delete(r21);
                                                                    tensorflow::Tensor::~Tensor();
                                                                    r21 = var_88;
                                                                    r19 = var_80;
                                                                    var_80 = 0x0;
                                                                    var_88 = 0x0;
                                                                    if ((sign_extend_64(var_199) & 0xffffffff80000000) != 0x0) {
                                                                            operator delete(var_1B0);
                                                                    }
                                                                    (*(*var_2B0 + 0x8))(var_2B0);
                                                                    r20 = var_190;
                                                                    if (r20 != 0x0) {
                                                                            r0 = var_188;
                                                                            if (r0 != r20) {
                                                                                    do {
                                                                                            r0 = tensorflow::Tensor::~Tensor();
                                                                                    } while (r0 != r20);
                                                                                    r0 = var_190;
                                                                            }
                                                                            else {
                                                                                    r0 = r20;
                                                                            }
                                                                            operator delete(r0);
                                                                    }
                                                                    r20 = var_178;
                                                                    if (r20 != 0x0) {
                                                                            r22 = var_170;
                                                                            if (r22 == r20) {
                                                                                    r0 = r20;
                                                                            }
                                                                            else {
                                                                                    do {
                                                                                            r23 = r22 - 0x38;
                                                                                            tensorflow::Tensor::~Tensor();
                                                                                            if ((sign_extend_64(*(int32_t *)(r22 + 0xffffffffffffffdf)) & 0xffffffff80000000) != 0x0) {
                                                                                                    operator delete(r22[0xfffffffffffffff9]);
                                                                                            }
                                                                                            r22 = r23;
                                                                                    } while (r23 != r20);
                                                                                    r0 = var_178;
                                                                            }
                                                                            operator delete(r0);
                                                                    }
                                                                    juce::String::~String();
                                                                    if (var_80 != 0x0) {
                                                                            r0 = var_88;
                                                                            if (r0 != 0x0) {
                                                                                    operator delete(r0);
                                                                            }
                                                                    }
                                                                    madmom::to_vector(r25);
                                                                    if (r19 != 0x0 && r21 != 0x0) {
                                                                            operator delete(r21);
                                                                    }
                                                                    r0 = juce::String::~String();
                                                                    if (**___stack_chk_guard != var_78) {
                                                                            __stack_chk_fail();
                                                                    }
                                                            }
                                                    }
                                                    else {
                                                            r19 = r21;
                                                            r0 = tensorflow::TensorShapeBase<tensorflow::TensorShape>::TensorShapeBase(&var_160);
                                                            r0 = tensorflow::Tensor::Tensor(&var_C0, 0x1);
                                                            if (var_151 == 0x2) {
                                                                    tensorflow::TensorShapeRep::DestructorOutOfLine();
                                                            }
                                                            r0 = tensorflow::Tensor::data();
                                                            r8 = var_320;
                                                            asm { sxtw       x8, w8 };
                                                            if (r21 < 0x10) {
                                                                    r10 = r19 - 0x0;
                                                                    r9 = 0x0 + r8 << 0x2;
                                                                    r8 = var_2E8 + r9;
                                                                    r9 = r22 + r9;
                                                                    s0 = 0x3fe0000000000000;
                                                                    do {
                                                                            s1 = *(int32_t *)r9;
                                                                            r9 = r9 + 0x4;
                                                                            s2 = *(int32_t *)r8;
                                                                            r8 = r8 + 0x4;
                                                                            s1 = (s2 + s1) * s0;
                                                                            *(int32_t *)r0 = s1;
                                                                            r0 = r0 + 0x4;
                                                                            r10 = r10 - 0x1;
                                                                    } while (r10 != 0x0);
                                                            }
                                                            else {
                                                                    r12 = r8 << 0x2;
                                                                    if (r0 - r12 + var_2E8 >= 0x40) {
                                                                            if (r0 - r12 + r22 >= 0x40) {
                                                                                    r9 = r19 & 0xfffffff0;
                                                                                    r10 = r0 + r9 * 0x4;
                                                                                    r11 = r0 + 0x20;
                                                                                    r13 = r12 + 0x20;
                                                                                    r12 = r22 + r13;
                                                                                    r13 = var_2E8 + r13;
                                                                                    v0 = 0x3f000000;
                                                                                    r14 = r9;
                                                                                    do {
                                                                                            q1 = r12[0xfffffffffffffffc];
                                                                                            q2 = r12[0xfffffffffffffffe];
                                                                                            q3 = *r12;
                                                                                            q4 = r12[0x2];
                                                                                            r12 = r12 + 0x40;
                                                                                            r13 = r13 + 0x40;
                                                                                            v1 = (v5 + v1) * v0;
                                                                                            v2 = (v6 + v2) * v0;
                                                                                            v3 = (v7 + v3) * v0;
                                                                                            v4 = (v16 + v4) * v0;
                                                                                            r11[0xfffffffffffffffc] = q1;
                                                                                            r11[0xfffffffffffffffe] = q2;
                                                                                            *r11 = q3;
                                                                                            r11[0x2] = q4;
                                                                                            r11 = r11 + 0x40;
                                                                                            r14 = r14 - 0x10;
                                                                                    } while (r14 != 0x0);
                                                                                    r0 = r10;
                                                                                    if (r9 != r19) {
                                                                                            r10 = r19 - r9;
                                                                                            r9 = r9 + r8 << 0x2;
                                                                                            r8 = var_2E8 + r9;
                                                                                            r9 = r22 + r9;
                                                                                            s0 = 0x3fe0000000000000;
                                                                                            do {
                                                                                                    s1 = *(int32_t *)r9;
                                                                                                    r9 = r9 + 0x4;
                                                                                                    s2 = *(int32_t *)r8;
                                                                                                    r8 = r8 + 0x4;
                                                                                                    s1 = (s2 + s1) * s0;
                                                                                                    *(int32_t *)r0 = s1;
                                                                                                    r0 = r0 + 0x4;
                                                                                                    r10 = r10 - 0x1;
                                                                                            } while (r10 != 0x0);
                                                                                    }
                                                                            }
                                                                            else {
                                                                                    r10 = r19 - 0x0;
                                                                                    r9 = 0x0 + r8 << 0x2;
                                                                                    r8 = var_2E8 + r9;
                                                                                    r9 = r22 + r9;
                                                                                    s0 = 0x3fe0000000000000;
                                                                                    do {
                                                                                            s1 = *(int32_t *)r9;
                                                                                            r9 = r9 + 0x4;
                                                                                            s2 = *(int32_t *)r8;
                                                                                            r8 = r8 + 0x4;
                                                                                            s1 = (s2 + s1) * s0;
                                                                                            *(int32_t *)r0 = s1;
                                                                                            r0 = r0 + 0x4;
                                                                                            r10 = r10 - 0x1;
                                                                                    } while (r10 != 0x0);
                                                                            }
                                                                    }
                                                                    else {
                                                                            r10 = r19 - 0x0;
                                                                            r9 = 0x0 + r8 << 0x2;
                                                                            r8 = var_2E8 + r9;
                                                                            r9 = r22 + r9;
                                                                            s0 = 0x3fe0000000000000;
                                                                            do {
                                                                                    s1 = *(int32_t *)r9;
                                                                                    r9 = r9 + 0x4;
                                                                                    s2 = *(int32_t *)r8;
                                                                                    r8 = r8 + 0x4;
                                                                                    s1 = (s2 + s1) * s0;
                                                                                    *(int32_t *)r0 = s1;
                                                                                    r0 = r0 + 0x4;
                                                                                    r10 = r10 - 0x1;
                                                                            } while (r10 != 0x0);
                                                                    }
                                                            }
                                                            r19 = var_178;
                                                            r20 = var_170;
                                                            if (r20 != r19) {
                                                                    r21 = r20 - 0x38;
                                                                    tensorflow::Tensor::~Tensor();
                                                                    if ((sign_extend_64(*(int32_t *)(r20 + 0xffffffffffffffdf)) & 0xffffffff80000000) != 0x0) {
                                                                            operator delete(r20[0xfffffffffffffff9]);
                                                                    }
                                                                    r20 = r21;
                                                                    if (r21 != r19) {
                                                                            continue;
                                                                    }
                                                                    break;
                                                            }
                                                            r21 = r22;
                                                            var_170 = r19;
                                                            r0 = std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >::basic_string(&var_160);
                                                            r22 = &var_160 + 0x18;
                                                            var_138 = var_B0;
                                                            if (var_B1 == 0x2) {
                                                                    tensorflow::TensorShapeRep::SlowCopyFrom(r22);
                                                            }
                                                            else {
                                                                    *(int128_t *)r22 = var_C0;
                                                            }
                                                            r8 = var_A8;
                                                            var_130 = r8;
                                                            if (r8 != 0x0) {
                                                                    asm { ldadd      w9, w8, [x8] };
                                                            }
                                                            r8 = var_170;
                                                            if (r8 < var_168) {
                                                                    r8[0x2] = var_150;
                                                                    *(int128_t *)r8 = var_160;
                                                                    var_150 = 0x0;
                                                                    var_160 = 0x0;
                                                                    r8[0x5] = var_138;
                                                                    *(int128_t *)(r8 + 0x18) = *(int128_t *)r22;
                                                                    r8[0x6] = var_130;
                                                                    var_170 = r8 + 0x38;
                                                            }
                                                            else {
                                                                    r0 = void std::__1::vector<std::__1::pair<std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, tensorflow::Tensor>, std::__1::allocator<std::__1::pair<std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, tensorflow::Tensor> > >::__push_back_slow_path<std::__1::pair<std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, tensorflow::Tensor> >(&var_178);
                                                            }
                                                            tensorflow::Tensor::~Tensor();
                                                            if ((sign_extend_64(var_149) & 0xffffffff80000000) != 0x0) {
                                                                    operator delete(var_160);
                                                            }
                                                            r0 = operator new(0x20);
                                                            var_E8 = r0;
                                                            *(int128_t *)r0 = *(int128_t *)"StatefulPartitionedCall:1";
                                                            *(int128_t *)(r0 + 0x9) = *(int128_t *)"artitionedCall:1";
                                                            r0[0x19] = 0x0;
                                                            r0 = operator new(0x18);
                                                            r22 = r0;
                                                            var_238 = r0;
                                                            std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >::basic_string(r0);
                                                            if ((sign_extend_64(var_D1) & 0xffffffff80000000) != 0x0) {
                                                                    operator delete(var_E8);
                                                            }
                                                            r0 = operator new(0x18);
                                                            var_210 = r0;
                                                            r19 = r0 + 0x18;
                                                            var_E8 = r0;
                                                            var_110 = r0;
                                                            std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >::basic_string(r0);
                                                            var_208 = r19;
                                                            r0 = TFWrapper::Model::run(var_2B0, &var_178, &var_210);
                                                            r19 = var_210;
                                                            if (r19 != 0x0) {
                                                                    r8 = var_208;
                                                                    if (r8 == r19) {
                                                                            r0 = r19;
                                                                    }
                                                                    else {
                                                                            do {
                                                                                    r20 = r8 - 0x18;
                                                                                    if ((sign_extend_64(*(int32_t *)(r8 + 0xffffffffffffffff)) & 0xffffffff80000000) != 0x0) {
                                                                                            operator delete(r8[0xfffffffffffffffd]);
                                                                                    }
                                                                                    r8 = r20;
                                                                            } while (r20 != r19);
                                                                            r0 = var_210;
                                                                    }
                                                                    operator delete(r0);
                                                            }
                                                            r0 = var_190;
                                                            if (var_188 != r0) {
                                                                    tensorflow::TensorShapeBase<tensorflow::TensorShape>::dim_size(r0);
                                                                    tensorflow::TensorShapeBase<tensorflow::TensorShape>::dim_size(var_190);
                                                                    var_D0 = tensorflow::Tensor::data();
                                                                    var_C8 = 0x0;
                                                                    r0 = operator new(0x4);
                                                                    r23 = r0;
                                                                    *(int32_t *)r0 = 0x4;
                                                                    var_250 = r0;
                                                                    s2 = 0x3d4ccccd;
                                                                    madmom::downbeat_tracking(&var_E8, &var_250, s0, s1, 0x3c, 0x64, 0x10, 0x3d4ccccd, 0x1, s3);
                                                                    r24 = &var_A0;
                                                                    if (var_320 >= 0x1) {
                                                                            r8 = var_110;
                                                                            r10 = r8 - 0x1;
                                                                            if (r10 >= 0x0) {
                                                                                    r9 = r8 & 0xffffffff;
                                                                                    s0 = var_320 * 0x37be37c6;
                                                                                    r11 = var_F8;
                                                                                    if (r9 < 0x4) {
                                                                                            r13 = r9 - 0x0;
                                                                                            r12 = r11 + 0x0;
                                                                                            do {
                                                                                                    s1 = *(int32_t *)r12;
                                                                                                    s1 = s1 + s0;
                                                                                                    *(int32_t *)r12 = s1;
                                                                                                    r12 = r12 + 0x8;
                                                                                                    r13 = r13 - 0x1;
                                                                                            } while (r13 != 0x0);
                                                                                    }
                                                                                    else {
                                                                                            r13 = r9 & 0x3;
                                                                                            r12 = r9 & 0xfffffffc;
                                                                                            r14 = r11 + 0x10;
                                                                                            r15 = r12;
                                                                                            do {
                                                                                                    s1 = r14[0xfffffffffffffffc];
                                                                                                    s2 = r14[0xfffffffffffffffe];
                                                                                                    s3 = *(int32_t *)r14;
                                                                                                    s4 = r14[0x2];
                                                                                                    s1 = s1 + s0;
                                                                                                    s2 = s2 + s0;
                                                                                                    s3 = s3 + s0;
                                                                                                    r14[0xfffffffffffffffc] = s1;
                                                                                                    r14[0xfffffffffffffffe] = s2;
                                                                                                    *(int32_t *)r14 = s3;
                                                                                                    r14[0x2] = s4 + s0;
                                                                                                    r14 = r14 + 0x20;
                                                                                                    r15 = r15 - 0x4;
                                                                                            } while (r15 != 0x0);
                                                                                            if (r13 != 0x0) {
                                                                                                    r13 = r9 - r12;
                                                                                                    r12 = r11 + r12 * 0x8;
                                                                                                    do {
                                                                                                            s1 = *(int32_t *)r12;
                                                                                                            s1 = s1 + s0;
                                                                                                            *(int32_t *)r12 = s1;
                                                                                                            r12 = r12 + 0x8;
                                                                                                            r13 = r13 - 0x1;
                                                                                                    } while (r13 != 0x0);
                                                                                            }
                                                                                    }
                                                                                    r12 = var_94;
                                                                                    if (r12 >= 0x1) {
                                                                                            if (r8 >= 0x2) {
                                                                                                    s0 = *(int32_t *)(var_88 + ((r12 & (r12 - 0x2) / 0x80000000) + (r12 - 0x2)) * 0x4);
                                                                                                    asm { fabd       s2, s0, s1 };
                                                                                                    s1 = r11[0x2];
                                                                                                    asm { fabd       s1, s0, s1 };
                                                                                                    if (s2 > s1) {
                                                                                                            r12 = 0x0;
                                                                                                            r11 = r11 + 0x10;
                                                                                                            r13 = r9 - 0x2;
                                                                                                            while (r13 != r12) {
                                                                                                                    s2 = *(int32_t *)r11;
                                                                                                                    r11 = r11 + 0x8;
                                                                                                                    asm { fabd       s2, s0, s2 };
                                                                                                                    r12 = r12 + 0x1;
                                                                                                                    bool_690 = s1 > s2;
                                                                                                                    s1 = s2;
                                                                                                                    if (bool_690) {
                                                                                                                            continue;
                                                                                                                    }
                                                                                                                    r10 = r12;
                                                                                                                    break;
                                                                                                            }
                                                                                                    }
                                                                                                    else {
                                                                                                            r10 = 0x0;
                                                                                                    }
                                                                                            }
                                                                                            else {
                                                                                                    r10 = 0x0;
                                                                                            }
                                                                                            r1 = r10 + 0x1;
                                                                                            if (r1 < r8) {
                                                                                                    asm { bfi        x1, x9, #0x20, #0x20 };
                                                                                                    nc::NdArray<float, std::__1::allocator<float> >::operator(&var_110, r1);
                                                                                                    r0 = nc::NdArray<float, std::__1::allocator<float> >::operator=(&var_110);
                                                                                                    if (var_140 != 0x0) {
                                                                                                            r0 = var_148;
                                                                                                            if (r0 != 0x0) {
                                                                                                                    operator delete(r0);
                                                                                                            }
                                                                                                    }
                                                                                                    r0 = nc::NdArray<float, std::__1::allocator<float> >::NdArray(&var_160);
                                                                                                    nc::NdArray<float, std::__1::allocator<float> >::NdArray(&var_160 + 0x28);
                                                                                                    var_268 = &var_160;
                                                                                                    nc::NdArray<float, std::__1::allocator<float> > nc::row_stack<float>(&var_268);
                                                                                                    r0 = nc::NdArray<float, std::__1::allocator<float> >::operator=(&var_A0);
                                                                                                    if (var_218 != 0x0) {
                                                                                                            r0 = var_220;
                                                                                                            if (r0 != 0x0) {
                                                                                                                    operator delete(r0);
                                                                                                            }
                                                                                                    }
                                                                                                    var_220 = 0x0;
                                                                                                    var_218 = 0x0;
                                                                                                    if (var_118 != 0x0) {
                                                                                                            r0 = var_120;
                                                                                                            if (r0 != 0x0) {
                                                                                                                    operator delete(r0);
                                                                                                            }
                                                                                                    }
                                                                                                    var_120 = 0x0;
                                                                                                    var_118 = 0x0;
                                                                                                    if (var_140 != 0x0) {
                                                                                                            r0 = var_148;
                                                                                                            if (r0 != 0x0) {
                                                                                                                    operator delete(r0);
                                                                                                            }
                                                                                                    }
                                                                                            }
                                                                                    }
                                                                                    else {
                                                                                            r0 = nc::NdArray<float, std::__1::allocator<float> >::NdArray(&var_160);
                                                                                            nc::NdArray<float, std::__1::allocator<float> >::NdArray(&var_160 + 0x28);
                                                                                            var_268 = &var_160;
                                                                                            nc::NdArray<float, std::__1::allocator<float> > nc::row_stack<float>(&var_268);
                                                                                            r0 = nc::NdArray<float, std::__1::allocator<float> >::operator=(&var_A0);
                                                                                            if (var_218 != 0x0) {
                                                                                                    r0 = var_220;
                                                                                                    if (r0 != 0x0) {
                                                                                                            operator delete(r0);
                                                                                                    }
                                                                                            }
                                                                                            var_220 = 0x0;
                                                                                            var_218 = 0x0;
                                                                                            if (var_118 != 0x0) {
                                                                                                    r0 = var_120;
                                                                                                    if (r0 != 0x0) {
                                                                                                            operator delete(r0);
                                                                                                    }
                                                                                            }
                                                                                            var_120 = 0x0;
                                                                                            var_118 = 0x0;
                                                                                            if (var_140 != 0x0) {
                                                                                                    r0 = var_148;
                                                                                                    if (r0 != 0x0) {
                                                                                                            operator delete(r0);
                                                                                                    }
                                                                                            }
                                                                                    }
                                                                            }
                                                                    }
                                                                    else {
                                                                            r0 = nc::NdArray<float, std::__1::allocator<float> >::operator=(&var_A0);
                                                                    }
                                                                    if (var_F0 != 0x0) {
                                                                            r0 = var_F8;
                                                                            if (r0 != 0x0) {
                                                                                    operator delete(r0);
                                                                            }
                                                                    }
                                                                    operator delete(r23);
                                                                    if (var_C8 != 0x0) {
                                                                            r0 = var_D0;
                                                                            if (r0 != 0x0) {
                                                                                    operator delete(r0);
                                                                            }
                                                                    }
                                                            }
                                                            if ((sign_extend_64(r22[0x17]) & 0xffffffff80000000) != 0x0) {
                                                                    operator delete(*r22);
                                                            }
                                                            operator delete(r22);
                                                            tensorflow::Tensor::~Tensor();
                                                            r22 = r21;
                                                            if (r26 >= 0x1) {
                                                                    r19 = r26;
                                                                    r0 = tensorflow::TensorShapeBase<tensorflow::TensorShape>::TensorShapeBase(&var_160);
                                                                    r0 = tensorflow::Tensor::Tensor(&var_C0, 0x1);
                                                                    if (var_151 == 0x2) {
                                                                            tensorflow::TensorShapeRep::DestructorOutOfLine();
                                                                    }
                                                                    r0 = tensorflow::Tensor::data();
                                                                    r8 = var_328;
                                                                    asm { sxtw       x8, w8 };
                                                                    if (r26 < 0x10) {
                                                                            r10 = r19 - 0x0;
                                                                            r9 = 0x0 + r8 << 0x2;
                                                                            r8 = var_2E8 + r9;
                                                                            r9 = r22 + r9;
                                                                            s0 = 0x3fe0000000000000;
                                                                            do {
                                                                                    s1 = *(int32_t *)r9;
                                                                                    r9 = r9 + 0x4;
                                                                                    s2 = *(int32_t *)r8;
                                                                                    r8 = r8 + 0x4;
                                                                                    s1 = (s2 + s1) * s0;
                                                                                    *(int32_t *)r0 = s1;
                                                                                    r0 = r0 + 0x4;
                                                                                    r10 = r10 - 0x1;
                                                                            } while (r10 != 0x0);
                                                                    }
                                                                    else {
                                                                            r12 = r8 << 0x2;
                                                                            if (r0 - r12 + var_2E8 >= 0x40) {
                                                                                    if (r0 - r12 + r22 >= 0x40) {
                                                                                            r9 = r19 & 0xfffffff0;
                                                                                            r10 = r0 + r9 * 0x4;
                                                                                            r11 = r0 + 0x20;
                                                                                            r13 = r12 + 0x20;
                                                                                            r12 = r22 + r13;
                                                                                            r13 = var_2E8 + r13;
                                                                                            v0 = 0x3f000000;
                                                                                            r14 = r9;
                                                                                            do {
                                                                                                    q1 = r12[0xfffffffffffffffc];
                                                                                                    q2 = r12[0xfffffffffffffffe];
                                                                                                    q3 = *r12;
                                                                                                    q4 = r12[0x2];
                                                                                                    r12 = r12 + 0x40;
                                                                                                    r13 = r13 + 0x40;
                                                                                                    v1 = (v5 + v1) * v0;
                                                                                                    v2 = (v6 + v2) * v0;
                                                                                                    v3 = (v7 + v3) * v0;
                                                                                                    v4 = (v16 + v4) * v0;
                                                                                                    r11[0xfffffffffffffffc] = q1;
                                                                                                    r11[0xfffffffffffffffe] = q2;
                                                                                                    *r11 = q3;
                                                                                                    r11[0x2] = q4;
                                                                                                    r11 = r11 + 0x40;
                                                                                                    r14 = r14 - 0x10;
                                                                                            } while (r14 != 0x0);
                                                                                            r0 = r10;
                                                                                            if (r9 != r19) {
                                                                                                    r10 = r19 - r9;
                                                                                                    r9 = r9 + r8 << 0x2;
                                                                                                    r8 = var_2E8 + r9;
                                                                                                    r9 = r22 + r9;
                                                                                                    s0 = 0x3fe0000000000000;
                                                                                                    do {
                                                                                                            s1 = *(int32_t *)r9;
                                                                                                            r9 = r9 + 0x4;
                                                                                                            s2 = *(int32_t *)r8;
                                                                                                            r8 = r8 + 0x4;
                                                                                                            s1 = (s2 + s1) * s0;
                                                                                                            *(int32_t *)r0 = s1;
                                                                                                            r0 = r0 + 0x4;
                                                                                                            r10 = r10 - 0x1;
                                                                                                    } while (r10 != 0x0);
                                                                                            }
                                                                                    }
                                                                                    else {
                                                                                            r10 = r19 - 0x0;
                                                                                            r9 = 0x0 + r8 << 0x2;
                                                                                            r8 = var_2E8 + r9;
                                                                                            r9 = r22 + r9;
                                                                                            s0 = 0x3fe0000000000000;
                                                                                            do {
                                                                                                    s1 = *(int32_t *)r9;
                                                                                                    r9 = r9 + 0x4;
                                                                                                    s2 = *(int32_t *)r8;
                                                                                                    r8 = r8 + 0x4;
                                                                                                    s1 = (s2 + s1) * s0;
                                                                                                    *(int32_t *)r0 = s1;
                                                                                                    r0 = r0 + 0x4;
                                                                                                    r10 = r10 - 0x1;
                                                                                            } while (r10 != 0x0);
                                                                                    }
                                                                            }
                                                                            else {
                                                                                    r10 = r19 - 0x0;
                                                                                    r9 = 0x0 + r8 << 0x2;
                                                                                    r8 = var_2E8 + r9;
                                                                                    r9 = r22 + r9;
                                                                                    s0 = 0x3fe0000000000000;
                                                                                    do {
                                                                                            s1 = *(int32_t *)r9;
                                                                                            r9 = r9 + 0x4;
                                                                                            s2 = *(int32_t *)r8;
                                                                                            r8 = r8 + 0x4;
                                                                                            s1 = (s2 + s1) * s0;
                                                                                            *(int32_t *)r0 = s1;
                                                                                            r0 = r0 + 0x4;
                                                                                            r10 = r10 - 0x1;
                                                                                    } while (r10 != 0x0);
                                                                            }
                                                                    }
                                                                    r19 = var_178;
                                                                    r20 = var_170;
                                                                    if (r20 != r19) {
                                                                            r21 = r20 - 0x38;
                                                                            tensorflow::Tensor::~Tensor();
                                                                            if ((sign_extend_64(*(int32_t *)(r20 + 0xffffffffffffffdf)) & 0xffffffff80000000) != 0x0) {
                                                                                    operator delete(r20[0xfffffffffffffff9]);
                                                                            }
                                                                            r20 = r21;
                                                                            if (r21 != r19) {
                                                                                    continue;
                                                                            }
                                                                            break;
                                                                    }
                                                                    var_170 = r19;
                                                                    r0 = std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >::basic_string(&var_160);
                                                                    r21 = &var_160 + 0x18;
                                                                    var_138 = var_B0;
                                                                    if (var_B1 == 0x2) {
                                                                            tensorflow::TensorShapeRep::SlowCopyFrom(r21);
                                                                    }
                                                                    else {
                                                                            *(int128_t *)r21 = var_C0;
                                                                    }
                                                                    r8 = var_A8;
                                                                    var_130 = r8;
                                                                    if (r8 != 0x0) {
                                                                            asm { ldadd      w9, w8, [x8] };
                                                                    }
                                                                    r8 = var_170;
                                                                    if (r8 < var_168) {
                                                                            r8[0x2] = var_150;
                                                                            *(int128_t *)r8 = var_160;
                                                                            var_160 = 0x0;
                                                                            r8[0x5] = var_138;
                                                                            *(int128_t *)(r8 + 0x18) = *(int128_t *)r21;
                                                                            r8[0x6] = var_130;
                                                                            var_170 = r8 + 0x38;
                                                                    }
                                                                    else {
                                                                            r0 = void std::__1::vector<std::__1::pair<std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, tensorflow::Tensor>, std::__1::allocator<std::__1::pair<std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, tensorflow::Tensor> > >::__push_back_slow_path<std::__1::pair<std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, tensorflow::Tensor> >(&var_178);
                                                                    }
                                                                    tensorflow::Tensor::~Tensor();
                                                                    if ((sign_extend_64(var_149) & 0xffffffff80000000) != 0x0) {
                                                                            operator delete(var_160);
                                                                    }
                                                                    r0 = operator new(0x20);
                                                                    var_E8 = r0;
                                                                    *(int128_t *)r0 = *(int128_t *)"StatefulPartitionedCall:1";
                                                                    *(int128_t *)(r0 + 0x9) = *(int128_t *)"artitionedCall:1";
                                                                    r0[0x19] = 0x0;
                                                                    r0 = operator new(0x18);
                                                                    r21 = r0;
                                                                    var_238 = r0;
                                                                    std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >::basic_string(r0);
                                                                    if ((sign_extend_64(var_D1) & 0xffffffff80000000) != 0x0) {
                                                                            operator delete(var_E8);
                                                                    }
                                                                    r0 = operator new(0x18);
                                                                    var_250 = r0;
                                                                    r19 = r0 + 0x18;
                                                                    var_E8 = r0;
                                                                    var_110 = r0;
                                                                    std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >::basic_string(r0);
                                                                    var_248 = r19;
                                                                    r0 = TFWrapper::Model::run(var_2B0, &var_178, &var_250);
                                                                    r19 = var_250;
                                                                    if (r19 != 0x0) {
                                                                            r8 = var_248;
                                                                            if (r8 == r19) {
                                                                                    r0 = r19;
                                                                            }
                                                                            else {
                                                                                    do {
                                                                                            r20 = r8 - 0x18;
                                                                                            if ((sign_extend_64(*(int32_t *)(r8 + 0xffffffffffffffff)) & 0xffffffff80000000) != 0x0) {
                                                                                                    operator delete(r8[0xfffffffffffffffd]);
                                                                                            }
                                                                                            r8 = r20;
                                                                                    } while (r20 != r19);
                                                                                    r0 = var_250;
                                                                            }
                                                                            operator delete(r0);
                                                                    }
                                                                    r0 = var_190;
                                                                    if (var_188 != r0) {
                                                                            tensorflow::TensorShapeBase<tensorflow::TensorShape>::dim_size(r0);
                                                                            tensorflow::TensorShapeBase<tensorflow::TensorShape>::dim_size(var_190);
                                                                            var_D0 = tensorflow::Tensor::data();
                                                                            var_C8 = 0x0;
                                                                            r0 = operator new(0x4);
                                                                            r22 = r0;
                                                                            *(int32_t *)r0 = 0x4;
                                                                            var_268 = r0;
                                                                            s2 = 0x3d4ccccd;
                                                                            madmom::downbeat_tracking(&var_E8, &var_268, s0, s1, 0x3c, 0x64, 0x10, 0x3d4ccccd, 0x1, s3);
                                                                            if (var_328 >= 0x1) {
                                                                                    r8 = var_110;
                                                                                    r10 = r8 - 0x1;
                                                                                    if (r10 >= 0x0) {
                                                                                            r9 = r8 & 0xffffffff;
                                                                                            s0 = var_328 * 0x37be37c6;
                                                                                            r11 = var_F8;
                                                                                            if (r9 < 0x4) {
                                                                                                    r13 = r9 - 0x0;
                                                                                                    r12 = r11 + 0x0;
                                                                                                    do {
                                                                                                            *(int32_t *)r12 = *(int32_t *)r12 + s0;
                                                                                                            r12 = r12 + 0x8;
                                                                                                            r13 = r13 - 0x1;
                                                                                                    } while (r13 != 0x0);
                                                                                            }
                                                                                            else {
                                                                                                    r13 = r9 & 0x3;
                                                                                                    r12 = r9 & 0xfffffffc;
                                                                                                    r14 = r11 + 0x10;
                                                                                                    r15 = r12;
                                                                                                    do {
                                                                                                            s1 = r14[0xfffffffffffffffc];
                                                                                                            s2 = r14[0xfffffffffffffffe];
                                                                                                            s3 = *(int32_t *)r14;
                                                                                                            s4 = r14[0x2];
                                                                                                            s2 = s2 + s0;
                                                                                                            r14[0xfffffffffffffffc] = s1 + s0;
                                                                                                            r14[0xfffffffffffffffe] = s2;
                                                                                                            *(int32_t *)r14 = s3 + s0;
                                                                                                            r14[0x2] = s4 + s0;
                                                                                                            r14 = r14 + 0x20;
                                                                                                            r15 = r15 - 0x4;
                                                                                                    } while (r15 != 0x0);
                                                                                                    if (r13 != 0x0) {
                                                                                                            r13 = r9 - r12;
                                                                                                            r12 = r11 + r12 * 0x8;
                                                                                                            do {
                                                                                                                    *(int32_t *)r12 = *(int32_t *)r12 + s0;
                                                                                                                    r12 = r12 + 0x8;
                                                                                                                    r13 = r13 - 0x1;
                                                                                                            } while (r13 != 0x0);
                                                                                                    }
                                                                                            }
                                                                                            r12 = var_94;
                                                                                            if (r12 >= 0x1) {
                                                                                                    if (r8 >= 0x2) {
                                                                                                            asm { fabd       s2, s0, s1 };
                                                                                                            s1 = r11[0x2];
                                                                                                            asm { fabd       s1, s0, s1 };
                                                                                                            if (s2 > s1) {
                                                                                                                    r12 = 0x0;
                                                                                                                    r11 = r11 + 0x10;
                                                                                                                    r13 = r9 - 0x2;
                                                                                                                    while (r13 != r12) {
                                                                                                                            s2 = *(int32_t *)r11;
                                                                                                                            r11 = r11 + 0x8;
                                                                                                                            asm { fabd       s2, s0, s2 };
                                                                                                                            r12 = r12 + 0x1;
                                                                                                                            bool_673 = s1 > s2;
                                                                                                                            s1 = s2;
                                                                                                                            if (bool_673) {
                                                                                                                                    continue;
                                                                                                                            }
                                                                                                                            r10 = r12;
                                                                                                                            break;
                                                                                                                    }
                                                                                                            }
                                                                                                            else {
                                                                                                                    r10 = 0x0;
                                                                                                            }
                                                                                                    }
                                                                                                    else {
                                                                                                            r10 = 0x0;
                                                                                                    }
                                                                                                    r1 = r10 + 0x1;
                                                                                                    if (r1 < r8) {
                                                                                                            asm { bfi        x1, x9, #0x20, #0x20 };
                                                                                                            nc::NdArray<float, std::__1::allocator<float> >::operator(&var_110, r1);
                                                                                                            r0 = nc::NdArray<float, std::__1::allocator<float> >::operator=(&var_110);
                                                                                                            if (var_140 != 0x0) {
                                                                                                                    r0 = var_148;
                                                                                                                    if (r0 != 0x0) {
                                                                                                                            operator delete(r0);
                                                                                                                    }
                                                                                                            }
                                                                                                            nc::NdArray<float, std::__1::allocator<float> >::NdArray(&var_160);
                                                                                                            nc::NdArray<float, std::__1::allocator<float> >::NdArray(&var_160 + 0x28);
                                                                                                            var_1C0 = &var_160;
                                                                                                            nc::NdArray<float, std::__1::allocator<float> > nc::row_stack<float>(&var_1C0);
                                                                                                            nc::NdArray<float, std::__1::allocator<float> >::operator=(&var_A0);
                                                                                                            if (var_218 != 0x0) {
                                                                                                                    r0 = var_220;
                                                                                                                    if (r0 != 0x0) {
                                                                                                                            operator delete(r0);
                                                                                                                    }
                                                                                                            }
                                                                                                            if (var_118 != 0x0) {
                                                                                                                    r0 = var_120;
                                                                                                                    if (r0 != 0x0) {
                                                                                                                            operator delete(r0);
                                                                                                                    }
                                                                                                            }
                                                                                                            if (var_140 != 0x0) {
                                                                                                                    r0 = var_148;
                                                                                                                    if (r0 != 0x0) {
                                                                                                                            operator delete(r0);
                                                                                                                    }
                                                                                                            }
                                                                                                    }
                                                                                            }
                                                                                            else {
                                                                                                    nc::NdArray<float, std::__1::allocator<float> >::NdArray(&var_160);
                                                                                                    nc::NdArray<float, std::__1::allocator<float> >::NdArray(&var_160 + 0x28);
                                                                                                    var_1C0 = &var_160;
                                                                                                    nc::NdArray<float, std::__1::allocator<float> > nc::row_stack<float>(&var_1C0);
                                                                                                    nc::NdArray<float, std::__1::allocator<float> >::operator=(&var_A0);
                                                                                                    if (var_218 != 0x0) {
                                                                                                            r0 = var_220;
                                                                                                            if (r0 != 0x0) {
                                                                                                                    operator delete(r0);
                                                                                                            }
                                                                                                    }
                                                                                                    if (var_118 != 0x0) {
                                                                                                            r0 = var_120;
                                                                                                            if (r0 != 0x0) {
                                                                                                                    operator delete(r0);
                                                                                                            }
                                                                                                    }
                                                                                                    if (var_140 != 0x0) {
                                                                                                            r0 = var_148;
                                                                                                            if (r0 != 0x0) {
                                                                                                                    operator delete(r0);
                                                                                                            }
                                                                                                    }
                                                                                            }
                                                                                    }
                                                                            }
                                                                            else {
                                                                                    nc::NdArray<float, std::__1::allocator<float> >::operator=(&var_A0);
                                                                            }
                                                                            if (var_F0 != 0x0) {
                                                                                    r0 = var_F8;
                                                                                    if (r0 != 0x0) {
                                                                                            operator delete(r0);
                                                                                    }
                                                                            }
                                                                            operator delete(r22);
                                                                            if (var_C8 != 0x0) {
                                                                                    r0 = var_D0;
                                                                                    if (r0 != 0x0) {
                                                                                            operator delete(r0);
                                                                                    }
                                                                            }
                                                                    }
                                                                    if ((sign_extend_64(r21[0x17]) & 0xffffffff80000000) != 0x0) {
                                                                            operator delete(*r21);
                                                                    }
                                                                    operator delete(r21);
                                                                    tensorflow::Tensor::~Tensor();
                                                                    r21 = var_88;
                                                                    r19 = var_80;
                                                                    var_80 = 0x0;
                                                                    var_88 = 0x0;
                                                                    if ((sign_extend_64(var_199) & 0xffffffff80000000) != 0x0) {
                                                                            operator delete(var_1B0);
                                                                    }
                                                                    (*(*var_2B0 + 0x8))(var_2B0);
                                                                    r20 = var_190;
                                                                    if (r20 != 0x0) {
                                                                            r0 = var_188;
                                                                            if (r0 != r20) {
                                                                                    do {
                                                                                            r0 = tensorflow::Tensor::~Tensor();
                                                                                    } while (r0 != r20);
                                                                                    r0 = var_190;
                                                                            }
                                                                            else {
                                                                                    r0 = r20;
                                                                            }
                                                                            operator delete(r0);
                                                                    }
                                                                    r20 = var_178;
                                                                    if (r20 != 0x0) {
                                                                            r22 = var_170;
                                                                            if (r22 == r20) {
                                                                                    r0 = r20;
                                                                            }
                                                                            else {
                                                                                    do {
                                                                                            r23 = r22 - 0x38;
                                                                                            tensorflow::Tensor::~Tensor();
                                                                                            if ((sign_extend_64(*(int32_t *)(r22 + 0xffffffffffffffdf)) & 0xffffffff80000000) != 0x0) {
                                                                                                    operator delete(r22[0xfffffffffffffff9]);
                                                                                            }
                                                                                            r22 = r23;
                                                                                    } while (r23 != r20);
                                                                                    r0 = var_178;
                                                                            }
                                                                            operator delete(r0);
                                                                    }
                                                                    juce::String::~String();
                                                                    if (var_80 != 0x0) {
                                                                            r0 = var_88;
                                                                            if (r0 != 0x0) {
                                                                                    operator delete(r0);
                                                                            }
                                                                    }
                                                                    madmom::to_vector(r25);
                                                                    if (r19 != 0x0 && r21 != 0x0) {
                                                                            operator delete(r21);
                                                                    }
                                                                    r0 = juce::String::~String();
                                                                    if (**___stack_chk_guard != var_78) {
                                                                            __stack_chk_fail();
                                                                    }
                                                            }
                                                            else {
                                                                    r21 = var_88;
                                                                    r19 = var_80;
                                                                    var_80 = 0x0;
                                                                    var_88 = 0x0;
                                                                    if ((sign_extend_64(var_199) & 0xffffffff80000000) != 0x0) {
                                                                            operator delete(var_1B0);
                                                                    }
                                                                    (*(*var_2B0 + 0x8))(var_2B0);
                                                                    r20 = var_190;
                                                                    if (r20 != 0x0) {
                                                                            r0 = var_188;
                                                                            if (r0 != r20) {
                                                                                    do {
                                                                                            r0 = tensorflow::Tensor::~Tensor();
                                                                                    } while (r0 != r20);
                                                                                    r0 = var_190;
                                                                            }
                                                                            else {
                                                                                    r0 = r20;
                                                                            }
                                                                            operator delete(r0);
                                                                    }
                                                                    r20 = var_178;
                                                                    if (r20 != 0x0) {
                                                                            r22 = var_170;
                                                                            if (r22 == r20) {
                                                                                    r0 = r20;
                                                                            }
                                                                            else {
                                                                                    do {
                                                                                            r23 = r22 - 0x38;
                                                                                            tensorflow::Tensor::~Tensor();
                                                                                            if ((sign_extend_64(*(int32_t *)(r22 + 0xffffffffffffffdf)) & 0xffffffff80000000) != 0x0) {
                                                                                                    operator delete(r22[0xfffffffffffffff9]);
                                                                                            }
                                                                                            r22 = r23;
                                                                                    } while (r23 != r20);
                                                                                    r0 = var_178;
                                                                            }
                                                                            operator delete(r0);
                                                                    }
                                                                    juce::String::~String();
                                                                    if (var_80 != 0x0) {
                                                                            r0 = var_88;
                                                                            if (r0 != 0x0) {
                                                                                    operator delete(r0);
                                                                            }
                                                                    }
                                                                    madmom::to_vector(r25);
                                                                    if (r19 != 0x0 && r21 != 0x0) {
                                                                            operator delete(r21);
                                                                    }
                                                                    r0 = juce::String::~String();
                                                                    if (**___stack_chk_guard != var_78) {
                                                                            __stack_chk_fail();
                                                                    }
                                                            }
                                                    }
                                            }
                                            else {
                                                    if (r21 >= 0x1) {
                                                            r19 = r21;
                                                            r0 = tensorflow::TensorShapeBase<tensorflow::TensorShape>::TensorShapeBase(&var_160);
                                                            r0 = tensorflow::Tensor::Tensor(&var_C0, 0x1);
                                                            if (var_151 == 0x2) {
                                                                    tensorflow::TensorShapeRep::DestructorOutOfLine();
                                                            }
                                                            r0 = tensorflow::Tensor::data();
                                                            r8 = var_320;
                                                            asm { sxtw       x8, w8 };
                                                            if (r21 < 0x10) {
                                                                    r10 = r19 - 0x0;
                                                                    r9 = 0x0 + r8 << 0x2;
                                                                    r8 = var_2E8 + r9;
                                                                    r9 = r22 + r9;
                                                                    s0 = 0x3fe0000000000000;
                                                                    do {
                                                                            s1 = *(int32_t *)r9;
                                                                            r9 = r9 + 0x4;
                                                                            s2 = *(int32_t *)r8;
                                                                            r8 = r8 + 0x4;
                                                                            s1 = (s2 + s1) * s0;
                                                                            *(int32_t *)r0 = s1;
                                                                            r0 = r0 + 0x4;
                                                                            r10 = r10 - 0x1;
                                                                    } while (r10 != 0x0);
                                                            }
                                                            else {
                                                                    r12 = r8 << 0x2;
                                                                    if (r0 - r12 + var_2E8 >= 0x40) {
                                                                            if (r0 - r12 + r22 >= 0x40) {
                                                                                    r9 = r19 & 0xfffffff0;
                                                                                    r10 = r0 + r9 * 0x4;
                                                                                    r11 = r0 + 0x20;
                                                                                    r13 = r12 + 0x20;
                                                                                    r12 = r22 + r13;
                                                                                    r13 = var_2E8 + r13;
                                                                                    v0 = 0x3f000000;
                                                                                    r14 = r9;
                                                                                    do {
                                                                                            q1 = r12[0xfffffffffffffffc];
                                                                                            q2 = r12[0xfffffffffffffffe];
                                                                                            q3 = *r12;
                                                                                            q4 = r12[0x2];
                                                                                            r12 = r12 + 0x40;
                                                                                            r13 = r13 + 0x40;
                                                                                            v1 = (v5 + v1) * v0;
                                                                                            v2 = (v6 + v2) * v0;
                                                                                            v3 = (v7 + v3) * v0;
                                                                                            v4 = (v16 + v4) * v0;
                                                                                            r11[0xfffffffffffffffc] = q1;
                                                                                            r11[0xfffffffffffffffe] = q2;
                                                                                            *r11 = q3;
                                                                                            r11[0x2] = q4;
                                                                                            r11 = r11 + 0x40;
                                                                                            r14 = r14 - 0x10;
                                                                                    } while (r14 != 0x0);
                                                                                    r0 = r10;
                                                                                    if (r9 != r19) {
                                                                                            r10 = r19 - r9;
                                                                                            r9 = r9 + r8 << 0x2;
                                                                                            r8 = var_2E8 + r9;
                                                                                            r9 = r22 + r9;
                                                                                            s0 = 0x3fe0000000000000;
                                                                                            do {
                                                                                                    s1 = *(int32_t *)r9;
                                                                                                    r9 = r9 + 0x4;
                                                                                                    s2 = *(int32_t *)r8;
                                                                                                    r8 = r8 + 0x4;
                                                                                                    s1 = (s2 + s1) * s0;
                                                                                                    *(int32_t *)r0 = s1;
                                                                                                    r0 = r0 + 0x4;
                                                                                                    r10 = r10 - 0x1;
                                                                                            } while (r10 != 0x0);
                                                                                    }
                                                                            }
                                                                            else {
                                                                                    r10 = r19 - 0x0;
                                                                                    r9 = 0x0 + r8 << 0x2;
                                                                                    r8 = var_2E8 + r9;
                                                                                    r9 = r22 + r9;
                                                                                    s0 = 0x3fe0000000000000;
                                                                                    do {
                                                                                            s1 = *(int32_t *)r9;
                                                                                            r9 = r9 + 0x4;
                                                                                            s2 = *(int32_t *)r8;
                                                                                            r8 = r8 + 0x4;
                                                                                            s1 = (s2 + s1) * s0;
                                                                                            *(int32_t *)r0 = s1;
                                                                                            r0 = r0 + 0x4;
                                                                                            r10 = r10 - 0x1;
                                                                                    } while (r10 != 0x0);
                                                                            }
                                                                    }
                                                                    else {
                                                                            r10 = r19 - 0x0;
                                                                            r9 = 0x0 + r8 << 0x2;
                                                                            r8 = var_2E8 + r9;
                                                                            r9 = r22 + r9;
                                                                            s0 = 0x3fe0000000000000;
                                                                            do {
                                                                                    s1 = *(int32_t *)r9;
                                                                                    r9 = r9 + 0x4;
                                                                                    s2 = *(int32_t *)r8;
                                                                                    r8 = r8 + 0x4;
                                                                                    s1 = (s2 + s1) * s0;
                                                                                    *(int32_t *)r0 = s1;
                                                                                    r0 = r0 + 0x4;
                                                                                    r10 = r10 - 0x1;
                                                                            } while (r10 != 0x0);
                                                                    }
                                                            }
                                                            r19 = var_178;
                                                            r20 = var_170;
                                                            if (r20 != r19) {
                                                                    r21 = r20 - 0x38;
                                                                    tensorflow::Tensor::~Tensor();
                                                                    if ((sign_extend_64(*(int32_t *)(r20 + 0xffffffffffffffdf)) & 0xffffffff80000000) != 0x0) {
                                                                            operator delete(r20[0xfffffffffffffff9]);
                                                                    }
                                                                    r20 = r21;
                                                                    if (r21 != r19) {
                                                                            continue;
                                                                    }
                                                                    break;
                                                            }
                                                            r21 = r22;
                                                            var_170 = r19;
                                                            r0 = std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >::basic_string(&var_160);
                                                            r22 = &var_160 + 0x18;
                                                            var_138 = var_B0;
                                                            if (var_B1 == 0x2) {
                                                                    tensorflow::TensorShapeRep::SlowCopyFrom(r22);
                                                            }
                                                            else {
                                                                    *(int128_t *)r22 = var_C0;
                                                            }
                                                            r8 = var_A8;
                                                            var_130 = r8;
                                                            if (r8 != 0x0) {
                                                                    asm { ldadd      w9, w8, [x8] };
                                                            }
                                                            r8 = var_170;
                                                            if (r8 < var_168) {
                                                                    r8[0x2] = var_150;
                                                                    *(int128_t *)r8 = var_160;
                                                                    var_150 = 0x0;
                                                                    var_160 = 0x0;
                                                                    r8[0x5] = var_138;
                                                                    *(int128_t *)(r8 + 0x18) = *(int128_t *)r22;
                                                                    r8[0x6] = var_130;
                                                                    var_170 = r8 + 0x38;
                                                            }
                                                            else {
                                                                    r0 = void std::__1::vector<std::__1::pair<std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, tensorflow::Tensor>, std::__1::allocator<std::__1::pair<std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, tensorflow::Tensor> > >::__push_back_slow_path<std::__1::pair<std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, tensorflow::Tensor> >(&var_178);
                                                            }
                                                            tensorflow::Tensor::~Tensor();
                                                            if ((sign_extend_64(var_149) & 0xffffffff80000000) != 0x0) {
                                                                    operator delete(var_160);
                                                            }
                                                            r0 = operator new(0x20);
                                                            var_E8 = r0;
                                                            *(int128_t *)r0 = *(int128_t *)"StatefulPartitionedCall:1";
                                                            *(int128_t *)(r0 + 0x9) = *(int128_t *)"artitionedCall:1";
                                                            r0[0x19] = 0x0;
                                                            r0 = operator new(0x18);
                                                            r22 = r0;
                                                            var_238 = r0;
                                                            std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >::basic_string(r0);
                                                            if ((sign_extend_64(var_D1) & 0xffffffff80000000) != 0x0) {
                                                                    operator delete(var_E8);
                                                            }
                                                            r0 = operator new(0x18);
                                                            var_210 = r0;
                                                            r19 = r0 + 0x18;
                                                            var_E8 = r0;
                                                            var_110 = r0;
                                                            std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >::basic_string(r0);
                                                            var_208 = r19;
                                                            r0 = TFWrapper::Model::run(var_2B0, &var_178, &var_210);
                                                            r19 = var_210;
                                                            if (r19 != 0x0) {
                                                                    r8 = var_208;
                                                                    if (r8 == r19) {
                                                                            r0 = r19;
                                                                    }
                                                                    else {
                                                                            do {
                                                                                    r20 = r8 - 0x18;
                                                                                    if ((sign_extend_64(*(int32_t *)(r8 + 0xffffffffffffffff)) & 0xffffffff80000000) != 0x0) {
                                                                                            operator delete(r8[0xfffffffffffffffd]);
                                                                                    }
                                                                                    r8 = r20;
                                                                            } while (r20 != r19);
                                                                            r0 = var_210;
                                                                    }
                                                                    operator delete(r0);
                                                            }
                                                            r0 = var_190;
                                                            if (var_188 != r0) {
                                                                    tensorflow::TensorShapeBase<tensorflow::TensorShape>::dim_size(r0);
                                                                    tensorflow::TensorShapeBase<tensorflow::TensorShape>::dim_size(var_190);
                                                                    var_D0 = tensorflow::Tensor::data();
                                                                    var_C8 = 0x0;
                                                                    r0 = operator new(0x4);
                                                                    r23 = r0;
                                                                    *(int32_t *)r0 = 0x4;
                                                                    var_250 = r0;
                                                                    s2 = 0x3d4ccccd;
                                                                    madmom::downbeat_tracking(&var_E8, &var_250, s0, s1, 0x3c, 0x64, 0x10, 0x3d4ccccd, 0x1, s3);
                                                                    r24 = &var_A0;
                                                                    if (var_320 >= 0x1) {
                                                                            r8 = var_110;
                                                                            r10 = r8 - 0x1;
                                                                            if (r10 >= 0x0) {
                                                                                    r9 = r8 & 0xffffffff;
                                                                                    s0 = var_320 * 0x37be37c6;
                                                                                    r11 = var_F8;
                                                                                    if (r9 < 0x4) {
                                                                                            r13 = r9 - 0x0;
                                                                                            r12 = r11 + 0x0;
                                                                                            do {
                                                                                                    s1 = *(int32_t *)r12;
                                                                                                    s1 = s1 + s0;
                                                                                                    *(int32_t *)r12 = s1;
                                                                                                    r12 = r12 + 0x8;
                                                                                                    r13 = r13 - 0x1;
                                                                                            } while (r13 != 0x0);
                                                                                    }
                                                                                    else {
                                                                                            r13 = r9 & 0x3;
                                                                                            r12 = r9 & 0xfffffffc;
                                                                                            r14 = r11 + 0x10;
                                                                                            r15 = r12;
                                                                                            do {
                                                                                                    s1 = r14[0xfffffffffffffffc];
                                                                                                    s2 = r14[0xfffffffffffffffe];
                                                                                                    s3 = *(int32_t *)r14;
                                                                                                    s4 = r14[0x2];
                                                                                                    s1 = s1 + s0;
                                                                                                    s2 = s2 + s0;
                                                                                                    s3 = s3 + s0;
                                                                                                    r14[0xfffffffffffffffc] = s1;
                                                                                                    r14[0xfffffffffffffffe] = s2;
                                                                                                    *(int32_t *)r14 = s3;
                                                                                                    r14[0x2] = s4 + s0;
                                                                                                    r14 = r14 + 0x20;
                                                                                                    r15 = r15 - 0x4;
                                                                                            } while (r15 != 0x0);
                                                                                            if (r13 != 0x0) {
                                                                                                    r13 = r9 - r12;
                                                                                                    r12 = r11 + r12 * 0x8;
                                                                                                    do {
                                                                                                            s1 = *(int32_t *)r12;
                                                                                                            s1 = s1 + s0;
                                                                                                            *(int32_t *)r12 = s1;
                                                                                                            r12 = r12 + 0x8;
                                                                                                            r13 = r13 - 0x1;
                                                                                                    } while (r13 != 0x0);
                                                                                            }
                                                                                    }
                                                                                    r12 = var_94;
                                                                                    if (r12 >= 0x1) {
                                                                                            if (r8 >= 0x2) {
                                                                                                    s0 = *(int32_t *)(var_88 + ((r12 & (r12 - 0x2) / 0x80000000) + (r12 - 0x2)) * 0x4);
                                                                                                    asm { fabd       s2, s0, s1 };
                                                                                                    s1 = r11[0x2];
                                                                                                    asm { fabd       s1, s0, s1 };
                                                                                                    if (s2 > s1) {
                                                                                                            r12 = 0x0;
                                                                                                            r11 = r11 + 0x10;
                                                                                                            r13 = r9 - 0x2;
                                                                                                            while (r13 != r12) {
                                                                                                                    s2 = *(int32_t *)r11;
                                                                                                                    r11 = r11 + 0x8;
                                                                                                                    asm { fabd       s2, s0, s2 };
                                                                                                                    r12 = r12 + 0x1;
                                                                                                                    bool_567 = s1 > s2;
                                                                                                                    s1 = s2;
                                                                                                                    if (bool_567) {
                                                                                                                            continue;
                                                                                                                    }
                                                                                                                    r10 = r12;
                                                                                                                    break;
                                                                                                            }
                                                                                                    }
                                                                                                    else {
                                                                                                            r10 = 0x0;
                                                                                                    }
                                                                                            }
                                                                                            else {
                                                                                                    r10 = 0x0;
                                                                                            }
                                                                                            r1 = r10 + 0x1;
                                                                                            if (r1 < r8) {
                                                                                                    asm { bfi        x1, x9, #0x20, #0x20 };
                                                                                                    nc::NdArray<float, std::__1::allocator<float> >::operator(&var_110, r1);
                                                                                                    r0 = nc::NdArray<float, std::__1::allocator<float> >::operator=(&var_110);
                                                                                                    if (var_140 != 0x0) {
                                                                                                            r0 = var_148;
                                                                                                            if (r0 != 0x0) {
                                                                                                                    operator delete(r0);
                                                                                                            }
                                                                                                    }
                                                                                                    r0 = nc::NdArray<float, std::__1::allocator<float> >::NdArray(&var_160);
                                                                                                    nc::NdArray<float, std::__1::allocator<float> >::NdArray(&var_160 + 0x28);
                                                                                                    var_268 = &var_160;
                                                                                                    nc::NdArray<float, std::__1::allocator<float> > nc::row_stack<float>(&var_268);
                                                                                                    r0 = nc::NdArray<float, std::__1::allocator<float> >::operator=(&var_A0);
                                                                                                    if (var_218 != 0x0) {
                                                                                                            r0 = var_220;
                                                                                                            if (r0 != 0x0) {
                                                                                                                    operator delete(r0);
                                                                                                            }
                                                                                                    }
                                                                                                    var_220 = 0x0;
                                                                                                    var_218 = 0x0;
                                                                                                    if (var_118 != 0x0) {
                                                                                                            r0 = var_120;
                                                                                                            if (r0 != 0x0) {
                                                                                                                    operator delete(r0);
                                                                                                            }
                                                                                                    }
                                                                                                    var_120 = 0x0;
                                                                                                    var_118 = 0x0;
                                                                                                    if (var_140 != 0x0) {
                                                                                                            r0 = var_148;
                                                                                                            if (r0 != 0x0) {
                                                                                                                    operator delete(r0);
                                                                                                            }
                                                                                                    }
                                                                                            }
                                                                                    }
                                                                                    else {
                                                                                            r0 = nc::NdArray<float, std::__1::allocator<float> >::NdArray(&var_160);
                                                                                            nc::NdArray<float, std::__1::allocator<float> >::NdArray(&var_160 + 0x28);
                                                                                            var_268 = &var_160;
                                                                                            nc::NdArray<float, std::__1::allocator<float> > nc::row_stack<float>(&var_268);
                                                                                            r0 = nc::NdArray<float, std::__1::allocator<float> >::operator=(&var_A0);
                                                                                            if (var_218 != 0x0) {
                                                                                                    r0 = var_220;
                                                                                                    if (r0 != 0x0) {
                                                                                                            operator delete(r0);
                                                                                                    }
                                                                                            }
                                                                                            var_220 = 0x0;
                                                                                            var_218 = 0x0;
                                                                                            if (var_118 != 0x0) {
                                                                                                    r0 = var_120;
                                                                                                    if (r0 != 0x0) {
                                                                                                            operator delete(r0);
                                                                                                    }
                                                                                            }
                                                                                            var_120 = 0x0;
                                                                                            var_118 = 0x0;
                                                                                            if (var_140 != 0x0) {
                                                                                                    r0 = var_148;
                                                                                                    if (r0 != 0x0) {
                                                                                                            operator delete(r0);
                                                                                                    }
                                                                                            }
                                                                                    }
                                                                            }
                                                                    }
                                                                    else {
                                                                            r0 = nc::NdArray<float, std::__1::allocator<float> >::operator=(&var_A0);
                                                                    }
                                                                    if (var_F0 != 0x0) {
                                                                            r0 = var_F8;
                                                                            if (r0 != 0x0) {
                                                                                    operator delete(r0);
                                                                            }
                                                                    }
                                                                    operator delete(r23);
                                                                    if (var_C8 != 0x0) {
                                                                            r0 = var_D0;
                                                                            if (r0 != 0x0) {
                                                                                    operator delete(r0);
                                                                            }
                                                                    }
                                                            }
                                                            if ((sign_extend_64(r22[0x17]) & 0xffffffff80000000) != 0x0) {
                                                                    operator delete(*r22);
                                                            }
                                                            operator delete(r22);
                                                            tensorflow::Tensor::~Tensor();
                                                            r22 = r21;
                                                            if (r26 >= 0x1) {
                                                                    r19 = r26;
                                                                    r0 = tensorflow::TensorShapeBase<tensorflow::TensorShape>::TensorShapeBase(&var_160);
                                                                    r0 = tensorflow::Tensor::Tensor(&var_C0, 0x1);
                                                                    if (var_151 == 0x2) {
                                                                            tensorflow::TensorShapeRep::DestructorOutOfLine();
                                                                    }
                                                                    r0 = tensorflow::Tensor::data();
                                                                    r8 = var_328;
                                                                    asm { sxtw       x8, w8 };
                                                                    if (r26 < 0x10) {
                                                                            r10 = r19 - 0x0;
                                                                            r9 = 0x0 + r8 << 0x2;
                                                                            r8 = var_2E8 + r9;
                                                                            r9 = r22 + r9;
                                                                            s0 = 0x3fe0000000000000;
                                                                            do {
                                                                                    s1 = *(int32_t *)r9;
                                                                                    r9 = r9 + 0x4;
                                                                                    s2 = *(int32_t *)r8;
                                                                                    r8 = r8 + 0x4;
                                                                                    s1 = (s2 + s1) * s0;
                                                                                    *(int32_t *)r0 = s1;
                                                                                    r0 = r0 + 0x4;
                                                                                    r10 = r10 - 0x1;
                                                                            } while (r10 != 0x0);
                                                                    }
                                                                    else {
                                                                            r12 = r8 << 0x2;
                                                                            if (r0 - r12 + var_2E8 >= 0x40) {
                                                                                    if (r0 - r12 + r22 >= 0x40) {
                                                                                            r9 = r19 & 0xfffffff0;
                                                                                            r10 = r0 + r9 * 0x4;
                                                                                            r11 = r0 + 0x20;
                                                                                            r13 = r12 + 0x20;
                                                                                            r12 = r22 + r13;
                                                                                            r13 = var_2E8 + r13;
                                                                                            v0 = 0x3f000000;
                                                                                            r14 = r9;
                                                                                            do {
                                                                                                    q1 = r12[0xfffffffffffffffc];
                                                                                                    q2 = r12[0xfffffffffffffffe];
                                                                                                    q3 = *r12;
                                                                                                    q4 = r12[0x2];
                                                                                                    r12 = r12 + 0x40;
                                                                                                    r13 = r13 + 0x40;
                                                                                                    v1 = (v5 + v1) * v0;
                                                                                                    v2 = (v6 + v2) * v0;
                                                                                                    v3 = (v7 + v3) * v0;
                                                                                                    v4 = (v16 + v4) * v0;
                                                                                                    r11[0xfffffffffffffffc] = q1;
                                                                                                    r11[0xfffffffffffffffe] = q2;
                                                                                                    *r11 = q3;
                                                                                                    r11[0x2] = q4;
                                                                                                    r11 = r11 + 0x40;
                                                                                                    r14 = r14 - 0x10;
                                                                                            } while (r14 != 0x0);
                                                                                            r0 = r10;
                                                                                            if (r9 != r19) {
                                                                                                    r10 = r19 - r9;
                                                                                                    r9 = r9 + r8 << 0x2;
                                                                                                    r8 = var_2E8 + r9;
                                                                                                    r9 = r22 + r9;
                                                                                                    s0 = 0x3fe0000000000000;
                                                                                                    do {
                                                                                                            s1 = *(int32_t *)r9;
                                                                                                            r9 = r9 + 0x4;
                                                                                                            s2 = *(int32_t *)r8;
                                                                                                            r8 = r8 + 0x4;
                                                                                                            s1 = (s2 + s1) * s0;
                                                                                                            *(int32_t *)r0 = s1;
                                                                                                            r0 = r0 + 0x4;
                                                                                                            r10 = r10 - 0x1;
                                                                                                    } while (r10 != 0x0);
                                                                                            }
                                                                                    }
                                                                                    else {
                                                                                            r10 = r19 - 0x0;
                                                                                            r9 = 0x0 + r8 << 0x2;
                                                                                            r8 = var_2E8 + r9;
                                                                                            r9 = r22 + r9;
                                                                                            s0 = 0x3fe0000000000000;
                                                                                            do {
                                                                                                    s1 = *(int32_t *)r9;
                                                                                                    r9 = r9 + 0x4;
                                                                                                    s2 = *(int32_t *)r8;
                                                                                                    r8 = r8 + 0x4;
                                                                                                    s1 = (s2 + s1) * s0;
                                                                                                    *(int32_t *)r0 = s1;
                                                                                                    r0 = r0 + 0x4;
                                                                                                    r10 = r10 - 0x1;
                                                                                            } while (r10 != 0x0);
                                                                                    }
                                                                            }
                                                                            else {
                                                                                    r10 = r19 - 0x0;
                                                                                    r9 = 0x0 + r8 << 0x2;
                                                                                    r8 = var_2E8 + r9;
                                                                                    r9 = r22 + r9;
                                                                                    s0 = 0x3fe0000000000000;
                                                                                    do {
                                                                                            s1 = *(int32_t *)r9;
                                                                                            r9 = r9 + 0x4;
                                                                                            s2 = *(int32_t *)r8;
                                                                                            r8 = r8 + 0x4;
                                                                                            s1 = (s2 + s1) * s0;
                                                                                            *(int32_t *)r0 = s1;
                                                                                            r0 = r0 + 0x4;
                                                                                            r10 = r10 - 0x1;
                                                                                    } while (r10 != 0x0);
                                                                            }
                                                                    }
                                                                    r19 = var_178;
                                                                    r20 = var_170;
                                                                    if (r20 != r19) {
                                                                            r21 = r20 - 0x38;
                                                                            tensorflow::Tensor::~Tensor();
                                                                            if ((sign_extend_64(*(int32_t *)(r20 + 0xffffffffffffffdf)) & 0xffffffff80000000) != 0x0) {
                                                                                    operator delete(r20[0xfffffffffffffff9]);
                                                                            }
                                                                            r20 = r21;
                                                                            if (r21 != r19) {
                                                                                    continue;
                                                                            }
                                                                            break;
                                                                    }
                                                                    var_170 = r19;
                                                                    r0 = std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >::basic_string(&var_160);
                                                                    r21 = &var_160 + 0x18;
                                                                    var_138 = var_B0;
                                                                    if (var_B1 == 0x2) {
                                                                            tensorflow::TensorShapeRep::SlowCopyFrom(r21);
                                                                    }
                                                                    else {
                                                                            *(int128_t *)r21 = var_C0;
                                                                    }
                                                                    r8 = var_A8;
                                                                    var_130 = r8;
                                                                    if (r8 != 0x0) {
                                                                            asm { ldadd      w9, w8, [x8] };
                                                                    }
                                                                    r8 = var_170;
                                                                    if (r8 < var_168) {
                                                                            r8[0x2] = var_150;
                                                                            *(int128_t *)r8 = var_160;
                                                                            var_160 = 0x0;
                                                                            r8[0x5] = var_138;
                                                                            *(int128_t *)(r8 + 0x18) = *(int128_t *)r21;
                                                                            r8[0x6] = var_130;
                                                                            var_170 = r8 + 0x38;
                                                                    }
                                                                    else {
                                                                            r0 = void std::__1::vector<std::__1::pair<std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, tensorflow::Tensor>, std::__1::allocator<std::__1::pair<std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, tensorflow::Tensor> > >::__push_back_slow_path<std::__1::pair<std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, tensorflow::Tensor> >(&var_178);
                                                                    }
                                                                    tensorflow::Tensor::~Tensor();
                                                                    if ((sign_extend_64(var_149) & 0xffffffff80000000) != 0x0) {
                                                                            operator delete(var_160);
                                                                    }
                                                                    r0 = operator new(0x20);
                                                                    var_E8 = r0;
                                                                    *(int128_t *)r0 = *(int128_t *)"StatefulPartitionedCall:1";
                                                                    *(int128_t *)(r0 + 0x9) = *(int128_t *)"artitionedCall:1";
                                                                    r0[0x19] = 0x0;
                                                                    r0 = operator new(0x18);
                                                                    r21 = r0;
                                                                    var_238 = r0;
                                                                    std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >::basic_string(r0);
                                                                    if ((sign_extend_64(var_D1) & 0xffffffff80000000) != 0x0) {
                                                                            operator delete(var_E8);
                                                                    }
                                                                    r0 = operator new(0x18);
                                                                    var_250 = r0;
                                                                    r19 = r0 + 0x18;
                                                                    var_E8 = r0;
                                                                    var_110 = r0;
                                                                    std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >::basic_string(r0);
                                                                    var_248 = r19;
                                                                    r0 = TFWrapper::Model::run(var_2B0, &var_178, &var_250);
                                                                    r19 = var_250;
                                                                    if (r19 != 0x0) {
                                                                            r8 = var_248;
                                                                            if (r8 == r19) {
                                                                                    r0 = r19;
                                                                            }
                                                                            else {
                                                                                    do {
                                                                                            r20 = r8 - 0x18;
                                                                                            if ((sign_extend_64(*(int32_t *)(r8 + 0xffffffffffffffff)) & 0xffffffff80000000) != 0x0) {
                                                                                                    operator delete(r8[0xfffffffffffffffd]);
                                                                                            }
                                                                                            r8 = r20;
                                                                                    } while (r20 != r19);
                                                                                    r0 = var_250;
                                                                            }
                                                                            operator delete(r0);
                                                                    }
                                                                    r0 = var_190;
                                                                    if (var_188 != r0) {
                                                                            tensorflow::TensorShapeBase<tensorflow::TensorShape>::dim_size(r0);
                                                                            tensorflow::TensorShapeBase<tensorflow::TensorShape>::dim_size(var_190);
                                                                            var_D0 = tensorflow::Tensor::data();
                                                                            var_C8 = 0x0;
                                                                            r0 = operator new(0x4);
                                                                            r22 = r0;
                                                                            *(int32_t *)r0 = 0x4;
                                                                            var_268 = r0;
                                                                            s2 = 0x3d4ccccd;
                                                                            madmom::downbeat_tracking(&var_E8, &var_268, s0, s1, 0x3c, 0x64, 0x10, 0x3d4ccccd, 0x1, s3);
                                                                            if (var_328 >= 0x1) {
                                                                                    r8 = var_110;
                                                                                    r10 = r8 - 0x1;
                                                                                    if (r10 >= 0x0) {
                                                                                            r9 = r8 & 0xffffffff;
                                                                                            s0 = var_328 * 0x37be37c6;
                                                                                            r11 = var_F8;
                                                                                            if (r9 < 0x4) {
                                                                                                    r13 = r9 - 0x0;
                                                                                                    r12 = r11 + 0x0;
                                                                                                    do {
                                                                                                            *(int32_t *)r12 = *(int32_t *)r12 + s0;
                                                                                                            r12 = r12 + 0x8;
                                                                                                            r13 = r13 - 0x1;
                                                                                                    } while (r13 != 0x0);
                                                                                            }
                                                                                            else {
                                                                                                    r13 = r9 & 0x3;
                                                                                                    r12 = r9 & 0xfffffffc;
                                                                                                    r14 = r11 + 0x10;
                                                                                                    r15 = r12;
                                                                                                    do {
                                                                                                            s1 = r14[0xfffffffffffffffc];
                                                                                                            s2 = r14[0xfffffffffffffffe];
                                                                                                            s3 = *(int32_t *)r14;
                                                                                                            s4 = r14[0x2];
                                                                                                            s2 = s2 + s0;
                                                                                                            r14[0xfffffffffffffffc] = s1 + s0;
                                                                                                            r14[0xfffffffffffffffe] = s2;
                                                                                                            *(int32_t *)r14 = s3 + s0;
                                                                                                            r14[0x2] = s4 + s0;
                                                                                                            r14 = r14 + 0x20;
                                                                                                            r15 = r15 - 0x4;
                                                                                                    } while (r15 != 0x0);
                                                                                                    if (r13 != 0x0) {
                                                                                                            r13 = r9 - r12;
                                                                                                            r12 = r11 + r12 * 0x8;
                                                                                                            do {
                                                                                                                    *(int32_t *)r12 = *(int32_t *)r12 + s0;
                                                                                                                    r12 = r12 + 0x8;
                                                                                                                    r13 = r13 - 0x1;
                                                                                                            } while (r13 != 0x0);
                                                                                                    }
                                                                                            }
                                                                                            r12 = var_94;
                                                                                            if (r12 >= 0x1) {
                                                                                                    if (r8 >= 0x2) {
                                                                                                            asm { fabd       s2, s0, s1 };
                                                                                                            s1 = r11[0x2];
                                                                                                            asm { fabd       s1, s0, s1 };
                                                                                                            if (s2 > s1) {
                                                                                                                    r12 = 0x0;
                                                                                                                    r11 = r11 + 0x10;
                                                                                                                    r13 = r9 - 0x2;
                                                                                                                    while (r13 != r12) {
                                                                                                                            s2 = *(int32_t *)r11;
                                                                                                                            r11 = r11 + 0x8;
                                                                                                                            asm { fabd       s2, s0, s2 };
                                                                                                                            r12 = r12 + 0x1;
                                                                                                                            bool_686 = s1 > s2;
                                                                                                                            s1 = s2;
                                                                                                                            if (bool_686) {
                                                                                                                                    continue;
                                                                                                                            }
                                                                                                                            r10 = r12;
                                                                                                                            break;
                                                                                                                    }
                                                                                                            }
                                                                                                            else {
                                                                                                                    r10 = 0x0;
                                                                                                            }
                                                                                                    }
                                                                                                    else {
                                                                                                            r10 = 0x0;
                                                                                                    }
                                                                                                    r1 = r10 + 0x1;
                                                                                                    if (r1 < r8) {
                                                                                                            asm { bfi        x1, x9, #0x20, #0x20 };
                                                                                                            nc::NdArray<float, std::__1::allocator<float> >::operator(&var_110, r1);
                                                                                                            r0 = nc::NdArray<float, std::__1::allocator<float> >::operator=(&var_110);
                                                                                                            if (var_140 != 0x0) {
                                                                                                                    r0 = var_148;
                                                                                                                    if (r0 != 0x0) {
                                                                                                                            operator delete(r0);
                                                                                                                    }
                                                                                                            }
                                                                                                            nc::NdArray<float, std::__1::allocator<float> >::NdArray(&var_160);
                                                                                                            nc::NdArray<float, std::__1::allocator<float> >::NdArray(&var_160 + 0x28);
                                                                                                            var_1C0 = &var_160;
                                                                                                            nc::NdArray<float, std::__1::allocator<float> > nc::row_stack<float>(&var_1C0);
                                                                                                            nc::NdArray<float, std::__1::allocator<float> >::operator=(&var_A0);
                                                                                                            if (var_218 != 0x0) {
                                                                                                                    r0 = var_220;
                                                                                                                    if (r0 != 0x0) {
                                                                                                                            operator delete(r0);
                                                                                                                    }
                                                                                                            }
                                                                                                            if (var_118 != 0x0) {
                                                                                                                    r0 = var_120;
                                                                                                                    if (r0 != 0x0) {
                                                                                                                            operator delete(r0);
                                                                                                                    }
                                                                                                            }
                                                                                                            if (var_140 != 0x0) {
                                                                                                                    r0 = var_148;
                                                                                                                    if (r0 != 0x0) {
                                                                                                                            operator delete(r0);
                                                                                                                    }
                                                                                                            }
                                                                                                    }
                                                                                            }
                                                                                            else {
                                                                                                    nc::NdArray<float, std::__1::allocator<float> >::NdArray(&var_160);
                                                                                                    nc::NdArray<float, std::__1::allocator<float> >::NdArray(&var_160 + 0x28);
                                                                                                    var_1C0 = &var_160;
                                                                                                    nc::NdArray<float, std::__1::allocator<float> > nc::row_stack<float>(&var_1C0);
                                                                                                    nc::NdArray<float, std::__1::allocator<float> >::operator=(&var_A0);
                                                                                                    if (var_218 != 0x0) {
                                                                                                            r0 = var_220;
                                                                                                            if (r0 != 0x0) {
                                                                                                                    operator delete(r0);
                                                                                                            }
                                                                                                    }
                                                                                                    if (var_118 != 0x0) {
                                                                                                            r0 = var_120;
                                                                                                            if (r0 != 0x0) {
                                                                                                                    operator delete(r0);
                                                                                                            }
                                                                                                    }
                                                                                                    if (var_140 != 0x0) {
                                                                                                            r0 = var_148;
                                                                                                            if (r0 != 0x0) {
                                                                                                                    operator delete(r0);
                                                                                                            }
                                                                                                    }
                                                                                            }
                                                                                    }
                                                                            }
                                                                            else {
                                                                                    nc::NdArray<float, std::__1::allocator<float> >::operator=(&var_A0);
                                                                            }
                                                                            if (var_F0 != 0x0) {
                                                                                    r0 = var_F8;
                                                                                    if (r0 != 0x0) {
                                                                                            operator delete(r0);
                                                                                    }
                                                                            }
                                                                            operator delete(r22);
                                                                            if (var_C8 != 0x0) {
                                                                                    r0 = var_D0;
                                                                                    if (r0 != 0x0) {
                                                                                            operator delete(r0);
                                                                                    }
                                                                            }
                                                                    }
                                                                    if ((sign_extend_64(r21[0x17]) & 0xffffffff80000000) != 0x0) {
                                                                            operator delete(*r21);
                                                                    }
                                                                    operator delete(r21);
                                                                    tensorflow::Tensor::~Tensor();
                                                                    r21 = var_88;
                                                                    r19 = var_80;
                                                                    var_80 = 0x0;
                                                                    var_88 = 0x0;
                                                                    if ((sign_extend_64(var_199) & 0xffffffff80000000) != 0x0) {
                                                                            operator delete(var_1B0);
                                                                    }
                                                                    (*(*var_2B0 + 0x8))(var_2B0);
                                                                    r20 = var_190;
                                                                    if (r20 != 0x0) {
                                                                            r0 = var_188;
                                                                            if (r0 != r20) {
                                                                                    do {
                                                                                            r0 = tensorflow::Tensor::~Tensor();
                                                                                    } while (r0 != r20);
                                                                                    r0 = var_190;
                                                                            }
                                                                            else {
                                                                                    r0 = r20;
                                                                            }
                                                                            operator delete(r0);
                                                                    }
                                                                    r20 = var_178;
                                                                    if (r20 != 0x0) {
                                                                            r22 = var_170;
                                                                            if (r22 == r20) {
                                                                                    r0 = r20;
                                                                            }
                                                                            else {
                                                                                    do {
                                                                                            r23 = r22 - 0x38;
                                                                                            tensorflow::Tensor::~Tensor();
                                                                                            if ((sign_extend_64(*(int32_t *)(r22 + 0xffffffffffffffdf)) & 0xffffffff80000000) != 0x0) {
                                                                                                    operator delete(r22[0xfffffffffffffff9]);
                                                                                            }
                                                                                            r22 = r23;
                                                                                    } while (r23 != r20);
                                                                                    r0 = var_178;
                                                                            }
                                                                            operator delete(r0);
                                                                    }
                                                                    juce::String::~String();
                                                                    if (var_80 != 0x0) {
                                                                            r0 = var_88;
                                                                            if (r0 != 0x0) {
                                                                                    operator delete(r0);
                                                                            }
                                                                    }
                                                                    madmom::to_vector(r25);
                                                                    if (r19 != 0x0 && r21 != 0x0) {
                                                                            operator delete(r21);
                                                                    }
                                                                    r0 = juce::String::~String();
                                                                    if (**___stack_chk_guard != var_78) {
                                                                            __stack_chk_fail();
                                                                    }
                                                            }
                                                            else {
                                                                    r21 = var_88;
                                                                    r19 = var_80;
                                                                    var_80 = 0x0;
                                                                    var_88 = 0x0;
                                                                    if ((sign_extend_64(var_199) & 0xffffffff80000000) != 0x0) {
                                                                            operator delete(var_1B0);
                                                                    }
                                                                    (*(*var_2B0 + 0x8))(var_2B0);
                                                                    r20 = var_190;
                                                                    if (r20 != 0x0) {
                                                                            r0 = var_188;
                                                                            if (r0 != r20) {
                                                                                    do {
                                                                                            r0 = tensorflow::Tensor::~Tensor();
                                                                                    } while (r0 != r20);
                                                                                    r0 = var_190;
                                                                            }
                                                                            else {
                                                                                    r0 = r20;
                                                                            }
                                                                            operator delete(r0);
                                                                    }
                                                                    r20 = var_178;
                                                                    if (r20 != 0x0) {
                                                                            r22 = var_170;
                                                                            if (r22 == r20) {
                                                                                    r0 = r20;
                                                                            }
                                                                            else {
                                                                                    do {
                                                                                            r23 = r22 - 0x38;
                                                                                            tensorflow::Tensor::~Tensor();
                                                                                            if ((sign_extend_64(*(int32_t *)(r22 + 0xffffffffffffffdf)) & 0xffffffff80000000) != 0x0) {
                                                                                                    operator delete(r22[0xfffffffffffffff9]);
                                                                                            }
                                                                                            r22 = r23;
                                                                                    } while (r23 != r20);
                                                                                    r0 = var_178;
                                                                            }
                                                                            operator delete(r0);
                                                                    }
                                                                    juce::String::~String();
                                                                    if (var_80 != 0x0) {
                                                                            r0 = var_88;
                                                                            if (r0 != 0x0) {
                                                                                    operator delete(r0);
                                                                            }
                                                                    }
                                                                    madmom::to_vector(r25);
                                                                    if (r19 != 0x0 && r21 != 0x0) {
                                                                            operator delete(r21);
                                                                    }
                                                                    r0 = juce::String::~String();
                                                                    if (**___stack_chk_guard != var_78) {
                                                                            __stack_chk_fail();
                                                                    }
                                                            }
                                                    }
                                                    else {
                                                            if (r26 >= 0x1) {
                                                                    r19 = r26;
                                                                    r0 = tensorflow::TensorShapeBase<tensorflow::TensorShape>::TensorShapeBase(&var_160);
                                                                    r0 = tensorflow::Tensor::Tensor(&var_C0, 0x1);
                                                                    if (var_151 == 0x2) {
                                                                            tensorflow::TensorShapeRep::DestructorOutOfLine();
                                                                    }
                                                                    r0 = tensorflow::Tensor::data();
                                                                    r8 = var_328;
                                                                    asm { sxtw       x8, w8 };
                                                                    if (r26 < 0x10) {
                                                                            r10 = r19 - 0x0;
                                                                            r9 = 0x0 + r8 << 0x2;
                                                                            r8 = var_2E8 + r9;
                                                                            r9 = r22 + r9;
                                                                            s0 = 0x3fe0000000000000;
                                                                            do {
                                                                                    s1 = *(int32_t *)r9;
                                                                                    r9 = r9 + 0x4;
                                                                                    s2 = *(int32_t *)r8;
                                                                                    r8 = r8 + 0x4;
                                                                                    s1 = (s2 + s1) * s0;
                                                                                    *(int32_t *)r0 = s1;
                                                                                    r0 = r0 + 0x4;
                                                                                    r10 = r10 - 0x1;
                                                                            } while (r10 != 0x0);
                                                                    }
                                                                    else {
                                                                            r12 = r8 << 0x2;
                                                                            if (r0 - r12 + var_2E8 >= 0x40) {
                                                                                    if (r0 - r12 + r22 >= 0x40) {
                                                                                            r9 = r19 & 0xfffffff0;
                                                                                            r10 = r0 + r9 * 0x4;
                                                                                            r11 = r0 + 0x20;
                                                                                            r13 = r12 + 0x20;
                                                                                            r12 = r22 + r13;
                                                                                            r13 = var_2E8 + r13;
                                                                                            v0 = 0x3f000000;
                                                                                            r14 = r9;
                                                                                            do {
                                                                                                    q1 = r12[0xfffffffffffffffc];
                                                                                                    q2 = r12[0xfffffffffffffffe];
                                                                                                    q3 = *r12;
                                                                                                    q4 = r12[0x2];
                                                                                                    r12 = r12 + 0x40;
                                                                                                    r13 = r13 + 0x40;
                                                                                                    v1 = (v5 + v1) * v0;
                                                                                                    v2 = (v6 + v2) * v0;
                                                                                                    v3 = (v7 + v3) * v0;
                                                                                                    v4 = (v16 + v4) * v0;
                                                                                                    r11[0xfffffffffffffffc] = q1;
                                                                                                    r11[0xfffffffffffffffe] = q2;
                                                                                                    *r11 = q3;
                                                                                                    r11[0x2] = q4;
                                                                                                    r11 = r11 + 0x40;
                                                                                                    r14 = r14 - 0x10;
                                                                                            } while (r14 != 0x0);
                                                                                            r0 = r10;
                                                                                            if (r9 != r19) {
                                                                                                    r10 = r19 - r9;
                                                                                                    r9 = r9 + r8 << 0x2;
                                                                                                    r8 = var_2E8 + r9;
                                                                                                    r9 = r22 + r9;
                                                                                                    s0 = 0x3fe0000000000000;
                                                                                                    do {
                                                                                                            s1 = *(int32_t *)r9;
                                                                                                            r9 = r9 + 0x4;
                                                                                                            s2 = *(int32_t *)r8;
                                                                                                            r8 = r8 + 0x4;
                                                                                                            s1 = (s2 + s1) * s0;
                                                                                                            *(int32_t *)r0 = s1;
                                                                                                            r0 = r0 + 0x4;
                                                                                                            r10 = r10 - 0x1;
                                                                                                    } while (r10 != 0x0);
                                                                                            }
                                                                                    }
                                                                                    else {
                                                                                            r10 = r19 - 0x0;
                                                                                            r9 = 0x0 + r8 << 0x2;
                                                                                            r8 = var_2E8 + r9;
                                                                                            r9 = r22 + r9;
                                                                                            s0 = 0x3fe0000000000000;
                                                                                            do {
                                                                                                    s1 = *(int32_t *)r9;
                                                                                                    r9 = r9 + 0x4;
                                                                                                    s2 = *(int32_t *)r8;
                                                                                                    r8 = r8 + 0x4;
                                                                                                    s1 = (s2 + s1) * s0;
                                                                                                    *(int32_t *)r0 = s1;
                                                                                                    r0 = r0 + 0x4;
                                                                                                    r10 = r10 - 0x1;
                                                                                            } while (r10 != 0x0);
                                                                                    }
                                                                            }
                                                                            else {
                                                                                    r10 = r19 - 0x0;
                                                                                    r9 = 0x0 + r8 << 0x2;
                                                                                    r8 = var_2E8 + r9;
                                                                                    r9 = r22 + r9;
                                                                                    s0 = 0x3fe0000000000000;
                                                                                    do {
                                                                                            s1 = *(int32_t *)r9;
                                                                                            r9 = r9 + 0x4;
                                                                                            s2 = *(int32_t *)r8;
                                                                                            r8 = r8 + 0x4;
                                                                                            s1 = (s2 + s1) * s0;
                                                                                            *(int32_t *)r0 = s1;
                                                                                            r0 = r0 + 0x4;
                                                                                            r10 = r10 - 0x1;
                                                                                    } while (r10 != 0x0);
                                                                            }
                                                                    }
                                                                    r19 = var_178;
                                                                    r20 = var_170;
                                                                    if (r20 != r19) {
                                                                            r21 = r20 - 0x38;
                                                                            tensorflow::Tensor::~Tensor();
                                                                            if ((sign_extend_64(*(int32_t *)(r20 + 0xffffffffffffffdf)) & 0xffffffff80000000) != 0x0) {
                                                                                    operator delete(r20[0xfffffffffffffff9]);
                                                                            }
                                                                            r20 = r21;
                                                                            if (r21 != r19) {
                                                                                    continue;
                                                                            }
                                                                            break;
                                                                    }
                                                                    var_170 = r19;
                                                                    r0 = std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >::basic_string(&var_160);
                                                                    r21 = &var_160 + 0x18;
                                                                    var_138 = var_B0;
                                                                    if (var_B1 == 0x2) {
                                                                            tensorflow::TensorShapeRep::SlowCopyFrom(r21);
                                                                    }
                                                                    else {
                                                                            *(int128_t *)r21 = var_C0;
                                                                    }
                                                                    r8 = var_A8;
                                                                    var_130 = r8;
                                                                    if (r8 != 0x0) {
                                                                            asm { ldadd      w9, w8, [x8] };
                                                                    }
                                                                    r8 = var_170;
                                                                    if (r8 < var_168) {
                                                                            r8[0x2] = var_150;
                                                                            *(int128_t *)r8 = var_160;
                                                                            var_160 = 0x0;
                                                                            r8[0x5] = var_138;
                                                                            *(int128_t *)(r8 + 0x18) = *(int128_t *)r21;
                                                                            r8[0x6] = var_130;
                                                                            var_170 = r8 + 0x38;
                                                                    }
                                                                    else {
                                                                            r0 = void std::__1::vector<std::__1::pair<std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, tensorflow::Tensor>, std::__1::allocator<std::__1::pair<std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, tensorflow::Tensor> > >::__push_back_slow_path<std::__1::pair<std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, tensorflow::Tensor> >(&var_178);
                                                                    }
                                                                    tensorflow::Tensor::~Tensor();
                                                                    if ((sign_extend_64(var_149) & 0xffffffff80000000) != 0x0) {
                                                                            operator delete(var_160);
                                                                    }
                                                                    r0 = operator new(0x20);
                                                                    var_E8 = r0;
                                                                    *(int128_t *)r0 = *(int128_t *)"StatefulPartitionedCall:1";
                                                                    *(int128_t *)(r0 + 0x9) = *(int128_t *)"artitionedCall:1";
                                                                    r0[0x19] = 0x0;
                                                                    r0 = operator new(0x18);
                                                                    r21 = r0;
                                                                    var_238 = r0;
                                                                    std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >::basic_string(r0);
                                                                    if ((sign_extend_64(var_D1) & 0xffffffff80000000) != 0x0) {
                                                                            operator delete(var_E8);
                                                                    }
                                                                    r0 = operator new(0x18);
                                                                    var_250 = r0;
                                                                    r19 = r0 + 0x18;
                                                                    var_E8 = r0;
                                                                    var_110 = r0;
                                                                    std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >::basic_string(r0);
                                                                    var_248 = r19;
                                                                    r0 = TFWrapper::Model::run(var_2B0, &var_178, &var_250);
                                                                    r19 = var_250;
                                                                    if (r19 != 0x0) {
                                                                            r8 = var_248;
                                                                            if (r8 == r19) {
                                                                                    r0 = r19;
                                                                            }
                                                                            else {
                                                                                    do {
                                                                                            r20 = r8 - 0x18;
                                                                                            if ((sign_extend_64(*(int32_t *)(r8 + 0xffffffffffffffff)) & 0xffffffff80000000) != 0x0) {
                                                                                                    operator delete(r8[0xfffffffffffffffd]);
                                                                                            }
                                                                                            r8 = r20;
                                                                                    } while (r20 != r19);
                                                                                    r0 = var_250;
                                                                            }
                                                                            operator delete(r0);
                                                                    }
                                                                    r0 = var_190;
                                                                    if (var_188 != r0) {
                                                                            tensorflow::TensorShapeBase<tensorflow::TensorShape>::dim_size(r0);
                                                                            tensorflow::TensorShapeBase<tensorflow::TensorShape>::dim_size(var_190);
                                                                            var_D0 = tensorflow::Tensor::data();
                                                                            var_C8 = 0x0;
                                                                            r0 = operator new(0x4);
                                                                            r22 = r0;
                                                                            *(int32_t *)r0 = 0x4;
                                                                            var_268 = r0;
                                                                            s2 = 0x3d4ccccd;
                                                                            madmom::downbeat_tracking(&var_E8, &var_268, s0, s1, 0x3c, 0x64, 0x10, 0x3d4ccccd, 0x1, s3);
                                                                            if (var_328 >= 0x1) {
                                                                                    r8 = var_110;
                                                                                    r10 = r8 - 0x1;
                                                                                    if (r10 >= 0x0) {
                                                                                            r9 = r8 & 0xffffffff;
                                                                                            s0 = var_328 * 0x37be37c6;
                                                                                            r11 = var_F8;
                                                                                            if (r9 < 0x4) {
                                                                                                    r13 = r9 - 0x0;
                                                                                                    r12 = r11 + 0x0;
                                                                                                    do {
                                                                                                            *(int32_t *)r12 = *(int32_t *)r12 + s0;
                                                                                                            r12 = r12 + 0x8;
                                                                                                            r13 = r13 - 0x1;
                                                                                                    } while (r13 != 0x0);
                                                                                            }
                                                                                            else {
                                                                                                    r13 = r9 & 0x3;
                                                                                                    r12 = r9 & 0xfffffffc;
                                                                                                    r14 = r11 + 0x10;
                                                                                                    r15 = r12;
                                                                                                    do {
                                                                                                            s1 = r14[0xfffffffffffffffc];
                                                                                                            s2 = r14[0xfffffffffffffffe];
                                                                                                            s3 = *(int32_t *)r14;
                                                                                                            s4 = r14[0x2];
                                                                                                            s2 = s2 + s0;
                                                                                                            r14[0xfffffffffffffffc] = s1 + s0;
                                                                                                            r14[0xfffffffffffffffe] = s2;
                                                                                                            *(int32_t *)r14 = s3 + s0;
                                                                                                            r14[0x2] = s4 + s0;
                                                                                                            r14 = r14 + 0x20;
                                                                                                            r15 = r15 - 0x4;
                                                                                                    } while (r15 != 0x0);
                                                                                                    if (r13 != 0x0) {
                                                                                                            r13 = r9 - r12;
                                                                                                            r12 = r11 + r12 * 0x8;
                                                                                                            do {
                                                                                                                    *(int32_t *)r12 = *(int32_t *)r12 + s0;
                                                                                                                    r12 = r12 + 0x8;
                                                                                                                    r13 = r13 - 0x1;
                                                                                                            } while (r13 != 0x0);
                                                                                                    }
                                                                                            }
                                                                                            r12 = var_94;
                                                                                            if (r12 >= 0x1) {
                                                                                                    if (r8 >= 0x2) {
                                                                                                            asm { fabd       s2, s0, s1 };
                                                                                                            s1 = r11[0x2];
                                                                                                            asm { fabd       s1, s0, s1 };
                                                                                                            if (s2 > s1) {
                                                                                                                    r12 = 0x0;
                                                                                                                    r11 = r11 + 0x10;
                                                                                                                    r13 = r9 - 0x2;
                                                                                                                    while (r13 != r12) {
                                                                                                                            s2 = *(int32_t *)r11;
                                                                                                                            r11 = r11 + 0x8;
                                                                                                                            asm { fabd       s2, s0, s2 };
                                                                                                                            r12 = r12 + 0x1;
                                                                                                                            bool_557 = s1 > s2;
                                                                                                                            s1 = s2;
                                                                                                                            if (bool_557) {
                                                                                                                                    continue;
                                                                                                                            }
                                                                                                                            r10 = r12;
                                                                                                                            break;
                                                                                                                    }
                                                                                                            }
                                                                                                            else {
                                                                                                                    r10 = 0x0;
                                                                                                            }
                                                                                                    }
                                                                                                    else {
                                                                                                            r10 = 0x0;
                                                                                                    }
                                                                                                    r1 = r10 + 0x1;
                                                                                                    if (r1 < r8) {
                                                                                                            asm { bfi        x1, x9, #0x20, #0x20 };
                                                                                                            nc::NdArray<float, std::__1::allocator<float> >::operator(&var_110, r1);
                                                                                                            r0 = nc::NdArray<float, std::__1::allocator<float> >::operator=(&var_110);
                                                                                                            if (var_140 != 0x0) {
                                                                                                                    r0 = var_148;
                                                                                                                    if (r0 != 0x0) {
                                                                                                                            operator delete(r0);
                                                                                                                    }
                                                                                                            }
                                                                                                            nc::NdArray<float, std::__1::allocator<float> >::NdArray(&var_160);
                                                                                                            nc::NdArray<float, std::__1::allocator<float> >::NdArray(&var_160 + 0x28);
                                                                                                            var_1C0 = &var_160;
                                                                                                            nc::NdArray<float, std::__1::allocator<float> > nc::row_stack<float>(&var_1C0);
                                                                                                            nc::NdArray<float, std::__1::allocator<float> >::operator=(&var_A0);
                                                                                                            if (var_218 != 0x0) {
                                                                                                                    r0 = var_220;
                                                                                                                    if (r0 != 0x0) {
                                                                                                                            operator delete(r0);
                                                                                                                    }
                                                                                                            }
                                                                                                            if (var_118 != 0x0) {
                                                                                                                    r0 = var_120;
                                                                                                                    if (r0 != 0x0) {
                                                                                                                            operator delete(r0);
                                                                                                                    }
                                                                                                            }
                                                                                                            if (var_140 != 0x0) {
                                                                                                                    r0 = var_148;
                                                                                                                    if (r0 != 0x0) {
                                                                                                                            operator delete(r0);
                                                                                                                    }
                                                                                                            }
                                                                                                    }
                                                                                            }
                                                                                            else {
                                                                                                    nc::NdArray<float, std::__1::allocator<float> >::NdArray(&var_160);
                                                                                                    nc::NdArray<float, std::__1::allocator<float> >::NdArray(&var_160 + 0x28);
                                                                                                    var_1C0 = &var_160;
                                                                                                    nc::NdArray<float, std::__1::allocator<float> > nc::row_stack<float>(&var_1C0);
                                                                                                    nc::NdArray<float, std::__1::allocator<float> >::operator=(&var_A0);
                                                                                                    if (var_218 != 0x0) {
                                                                                                            r0 = var_220;
                                                                                                            if (r0 != 0x0) {
                                                                                                                    operator delete(r0);
                                                                                                            }
                                                                                                    }
                                                                                                    if (var_118 != 0x0) {
                                                                                                            r0 = var_120;
                                                                                                            if (r0 != 0x0) {
                                                                                                                    operator delete(r0);
                                                                                                            }
                                                                                                    }
                                                                                                    if (var_140 != 0x0) {
                                                                                                            r0 = var_148;
                                                                                                            if (r0 != 0x0) {
                                                                                                                    operator delete(r0);
                                                                                                            }
                                                                                                    }
                                                                                            }
                                                                                    }
                                                                            }
                                                                            else {
                                                                                    nc::NdArray<float, std::__1::allocator<float> >::operator=(&var_A0);
                                                                            }
                                                                            if (var_F0 != 0x0) {
                                                                                    r0 = var_F8;
                                                                                    if (r0 != 0x0) {
                                                                                            operator delete(r0);
                                                                                    }
                                                                            }
                                                                            operator delete(r22);
                                                                            if (var_C8 != 0x0) {
                                                                                    r0 = var_D0;
                                                                                    if (r0 != 0x0) {
                                                                                            operator delete(r0);
                                                                                    }
                                                                            }
                                                                    }
                                                                    if ((sign_extend_64(r21[0x17]) & 0xffffffff80000000) != 0x0) {
                                                                            operator delete(*r21);
                                                                    }
                                                                    operator delete(r21);
                                                                    tensorflow::Tensor::~Tensor();
                                                            }
                                                            r21 = var_88;
                                                            r19 = var_80;
                                                            var_80 = 0x0;
                                                            var_88 = 0x0;
                                                            if ((sign_extend_64(var_199) & 0xffffffff80000000) != 0x0) {
                                                                    operator delete(var_1B0);
                                                            }
                                                            (*(*var_2B0 + 0x8))(var_2B0);
                                                            r20 = var_190;
                                                            if (r20 != 0x0) {
                                                                    r0 = var_188;
                                                                    if (r0 != r20) {
                                                                            do {
                                                                                    r0 = tensorflow::Tensor::~Tensor();
                                                                            } while (r0 != r20);
                                                                            r0 = var_190;
                                                                    }
                                                                    else {
                                                                            r0 = r20;
                                                                    }
                                                                    operator delete(r0);
                                                            }
                                                            r20 = var_178;
                                                            if (r20 != 0x0) {
                                                                    r22 = var_170;
                                                                    if (r22 == r20) {
                                                                            r0 = r20;
                                                                    }
                                                                    else {
                                                                            do {
                                                                                    r23 = r22 - 0x38;
                                                                                    tensorflow::Tensor::~Tensor();
                                                                                    if ((sign_extend_64(*(int32_t *)(r22 + 0xffffffffffffffdf)) & 0xffffffff80000000) != 0x0) {
                                                                                            operator delete(r22[0xfffffffffffffff9]);
                                                                                    }
                                                                                    r22 = r23;
                                                                            } while (r23 != r20);
                                                                            r0 = var_178;
                                                                    }
                                                                    operator delete(r0);
                                                            }
                                                            juce::String::~String();
                                                            if (var_80 != 0x0) {
                                                                    r0 = var_88;
                                                                    if (r0 != 0x0) {
                                                                            operator delete(r0);
                                                                    }
                                                            }
                                                            madmom::to_vector(r25);
                                                            if (r19 != 0x0 && r21 != 0x0) {
                                                                    operator delete(r21);
                                                            }
                                                            r0 = juce::String::~String();
                                                            if (**___stack_chk_guard != var_78) {
                                                                    __stack_chk_fail();
                                                            }
                                                    }
                                            }
                                    }
                                    else {
                                            var_328 = r21;
                                            var_320 = 0x0;
                                            if (r21 >= 0x1) {
                                                    r19 = r21;
                                                    r0 = tensorflow::TensorShapeBase<tensorflow::TensorShape>::TensorShapeBase(&var_160);
                                                    r0 = tensorflow::Tensor::Tensor(&var_C0, 0x1);
                                                    if (var_151 == 0x2) {
                                                            tensorflow::TensorShapeRep::DestructorOutOfLine();
                                                    }
                                                    r0 = tensorflow::Tensor::data();
                                                    r8 = var_320;
                                                    asm { sxtw       x8, w8 };
                                                    if (r21 < 0x10) {
                                                            r10 = r19 - 0x0;
                                                            r9 = 0x0 + r8 << 0x2;
                                                            r8 = var_2E8 + r9;
                                                            r9 = r22 + r9;
                                                            s0 = 0x3fe0000000000000;
                                                            do {
                                                                    s1 = *(int32_t *)r9;
                                                                    r9 = r9 + 0x4;
                                                                    s2 = *(int32_t *)r8;
                                                                    r8 = r8 + 0x4;
                                                                    s1 = (s2 + s1) * s0;
                                                                    *(int32_t *)r0 = s1;
                                                                    r0 = r0 + 0x4;
                                                                    r10 = r10 - 0x1;
                                                            } while (r10 != 0x0);
                                                    }
                                                    else {
                                                            r12 = r8 << 0x2;
                                                            if (r0 - r12 + var_2E8 >= 0x40) {
                                                                    if (r0 - r12 + r22 >= 0x40) {
                                                                            r9 = r19 & 0xfffffff0;
                                                                            r10 = r0 + r9 * 0x4;
                                                                            r11 = r0 + 0x20;
                                                                            r13 = r12 + 0x20;
                                                                            r12 = r22 + r13;
                                                                            r13 = var_2E8 + r13;
                                                                            v0 = 0x3f000000;
                                                                            r14 = r9;
                                                                            do {
                                                                                    q1 = r12[0xfffffffffffffffc];
                                                                                    q2 = r12[0xfffffffffffffffe];
                                                                                    q3 = *r12;
                                                                                    q4 = r12[0x2];
                                                                                    r12 = r12 + 0x40;
                                                                                    r13 = r13 + 0x40;
                                                                                    v1 = (v5 + v1) * v0;
                                                                                    v2 = (v6 + v2) * v0;
                                                                                    v3 = (v7 + v3) * v0;
                                                                                    v4 = (v16 + v4) * v0;
                                                                                    r11[0xfffffffffffffffc] = q1;
                                                                                    r11[0xfffffffffffffffe] = q2;
                                                                                    *r11 = q3;
                                                                                    r11[0x2] = q4;
                                                                                    r11 = r11 + 0x40;
                                                                                    r14 = r14 - 0x10;
                                                                            } while (r14 != 0x0);
                                                                            r0 = r10;
                                                                            if (r9 != r19) {
                                                                                    r10 = r19 - r9;
                                                                                    r9 = r9 + r8 << 0x2;
                                                                                    r8 = var_2E8 + r9;
                                                                                    r9 = r22 + r9;
                                                                                    s0 = 0x3fe0000000000000;
                                                                                    do {
                                                                                            s1 = *(int32_t *)r9;
                                                                                            r9 = r9 + 0x4;
                                                                                            s2 = *(int32_t *)r8;
                                                                                            r8 = r8 + 0x4;
                                                                                            s1 = (s2 + s1) * s0;
                                                                                            *(int32_t *)r0 = s1;
                                                                                            r0 = r0 + 0x4;
                                                                                            r10 = r10 - 0x1;
                                                                                    } while (r10 != 0x0);
                                                                            }
                                                                    }
                                                                    else {
                                                                            r10 = r19 - 0x0;
                                                                            r9 = 0x0 + r8 << 0x2;
                                                                            r8 = var_2E8 + r9;
                                                                            r9 = r22 + r9;
                                                                            s0 = 0x3fe0000000000000;
                                                                            do {
                                                                                    s1 = *(int32_t *)r9;
                                                                                    r9 = r9 + 0x4;
                                                                                    s2 = *(int32_t *)r8;
                                                                                    r8 = r8 + 0x4;
                                                                                    s1 = (s2 + s1) * s0;
                                                                                    *(int32_t *)r0 = s1;
                                                                                    r0 = r0 + 0x4;
                                                                                    r10 = r10 - 0x1;
                                                                            } while (r10 != 0x0);
                                                                    }
                                                            }
                                                            else {
                                                                    r10 = r19 - 0x0;
                                                                    r9 = 0x0 + r8 << 0x2;
                                                                    r8 = var_2E8 + r9;
                                                                    r9 = r22 + r9;
                                                                    s0 = 0x3fe0000000000000;
                                                                    do {
                                                                            s1 = *(int32_t *)r9;
                                                                            r9 = r9 + 0x4;
                                                                            s2 = *(int32_t *)r8;
                                                                            r8 = r8 + 0x4;
                                                                            s1 = (s2 + s1) * s0;
                                                                            *(int32_t *)r0 = s1;
                                                                            r0 = r0 + 0x4;
                                                                            r10 = r10 - 0x1;
                                                                    } while (r10 != 0x0);
                                                            }
                                                    }
                                                    r19 = var_178;
                                                    r20 = var_170;
                                                    if (r20 != r19) {
                                                            r21 = r20 - 0x38;
                                                            tensorflow::Tensor::~Tensor();
                                                            if ((sign_extend_64(*(int32_t *)(r20 + 0xffffffffffffffdf)) & 0xffffffff80000000) != 0x0) {
                                                                    operator delete(r20[0xfffffffffffffff9]);
                                                            }
                                                            r20 = r21;
                                                            if (r21 != r19) {
                                                                    continue;
                                                            }
                                                            break;
                                                    }
                                                    r21 = r22;
                                                    var_170 = r19;
                                                    r0 = std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >::basic_string(&var_160);
                                                    r22 = &var_160 + 0x18;
                                                    var_138 = var_B0;
                                                    if (var_B1 == 0x2) {
                                                            tensorflow::TensorShapeRep::SlowCopyFrom(r22);
                                                    }
                                                    else {
                                                            *(int128_t *)r22 = var_C0;
                                                    }
                                                    r8 = var_A8;
                                                    var_130 = r8;
                                                    if (r8 != 0x0) {
                                                            asm { ldadd      w9, w8, [x8] };
                                                    }
                                                    r8 = var_170;
                                                    if (r8 < var_168) {
                                                            r8[0x2] = var_150;
                                                            *(int128_t *)r8 = var_160;
                                                            var_150 = 0x0;
                                                            var_160 = 0x0;
                                                            r8[0x5] = var_138;
                                                            *(int128_t *)(r8 + 0x18) = *(int128_t *)r22;
                                                            r8[0x6] = var_130;
                                                            var_170 = r8 + 0x38;
                                                    }
                                                    else {
                                                            r0 = void std::__1::vector<std::__1::pair<std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, tensorflow::Tensor>, std::__1::allocator<std::__1::pair<std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, tensorflow::Tensor> > >::__push_back_slow_path<std::__1::pair<std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, tensorflow::Tensor> >(&var_178);
                                                    }
                                                    tensorflow::Tensor::~Tensor();
                                                    if ((sign_extend_64(var_149) & 0xffffffff80000000) != 0x0) {
                                                            operator delete(var_160);
                                                    }
                                                    r0 = operator new(0x20);
                                                    var_E8 = r0;
                                                    *(int128_t *)r0 = *(int128_t *)"StatefulPartitionedCall:1";
                                                    *(int128_t *)(r0 + 0x9) = *(int128_t *)"artitionedCall:1";
                                                    r0[0x19] = 0x0;
                                                    r0 = operator new(0x18);
                                                    r22 = r0;
                                                    var_238 = r0;
                                                    std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >::basic_string(r0);
                                                    if ((sign_extend_64(var_D1) & 0xffffffff80000000) != 0x0) {
                                                            operator delete(var_E8);
                                                    }
                                                    r0 = operator new(0x18);
                                                    var_210 = r0;
                                                    r19 = r0 + 0x18;
                                                    var_E8 = r0;
                                                    var_110 = r0;
                                                    std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >::basic_string(r0);
                                                    var_208 = r19;
                                                    r0 = TFWrapper::Model::run(var_2B0, &var_178, &var_210);
                                                    r19 = var_210;
                                                    if (r19 != 0x0) {
                                                            r8 = var_208;
                                                            if (r8 == r19) {
                                                                    r0 = r19;
                                                            }
                                                            else {
                                                                    do {
                                                                            r20 = r8 - 0x18;
                                                                            if ((sign_extend_64(*(int32_t *)(r8 + 0xffffffffffffffff)) & 0xffffffff80000000) != 0x0) {
                                                                                    operator delete(r8[0xfffffffffffffffd]);
                                                                            }
                                                                            r8 = r20;
                                                                    } while (r20 != r19);
                                                                    r0 = var_210;
                                                            }
                                                            operator delete(r0);
                                                    }
                                                    r0 = var_190;
                                                    if (var_188 != r0) {
                                                            tensorflow::TensorShapeBase<tensorflow::TensorShape>::dim_size(r0);
                                                            tensorflow::TensorShapeBase<tensorflow::TensorShape>::dim_size(var_190);
                                                            var_D0 = tensorflow::Tensor::data();
                                                            var_C8 = 0x0;
                                                            r0 = operator new(0x4);
                                                            r23 = r0;
                                                            *(int32_t *)r0 = 0x4;
                                                            var_250 = r0;
                                                            s2 = 0x3d4ccccd;
                                                            madmom::downbeat_tracking(&var_E8, &var_250, s0, s1, 0x3c, 0x64, 0x10, 0x3d4ccccd, 0x1, s3);
                                                            r24 = &var_A0;
                                                            if (var_320 >= 0x1) {
                                                                    r8 = var_110;
                                                                    r10 = r8 - 0x1;
                                                                    if (r10 >= 0x0) {
                                                                            r9 = r8 & 0xffffffff;
                                                                            s0 = var_320 * 0x37be37c6;
                                                                            r11 = var_F8;
                                                                            if (r9 < 0x4) {
                                                                                    r13 = r9 - 0x0;
                                                                                    r12 = r11 + 0x0;
                                                                                    do {
                                                                                            s1 = *(int32_t *)r12;
                                                                                            s1 = s1 + s0;
                                                                                            *(int32_t *)r12 = s1;
                                                                                            r12 = r12 + 0x8;
                                                                                            r13 = r13 - 0x1;
                                                                                    } while (r13 != 0x0);
                                                                            }
                                                                            else {
                                                                                    r13 = r9 & 0x3;
                                                                                    r12 = r9 & 0xfffffffc;
                                                                                    r14 = r11 + 0x10;
                                                                                    r15 = r12;
                                                                                    do {
                                                                                            s1 = r14[0xfffffffffffffffc];
                                                                                            s2 = r14[0xfffffffffffffffe];
                                                                                            s3 = *(int32_t *)r14;
                                                                                            s4 = r14[0x2];
                                                                                            s1 = s1 + s0;
                                                                                            s2 = s2 + s0;
                                                                                            s3 = s3 + s0;
                                                                                            r14[0xfffffffffffffffc] = s1;
                                                                                            r14[0xfffffffffffffffe] = s2;
                                                                                            *(int32_t *)r14 = s3;
                                                                                            r14[0x2] = s4 + s0;
                                                                                            r14 = r14 + 0x20;
                                                                                            r15 = r15 - 0x4;
                                                                                    } while (r15 != 0x0);
                                                                                    if (r13 != 0x0) {
                                                                                            r13 = r9 - r12;
                                                                                            r12 = r11 + r12 * 0x8;
                                                                                            do {
                                                                                                    s1 = *(int32_t *)r12;
                                                                                                    s1 = s1 + s0;
                                                                                                    *(int32_t *)r12 = s1;
                                                                                                    r12 = r12 + 0x8;
                                                                                                    r13 = r13 - 0x1;
                                                                                            } while (r13 != 0x0);
                                                                                    }
                                                                            }
                                                                            r12 = var_94;
                                                                            if (r12 >= 0x1) {
                                                                                    if (r8 >= 0x2) {
                                                                                            s0 = *(int32_t *)(var_88 + ((r12 & (r12 - 0x2) / 0x80000000) + (r12 - 0x2)) * 0x4);
                                                                                            asm { fabd       s2, s0, s1 };
                                                                                            s1 = r11[0x2];
                                                                                            asm { fabd       s1, s0, s1 };
                                                                                            if (s2 > s1) {
                                                                                                    r12 = 0x0;
                                                                                                    r11 = r11 + 0x10;
                                                                                                    r13 = r9 - 0x2;
                                                                                                    while (r13 != r12) {
                                                                                                            s2 = *(int32_t *)r11;
                                                                                                            r11 = r11 + 0x8;
                                                                                                            asm { fabd       s2, s0, s2 };
                                                                                                            r12 = r12 + 0x1;
                                                                                                            bool_653 = s1 > s2;
                                                                                                            s1 = s2;
                                                                                                            if (bool_653) {
                                                                                                                    continue;
                                                                                                            }
                                                                                                            r10 = r12;
                                                                                                            break;
                                                                                                    }
                                                                                            }
                                                                                            else {
                                                                                                    r10 = 0x0;
                                                                                            }
                                                                                    }
                                                                                    else {
                                                                                            r10 = 0x0;
                                                                                    }
                                                                                    r1 = r10 + 0x1;
                                                                                    if (r1 < r8) {
                                                                                            asm { bfi        x1, x9, #0x20, #0x20 };
                                                                                            nc::NdArray<float, std::__1::allocator<float> >::operator(&var_110, r1);
                                                                                            r0 = nc::NdArray<float, std::__1::allocator<float> >::operator=(&var_110);
                                                                                            if (var_140 != 0x0) {
                                                                                                    r0 = var_148;
                                                                                                    if (r0 != 0x0) {
                                                                                                            operator delete(r0);
                                                                                                    }
                                                                                            }
                                                                                            r0 = nc::NdArray<float, std::__1::allocator<float> >::NdArray(&var_160);
                                                                                            nc::NdArray<float, std::__1::allocator<float> >::NdArray(&var_160 + 0x28);
                                                                                            var_268 = &var_160;
                                                                                            nc::NdArray<float, std::__1::allocator<float> > nc::row_stack<float>(&var_268);
                                                                                            r0 = nc::NdArray<float, std::__1::allocator<float> >::operator=(&var_A0);
                                                                                            if (var_218 != 0x0) {
                                                                                                    r0 = var_220;
                                                                                                    if (r0 != 0x0) {
                                                                                                            operator delete(r0);
                                                                                                    }
                                                                                            }
                                                                                            var_220 = 0x0;
                                                                                            var_218 = 0x0;
                                                                                            if (var_118 != 0x0) {
                                                                                                    r0 = var_120;
                                                                                                    if (r0 != 0x0) {
                                                                                                            operator delete(r0);
                                                                                                    }
                                                                                            }
                                                                                            var_120 = 0x0;
                                                                                            var_118 = 0x0;
                                                                                            if (var_140 != 0x0) {
                                                                                                    r0 = var_148;
                                                                                                    if (r0 != 0x0) {
                                                                                                            operator delete(r0);
                                                                                                    }
                                                                                            }
                                                                                    }
                                                                            }
                                                                            else {
                                                                                    r0 = nc::NdArray<float, std::__1::allocator<float> >::NdArray(&var_160);
                                                                                    nc::NdArray<float, std::__1::allocator<float> >::NdArray(&var_160 + 0x28);
                                                                                    var_268 = &var_160;
                                                                                    nc::NdArray<float, std::__1::allocator<float> > nc::row_stack<float>(&var_268);
                                                                                    r0 = nc::NdArray<float, std::__1::allocator<float> >::operator=(&var_A0);
                                                                                    if (var_218 != 0x0) {
                                                                                            r0 = var_220;
                                                                                            if (r0 != 0x0) {
                                                                                                    operator delete(r0);
                                                                                            }
                                                                                    }
                                                                                    var_220 = 0x0;
                                                                                    var_218 = 0x0;
                                                                                    if (var_118 != 0x0) {
                                                                                            r0 = var_120;
                                                                                            if (r0 != 0x0) {
                                                                                                    operator delete(r0);
                                                                                            }
                                                                                    }
                                                                                    var_120 = 0x0;
                                                                                    var_118 = 0x0;
                                                                                    if (var_140 != 0x0) {
                                                                                            r0 = var_148;
                                                                                            if (r0 != 0x0) {
                                                                                                    operator delete(r0);
                                                                                            }
                                                                                    }
                                                                            }
                                                                    }
                                                            }
                                                            else {
                                                                    r0 = nc::NdArray<float, std::__1::allocator<float> >::operator=(&var_A0);
                                                            }
                                                            if (var_F0 != 0x0) {
                                                                    r0 = var_F8;
                                                                    if (r0 != 0x0) {
                                                                            operator delete(r0);
                                                                    }
                                                            }
                                                            operator delete(r23);
                                                            if (var_C8 != 0x0) {
                                                                    r0 = var_D0;
                                                                    if (r0 != 0x0) {
                                                                            operator delete(r0);
                                                                    }
                                                            }
                                                    }
                                                    if ((sign_extend_64(r22[0x17]) & 0xffffffff80000000) != 0x0) {
                                                            operator delete(*r22);
                                                    }
                                                    operator delete(r22);
                                                    tensorflow::Tensor::~Tensor();
                                                    r22 = r21;
                                                    if (0x0 >= 0x1) {
                                                            r19 = 0x0;
                                                            r0 = tensorflow::TensorShapeBase<tensorflow::TensorShape>::TensorShapeBase(&var_160);
                                                            r0 = tensorflow::Tensor::Tensor(&var_C0, 0x1);
                                                            if (var_151 == 0x2) {
                                                                    tensorflow::TensorShapeRep::DestructorOutOfLine();
                                                            }
                                                            r26 = 0x0;
                                                            r0 = tensorflow::Tensor::data();
                                                            r8 = var_328;
                                                            asm { sxtw       x8, w8 };
                                                            if (r26 < 0x10) {
                                                                    r10 = r19 - 0x0;
                                                                    r9 = 0x0 + r8 << 0x2;
                                                                    r8 = var_2E8 + r9;
                                                                    r9 = r22 + r9;
                                                                    s0 = 0x3fe0000000000000;
                                                                    do {
                                                                            s1 = *(int32_t *)r9;
                                                                            r9 = r9 + 0x4;
                                                                            s2 = *(int32_t *)r8;
                                                                            r8 = r8 + 0x4;
                                                                            s1 = (s2 + s1) * s0;
                                                                            *(int32_t *)r0 = s1;
                                                                            r0 = r0 + 0x4;
                                                                            r10 = r10 - 0x1;
                                                                    } while (r10 != 0x0);
                                                            }
                                                            else {
                                                                    r12 = r8 << 0x2;
                                                                    if (r0 - r12 + var_2E8 >= 0x40) {
                                                                            if (r0 - r12 + r22 >= 0x40) {
                                                                                    r9 = r19 & 0xfffffff0;
                                                                                    r10 = r0 + r9 * 0x4;
                                                                                    r11 = r0 + 0x20;
                                                                                    r13 = r12 + 0x20;
                                                                                    r12 = r22 + r13;
                                                                                    r13 = var_2E8 + r13;
                                                                                    v0 = 0x3f000000;
                                                                                    r14 = r9;
                                                                                    do {
                                                                                            q1 = r12[0xfffffffffffffffc];
                                                                                            q2 = r12[0xfffffffffffffffe];
                                                                                            q3 = *r12;
                                                                                            q4 = r12[0x2];
                                                                                            r12 = r12 + 0x40;
                                                                                            r13 = r13 + 0x40;
                                                                                            v1 = (v5 + v1) * v0;
                                                                                            v2 = (v6 + v2) * v0;
                                                                                            v3 = (v7 + v3) * v0;
                                                                                            v4 = (v16 + v4) * v0;
                                                                                            r11[0xfffffffffffffffc] = q1;
                                                                                            r11[0xfffffffffffffffe] = q2;
                                                                                            *r11 = q3;
                                                                                            r11[0x2] = q4;
                                                                                            r11 = r11 + 0x40;
                                                                                            r14 = r14 - 0x10;
                                                                                    } while (r14 != 0x0);
                                                                                    r0 = r10;
                                                                                    if (r9 != r19) {
                                                                                            r10 = r19 - r9;
                                                                                            r9 = r9 + r8 << 0x2;
                                                                                            r8 = var_2E8 + r9;
                                                                                            r9 = r22 + r9;
                                                                                            s0 = 0x3fe0000000000000;
                                                                                            do {
                                                                                                    s1 = *(int32_t *)r9;
                                                                                                    r9 = r9 + 0x4;
                                                                                                    s2 = *(int32_t *)r8;
                                                                                                    r8 = r8 + 0x4;
                                                                                                    s1 = (s2 + s1) * s0;
                                                                                                    *(int32_t *)r0 = s1;
                                                                                                    r0 = r0 + 0x4;
                                                                                                    r10 = r10 - 0x1;
                                                                                            } while (r10 != 0x0);
                                                                                    }
                                                                            }
                                                                            else {
                                                                                    r10 = r19 - 0x0;
                                                                                    r9 = 0x0 + r8 << 0x2;
                                                                                    r8 = var_2E8 + r9;
                                                                                    r9 = r22 + r9;
                                                                                    s0 = 0x3fe0000000000000;
                                                                                    do {
                                                                                            s1 = *(int32_t *)r9;
                                                                                            r9 = r9 + 0x4;
                                                                                            s2 = *(int32_t *)r8;
                                                                                            r8 = r8 + 0x4;
                                                                                            s1 = (s2 + s1) * s0;
                                                                                            *(int32_t *)r0 = s1;
                                                                                            r0 = r0 + 0x4;
                                                                                            r10 = r10 - 0x1;
                                                                                    } while (r10 != 0x0);
                                                                            }
                                                                    }
                                                                    else {
                                                                            r10 = r19 - 0x0;
                                                                            r9 = 0x0 + r8 << 0x2;
                                                                            r8 = var_2E8 + r9;
                                                                            r9 = r22 + r9;
                                                                            s0 = 0x3fe0000000000000;
                                                                            do {
                                                                                    s1 = *(int32_t *)r9;
                                                                                    r9 = r9 + 0x4;
                                                                                    s2 = *(int32_t *)r8;
                                                                                    r8 = r8 + 0x4;
                                                                                    s1 = (s2 + s1) * s0;
                                                                                    *(int32_t *)r0 = s1;
                                                                                    r0 = r0 + 0x4;
                                                                                    r10 = r10 - 0x1;
                                                                            } while (r10 != 0x0);
                                                                    }
                                                            }
                                                            r19 = var_178;
                                                            r20 = var_170;
                                                            if (r20 != r19) {
                                                                    r21 = r20 - 0x38;
                                                                    tensorflow::Tensor::~Tensor();
                                                                    if ((sign_extend_64(*(int32_t *)(r20 + 0xffffffffffffffdf)) & 0xffffffff80000000) != 0x0) {
                                                                            operator delete(r20[0xfffffffffffffff9]);
                                                                    }
                                                                    r20 = r21;
                                                                    if (r21 != r19) {
                                                                            continue;
                                                                    }
                                                                    break;
                                                            }
                                                            var_170 = r19;
                                                            r0 = std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >::basic_string(&var_160);
                                                            r21 = &var_160 + 0x18;
                                                            var_138 = var_B0;
                                                            if (var_B1 == 0x2) {
                                                                    tensorflow::TensorShapeRep::SlowCopyFrom(r21);
                                                            }
                                                            else {
                                                                    *(int128_t *)r21 = var_C0;
                                                            }
                                                            r8 = var_A8;
                                                            var_130 = r8;
                                                            if (r8 != 0x0) {
                                                                    asm { ldadd      w9, w8, [x8] };
                                                            }
                                                            r8 = var_170;
                                                            if (r8 < var_168) {
                                                                    r8[0x2] = var_150;
                                                                    *(int128_t *)r8 = var_160;
                                                                    var_160 = 0x0;
                                                                    r8[0x5] = var_138;
                                                                    *(int128_t *)(r8 + 0x18) = *(int128_t *)r21;
                                                                    r8[0x6] = var_130;
                                                                    var_170 = r8 + 0x38;
                                                            }
                                                            else {
                                                                    r0 = void std::__1::vector<std::__1::pair<std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, tensorflow::Tensor>, std::__1::allocator<std::__1::pair<std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, tensorflow::Tensor> > >::__push_back_slow_path<std::__1::pair<std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, tensorflow::Tensor> >(&var_178);
                                                            }
                                                            tensorflow::Tensor::~Tensor();
                                                            if ((sign_extend_64(var_149) & 0xffffffff80000000) != 0x0) {
                                                                    operator delete(var_160);
                                                            }
                                                            r0 = operator new(0x20);
                                                            var_E8 = r0;
                                                            *(int128_t *)r0 = *(int128_t *)"StatefulPartitionedCall:1";
                                                            *(int128_t *)(r0 + 0x9) = *(int128_t *)"artitionedCall:1";
                                                            r0[0x19] = 0x0;
                                                            r0 = operator new(0x18);
                                                            r21 = r0;
                                                            var_238 = r0;
                                                            std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >::basic_string(r0);
                                                            if ((sign_extend_64(var_D1) & 0xffffffff80000000) != 0x0) {
                                                                    operator delete(var_E8);
                                                            }
                                                            r0 = operator new(0x18);
                                                            var_250 = r0;
                                                            r19 = r0 + 0x18;
                                                            var_E8 = r0;
                                                            var_110 = r0;
                                                            std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >::basic_string(r0);
                                                            var_248 = r19;
                                                            r0 = TFWrapper::Model::run(var_2B0, &var_178, &var_250);
                                                            r19 = var_250;
                                                            if (r19 != 0x0) {
                                                                    r8 = var_248;
                                                                    if (r8 == r19) {
                                                                            r0 = r19;
                                                                    }
                                                                    else {
                                                                            do {
                                                                                    r20 = r8 - 0x18;
                                                                                    if ((sign_extend_64(*(int32_t *)(r8 + 0xffffffffffffffff)) & 0xffffffff80000000) != 0x0) {
                                                                                            operator delete(r8[0xfffffffffffffffd]);
                                                                                    }
                                                                                    r8 = r20;
                                                                            } while (r20 != r19);
                                                                            r0 = var_250;
                                                                    }
                                                                    operator delete(r0);
                                                            }
                                                            r0 = var_190;
                                                            if (var_188 != r0) {
                                                                    tensorflow::TensorShapeBase<tensorflow::TensorShape>::dim_size(r0);
                                                                    tensorflow::TensorShapeBase<tensorflow::TensorShape>::dim_size(var_190);
                                                                    var_D0 = tensorflow::Tensor::data();
                                                                    var_C8 = 0x0;
                                                                    r0 = operator new(0x4);
                                                                    r22 = r0;
                                                                    *(int32_t *)r0 = 0x4;
                                                                    var_268 = r0;
                                                                    s2 = 0x3d4ccccd;
                                                                    madmom::downbeat_tracking(&var_E8, &var_268, s0, s1, 0x3c, 0x64, 0x10, 0x3d4ccccd, 0x1, s3);
                                                                    if (var_328 >= 0x1) {
                                                                            r8 = var_110;
                                                                            r10 = r8 - 0x1;
                                                                            if (r10 >= 0x0) {
                                                                                    r9 = r8 & 0xffffffff;
                                                                                    s0 = var_328 * 0x37be37c6;
                                                                                    r11 = var_F8;
                                                                                    if (r9 < 0x4) {
                                                                                            r13 = r9 - 0x0;
                                                                                            r12 = r11 + 0x0;
                                                                                            do {
                                                                                                    *(int32_t *)r12 = *(int32_t *)r12 + s0;
                                                                                                    r12 = r12 + 0x8;
                                                                                                    r13 = r13 - 0x1;
                                                                                            } while (r13 != 0x0);
                                                                                    }
                                                                                    else {
                                                                                            r13 = r9 & 0x3;
                                                                                            r12 = r9 & 0xfffffffc;
                                                                                            r14 = r11 + 0x10;
                                                                                            r15 = r12;
                                                                                            do {
                                                                                                    s1 = r14[0xfffffffffffffffc];
                                                                                                    s2 = r14[0xfffffffffffffffe];
                                                                                                    s3 = *(int32_t *)r14;
                                                                                                    s4 = r14[0x2];
                                                                                                    s2 = s2 + s0;
                                                                                                    r14[0xfffffffffffffffc] = s1 + s0;
                                                                                                    r14[0xfffffffffffffffe] = s2;
                                                                                                    *(int32_t *)r14 = s3 + s0;
                                                                                                    r14[0x2] = s4 + s0;
                                                                                                    r14 = r14 + 0x20;
                                                                                                    r15 = r15 - 0x4;
                                                                                            } while (r15 != 0x0);
                                                                                            if (r13 != 0x0) {
                                                                                                    r13 = r9 - r12;
                                                                                                    r12 = r11 + r12 * 0x8;
                                                                                                    do {
                                                                                                            *(int32_t *)r12 = *(int32_t *)r12 + s0;
                                                                                                            r12 = r12 + 0x8;
                                                                                                            r13 = r13 - 0x1;
                                                                                                    } while (r13 != 0x0);
                                                                                            }
                                                                                    }
                                                                                    r12 = var_94;
                                                                                    if (r12 >= 0x1) {
                                                                                            if (r8 >= 0x2) {
                                                                                                    asm { fabd       s2, s0, s1 };
                                                                                                    s1 = r11[0x2];
                                                                                                    asm { fabd       s1, s0, s1 };
                                                                                                    if (s2 > s1) {
                                                                                                            r12 = 0x0;
                                                                                                            r11 = r11 + 0x10;
                                                                                                            r13 = r9 - 0x2;
                                                                                                            while (r13 != r12) {
                                                                                                                    s2 = *(int32_t *)r11;
                                                                                                                    r11 = r11 + 0x8;
                                                                                                                    asm { fabd       s2, s0, s2 };
                                                                                                                    r12 = r12 + 0x1;
                                                                                                                    bool_729 = s1 > s2;
                                                                                                                    s1 = s2;
                                                                                                                    if (bool_729) {
                                                                                                                            continue;
                                                                                                                    }
                                                                                                                    r10 = r12;
                                                                                                                    break;
                                                                                                            }
                                                                                                    }
                                                                                                    else {
                                                                                                            r10 = 0x0;
                                                                                                    }
                                                                                            }
                                                                                            else {
                                                                                                    r10 = 0x0;
                                                                                            }
                                                                                            r1 = r10 + 0x1;
                                                                                            if (r1 < r8) {
                                                                                                    asm { bfi        x1, x9, #0x20, #0x20 };
                                                                                                    nc::NdArray<float, std::__1::allocator<float> >::operator(&var_110, r1);
                                                                                                    r0 = nc::NdArray<float, std::__1::allocator<float> >::operator=(&var_110);
                                                                                                    if (var_140 != 0x0) {
                                                                                                            r0 = var_148;
                                                                                                            if (r0 != 0x0) {
                                                                                                                    operator delete(r0);
                                                                                                            }
                                                                                                    }
                                                                                                    nc::NdArray<float, std::__1::allocator<float> >::NdArray(&var_160);
                                                                                                    nc::NdArray<float, std::__1::allocator<float> >::NdArray(&var_160 + 0x28);
                                                                                                    var_1C0 = &var_160;
                                                                                                    nc::NdArray<float, std::__1::allocator<float> > nc::row_stack<float>(&var_1C0);
                                                                                                    nc::NdArray<float, std::__1::allocator<float> >::operator=(&var_A0);
                                                                                                    if (var_218 != 0x0) {
                                                                                                            r0 = var_220;
                                                                                                            if (r0 != 0x0) {
                                                                                                                    operator delete(r0);
                                                                                                            }
                                                                                                    }
                                                                                                    if (var_118 != 0x0) {
                                                                                                            r0 = var_120;
                                                                                                            if (r0 != 0x0) {
                                                                                                                    operator delete(r0);
                                                                                                            }
                                                                                                    }
                                                                                                    if (var_140 != 0x0) {
                                                                                                            r0 = var_148;
                                                                                                            if (r0 != 0x0) {
                                                                                                                    operator delete(r0);
                                                                                                            }
                                                                                                    }
                                                                                            }
                                                                                    }
                                                                                    else {
                                                                                            nc::NdArray<float, std::__1::allocator<float> >::NdArray(&var_160);
                                                                                            nc::NdArray<float, std::__1::allocator<float> >::NdArray(&var_160 + 0x28);
                                                                                            var_1C0 = &var_160;
                                                                                            nc::NdArray<float, std::__1::allocator<float> > nc::row_stack<float>(&var_1C0);
                                                                                            nc::NdArray<float, std::__1::allocator<float> >::operator=(&var_A0);
                                                                                            if (var_218 != 0x0) {
                                                                                                    r0 = var_220;
                                                                                                    if (r0 != 0x0) {
                                                                                                            operator delete(r0);
                                                                                                    }
                                                                                            }
                                                                                            if (var_118 != 0x0) {
                                                                                                    r0 = var_120;
                                                                                                    if (r0 != 0x0) {
                                                                                                            operator delete(r0);
                                                                                                    }
                                                                                            }
                                                                                            if (var_140 != 0x0) {
                                                                                                    r0 = var_148;
                                                                                                    if (r0 != 0x0) {
                                                                                                            operator delete(r0);
                                                                                                    }
                                                                                            }
                                                                                    }
                                                                            }
                                                                    }
                                                                    else {
                                                                            nc::NdArray<float, std::__1::allocator<float> >::operator=(&var_A0);
                                                                    }
                                                                    if (var_F0 != 0x0) {
                                                                            r0 = var_F8;
                                                                            if (r0 != 0x0) {
                                                                                    operator delete(r0);
                                                                            }
                                                                    }
                                                                    operator delete(r22);
                                                                    if (var_C8 != 0x0) {
                                                                            r0 = var_D0;
                                                                            if (r0 != 0x0) {
                                                                                    operator delete(r0);
                                                                            }
                                                                    }
                                                            }
                                                            if ((sign_extend_64(r21[0x17]) & 0xffffffff80000000) != 0x0) {
                                                                    operator delete(*r21);
                                                            }
                                                            operator delete(r21);
                                                            tensorflow::Tensor::~Tensor();
                                                            r21 = var_88;
                                                            r19 = var_80;
                                                            var_80 = 0x0;
                                                            var_88 = 0x0;
                                                            if ((sign_extend_64(var_199) & 0xffffffff80000000) != 0x0) {
                                                                    operator delete(var_1B0);
                                                            }
                                                            (*(*var_2B0 + 0x8))(var_2B0);
                                                            r20 = var_190;
                                                            if (r20 != 0x0) {
                                                                    r0 = var_188;
                                                                    if (r0 != r20) {
                                                                            do {
                                                                                    r0 = tensorflow::Tensor::~Tensor();
                                                                            } while (r0 != r20);
                                                                            r0 = var_190;
                                                                    }
                                                                    else {
                                                                            r0 = r20;
                                                                    }
                                                                    operator delete(r0);
                                                            }
                                                            r20 = var_178;
                                                            if (r20 != 0x0) {
                                                                    r22 = var_170;
                                                                    if (r22 == r20) {
                                                                            r0 = r20;
                                                                    }
                                                                    else {
                                                                            do {
                                                                                    r23 = r22 - 0x38;
                                                                                    tensorflow::Tensor::~Tensor();
                                                                                    if ((sign_extend_64(*(int32_t *)(r22 + 0xffffffffffffffdf)) & 0xffffffff80000000) != 0x0) {
                                                                                            operator delete(r22[0xfffffffffffffff9]);
                                                                                    }
                                                                                    r22 = r23;
                                                                            } while (r23 != r20);
                                                                            r0 = var_178;
                                                                    }
                                                                    operator delete(r0);
                                                            }
                                                            juce::String::~String();
                                                            if (var_80 != 0x0) {
                                                                    r0 = var_88;
                                                                    if (r0 != 0x0) {
                                                                            operator delete(r0);
                                                                    }
                                                            }
                                                            madmom::to_vector(r25);
                                                            if (r19 != 0x0 && r21 != 0x0) {
                                                                    operator delete(r21);
                                                            }
                                                            r0 = juce::String::~String();
                                                            if (**___stack_chk_guard != var_78) {
                                                                    __stack_chk_fail();
                                                            }
                                                    }
                                                    else {
                                                            r21 = var_88;
                                                            r19 = var_80;
                                                            var_80 = 0x0;
                                                            var_88 = 0x0;
                                                            if ((sign_extend_64(var_199) & 0xffffffff80000000) != 0x0) {
                                                                    operator delete(var_1B0);
                                                            }
                                                            (*(*var_2B0 + 0x8))(var_2B0);
                                                            r20 = var_190;
                                                            if (r20 != 0x0) {
                                                                    r0 = var_188;
                                                                    if (r0 != r20) {
                                                                            do {
                                                                                    r0 = tensorflow::Tensor::~Tensor();
                                                                            } while (r0 != r20);
                                                                            r0 = var_190;
                                                                    }
                                                                    else {
                                                                            r0 = r20;
                                                                    }
                                                                    operator delete(r0);
                                                            }
                                                            r20 = var_178;
                                                            if (r20 != 0x0) {
                                                                    r22 = var_170;
                                                                    if (r22 == r20) {
                                                                            r0 = r20;
                                                                    }
                                                                    else {
                                                                            do {
                                                                                    r23 = r22 - 0x38;
                                                                                    tensorflow::Tensor::~Tensor();
                                                                                    if ((sign_extend_64(*(int32_t *)(r22 + 0xffffffffffffffdf)) & 0xffffffff80000000) != 0x0) {
                                                                                            operator delete(r22[0xfffffffffffffff9]);
                                                                                    }
                                                                                    r22 = r23;
                                                                            } while (r23 != r20);
                                                                            r0 = var_178;
                                                                    }
                                                                    operator delete(r0);
                                                            }
                                                            juce::String::~String();
                                                            if (var_80 != 0x0) {
                                                                    r0 = var_88;
                                                                    if (r0 != 0x0) {
                                                                            operator delete(r0);
                                                                    }
                                                            }
                                                            madmom::to_vector(r25);
                                                            if (r19 != 0x0 && r21 != 0x0) {
                                                                    operator delete(r21);
                                                            }
                                                            r0 = juce::String::~String();
                                                            if (**___stack_chk_guard != var_78) {
                                                                    __stack_chk_fail();
                                                            }
                                                    }
                                            }
                                            else {
                                                    if (0x0 >= 0x1) {
                                                            r0 = tensorflow::TensorShapeBase<tensorflow::TensorShape>::TensorShapeBase(&var_160);
                                                            r0 = tensorflow::Tensor::Tensor(&var_C0, 0x1);
                                                            if (var_151 == 0x2) {
                                                                    tensorflow::TensorShapeRep::DestructorOutOfLine();
                                                            }
                                                            r26 = 0x0;
                                                            r0 = tensorflow::Tensor::data();
                                                            r8 = var_328;
                                                            asm { sxtw       x8, w8 };
                                                            if (r26 < 0x10) {
                                                                    r10 = 0x0;
                                                                    r9 = 0x0 + r8 << 0x2;
                                                                    r8 = var_2E8 + r9;
                                                                    r9 = r22 + r9;
                                                                    s0 = 0x3fe0000000000000;
                                                                    do {
                                                                            s1 = *(int32_t *)r9;
                                                                            r9 = r9 + 0x4;
                                                                            s2 = *(int32_t *)r8;
                                                                            r8 = r8 + 0x4;
                                                                            s1 = (s2 + s1) * s0;
                                                                            *(int32_t *)r0 = s1;
                                                                            r0 = r0 + 0x4;
                                                                            r10 = r10 - 0x1;
                                                                    } while (r10 != 0x0);
                                                            }
                                                            else {
                                                                    r12 = r8 << 0x2;
                                                                    if (r0 - r12 + var_2E8 >= 0x40) {
                                                                            if (r0 - r12 + r22 >= 0x40) {
                                                                                    r19 = 0x0;
                                                                                    r9 = 0x0 & 0xfffffff0;
                                                                                    r10 = r0 + r9 * 0x4;
                                                                                    r11 = r0 + 0x20;
                                                                                    r13 = r12 + 0x20;
                                                                                    r12 = r22 + r13;
                                                                                    r13 = var_2E8 + r13;
                                                                                    v0 = 0x3f000000;
                                                                                    r14 = r9;
                                                                                    do {
                                                                                            q1 = r12[0xfffffffffffffffc];
                                                                                            q2 = r12[0xfffffffffffffffe];
                                                                                            q3 = *r12;
                                                                                            q4 = r12[0x2];
                                                                                            r12 = r12 + 0x40;
                                                                                            r13 = r13 + 0x40;
                                                                                            v1 = (v5 + v1) * v0;
                                                                                            v2 = (v6 + v2) * v0;
                                                                                            v3 = (v7 + v3) * v0;
                                                                                            v4 = (v16 + v4) * v0;
                                                                                            r11[0xfffffffffffffffc] = q1;
                                                                                            r11[0xfffffffffffffffe] = q2;
                                                                                            *r11 = q3;
                                                                                            r11[0x2] = q4;
                                                                                            r11 = r11 + 0x40;
                                                                                            r14 = r14 - 0x10;
                                                                                    } while (r14 != 0x0);
                                                                                    r0 = r10;
                                                                                    if (r9 != r19) {
                                                                                            r10 = 0x0 - r9;
                                                                                            r9 = r9 + r8 << 0x2;
                                                                                            r8 = var_2E8 + r9;
                                                                                            r9 = r22 + r9;
                                                                                            s0 = 0x3fe0000000000000;
                                                                                            do {
                                                                                                    s1 = *(int32_t *)r9;
                                                                                                    r9 = r9 + 0x4;
                                                                                                    s2 = *(int32_t *)r8;
                                                                                                    r8 = r8 + 0x4;
                                                                                                    s1 = (s2 + s1) * s0;
                                                                                                    *(int32_t *)r0 = s1;
                                                                                                    r0 = r0 + 0x4;
                                                                                                    r10 = r10 - 0x1;
                                                                                            } while (r10 != 0x0);
                                                                                    }
                                                                            }
                                                                            else {
                                                                                    r10 = 0x0;
                                                                                    r9 = 0x0 + r8 << 0x2;
                                                                                    r8 = var_2E8 + r9;
                                                                                    r9 = r22 + r9;
                                                                                    s0 = 0x3fe0000000000000;
                                                                                    do {
                                                                                            s1 = *(int32_t *)r9;
                                                                                            r9 = r9 + 0x4;
                                                                                            s2 = *(int32_t *)r8;
                                                                                            r8 = r8 + 0x4;
                                                                                            s1 = (s2 + s1) * s0;
                                                                                            *(int32_t *)r0 = s1;
                                                                                            r0 = r0 + 0x4;
                                                                                            r10 = r10 - 0x1;
                                                                                    } while (r10 != 0x0);
                                                                            }
                                                                    }
                                                                    else {
                                                                            r10 = 0x0;
                                                                            r9 = 0x0 + r8 << 0x2;
                                                                            r8 = var_2E8 + r9;
                                                                            r9 = r22 + r9;
                                                                            s0 = 0x3fe0000000000000;
                                                                            do {
                                                                                    s1 = *(int32_t *)r9;
                                                                                    r9 = r9 + 0x4;
                                                                                    s2 = *(int32_t *)r8;
                                                                                    r8 = r8 + 0x4;
                                                                                    s1 = (s2 + s1) * s0;
                                                                                    *(int32_t *)r0 = s1;
                                                                                    r0 = r0 + 0x4;
                                                                                    r10 = r10 - 0x1;
                                                                            } while (r10 != 0x0);
                                                                    }
                                                            }
                                                            r19 = var_178;
                                                            r20 = var_170;
                                                            if (r20 != r19) {
                                                                    r21 = r20 - 0x38;
                                                                    tensorflow::Tensor::~Tensor();
                                                                    if ((sign_extend_64(*(int32_t *)(r20 + 0xffffffffffffffdf)) & 0xffffffff80000000) != 0x0) {
                                                                            operator delete(r20[0xfffffffffffffff9]);
                                                                    }
                                                                    r20 = r21;
                                                                    if (r21 != r19) {
                                                                            continue;
                                                                    }
                                                                    break;
                                                            }
                                                            var_170 = r19;
                                                            r0 = std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >::basic_string(&var_160);
                                                            r21 = &var_160 + 0x18;
                                                            var_138 = var_B0;
                                                            if (var_B1 == 0x2) {
                                                                    tensorflow::TensorShapeRep::SlowCopyFrom(r21);
                                                            }
                                                            else {
                                                                    *(int128_t *)r21 = var_C0;
                                                            }
                                                            r8 = var_A8;
                                                            var_130 = r8;
                                                            if (r8 != 0x0) {
                                                                    asm { ldadd      w9, w8, [x8] };
                                                            }
                                                            r8 = var_170;
                                                            if (r8 < var_168) {
                                                                    r8[0x2] = var_150;
                                                                    *(int128_t *)r8 = var_160;
                                                                    var_160 = 0x0;
                                                                    r8[0x5] = var_138;
                                                                    *(int128_t *)(r8 + 0x18) = *(int128_t *)r21;
                                                                    r8[0x6] = var_130;
                                                                    var_170 = r8 + 0x38;
                                                            }
                                                            else {
                                                                    r0 = void std::__1::vector<std::__1::pair<std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, tensorflow::Tensor>, std::__1::allocator<std::__1::pair<std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, tensorflow::Tensor> > >::__push_back_slow_path<std::__1::pair<std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, tensorflow::Tensor> >(&var_178);
                                                            }
                                                            tensorflow::Tensor::~Tensor();
                                                            if ((sign_extend_64(var_149) & 0xffffffff80000000) != 0x0) {
                                                                    operator delete(var_160);
                                                            }
                                                            r0 = operator new(0x20);
                                                            var_E8 = r0;
                                                            *(int128_t *)r0 = *(int128_t *)"StatefulPartitionedCall:1";
                                                            *(int128_t *)(r0 + 0x9) = *(int128_t *)"artitionedCall:1";
                                                            r0[0x19] = 0x0;
                                                            r0 = operator new(0x18);
                                                            r21 = r0;
                                                            var_238 = r0;
                                                            std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >::basic_string(r0);
                                                            if ((sign_extend_64(var_D1) & 0xffffffff80000000) != 0x0) {
                                                                    operator delete(var_E8);
                                                            }
                                                            r0 = operator new(0x18);
                                                            var_250 = r0;
                                                            r19 = r0 + 0x18;
                                                            var_E8 = r0;
                                                            var_110 = r0;
                                                            std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >::basic_string(r0);
                                                            var_248 = r19;
                                                            r0 = TFWrapper::Model::run(var_2B0, &var_178, &var_250);
                                                            r19 = var_250;
                                                            if (r19 != 0x0) {
                                                                    r8 = var_248;
                                                                    if (r8 == r19) {
                                                                            r0 = r19;
                                                                    }
                                                                    else {
                                                                            do {
                                                                                    r20 = r8 - 0x18;
                                                                                    if ((sign_extend_64(*(int32_t *)(r8 + 0xffffffffffffffff)) & 0xffffffff80000000) != 0x0) {
                                                                                            operator delete(r8[0xfffffffffffffffd]);
                                                                                    }
                                                                                    r8 = r20;
                                                                            } while (r20 != r19);
                                                                            r0 = var_250;
                                                                    }
                                                                    operator delete(r0);
                                                            }
                                                            r0 = var_190;
                                                            if (var_188 != r0) {
                                                                    tensorflow::TensorShapeBase<tensorflow::TensorShape>::dim_size(r0);
                                                                    tensorflow::TensorShapeBase<tensorflow::TensorShape>::dim_size(var_190);
                                                                    var_D0 = tensorflow::Tensor::data();
                                                                    var_C8 = 0x0;
                                                                    r0 = operator new(0x4);
                                                                    r22 = r0;
                                                                    *(int32_t *)r0 = 0x4;
                                                                    var_268 = r0;
                                                                    s2 = 0x3d4ccccd;
                                                                    madmom::downbeat_tracking(&var_E8, &var_268, s0, s1, 0x3c, 0x64, 0x10, 0x3d4ccccd, 0x1, s3);
                                                                    if (var_328 >= 0x1) {
                                                                            r8 = var_110;
                                                                            r10 = r8 - 0x1;
                                                                            if (r10 >= 0x0) {
                                                                                    r9 = r8 & 0xffffffff;
                                                                                    s0 = var_328 * 0x37be37c6;
                                                                                    r11 = var_F8;
                                                                                    if (r9 < 0x4) {
                                                                                            r13 = r9 - 0x0;
                                                                                            r12 = r11 + 0x0;
                                                                                            do {
                                                                                                    *(int32_t *)r12 = *(int32_t *)r12 + s0;
                                                                                                    r12 = r12 + 0x8;
                                                                                                    r13 = r13 - 0x1;
                                                                                            } while (r13 != 0x0);
                                                                                    }
                                                                                    else {
                                                                                            r13 = r9 & 0x3;
                                                                                            r12 = r9 & 0xfffffffc;
                                                                                            r14 = r11 + 0x10;
                                                                                            r15 = r12;
                                                                                            do {
                                                                                                    s1 = r14[0xfffffffffffffffc];
                                                                                                    s2 = r14[0xfffffffffffffffe];
                                                                                                    s3 = *(int32_t *)r14;
                                                                                                    s4 = r14[0x2];
                                                                                                    s2 = s2 + s0;
                                                                                                    r14[0xfffffffffffffffc] = s1 + s0;
                                                                                                    r14[0xfffffffffffffffe] = s2;
                                                                                                    *(int32_t *)r14 = s3 + s0;
                                                                                                    r14[0x2] = s4 + s0;
                                                                                                    r14 = r14 + 0x20;
                                                                                                    r15 = r15 - 0x4;
                                                                                            } while (r15 != 0x0);
                                                                                            if (r13 != 0x0) {
                                                                                                    r13 = r9 - r12;
                                                                                                    r12 = r11 + r12 * 0x8;
                                                                                                    do {
                                                                                                            *(int32_t *)r12 = *(int32_t *)r12 + s0;
                                                                                                            r12 = r12 + 0x8;
                                                                                                            r13 = r13 - 0x1;
                                                                                                    } while (r13 != 0x0);
                                                                                            }
                                                                                    }
                                                                                    r12 = var_94;
                                                                                    if (r12 >= 0x1) {
                                                                                            if (r8 >= 0x2) {
                                                                                                    asm { fabd       s2, s0, s1 };
                                                                                                    s1 = r11[0x2];
                                                                                                    asm { fabd       s1, s0, s1 };
                                                                                                    if (s2 > s1) {
                                                                                                            r12 = 0x0;
                                                                                                            r11 = r11 + 0x10;
                                                                                                            r13 = r9 - 0x2;
                                                                                                            while (r13 != r12) {
                                                                                                                    s2 = *(int32_t *)r11;
                                                                                                                    r11 = r11 + 0x8;
                                                                                                                    asm { fabd       s2, s0, s2 };
                                                                                                                    r12 = r12 + 0x1;
                                                                                                                    bool_708 = s1 > s2;
                                                                                                                    s1 = s2;
                                                                                                                    if (bool_708) {
                                                                                                                            continue;
                                                                                                                    }
                                                                                                                    r10 = r12;
                                                                                                                    break;
                                                                                                            }
                                                                                                    }
                                                                                                    else {
                                                                                                            r10 = 0x0;
                                                                                                    }
                                                                                            }
                                                                                            else {
                                                                                                    r10 = 0x0;
                                                                                            }
                                                                                            r1 = r10 + 0x1;
                                                                                            if (r1 < r8) {
                                                                                                    asm { bfi        x1, x9, #0x20, #0x20 };
                                                                                                    nc::NdArray<float, std::__1::allocator<float> >::operator(&var_110, r1);
                                                                                                    r0 = nc::NdArray<float, std::__1::allocator<float> >::operator=(&var_110);
                                                                                                    if (var_140 != 0x0) {
                                                                                                            r0 = var_148;
                                                                                                            if (r0 != 0x0) {
                                                                                                                    operator delete(r0);
                                                                                                            }
                                                                                                    }
                                                                                                    nc::NdArray<float, std::__1::allocator<float> >::NdArray(&var_160);
                                                                                                    nc::NdArray<float, std::__1::allocator<float> >::NdArray(&var_160 + 0x28);
                                                                                                    var_1C0 = &var_160;
                                                                                                    nc::NdArray<float, std::__1::allocator<float> > nc::row_stack<float>(&var_1C0);
                                                                                                    nc::NdArray<float, std::__1::allocator<float> >::operator=(&var_A0);
                                                                                                    if (var_218 != 0x0) {
                                                                                                            r0 = var_220;
                                                                                                            if (r0 != 0x0) {
                                                                                                                    operator delete(r0);
                                                                                                            }
                                                                                                    }
                                                                                                    if (var_118 != 0x0) {
                                                                                                            r0 = var_120;
                                                                                                            if (r0 != 0x0) {
                                                                                                                    operator delete(r0);
                                                                                                            }
                                                                                                    }
                                                                                                    if (var_140 != 0x0) {
                                                                                                            r0 = var_148;
                                                                                                            if (r0 != 0x0) {
                                                                                                                    operator delete(r0);
                                                                                                            }
                                                                                                    }
                                                                                            }
                                                                                    }
                                                                                    else {
                                                                                            nc::NdArray<float, std::__1::allocator<float> >::NdArray(&var_160);
                                                                                            nc::NdArray<float, std::__1::allocator<float> >::NdArray(&var_160 + 0x28);
                                                                                            var_1C0 = &var_160;
                                                                                            nc::NdArray<float, std::__1::allocator<float> > nc::row_stack<float>(&var_1C0);
                                                                                            nc::NdArray<float, std::__1::allocator<float> >::operator=(&var_A0);
                                                                                            if (var_218 != 0x0) {
                                                                                                    r0 = var_220;
                                                                                                    if (r0 != 0x0) {
                                                                                                            operator delete(r0);
                                                                                                    }
                                                                                            }
                                                                                            if (var_118 != 0x0) {
                                                                                                    r0 = var_120;
                                                                                                    if (r0 != 0x0) {
                                                                                                            operator delete(r0);
                                                                                                    }
                                                                                            }
                                                                                            if (var_140 != 0x0) {
                                                                                                    r0 = var_148;
                                                                                                    if (r0 != 0x0) {
                                                                                                            operator delete(r0);
                                                                                                    }
                                                                                            }
                                                                                    }
                                                                            }
                                                                    }
                                                                    else {
                                                                            nc::NdArray<float, std::__1::allocator<float> >::operator=(&var_A0);
                                                                    }
                                                                    if (var_F0 != 0x0) {
                                                                            r0 = var_F8;
                                                                            if (r0 != 0x0) {
                                                                                    operator delete(r0);
                                                                            }
                                                                    }
                                                                    operator delete(r22);
                                                                    if (var_C8 != 0x0) {
                                                                            r0 = var_D0;
                                                                            if (r0 != 0x0) {
                                                                                    operator delete(r0);
                                                                            }
                                                                    }
                                                            }
                                                            if ((sign_extend_64(r21[0x17]) & 0xffffffff80000000) != 0x0) {
                                                                    operator delete(*r21);
                                                            }
                                                            operator delete(r21);
                                                            tensorflow::Tensor::~Tensor();
                                                    }
                                                    r21 = var_88;
                                                    r19 = var_80;
                                                    var_80 = 0x0;
                                                    var_88 = 0x0;
                                                    if ((sign_extend_64(var_199) & 0xffffffff80000000) != 0x0) {
                                                            operator delete(var_1B0);
                                                    }
                                                    (*(*var_2B0 + 0x8))(var_2B0);
                                                    r20 = var_190;
                                                    if (r20 != 0x0) {
                                                            r0 = var_188;
                                                            if (r0 != r20) {
                                                                    do {
                                                                            r0 = tensorflow::Tensor::~Tensor();
                                                                    } while (r0 != r20);
                                                                    r0 = var_190;
                                                            }
                                                            else {
                                                                    r0 = r20;
                                                            }
                                                            operator delete(r0);
                                                    }
                                                    r20 = var_178;
                                                    if (r20 != 0x0) {
                                                            r22 = var_170;
                                                            if (r22 == r20) {
                                                                    r0 = r20;
                                                            }
                                                            else {
                                                                    do {
                                                                            r23 = r22 - 0x38;
                                                                            tensorflow::Tensor::~Tensor();
                                                                            if ((sign_extend_64(*(int32_t *)(r22 + 0xffffffffffffffdf)) & 0xffffffff80000000) != 0x0) {
                                                                                    operator delete(r22[0xfffffffffffffff9]);
                                                                            }
                                                                            r22 = r23;
                                                                    } while (r23 != r20);
                                                                    r0 = var_178;
                                                            }
                                                            operator delete(r0);
                                                    }
                                                    juce::String::~String();
                                                    if (var_80 != 0x0) {
                                                            r0 = var_88;
                                                            if (r0 != 0x0) {
                                                                    operator delete(r0);
                                                            }
                                                    }
                                                    madmom::to_vector(r25);
                                                    if (r19 != 0x0 && r21 != 0x0) {
                                                            operator delete(r21);
                                                    }
                                                    r0 = juce::String::~String();
                                                    if (**___stack_chk_guard != var_78) {
                                                            __stack_chk_fail();
                                                    }
                                            }
                                    }
                            }
                            else {
                                    r20 = std::__1::basic_ostream<char, std::__1::char_traits<char> >& std::__1::__put_character_sequence<char, std::__1::char_traits<char> >(*std::__1::cerr, "\r\x1B[31m", 0x6);
                                    r0 = juce::String::toRawUTF8();
                                    r20 = std::__1::basic_ostream<char, std::__1::char_traits<char> >& std::__1::__put_character_sequence<char, std::__1::char_traits<char> >(std::__1::basic_ostream<char, std::__1::char_traits<char> >& std::__1::__put_character_sequence<char, std::__1::char_traits<char> >(std::__1::basic_ostream<char, std::__1::char_traits<char> >& std::__1::__put_character_sequence<char, std::__1::char_traits<char> >(r20, r0, strlen(r0)), ": models not found", 0x12), "\x1B[0m", 0x4);
                                    std::__1::ios_base::getloc();
                                    r0 = std::__1::locale::use_facet(&var_160);
                                    (*(*r0 + 0x38))();
                                    std::__1::locale::~locale();
                                    std::__1::basic_ostream<char, std::__1::char_traits<char> >::put(r20);
                                    std::__1::basic_ostream<char, std::__1::char_traits<char> >::flush();
                                    r21 = var_88;
                                    r19 = var_80;
                                    var_80 = 0x0;
                                    var_88 = 0x0;
                                    juce::String::~String();
                                    if (var_80 != 0x0) {
                                            r0 = var_88;
                                            if (r0 != 0x0) {
                                                    operator delete(r0);
                                            }
                                    }
                                    madmom::to_vector(r25);
                                    if (r19 != 0x0 && r21 != 0x0) {
                                            operator delete(r21);
                                    }
                                    r0 = juce::String::~String();
                                    if (**___stack_chk_guard != var_78) {
                                            __stack_chk_fail();
                                    }
                            }
                    }
                    else {
                            madmom::to_vector(r25);
                            if (0x0 != 0x0 && 0x0 != 0x0) {
                                    operator delete(0x0);
                            }
                            r0 = juce::String::~String();
                            if (**___stack_chk_guard != var_78) {
                                    __stack_chk_fail();
                            }
                    }
            }
            else {
                    madmom::to_vector(r25);
                    if (0x0 != 0x0 && 0x0 != 0x0) {
                            operator delete(0x0);
                    }
                    r0 = juce::String::~String();
                    if (**___stack_chk_guard != var_78) {
                            __stack_chk_fail();
                    }
            }
    }
    else {
            juce::String::String();
            if (r22 != 0x0 && r21 != 0x0) {
                    if (r20 != 0x0) {
                            r19 = r20;
                    }
                    else {
                            r19 = r22;
                    }
                    r0 = juce::File::File(&var_1E0);
                    if ((juce::File::exists() & 0x1) != 0x0) {
                            var_238 = 0x0;
                            var_230 = 0x0;
                            var_228 = 0x0;
                            var_290 = 0x0;
                            var_288 = 0x0;
                            r20 = operator new(0x10);
                            juce::String::toStdString();
                            r0 = std::__1::thread::hardware_concurrency();
                            r0 = TFWrapper::Model::Model(r20, &var_160, 0x0, r0);
                            if ((sign_extend_64(var_149) & 0xffffffff80000000) != 0x0) {
                                    operator delete(var_160);
                            }
                            std::__1::chrono::system_clock::now();
                            var_C0 = *(int128_t *)"serving_default_fltp:0";
                            r0 = tensorflow::TensorShapeBase<tensorflow::TensorShape>::TensorShapeBase(&var_160);
                            r0 = tensorflow::Tensor::Tensor(&var_110, 0x1);
                            if (var_151 == 0x2) {
                                    tensorflow::TensorShapeRep::DestructorOutOfLine();
                            }
                            r0 = tensorflow::Tensor::data();
                            if (r21 >= 0x1) {
                                    if (r21 < 0x10) {
                                            r9 = r21 - 0x0;
                                            r8 = r19 + (0x0 << 0x2);
                                            r10 = r22 + (0x0 << 0x2);
                                            s0 = 0x3fe0000000000000;
                                            do {
                                                    s1 = *(int32_t *)r10;
                                                    r10 = r10 + 0x4;
                                                    s2 = *(int32_t *)r8;
                                                    r8 = r8 + 0x4;
                                                    s1 = (s2 + s1) * s0;
                                                    *(int32_t *)r0 = s1;
                                                    r0 = r0 + 0x4;
                                                    r9 = r9 - 0x1;
                                            } while (r9 != 0x0);
                                    }
                                    else {
                                            if (r0 - r19 >= 0x40) {
                                                    if (r0 - r22 >= 0x40) {
                                                            r8 = r21 & 0xfffffffffffffff0;
                                                            r9 = r0 + r8 * 0x4;
                                                            r10 = r22 + 0x20;
                                                            r11 = r0 + 0x20;
                                                            r12 = r19 + 0x20;
                                                            v0 = 0x3f000000;
                                                            r13 = r8;
                                                            do {
                                                                    q1 = r10[0xfffffffffffffffc];
                                                                    q2 = r10[0xfffffffffffffffe];
                                                                    q3 = *r10;
                                                                    q4 = r10[0x2];
                                                                    r10 = r10 + 0x40;
                                                                    r12 = r12 + 0x40;
                                                                    v1 = (v5 + v1) * v0;
                                                                    v2 = (v6 + v2) * v0;
                                                                    v3 = (v7 + v3) * v0;
                                                                    v4 = (v16 + v4) * v0;
                                                                    r11[0xfffffffffffffffc] = q1;
                                                                    r11[0xfffffffffffffffe] = q2;
                                                                    *r11 = q3;
                                                                    r11[0x2] = q4;
                                                                    r11 = r11 + 0x40;
                                                                    r13 = r13 - 0x10;
                                                            } while (r13 != 0x0);
                                                            r0 = r9;
                                                            if (r8 != r21) {
                                                                    r9 = r21 - r8;
                                                                    r10 = r8 << 0x2;
                                                                    r8 = r19 + r10;
                                                                    r10 = r22 + r10;
                                                                    s0 = 0x3fe0000000000000;
                                                                    do {
                                                                            s1 = *(int32_t *)r10;
                                                                            r10 = r10 + 0x4;
                                                                            s2 = *(int32_t *)r8;
                                                                            r8 = r8 + 0x4;
                                                                            s1 = (s2 + s1) * s0;
                                                                            *(int32_t *)r0 = s1;
                                                                            r0 = r0 + 0x4;
                                                                            r9 = r9 - 0x1;
                                                                    } while (r9 != 0x0);
                                                            }
                                                    }
                                                    else {
                                                            r9 = r21 - 0x0;
                                                            r8 = r19 + (0x0 << 0x2);
                                                            r10 = r22 + (0x0 << 0x2);
                                                            s0 = 0x3fe0000000000000;
                                                            do {
                                                                    s1 = *(int32_t *)r10;
                                                                    r10 = r10 + 0x4;
                                                                    s2 = *(int32_t *)r8;
                                                                    r8 = r8 + 0x4;
                                                                    s1 = (s2 + s1) * s0;
                                                                    *(int32_t *)r0 = s1;
                                                                    r0 = r0 + 0x4;
                                                                    r9 = r9 - 0x1;
                                                            } while (r9 != 0x0);
                                                    }
                                            }
                                            else {
                                                    r9 = r21 - 0x0;
                                                    r8 = r19 + (0x0 << 0x2);
                                                    r10 = r22 + (0x0 << 0x2);
                                                    s0 = 0x3fe0000000000000;
                                                    do {
                                                            s1 = *(int32_t *)r10;
                                                            r10 = r10 + 0x4;
                                                            s2 = *(int32_t *)r8;
                                                            r8 = r8 + 0x4;
                                                            s1 = (s2 + s1) * s0;
                                                            *(int32_t *)r0 = s1;
                                                            r0 = r0 + 0x4;
                                                            r9 = r9 - 0x1;
                                                    } while (r9 != 0x0);
                                            }
                                    }
                            }
                            r0 = std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >::basic_string(&var_160);
                            r21 = &var_160 + 0x18;
                            var_138 = var_100;
                            if (var_101 == 0x2) {
                                    tensorflow::TensorShapeRep::SlowCopyFrom(r21);
                                    r8 = var_F8;
                                    var_130 = r8;
                                    if (r8 != 0x0) {
                                            asm { ldadd      w9, w8, [x8] };
                                    }
                            }
                            else {
                                    *(int128_t *)r21 = var_110;
                                    r8 = var_F8;
                                    var_130 = r8;
                                    if (r8 != 0x0) {
                                            asm { ldadd      w9, w8, [x8] };
                                    }
                            }
                            r8 = var_230;
                            if (r8 < var_228) {
                                    r8[0x2] = var_150;
                                    *(int128_t *)r8 = var_160;
                                    var_160 = 0x0;
                                    r8[0x5] = var_138;
                                    *(int128_t *)(r8 + 0x18) = *(int128_t *)r21;
                                    r8[0x6] = var_130;
                                    var_230 = r8 + 0x38;
                            }
                            else {
                                    r0 = void std::__1::vector<std::__1::pair<std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, tensorflow::Tensor>, std::__1::allocator<std::__1::pair<std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, tensorflow::Tensor> > >::__push_back_slow_path<std::__1::pair<std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, tensorflow::Tensor> >(&var_238);
                            }
                            tensorflow::Tensor::~Tensor();
                            if ((sign_extend_64(var_149) & 0xffffffff80000000) != 0x0) {
                                    operator delete(var_160);
                            }
                            r0 = operator new(0x20);
                            var_A0 = r0;
                            *(int128_t *)(r24 + 0x8) = 1.23516e-322;
                            *(int128_t *)r0 = *(int128_t *)"StatefulPartitionedCall:1";
                            q0 = *(int128_t *)"artitionedCall:1";
                            *(int128_t *)(r0 + 0x9) = *(int128_t *)"artitionedCall:1";
                            r0[0x19] = 0x0;
                            r0 = operator new(0x18);
                            r21 = r0;
                            std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >::basic_string(r0);
                            if ((sign_extend_64(var_89) & 0xffffffff80000000) != 0x0) {
                                    operator delete(var_A0);
                            }
                            r0 = operator new(0x18);
                            var_190 = r0;
                            r19 = r0 + 0x18;
                            var_A0 = r0;
                            var_1B0 = r0;
                            std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >::basic_string(r0);
                            var_188 = r19;
                            r0 = TFWrapper::Model::run(r20, &var_238, &var_190);
                            r19 = var_190;
                            if (r19 != 0x0) {
                                    r8 = var_188;
                                    if (r8 == r19) {
                                            r0 = r19;
                                    }
                                    else {
                                            do {
                                                    r22 = r8 - 0x18;
                                                    if ((sign_extend_64(*(int32_t *)(r8 + 0xffffffffffffffff)) & 0xffffffff80000000) != 0x0) {
                                                            operator delete(r8[0xfffffffffffffffd]);
                                                    }
                                                    r8 = r22;
                                            } while (r22 != r19);
                                            r0 = var_190;
                                    }
                                    operator delete(r0);
                            }
                            r0 = var_290;
                            if (var_288 != r0) {
                                    tensorflow::TensorShapeBase<tensorflow::TensorShape>::dim_size(r0);
                                    tensorflow::TensorShapeBase<tensorflow::TensorShape>::dim_size(var_290);
                                    var_148 = tensorflow::Tensor::data();
                                    r0 = operator new(0x4);
                                    r23 = r0;
                                    *(int32_t *)r0 = 0x4;
                                    var_1B0 = r0;
                                    r0 = madmom::downbeat_tracking(&var_160, &var_1B0, s0, s1, 0x3c, 0x64, 0x10, 0x3d4ccccd, 0x1, s3);
                                    r24 = var_9C;
                                    d0 = var_94;
                                    var_2B0 = q0;
                                    r22 = var_88;
                                    r19 = var_80;
                                    operator delete(r23);
                                    if (0x0 != 0x0) {
                                            r0 = var_148;
                                            if (r0 != 0x0) {
                                                    operator delete(r0);
                                            }
                                    }
                            }
                            else {
                                    r19 = 0x0;
                                    r22 = 0x0;
                                    r24 = 0x200000000;
                            }
                            if ((sign_extend_64(r21[0x17]) & 0xffffffff80000000) != 0x0) {
                                    operator delete(*r21);
                            }
                            operator delete(r21);
                            tensorflow::Tensor::~Tensor();
                            if ((sign_extend_64(var_A9) & 0xffffffff80000000) != 0x0) {
                                    operator delete(var_C0);
                            }
                            (*(*r20 + 0x8))(r20);
                            r20 = var_290;
                            if (r20 != 0x0) {
                                    r0 = var_288;
                                    if (r0 != r20) {
                                            do {
                                                    r0 = tensorflow::Tensor::~Tensor();
                                            } while (r0 != r20);
                                            r0 = var_290;
                                    }
                                    else {
                                            r0 = r20;
                                    }
                                    operator delete(r0);
                            }
                            r20 = var_238;
                            if (r20 != 0x0) {
                                    r21 = var_230;
                                    if (r21 == r20) {
                                            r0 = r20;
                                    }
                                    else {
                                            do {
                                                    r23 = r21 - 0x38;
                                                    tensorflow::Tensor::~Tensor();
                                                    if ((sign_extend_64(*(int32_t *)(r21 + 0xffffffffffffffdf)) & 0xffffffff80000000) != 0x0) {
                                                            operator delete(r21[0xfffffffffffffff9]);
                                                    }
                                                    r21 = r23;
                                            } while (r23 != r20);
                                            r0 = var_238;
                                    }
                                    operator delete(r0);
                            }
                    }
                    else {
                            r20 = std::__1::basic_ostream<char, std::__1::char_traits<char> >& std::__1::__put_character_sequence<char, std::__1::char_traits<char> >(*std::__1::cerr, "\r\x1B[31m", 0x6);
                            r0 = juce::String::toRawUTF8();
                            r20 = std::__1::basic_ostream<char, std::__1::char_traits<char> >& std::__1::__put_character_sequence<char, std::__1::char_traits<char> >(std::__1::basic_ostream<char, std::__1::char_traits<char> >& std::__1::__put_character_sequence<char, std::__1::char_traits<char> >(std::__1::basic_ostream<char, std::__1::char_traits<char> >& std::__1::__put_character_sequence<char, std::__1::char_traits<char> >(r20, r0, strlen(r0)), ": models not found", 0x12), "\x1B[0m", 0x4);
                            std::__1::ios_base::getloc();
                            r0 = std::__1::locale::use_facet(&var_160);
                            (*(*r0 + 0x38))();
                            std::__1::locale::~locale();
                            std::__1::basic_ostream<char, std::__1::char_traits<char> >::put(r20);
                            std::__1::basic_ostream<char, std::__1::char_traits<char> >::flush();
                            r22 = 0x0;
                            r19 = 0x0;
                    }
                    juce::String::~String();
            }
            else {
                    r22 = 0x0;
                    r19 = 0x0;
            }
            madmom::to_vector(r25);
            if (r19 != 0x0 && r22 != 0x0) {
                    operator delete(r22);
            }
            r0 = juce::String::~String();
            if (**___stack_chk_guard != var_78) {
                    __stack_chk_fail();
            }
    }
    return r0;
