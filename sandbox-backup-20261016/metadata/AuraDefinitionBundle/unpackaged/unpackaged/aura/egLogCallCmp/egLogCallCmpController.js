({
    doInit : function(component, event, helper) {
        var navService = component.find("navService");
        var pageReference = {
            //type: 'standard__component',
            componentDef: "c:egLogCall",
            attributes: {
                componentName : 'c__egLogCall'
                ,c__recordId : component.get('v.recordId')
                
            },
            state:{
                c__recordId : component.get('v.recordId')
            }
        };
        let encodedCompDef = btoa(JSON.stringify(pageReference));
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": "/one/one.app#" + encodedCompDef
        });
        urlEvent.fire();
        //navService.navigate(pageReference);

    }
})