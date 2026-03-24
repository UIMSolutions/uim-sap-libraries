module uim.sap.idoc.exceptions.configuration;

import uim.sap.idoc.exceptions.exception;

class IDocConfigurationException : IDocException {
    this(string msg, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line);
    }
}
