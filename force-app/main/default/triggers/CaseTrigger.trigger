trigger CaseTrigger on Case (before insert, before update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            CaseTriggerHandler.beforeInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            CaseTriggerHandler.beforeUpdate(Trigger.new, Trigger.oldMap);
        }
    } 
}