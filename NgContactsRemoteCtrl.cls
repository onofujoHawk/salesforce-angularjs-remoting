/**
 * AngularJS promises - Remote Action controller
 */
global with sharing class NgContactsRemoteCtrl {
    global PageReference goToContacts {get; private set;}
    global PageReference goToAccounts {get; private set;}
    global PageReference goToHomepage {get; private set;}

    static global String[] fieldsContact = new String[] {
        'Id', 
        'Name', 
        'Department', 
        'Email', 
        'Phone', 
        'AccountId', 
        'Account.Name'
    };

    global NgContactsRemoteCtrl() {
        System.debug('init: start');
        /*--- CONTACTS PAGE ---*/
        goToContacts = Page.NgContactsRemote;
        goToContacts.setRedirect(true);
        /*--- ACCOUNT PAGE ---*/
        goToAccounts = Page.NgAccountsRemote;
        goToAccounts.setRedirect(true);
        /*--- HOMEPAGE ---*/
        goToHomepage = new PageReference('https://eu11.salesforce.com/setup/forcecomHomepage.apexp?setupid=ForceCom');
        goToHomepage.setRedirect(true);
        System.debug('init: done');
    }

    //No RemoteAction, use Wrapper instead
    global static String getContactListJSON() {
        System.debug('get Contacts list as JSON...');
        List <InstanceWrapper> instance = new List <InstanceWrapper>();
        for (Contact c : contacts()) {
            instance.add(new InstanceWrapper( c.Id, c.Name, c.Department, c.Email, c.Phone, c.Account.Name ));
        }
        return JSON.serializePretty(instance);

    }

    @RemoteAction
    global static String findAll() {
        return JSON.serializePretty(contacts());
    }

    @RemoteAction
    global static List<Contact> getAllByFilter(String searchText) {
        String pattern = '%' + searchText + '%';
        Try {

            return [SELECT Id, 
                           Name,
                           Email,
                           Phone,
                           Department,
                           AccountId, 
                           Account.Name
                    FROM Contact 
                    WHERE Name LIKE :pattern];

        } Catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'An error has occured during Fetch: ' + e.getMessage() + ' caused by ' + e.getCause() + ' on line ' + e.getLineNumber());
            return null;
        }
    }    

    @RemoteAction
    global static String saveAndGetAll(Contact contact) {
        Try {

            insert contact;
            Map <String,Contact> contactMap = new Map <String,Contact>();
            List <Contact> contacts = contacts();       
            for (Contact cont : contacts) {
                contactMap.put(cont.Id, cont);
            }
            if (!contactMap.containsKey(contact.Id)) {
                System.debug('Persisted successfully into Salesforce...');
                return findAll();
            } else {
                System.debug('Contact not successfully inserted...');
                return 'An error has occurred, Contact not successfully persisted.';
            }

        } Catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'An error has occured during Saving: ' + e.getMessage() + ' caused by ' + e.getCause() + ' on line ' + e.getLineNumber());
            return null;
        }
    }

    @RemoteAction
    global static String deleteById(String ID) {
        Try {
                
            Contact contact = Database.Query('SELECT ' + getObjectFields('Contact') + ' FROM Contact WHERE ID = \'' + ID + '\' LIMIT 1');
            if (contact != null) {
                Map <String, Contact> contactMap = new Map <String, Contact>();
                System.debug('Deleting Contact... ' + contact);
                delete contact;
                Contact[] contacts = contacts();
                for (Contact cont : contacts) {
                    contactMap.put(cont.ID, cont);
                }
                if (!contactMap.containsKey(Id)) {
                    System.debug('Contact successfully deleted...');
                    return findAll();       
                } else {
                    System.debug('Not successfully deleted...');
                    return 'An error has occurred, Contact not successfully deleted.';
                }
            } else {
                System.debug('Contact is null or empty...');
                return null;
            }
            
        } Catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'An error has occured during Deletion: ' + e.getMessage() + ' caused by ' + e.getCause() + ' on line ' + e.getLineNumber());
            return null;
        }
    }

    @RemoteAction
    global static List<Contact> updateContact(String contactJSON) {
        Try {
          
            Contact contactNew = (Contact) JSON.deserialize(contactJSON, Contact.class);
            System.debug('Contact to update... ' + contactNew);
            Contact contactOld = Database.Query('SELECT ' + getObjectFields('Contact') + ' FROM Contact WHERE ID = \'' + contactNew.Id + '\'');
            if (contactNew != contactOld) {
                System.debug('Updating Contact... ' + contactNew);
                update contactNew;
                return contacts();
            } else {
                System.debug('New Contact and Old Contact are the same, cannot update...');
                return null;
            }
            
        } Catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'An error has occured during Merging: ' + e.getMessage() + ' caused by ' + e.getCause() + ' on line ' + e.getLineNumber());
            return null;
        }
    }

    //Utility class
    global class InstanceWrapper {
        String Id;
        String Name;
        String Department;
        String Email;
        String Phone;
        String AccountId;
        String AccountName;

        global InstanceWrapper() {
            Name = Department = Email = Phone = AccountID = AccountName = '';
        }

        global InstanceWrapper(String Id, 
            String Name, 
            String Department, 
            String Email, 
            String Phone, 
            String AccountName) {
            
            this.Id             = Id;
            this.Name           = Name;
            this.Department     = Department;
            this.Email          = Email;
            this.Phone          = Phone;
            this.AccountName    = AccountName;
            String pattern = '%' + AccountName + '%';

            if (AccountName != null) {
                this.AccountId = [SELECT ID
                                  FROM Account
                                  WHERE Name LIKE :pattern
                                  LIMIT 1].ID;
            }
        }

    }

    private static String getObjectFields(String objName) {

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

    private static List<Contact> contacts() {
        return [SELECT Id,
                       Name,
                       Email,
                       Phone,
                       Department,
                       AccountId,
                       Account.Name
                FROM Contact
                ORDER BY Name
                LIMIT 200];
    }

    private static Integer count() {
        return [SELECT COUNT() FROM Contact];
    }

    static private Boolean isAccessible() {
        Map<String, Schema.SObjectField> fieldsToken = getMap();
        for (String field : fieldsContact) {
            if (!fieldsToken.get(field).getDescribe().isAccessible()) {
                throw new System.NoAccessException();
                return false;
            }
        }
        return true;
    }

    static private Boolean isUpdateable() {
        Map<String, Schema.SObjectField> fieldsToken = getMap();
        for (String field : fieldsContact) {
            if (!fieldsToken.get(field).getDescribe().isUpdateable()) {
                throw new System.NoAccessException();
                return false;
            }
        }
        return true;
    }

    private static Map<String, Schema.SObjectField> getMap() {
        Map<String, Schema.SObjectField> fieldsToken = Schema.SObjectType.Contact.fields.getMap();
        return fieldsToken;
    }


}