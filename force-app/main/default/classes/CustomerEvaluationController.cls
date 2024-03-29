public class CustomerEvaluationController {
    
    @AuraEnabled
    public static Result getLastCE(String accId) {
        Result resultObj = new Result();
        resultObj.yearPicklistValues = getYear();
        resultObj.statusPicklistValues = getStatus();
        resultObj.languagePicklist = getLanguagePicklist();
        Profile p = [select id,name from Profile where id=:UserInfo.getProfileId()];
        resultObj.isAdmin = p.name == 'System Administrator';
        resultObj.lastCE = new Customer_Evaluation__c();
        
        Account acc = [SELECT name,Owner.Name,recordType.DeveloperName,recordType.Name,BillingStreet,BillingCountry,BillingState,Street_2__c FROM Account WHERE id = :accId];
        resultObj.acc = acc;
        resultObj.accountName = acc.name;
        if(acc.RecordType.DeveloperName == 'Doctor_D' || acc.RecordType.DeveloperName == 'Doctor_T'){
            resultObj.recordType = 'Doctor_D_and_T';
        }else if(acc.RecordType.DeveloperName == 'Distributor' || acc.RecordType.DeveloperName == 'Distributor_T'){
            resultObj.recordType = 'Distributor_D';
        }else{
            resultObj.recordType = 'International';
        }
        String currentyear = System.today().year()+'';
        List<Customer_Evaluation__c> customerEvaluationList = [SELECT Id, IsDeleted, Name, RecordTypeId, 
                                                               No_of_Procedures_Cataract__c, No_of_Procedures_Glaucoma__c, 
                                                               No_of_Procedures_Pediatric__c, No_of_Procedures_Refractive__c, No_of_Procedures_Retina__c, 
                                                               Year__c, Last_Customer_Evaluation__c, Status__c, No_of_Working_Days__c, No_of_Doctors__c, 
                                                               No_of_Counselors__c, Account__c, Customer_Evaluation_Rating__c, Number_of_Time_Submitted__c, 
                                                               Annual_Turn_over_in_INR__c, No_of_Employees__c, No_of_Distribution_centers_Branch__c, Areas_covered__c, 
                                                               Number_of_Sales_Staff__c, Current_Distribution_Name_of_Companies__c, Number_of_Products_Handled_with_company__c, 
                                                               By_Tender_Business__c, By_Hospital_Supplies__c, Others__c, Annual_Turn_over_in_USD__c, 
                                                               How_much_would_be_the_annual_projection__c, Your_Retail_Shops__c, Name_the_competitors_in_your_Market__c, 
                                                               Year_of_Establishment__c, Population__c, Language_and_Currency__c, Age_ratio__c, GDP_in_USD__c, GDP_Per_capita_in_USD__c, 
                                                               Per_Capita_Health_Expenditure__c, No_of_Eye_surgeons__c, No_of_Eye_hospitals__c, No_of_Cataract_surgery_annum__c, 
                                                               Govt_Health_Policy_Tender_Facility__c, Common_Diseases__c, No_of_wholesalers__c, No_of_Pharmacies__c, 
                                                               Products_to_import__c, Value_of_imports_by_your_company__c, Do_you_have_any_Expert_Specific_Division__c, 
                                                               Are_you_handling_any_Ophthalmic_products__c, Ophthalmic_products_imported__c, Company_s_product_has_a_easy_recall__c, 
                                                               The_reasons_why_you_chose_our_Company__c, How_you_can_garner_extra_volumes__c, Do_You_Sell_products_inside_Palestine__c, 
                                                               Registration_Protocols__c, Maximum_number_of_distributors_MOH__c, Any_brands_of_your_company_registered__c 
                                                               FROM Customer_Evaluation__c
                                                               WHERE Account__c=:accId AND Year__c=:currentyear
                                                              ];
        
        if(customerEvaluationList.size()>0){
            resultObj.lastCE = customerEvaluationList[0];
        }else{
            resultObj.lastCE.recordTypeId = Schema.SObjectType.Customer_Evaluation__c.getRecordTypeInfosByDeveloperName().get(resultObj.recordType).getRecordTypeId();
        }
        /*
        resultObj.lastCEname = '';
        for(Customer_Evaluation__c obj : [SELECT Name, No_of_Procedures_Cataract__c, No_of_Procedures_Glaucoma__c, No_of_Procedures_Pediatric__c,
                                          No_of_Procedures_Refractive__c, No_of_Procedures_Retina__c, Year__c, Status__c, 
                                          No_of_Working_Days__c, No_of_Doctors__c, No_of_Counselors__c,Customer_Evaluation_Rating__c 
                                          FROM Customer_Evaluation__c WHERE Account__c=:accId ORDER BY CreatedDate DESC LIMIT 1]
           ){
               system.debug('###=' + obj);
               resultObj.lastCE = obj.clone(false);
               resultObj.lastCEname = obj.Name;
           }
        */
        
        if(resultObj.lastCE.Status__c == 'Pending Approval' ){
            resultObj.disableForm = true;
        }else{
            resultObj.disableForm = false;
        }
        resultObj.lastCE.Year__c = ''+System.today().year();
        return resultObj;                                 
    }
    
    
    @AuraEnabled
    public static Customer_Evaluation__c saveCustEvaluation( String custEvaluationJSON) {
        try{
            Customer_Evaluation__c custEvaluation = (Customer_Evaluation__c) JSON.deserialize(custEvaluationJSON, Customer_Evaluation__c.class);
            List<Account> accList = [SELECT Id,Approver_1__c,Approver_2__c FROM Account where id=:custEvaluation.Account__c];
            if(accList.size()>0){
                custEvaluation.Approver_1__c = accList[0].Approver_1__c;
                custEvaluation.Approver_2__c = accList[0].Approver_2__c;
            }
            List<Customer_Evaluation__c> lastCE = [SELECT Id
                                                   FROM Customer_Evaluation__c 
                                                   WHERE Account__c=:custEvaluation.Account__c AND Id !=: custEvaluation.Id
                                                   ORDER BY CreatedDate DESC LIMIT 1];
            if(lastCE.size()>0){
                custEvaluation.Last_Customer_Evaluation__c = lastCE[0].Id;
            }
            custEvaluation.Status__c = 'Draft';
            if(custEvaluation.Id ==null){
                Account a = new Account();
                a.last_CE_date__c = System.today();
                a.Id = custEvaluation.Account__c;
                update a;
            }
            upsert custEvaluation;
            return custEvaluation; 
        }catch(DMLException e){
            throw new AuraHandledException(e.getDMLMessage(0));
        }catch(Exception e){
            System.debug('getMessage:::'+e.getMessage()+':::at Line No:::'+e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    public static List<String> getStatus() {
        List<String> options = new List<String>();
        Schema.DescribeFieldResult fieldResult = Customer_Evaluation__c.Status__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f: ple) {
            options.add(f.getLabel());
        }
        return options;
    }
    
    private static List<String> getYear() {
        List<String> options = new List<String>();
        Schema.DescribeFieldResult fieldResult = Customer_Evaluation__c.Year__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f: ple) {
            options.add(f.getLabel());
        }
        return options;
    }
    
    private static List<String> getLanguagePicklist(){
        List<String> options = new List<String>();
        Schema.DescribeFieldResult fieldResult = Customer_Evaluation__c.Language_and_Currency__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f: ple) {
            options.add(f.getLabel());
        }
        return options;
    }
    
    public class Result{
        @AuraEnabled
        public boolean isAdmin;
        @AuraEnabled
        public boolean disableForm;
        @AuraEnabled
        public List<String> yearPicklistValues;
        @AuraEnabled
        public List<String> statusPicklistValues;
        @AuraEnabled
        public List<String> languagePicklist;
        @AuraEnabled
        public String accountName;
        @AuraEnabled
        public String lastCEname;
        @AuraEnabled
        public Customer_Evaluation__c lastCE;
        @AuraEnabled
        public Account acc;
        @AuraEnabled
        public String recordType;
        
    }
}