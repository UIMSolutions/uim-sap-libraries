module uim.sap.ale.application.usecases.hr_mini_master_distribution;

import uim.sap.ale.domain;
import uim.sap.ale.application.usecases.base;

class HRMiniMasterDistributionUseCase : ALEUseCase {
    override string name() const {
        return "HR Mini-Master Distribution";
    }

    override ALEProcessMode mode() const {
        return ALEProcessMode.HRMiniMasterDistribution;
    }

    override bool allowBuffering() const {
        return true;
    }

    override bool requireAcknowledgement() const {
        return true;
    }

    override string[] notes(ALEUseCaseInput input) const {
        return [
            "Distributes minimal employee identity and assignment data",
            "Protects full HR records by sharing only required fields",
            "Enables logistics and finance role assignment scenarios"
        ];
    }
}
