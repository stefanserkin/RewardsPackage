public with sharing class RewardsEventLinkHandler {

    // Receives records from handleRedemptions in RewardsEventHandler
    public static Map<Id, Rewards_Event__c> mapRewardsEventsToUpdate = new Map<Id, Rewards_Event__c>();

    public static void debitAwards(List<Rewards_Event_Link__c> lstRelsInTrigger) {
        if (mapRewardsEventsToUpdate.isEmpty()) {
            mapRewardsEventsToUpdate = getRewardsEventsToUpdateMap(lstRelsInTrigger);
        }
        System.debug('Size of rewards events when creating links : ' + mapRewardsEventsToUpdate.size());
        for (Rewards_Event_Link__c rel : lstRelsInTrigger) {
            Rewards_Event__c award = mapRewardsEventsToUpdate.get(rel.Award_Event__c);
            if (award.Points_Used__c == null) award.Points_Used__c = 0;
            if (award.Points_Expired__c == null) award.Points_Expired__c = 0;
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
            mapRewardsEventsToUpdate.put(award.Id, award);
        }
        try {
            update mapRewardsEventsToUpdate.values();
        } catch (DmlException e) {
            System.debug(':::: Failed to update Rewards Events: ' + e.getMessage());
        }
    }

    private static Map<Id, Rewards_Event__c> getRewardsEventsToUpdateMap(List<Rewards_Event_Link__c> lstRelsInTrigger) {
        Set<Id> setRewardsEventsIds = new Set<Id>();
        for (Rewards_Event_Link__c rel : lstRelsInTrigger) {
            setRewardsEventsIds.add(rel.Award_Event__c);
        }
        return new Map<Id, Rewards_Event__c>([
            SELECT Id, Points__c, Points_Remaining__c, Points_Used__c,
                   Points_Expired__c, Status__c, RecordTypeId, Expired__c
              FROM Rewards_Event__c
             WHERE Id IN :setRewardsEventsIds
        ]);
    }
    
}
