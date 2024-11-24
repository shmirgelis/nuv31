public class CaseTriggerHandler {
    public static void beforeInsert(List<Case> newCases) {
        // Add logic for before insert
    }

    public static void beforeUpdate(List<Case> newCases, Map<Id, Case> oldCaseMap) {
        // Add logic for before update
    }

    public static void afterInsert(List<Case> newCases) {
        // Add logic for after insert
    }

    public static void afterUpdate(List<Case> newCases, Map<Id, Case> oldCaseMap) {
        // Add logic for after update
    }
}