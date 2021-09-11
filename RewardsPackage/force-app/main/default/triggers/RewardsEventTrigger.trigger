trigger RewardsEventTrigger on Rewards_Event__c (before insert, after insert, 
                                    before update, after update, after delete) {

    if (Trigger.isBefore && Trigger.isInsert) {
        RewardsEventHandler.setRunningBalance(Trigger.new);
    }

}