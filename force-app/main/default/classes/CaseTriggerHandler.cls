public with sharing class CaseTriggerHandler {

    public static void beforeInsert(List<Case> newCases) {
        for(Case newCase : newCases) {
            if(newCase.Status == 'New') {
                newCase.Status_Change_Start_Time__c = Datetime.now();
                newCase.SLA_Total_Time__c = 0;
            }
             // below code block is testing case resoliution on case creation.
             if(newCase.Status == 'Resolved') {
                newCase.Case_SLA__c = '0 minutes';
            }
        }
    }

    public static void beforeUpdate(List<Case> newCases, Map<Id, Case> oldCaseMap) {   
        calculateCaseSLATime(newCases, oldCaseMap, getCaseOwnerBusinessHoursId(newCases));       
    }
    
    private static void calculateCaseSLATime(List<Case> newCases, Map<Id, Case> oldCaseMap,  Map<Id, Id> caseOwnerIdToBussinessHoursId) {
        for(Case newCase : newCases) {
            Case oldCase = oldCaseMap.get(newCase.Id);
             // if case was not created with New status, SLA will start here with New status. If case always starts witn NEW status, this block can be removed. 
             if(newCase.Status == 'New' && oldCase.Status_Change_Start_Time__c == null) {
                newCase.Status_Change_Start_Time__c = Datetime.now();
                newCase.SLA_Total_Time__c = 0;
                continue;
            }
            // if case was Resolved without triggering SLA calculation conditions.
            if(newCase.Status == 'Resolved' && oldCase.Status_Change_Start_Time__c == null) {
                newCase.Case_SLA__c = '0 minutes';
                continue;
            }
            if((newCase.Status != oldCase.Status) && oldCase.Status_Change_Start_Time__c != null) {
                Id businessHoursId = caseOwnerIdToBussinessHoursId.get(newCase.OwnerId);          
                if(oldCase.Status == 'New' || oldCase.Status == 'In Progress' || newCase.Status == 'Resolved') {
                    System.debug('oldCase.Status_Change_Start_Time__c: ' + oldCase.Status_Change_Start_Time__c);
                    newCase.SLA_Total_Time__c += BusinessHours.diff(businessHoursId, oldCase.Status_Change_Start_Time__c, Datetime.now());
                }
                if(newCase.Status == 'Resolved') {
                    newCase.SLA_Total_Time__c += BusinessHours.diff(businessHoursId, oldCase.Status_Change_Start_Time__c, Datetime.now());
                    newCase.Case_SLA__c = convertMillisecondsToFormattedTime(Integer.valueOf(newCase.SLA_Total_Time__c));
                }
                newCase.Status_Change_Start_Time__c = Datetime.now();                
            } 
        }       
    }
    
    private static Map<Id, Id> getCaseOwnerBusinessHoursId(List<Case> cases){
        Set<Id> ownerIds = new Set<Id>();
        Map<String, Id> businessHoursMap = new Map<String, Id>();
        Map<Id, Id> caseOwnerIdToBussinessHoursId = new Map<Id, Id>();

        for (BusinessHours bh : [SELECT Id, TimeZoneSidKey FROM BusinessHours]) {
            businessHoursMap.put(bh.TimeZoneSidKey, bh.Id);
        }

        for (Case c : cases) {
            ownerIds.add(c.OwnerId);
        }

        for (User caseOwner : [SELECT Id, Name, TimeZoneSidKey FROM User WHERE Id IN :ownerIds]) {
            if (businessHoursMap.get(caseOwner.TimeZoneSidKey) != null){
                caseOwnerIdToBussinessHoursId.put(caseOwner.Id, businessHoursMap.get(caseOwner.TimeZoneSidKey));
            }
            else {
                throw new CustomException('Business Hours not found for the agent, ' + caseOwner.Name + ', agent\'s time zone is ' +  caseOwner.TimeZoneSidKey);
            }           
        }     
        return caseOwnerIdToBussinessHoursId;   
    }

    private static String convertMillisecondsToFormattedTime(Integer slaTimeInMilliSeconds) {
        Integer dayInMilliSeconds = 1000 * 60 * 60 * 24;
        Integer hoursInMilliSeconds = 1000 * 60 * 60;
        Integer minutesInMilliSeconds = 1000 * 60;
        Integer days;
        Integer hours;
        Integer minutes;
        
        if(slaTimeInMilliSeconds >= dayInMilliSeconds) {
            days = slaTimeInMilliSeconds / dayInMilliSeconds;
            slaTimeInMilliSeconds = Math.mod(slaTimeInMilliSeconds, dayInMilliSeconds);
        }
        if(slaTimeInMilliSeconds >= hoursInMilliSeconds) {
            hours = slaTimeInMilliSeconds / hoursInMilliSeconds;
            slaTimeInMilliSeconds = Math.mod(slaTimeInMilliSeconds, hoursInMilliSeconds);
        }
        if(slaTimeInMilliSeconds >= minutesInMilliSeconds) {
           minutes = slaTimeInMilliSeconds / minutesInMilliSeconds;
        }
        
        return formatTime(days, hours, minutes);
    }

    private static String formatTime(Integer days, Integer hours, Integer minutes) {
        String formattedTime = '0 minutes';
        if (days != null) {
            formattedTime = days + ' days ' + hours + ' hours ' + minutes + ' minutes';
        } else if (hours != null) {
            formattedTime = hours + ' hours ' + minutes + ' minutes';
        } else if (minutes != null) {
            formattedTime = minutes + ' minutes';
        }
        return formattedTime;
    }
}