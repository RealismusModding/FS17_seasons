const fs = require("fs")
const path = require("path")

const gulp = require("gulp");
const gutil = require("gulp-util");
const ftp = require("vinyl-ftp");
const zip = require("gulp-zip");
const rename = require("gulp-rename");
const size = require("gulp-size");
const template = require("gulp-template");
const xmlpoke = require("gulp-xmlpoke");
const merge = require("merge-stream");
const git = require("git-rev-sync");
const run = require("gulp-run");
const del = require("del");

const _defaults = require("lodash.defaultsdeep")
const _has = require("lodash.has")
const _get = require("lodash.get")

/////////////////////////////////////////////////////
/// Functions
/////////////////////////////////////////////////////

function toLuaString(value) {
    return `"${value.toString()}"`;
}

/**
 * Add updated values to the modDesc
 * @return {Vinyl} Stream containing updated modDesc
 */
function fillModDesc() {
    const replacements = [{
        xpath: "/modDesc/version",
        value: packageVersion
    }, {
        xpath: "/modDesc/@descVersion",
        value: package.fs.modDescRev
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
        debug: buildConfig.get("options.debug", false).toString(),
        verbose: buildConfig.get("options.verbose", false).toString(),
        buildnumber: toLuaString(versionName)
    };

    return gulp
        .src("src/*.lua", { base: "." })
        .pipe(template(replacements, options));
}

function createVersionName() {
    const short = git.short();
    const branch = git.branch();
    const tag = git.tag();

    let versionName = "";
    if (tag !== git.long()) {
        versionName = tag;
    } else {
        versionName = branch + "_" + short;
    }

    // to check if dirty: if so, echos *, otherwise exit -1
    // [[ $(git diff --shortstat 2> /dev/null | tail -n1) != "" ]] && echo "*"

    if (false) {
        versionName += "_wd";
    }

    return versionName;
}

function dediUrl() {
    return `http://${buildConfig.get("server.web.host")}:${buildConfig.get("server.web.port")}/`;
}

function dediStop() {
    const url = dediUrl();
    const command = `curl -X POST -v --cookie "SessionID=${buildConfig.get("server.web.cookie")}" --data "stop_server=Stop" -H "Origin: ${url}" ${url}index.html > /dev/null`;

    return run(command, { silent: true }).exec()
        .pipe(gutil.noop());
}

function dediStart() {
    const url = dediUrl();
    const command = `curl -X POST -v --cookie "SessionID=${buildConfig.get("server.web.cookie")}" --data "game_name=${buildConfig.get("server.game.name")}&admin_password=${buildConfig.get("server.game.adminPassword")}&game_password=${buildConfig.get("server.game.password")}&savegame=${buildConfig.get("server.game.savegame")}&map_start=${buildConfig.get("server.game.mapStart")}&difficulty=2&dirt_interval=2&matchmaking_server=2&mp_language=en&auto_save_interval=180&stats_interval=360&pause_game_if_empty=on&start_server=Start" -H "Origin: ${url}" ${url}index.html > /dev/null`;

    return run(command, { silent: true }).exec()
        .pipe(gutil.noop());
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
        // return _has(this.data, "modsFolder");
        return true;
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
var package = JSON.parse(fs.readFileSync("package.json"));
var packageVersion = package.version + ".0"; // npm wants 3, modhub wants 4 items. Last one could be build number.
const versionName = createVersionName()
var outputZipName = `FS17_seasons_${versionName}.zip`;

console.log("packageVersion",packageVersion,"output",outputZipName)


gulp.task("clean:zip", () => {
    return del("FS17_seasons*.zip");
});

gulp.task("clean:mods", () => {
    return del(path.join(buildConfig.get("modsFolder"), "FS17_seasons*.zip"), { force: true });
});

// Build the mod zipfile
gulp.task("build", () => {
    const sources = [
        "translations/translation_*.xml",
        "data/**/*",
        "resources/**/*",
        "icon.dds",
        "CREDITS.txt"
    ];

    let sourceStream = gulp.src(sources, { base: "." });

    return merge(sourceStream, fillModDesc(), templatedLua())
        .pipe(size())
        .pipe(zip(outputZipName))
        .pipe(size())
        .pipe(gulp.dest("."));
});

// Install locally in the mods folder of the developer
gulp.task("install", ["build", "clean:mods"], () => {
    return gulp
        .src(outputZipName, { base: "." })
        .pipe(rename("FS17_seasons.zip"))
        .pipe(gulp.dest(buildConfig.get("modsFolder")));
});

/**
 * Stop the dedicated server.
 */
gulp.task("server:stop", dediStop);

/**
 * Start the dedicated server.
 */
gulp.task("server:start", dediStart);

gulp.task("server:log", () => {
    const url = dediUrl();
    const command = `curl -X GET -v --cookie "SessionID=${buildConfig.get("server.web.cookie")}" -H "Origin: ${url}" ${url}logs.html?lang=en`;

    return run(command, { silent: true }).exec()
        .pipe(gulp.dest("log"));
});

/**
 * First step in installing on a dedicated server: stopping the server.
 * A requirement for dedis is that the server mod is the same as the client mod,
 * that is why the mod is rebuild and installed to the client as well.
 */
gulp.task("ir:1", ["install"], dediStop);

/**
 * Second step is uploading the mod. The server had to be shut down because otherwise
 * the old version is busy and can't be changed.
 */
gulp.task("ir:2", ["ir:1"], () => {
    const conn = new ftp({
        host: buildConfig.get("server.ftp.host"),
        port: buildConfig.get("server.ftp.port", 21),
        user: buildConfig.get("server.ftp.user"),
        pass: buildConfig.get("server.ftp.password")
    });

    return gulp
        .src(outputZipName, { buffer: false })
        .pipe(rename("FS17_seasons.zip"))
        .pipe(conn.dest(buildConfig.get("server.ftp.path")))
        .pipe(gutil.noop());
});

/**
 * Install the mod locally and on a remote dedicated server.
 *
 * Using dependencies for serial async steps. Final step is
 * starting the server again.
 */
gulp.task("server:install", ["ir:2"], dediStart);

gulp.task("default", ["build"]);

/*


curl -T FS17_seasons.zip ftp://$FTPUSER:$FTPPASS@ftp-3.verygames.net/games/FarmingSimulator17/mods/



translationsMissing
translationBloat
style -> luacheck

installRemote
watch/develop

 */
