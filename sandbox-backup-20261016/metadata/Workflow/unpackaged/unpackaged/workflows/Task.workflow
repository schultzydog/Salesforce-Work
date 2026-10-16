<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Email_User_on_Portal_Task_Creation</fullName>
        <description>Email User on Portal Task Creation</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>DefaultWorkflowUser</senderType>
        <template>Portal_Notifications/New_Task_Alert</template>
    </alerts>
    <alerts>
        <fullName>Notify_Account_Owner_of_Trial_Expiration</fullName>
        <description>Notify Account Owner of Trial Expiration</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderAddress>salesops@eurasiagroup.net</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>Public_Templates/Task_Trial_Task_Assignment</template>
    </alerts>
    <fieldUpdates>
        <fullName>Task_field_update</fullName>
        <field>Priority</field>
        <literalValue>Low</literalValue>
        <name>Task field update</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_to_Email</fullName>
        <field>Type</field>
        <literalValue>Email</literalValue>
        <name>Update to Email</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>jpw2__Update_Type_from_Task</fullName>
        <field>jpw2__Activity_Type__c</field>
        <formula>TEXT(Type)</formula>
        <name>Update Type from Task</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <rules>
        <fullName>jpw2__Update %22Type%22 from Task</fullName>
        <actions>
            <name>jpw2__Update_Type_from_Task</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <description>To update custom field Type with task type for reporting purpose</description>
        <formula>! ISNULL(TEXT(Type))</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
