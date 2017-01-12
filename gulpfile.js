const fs = require("fs")

const gulp = require("gulp");
const gutil = require("gulp-util");
const ftp = require("gulp-ftp");
const zip = require("gulp-zip");
const size = require("gulp-size");
const template = require("gulp-template");
const xmlpoke = require("gulp-xmlpoke");
const merge = require("merge-stream")

const _defaults = require("lodash.defaultsdeep")
const _has = require("lodash.has")
const _get = require("lodash.get")


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

function templatedLua() {
    const options = {
        interpolate: /\-\-<%=([\s\S]+?)%>/g,
        evaluate: undefined,
        escape: undefined
    };

    const replacements = {
        debug: "true",
        verbose: "false",
        buildnumber: "\"037fsh\""
    };

    return gulp
        .src("src/*.lua", { base: "." })
        .pipe(template(replacements, options));
}

/**
 * Class containing the configuration
 */
class BuildConfig {
    constructor() {
        const userData = this.loadFromFile(process.env.HOME + "/.rm_buildrc");
        const projectData = this.loadFromFile(".buildrc");

        this.data = {}
        _defaults(this.data, projectData, userData);

        if (!this.isValid()) {
            throw "Error: build configuration is invalid";
        }
    }

    loadFromFile(filename) {
        try {
            const data = fs.readFileSync(filename);
            return JSON.parse(data);
        } catch (e) {
            return "{}";
        }
    }

    isValid() {
        return _has(this.data, "modsFolder");
    }

    get(path, defaultValue) {
        return _get(this.data, path, defaultValue);
    }

    has(path) {
        return _has(this.data, path);
    }
}

/////////////////////////////////////////////////////
/// Tasks
/////////////////////////////////////////////////////

var buildConfig = new BuildConfig();

gulp.task("clean:zip", () => {
    return del(c_outZipName);
});

// Build the mod zipfile
gulp.task("build", () => {
    const sources = [
        "translations/translation_*.xml",
        "data/**/*",
        "resources/**/*",
        "icon.dds",
        "CREDITS.md"
    ];

    let sourceStream = gulp.src(sources, { base: "." });

    return merge(sourceStream, fillModDesc(), templatedLua())
        .pipe(size())
        .pipe(zip(c_outZipName))
        .pipe(size())
        .pipe(gulp.dest("."));
});

// Install locally in the mods folder of the developer
gulp.task("install", ["build"], () => {
    return gulp
        .src(c_outZipName, { base: "." })
        .pipe(gulp.dest(buildConfig.get("modsFolder")));
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
