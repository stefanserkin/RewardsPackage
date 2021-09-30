trigger RewardsAccountTrigger on Rewards_Account__c (before insert, before update) {

    if (Trigger.isBefore) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            RewardsAccountHandler.handleTriggerEvent(Trigger.new);
        }
    }

}