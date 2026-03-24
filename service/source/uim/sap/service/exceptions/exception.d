module uim.sap.service.exceptions.exception;

import uim.sap.service;

mixin(ShowModule!());

@safe:

class SAPException : Exception {
  this(string msg) {
    super(msg);
  }

  this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null) {
    super(msg, file, line, next);
  }
}
///
unittest {
  SAPException ex1 = new SAPException("Test message");
  assert(ex1.message == "Test message");

  SAPException ex2 = new SAPException("Test message", "testfile.d", 123);
  assert(ex2.message == "Test message");
  assert(ex2.file == "testfile.d");
  assert(ex2.line == 123);
}