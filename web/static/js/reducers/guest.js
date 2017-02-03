import * as actions from '../actions/guest'
import Crypto from 'crypto'

const initialState = {
  email: '',
  level: '',
  code: ''
}

export default (state = initialState, action) => {
  switch (action.type) {
    case actions.CHANGE_EMAIL: return changeEmail(state, action)
    case actions.CHANGE_LEVEL: return changeLevel(state, action)
    case actions.GENERATE_CODE: return generateCode(state, action)
    case actions.CLEAR: return clear()
    default: return state
  }
}

const changeEmail = (state, action) => {
  return {
    ...state,
    email: action.email
  }
}

const changeLevel = (state, action) => {
  if (['reader', 'editor'].includes(action.level)) {
    return {
      ...state,
      level: action.level
    }
  } else {
    return state
  }
}

const generateCode = (state, action) => {
  if (state.email && state.level) {
    const code = Crypto.randomBytes(20).toString('hex')
    return {
      ...state,
      code: code
    }
  } else {
    return {
      ...state
    }
  }
}

const clear = () => {
  return initialState
}
