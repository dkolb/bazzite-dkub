import "@typespec/json-schema";
using TypeSpec.JsonSchema;

@jsonSchema("/modules/install-adi1090x-plymouth-theme.json")
model InstallAdi1090xPlymouthThemeModule {
    /** The install-adi1090x-plymouth-theme module allows the individual installation of plymouth themes from https://github.com/adi1090x/plymouth-themes
     * https://blue-build.org/reference/modules/install-adi1090x-plymouth-theme/
     */
    type: "install-adi1090x-plymouth-theme";

    /** List of plymouth themes to install (just the name) */
    themes?: Array<string>;
}