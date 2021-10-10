@isTest
public class RewardsCommonUtilities_Test {

    private static Map<String, Rewards_Automation_Override__mdt> raoMap = Rewards_Automation_Override__mdt.getAll();

    @isTest
    static void testBypassRewardsAccount() {

        String objType = 'Rewards_Account__c';

        Boolean bypassTriggerResult = RewardsCommonUtilities.bypassTrigger(objType);
        Boolean hasValidBypass = false;
        for (Rewards_Automation_Override__mdt rao : raoMap.values()) {
            if (rao.SObject_Type__c == objType) {
                if (rao.Active__c) {
                    if (rao.Bypass_All__c) {
                        hasValidBypass = true;
                    } else if ((rao.User_IDs__c != null && rao?.User_IDs__c.containsIgnoreCase(UserInfo.getUserId())) ||
                                    (rao?.Profile_IDs__c != null && rao?.Profile_IDs__c.contains(UserInfo.getProfileId()))) 
                    {
                        hasValidBypass = true;
                    }
                }
            }
        }
        System.assertEquals(hasValidBypass, bypassTriggerResult, 'Unexpected bypass result');

    }

    @isTest
    static void testBypassRewardsEvent() {

        String objType = 'Rewards_Event__c';

        Boolean bypassTriggerResult = RewardsCommonUtilities.bypassTrigger(objType);
        Boolean hasValidBypass = false;
        for (Rewards_Automation_Override__mdt rao : raoMap.values()) {
            if (rao.SObject_Type__c == objType) {
                if (rao.Active__c) {
                    if (rao.Bypass_All__c) {
                        hasValidBypass = true;
                    } else if ((rao.User_IDs__c != null && rao?.User_IDs__c.containsIgnoreCase(UserInfo.getUserId())) ||
                                    (rao?.Profile_IDs__c != null && rao?.Profile_IDs__c.contains(UserInfo.getProfileId()))) 
                    {
                        hasValidBypass = true;
                    }
                }
            }
        }
        System.assertEquals(hasValidBypass, bypassTriggerResult, 'Unexpected bypass result');

    }

    @isTest
    static void testBypassRewardsEventLink() {

        String objType = 'Rewards_Event_Link__c';

        Boolean bypassTriggerResult = RewardsCommonUtilities.bypassTrigger(objType);
        Boolean hasValidBypass = false;
        for (Rewards_Automation_Override__mdt rao : raoMap.values()) {
            if (rao.SObject_Type__c == objType) {
                if (rao.Active__c) {
                    if (rao.Bypass_All__c) {
                        hasValidBypass = true;
                    } else if ((rao.User_IDs__c != null && rao?.User_IDs__c.containsIgnoreCase(UserInfo.getUserId())) ||
                                    (rao?.Profile_IDs__c != null && rao?.Profile_IDs__c.contains(UserInfo.getProfileId()))) 
                    {
                        hasValidBypass = true;
                    }
                }
            }
        }
        System.assertEquals(hasValidBypass, bypassTriggerResult, 'Unexpected bypass result');

    }

    @isTest
    static void testInvalidObjectName() {

        String objType = 'LetsGoMets';

        Boolean bypassTriggerResult = RewardsCommonUtilities.bypassTrigger(objType);
        Boolean hasValidBypass = false;
        for (Rewards_Automation_Override__mdt rao : raoMap.values()) {
            if (rao.SObject_Type__c == objType) {
                if (rao.Active__c) {
                    if (rao.Bypass_All__c) {
                        hasValidBypass = true;
                    } else if ((rao.User_IDs__c != null && rao?.User_IDs__c.containsIgnoreCase(UserInfo.getUserId())) ||
                                    (rao?.Profile_IDs__c != null && rao?.Profile_IDs__c.contains(UserInfo.getProfileId()))) 
                    {
                        hasValidBypass = true;
                    }
                }
            }
        }
        System.assertEquals(hasValidBypass, bypassTriggerResult, 'Unexpected bypass result');

    }

    @isTest
    static void testActiveBypassAll() {
        RewardsCommonUtilities.setTestActive();
        RewardsCommonUtilities.setTestBypassAll();
        RewardsCommonUtilities.setTestObjectFound();
        Boolean result = RewardsCommonUtilities.bypassTrigger('TestingFakeStuff');
        System.assert(result, 'Expected to bypass the test routine');
    }

    @isTest
    static void testActiveBypassUser() {
        RewardsCommonUtilities.setTestActive();
        RewardsCommonUtilities.setTestUserFound();
        RewardsCommonUtilities.setTestObjectFound();
        Boolean result = RewardsCommonUtilities.bypassTrigger('TestingFakeStuff');
        System.assert(result, 'Expected to bypass the test routine');
    }

    @isTest
    static void testActiveBypassProfile() {
        RewardsCommonUtilities.setTestActive();
        RewardsCommonUtilities.setTestProfileFound();
        RewardsCommonUtilities.setTestObjectFound();
        Boolean result = RewardsCommonUtilities.bypassTrigger('TestingFakeStuff');
        System.assert(result, 'Expected to bypass the test routine');
    }

}