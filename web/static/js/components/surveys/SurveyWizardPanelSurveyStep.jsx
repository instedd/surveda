import React, { PropTypes, Component } from 'react'
import { withRouter } from 'react-router'
import { connect } from 'react-redux'
import { translate } from 'react-i18next'

class SurveyWizardPanelSurveyStep extends Component {
  static propTypes = {
    t: PropTypes.func,
    survey: PropTypes.object.isRequired,
    readOnly: PropTypes.bool.isRequired,
    dispatch: PropTypes.func.isRequired
  }

  render() {
    const { t } = this.props

    return (
      <div>
        <div className='row'>
          <div className='col s12'>
            <h4>{t('Panel Survey')}</h4>
            <p className='flow-text'>{t('This is an occurrence of a Panel Survey, it might inherit settings from previous occurrences (if any) and will be used as a template for the next occurrence.')}</p>
          </div>
        </div>
      </div>
    )
  }
}

export default translate()(withRouter(connect()(SurveyWizardPanelSurveyStep)))
