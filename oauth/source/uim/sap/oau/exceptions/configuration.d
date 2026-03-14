module uim.sap.oau.exceptions.configuration;

import uim.sap.oau;

mixin(ShowModule!());

@safe:

class OAUConfigurationException : OAUException {
    this(string msg, string file = __FILE__, size_t line = __LINE__) {
        super("Configuration error: " ~ msg, file, line);
    }
}
