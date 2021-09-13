public with sharing class RewardsAccountHandler {

    public static void setRewardsAccountDefaults(List<Rewards_Account__c> lstRAsInTrigger) {
        Map<Id, Contact> mapContacts = getContactMap(lstRAsInTrigger);
        Map<Id, Rewards_Program__c> mapRewardsPrograms = getRewardsProgramMap(lstRAsInTrigger);

        setRewardsAccountName(
            lstRAsInTrigger,
            mapRewardsPrograms,
            mapContacts
        );

        setDatesFromProgram(
            lstRAsInTrigger,
            mapRewardsPrograms
        );
    }

    public static Map<Id, Rewards_Account__c> getRewardsAccountMap(Set<Id> setRewardsAccountIds) {
        return queryForMap(setRewardsAccountIds);
    }

    public static Map<Id, Rewards_Account__c> getRewardsAccountMap(List<Rewards_Event__c> lstRewardsEvents) {
        Set<Id> setRewardsAccountIds = new Set<Id>();
        for (Rewards_Event__c re : lstRewardsEvents) {
            if (re.Rewards_Account__c != null) {
                setRewardsAccountIds.add(re.Rewards_Account__c);
            }
        }
        return queryForMap(setRewardsAccountIds);
    }

    public static Map<Id, Rewards_Account__c> getRewardsAccountMap(Map<Id, Rewards_Event__c> mapRewardsEvents) {
        Set<Id> setRewardsAccountIds = new Set<Id>();
        for (Rewards_Event__c re : mapRewardsEvents.values()) {
            if (re.Rewards_Account__c != null) {
                setRewardsAccountIds.add(re.Rewards_Account__c);
            }
        }
        return queryForMap(setRewardsAccountIds);
    }

    public static Rewards_Account__c getRewardsAccount(String contactId, String rewardsProgramId) {
        return [SELECT Id, Points_Total__c, Rewards_Program__c, Rewards_Program__r.Name, 
                       Rewards_Program__r.End_Datetime__c, Rewards_Program__r.Days_Until_Points_Expire__c
                  FROM Rewards_Account__c 
                 WHERE Contact__c = :contactId 
                   AND Rewards_Program__c = :rewardsProgramId
                   AND Status__c IN ('Pending','Active') 
                  WITH SECURITY_ENFORCED
                 LIMIT 1];
    }

    public static Map<Id, Rewards_Account__c> getActiveAwardsForRedemptions(Map<Id, Rewards_Event__c> mapRedemptionEvents) {
        Id awardRecordTypeId = Schema.SObjectType.Rewards_Event__c.getRecordTypeInfosByDeveloperName().get('Award').getRecordTypeId();
        Set<Id> setRewardsAccountIds = new Set<Id>();
        for (Rewards_Event__c re : mapRedemptionEvents.values()) {
            setRewardsAccountIds.add(re.Rewards_Account__c);
        }
        Map<Id, Rewards_Account__c> mapRewardsAccounts = new Map<Id, Rewards_Account__c>([
            SELECT Id, Points_Total__c, Contact__c, Contact__r.FirstName, Contact__r.LastName, 
                   Rewards_Program__c, Rewards_Program__r.Name, Rewards_Program__r.End_Datetime__c, 
                   Rewards_Program__r.Days_Until_Points_Expire__c,
                   (SELECT Id, Points__c, Expiration_Date__c, Date__c, Points_Remaining__c, Points_Used__c,
                           Status__c, RecordTypeId, Points_Expired__c, Expired__c
                      FROM Rewards_Events__r
                     WHERE RecordTypeId = :awardRecordTypeId
                       AND Points_Remaining__c > 0
                     ORDER BY Expiration_Date__c ASC NULLS LAST, Date__c ASC, Points_Remaining__c ASC)
              FROM Rewards_Account__c 
             WHERE Id IN :setRewardsAccountIds
               AND Status__c IN ('Pending','Active') 
              WITH SECURITY_ENFORCED
             LIMIT 10000
        ]);
        return mapRewardsAccounts;
    }

    private static void setRewardsAccountName(
        List<Rewards_Account__c> lstRAsInTrigger, 
        Map<Id, Rewards_Program__c> mapRewardsPrograms,
        Map<Id, Contact> mapContacts
    ) {
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

    private static void setDatesFromProgram(
        List<Rewards_Account__c> lstRAsInTrigger, 
        Map<Id, Rewards_Program__c> mapRewardsPrograms
    ) {
        for (Rewards_Account__c ra : lstRAsInTrigger) {
            Datetime programStart = mapRewardsPrograms.get(ra.Rewards_Program__c).Start_Datetime__c;
            Datetime programEnd = mapRewardsPrograms.get(ra.Rewards_Program__c).End_Datetime__c;
            if (ra.Start_Datetime__c == null) {
                ra.Start_Datetime__c = programStart != null && programStart > Datetime.now() ? programStart : Datetime.now();
            }
            if (ra.End_Datetime__c == null && programEnd != null) {
                ra.End_Datetime__c = programEnd;
            }
        }
    }

    private static Map<Id, Rewards_Account__c> queryForMap(Set<Id> setRewardsAccountIds) {
        Map<Id, Rewards_Account__c> mapRewardsAccounts = new Map<Id, Rewards_Account__c>([
            SELECT Id, Points_Total__c, Contact__c, Contact__r.FirstName, Contact__r.LastName, 
                   Rewards_Program__c, Rewards_Program__r.Name, Rewards_Program__r.End_Datetime__c, 
                   Rewards_Program__r.Days_Until_Points_Expire__c, Status__c 
              FROM Rewards_Account__c 
             WHERE Id IN :setRewardsAccountIds
              WITH SECURITY_ENFORCED
             LIMIT 10000
        ]);
        return mapRewardsAccounts;
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
            SELECT Id, Name, Start_Datetime__c, End_Datetime__c
              FROM Rewards_Program__c
             WHERE Id IN :setRewardsProgramIds
        ]);
        return mapRewardsPrograms;
    }

}