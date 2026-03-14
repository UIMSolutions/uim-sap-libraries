module uim.sap.oau.exceptions.quota;

import uim.sap.oau;

mixin(ShowModule!());

@safe:

class OAUQuotaExceededException : OAUException {
    this(string resource, size_t limit, string file = __FILE__, size_t line = __LINE__) {
        import std.conv : to;
        super("Quota exceeded for " ~ resource ~ ": maximum " ~ limit.to!string, file, line);
    }
}
