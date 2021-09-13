public without sharing class RewardsExpirationBatchUpdater implements Database.Batchable<sObject> {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Id awardRecTypeId = Schema.SObjectType.Rewards_Event__c.getRecordTypeInfosByDeveloperName()
                                .get('Award').getRecordTypeId();
        String query = 'SELECT Id, Rewards_Program__c, Rewards_Program__r.Name, End_Datetime__c, Status__c,';
        query += ' (SELECT Id, Status__c, Points_Remaining__c FROM Rewards_Events__r';
        query += ' WHERE Expiration_Date__c != null AND Expiration_Date__c < TODAY';
        query += ' AND Points_Remaining__c > 0 AND Status__c = \'Active\'';
        query += ' AND RecordTypeId = \'' + awardRecTypeId + '\')';
        query += ' FROM Rewards_Account__c';
        query += ' WHERE Id IN (SELECT Rewards_Account__c FROM Rewards_Event__c';
        query += ' WHERE (Expiration_Date__c != null AND Expiration_Date__c < TODAY';
        query += ' AND Points_Remaining__c > 0 AND Status__c = \'Active\'';
        query += ' AND RecordTypeId = \'' + awardRecTypeId + '\'))';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Rewards_Account__c> scope) {
        Id expRecTypeId = Schema.SObjectType.Rewards_Event__c.getRecordTypeInfosByDeveloperName()
                            .get('Expiration').getRecordTypeId();

        Map<Id, Rewards_Event__c> mapAccountToExpREs = new Map<Id, Rewards_Event__c>();
        List<Rewards_Event_Link__c> lstRELsToInsert = new List<Rewards_Event_Link__c>();
        List<Rewards_Account__c> lstRewardsAccsToUpdate = new List<Rewards_Account__c>();

        for (Rewards_Account__c ra : scope) {
            Decimal sumOfExpiringPts = 0;

            if (ra.End_Datetime__c < Datetime.now() && ra.Status__c == 'Active') {
                ra.Status__c = 'Complete';
                lstRewardsAccsToUpdate.add(ra);
            }

            for (Rewards_Event__c re : ra.Rewards_Events__r) {
                if (re.Points_Remaining__c != null) {
                    sumOfExpiringPts += re.Points_Remaining__c;
                }
            }
            mapAccountToExpREs.put(
                ra.Id,
                new Rewards_Event__c(
                    RecordTypeId            = expRecTypeId,
                    Status__c               = 'Applied',
                    Date__c                 = Datetime.now(),
                    Description__c          = 'Points Expired',
                    Rewards_Account__c      = ra.Id,
                    Points__c               = sumOfExpiringPts,
                    Rewards_Program_Name__c = ra.Rewards_Program__r.Name,
                    Rewards_Program_ID__c   = ra.Rewards_Program__c
                )
            );
        }

        if (!lstRewardsAccsToUpdate.isEmpty()) {
            update lstRewardsAccsToUpdate;
        }

        insert mapAccountToExpREs.values();

        for (Rewards_Account__c ra : scope) {
            Rewards_Event__c expirationEvent = mapAccountToExpREs.get(ra.Id);
            for (Rewards_Event__c re : ra.Rewards_Events__r) {
                lstRELsToInsert.add(
                    new Rewards_Event_Link__c(
                        Award_Event__c     = re.Id,
                        Deduction_Event__c = expirationEvent.Id,
                        Points_Used__c     = re.Points_Remaining__c,
                        Type__c            = 'Expiration'
                    )
                );
            }
        }
        insert lstRELsToInsert;
    }

    public void finish(Database.BatchableContext bc) {
        AsyncApexJob apexJob = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email
                                FROM AsyncApexJob WHERE Id =: bc.getJobId()];
        
        // Send email to job creator with batch results
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        String[] toAddress = new String[] {apexJob.CreatedBy.Email};
        system.debug('apexJob.CreatedBy.Email : '+apexJob.CreatedBy.Email);
        email.setToAddresses(toAddress);
        email.setSubject('Apex Job status is ' + apexJob.Status);
        email.setPlainTextBody('The batch Apex job processed ' + apexJob.TotalJobItems + ' batches with '+ apexJob.NumberOfErrors + ' failures.');
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
    }

}