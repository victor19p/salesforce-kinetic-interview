trigger OpportunityAuditTrigger on Opportunity (after insert, after update) {
    new OpportunityAuditTriggerHandler('OpportunityAuditTriggerHandler').setMaxLoopCount(3).run();
}