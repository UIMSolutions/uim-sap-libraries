module uim.sap.ale.exceptions.configuration;

import uim.sap.ale.exceptions.exception;

class ALEConfigurationException : ALEException {
    this(string msg, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line);
    }
}
