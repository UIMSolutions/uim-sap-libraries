module uim.sap.idoc.exceptions.exception;

import uim.sap.idoc;

@safe:

/**
  * Base exception class for all IDoc-related exceptions.
  * This class can be extended to create specific exceptions for different error scenarios in the IDoc service.
  * It provides a common structure for handling errors and allows for chaining exceptions with additional context.
  *
  * Example usage:
  * throw new IDocException("An error occurred while processing the IDoc");
  */
class IDocException : SAPException {
  this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null)
  pure nothrow @safe @nogc {
    super(msg, file, line, next);
  }
}
