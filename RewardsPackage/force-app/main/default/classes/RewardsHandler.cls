public with sharing class RewardsHandler {

    private static Map<Id, Reward__c> mapRewards;

    public static Map<Id, Reward__c> getRewardsMap(Set<Id> setRewardIds) {
        if (mapRewards != null) {
            return mapRewards;
        }
        mapRewards = queryForMap(setRewardIds);
        return mapRewards;
    }

    public static Map<Id, Reward__c> getRewardsMap(List<Rewards_Event__c> lstRedemptionEvents) {
        if (mapRewards != null) {
            return mapRewards;
        }
        RewardsEventHandler.setRecordTypeIds();
        Set<Id> setRewardIds = new Set<Id>();
        for (Rewards_Event__c re : lstRedemptionEvents) {
            if (re.RecordTypeId == RewardsEventHandler.getRedemptionRecordTypeId() 
                    && re.Reward__c != null) {
                setRewardIds.add(re.Reward__c);
            }
        }
        mapRewards = queryForMap(setRewardIds);
        return mapRewards;
    }

    private static Map<Id, Reward__c> queryForMap(Set<Id> setRewardIds) {
        Map<Id, Reward__c> mapRewards = new Map<Id, Reward__c>([SELECT Id, Name FROM Reward__c WHERE Id IN :setRewardIds]);
        return mapRewards;
    }
    
}