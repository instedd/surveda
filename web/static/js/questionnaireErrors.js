// @flow
import some from 'lodash/some'
import startsWith from 'lodash/startsWith'

export const hasErrorsInPrefix = (errors: ValidationError[], prefix: string) => {
  return some(errors, error => startsWith(error.path, prefix))
}
