// import { combineReducers }  from 'redux'
import * as actions  from '../actions'

const study = (state, action) => {
  switch (action.type) {
    case actions.ADD_STUDY:
      return action.response
    default:
    return state
  }
}

const studies = (state = [], action) => {
  switch (action.type) {
    case actions.ADD_STUDY:
      return [
        ...state,
        study(undefined, action)
      ]
    // case 'TOGGLE_TODO':
    //   return state.map(t =>
    //     todo(t, action)
    //   )
    case actions.RECEIVE_STUDIES:
      return action.response
    default:
      return state
  }
}

export default studies
