global class RewardsEventWrapper implements Comparable {

    public Rewards_Event__c rewardsEvent;
    
    // Constructor
    public RewardsEventWrapper(Rewards_Event__c re) {
        rewardsEvent = re;
    }
    
    // Compare Rewards Events based on the date.
    global Integer compareTo(Object compareTo) {
        // Cast argument to RewardsEventWrapper
        RewardsEventWrapper compareToRE = (RewardsEventWrapper)compareTo;
        
        // The return value of 0 indicates that both elements are equal.
        Integer returnValue = 0;
        if (rewardsEvent.Date__c > compareToRE.rewardsEvent.Date__c) {
            // Set return value to a positive value.
            returnValue = 1;
        } else if (rewardsEvent.Date__c < compareToRE.rewardsEvent.Date__c) {
            // Set return value to a negative value.
            returnValue = -1;
        } else if ((rewardsEvent.Date__c == null) && (compareToRE.rewardsEvent.Date__c != null)){
            // nulls-first implementation
            returnValue = -1;
        } else if ((rewardsEvent.Date__c != null) && (compareToRE.rewardsEvent.Date__c == null)){
            // nulls-first implementation
            returnValue = 1;
        }
        return returnValue;
    }
}