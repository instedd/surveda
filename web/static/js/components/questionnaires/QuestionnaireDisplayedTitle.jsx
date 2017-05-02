import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { Card, InputWithLabel } from '../ui'
import classNames from 'classnames'
import * as actions from '../../actions/questionnaire'
import propsAreEqual from '../../propsAreEqual'

class QuestionnaireDisplayedTitle extends Component {
  constructor(props) {
    super(props)
    this.state = this.stateFromProps(props, false)
  }

  handleClick(e) {
    e.preventDefault()
    this.setState({editing: !this.state.editing})
  }

  componentWillReceiveProps(newProps) {
    if (propsAreEqual(this.props, newProps)) return

    this.setState(this.stateFromProps(newProps))
  }

  stateFromProps(props, editing) {
    return {
      text: props.title
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
    dispatch(actions.setDisplayedTitle(this.state.text))
  }

  errors() {
    const { questionnaire, errorsByPath } = this.props
    return errorsByPath[`title['${questionnaire.activeLanguage}']`]
  }

  collapsed() {
    let hasErrors = !!this.errors()

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
                  <i className={iconClass}>assignment</i>
                  <span className={classNames({'text-error': hasErrors})}>Title</span>
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
    const { readOnly } = this.props

    const value = this.state.text
    let inputErrors = this.errors()
    const maybeInvalidClass = classNames({'validate invalid': inputErrors})

    return (
      <div className='row'>
        <Card className='z-depth-0'>
          <ul className='collection collection-card dark'>
            <li className='collection-item header'>
              <div className='row'>
                <div className='col s12'>
                  <i className='material-icons left'>assignment</i>
                  <a className='page-title truncate'>
                    <span>Title</span>
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
                  <InputWithLabel id='titleInput' value={value} label='Title' errors={inputErrors} >
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

QuestionnaireDisplayedTitle.propTypes = {
  dispatch: PropTypes.any,
  questionnaire: PropTypes.object,
  title: PropTypes.string,
  errorsByPath: PropTypes.object,
  hasErrors: PropTypes.bool,
  readOnly: PropTypes.bool
}

const mapStateToProps = (state, ownProps) => {
  const quiz = state.questionnaire
  return {
    questionnaire: quiz.data,
    title: quiz.data ? (quiz.data.settings.title || {})[quiz.data.activeLanguage] || '' : '',
    errorsByPath: quiz.errorsByPath
  }
}

export default connect(mapStateToProps)(QuestionnaireDisplayedTitle)
