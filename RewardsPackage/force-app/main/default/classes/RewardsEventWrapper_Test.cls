@isTest
public class RewardsEventWrapper_Test {

    private static Id awardRecTypeId = Schema.SObjectType.Rewards_Event__c
        .getRecordTypeInfosByDeveloperName().get('Award').getRecordTypeId();

    @isTest
    static void returnSortedEvents() {
        List<Program_Reward__c> lstPRs  = RewardsTestDataFactory.createPerpetualProgramWithRewards(4);
        List<Contact> lstContacts       = RewardsTestDataFactory.createContacts(1, 1);
        List<Rewards_Account__c> lstRAs = RewardsTestDataFactory.createRewardsAccounts(lstContacts, lstPRs[0].Rewards_Program__c);
        Rewards_Account__c ra           = lstRAs.get(0);
        List<Rewards_Event__c> lstUnsortedRewardsEvents = new List<Rewards_Event__c>();
        lstUnsortedRewardsEvents.add(
            new Rewards_Event__c(
                Rewards_Account__c = ra.Id, 
                Points__c          = 400, 
                RecordTypeId       = awardRecTypeId,
                Description__c     = 'Test Points',
                Date__c            = Date.today()
            )
        );
        // 5 days earlier
        lstUnsortedRewardsEvents.add(
            new Rewards_Event__c(
                Rewards_Account__c = ra.Id, 
                Points__c          = 200, 
                RecordTypeId       = awardRecTypeId,
                Description__c     = 'Test Points',
                Date__c            = Datetime.now().addDays(-5)
            )
        );
        // Date is null
        lstUnsortedRewardsEvents.add(
            new Rewards_Event__c(
                Rewards_Account__c = ra.Id, 
                Points__c          = 200, 
                RecordTypeId       = awardRecTypeId,
                Description__c     = 'Null Date Test Points'
            )
        );
        // 3 days earlier
        lstUnsortedRewardsEvents.add(
            new Rewards_Event__c(
                Rewards_Account__c = ra.Id, 
                Points__c          = 200, 
                RecordTypeId       = awardRecTypeId,
                Description__c     = 'Test Points',
                Date__c            = Datetime.now().addDays(-2)
            )
        );
        List<Rewards_Event__c> lstSortedRewardsEvents = new List<Rewards_Event__c>();
        RewardsEventWrapper[] lstRewardsEventWrapper = new List<RewardsEventWrapper>();
        for (Rewards_Event__c re : lstUnsortedRewardsEvents) {
            lstRewardsEventWrapper.add( new RewardsEventWrapper(re) );
        }
        lstRewardsEventWrapper.sort();
        for (RewardsEventWrapper reWrapper : lstRewardsEventWrapper) {
            lstSortedRewardsEvents.add( reWrapper.rewardsEvent );
        }

        Integer sizeOfList = lstSortedRewardsEvents.size();
        System.assertEquals('Null Date Test Points', lstSortedRewardsEvents.get(sizeOfList - 1).Description__c, 'Did not receive most recent Rewards Event');
        
    }

}