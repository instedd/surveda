import * as api from '../api'

// export const INVITE = 'INVITE'

export const invite = (projectId, code, level, email) => dispatch => {
  api.invite(projectId, code, level, email)
    // .then(response => dispatch(inviteSent()))
}

export const confirm = (code) => dispatch => {
  api.confirm(code)
}

// const inviteSent = () => ({
//
// })
//
