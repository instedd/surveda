import { combineReducers }  from 'redux'
import * as actions from '../actions/surveys'
import merge from 'lodash/merge'
import union from 'lodash/union'

export default (state = {}, action) => {
  switch (action.type) {
    case actions.CREATE_SURVEY:
    case actions.UPDATE_SURVEY:
      return {
        ...state,
        [action.id]: {
          ...action.survey
        }
      }
    case actions.FETCH_SURVEYS_SUCCESS:
    default:
      if (action.response && action.response.entities) {
        return merge({}, state, action.response.entities.surveys)
      }
      return state
  }
}

// const ids = (state = [], action) => {
//     switch (action.type) {
//       case actions.CREATE_SURVEY:
//         return [...state, action.id]
//       case actions.FETCH_SURVEYS_SUCCESS:
//         return union(state, action.response.result)
//       case actions.UPDATE_SURVEY:
//       default:
//         return state
//     }
//   }

// export default combineReducers({
//   // ids,
//   surveys
// });
