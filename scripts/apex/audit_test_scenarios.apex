// Simulación de escenarios para consola anónima

// Instancia tu servicio (asume que la clase AuditService existe en tu org)
AuditService service = new AuditService();

// ----------- SETUP: Oportunidades y Leads ------------

// Opportunity en stage válido (debe crear Audit)
Opportunity opp1 = new Opportunity(Name='Opp Válido', StageName='Qualification', CloseDate=Date.today());
insert opp1;

// Opportunity en stage NO válido (no debe crear Audit)
Opportunity opp2 = new Opportunity(Name='Opp No Válido', StageName='Prospecting', CloseDate=Date.today());
insert opp2;

// Lead en status válido (debe crear Audit)
Lead lead1 = new Lead(LastName='Lead Válido', Company='Empresa', Status='Working - Contacted');
insert lead1;

// Lead en status NO válido (no debe crear Audit)
Lead lead2 = new Lead(LastName='Lead No Válido', Company='Empresa', Status='Qualified');
insert lead2;

// ----------- Simula cambios de etapa/status ------------

// Cambia opp1 a otro stage válido
opp1.StageName = 'Closed Won';
update opp1;

// Cambia opp2 a stage válido (debe crear Audit)
opp2.StageName = 'Closed Lost';
update opp2;

// Cambia lead1 a otro status válido
lead1.Status = 'Closed - Not Converted';
update lead1;

// Cambia lead2 a status válido (debe crear Audit si existe config activa)
lead2.Status = 'Working - Contacted';
update lead2;

// Cambia opp1 a mismo stage (no debe crear Audit)
opp1.StageName = 'Closed Won';
update opp1;

// --------- Consulta los audits generados ---------
List<Audit__c> audits = [SELECT Id, Parent_Type__c, Audity_Type__c, Comments__c, Expected_Audit_Date__c FROM Audit__c ORDER BY CreatedDate DESC];
System.debug('Audits creados: ' + audits.size());