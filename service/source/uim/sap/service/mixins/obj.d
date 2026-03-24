module uim.sap.service.mixins.obj;

import uim.sap.service;

mixin(ShowModule!());

@safe:
string sapObjectTemplate() {
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

template SAPObjectTemplate(alias Symbol) {
  const char[] SAPObjectTemplate = sapObjectTemplate();
}