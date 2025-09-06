// INSERT Opportunity
Opportunity opp = new Opportunity(
    Name = 'Test Audit Opportunity',
    StageName = 'Qualification',
    CloseDate = Date.today().addDays(30)
);
insert opp;
System.debug('Inserted Opportunity: ' + opp.Id);

// UPDATE Opportunity (change StageName to trigger audit)
opp.StageName = 'Closed Won';
update opp;
System.debug('Updated Opportunity StageName: ' + opp.StageName);