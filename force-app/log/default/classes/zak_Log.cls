// based on github.com/goforce/zak.
// simple error logging via platform event (zak_LogEvent__e) or directly to object (zak_Log__c).
// object methods are suffixed with x.
// configure topics to be logged using 'log_topics' and 'logx_topics' in zak_Settings class.
// use log_topics to enable event publishing for the topic.
// use logx_topics to disable capturing of the topic into zak_Log__c object.
// by default all topics are enabled.
public without sharing virtual class zak_Log {

    public static final Topic ERR = new Topic( 'ERR' );
    public static final Topic WARN = new Topic( 'WARN' );
    public static final Topic INFO = new Topic( 'INFO' );
    public static final Topic PERF = new Topic( 'PERF' );

    private static List<zak_LogEvent__e> buffer;
    private static List<zak_Log__c> bufferx;

    // base methods: set topics, log via event, log directly to error log object, buffering.

    // publish error log event. topic should be enabled.
    public static void log( Topic t, String source, String message, String stackTrace, String payload ) {
        debug( t, message, stackTrace, payload );
        if ( t <> null && t.enabled ) {
            EventBus.publish( event( t, source, message, stackTrace, payload ) );
        }
    }

    // add error log event to the buffer. topic should be enabled. buffer should be explicitly flushed.
    public static void add( Topic t, String source, String message, String stackTrace, String payload ) {
        debug( t, message, stackTrace, payload );
        if ( t <> null && t.enabled ) {
            if ( buffer == null ) buffer = new List<zak_LogEvent__e>();
            buffer.add( event( t, source, message, stackTrace, payload ) );
        }
    }

    // publish error log events from buffer. buffer is reset after flush.
    public static void flush() {
        if ( buffer <> null && ! buffer.isEmpty() ) {
            EventBus.publish( buffer );
            buffer.clear();
        }
    }

    // insert log records mapped from error log events
    public static void logx( List<zak_LogEvent__e> events ) {
        List<zak_Log__c> logs = new List<zak_Log__c>();
        for ( zak_LogEvent__e e : events ) {
            if ( e == null ) continue; 
            if ( e.Topic__c <> null ) {
                Topic t = ENCODING.get( e.Topic__c );
                if ( t <> null && t.enabledx ) {
                    logs.add( record( e ) );
                }
            }
        }
        insert logs;
    }

    // insert log record. topic should be enabled for recording.
    public static void logx( Topic t, String source, String message, String stackTrace, String payload ) {
        if ( t <> null && t.enabledx ) {
            insert record( t, source, message, stackTrace, payload );
        }
    }

    // add log record to the buffer. topic should be enabled. buffer should be explicitly flushed.
    public static void addx( Topic t, String source, String message, String stackTrace, String payload ) {
        if ( t <> null && t.enabledx ) {
            if ( bufferx == null ) bufferx = new List<zak_Log__c>();
            bufferx.add( record( t, source, message, stackTrace, payload ) );
        }
    }

    // insert log records from buffer. buffer is reset after flush.
    public static void flushx() {
        if ( bufferx <> null && ! bufferx.isEmpty() ) {
            insert bufferx;
            bufferx.clear();
        }
    }

    // shortcut methods

    // log exception as error
    public static void log( String source, Exception e ) {
        log( ERR, source, String.valueOf( e ), e.getStackTraceString(), null );
    }

    // log exception as error with payload
    public static void log( String source, Exception e, String payload ) {
        log( ERR, source, String.valueOf( e ), e.getStackTraceString(), payload );
    }

    // log exception as error with payload
    public static void log( String source, Exception e, Blob payload ) {
        log( ERR, source, String.valueOf( e ), e.getStackTraceString(), payload == null ? null : payload.toString() );
    }

    // log save result if not success as error
    public static void log( String source, Database.SaveResult r ) {
        if ( ! r.isSuccess() ) {
            String m = null;
            String sts = '';
            for ( Database.Error e : r.getErrors() ) {
                if ( m == null ) m = e.getMessage();
                sts += e.getStatusCode() + ' ' + e.getMessage() + ' (' + e.getFields() + ')\n';
            }
            log( ERR, source, m, sts, String.valueOf( r ) );
        }
    }

    // log upsert result if not success as error
    public static void log( String source, Database.UpsertResult r ) {
        if ( ! r.isSuccess() ) {
            String m = null;
            String sts = '';
            for ( Database.Error e : r.getErrors() ) {
                if ( m == null ) m = e.getMessage();
                sts += e.getStatusCode() + ' ' + e.getMessage() + ' (' + e.getFields() + ')\n';
            }
            log( ERR, source, m, sts, String.valueOf( r ) );
        }
    }

    // log upsert result if not success as error
    public static void log( String source, Database.DeleteResult r ) {
        if ( ! r.isSuccess() ) {
            String m = null;
            String sts = '';
            for ( Database.Error e : r.getErrors() ) {
                if ( m == null ) m = e.getMessage();
                sts += e.getStatusCode() + ' ' + e.getMessage() + ' (' + e.getFields() + ')\n';
            }
            log( ERR, source, m, sts, String.valueOf( r ) );
        }
    }

    // log upsert result if not success as error
    public static void log( String source, Approval.LockResult r ) {
        if ( ! r.isSuccess() ) {
            String m = null;
            String sts = '';
            for ( Database.Error e : r.getErrors() ) {
                if ( m == null ) m = e.getMessage();
                sts += e.getStatusCode() + ' ' + e.getMessage() + ' (' + e.getFields() + ')\n';
            }
            log( ERR, source, m, sts, String.valueOf( r ) );
        }
    }

    // log upsert result if not success as error
    public static void log( String source, Approval.UnlockResult r ) {
        if ( ! r.isSuccess() ) {
            String m = null;
            String sts = '';
            for ( Database.Error e : r.getErrors() ) {
                if ( m == null ) m = e.getMessage();
                sts += e.getStatusCode() + ' ' + e.getMessage() + ' (' + e.getFields() + ')\n';
            }
            log( ERR, source, m, sts, String.valueOf( r ) );
        }
    }

    // log error with source, message
    public static void error( String source, String message ) {
        log( ERR, source, message, null, null );
    }

    // log error with source, message and payload
    public static void error( String source, String message, String payload ) {
        log( ERR, source, message, null, payload );
    }

    // log error with source, message and payload
    public static void error( String source, String message, Blob payload ) {
        log( ERR, source, message, null, payload == null ? null : payload.toString() );
    }

    // log warning with source, message
    public static void warn( String source, String message ) {
        log( WARN, source, message, null, null );
    }

    // log warning with source, message and payload
    public static void warn( String source, String message, String payload ) {
        log( WARN, source, message, null, payload );
    }

    // log warning with source, message and payload
    public static void warn( String source, String message, Blob payload ) {
        log( WARN, source, message, null, payload == null ? null : payload.toString() );
    }

    // log info message with source, message
    public static void info( String source, String message ) {
        log( INFO, source, message, null, null );
    }

    // log info message with source, message and payload
    public static void info( String source, String message, String payload ) {
        log( INFO, source, message, null, payload );
    }

    // log info message with source, message and payload
    public static void info( String source, String message, Blob payload ) {
        log( INFO, source, message, null, payload == null ? null : payload.toString() );
    }

    // log info message with source and payload
    public static void info( String source, Blob payload ) {
        log( INFO, source, null, null, payload == null ? null : payload.toString() );
    }

    // log performance checkpoint with source, message
    public static void perf( String source, String message ) {
        log( PERF, source, message, null, null );
    }

    // private methods to create/map events and records

    // create event from parameters
    private static zak_LogEvent__e event( Topic t, String source, String message, String stackTrace, String payload ) {
        Request req = Request.getCurrent();
        return new zak_LogEvent__e(
            Topic__c = t == null ? INFO.label : t.label
          , Source__c = source == null ? 'unknown' : source.abbreviate( 255 )
          , Message__c = message == null ? null : message.abbreviate( 32768 )
          , StackTrace__c = stackTrace == null ? null : stackTrace.abbreviate( 32768 )
          , Payload__c = payload == null ? null : payload.abbreviate( 131072 )
          , TimeMillis__c = System.currentTimeMillis()
          , RequestId__c = req.getRequestId().abbreviate( 255 )
          , Quiddity__c = String.valueOf( req.getQuiddity() ).abbreviate( 80 )
          , UserId__c = UserInfo.getUserId()
        );
    }

    // create record from parameters
    private static zak_Log__c record( Topic t, String source, String message, String stackTrace, String payload ) {
        Request req = Request.getCurrent();
        return new zak_Log__c(
            Name = message == null ? 'unknown' : message.abbreviate( 80 )
          , Topic__c = t == null ? INFO.label : t.label
          , Source__c = source == null ? 'unknown' : source.abbreviate( 255 )
          , Message__c = message == null ? null : message.abbreviate( 32768 )
          , StackTrace__c = stackTrace == null ? null : stackTrace.abbreviate( 32768 )
          , Payload__c = payload == null ? null : payload.abbreviate( 131072 )
          , TimeMillis__c = System.currentTimeMillis()
          , Timestamp__c = System.now()
          , RequestId__c = req.getRequestId().abbreviate( 255 )
          , Quiddity__c = String.valueOf( req.getQuiddity() ).abbreviate( 80 )
          , UserId__c = UserInfo.getUserId()
        );
    }

    private static zak_Log__c record( zak_LogEvent__e e ) {
        if ( e == null ) return null;
        return new zak_Log__c(
            Name = e.Message__c == null ? 'unknown' : e.Message__c.abbreviate( 80 )
          , Topic__c = e.Topic__c
          , Source__c = e.Source__c
          , Message__c = e.Message__c
          , StackTrace__c = e.StackTrace__c
          , Payload__c = e.Payload__c
          , TimeMillis__c = e.TimeMillis__c
          , Timestamp__c = e.TimeMillis__c == null ? null : Datetime.newInstance( e.TimeMillis__c.longValue() )
          , RequestId__c = e.RequestId__c
          , Quiddity__c = e.Quiddity__c
          , UserId__c = e.UserId__c
        );
    }

    // output to system debug log
    private static void debug( Topic t, String error, String stackTrace, String payload ) {
        if ( t == ERR ) {
            System.debug( LoggingLevel.ERROR, error + '\nStackTrace:\n' + stackTrace + '\nPayload:\n' + payload );
        } else if ( t == WARN ) {
            System.debug( LoggingLevel.WARN, error + '\nStackTrace:\n' + stackTrace + '\nPayload:\n' + payload );
        } else if ( t == INFO ) {
            System.debug( LoggingLevel.INFO, error + '\nStackTrace:\n' + stackTrace + '\nPayload:\n' + payload );
        } else {
            System.debug( LoggingLevel.DEBUG, error + '\nStackTrace:\n' + stackTrace + '\nPayload:\n' + payload );
        }
    }


    // topics allows to group logs and enable/disable them per topic. new topics can be introduced by overriding
    // zak_Log. new topics should be added to encoding map.
    public class Topic {
        private String label;
        private Boolean enabled = false;
        private Boolean enabledx = true;
        private Topic( String label ) {
            this.label = label;
        }
        public Boolean enable() { Boolean b = enabled; enabled = true; return b; }
        public Boolean disable() { Boolean b = enabled; enabled = false; return b; }
        public Boolean enablex() { Boolean b = enabledx; enabledx = true; return b; }
        public Boolean disablex() { Boolean b = enabledx; enabledx = false; return b; }
        public override String toString() { return label; }
    }

    // singleton to create new topics
    public static Topic newTopic( String label ) {
        if ( label == null || label.length() > 5 ) {
            throw new LogException( 'topic can not be null and can not exceed 5 chars' );
        }
        if ( ENCODING.containsKey( label ) ) return ENCODING.get( label );
        Topic t = new Topic( label );
        ENCODING.put( t.label, t );
        return t;
    }

    // to avoid for loops encoding is done using fixed map it means that it is case-sensitive.
    private static final Map<String,Topic> ENCODING = new Map<String,Topic>{
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
                n = n.trim();
                Topic t = ENCODING.get( n );
                if ( t == null ) t = newTopic( n );
                if ( t <> null ) t.enabled = true;
            }
        } else {
            ERR.enabled = true;
            WARN.enabled = true;
            INFO.enabled = true;
            PERF.enabled = true;
        }
        String x = zak_Settings.get( 'logx_topics', null );
        if ( x <> null ) {
            for ( String n : x.split( ',' ) ) {
                n = n.trim();
                Topic t = ENCODING.get( n );
                if ( t == null ) t = newTopic( n );
                if ( t <> null ) t.enabledx = false;
            }
        }
    }

    public class LogException extends Exception {}

}