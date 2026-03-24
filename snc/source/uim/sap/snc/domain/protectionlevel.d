module uim.sap.snc.domain.protectionlevel;

enum SNCProtectionLevel : uint {
    AuthenticationOnly = 1,
    IntegrityProtection = 2,
    PrivacyProtection = 3
}

bool isValidProtectionLevel(SNCProtectionLevel level) pure nothrow @safe @nogc {
    return level >= SNCProtectionLevel.AuthenticationOnly &&
           level <= SNCProtectionLevel.PrivacyProtection;
}

SNCProtectionLevel enforceMinimumProtectionLevel(
    SNCProtectionLevel requested,
    SNCProtectionLevel minimumAllowed
) pure nothrow @safe @nogc {
    return requested < minimumAllowed ? minimumAllowed : requested;
}

bool hasAuthentication(SNCProtectionLevel level) pure nothrow @safe @nogc {
    return level >= SNCProtectionLevel.AuthenticationOnly;
}

bool hasIntegrity(SNCProtectionLevel level) pure nothrow @safe @nogc {
    return level >= SNCProtectionLevel.IntegrityProtection;
}

bool hasPrivacy(SNCProtectionLevel level) pure nothrow @safe @nogc {
    return level >= SNCProtectionLevel.PrivacyProtection;
}
