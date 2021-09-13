public with sharing class RewardsEventHandler {

    private static Id awardRecordTypeId;
    private static Id redemptionRecordTypeId;
    private static Id expirationRecordTypeId;
    private static Boolean recordTypeIdsAreSet = false;
    private static Map<Id, Rewards_Account__c> mapRewardsAccounts;
    private static Boolean rewardsAccountMapIsSet = false;

    public static void setRunningBalance(List<Rewards_Event__c> lstRewardsEventsInTrigger) {
        // Map Rewards Accounts to their list of Rewards Events
        Map<Rewards_Account__c, List<Rewards_Event__c>> mapRewardsAccsToSortedEvents = 
            new Map<Rewards_Account__c, List<Rewards_Event__c>>();
        List<Rewards_Account__c> lstRewardsAccsToUpdate = new List<Rewards_Account__c>();
        
        // Get list of Rewards Events sorted by date
        List<Rewards_Event__c> lstSortedRewardsEvents = sortRewardsEventsByDate(lstRewardsEventsInTrigger);
        Map<Id, Rewards_Account__c> mapRewardsAccounts = RewardsAccountHandler.getRewardsAccountMap(lstRewardsEventsInTrigger);

        // Populate map for each Rewards Account in trigger context
        for (Rewards_Account__c ra : mapRewardsAccounts.values()) {
            List<Rewards_Event__c> lstRAsRewardsEvents = new List<Rewards_Event__c>();
            for (Rewards_Event__c re : lstSortedRewardsEvents) {
                if (re.Rewards_Account__c == ra.Id) {
                    lstRAsRewardsEvents.add(re);
                }
            }
            mapRewardsAccsToSortedEvents.put(ra, lstRAsRewardsEvents);
        }

        for (Rewards_Account__c ra : mapRewardsAccsToSortedEvents.keySet()) {
            // Set balance from beginning of transaction
            Decimal runningBalance;
            if (ra.Points_Total__c != null) {
                runningBalance = ra.Points_Total__c;
            } else {
                runningBalance = 0;
            }

            // Set balances for each of the related events
            for (Rewards_Event__c re : mapRewardsAccsToSortedEvents.get(ra)) {
                if (re.Type__c == 'Award') {
                    runningBalance += re.Points__c;
                    re.Points_Balance__c = runningBalance;
                    // set description if blank
                    if (String.isEmpty(re.Description__c)) {
                        setBlankAwardDescription(re, mapRewardsAccounts);
                    }
                } else if (re.Type__c == 'Redemption' || re.Type__c == 'Expiration') {
                    runningBalance -= re.Points__c;
                    re.Points_Balance__c = runningBalance;
                }
            }
            ra.Points_Total__c = runningBalance;
            lstRewardsAccsToUpdate.add(ra);
        }

        try {
            update lstRewardsAccsToUpdate;
        } catch (DmlException e) {
            System.debug(':::: Failed to update Rewards Accounts: ' + e.getMessage());
        }

    }

    public static void handleDeductions(List<Rewards_Event__c> lstRewardsEventsInTrigger, Boolean isBefore) {
        if (!rewardsAccountMapIsSet) {
            mapRewardsAccounts = new Map<Id, Rewards_Account__c>();
            mapRewardsAccounts = RewardsAccountHandler.getRewardsAccountMap(lstRewardsEventsInTrigger);
            rewardsAccountMapIsSet = true;
        }
        if (!recordTypeIdsAreSet) {
            setRecordTypeIds();
        }

        if (isBefore) {
            List<Rewards_Event__c> lstEventsMissingDescriptions = new List<Rewards_Event__c>();
            for (Rewards_Event__c re : lstRewardsEventsInTrigger) {
                if (re.RecordTypeId == redemptionRecordTypeId && mapRewardsAccounts.get(re.Rewards_Account__c).Points_Total__c < re.Points__c) {
                    re.addError('Not enough points to redeem reward.');
                }
                if (String.isBlank(re.Description__c)) {
                    lstEventsMissingDescriptions.add(re);
                }
            }
            if (!lstEventsMissingDescriptions.isEmpty()) {
                setBlankRedemptionDescriptions(lstEventsMissingDescriptions);
            }
            return;
        }

        Map<Id, Rewards_Event__c> mapRedemptionEventsInTrigger = new Map<Id, Rewards_Event__c>();
        Map<Id, Rewards_Event__c> mapExpirationEventsInTrigger = new Map<Id, Rewards_Event__c>();
        for (Rewards_Event__c re : lstRewardsEventsInTrigger) {
            if (re.RecordTypeId == redemptionRecordTypeId) {
                mapRedemptionEventsInTrigger.put(re.Id, re);
            } else if (re.RecordTypeId == expirationRecordTypeId) {
                mapExpirationEventsInTrigger.put(re.Id, re);
            }
        }
        handleRedemptions(mapRedemptionEventsInTrigger);
        handleExpirations(mapExpirationEventsInTrigger);
    }

    private static void setBlankAwardDescription(
        Rewards_Event__c re, 
        Map<Id, Rewards_Account__c> mapRewardsAccounts
    ) {
        re.Rewards_Program_ID__c = mapRewardsAccounts.get(re.Rewards_Account__c)?.Rewards_Program__r?.Id;
        re.Rewards_Program_ID__c = mapRewardsAccounts.get(re.Rewards_Account__c)?.Rewards_Program__c;
    }

    private static void setBlankRedemptionDescriptions(List<Rewards_Event__c> lstRewardsEvents) {
        Set<Id> setRewardIds = new Set<Id>();
        for (Rewards_Event__c re : lstRewardsEvents) {
            setRewardIds.add(re.Reward__c);
        }
        Map<Id, Reward__c> mapRewards = new Map<Id, Reward__c>([SELECT Id, Name FROM Reward__c WHERE Id IN :setRewardIds]);
        for (Rewards_Event__c re : lstRewardsEvents) {
            re.Description__c = mapRewards.get(re.Reward__c).Name;
        }
    }

    private static void handleRedemptions(Map<Id, Rewards_Event__c> mapRedemptionEventsInTrigger) {
        List<Rewards_Event_Link__c> lstRelsToInsert = new List<Rewards_Event_Link__c>();
        List<Rewards_Event__c> lstAwardsToUpdate    = new List<Rewards_Event__c>();
        // getActiveAwardsForRedemptions method returns a map of accounts 
        // with sorted award events for a map of redemption events
        Map<Id, Rewards_Account__c> mapRewardsAccountsWithAwards = 
            RewardsAccountHandler.getActiveAwardsForRedemptions(mapRedemptionEventsInTrigger);
        System.debug(':::: map size: ' + mapRewardsAccountsWithAwards.size());

        for (Rewards_Event__c reRe : mapRedemptionEventsInTrigger.values()) {
            Rewards_Account__c acc = mapRewardsAccountsWithAwards?.get(reRe.Rewards_Account__c);
            List<Rewards_Event__c> lstAwards = acc.Rewards_Events__r;
            Decimal costOfReward  = reRe.Points__c;
            Decimal costRemaining = costOfReward;
            Boolean costCovered   = false;

            for (Rewards_Event__c awRe : lstAwards) {
                Rewards_Event_Link__c rel = new Rewards_Event_Link__c();
                rel.Type__c            = 'Redemption';
                rel.Deduction_Event__c = reRe.Id;
                rel.Award_Event__c     = awRe.Id;

                if (costRemaining > awRe.Points_Remaining__c) {
                    rel.Points_Used__c = awRe.Points_Remaining__c;
                } else {
                    rel.Points_Used__c = costRemaining;
                    costCovered = true;
                }
                costRemaining -= rel.Points_Used__c;
                lstRelsToInsert.add(rel);
                RewardsEventLinkHandler.mapRewardsEventsToUpdate.put(awRe.Id, awRe);

                if (costCovered) {
                    break;
                }
            }
        }
        try {
            insert lstRelsToInsert;
        } catch (DmlException e) {
            System.debug(':::: Failed to insert rewards event links: ' + e.getMessage());
        }
        
    }

    private static void handleExpirations(Map<Id, Rewards_Event__c> mapExpirationEventsInTrigger) {
        // Daily flow is currently expiring rewards events
    }

    private static List<Rewards_Event__c> sortRewardsEventsByDate(List<Rewards_Event__c> lstUnsortedRewardsEvents) {
        List<Rewards_Event__c> lstSortedRewardsEvents = new List<Rewards_Event__c>();
        RewardsEventWrapper[] lstRewardsEventWrapper = new List<RewardsEventWrapper>();
        for (Rewards_Event__c re : lstUnsortedRewardsEvents) {
            lstRewardsEventWrapper.add( new RewardsEventWrapper(re) );
        }
        lstRewardsEventWrapper.sort();
        for (RewardsEventWrapper reWrapper : lstRewardsEventWrapper) {
            lstSortedRewardsEvents.add( reWrapper.rewardsEvent );
        }
        return lstSortedRewardsEvents;
    }

    private static void setRecordTypeIds() {
        awardRecordTypeId = Schema.SObjectType.Rewards_Event__c.getRecordTypeInfosByDeveloperName().get('Award').getRecordTypeId();
        redemptionRecordTypeId = Schema.SObjectType.Rewards_Event__c.getRecordTypeInfosByDeveloperName().get('Redemption').getRecordTypeId();
        expirationRecordTypeId = Schema.SObjectType.Rewards_Event__c.getRecordTypeInfosByDeveloperName().get('Expiration').getRecordTypeId();
        recordTypeIdsAreSet = true;
    }

    private static Date getExpirationDateForRewardsEvent(
        Rewards_Account__c rewardsAccount, 
        Decimal reDaysUntilExpiration
    ) {
        List<Date> lstDates = new List<Date>();
        Date rewardsEventExpiration;
        Date rewardsProgramExpiration;
        Date rewardsProgramEndDate;
        // Get expiration based on number of days until rewards event expires
        if (reDaysUntilExpiration != null && reDaysUntilExpiration > 0) {
            rewardsEventExpiration = Date.today().addDays( reDaysUntilExpiration.intValue() );
            lstDates.add(rewardsEventExpiration);
        } 
        // Get expiration based on number of days until rewards program points expire
        if (rewardsAccount.Rewards_Program__r.Days_Until_Points_Expire__c != null) {
            Decimal pDaysUntilExpiration = rewardsAccount.Rewards_Program__r.Days_Until_Points_Expire__c;
            rewardsProgramExpiration = Date.today().addDays( pDaysUntilExpiration.intValue() );
            lstDates.add(rewardsProgramExpiration);
        }
        // Get expiration based on final day of program
        if (rewardsAccount.Rewards_Program__r.End_Datetime__c != null) {
            Datetime rpEndDatetime = rewardsAccount.Rewards_Program__r.End_Datetime__c;
            rewardsProgramEndDate = Date.newInstance(rpEndDatetime.year(), rpEndDatetime.month(), rpEndDatetime.day());
            lstDates.add(rewardsProgramEndDate);
        }
        // Return earliest date
        lstDates.sort();
        return lstDates[0];
    }

    public static Boolean handleInvokedRewardsEventCreation(
        String rewardsProgramId, String contactId, Decimal points, 
        String description, String relatedEntityId, Decimal daysUntilExpiration
    ) {
        Boolean insertIsSuccess;
        Date expirationDate;

        if (!recordTypeIdsAreSet) {
            setRecordTypeIds();
        }

        Rewards_Account__c rewardsAccount = RewardsAccountHandler.getRewardsAccount(contactId, rewardsProgramId);

        // If no rewards account, exit
        if (rewardsAccount == null) {
            return false;
        }
        // If any expiration criteria apply, get earliest expiration date
        if (
            (daysUntilExpiration != null && daysUntilExpiration > 0) || 
            rewardsAccount.Rewards_Program__r.Days_Until_Points_Expire__c != null || 
            rewardsAccount.Rewards_Program__r.End_Datetime__c != null
        ) {
            expirationDate = getExpirationDateForRewardsEvent(rewardsAccount, daysUntilExpiration);
        }

        Rewards_Event__c re = new Rewards_Event__c();
        re.RecordTypeId            = awardRecordTypeId;
        re.Rewards_Account__c      = rewardsAccount.Id;
        re.Points__c               = points;
        re.Description__c          = description;
        re.Related_Entity_ID__c    = relatedEntityId;
        re.Rewards_Program_ID__c   = rewardsAccount.Rewards_Program__c;
        re.Rewards_Program_Name__c = rewardsAccount.Rewards_Program__r.Name;
        if (expirationDate != null) {
            re.Expiration_Date__c = expirationDate;
        }
        re.Date__c                 = Datetime.now();
        re.Status__c               = 'Active';

        // Insert rewards event
        try {
            insert re;
            insertIsSuccess = true;
        } catch (DmlException e) {
            insertIsSuccess = false;
            System.debug(':::: Rewards Event insertion was unsuccessful: ' + e.getMessage());
        }

        return insertIsSuccess;

    }
    
}