<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Contract_has_been_approved1</fullName>
        <description>Contract has been approved</description>
        <protected>false</protected>
        <recipients>
            <type>creator</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Contract_Contract_has_been_approved</template>
    </alerts>
    <alerts>
        <fullName>Contract_has_been_rejected</fullName>
        <description>Contract has been rejected</description>
        <protected>false</protected>
        <recipients>
            <type>creator</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Contract_Contract_has_not_been_approved</template>
    </alerts>
    <alerts>
        <fullName>Email_to_Notify_Contract_Owner_of_Contract_Expiration</fullName>
        <description>Email to Notify Contract Owner of Contract Expiration</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Contract_to_Expire</template>
    </alerts>
</Workflow>
