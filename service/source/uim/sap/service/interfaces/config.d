module uim.sap.service.interfaces.config;
import uim.sap.service;

mixin(ShowModule!());

@safe:
interface ISAPConfig {
  string serviceName();
  void serviceName(string name);

  string serviceVersion();
  void serviceVersion(string vers);

  string host();
  void host(string host);  

  ushort port();
  void port(ushort port);

  string basePath();
  void basePath(string basePath);

  bool requireAuthToken();
  void requireAuthToken(bool required);

  string authToken();
  void authToken(string token);

  string[string] customHeaders();
  void customHeaders(string[string] headers);

  string customHeader(string key);
  void customHeader(string key, string value);

  void validate();
}