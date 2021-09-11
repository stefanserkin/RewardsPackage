trigger RewardsEventTrigger on Rewards_Event__c (before insert, after insert) {

    if (Trigger.isInsert) {
        if (Trigger.isBefore) {
            RewardsEventHandler.handleDeductions(Trigger.new, Trigger.isBefore);
            RewardsEventHandler.setRunningBalance(Trigger.new);
        } else if (Trigger.isAfter) {
            RewardsEventHandler.handleDeductions(Trigger.new, Trigger.isBefore);
        }
    }

}