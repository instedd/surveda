import * as surveyActions from '../actions/survey'
import * as questionnaireActions from '../actions/questionnaire'

const initialState = {
  updatedAt: null,
  saving: false
}

export default (state = initialState, action) => {
  switch (action.type) {
    case surveyActions.SAVING: return saving(state, action)
    case surveyActions.SAVED: return saved(state, action)
    case surveyActions.RECEIVE: return receive(state, action)
    case questionnaireActions.SAVING: return saving(state, action)
    case questionnaireActions.SAVED: return saved(state, action)
    case questionnaireActions.RECEIVE: return receive(state, action)
    default: return state
  }
}

const saving = (state, action) => {
  return {
    ...state,
    saving: true
  }
}

const receive = (state, action) => {
  return {
    ...state,
    updatedAt: action.data.updatedAt,
    saving: false
  }
}

const saved = (state, action) => {
  return {
    ...state,
    updatedAt: action.data.updatedAt,
    saving: false
  }
}
