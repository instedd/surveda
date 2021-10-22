import * as api from '../api'

export const FETCH = 'FOLDER_FETCH'
export const RECEIVE = 'FOLDER_RECEIVE'

export const fetchFolder = (projectId: number, id: number) => (dispatch: Function, getState: () => Store): Folder => {
  dispatch({ type: FETCH })

  return api.fetchFolder(projectId, id)
    .then(res => dispatch(receive(projectId, id, res.entities.folders[res.result])))
    .then(() => getState().folder.data)
}

export const receive = (projectId: number, id: number, folder: Array<Folder>) => {
  return {
    type: RECEIVE,
    projectId,
    folderId: id,
    data: folder
  }
}
