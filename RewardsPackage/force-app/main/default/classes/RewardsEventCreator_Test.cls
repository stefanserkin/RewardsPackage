@isTest
private class RewardsEventCreator_Test {

    @TestSetup
    static void setupData(){
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
            String rewardsProgramId = assignToCurrentProgram ? rp2.Id : rp3.Id;
            lstProgramRewards.add(
                new Program_Reward__c(Reward__c=reward.Id, Rewards_Program__c=rewardsProgramId)
            );
        }
        insert lstProgramRewards;

        Contact ct = new Contact(FirstName='David', LastName='Wright', Email='thecaptain@mets.com');
        insert ct;

        List<Rewards_Account__c> lstRewardAccounts = new List<Rewards_Account__c>();
        for (Rewards_Program__c rewPro : lstRewardsPrograms) {
            lstRewardAccounts.add(
                new Rewards_Account__c(Contact__c=ct.Id, Rewards_Program__c=rewPro.Id, Points_Total__c=0, Status__c=rewPro.Status__c)
            );
        }
        insert lstRewardAccounts;

    }

    @isTest
    static void testCreateBasicPointsAward() {

        Rewards_Account__c ra = [SELECT Id, Contact__c, Rewards_Program__c FROM Rewards_Account__c WHERE Rewards_Program__r.Name LIKE '%Perpetual%' LIMIT 1];

        RewardsEventCreator.Request request;
        request = new RewardsEventCreator.Request();
        request.contactId        = ra.Contact__c;
        request.description      = 'Test 100 points';
        request.points           = 100;
        request.rewardsProgramId = ra.Rewards_Program__c;
        request.relatedEntityId  = ra.Contact__c;

        Test.startTest();
        RewardsEventCreator.createRewardsEvent(
            new List<RewardsEventCreator.Request>{ request }
        );
        Test.stopTest();

        Rewards_Account__c raToVerify = [SELECT Id, Contact__c, Rewards_Program__c, Points_Total__c, 
                                                (SELECT Id 
                                                   FROM Rewards_Events__r)
                                           FROM Rewards_Account__c 
                                          WHERE Rewards_Program__r.Name LIKE '%Perpetual%' LIMIT 1];

        System.assertEquals(100, raToVerify.Points_Total__c, 'Unexpected points total');

    }

    @isTest
    static void testCreateMultiplePointsAwards() {

        List<Rewards_Account__c> raList  = [SELECT Id, Contact__c, Rewards_Program__c 
                                              FROM Rewards_Account__c 
                                             WHERE Rewards_Program__r.Name LIKE '%Perpetual%' 
                                                OR Rewards_Program__r.Name LIKE '%Coming%' 
                                             ORDER BY Rewards_Program__r.Name DESC 
                                             LIMIT 2];

        RewardsEventCreator.Request request;
        request = new RewardsEventCreator.Request();
        request.contactId        = raList[0].Contact__c;
        request.description      = 'Test 100 points';
        request.points           = 100;
        request.rewardsProgramId = raList[0].Rewards_Program__c;
        request.relatedEntityId  = raList[0].Contact__c;

        RewardsEventCreator.Request request2;
        request2 = new RewardsEventCreator.Request();
        request2.contactId        = raList[0].Contact__c;
        request2.description      = 'Test 200 points';
        request2.points           = 200;
        request2.rewardsProgramId = raList[1].Rewards_Program__c;
        request2.relatedEntityId  = raList[0].Contact__c;

        Test.startTest();
        RewardsEventCreator.createRewardsEvent(
            new List<RewardsEventCreator.Request>{ request }
        );

        RewardsEventCreator.createRewardsEvent(
            new List<RewardsEventCreator.Request>{ request2 }
        );
        Test.stopTest();

        List<Rewards_Account__c> rasToVerify = [SELECT Id, Contact__c, Rewards_Program__c, Points_Total__c, 
                                                       (SELECT Id 
                                                          FROM Rewards_Events__r)
                                                  FROM Rewards_Account__c 
                                                 WHERE Contact__c = :raList.get(0).Contact__c
                                                   AND (Rewards_Program__r.Name LIKE '%Perpetual%' 
                                                    OR Rewards_Program__r.Name LIKE '%Coming%')
                                                 ORDER BY Rewards_Program__r.Name DESC
                                                 LIMIT 2];

        System.assertEquals(100, rasToVerify[0].Points_Total__c, 'Unexpected points total');
        System.assertEquals(200, rasToVerify[1].Points_Total__c, 'Unexpected points total');

    }

}