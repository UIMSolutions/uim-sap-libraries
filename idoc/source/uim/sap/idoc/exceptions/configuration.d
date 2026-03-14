module uim.sap.idoc.exceptions.configuration;

import uim.sap.idoc;

@safe:

/** 
  * Exception thrown when there is a configuration error in the IDoc service.
  * This can occur when required configuration parameters are missing or invalid.
  * The exception message should provide details about the specific configuration issue.
  *
  * Example usage:
  * if (config.host.length == 0) {
  *     throw new IDocConfigurationException("Host cannot be empty");
  * }
  */
class IDocConfigurationException : IDocException {
  this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null)
  pure nothrow @safe @nogc {
    super(msg, file, line, next);
  }
}

