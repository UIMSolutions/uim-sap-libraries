module uim.sap.idoc.exceptions.exception;

class IDocException : Exception {
    this(string msg, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line);
    }
}
