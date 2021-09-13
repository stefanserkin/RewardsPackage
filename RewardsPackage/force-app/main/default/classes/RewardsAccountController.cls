public with sharing class RewardsAccountController {
    
    @AuraEnabled
    public static void recalculateRewardsAccount(String recordId) {

        Rewards_Account__c rewardsAccountWithRewardsEvents = [
            SELECT Id, 
                   Points_Total__c, 
                   (SELECT Id,
                           Points__c,
                           Points_Balance__c,
                           RecordType.DeveloperName 
                      FROM Rewards_Events__r
                     ORDER BY Date__c ASC)
              FROM Rewards_Account__c
             WHERE Id = :recordId
              WITH SECURITY_ENFORCED
             LIMIT 1
        ];
        List<Rewards_Event__c> lstRewardsEventsToUpdate = new List<Rewards_Event__c>();

        Decimal runningBalance = 0;

        for (Rewards_Event__c re : rewardsAccountWithRewardsEvents.Rewards_Events__r)
        {
            if (re.RecordType.DeveloperName == 'Award') {
                runningBalance += re.Points__c;
                re.Points_Balance__c = runningBalance;
            } else if (re.RecordType.DeveloperName == 'Redemption' || re.RecordType.DeveloperName == 'Expiration') {
                runningBalance -= re.Points__c;
                re.Points_Balance__c = runningBalance;
            }
            lstRewardsEventsToUpdate.add(re);
        }

        rewardsAccountWithRewardsEvents.Points_Total__c = runningBalance;

        update rewardsAccountWithRewardsEvents;
        update lstRewardsEventsToUpdate;

    }
    
}