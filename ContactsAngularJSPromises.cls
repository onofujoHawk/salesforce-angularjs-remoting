/**
 * AngularJS promises - Remote Action controller
 */
global with sharing class ContactsAngularJSPromises {

    global static String getContactListJSON() {
        List<InstanceWrapper> instance = new List<InstanceWrapper>();
        for (Contact c : contacts()) {

            instance.add(new InstanceWrapper(c.ID, c.Name, c.Department, c.Email, c.Phone, c.Account.Name));
        }

        return JSON.serializePretty(instance);

    }

    @RemoteAction
    global static String findAll() {
        return JSON.serializePretty(contacts());
    }

    @RemoteAction
    global static List<Contact> getAllByFilter(String searchText) {
        String searchString = '%' + searchText + '%';
        try {
            return [SELECT ID, 
                           Name,
                           Email,
                           Phone,
                           Department,
                           AccountId, 
                           Account.Name
                    FROM Contact 
                    WHERE Name LIKE :searchString];

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'An error has occured during Fetch.');
            return null;
        }
    }    

    @RemoteAction
    global static String saveAndGetAll(Contact cont) {
        try {
            insert cont;
            return findAll();

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'An error has occured during Saving.');
            return null;
        }
    }

    @RemoteAction
    global static String deleteById(String ID) {
        try {
          Contact cont = Database.Query('SELECT ' + getObjectFields('Contact') + ' FROM Contact WHERE ID = \'' + ID + '\' LIMIT 1');
          delete cont;
          return findAll();

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'An error has occured during Deleting.');
            return null;
        }
    }

    @RemoteAction
    global static List<Contact> updateContact(String contactJSON) {
        try {
          Contact cont = (Contact) JSON.deserialize(contactJSON, Contact.class);
          update cont;
          return contacts();

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'An error has occured during Merge.');
            return null;
        }
    }

    //Utility class
    global class InstanceWrapper {

        String ID;
        String Name;
        String Department;
        String Email;
        String Phone;
        String AccountID;
        String AccountName;

        global InstanceWrapper() {
            Name = Department = Email = Phone = AccountID = AccountName = '';
        }

        global InstanceWrapper(String ID, String Name, String Department, String Email, String Phone, String AccountName) {
            this.ID = ID;
            this.Name = Name;
            this.Department = Department;
            this.Email = Email;
            this.Phone = Phone;
            this.AccountName = AccountName;
            String pattern = '%' + AccountName + '%';
            if (AccountName != null) {
                this.AccountID = [SELECT ID
                                  FROM Account
                                  WHERE Name LIKE :pattern
                                  LIMIT 1].ID;
            }
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

    private static List<Contact> contacts() {
        return [SELECT ID,
                       Name,
                       Email,
                       Phone,
                       Department,
                       AccountID,
                       Account.Name
                FROM Contact
                ORDER BY Name
                LIMIT 200];
    }

    private static Integer count() {
        return [SELECT COUNT() FROM Contact];
    }

}