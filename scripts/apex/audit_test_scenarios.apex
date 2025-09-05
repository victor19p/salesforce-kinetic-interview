// ----------- SETUP: Oportunidades con cuentas existentes ------------

// Obtén 2 cuentas aleatorias
List<Account> accounts = [SELECT Id, Name, OwnerId FROM Account WHERE IsDeleted = false LIMIT 2];

for (Account acc : accounts) {
    // Opportunity en stage válido (debe crear Audit)
    Opportunity opp1 = new Opportunity(
        Name = 'Opp type1 ' + acc.Name,
        StageName = 'Qualification',
        CloseDate = Date.today(),
        AccountId = acc.Id,
        OwnerId = acc.OwnerId
    );
    insert opp1;

    // Opportunity en stage NO válido (no debe crear Audit)
    Opportunity opp2 = new Opportunity(
        Name = 'Opp type2 ' + acc.Name,
        StageName = 'Prospecting',
        CloseDate = Date.today(),
        AccountId = acc.Id,
        OwnerId = acc.OwnerId
    );
    insert opp2;

    // Cambia opp1 a otro stage válido
    opp1.StageName = 'Closed Won';
    update opp1;

    // Cambia opp2 a stage válido (debe crear Audit)
    opp2.StageName = 'Closed Lost';
    update opp2;

    // Cambia opp1 a mismo stage (no debe crear Audit)
    opp1.StageName = 'Closed Won';
    update opp1;
}

// ----------- SETUP: Leads ------------

Lead lead1 = new Lead(LastName='Lead type1', Company='Empresa', Status='Working - Contacted');
insert lead1;

Lead lead2 = new Lead(LastName='Lead type2', Company='Empresa', Status='Qualified');
insert lead2;

// Cambia lead1 a otro status válido
lead1.Status = 'Closed - Not Converted';
update lead1;

// Cambia lead2 a status válido (debe crear Audit si existe config activa)
lead2.Status = 'Working - Contacted';
update lead2;

// --------- Consulta los audits generados ---------
List<Audit__c> audits = [SELECT Id, Parent_Type__c, Audity_Type__c, Comments__c, Expected_Audit_Date__c FROM Audit__c ORDER BY CreatedDate DESC];
System.debug('Audits creados: ' + audits.size());