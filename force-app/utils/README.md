# motivation

There are number of nice small pieces of code which are used over and over and can be arranged in small class
with static methods.

# reference

### sobject methods

#### `public static Set<String> getStrings( List<SObject> records, Schema.SObjectField f )`
getStrings returns set of String of field values from the list of SObjects.  
null values are removed.  
Mostly used as shortcut to retrieve data needed in soql where clauses.

#### `public static Set<ID> getIds( List<SObject> records, Schema.SObjectField f )`
getIDs returns set of Ids of field values from the list of SObjects.  
null values are removed.  
Mostly used as shortcut to retrieve data needed in soql where clauses.

#### `public static Map<String,List<SObject>> assort( List<SObject> records, Schema.SObjectField f )`
assort creates map of lists with sobjects by value of the field of type string.


### string methods

#### `public static String hash( String a, String b [, String c, String d, String e] )`
hash returns concatenated strings separated with hash (#). Up to 5 string can used as parameters.

#### `public static String ns( String s )`
ns returns same string or empty string for null.

#### `public static String trim( String s )`
trim returns trimmed string or empty string for null.

#### `public static Boolean isSelected( String fieldValue, String value )`
isSelected checks that picklist value is selected in multi-picklist field value. This is case insensitive.


### number methods

#### `public static Long nn( Long n )`
returns same number or 0 for null.

#### `public static Integer nn( Integer n )`

#### `public static Decimal nn( Decimal n )`


### date and time methods

#### `public static Time parseTime( String f )`
parseTime parses time in hh:mm:ss format.

#### `public static Integer weekDay( Date d )`
weekDay returns weekday, 0 for monday and 6 for sunday.

#### `public static Date getLocalDate( Datetime t, String z )`
#### `public static Date getLocalDate( Datetime t, TimeZone z )`
getLocalDate returns local Date for Datetime in TimeZone z. For String values of z use values from
User.TimeZoneSidKey.getDescribe().getPicklistValues().  
Unknown time zones are considered GMT.

#### `public static Time getLocalTime( Datetime t, String z )`
#### `public static Time getLocalTime( Datetime t, TimeZone z )`
getLocalTime returns local Time for Datetime t in TimeZone z. For String values of z use values from
User.TimeZoneSidKey.getDescribe().getPicklistValues().  
Unknown time zones are considered GMT.

#### `public static Datetime getDatetime( Date d, Time t, String z )`
#### `public static Datetime getDatetime( Date d, Time t, TimeZone z )`
getDatetime returns GMT/UTC Datetime from local Date and Time in TimeZone z. For String values of z use values
from User.TimeZoneSidKey.getDescribe().getPicklistValues().  
Unknown time zones are considered GMT.

#### `public static TimeZone getOrgTimeZone()`
getOrgTimeZone returns org default time zone.

### unit test methods

#### `public static ID nextId( Schema.SObjectType t )`
nextId generates dummy 15 char ID for sobject type. to be used only in unit tests.

#### `public static String genString( Integer len )`
genString generates random string from upper and lower case latin letters and numbers.

#### `public static String genLower( Integer len )`
genLower generates randow string from lower case latin letters and numbers.

#### `public static String genString( Integer len, String chars )`
getString generates random string from given set of chars.

### collection methods

#### `public static void refine( List<Refinable> scope )`
refine removes objects from scope with duplicate keys, leaving newest version of the object. Intended for use in custom services.
