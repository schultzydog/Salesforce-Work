<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Name_Update</fullName>
        <field>Name</field>
        <formula>LEFT(Contact__r.FirstName &amp; &quot; &quot; &amp;  Contact__r.LastName &amp; &quot; - &quot; &amp; Account_Preferences__r.Name,80)</formula>
        <name>Name Update</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Populate_Contact_Acct_Pref_concat</fullName>
        <field>Contact_AcctPref_Concat__c</field>
        <formula>CASESAFEID( Contact__c ) + CASESAFEID( Account_Preferences__c )</formula>
        <name>Populate Contact Acct Pref concat</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Populate_Contact_Library_concat</fullName>
        <field>Contact_Library_Concat__c</field>
        <formula>CASESAFEID( Contact__c ) + CASESAFEID( Account_Preferences__r.Library__c)</formula>
        <name>Populate Contact Library concat</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
</Workflow>
