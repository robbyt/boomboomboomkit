    asm { fmadd      s0, s0, s1, s2 };
    asm { fcvtzs     w0, s0 };
    return r0;
