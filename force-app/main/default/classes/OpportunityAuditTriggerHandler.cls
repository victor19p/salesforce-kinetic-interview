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
        auditService.createAuditForOpportunity(newRecordsMap, null, 'afterInsert');

        TriggerHandler.clearBypass('OpportunityAuditTriggerHandler');
    }

    public override void afterUpdate() {
        TriggerHandler.bypass('OpportunityAuditTriggerHandler');

        AuditService auditService = new AuditService();
        auditService.createAuditForOpportunity(newRecordsMap, oldRecordsMap, 'afterUpdate');

        TriggerHandler.clearBypass('OpportunityAuditTriggerHandler');
    }

    public override void andFinally() {
        TriggerHandler.clearBypass('OpportunityAuditTriggerHandler');
    }
}


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