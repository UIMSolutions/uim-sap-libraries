module uim.sap.service.exceptions.authorization;

import uim.sap.service;

mixin(ShowModule!());

@safe:

class SAPAuthorizationException : SAPException {
  this(string message) {
    super("Unauthorized: " ~ message);
  }

  this(string message, string file = __FILE__, size_t line = __LINE__, Throwable next = null) {
    super("Unauthorized: " ~ message, file, line, next);
  }
}
///
unittest {
  SAPAuthorizationException ex1 = new SAPAuthorizationException("Test message");
  assert(ex1.message == "Unauthorized: Test message");

  SAPAuthorizationException ex2 = new SAPAuthorizationException("Test message", "testfile.d", 123);
  assert(ex2.message == "Unauthorized: Test message");
  assert(ex2.file == "testfile.d");
  assert(ex2.line == 123);
}