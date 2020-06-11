trigger zak_ErrorLogEventTrigger on zak_ErrorLogEvent__e ( after insert ) {
    zak_ErrorLog.logx( Trigger.new );
}