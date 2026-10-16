({
	doInit : function(component, event, helper) {
		
        // the function that reads the url parameters
		var getUrlParameter = function getUrlParameter(sParam) {
			var sPageURL = decodeURIComponent(window.location.search.substring(1)),
				sURLVariables = sPageURL.split('&'),
				sParameterName,
				i;

			for (i = 0; i < sURLVariables.length; i++) {
				sParameterName = sURLVariables[i].split('=');

				if (sParameterName[0] === sParam) {
					return sParameterName[1] === undefined ? true : sParameterName[1];
				}
			}
		};

		//set the src param value to my src attribute
		component.set("v.key", getUrlParameter('key'));
		component.set("v.id", getUrlParameter('id'));
        
        var action = component.get("c.getContact");
		action.setParams({ key : component.get("v.key") });
        action.setCallback(this, function(response) {
			component.set("v.toggleSpinner", false);
            var state = response.getState();
            if (state === "SUCCESS") {
                console.log("Success");
                var data = response.getReturnValue();
				console.log(data);
                if (data === null || data === "" || data === "[]" || data === "{}") {
					//error
                } else {
					component.set("v.contact", data);
                    component.set("v.contactFound", true);
                }
            } else {

                console.log('Error');
                var errors = response.getError();
				if (errors && errors[0]) {

                    console.error('### error: ' + JSON.stringify(errors));
                    console.error("Error message: " + errors[0].message);    
                }
            }
        });
        $A.enqueueAction(action);
        
	},
    
    save : function(component, event, helper) {
        
        component.set("v.toggleSpinner", true);
        
        var action = component.get("c.saveContact");
        var s = JSON.stringify(component.get("v.contact"));
        console.log(s);
        action.setParams({ contactJSON: s });
        action.setCallback(this, function(response) {
			component.set("v.toggleSpinner", false);
            var state = response.getState();
            if (state === "SUCCESS") {
                console.log("Success");
                var data = response.getReturnValue();
				console.log(data);
                alert(data);
            } else {

                console.log('Error');
                var errors = response.getError();
				if (errors && errors[0]) {

                    console.error('### error: ' + JSON.stringify(errors));
                    console.error("Error message: " + errors[0].message);    
                }
            }
        });
        $A.enqueueAction(action);
        
    }
})