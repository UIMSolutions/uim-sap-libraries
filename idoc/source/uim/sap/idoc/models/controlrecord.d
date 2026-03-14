module uim.sap.idoc.models.controlrecord;

import uim.sap.idoc;

@safe:

/** 
  * Represents the control record of an IDoc, containing metadata about the message.
  * This struct is used to define the structure of the control record when submitting an IDoc.
  * It includes fields such as message type, IDoc type, sender and receiver information.
  * The `toJson` method converts the control record into a JSON object, which can be sent to the IDoc service.
  * All fields are optional, but at least the message type or IDoc type should be provided for a valid control record.
  *
  * Example usage:
  * IDocControlRecord control = IDocControlRecord(
  *     messageType: "DEBMAS",
  *     idocType: "DEBMAS01",
  *     senderPort: "PORT1",
  *     senderPartner: "SENDER",
  *     receiverPort: "PORT2",
  *     receiverPartner: "RECEIVER"
  * );
  * Json controlJson = control.toJson();
  * // controlJson will contain the JSON representation of the control record.
  */
struct IDocControlRecord {
  string messageType;
  string idocType;
  string senderPort;
  string senderPartner;
  string receiverPort;
  string receiverPartner;

  Json toJson() const {
    Json data = Json.emptyObject;
    if (messageType.length > 0)
      data["messageType"] = Json(messageType);
    if (idocType.length > 0)
      data["idocType"] = Json(idocType);
    if (senderPort.length > 0)
      data["senderPort"] = Json(senderPort);
    if (senderPartner.length > 0)
      data["senderPartner"] = Json(senderPartner);
    if (receiverPort.length > 0)
      data["receiverPort"] = Json(receiverPort);
    if (receiverPartner.length > 0)
      data["receiverPartner"] = Json(receiverPartner);
    return data;
  }
}
