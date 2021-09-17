import { LightningElement, wire, api } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import getRewardsAccount from '@salesforce/apex/RewardsEventController.getRewardsAccount';
import getRewardsEvents from '@salesforce/apex/RewardsEventController.getRewardsEvents';

import USER_ID from '@salesforce/user/Id';
import NAME_FIELD from '@salesforce/schema/User.FirstName';
import CONTACTID_FIELD from '@salesforce/schema/User.ContactId';

const COLS = [
    { label: 'Date', fieldName: 'Date__c', initialWidth: 275, type: 'date', typeAttributes:{
        year: "numeric",
        month: "long",
        day: "2-digit",
        hour: "2-digit",
        minute: "2-digit"
    }},
    { label: 'Description', fieldName: 'Description__c', type: 'text', cellAttributes:{
        class:{fieldName:'typeColor'}
    }},
    { label: 'Type', fieldName: 'Type__c', initialWidth: 140, type: 'text', cellAttributes:{
        class:{fieldName:'typeColor'}
    }},
    { label: 'Points', fieldName: 'Points__c', initialWidth: 110, type: 'number', cellAttributes:{
        class:{fieldName:'typeColor'}
    }},
    { label: 'Balance', fieldName: 'Points_Balance__c', initialWidth: 110, type: 'number' }
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
    initialLoad = false;
    isLoading = true;
    activeTab = '1';

    // Styles
    @api themeColor;

    get themeStyle() {
        return `color:${this.themeColor}; font-weight: bold`;
    }

    // <h1 style="background-color:rgba(255, 99, 71, 0);">

    handleActiveTab(event) {
        const tab = event.target;
        this.activeTab = tab.value;
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
           this.error = error ; 
        } else if (data) {
            this.name = data.fields.FirstName.value;
            this.contactId = data.fields.ContactId.value;
        }
    }

    // Rewards Account
    wiredRewardsAccount;
    rewardsAccount;
    accPoints;
    accStatus;

    @wire(getRewardsAccount, { contactId: '$contactId', rewardsProgramId: '$rewardsProgramId' }) 
    ra(result) {
        this.wiredRewardsAccount = result;
        if (result.data) {
            this.rewardsAccount = result.data;
            this.accPoints = result.data.Points_Total__c;
            this.accStatus = result.data.Status__c;
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.rewardsEventList = [];
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
                let typeColor = item.Type__c === 'Redemption' ? "slds-text-color_success" : "slds-text-color_default"
                return {...item,
                    "typeColor":typeColor
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

}