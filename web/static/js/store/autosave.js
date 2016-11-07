import * as questionnaireActions from '../actions/questionnaire'
import * as surveyActions from '../actions/survey'

export default store => next => action => {
  const result = next(action)
  const state = store.getState()

  if (state.questionnaire.dirty) {
    return store.dispatch(questionnaireActions.save())
  }

  if (state.survey.dirty) {
    return store.dispatch(surveyActions.save())
  }

  return result
}
