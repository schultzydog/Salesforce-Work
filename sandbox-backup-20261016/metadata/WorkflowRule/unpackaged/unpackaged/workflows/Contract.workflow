<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <rules>
        <fullName>Expire ended Contracts</fullName>
        <active>false</active>
        <criteriaItems>
            <field>Contract.Status</field>
            <operation>equals</operation>
            <value>Executed</value>
        </criteriaItems>
        <description>When End Date = Today, change status to Expired</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
        <workflowTimeTriggers>
            <actions>
                <name>Change_Status_to_Expired</name>
                <type>FieldUpdate</type>
            </actions>
            <offsetFromField>Contract.EndDate</offsetFromField>
            <timeLength>1</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
    </rules>
    <rules>
        <fullName>Update Contract Name</fullName>
        <active>false</active>
        <criteriaItems>
            <field>Contract.OwnerId</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <description>Sets the Contract Name to Match the Opportunity Name</description>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
