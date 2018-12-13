import React, { Component, PropTypes } from 'react'
import * as uiActions from '../../actions/ui'
import { connect } from 'react-redux'
import { translate } from 'react-i18next'

class QuestionnaireImportError extends Component {
  constructor(props) {
    super(props)
    this.backToQuestionnaire = this.backToQuestionnaire.bind(this)
  }

  backToQuestionnaire() {
    const { dispatch } = this.props
    dispatch(uiActions.uploadFinished())
  }

  render() {
    const { description, t } = this.props
    return (
      <div className='center-align questionnaire-import-error'>
        <i className='material-icons'>warning</i>
        <h5 className='error-description'>
          { t(description) }
        </h5>
        <br />
        <a href='#!' onClick={this.backToQuestionnaire} className='back-link grey-text lighten-1'>
          { t('Back to questionnaire') }
        </a>
      </div>
    )
  }
}

QuestionnaireImportError.propTypes = {
  description: PropTypes.oneOfType([PropTypes.array, PropTypes.string]),
  dispatch: PropTypes.func.isRequired,
  t: PropTypes.func
}

export default translate()(connect()(QuestionnaireImportError))
