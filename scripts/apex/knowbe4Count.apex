// Sizes the KnowBe4 enrollment backlog before we design the sync around it.
//
//   sf apex run --file scripts/apex/knowbe4Count.apex --target-org EG-Sandbox

Datetime cutoff = Datetime.newInstanceGmt(2025, 1, 1, 0, 0, 0);

KnowBe4Client.EnrollmentSummary summary = KnowBe4Client.summarizeEnrollments(20, cutoff);

System.debug(LoggingLevel.ERROR, 'KB4_TOTAL=' + summary.totalRecords);
System.debug(LoggingLevel.ERROR, 'KB4_IN_SCOPE=' + summary.recordsInScope);
System.debug(LoggingLevel.ERROR, 'KB4_PAGES=' + summary.pagesFetched);
System.debug(LoggingLevel.ERROR, 'KB4_HIT_CAP=' + summary.hitPageCap);
System.debug(LoggingLevel.ERROR, 'KB4_OLDEST=' + summary.oldest);
System.debug(LoggingLevel.ERROR, 'KB4_NEWEST=' + summary.newest);
