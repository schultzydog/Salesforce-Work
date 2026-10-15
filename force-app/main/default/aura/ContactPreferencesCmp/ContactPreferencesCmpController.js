({

	check : function(component, event, helper){
		helper.checkState(component, event, helper);
	},

	doInit : function(component, event, helper) {

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

		if (component.get("v.key") == null && component.get("v.contactid") != null){
			component.set("v.key", component.get("v.contactid"));
		}

		var url = window.location.href;
		//console.log(url);
		var isCommunity = (url.indexOf("/s/editpreferences") > -1 || (url.indexOf("/ContactPreferencesPage") > -1 && url.indexOf("apex/ContactPreferencesPage") == -1));
		//console.log(isCommunity);
		component.set("v.isCommunity", isCommunity);

		var action = component.get("c.getLibraries");
		action.setParams({ key : component.get("v.key") , isCommunity : isCommunity, updateVisits : true});
        action.setCallback(this, function(response) {
			component.set("v.toggleSpinner", false);
            var state = response.getState();
            if (state === "SUCCESS") {
                console.log("Success50");
                var data = response.getReturnValue();
				console.log(data);
                if (data === null || data === "" || data === "[]" || data === "{}") {
					component.set("v.wrappers", null);
            		component.set("v.showNone", true);
                } else {
					component.set("v.wrappers", data);
					if (data.length > 0){
						component.set("v.accountOwnerEmail", data[0].accountOwnerEmail);
						component.set("v.contactEmail1", data[0].contactEmail1);
						component.set("v.contactEmail2", data[0].contactEmail2);
						component.set("v.contactEmail3", data[0].contactEmail3);
						component.set("v.ownerName", data[0].ownerName);
						component.set("v.firstname", data[0].firstname);
                        component.set("v.isRobot", data[0].isRobot);
                        component.set("v.isPress", data[0].isPress);
						component.set("v.scroll", data[0].scroll);
						component.set("v.enabled", data[0].enabled);
						component.set("v.isLicenseSalesforce", data[0].isLicenseSalesforce);
                        console.log(component.get("v.enabled"));
                        if (isCommunity && !component.get("v.enabled")){
                            alert("You do not have permission to update your preferences");
                        }
						let name = data[0].lastname;
						if (name != null && name != ""){
							component.set("v.display", true); 
							helper.checkState(component, event, helper);
							console.log("done");
						}
					}
					component.set("v.showModal", true);
                }
            } else {

                console.log('Error');
                var errors = response.getError();
				if (errors && errors[0]) {

                    console.error('### error: ' + JSON.stringify(errors));
                    console.error("Error message: " + errors[0].message);    
                }
                component.set("v.showNone", true);
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

	checkAllDaily : function(component, event, helper){

		console.log("check daily");
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

					wrap.libs[j].daily = val;

				}

			}

		}
		component.set("v.wrappers", wrappers);

		helper.checkState(component, event, helper);

	},
    checkAllDailyAll : function(component, event, helper){

		console.log("check daily all");
		var val = true;
		
		var wrappers = component.get("v.wrappers");

		for (var i = 0; i < wrappers.length; i++){
				for (var j = 0; j < wrappers[i].libs.length; j++){
					wrappers[i].libs[j].daily = val;
				}
		}
		component.set("v.wrappers", wrappers);

		helper.checkState(component, event, helper);

	},
	checkAllInd : function(component, event, helper){

		console.log("check ind");
		var name = event.currentTarget.getAttribute("data-id");
		name = name.split("-")[1];
		var val = true;

		console.log(name);

		var wrappers = component.get("v.wrappers");

		for (var i = 0; i < wrappers.length; i++){

			var wrap = wrappers[i];
			if (wrap.root.Id == name){

				for (var j = 0; j < wrap.libs.length; j++){

					wrap.libs[j].ind = val;

				}

			}

		}
		component.set("v.wrappers", wrappers);

		helper.checkState(component, event, helper);
	},
    checkAllIndAll : function(component, event, helper){

		console.log("check ind all");
		var val = true;
		
		var wrappers = component.get("v.wrappers");

		for (var i = 0; i < wrappers.length; i++){
            for (var j = 0; j < wrappers[i].libs.length; j++){
                wrappers[i].libs[j].ind = val;
            }
		}
		component.set("v.wrappers", wrappers);

		helper.checkState(component, event, helper);

	},

	uncheckAllDaily : function(component, event, helper){

		console.log("check daily");
		var name = event.currentTarget.getAttribute("data-id");
		name = name.split("-")[1];
		var val = false;
		//console.log(event.currentTarget.checked);

		console.log(name);

		var wrappers = component.get("v.wrappers");

		for (var i = 0; i < wrappers.length; i++){

			var wrap = wrappers[i];
			if (wrap.root.Id == name){

				for (var j = 0; j < wrap.libs.length; j++){

					wrap.libs[j].daily = val;

				}

			}

		}
		component.set("v.wrappers", wrappers);

		helper.checkState(component, event, helper);

	},
    uncheckAllDailyAll : function(component, event, helper){

		console.log("uncheck daily all");
		var val = false;
		
		var wrappers = component.get("v.wrappers");

        for (var i = 0; i < wrappers.length; i++){
            for (var j = 0; j < wrappers[i].libs.length; j++){
                wrappers[i].libs[j].daily = val;
            }
		}
		component.set("v.wrappers", wrappers);

		helper.checkState(component, event, helper);

	},
	uncheckAllInd : function(component, event, helper){

		console.log("check ind");
		var name = event.currentTarget.getAttribute("data-id");
		name = name.split("-")[1];
		var val = false;

		console.log(name);

		var wrappers = component.get("v.wrappers");

		for (var i = 0; i < wrappers.length; i++){

			var wrap = wrappers[i];
			if (wrap.root.Id == name){

				for (var j = 0; j < wrap.libs.length; j++){

					wrap.libs[j].ind = val;

				}

			}

		}
		component.set("v.wrappers", wrappers);

		helper.checkState(component, event, helper);

	},
    uncheckAllIndAll : function(component, event, helper){

		console.log("uncheck ind all");
		var val = false;
		
		var wrappers = component.get("v.wrappers");
        
        for (var i = 0; i < wrappers.length; i++){
            for (var j = 0; j < wrappers[i].libs.length; j++){
                wrappers[i].libs[j].ind = val;
            }
        }
		component.set("v.wrappers", wrappers);

		helper.checkState(component, event, helper);

	},
	selectAll : function(component, event, helper) {

		console.log("SelectAll");

		var val = true;
		let wrappers = component.get("v.wrappers");

		for (var i = 0; i < wrappers.length; i++){

			var wrap = wrappers[i];

			for (var j = 0; j < wrap.libs.length; j++){

				wrap.libs[j].daily = true;
				wrap.libs[j].ind = true;

			}

		}

		component.set("v.wrappers", wrappers);

		helper.checkState(component, event, helper);

	},
    
	clearAll : function(component, event, helper) {

		console.log("ClearAll");

		var val = true;
		let wrappers = component.get("v.wrappers");

		for (var i = 0; i < wrappers.length; i++){

			var wrap = wrappers[i];

			for (var j = 0; j < wrap.libs.length; j++){

				wrap.libs[j].daily = false;
				wrap.libs[j].ind = false;

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
					wrappers[i].libs[j].daily = val;
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
					wrappers[i].libs[j].ind = val;
				}

			}
		}

		component.set("v.wrappers", wrappers);

		helper.checkState(component, event, helper);

	}, 

	save : function(component, event, helper){

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

        console.log(getUrlParameter("prdt"));
        
		//set the src param value to my src attribute
		component.set("v.key", getUrlParameter('key'));
        console.log('key:'+component.get("v.key"));
        if (component.get("v.isCommunity") && getUrlParameter("prdt") == "eg"){
            component.set("v.showEmailValidation", true);
            return;
        }
        if (component.get("v.key") == null && component.get("v.contactid") != null){
			component.set("v.key", component.get("v.contactid"));
		}
        console.log('key:'+component.get("v.key"));
		console.log('save');
		component.set("v.toggleSpinner", true);

		var wrappers = component.get("v.wrappers");
		var isCommunity = component.get("v.isCommunity");

		var libs = [];
		for (var i = 0; i < wrappers.length; i++){
			console.log(i);
			var w = wrappers[i];
			var ls = w.libs;
			for (var j = 0; j < ls.length; j++){
				console.log(j);

				var l = ls[j];

				//if (l.lib.Exclusive_List__c){

				//	if (isCommunity){
				//		l.ind = l.orig_ind;
				//		l.daily = l.orig_daily;
				//	} else {
				//		l.daily = l.orig_daily;
				//	}

				//}
				//if (w.root.Name == 'egX Publications'){
				//	l.daily = l.orig_daily;
				//}
                if (l.lib.No_Summary_Emails_Option__c){
                    l.daily = l.orig_daily;
                }

				libs.push(l);
			}

		}

		console.log(libs);

		var action = component.get("c.saveApex");
		action.setParams({ key : component.get("v.key"), libs : JSON.stringify(libs) , isCommunity : component.get("v.isCommunity")});
        action.setCallback(this, function(response) {
			component.set("v.toggleSpinner", false);
            var state = response.getState();
            if (state === "SUCCESS") {
                console.log("Success480");
                var data = response.getReturnValue();
				console.log(data);
                if (data === null || data === "" || data === "[]" || data === "{}") {
					component.set("v.wrappers", null);
                } else {
					component.set("v.wrappers", data);
                }
                helper.checkState(component, event, helper);
            } else {
                console.log('Error');
            }

        });
        $A.enqueueAction(action);
	},

	closeModal : function(component, event, helper){

		component.set("v.showModal", false);

	},
    
    closeEmailValidation : function(component, event, helper){

		component.set("v.showEmailValidation", false);

	},
    
    continueEmailValidation : function(component, event, helper){

        var email1 = component.get("v.contactEmail1");
        var email2 = component.get("v.contactEmail2");
        var email3 = component.get("v.contactEmail3");
        var input = component.get("v.contactEmailInput");
        
        //console.log("match: " + ( email == input ) );
        
        if (input == null || input == "" || ( email1 != input && email2 != input && email3 != input )){
            alert("Sorry you are not able to make an email preference change for this user");
            return;
        } else {

            component.set("v.toggleSpinner", true);
    
            var wrappers = component.get("v.wrappers");
            var isCommunity = component.get("v.isCommunity");
    
            var libs = [];
            for (var i = 0; i < wrappers.length; i++){
                console.log(i);
                var w = wrappers[i];
                var ls = w.libs;
                for (var j = 0; j < ls.length; j++){
                    console.log(j);
    
                    var l = ls[j];
    
                    //if (l.lib.Exclusive_List__c){
    
                    //    if (isCommunity){
                    //        l.ind = l.orig_ind;
                    //        l.daily = l.orig_daily;
                    //    } else {
                    //        l.daily = l.orig_daily;
                    //    }
    
                    //}
                    if (w.root.Name == 'egX Publications'){
                        l.daily = l.orig_daily;
                    }
    
                    libs.push(l);
                }
    
            }
    
            console.log(libs);
    
            var action = component.get("c.saveApex");
            action.setParams({ key : component.get("v.key"), libs : JSON.stringify(libs) , isCommunity : component.get("v.isCommunity")});
            action.setCallback(this, function(response) {
                component.set("v.toggleSpinner", false);
                var state = response.getState();
                if (state === "SUCCESS") {
                    console.log("Success562");
                    var data = response.getReturnValue();
                    console.log(data);
                    if (data === null || data === "" || data === "[]" || data === "{}") {
                        component.set("v.wrappers", null);
                    } else {
                        component.set("v.wrappers", data);
                    }
                    helper.checkState(component, event, helper);
                } else {
                    console.log('Error');
                }
    
            });
            $A.enqueueAction(action);
            
	        component.set("v.showEmailValidation", false);    
            
        }
    
	},

	doBrazil : function(component, event, helper) {

		console.log("Brazil");

		let wrappers = component.get("v.wrappers");

		for (var i = 0; i < wrappers.length; i++){
			if (!wrappers[i].disabled){
				
				for (var j = 0; j < wrappers[i].libs.length; j++){
					
					if (wrappers[i].libs[j].lib.Name == 'Brazil' || wrappers[i].libs[j].lib.Name == 'Brazil Watch' || wrappers[i].libs[j].lib.Name == 'Brazil Regulatory') {
						wrappers[i].libs[j].ind = true;
					}

				}

			}
		}

		component.set("v.wrappers", wrappers);

		helper.checkState(component, event, helper);

	},

	doDM : function(component, event, helper) {

		let wrappers = component.get("v.wrappers");

		for (var i = 0; i < wrappers.length; i++){
			if (!wrappers[i].disabled){
				
				for (var j = 0; j < wrappers[i].libs.length; j++){
					
					if (wrappers[i].libs[j].lib.DM__c) {
						wrappers[i].libs[j].ind = true;
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
						wrappers[i].libs[j].ind = true;
					}

				}

			}
		}

		component.set("v.wrappers", wrappers);

		helper.checkState(component, event, helper);

	},

	doEMFM : function(component, event, helper) {

		let wrappers = component.get("v.wrappers");

		for (var i = 0; i < wrappers.length; i++){
			if (!wrappers[i].disabled){
				
				for (var j = 0; j < wrappers[i].libs.length; j++){
					
					if (wrappers[i].libs[j].lib.MSCI_EM__c || wrappers[i].libs[j].lib.MSCI_FM__c || wrappers[i].libs[j].lib.Eurasia_Group_coverage_but_not_in_MSCI__c) {
						wrappers[i].libs[j].ind = true;
					}

				}

			}
		}

		component.set("v.wrappers", wrappers);

		helper.checkState(component, event, helper);

	},

	doUSChinaTech : function(component, event, helper) {

		let wrappers = component.get("v.wrappers");

		for (var i = 0; i < wrappers.length; i++){
			if (!wrappers[i].disabled){
				
				for (var j = 0; j < wrappers[i].libs.length; j++){
					
					if (wrappers[i].libs[j].lib.US_China_Tech__c) {
						wrappers[i].libs[j].ind = true;
					}

				}

			}
		}

		component.set("v.wrappers", wrappers);

		helper.checkState(component, event, helper);

	},

	doMacro : function(component, event, helper) {

		let wrappers = component.get("v.wrappers");

		for (var i = 0; i < wrappers.length; i++){
			if (!wrappers[i].disabled){
				
				for (var j = 0; j < wrappers[i].libs.length; j++){
					
					if (wrappers[i].libs[j].lib.Macro__c) {
						wrappers[i].libs[j].ind = true;
					}

				}

			}
		}

		component.set("v.wrappers", wrappers);

		helper.checkState(component, event, helper);

	},

	doMacroT1 : function(component, event, helper) {

		let wrappers = component.get("v.wrappers");

		for (var i = 0; i < wrappers.length; i++){
			if (!wrappers[i].disabled){
				
				for (var j = 0; j < wrappers[i].libs.length; j++){
					
					if (wrappers[i].libs[j].lib.Macro_EMs_T1__c) {
						wrappers[i].libs[j].ind = true;
					}

				}

			}
		}

		component.set("v.wrappers", wrappers);

		helper.checkState(component, event, helper);

	},

	doMacroT2 : function(component, event, helper) {

		let wrappers = component.get("v.wrappers");

		for (var i = 0; i < wrappers.length; i++){
			if (!wrappers[i].disabled){
				
				for (var j = 0; j < wrappers[i].libs.length; j++){
					
					if (wrappers[i].libs[j].lib.Macro_EMs_T2__c) {
						wrappers[i].libs[j].ind = true;
					}

				}

			}
		}

		component.set("v.wrappers", wrappers);

		helper.checkState(component, event, helper);

	}
	,doStarter : function(component, event, helper){
		let wrappers = component.get("v.wrappers");
		for (var i = 0; i < wrappers.length; i++){
			if (!wrappers[i].disabled){
				for (var j = 0; j < wrappers[i].libs.length; j++){
					if (wrappers[i].libs[j].lib.Starter__c) {
						wrappers[i].libs[j].ind = true;
					}
				}

			}
		}

		component.set("v.wrappers", wrappers);

		helper.checkState(component, event, helper);
	}

})