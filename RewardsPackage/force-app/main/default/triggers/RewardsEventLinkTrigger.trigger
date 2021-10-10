trigger RewardsEventLinkTrigger on Rewards_Event_Link__c (before insert) {
    if (RewardsCommonUtilities.bypassTrigger('Rewards_Event_Link__c')) {
        return;
    }
    RewardsEventLinkHandler.debitAwards(Trigger.new);
}