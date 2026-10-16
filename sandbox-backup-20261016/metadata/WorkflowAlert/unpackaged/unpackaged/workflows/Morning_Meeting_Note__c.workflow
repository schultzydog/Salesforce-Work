<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Morning_Meeting_Note_Submission</fullName>
        <ccEmails>editorialcommittee@eurasiagroup.net</ccEmails>
        <description>Morning Meeting Note Submission</description>
        <protected>false</protected>
        <recipients>
            <field>Morning_Meeting_Email__c</field>
            <type>email</type>
        </recipients>
        <recipients>
            <field>Submitted_by_Email__c</field>
            <type>email</type>
        </recipients>
        <senderAddress>morningmeeting@eurasiagroup.net</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>unfiled$public/Morning_Meeting_Note_Submission_notice</template>
    </alerts>
</Workflow>
