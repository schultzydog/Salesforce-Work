public class egTimesheetMetrics_Ctlr {
    private static Date RELEASE_2024_03 = Date.valueOf('2024-03-03');

    @AuraEnabled(cacheable=false)
    public Static MetricsWrapper queryTimecardsByDate(Date d){
        return queryTimecards(null);
    }

    @AuraEnabled(cacheable=false)
    public Static MetricsWrapper queryTimecards(String userid){

        if (userid == null) return new MetricsWrapper();

        Id runningUserId = userid;
        Integer year = Date.today().year();
        Date today = Date.today();
        Date first = today.addDays(-12 * 7);
        if (today.month() == 1) {
            first = Date.newInstance(year - 1, 1, 1);
        }

        List<EG_Time_Card__c> timecards = [
            SELECT Id, Start_Date__c, End_Date__c, OwnerId,
                   (SELECT Id, EG_Project__c, EG_Project_Task__c, Hours_Worked__c, Date__c
                    FROM EG_Time_Entries__r)
            FROM EG_Time_Card__c
            WHERE OwnerId = :runningUserId
            AND Start_Date__c <= :today
            AND Start_Date__c >= :first
            ORDER BY Start_Date__c DESC
        ];

        MetricsWrapper wrapper = new MetricsWrapper();
        wrapper.complianceYear = String.valueOf(year);

        Decimal totalHours = 0;
        Boolean totalCompliance = true;

        wrapper.rows = new List<MetricsRow>();

        for ( EG_Time_Card__c tc : timecards ) {

            MetricsRow row = new MetricsRow();

            row.startDate = tc.Start_Date__c;
            row.start = ((DateTime)tc.Start_Date__c).formatGmt('M/d/YYYY');
            row.isFuture = (tc.Start_Date__c > Date.today());

            Decimal hours = 0;

            for ( EG_Time_Entry__c te : tc.EG_Time_Entries__r ) {
                if(te.EG_Project_Task__c!=null || tc.Start_Date__c < RELEASE_2024_03){
                    hours += te.Hours_Worked__c;
                }
            }

            row.hours = hours.setScale(1);

            Decimal percent = (100 * hours / (40)).setScale(2);

            row.percent = percent;
            row.compliance = (percent >= 100);

            wrapper.rows.add(row);

            totalHours += hours;
            if (hours < 40){
                totalCompliance = false;
            }

        }

        wrapper.totalPercent = (timecards.size()>0) ? (100 * totalHours / (40 * timecards.size())).setScale(2) : 0;
        wrapper.totalCompliance = totalCompliance;

        return wrapper;

    }

    public class MetricsWrapper {

        @AuraEnabled public Date d {get;set;}

        @AuraEnabled public Decimal totalPercent {get;set;}
        @AuraEnabled public Boolean totalCompliance {get;set;}

        @AuraEnabled public String complianceYear {get;set;}

        @AuraEnabled public List<MetricsRow> rows {get;set;}

        public MetricsWrapper() {

        }

    }

    public class MetricsRow{
        @AuraEnabled public String start {get;set;}
        @AuraEnabled public Date startDate {get;set;}
        @AuraEnabled public Boolean isFuture {get;set;}
        @AuraEnabled public Decimal hours {get;set;}
        @AuraEnabled public Decimal percent {get;set;}
        @AuraEnabled public Boolean compliance {get;set;}

        public MetricsRow() {

        }

    }
}