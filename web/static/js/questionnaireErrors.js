// @flow
import some from 'lodash/some'
import startsWith from 'lodash/startsWith'

export const hasErrorsInPrefixWithModeAndLanguage = (errors: ValidationError[], prefix: string, mode: string, language: ?string) => {
  return some(errors, error => (error.mode == null || error.mode == mode) && (error.lang == null || error.lang == language) && startsWith(error.path, prefix))
}

export const hasErrorsInModeWithLanguage = (errors: ValidationError[], mode: string, language: string) => {
  return some(errors, error => (error.mode == null || error.mode == mode) && (error.lang == null || error.lang == language))
}

export const hasErrorsInLanguage = (errors: ValidationError[], language: string) => {
  return some(errors, error => error.lang == null || error.lang == language)
}
