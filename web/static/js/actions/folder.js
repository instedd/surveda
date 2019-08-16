import * as api from '../api'

export const FETCH_FOLDERS = 'FETCH_FOLDERS'
export const FETCHING_FOLDERS = 'FETCHING_FOLDERS'
export const FETCHED_FOLDERS = 'FETCHED_FOLDERS'
export const FETCH_FOLDER = 'FETCH_FOLDER'
export const FETCHING_FOLDER = 'FETCHING_FOLDER'
export const FETCHED_FOLDER = 'FETCHED_FOLDER'
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

export const fetchFolder = (projectId: number, folderId: number) => (dispatch: Function) => {
  dispatch(fetchingFolder())

  return api.fetchFolder(projectId, folderId)
    .then(response => {
      dispatch(fetchedFolder(projectId, folderId, response.entities.folders[response.result]))
    })
}

export const fetchingFolder = (folderId: number) => {
  return {
    type: FETCHING_FOLDER
  }
}

export const fetchedFolder = (projectId, folderId, folder) => {
  return {
    type: FETCHED_FOLDER,
    folderId,
    folder
  }
}

export const fetchFolders = (projectId: number) => (dispatch: Function) => {
  dispatch(fetchingFolders())

  return api.fetchFolders(projectId)
    .then(response => {
      dispatch(fetchedFolders(projectId, response.entities.folders))
    })
}

export const fetchingFolders = (projectId: number) => {
  return {
    type: FETCHING_FOLDERS
  }
}

export const fetchedFolders = (projectId: number, folders) => {
  return {
    type: FETCHED_FOLDERS,
    projectId,
    folders
  }
}
