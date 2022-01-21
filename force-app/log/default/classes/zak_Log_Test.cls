@isTest
private without sharing class zak_Log_Test {

    @isTest
    static void testAll() {
        zak_Settings.set( 'log_topics', 'ERR' );
        zak_Settings.set( 'logx_topics', 'ERR' );
        Test.startTest();
        // test base methods
        zak_Log.log( zak_Log.ERR, 'unit-test', 'logged', 'stack-trace', null );
        zak_Log.log( zak_Log.WARN, 'unit-test', 'skipped', 'stack-trace', null );
        zak_Log.log( zak_Log.INFO, 'unit-test', 'skipped', 'stack-trace', null );
        zak_Log.log( zak_Log.PERF, 'unit-test', 'skipped', 'stack-trace', null );
        zak_Log.add( zak_Log.ERR, 'unit-test', 'added', 'stack-trace', null );
        zak_Log.add( zak_Log.ERR, 'unit-test', 'added', 'stack-trace', null );
        zak_Log.flush();
        zak_Log.logx( zak_Log.ERR, 'unit-test', 'logged', 'stack-trace', null );
        zak_Log.logx( zak_Log.WARN, 'unit-test', 'skipped', 'stack-trace', null );
        zak_Log.logx( zak_Log.INFO, 'unit-test', 'skipped', 'stack-trace', null );
        zak_Log.logx( zak_Log.PERF, 'unit-test', 'skipped', 'stack-trace', null );
        zak_Log.addx( zak_Log.ERR, 'unit-test', 'added', 'stack-trace', null );
        zak_Log.addx( zak_Log.ERR, 'unit-test', 'added', 'stack-trace', null );
        zak_Log.flushx();
        // test shortcut methods
        zak_Log.ERR.enable();
        zak_Log.WARN.enable();
        zak_Log.INFO.enable();
        zak_Log.PERF.enable();
        zak_Log.ERR.enablex();
        zak_Log.WARN.enablex();
        zak_Log.INFO.enablex();
        zak_Log.PERF.enablex();
        try {
            throw new TestException( 'test' );
        } catch ( Exception e ) {
            zak_Log.log( 'unit-test', e );
            zak_Log.log( 'unit-test', e,'test payload');
        }
        zak_Log.error( 'unit-test', 'logged' );
        zak_Log.error( 'unit-test', 'logged', 'stack trace' );
        zak_Log.warn( 'unit-test', 'logged' );
        zak_Log.warn( 'unit-test', 'logged', 'stack trace' );
        zak_Log.info( 'unit-test', 'logged' );
        zak_Log.info( 'unit-test', 'logged', 'stack trace' );
        zak_Log.perf( 'unit-test', 'logged' );
        zak_Log.add( zak_Log.ERR, 'unit-test', 'added', 'stack trace', 'payload' );
        zak_Log.flush();
        Test.stopTest();
        // count results
        Integer skipped = 0;
        Integer loggedErrors = 0;
        Integer loggedWarnings = 0;
        Integer loggedInfos = 0;
        Integer loggedPerfs = 0;
        Integer addedErrors = 0;
        Integer others = 0;
        for ( zak_Log__c e : [select Topic__c, Name from zak_Log__c] ) {
            if ( e.Name == 'skipped' ) {
                skipped += 1;
            } else if ( e.Name == 'logged' ) {
                if ( e.Topic__c == zak_Log.ERR.toString() ) {
                    loggedErrors += 1;
                }
                else if ( e.Topic__c == zak_Log.WARN.toString() ) {
                    loggedWarnings += 1;
                }
                else if ( e.Topic__c == zak_Log.INFO.toString() ) {
                    loggedInfos += 1;
                }
                else if ( e.Topic__c == zak_Log.PERF.toString() ) {
                    loggedPerfs += 1;
                } else {
                    others += 1;
                }
            } else if ( e.Name == 'added' ) {
                if ( e.Topic__c == zak_Log.ERR.toString() ) {
                    addedErrors += 1;
                } else {
                    others += 1;
                }
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
        System.assertEquals( 2, others, 'others failed' );
    }

    @isTest
    static void testDMLResults() {
        Test.startTest();
        zak_Log.ERR.enable();
        List<Account> acc = new List<Account>{
            new Account( Name = 'A', Id = zak_Utils.nextId( Schema.Account.sObjectType ) )
          , new Account( Name = 'B', Id = zak_Utils.nextId( Schema.Account.sObjectType ) )
          , new Account( Name = 'C', Id = zak_Utils.nextId( Schema.Account.sObjectType ) )
        };
        for ( Database.SaveResult r : Database.insert( acc, false ) ) zak_Log.log( 'unit-test', r );
        for ( Database.UpsertResult r : Database.upsert( acc, false ) ) zak_Log.log( 'unit-test', r );
        for ( Database.DeleteResult r : Database.delete( acc, false ) ) zak_Log.log( 'unit-test', r );
        Test.stopTest();
        List<zak_Log__c> l = [select Topic__c, Name from zak_Log__c];
        System.assertEquals( 9, l.size(), '9 logs' );
    }

    // Approval lock/unlock API should be enabled in Apex or unexpected system exception is thrown.
    // @isTest
    // static void testApprovalResults() {
    //     Test.startTest();
    //     zak_Log.ERR.enable();
    //     List<Account> acc = new List<Account>{
    //         new Account( Name = 'A', Id = zak_Utils.nextId( Schema.Account.sObjectType ) )
    //         , new Account( Name = 'B', Id = zak_Utils.nextId( Schema.Account.sObjectType ) )
    //         , new Account( Name = 'C', Id = zak_Utils.nextId( Schema.Account.sObjectType ) )
    //     };
    //     for ( Approval.LockResult r : Approval.lock( acc, false ) ) zak_Log.log( 'unit-test', r );
    //     for ( Approval.UnlockResult r : Approval.unlock( acc, false ) ) zak_Log.log( 'unit-test', r );
    //     Test.stopTest();
    //     List<zak_Log__c> l = [select Topic__c, Name from zak_Log__c];
    //     System.assertEquals( 6, l.size(), '6 logs' );
    // }

    @isTest
    static void testBlobs() {
        Test.startTest();
        String t = 'thisisblob';
        Blob b = Blob.valueOf( t );
        zak_Log.ERR.enable();
        zak_Log.WARN.enable();
        zak_Log.INFO.enable();
        zak_Log.info( 'unit-test', 'logged', b );
        zak_Log.info( 'unit-test', b );
        zak_Log.log( 'unit-test', new TestException( 'a' ), b );
        zak_Log.error( 'unit-test', 'logged', b );
        zak_Log.warn( 'unit-test', 'logged', b );
        Test.stopTest();
        List<zak_Log__c> l = [select Payload__c from zak_Log__c];
        System.assertEquals( 5, l.size(), '5 logs with payload' );
        System.assertEquals( t, l[0].Payload__c, 'payload is not ok 1' );
        System.assertEquals( t, l[1].Payload__c, 'payload is not ok 2' );
        System.assertEquals( t, l[2].Payload__c, 'payload is not ok 3' );
        System.assertEquals( t, l[3].Payload__c, 'payload is not ok 4' );
        System.assertEquals( t, l[4].Payload__c, 'payload is not ok 5' );
    }

    @isTest
    static void testUserTopic() {
        Test.startTest();
        try {
            zak_Log.Topic t = zak_Log.newTopic( 'unit-test' );
            System.assert( false, 'exception not thrown' );
        } catch ( Exception e ) {
            System.assert( e instanceof zak_Log.LogException, 'exception is not correct' );
        }
        zak_Log.Topic t = zak_Log.newTopic( 'unitt' );
        t.disable();
        zak_Log.log( t, 'disabled', 'log', 'stacktrace', 'payload' );
        t.disablex();
        zak_Log.logx( t, 'disabled', 'logx', 'stacktrace', 'payload' );
        t.enable();
        zak_Log.log( t, 'source', 'log', 'stacktrace', 'payload' );
        t.enablex();
        zak_Log.logx( t, 'source', 'logx', 'stacktrace', 'payload' );
        Test.stopTest();
        List<zak_Log__c> l = [select Topic__c, Source__c, Message__c from zak_Log__c];
        System.assertEquals( 2, l.size(), '2 logs with payload' );
        System.assertEquals( 'source', l[0].Source__c, 'source is not ok 1' );
        System.assertEquals( 'source', l[1].Source__c, 'source is not ok 2' );
        System.assertEquals( 'unitt', l[0].Topic__c, 'topic is not ok 1' );
        System.assertEquals( 'unitt', l[1].Topic__c, 'topic is not ok 2' );
    }

    private class TestException extends Exception {}

}