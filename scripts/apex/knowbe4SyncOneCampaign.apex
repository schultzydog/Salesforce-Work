// Runs the sync for a single campaign so the mapping can be checked before a full load.
List<KnowBe4SyncService.CampaignRef> all = KnowBe4SyncService.campaignsInScope();
System.debug(LoggingLevel.ERROR, 'KB4_IN_SCOPE=' + all.size());

KnowBe4SyncService.CampaignRef smallest = all[0];
System.debug(LoggingLevel.ERROR,
    'KB4_PICKED campaign=' + smallest.campaignId + ' due=' + smallest.dueDate);

KnowBe4SyncService.SyncResult result =
    KnowBe4SyncService.run(new List<KnowBe4SyncService.CampaignRef>{ smallest });

System.debug(LoggingLevel.ERROR, 'KB4_RESULT ' + result);
System.debug(LoggingLevel.ERROR, 'KB4_UNMATCHED ' + result.unmatchedEmails);
System.debug(LoggingLevel.ERROR, 'KB4_LIMITS dml=' + Limits.getDmlRows()
    + ' cpu=' + Limits.getCpuTime() + ' callouts=' + Limits.getCallouts());
