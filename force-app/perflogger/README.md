# motivation

There are number of tools to visualize apex debug log and there are also profiling sections in debug logs. Nevertheless
 there are cases when it is hard enable debug log for just one specific transaction and debug log itself is skewing
 timings.

Performance Logger is low cost logging used in [triggers](../triggers/README.md) and can be kept in flows and apex code
 without performance penalty. When enabled it allows to log performance data in simple table which is then capture in
 [zak_Log](../logging/README.md) as PERF topic. Data is captured in zak_Log__c.Payload__c field as it is longest one
 out-of-the-box.
 