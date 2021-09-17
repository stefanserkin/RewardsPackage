public with sharing class RewardsController {

    @AuraEnabled(cacheable = true)
    public static List<Reward__c> getRewards() {
        return [SELECT Id, Name, Cost__c, Image_URL__c, Relative_URL__c 
                  FROM Reward__c 
                 WHERE Active__c = true
                  WITH SECURITY_ENFORCED
                 ORDER BY Cost__c ASC
                 LIMIT 200];
    }

}