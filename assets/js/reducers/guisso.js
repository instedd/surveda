import * as actions from "../actions/guisso"

export default (state = {}, action) => {
  switch (action.type) {
    case actions.GUISSO_TOKEN:
      return guissoToken(state, action)
    default:
      return state
  }
}

const guissoToken = (state, action) => ({
  ...state,
  [action.app]: {
    ...action.token,
  },
})
