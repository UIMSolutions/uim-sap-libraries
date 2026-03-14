module uim.sap.oau.exceptions.validation;

import uim.sap.oau;

mixin(ShowModule!());

@safe:

class OAUValidationException : OAUException {
    this(string msg, string file = __FILE__, size_t line = __LINE__) {
        super("Validation failed: " ~ msg, file, line);
    }
}
