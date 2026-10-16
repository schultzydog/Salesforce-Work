<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <rules>
        <fullName>Populate Amount %28Converted%29</fullName>
        <active>true</active>
        <formula>ISCHANGED( Amount )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Update Probability for Red Flag</fullName>
        <actions>
            <name>Update_Probability_for_Red_Flag</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <booleanFilter>1 and 2</booleanFilter>
        <criteriaItems>
            <field>Opportunity.Red_Flag__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.StageName</field>
            <operation>equals</operation>
            <value>Draft Renewal Documents,Contract Sent,Negotiations</value>
        </criteriaItems>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Update Sales Type to Renewal</fullName>
        <actions>
            <name>Update_RecordType_to_Renewal</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Update_Sales_Type_to_Renewal</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Update oppty sales type to renewal if there&apos;s a previous oppty</description>
        <formula>ISCHANGED(Previous_Opportunity__c ) &amp;&amp; NOT( ISNULL( Previous_Opportunity__c ) ) &amp;&amp;  ISPICKVAL( RevenueType__c , &apos;Recurring&apos;)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
