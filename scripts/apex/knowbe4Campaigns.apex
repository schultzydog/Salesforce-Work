// Probes the training campaigns endpoint to see whether the daily sync can be
// scoped to active campaigns instead of scanning every enrollment.
//
//   sf apex run --file scripts/apex/knowbe4Campaigns.apex --target-org EG-Sandbox

String body = KnowBe4Client.get('/v1/training/campaigns');

System.debug(LoggingLevel.ERROR, 'KB4_CAMPAIGN_COUNT=' +
    ((List<Object>) JSON.deserializeUntyped(body)).size());
System.debug(LoggingLevel.ERROR, 'KB4_CAMPAIGNS_START');
System.debug(LoggingLevel.ERROR, body.left(8000));
System.debug(LoggingLevel.ERROR, 'KB4_CAMPAIGNS_END');
