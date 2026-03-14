module uim.sap.rfc.exceptions.configuration;

class RFCConfigurationException : RFCException {
    this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null)
    pure nothrow @safe @nogc {
        super(msg, file, line, next);
    }
}