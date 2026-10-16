<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Contract_Adjustment_has_been_approved</fullName>
        <ccEmails>Spratt@eurasiagroup.net</ccEmails>
        <description>Contract Adjustment has been approved</description>
        <protected>false</protected>
        <recipients>
            <type>creator</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Contract_Adjustment_has_been_approved</template>
    </alerts>
    <alerts>
        <fullName>Contract_Adjustment_has_been_rejected</fullName>
        <description>Contract Adjustment has been rejected</description>
        <protected>false</protected>
        <recipients>
            <type>creator</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Contract_Adjustment_has_been_rejected</template>
    </alerts>
    <alerts>
        <fullName>Notify_Finance_of_Contract_Adjustment</fullName>
        <description>Notify Finance of Contract Adjustment</description>
        <protected>false</protected>
        <recipients>
            <recipient>pali@eurasiagroup.net</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/New_Contract_Adjustment_For_Approval</template>
    </alerts>
</Workflow>
