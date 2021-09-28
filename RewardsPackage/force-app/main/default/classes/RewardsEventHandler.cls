public with sharing class RewardsEventHandler {

    private static Boolean recordTypeIdsAreSet = false;
    private static Id awardRecordTypeId;
    private static Id redemptionRecordTypeId;
    private static Id expirationRecordTypeId;
    private static Map<Id, Rewards_Account__c> mapRewardsAccountsToUpdate;
    private static Map<Id, Rewards_Event__c> mapRewardsEventsToUpdate;

    public static void setRecordTypeIds() {
        if (recordTypeIdsAreSet) {
            return;
        }
        awardRecordTypeId      = Schema.SObjectType.Rewards_Event__c.getRecordTypeInfosByDeveloperName().get('Award').getRecordTypeId();
        redemptionRecordTypeId = Schema.SObjectType.Rewards_Event__c.getRecordTypeInfosByDeveloperName().get('Redemption').getRecordTypeId();
        expirationRecordTypeId = Schema.SObjectType.Rewards_Event__c.getRecordTypeInfosByDeveloperName().get('Expiration').getRecordTypeId();
        recordTypeIdsAreSet = true;
    }

    public static Id getRedemptionRecordTypeId() {
        if (recordTypeIdsAreSet) {
            return redemptionRecordTypeId;
        }
        setRecordTypeIds();
        return redemptionRecordTypeId;
    }

    public static Map<Id, Rewards_Event__c> getMapRewardsEventsToUpdate() {
        if (mapRewardsEventsToUpdate == null) {
            mapRewardsEventsToUpdate = new Map<Id, Rewards_Event__c>();
        }
        return mapRewardsEventsToUpdate;
    }
    
    public static void addToMapToUpdate(Rewards_Event__c re) {
        if (mapRewardsEventsToUpdate == null) {
            mapRewardsEventsToUpdate = new Map<Id, Rewards_Event__c>();
        }
        mapRewardsEventsToUpdate.put(re.Id, re);
    }

    public static void addToMapToUpdate(List<Rewards_Event__c> reList) {
        if (mapRewardsEventsToUpdate == null) {
            mapRewardsEventsToUpdate = new Map<Id, Rewards_Event__c>();
        }
        mapRewardsEventsToUpdate.putAll(reList);
    }

    public static void updateRewardsEventsDml() {
        if (mapRewardsEventsToUpdate != null && !mapRewardsEventsToUpdate.isEmpty()) {
            update mapRewardsEventsToUpdate.values();
        }
    }

    public static void updateRewardsAccountsDml() {
        if (mapRewardsAccountsToUpdate != null && !mapRewardsAccountsToUpdate.isEmpty()) {
            update mapRewardsAccountsToUpdate.values();
        }
    }

    public static void handleInvokedRewardsEventCreation(
        String rewardsProgramId, String contactId, Decimal points, 
        String description, String relatedEntityId, Decimal daysUntilExpiration
    ) {
        setRecordTypeIds();

        Date expirationDate;
        if (daysUntilExpiration != null) {
            expirationDate = Date.today().addDays(Integer.valueOf(daysUntilExpiration));
        }
        List<Rewards_Account__c> lstRewardsAccounts = RewardsAccountHandler.getRewardsAccountList(
            contactId, rewardsProgramId
        );

        // If no rewards account, exit
        if (lstRewardsAccounts.isEmpty()) {
            return;
        }
        Rewards_Account__c rewardsAccount = lstRewardsAccounts[0];

        Rewards_Event__c re = new Rewards_Event__c();
        re.RecordTypeId            = awardRecordTypeId;
        re.Rewards_Account__c      = rewardsAccount.Id;
        re.Points__c               = points;
        re.Description__c          = description;
        re.Related_Entity_ID__c    = relatedEntityId;
        re.Rewards_Program_ID__c   = rewardsAccount.Rewards_Program__c;
        re.Rewards_Program_Name__c = rewardsAccount.Rewards_Program__r.Name;
        re.Contact__c              = contactId;
        // If any expiration criteria apply, get earliest expiration date
        if (
            (daysUntilExpiration != null && daysUntilExpiration > 0) || 
            rewardsAccount.Rewards_Program__r.Days_Until_Points_Expire__c != null || 
            rewardsAccount.Rewards_Program__r.End_Datetime__c != null
        ) {
            re.Expiration_Date__c = getExpirationDateForRewardsEvent(
                rewardsAccount, 
                re, 
                expirationDate
            );
        }
        re.Date__c                 = Datetime.now();
        re.Status__c               = 'Active';

        insert re;

    }

    public static void handleTriggerEvent(
        Boolean isBefore, Boolean isInsert, Boolean isUpdate, Boolean isDelete, Boolean isUndelete,
        List<Rewards_Event__c> lstREsInTrigger, Map<Id, Rewards_Event__c> mapNewREsInTrigger, 
        Map<Id, Rewards_Event__c> mapOldREsInTrigger
    ) {
        if (isInsert) {
            if (isBefore) {
                processBeforeInsert(lstREsInTrigger);
            } else {
                processAfterInsert(lstREsInTrigger);
            }
        }
    }

    private static void processBeforeInsert(List<Rewards_Event__c> lstREsInTrigger) {
        Map<Id, Rewards_Account__c> mapRewardsAccountsWithEvents = RewardsAccountHandler.getRewardsAccountWithEventsMap(lstREsInTrigger, true);
        Map<Id, Reward__c> mapRewards = RewardsHandler.getRewardsMap(lstREsInTrigger);
        // Combine map of queried events with new events in before context
        Map<Rewards_Account__c, List<Rewards_Event__c>> 
            mapRewardsAccsToSortedEvents = getMapAccountsToEvents(lstREsInTrigger, mapRewardsAccountsWithEvents);
        updateRecordsInTrigger(mapRewardsAccsToSortedEvents, mapRewardsAccountsWithEvents, mapRewards);
        updateRewardsEventsDml();
        updateRewardsAccountsDml();
    }

    private static void processAfterInsert(List<Rewards_Event__c> lstREsInTrigger) {
        setRecordTypeIds();
        Map<Id, Rewards_Account__c> mapRewardsAccountsWithEvents = RewardsAccountHandler.getRewardsAccountWithEventsMap(lstREsInTrigger);
        Map<Id, Rewards_Event__c> mapRedemptionEventsInTrigger = new Map<Id, Rewards_Event__c>();
        Map<Id, Rewards_Event__c> mapExpirationEventsInTrigger = new Map<Id, Rewards_Event__c>();
        for (Rewards_Event__c re : lstREsInTrigger) {
            if (re.RecordTypeId == redemptionRecordTypeId) {
                mapRedemptionEventsInTrigger.put(re.Id, re);
            } else if (re.RecordTypeId == expirationRecordTypeId) {
                mapExpirationEventsInTrigger.put(re.Id, re);
            }
        }
        handleRedemptions(mapRedemptionEventsInTrigger, mapRewardsAccountsWithEvents);
    }

    private static void handleRedemptions(
        Map<Id, Rewards_Event__c> mapRedemptionEventsInTrigger, 
        Map<Id, Rewards_Account__c> mapRewardsAccountsWithEvents
    ) {
        setRecordTypeIds();
        List<Rewards_Event_Link__c> lstRelsToInsert = new List<Rewards_Event_Link__c>();
        List<Rewards_Event__c> lstAwardsToUpdate    = new List<Rewards_Event__c>();

        for (Rewards_Event__c redemption : mapRedemptionEventsInTrigger.values()) {
            Decimal costOfReward  = redemption.Points__c;
            Decimal costRemaining = costOfReward;
            Boolean costIsCovered = false;

            Rewards_Account__c ra = mapRewardsAccountsWithEvents.get(redemption.Rewards_Account__c);
            List<Rewards_Event__c> lstAwards = new List<Rewards_Event__c>();
            for (Rewards_Event__c award : ra.Rewards_Events__r) {
                if (award.RecordTypeId != awardRecordTypeId || award.Points_Remaining__c <= 0) {
                    continue;
                }
                Decimal points = costRemaining > award.Points_Remaining__c ? award.Points_Remaining__c : costRemaining;
                Rewards_Event_Link__c rel = RewardsEventLinkHandler.createRewardsEventLink(
                    'Redemption', redemption.Id, award.Id, points
                );
                costRemaining -= rel.Points_Used__c;
                lstRelsToInsert.add(rel);
                if (mapRewardsEventsToUpdate == null) {
                    mapRewardsEventsToUpdate = new Map<Id, Rewards_Event__c>();
                }
                mapRewardsEventsToUpdate.put(award.Id, award);
                if (costRemaining <= 0) {
                    break;
                }
            }
        }
        if (!lstRelsToInsert.isEmpty()) {
            insert lstRelsToInsert;
        }
    }

    private static void updateRecordsInTrigger(
        Map<Rewards_Account__c, List<Rewards_Event__c>> mapRewardsAccsToSortedEvents,
        Map<Id, Rewards_Account__c> mapRewardsAccountsWithEvents,
        Map<Id, Reward__c> mapRewards
    ) {
        for (Rewards_Account__c ra : mapRewardsAccsToSortedEvents.keySet()) {
            
            Decimal raStartingPointsTotal = ra.Points_Total__c != null ? ra.Points_Total__c : 0;
            Decimal runningPointsTotal    = 0;
            
            for (Rewards_Event__c re : mapRewardsAccsToSortedEvents.get(ra)) {
                setEmptyFields(re, mapRewardsAccountsWithEvents, mapRewards);
                if (re.Id == null && re.RecordTypeId == redemptionRecordTypeId) {
                    Boolean costIsCovered = verifyCostIsCovered(re, raStartingPointsTotal);
                    if (!costIsCovered) {
                        re.addError('Not enough points for reward.');
                    }
                }
                if (re.Points__c != 0) {
                    runningPointsTotal = addToPointsTotal(runningPointsTotal, re, mapRewardsAccountsWithEvents);
                }
            }
            // Only update accounts if total value has changed
            if (runningPointsTotal != raStartingPointsTotal) {
                if (mapRewardsAccountsToUpdate == null) {
                    mapRewardsAccountsToUpdate = new Map<Id, Rewards_Account__c>();
                }
                ra.Points_Total__c = runningPointsTotal;
                mapRewardsAccountsToUpdate.put(ra.Id, ra);
            }
        }
    }

    private static Boolean verifyCostIsCovered(
        Rewards_Event__c re,
        Decimal raStartingPointsTotal
    ) {
        return raStartingPointsTotal >= re.Points__c ? true : false;
    }

    private static Decimal addToPointsTotal(
        Decimal pointsTotal, 
        Rewards_Event__c re,
        Map<Id, Rewards_Account__c> mapRewardsAccounts
    ) {
        setRecordTypeIds();

        if (pointsTotal == null) {
            pointsTotal = mapRewardsAccounts.get(re.Rewards_Account__c).Points_Total__c != null
                            ? mapRewardsAccounts.get(re.Rewards_Account__c).Points_Total__c : 0;
        }
        Decimal oldBalance = re.Points_Balance__c != null ? re.Points_Balance__c : null;

        if (re.RecordTypeId == awardRecordTypeId) {
            pointsTotal += re.Points__c;
            re.Points_Balance__c = pointsTotal;
        } else if (re.RecordTypeId == redemptionRecordTypeId || re.RecordTypeId == expirationRecordTypeId) {
            pointsTotal -= re.Points__c;
            re.Points_Balance__c = pointsTotal;
        }
        // If balance has changed, add to map of rewards events to update
        if (re.Id != null && re.Points_Balance__c != oldBalance) {
            if (mapRewardsEventsToUpdate == null) {
                mapRewardsEventsToUpdate = new Map<Id, Rewards_Event__c>();
            }
            mapRewardsEventsToUpdate.put(re.Id, re);
        }

        return pointsTotal;

    }

    private static void setEmptyFields(
        Rewards_Event__c re,
        Map<Id, Rewards_Account__c> mapRewardsAccounts, 
        Map<Id, Reward__c> mapRewards
    ) {
        setRecordTypeIds();
        setUniversalFields(re, mapRewardsAccounts);
        if (re.RecordTypeId == awardRecordTypeId) {
            setEmptyAwardFields(re, mapRewardsAccounts);
        }
        if (re.RecordTypeId == redemptionRecordTypeId) {
            setEmptyRedemptionFields(re, mapRewardsAccounts, mapRewards);
        }
    }

    private static void setUniversalFields(
        Rewards_Event__c re,
        Map<Id, Rewards_Account__c> mapRewardsAccounts
    ) {
        Rewards_Account__c ra = mapRewardsAccounts.get(re.Rewards_Account__c);
        String programName = mapRewardsAccounts.get(re.Rewards_Account__c)?.Rewards_Program__r?.Name;
        if (String.isEmpty(re.Rewards_Program_Name__c)) {
            re.Rewards_Program_Name__c = ra.Rewards_Program__r.Name;
        }
        if (String.isEmpty(re.Rewards_Program_ID__c)) {
            re.Rewards_Program_ID__c = ra.Rewards_Program__c;
        }
        if (re.Date__c == null) {
            re.Date__c = Datetime.now();
        }
        if (re.Contact__c == null) {
            re.Contact__c = ra.Contact__c;
        }
    }

    private static void setEmptyAwardFields(
        Rewards_Event__c re,
        Map<Id, Rewards_Account__c> mapRewardsAccounts
    ) {
        Rewards_Account__c ra = mapRewardsAccounts.get(re.Rewards_Account__c);
        if (String.isEmpty(re.Description__c)) {
            re.Description__c = ra.Rewards_Program__r.Name + ' Points';
        }
        if (String.isEmpty(re.Status__c)) {
            re.Status__c = ra.Status__c == 'Active' || ra.Status__c == 'Pending' ? 'Active' : 'Inactive';
        }
        if (
            re.Expiration_Date__c == null &&
            (ra.Rewards_Program__r.Days_Until_Points_Expire__c != null ||
             ra.Rewards_Program__r.End_Datetime__c != null)
        ) {
            re.Expiration_Date__c = getExpirationDateForRewardsEvent(ra, re, re.Expiration_Date__c);
        }
    }

    private static void setEmptyRedemptionFields(
        Rewards_Event__c re,
        Map<Id, Rewards_Account__c> mapRewardsAccounts, 
        Map<Id, Reward__c> mapRewards
    ) {
        if (String.isBlank(re.Description__c)) {
            re.Description__c = mapRewards.get(re.Reward__c)?.Name;
        }
        if (re.Points__c == null) {
            re.Points__c = mapRewards.get(re.Reward__c)?.Cost__c;
        }
    }

    private static Map<Rewards_Account__c, List<Rewards_Event__c>> getMapAccountsToEvents(
        List<Rewards_Event__c> lstREsInTrigger,
        Map<Id, Rewards_Account__c> mapRewardsAccountsWithEvents
    ) {
        Map<Rewards_Account__c, List<Rewards_Event__c>> mapAccountsToEvents = new Map<Rewards_Account__c, List<Rewards_Event__c>>();
        
        // Populate map for each Rewards Account in trigger context
        for (Rewards_Account__c ra : mapRewardsAccountsWithEvents.values()) {
            List<Rewards_Event__c> lstRAsRewardsEvents = new List<Rewards_Event__c>();
            for (Rewards_Event__c re : lstREsInTrigger) {
                if (re.Rewards_Account__c == ra.Id) {
                    lstRAsRewardsEvents.add(re);
                }
            }
            lstRAsRewardsEvents.addAll(ra.Rewards_Events__r);
            lstRAsRewardsEvents = sortRewardsEventsByDate(lstRAsRewardsEvents);
            mapAccountsToEvents.put(ra, lstRAsRewardsEvents);
        }
        return mapAccountsToEvents;
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

    private static Date getExpirationDateForRewardsEvent(
        Rewards_Account__c rewardsAccount, 
        Rewards_Event__c rewardsEvent,
        Date reExpirationDate
    ) {
        List<Date> lstDates = new List<Date>();
        // Get expiration based on number of days until rewards event expires
        if (reExpirationDate != null) {
            lstDates.add(reExpirationDate);
        }
        // Get expiration based on number of days until rewards program points expire
        if (rewardsAccount.Rewards_Program__r.Days_Until_Points_Expire__c != null) {
            Decimal pDaysUntilExpiration = rewardsAccount.Rewards_Program__r.Days_Until_Points_Expire__c;
            Date rewardsEventDate = rewardsEvent.Date__c == null ? Date.today() 
                : Date.newInstance(rewardsEvent.Date__c.year(), rewardsEvent.Date__c.month(), rewardsEvent.Date__c.day());
            Date rewardsProgramExpiration = rewardsEventDate.addDays( pDaysUntilExpiration.intValue() );
            lstDates.add(rewardsProgramExpiration);
        }
        // Get expiration based on final day of program
        if (rewardsAccount.Rewards_Program__r.End_Datetime__c != null) {
            Datetime rpEndDatetime = rewardsAccount.Rewards_Program__r.End_Datetime__c;
            Date rewardsProgramEndDate = Date.newInstance(rpEndDatetime.year(), rpEndDatetime.month(), rpEndDatetime.day());
            lstDates.add(rewardsProgramEndDate);
        }
        // Return earliest date
        lstDates.sort();
        return lstDates[0];
    }
    
}