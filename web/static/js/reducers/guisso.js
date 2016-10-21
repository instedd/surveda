import * as actions from '../actions/guisso'

export default (state = {}, action) => {
  switch (action.type) {
    case actions.GUISSO_TOKEN:
      return {
        ...state,
        [action.app]: {
          ...action.token
        }
      }
    default:
      return state
  }
}
