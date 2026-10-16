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
</Workflow>
