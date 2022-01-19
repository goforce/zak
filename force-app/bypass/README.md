zak_Bypass is used to provide granular and hierarchical bypass mechanism for automations.

### example

in apex trigger on Case sobject:
```
if ( zak_Bypass.isEnabled( 'services.case.validatesource' ) {
    ...
}
```
validation can be bypassed by:
-  calling `zak_Bypass.add( 'services.case.validatesource' )` somewhere before Case trigger is invoked;
-  mapping custom permission or custom settings (zak_Bypass__c) in custom metadata (zak_BypassMapping__mdt).

### details

Bypass key is dot (.) separated list of names. One or more segments can be replaced with star (\*) which would match combination.
For example, `*.case.*` would bypass all case related automations.

Bypasses can be mapped using zak_BypassMapping__mdt custom metadata. It could be mapped out-of-box to custom permissions (by name)
or zak_Bypass__c custom settings.

Recommended (but not limiting) sequence of segments: domain.sobject.action.

### methods

##### `public static List<Boolean> isEnabled( List<String> paths )`
variant of isEnabled exposed as invocable method to be used in flows. labeled Is Bypass Enabled in category Platform.

##### `public static Boolean isEnabled( String path )`
returns true if path can by bypassed.

##### `public static Boolean add( String path )`
adds path to be bypassed. returns true if path already was added before. if any of segments is empty then false is returned and no path added.

##### `public static Boolean remove( String path )`
removes path from to be bypassed. returns true if it was set to be bypassed.
