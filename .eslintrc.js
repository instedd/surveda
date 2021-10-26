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
    "space-before-function-paren": [2, {
      anonymous: "never",
      named: "never",
      asyncArrow: "always"
    }],
    "eqeqeq": "off",
    "quotes": [2, "single", {
      avoidEscape: true,
      allowTemplateLiterals: true
    }],
    "react/jsx-uses-react": 1,
    "react/jsx-uses-vars": 1,

    // TODO: eventually enable/fix all the following rules:
    "array-bracket-spacing": "off",
    "dot-notation": "off",
    "indent": "off",
    "multiline-ternary": "off",
    "object-curly-newline": "off",
    "object-curly-spacing": "off",
    "prefer-const": "off",
    "quote-props": "off",

    "no-case-declarations": "off",
    "no-mixed-operators": "off",
    "no-prototype-builtins": "off",
    "no-use-before-define": "off",
    "no-useless-return": "off",
    "no-var": "off",
    "prefer-promise-reject-errors": "off",

    "react/no-unused-prop-types": "off",

    "flowtype/no-types-missing-file-annotation": "off",
  },
  env: {
    "browser": true
  }
}
