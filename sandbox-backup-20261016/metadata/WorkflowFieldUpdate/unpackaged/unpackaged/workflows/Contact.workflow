<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Check_Deliver_Full_Content_Emails</fullName>
        <field>Deliver_Full_Content_Emails__c</field>
        <literalValue>1</literalValue>
        <name>Check Deliver Full Content Emails</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Check_EG_Staff_box</fullName>
        <field>EG_Staff__c</field>
        <literalValue>1</literalValue>
        <name>Check EG Staff box</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Check_Press_User_checkbox</fullName>
        <field>Press_User__c</field>
        <literalValue>1</literalValue>
        <name>Check Press User checkbox</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Check_Refresh_Crypto_Key</fullName>
        <field>Refresh_Crypto_Key__c</field>
        <literalValue>1</literalValue>
        <name>Check Refresh Crypto Key</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Clear_Batch_apex_checkbox</fullName>
        <field>Batch_apex_job_is_running__c</field>
        <literalValue>0</literalValue>
        <name>Clear Batch apex checkbox</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Clear_Crypto_Key</fullName>
        <field>Crypto_Key__c</field>
        <name>Clear Crypto Key</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Null</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Clear_Refresh_Crypto_Key</fullName>
        <field>Refresh_Crypto_Key__c</field>
        <literalValue>0</literalValue>
        <name>Clear Refresh Crypto Key</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Clear_WF_Last_Bounced_Email</fullName>
        <field>Worldflow_Last_Bounced_Email__c</field>
        <name>Clear WF Last Bounced Email</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Null</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Clear_WF_Last_Bounced_Reason</fullName>
        <field>Worldflow_Bounced_Email_Reason__c</field>
        <name>Clear WF Last Bounced Reason</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Null</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Deactivate_Update_First_Name</fullName>
        <field>FirstName</field>
        <formula>&quot;ZZ&quot; + FirstName</formula>
        <name>Deactivate Update First Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Deactivate_Update_Last_Name</fullName>
        <field>LastName</field>
        <formula>&quot;ZZ&quot; + LastName</formula>
        <name>Deactivate Update Last Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Populate_Deliver_Full_Content_Off</fullName>
        <field>Date_Linkbacks_activated__c</field>
        <formula>TODAY()</formula>
        <name>Populate Deliver Full Content Off</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Populate_EG_Update_Name</fullName>
        <field>eg_update_name__c</field>
        <formula>IF(NOT ISBLANK(FirstName), LOWER(FirstName), &apos;&apos;)</formula>
        <name>Populate EG Update Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Populate_Full_Content_Emails_Date_On</fullName>
        <field>Date_Linkbacks_deactivated__c</field>
        <formula>TODAY()</formula>
        <name>Populate Full Content Emails Date On</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Populate_Status</fullName>
        <field>Status__c</field>
        <literalValue>Disabled</literalValue>
        <name>Populate Status</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Uncheck_Aggregator_Access</fullName>
        <field>Subscribed_to_Aggregator_Services__c</field>
        <literalValue>0</literalValue>
        <name>Uncheck Aggregator Access</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Uncheck_Email_Access</fullName>
        <field>Worldflow_Email_Access__c</field>
        <literalValue>0</literalValue>
        <name>Uncheck Email Access</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Uncheck_Portal_Access</fullName>
        <field>Worldflow_Portal_Access__c</field>
        <literalValue>0</literalValue>
        <name>Uncheck Portal Access</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Date_First_Research_Sent</fullName>
        <field>Date_First_Research_Sent__c</field>
        <formula>TODAY()</formula>
        <name>Update Date First Research Sent</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>eg_update_Latest_Disable_Date</fullName>
        <field>eg_update_Latest_Disabled_Date__c</field>
        <formula>NOW()</formula>
        <name>eg update Latest Disable Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>eg_update_Latest_Disable_Date_clear</fullName>
        <field>eg_update_Latest_Disabled_Date__c</field>
        <name>eg update Latest Disable Date clear</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Null</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
</Workflow>
