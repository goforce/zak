// manage creation and use of user used in runAs.
// unit test best practices:
// 1. TestSetup and tests itself should be run within runAs blocks;
// 2. permission set groups should not be used to grant permissions. unlocked packages are validated right after deployment
//    and there is high chance to get exception that permission set can not be assigned as it was not updated just yet;
// 3. TestSetup is run with all validations and all automations turned off;
// 4. unit tests are run with validations and automations which are tested on. all the other are off;
// 5. avoid creation of unnecessary users for TestSetup and unit tests. creation of a user is expensive;
// 6. there should be no assumptions of field value defaulting or profile based record type defaulting;
public without sharing virtual class zak_UnitTestUser {

    public static final String DEFAULT_PREFIX = 'df';
    public static final String DOMAIN_SUFFIX = '@unit.test';

    private Set<String> permissionSetLicences = new Set<String>();
    private Set<String> permissionSets = new Set<String>();
    private Set<String> customPermissions = new Set<String>();

    public zak_UnitTestUser addPermissionSetLicenses( Set<String> psls ) {
        this.permissionSetLicences.addAll( psls );
        return this;
    }
    public zak_UnitTestUser removePermissionSetLicenses( Set<String> psls ) {
        this.permissionSetLicences.removeAll( psls );
        return this;
    }
    public zak_UnitTestUser addPermissionSets( Set<String> pss ) {
        this.permissionSets.addAll( pss );
        return this;
    }
    public zak_UnitTestUser removePermissionSets( Set<String> pss ) {
        this.permissionSets.removeAll( pss );
        return this;
    }
    public zak_UnitTestUser addCustomPermissions( Set<String> cps ) {
        this.customPermissions.addAll( cps );
        return this;
    }
    public zak_UnitTestUser removeCustomPermissions( Set<String> cps ) {
        this.customPermissions.removeAll( cps );
        return this;
    }
    public virtual User make() {
        User u = zak_UnitTestUser.get( DEFAULT_PREFIX );
        zak_UnitTestUser.addPermissionSetLicenses( u, this.permissionSetLicences );
        if ( zak_UnitTestUser.adjustCustomPermissions( u, this.customPermissions ) ) {
            this.permissionSets.add( u.LastName );
        }
        zak_UnitTestUser.addPermissionSets( u, this.permissionSets );
        return u;
    }
    public virtual User create() {
        User u = zak_UnitTestUser.create( DEFAULT_PREFIX, null );
        zak_UnitTestUser.addPermissionSetLicenses( u, this.permissionSetLicences );
        if ( zak_UnitTestUser.adjustCustomPermissions( u, this.customPermissions ) ) {
            this.permissionSets.add( u.LastName );
        }
        zak_UnitTestUser.addPermissionSets( u, this.permissionSets );
        return u;
    }

    //------------------------------ defaults ------------------------------//

    public static final Defaults DEFAULTS = new Defaults();

    public class Defaults {
        public String languageLocaleKey;
        public String profileName;
        public String emailEncodingKey;
        public String localeSidKey;
        public String timeZoneSidKey;
        public String roleName;
    }

    // create new user from template using prefix as prefix for username
    public static User create( String prefix, User template ) {
        prefix = prefix == null ? DEFAULT_PREFIX : prefix;
        User u = template == null ? new User() : template.clone( false );
        // init defaults
        if ( ( u.LanguageLocaleKey == null || u.LocaleSidKey == null || u.TimeZoneSidKey == null )
          && ( DEFAULTS.languageLocaleKey == null || DEFAULTS.localeSidKey == null || DEFAULTS.timeZoneSidKey == null ) ) {
            Organization org = [select LanguageLocaleKey, DefaultLocaleSidKey, TimeZoneSidKey
                                  from Organization
                                 where Id = :UserInfo.getOrganizationId()];
            if ( DEFAULTS.languageLocaleKey == null ) DEFAULTS.languageLocaleKey = org.LanguageLocaleKey;
            if ( DEFAULTS.localeSidKey == null ) DEFAULTS.localeSidKey = org.DefaultLocaleSidKey;
            if ( DEFAULTS.timeZoneSidKey == null ) DEFAULTS.timeZoneSidKey = org.TimeZoneSidKey;
            if ( DEFAULTS.profileName == null ) DEFAULTS.profileName = 'Minimum Access - Salesforce';
            if ( DEFAULTS.emailEncodingKey == null ) DEFAULTS.emailEncodingKey = 'UTF-8';
        }
        if ( u.Alias == null ) u.Alias = 'utest';
        if ( u.ProfileId == null && u.Profile == null ) u.Profile = new Profile( Name = DEFAULTS.profileName );
        String uname = prefix + zak_UnitTestEntity.genString( 20 );
        if ( u.Username == null ) u.Username = uname + DOMAIN_SUFFIX;
        if ( u.Email == null ) u.Email = 'data@unit.test';
        if ( u.FirstName == null ) u.FirstName = 'unit';
        if ( u.LastName == null ) u.LastName = uname;
        if ( u.EmailEncodingKey == null ) u.EmailEncodingKey = DEFAULTS.emailEncodingKey;
        if ( u.LanguageLocaleKey == null ) u.LanguageLocaleKey = DEFAULTS.languageLocaleKey;
        if ( u.LocaleSidKey == null ) u.LocaleSidKey = DEFAULTS.localeSidKey;
        if ( u.TimeZoneSidKey == null ) u.TimeZoneSidKey = DEFAULTS.timeZoneSidKey;
        insert u;
        return u;
    }

    // returns list of test users with name prefix np
    public static List<User> getAll( String np ) {
        String n = np + '%' + DOMAIN_SUFFIX;
        return [select Id, LastName, ProfileId from User where Username like :n];
    }

    // returns existing or creates new test user with name prefix np
    public static User get( String np ) {
        String n = np + '%' + DOMAIN_SUFFIX;
        List<User> tu = getAll( np );
        if ( tu.size() >= 1 ) {
            return tu[0];
        }
        return create( np, null );
    }

    // permission set licenses are considered complemental and as such never removed. only added.
    public static void addPermissionSetLicenses( User u, Set<String> licences ) {
        if ( licences <> null && ! licences.isEmpty() ) {
            List<PermissionSetLicense> pls = [select Id from PermissionSetLicense where DeveloperName in :licences];
            List<PermissionSetLicenseAssign> plas = new List<PermissionSetLicenseAssign>();
            for ( PermissionSetLicense pl : pls ) {
                plas.add( new PermissionSetLicenseAssign( AssigneeId = u.Id, PermissionSetLicenseId = pl.Id ) );
            }
            List<Database.SaveResult> srs = Database.insert( plas, false );
            for ( Database.SaveResult sr: srs ) {
                if ( ! sr.isSuccess() ) {
                    System.debug( 'ERROR: inserting permission set licenses: ' + sr );
                }
            }
        }
    }

    // permission sets are considered complemental and as such never removed. only added.
    public static void addPermissionSets( User u, Set<String> perms ) {
        if ( perms <> null && ! perms.isEmpty() ) {
            List<PermissionSetAssignment> psas = new List<PermissionSetAssignment>();
            List<PermissionSet> pss = [select Id from PermissionSet where Name in :perms];
            for ( PermissionSet ps : pss ) {
                psas.add( new PermissionSetAssignment( AssigneeId = u.Id, PermissionSetId = ps.Id ) );
            }
            List<Database.SaveResult> srs = Database.insert( psas, false );
            for ( Database.SaveResult sr: srs ) {
                if ( ! sr.isSuccess() ) {
                    System.debug( 'ERROR: inserting permission sets: ' + sr );
                }
            }
        }
    }

    // test user has its own permission set named as users last name (should be unique)
    // custom permissions are adjusted on that permission set
    // true is returned if permission set should be assigned to the user
    public static Boolean adjustCustomPermissions( User u, Set<String> custom ) {
        if ( custom == null || custom.isEmpty() ) return false;
        List<PermissionSet> ps = [select Id from PermissionSet where Name = :u.LastName];
        if ( ps.isEmpty() ) {
            ps.add( new PermissionSet( Name = u.LastName, Label = u.LastName ) );
            insert ps;
        }
        Set<ID> pids = new Set<ID>();
        for ( CustomPermission cp : [select Id from CustomPermission where DeveloperName in :custom] ) {
            pids.add( cp.Id );
        }
        return adjustCustomPermissions( ps[0].Id, pids, u );
    }

    // aligns custom permissions in pids for permission set psId.
    private static Boolean adjustCustomPermissions( ID psId, Set<ID> pids, User u ) {
        List<SetupEntityAccess> sea2delete = new List<SetupEntityAccess>();
        List<SetupEntityAccess> sea2insert = new List<SetupEntityAccess>();
        for ( SetupEntityAccess a : [select Id, ParentId, SetupEntityId
                                       from SetupEntityAccess
                                      where ParentId = :psId and SetupEntityType = 'CustomPermission'] )
        {
            if ( pids.contains( a.SetupEntityId ) ) {
                pids.remove( a.SetupEntityId );
            } else {
                sea2delete.add( a );
            }
        }
        for ( ID id : pids ) {
            sea2insert.add( new SetupEntityAccess( ParentId = psId, SetupEntityId = id ) );
        }
        delete sea2delete;
        insert sea2insert;

        return ! ( sea2delete.isEmpty() && sea2insert.isEmpty() );
    }

}