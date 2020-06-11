// simple error logging via platform event (zak_ErrorLogEvent__e) or directly to object (zak_ErrorLog__c).
// object methods are suffixed with x.
// configure topics to be logged using 'log_topics' and 'logx_topics'
public virtual class zak_ErrorLog {

    public static final Topic ERR = new Topic( 'ERR' );
    public static final Topic WARN = new Topic( 'WARN' );
    public static final Topic INFO = new Topic( 'INFO' );
    public static final Topic PERF = new Topic( 'PERF' );

    private static List<zak_ErrorLogEvent__e> buffer;
    private static List<zak_ErrorLog__c> bufferx;

    // base methods: set topics, log via event, log directly to error log object, buffering.

    // publish error log event. topic should be enabled.
    public static void log( Topic t, String source, String error, String stackTrace, String recordId, Long millis ) {
        if ( t <> null && t.enabled ) {
            EventBus.publish( event( t, source, error, stackTrace, recordId, millis ) );
        }
    }

    // add error log event to the buffer. topic should be enabled. buffer should be explicitly flushed.
    public static void add( Topic t, String source, String error, String stackTrace, String recordId, Long millis ) {
        if ( t <> null && t.enabled ) {
            if ( buffer == null ) buffer = new List<zak_ErrorLogEvent__e>();
            buffer.add( event( t, source, error, stackTrace, recordId, millis ) );
        }
    }

    // publish error log events from buffer. buffer is reset after flush.
    public static void flush() {
        if ( buffer <> null && ! buffer.isEmpty() ) {
            EventBus.publish( buffer );
            buffer.clear();
        }
    }

    // insert log records casted from error log events
    public static void logx( List<zak_ErrorLogEvent__e> events ) {
        List<zak_ErrorLog__c> logs = new List<zak_ErrorLog__c>();
        for ( zak_ErrorLogEvent__e e : events ) {
            if ( e == null ) continue; 
            if ( e.Topic__c <> null ) {
                Topic t = encoding.get( e.Topic__c );
                if ( t <> null && t.enabled ) {
                    logs.add( record( t, e ) );
                }
            }
        }
        insert logs;
    }

    // insert error log record. topic should be enabled for recording.
    public static void logx( Topic t, String source, String error, String stackTrace, String recordId, Datetime timestamp ) {
        if ( t <> null && t.enabledx ) {
            insert record( t, source, error, stackTrace, recordId, timestamp );
        }
    }

    // add error log record to the buffer. topic should be enabled. buffer should be explicitly flushed.
    public static void addx( Topic t, String source, String error, String stackTrace, String recordId, Datetime timestamp ) {
        if ( t <> null && t.enabledx ) {
            if ( bufferx == null ) bufferx = new List<zak_ErrorLog__c>();
            bufferx.add( record( t, source, error, stackTrace, recordId, timestamp ) );
        }
    }

    // insert error log records from buffer. buffer is reset after flush.
    public static void flushx() {
        if ( bufferx <> null && ! bufferx.isEmpty() ) {
            insert bufferx;
            bufferx.clear();
        }
    }

    // shortcut methods

    // log exception as error
    public static void log( String source, Exception e ) {
        log( ERR, source, e.getMessage(), e.getStackTraceString(), null );
    }

    // log error with source, error message
    public static void error( String source, String error ) {
        log( ERR, source, error, null, null );
    }

    // log error with source, error message and recordId
    public static void error( String source, String error, ID recordId ) {
        log( ERR, source, error, null, recordId );
    }

    // log warning with source, error message
    public static void warn( String source, String error ) {
        log( WARN, source, error, null, null );
    }

    // log warning with source, error message and recordId
    public static void warn( String source, String error, ID recordId ) {
        log( WARN, source, error, null, recordId );
    }

    // log info message with source, error message
    public static void info( String source, String error ) {
        log( INFO, source, error, null, null );
    }

    // log info message with source, error message and recordId
    public static void info( String source, String error, ID recordId ) {
        log( INFO, source, error, null, recordId );
    }

    // log performance checkpoint with source, error message
    public static void perf( String source, String checkpoint ) {
        log( PERF, source, checkpoint, null, null );
    }

    public static void log( Topic t, String source, String error, String stackTrace, String recordId ) {
        log( t, source, error, stackTrace, recordId, System.currentTimeMillis() );
    }

    public static void log( Topic t, String source, String error, String stackTrace, String recordId, Datetime timestamp ) {
        log( t, source, error, stackTrace, recordId, timestamp.getTime() );
    }

    public static void add( Topic t, String source, String error, String recordId ) {
        log( t, source, error, null, recordId );
    }

    // private methods to create/map events and records

    // create event from parameters
    private static zak_ErrorLogEvent__e event( Topic t, String source, String error, String stackTrace, String recordId, Long millis ) {
        return new zak_ErrorLogEvent__e(
            Topic__c = t == null ? INFO.label : t.label
          , Source__c = source == null ? 'unknown' : source.abbreviate( 255 )
          , Error__c = error == null ? null : error.abbreviate( 32768 )
          , StackTrace__c = stackTrace == null ? null : stackTrace.abbreviate( 32768 )
          , RecordId__c = recordId == null ? null : recordId.left( 18 )
          , TimeMillis__c = millis == null ? System.currentTimeMillis() : millis
        );
    }

    // create record from parameters
    private static zak_ErrorLog__c record( Topic t, String source, String error, String stackTrace, String recordId, Datetime timestamp ) {
        return new zak_ErrorLog__c(
            Name = error == null ? 'unknown' : error.abbreviate( 80 )
          , Topic__c = t == null ? INFO.label : t.label
          , Source__c = source == null ? 'unknown' : source.abbreviate( 255 )
          , ErrorMessage__c = error == null ? null : error.abbreviate( 32768 )
          , StackTrace__c = stackTrace == null ? null : stackTrace.abbreviate( 32768 )
          , RecordId__c = recordId == null ? null : recordId.left( 18 )
          , TimeMillis__c = timestamp == null ? System.currentTimeMillis() : timestamp.getTime()
          , Timestamp__c = timestamp == null ? System.now() : timestamp
        );
    }

    private static zak_ErrorLog__c record( Topic t, zak_ErrorLogEvent__e e ) {
        if ( e == null ) return null;
        return new zak_ErrorLog__c(
            Name = e.Error__c == null ? 'unknown' : e.Error__c.abbreviate( 80 )
          , Topic__c = e.Topic__c == null ? INFO.label : e.Topic__c
          , Source__c = e.Source__c == null ? 'unknown' : e.Source__c
          , ErrorMessage__c = e.Error__c == null ? null : e.Error__c
          , StackTrace__c = e.StackTrace__c == null ? null : e.StackTrace__c
          , RecordId__c = e.RecordId__c == null ? null : e.RecordId__c
          , TimeMillis__c = e.TimeMillis__c == null ? System.currentTimeMillis() : e.TimeMillis__c
          , Timestamp__c = e.TimeMillis__c == null ? System.now() : Datetime.newInstance( e.TimeMillis__c.longValue() )
        );
    }

    // topics allows to group logs and enable/disable them per topic. new topics can be introduced by overriding
    // zak_ErrorLog. new topics should be added to encoding map.
    public class Topic {
        private String label;
        private Boolean enabled = false;
        private Boolean enabledx = false;
        private Topic( String label ) {
            this.label = label;
        }
        public void enable() { enabled = true; }
        public void disable() { enabled = false; }
        public void enablex() { enabledx = true; }
        public void disablex() { enabledx = false; }
        public override String toString() { return label; }
    }

    // singleton to create new topics
    public static Topic newTopic( String label ) {
        if ( encoding.containsKey( label ) ) return encoding.get( label );
        Topic t = new Topic( label );
        encoding.put( t.label, t );
        return t;
    }

    // to avoid for loops encoding is done using fixed map it means that it is case-sensitive.
    private static final Map<String,Topic> encoding = new Map<String,Topic>{
        ERR.label => ERR
      , WARN.label => WARN
      , INFO.label => INFO
      , PERF.label => PERF
    };

    // init topics from settings
    static {
        String s = zak_Settings.get( 'log_topics', null );
        if ( s <> null ) {
            for ( String n : s.split( ',' ) ) {
                Topic t = encoding.get( n );
                if ( t <> null ) t.enabled = true;
            }
        } else {
            ERR.enabled = true;
        }
        String x = zak_Settings.get( 'logx_topics', null );
        if ( x <> null ) {
            for ( String n : x.split( ',' ) ) {
                Topic t = encoding.get( n );
                if ( t <> null ) t.enabledx = true;
            }
        } else {
            ERR.enabledx = true;
        }
    }

}