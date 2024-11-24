@isTest
public class CaseTriggerHandlerTest {
    @isTest
    static void testBeforeInsert() {
        Case testCase = new Case();
        insert testCase;
        
        // Add assertions to verify the trigger logic
        System.assertEquals('Default Value', testCase.Custom_Field__c);
    }
}