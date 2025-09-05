trigger OpportunityAuditTrigger on Opportunity (after insert, after update) {
    new OpportunityAuditTriggerHandler('OpportunityAuditTriggerHandler').setMaxLoopCount(1).run();
}