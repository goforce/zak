// container for zak settings. all settings are string key-value pairs.
// default settings can be overriding by implementing zak_Defaults class extending zak_Settings.Defaults.
public inherited sharing class zak_Settings {

    private static Defaults settings;

    static {
        Type t = Type.forName( 'zak_Defaults' );
        settings = t == null ? new Defaults() : (Defaults) t.newInstance();
    }

    public static String get( String key, String def ) {
        return settings.get( key, def );
    }

    public static String set( String key, String value ) {
        return settings.set( key, value );
    }

    // override Defaults with class named zak_Defaults to initialize default settings from code
    // or custom settings or custom metadata or custom permissions.
    public virtual class Defaults {
        protected Map<String,String> settings = new Map<String,String>();
        // get value of the key. if value is null then return def(ault) value.
        public virtual String get( String key, String def ) {
            String value = settings.get( key );
            return value == null ? def : value;
        }
        // set key to value, return previous value of the key.
        public virtual String set( String key, String value ) {
            return settings.put( key, value );
        }
    }

}