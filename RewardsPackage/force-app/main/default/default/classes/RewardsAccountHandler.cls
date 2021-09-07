public with sharing class RewardsAccountHandler {

    public static void setRewardsAccountName(List<Rewards_Account__c> lstRAsInTrigger) {
        Map<Id, Contact> mapContacts = getContactMap(lstRAsInTrigger);
        Map<Id, Rewards_Program__c> mapRewardsPrograms = getRewardsProgramMap(lstRAsInTrigger);

        for (Rewards_Account__c ra : lstRAsInTrigger) {
            String strName = '';
            if (mapContacts.get(ra.Contact__c) != null) {
                strName += mapContacts.get(ra.Contact__c).FirstName;
            }
            strName += '\'s ';
            if (mapRewardsPrograms.get(ra.Rewards_Program__c) != null) {
                strName += mapRewardsPrograms.get(ra.Rewards_Program__c).Name;
            }
            strName += ' Rewards';
            ra.Name = strName;
        }

    }

    private static Map<Id, Contact> getContactMap(List<Rewards_Account__c> lstRAs) {
        Set<Id> setContactIds = new Set<Id>();
        for (Rewards_Account__c ra : lstRAs) {
            if (ra.Contact__c != null) {
                setContactIds.add(ra.Contact__c);
            }
        }
        Map<Id, Contact> mapContacts = new Map<Id, Contact>([
            SELECT Id, FirstName
              FROM Contact
             WHERE Id IN :setContactIds
        ]);
        return mapContacts;
    }

    private static Map<Id, Rewards_Program__c> getRewardsProgramMap(List<Rewards_Account__c> lstRAs) {
        Set<Id> setRewardsProgramIds = new Set<Id>();
        for (Rewards_Account__c ra : lstRAs) {
            if (ra.Rewards_Program__c != null) {
                setRewardsProgramIds.add(ra.Rewards_Program__c);
            }
        }
        Map<Id, Rewards_Program__c> mapRewardsPrograms = new Map<Id, Rewards_Program__c>([
            SELECT Id, Name
              FROM Rewards_Program__c
             WHERE Id IN :setRewardsProgramIds
        ]);
        return mapRewardsPrograms;
    }
}