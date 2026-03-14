module uim.sap.oau.exceptions.authorization;

import uim.sap.oau;

mixin(ShowModule!());

@safe:

class OAUAuthorizationException : OAUException {
    this(string msg, string file = __FILE__, size_t line = __LINE__) {
        super("Authorization failed: " ~ msg, file, line);
    }
}
