@isTest
private class RewardsAccountController_Test {

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

        List<Rewards_Event__c> lstRewardsEvents = new List<Rewards_Event__c>();
        for (Integer i = 0; i < 5; i++) {
            Integer offset = -i;
            if (i == 1) {
                offset = -6;
            }
            lstRewardsEvents.add(
                new Rewards_Event__c(
                    Rewards_Account__c    = lstRewardAccounts.get(0).Id,
                    Description__c        = String.valueOf(i),
                    Points__c             = i,
                    Rewards_Program_ID__c = lstRewardsPrograms.get(0).Id,
                    Status__c             = 'Active',
                    Date__c               = Date.today().addDays(offset)
                )
            );
        }
        insert lstRewardsEvents;

    }
    
    @isTest
    static void testRecalculateRewardsAccount() {

        Rewards_Account__c ra = [SELECT Id FROM Rewards_Account__c WHERE Points_Total__c > 0 LIMIT 1];
        Test.startTest();
        RewardsAccountController.recalculateRewardsAccount(ra.Id);
        Test.stopTest();
        Rewards_Account__c rasToVerify = [SELECT Id, (SELECT Id, Description__c, Points__c, Points_Balance__c FROM Rewards_Events__r ORDER BY Date__c ASC) FROM Rewards_Account__c WHERE Points_Total__c > 0 LIMIT 1];
        System.assertEquals(1, rasToVerify.Rewards_Events__r.get(0).Points_Balance__c, 'Reordering unexpected');

    }

}
