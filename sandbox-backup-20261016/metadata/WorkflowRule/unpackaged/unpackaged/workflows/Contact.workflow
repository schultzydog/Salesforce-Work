<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <rules>
        <fullName>Check Deliver Full Content when no Portal Access</fullName>
        <actions>
            <name>Check_Deliver_Full_Content_Emails</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Contact.Worldflow_Portal_Access__c</field>
            <operation>equals</operation>
            <value>False</value>
        </criteriaItems>
        <criteriaItems>
            <field>Contact.Press_User__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Check if Disabled Aggregator Subscriber</fullName>
        <actions>
            <name>Notify_on_Aggregator_Subscriber_Disablement</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Contact.Selected_Aggregators__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <criteriaItems>
            <field>Contact.Status__c</field>
            <operation>equals</operation>
            <value>Disabled</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Clear Batch apex checkbox</fullName>
        <actions>
            <name>Clear_Batch_apex_checkbox</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Contact.Batch_apex_job_is_running__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Clear WF Bounced Fields</fullName>
        <actions>
            <name>Clear_WF_Last_Bounced_Email</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Clear_WF_Last_Bounced_Reason</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>Worldflow_Last_Email_Sent__c &gt;  Worldflow_Last_Bounced_Email__c</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Disable if contact left the firm</fullName>
        <actions>
            <name>Uncheck_Aggregator_Access</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Uncheck_Email_Access</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Uncheck_Portal_Access</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Contact.Contact_Type__c</field>
            <operation>equals</operation>
            <value>No Longer With Firm</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>New EG Employee</fullName>
        <actions>
            <name>Notify_on_EG_employee_insert</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Contact.AccountName</field>
            <operation>equals</operation>
            <value>Eurasia Group</value>
        </criteriaItems>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Notify Account Owner of Contact by Lead Conversion</fullName>
        <actions>
            <name>Notify_Account_Owner_of_New_Contact</name>
            <type>Alert</type>
        </actions>
        <actions>
            <name>Populate_EG_Update_Name</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Populate_Status</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Contact.LeadSource</field>
            <operation>equals</operation>
            <value>Conference Call</value>
        </criteriaItems>
        <description>Notify Account owner when new contact is created due to webex conference call lead conversion</description>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Notify Account Owner when Contact Email Opt Out</fullName>
        <actions>
            <name>Notify_Account_Owner_of_Contact_Email_Opt_Out</name>
            <type>Alert</type>
        </actions>
        <actions>
            <name>Uncheck_Email_Access</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Contact.Worldflow_Email_Opt_Out_Date__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <criteriaItems>
            <field>Contact.Worldflow_Email_Access__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Populate Full Content Emails Date Off</fullName>
        <actions>
            <name>Populate_Deliver_Full_Content_Off</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Contact.Deliver_Full_Content_Emails__c</field>
            <operation>equals</operation>
            <value>False</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Populate Full Content Emails Date On</fullName>
        <actions>
            <name>Populate_Full_Content_Emails_Date_On</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Contact.Deliver_Full_Content_Emails__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Refresh Crypto Key</fullName>
        <actions>
            <name>Clear_Crypto_Key</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Clear_Refresh_Crypto_Key</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Contact.Refresh_Crypto_Key__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
        <workflowTimeTriggers>
            <actions>
                <name>Check_Refresh_Crypto_Key</name>
                <type>FieldUpdate</type>
            </actions>
            <timeLength>20</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
    </rules>
    <rules>
        <fullName>eg update Latest Disable Date</fullName>
        <actions>
            <name>eg_update_Latest_Disable_Date</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>(ISCHANGED( eg_update_Counter__c )  &amp;&amp;  eg_update_Counter__c =0 &amp;&amp; ISPICKVAL(Status__c, &apos;Enabled&apos;)) || (ISCHANGED( Status__c ) &amp;&amp;  NOT(ISPICKVAL(Status__c, &apos;Enabled&apos;)) &amp;&amp;  eg_update_Counter__c &gt; 0)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>eg update Latest Disable Date clear</fullName>
        <actions>
            <name>eg_update_Latest_Disable_Date_clear</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>(ISCHANGED( eg_update_Counter__c )  &amp;&amp;  eg_update_Counter__c &gt; 0 &amp;&amp; ISPICKVAL(Status__c, &apos;Enabled&apos;)) || (ISCHANGED( Status__c ) &amp;&amp;  ISPICKVAL(Status__c, &apos;Enabled&apos;) &amp;&amp;  eg_update_Counter__c &gt; 0)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
