global without sharing class RewardsEventCreator {

    @InvocableMethod(label='Create Rewards Event' description='Creates a rewards event based on arguments' category='Rewards')
    public static void createRewardsEvent(List<Request> request) {
        String rewardsProgramId     = request.get(0).rewardsProgramId;
        String contactId            = request.get(0).contactId;
        Decimal points              = request.get(0).points;
        String description          = request.get(0).description;
        String relatedEntityId;
        if (request.get(0).relatedEntityId != null) {
            relatedEntityId = request.get(0).relatedEntityId;
        }
        Decimal daysUntilExpiration;
        if (request.get(0).daysUntilExpiration != null) {
            daysUntilExpiration = request.get(0).daysUntilExpiration;
        }

        RewardsEventHandler.handleInvokedRewardsEventCreation(
            rewardsProgramId, // rewardsProgramId
            contactId, // contactId
            points, // points
            description, // description
            relatedEntityId, // relatedEntityId
            daysUntilExpiration // daysUntilExpiration
        );

    }

    public class Request {

        @InvocableVariable(label='Rewards Program ID' required=true)
        public String rewardsProgramId;

        @InvocableVariable(label='Contact ID' required=true)
        public String contactId;

        @InvocableVariable(label='Points Awarded' required=true)
        public Decimal points;

        @InvocableVariable(label='Description' required=true)
        public String description;

        @InvocableVariable(label='Related Entity Id' description='Optionally include the Record ID of the record that initiated this event')
        public String relatedEntityId;

        @InvocableVariable(label='Days Until Expiration' description='Optional. Points will expire after this amount of days, unless the Rewards Program policies expire them sooner')
        public Decimal daysUntilExpiration;

    }

}