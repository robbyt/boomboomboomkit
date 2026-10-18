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
    r31 = r31 + 0xffffffffffffff90 - 0x250;
    r22 = arg3;
    var_2B0 = arg2;
    var_298 = arg1;
    var_70 = **___stack_chk_guard;
    var_280 = r8;
    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::basic_json(r8, 0x0, 0x0);
    var_1F0 = 0x0;
    var_1E8 = 0x0;
    r21 = *arg0;
    r20 = arg0[0x1];
    r19 = r20 - r21;
    if (r19 != 0x0) {
            if ((r19 & 0xffffffff80000000) == 0x0) {
                    r1 = operator new(r19);
                    var_1F0 = r1;
                    r9 = r19 - 0x8;
                    if (r9 >= 0x38) {
                            r8 = r1;
                            if (r1 - r21 >= 0x40) {
                                    r9 = (r9 >> 0x3) + 0x1;
                                    r10 = r9 & 0x3ffffffffffffff8;
                                    r11 = r21 + (r10 << 0x3);
                                    r8 = r1 + (r10 << 0x3);
                                    r12 = r21 + 0x20;
                                    r13 = r1 + 0x20;
                                    r14 = r10;
                                    do {
                                            q0 = r12[0xfffffffffffffffc];
                                            q1 = r12[0xfffffffffffffffe];
                                            q2 = *r12;
                                            q3 = r12[0x2];
                                            r12 = r12 + 0x40;
                                            r13[0xfffffffffffffffc] = q0;
                                            r13[0xfffffffffffffffe] = q1;
                                            *r13 = q2;
                                            r13[0x2] = q3;
                                            r13 = r13 + 0x40;
                                            r14 = r14 - 0x8;
                                    } while (r14 != 0x0);
                                    r21 = r11;
                                    if (r9 != r10) {
                                            do {
                                                    r9 = *r21;
                                                    r21 = r21 + 0x8;
                                                    *r8 = r9;
                                                    r8 = r8 + 0x8;
                                            } while (r21 != r20);
                                    }
                            }
                            else {
                                    do {
                                            r9 = *r21;
                                            r21 = r21 + 0x8;
                                            *r8 = r9;
                                            r8 = r8 + 0x8;
                                    } while (r21 != r20);
                            }
                    }
                    else {
                            r8 = r1;
                            do {
                                    r9 = *r21;
                                    r21 = r21 + 0x8;
                                    *r8 = r9;
                                    r8 = r8 + 0x8;
                            } while (r21 != r20);
                    }
                    var_1E8 = r8;
                    r8 = r8 - r1;
                    r21 = var_280;
                    var_29C = r22;
                    if (r8 >= 0x9) {
                            s0 = *(int32_t *)r1;
                            s8 = s0 - r1[0x2];
                            s9 = s0 + s8;
                            if (s9 >= 0x0) {
                                    r19 = r1[0x1];
                                    while (true) {
                                            r8 = r19 - 0x1;
                                            if (r19 >= 0x2) {
                                                    r19 = r8;
                                            }
                                            else {
                                                    r19 = r22;
                                            }
                                            r8 = s9;
                                            asm { bfi        x8, x19, #0x20, #0x20 };
                                            var_E8 = r8;
                                            r0 = std::__1::vector<std::__1::pair<float, int>, std::__1::allocator<std::__1::pair<float, int> > >::insert(&var_1F0, r1);
                                            s9 = s9 + s8;
                                            if (s9 < 0x0) {
                                                    break;
                                            }
                                            r1 = var_1F0;
                                    }
                                    r1 = var_1F0;
                                    r8 = var_1E8 - r1;
                            }
                    }
                    var_2A8 = SAR(r8, 0x3);
                    if (SAR(r8, 0x3) != 0x0) {
                            r23 = 0x0;
                            r9 = var_2B0;
                            asm { sxtw       x9, w9 };
                            var_248 = r9;
                            var_290 = var_2A8 - 0x1;
                            var_288 = &var_200 + 0x8;
                            var_220 = &var_118 + 0x20;
                            var_230 = &var_118 + 0x18;
                            r26 = &var_E8 + 0x18;
                            var_228 = &var_148 + 0x20;
                            var_240 = &var_148 + 0x18;
                            var_218 = &var_E8 + 0x30;
                            var_238 = &var_178 + 0x20;
                            var_250 = &var_178 + 0x18;
                            r22 = &var_E8 + 0x48;
                            var_260 = &var_1A8 + 0x18;
                            var_258 = &var_1A8 + 0x20;
                            r28 = &var_E8 + 0x60;
                            var_270 = &var_1D8 + 0x18;
                            var_268 = &var_1D8 + 0x20;
                            asm { ubfx       x8, x8, #0x3, #0x20 };
                            var_278 = r8 - 0x1;
                            r27 = 0x4;
                            while (true) {
                                    r20 = sign_extend_64(*(int32_t *)(r1 + r27));
                                    r8 = 0x447a0000;
                                    asm { fcvtas     x25, s0 };
                                    if (r23 != 0x0) {
                                            r24 = 0x5;
                                            r0 = nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::operator[](r21);
                                            r19 = r0;
                                            r0 = nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >& nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::operator[]<char const>(r0);
                                            var_E8 = 0x0;
                                            r0 = void nlohmann::detail::from_json<nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >, int, 0>(r0, &var_E8);
                                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::json_value::destroy(var_288);
                                            r8 = 0x42c80000;
                                            asm { fcvtzs     w8, s0 };
                                            asm { sxtw       x8, w8 };
                                            var_1F8 = r8;
                                            r0 = nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >& nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::operator[]<char const>(r19);
                                            *(int8_t *)r0 = r24;
                                            r0[0x1] = var_1F8;
                                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                            r8 = var_290;
                                            r21 = var_280;
                                            if (r8 == r23) {
                                                    r0 = nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >& nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::operator[]<char const>(r19);
                                                    var_E8 = 0x0;
                                                    r0 = void nlohmann::detail::from_json<nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >, float, 0>(r0, &var_E8);
                                            }
                                    }
                                    var_118 = 0x0;
                                    void nlohmann::detail::external_constructor<(&var_118, "index");
                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::json_value::destroy(var_220);
                                    r0 = nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::basic_json(&var_E8, &var_118, 0x2);
                                    var_148 = 0x0;
                                    void nlohmann::detail::external_constructor<(&var_148, "bpm");
                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::json_value::destroy(var_228);
                                    asm { fcvtzs     w8, s8 };
                                    asm { sxtw       x8, w8 };
                                    r0 = nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::basic_json(r26, &var_148, 0x2);
                                    var_178 = 0x0;
                                    void nlohmann::detail::external_constructor<(&var_178, "pos");
                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::json_value::destroy(var_238);
                                    asm { fcvtzs     w8, s0 };
                                    asm { sxtw       x8, w8 };
                                    r0 = nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::basic_json(var_218, &var_178, 0x2);
                                    var_1A8 = 0x0;
                                    void nlohmann::detail::external_constructor<(&var_1A8, "msec");
                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::json_value::destroy(var_258);
                                    r0 = nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::basic_json(r22, &var_1A8, 0x2);
                                    var_1D8 = 0x0;
                                    void nlohmann::detail::external_constructor<(&var_1D8, "numBar");
                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::json_value::destroy(var_268);
                                    r0 = nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::basic_json(r28, &var_1D8, 0x2);
                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::push_back(r21);
                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                    if (var_278 == r23) {
                                            break;
                                    }
                                    r1 = var_1F0;
                                    r27 = r27 + 0x8;
                                    r23 = r23 + 0x1;
                            }
                    }
                    r8 = *(int8_t *)r21;
                    if (r8 != 0x1) {
                            if (r8 == 0x2) {
                                    r9 = r21[0x1];
                                    if (SAR(r9[0x1] - *r9, 0x4) <= 0x1) {
                                            r0 = var_1F0;
                                            if (r0 != 0x0) {
                                                    r0 = operator delete(r0);
                                            }
                                            if (**___stack_chk_guard != var_70) {
                                                    __stack_chk_fail();
                                            }
                                    }
                                    else {
                                            var_E8 = r21;
                                            nlohmann::detail::iter_impl<nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > > >::operator*();
                                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::basic_json(&decomp_var_210);
                                            r0 = nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >& nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::operator[]<char const>(&decomp_var_210);
                                            var_E8 = 0x0;
                                            void nlohmann::detail::from_json<nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >, int, 0>(r0, &var_E8);
                                            r28 = sign_extend_64(var_E8);
                                            r0 = nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >& nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::operator[]<char const>(&decomp_var_210);
                                            var_E8 = 0x0;
                                            void nlohmann::detail::from_json<nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >, int, 0>(r0, &var_E8);
                                            var_218 = sign_extend_64(var_E8);
                                            r0 = nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >& nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::operator[]<char const>(&decomp_var_210);
                                            var_E8 = 0x0;
                                            void nlohmann::detail::get_arithmetic_value<nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >, long long, 0>(r0, &var_E8);
                                            r19 = var_E8;
                                            r0 = nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >& nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::operator[]<char const>(&decomp_var_210);
                                            var_E8 = 0x0;
                                            void nlohmann::detail::from_json<nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >, int, 0>(r0, &var_E8);
                                            r27 = var_E8;
                                            r0 = nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::operator[](r21);
                                            r0 = nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >& nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::operator[]<char const>(r0);
                                            var_E8 = 0x0;
                                            r0 = void nlohmann::detail::get_arithmetic_value<nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >, long long, 0>(r0, &var_E8);
                                            var_220 = r19 - var_E8;
                                            r23 = r19 + (r19 - var_E8);
                                            if (r23 < var_298) {
                                                    var_238 = &var_118 + 0x18;
                                                    r20 = &var_E8 + 0x18;
                                                    var_230 = &var_148 + 0x20;
                                                    var_228 = &var_118 + 0x20;
                                                    r24 = &var_E8 + 0x30;
                                                    var_248 = &var_148 + 0x18;
                                                    var_240 = &var_178 + 0x20;
                                                    r25 = &var_E8 + 0x48;
                                                    r19 = &var_1A8 + 0x20;
                                                    var_258 = &var_1A8 + 0x18;
                                                    var_250 = &var_178 + 0x18;
                                                    r26 = &var_E8 + 0x60;
                                                    r22 = &var_1D8 + 0x20;
                                                    var_260 = &var_1D8 + 0x18;
                                                    d8 = 0x3ff0000000000000 / var_2B0;
                                                    r28 = r28 + 0x1;
                                                    do {
                                                            var_118 = 0x0;
                                                            void nlohmann::detail::external_constructor<(&var_118, "index");
                                                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::json_value::destroy(var_228);
                                                            r0 = nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::basic_json(&var_E8, &var_118, 0x2);
                                                            var_148 = 0x0;
                                                            void nlohmann::detail::external_constructor<(&var_148, "bpm");
                                                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::json_value::destroy(var_230);
                                                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::basic_json(r20, &var_148, 0x2);
                                                            var_178 = 0x0;
                                                            void nlohmann::detail::external_constructor<(&var_178, "pos");
                                                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::json_value::destroy(var_240);
                                                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::basic_json(r24, &var_178, 0x2);
                                                            var_1A8 = 0x0;
                                                            void nlohmann::detail::external_constructor<(&var_1A8, "msec");
                                                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::json_value::destroy(r19);
                                                            asm { fcvtas     x8, d0 };
                                                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::basic_json(r25, &var_1A8, 0x2);
                                                            var_1D8 = 0x0;
                                                            void nlohmann::detail::external_constructor<(&var_1D8, "numBar");
                                                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::json_value::destroy(r22);
                                                            asm { sxtw       x8, w8 };
                                                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::basic_json(r26, &var_1D8, 0x2);
                                                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::push_back(var_280);
                                                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                                            r28 = r28 + 0x1;
                                                            r27 = r27 + 0x1;
                                                            r23 = r23 + var_220;
                                                    } while (r23 < var_298);
                                            }
                                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                            r0 = var_1F0;
                                            if (r0 != 0x0) {
                                                    r0 = operator delete(r0);
                                            }
                                            if (**___stack_chk_guard != var_70) {
                                                    __stack_chk_fail();
                                            }
                                    }
                            }
                            else {
                                    r0 = var_1F0;
                                    if (r0 != 0x0) {
                                            r0 = operator delete(r0);
                                    }
                                    if (**___stack_chk_guard != var_70) {
                                            __stack_chk_fail();
                                    }
                            }
                    }
                    else {
                            r9 = r21[0x1];
                            if ((SAR(r9[0x1] - *r9, 0x3)) * 0xcccccccccccccccd >= 0x1) {
                                    var_E8 = r21;
                                    nlohmann::detail::iter_impl<nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > > >::operator*();
                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::basic_json(&decomp_var_210);
                                    r0 = nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >& nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::operator[]<char const>(&decomp_var_210);
                                    var_E8 = 0x0;
                                    void nlohmann::detail::from_json<nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >, int, 0>(r0, &var_E8);
                                    r28 = sign_extend_64(var_E8);
                                    r0 = nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >& nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::operator[]<char const>(&decomp_var_210);
                                    var_E8 = 0x0;
                                    void nlohmann::detail::from_json<nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >, int, 0>(r0, &var_E8);
                                    var_218 = sign_extend_64(var_E8);
                                    r0 = nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >& nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::operator[]<char const>(&decomp_var_210);
                                    var_E8 = 0x0;
                                    void nlohmann::detail::get_arithmetic_value<nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >, long long, 0>(r0, &var_E8);
                                    r19 = var_E8;
                                    r0 = nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >& nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::operator[]<char const>(&decomp_var_210);
                                    var_E8 = 0x0;
                                    void nlohmann::detail::from_json<nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >, int, 0>(r0, &var_E8);
                                    r27 = var_E8;
                                    r0 = nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::operator[](r21);
                                    r0 = nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >& nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::operator[]<char const>(r0);
                                    var_E8 = 0x0;
                                    r0 = void nlohmann::detail::get_arithmetic_value<nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >, long long, 0>(r0, &var_E8);
                                    var_220 = r19 - var_E8;
                                    r23 = r19 + (r19 - var_E8);
                                    if (r23 < var_298) {
                                            var_238 = &var_118 + 0x18;
                                            r20 = &var_E8 + 0x18;
                                            var_230 = &var_148 + 0x20;
                                            var_228 = &var_118 + 0x20;
                                            r24 = &var_E8 + 0x30;
                                            var_248 = &var_148 + 0x18;
                                            var_240 = &var_178 + 0x20;
                                            r25 = &var_E8 + 0x48;
                                            r19 = &var_1A8 + 0x20;
                                            var_258 = &var_1A8 + 0x18;
                                            var_250 = &var_178 + 0x18;
                                            r26 = &var_E8 + 0x60;
                                            r22 = &var_1D8 + 0x20;
                                            var_260 = &var_1D8 + 0x18;
                                            d8 = 0x3ff0000000000000 / var_2B0;
                                            r28 = r28 + 0x1;
                                            do {
                                                    var_118 = 0x0;
                                                    void nlohmann::detail::external_constructor<(&var_118, "index");
                                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::json_value::destroy(var_228);
                                                    r0 = nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::basic_json(&var_E8, &var_118, 0x2);
                                                    var_148 = 0x0;
                                                    void nlohmann::detail::external_constructor<(&var_148, "bpm");
                                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::json_value::destroy(var_230);
                                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::basic_json(r20, &var_148, 0x2);
                                                    var_178 = 0x0;
                                                    void nlohmann::detail::external_constructor<(&var_178, "pos");
                                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::json_value::destroy(var_240);
                                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::basic_json(r24, &var_178, 0x2);
                                                    var_1A8 = 0x0;
                                                    void nlohmann::detail::external_constructor<(&var_1A8, "msec");
                                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::json_value::destroy(r19);
                                                    asm { fcvtas     x8, d0 };
                                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::basic_json(r25, &var_1A8, 0x2);
                                                    var_1D8 = 0x0;
                                                    void nlohmann::detail::external_constructor<(&var_1D8, "numBar");
                                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::json_value::destroy(r22);
                                                    asm { sxtw       x8, w8 };
                                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::basic_json(r26, &var_1D8, 0x2);
                                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::push_back(var_280);
                                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                                    r28 = r28 + 0x1;
                                                    r27 = r27 + 0x1;
                                                    r23 = r23 + var_220;
                                            } while (r23 < var_298);
                                    }
                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                    r0 = var_1F0;
                                    if (r0 != 0x0) {
                                            r0 = operator delete(r0);
                                    }
                                    if (**___stack_chk_guard != var_70) {
                                            __stack_chk_fail();
                                    }
                            }
                            else {
                                    r0 = var_1F0;
                                    if (r0 != 0x0) {
                                            r0 = operator delete(r0);
                                    }
                                    if (**___stack_chk_guard != var_70) {
                                            __stack_chk_fail();
                                    }
                            }
                    }
            }
            else {
                    r0 = std::__1::vector<std::__1::pair<float, int>, std::__1::allocator<std::__1::pair<float, int> > >::__throw_length_error[abi:v15006]();
            }
    }
    else {
            r1 = 0x0;
            r8 = 0x0;
            r21 = var_280;
            var_29C = r22;
            if (r8 >= 0x9) {
                    r1 = 0x0;
                    s0 = *(int32_t *)0x0;
                    s8 = s0 - *(int32_t *)0x8;
                    s9 = s0 + s8;
                    if (s9 >= 0x0) {
                            r1 = 0x0;
                            r19 = *(int32_t *)0x4;
                            while (true) {
                                    r8 = r19 - 0x1;
                                    if (r19 >= 0x2) {
                                            r19 = r8;
                                    }
                                    else {
                                            r19 = r22;
                                    }
                                    r8 = s9;
                                    asm { bfi        x8, x19, #0x20, #0x20 };
                                    var_E8 = r8;
                                    r0 = std::__1::vector<std::__1::pair<float, int>, std::__1::allocator<std::__1::pair<float, int> > >::insert(&var_1F0, r1);
                                    s9 = s9 + s8;
                                    if (s9 < 0x0) {
                                            break;
                                    }
                                    r1 = var_1F0;
                            }
                            r1 = var_1F0;
                            r8 = var_1E8 - r1;
                    }
            }
            var_2A8 = SAR(r8, 0x3);
            if (SAR(r8, 0x3) != 0x0) {
                    r23 = 0x0;
                    r9 = var_2B0;
                    asm { sxtw       x9, w9 };
                    var_248 = r9;
                    var_290 = var_2A8 - 0x1;
                    var_288 = &var_200 + 0x8;
                    var_220 = &var_118 + 0x20;
                    var_230 = &var_118 + 0x18;
                    r26 = &var_E8 + 0x18;
                    var_228 = &var_148 + 0x20;
                    var_240 = &var_148 + 0x18;
                    var_218 = &var_E8 + 0x30;
                    var_238 = &var_178 + 0x20;
                    var_250 = &var_178 + 0x18;
                    r22 = &var_E8 + 0x48;
                    var_260 = &var_1A8 + 0x18;
                    var_258 = &var_1A8 + 0x20;
                    r28 = &var_E8 + 0x60;
                    var_270 = &var_1D8 + 0x18;
                    var_268 = &var_1D8 + 0x20;
                    asm { ubfx       x8, x8, #0x3, #0x20 };
                    var_278 = r8 - 0x1;
                    r27 = 0x4;
                    while (true) {
                            r20 = sign_extend_64(*(int32_t *)(r1 + r27));
                            r8 = 0x447a0000;
                            asm { fcvtas     x25, s0 };
                            if (r23 != 0x0) {
                                    r24 = 0x5;
                                    r0 = nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::operator[](r21);
                                    r19 = r0;
                                    r0 = nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >& nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::operator[]<char const>(r0);
                                    var_E8 = 0x0;
                                    r0 = void nlohmann::detail::from_json<nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >, int, 0>(r0, &var_E8);
                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::json_value::destroy(var_288);
                                    r8 = 0x42c80000;
                                    asm { fcvtzs     w8, s0 };
                                    asm { sxtw       x8, w8 };
                                    var_1F8 = r8;
                                    r0 = nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >& nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::operator[]<char const>(r19);
                                    *(int8_t *)r0 = r24;
                                    r0[0x1] = var_1F8;
                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                    r8 = var_290;
                                    r21 = var_280;
                                    if (r8 == r23) {
                                            r0 = nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >& nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::operator[]<char const>(r19);
                                            var_E8 = 0x0;
                                            r0 = void nlohmann::detail::from_json<nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >, float, 0>(r0, &var_E8);
                                    }
                            }
                            var_118 = 0x0;
                            void nlohmann::detail::external_constructor<(&var_118, "index");
                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::json_value::destroy(var_220);
                            r0 = nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::basic_json(&var_E8, &var_118, 0x2);
                            var_148 = 0x0;
                            void nlohmann::detail::external_constructor<(&var_148, "bpm");
                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::json_value::destroy(var_228);
                            asm { fcvtzs     w8, s8 };
                            asm { sxtw       x8, w8 };
                            r0 = nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::basic_json(r26, &var_148, 0x2);
                            var_178 = 0x0;
                            void nlohmann::detail::external_constructor<(&var_178, "pos");
                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::json_value::destroy(var_238);
                            asm { fcvtzs     w8, s0 };
                            asm { sxtw       x8, w8 };
                            r0 = nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::basic_json(var_218, &var_178, 0x2);
                            var_1A8 = 0x0;
                            void nlohmann::detail::external_constructor<(&var_1A8, "msec");
                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::json_value::destroy(var_258);
                            r0 = nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::basic_json(r22, &var_1A8, 0x2);
                            var_1D8 = 0x0;
                            void nlohmann::detail::external_constructor<(&var_1D8, "numBar");
                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::json_value::destroy(var_268);
                            r0 = nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::basic_json(r28, &var_1D8, 0x2);
                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::push_back(r21);
                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                            if (var_278 == r23) {
                                    break;
                            }
                            r1 = var_1F0;
                            r27 = r27 + 0x8;
                            r23 = r23 + 0x1;
                    }
            }
            r8 = *(int8_t *)r21;
            if (r8 != 0x1) {
                    if (r8 == 0x2) {
                            r9 = r21[0x1];
                            if (SAR(r9[0x1] - *r9, 0x4) <= 0x1) {
                                    r0 = var_1F0;
                                    if (r0 != 0x0) {
                                            r0 = operator delete(r0);
                                    }
                                    if (**___stack_chk_guard != var_70) {
                                            __stack_chk_fail();
                                    }
                            }
                            else {
                                    var_E8 = r21;
                                    nlohmann::detail::iter_impl<nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > > >::operator*();
                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::basic_json(&decomp_var_210);
                                    r0 = nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >& nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::operator[]<char const>(&decomp_var_210);
                                    var_E8 = 0x0;
                                    void nlohmann::detail::from_json<nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >, int, 0>(r0, &var_E8);
                                    r28 = sign_extend_64(var_E8);
                                    r0 = nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >& nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::operator[]<char const>(&decomp_var_210);
                                    var_E8 = 0x0;
                                    void nlohmann::detail::from_json<nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >, int, 0>(r0, &var_E8);
                                    var_218 = sign_extend_64(var_E8);
                                    r0 = nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >& nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::operator[]<char const>(&decomp_var_210);
                                    var_E8 = 0x0;
                                    void nlohmann::detail::get_arithmetic_value<nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >, long long, 0>(r0, &var_E8);
                                    r19 = var_E8;
                                    r0 = nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >& nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::operator[]<char const>(&decomp_var_210);
                                    var_E8 = 0x0;
                                    void nlohmann::detail::from_json<nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >, int, 0>(r0, &var_E8);
                                    r27 = var_E8;
                                    r0 = nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::operator[](r21);
                                    r0 = nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >& nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::operator[]<char const>(r0);
                                    var_E8 = 0x0;
                                    r0 = void nlohmann::detail::get_arithmetic_value<nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >, long long, 0>(r0, &var_E8);
                                    var_220 = r19 - var_E8;
                                    r23 = r19 + (r19 - var_E8);
                                    if (r23 < var_298) {
                                            var_238 = &var_118 + 0x18;
                                            r20 = &var_E8 + 0x18;
                                            var_230 = &var_148 + 0x20;
                                            var_228 = &var_118 + 0x20;
                                            r24 = &var_E8 + 0x30;
                                            var_248 = &var_148 + 0x18;
                                            var_240 = &var_178 + 0x20;
                                            r25 = &var_E8 + 0x48;
                                            r19 = &var_1A8 + 0x20;
                                            var_258 = &var_1A8 + 0x18;
                                            var_250 = &var_178 + 0x18;
                                            r26 = &var_E8 + 0x60;
                                            r22 = &var_1D8 + 0x20;
                                            var_260 = &var_1D8 + 0x18;
                                            d8 = 0x3ff0000000000000 / var_2B0;
                                            r28 = r28 + 0x1;
                                            do {
                                                    var_118 = 0x0;
                                                    void nlohmann::detail::external_constructor<(&var_118, "index");
                                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::json_value::destroy(var_228);
                                                    r0 = nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::basic_json(&var_E8, &var_118, 0x2);
                                                    var_148 = 0x0;
                                                    void nlohmann::detail::external_constructor<(&var_148, "bpm");
                                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::json_value::destroy(var_230);
                                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::basic_json(r20, &var_148, 0x2);
                                                    var_178 = 0x0;
                                                    void nlohmann::detail::external_constructor<(&var_178, "pos");
                                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::json_value::destroy(var_240);
                                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::basic_json(r24, &var_178, 0x2);
                                                    var_1A8 = 0x0;
                                                    void nlohmann::detail::external_constructor<(&var_1A8, "msec");
                                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::json_value::destroy(r19);
                                                    asm { fcvtas     x8, d0 };
                                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::basic_json(r25, &var_1A8, 0x2);
                                                    var_1D8 = 0x0;
                                                    void nlohmann::detail::external_constructor<(&var_1D8, "numBar");
                                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::json_value::destroy(r22);
                                                    asm { sxtw       x8, w8 };
                                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::basic_json(r26, &var_1D8, 0x2);
                                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::push_back(var_280);
                                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                                    r28 = r28 + 0x1;
                                                    r27 = r27 + 0x1;
                                                    r23 = r23 + var_220;
                                            } while (r23 < var_298);
                                    }
                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                    r0 = var_1F0;
                                    if (r0 != 0x0) {
                                            r0 = operator delete(r0);
                                    }
                                    if (**___stack_chk_guard != var_70) {
                                            __stack_chk_fail();
                                    }
                            }
                    }
                    else {
                            r0 = var_1F0;
                            if (r0 != 0x0) {
                                    r0 = operator delete(r0);
                            }
                            if (**___stack_chk_guard != var_70) {
                                    __stack_chk_fail();
                            }
                    }
            }
            else {
                    r9 = r21[0x1];
                    if ((SAR(r9[0x1] - *r9, 0x3)) * 0xcccccccccccccccd >= 0x1) {
                            var_E8 = r21;
                            nlohmann::detail::iter_impl<nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > > >::operator*();
                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::basic_json(&decomp_var_210);
                            r0 = nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >& nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::operator[]<char const>(&decomp_var_210);
                            var_E8 = 0x0;
                            void nlohmann::detail::from_json<nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >, int, 0>(r0, &var_E8);
                            r28 = sign_extend_64(var_E8);
                            r0 = nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >& nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::operator[]<char const>(&decomp_var_210);
                            var_E8 = 0x0;
                            void nlohmann::detail::from_json<nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >, int, 0>(r0, &var_E8);
                            var_218 = sign_extend_64(var_E8);
                            r0 = nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >& nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::operator[]<char const>(&decomp_var_210);
                            var_E8 = 0x0;
                            void nlohmann::detail::get_arithmetic_value<nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >, long long, 0>(r0, &var_E8);
                            r19 = var_E8;
                            r0 = nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >& nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::operator[]<char const>(&decomp_var_210);
                            var_E8 = 0x0;
                            void nlohmann::detail::from_json<nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >, int, 0>(r0, &var_E8);
                            r27 = var_E8;
                            r0 = nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::operator[](r21);
                            r0 = nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >& nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::operator[]<char const>(r0);
                            var_E8 = 0x0;
                            r0 = void nlohmann::detail::get_arithmetic_value<nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >, long long, 0>(r0, &var_E8);
                            var_220 = r19 - var_E8;
                            r23 = r19 + (r19 - var_E8);
                            if (r23 < var_298) {
                                    var_238 = &var_118 + 0x18;
                                    r20 = &var_E8 + 0x18;
                                    var_230 = &var_148 + 0x20;
                                    var_228 = &var_118 + 0x20;
                                    r24 = &var_E8 + 0x30;
                                    var_248 = &var_148 + 0x18;
                                    var_240 = &var_178 + 0x20;
                                    r25 = &var_E8 + 0x48;
                                    r19 = &var_1A8 + 0x20;
                                    var_258 = &var_1A8 + 0x18;
                                    var_250 = &var_178 + 0x18;
                                    r26 = &var_E8 + 0x60;
                                    r22 = &var_1D8 + 0x20;
                                    var_260 = &var_1D8 + 0x18;
                                    d8 = 0x3ff0000000000000 / var_2B0;
                                    r28 = r28 + 0x1;
                                    do {
                                            var_118 = 0x0;
                                            void nlohmann::detail::external_constructor<(&var_118, "index");
                                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::json_value::destroy(var_228);
                                            r0 = nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::basic_json(&var_E8, &var_118, 0x2);
                                            var_148 = 0x0;
                                            void nlohmann::detail::external_constructor<(&var_148, "bpm");
                                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::json_value::destroy(var_230);
                                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::basic_json(r20, &var_148, 0x2);
                                            var_178 = 0x0;
                                            void nlohmann::detail::external_constructor<(&var_178, "pos");
                                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::json_value::destroy(var_240);
                                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::basic_json(r24, &var_178, 0x2);
                                            var_1A8 = 0x0;
                                            void nlohmann::detail::external_constructor<(&var_1A8, "msec");
                                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::json_value::destroy(r19);
                                            asm { fcvtas     x8, d0 };
                                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::basic_json(r25, &var_1A8, 0x2);
                                            var_1D8 = 0x0;
                                            void nlohmann::detail::external_constructor<(&var_1D8, "numBar");
                                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::json_value::destroy(r22);
                                            asm { sxtw       x8, w8 };
                                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::basic_json(r26, &var_1D8, 0x2);
                                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::push_back(var_280);
                                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                            r28 = r28 + 0x1;
                                            r27 = r27 + 0x1;
                                            r23 = r23 + var_220;
                                    } while (r23 < var_298);
                            }
                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                            r0 = var_1F0;
                            if (r0 != 0x0) {
                                    r0 = operator delete(r0);
                            }
                            if (**___stack_chk_guard != var_70) {
                                    __stack_chk_fail();
                            }
                    }
                    else {
                            r0 = var_1F0;
                            if (r0 != 0x0) {
                                    r0 = operator delete(r0);
                            }
                            if (**___stack_chk_guard != var_70) {
                                    __stack_chk_fail();
                            }
                    }
            }
    }
    return r0;
