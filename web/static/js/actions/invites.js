import * as api from '../api'
import * as collaboratorsActions from './collaborators'

export const RECEIVE_INVITE = 'RECEIVE_INVITE'

export const invite = (projectId, code, level, email) => dispatch => {
  return api.invite(projectId, code, level, email)
}

export const getInviteByEmailAndProject = (projectId, email) => dispatch => {
  return api.getInviteByEmailAndProject(projectId, email)
}

export const inviteMail = (projectId, code, level, email) => dispatch => {
  return api.inviteMail(projectId, code, level, email)
}

export const updateLevel = (projectId, collaborator, level) => dispatch => {
  return api.updateInviteLevel(projectId, collaborator.email, level)
  .then(response => {
    dispatch(collaboratorsActions.fetchCollaborators(projectId))
    window.Materialize.toast(`Invite level successfully updated`, 5000)
  })
}

export const removeInvite = (projectId, collaborator) => dispatch => {
  api.removeInvite(projectId, collaborator.email)
    .then(response => {
      dispatch(collaboratorsActions.fetchCollaborators(projectId))
      window.Materialize.toast(`Invite successfully removed`, 5000)
    })
}

export const fetchInvite = (code) => dispatch => {
  return api.fetchInvite(code)
    .then(invite => {
      dispatch(receiveInvite(invite))
      return invite
    })
}

export const confirm = (code) => dispatch => {
  return api.confirm(code)
}

export const receiveInvite = (data) => ({
  type: RECEIVE_INVITE,
  data: data
})
