import { LightningElement, api, wire } from 'lwc';
import getExpiredRewardsEvents from '@salesforce/apex/CommunityRewardsController.getExpiredRewardsEvents';

const COLS = [
    { label: 'Date Awarded', fieldName: 'Date__c', initialWidth: 150, type: 'date', typeAttributes:{
        year: "numeric",
        month: "long",
        day: "2-digit"
    }},
    { label: 'Description', fieldName: 'Description__c', type: 'text' },
    { label: 'Points Awarded', fieldName: 'Points__c', initialWidth: 135, type: 'number' },
    { label: 'Points Used', fieldName: 'Points_Used__c', initialWidth: 135, type: 'number' },
    { label: 'Expiration Date', fieldName: 'Expiration_Date__c', initialWidth: 150, type: 'date', typeAttributes:{
        year: "numeric",
        month: "long",
        day: "2-digit"
    }},
    { label: 'Points Expired', fieldName: 'Points_Expired__c', initialWidth: 135, type: 'number', cellAttributes:{
        class:{fieldName:'typeColor'}
    }}
];

export default class CommunityRewardsEventDetails extends LightningElement {
    @api rewardsevent;

    get isAwardEvent() {
        return this.rewardsevent.Type__c === 'Award';
    }
    get isRedemptionEvent() {
        return this.rewardsevent.Type__c === 'Redemption';
    }
    get isExpirationEvent() {
        return this.rewardsevent.Type__c === 'Expiration';
    }
    get cardTitle() {
        if (this.rewardsevent.Type__c === 'Award') {
            return `Award: ${this.rewardsevent.Description__c}`;
        } else if (this.rewardsevent.Type__c === 'Redemption') {
            return `Redemption: ${this.rewardsevent.Description__c}`;
        } else if (this.rewardsevent.Type__c === 'Expiration') {
            return `Points Expired`;
        }
    }
    get date() {
        return this.rewardsevent.Date__c;
    }
    get points() {
        return this.rewardsevent.Points__c;
    }
    get status() {
        return this.rewardsevent.Status__c;
    }
    get name() {
        return this.rewardsevent.Name;
    }
    get image() {
        return this.rewardsevent.Reward__r.Image_URL__c;
    }
    
    cols = COLS;
    wiredRewardsEventList;
    rewardsEventList = [];

    @wire(getExpiredRewardsEvents, { recordId: '$rewardsevent.Id' }) 
    reList(result) {
        this.wiredRewardsEventList = result;
        if (result.data) {
            this.rewardsEventList = result.data.map(item=>{
                let typeColor = "slds-text-color_error";
                return {...item,
                    "typeColor":typeColor
                }
            })

            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.rewardsEventList = [];
        }
    }

    backHandler() {
        this.dispatchEvent(new CustomEvent('back'));
    }

    handleDebug() {
        console.log('rewardsevent id ' + this.rewardsevent.Id);
        console.log('rewardsevent id ' + this.rewardsevent.Type__c);
    }

}