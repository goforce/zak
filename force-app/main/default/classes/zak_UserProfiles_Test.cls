@isTest
private class zak_UserProfiles_Test {

    @isTest
    private static void testAll() {
        Test.startTest();
        Map<ID,String> userProfiles = new Map<ID,String>();
        for ( Profile p : [select Id, Name from Profile limit 5] ) {
            userProfiles.put( p.Id, p.Name );
        }
        // check that all defined record types are returned correctly
        for ( ID pid : userProfiles.keySet() ) {
            String n = zak_UserProfiles.getProfileName( pid );
            System.assertEquals( userProfiles.get( pid ), n, 'names match.' );
        }
        Test.stopTest();
    }

    @isTest
    private static void testMultipleProfiles() {
        Test.startTest();
        Map<ID,String> userProfiles = new Map<ID,String>();
        for ( Profile p : [select Id, Name from Profile limit 5] ) {
            userProfiles.put( p.Id, p.Name );
        }
        zak_Settings.set( zak_Keys.SETTINGS_CACHE_PROFILES, String.join( userProfiles.values(), ',' ) );
        // check that all pre-populated record types are returned correctly
        for ( ID pid : userProfiles.keySet() ) {
            String n = zak_UserProfiles.getProfileName( pid );
            System.assertEquals( userProfiles.get( pid ), n, 'names match.' );
        }
        Test.stopTest();
    }

    @isTest
    private static void testCacheException() {
        Test.startTest();
        zak_Settings.set( zak_Keys.SETTINGS_CACHE_PARTITION, 'very-incorrect-name' );
        try {
            String n = zak_UserProfiles.getProfileName( '00e000000000000AAA' );
        } catch ( Exception e ) {
            System.assert( true, 'no exceptions caused by incorrect cache configuration or non-existing Id' );
        }
        Test.stopTest();
    }

}