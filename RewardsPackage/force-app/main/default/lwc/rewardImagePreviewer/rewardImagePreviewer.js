import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

import IMAGEURL_FIELD from '@salesforce/schema/Reward__c.Image_URL__c';
import COST_FIELD from '@salesforce/schema/Reward__c.Cost__c';
import REWARDNAME_FIELD from '@salesforce/schema/Reward__c.Name';

export default class RewardImagePreviewer extends LightningElement {
    @api recordId;

    name;
    cost;
    url;

    @wire(getRecord, {
        recordId: '$recordId',
        fields: [REWARDNAME_FIELD, COST_FIELD, IMAGEURL_FIELD]
    }) wireuser({
        error,
        data
    }) {
        if (error) {
           this.error = error; 
        } else if (data) {
            this.name = data.fields.Name.value;
            this.cost = data.fields.Cost__c.value;
            this.url = data.fields.Image_URL__c.value;
        }
    }

}