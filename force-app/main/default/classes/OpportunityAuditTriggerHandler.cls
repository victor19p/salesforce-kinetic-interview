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
        // Implement logic for after insert
        System.debug(LoggingLevel.INFO, '=================> Opportunity inserted: ' + newRecords);
        TriggerHandler.bypass('OpportunityAuditTriggerHandler');
        // ! Test Loop Recursive on trigger
        // Opportunity opp = new Opportunity(
        //     Name = 'Test Audit Opportunity',
        //     StageName = 'Prospecting',
        //     CloseDate = Date.today().addDays(30)
        // );
        // insert opp;
        // System.debug('Oportunidad creada inside: ' + opp.Id);

        // // Actualizar la oportunidad (por ejemplo, cambiar StageName)
        // opp.StageName = 'Closed Won';
        // update opp;
        // System.debug('Oportunidad actualizada inside: ' + opp.Id);
        TriggerHandler.clearBypass('OpportunityAuditTriggerHandler');
    }

    public override void afterUpdate() {
        // Implement logic for after update
        System.debug(LoggingLevel.INFO, '=================> Opportunity updated: ' + oldRecords);
        TriggerHandler.bypass('OpportunityAuditTriggerHandler');


        TriggerHandler.clearBypass('OpportunityAuditTriggerHandler');
    }

    public override void andFinally() {
        // Implement logic for andFinally
        System.debug(LoggingLevel.INFO, '=================> Opportunity andFinally executed');
        TriggerHandler.clearBypass('OpportunityAuditTriggerHandler');
    }
}