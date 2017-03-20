import React, { PropTypes, Component } from 'react'
import { connect } from 'react-redux'
import { withRouter } from 'react-router'
import { EditableTitleLabel } from '../ui'
import merge from 'lodash/merge'
import * as projectActions from '../../actions/project'
import { updateProject } from '../../api'
import ColourSchemeModal from './ColourSchemeModal'

class ProjectTitle extends Component {
  static propTypes = {
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

  selectColourScheme(e) {
    $('#colourSchemeModal').modal('open')
  }

  render() {
    const { project, readOnly } = this.props
    if (project == null) return null

    return (
      <div className='color-palette-wrapper'>
        <div className='fixed-action-btn horizontal'>
          <EditableTitleLabel title={project.name} entityName='project' onSubmit={(value) => { this.handleSubmit(value) }} readOnly={readOnly} />
          <ul>
            <li><a onClick={(e) => this.selectColourScheme(e)}><i className='material-icons'>palette</i></a></li>
          </ul>
        </div>
        <ColourSchemeModal modalId='colourSchemeModal' />
      </div>
    )
  }
}

const mapStateToProps = (state, ownProps) => {
  return {
    projectId: ownProps.params.projectId,
    project: state.project.data,
    readOnly: state.project && state.project.data ? state.project.data.readOnly : true
  }
}

export default withRouter(connect(mapStateToProps)(ProjectTitle))
