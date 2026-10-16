<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Update_Activity_Type</fullName>
        <field>Activity_Type__c</field>
        <formula>TEXT(Type)</formula>
        <name>Update Activity Type</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>jpw2__Update_Type_from_Event</fullName>
        <field>jpw2__Activity_Type__c</field>
        <formula>TEXT(Type)</formula>
        <name>Update Type from Event</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <rules>
        <fullName>Update Activity Type</fullName>
        <actions>
            <name>Update_Activity_Type</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Event.Type</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>jpw2__Update %22Type%22 from Event</fullName>
        <actions>
            <name>jpw2__Update_Type_from_Event</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <description>To update custom field Type with event type for reporting purpose</description>
        <formula>!ISNULL(TEXT(Type))</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
