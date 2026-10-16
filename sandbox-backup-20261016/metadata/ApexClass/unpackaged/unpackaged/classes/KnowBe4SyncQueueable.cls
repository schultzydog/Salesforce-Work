/**
 * Daily KnowBe4 pull. First invocation loads in-scope campaigns, then each job
 * processes CAMPAIGNS_PER_JOB campaigns and chains the remainder so CPU and
 * callout limits stay inside one transaction.
 */
public with sharing class KnowBe4SyncQueueable implements Queueable, Database.AllowsCallouts {

    private final List<KnowBe4SyncService.CampaignScope> remainingCampaigns;

    public KnowBe4SyncQueueable() {
        this(null);
    }

    public KnowBe4SyncQueueable(List<KnowBe4SyncService.CampaignScope> remainingCampaigns) {
        this.remainingCampaigns = remainingCampaigns;
    }

    public void execute(QueueableContext context) {
        List<KnowBe4SyncService.CampaignScope> campaigns = remainingCampaigns;
        if (campaigns == null) {
            campaigns = KnowBe4SyncService.loadInScopeCampaigns();
        }
        if (campaigns.isEmpty()) {
            return;
        }

        List<KnowBe4SyncService.CampaignScope> currentChunk = new List<KnowBe4SyncService.CampaignScope>();
        List<KnowBe4SyncService.CampaignScope> leftover = new List<KnowBe4SyncService.CampaignScope>();
        Integer chunkSize = KnowBe4SyncService.CAMPAIGNS_PER_JOB;
        for (Integer i = 0; i < campaigns.size(); i++) {
            if (i < chunkSize) {
                currentChunk.add(campaigns[i]);
            } else {
                leftover.add(campaigns[i]);
            }
        }

        KnowBe4SyncService.SyncResult outcome = KnowBe4SyncService.syncCampaigns(currentChunk);
        System.debug(
            LoggingLevel.INFO,
            'KnowBe4 sync chunk: campaigns=' + currentChunk.size()
                + ' enrollments=' + outcome.enrollmentsSeen
                + ' resultsWritten=' + outcome.resultsUpserted
                + ' unmatchedUsers=' + outcome.unmatchedUsers
        );
        if (!outcome.unmatchedEmails.isEmpty()) {
            System.debug(LoggingLevel.WARN, 'KnowBe4 unmatched emails: ' + outcome.unmatchedEmails);
        }

        if (!leftover.isEmpty() && !Test.isRunningTest()) {
            System.enqueueJob(new KnowBe4SyncQueueable(leftover));
        }
    }
}