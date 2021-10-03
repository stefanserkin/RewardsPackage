@isTest
public class RewardsTestDataFactory {

    private static Id rpPerpetualRecTypeId = Schema.SObjectType.Rewards_Program__c.getRecordTypeInfosByDeveloperName().get('Perpetual').getRecordTypeId();
    private static Id rpLimitedRecTypeId   = Schema.SObjectType.Rewards_Program__c.getRecordTypeInfosByDeveloperName().get('Limited_Duration').getRecordTypeId();
    private static Id awardRecTypeId       = Schema.SObjectType.Rewards_Event__c.getRecordTypeInfosByDeveloperName().get('Award').getRecordTypeId();
    private static Id redemptionRecTypeId  = Schema.SObjectType.Rewards_Event__c.getRecordTypeInfosByDeveloperName().get('Redemption').getRecordTypeId();

    public static List<Program_Reward__c> createPerpetualProgramWithRewards(
        Integer numRewards
    ) {
        Rewards_Program__c rp = new Rewards_Program__c(
            Name                        = 'Perpetual Program Test',
            Days_Until_Points_Expire__c = 365,
            Status__c                   = 'Active',
            RecordTypeId                = rpPerpetualRecTypeId
        );
        insert rp;

        List<Reward__c> lstRewards = new List<Reward__c>();
        for (Integer i = 0; i < numRewards; i++) {
            lstRewards.add(
                new Reward__c(
                    Name    = 'Test Reward ' + String.valueOf(i),
                    Cost__c = 100 + (i * 10),
                    Active__c = true
                )
            );
        }
        insert lstRewards;

        List<Program_Reward__c> lstProgramRewards = new List<Program_Reward__c>();
        for (Reward__c r : lstRewards) {
            lstProgramRewards.add(
                new Program_Reward__c(
                    Reward__c          = r.Id,
                    Rewards_Program__c = rp.Id
                )
            );
        }
        insert lstProgramRewards;
        return lstProgramRewards;
    }

    public static List<Contact> createContacts(
        Integer numAccounts, 
        Integer numContactsPerAccount
    ) {
        Id accHHRecTypeId = Schema.SObjectType.Account
            .getRecordTypeInfosByDeveloperName().get('HH_Account')?.getRecordTypeId();
            
        List<Account> lstAccounts = new List<Account>();
        for (Integer i = 0; i < numAccounts; i++) {
            Account a = new Account();
            a.Name = 'Test' + String.valueOf(i) + ' Household';
            if (accHHRecTypeId != null) {
                a.RecordTypeId = accHHRecTypeId;
            }
            lstAccounts.add(a);
        }
        insert lstAccounts;

        List<Contact> lstContacts = new List<Contact>();
        for (Account acc : lstAccounts) {
            for (Integer i = 0; i < numContactsPerAccount; i++) {
                lstContacts.add(
                    new Contact(
                        AccountId = acc.Id,
                        FirstName = 'Testing',
                        LastName  = 'Test' + String.valueOf(i),
                        Email     = 'testingtest'+String.valueOf(i)+'@testeroo.com'
                    )
                );
            }
        }
        insert lstContacts;
        return lstContacts;
    }

    public static List<Rewards_Account__c> createRewardsAccounts(
        List<Contact> lstContacts,
        Id rewardsProgramId
    ) {
        List<Rewards_Account__c> lstRewardsAccounts = new List<Rewards_Account__c>();
        for (Contact ct : lstContacts) {
            lstRewardsAccounts.add(
                new Rewards_Account__c(
                    Contact__c = ct.Id,
                    Rewards_Program__c = rewardsProgramId,
                    Points_Total__c = 0
                )
            );
        }
        insert lstRewardsAccounts;
        return lstRewardsAccounts;
    }



    public static Rewards_Account__c createRewardsEventsForRA(
        Rewards_Account__c ra, Integer numAwards, Integer numRedemptions
    ) {
        Program_Reward__c pr = [SELECT Id, Reward__c, Reward__r.Cost__c FROM Program_Reward__c WHERE Rewards_Program__c = :ra.Rewards_Program__c LIMIT 1];
        Id rewardId = pr.Reward__c;
        Decimal rewardCost = pr.Reward__r.Cost__c;
        List<Rewards_Event__c> lstAwards      = new List<Rewards_Event__c>();
        List<Rewards_Event__c> lstRedemptions = new List<Rewards_Event__c>();
        // Awards
        for (Integer i = 0; i < numAwards; i++) {
            lstAwards.add(
                new Rewards_Event__c(
                    Rewards_Account__c = ra.Id, 
                    Points__c          = 200, 
                    RecordTypeId       = awardRecTypeId,
                    Description__c     = 'Test Points',
                    // stagger dates in 5 day increments
                    Date__c            = Date.today().addDays(-(i*5))
                )
            );
        }
        insert lstAwards;
        // Redemptions
        for (Integer i = 0; i < numRedemptions; i++) {
            lstRedemptions.add(
                new Rewards_Event__c(
                    Rewards_Account__c = ra.Id,
                    Reward__c          = rewardId,
                    Points__c          = rewardCost, 
                    RecordTypeId       = redemptionRecTypeId,
                    Description__c     = 'Test Redemption',
                    // stagger dates in 5 day increments
                    Date__c            = Date.today().addDays(-(i))
                )
            );
        }
        insert lstRedemptions;

        return [SELECT Id, Rewards_Program__c, Points_Total__c, 
                       Status__c, Contact__c, End_Datetime__c,
                       (SELECT Id, Rewards_Account__c, Reward__c, Points__c, RecordTypeId, 
                               Description__c, Expired__c, Expiration_Date__c, Points_Used__c,
                               Points_Expired__c, Points_Remaining__c, Type__c
                          FROM Rewards_Events__r
                         ORDER BY Date__c ASC) 
                  FROM Rewards_Account__c
                 WHERE Id = :ra.Id
                 LIMIT 1];
    }

    public static Id getRecordTypeId(String obj, String developerName) {
        return [SELECT Id FROM RecordType WHERE SobjectType = :obj AND DeveloperName = :developerName LIMIT 1].Id;
    }

    public static Boolean isAvailableField(String sObjectAPIName, String fieldAPIName) {
        // Call to get the appropriate object's describe
        Map<String, Schema.SObjectType> mapGlobalDescribe = Schema.getGlobalDescribe();
        Schema.SObjectType objSObjectType = mapGlobalDescribe.get(sObjectAPIName);
    
        // Field describe
        Schema.DescribeSObjectResult objectDescribe = objSObjectType.getDescribe();
        Map<String, Schema.SObjectField> mapFieldDescribe = 
            objSObjectType.getDescribe().fields.getMap();
    
        // Check if field exists in describe call
        return mapFieldDescribe.containsKey(fieldAPIName);
    }


}