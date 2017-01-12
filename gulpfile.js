const gulp = require("gulp")

gulp.task("build", () => {
    return gulp.src("CREDITS.md")
        .pipe(gulp.dest("CREDITS2.md"))
});

gulp.task("default", ["build"]);
