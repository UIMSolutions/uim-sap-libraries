module uim.sap.idoc.exceptions.connection;

import uim.sap.idoc;

@safe:

/** 
  * Exception thrown when there is a connection error while communicating with the IDoc service.
  * This can occur when the service is unreachable, the network is down, or authentication fails.
  * The exception message should provide details about the specific connection issue.
  *
  * Example usage:
  * if (!connectToIDocService()) {
  *     throw new IDocConnectionException("Failed to connect to IDoc service");
  * }
  */
class IDocConnectionException : IDocException {
  this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null)
  pure nothrow @safe @nogc {
    super(msg, file, line, next);
  }
}
