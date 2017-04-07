exports.config = {
  // See http://brunch.io/#documentation for docs.
  files: {
    javascripts: {
      joinTo: {
        'js/app.js': /^(web\/static\/js)|(web\/static\/vendor)|(node_modules)|(deps)/,
        'js/mobileSurvey.js': /^(web\/static\/mobile_survey\/js)|(node_modules\/process.*)|(node_modules\/react\/)|(node_modules\/react-dom)|(node_modules\/object-assign)|(node_modules\/fbjs)|(node_modules\/isomorphic-fetch)|(node_modules\/invariant)|(node_modules\/hoist-non-react-statics)|(node_modules\/symbol-observable)|(node_modules\/lodash)|(node_modules\/redux\/)|(node_modules\/react-redux\/)|(node_modules\/whatwg-fetch)|(node_modules\/react-router)|(node_modules\/react-router\/lib)|(node_modules\/react-router-redux)|(node_modules\/react-router-redux\/lib)/
      }

      // To use a separate vendor.js bundle, specify two files path
      // http://brunch.io/docs/config#-files-
      // joinTo: {
      //  "js/app.js": /^(web\/static\/js)/,
      //  "js/vendor.js": /^(web\/static\/vendor)|(deps)/
      // }
      //
      // To change the order of concatenation of files, explicitly mention here
      // order: {
      //   before: [
      //     "web/static/vendor/js/jquery-2.1.1.js",
      //     "web/static/vendor/js/bootstrap.min.js"
      //   ]
      // }
    },
    stylesheets: {
      joinTo: {
        'css/app.css': /^(web\/static\/css)|(web\/static\/vendor\/css)/,
        'css/mobileSurvey.css': /^(web\/static\/mobile_survey\/css)/
      },
      order: {
        after: ['web/static/css/app.css'] // concat app.css last
      }
    },
    templates: {
      joinTo: 'js/app.js'
    }
  },

  conventions: {
    // This option sets where we should place non-css and non-js assets in.
    // By default, we set this to "/web/static/assets". Files in this directory
    // will be copied to `paths.public`, which is "priv/static" by default.
    assets: /^(web\/static\/assets)/
  },

  // Phoenix paths configuration
  paths: {
    // Dependencies and current project directories to watch
    watched: [
      'web/static',
      'test/static'
    ],

    // Where to compile files to
    public: 'priv/static'
  },

  // Configure your plugins
  plugins: {
    babel: {
      presets: ['es2015', 'stage-0', 'react'],
      plugins: ['transform-object-rest-spread'],
      // Do not use ES6 compiler in vendor code
      ignore: [/web\/static\/vendor/]
    },
    sass: {
      options: {
        includePaths: ['web/static/vendor/css']
      }
    }
  },

  modules: {
    autoRequire: {
      'js/app.js': ['web/static/js/app'],
      'js/mobileSurvey.js': ['web/static/mobile_survey/js/mobileSurvey']
    }
  },

  npm: {
    enabled: true
  },

  overrides: {
    production: {
      sourceMaps: true
    }
  }
}
