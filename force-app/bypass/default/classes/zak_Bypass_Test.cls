@isTest
private without sharing class zak_Bypass_Test {

    @isTest
    private static void testAll() {
        zak_Bypass__c settings = new zak_Bypass__c();
        Test.startTest();
        System.assertEquals( false, zak_Bypass.isEnabled( 'unittest.package.automation.action' ) );
        System.assertEquals( false, zak_Bypass.add( 'unittest.package.automation.action' ) );
        System.assertEquals( true, zak_Bypass.add( 'unittest.package.automation.action' ) );
        System.assertEquals( true, zak_Bypass.isEnabled( 'unittest.package.automation.action' ) );
        System.assertEquals( true, zak_Bypass.isEnabled( 'unittest.package.automation.action.child' ) );
        System.assertEquals( false, zak_Bypass.isEnabled( 'unittest.package.automation' ) );
        System.assertEquals( false, zak_Bypass.isEnabled( 'unittest.package.nonsense' ) );

        List<Boolean> results = zak_Bypass.isEnabled( new List<String>{
            'unittest.package.automation.action'
          , 'unittest.package.automation.action.child'
          , 'unittest.package.automation'
          , 'unittest.package.nonsense'
        } );
        System.assertEquals( true, results[0] );
        System.assertEquals( true, results[1] );
        System.assertEquals( false, results[2] );
        System.assertEquals( false, results[3] );

        System.assertEquals( false, zak_Bypass.isEnabled( 'unittest' ) );
        System.assertEquals( false, zak_Bypass.isEnabled( '' ) );
        System.assertEquals( false, zak_Bypass.isEnabled( '.' ) );
        System.assertEquals( false, zak_Bypass.add( 'unittest.*.*.action' ) );
        System.assertEquals( true, zak_Bypass.isEnabled( 'unittest.z.z.action' ) );
        System.assertEquals( true, zak_Bypass.isEnabled( 'unittest.z.z.action.z' ) );
        System.assertEquals( true, zak_Bypass.remove( 'unittest.*.*.action' ) );
        System.assertEquals( false, zak_Bypass.isEnabled( 'unittest.z.z.action' ) );
        System.assertEquals( true, zak_Bypass.isEnabled( 'unittest.package.automation.action' ) );

        System.assertEquals( false, zak_Bypass.add( '' ) );
        System.assertEquals( false, zak_Bypass.add( '.' ) );
        System.assertEquals( false, zak_Bypass.add( '..' ) );
        System.assertEquals( false, zak_Bypass.add( '.a.' ) );
        System.assertEquals( false, zak_Bypass.add( 'a..' ) );
        System.assertEquals( false, zak_Bypass.isEnabled( '' ) );
        System.assertEquals( false, zak_Bypass.isEnabled( '.' ) );
        System.assertEquals( false, zak_Bypass.isEnabled( '..' ) );
        System.assertEquals( true, zak_Bypass.isEnabled( 'a..' ) );
        System.assertEquals( false, zak_Bypass.isEnabled( '.a...' ) );
        System.assertEquals( false, zak_Bypass.remove( '.a...' ) );
        System.assertEquals( false, zak_Bypass.remove( '' ) );

        System.assertEquals( false, zak_Bypass.add( '*' ) );
        System.assertEquals( true, zak_Bypass.isEnabled( 'unittest.z.z.action' ) );
        Test.stopTest();
    }

    @isTest
    private static void testIsEnabled() {
        Test.startTest();
        List<Boolean> results = zak_Bypass.isEnabled( new List<String>{ 'a', 'a.b', 'c', 'd.c' } );
        System.assertEquals( false, results[0] );
        System.assertEquals( false, results[1] );
        System.assertEquals( false, results[2] );
        System.assertEquals( false, results[3] );
        zak_Bypass.add( 'a' );
        zak_Bypass.add( 'c' );
        results = zak_Bypass.isEnabled( new List<String>{ 'a', 'a.b', 'c', 'd.c' } );
        System.assertEquals( true, results[0] );
        System.assertEquals( true, results[1] );
        System.assertEquals( true, results[2] );
        System.assertEquals( false, results[3] );
        Test.stopTest();
    }

}
