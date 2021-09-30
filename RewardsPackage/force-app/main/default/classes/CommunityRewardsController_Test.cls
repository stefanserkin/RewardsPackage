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
        Integer numIneligibleRewards = CommunityRewardsController.getIneligibleRewards(
            lstPRs.get(0).Rewards_Program__c, 
            raToVerify.Points_Total__c
        ).size();
        System.assertEquals(105, raToVerify.Points_Total__c, 'Points total unexpected: ' + raToVerify.Points_Total__c);
        System.assertEquals(
            1,
            numIneligibleRewards, 
            'Unexpected amount of ineligible rewards: ' + numIneligibleRewards
        );
    }

    @isTest
    static void testGetRewardsEvents() {
        List<Program_Reward__c> lstPRs  = RewardsTestDataFactory.createPerpetualProgramWithRewards(1);
        List<Contact> lstContacts       = RewardsTestDataFactory.createContacts(1, 1);
        Rewards_Account__c ra = RewardsTestDataFactory.createRewardsAccounts(lstContacts, lstPRs[0].Rewards_Program__c).get(0);

        Id awardRecTypeId = RewardsTestDataFactory.getRecordTypeId('Rewards_Event__c', 'Award');
        List<Rewards_Event__c> reList = new List<Rewards_Event__c>();
        reList.add( new Rewards_Event__c(Rewards_Account__c = ra.Id, Points__c = 100, RecordTypeId = awardRecTypeId, Description__c = 'Test Points') );
        reList.add( new Rewards_Event__c(Rewards_Account__c = ra.Id, Points__c = 100, RecordTypeId = awardRecTypeId, Description__c = 'Test Points') );
        insert reList;

        List<Rewards_Event__c> reListToVerify = CommunityRewardsController.getRewardsEvents(
            ra.Contact__c,
            ra.Rewards_Program__c
        );

        System.assertEquals(2, reListToVerify.size(), 'Unexpected amount of events');

    }

    @isTest
    static void testGetExpiredRewardsEvents() {
        List<Program_Reward__c> lstPRs  = RewardsTestDataFactory.createPerpetualProgramWithRewards(1);
        List<Contact> lstContacts       = RewardsTestDataFactory.createContacts(1, 1);
        Rewards_Account__c ra = RewardsTestDataFactory.createRewardsAccounts(lstContacts, lstPRs[0].Rewards_Program__c).get(0);

        Id awardRecTypeId = RewardsTestDataFactory.getRecordTypeId('Rewards_Event__c', 'Award');
        List<Rewards_Event__c> reList = new List<Rewards_Event__c>();
        Rewards_Event__c re  = new Rewards_Event__c(Rewards_Account__c = ra.Id, Points__c = 100, RecordTypeId = awardRecTypeId, Description__c = 'Test Points', Date__c = Datetime.now().addYears(-1));
        Rewards_Event__c re2 = new Rewards_Event__c(Rewards_Account__c = ra.Id, Points__c = 100, RecordTypeId = awardRecTypeId, Description__c = 'Test Points', Date__c = Datetime.now().addYears(-1));
        reList.add(re);
        reList.add(re2);
        insert reList;

        Id expRecTypeId = Schema.SObjectType.Rewards_Event__c.getRecordTypeInfosByDeveloperName().get('Expiration').getRecordTypeId();
        List<Rewards_Event_Link__c> lstRELsToInsert = new List<Rewards_Event_Link__c>();

        Rewards_Account__c raWithAwards = [
            SELECT Id, 
                   (SELECT Id, Points__c, Points_Remaining__c 
                      FROM Rewards_Events__r) 
              FROM Rewards_Account__c
             WHERE Id = :ra.Id
             LIMIT 1
        ];

        Decimal sumOfExpiringPts = 0;
        for (Rewards_Event__c event : raWithAwards.Rewards_Events__r) {
            if (event.Points_Remaining__c != null) {
                sumOfExpiringPts += event.Points_Remaining__c;
            }
        }

        Rewards_Event__c expEvent = new Rewards_Event__c(
            RecordTypeId            = expRecTypeId,
            Contact__c              = ra.Contact__c,
            Status__c               = 'Applied',
            Date__c                 = Datetime.now(),
            Description__c          = 'Points Expired',
            Rewards_Account__c      = ra.Id,
            Points__c               = sumOfExpiringPts,
            Rewards_Program_Name__c = ra.Rewards_Program__r.Name,
            Rewards_Program_ID__c   = ra.Rewards_Program__c
        );
        insert expEvent;

        for (Rewards_Event__c event : raWithAwards.Rewards_Events__r) {
            lstRELsToInsert.add(
                new Rewards_Event_Link__c(
                    Award_Event__c     = event.Id,
                    Deduction_Event__c = expEvent.Id,
                    Points_Used__c     = event.Points_Remaining__c,
                    Type__c            = 'Expiration'
                )
            );
        }
        insert lstRELsToInsert;

        List<Rewards_Event__c> resToVerify = CommunityRewardsController.getExpiredRewardsEvents(expEvent.Id);
        System.assertEquals(2, resToVerify.size(), 'Received unexpected amount of expired events');

    }

    @isTest
    static void testGetRewardsAccount() {
        List<Program_Reward__c> lstPRs  = RewardsTestDataFactory.createPerpetualProgramWithRewards(1);
        List<Contact> lstContacts       = RewardsTestDataFactory.createContacts(1, 1);
        Rewards_Account__c ra           = RewardsTestDataFactory.createRewardsAccounts(lstContacts, lstPRs[0].Rewards_Program__c).get(0);

        Id awardRecTypeId = Schema.SObjectType.Rewards_Event__c.getRecordTypeInfosByDeveloperName().get('Award').getRecordTypeId();
        Rewards_Event__c re = new Rewards_Event__c(
            Rewards_Account__c = ra.Id, 
            Points__c          = 105, 
            RecordTypeId       = awardRecTypeId,
            Description__c     = 'Test Points'
        );
        insert re;

        Id ctId = lstContacts[0].Id;
        Id rpId = lstPRs[0].Rewards_Program__c;
        Rewards_Account__c raToVerify = CommunityRewardsController.getRewardsAccount(ctId, rpId);

        System.assertEquals(105, raToVerify.Points_Total__c, 'Unexpected points total for rewards account');
    }

}