import { LightningElement, wire } from 'lwc';
import getEligibleRewards from '@salesforce/apex/CommunityRewardsController.getEligibleRewards';

export default class RichTextAssembler extends LightningElement {

    rewardsProgramId = 'a035f000000xdmRAAQ';
    accPoints = 999999999;

    rewards;
    wiredRewardsResult;

    @wire(getEligibleRewards, { rewardsProgramId: '$rewardsProgramId', accountPoints: '$accPoints' })
    wiredRewards(result) {
        this.wiredRewardsResult = result;
        if (result.data) {
            this.rewards = result.data;
            this.error = null;
            if (result.data.length > 0) {
                this.hasEligibleRewards = true;
            }
        } else if (result.error) {
            this.error = result.error;
            this.rewards = undefined;
        }
    }

    isModalOpen;

    selectedReward;

    handleRewardSelection(event) {
        let rewardData = event.target.dataset;
        this.selectedReward = rewardData.recordid;
        this.rewardDetails = rewardData.details;
        this.points = rewardData.points;
        this.description = rewardData.description;
        this.modalHeader = 'Redeem Reward';

        this.isModalOpen = true;
    }

    closeModal() {
        this.isModalOpen = false;
    }

}