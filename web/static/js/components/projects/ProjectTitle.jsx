import React, { PropTypes, Component } from 'react'
import { connect } from 'react-redux'
import { withRouter } from 'react-router'
import { EditableTitleLabel } from '../ui'
import merge from 'lodash/merge'
import * as projectActions from '../../actions/project'
import { updateProject } from '../../api'
import { translate } from 'react-i18next'
import { isProjectReadOnly } from '../../reducers/project'

class ProjectTitle extends Component {
  static propTypes = {
    t: PropTypes.func,
    dispatch: PropTypes.func.isRequired,
    projectId: PropTypes.any.isRequired,
    project: PropTypes.object,
    readOnly: PropTypes.bool
  }

  componentWillMount() {
    const { dispatch, projectId } = this.props
    dispatch(projectActions.fetchProject(projectId))
  }

  handleSubmit(newName) {
    const { dispatch, project } = this.props
    if (project.name == newName) return
    const newProject = merge({}, project, {name: newName})

    dispatch(projectActions.updateProject(newProject)) // Optimistic update
    updateProject(newProject)
      .then(response => dispatch(projectActions.updateProject(response.entities.projects[response.result])))
  }

  render() {
    const { project, readOnly, t } = this.props
    if (project == null) return null

    return <EditableTitleLabel title={project.name} entityName='project' onSubmit={(value) => { this.handleSubmit(value) }} readOnly={readOnly} emptyText={t('Untitled project')} />
  }
}

const mapStateToProps = (state, ownProps) => {
  return {
    projectId: ownProps.params.projectId,
    project: state.project.data,
    readOnly: isProjectReadOnly(state)
  }
}

export default translate()(withRouter(connect(mapStateToProps)(ProjectTitle)))
