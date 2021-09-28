@isTest
public with sharing class RewardsEventHandler_Test {

    @isTest
    static void testTheTester() {
        List<Program_Reward__c> lstPRs  = RewardsTestDataFactory.createPerpetualProgramWithRewards(4);
        List<Contact> lstContacts       = RewardsTestDataFactory.createContacts(1, 1);
        List<Rewards_Account__c> lstRAs = RewardsTestDataFactory.createRewardsAccounts(lstContacts, lstPRs[0].Rewards_Program__c);
        
        System.assertEquals(4, lstPRs.size(), 'Unexpected amount of program rewards');
    }

    @isTest
    static void testGrantAward() {
        List<Program_Reward__c> lstPRs  = RewardsTestDataFactory.createPerpetualProgramWithRewards(1);
        List<Contact> lstContacts       = RewardsTestDataFactory.createContacts(1, 1);
        List<Rewards_Account__c> lstRAs = RewardsTestDataFactory.createRewardsAccounts(lstContacts, lstPRs[0].Rewards_Program__c);

        Id awardRecTypeId = RewardsTestDataFactory.getRecordTypeId('Rewards_Event__c', 'Award');

        Rewards_Event__c re = new Rewards_Event__c(
            Rewards_Account__c = lstRAs.get(0).Id, 
            Points__c          = 100, 
            RecordTypeId       = awardRecTypeId,
            Description__c     = 'Test Points'
        );

        Test.startTest();
        Database.SaveResult sr = Database.insert(re, false);
        Test.stopTest();

        System.assert(sr.isSuccess(), 'Failed to insert rewards event');

        Rewards_Account__c raToVerify = [SELECT Id, Points_Total__c FROM Rewards_Account__c WHERE Id = :re.Rewards_Account__c LIMIT 1];

        System.assertEquals(100, raToVerify.Points_Total__c, 'Unexpected points total');
    }

    @isTest
    static void testRedeemReward() {
        List<Program_Reward__c> lstPRs  = RewardsTestDataFactory.createPerpetualProgramWithRewards(1);
        List<Contact> lstContacts       = RewardsTestDataFactory.createContacts(1, 1);
        List<Rewards_Account__c> lstRAs = RewardsTestDataFactory.createRewardsAccounts(lstContacts, lstPRs[0].Rewards_Program__c);

        Rewards_Account__c ra = lstRAs.get(0);

        Rewards_Event__c award = new Rewards_Event__c(
            Rewards_Account__c = ra.Id, 
            Points__c          = 1000, 
            RecordTypeId       = RewardsTestDataFactory.getRecordTypeId('Rewards_Event__c', 'Award'),
            Description__c     = 'Test Points'
        );
        insert award;

        Rewards_Event__c redemption = new Rewards_Event__c(
            Rewards_Account__c = ra.Id, 
            RecordTypeId       = RewardsTestDataFactory.getRecordTypeId('Rewards_Event__c', 'Redemption'),
            Reward__c          = lstPRs.get(0).Reward__c,
            Status__c          = 'Pending',
            Points__c          = 100
        );
        
        Test.startTest();
        Database.SaveResult sr = Database.insert(redemption, false);
        Test.stopTest();

        System.assert(sr.isSuccess(), 'Failed to redeem reward');

        Rewards_Account__c raToVerify = [SELECT Id, Points_Total__c FROM Rewards_Account__c WHERE Id = :redemption.Rewards_Account__c LIMIT 1];

        System.assertEquals(900, raToVerify.Points_Total__c, 'Unexpected points total');

    }

    @isTest
    static void testBulkAwards() {
        List<Program_Reward__c> lstPRs  = RewardsTestDataFactory.createPerpetualProgramWithRewards(1);
        List<Contact> lstContacts       = RewardsTestDataFactory.createContacts(1, 1);
        List<Rewards_Account__c> lstRAs = RewardsTestDataFactory.createRewardsAccounts(lstContacts, lstPRs[0].Rewards_Program__c);

        List<Rewards_Event__c> lstREsToInsert = new List<Rewards_Event__c>();

        Id awardRecTypeId = RewardsTestDataFactory.getRecordTypeId('Rewards_Event__c', 'Award');
        for (Integer i = 0; i < 201; i++) {
            Rewards_Event__c re = new Rewards_Event__c(
                Rewards_Account__c = lstRAs.get(0).Id, 
                Points__c          = 100, 
                RecordTypeId       = awardRecTypeId,
                Description__c     = 'Test Points'
            );
            lstREsToInsert.add(re);
        }

        Test.startTest();
        insert lstREsToInsert;
        Test.stopTest();

        Rewards_Account__c raToVerify = [SELECT Id, Points_Total__c FROM Rewards_Account__c WHERE Id = :lstREsToInsert.get(0).Rewards_Account__c LIMIT 1];

        Integer expectedPointsTotal = 100 * 201;
        System.assertEquals(expectedPointsTotal, raToVerify.Points_Total__c, 'Unexpected points total');
    }

    
}