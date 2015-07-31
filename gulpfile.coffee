#!/usr/bin/env coffee

# region header

camelize = require 'camelize'
gulpPlugins = require('gulp-load-plugins')()
for pluginName in ['gulp', 'streamqueue', 'developmentServer']
    global[camelize pluginName] = require pluginName

errorHandler = (error) ->
    # Output an error message
    gulpPlugins.util.log gulpPlugins.util.colors.red(
        'Error (' + error.plugin + '): ' + error.message)
    # Emit the end event, to properly end the task.
    this.emit 'end'
gulpSource = ->
    gulp.src.apply(gulp, arguments)
    .pipe gulpPlugins.plumber errorHandler

# endregion

# region configuration

loadConfiguration = (debugBuild=true, rootPath='./', buildPath='./build') ->
    configuration =
        rootPath: rootPath, debugBuild: debugBuild, buildPath: buildPath
        jade: compile_debug: false, debug: false, pretty: debugBuild
        coffee: {}
        htmlMinifier:
            caseSensitive: false, collapseBooleanAttributes: true
            collapseWhitespace: false, conservativeCollapse: true
            keepClosingSlash: false, minifyCSS: true, minifyJS: true
            minifyURLs: true, preserveLineBreaks: true
            preventAttributesEscaping: false, removeAttributeQuotes: true
            removeCDATASectionsFromCDATA: true, removeComments: true
            removeCommentsFromCDATA: true, removeEmptyAttributes: true
            removeEmptyElements: false, removeIgnored: true
            removeOptionalTags: true, removeRedundantAttributes: true
            removeScriptTypeAttributes: true
            removeStyleLinkTypeAttributes: true, useShortDoctype: true
        prettyData: preserve_comments: false, type: 'minify'
        uglify:
            compress:
                booleans: true, cascade: true, comparisons: true
                conditionals: true, dead_code: true, drop_debugger: true
                evaluate: true, global_defs: {}, hoist_funs: true, loops: true
                hoist_vars: false, if_return: true, join_vars: true
                properties: true, sequences: true, side_effects: true
                unsafe: false, unused: true, warnings: false
            mangle: true
        minifyCss:
            advanced: true, aggressive_merging: true, compatibility: 'ie8'
            keep_breaks: false, keep_special_comments: 0, media_merging: true
            process_import: true, restructuring: true, rounding_precision: -1
            shorthand_compacting: true, relative_to: buildPath
            target: rootPath
        imagemin: multipass: true, optimization_level: 7
        sass: paths: [rootPath]
        less: paths: [rootPath]
        hash:
            src_path: rootPath, build_dir: buildPath, verbose: true
            query_name: 'md5', hash: 'md5', exts: [
                '.jpg', '.jpeg', '.png', '.svg', '.ico', '.gif', '.tiff'
                '.bmp', '.webp', '.midi', '.mpeg', '.ogg', '.m4a', '.webm'
                '.3gpp', '.mp2t', '.mp4', '.mpeg', '.mov', '.qt', '.flv'
                '.m4v', '.mng', '.asf', '.wmv', '.woff', '.woff2', '.eot'
                '.ttf', '.java', '.zip', '.rar', '.7z', '.txt', '.html', '.css'
                '.pdf', '.rtf', '.ps', '.doc', '.docx', '.js', '.pl', '.py'
                '.xml', '.csv', '.json', '.kml'
            ]
        simpleAssetTypeNames: ['image', 'font']
        assetLocation:
            cascadingStyleSheet: []
            sass: []
            less: ['less/main.less']
            javaScript: [
                'javaScript/jQuery/jquery-2.1.1.js'
                'javaScript/jQuery/jquery-observeHashChange-1.0.js'
                'javaScript/jQuery/jquery-scrollTo-2.1.0.js'
                'javaScript/jQuery/jquery-spin-2.0.1.js'
            ]
            coffeeScript: [
                'coffeeScript/jQuery/jquery-tools-1.0.coffee'
                'coffeeScript/jQuery/jquery-lang-1.0.coffee'
                'coffeeScript/jQuery/jquery-website-1.0.coffee'
                'coffeeScript/jQuery/jquery-documentation-1.0.coffee'
                'coffeeScript/main.coffee'
            ]
            jade: ['*.jade']
            html: ['*.html']
            data: ['data/**/*.@(json|xml)']
            image: ['image/**']
            font: ['font/**']
        developmentServer:
            connectModrewrite: ['^/?favicon.ico$ /image/favicon.ico']
            getResourcePipelines: (errorHandler, addWatcher) -> [
                {
                    url: /.*\.tpl$/
                    mimeType: 'text/plain'
                }
                {
                    url: /.*\.jade$/
                    mimeType: 'text/html'
                    pipeline: (files) -> jade(
                        files.pipe gulpPlugins.plumber errorHandler)
                }
                {
                    url: /.*\.(scss|sass)$/
                    mimeType: 'text/css'
                    pipeline: (files) -> sass(
                        files.pipe gulpPlugins.plumber errorHandler)
                }
                {
                    url: /.*\.less$/
                    mimeType: 'text/css'
                    pipeline: (files) -> less(
                        files.pipe gulpPlugins.plumber errorHandler)
                }
                {
                    url: /.*\.coffee$/
                    mimeType: 'text/js'
                    pipeline: (files) -> coffeeScript(
                        files.pipe gulpPlugins.plumber errorHandler)
                }
                {
                    url: /(?:^|.*\/)main\.js$/
                    pipeline: (files) ->
                        ### TODO should support globs.
                        addWatcher(
                            CONFIGURATION.assetLocation.javaScript.concat(
                                CONFIGURATION.assetLocation.coffeeScript))###
                        toJavaScript()
                }
                {
                    url: /(?:^|.*\/)main\.css$/
                    pipeline: (files) ->
                        ### TODO should support globs.
                        addWatcher(
                            CONFIGURATION.assetLocation.cascadingStyleSheet
                            .concat(
                                CONFIGURATION.assetLocation.sass
                                CONFIGURATION.assetLocation.less))###
                        toCascadingStyleSheet()
                }
            ]
    configuration.hashHTML = configuration.hash
    configuration.hashHTML.regex = ///
        (href|src)\s*=\s*(?:
            (")([^"]*)
            |
            (')([^']*)
            |
            ([^'"\s>]+)
        )
        |
        url\s*\((
            ?:(")([^"]+)
            |
            (')([^']+)
            |
            ([^'"\)]+)
        )
        |
        (["']?templateurl["']?:\s*["'])([^"']+)
    ///ig
    configuration.hashHTML.analyze = (match) ->
        quote = match[2] or match[4] or match[7] or match[9] or ''
        link = match[3] or match[5] or match[6]
        if link
            # "href" or "src" match
            return {
                prefix: "#{match[1]}=#{quote}"
                link: link
                suffix: ''
            }
        if match[12] and match[13]
            # "templateUrl" match
            return {
                prefix: match[12]
                link: match[13]
                suffix: ''
            }
        # css matches are implemented as fallback
        return {
            prefix: "url(#{quote}"
            link: match[8] or match[10] or match[11]
            suffix: ''
        }
    configuration
global.CONFIGURATION = loadConfiguration()

# endregion

# region converter

html = (source) ->
    (if Object.prototype.toString.call(
        source
    ) is '[object Object]' then source else gulpSource source)
jade = (source) ->
    (if Object.prototype.toString.call(
        source
    ) is '[object Object]' then source else gulpSource source)
    .pipe gulpPlugins.jade CONFIGURATION.jade
cascadingStyleSheet = (source) ->
    (if Object.prototype.toString.call(
        source
    ) is '[object Object]' then source else gulpSource source)
sass = (source) ->
    (if Object.prototype.toString.call(
        source
    ) is '[object Object]' then source else gulpSource source)
    .pipe(gulpPlugins.sass CONFIGURATION.sass)
less = (source) ->
    (if Object.prototype.toString.call(
        source
    ) is '[object Object]' then source else gulpSource source)
    .pipe gulpPlugins.less CONFIGURATION.less
javaScript = (source) ->
    (if Object.prototype.toString.call(
        source
    ) is '[object Object]' then source else gulpSource source)
coffeeScript = (source) ->
    (if Object.prototype.toString.call(
        source
    ) is '[object Object]' then source else gulpSource source)
    .pipe gulpPlugins.coffee CONFIGURATION.coffee

# endregion

# region tasks

for simpleAssetTypeName in CONFIGURATION.simpleAssetTypeNames
    functionName = "to#{simpleAssetTypeName.charAt(0).toUpperCase()}" +
        simpleAssetTypeName.substring(1)
    global[functionName] = do (simpleAssetTypeName) -> (destination) ->
        gulpSource(CONFIGURATION.assetLocation[simpleAssetTypeName])
        .pipe(gulpPlugins.size showFiles: true)
        .pipe gulpPlugins.if destination?, gulp.dest(
            destination or CONFIGURATION.rootPath)
    gulp.task simpleAssetTypeName, do (functionName, simpleAssetTypeName) -> ->
        global[functionName] CONFIGURATION.buildPath + simpleAssetTypeName

global.toData = (destination) ->
    gulpSource(CONFIGURATION.assetLocation.data)
    .pipe(gulpPlugins.size showFiles: true)
    .pipe(gulpPlugins.if not CONFIGURATION.debugBuild, gulpPlugins.prettyData(
        CONFIGURATION.prettyData))
    .pipe(gulpPlugins.if not CONFIGURATION.debugBuild, gulpPlugins.replace(
        /^(\)]}',)/, '$1\n'))
    .pipe(gulpPlugins.size showFiles: true)
    .pipe gulpPlugins.if destination?, gulp.dest(
        destination or CONFIGURATION.rootPath)
gulp.task 'data', -> toData CONFIGURATION.buildPath + 'data/'

global.toCascadingStyleSheet = (destination) ->
    streamqueue(
        {objectMode: true}
        cascadingStyleSheet CONFIGURATION.assetLocation.cascadingStyleSheet
        sass CONFIGURATION.assetLocation.sass
        less CONFIGURATION.assetLocation.less
    )
    .on('error', ->)
    .pipe(gulpPlugins.if CONFIGURATION.debugBuild, gulpPlugins.insert.wrap ((
        file
    ) -> "\n/* region file: #{file.path} */\n\n"), '\n\n/* endregion */\n')
    .pipe(gulpPlugins.size showFiles: true)
    .pipe(gulpPlugins.concat 'main.css')
    .pipe(gulpPlugins.size showFiles: true)
    # NOTE: We only process imports first to rebase all images later.

    .pipe(gulpPlugins.if not CONFIGURATION.debugBuild, gulpPlugins.minifyCss(
        CONFIGURATION.minifyCss))
    .pipe(gulpPlugins.hashSrc CONFIGURATION.hash)
    .pipe(gulpPlugins.size showFiles: true)
    .pipe gulpPlugins.if destination?, gulp.dest(
        destination or CONFIGURATION.rootPath)
gulp.task 'cascadingStyleSheet', CONFIGURATION.simpleAssetTypeNames.concat(
    ['data']
), -> toCascadingStyleSheet CONFIGURATION.buildPath + 'cascadingStyleSheet/'

global.toJavaScript = (destination) ->
    streamqueue(
        {objectMode: true}
        javaScript CONFIGURATION.assetLocation.javaScript
        coffeeScript CONFIGURATION.assetLocation.coffeeScript)
    .on('error', ->)
    .pipe(gulpPlugins.if CONFIGURATION.debugBuild, gulpPlugins.insert.wrap ((
        file
    ) -> "\n/* region file: #{file.path} */\n\n"), '\n\n/* endregion */\n')
    .pipe(gulpPlugins.ngAnnotate())
    .pipe(gulpPlugins.size showFiles: true)
    .pipe(gulpPlugins.concat 'main.js')
    .pipe(gulpPlugins.size showFiles: true)
    .pipe(gulpPlugins.if not CONFIGURATION.debugBuild, gulpPlugins.uglify(
        CONFIGURATION.uglify))
    .pipe(gulpPlugins.size showFiles: true)
    .pipe gulpPlugins.if destination?, gulp.dest(
        destination or CONFIGURATION.rootPath)
gulp.task 'javaScript', -> toJavaScript CONFIGURATION.buildPath + 'javaScript/'

global.toHTML = (destination) ->
    streamqueue(
        {objectMode: true}
        html CONFIGURATION.assetLocation.html
        jade CONFIGURATION.assetLocation.jade)
    .on('error', ->)
    .pipe(gulpPlugins.size showFiles: true)
    .pipe(gulpPlugins.if(
        not CONFIGURATION.debugBuild, gulpPlugins.htmlMinifier(
            CONFIGURATION.htmlMinifier)))
    .pipe(gulpPlugins.hashSrc CONFIGURATION.hashHTML)
    .pipe(gulpPlugins.size showFiles: true)
    .pipe gulpPlugins.if destination?, gulp.dest(
        destination or CONFIGURATION.rootPath)
gulp.task 'html', CONFIGURATION.simpleAssetTypeNames.concat([
    'javaScript', 'cascadingStyleSheet', 'data'
]), -> toHTML CONFIGURATION.buildPath

gulp.task 'default', ['html']

gulp.task 'compressImage', ->
    gulpSource(CONFIGURATION.assetLocation.image, base: './')
    .pipe(gulpPlugins.imagemin CONFIGURATION.imagemin)
    .pipe gulp.dest './'

gulp.task 'developmentServer', ->
    global.CONFIGURATION = loadConfiguration(
        true, CONFIGURATION.rootPath, CONFIGURATION.rootPath)
    developmentServer CONFIGURATION.developmentServer

# endregion

# region vim modline

# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:

# endregion
