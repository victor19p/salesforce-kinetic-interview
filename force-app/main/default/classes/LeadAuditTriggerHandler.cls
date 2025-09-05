/**
 * @description Opportunity Audit Trigger handler
 * @author Victor Pineda
 * @since 2025
 * @group OpportunityAuditTriggerHandler
 * https://github.com/dschach/salesforce-trigger-framework
 */

public without sharing class LeadAuditTriggerHandler extends TriggerHandler {
    private List<Lead> newRecords;
    private List<Lead> oldRecords;
    private Map<Id, Lead> newRecordsMap;
    private Map<Id, Lead> oldRecordsMap;

    public LeadAuditTriggerHandler(String className) {
        this.newRecords = (List<Lead>) Trigger.new;
        this.oldRecords = (List<Lead>) Trigger.old;
        this.newRecordsMap = (Map<Id, Lead>) Trigger.newMap;
        this.oldRecordsMap = (Map<Id, Lead>) Trigger.oldMap;
    }

    public override void afterInsert() {
        // Implement logic for after insert
        System.debug(LoggingLevel.INFO, 'Lead inserted: ' + newRecords);
    }

    public override void afterUpdate() {
        // Implement logic for after update
        System.debug(LoggingLevel.INFO, 'Lead updated: ' + oldRecords);
    }
}