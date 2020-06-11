@isTest
private class zak_ErrorLog_Test {

    @isTest
    static void testAll() {
        Test.startTest();
        zak_ErrorLog.ERR.enable();
        zak_ErrorLog.WARN.disable();
        zak_ErrorLog.INFO.disable();
        zak_ErrorLog.PERF.disable();
        zak_ErrorLog.ERR.enablex();
        zak_ErrorLog.WARN.disablex();
        zak_ErrorLog.INFO.disablex();
        zak_ErrorLog.PERF.disablex();
        // test base methods
        zak_ErrorLog.log( zak_ErrorLog.ERR, 'unit-test', 'logged', 'stack-trace', null, 1 );
        zak_ErrorLog.log( zak_ErrorLog.WARN, 'unit-test', 'skipped', 'stack-trace', null, 1 );
        zak_ErrorLog.log( zak_ErrorLog.INFO, 'unit-test', 'skipped', 'stack-trace', null, 1 );
        zak_ErrorLog.log( zak_ErrorLog.PERF, 'unit-test', 'skipped', 'stack-trace', null, 1 );
        zak_ErrorLog.add( zak_ErrorLog.ERR, 'unit-test', 'added', 'stack-trace', null, 2 );
        zak_ErrorLog.add( zak_ErrorLog.ERR, 'unit-test', 'added', 'stack-trace', null, 2 );
        zak_ErrorLog.flush();
        zak_ErrorLog.logx( zak_ErrorLog.ERR, 'unit-test', 'logged', 'stack-trace', null, System.now() );
        zak_ErrorLog.logx( zak_ErrorLog.WARN, 'unit-test', 'skipped', 'stack-trace', null, System.now() );
        zak_ErrorLog.logx( zak_ErrorLog.INFO, 'unit-test', 'skipped', 'stack-trace', null, System.now() );
        zak_ErrorLog.logx( zak_ErrorLog.PERF, 'unit-test', 'skipped', 'stack-trace', null, System.now() );
        zak_ErrorLog.addx( zak_ErrorLog.ERR, 'unit-test', 'added', 'stack-trace', null, System.now() );
        zak_ErrorLog.addx( zak_ErrorLog.ERR, 'unit-test', 'added', 'stack-trace', null, System.now() );
        zak_ErrorLog.flushx();
        // test shortcut methods
        zak_ErrorLog.ERR.enable();
        zak_ErrorLog.WARN.enable();
        zak_ErrorLog.INFO.enable();
        zak_ErrorLog.PERF.enable();
        zak_ErrorLog.ERR.enablex();
        zak_ErrorLog.WARN.enablex();
        zak_ErrorLog.INFO.enablex();
        zak_ErrorLog.PERF.enablex();
        try {
            throw new TestException( 'test' );
        } catch ( Exception e ) {
            zak_ErrorLog.log( 'unit-test', e );
        }
        zak_ErrorLog.error( 'unit-test', 'logged' );
        zak_ErrorLog.error( 'unit-test', 'logged', '001000000000000AAA' );
        zak_ErrorLog.warn( 'unit-test', 'logged' );
        zak_ErrorLog.warn( 'unit-test', 'logged', '001000000000000AAA' );
        zak_ErrorLog.info( 'unit-test', 'logged' );
        zak_ErrorLog.info( 'unit-test', 'logged', '001000000000000AAA' );
        zak_ErrorLog.perf( 'unit-test', 'logged' );
        zak_ErrorLog.add( zak_ErrorLog.ERR, 'unit-test', 'added', '001000000000000AAA' );
        zak_ErrorLog.flush();
        Test.stopTest();
        // count results
        Integer skipped = 0;
        Integer loggedErrors = 0;
        Integer loggedWarnings = 0;
        Integer loggedInfos = 0;
        Integer loggedPerfs = 0;
        Integer addedErrors = 0;
        Integer others = 0;
        for ( zak_ErrorLog__c e : [select Topic__c, Name from zak_ErrorLog__c] ) {
            if ( e.Name == 'skipped' ) {
                skipped += 1;
            } else if ( e.Name == 'logged' ) {
                if ( e.Topic__c == zak_ErrorLog.ERR.toString() ) loggedErrors += 1;
                else if ( e.Topic__c == zak_ErrorLog.WARN.toString() ) loggedWarnings += 1;
                else if ( e.Topic__c == zak_ErrorLog.INFO.toString() ) loggedInfos += 1;
                else if ( e.Topic__c == zak_ErrorLog.PERF.toString() ) loggedPerfs += 1;
                else others += 1;
            } else if ( e.Name == 'added' ) {
                if ( e.Topic__c == zak_ErrorLog.ERR.toString() ) addedErrors += 1;
                else others += 1;
            } else {
                // logged exception should be counted as 1
                others += 1;
            }
        }
        System.assertEquals( 0, skipped, 'skipped failed' );
        System.assertEquals( 4, loggedErrors, 'loggedErrors failed' );
        System.assertEquals( 2, loggedWarnings, 'loggedWarnings failed' );
        System.assertEquals( 2, loggedInfos, 'loggedInfos failed' );
        System.assertEquals( 1, loggedPerfs, 'loggedPerfs failed' );
        System.assertEquals( 5, addedErrors, 'addedErrors failed' );
        System.assertEquals( 1, others, 'others failed' );
    }

    private class TestException extends Exception {}

}