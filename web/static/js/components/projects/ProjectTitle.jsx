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

  onClickToggle(colourScheme) {
    const { dispatch, project } = this.props
    if (project.colourScheme == colourScheme) return
    const newProject = merge({}, project, {colour_scheme: colourScheme})
    updateProject(newProject)
      .then(response => dispatch(projectActions.updateProject(response.entities.projects[response.result])))
    // toggleColourScheme(project.colourScheme)
  }

  selectColourScheme() {
    $('#colourSchemeModal').modal('open')
  }

  render() {
    const { project, readOnly } = this.props
    if (project == null) return null

    console.log(project.colourScheme)

    return (
      <div>
        <p onClick={() => this.onClickToggle()}>Set colour scheme</p>
        <input
          id={`defaultScheme`}
          type='radio'
          name='toggleDefault'
          value='default'
          checked={project.colourScheme == 'default'}
          onChange={e => this.onClickToggle('default')}
          disabled={readOnly}
          className='colourScheme'
        />
        <label className='colourScheme' htmlFor={`defaultScheme`}>Default scheme</label>
        <input
          id={`betterDataForHealthScheme`}
          type='radio'
          name='toggleDefault'
          value='better_data_for_health'
          checked={project.colourScheme == 'better_data_for_health'}
          onChange={e => this.onClickToggle('better_data_for_health')}
          disabled={readOnly}
          className='colourScheme'
        />
        <label className='colourScheme' htmlFor={`betterDataForHealthScheme`}>Better Data for Health</label>
        <button type='button' onClick={() => this.selectColourScheme()}>
          Colour scheme
        </button>
        <ColourSchemeModal modalId='colourSchemeModal' />
        <EditableTitleLabel title={project.name} entityName='project' onSubmit={(value) => { this.handleSubmit(value) }} readOnly={readOnly} />
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
