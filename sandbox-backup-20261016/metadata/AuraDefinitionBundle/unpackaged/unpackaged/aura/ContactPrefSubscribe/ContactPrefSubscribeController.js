({
	doInit : function(component, event, helper) {
		
        component.set("v.toggleSpinner", true);
        
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
		component.set("v.library", getUrlParameter('library'));
        
        var action = component.get("c.getPref");
		action.setParams({ key : component.get("v.key") , library : component.get("v.library")});
        action.setCallback(this, function(response) {
			component.set("v.toggleSpinner", false);
            var state = response.getState();
            if (state === "SUCCESS") {
                console.log("Success");
                var data = response.getReturnValue();
				console.log(data);
                if (data === null || data === "" || data === "[]" || data === "{}") {
					console.log('NONE');
                } else {
                    
                    //alert(data);
                    component.set("v.message", data);
					//component.set("v.wrappers", data);
					//console.log(data);
                    //component.set("v.id", data.Id);
                    //console.log(component.get("v.id"));
                    //component.set("v.name", data.Name);
                    //console.log(component.get("v.name"));
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
    
    /*
	subscribe : function(component, event, helper) { 
     	console.log("save");  
        component.set("v.toggleSpinner", true);
        
        var action = component.get("c.saveApex");
		action.setParams({ id : component.get("v.id") });
        action.setCallback(this, function(response) {
			component.set("v.toggleSpinner", false);
            var state = response.getState();
            if (state === "SUCCESS") {
                console.log("Success");
                var data = response.getReturnValue();
				console.log(data);
                if (data === null || data === "" || data === "[]" || data === "{}") {
					console.log('NONE');
                } else {
					//component.set("v.wrappers", data);
					console.log(data);
                    alert(data);
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
        
    }
    */
})