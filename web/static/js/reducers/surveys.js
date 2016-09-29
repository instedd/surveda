import * as actions from '../actions/surveys'

export default (state = {}, action) => {
  switch (action.type) {
    case actions.SET_SURVEY:
      return {
        ...state,
        [action.id]: {
          ...action.survey
        }
      }
    case actions.RECEIVE_SURVEYS:
      if (action.response && action.response.entities) {
        return action.response.entities.surveys || {}
      }
      return state
    default:
      return state
  }
}
