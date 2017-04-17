import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { Card, InputWithLabel } from '../ui'
import classNames from 'classnames'
import * as actions from '../../actions/questionnaire'
import { mobileWebSurveyIsOverMessagePath, mobileWebSurveyIsOverMessageHasErrors } from '../../questionnaireErrors'

class MobileWebSurveyIsOverMessage extends Component {
  constructor(props) {
    super(props)
    this.state = this.stateFromProps(props)
  }

  handleClick(e) {
    e.preventDefault()
    this.setState({editing: !this.state.editing})
  }

  stateFromProps(props, editing) {
    const { questionnaire } = props

    if (!questionnaire) {
      return {
        editing: editing,
        text: ''
      }
    }

    return {
      editing,
      text: questionnaire.mobileWebSurveyIsOverMessage || ''
    }
  }

  onChange(e) {
    e.preventDefault()

    this.setState({
      text: e.target.value
    })
  }

  onBlur(e) {
    e.preventDefault()

    const { dispatch } = this.props
    dispatch(actions.setMobileWebSurveyIsOverMessage(this.state.text))
  }

  collapsed() {
    const { hasErrors } = this.props

    const iconClass = classNames({
      'material-icons left': true,
      'text-error': hasErrors
    })

    return (
      <div className='row'>
        <ul className='collapsible dark'>
          <li>
            <Card>
              <div className='card-content closed-step'>
                <a className='truncate' href='#!' onClick={(e) => this.handleClick(e)}>
                  <i className={iconClass}>phonelink</i>
                  <span className={classNames({'text-error': hasErrors})}>Mobile Web "Survey is over" message</span>
                  <i className={classNames({'material-icons right grey-text': true, 'text-error': hasErrors})}>expand_more</i>
                </a>
              </div>
            </Card>
          </li>
        </ul>
      </div>
    )
  }

  expanded() {
    const { readOnly, errors } = this.props

    const value = this.state.text
    let inputErrors = errors[mobileWebSurveyIsOverMessagePath()]
    const maybeInvalidClass = classNames({'validate invalid': inputErrors})

    return (
      <div className='row'>
        <Card className='z-depth-0'>
          <ul className='collection collection-card dark'>
            <li className='collection-item header'>
              <div className='row'>
                <div className='col s12'>
                  <i className='material-icons left'>phonelink</i>
                  <a className='page-title truncate'>
                    <span>Mobile Web "Survey is over" message</span>
                  </a>
                  <a className='collapse right' href='#!' onClick={(e) => this.handleClick(e)}>
                    <i className='material-icons'>expand_less</i>
                  </a>
                </div>
              </div>
            </li>
            <li className='collection-item'>
              <div className='row'>
                <div className='col input-field s12'>
                  <InputWithLabel id='mobileWebSurveyIsOverMessageInput' value={value} label='Message' errors={inputErrors} >
                    <input
                      type='text'
                      disabled={readOnly}
                      onChange={e => this.onChange(e)}
                      onBlur={e => this.onBlur(e)}
                      className={maybeInvalidClass}
                      ref={ref => { this.input = ref; $(ref).addClass(maybeInvalidClass) }}
                    />
                  </InputWithLabel>
                </div>
              </div>
            </li>
          </ul>
        </Card>
      </div>
    )
  }

  render() {
    const { questionnaire } = this.props
    if (!questionnaire) {
      return <div>Loading...</div>
    }

    if (this.state.editing) {
      return this.expanded()
    } else {
      return this.collapsed()
    }
  }
}

MobileWebSurveyIsOverMessage.propTypes = {
  dispatch: PropTypes.any,
  questionnaire: PropTypes.object,
  errors: PropTypes.object,
  hasErrors: PropTypes.bool,
  readOnly: PropTypes.bool
}

const mapStateToProps = (state, ownProps: Props) => {
  const quiz = state.questionnaire
  return {
    questionnaire: quiz.data,
    errors: quiz.errors,
    hasErrors: quiz.data ? mobileWebSurveyIsOverMessageHasErrors(quiz) : false
  }
}

export default connect(mapStateToProps)(MobileWebSurveyIsOverMessage)
