import "@typespec/json-schema";
using TypeSpec.JsonSchema;

@jsonSchema("/modules/set-plymouth-theme.json")
model InstallAdi1090xPlymouthThemeModule {
    /** This module will set the plymouth theme along with installing necessary fedora packages to do it
     * https://blue-build.org/reference/modules/install-adi1090x-plymouth-theme/
     */
    type: "set-plymouth-theme";

    /** theme name */
    theme: string;
}