module uim.sap.service.mixins.service;
import uim.sap.service;

mixin(ShowModule!());

@safe:
string sapServiceTemplate() {
  return q{
    this() {
      super();
    }

    this(Json initData) {
      super(initData);
    }

    this(Json[] initData) {
      super(initData);
    }

    this(Json[string] initData) {
      super(initData);
    }
  };
}

template SAPServiceTemplate(alias Symbol) {
  const char[] SAPServiceTemplate = sapServiceTemplate();
}