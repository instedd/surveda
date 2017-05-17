import React, { Component, PropTypes } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import * as questionnaireActions from '../../actions/questionnaire'
import Draft from './Draft'

class MobileWebPrompt extends Component {
  state: State

  onBlur(e) {
    const { onBlur } = this.props
    onBlur(e)
  }

  render() {
    const { value, readOnly, onBlur, inputErrors } = this.props
    let { label } = this.props
    if (!label) label = 'Mobile Web Message'

    const shouldDisplayErrors = value == this.props.originalValue
    return (
      <div>
        <div className='row'>
          <div className='col s12 mobile-prompt'>
            <Draft
              label={label}
              onBlur={onBlur}
              errors={shouldDisplayErrors && inputErrors}
              value={value}
              readOnly={readOnly}
              />
          </div>
        </div>
      </div>
    )
  }
}

MobileWebPrompt.propTypes = {
  label: PropTypes.string,
  value: PropTypes.string.isRequired,
  originalValue: PropTypes.string.isRequired,
  onBlur: PropTypes.func.isRequired,
  inputErrors: PropTypes.array,
  readOnly: PropTypes.bool,
  stepId: PropTypes.string
}

const mapDispatchToProps = (dispatch) => ({
  questionnaireActions: bindActionCreators(questionnaireActions, dispatch)
})

export default connect(null, mapDispatchToProps)(MobileWebPrompt)
