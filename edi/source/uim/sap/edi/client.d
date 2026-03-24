module uim.sap.edi.client;

import uim.sap.edi.config;
import uim.sap.edi.domain;
import uim.sap.edi.models;
import uim.sap.edi.application.service;
import uim.sap.edi.application.usecases;
import uim.sap.edi.infrastructure;

class EDIClient {
    private EDIConfig _config;
    private EDIUseCaseService _service;

    this(EDIConfig config = EDIConfig.init) {
        config.validate();
        _config = config;

        auto gateway = new VibeEDIGateway(_config.dryRunGateway, _config.strictValidation);
        auto monitor = new ConsoleEDIMonitoringPort();
        _service = new EDIUseCaseService(gateway, monitor, _config);
    }

    EDIUseCaseResult procureToPayPurchasing(EDIUseCaseInput input) {
        return _service.execute(new ProcureToPayPurchasingUseCase(), input);
    }

    EDIUseCaseResult orderToCashSales(EDIUseCaseInput input) {
        return _service.execute(new OrderToCashSalesUseCase(), input);
    }

    EDIUseCaseResult logisticsTransport3PL(EDIUseCaseInput input) {
        return _service.execute(new LogisticsTransport3PLUseCase(), input);
    }

    EDIUseCaseResult cashManagementBanking(EDIUseCaseInput input) {
        return _service.execute(new CashManagementBankingUseCase(), input);
    }
}

unittest {
    EDIConfig cfg;
    cfg.dryRunGateway = true;

    auto client = new EDIClient(cfg);

    EDIUseCaseInput input;
    input.sender.partnerId = "SAP_ERP_PRD";
    input.sender.role = "BUYER";
    input.receiver.partnerId = "SUPPLIER_0001";
    input.receiver.role = "SUPPLIER";
    input.messageType = EDIMessageType.ORDERS;
    input.standard = EDIMessageStandard.EDIFACT;
    input.sapTransactionCode = "ME21N";
    input.documentNumber = "4500000100";

    auto result = client.procureToPayPurchasing(input);
    assert(result.success);
    assert(result.useCaseName == "Procure-to-Pay (Purchasing)");
}

unittest {
    EDIConfig cfg;
    cfg.dryRunGateway = true;

    auto client = new EDIClient(cfg);

    EDIUseCaseInput input;
    input.sender.partnerId = "CUSTOMER_01";
    input.sender.role = "CUSTOMER";
    input.receiver.partnerId = "SAP_SALES";
    input.receiver.role = "SELLER";
    input.messageType = EDIMessageType.OUTBOUND_INVOICE;
    input.standard = EDIMessageStandard.EDIFACT;
    input.sapTransactionCode = "VA01";
    input.documentNumber = "SO-10001";

    auto result = client.orderToCashSales(input);
    assert(result.success);
    assert(result.useCaseName == "Order-to-Cash (Sales)");
}

unittest {
    EDIConfig cfg;
    cfg.dryRunGateway = false;
    cfg.bufferWhenReceiverOffline = true;

    auto client = new EDIClient(cfg);

    EDIUseCaseInput input;
    input.sender.partnerId = "SAP_SHIPPING";
    input.sender.role = "SHIPPER";
    input.receiver.partnerId = "CARRIER_17";
    input.receiver.logicalAddress = "";
    input.receiver.role = "CARRIER";
    input.messageType = EDIMessageType.IFTSTA;
    input.standard = EDIMessageStandard.EDIFACT;
    input.documentNumber = "DEL-9900";

    auto result = client.logisticsTransport3PL(input);
    assert(result.success);
    assert(result.state == EDIFlowState.Buffered);
}

unittest {
    EDIConfig cfg;
    cfg.dryRunGateway = false;
    cfg.bufferWhenReceiverOffline = false;

    auto client = new EDIClient(cfg);

    EDIUseCaseInput input;
    input.sender.partnerId = "SAP_TREASURY";
    input.sender.role = "TREASURY";
    input.receiver.partnerId = "HOUSE_BANK";
    input.receiver.logicalAddress = "https://bank.example/iso20022";
    input.receiver.role = "BANK";
    input.messageType = EDIMessageType.FINSTA;
    input.standard = EDIMessageStandard.ISO20022;
    input.documentNumber = "BANKSTMT-2026-03-24";

    auto result = client.cashManagementBanking(input);
    assert(result.success);
    assert(result.useCaseName == "Cash Management (Banking)");
}