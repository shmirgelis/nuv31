---

## CaseTriggerHandler Class

### Summary
This class manages the logic for Case records before they are inserted or updated in Salesforce. It ensures accurate calculation and updating of Service Level Agreement (SLA) times based on status changes and the support agent's business hours, which are configured according to time zones.

The SLA calculation begins when the case status is set to "New," either upon creation or update. The SLA time progresses when the support agent is within their business hours and the case status is "New" or "In Progress." Conversely, the SLA time pauses if the case status is anything other than "New" or "In Progress," or if the support agent is outside their business hours, including holidays and weekends.

When the case status changes to "Resolved," the "Case SLA" field is populated with a string representing the SLA time in days, hours, and minutes.
### Methods:

1. **beforeInsert(List<Case> newCases)**
   - This method is triggered before new Case records are inserted.
   - It initializes the `Status_Change_Start_Time__c` and `SLA_Total_Time__c` fields for cases with the status 'New'.
   - If a case is created with the status 'Resolved', it sets the `Case_SLA__c` field to '0 minutes'.
   - SLA starts with case status "New" and stops with "Resolved" status.

2. **beforeUpdate(List<Case> newCases, Map<Id, Case> oldCaseMap)**
   - This method is triggered before existing Case records are updated.
   - It calls the `calculateCaseSLATime` method to update the SLA times based on the status changes.

3. **calculateCaseSLATime(List<Case> newCases, Map<Id, Case> oldCaseMap, Map<Id, Id> caseOwnerIdToBussinessHoursId)**
   - This method calculates the SLA time for each case.
   - `Status_Change_Start_Time__c` fiels is updated on every case Status change, field is used to calculate business hours.
   - `SLA_Total_Time__c` field is updated only for "New" and "In Progress" case statuses.
   - If a case is resolved, it converts the total SLA time from milliseconds to a formatted string and updates the `Case_SLA__c` field.

4. **getCaseOwnerBusinessHoursId(List<Case> cases)**
   - This method retrieves the business hours for each case owner based on their time zone.
   - Salesforce org Business hours setup lets correctly calculate Case SLA. 

5. **convertMillisecondsToFormattedTime(Integer slaTimeInMilliSeconds)**
   - This method converts the SLA time from milliseconds to a formatted string (e.g., '2 days 3 hours 15 minutes').

6. **formatTime(Integer days, Integer hours, Integer minutes)**
   - This method formats the time components (days, hours, minutes) into a readable string.

---
