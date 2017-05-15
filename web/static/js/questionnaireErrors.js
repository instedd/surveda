// @flow
import some from 'lodash/some'
import startsWith from 'lodash/startsWith'

export const hasErrorsInPrefixWithLanguage = (errors: ValidationError[], prefix: string, language: ?string) => {
  return some(errors, error => error.lang == language && startsWith(error.path, prefix))
}
