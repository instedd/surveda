import * as questionnaireActions from '../actions/questionnaire'
import * as surveyActions from '../actions/survey'
import includes from 'lodash/includes'

export default store => next => action => {
  if (includes(questionnaireActions.AUTOSAVE, action.type)) {
    next(action)
    return store.dispatch(questionnaireActions.save())
  }

  if (includes(surveyActions.AUTOSAVE, action.type)) {
    next(action)
    return store.dispatch(surveyActions.save())
  }

  return next(action)
}
