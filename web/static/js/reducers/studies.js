import { combineReducers }  from 'redux'
import * as actions  from '../actions'
import merge from 'lodash/merge'
import union from 'lodash/union'

const studies = (state = {}, action) => {
  switch (action.type) {
    case actions.CREATE_STUDY:
      return {
        ...state,
        [action.id]: {
          ...action.study
        }
      }
    case actions.FETCH_STUDIES_SUCCESS:
    default:
      if (action.response && action.response.entities) {
        return merge({}, state, action.response.entities.studies)
      }
      return state
  }
}

const ids = (state = [], action) => {
    switch (action.type) {
      case actions.CREATE_STUDY:
        return [...state, action.id]
      case actions.FETCH_STUDIES_SUCCESS:
        return union(state, action.response.result)
      default:
        return state
    }
  }

export default combineReducers({
  ids,
  studies
});
