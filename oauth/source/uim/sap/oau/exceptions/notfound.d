module uim.sap.oau.exceptions.notfound;

import uim.sap.oau;

mixin(ShowModule!());

@safe:

class OAUNotFoundException : OAUException {
    this(string resource, string id, string file = __FILE__, size_t line = __LINE__) {
        super(resource ~ " not found: " ~ id, file, line);
    }
}
