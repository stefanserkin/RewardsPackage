public with sharing class RewardsEventHandler {

    private static List<Rewards_Event__c> lstRewardsEventsToInsert;
    // private static Boolean balanceIsSet = false;
    private static Id awardRecordTypeId = Schema.SObjectType.Rewards_Event__c.getRecordTypeInfosByDeveloperName().get('Award').getRecordTypeId();

    public static void setRunningBalance(List<Rewards_Event__c> lstRewardsEvents) {
        // if (balanceIsSet) return;

        // Map Rewards Accounts to their list of Rewards Events
        Map<Rewards_Account__c, List<Rewards_Event__c>> mapRewardsAccsToSortedEvents = 
            new Map<Rewards_Account__c, List<Rewards_Event__c>>();
        List<Rewards_Account__c> lstRewardsAccsToUpdate = new List<Rewards_Account__c>();

        Set<Id> setRewardsAccountIds = new Set<Id>();
        // Get list of Rewards Events sorted by date
        List<Rewards_Event__c> lstSortedRewardsEvents = sortRewardsEventsByDate(lstRewardsEvents);

        for (Rewards_Event__c re : lstRewardsEvents) {
            // Set any null dates
            if (re.Date__c == null) {
                re.Date__c = DateTime.now();
            }
            // Add id to set for rewards accounts query
            setRewardsAccountIds.add(re.Rewards_Account__c);
        }

        // Get needed values from Rewards Accounts
        List<Rewards_Account__c> lstRewardsAccounts = [
            SELECT Id, Points_Total__c, Contact__c
              FROM Rewards_Account__c 
             WHERE Id IN :setRewardsAccountIds 
              WITH SECURITY_ENFORCED
             LIMIT 10000
        ];
        // Populate map for each Rewards Account in trigger context
        for (Rewards_Account__c ra : lstRewardsAccounts) {
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
        // Set static variable to ensure balance setting logic is only executed once
        // balanceIsSet = true;
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

    public static void insertRewardsEvents() {
        try {
            insert lstRewardsEventsToInsert;
        } catch (DmlException e) {
            System.debug(':::: Received an error inserting Rewards Events: ' + e.getMessage());
        }
    }

    public static Boolean handleInvokedRewardsEventCreation(
        String rewardsProgramId, String contactId, Decimal points, 
        String description, String relatedEntityId, Decimal daysUntilExpiration
    ) {
        Boolean insertIsSuccess;

        Rewards_Account__c rewardsAccount = RewardsAccountHandler.getRewardsAccount(contactId, rewardsProgramId);

        // If no rewards account, exit
        if (rewardsAccount == null) {
            return false;
        }
        // If no expiration is set by admin, take days until points expire from program
        if (daysUntilExpiration == null & rewardsAccount.Rewards_Program__r.Days_Until_Points_Expire__c != null) {
            daysUntilExpiration = rewardsAccount.Rewards_Program__r.Days_Until_Points_Expire__c;
        }

        Rewards_Event__c re = new Rewards_Event__c();
        re.RecordTypeId            = awardRecordTypeId;
        re.Rewards_Account__c      = rewardsAccount.Id;
        re.Points__c               = points;
        re.Description__c          = description;
        re.Related_Entity_ID__c    = relatedEntityId;
        re.Rewards_Program_ID__c   = rewardsAccount.Rewards_Program__c;
        re.Rewards_Program_Name__c = rewardsAccount.Rewards_Program__r.Name;
        if (daysUntilExpiration != null && daysUntilExpiration > 0)
            Date.today().addDays( daysUntilExpiration.intValue() );
        re.Date__c                 = Datetime.now();
        re.Active__c               = true;
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