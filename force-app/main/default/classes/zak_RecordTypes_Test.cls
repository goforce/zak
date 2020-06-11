@isTest
private class zak_RecordTypes_Test {

    private static final List<Schema.SObjectType> sobjs = new List<Schema.SObjectType>{
        Schema.Account.sObjectType, Schema.Contact.sObjectType, Schema.Asset.sObjectType
    };

    @isTest
    private static void testAll() {
        Test.startTest();
        Map<Schema.SObjectType,Map<String,ID>> recordTypes = new Map<Schema.SObjectType,Map<String,ID>>();
        for ( Schema.SObjectType sobj : sobjs ) {
            Map<String,RecordTypeInfo> t = sobj.getDescribe().getRecordTypeInfosByDeveloperName();
            Map<String,ID> m = new Map<String,ID>();
            recordTypes.put( sobj, m );
            for ( String n : t.keySet() ) {
                m.put( n, t.get( n ).getRecordTypeId() );
            }
        }
        // check that all defined record types are returned correctly
        for ( Schema.SObjectType sobj : recordTypes.keySet() ) {
            Map<String,ID> m = recordTypes.get( sobj );
            for ( String n : m.keySet() ) {
                ID id = zak_RecordTypes.getRecordTypeId( sobj, n );
                System.assertEquals( m.get( n ), id, 'ids match.' );
            }
        }
        Test.stopTest();
    }

    @isTest
    private static void testCacheException() {
        Test.startTest();
        zak_Settings.set( zak_Keys.SETTINGS_CACHE_PARTITION, 'very-incorrect-name' );
        try {
            ID id = zak_RecordTypes.getRecordTypeId( Schema.Account.sObjectType, 'very-incorrect-name' );
        } catch ( Exception e ) {
            System.assert( true, 'no exceptions caused by incorrect cache configuration' );
        }
        Test.stopTest();
    }

}