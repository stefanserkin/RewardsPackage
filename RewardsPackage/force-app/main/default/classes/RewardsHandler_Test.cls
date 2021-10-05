@isTest
public class RewardsHandler_Test {

    private static Id redemptionRecTypeId = Schema.SObjectType.Rewards_Event__c
        .getRecordTypeInfosByDeveloperName().get('Redemption').getRecordTypeId();
    
    @isTest
    static void testGetRewardsMapFromListREs() {
        List<Program_Reward__c> lstPRs  = RewardsTestDataFactory.createPerpetualProgramWithRewards(5);
        List<Contact> lstContacts       = RewardsTestDataFactory.createContacts(1, 1);
        List<Rewards_Account__c> lstRAs = RewardsTestDataFactory.createRewardsAccounts(lstContacts, lstPRs[0].Rewards_Program__c);
        List<Rewards_Event__c> lstRedemptions = new List<Rewards_Event__c>();
        lstRedemptions.add(
            new Rewards_Event__c(
                RecordTypeId   = redemptionRecTypeId,
                Reward__c      = lstPRs.get(0).Reward__c,
                Points__c      = lstPRs.get(0).Cost__c,
                Description__c = 'Test Redemption'
            )
        );
        Test.startTest();
        Map<Id, Reward__c> mapRewards = RewardsHandler.getRewardsMap(lstRedemptions);
        Test.stopTest();

        System.assertEquals(true, !mapRewards.isEmpty(), 'No rewards were returned');

    }

    @isTest
    static void testGetRewardsMapFromSetIds() {
        List<Program_Reward__c> lstPRs  = RewardsTestDataFactory.createPerpetualProgramWithRewards(1);
        Set<Id> setRewardIds = new Set<Id>();
        for (Program_Reward__c pr : lstPRs) {
            setRewardIds.add(pr.Reward__c);
        }

        Test.startTest();
        Map<Id, Reward__c> mapRewards = RewardsHandler.getRewardsMap(setRewardIds);
        Test.stopTest();

        System.assertEquals(true, !mapRewards.isEmpty(), 'No rewards were returned');

    }

    @isTest
    static void testGetRewardsAgain() {
        List<Program_Reward__c> lstPRs  = RewardsTestDataFactory.createPerpetualProgramWithRewards(5);
        List<Contact> lstContacts       = RewardsTestDataFactory.createContacts(1, 1);
        List<Rewards_Account__c> lstRAs = RewardsTestDataFactory.createRewardsAccounts(lstContacts, lstPRs[0].Rewards_Program__c);
        
        List<Rewards_Event__c> lstRedemptions = new List<Rewards_Event__c>();
        lstRedemptions.add(
            new Rewards_Event__c(
                RecordTypeId   = redemptionRecTypeId,
                Reward__c      = lstPRs.get(0).Reward__c,
                Points__c      = lstPRs.get(0).Cost__c,
                Description__c = 'Test Redemption'
            )
        );

        Set<Id> setRewardIds = new Set<Id>();
        for (Program_Reward__c pr : lstPRs) {
            setRewardIds.add(pr.Reward__c);
        }

        Map<Id, Reward__c> mapRewards = RewardsHandler.getRewardsMap(setRewardIds);
        Test.startTest();
        mapRewards = RewardsHandler.getRewardsMap(setRewardIds);
        mapRewards = RewardsHandler.getRewardsMap(lstRedemptions);
        Test.stopTest();

        System.assertEquals(true, !mapRewards.isEmpty(), 'No rewards were returned');

    }
}