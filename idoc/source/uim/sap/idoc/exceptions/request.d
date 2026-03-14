module uim.sap.idoc.exceptions.request;

import uim.sap.idoc;

@safe:

/** 
  * Exception thrown when there is an error in processing an IDoc request.
  * This can occur when the request is malformed, contains invalid data, or fails validation.
  * The exception message should provide details about the specific request issue.
  *
  * Example usage:
  * if (!validateIDocRequest(request)) {
  *     throw new IDocRequestException("Invalid IDoc request");
  * }
  */
class IDocRequestException : IDocException {
  int statusCode;

  this(
    string msg,
    int statusCode = 0,
    string file = __FILE__,
    size_t line = __LINE__,
    Throwable next = null
  ) pure nothrow @safe {
    super(msg, file, line, next);
    this.statusCode = statusCode;
  }
}
