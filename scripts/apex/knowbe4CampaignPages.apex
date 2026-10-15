// The campaigns endpoint returned only 10 rows despite per_page=500, while
// enrollments run to 2026. Checking whether it simply paginates 10 at a time.
//
//   sf apex run --file scripts/apex/knowbe4CampaignPages.apex --target-org EG-Sandbox

Integer total = 0;
String latestStart;
Integer latestId;

for (Integer page = 1; page <= 15; page++) {
    List<Object> rows = (List<Object>) JSON.deserializeUntyped(
        KnowBe4Client.get('/v1/training/campaigns?page=' + page + '&per_page=500')
    );

    System.debug(LoggingLevel.ERROR, 'KB4_PAGE_' + page + '_SIZE=' + rows.size());
    total += rows.size();

    for (Object row : rows) {
        Map<String, Object> c = (Map<String, Object>) row;
        String startDate = String.valueOf(c.get('start_date'));
        if (latestStart == null || startDate > latestStart) {
            latestStart = startDate;
            latestId = Integer.valueOf(c.get('campaign_id'));
        }
    }

    if (rows.isEmpty()) {
        break;
    }
}

System.debug(LoggingLevel.ERROR, 'KB4_CAMPAIGNS_TOTAL=' + total);
System.debug(LoggingLevel.ERROR, 'KB4_LATEST=' + latestId + ' starting ' + latestStart);
