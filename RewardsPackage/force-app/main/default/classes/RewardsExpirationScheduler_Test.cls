@isTest
public class RewardsExpirationScheduler_Test {

    public static String cronExp = '0 0 0 15 3 ? 2022';
    private static Id awardRecordTypeId = Schema.SObjectType.Rewards_Event__c
        .getRecordTypeInfosByDeveloperName().get('Award').getRecordTypeId();
    
    @isTest
    static void testScheduledJob() {
        List<Program_Reward__c> lstPRs  = RewardsTestDataFactory.createPerpetualProgramWithRewards(4);
        List<Contact> lstContacts       = RewardsTestDataFactory.createContacts(1, 1);
        List<Rewards_Account__c> lstRAs = RewardsTestDataFactory.createRewardsAccounts(lstContacts, lstPRs[0].Rewards_Program__c);
        Rewards_Account__c raWithEvents = RewardsTestDataFactory.createRewardsEventsForRA(lstRAs[0], 10, 0);

        List<Rewards_Event__c> lstAwardsToExpire = [SELECT Id, Expiration_Date__c 
                                                      FROM Rewards_Event__c
                                                     WHERE Rewards_Account__c = :raWithEvents.Id
                                                       AND RecordTypeId = :awardRecordTypeId
                                                     LIMIT 2];
        for (Rewards_Event__c re : lstAwardsToExpire) {
            re.Expiration_Date__c = Date.today().addDays(-1);
        }
        update lstAwardsToExpire;

        Test.startTest();
        RewardsExpirationScheduler res = new RewardsExpirationScheduler();
        String jobId = System.schedule(
            'Test Rewards Expiration Batch Updater', 
            cronExp, 
            res
        );
        res.execute(null);
        Test.stopTest();

        List<Rewards_Event__c> lstExpiredEvents = [SELECT Id FROM Rewards_Event__c WHERE Rewards_Account__c = :raWithEvents.Id AND Expired__c = true];
        System.assertEquals(lstAwardsToExpire.size(), lstExpiredEvents.size(), 'Unexpected amount of expired events');
    }

    @isTest
    static void testScheduleExpireAccountInBatch() {
        List<Program_Reward__c> lstPRs  = RewardsTestDataFactory.createPerpetualProgramWithRewards(4);
        List<Contact> lstContacts       = RewardsTestDataFactory.createContacts(1, 1);
        List<Rewards_Account__c> lstRAs = RewardsTestDataFactory.createRewardsAccounts(lstContacts, lstPRs[0].Rewards_Program__c);
        Rewards_Account__c raWithEvents = RewardsTestDataFactory.createRewardsEventsForRA(lstRAs[0], 10, 0);

        List<Rewards_Event__c> lstAwardsToExpire = [SELECT Id, Expiration_Date__c 
                                                      FROM Rewards_Event__c
                                                     WHERE Rewards_Account__c = :raWithEvents.Id
                                                       AND RecordTypeId = :awardRecordTypeId];
        for (Rewards_Event__c re : lstAwardsToExpire) {
            re.Expiration_Date__c = Date.today().addDays(-1);
        }
        update lstAwardsToExpire;

        raWithEvents.End_Datetime__c = Date.today().addDays(-1);
        update raWithEvents;

        Test.startTest();
        RewardsExpirationScheduler.run();
        RewardsExpirationScheduler res = new RewardsExpirationScheduler();
        String jobId = System.schedule(
            'Test Rewards Expiration Batch Updater', 
            cronExp, 
            res
        );
        res.execute(null);
        Test.stopTest();

        Rewards_Account__c expiredRAWithEvents = [
            SELECT Id, Status__c, (SELECT Id FROM Rewards_Events__r WHERE Expired__c = true) 
              FROM Rewards_Account__c 
             WHERE Id = :raWithEvents.Id
             LIMIT 1
        ];
        System.assertEquals('Complete', expiredRAWithEvents.Status__c, 'Unexpected status for rewards account');
        System.assertEquals(lstAwardsToExpire.size(), expiredRAWithEvents.Rewards_Events__r.size(), 'Unexpected amount of expired events');
    }

}
