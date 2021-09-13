trigger RewardsEventLinkTrigger on Rewards_Event_Link__c (before insert) {
    RewardsEventLinkHandler.debitAwards(Trigger.new);
}