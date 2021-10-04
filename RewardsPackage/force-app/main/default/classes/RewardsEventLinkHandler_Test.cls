@isTest
public class RewardsEventLinkHandler_Test {

    private static Id awardRecTypeId = Schema.SObjectType.Rewards_Event__c
        .getRecordTypeInfosByDeveloperName().get('Award').getRecordTypeId();
    private static Id redemptionRecTypeId = Schema.SObjectType.Rewards_Event__c
        .getRecordTypeInfosByDeveloperName().get('Redemption').getRecordTypeId();
    
    @isTest
    static void testAddToMapToUpdate() {
        List<Program_Reward__c> lstPRs  = RewardsTestDataFactory.createPerpetualProgramWithRewards(4);
        List<Contact> lstContacts       = RewardsTestDataFactory.createContacts(1, 1);
        List<Rewards_Account__c> lstRAs = RewardsTestDataFactory.createRewardsAccounts(lstContacts, lstPRs[0].Rewards_Program__c);
        Rewards_Account__c raWithEvents = RewardsTestDataFactory.createRewardsEventsForRA(lstRAs[0], 10, 5);
        List<Rewards_Event__c> reList   = [SELECT Id, RecordTypeId, Points__c, Reward__r.Cost__c 
                                             FROM Rewards_Event__c
                                            WHERE Rewards_Account__c = :raWithEvents.Id];
        Id awardId;
        Id redemptionId;
        Decimal pointsUsed;
        Boolean awardIsSet     = false;
        Boolean deductionIsSet = false;
        for (Rewards_Event__c re : reList) {
            if (!awardIsSet && re.RecordTypeId == awardRecTypeId) {
                awardId = re.Id;
                awardIsSet = true;
            }
            if (!deductionIsSet && re.RecordTypeId == redemptionRecTypeId) {
                redemptionId = re.Id;
                pointsUsed   = re.Reward__r.Cost__c;
                deductionIsSet = true;
            }
            if (awardIsSet && deductionIsSet) {
                break;
            }
        }

        Rewards_Event_Link__c rel = new Rewards_Event_Link__c(
            Award_Event__c     = awardId,
            Deduction_Event__c = redemptionId,
            Type__c            = 'Redemption',
            Points_Used__c     = pointsUsed
        );
        insert rel;
        RewardsEventLinkHandler.addToMapToUpdate(rel);
        System.assertEquals(true, !RewardsEventLinkHandler.mapRewardsEventLinksToUpdate.isEmpty(), 'No RELs found');
        
    }

    @isTest
    static void testAddToMapToUpdateFromList() {
        List<Program_Reward__c> lstPRs  = RewardsTestDataFactory.createPerpetualProgramWithRewards(4);
        List<Contact> lstContacts       = RewardsTestDataFactory.createContacts(1, 1);
        List<Rewards_Account__c> lstRAs = RewardsTestDataFactory.createRewardsAccounts(lstContacts, lstPRs[0].Rewards_Program__c);
        Rewards_Account__c raWithEvents = RewardsTestDataFactory.createRewardsEventsForRA(lstRAs[0], 10, 5);
        List<Rewards_Event__c> reList   = [SELECT Id, RecordTypeId, Points__c, Reward__r.Cost__c 
                                             FROM Rewards_Event__c
                                            WHERE Rewards_Account__c = :raWithEvents.Id];
        Id awardId;
        Id redemptionId;
        Decimal pointsUsed;
        Boolean awardIsSet     = false;
        Boolean deductionIsSet = false;
        for (Rewards_Event__c re : reList) {
            if (!awardIsSet && re.RecordTypeId == awardRecTypeId) {
                awardId = re.Id;
                awardIsSet = true;
            }
            if (!deductionIsSet && re.RecordTypeId == redemptionRecTypeId) {
                redemptionId = re.Id;
                pointsUsed   = re.Reward__r.Cost__c;
                deductionIsSet = true;
            }
            if (awardIsSet && deductionIsSet) {
                break;
            }
        }

        Rewards_Event_Link__c rel = new Rewards_Event_Link__c(
            Award_Event__c     = awardId,
            Deduction_Event__c = redemptionId,
            Type__c            = 'Redemption',
            Points_Used__c     = pointsUsed
        );
        List<Rewards_Event_Link__c>  lstRELs = new List<Rewards_Event_Link__c>();
        lstRELs.add(rel);
        insert lstRELs;
        RewardsEventLinkHandler.addToMapToUpdate(lstRELs);
        System.assertEquals(true, !RewardsEventLinkHandler.mapRewardsEventLinksToUpdate.isEmpty(), 'No RELs found');
    }
    
}