import React, { PropTypes, Component } from 'react'
import { withRouter } from 'react-router'
import { connect } from 'react-redux'
import { translate } from 'react-i18next'

class SurveyWizardPanelSurveyStep extends Component {
  static propTypes = {
    t: PropTypes.func,
    survey: PropTypes.object.isRequired,
    readOnly: PropTypes.bool.isRequired
  }

  render() {
    const { survey, readOnly, t } = this.props

    return (
      <div>
        <div className='row'>
          <div className='col s12'>
            <h4>{t('Repeat survey')}</h4>
            <p className='flow-text'>{t('Panel surveys (longitudinal studies) can be accomplished by repeating the exact same survey multiple times. Please enable repetition to allow this survey to be repeated in the future.')}</p>
          </div>
        </div>
        <div className='row'>
          <div className='col s12'>
            <p>
              <div className='switch'>
                <label>
                  <input type='checkbox' disabled={readOnly} checked={!!survey.panelSurveyId} onChange={() => {
                    // TODO: change the new property new `generates_panel_survey` property here
                  }} />
                  <span className='lever' />
                </label>
                {t('Repeatable')}
              </div>
            </p>
          </div>
        </div>
      </div>
    )
  }
}

export default translate()(withRouter(connect()(SurveyWizardPanelSurveyStep)))
