module uim.sap.edi.exceptions.exception;

class EDIException : Exception {
    this(string msg, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line);
    }
}