module uim.sap.service.mixins.config;
import uim.sap.service;

mixin(ShowModule!());

@safe:
string sapConfigTemplate() {
  return "
  this() {
    super();
  }

  this(Json[string] initData) {
    super(initData);
  }
  ";
}

template SAPConfigTemplate(alias Symbol) {
  const char[] SAPConfigTemplate = sapConfigTemplate();
}