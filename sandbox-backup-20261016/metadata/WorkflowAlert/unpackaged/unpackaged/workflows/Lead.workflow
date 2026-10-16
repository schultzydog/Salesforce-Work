<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Notify_lead_owner_of_company_referral_lead</fullName>
        <description>Notify lead owner of company sign up lead</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>DefaultWorkflowUser</senderType>
        <template>unfiled$public/Lead_Notify_on_company_sign_up</template>
    </alerts>
</Workflow>
