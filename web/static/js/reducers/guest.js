import * as actions from '../actions/guest'
import Crypto from 'crypto'

const initialState = {
  data: {
    email: '',
    level: '',
    code: ''
  }
}

export const reducer = (state = initialState, action) => {
  switch (action.type) {
    case actions.CHANGE_EMAIL: return changeEmail(state, action)
    case actions.CHANGE_LEVEL: return changeLevel(state, action)
    case actions.GENERATE_CODE: return generateCode(state, action)
    case actions.SET_CODE: return setCode(state, action)
    case actions.CLEAR: return clear()
    default: return state
  }
}

const validateReducer = (state) => {
  return (state, action) => {
    const newState = reducer(state, action)
    validate(newState)
    return newState
  }
}

const validate = (state) => {
  state.errors = {}
  validateEmail(state)
}

const validateEmail = (state) => {
  const valid = /^[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?$/.test(state.data.email)
  if (!valid) {
    state.errors = {...state.errors, email: 'invalid email'}
  }
}

export default validateReducer(reducer)

const changeEmail = (state, action) => {
  const newData = {...state.data}
  newData.email = action.email
  return {
    ...state,
    data: newData
  }
}

const changeLevel = (state, action) => {
  if (['reader', 'editor'].includes(action.level)) {
    const newData = {...state.data}
    newData.level = action.level
    return {
      ...state,
      data: newData
    }
  } else {
    return state
  }
}

const setCode = (state, action) => {
  return {
    ...state,
    code: action.code
  }
}

const generateCode = (state, action) => {
  if (state.data.email && state.data.level && !state.data.code) {
    const code = Crypto.randomBytes(20).toString('hex')
    const newData = {...state.data}
    newData.code = code
    return {
      ...state,
      data: newData
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
