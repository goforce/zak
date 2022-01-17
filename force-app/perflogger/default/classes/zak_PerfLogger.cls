public inherited sharing class zak_PerfLogger {

    private enum LogType { START, INTERMEDIATE, FINISH }

    private static final Long millisZero = System.currentTimeMillis();
    private static String header = 'SeqNr,Depth,Type,Subject,Started,Timestamp,FromStart,Start2Finish,FromLast,CPUTime,DMLs,Queries,HeapSize\n';
    private static zak_PerfLogger last;
    private static Integer seqNr = 0;
    private static Long lastMillis;
    @TestVisible
    private static String rows = header;

    private zak_PerfLogger parent;
    private Integer depth;
    private String subject;
    private Datetime startTimestamp;
    private Long startMillis;

    @InvocableMethod( label = 'Log Performance' )
    public static List<FlowResults> log( List<FlowParams> params ) {
        if ( params == null || params.isEmpty() ) return new List<FlowResults>();
        FlowResults r = new FlowResults();
        if ( params[0].logType == logType.START.name() ) {
            r.logger = new zak_PerfLogger( params[0].subject );
        } else if ( params[0].logType == logType.INTERMEDIATE.name() ) {
            r.logger = params[0].logger;
            if ( r.logger != null ) {
                r.logger.log( params[0].subject );
            }
        } else if ( params[0].logType == logType.FINISH.name() ) {
            r.logger = params[0].logger;
            if ( r.logger != null ) {
                r.logger.finish();
            }
        }
        List<FlowResults> results = new List<FlowResults>();
        for ( Integer i = 0; i < params.size(); i++ ) {
            results.add( r );
        }
        return results;
    }

    public class FlowParams {
        @InvocableVariable
        public String logType;
        @InvocableVariable
        public String subject;
        @InvocableVariable
        public zak_PerfLogger logger;
    }

    public class FlowResults {
        @InvocableVariable
        public zak_PerfLogger logger;
    }

    public zak_PerfLogger( String subject ) {
        this.parent = zak_PerfLogger.last;
        zak_PerfLogger.last = this;
        this.depth = this.parent != null ? this.parent.depth + 1 : 1;
        this.subject = subject;
        this.startTimestamp = System.now();
        this.startMillis = System.currentTimeMillis();
        this.addRow( LogType.START, null );
    }

    public void log( String suffix ) {
        this.addRow( LogType.INTERMEDIATE, suffix );
    }

    // finish calculates and logs total times and elapsed times and publishes event with log info on very first log (root).
    // log is published using zak_Log with PERF topic. PERF topic is auto enabled for this publish only.
    public void finish() {
        this.addRow( LogType.FINISH, null );
        zak_PerfLogger.last = this.parent;
        if ( this.parent == null ) {
            Boolean b = zak_Log.PERF.enable();
            zak_Log.log( zak_Log.PERF, this.subject, 'zak_PerfLogger results', null, zak_PerfLogger.rows );
            if ( ! b ) {
                zak_Log.PERF.disable();
            }
            zak_PerfLogger.rows = header;
        }
    }

    private void addRow( LogType t, String suffix ) {
        zak_PerfLogger.seqNr += 1;
        String s = suffix == null ? this.subject : this.subject + '#' + suffix;
        Long currentMillis = System.currentTimeMillis();
        String start = t == LogType.FINISH ? this.startTimestamp.format( 'hh:mm:ss.SSS' ) : '';
        String elapsed = t == LogType.FINISH ? String.valueOf( currentMillis - this.startMillis ) : '';
        rows += zak_PerfLogger.seqNr + ',' + this.depth + ',' + t + ',' + s
             + ',' + start + ',' + System.now().format( 'hh:mm:ss.SSS' )
             + ',' + ( currentMillis - millisZero ) + ',' + elapsed
             + ',' + ( zak_PerfLogger.lastMillis == null ? 0 : currentMillis - zak_PerfLogger.lastMillis )
             + ',' + Limits.getCPUTime() + ',' + Limits.getDMLStatements()
             + ',' + Limits.getQueries() + ',' + Limits.getHeapSize() + '\n';
        zak_PerfLogger.lastMillis = currentMillis;
    }

}
