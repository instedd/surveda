import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { Modal } from '../ui'
import * as projectActions from '../../actions/project'
import { updateProject } from '../../api'
import merge from 'lodash/merge'
import { translate } from 'react-i18next'

export class ColourSchemeModal extends Component {
  toggleColourScheme(colourScheme) {
    const { dispatch, project } = this.props
    if (project.colourScheme == colourScheme) return
    const newProject = merge({}, project, {colourScheme: colourScheme})
    dispatch(projectActions.updateProject(newProject)) // Optimistic update
    updateProject(newProject)
      .then(response => dispatch(projectActions.updateProject(response.entities.projects[response.result])))
  }

  render() {
    const { modalId, project, t } = this.props
    if (project == null) return null

    return (
      <Modal card id={modalId}>
        <div className='modal-content'>
          <div className='card-title header'>
            <h5>{t('Select color scheme')}</h5>
            <p>{t('Choose an option to change the color scheme')}</p>
          </div>
          <div className='card-content'>
            <div className='row'>
              <div className='col s12'>
                <input
                  id={`defaultScheme`}
                  type='radio'
                  name='toggleDefault'
                  value='default'
                  checked={project.colourScheme == 'default'}
                  onChange={e => this.toggleColourScheme('default')}
                  className='with-gap'
                />
                <label className='colourScheme' htmlFor={`defaultScheme`}>{t('Default color scheme')}</label>
              </div>
            </div>
            <div className='row'>
              <div className='col s12'>
                <input
                  id={`betterDataForHealthScheme`}
                  type='radio'
                  name='toggleDefault'
                  value='better_data_for_health'
                  checked={project.colourScheme == 'better_data_for_health'}
                  onChange={e => this.toggleColourScheme('better_data_for_health')}
                  className='with-gap'
                />
                <label className='colourScheme' htmlFor={`betterDataForHealthScheme`}>{t('Data for health initiative')}</label>
              </div>
            </div>
          </div>
          <div className='card-action'>
            <a className='btn-large waves-effect waves-light blue modal-action modal-close '>{t('Done')}</a>
          </div>
        </div>
      </Modal>
    )
  }
}

ColourSchemeModal.propTypes = {
  t: PropTypes.func,
  modalId: PropTypes.string,
  project: PropTypes.object,
  dispatch: PropTypes.func.isRequired
}

const mapStateToProps = (state) => ({
  project: state.project.data
})

export default translate()(connect(mapStateToProps)(ColourSchemeModal))
