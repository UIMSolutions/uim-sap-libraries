module uim.sap.edi.exceptions.configuration;

import uim.sap.edi.exceptions.exception;

class EDIConfigurationException : EDIException {
    this(string msg, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line);
    }
}