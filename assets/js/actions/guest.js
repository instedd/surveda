export const CHANGE_EMAIL = "CHANGE_EMAIL"
export const CHANGE_LEVEL = "CHANGE_LEVEL"
export const SET_CODE = "SET_CODE"
export const GENERATE_CODE = "GENERATE_CODE"
export const CLEAR = "CLEAR"

export const changeEmail = (email) => ({
  type: CHANGE_EMAIL,
  email,
})

export const changeLevel = (level) => ({
  type: CHANGE_LEVEL,
  level,
})

export const setCode = (code) => ({
  type: SET_CODE,
  code,
})

export const generateCode = () => ({
  type: GENERATE_CODE,
})

export const clear = () => ({
  type: CLEAR,
})
