module uim.sap.ale.exceptions.exception;

class ALEException : Exception {
    this(string msg, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line);
    }
}
