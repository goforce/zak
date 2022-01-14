@isTest
public without sharing class zak_UnitTest {

    public static final String BYPASS_AUTOMATIONS = zak_Settings.get( 'bypass_automations_permission', 'BypassAutomations' );
    public static final String BYPASS_VALIDATIONS = zak_Settings.get( 'bypass_validations_permission', 'BypassValidations' );

    public static final Set<String> DATA_CUSTOM_PERMISSIONS = new Set<String>{ BYPASS_AUTOMATIONS, BYPASS_VALIDATIONS };
    public static final Set<String> RUN_CUSTOM_PERMISSIONS = new Set<String>{ BYPASS_VALIDATIONS };

    public static User user() {
        return new User();
    }

    // extends Unit Test User to define two types of the users: data and run. sets custom permissions per user type.
    public virtual class User extends zak_UnitTestUser {
        public virtual User data() {
            this.addCustomPermissions( DATA_CUSTOM_PERMISSIONS );
            return this;
        }
        public virtual User run() {
            return this.run( null );
        }
        public virtual User run( Set<String> customPermissionsToRemove ) {
            this.addCustomPermissions( RUN_CUSTOM_PERMISSIONS );
            if ( customPermissionsToRemove <> null && ! customPermissionsToRemove.isEmpty() ) {
                removeCustomPermissions( customPermissionsToRemove );
            }
            return this;
        }
    }

    public virtual class Scope extends zak_UnitTestScope {
        public Scope() {
            super( new Context() );
        }
        public Scope( Context ctx ) {
            super( ctx );
        }
    }

    public virtual class Context extends zak_UnitTestScope.Context {}

    public abstract class Entity extends zak_UnitTestEntity {
        public override void link( zak_UnitTestEntity.Context ctx, SObject o ) {
            this.link( (Context) ctx, o );
        }
        public abstract void link( Context ctx, SObject o );
    }

    public static Factory factory() {
        return new Factory();
    }

    public virtual class Factory extends zak_UnitTestFactory {}

    private static Integer idCounter = 1;
    // generate dummy 15 char ID for sobject type. to be used only in unit tests.
    public static ID nextId( Schema.SObjectType t ) {
        if ( t == null ) return null;
        String prefix = t.getDescribe().getKeyPrefix();
        return prefix + String.valueOf( idCounter++ ).leftPad( 12, '0' );
    }

}