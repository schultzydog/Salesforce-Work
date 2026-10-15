// Measures the campaign-scoped strategy: how many campaigns start on or after the
// cutoff, how many enrollments they carry, and what that costs in callouts + CPU.
//
//   sf apex run --file scripts/apex/knowbe4ScopeProbe.apex --target-org EG-Sandbox

String cutoff = '2025-01-01';

List<Integer> campaignIds = new List<Integer>();
for (Integer page = 1; page <= 10; page++) {
    List<Object> rows = (List<Object>) JSON.deserializeUntyped(
        KnowBe4Client.get('/v1/training/campaigns?page=' + page)
    );
    if (rows.isEmpty()) {
        break;
    }
    for (Object row : rows) {
        Map<String, Object> c = (Map<String, Object>) row;
        if (String.valueOf(c.get('start_date')) >= cutoff) {
            campaignIds.add(Integer.valueOf(c.get('campaign_id')));
        }
    }
}

System.debug(LoggingLevel.ERROR, 'KB4_CAMPAIGNS_IN_SCOPE=' + campaignIds.size());

Integer enrollments = 0;
Integer pagedCampaigns = 0;

for (Integer campaignId : campaignIds) {
    Integer rowCount = ((List<Object>) JSON.deserializeUntyped(
        KnowBe4Client.get('/v1/training/enrollments?campaign_id=' + campaignId + '&per_page=500')
    )).size();

    enrollments += rowCount;
    if (rowCount == 500) {
        pagedCampaigns++;   // would need a second page
    }
}

System.debug(LoggingLevel.ERROR, 'KB4_ENROLLMENTS_IN_SCOPE=' + enrollments);
System.debug(LoggingLevel.ERROR, 'KB4_CAMPAIGNS_NEEDING_PAGING=' + pagedCampaigns);
System.debug(LoggingLevel.ERROR, 'KB4_CALLOUTS_USED=' + Limits.getCallouts());
System.debug(LoggingLevel.ERROR, 'KB4_CPU_MS=' + Limits.getCpuTime());
