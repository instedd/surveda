import React, { Component, PropTypes } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import { InputWithLabel } from '../ui'
import * as questionnaireActions from '../../actions/questionnaire'
import classNames from 'classnames/bind'

class MobileWebPrompt extends Component {
  state: State

  onBlur(e) {
    const { onBlur } = this.props
    onBlur(e)
  }

  render() {
    const { id, value, onChange, readOnly, onBlur, inputErrors } = this.props
    let { label } = this.props
    if (!label) label = 'Mobile Web Message'

    const shouldDisplayErrors = value == this.props.originalValue
    const maybeInvalidClass = classNames({'validate invalid': inputErrors && shouldDisplayErrors})

    return (
      <div>
        <div className='row'>
          <div className='col input-field s12'>
            <InputWithLabel id={id} value={value} label={label} errors={[inputErrors]}>
              <input
                type='text'
                disabled={readOnly}
                onChange={e => onChange(e.target.value)}
                onBlur={e => onBlur(e.target.value)}
                className={maybeInvalidClass}
              />
            </InputWithLabel>
          </div>
        </div>
      </div>
    )
  }
}

MobileWebPrompt.propTypes = {
  id: PropTypes.string.isRequired,
  label: PropTypes.string,
  value: PropTypes.string.isRequired,
  originalValue: PropTypes.string.isRequired,
  onChange: PropTypes.func.isRequired,
  onBlur: PropTypes.func.isRequired,
  inputErrors: PropTypes.array,
  readOnly: PropTypes.bool,
  stepId: PropTypes.string
}

const mapDispatchToProps = (dispatch) => ({
  questionnaireActions: bindActionCreators(questionnaireActions, dispatch)
})

export default connect(null, mapDispatchToProps)(MobileWebPrompt)
