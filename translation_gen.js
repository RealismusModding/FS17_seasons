const xmlbuilder = require("xmlbuilder");
const _map = require("lodash.map");
const _ = require("lodash");
const fs = require("fs");
const path = require("path");
const xml2js = require("xml2js");
const Promise = require("bluebird");

//////////////////////////////////////////
// Library
//////////////////////////////////////////

function pp(obj) {
    console.log(JSON.stringify(obj, null, 2));
}

function createXML(data, language) {
    if (!data[language]) {
        data[language] = {
            translations: {},
            contributors: []
        }
    }

    // Go over the english data as it is leading
    const xmlTexts = _.reduce(data["en"].translations, (result, value, key) => {
        const trValue = data[language].translations[key];

        if (language != "en" && !trValue) {
            result.push({
                "#comment": `Missing translation of "${data["en"].translations[key]}."`
            });
        }

        result.push({
            "text": {
                "@name": key,
                "@text": !!trValue ? trValue : ""
            }
        })

        return result
    }, []);

    const xmlHeader = {
        version: "1.0",
        encoding: "utf-8",
        standalone: false
    };

    const xmlOptions = {
        stringify: {
            convertCommentKey: "#comment"
        }
    };

    const root = xmlbuilder.create("l10n", xmlHeader, {}, xmlOptions);

    root.ele("translationContributors", {}, data[language].contributors.join(", "));
    root.ele("texts").ele(xmlTexts)

    return Promise.resolve(root.end({
        pretty: true,
        indent: "    "
    }));
}

function pathForTranslation(language, test) {
    return path.join(".", "translations", `translation_${language}${test ? "_t" : ""}.xml`)
}

function readXML(path) {
    return new Promise((resolve, reject) => {
        fs.readFile(path, { encoding: "utf8" }, (err, data) => {
            if (err) {
                return reject(err);
            }

            xml2js.parseString(data, (err, data) => {
                if (err) {
                    return reject(err);
                }

                resolve(data)
            });
        });
    });
}

function loadXML(language) {
    if (!fs.existsSync(pathForTranslation(language))) {
        return Promise.resolve();
    }

    return readXML(pathForTranslation(language)).then((xml) => {
        // pp(xml)
        console.log(`Read XML file for '${language}'`)

        let data = {
            translations: {},
            contributors: []
        }

        if (!xml.l10n) {
            return data;
        }

        // Read the contributors text value (item 0)
        let contribs = _.get(xml, "l10n.translationContributors", [""])[0];
        data.contributors = _.map(contribs.split(","), _.trim);

        let items = _.get(xml, "l10n.texts.0.text");
        data.translations = _.reduce(items, (result, value) => {
            if (_.has(value, "$.name")) {
                result[_.get(value, "$.name")] = _.get(value, "$.text", "");
            }

            return result;
        }, {})

        return data;
    })
}

function writeXML(xml, path) {
    return new Promise((resolve, reject) => {
        fs.writeFile(path, xml, { encoding: "utf8" }, (err) => {
            if (err) {
                return reject(err);
            }

            resolve();
        });
    });
}

//////////////////////////////////////////
// Program
//////////////////////////////////////////

function main(args) {
    const languages = ["cz", "de", "en", "es", "fr", "it", "nl", "pl", "ru", "se", "no"];

    // Reading XML
    Promise.reduce(languages, (result, language) => {
        return loadXML(language).then((data) => {
            result[language] = data;

            return result;
        });
    }, {})

    .then((data) => Promise.map(languages, (language) => {
        if (language == "en") {
            return Promise.resolve();
        }

        const path = pathForTranslation(language);

        return createXML(data, language).then((xml) => {
            console.log(`Writing XML file for '${language}'`);

            return writeXML(xml, path);
        });
    }))

    .then(() => {
        console.log("Finished!");
    })

    .catch((err) => {
        console.log("Error", err);
    })
}

main(process.argv)
