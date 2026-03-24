module uim.sap.service.exceptions.validation;

import uim.sap.service;

mixin(ShowModule!());

@safe:
class SAPValidationException : SAPException {
  this(string message) {
    super("Validation error: " ~ message);
  }

  this(string message, string file = __FILE__, size_t line = __LINE__, Throwable next = null) {
    super("Validation error: " ~ message, file, line, next);
  }
}
///
unittest {
  SAPValidationException ex1 = new SAPValidationException("Test message");
  assert(ex1.message == "Validation error: Test message");

  SAPValidationException ex2 = new SAPValidationException("Test message", "testfile.d", 123);
  assert(ex2.message == "Validation error: Test message");
  assert(ex2.file == "testfile.d");
  assert(ex2.line == 123);
}