import * as actions from "../actions/guest"
import Crypto from "crypto"

const initialState = {
  data: {
    email: "",
    level: "",
    code: "",
  },
  errors: {},
}

export default (state = initialState, action) => {
  switch (action.type) {
    case actions.CHANGE_EMAIL:
      return changeEmail(state, action)
    case actions.CHANGE_LEVEL:
      return changeLevel(state, action)
    case actions.GENERATE_CODE:
      return generateCode(state, action)
    case actions.SET_CODE:
      return setCode(state, action)
    case actions.CLEAR:
      return clear()
    default:
      return state
  }
}

const validEmail = (email) => {
  return /^[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?$/.test(
    email
  )
}

const changeEmail = (state, action) => {
  return {
    ...state,
    data: {
      ...state.data,
      email: action.email,
    },
    errors: {
      ...state.errors,
      email: !validEmail(action.email),
    },
  }
}

const changeLevel = (state, action) => {
  if (["admin", "editor", "reader"].includes(action.level)) {
    return {
      ...state,
      data: {
        ...state.data,
        level: action.level,
      },
    }
  } else {
    return state
  }
}

const setCode = (state, action) => {
  return {
    ...state,
    data: {
      ...state.data,
      action: action.code,
    },
  }
}

const generateCode = (state, action) => {
  if (state.data.email && validEmail(state.data.email) && state.data.level && !state.data.code) {
    const code = Crypto.randomBytes(20).toString("hex")
    return {
      ...state,
      data: {
        ...state.data,
        code: code,
      },
    }
  } else {
    return {
      ...state,
    }
  }
}

const clear = () => {
  return initialState
}
