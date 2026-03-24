module uim.sap.idoc.application.usecases.edi_external_partners;

import uim.sap.idoc.domain;
import uim.sap.idoc.application.usecases.base;

class EDIExternalPartnersUseCase : IDocUseCase {
    override string name() const {
        return "EDI with External Partners";
    }

    override IDocProcessingMode mode() const {
        return IDocProcessingMode.EDIExternalPartners;
    }

    override bool requireWorkflowOnError() const {
        return true;
    }

    override bool enableAutoResend() const {
        return true;
    }

    override string[] notes(IDocUseCaseInput input) const {
        return [
            "Supports classic EDI bridges to EDIFACT/ANSI X12",
            "Typical payloads: ORDERS, INVOIC, DESADV",
            "Automates procurement, invoicing and shipping notifications",
            "Sender " ~ input.sender.systemId ~ " to receiver " ~ input.receiver.systemId
        ];
    }
}
