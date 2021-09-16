public with sharing class RewardsEventLinkHandler {

    // Receives records from handleRedemptions in RewardsEventHandler
    public static Map<Id, Rewards_Event__c> mapRewardsEventsToUpdate;
    public static Map<Id, Rewards_Event_Link__c> mapRewardsEventLinksToUpdate;

    public static void debitAwards(List<Rewards_Event_Link__c> lstRelsInTrigger) {
        Map<Id, Rewards_Event__c> mapAwardsToUpdate = getRewardsEventsToUpdateMap(lstRelsInTrigger);

        for (Rewards_Event_Link__c rel : lstRelsInTrigger) {
            Rewards_Event__c award = mapAwardsToUpdate.get(rel.Award_Event__c);
            if (award.Points_Used__c == null) {
                award.Points_Used__c = 0;
            }
            if (award.Points_Expired__c == null) {
                award.Points_Expired__c = 0;
            }
            if (rel.Type__c == 'Redemption') {
                award.Points_Used__c += rel.Points_Used__c;
                if (award.Points_Used__c + award.Points_Expired__c == award.Points__c) {
                    award.Status__c = 'Empty';
                }
            }
            if (rel.Type__c == 'Expiration') {
                award.Points_Expired__c += rel.Points_Used__c;
                award.Status__c  = 'Empty';
                award.Expired__c = true;
            }
            RewardsEventHandler.addToMapToUpdate(award);
        }

        RewardsEventHandler.updateRewardsEventsDml();

    }

    public static Rewards_Event_Link__c createRewardsEventLink(
        String type, Id deductionEvent, Id awardEvent, Decimal points
    ) {
        return new Rewards_Event_Link__c(
            Type__c = type, 
            Deduction_Event__c = deductionEvent, 
            Award_Event__c = awardEvent, 
            Points_Used__c = points
        );
    }

    public static void addToMapToUpdate(Rewards_Event_Link__c rel) {
        if (mapRewardsEventLinksToUpdate == null) {
            mapRewardsEventLinksToUpdate = new Map<Id, Rewards_Event_Link__c>();
        }
        mapRewardsEventLinksToUpdate.put(rel.Id, rel);
    }

    public static void addToMapToUpdate(List<Rewards_Event_Link__c> lstRELs) {
        if (mapRewardsEventLinksToUpdate == null) {
            mapRewardsEventLinksToUpdate = new Map<Id, Rewards_Event_Link__c>();
        }
        mapRewardsEventLinksToUpdate.putAll(lstRELs);
    }

    private static Map<Id, Rewards_Event__c> getRewardsEventsToUpdateMap(
        List<Rewards_Event_Link__c> lstRelsInTrigger
    ) {
        Set<Id> setRewardsEventsIds = new Set<Id>();
        for (Rewards_Event_Link__c rel : lstRelsInTrigger) {
            setRewardsEventsIds.add(rel.Award_Event__c);
        }
        return new Map<Id, Rewards_Event__c>([
            SELECT Id, Points__c, Points_Remaining__c, Points_Used__c,
                   Points_Expired__c, Status__c, RecordTypeId, Expired__c
              FROM Rewards_Event__c
             WHERE Id IN :setRewardsEventsIds
               AND Status__c != 'Canceled'
        ]);
    }

}