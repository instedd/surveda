var webpack = require('webpack')
var path = require('path')
var ExtractTextPlugin = require('extract-text-webpack-plugin')
var CopyWebpackPlugin = require('copy-webpack-plugin')
const i18nextWebpackPlugin = require('i18next-scanner-webpack')

module.exports = {
  resolve: {
    modules: [
      'node_modules',
      path.join(__dirname, '/assets/js')
    ],
    extensions: ['.js', '.jsx']
  },
  entry: {
    app: [
      './assets/vendor/js/materialize.js',
      './assets/vendor/js/materialize-dropdown-fix.js',
      './assets/js/app.jsx',
      './assets/css/app.scss'
    ],
    mobileSurvey: [
      './assets/mobile_survey/js/mobileSurvey.jsx',
      './assets/mobile_survey/css/mobile.scss'
    ]
  },

  output: {
    path: path.join(__dirname, '/priv/static'),
    filename: 'js/[name].js'
  },

  module: {
    rules: [
      {
        test: /\.(js|jsx)$/,
        exclude: [
          /node_modules/,
          /static\/vendor/
        ],
        use: {
          loader: 'babel-loader'
        }
      },
      {
        test: /\.css$/,
        use: ExtractTextPlugin.extract({use: 'css-loader'})
      },
      {
        test: /\.scss$/,
        use: ExtractTextPlugin.extract({
          use: [
            {
              loader: 'css-loader',
              options: {
                url: false
              }
            },
            {
              loader: 'sass-loader?sourceMap',
              options: {
                includePaths: [
                  path.join(__dirname, '/assets/vendor/css'),
                  path.join(__dirname, '/node_modules')
                ]
              }
            }
          ]
        })
      },
      {
        test: require.resolve('jquery'),
        use: [{
          loader: 'expose-loader',
          options: '$'
        }]
      }
    ]
  },

  devtool: 'cheap-module-source-map',

  plugins: [
    new i18nextWebpackPlugin({ // eslint-disable-line
      src: path.resolve(__dirname, './assets/js/**/*.{js,jsx}'),
      dest: path.resolve(__dirname, 'locales'),
      options: {
        func: {
          list: ['i18next.t', 'i18n.t', 't', 'k'],
          extensions: ['.js', '.jsx']
        },
        trans: {
          component: 'Trans',
          i18nKey: 'i18nKey',
          extensions: ['.js', '.jsx'],
          fallbackKey: function(ns, value) {
            return value
          }
        },
        defaultLng: 'template',
        defaultValue: '',
        sort: true,
        keySeparator: false,
        nsSeparator: false,
        lngs: ['template'],
        interpolation: {
          prefix: '{{',
          suffix: '}}'
        },
        resource: {
          savePath: '{{lng}}/{{ns}}.json'
        }
      }
    }),
    new ExtractTextPlugin('css/[name].css'),
    new CopyWebpackPlugin([{ from: './assets/static' }]),
    new webpack.ProvidePlugin({
      'window.jQuery': 'jquery',
      'window.$': 'jquery',
      jQuery: 'jquery',
      $: 'jquery'
    })
  ]
}
