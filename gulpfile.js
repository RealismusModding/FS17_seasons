const gulp = require("gulp");
const gutil = require("gulp-util");
const ftp = require("gulp-ftp");
const zip = require("gulp-zip");
const size = require("gulp-size");
const clean = require("gulp-clean");
const template = require("gulp-template");
const xmlpoke = require("gulp-xmlpoke");
const _defaults = require("lodash.defaults")
const merge = require("merge-stream")

const c_outZipName = "FS17_seasons.zip";
const c_version = "1.0.0.0" // TODO: make this the package.json version + some number
const c_descVersion = "33"

/////////////////////////////////////////////////////
/// Functions
/////////////////////////////////////////////////////

/**
 * Add updated values to the modDesc
 * @return {Vinyl} Stream containing updated modDesc
 */
function fillModDesc() {
    const replacements = [{
        xpath: "/modDesc/version",
        value: c_version
    }, {
        xpath: "/modDesc/@descVersion",
        value: c_descVersion
    }];

    return gulp
        .src("modDesc.xml")
        .pipe(xmlpoke({replacements: replacements}));
}

function checkIfBuildRcExists() {

}

function readBuildRCProperties() {

}

/////////////////////////////////////////////////////
/// Tasks
/////////////////////////////////////////////////////

gulp.task("clean:zip", () => {
    return del(c_outZipName);
});

// Build the mod zipfile
gulp.task("build", () => {
    const sources = [
        "src/*.lua",
        "translations/translation_*.xml",
        "data/**/*",
        "resources/**/*",
        "icon.dds",
        "CREDITS.md"
    ];

    let sourceStream = gulp.src(sources, { base: "." });

    return merge(sourceStream, fillModDesc())
        .pipe(size())
        .pipe(zip(c_outZipName))
        .pipe(size())
        .pipe(gulp.dest("."));
});

// Install locally in the mods folder of the developer
gulp.task("install", ["build"], () => {

});

// Install on the remote server. Hashes must be the same so also install locally
gulp.task("installRemote", ["install"], () => {

});

gulp.task("default", ["build"]);

/*

rm -f ../mods/FS17_seasons.zip

echo "Copying new mod..."
cp FS17_seasons.zip ../mods/



translationsMissing
translationBloat
style -> luacheck

install
installRemote
watch/develop

 */


/*

gulp.task('default', function () {
    return gulp.src('src/*')
        .pipe(ftp({
            host: 'website.com',
            user: 'johndoe',
            pass: '1234'
        }))
        // you need to have some kind of stream after gulp-ftp to make sure it's flushed
        // this can be a gulp plugin, gulp.dest, or any kind of stream
        // here we use a passthrough stream
        .pipe(gutil.noop());
});

 */
