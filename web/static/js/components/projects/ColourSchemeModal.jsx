import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { Modal } from '../ui'
import * as projectActions from '../../actions/project'
import { updateProject } from '../../api'
import merge from 'lodash/merge'

export class ColourSchemeModal extends Component {
  toggleColourScheme(colourScheme) {
    const { dispatch, project } = this.props
    if (project.colourScheme == colourScheme) return
    const newProject = merge({}, project, {colour_scheme: colourScheme})
    dispatch(projectActions.updateProject(newProject)) // Optimistic update
    updateProject(newProject)
      .then(response => dispatch(projectActions.updateProject(response.entities.projects[response.result])))
  }

  render() {
    const { modalId, project } = this.props
    if (project == null) return null

    return (
      <Modal card id={modalId}>
        <input
          id={`defaultScheme`}
          type='radio'
          name='toggleDefault'
          value='default'
          checked={project.colourScheme == 'default'}
          onChange={e => this.toggleColourScheme('default')}
          className='colourScheme'
        />
        <label className='colourScheme' htmlFor={`defaultScheme`}>Default scheme</label>
        <input
          id={`betterDataForHealthScheme`}
          type='radio'
          name='toggleDefault'
          value='better_data_for_health'
          checked={project.colourScheme == 'better_data_for_health'}
          onChange={e => this.toggleColourScheme('better_data_for_health')}
          className='colourScheme'
        />
        <label className='colourScheme' htmlFor={`betterDataForHealthScheme`}>Better Data for Health</label>
      </Modal>
    )
  }
}

ColourSchemeModal.propTypes = {
  modalId: PropTypes.string,
  project: PropTypes.object,
  dispatch: PropTypes.func.isRequired
}

const mapStateToProps = (state) => ({
  project: state.project.data
})

export default connect(mapStateToProps)(ColourSchemeModal)
