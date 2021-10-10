public without sharing class RewardsCommonUtilities {

    /**
     * Set in test context to avoid manipulating custom metadata records
     */
    @TestVisible private static Boolean testActive = false;
    @TestVisible private static Boolean testBypassAll = false;
    @TestVisible private static Boolean testUserFound = false;
    @TestVisible private static Boolean testProfileFound = false;
    @TestVisible private static Boolean testObjectFound = false;
    @TestVisible private static void setTestActive() { testActive = true; }
    @TestVisible private static void setTestBypassAll() { testBypassAll = true; }
    @TestVisible private static void setTestUserFound() { testUserFound = true; }
    @TestVisible private static void setTestProfileFound() { testProfileFound = true; }
    @TestVisible private static void setTestObjectFound() { testObjectFound = true; }

    private static Map<String, Rewards_Automation_Override__mdt> raoMap;

    /** 
     * Returns true if the running user's id or profileId is found in
     * an active override for the provided SObject Type
     */
    public static Boolean bypassTrigger(String sObjectType) {
        if (raoMap == null) {
            raoMap = new Map<String, Rewards_Automation_Override__mdt>();
            List<Rewards_Automation_Override__mdt> raoList = Rewards_Automation_Override__mdt.getAll().values();
            for (Rewards_Automation_Override__mdt rao : raoList) {
                raoMap.put(rao.SObject_Type__c, rao);
            }
        }
        Rewards_Automation_Override__mdt rao = raoMap.get(sObjectType);
        if (rao == null && !testObjectFound) {
            return false;
        }
        if (testActive || rao.Active__c) {
            if (testBypassAll || (rao != null && rao.Bypass_All__c)) {
                return true;
            } else if (
                testUserFound || (rao?.User_IDs__c != null && rao?.User_IDs__c.containsIgnoreCase(UserInfo.getUserId()))
            ) {
                return true;
            } else if (
                testProfileFound || (rao?.Profile_IDs__c != null && rao?.Profile_IDs__c.contains(UserInfo.getProfileId()))
            ) {
                return true;
            }
        }
        return false;
    }

}