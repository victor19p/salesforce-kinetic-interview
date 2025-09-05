/**
 * @description Opportunity Audit Trigger handler
 * @author Victor Pineda
 * @since 2025
 * @group OpportunityAuditTriggerHandler
 * https://github.com/dschach/salesforce-trigger-framework
 */

public without sharing class OpportunityAuditTriggerHandler extends TriggerHandler {
    private List<Opportunity> newRecords;
	private List<Opportunity> oldRecords;
	private Map<Id, Opportunity> newRecordsMap;
	private Map<Id, Opportunity> oldRecordsMap;

    public OpportunityAuditTriggerHandler(String className) {
        super('OpportunityAuditTriggerHandler');
		this.newRecords = (List<Opportunity>) Trigger.new;
		this.oldRecords = (List<Opportunity>) Trigger.old;
		this.newRecordsMap = (Map<Id, Opportunity>) Trigger.newMap;
		this.oldRecordsMap = (Map<Id, Opportunity>) Trigger.oldMap;
	}

    public override void afterInsert() {
        TriggerHandler.bypass('OpportunityAuditTriggerHandler');

        AuditService auditService = new AuditService();
        auditService.createAuditForOpportunity(newRecordsMap, oldRecordsMap, 'AFTER_INSERT');

        AuditParticipantService auditParticipantService = new AuditParticipantService();
        auditParticipantService.createAuditParticipantForOpportunity(newRecordsMap, oldRecordsMap, 'AFTER_INSERT');

        TriggerHandler.clearBypass('OpportunityAuditTriggerHandler');
    }

    public override void afterUpdate() {
        TriggerHandler.bypass('OpportunityAuditTriggerHandler');

        AuditService auditService = new AuditService();
        auditService.createAuditForOpportunity(newRecordsMap, oldRecordsMap, 'AFTER_UPDATE');

        AuditParticipantService auditParticipantService = new AuditParticipantService();
        auditParticipantService.createAuditParticipantForOpportunity(newRecordsMap, oldRecordsMap, 'AFTER_UPDATE');

        TriggerHandler.clearBypass('OpportunityAuditTriggerHandler');
    }

    public override void andFinally() {
        TriggerHandler.clearBypass('OpportunityAuditTriggerHandler');
    }
}
