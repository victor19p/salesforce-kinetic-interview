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
		this.newRecords = (List<Opportunity>) Trigger.new;
		this.oldRecords = (List<Opportunity>) Trigger.old;
		this.newRecordsMap = (Map<Id, Opportunity>) Trigger.newMap;
		this.oldRecordsMap = (Map<Id, Opportunity>) Trigger.oldMap;
	}

    public override void afterInsert() {
        // Implement logic for after insert
        System.debug(LoggingLevel.INFO, 'Opportunity inserted: ' + newRecords);
    }

    public override void afterUpdate() {
        // Implement logic for after update
        System.debug(LoggingLevel.INFO, 'Opportunity updated: ' + oldRecords);
    }
}