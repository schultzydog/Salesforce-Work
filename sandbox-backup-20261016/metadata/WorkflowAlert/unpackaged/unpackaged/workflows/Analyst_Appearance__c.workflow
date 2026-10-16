<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Notifty_Analyst_on_Appearance</fullName>
        <description>Notifty Analyst on Appearance</description>
        <protected>false</protected>
        <recipients>
            <field>AnalystUser__c</field>
            <type>userLookup</type>
        </recipients>
        <senderAddress>communications@eurasiagroup.net</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>unfiled$public/Notify_Analyst_on_Appearance</template>
    </alerts>
</Workflow>
