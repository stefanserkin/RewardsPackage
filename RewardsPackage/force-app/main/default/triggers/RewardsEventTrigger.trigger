trigger RewardsEventTrigger on Rewards_Event__c (before insert, after insert) {

    RewardsEventHandler.handleTriggerEvent(
        Trigger.isBefore, Trigger.isInsert, Trigger.isUpdate, 
        Trigger.isDelete, Trigger.isUndelete, Trigger.new, 
        Trigger.newMap, Trigger.oldMap
    );

}