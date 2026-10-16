({
	checkState : function(component, event, helper){

		var wrappers = component.get("v.wrappers");

		for (var i = 0; i < wrappers.length; i++){

			var wrap = wrappers[i];

			var all = true;
			var some = false;

			wrappers[i].state = 'None';

			for (var j = 0; j < wrap.libs.length; j++){

				if (wrap.libs[j].selected){
					some = true;
				} else {
					all= false;
				}

			}

			if (all){
				wrappers[i].state = 'All';
			} else if (some){
				wrappers[i].state = 'Some';
			}

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