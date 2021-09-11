import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import recalculateRewardsAccount from '@salesforce/apex/RewardsAccountController.recalculateRewardsAccount';

export default class RecalculateRewardsAccount extends LightningElement {
    @api recordId;
    isModalOpen = false;
    isRecalculated = false;
    isLoading = false;

    cardTitle = 'Recalculate Rewards Account';

    handleButtonClick() {
        this.isModalOpen = true;
    }

    handleRecalculate() {
        this.isModalOpen = false;
        this.isLoading = true;

        recalculateRewardsAccount({ recordId: this.recordId })
        .then(result => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success!',
                    message: 'This Rewards Account has been recalculated successfully.',
                    variant: 'success'
                })
            );
            this.isLoading = false;
        });

        this.isRecalculated = true;

    }

    closeModal() {
        this.isModalOpen = false;
    }
    
}