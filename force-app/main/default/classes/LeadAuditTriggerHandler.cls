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
        super('LeadAuditTriggerHandler');
        this.newRecords = (List<Lead>) Trigger.new;
        this.oldRecords = (List<Lead>) Trigger.old;
        this.newRecordsMap = (Map<Id, Lead>) Trigger.newMap;
        this.oldRecordsMap = (Map<Id, Lead>) Trigger.oldMap;
    }

    public override void afterInsert() {
        TriggerHandler.bypass('LeadAuditTriggerHandler');

        AuditService auditService = new AuditService();
        auditService.createAuditForLead(newRecordsMap, null, 'afterInsert');

        TriggerHandler.clearAllBypasses();
    }

    public override void afterUpdate() {
        TriggerHandler.bypass('LeadAuditTriggerHandler');

        AuditService auditService = new AuditService();
        auditService.createAuditForLead(newRecordsMap, oldRecordsMap, 'afterUpdate');

        TriggerHandler.clearBypass('LeadAuditTriggerHandler');
    }
}