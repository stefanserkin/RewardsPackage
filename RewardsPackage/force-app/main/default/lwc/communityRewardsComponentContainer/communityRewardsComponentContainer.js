import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import { createRecord } from 'lightning/uiRecordApi';
import getRewardsProgram from '@salesforce/apex/CommunityRewardsController.getRewardsProgram';
import getRewardsAccount from '@salesforce/apex/CommunityRewardsController.getRewardsAccount';
import USER_ID from '@salesforce/user/Id';
import CONTACTID_FIELD from '@salesforce/schema/User.ContactId';
import REWARDACCOUNT_OBJECT from '@salesforce/schema/Rewards_Account__c';
import REWARDSPROGRAM_FIELD from '@salesforce/schema/Rewards_Account__c.Rewards_Program__c';
import CONTACT_FIELD from '@salesforce/schema/Rewards_Account__c.Contact__c';
import POINTSTOTAL_FIELD from '@salesforce/schema/Rewards_Account__c.Points_Total__c';

export default class CommunityRewardsComponentContainer extends LightningElement {
    @api componentTitle = 'Rewards';
    @api includeLinkToMoreInfo;
    @api moreInfoURL;
    @api moreInfoURLText;
    @api rewardsProgramId;
    @api activationButtonLabel;
    
    // Styles
    @api themeColor;

    get themeStyle() {
        return `color:${this.themeColor}; font-weight: bold; font-size: 32px`;
    }

    isLoading = true;
    error;

    contactId;

    @wire(getRecord, {
        recordId: USER_ID,
        fields: [CONTACTID_FIELD]
    }) wireuser({
        error,
        data
    }) {
        if (error) {
           this.error = error; 
        } else if (data) {
            this.contactId = data.fields.ContactId.value;
        }
    }
    
    rewardsProgram;
    wiredRewardsProgram;
    activationDetails;

    @wire(getRewardsProgram, { rewardsProgramId: '$rewardsProgramId' }) 
    rp(result) {
        this.wiredRewardsProgram = result;
        if (result.data) {
            this.rewardsProgram = result.data;
            this.activationDetails = result.data.Activate_Account_Details__c;
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.rewardsProgram = undefined;
            this.isLoading = false;
        }
    }
    
    accountIsActive = false;
    rewardsAccountId;
    rewardsAccount;
    wiredRewardsAccount;

    @wire(getRewardsAccount, { contactId: '$contactId', rewardsProgramId: '$rewardsProgramId' }) 
    ra(result) {
        this.wiredRewardsAccount = result;
        if (result.data) {
            this.isLoading = true;
            this.rewardsAccount = result.data;
            this.rewardsAccountId = result.data.Id;
            this.accountIsActive = true;
            this.isLoading = false;
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.rewardsAccount = undefined;
            this.isLoading = false;
        }
    }

    activateAccount() {
        this.isLoading = true;

        const fields = {};
        fields[REWARDSPROGRAM_FIELD.fieldApiName] = this.rewardsProgramId;
        fields[CONTACT_FIELD.fieldApiName] = this.contactId;
        fields[POINTSTOTAL_FIELD.fieldApiName] = 0;
        const recordInput = { apiName: REWARDACCOUNT_OBJECT.objectApiName, fields };
        createRecord(recordInput)
            .then((rewardsAccount) => {
                this.rewardsAccountId = rewardsAccount.Id;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'A new Rewards Account was activated',
                        variant: 'success'
                    })
                );
                this.accountIsActive = true;
                this.isLoading = false;
            })
            .catch((error) => {
                this.error = error;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error creating record',
                        message: 'Shoot - failed to activate account',
                        variant: 'error'
                    })
                );
                this.isLoading = false;
            });
    }

}