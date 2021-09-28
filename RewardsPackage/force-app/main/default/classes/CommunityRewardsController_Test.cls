@isTest
public class CommunityRewardsController_Test {
    
    @isTest
    static void testGetRewards() {
        List<Program_Reward__c> lstPRs = RewardsTestDataFactory.createPerpetualProgramWithRewards(5);
        List<Reward__c> lstRewards = CommunityRewardsController.getRewards(lstPRs.get(0).Rewards_Program__c);
        System.assertEquals(5, lstRewards.size(), 'Unexpected amount of rewards');
    }

    @isTest
    static void testGetEligibleRewards() {
        // Creates rewards at 100 and 110 points
        List<Program_Reward__c> lstPRs  = RewardsTestDataFactory.createPerpetualProgramWithRewards(2);
        List<Contact> lstContacts       = RewardsTestDataFactory.createContacts(1, 1);
        List<Rewards_Account__c> lstRAs = RewardsTestDataFactory.createRewardsAccounts(lstContacts, lstPRs[0].Rewards_Program__c);

        Id awardRecTypeId = RewardsTestDataFactory.getRecordTypeId('Rewards_Event__c', 'Award');

        Rewards_Event__c re = new Rewards_Event__c(
            Rewards_Account__c = lstRAs.get(0).Id, 
            Points__c          = 105, 
            RecordTypeId       = awardRecTypeId,
            Description__c     = 'Test Points'
        );
        insert re;

        Rewards_Account__c raToVerify = [SELECT Id, Points_Total__c FROM Rewards_Account__c WHERE Id = :re.Rewards_Account__c LIMIT 1];
        System.assertEquals(105, raToVerify.Points_Total__c, 'Points total unexpected: ' + raToVerify.Points_Total__c);
        System.assertEquals(
            1,
            CommunityRewardsController.getEligibleRewards(lstPRs.get(0).Rewards_Program__c, raToVerify.Points_Total__c).size(), 
            'Unexpected amount of eligible rewards: ' + CommunityRewardsController.getEligibleRewards(lstPRs.get(0).Rewards_Program__c, raToVerify.Points_Total__c).size()
        );

    }

    @isTest
    static void testGetIneligibleRewards() {
        // Creates rewards at 100 and 110 points
        List<Program_Reward__c> lstPRs  = RewardsTestDataFactory.createPerpetualProgramWithRewards(2);
        List<Contact> lstContacts       = RewardsTestDataFactory.createContacts(1, 1);
        List<Rewards_Account__c> lstRAs = RewardsTestDataFactory.createRewardsAccounts(lstContacts, lstPRs[0].Rewards_Program__c);

        Id awardRecTypeId = RewardsTestDataFactory.getRecordTypeId('Rewards_Event__c', 'Award');

        Rewards_Event__c re = new Rewards_Event__c(
            Rewards_Account__c = lstRAs.get(0).Id, 
            Points__c          = 105, 
            RecordTypeId       = awardRecTypeId,
            Description__c     = 'Test Points'
        );
        insert re;

        Rewards_Account__c raToVerify = [SELECT Id, Points_Total__c FROM Rewards_Account__c WHERE Id = :re.Rewards_Account__c LIMIT 1];
        System.assertEquals(105, raToVerify.Points_Total__c, 'Points total unexpected: ' + raToVerify.Points_Total__c);
        System.assertEquals(
            1,
            CommunityRewardsController.getIneligibleRewards(lstPRs.get(0).Rewards_Program__c, raToVerify.Points_Total__c).size(), 
            'Unexpected amount of ineligible rewards: ' + CommunityRewardsController.getIneligibleRewards(lstPRs.get(0).Rewards_Program__c, raToVerify.Points_Total__c).size()
        );
    }

    @isTest
    static void testGetRewardsEvents() {

    }

    @isTest
    static void testGetExpiredRewardsEvents() {

    }

    @isTest
    static void testGetRewardsAccount() {

    }

}
