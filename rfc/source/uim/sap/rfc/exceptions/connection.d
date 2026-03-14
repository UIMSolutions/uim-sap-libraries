module uim.sap.rfc.exceptions.connection;





class RFCConnectionException : RFCException {
    this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null)
    pure nothrow @safe @nogc {
        super(msg, file, line, next);
    }
}


