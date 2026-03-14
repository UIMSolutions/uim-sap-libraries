module uim.sap.oau.exceptions.conflict;

import uim.sap.oau;

mixin(ShowModule!());

@safe:

class OAUConflictException : OAUException {
    this(string resource, string id, string file = __FILE__, size_t line = __LINE__) {
        super(resource ~ " already exists: " ~ id, file, line);
    }
}
