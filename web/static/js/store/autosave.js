import * as questionnaireActions from '../actions/questionnaire'
import includes from 'lodash/includes'

export default store => next => action => {
  if (includes(questionnaireActions.AUTOSAVE, action.type)) {
    next(action)
    return store.dispatch(questionnaireActions.save())
  }

  return next(action)
}
