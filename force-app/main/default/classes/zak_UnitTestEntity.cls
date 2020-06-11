// zak_UnitTestEntity is basic class to implement unit test entities. Entities have name (class) and
// know how to link themselves into context. Examples of entities could be from very general like Account to
// very granular like ConsumerCustomerWithEmailOnlyAndLinkedIndividual.
public abstract class zak_UnitTestEntity {

    // lists all entities which SHOULD be pre-created to create entity.
    // requires may return null if nothing required. it should always return new set of entities
    // as set could be modified.
    public virtual Set<Type> requires() { return null; }

    // returns SObject of the entity. create may return null if entity
    // is not represented by a record.
    public virtual SObject create() { return null; }

    // initializes passed in record in context of ctx. if entity is represented by
    // record (code only entities) then it is linked just once per context.
    public abstract void link( zak_UnitTestContext ctx, zak_UnitTestRecord rec );

    // defines which user should be used for DML on this entity (used in factory run)
    public virtual User runAs() { return null; }

    // defines permission sets which should be injected into the user before entities are created.
    public virtual List<String> permissions() { return null; }

    // shortcut method used to create records after factory has been run.
    public SObject link( zak_UnitTestContext ctx, SObject obj ) {
        link( ctx, new zak_UnitTestRecord( obj ) );
        return obj;
    }

    // returns User record of the current user. to be used to run creation of the data in context of the current user
    // but separate transaction (regular vs system DMLs).
    // do not call from within runAs context (linkers). only from runAs method.
    private static User me;
    public static User getMe() {
        if ( me == null ) me = [select Id from User where Id = :UserInfo.getUserId()];
        return me;
    }

}