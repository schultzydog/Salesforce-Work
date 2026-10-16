<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Notify_lead_owner_of_company_referral_lead</fullName>
        <description>Notify lead owner of company sign up lead</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>DefaultWorkflowUser</senderType>
        <template>unfiled$public/Lead_Notify_on_company_sign_up</template>
    </alerts>
    <fieldUpdates>
        <fullName>Lead_Record_Type</fullName>
        <field>RecordTypeId</field>
        <lookupValue>Standard</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>Lead Record Type</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Lead_Source</fullName>
        <field>LeadSource</field>
        <literalValue>Web</literalValue>
        <name>Lead Source</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>jpw2__Update_Read_Date</fullName>
        <field>jpw2__Read_Date_Current_owner__c</field>
        <formula>IF( jpw2__Unread_By_Current_Owner__c = TRUE, null, now())</formula>
        <name>Update Read Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <rules>
        <fullName>New Lead not Modified after 24 hours</fullName>
        <active>false</active>
        <criteriaItems>
            <field>Lead.Status</field>
            <operation>equals</operation>
            <value>New</value>
        </criteriaItems>
        <description>Workflow to create a task when a new lead is not touched after 24 hours</description>
        <triggerType>onCreateOnly</triggerType>
        <workflowTimeTriggers>
            <offsetFromField>Lead.Last_Modified_Date_Time__c</offsetFromField>
            <timeLength>24</timeLength>
            <workflowTimeTriggerUnit>Hours</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
    </rules>
    <rules>
        <fullName>Notify Lead Owner on Company Sign Up leads</fullName>
        <actions>
            <name>Notify_lead_owner_of_company_referral_lead</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Lead.LeadSource</field>
            <operation>equals</operation>
            <value>Company Sign Up Form</value>
        </criteriaItems>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>jpw2__Update Read Date</fullName>
        <actions>
            <name>jpw2__Update_Read_Date</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <formula>ISCHANGED( jpw2__Unread_By_Current_Owner__c)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
