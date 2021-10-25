module.exports = {
  extends: [
    "standard",
    // "standard-jsx",
    "standard-react",
    "plugin:flowtype/recommended"
  ],
  parser: "@babel/eslint-parser",
  parserOptions: {
    ecmaFeatures: {
      "jsx": true
    }
  },
  plugins: [
    "flowtype",
    "import",
    "node",
    "promise",
    "react"
  ],
  globals: {
    "$": true
  },
  rules: {
    "space-before-function-paren": [2, "never"],
    "eqeqeq": "off",
    "react/jsx-uses-react": 1,
    "react/jsx-uses-vars": 1
  },
  env: {
    "browser": true
  }
}
