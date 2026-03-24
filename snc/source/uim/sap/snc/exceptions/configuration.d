module uim.sap.snc.exceptions.configuration;

import uim.sap.snc.exceptions.exception;

class SNCConfigurationException : SNCException {
    this(string msg, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line);
    }
}
