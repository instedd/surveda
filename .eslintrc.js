module.exports = {
  extends: [
    "standard",
    // "standard-jsx",
    "standard-react",
    "plugin:flowtype/recommended",
    "prettier",
  ],
  parser: "@babel/eslint-parser",
  parserOptions: {
    ecmaFeatures: {
      jsx: true,
    },
  },
  plugins: ["flowtype", "import", "node", "promise", "react"],
  globals: {
    $: true,
  },
  rules: {
    eqeqeq: "off",

    // TODO: eventually enable/fix the following rules:
    "dot-notation": "off",
    "prefer-const": "off",
    "no-case-declarations": "off",
    "no-prototype-builtins": "off",
    "no-use-before-define": "off",
    "no-useless-return": "off",
    "no-var": "off",
    "prefer-promise-reject-errors": "off",

    "react/jsx-uses-react": 1,
    "react/jsx-uses-vars": 1,
    "react/no-unused-prop-types": "off",

    "flowtype/no-types-missing-file-annotation": "off",
  },
  env: {
    browser: true,
  },
}
