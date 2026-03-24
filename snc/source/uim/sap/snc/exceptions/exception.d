module uim.sap.snc.exceptions.exception;

class SNCException : Exception {
    this(string msg, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line);
    }
}
