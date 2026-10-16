<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Travel_Request_Practice_Group_notification</fullName>
        <description>Travel Request: Practice Group notification</description>
        <protected>false</protected>
        <recipients>
            <field>Practice_Head_Email__c</field>
            <type>email</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Travel_Request_team_lead_notification</template>
    </alerts>
    <alerts>
        <fullName>Travel_request_Approval_notice</fullName>
        <description>Travel request: Approval notice</description>
        <protected>false</protected>
        <recipients>
            <type>creator</type>
        </recipients>
        <recipients>
            <recipient>ubriaco@eurasiagroup.net</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Travel_Request_approval_notification</template>
    </alerts>
    <alerts>
        <fullName>Travel_request_send_notification</fullName>
        <ccEmails>travelrequest@eurasiagroup.net</ccEmails>
        <description>Travel request: send notification</description>
        <protected>false</protected>
        <recipients>
            <type>creator</type>
        </recipients>
        <recipients>
            <recipient>trigo.ne@eurasiagroup.net</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Travel_Request_approver_notification</template>
    </alerts>
</Workflow>
