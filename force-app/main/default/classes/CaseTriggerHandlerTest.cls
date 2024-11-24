@isTest
public class CaseTriggerHandlerTest {
    @testSetup
    public static void prepareTestData() {
        List<Case> listOfCases = new List<Case>();
        for (Integer i = 0; i < 4; i++) {
            if (i < 2) {
                listOfCases.add(new Case(Status = 'On Hold', Subject = 'Test Case Update ' + i));
            } else {
                listOfCases.add(new Case(Status = 'New', Subject = 'Test Case Update ' + i));
            }
        }
        insert listOfCases;
    }

    @isTest
    static void testCaseCreationWithNewStatus() {
        Case testCase = new Case(Status = 'New', Subject = 'Test Case');

        Test.startTest();
        insert testCase;
        Test.stopTest();

        Case insertedCase = [SELECT Id, Status, Status_Change_Start_Time__c, SLA_Total_Time__c FROM Case WHERE Id = :testCase.Id];

        Assert.areEqual('New', insertedCase.Status);
        Assert.isNotNull(insertedCase.Status_Change_Start_Time__c);
        Assert.isNotNull(insertedCase.SLA_Total_Time__c);
    }

    @isTest
    static void testCaseCreationWithNotNewStatus() {
        Case testCase = new Case(Status = 'On Hold', Subject = 'Test Case');

        Test.startTest();
        insert testCase;
        Test.stopTest();

        Case insertedCase = [SELECT Id, Status, Status_Change_Start_Time__c, SLA_Total_Time__c FROM Case WHERE Id = :testCase.Id];

        Assert.areEqual('On Hold', insertedCase.Status);
        Assert.isNull(insertedCase.Status_Change_Start_Time__c);
        Assert.isNull(insertedCase.SLA_Total_Time__c);
    }

    @isTest
    static void testCaseCreationWithResolvedStatus() {
        Case testCase = new Case(Status = 'Resolved', Subject = 'Test Case');

        Test.startTest();
        insert testCase;
        Test.stopTest();

        Case insertedCase = [SELECT Id, Status, Case_SLA__c FROM Case WHERE Id = :testCase.Id];

        Assert.areEqual('Resolved', insertedCase.Status);
        Assert.areEqual('0 minutes', insertedCase.Case_SLA__c);
    }

    @isTest
    static void testCaseUpdateToResolvedStatus() {
        List<Case> cases = [SELECT Id, Status, SLA_Total_Time__c FROM Case WHERE Subject LIKE 'Test Case Update%' LIMIT 4];

        for (Case c : cases) {
            c.Status = 'In Progress';
        }
        update cases;

        Test.startTest();
        for (Case c : cases) {
            c.Status = 'Resolved';
            if (c.SLA_Total_Time__c != null) {
                c.SLA_Total_Time__c = 80000; // adding some time to SLA to cover the case when SLA is more than 1 minute
            }
        }
        update cases;
        Test.stopTest();

        List<Case> updatedCaseToResolveNoSLACases = [SELECT Id, Case_SLA__c FROM Case WHERE Status = 'Resolved' AND SLA_Total_Time__c = null AND Status_Change_Start_Time__c = null];
        List<Case> updatedCaseToResolveCases = [SELECT Id, Case_SLA__c, Status_Change_Start_Time__c FROM Case WHERE Status = 'Resolved' AND SLA_Total_Time__c != null AND Status_Change_Start_Time__c != null AND Case_SLA__c != null];

        Assert.areEqual(2, updatedCaseToResolveNoSLACases.size());
        Assert.areEqual('0 minutes', updatedCaseToResolveNoSLACases[0].Case_SLA__c);
        Assert.areEqual('0 minutes', updatedCaseToResolveNoSLACases[1].Case_SLA__c);
        Assert.areEqual(2, updatedCaseToResolveCases.size());
    }

    @isTest
    static void testCaseUpdateToNewToResolvedStatus() {
        List<Case> cases = [SELECT Id, Status, SLA_Total_Time__c FROM Case WHERE Subject LIKE 'Test Case Update%' AND Status != 'New' LIMIT 2];

        for (Case c : cases) {
            c.Status = 'New';
        }
        update cases;

        Test.startTest();
        cases[0].Status = 'Resolved';
        cases[0].SLA_Total_Time__c = 3605555; // adding some time to SLA to cover the case when SLA is more than 1 hour
        cases[1].Status = 'Resolved';
        cases[1].SLA_Total_Time__c = 86405555; // adding some time to SLA to cover the case when SLA is more than 1 day
        update cases;
        Test.stopTest();

        List<Case> updatedCaseToResolveCases = [SELECT Id, Case_SLA__c, Status_Change_Start_Time__c FROM Case WHERE Status = 'Resolved' AND SLA_Total_Time__c != null AND Status_Change_Start_Time__c != null AND Case_SLA__c != null];

        Assert.areEqual(2, updatedCaseToResolveCases.size());
    }
}