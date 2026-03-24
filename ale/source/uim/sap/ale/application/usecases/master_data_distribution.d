module uim.sap.ale.application.usecases.master_data_distribution;

import uim.sap.ale.domain;
import uim.sap.ale.application.usecases.base;

class MasterDataDistributionUseCase : ALEUseCase {
    override string name() const {
        return "Master Data Distribution";
    }

    override ALEProcessMode mode() const {
        return ALEProcessMode.MasterDataDistribution;
    }

    override bool allowBuffering() const {
        return true;
    }

    override bool requireAcknowledgement() const {
        return true;
    }

    override string[] notes(ALEUseCaseInput input) const {
        return [
            "Single source of truth distribution for MATMAS, DEBMAS, CREMAS",
            "Central source pushes consistent identifiers to subscriber systems",
            "Source " ~ input.source.systemId ~ " to subscriber " ~ input.target.systemId
        ];
    }
}
