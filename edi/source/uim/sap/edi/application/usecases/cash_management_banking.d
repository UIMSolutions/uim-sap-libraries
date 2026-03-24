module uim.sap.edi.application.usecases.cash_management_banking;

import uim.sap.edi.domain;
import uim.sap.edi.application.usecases.base;

class CashManagementBankingUseCase : EDIUseCase {
    override string name() const {
        return "Cash Management (Banking)";
    }

    override EDIProcessMode mode() const {
        return EDIProcessMode.CashManagementBanking;
    }

    override bool allowBuffering() const {
        return false;
    }

    override bool requireAcknowledgement() const {
        return true;
    }

    override bool requireThreeWayMatch() const {
        return false;
    }

    override EDIMessageType[] supportedMessageTypes() const {
        return [
            EDIMessageType.PAYEXT,
            EDIMessageType.FINSTA
        ];
    }

    override string[] checkpoints(EDIUseCaseInput input) const {
        return [
            "Payment instructions (PAYEXT) issued from SAP to house bank",
            "Bank statement (FINSTA) received and auto-clearing can be triggered",
            "ISO 20022 and PAIN format handling is represented by selected message standard",
            "Financial document context: " ~ input.documentNumber
        ];
    }
}