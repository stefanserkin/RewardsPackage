public with sharing class RewardsEventController {

    @AuraEnabled(cacheable=true)
    public static List<Rewards_Event__c> getRewardsEvents(Id contactId, Id rewardsProgramId) {
        return [SELECT Id, Type__c, Date__c, Description__c, Points__c, Points_Balance__c
                  FROM Rewards_Event__c
                 WHERE Rewards_Account__r.Contact__c = :contactId
                   AND Rewards_Account__r.Rewards_Program__c = :rewardsProgramId
                  WITH SECURITY_ENFORCED 
                 ORDER BY Date__c DESC
                 LIMIT 10000
               ];
    }

    @AuraEnabled(cacheable=true)
    public static Rewards_Account__c getRewardsAccount(Id contactId, Id rewardsProgramId) {
        return [SELECT Id, Points_Total__c, Status__c
                  FROM Rewards_Account__c
                 WHERE Contact__c = :contactId
                   AND Rewards_Program__c = :rewardsProgramId
                  WITH SECURITY_ENFORCED
                 LIMIT 1
        ];
    }
    
}