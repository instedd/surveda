import * as api from '../api'

export const invite = (projectId, code, level, email) => dispatch => {
  api.invite(projectId, code, level, email)
}

export const inviteMail = (projectId, code, level, email) => dispatch => {
  api.inviteMail(projectId, code, level, email)
}

export const confirm = (code) => dispatch => {
  api.confirm(code)
}
