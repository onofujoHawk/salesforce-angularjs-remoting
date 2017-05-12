/**
 * CRUD repository
 */
public abstract class CrudOps {

	static public List<sObject> findObjectFiltered(sObject sObj, String filter) {

		if (sObj instanceof Account)

			return Database.Query('SELECT ' + getObjectFields('Account') + ' FROM Account WHERE Name LIKE \'' + filter + '\'');

		else if (sObj instanceof Contact)

			return Database.Query('SELECT ' + getObjectFields('Contact') + ' FROM Contact WHERE Name LIKE \'' + filter + '\'');

		else
			return null;

	}

	static public Boolean saveObject(sObject sObj) {

		Map <String,sObject> sObjMap = new Map <String,sObject>();
        Boolean status = false;

        insert sObj;

        if (sObj instanceof Account) {

        	sObject[] objects = Database.Query('SELECT ' + getObjectFields('Account') + ' FROM Account ORDER BY Name DESC LIMIT 200');
        	for (sObject obj : objects) {
        		sObjMap.put(obj.ID, obj);
        	}
        	if (sObjMap.containsKey(sObj.ID))
        		status = true;

    	} else if (sObj instanceof Contact) {

    		sObject[] objects = Database.Query('SELECT ' + getObjectFields('Contact') + ' FROM Contact ORDER BY NumberOfEmployees DESC LIMIT 200');
    		for (sObject obj : objects) {
        		sObjMap.put(obj.ID, obj);
        	}
        	if (sObjMap.containsKey(sObj.ID)) 
        		status = true;
    	}
    	if (status) {

    		System.debug('Persisted successfully into Salesforce...');
    		return true;

		} else {

			System.debug('Contact not successfully inserted...');
            return false;

		}

	}

	static public Boolean deleteObjectById(sObject sObj, String Id) {
		
		Map <String,sObject> sObjMap = new Map <String,sObject>();
        Boolean status = true;

        delete sObj;

        if (sObj instanceof Account) {

        	sObject[] objects = Database.Query('SELECT ' + getObjectFields('Account') + ' FROM Account ORDER BY NumberOfEmployees DESC LIMIT 200');
        	for (sObject obj : objects) {
        		sObjMap.put(obj.ID, obj);
        	}
        	if (sObjMap.containsKey(sObj.ID))
        		status = false;

    	} else if (sObj instanceof Contact) {

    		sObject[] objects = Database.Query('SELECT ' + getObjectFields('Contact') + ' FROM Contact ORDER BY Name DESC LIMIT 200');
    		for (sObject obj : objects) {
        		sObjMap.put(obj.ID, obj);
        	}
        	if (sObjMap.containsKey(sObj.ID)) 
        		status = false;
    	}
    	if (status) {

    		System.debug('Contact removed successfully from Salesforce...');
    		return true;

		} else {

			System.debug('Contact not successfully deleted...');
            return false;

		}

	}

	static public Boolean updateObject(sObject sObjNew) {

		Boolean status = false;
		sObject sObjOld = null;

		if (sObjNew instanceof Account) {

			System.debug('Account to update... ' + sObjNew);
			sObjOld = Database.Query('SELECT ' + getObjectFields('Account') + ' FROM Account WHERE ID = \'' + sObjNew.ID + '\' LIMIT 1');

		} else if (sObjNew instanceof Contact) {

			System.debug('Contact to update... ' + sObjNew);
			sObjOld = Database.Query('SELECT ' + getObjectFields('Contact') + ' FROM Contact WHERE ID = \'' + sObjNew.ID + '\' LIMIT 1');

		}
		if (sObjNew != sObjOld) {

			System.debug('Updating Object... ' + sObjNew);
			update sObjNew;
			return true;

		} else {

			System.debug('New Object and old Object are the same, cannot update...');
			return false;

		}

	}

	public static String getObjectFields(String objName) {

        String fieldnames = '';

        Map <String, Schema.SObjectType> m = Schema.getGlobalDescribe();
        Schema.SObjectType s = m.get(objName);
        Schema.DescribeSObjectResult r = s.getDescribe();

        //get fields
        Map <String, Schema.SObjectField> fields = r.fields.getMap();
        for (string field : fields.keySet()) {
            if (fieldnames == '') {

                fieldnames = field;

            } else {

                fieldnames += ',' + field;

            }
        }

        return fieldnames;

    }

    static public Boolean isAccessible(sObject sObj, String[] fields) {

        Map<String, Schema.SObjectField> fieldsToken = getMap(sObj);
        for (String field : fields) {
            if (!fieldsToken.get(field).getDescribe().isAccessible()) {

                throw new System.NoAccessException();
                return false;

            }
        }
        return true;

    }

    static public Boolean isUpdateable(sObject sObj, String[] fields) {

        Map<String, Schema.SObjectField> fieldsToken = getMap(sObj);
        for (String field : fields) {
            if (!fieldsToken.get(field).getDescribe().isUpdateable()) {

                throw new System.NoAccessException();
                return false;

            }
        }
        return true;

    }

    private static Map<String, Schema.SObjectField> getMap(sObject sObj) {
    	
    	Map<String, Schema.SObjectField> fieldsToken = null;
    	if (sObj instanceof Contact)

    		fieldsToken = Schema.SObjectType.Contact.fields.getMap();
    	
    	else if (sObj instanceof Account)

    		fieldsToken = Schema.SObjectType.Account.fields.getMap();

    	return fieldsToken;
        
    }

}