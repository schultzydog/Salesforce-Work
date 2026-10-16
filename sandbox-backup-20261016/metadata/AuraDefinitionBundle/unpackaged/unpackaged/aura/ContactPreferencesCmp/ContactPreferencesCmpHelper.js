({
	checkState : function(component, event, helper){

		var wrappers = component.get("v.wrappers");
		var isCommunity = component.get("v.isCommunity");

		for (var i = 0; i < wrappers.length; i++){

			var wrap = wrappers[i];

            console.log('root-');
            console.log(wrap.root.Name);
            
			var indAll = true;
			var indSome = false;

			var dailyAll = true;
			var dailySome = false;

			wrappers[i].indState = 'None';
			wrappers[i].dailyState = 'None';

			for (var j = 0; j < wrap.libs.length; j++){

                //if (!wrap.libs[j].ind || !wrap.libs[j].daily) continue;
                
                console.log('--'+j+'-'+wrap.libs[j].lib.Name);
                console.log('--'+wrap.libs[j].ind);
                console.log('--'+wrap.libs[j].daily);
                if (!isCommunity || wrap.libs[j].lib.Exclusive_List__c==false){
                    if (wrap.libs[j].ind){
                        indSome = true;
                    } else {
                        indAll= false;
                    }
                }
                
                
                //if (wrap.libs[j].lib.Exclusive_List__c==false && wrap.root.Name!='egX Publications'){
                //if (wrap.libs[j].lib.Exclusive_List__c==false && wrap.libs[j].lib.No_Summary_Emails_Option__c==false){
                if (!isCommunity || wrap.libs[j].lib.Exclusive_List__c==false){
                    if (wrap.libs[j].lib.No_Summary_Emails_Option__c==false){
                        if (wrap.libs[j].daily){
                            dailySome = true;
                        } else {
                            dailyAll = false;
                        }
                    }
                }

			}

			if (indAll){
				wrappers[i].indState = 'All';
			} else if (indSome){
				wrappers[i].indState = 'Some';
			}

			if (dailyAll){
				wrappers[i].dailyState = 'All';
			} else if (dailySome){
				wrappers[i].dailyState = 'Some';
			}
			
            
            console.log('state-');
            console.log(wrappers[i].indState);
            console.log(wrappers[i].dailyState);
            console.log('---------------------');

		}
		component.set("v.wrappers", wrappers);

	},

	expandAll : function(component, event, helper) {
		
		var wrappers = component.get("v.wrappers");

		for (var i = 0; i < wrappers.length; i++){

			var secId = i;

			console.log(secId);
			var acc = component.find(secId);
			for(var cmp in acc) {
				//$A.util.toggleClass(acc[cmp], 'slds-show');
				//$A.util.toggleClass(acc[cmp], 'slds-hide');
			}
	
			var rowElements = document.getElementsByClassName('row-'+secId);
			Array.prototype.forEach.call(rowElements, function(row) {
				row.classList.add("slds-show");
				row.classList.remove("slds-hide");
			});
	
	
			//var element = document.getElementById(secId);
			//console.log(element.classList);
			//element.classList.toggle("slds-show");
			//element.classList.toggle("slds-hide");
	
			var addId = "add-"+secId;
			console.log(addId);
			var addButton = document.getElementById(addId);
			console.log(addButton);
			console.log(addButton.classList);
			addButton.classList.remove("slds-show");
			addButton.classList.add("slds-hide");
	
			var dashId = "dash-"+secId;
			console.log(dashId);
			var dashButton = document.getElementById(dashId);
			console.log(dashButton.classList);
			dashButton.classList.add("slds-show");
			dashButton.classList.remove("slds-hide");

		}
		
	},

	collapseAll : function(component, event, helper) {

		var wrappers = component.get("v.wrappers");

		for (var i = 0; i < wrappers.length; i++){

			var secId = i;

			console.log(secId);
			var acc = component.find(secId);
			for(var cmp in acc) {
				//$A.util.toggleClass(acc[cmp], 'slds-show');
				//$A.util.toggleClass(acc[cmp], 'slds-hide');
			}
	
			var rowElements = document.getElementsByClassName('row-'+secId);
			Array.prototype.forEach.call(rowElements, function(row) {
				row.classList.remove("slds-show");
				row.classList.add("slds-hide");
			});
	
	
			//var element = document.getElementById(secId);
			//console.log(element.classList);
			//element.classList.toggle("slds-show");
			//element.classList.toggle("slds-hide");
	
			var addId = "add-"+secId;
			console.log(addId);
			var addButton = document.getElementById(addId);
			console.log(addButton);
			console.log(addButton.classList);
			addButton.classList.add("slds-show");
			addButton.classList.remove("slds-hide");
	
			var dashId = "dash-"+secId;
			console.log(dashId);
			var dashButton = document.getElementById(dashId);
			console.log(dashButton.classList);
			dashButton.classList.remove("slds-show");
			dashButton.classList.add("slds-hide");

		}

	},

	helperToggle : function(component,event,secId) {
		console.log(secId);
		var acc = component.find(secId);
    	for(var cmp in acc) {
        	//$A.util.toggleClass(acc[cmp], 'slds-show');
        	//$A.util.toggleClass(acc[cmp], 'slds-hide');
		}

		var rowElements = document.getElementsByClassName('row-'+secId);
		Array.prototype.forEach.call(rowElements, function(row) {
			row.classList.toggle("slds-show");
			row.classList.toggle("slds-hide");
		});


		//var element = document.getElementById(secId);
		//console.log(element.classList);
		//element.classList.toggle("slds-show");
		//element.classList.toggle("slds-hide");

		var addId = "add-"+secId;
		console.log(addId);
		var addButton = document.getElementById(addId);
		console.log(addButton);
		console.log(addButton.classList);
		addButton.classList.toggle("slds-show");
		addButton.classList.toggle("slds-hide");

		var dashId = "dash-"+secId;
		console.log(dashId);
		var dashButton = document.getElementById(dashId);
		console.log(dashButton.classList);
		dashButton.classList.toggle("slds-show");
		dashButton.classList.toggle("slds-hide");

	}
})