@isTest
public with sharing class RewardsEventHandler_Test {

    private static Id rpPerpetualRecTypeId = Schema.SObjectType.Rewards_Program__c.getRecordTypeInfosByDeveloperName().get('Perpetual').getRecordTypeId();

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

    @isTest
    static void testInsertAwardOutOfOrder() {
        List<Program_Reward__c> lstPRs  = RewardsTestDataFactory.createPerpetualProgramWithRewards(1);
        List<Contact> lstContacts       = RewardsTestDataFactory.createContacts(1, 1);
        List<Rewards_Account__c> lstRAs = RewardsTestDataFactory.createRewardsAccounts(lstContacts, lstPRs[0].Rewards_Program__c);

        Id awardRecTypeId = RewardsTestDataFactory.getRecordTypeId('Rewards_Event__c', 'Award');
        List<Rewards_Event__c> reList = new List<Rewards_Event__c>();
        reList.add( new Rewards_Event__c(Rewards_Account__c = lstRAs.get(0).Id, Points__c = 100, RecordTypeId = awardRecTypeId, Description__c = 'Test Points Now') );
        reList.add( new Rewards_Event__c(Rewards_Account__c = lstRAs.get(0).Id, Points__c = 100, RecordTypeId = awardRecTypeId, Description__c = 'Test Points Now') );
        insert reList;

        Rewards_Event__c re = new Rewards_Event__c(
            Rewards_Account__c = lstRAs.get(0).Id, 
            Points__c          = 100, 
            RecordTypeId       = awardRecTypeId, 
            Description__c     = 'Test Points Yesterday', 
            Date__c            = Datetime.now().addDays(-1)
        );

        Test.startTest();
        Database.SaveResult sr = Database.insert(re, false);
        Test.stopTest();

        System.assert(sr.isSuccess(), 'Failed to insert rewards event');

        Rewards_Account__c raToVerify = [SELECT Id, 
                                                Points_Total__c, 
                                                (SELECT Id, Description__c, Points__c 
                                                   FROM Rewards_Events__r 
                                                  ORDER BY Date__c ASC) 
                                           FROM Rewards_Account__c 
                                          WHERE Id = :re.Rewards_Account__c 
                                          LIMIT 1];

        Rewards_Event__c oldestEvent = raToVerify.Rewards_Events__r.get(0);

        System.assertEquals(300, raToVerify.Points_Total__c, 'Unexpected points total');
        System.assertEquals('Test Points Yesterday', oldestEvent.Description__c, 'Oldest event unexpected');

    }

    @isTest
    static void testGetMapRewardsEventsToUpdate() {
        List<Program_Reward__c> lstPRs  = RewardsTestDataFactory.createPerpetualProgramWithRewards(1);
        List<Contact> lstContacts       = RewardsTestDataFactory.createContacts(1, 1);
        List<Rewards_Account__c> lstRAs = RewardsTestDataFactory.createRewardsAccounts(lstContacts, lstPRs[0].Rewards_Program__c);
        Rewards_Account__c raWithEvents = RewardsTestDataFactory.createRewardsEventsForRA(lstRAs[0], 10, 0);

        Test.startTest();
        Map<Id, Rewards_Event__c> mapRewardsEventsToUpdate = RewardsEventHandler.getMapRewardsEventsToUpdate();
        mapRewardsEventsToUpdate = RewardsEventHandler.getMapRewardsEventsToUpdate();
        Test.stopTest();

        System.assert(mapRewardsEventsToUpdate.isEmpty(), 'Rewards Events to update map is not empty');
    }

    @isTest
    static void testSetRecordTypeIds() {
        Id redemptionRecordTypeId = Schema.SObjectType.Rewards_Event__c.getRecordTypeInfosByDeveloperName().get('Redemption').getRecordTypeId();
        Id awardRecordTypeId      = Schema.SObjectType.Rewards_Event__c.getRecordTypeInfosByDeveloperName().get('Award').getRecordTypeId();
        Id expirationRecordTypeId = Schema.SObjectType.Rewards_Event__c.getRecordTypeInfosByDeveloperName().get('Expiration').getRecordTypeId();

        Id redemptionRecTypeIdToVerify   = RewardsEventHandler.getRedemptionRecordTypeId();
        Id confirmRedemptionRecordTypeId = RewardsEventHandler.getRedemptionRecordTypeId();

        Id awardRecordTypeIdToVerify = RewardsEventHandler.getAwardRecordTypeId();
        Id confirmAwardRecordTypeId  = RewardsEventHandler.getAwardRecordTypeId();

        Id expirationRecordTypeIdToVerify = RewardsEventHandler.getExpirationRecordTypeId();
        Id confirmExpirationRecordTypeId  = RewardsEventHandler.getExpirationRecordTypeId();

        System.assertEquals(redemptionRecTypeIdToVerify, confirmRedemptionRecordTypeId, 'Received different id on second request');
        System.assertEquals(awardRecordTypeIdToVerify, confirmAwardRecordTypeId, 'Received different id on second request');
        System.assertEquals(expirationRecordTypeIdToVerify, confirmExpirationRecordTypeId, 'Received different id on second request');
        System.assertEquals(redemptionRecordTypeId, redemptionRecTypeIdToVerify, 'Received different id from schema');
        System.assertEquals(awardRecordTypeId, awardRecordTypeIdToVerify, 'Received different id from schema');
        System.assertEquals(expirationRecordTypeId, expirationRecordTypeIdToVerify, 'Received different id from schema');

    }

    @isTest
    static void testGetRedemptionRecordTypeIdAgain() {
        Id redemptionRecordTypeId        = Schema.SObjectType.Rewards_Event__c.getRecordTypeInfosByDeveloperName().get('Redemption').getRecordTypeId();
        Id redemptionRecTypeIdToVerify   = RewardsEventHandler.getRedemptionRecordTypeId();
        Id confirmRedemptionRecordTypeId = RewardsEventHandler.getRedemptionRecordTypeId();
        System.assertEquals(redemptionRecTypeIdToVerify, confirmRedemptionRecordTypeId, 'Received different id on second request');
        System.assertEquals(redemptionRecordTypeId, redemptionRecTypeIdToVerify, 'Received different id from schema');
    }

    @isTest
    static void testGetAwardRecordTypeIdAgain() {
        Id awardRecordTypeId         = Schema.SObjectType.Rewards_Event__c.getRecordTypeInfosByDeveloperName().get('Award').getRecordTypeId();
        Id awardRecordTypeIdToVerify = RewardsEventHandler.getAwardRecordTypeId();
        Id confirmAwardRecordTypeId  = RewardsEventHandler.getAwardRecordTypeId();
        System.assertEquals(awardRecordTypeIdToVerify, confirmAwardRecordTypeId, 'Received different id on second request');
        System.assertEquals(awardRecordTypeId, awardRecordTypeIdToVerify, 'Received different id from schema');
    }

    @isTest
    static void testGetExpirationRecordTypeIdAgain() {
        Id expirationRecordTypeId         = Schema.SObjectType.Rewards_Event__c.getRecordTypeInfosByDeveloperName().get('Expiration').getRecordTypeId();
        Id expirationRecordTypeIdToVerify = RewardsEventHandler.getExpirationRecordTypeId();
        Id confirmExpirationRecordTypeId  = RewardsEventHandler.getExpirationRecordTypeId();
        System.assertEquals(expirationRecordTypeIdToVerify, confirmExpirationRecordTypeId, 'Received different id on second request');
        System.assertEquals(expirationRecordTypeId, expirationRecordTypeIdToVerify, 'Received different id from schema');
    }

    @isTest
    static void testAddToMapToUpdateFromRecord() {
        List<Program_Reward__c> lstPRs  = RewardsTestDataFactory.createPerpetualProgramWithRewards(1);
        List<Contact> lstContacts       = RewardsTestDataFactory.createContacts(1, 1);
        List<Rewards_Account__c> lstRAs = RewardsTestDataFactory.createRewardsAccounts(lstContacts, lstPRs[0].Rewards_Program__c);
        Id awardRecordTypeId         = Schema.SObjectType.Rewards_Event__c.getRecordTypeInfosByDeveloperName().get('Award').getRecordTypeId();
        Rewards_Event__c re = new Rewards_Event__c(
            Rewards_Account__c = lstRAs.get(0).Id, 
            Points__c          = 100, 
            RecordTypeId       = awardRecordTypeId, 
            Description__c     = 'Test Points To Add', 
            Date__c            = Datetime.now().addDays(-1)
        );
        insert re;
        Test.startTest();
        RewardsEventHandler.addToMapToUpdate(re);
        Test.stopTest();
        Map<Id, Rewards_Event__c> mapRewardsEvents = RewardsEventHandler.getMapRewardsEventsToUpdate();
        System.assertEquals(
            'Test Points To Add', 
            mapRewardsEvents.get(re.Id).Description__c, 
            'Rewards Event was not in map to update'
        );
    }

    @isTest
    static void testAddToMapToUpdateFromList() {
        List<Program_Reward__c> lstPRs  = RewardsTestDataFactory.createPerpetualProgramWithRewards(1);
        List<Contact> lstContacts       = RewardsTestDataFactory.createContacts(1, 1);
        List<Rewards_Account__c> lstRAs = RewardsTestDataFactory.createRewardsAccounts(lstContacts, lstPRs[0].Rewards_Program__c);
        Id awardRecordTypeId            = Schema.SObjectType.Rewards_Event__c.getRecordTypeInfosByDeveloperName().get('Award').getRecordTypeId();
        List<Rewards_Event__c> lstREs   = new List<Rewards_Event__c>();
        for (Integer i = 0; i < 5; i++) {
            Rewards_Event__c re = new Rewards_Event__c(
                Rewards_Account__c = lstRAs.get(0).Id, 
                Points__c          = 100, 
                RecordTypeId       = awardRecordTypeId, 
                Description__c     = 'Test Points To Add', 
                Date__c            = Datetime.now().addDays(-1)
            );
            lstREs.add(re);
        }
        insert lstREs;

        Test.startTest();
        RewardsEventHandler.addToMapToUpdate(lstREs);
        Test.stopTest();

        Map<Id, Rewards_Event__c> mapRewardsEvents = RewardsEventHandler.getMapRewardsEventsToUpdate();
        for (Rewards_Event__c reToVerify : mapRewardsEvents.values()) {
            System.assertEquals(
                'Test Points To Add', 
                reToVerify.Description__c, 
                'Rewards Event was not in map to update'
            );
        }
        System.assertEquals(5, mapRewardsEvents.size(), 'Received unexpected number of rewards events in map');
    }

    @isTest
    static void testHandleInvokedRewardsEventCreation() {
        List<Program_Reward__c> lstPRs  = RewardsTestDataFactory.createPerpetualProgramWithRewards(1);
        Id rewardsProgramId             = lstPRs[0].Rewards_Program__c;
        List<Contact> lstCts            = RewardsTestDataFactory.createContacts(1, 1);
        Id contactId                    = lstCts.get(0).Id;
        List<Rewards_Account__c> lstRAs = RewardsTestDataFactory.createRewardsAccounts(lstCts, rewardsProgramId);

        Test.startTest();
        RewardsEventHandler.handleInvokedRewardsEventCreation(
            rewardsProgramId, 
            contactId, 
            50, 
            'Test points', 
            contactId, 
            25
        );
        Test.stopTest();
        Rewards_Account__c raWithEvents = [SELECT Id, Points_Total__c,
                                                  (SELECT Id, Points__c 
                                                     FROM Rewards_Events__r) 
                                             FROM Rewards_Account__c
                                            WHERE Contact__c = :contactId
                                              AND Rewards_Program__c = :rewardsProgramId
                                            LIMIT 1];
        System.assertEquals(50, raWithEvents.Rewards_Events__r.get(0).Points__c, 'Unexpected points from event');
        System.assertEquals(50, raWithEvents.Points_Total__c, 'Unexpected points from event');
    }

    @isTest
    static void testHandleInvokedRewardsEventCreationWithoutAccount() {
        List<Program_Reward__c> lstPRs  = RewardsTestDataFactory.createPerpetualProgramWithRewards(1);
        Id rewardsProgramId             = lstPRs[0].Rewards_Program__c;
        List<Contact> lstCts            = RewardsTestDataFactory.createContacts(1, 1);
        Id contactId                    = lstCts.get(0).Id;

        Test.startTest();
        RewardsEventHandler.handleInvokedRewardsEventCreation(
            rewardsProgramId, 
            contactId, 
            50, 
            'Test points', 
            contactId, 
            25
        );
        Test.stopTest();
        List<Rewards_Event__c> lstRewardsEventsToVerify = [SELECT Id FROM Rewards_Event__c];
        System.assert(lstRewardsEventsToVerify.isEmpty(), 'Rewards event was created');
    }

    @isTest
    static void testExpirationPoliciesRewardsProgramEndDate() {
        Rewards_Program__c rp = new Rewards_Program__c(
            Name                        = 'Program With End Date',
            Status__c                   = 'Active',
            RecordTypeId                = rpPerpetualRecTypeId,
            End_Datetime__c             = Datetime.now().addDays(10)
        );
        insert rp;
        List<Contact> lstCts            = RewardsTestDataFactory.createContacts(1, 1);
        Id contactId                    = lstCts.get(0).Id;
        List<Rewards_Account__c> lstRAs = RewardsTestDataFactory.createRewardsAccounts(lstCts, rp.Id);

        Test.startTest();
        RewardsEventHandler.handleInvokedRewardsEventCreation(
            rp.Id, 
            contactId, 
            50, 
            'Test points', 
            contactId,
            null
        );
        Test.stopTest();
        Rewards_Account__c raWithEvents = [SELECT Id, Points_Total__c,
                                                  (SELECT Id, Points__c, Expiration_Date__c
                                                     FROM Rewards_Events__r) 
                                             FROM Rewards_Account__c
                                            WHERE Contact__c = :contactId
                                              AND Rewards_Program__c = :rp.Id
                                            LIMIT 1];
        Date expectedDate = Date.today().addDays(10);
        System.assertEquals(expectedDate, raWithEvents.Rewards_Events__r.get(0).Expiration_Date__c, 'Unexpected expiration date from event');
    }

    @isTest
    static void testExpirationPoliciesRewardsProgramDaysToExpiration() {
        Rewards_Program__c rp = new Rewards_Program__c(
            Name                        = 'Program With End Date',
            Status__c                   = 'Active',
            RecordTypeId                = rpPerpetualRecTypeId,
            Days_Until_Points_Expire__c = 365
        );
        insert rp;
        List<Contact> lstCts            = RewardsTestDataFactory.createContacts(1, 1);
        Id contactId                    = lstCts.get(0).Id;
        List<Rewards_Account__c> lstRAs = RewardsTestDataFactory.createRewardsAccounts(lstCts, rp.Id);

        Test.startTest();
        RewardsEventHandler.handleInvokedRewardsEventCreation(
            rp.Id, 
            contactId, 
            50, 
            'Test points', 
            contactId,
            null 
        );
        Test.stopTest();
        Rewards_Account__c raWithEvents = [SELECT Id, Points_Total__c,
                                                  (SELECT Id, Points__c, Expiration_Date__c 
                                                     FROM Rewards_Events__r) 
                                             FROM Rewards_Account__c
                                            WHERE Contact__c = :contactId
                                              AND Rewards_Program__c = :rp.Id
                                            LIMIT 1];
        Date expectedDate = Date.today().addDays(365);
        System.assertEquals(expectedDate, raWithEvents.Rewards_Events__r.get(0).Expiration_Date__c, 'Unexpected expiration date from event');
    }

    @isTest
    static void testInsufficientPointsForRedemption() {
        List<Program_Reward__c> lstPRs  = RewardsTestDataFactory.createPerpetualProgramWithRewards(1);
        List<Contact> lstContacts       = RewardsTestDataFactory.createContacts(1, 1);
        Rewards_Account__c ra           = RewardsTestDataFactory.createRewardsAccounts(lstContacts, lstPRs[0].Rewards_Program__c).get(0);
        
        Rewards_Event__c redemption = new Rewards_Event__c(
            Rewards_Account__c = ra.Id, 
            RecordTypeId       = RewardsTestDataFactory.redemptionRecTypeId,
            Reward__c          = lstPRs.get(0).Reward__c,
            Status__c          = 'Pending',
            Points__c          = 100
        );
        Test.startTest();
        try {
            insert redemption;
        } catch (Exception e) {
            Boolean gotExpectedError = e.getMessage().contains('Not enough points') ? true : false;
            System.assert(gotExpectedError, 'Did not receive expected error');
        }
        Test.stopTest();
    }

    @isTest
    static void testSetEmptyAwardFields() {
        Rewards_Program__c rp = new Rewards_Program__c(
            Name                        = 'Test Program',
            Status__c                   = 'Active',
            RecordTypeId                = rpPerpetualRecTypeId,
            End_Datetime__c             = Datetime.now().addDays(30)
        );
        insert rp;
        List<Contact> lstContacts       = RewardsTestDataFactory.createContacts(1, 1);
        Rewards_Account__c ra           = RewardsTestDataFactory.createRewardsAccounts(lstContacts, rp.Id).get(0);
        Rewards_Event__c re = new Rewards_Event__c(
            Rewards_Account__c = ra.Id, 
            RecordTypeId       = RewardsTestDataFactory.awardRecTypeId
        );
        Test.startTest();
        insert re;
        Test.stopTest();
        Rewards_Event__c reRefreshed = [SELECT Id, Description__c, Status__c, Points__c, Points_Used__c, Points_Expired__c
                                          FROM Rewards_Event__c
                                         WHERE Rewards_Account__c = :ra.Id
                                         LIMIT 1];
        String expectedDescription = 'Test Program Points';
        String expectedStatus      = 'Active';
        Decimal expectedPoints     = 0;
        System.assertEquals(expectedDescription, reRefreshed.Description__c, 'Received unexpected description');
        System.assertEquals(expectedStatus, reRefreshed.Status__c, 'Received unexpected status');
        System.assertEquals(expectedPoints, reRefreshed.Points__c, 'Received unexpected points');
    }

    @isTest
    static void testSetEmptyRedemptionFields() {
        List<Program_Reward__c> lstPRs  = RewardsTestDataFactory.createPerpetualProgramWithRewards(5);
        List<Contact> lstContacts       = RewardsTestDataFactory.createContacts(1, 1);
        Rewards_Account__c ra           = RewardsTestDataFactory.createRewardsAccounts(lstContacts, lstPRs[0].Rewards_Program__c).get(0);
        Id redemptionRecTypeId          = RewardsTestDataFactory.redemptionRecTypeId;
        Id rewardId                     = lstPRs.get(0).Reward__c;

        Rewards_Event__c re = new Rewards_Event__c(
            Rewards_Account__c = ra.Id, 
            RecordTypeId       = RewardsTestDataFactory.awardRecTypeId,
            Points__c          = 100000,
            Description__c     = 'Test Redemption Coverage'
        );
        insert re;

        Rewards_Event__c redemption = new Rewards_Event__c(
            Rewards_Account__c = ra.Id, 
            RecordTypeId       = redemptionRecTypeId,
            Reward__c          = rewardId,
            Status__c          = 'Pending'
        );
        Test.startTest();
        insert redemption;
        Test.stopTest();
        Rewards_Event__c redemptionRefreshed = [SELECT Id, Points__c, Reward__r.Cost__c
                                                  FROM Rewards_Event__c
                                                 WHERE Rewards_Account__c = :ra.Id
                                                   AND RecordTypeId = :redemptionRecTypeId
                                                 LIMIT 1];
        System.assertEquals(redemptionRefreshed.Reward__r.Cost__c, redemptionRefreshed.Points__c, 'Received unexpected points');
    }
    
}