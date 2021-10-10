@isTest
public with sharing class RewardsAccountHandler_Test {

    @TestSetup
    static void setupTestData(){
        Id perpetualRecordTypeId = Schema.SObjectType.Rewards_Program__c.getRecordTypeInfosByDeveloperName().get('Perpetual').getRecordTypeId();
        Id limitedRecordTypeId   = Schema.SObjectType.Rewards_Program__c.getRecordTypeInfosByDeveloperName().get('Limited_Duration').getRecordTypeId();

        Account acc = new Account(Name='Test Household');
        insert acc;

        Contact ct = new Contact(FirstName='Testing', LastName='Test', Email='testingrewards@test.com', AccountId=acc.Id);
        insert ct;

        Rewards_Program__c rpForNaming = new Rewards_Program__c(Name='Evergreen Testing', Status__c='Active', RecordTypeId=perpetualRecordTypeId);
        insert rpForNaming;

        Id perpetualProgramRecTypeId = Schema.SObjectType.Rewards_Program__c.getRecordTypeInfosByDeveloperName().get('Perpetual').getRecordTypeId();
        Id limitedProgramRecTypeId   = Schema.SObjectType.Rewards_Program__c.getRecordTypeInfosByDeveloperName().get('Limited_Duration').getRecordTypeId();

        List<Rewards_Program__c> lstRewardsPrograms = new List<Rewards_Program__c>();
        Rewards_Program__c rp  = new Rewards_Program__c(Name='Perpetual Program', Status__c = 'Active', Days_Until_Points_Expire__c=100, RecordTypeId=perpetualProgramRecTypeId);
        Rewards_Program__c rp2 = new Rewards_Program__c(Name='Short Time Program', Status__c = 'Active', RecordTypeId=limitedProgramRecTypeId, Start_Datetime__c=Date.today().addDays(-10), End_Datetime__c=Date.today().addDays(10));
        Rewards_Program__c rp3 = new Rewards_Program__c(Name='Coming Up Rewards', Status__c = 'Pending', RecordTypeId=limitedProgramRecTypeId, Start_Datetime__c=Date.today().addDays(10), End_Datetime__c=Date.today().addDays(30));
        lstRewardsPrograms.add(rp);
        lstRewardsPrograms.add(rp2);
        lstRewardsPrograms.add(rp3);
        insert lstRewardsPrograms;

        List<Reward__c> lstRewards = new List<Reward__c>();
        for (Integer i = 0; i < 10; i++) {
            lstRewards.add(
                new Reward__c(Name='Great Test Prize '+String.valueOf(i), Cost__c=100, Active__c = true)
            );
        }
        insert lstRewards;

        List<Program_Reward__c> lstProgramRewards = new List<Program_Reward__c>();
        Boolean assignToCurrentProgram = true;
        for (Reward__c reward : lstRewards) {
            String rewardsProgramId = assignToCurrentProgram ? rp.Id : rp3.Id;
            lstProgramRewards.add(
                new Program_Reward__c(Reward__c=reward.Id, Rewards_Program__c=rewardsProgramId)
            );
        }
        insert lstProgramRewards;

        Contact ct2 = new Contact(FirstName='David', LastName='Wright', Email='thecaptain@mets.com');
        insert ct2;

        List<Rewards_Account__c> lstRewardAccounts = new List<Rewards_Account__c>();
        for (Rewards_Program__c rewPro : lstRewardsPrograms) {
            lstRewardAccounts.add(
                new Rewards_Account__c(Contact__c=ct.Id, Rewards_Program__c=rewPro.Id, Points_Total__c=0, Status__c=rewPro.Status__c)
            );
        }
        insert lstRewardAccounts;

        List<Rewards_Event__c> lstRewardsEvents = new List<Rewards_Event__c>();
        for (Integer i = 0; i < 5; i++) {
            Integer offset = i;
            if (i == 1) {
                offset = 6;
            }
            lstRewardsEvents.add(
                new Rewards_Event__c(
                    Rewards_Account__c    = lstRewardAccounts.get(0).Id,
                    Description__c        = String.valueOf(i),
                    Points__c             = i,
                    Rewards_Program_ID__c = lstRewardsPrograms.get(0).Id,
                    Status__c             = 'Active',
                    Date__c               = Date.today().addDays(-offset)
                )
            );
        }
        insert lstRewardsEvents;
    }

    @isTest
    static void testRewardsAccountNaming() {
        Contact ct = [SELECT Id, FirstName FROM Contact LIMIT 1];
        Rewards_Program__c rp = [SELECT Id, Name FROM Rewards_Program__c WHERE Name LIKE '%Evergreen%' LIMIT 1];

        Rewards_Account__c ra = new Rewards_Account__c();
        ra.Contact__c = ct.Id;
        ra.Rewards_Program__c = rp.Id;
        ra.Status__c = 'Active';

        Test.startTest();
        Database.SaveResult sr = Database.insert(ra, false);
        Test.stopTest();

        System.assert(sr.isSuccess(), 'Insert of rewards account was unsuccessful');

        Rewards_Account__c raToVerify = [SELECT Id, Name FROM Rewards_Account__c WHERE Id = :ra.Id LIMIT 1];

        String strExpectedName = ct.FirstName + '\'s ' + rp.Name + ' Rewards';
        System.assertEquals(strExpectedName, raToVerify.Name, 'Unexpected rewards account name');
    }

    @isTest
    static void testRewardsAccountQueryBySetofIds() {
        List<Rewards_Account__c> raList = [SELECT Id FROM Rewards_Account__c];

        Set<Id> setRewardsAccountIds = new Set<Id>();
        for (Rewards_Account__c ra : raList) {
            setRewardsAccountIds.add(ra.Id);
        }

        Map<Id, Rewards_Account__c> rasToVerify;

        Test.startTest();
        rasToVerify = RewardsAccountHandler.getRewardsAccountMap(setRewardsAccountIds);
        Test.stopTest();

        System.assertEquals(raList.size(), rasToVerify.size(), 'Query results were different than input');
        
    }

    @isTest
    static void testRewardsAccountQueryByListOfRes() {
        Rewards_Account__c ra = [SELECT Id,
                                        (SELECT Id, Rewards_Account__c
                                            FROM Rewards_Events__r) 
                                   FROM Rewards_Account__c
                                  WHERE Points_Total__c > 0
                                  LIMIT 1];
        
        Map<Id, Rewards_Event__c> mapRewardsEvents = new Map<Id, Rewards_Event__c>();
        for (Rewards_Event__c re : ra.Rewards_Events__r) {
            mapRewardsEvents.put(re.Id, re);
        }
                                  
        Map<Id, Rewards_Account__c> rasToVerify;

        Test.startTest();
        rasToVerify = RewardsAccountHandler.getRewardsAccountMap(mapRewardsEvents.values());
        Test.stopTest();

        System.assertEquals(ra.Id, rasToVerify.get(ra.Id).Id, 'Query results were unexpected');
        
    }

    @isTest
    static void testRewardsAccountQueryByMapOfRes() {
        Rewards_Account__c ra = [SELECT Id,
                                        (SELECT Id, Rewards_Account__c
                                            FROM Rewards_Events__r) 
                                   FROM Rewards_Account__c
                                  WHERE Points_Total__c > 0
                                  LIMIT 1];
        
        Map<Id, Rewards_Event__c> mapRewardsEvents = new Map<Id, Rewards_Event__c>();
        for (Rewards_Event__c re : ra.Rewards_Events__r) {
            mapRewardsEvents.put(re.Id, re);
        }
                                  
        Map<Id, Rewards_Account__c> rasToVerify;

        Test.startTest();
        rasToVerify = RewardsAccountHandler.getRewardsAccountMap(mapRewardsEvents);
        Test.stopTest();

        System.assertEquals(ra.Id, rasToVerify.get(ra.Id).Id, 'Query results were unexpected');
        
    }

    @isTest
    static void testReturnExistingRAsOnRequest() {
        List<Rewards_Account__c> raList = [SELECT Id,
                                                  (SELECT Id, Rewards_Account__c
                                                     FROM Rewards_Events__r) 
                                             FROM Rewards_Account__c
                                            WHERE Points_Total__c > 0];

        Set<Id> setRewardsAccountIds = new Set<Id>();
        for (Rewards_Account__c ra : raList) {
            setRewardsAccountIds.add(ra.Id);
        }

        Map<Id, Rewards_Event__c> mapRewardsEvents = new Map<Id, Rewards_Event__c>();
        for (Rewards_Account__c ra : raList) {
            for (Rewards_Event__c re : ra.Rewards_Events__r) {
                mapRewardsEvents.put(re.Id, re);
            }
        }

        Map<Id, Rewards_Account__c> raList1;
        Map<Id, Rewards_Account__c> raList2;
        Map<Id, Rewards_Account__c> raList3;
        Map<Id, Rewards_Account__c> raList4;

        raList1 = RewardsAccountHandler.getRewardsAccountMap(setRewardsAccountIds);

        Test.startTest();
        raList2 = RewardsAccountHandler.getRewardsAccountMap(setRewardsAccountIds);
        raList3 = RewardsAccountHandler.getRewardsAccountMap(mapRewardsEvents.values());
        raList4 = RewardsAccountHandler.getRewardsAccountMap(mapRewardsEvents);
        Test.stopTest();

        System.assertEquals(raList.size(), raList4.size(), 'Query results were different than input');
        
    }

    @isTest
    static void testRewardsAccountWithEventsQuery() {
        List<Rewards_Account__c> raList = [SELECT Id FROM Rewards_Account__c];

        Set<Id> setRewardsAccountIds = new Set<Id>();
        for (Rewards_Account__c ra : raList) {
            setRewardsAccountIds.add(ra.Id);
        }

        Map<Id, Rewards_Account__c> rasToVerify;
        Map<Id, Rewards_Account__c> rasToRequery;

        Test.startTest();
        rasToVerify  = RewardsAccountHandler.getRewardsAccountWithEventsMap(setRewardsAccountIds);
        rasToRequery = RewardsAccountHandler.getRewardsAccountWithEventsMap(setRewardsAccountIds);
        rasToRequery = RewardsAccountHandler.getRewardsAccountWithEventsMap(setRewardsAccountIds, false);
        rasToRequery = RewardsAccountHandler.getRewardsAccountWithEventsMap(setRewardsAccountIds, true);
        Test.stopTest();

        System.assertEquals(raList.size(), rasToVerify.size(), 'Query results were different than input');
        
    }

    @isTest
    static void testRAsWithEventsQueryByListOfRes() {
        Rewards_Account__c ra = [SELECT Id,
                                        (SELECT Id, Rewards_Account__c
                                            FROM Rewards_Events__r) 
                                   FROM Rewards_Account__c
                                  WHERE Points_Total__c > 0
                                  LIMIT 1];
        
        Map<Id, Rewards_Event__c> mapRewardsEvents = new Map<Id, Rewards_Event__c>();
        for (Rewards_Event__c re : ra.Rewards_Events__r) {
            mapRewardsEvents.put(re.Id, re);
        }
                                  
        Map<Id, Rewards_Account__c> rasToVerify;
        Map<Id, Rewards_Account__c> rasToRequery;

        Test.startTest();
        rasToVerify  = RewardsAccountHandler.getRewardsAccountWithEventsMap(mapRewardsEvents.values());
        rasToRequery = RewardsAccountHandler.getRewardsAccountWithEventsMap(mapRewardsEvents.values(), false);
        Test.stopTest();

        System.assertEquals(ra.Id, rasToVerify.get(ra.Id).Id, 'Query results were unexpected');
        System.assertEquals(1, rasToVerify.size(), 'Query result size was unexpected');
    }

    @isTest
    static void testGetRewardsAccountList() {
        Rewards_Account__c ra = [SELECT Id, Contact__c, Rewards_Program__c FROM Rewards_Account__c LIMIT 1];

        List<Rewards_Account__c> rasToVerify;

        Test.startTest();
        rasToVerify = RewardsAccountHandler.getRewardsAccountList(ra.Contact__c, ra.Rewards_Program__c);
        Test.stopTest();

        System.assertEquals(1, rasToVerify.size(), 'Query result size was unexpected');
        System.assertEquals(ra.Id, rasToVerify.get(0).Id, 'Query results were unexpected');
    }

    @isTest
    static void testGetActiveAwardsForRedemptions() {
        Rewards_Account__c ra = [SELECT Id, Contact__c, Rewards_Program__c 
                                   FROM Rewards_Account__c 
                                  WHERE Points_Total__c > 0
                                  LIMIT 1];
        Rewards_Program__c rp = [SELECT Id, 
                                        (SELECT Id, Reward__c, Cost__c
                                           FROM Program_Rewards__r)
                                   FROM Rewards_Program__c
                                  WHERE Id = :ra.Rewards_Program__c
                                  LIMIT 1];

        insert new Rewards_Event__c(
            Rewards_Account__c    = ra.Id,
            Description__c        = 'Test Points to Cover',
            Points__c             = 100000,
            Rewards_Program_ID__c = ra.Rewards_Program__c,
            Status__c             = 'Active',
            Date__c               = Datetime.now()
        );

        Id redemptionRecTypeId = Schema.SObjectType.Rewards_Event__c
            .getRecordTypeInfosByDeveloperName().get('Redemption').getRecordTypeId();
        Rewards_Event__c redemption = new Rewards_Event__c(
            Rewards_Account__c    = ra.Id,
            Rewards_Program_ID__c = ra.Rewards_Program__c,
            Reward__c             = rp.Program_Rewards__r.get(0).Reward__c,
            Points__c             = rp.Program_Rewards__r.get(0).Cost__c,
            RecordTypeId          = redemptionRecTypeId
        );

        
        Database.SaveResult sr = Database.insert(redemption);
        System.assert(sr.isSuccess(), 'Could not insert redemption');

        Map<Id, Rewards_Event__c> mapRedemptionEvents = new Map<Id, Rewards_Event__c>();
        mapRedemptionEvents.put(redemption.Id, redemption);

        Test.startTest();
        Map<Id, Rewards_Account__c> mapRewardsAccountsToVerify;
        mapRewardsAccountsToVerify = RewardsAccountHandler.getActiveAwardsForRedemptions(mapRedemptionEvents);
        Test.stopTest();

        Boolean gotRewardsEvents = !mapRewardsAccountsToVerify.isEmpty();
        System.assert(gotRewardsEvents, 'Did not return any rewards event awards');
    }

    @isTest
    static void testInsertRAWithEmptyStatus() {
        Contact ct            = [SELECT Id FROM Contact LIMIT 1];
        Rewards_Program__c rp = [SELECT Id, Status__c FROM Rewards_Program__c LIMIT 1];

        Rewards_Account__c ra = new Rewards_Account__c(
            Contact__c=ct.Id, 
            Rewards_Program__c=rp.Id, 
            Points_Total__c=0
        );
        insert ra;

        Rewards_Account__c raToVerify = [SELECT Id, Status__c FROM Rewards_Account__c WHERE Id = :ra.Id LIMIT 1];
        System.assertEquals(rp.Status__c, raToVerify.Status__c, 'Rewards Account status was unexpected');
    }

    @isTest
    static void testBypassTrigger() {
        Contact ct = [SELECT Id, FirstName FROM Contact LIMIT 1];
        Rewards_Program__c rp = [SELECT Id, Name FROM Rewards_Program__c WHERE Name LIKE '%Evergreen%' LIMIT 1];

        Rewards_Account__c ra = new Rewards_Account__c();
        ra.Contact__c = ct.Id;
        ra.Rewards_Program__c = rp.Id;
        ra.Status__c = 'Active';
        ra.Name = 'Test Account';

        RewardsCommonUtilities.setTestObjectFound();
        RewardsCommonUtilities.setTestActive();
        RewardsCommonUtilities.setTestBypassAll();

        Test.startTest();
        Database.SaveResult sr = Database.insert(ra, false);
        Test.stopTest();

        System.assert(sr.isSuccess(), 'Insert of rewards account was unsuccessful');
    }

}