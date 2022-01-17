@isTest
private without sharing class zak_PerfLogger_Test {

    @isTest
    private static void testAll() {
        zak_Log.PERF.disable();
        Test.startTest();
        zak_PerfLogger first = new zak_PerfLogger( 'first' );
        first.log( 'milestone' );
        zak_PerfLogger second = new zak_PerfLogger( 'second' );
        zak_PerfLogger.FlowParams p = new zak_PerfLogger.FlowParams();
        p.logType = 'START';
        p.subject = 'flow';
        List<zak_PerfLogger.FlowResults> results = zak_PerfLogger.log( new List<zak_PerfLogger.FlowParams>{ p } );
        System.assertEquals( 1, results.size(), 'results.size = params.size' );
        System.assert( results[0].logger <> null, 'logger is returned' );
        p.logType = 'INTERMEDIATE';
        p.subject = 'milestone';
        p.logger = results[0].logger;
        results = zak_PerfLogger.log( new List<zak_PerfLogger.FlowParams>{ p } );
        p.logType = 'FINISH';
        results = zak_PerfLogger.log( new List<zak_PerfLogger.FlowParams>{ p } );
        second.finish();
        zak_PerfLogger third = new zak_PerfLogger( 'third' );
        List<String> rows = zak_PerfLogger.rows.split( '\n' );
        System.assertEquals( 9, rows.size(), 'nine rows' );
        System.assert( rows[1].startsWith( '1,1,START,first,' ), 'first row' );
        System.assert( rows[2].startsWith( '2,1,INTERMEDIATE,first#milestone,' ), 'second row' );
        System.assert( rows[3].startsWith( '3,2,START,second,' ), 'third row' );
        System.assert( rows[4].startsWith( '4,3,START,flow,' ), 'fourth row' );
        System.assert( rows[5].startsWith( '5,3,INTERMEDIATE,flow#milestone,' ), 'fifth row' );
        System.assert( rows[6].startsWith( '6,3,FINISH,flow,' ), 'sixth row' );
        System.assert( rows[7].startsWith( '7,2,FINISH,second,' ), 'seventh row' );
        System.assert( rows[8].startsWith( '8,2,START,third,' ), 'eighth row' );
        first.finish();
        // rows should be reset
        rows = zak_PerfLogger.rows.split( '\n' );
        System.assertEquals( 1, rows.size(), 'two rows' );
        Test.stopTest();
    }

}
