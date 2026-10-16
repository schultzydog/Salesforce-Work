<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>GLOMA_weekend_email</fullName>
        <description>GLOMA weekend email</description>
        <protected>false</protected>
        <recipients>
            <field>Email</field>
            <type>email</type>
        </recipients>
        <senderAddress>gmateam@eurasiagroup.net</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>unfiled$public/GLOMA_weekend_email</template>
    </alerts>
    <alerts>
        <fullName>Notify_Account_Owner_of_Contact_Email_Disablement</fullName>
        <description>Email Hard Bounce - Notify Account Owner of Contact Email Disablement</description>
        <protected>false</protected>
        <recipients>
            <type>accountOwner</type>
        </recipients>
        <senderAddress>salesops@eurasiagroup.net</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>unfiled$public/Notify_of_Contact_Email_Access_Disablement</template>
    </alerts>
    <alerts>
        <fullName>Notify_Account_Owner_of_Contact_Email_Opt_Out</fullName>
        <description>Notify Account Owner of Contact Email Opt Out</description>
        <protected>false</protected>
        <recipients>
            <type>accountOwner</type>
        </recipients>
        <senderAddress>salesops@eurasiagroup.net</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>unfiled$public/Worldflow_Email_Opt_Out</template>
    </alerts>
    <alerts>
        <fullName>Notify_Account_Owner_of_New_Contact</fullName>
        <description>Notify Account Owner of New Contact</description>
        <protected>false</protected>
        <recipients>
            <type>accountOwner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/New_Contact_from_Lead_conversion</template>
    </alerts>
    <alerts>
        <fullName>Notify_Contacts_for_EG_In_Media</fullName>
        <description>Notify Contacts for EG In Media</description>
        <protected>false</protected>
        <recipients>
            <field>Email</field>
            <type>email</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/EG_in_the_Media</template>
    </alerts>
    <alerts>
        <fullName>Notify_on_Aggregator_Subscriber_Disablement</fullName>
        <description>Notify on Aggregator Subscriber Disablement</description>
        <protected>false</protected>
        <recipients>
            <recipient>albuquerque@eurasiagroup.net</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>detmer@eurasiagroup.net</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>talmeida@eurasiagroup.net</recipient>
            <type>user</type>
        </recipients>
        <senderType>DefaultWorkflowUser</senderType>
        <template>unfiled$public/Aggregator_Subscriber_Disabled</template>
    </alerts>
    <alerts>
        <fullName>Notify_on_EG_employee_insert</fullName>
        <description>Notify on EG employee insert</description>
        <protected>false</protected>
        <recipients>
            <recipient>wehrmann@eurasiagroup.net</recipient>
            <type>user</type>
        </recipients>
        <senderAddress>salesops@eurasiagroup.net</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>unfiled$public/Notify_On_EG_ee_insert</template>
    </alerts>
    <alerts>
        <fullName>Notify_on_New_Contact_created_by_Rippling_integration</fullName>
        <description>Notify on New Contact created by Rippling integration</description>
        <protected>false</protected>
        <recipients>
            <recipient>schultz@eurasiagroup.net</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/New_Contact_created_by_Rippling_integration</template>
    </alerts>
    <alerts>
        <fullName>Risk_Dashboard_note_to_Two_Sigma</fullName>
        <description>Risk Dashboard - note to Two Sigma</description>
        <protected>false</protected>
        <recipients>
            <field>Email</field>
            <type>email</type>
        </recipients>
        <senderAddress>consonery@eurasiagroup.net</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>unfiled$public/RIsk_Dashboard_Two_Sigma</template>
    </alerts>
    <alerts>
        <fullName>Risk_Dashboard_note_to_not_Two_Sigma</fullName>
        <ccEmails>tavares@eurasiagroup.net</ccEmails>
        <ccEmails>trigo@eurasiagroup.net</ccEmails>
        <description>Risk Dashboard - note to not Two Sigma</description>
        <protected>false</protected>
        <recipients>
            <field>Email</field>
            <type>email</type>
        </recipients>
        <senderAddress>nickolova@eurasiagroup.net</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>unfiled$public/Risk_Dashboard_NOT_Two_Sigma</template>
    </alerts>
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
