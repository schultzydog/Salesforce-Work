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
    <rules>
        <fullName>Notify Analyst on Appearance</fullName>
        <actions>
            <name>Notifty_Analyst_on_Appearance</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <booleanFilter>1 AND 2</booleanFilter>
        <criteriaItems>
            <field>Analyst_Appearance__c.AnalystUser__c</field>
            <operation>notContain</operation>
            <value>bremmer</value>
        </criteriaItems>
        <criteriaItems>
            <field>Analyst_Appearance__c.Author__c</field>
            <operation>notEqual</operation>
            <value>True</value>
        </criteriaItems>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
