export const RECEIVE = 'AUTOSAVE_RECEIVE'
export const SAVED = 'AUTOSAVE_SAVED'
export const SAVING = 'AUTOSAVE_SAVING'
export const ERROR = 'AUTOSAVE_ERROR'

export const receive = (entity) => ({
  type: RECEIVE,
  data: entity
})

export const saved = (entity) => ({
  type: SAVED,
  data: entity
})

export const saving = () => ({
  type: SAVING
})

export const error = () => ({
  type: ERROR
})
