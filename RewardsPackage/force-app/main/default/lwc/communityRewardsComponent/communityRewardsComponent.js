import { LightningElement, wire, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { getRecord } from 'lightning/uiRecordApi';
import { createRecord } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import getRewardsAccount from '@salesforce/apex/CommunityRewardsController.getRewardsAccount';
import getRewardsEvents from '@salesforce/apex/CommunityRewardsController.getRewardsEvents';
import getEligibleRewards from '@salesforce/apex/CommunityRewardsController.getEligibleRewards';
import getIneligibleRewards from '@salesforce/apex/CommunityRewardsController.getIneligibleRewards';

import USER_ID from '@salesforce/user/Id';
import NAME_FIELD from '@salesforce/schema/User.FirstName';
import CONTACTID_FIELD from '@salesforce/schema/User.ContactId';

import REWARDSEVENT_OBJECT from '@salesforce/schema/Rewards_Event__c';
import REDEMPTION_RECORDTYPEID_FIELD from '@salesforce/schema/Rewards_Event__c.RecordTypeId';
import POINTS_FIELD from '@salesforce/schema/Rewards_Event__c.Points__c';
import DESCRIPTION_FIELD from '@salesforce/schema/Rewards_Event__c.Description__c';
import REWARDSACCOUNT_FIELD from '@salesforce/schema/Rewards_Event__c.Rewards_Account__c';
import REWARD_FIELD from '@salesforce/schema/Rewards_Event__c.Reward__c';
import STATUS_FIELD from '@salesforce/schema/Rewards_Event__c.Status__c';
import RELATEDID_FIELD from '@salesforce/schema/Rewards_Event__c.Related_Entity_ID__c';

const COLS = [
    { label: 'Date', fieldName: 'Date__c', initialWidth: 225, type: 'date', typeAttributes:{
        year: "numeric",
        month: "long",
        day: "2-digit",
        hour: "2-digit",
        minute: "2-digit"
    }},
    { label: 'Description', fieldName: 'descriptionName', type: 'text', 
        cellAttributes:{ 
            class:{fieldName:'typeColor'},
            iconName: { 
                fieldName: 'priorityIcon' 
            },
            iconPosition: 'left', 
            iconAlternativeText: 'Expired Icon'
        }
    },
    { label: 'Type', fieldName: 'Type__c', initialWidth: 120, type: 'text', cellAttributes:{
        class:{fieldName:'typeColor'}
    }},
    { label: 'Points Spent', fieldName: 'Points_Spent__c', initialWidth: 125, type: 'number', cellAttributes:{
        class:{fieldName:'typeColor'}
    }},
    { label: 'Points Earned', fieldName: 'Points_Earned__c', initialWidth: 125, type: 'number', cellAttributes:{
        class:{fieldName:'typeColor'}
    }},
    { label: 'Balance', fieldName: 'Points_Balance__c', initialWidth: 110, type: 'number' },
    {  
        type: 'button',
        initialWidth: 110, 
        typeAttributes: {
            label: 'Details'
        }
    }
];

export default class CommunityRewardsComponent extends LightningElement {
    @api componentTitle = 'Rewards';
    @api includeLinkToMoreInfo;
    @api moreInfoURL;
    @api moreInfoURLText;
    @api rewardsProgramId;

    error;
    
    userId = USER_ID;
    name;
    contactId;

    // Display control
    isLoading = true;
    activeTab = '1';
    // Modal
    isModalRedeem = false;
    isModalOpen = false;
    modalHeader;
    modalBody;

    // Styles
    @api themeColor;

    get themeStyle() {
        return `color:${this.themeColor}; font-weight: bold`;
    }

    get pointsHistoryTabTitle() {
        return `${this.name}'s Rewards Points History`;
    }

    handleActiveTab(event) {
        const tab = event.target;
        this.activeTab = tab.value;
    }

    goNext() {
        let activeTabValue = Number(this.activeTab) + 1;
        this.activeTab = activeTabValue.toString();
    }

    goBack() {
        let activeTabValue = Number(this.activeTab) - 1;
        this.activeTab = activeTabValue.toString();
    }

    get isGoNextDisabled() {
        return this.activeTab === '3' ? true : false;
    }

    get isGoBackDisabled() {
        return this.activeTab === '1' ? true : false;
    }

    // Wire user
    
    @wire(getRecord, {
        recordId: USER_ID,
        fields: [NAME_FIELD, CONTACTID_FIELD]
    }) wireuser({
        error,
        data
    }) {
        if (error) {
           this.error = error; 
        } else if (data) {
            this.name = data.fields.FirstName.value;
            this.contactId = data.fields.ContactId.value;
        }
    }
    

    // Rewards Account
    wiredRewardsAccount;
    rewardsAccount;
    rewardsAccountId;
    accPoints;
    accStatus;
    
    @wire(getRewardsAccount, { contactId: '$contactId', rewardsProgramId: '$rewardsProgramId' }) 
    ra(result) {
        this.wiredRewardsAccount = result;
        if (result.data) {
            this.rewardsAccount = result.data;
            this.rewardsAccountId = result.data.Id;
            this.accPoints = result.data.Points_Total__c;
            this.accStatus = result.data.Status__c;
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.rewardsAccount = undefined;
        }
    }

    // Rewards Event formatted columns
    cols = COLS;
    // Rewards Events data from wire service
    wiredRewardsEventList;
    rewardsEventList = [];
    rewardsEventsPerPage = [];
    // Navigation
    page = 1;
    pageSize = 10;
    startingRecord = 1;
    endingRecord = 0;
    totalRecordCount = 0;
    totalPages = 0;

    // Pagination methods
    previousHandler() {
        if (this.page > 1) {
            this.page = this.page - 1;
            this.displayRecordsPerPage(this.page);
        }
    }

    nextHandler() {
        if((this.page < this.totalPages) && this.page !== this.totalPages){
            this.page = this.page + 1;
            this.displayRecordsPerPage(this.page);            
        }
    }

    displayRecordsPerPage(page){
        this.startingRecord = ((page -1) * this.pageSize) ;
        this.endingRecord = (this.pageSize * page);
        this.endingRecord = (this.endingRecord > this.totalRecountCount) ? this.totalRecountCount : this.endingRecord; 

        this.rewardsEventsPerPage = this.rewardsEventList.slice(this.startingRecord, this.endingRecord);

        this.startingRecord = this.startingRecord + 1;
    } 

    @wire(getRewardsEvents, { contactId: '$contactId', rewardsProgramId: '$rewardsProgramId' }) 
    reList(result) {
        this.wiredRewardsEventList = result;
        if (result.data) {
            this.rewardsEventList = result.data.map(item=>{
                let typeColor;
                let priorityIcon;
                let descriptionName = item.Description__c;
                let url = '/rewardscommunity/' + item.Id;
                if (item.Type__c === 'Redemption') {
                    typeColor = "slds-text-color_success";
                } else if (item.Type__c === 'Expiration') {
                    typeColor = "slds-text-color_error";
                    priorityIcon = 'utility:date_time';
                } else {
                    typeColor = "slds-text-color_default";
                }
                if (item.Points_Remaining__c === 0 && item.Expired__c) {
                    priorityIcon = 'utility:date_time';
                    descriptionName += ' ('+item.Points_Expired__c+' points expired on '+item.Expiration_Date__c+')';
                }
                return {...item,
                    "typeColor":typeColor,
                    "priorityIcon":priorityIcon,
                    "descriptionName":descriptionName,
                    "rewardsEventUrl":url
                }
            })
            this.totalRecordCount = result.data.length;
            this.totalPages = Math.ceil(this.totalRecordCount / this.pageSize);
            this.rewardsEventsPerPage = this.rewardsEventList.slice(0, this.pageSize);
            this.endingRecord = this.pageSize;
            this.isLoading = false;

            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.rewardsEventList = [];
        }
    }

    // Rewards
    rewards;
    wiredRewardsResult;
    ineligibleRewards;
    wiredIneligibleRewardsResult;
    hasEligibleRewards = false;
    hasIneligibleRewards = false;

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

    @wire(getIneligibleRewards, { rewardsProgramId: '$rewardsProgramId', accountPoints: '$accPoints' })
    ineligibleRewards(result) {
        this.wiredIneligibleRewardsResult = result;
        if (result.data) {
            this.ineligibleRewards = result.data;
            this.error = null;
            if (result.data.length > 0) {
                this.hasIneligibleRewards = true;
            }
        } else if (result.error) {
            this.error = result.error;
            this.ineligibleRewards = undefined;
        }
    }

    // Selected reward
    selectedReward;
    points;
    description;
    rewardsEventStatus = 'Pending';

    @wire(getObjectInfo, { objectApiName: REWARDSEVENT_OBJECT })
    rewardsEventObjectInfo;

    get redemptionRecordTypeId() {
        const rtis = this.rewardsEventObjectInfo.data.recordTypeInfos;
        return Object.keys(rtis).find(rti => rtis[rti].name === 'Redemption');
    }

    handleRewardSelection(event) {
        this.selectedReward = event.target.dataset.recordid;
        this.points = event.target.dataset.points;
        this.description = event.target.dataset.description;

        this.modalHeader = 'Redeem Reward';
        this.modalBody = `Are you sure you would like to redeem ${this.description} for ${this.points} points?`;
        this.isModalRedeem = true;
        this.isModalOpen = true;
    }

    handleIneligibleRewardSelection() {
        alert('More points are needed to unlock this reward.');
    }

    closeModal() {
        this.isModalOpen = false;
    }

    closeRedeemModal() {
        this.redeemReward();
        this.isModalOpen = false;
    }

    redeemReward() { 
        this.isLoading = true;
        this.activeTab = '1';

        const fields = {};
        fields[DESCRIPTION_FIELD.fieldApiName] = this.description;
        fields[POINTS_FIELD.fieldApiName] = this.points;
        fields[REWARD_FIELD.fieldApiName] = this.selectedReward;
        fields[STATUS_FIELD.fieldApiName] = this.rewardsEventStatus;
        fields[REWARDSACCOUNT_FIELD.fieldApiName] = this.rewardsAccountId;
        fields[RELATEDID_FIELD.fieldApiName] = this.selectedReward;
        fields[REDEMPTION_RECORDTYPEID_FIELD.fieldApiName] = this.redemptionRecordTypeId;
        const recordInput = { apiName: REWARDSEVENT_OBJECT.objectApiName, fields };
        createRecord(recordInput)
            .then((rewardsEvent) => {
                this.activeTab = '1';
                console.log('active tab when entering create records : ' + this.activeTab);
                this.rewardsEventId = rewardsEvent.id;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Reward Redeemed',
                        variant: 'success'
                    })
                );
                // refreshApex(this.wiredRewardsAccount);
                // refreshApex(this.wiredRewardsEventList);
                // refreshApex(this.wiredRewardsResult);
                // refreshApex(this.wiredIneligibleRewardsResult);
                console.log('active tab when exiting create records : ' + this.activeTab);
                this.isLoading = false;
            })
            .catch((error) => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error creating record',
                        message: 'Shoot - failed to redeem reward',
                        variant: 'error'
                    })
                );
                this.isLoading = false;
            });
    }

    selectedRewardsEventId;
    selectedRewardsEvent;

    showPointsTable = true;
    showPointsDetail = false;

    handleRowAction(event) {
        const row = event.detail.row;
        this.selectedRewardsEvent = row;
        this.selectedRewardsEventId = row.Id;
        this.showPointsTable = false;
        this.showPointsDetail = true;
    }

    handleBackToTable() {
        this.showPointsDetail = false;
        this.showPointsTable = true;
    }

}