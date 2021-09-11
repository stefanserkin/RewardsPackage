public with sharing class RewardsAccountHandler {

    public static void setRewardsAccountName(List<Rewards_Account__c> lstRAsInTrigger) {
        Map<Id, Contact> mapContacts = getContactMap(lstRAsInTrigger);
        Map<Id, Rewards_Program__c> mapRewardsPrograms = getRewardsProgramMap(lstRAsInTrigger);

        for (Rewards_Account__c ra : lstRAsInTrigger) {
            String strName = '';
            strName += mapContacts.get(ra.Contact__c)?.FirstName;
            strName += '\'s ';
            strName += mapRewardsPrograms.get(ra.Rewards_Program__c)?.Name;
            if (mapRewardsPrograms.get(ra.Rewards_Program__c)?.Name?.right(7) == 'Rewards') {
                strName += ' Account';
            } else {
                strName += ' Rewards';
            }
            ra.Name = strName;
        }

    }

    public static Rewards_Account__c getRewardsAccount(String contactId, String rewardsProgramId) {
        return [SELECT Id, Points_Total__c, Rewards_Program__c, Rewards_Program__r.Name, Rewards_Program__r.Days_Until_Points_Expire__c
                  FROM Rewards_Account__c 
                 WHERE Contact__c = :contactId 
                   AND Rewards_Program__c = :rewardsProgramId
                   AND Status__c IN ('Pending','Active') 
                  WITH SECURITY_ENFORCED
                 LIMIT 1];
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