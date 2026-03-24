module uim.sap.service.exceptions.configuration;

import uim.sap.service;

mixin(ShowModule!());

@safe:

class SAPConfigurationException : SAPException {
  this(string message) {
    super("Configuration error: " ~ message);
  }

  this(string message, string file = __FILE__, size_t line = __LINE__, Throwable next = null) {
    super("Configuration error: " ~ message, file, line, next);
  }
}
///
unittest {
  SAPConfigurationException ex1 = new SAPConfigurationException("Test message");
  assert(ex1.message == "Configuration error: Test message");

  SAPConfigurationException ex2 = new SAPConfigurationException("Test message", "testfile.d", 123);
  assert(ex2.message == "Configuration error: Test message");
  assert(ex2.file == "testfile.d");
  assert(ex2.line == 123);
}