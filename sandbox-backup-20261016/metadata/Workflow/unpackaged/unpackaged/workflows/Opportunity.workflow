<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>My_Trials_Tracker_Weekly</fullName>
        <description>My Trials Tracker</description>
        <protected>false</protected>
        <recipients>
            <recipient>Account Coordinator</recipient>
            <type>opportunityTeam</type>
        </recipients>
        <recipients>
            <recipient>Co-Relationship Manager</recipient>
            <type>opportunityTeam</type>
        </recipients>
        <recipients>
            <recipient>Opportunity Owner</recipient>
            <type>opportunityTeam</type>
        </recipients>
        <recipients>
            <recipient>Primary Relationship Manager</recipient>
            <type>opportunityTeam</type>
        </recipients>
        <recipients>
            <recipient>Secondary Relationship Manager</recipient>
            <type>opportunityTeam</type>
        </recipients>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderAddress>salesops@eurasiagroup.net</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>unfiled$public/My_Trials_Tracker_Weekly</template>
    </alerts>
    <alerts>
        <fullName>Notify_Finance_of_Lost_Revenue_Opportunities</fullName>
        <ccEmails>accountsreceivable@eurasiagroup.net</ccEmails>
        <description>Notify Finance of Lost Revenue Opportunities</description>
        <protected>false</protected>
        <recipients>
            <type>accountOwner</type>
        </recipients>
        <senderType>DefaultWorkflowUser</senderType>
        <template>unfiled$public/Finance_Provisional_Loss</template>
    </alerts>
    <alerts>
        <fullName>Notify_On_Opportunity_Rejected_Approval</fullName>
        <description>Notify On Opportunity Rejected Approval</description>
        <protected>false</protected>
        <recipients>
            <recipient>oliveira@eurasiagroup.net</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Opportunity_Opportunity_has_not_been_approved</template>
    </alerts>
    <alerts>
        <fullName>Notify_On_Opportunity_Rejected_Approval_Corporates</fullName>
        <description>Notify On Opportunity Rejected Approval - Corporates</description>
        <protected>false</protected>
        <recipients>
            <recipient>dean@eurasiagroup.net</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>oliveira@eurasiagroup.net</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>shepherd@eurasiagroup.net</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Opportunity_Opportunity_has_not_been_approved</template>
    </alerts>
    <alerts>
        <fullName>Notify_On_Opportunity_Rejected_Approval_Gloma</fullName>
        <description>Notify On Opportunity Rejected Approval - Gloma</description>
        <protected>false</protected>
        <recipients>
            <recipient>gangji@eurasiagroup.net</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>oliveira@eurasiagroup.net</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Opportunity_Opportunity_has_not_been_approved</template>
    </alerts>
    <alerts>
        <fullName>Notify_Owner_of_Approved_Opportunity</fullName>
        <description>Notify Owner of Approved Opportunity</description>
        <protected>false</protected>
        <recipients>
            <type>accountOwner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Opportunity_has_been_approved</template>
    </alerts>
    <alerts>
        <fullName>Notify_on_Gloma_Opportunity_Win_New_Sale_Oliver</fullName>
        <description>Notify on Gloma Opportunity Win - New Sale (Oliver)</description>
        <protected>false</protected>
        <recipients>
            <recipient>ganguly@eurasiagroup.net</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>oliveira@eurasiagroup.net</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Opportunity_Won_New_Sales_Gloma_Opportunity</template>
    </alerts>
    <alerts>
        <fullName>Notify_on_Opportunity_Win</fullName>
        <description>Notify on Opportunity Win</description>
        <protected>false</protected>
        <recipients>
            <recipient>oliveira@eurasiagroup.net</recipient>
            <type>user</type>
        </recipients>
        <recipients>
            <recipient>spratt@eurasiagroup.net</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Opportunity_Non_Gloma_Won_Opportunity_For_Approval</template>
    </alerts>
    <alerts>
        <fullName>Reminder_Trial_Close_to_Expiration</fullName>
        <ccEmails>gangji@eurasiagroup.net</ccEmails>
        <ccEmails>salesops@eurasiagroup.net</ccEmails>
        <description>Reminder: Trial Close to Expiration Gloma</description>
        <protected>false</protected>
        <recipients>
            <type>accountOwner</type>
        </recipients>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderAddress>salesops@eurasiagroup.net</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>unfiled$public/Reminder_Trial_Close_to_Expiration</template>
    </alerts>
    <alerts>
        <fullName>Reminder_Trial_Close_to_Expiration_Corps</fullName>
        <ccEmails>salesops@eurasiagroup.net</ccEmails>
        <description>Reminder: Trial Close to Expiration Corps</description>
        <protected>false</protected>
        <recipients>
            <type>accountOwner</type>
        </recipients>
        <recipients>
            <recipient>Co-Relationship Manager</recipient>
            <type>accountTeam</type>
        </recipients>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderAddress>salesops@eurasiagroup.net</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>unfiled$public/Reminder_Trial_Close_to_Expiration</template>
    </alerts>
    <alerts>
        <fullName>Renewal_Opportunity_reminder</fullName>
        <ccEmails>salesops@eurasiagroup.net</ccEmails>
        <description>Renewal Opportunity reminder</description>
        <protected>false</protected>
        <recipients>
            <type>accountOwner</type>
        </recipients>
        <recipients>
            <recipient>Co-Relationship Manager</recipient>
            <type>accountTeam</type>
        </recipients>
        <recipients>
            <recipient>Sales_Ops</recipient>
            <type>group</type>
        </recipients>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderAddress>salesops@eurasiagroup.net</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>unfiled$public/Opportunity_Pending_Renewal</template>
    </alerts>
    <fieldUpdates>
        <fullName>Approval_Status_Approved</fullName>
        <field>Approval_Status__c</field>
        <literalValue>Approved</literalValue>
        <name>Approval Status - Approved</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Approval_Status_Pending_Business</fullName>
        <field>Approval_Status__c</field>
        <literalValue>Pending Business Approval</literalValue>
        <name>Approval Status - Pending Business</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Approval_Status_Pending_Finance</fullName>
        <field>Approval_Status__c</field>
        <literalValue>Pending Finance Approval</literalValue>
        <name>Approval Status - Pending Finance</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Approval_Status_Recalled</fullName>
        <field>Approval_Status__c</field>
        <literalValue>Recalled</literalValue>
        <name>Approval Status - Recalled</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Approval_Status_Rejected</fullName>
        <field>Approval_Status__c</field>
        <literalValue>Rejected</literalValue>
        <name>Approval Status - Rejected</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Contract_Status_Draft</fullName>
        <field>Contract_Status__c</field>
        <literalValue>Draft</literalValue>
        <name>Contract Status - Draft</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Contract_Status_Executed</fullName>
        <field>Contract_Status__c</field>
        <literalValue>Executed</literalValue>
        <name>Contract Status - Executed</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Contract_Status_Rejected</fullName>
        <field>Contract_Status__c</field>
        <literalValue>Rejected</literalValue>
        <name>Contract Status - Rejected</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Contract_Status_Submitted</fullName>
        <field>Contract_Status__c</field>
        <literalValue>Submitted</literalValue>
        <name>Contract Status - Submitted</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>UpdateAutoCreateRenwal</fullName>
        <description>Updates AutoCreateRenewal Checkbox on Opportunity which will trigger the AutoCreateRenewalOpportunity Process</description>
        <field>AutoCreateRenewal__c</field>
        <literalValue>1</literalValue>
        <name>UpdateAutoCreateRenwal</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Opportunity</fullName>
        <description>Update the AutoCreateRenewalField this will then trigger Process Builder to execute AutoCreateRenewalOpportunity</description>
        <field>AutoCreateRenewal__c</field>
        <literalValue>1</literalValue>
        <name>Update Opportunity</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Probability_for_Red_Flag</fullName>
        <field>Probability</field>
        <formula>1 / 10</formula>
        <name>Update Probability for Red Flag</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_RecordType_to_Renewal</fullName>
        <field>RecordTypeId</field>
        <lookupValue>Renewal</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>Update RecordType to Renewal</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Sales_Type_to_Downsell</fullName>
        <field>Type</field>
        <literalValue>Downsell</literalValue>
        <name>Update Sales Type to Downsell</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Sales_Type_to_Renewal</fullName>
        <field>Type</field>
        <literalValue>Renewal</literalValue>
        <name>Update Sales Type to Renewal</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Sales_Type_to_Upsell</fullName>
        <field>Type</field>
        <literalValue>Upsell</literalValue>
        <name>Update Sales Type to Upsell</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <outboundMessages>
        <fullName>Zapier_create_MSA_zap</fullName>
        <apiVersion>64.0</apiVersion>
        <description>sends message to zapier webhook for MSA creation</description>
        <endpointUrl>https://hooks.zapier.com/hooks/catch/19404020/uyz8i8a/</endpointUrl>
        <fields>Id</fields>
        <includeSessionId>false</includeSessionId>
        <integrationUser>schultz@eurasiagroup.net</integrationUser>
        <name>Zapier create MSA zap</name>
        <protected>false</protected>
        <useDeadLetterQueue>false</useDeadLetterQueue>
    </outboundMessages>
    <outboundMessages>
        <fullName>Zapier_create_SOW_zap</fullName>
        <apiVersion>63.0</apiVersion>
        <description>sends message to zapier webhook for SOW creation</description>
        <endpointUrl>https://hooks.zapier.com/hooks/catch/19404020/uyzm6a6/</endpointUrl>
        <fields>Id</fields>
        <includeSessionId>false</includeSessionId>
        <integrationUser>schultz@eurasiagroup.net</integrationUser>
        <name>Zapier create SOW zap</name>
        <protected>false</protected>
        <useDeadLetterQueue>false</useDeadLetterQueue>
    </outboundMessages>
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
