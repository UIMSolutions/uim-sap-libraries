module uim.sap.service.interfaces.service;
import uim.sap.service;

mixin(ShowModule!());

@safe:
interface ISAPService {
  ISAPConfig config();
  void config(ISAPConfig cfg);

  Json health();
  Json ready();
}
