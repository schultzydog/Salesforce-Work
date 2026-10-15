Savepoint sp = Database.setSavepoint();
try {
    Integer cards = [SELECT COUNT() FROM EG_Time_Card__c];
    Integer entries = [SELECT COUNT() FROM EG_Time_Entry__c];
    System.debug('PROBE cards=' + cards + ' entries=' + entries);

    egTimesheet_Ctlr.TimesheetWrapper sheet =
        egTimesheet_Ctlr.getTimesheetForDateApex(Date.today(), UserInfo.getUserId(), false);
    System.debug('PROBE timesheet card=' + sheet.timeCardId
        + ' start=' + sheet.startDateString
        + ' rows=' + (sheet.rows == null ? 0 : sheet.rows.size()));

    egTimesheetMetrics_Ctlr.MetricsWrapper metrics =
        egTimesheetMetrics_Ctlr.queryTimecards(UserInfo.getUserId());
    System.debug('PROBE metrics year=' + metrics.complianceYear
        + ' weeks=' + (metrics.rows == null ? 0 : metrics.rows.size()));
} finally {
    Database.rollback(sp);
}
