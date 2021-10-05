public with sharing class RewardsHandler {

    private static Map<Id, Reward__c> mapRewards;

    public static Map<Id, Reward__c> getRewardsMap(Set<Id> setRewardIds) {
        if (mapRewards != null) {
            return mapRewards;
        }
        mapRewards = queryForMap();
        return mapRewards;
    }

    public static Map<Id, Reward__c> getRewardsMap(List<Rewards_Event__c> lstRedemptionEvents) {
        if (mapRewards != null) {
            return mapRewards;
        }
        mapRewards = queryForMap();
        return mapRewards;
    }

    private static Map<Id, Reward__c> queryForMap() {
        Map<Id, Reward__c> mapRewards = new Map<Id, Reward__c>([
            SELECT Id, Name, Cost__c 
              FROM Reward__c 
             LIMIT 10000
        ]);
        return mapRewards;
    }
    
}