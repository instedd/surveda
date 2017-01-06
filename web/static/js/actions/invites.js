import * as api from '../api'

export const RECEIVE_INVITE = 'RECEIVE_INVITE'

export const invite = (projectId, code, level, email) => dispatch => {
  api.invite(projectId, code, level, email)
}

export const inviteMail = (projectId, code, level, email) => dispatch => {
  api.inviteMail(projectId, code, level, email)
}

export const fetchInvite = (code) => dispatch => {
  api.fetchInvite(code)
    .then(invite => {
      dispatch(receiveInvite(invite))
    })
}

export const confirm = (code) => dispatch => {
  api.confirm(code)
}

export const receiveInvite = (data) => ({
  type: RECEIVE_INVITE,
  data
})
