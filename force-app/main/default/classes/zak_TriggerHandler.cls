public interface zak_TriggerHandler {

    void beforeInsert( zak_TriggerContext ctx );
    void afterInsert( zak_TriggerContext ctx );
    void beforeUpdate( zak_TriggerContext ctx );
    void afterUpdate( zak_TriggerContext ctx );
    void beforeDelete( zak_TriggerContext ctx );
    void afterDelete( zak_TriggerContext ctx );
    void afterUndelete( zak_TriggerContext ctx );

}