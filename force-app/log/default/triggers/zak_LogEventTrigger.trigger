trigger zak_LogEventTrigger on zak_LogEvent__e ( after insert ) {
    zak_Log.logx( Trigger.new );
}