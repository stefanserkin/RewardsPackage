public with sharing class CommunityRewardsController {

    @AuraEnabled(cacheable = true)
    public static List<Reward__c> getRewards(Id rewardsProgramId) {
        return [SELECT Id, Name, Cost__c, Image_URL__c, Relative_URL__c, Redemption_Instructions__c 
                  FROM Reward__c 
                 WHERE Active__c = true
                   AND Id IN (SELECT Reward__c 
                                FROM Program_Reward__c 
                               WHERE Rewards_Program__c = :rewardsProgramId)
                  WITH SECURITY_ENFORCED
                 ORDER BY Cost__c ASC
                 LIMIT 200];
    }

    @AuraEnabled(cacheable = true)
    public static List<Reward__c> getEligibleRewards(Id rewardsProgramId, Decimal accountPoints) {
        return [SELECT Id, Name, Cost__c, Image_URL__c, Relative_URL__c, Redemption_Instructions__c 
                  FROM Reward__c 
                 WHERE Active__c = true
                   AND Cost__c <= :accountPoints
                   AND Id IN (SELECT Reward__c 
                                FROM Program_Reward__c 
                               WHERE Rewards_Program__c = :rewardsProgramId)
                  WITH SECURITY_ENFORCED
                 ORDER BY Cost__c ASC
                 LIMIT 200];
    }

    @AuraEnabled(cacheable = true)
    public static List<Reward__c> getIneligibleRewards(Id rewardsProgramId, Decimal accountPoints) {
        return [SELECT Id, Name, Cost__c, Image_URL__c, Relative_URL__c, Redemption_Instructions__c 
                  FROM Reward__c 
                 WHERE Active__c = true
                   AND Cost__c > :accountPoints
                   AND Id IN (SELECT Reward__c 
                                FROM Program_Reward__c 
                               WHERE Rewards_Program__c = :rewardsProgramId)
                  WITH SECURITY_ENFORCED
                 ORDER BY Cost__c ASC
                 LIMIT 200];
    }

    @AuraEnabled(cacheable = true)
    public static List<Rewards_Event__c> getRewardsEvents(Id contactId, Id rewardsProgramId) {
        return [SELECT Id, Name, Type__c, Date__c, Description__c, Points__c, Points_Balance__c, Points_Expired__c, Points_Used__c,
                       Expiration_Date__c, Points_Earned__c, Points_Spent__c, Points_Remaining__c, Expired__c, Reward__c, Status__c,
                       Reward__r.Image_URL__c, Reward__r.Redemption_Instructions__c
                  FROM Rewards_Event__c
                 WHERE Rewards_Account__r.Contact__c = :contactId
                   AND Rewards_Account__r.Rewards_Program__c = :rewardsProgramId
                  WITH SECURITY_ENFORCED 
                 ORDER BY Date__c DESC
                 LIMIT 10000
               ];
    }

    @AuraEnabled(cacheable = true)
    public static List<Rewards_Event__c> getExpiredRewardsEvents(Id recordId) {
        return [SELECT Id, Name, Type__c, Date__c, Description__c, Points__c, Points_Balance__c, Points_Expired__c, Points_Used__c,
                       Expiration_Date__c, Points_Earned__c, Points_Spent__c, Points_Remaining__c, Expired__c, Reward__c, Status__c, 
                       Reward__r.Image_URL__c
                  FROM Rewards_Event__c
                 WHERE Id IN (SELECT Award_Event__c 
                                FROM Rewards_Event_Link__c 
                               WHERE Deduction_Event__c = :recordId)
                  WITH SECURITY_ENFORCED
                 ORDER BY Date__c DESC
                 LIMIT 10000
               ];
    }

    @AuraEnabled(cacheable = true)
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
