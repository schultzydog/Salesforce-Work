export class RatingCalculator{

    fields = [];
    outlookST = [];
    impactST = [];
    impactLT = [];
    outlookLT = [];
    data = [];
    rootAnswers = [];
    sumOfRootAnswers = 0;

    eigenVectors = [];
    weightedSTSum;
    weightedLTSum;

    impactMap = new Map([
        ['Positive', 1],
        ['Neutral', 0],
        ['Negative', -1]
      ]);

    outlookMap = new Map([
        ['Very positive', 3],
        ['Positive', 2],
        ['Slightly positive', 1],
        ['Neutral', 0],
        ['Slightly negative', -1],
        ['Negative', -2],
        ['Very negative', -3]
      ]);

      fieldMap = new Map([
        ['-4',9],
        ['-3',7],
        ['-2',5],
        ['-1',3],
        ['0',1],
        ['1',.33],
        ['2',.2],
        ['3',.14],
        ['4',.11]
      ]);

    constructor(sliders,trajectoryList){
        this.fields = new Array();
        sliders.forEach(slider => {
            this.fields.push(this.fieldMap.get(slider.value));
        });

       /* this.trajectoryList[2].structuralWeight = this.trajectoryRecord.Security__c;
        this.trajectoryList[2].outlookShortTerm = this.trajectoryRecord.Security_Outlook_6_months__c;
        this.trajectoryList[2].impactShortTerm = this.trajectoryRecord.Security_Impact_6_Months__c; 
        this.trajectoryList[2].outlookLongTerm = this.trajectoryRecord.Security_Outlook_24_Months__c; 
        this.trajectoryList[2].impactLongTerm =  this.trajectoryRecord.Security_Impact_24_Months__c;*/

        this.impactST = new Array();
        this.impactLT = new Array();
        this.outlookLT = new Array();
        this.outlookST = new Array();

        trajectoryList.forEach(trajectory => {
            this.impactST.push(this.impactMap.get(trajectory.impactShortTerm));
            this.impactLT.push(this.impactMap.get(trajectory.impactLongTerm));
            this.outlookLT.push(this.outlookMap.get(trajectory.outlookLongTerm));
            this.outlookST.push(this.outlookMap.get(trajectory.outlookShortTerm));
        });
    }

    calc(){
        this.setStructuralWeight();
        this.weightedSTSum = this.setRawScore(this.outlookST, this.impactST);
        this.weightedLTSum = this.setRawScore(this.outlookLT, this.impactLT);
    }

    setRawScore(outlooks, impacts){
        //Calcualate unweightedST
        /*
        unweightedST1	 (GovernmentStabilityCohesionST1 + GovernmentStabilityCohesionST2 * 2.5) / 2 
        unweightedST2	(SocialStabilityST1 + SocialStabilityST2 * 2.5) / 2 
        unweightedST3	(SecurityST1 + SecurityST2 * 2.5) / 2 
        unweightedST4	 (EconomicPolicyST1 + EconomicPolicyST2 * 2.5) / 2 
        unweightedST5	(InvestmentPolicyST1 + InvestmentPolicyST2 * 2.5) / 2 
        */
       let weightedSum = 0;
       for(let index = 0; index < outlooks.length; index++){
            let unWeighted = (outlooks[index] * impacts[index] * 2.5) / 2;
            let weighted = unWeighted * this.eigenVectors[index];
            weightedSum += weighted;
       }

        //Calcualate Weighted
        /* 
        weightedST1:	unweightedST1 * eigenvector1 
        weightedST2	unweightedST2 * eigenvector2 
        weightedST3	unweightedST3 * eigenvector3 
        weightedST4	unweightedST4 * eigenvector4 
        weightedST5	unweightedST5 * eigenvector5 
        weightedSTSum	 weightedST1 + weightedST2 + weightedST3 + weightedST4 + weightedST5 
        */
       return weightedSum;
    }

    setStructuralWeight(){
        //Calculate Data 
         /*
            data1	round(1/field1)*1000)/1000
            data2	(1/field2
            data3	(1/field3)
            data4	(f/field4)
            data5	(1/field5
            data6	1/field6
            data7	1/field7
            data8	1/field8
            data9	1/field9
            data10	1/field10
        */
        this.data = new Array();
        this.data.push(Math.round(1/this.fields[0]*1000)/1000);
        for(let index = 1; index < this.fields.length; index++){
            this.data.push(1/this.fields[index]);
        }
        //Calculate Roots
         /*
            root1	1*data1*data2*data3*data4
            root2	field1*1*data5*data6*data7
            root3	field2*field5 * 1 * data8 * data9
            root4	field3* field 6 * field 8 * 1 * data10
            root5	field4 * field7 * field9 * field10 * 1
        */
        let roots = new Array();
        roots.push( 1 * this.data[0] * this.data[1] * this.data[2] * this.data[3]);
        roots.push( 1 * this.fields[0] * this.data[4] * this.data[5] * this.data[6]);
        roots.push( 1 * this.fields[1] * this.fields[4] * this.data[7] * this.data[8]);
        roots.push( 1 * this.fields[2] * this.fields[5] * this.fields[7] * this.data[9]);
        roots.push( 1 * this.fields[3] * this.fields[6] * this.fields[8] * this.fields[9]);

         //Calcualte Root Answers
        this.sumOfRootAnswers = 0
        roots.forEach(root => {
            const rootAns = Math.pow(root, 1/5);
            this.rootAnswers.push(rootAns);
            this.sumOfRootAnswers += rootAns;
        });

        //Calcualte eigenVectors
        /*
        eignvector1	root1Answer/SumOfRoots
        eignvector2	root2Answer/SumOfRoots
        eignvector3	root3Answer/SumOfRoots
        eignvector4	root4Answer/SumOfRoots
        eignvector5	root5Answer/SumOfRoots
        */
       this.eigenVectors = new Array();
       this.rootAnswers.forEach(rootAns => {
            this.eigenVectors.push(rootAns/this.sumOfRootAnswers);
        });
    }
}