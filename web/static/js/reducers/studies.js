import { combineReducers }  from 'redux'
import * as actions  from '../actions'
import merge from 'lodash/merge'
import union from 'lodash/union'

const studies = (state = {}, action) => {
  switch (action.type) {
    case actions.ADD_STUDY:
    case actions.FETCH_STUDIES_SUCCESS:
      if (action.response && action.response.entities) {
        return merge({}, state, action.response.entities.studies)
      } else {
        return state
      }
    default:
      return state
  }
}

const ids = (state = [], action) => {
    switch (action.type) {
      case actions.ADD_STUDY:
      case actions.FETCH_STUDIES_SUCCESS:
        return union(state.ids, action.response.result)
      default:
        return state
    }
  }

export default combineReducers({
  ids,
  studies
});
