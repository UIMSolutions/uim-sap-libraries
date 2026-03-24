module uim.sap.ale.application.usecases.decoupling_high_availability;

import uim.sap.ale.domain;
import uim.sap.ale.application.usecases.base;

class DecouplingHighAvailabilityUseCase : ALEUseCase {
    override string name() const {
        return "Decoupling for High Availability";
    }

    override ALEProcessMode mode() const {
        return ALEProcessMode.DecouplingHighAvailability;
    }

    override bool allowBuffering() const {
        return true;
    }

    override bool requireAcknowledgement() const {
        return false;
    }

    override string[] notes(ALEUseCaseInput input) const {
        return [
            "Supports decentralized WMS operation during ERP maintenance windows",
            "Buffers confirmation IDocs while central system is offline",
            "Flushes backlog once core ERP connectivity is restored"
        ];
    }
}
