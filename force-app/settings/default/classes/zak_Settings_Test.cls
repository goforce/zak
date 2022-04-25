@isTest
private without sharing class zak_Settings_Test {

    @isTest
    static void testAll() {
        Test.startTest();
        System.assertEquals( null, zak_Settings.get( 'zak-unit-test', null ), 'never-existing setting is null' );
        System.assertEquals( 'test', zak_Settings.get( 'zak-unit-test', 'test' ), 'never-existing setting default is ok' );
        zak_Settings.set( 'zak-unit-test', 'unit-test' );
        System.assertEquals( 'unit-test', zak_Settings.get( 'zak-unit-test', 'test' ), 'never-existing setting was set' );
        Test.stopTest();
    }

}