/**
 * AngularJS promises - Remote Action controller
 */
global with sharing class ContactsAngularJSPromises {

    global static String getContactListJSON() {
        List<InstanceWrapper> instance = new List<InstanceWrapper>();
        for (Contact c : [SELECT ID, 
                                 Name,
                                 Email,
                                 Phone,
                                 Department 
                          FROM Contact 
                          ORDER BY CreatedDate 
                          LIMIT 10]) {

            instance.add(new InstanceWrapper(c.ID, c.Name, c.Department, c.Email, c.Phone));
        }

        return JSON.serializePretty(instance);

    }

    @RemoteAction
    global static List<Contact> getAllByFilter(String searchText) {
        String searchString = '%' + searchText + '%';
        try {
            return [SELECT ID, 
                           Name,
                           Email,
                           Phone,
                           Department
                    FROM Contact 
                    WHERE Name LIKE :searchString
                    ORDER BY CreatedDate 
                    LIMIT 10];
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'An error has occured during Fetch.');
            return null;
        }
    }    

    @RemoteAction
    global static String saveAndGetAll(Contact cnt) {
        try {
            insert cnt;
            
            return JSON.serializePretty([SELECT ID,
                                                Name,
                                                Email,
                                                Phone,
                                                Department
                                         FROM Contact
                                         ORDER BY CreatedDate
                                         LIMIT 10]);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'An error has occured during Saving.');
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

        global InstanceWrapper() {
            Name = Department = Email = Phone = '';
        }

        global InstanceWrapper(String ID, String Name, String Department, String Email, String Phone) {
            this.ID = ID;
            this.Name = Name;
            this.Department = Department;
            this.Email = Email;
            this.Phone = Phone;
        }

    }

}