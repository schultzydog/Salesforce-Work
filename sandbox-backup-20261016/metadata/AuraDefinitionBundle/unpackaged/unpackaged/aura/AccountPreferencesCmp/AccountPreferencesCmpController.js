({
	check : function(component, event, helper){
		helper.checkState(component, event, helper);
	},

	doInit : function(component, event) {
		let recordId = component.get('v.recordId');
        if(!component.get('v.accountid')) component.set('v.accountid', recordId);
        
		component.set("v.toggleSpinner", true);

		var helptext = $A.get("$Label.c.Contact_Preferences_Help_Text");
		component.set("v.HelpText", helptext);

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

		if (component.get("v.key") == null && component.get("v.accountid") != null){
			component.set("v.key", component.get("v.accountid"));
		}
		console.log('adam',component.get('v.accountid'),component.get('v.recordId'), component.get("v.key") );
		var url = window.location.href;
		//console.log(url);
		var isCommunity = (url.indexOf("/s/editpreferences") > -1);
		//console.log(isCommunity);
		component.set("v.isCommunity", isCommunity);

		var action = component.get("c.getLibraries");
		action.setParams({ key : component.get("v.key") });
        action.setCallback(this, function(response) {
			component.set("v.toggleSpinner", false);
            var state = response.getState();
            if (state === "SUCCESS") {
                console.log("Success");
                var data = response.getReturnValue();
				console.log(data);
                if (data === null || data === "" || data === "[]" || data === "{}") {
					component.set("v.wrappers", null);
                } else {
					component.set("v.wrappers", data);
					if (data.length > 0){
						component.set("v.email", data[0].email);
						component.set("v.isLicenseSalesforce", data[0].isLicenseSalesforce);
						console.log(data[0].email);
					}
					
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
	
	expandAll : function(component, event, helper) {
		
		helper.expandAll(component, event, helper);
		
	},

	collapseAll : function(component, event, helper) {

		helper.collapseAll(component, event, helper);

	},

    toggle : function(component, event, helper) {
		var id = event.currentTarget.getAttribute("data-id");
		console.log(id);
		helper.helperToggle(component,event,id);
	},
	
	selectAll : function(component, event, helper) {

		console.log("SelectAll");

		var val = true;
		let wrappers = component.get("v.wrappers");

		for (var i = 0; i < wrappers.length; i++){

			var wrap = wrappers[i];

			if (wrap.root.Name != '日本クライアント限定サービス') {

				for (var j = 0; j < wrap.libs.length; j++){

					wrap.libs[j].selected = true;

				}

			}

		}

		component.set("v.wrappers", wrappers);

		helper.checkState(component, event, helper);

	},

	unselectAll : function(component, event, helper) {

		console.log("UnselectAll");

		var val = false;
		let wrappers = component.get("v.wrappers");

		for (var i = 0; i < wrappers.length; i++){

			var wrap = wrappers[i];

			if (wrap.root.Name != '日本クライアント限定サービス') {

				for (var j = 0; j < wrap.libs.length; j++){

					wrap.libs[j].selected = false;

				}

			}

		}

		component.set("v.wrappers", wrappers);

		helper.checkState(component, event, helper);

	},	

	checkAll : function(component, event, helper){

		var name = event.currentTarget.getAttribute("data-id");
		name = name.split("-")[1];
		var val = true;
		//console.log(event.currentTarget.checked);

		console.log(name);

		var wrappers = component.get("v.wrappers");

		for (var i = 0; i < wrappers.length; i++){

			var wrap = wrappers[i];
			if (wrap.root.Id == name){

				for (var j = 0; j < wrap.libs.length; j++){

					wrap.libs[j].selected = val;

				}

			}

		}
		component.set("v.wrappers", wrappers);

		helper.checkState(component, event, helper);

	},
	uncheckAll : function(component, event, helper){

		var name = event.currentTarget.getAttribute("data-id");
		name = name.split("-")[1];
		var val = false;

		console.log(name);

		var wrappers = component.get("v.wrappers");

		for (var i = 0; i < wrappers.length; i++){

			var wrap = wrappers[i];
			if (wrap.root.Id == name){

				for (var j = 0; j < wrap.libs.length; j++){

					wrap.libs[j].selected = val;

				}

			}

		}
		component.set("v.wrappers", wrappers);

		helper.checkState(component, event, helper);

	},

	selectAllDaily : function(component, event, helper) {

		console.log("SelectAll Daily");

		var val = event.currentTarget.checked;
		let wrappers = component.get("v.wrappers");

		for (var i = 0; i < wrappers.length; i++){
			if (!wrappers[i].disabled){
				document.getElementsByName("checkbox-2-"+wrappers[i].root.Id)[0].checked = val;

				for (var j = 0; j < wrappers[i].libs.length; j++){
					wrappers[i].libs[j].selected = val;
				}

			}
		}

		component.set("v.wrappers", wrappers);

		helper.checkState(component, event, helper);

	}, 

	selectAllInd : function(component, event, helper) {

		console.log("SelectAll Individual");

		var val = event.currentTarget.checked;
		let wrappers = component.get("v.wrappers");

		for (var i = 0; i < wrappers.length; i++){
			if (!wrappers[i].disabled){
				document.getElementsByName("checkbox-1-"+wrappers[i].root.Id)[0].checked = val;

				for (var j = 0; j < wrappers[i].libs.length; j++){
					wrappers[i].libs[j].selected = val;
				}

			}
		}

		component.set("v.wrappers", wrappers);

		helper.checkState(component, event, helper);

	}, 

	save : function(component, event, helper){

		console.log('save');
		component.set("v.toggleSpinner", true);

		var wrappers = component.get("v.wrappers");

		var libs = [];
		for (var i = 0; i < wrappers.length; i++){
			console.log(i);
			var w = wrappers[i];
			var ls = w.libs;
			for (var j = 0; j < ls.length; j++){
				console.log(j);

				var l = ls[j];

				libs.push(l);
			}

		}

		console.log(libs);

		var action = component.get("c.saveApex");
		action.setParams({ key : component.get("v.key"), libs : JSON.stringify(libs) });
        action.setCallback(this, function(response) {
			component.set("v.toggleSpinner", false);
            var state = response.getState();
            if (state === "SUCCESS") {
                console.log("Success");
                var data = response.getReturnValue();
				console.log(data);
                if (data === null || data === "" || data === "[]" || data === "{}") {
					component.set("v.wrappers", null);
                } else {
					component.set("v.wrappers", data);
                }
            } else {
                console.log('Error');
            }

        });
        $A.enqueueAction(action);
	},
    
    doDM : function(component, event, helper) {

		let wrappers = component.get("v.wrappers");

		for (var i = 0; i < wrappers.length; i++){
			if (!wrappers[i].disabled){
				
				for (var j = 0; j < wrappers[i].libs.length; j++){
					
					if (wrappers[i].libs[j].lib.DM__c) {
						wrappers[i].libs[j].selected = true;
					}

				}

			}
		}

		component.set("v.wrappers", wrappers);

		helper.checkState(component, event, helper);

	},

	doEM : function(component, event, helper) {

		let wrappers = component.get("v.wrappers");

		for (var i = 0; i < wrappers.length; i++){
			if (!wrappers[i].disabled){
				
				for (var j = 0; j < wrappers[i].libs.length; j++){
					
					if (wrappers[i].libs[j].lib.MSCI_EM__c) {
						wrappers[i].libs[j].selected = true;
					}

				}

			}
		}

		component.set("v.wrappers", wrappers);

		helper.checkState(component, event, helper);

	}

})