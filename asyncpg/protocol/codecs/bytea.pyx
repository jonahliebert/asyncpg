import decimal

_Dec = decimal.Decimal


cdef bytea_encode(ConnectionSettings settings, WriteBuffer wbuf, obj):
    cdef:
        Py_buffer pybuf
        bint pybuf_used = False
        char *buf
        ssize_t len

    if cpython.PyBytes_CheckExact(obj):
        buf = cpython.PyBytes_AS_STRING(obj)
        len = cpython.Py_SIZE(obj)
    else:
        cpython.PyObject_GetBuffer(obj, &pybuf, cpython.PyBUF_SIMPLE)
        pybuf_used = True
        buf = <char*>pybuf.buf
        len = pybuf.len

    try:
        wbuf.write_int32(<int32_t>len)
        wbuf.write_cstr(buf, len)
    finally:
        if pybuf_used:
            cpython.PyBuffer_Release(&pybuf)


cdef bytea_decode(ConnectionSettings settings, FastReadBuffer buf):
    cdef size_t buf_len = buf.len
    return cpython.PyBytes_FromStringAndSize(buf.read_all(), buf_len)


cdef init_bytea_codecs():
    register_core_codec(BYTEAOID,
                        <encode_func>&bytea_encode,
                        <decode_func>&bytea_decode,
                        PG_FORMAT_BINARY)

    register_core_codec(CHAROID,
                        <encode_func>&bytea_encode,
                        <decode_func>&bytea_decode,
                        PG_FORMAT_BINARY)
