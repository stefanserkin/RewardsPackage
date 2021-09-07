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

        Rewards_Program__c rp = new Rewards_Program__c(Name='Evergreen Testing', Status__c='Active', RecordTypeId=perpetualRecordTypeId);
        insert rp;
    }

    @isTest
    static void testRewardsAccountNaming() {
        Contact ct = [SELECT Id, FirstName FROM Contact LIMIT 1];
        Rewards_Program__c rp = [SELECT Id, Name FROM Rewards_Program__c LIMIT 1];

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

}