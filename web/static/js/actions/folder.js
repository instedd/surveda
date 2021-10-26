import * as api from '../api'

export const FETCH = 'FOLDER_FETCH'
export const RECEIVE = 'FOLDER_RECEIVE'

export const fetchFolder = (projectId: number, id: number) => (dispatch: Function, getState: () => Store): Folder => {
  dispatch(fetching(projectId, id))

  return api.fetchFolder(projectId, id)
    .then(res => dispatch(receive(projectId, id, res.entities.folders[res.result])))
    .then(() => getState().folder.data)
}

export const fetching = (projectId: number, id: number) => {
  return {
    type: FETCH,
    projectId: projectId,
    folderId: id
  }
}

export const receive = (projectId: number, id: number, folder: Array<Folder>) => {
  return {
    type: RECEIVE,
    projectId,
    folderId: id,
    data: folder
  }
}
