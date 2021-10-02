import { LightningElement, api } from 'lwc';

export default class CommunityRewardDetails extends LightningElement {
    @api imageUrl;
    @api name;
    @api cost;
    @api details;
    @api themeStyle;

    backHandler() {
        this.dispatchEvent(new CustomEvent('back'));
    }

}