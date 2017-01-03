import * as api from '../api'

// export const INVITE = 'INVITE'

export const invite = (projectId, code, level, email) => dispatch => {
  api.invite(projectId, code, level, email)
    // .then(response => dispatch(inviteSent()))
}

// const inviteSent = () => ({
//
// })
//
