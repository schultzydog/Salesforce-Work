// Live smoke test: sync the first in-scope KnowBe4 campaign only.
//
//   sf apex run --file scripts/apex/runKnowBe4OneCampaign.apex --target-org EG-Sandbox

List<KnowBe4SyncService.CampaignScope> campaigns = KnowBe4SyncService.loadInScopeCampaigns();
System.debug(LoggingLevel.ERROR, 'KB4_IN_SCOPE_CAMPAIGNS=' + campaigns.size());

if (campaigns.isEmpty()) {
    System.debug(LoggingLevel.ERROR, 'KB4_NO_CAMPAIGNS');
} else {
    KnowBe4SyncService.CampaignScope first = campaigns[0];
    System.debug(LoggingLevel.ERROR, 'KB4_CHOSEN_CAMPAIGN=' + first.campaignId + ' due=' + first.dueDate);

    KnowBe4SyncService.SyncResult outcome = KnowBe4SyncService.syncCampaigns(
        new List<KnowBe4SyncService.CampaignScope>{ first }
    );
    System.debug(LoggingLevel.ERROR, 'KB4_ENROLLMENTS_SEEN=' + outcome.enrollmentsSeen);
    System.debug(LoggingLevel.ERROR, 'KB4_RESULTS_WRITTEN=' + outcome.resultsUpserted);
    System.debug(LoggingLevel.ERROR, 'KB4_UNMATCHED=' + outcome.unmatchedUsers);
    System.debug(LoggingLevel.ERROR, 'KB4_UNMATCHED_EMAILS=' + outcome.unmatchedEmails);
}
