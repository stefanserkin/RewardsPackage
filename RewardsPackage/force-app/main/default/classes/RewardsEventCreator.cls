global class RewardsEventCreator {

    private static Id awardRecordTypeId = Schema.SObjectType.Rewards_Event__c.getRecordTypeInfosByDeveloperName().get('Award').getRecordTypeId();

    @InvocableMethod(label='Create Rewards Event' description='Creates a rewards event based on arguments' category='Rewards')
    public static List<Result> createRewardsEvent(List<Request> request) {
        String rewardsProgramId     = request.get(0).rewardsProgramId;
        String contactId            = request.get(0).contactId;
        Decimal points              = request.get(0).points;
        String description          = request.get(0).description;
        String relatedEntityId;
        if (request.get(0).relatedEntityId != null) relatedEntityId = request.get(0).relatedEntityId;
        Decimal daysUntilExpiration = 0;
        if (request.get(0).daysUntilExpiration != null) daysUntilExpiration = request.get(0).daysUntilExpiration;
        Boolean isSuccess;

        Rewards_Program__c rewardsProgram = [SELECT Id, Name, Days_Until_Points_Expire__c 
                                               FROM Rewards_Program__c 
                                              WHERE Id = :rewardsProgramId 
                                               WITH SECURITY_ENFORCED 
                                              LIMIT 1];

        Rewards_Account__c rewardsAccount = [SELECT Id, Points_Total__c 
                                               FROM Rewards_Account__c 
                                              WHERE Contact__c = :contactId 
                                                AND Rewards_Program__c = :rewardsProgramId
                                                AND Status__c IN ('Pending','Active') 
                                               WITH SECURITY_ENFORCED
                                              LIMIT 1];

        Decimal runningBalance = rewardsAccount.Points_Total__c + points;
        if (daysUntilExpiration == null & rewardsProgram.Days_Until_Points_Expire__c != null) {
            daysUntilExpiration = rewardsProgram.Days_Until_Points_Expire__c;
        }

        Rewards_Event__c re = new Rewards_Event__c();
        re.RecordTypeId            = awardRecordTypeId;
        re.Rewards_Account__c      = rewardsAccount.Id;
        re.Points__c               = points;
        re.Description__c          = description;
        re.Related_Entity_ID__c    = relatedEntityId;
        re.Rewards_Program_ID__c   = rewardsProgramId;
        re.Rewards_Program_Name__c = rewardsProgram.Name;
        if (daysUntilExpiration != null && daysUntilExpiration > 0)
            Date.today().addDays( daysUntilExpiration.intValue() );
        re.Points_Balance__c       = runningBalance;
        re.Date__c                 = Datetime.now();
        re.Active__c               = true;
        re.Status__c               = 'Active';
        try {
            insert re;
            isSuccess = true;
        } catch (DmlException e) {
            isSuccess = false;
        }

        Result result = new Result();
        result.isSuccess = isSuccess;
        result.rewardsEvent = re;
        List<Result> resultList = new List<Result>();
        resultList.add(result);
        return resultList;
    }

    public class Request {

        @InvocableVariable(required=true)
        public String rewardsProgramId;

        @InvocableVariable(required=true)
        public String contactId;

        @InvocableVariable(required=true)
        public Decimal points;

        @InvocableVariable(required=true)
        public String description;

        @InvocableVariable
        public String relatedEntityId;

        @InvocableVariable
        public Decimal daysUntilExpiration;

    }

    public class Result {

        @InvocableVariable
        public Rewards_Event__c rewardsEvent;

        @InvocableVariable
        public Boolean isSuccess;

    }

}