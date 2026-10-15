# Contact Preferences — teardown rolled back

Status: **rolled back in EG-Sandbox** (2026-10-12).

The Contact Preferences object was never deleted. Shared Apex/UI that had been
stripped or removed for the teardown was restored from `metadata-audit` and
redeployed.

## Restored in EG-Sandbox

- Trigger `ContactPreferenceTrigger`
- Apex: `ContactPreferencesCtlr` (+ tests), `ContactPrefSubscribeCtlr` (+ tests),
  `PortalAddCampaignMembersBatch`, `PortalAddCampaignSEMembersBatch`,
  `PortalAddCampaignMemberBatchTest`
- Shared code: `EntitlementsHandler`, `ClientPortal_Subscribers_Ctlr` + LWC,
  related tests, `RipplingEmailHandler`, `blogic_Contact` (+ tests),
  `AccountPreferencesCtlrTests`
- Aura: `ContactPreferencesApp`, `ContactPreferencesCmp`, `ContactPrefSubscribe`,
  `ContactSubscriptionsCmp`
- VF `ContactPreferencesPage`
- FlexiPage `Contact_Record_Page1` — Subscriptions tab back
- Contact / Account Preference related lists and `Count_of_Active_prefs__c` on layout
- Rollup filters restored on `Active_Contact_Preferences__c` and
  `Count_of_Active_prefs__c`
- Contact formulas restored (`Research_Status__c`, `EG_Update_with_Summary_Only__c`,
  `eg_update_only__c`, `Has_eg_update_japan_and_not_ogdb_egupdat__c`)
- Visit fields recreated: `Contact_Preferences_Date_of_Last_Visit__c`,
  `Contact_Preferences_Edited_by_Contact__c`, `Contact_Preferences_Page_Visits__c`
- Tab `Contact_Preferences__c`
- Scheduled flows recreated and Active
- Experience Cloud Network **Contact Preferences** set back to `Live`

Manifest used: `manifest/contact-preferences-rollback/package.xml`

## Not restored (no local source)

- The 10 Contact Preference reports deleted during teardown
- Dashboard component **Current FY Contact Preference Stats** on
  `Sales Ops Team Performance`
- Draft flow `Contact: Auto-create subscriptions for EG Staff` (if it only
  existed in the org)

Rebuild those from production if still needed.
