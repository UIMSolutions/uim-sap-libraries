module uim.sap.oau.exceptions.exception;

import uim.sap.oau;

mixin(ShowModule!());

@safe:

class OAUException : SAPException {
    this(string msg, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line);
    }
}
