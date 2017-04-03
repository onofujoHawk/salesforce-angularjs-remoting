/**
 * AngularJS promises - Remote Action controller
 */
global with sharing class AccountsAngularJSPromises {

	global static String getAccountListJSON() {
		List<InstanceWrapper> instance = new List<InstanceWrapper>();
		for (Account a : accounts()) {

			instance.add(new InstanceWrapper(a.ID, a.Name, a.BillingStreet, a.NumberOfEmployees, a.AnnualRevenue, a.Industry));

		}

		return JSON.serializePretty(instance);
	}

	@RemoteAction
	global static List<Account> getAllByFilter(String searchText) {
		String searchString = '%' + searchText + '%';
		try {
			return [SELECT ID,
					   	   Name,
					   	   BillingStreet,
					   	   NumberOfEmployees,
					   	   AnnualRevenue,
					   	   Industry
					FROM Account
					WHERE Name LIKE :searchString];

		} catch (Exception e) {
			System.debug(LoggingLevel.ERROR, 'An error has occured during Fetch.');
			return null;
		}
	}

	//Utility class
    global class InstanceWrapper {

        String ID;
		String Name;
		String BillingStreet;
		Integer NumberOfEmployees;
		Decimal AnnualRevenue;
		String Industry;

        global InstanceWrapper() {
            ID = Name = BillingStreet = Industry = null;
            NumberOfEmployees = null;
            AnnualRevenue = null;
        }

        global InstanceWrapper(String ID, String Name, String BillingStreet, Integer NumberOfEmployees, Decimal AnnualRevenue, String Industry) {
            this.ID = ID;
            this.Name = Name;
            this.BillingStreet = BillingStreet;
            this.NumberOfEmployees = NumberOfEmployees;
            this.AnnualRevenue = AnnualRevenue;
            this.Industry = Industry;
        }

    }

    private static String getObjectFields(String objName) {

        String fieldnames = '';

        Map < String, Schema.SObjectType > m = Schema.getGlobalDescribe();
        Schema.SObjectType s = m.get(objName);
        Schema.DescribeSObjectResult r = s.getDescribe();

        //get fields
        Map < String, Schema.SObjectField > fields = r.fields.getMap();
        for (string field : fields.keySet()) {
            if (fieldnames == '') {
                fieldnames = field;
            } else {
                fieldnames += ',' + field;
            }
        }

        return fieldnames;

    }

    private static List<Account> accounts() {
    	return [SELECT ID, 
					   Name,
					   BillingStreet,
					   NumberOfEmployees,
					   AnnualRevenue,
					   Industry
				FROM Account
				ORDER BY NumberOfEmployees 
				LIMIT 200];
    }
	
}