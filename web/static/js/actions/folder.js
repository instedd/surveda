import * as api from '../api'

export const CREATE_FOLDER = 'FOLDER_CREATE'
export const SAVING_FOLDER = 'FOLDER_SAVING'
export const SAVED_FOLDER = 'FOLDER_SAVED'

export const createFolder = (projectId: number, name: string) => (dispatch: Function) => {
  dispatch(savingFolder())
  return api.fetchSurvey(projectId, name)
    .then(response => {
      dispatch(savedFolder())
    })
}

export const savingFolder = (projectId: number) => {
  return {
    type: SAVING_FOLDER
  }
}

export const savedFolder = (projectId: number) => {
  return {
    type: SAVED_FOLDER
  }
}