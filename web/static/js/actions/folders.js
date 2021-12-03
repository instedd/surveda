import * as api from '../api'

export const FETCH_FOLDERS = 'FETCH_FOLDERS'
export const RECEIVE_FOLDERS = 'RECEIVE_FOLDERS'
export const CREATE_FOLDER = 'FOLDER_CREATE'
export const DELETE_FOLDER = 'FOLDER_DELETE'
export const SAVING_FOLDER = 'FOLDER_SAVING'
export const NOT_SAVED_FOLDER = 'NOT_SAVED_FOLDER'
export const CREATED_FOLDER = 'FOLDER_CREATED'
export const DELETED_FOLDER = 'FOLDER_DELETED'
export const RENAMED_FOLDER = 'FOLDER_RENAMED'
export const NOT_RENAMED_FOLDER = 'NOT_RENAMED_FOLDER'

export const createFolder = (projectId: number, name: string) => (dispatch: Function) => {
  dispatch(savingFolder())
  return api.createFolder(projectId, name)
    .then(res => {
      const { projectId, id, name } = res.entities.folders[res.result]
      dispatch(createdFolder(projectId, id, name))
      return { error: false }
    })
    .catch(async res => {
      const err = await res.json()
      dispatch(notSavedFolder(`Name ${err.errors.name[0]}`))
      return { error: true }
    })
}

export const renameFolder = (projectId: number, folderId: number, name: string) => (dispatch: Function) => {
  return api.renameFolder(projectId, folderId, name)
    .then(res => {
      dispatch(renamedFolder(folderId, name))
      return { error: false }
    })
    .catch(async res => {
      const err = await res.json()
      dispatch(notRenamedFolder(folderId, `Name ${err.errors.name[0]}`))
      return { error: true }
    })
}

export const deleteFolder = (projectId: number, folderId: number) => (dispatch: Function) => {
  return api.deleteFolder(projectId, folderId)
    .then(res => {
      dispatch(deletedFolder(folderId))
      return { error: false }
    })
    .catch(async res => {
      const err = await res.json()
      return { error: err.errors.surveys[0] }
    })
}

export const renamedFolder = (id, name) => {
  return {
    type: RENAMED_FOLDER,
    id: id,
    name: name
  }
}

export const notRenamedFolder = (id, error) => {
  return {
    type: NOT_RENAMED_FOLDER,
    id,
    error
  }
}

export const deletedFolder = id => {
  return {
    type: DELETED_FOLDER,
    id: id
  }
}

export const savingFolder = (projectId: number) => {
  return {
    type: SAVING_FOLDER
  }
}

export const createdFolder = (projectId: number, id: number, name: string) => {
  return {
    type: CREATED_FOLDER,
    folder: {
      projectId,
      name,
      id
    }
  }
}

export const notSavedFolder = error => {
  return {
    type: NOT_SAVED_FOLDER,
    error
  }
}

export const fetchFolders = (projectId: number) => (dispatch: Function) => {
  dispatch(fetchingFolders())

  return api.fetchFolders(projectId)
    .then(response => {
      /*
        When there are no folders:
          - the API response is {"data": []}
          - `response` here is {entities: {}, result: []}
        When there are folders:
          - the API response is {"data": [{"project_id": 15, "name": "Foo", "id": 6}]}
          - `response` here is {entities: {folders: {6: {…}}}, result: [6]}

        When there are no folders `response.entities.folders` is undefined.
        This is why in this case it's defaulted to an empty array.
      */
      dispatch(fetchedFolders(projectId, response.entities.folders || []))
    })
}

export const fetchingFolders = (projectId: number) => {
  return {
    type: FETCH_FOLDERS
  }
}

export const fetchedFolders = (projectId: number, folders) => {
  return {
    type: RECEIVE_FOLDERS,
    projectId,
    folders: folders
  }
}
