export default (( survey ) => {
  let to = `/projects/${survey.projectId}/surveys/${survey.id}`

  if (survey.state == 'not_ready' || survey.state == 'ready') {
    to = to + '/edit'
  }

  return to
})
