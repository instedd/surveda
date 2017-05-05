// @flow
import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import * as actions from '../actions/step'
import MultipleChoiceStep from './steps/MultipleChoiceStep'
import NumericStep from './steps/NumericStep'
import ExplanationStep from './steps/ExplanationStep'
import LanguageSelectionStep from './steps/LanguageSelectionStep'
import Header from './Header'
import EndStep from './steps/EndStep'

class Step extends Component {
  handleSubmit: PropTypes.func.isRequired
  hideMoreContentHint: PropTypes.func.isRequired
  props: {
    dispatch: PropTypes.func.isRequired,
    respondentId: any,
    token: string,
    step: PropTypes.object.isRequired,
    errorMessage: ?string
  }

  constructor(props) {
    super(props)

    this.handleSubmit = this.handleSubmit.bind(this)
    this.hideMoreContentHint = this.hideMoreContentHint.bind(this)
  }

  componentDidMount() {
    this.fetchStep()
    window.addEventListener('scroll', this.hideMoreContentHint)

    // This is so that when the user switches between tabs,
    // in case there are multiple tabs open they refresh
    // to the current step and so there's no way to submit
    // an answer for a previous question
    window.onfocus = () => this.fetchStep()
  }

  componentWillUnmount() {
    window.removeEventListener('scroll', this.hideMoreContentHint)
  }

  fetchStep() {
    const { dispatch, respondentId, token } = this.props
    actions.fetchStep(dispatch, respondentId, token)
  }

  componentDidUpdate(prevProps) {
    if (prevProps.step !== this.props.step) {
      if (this.isContentTallerThanViewport()) {
        this.showMoreContentHint()
      } else {
        this.hideMoreContentHint()
      }
    }
  }

  hideMoreContentHint() {
    this.refs.moreContentHint.style.display = 'none'
  }

  showMoreContentHint() {
    this.refs.moreContentHint.style.display = 'block'
  }

  isContentTallerThanViewport() {
    const viewportHeight = document.documentElement.clientHeight
    const contentHeight = this.refs.stepContent.offsetHeight
    return contentHeight > viewportHeight
  }

  stepComponent() {
    const { step, errorMessage } = this.props

    switch (step.type) {
      case 'multiple-choice':
        return <MultipleChoiceStep ref='step' step={step} onClick={value => this.handleValue(value)} />
      case 'numeric':
        return <NumericStep ref='step' step={step} errorMessage={errorMessage} onRefusal={value => this.handleValue(value)} />
      case 'explanation':
        return <ExplanationStep ref='step' step={step} />
      case 'language-selection':
        return <LanguageSelectionStep ref='step' step={step} onClick={value => this.handleValue(value)} />
      case 'end':
        return <EndStep ref='step' step={step} />
      default:
        throw new Error(`Unknown step type: ${step.type}`)
    }
  }

  handleSubmit(event) {
    event.preventDefault()

    this.handleValue(this.refs.step.getValue())
  }

  handleValue(value) {
    const { dispatch, step, respondentId, token } = this.props
    actions.sendReply(dispatch, respondentId, token, step.id, value)
      .then(() => this.refs.step.clearValue())
  }

  render() {
    const { step } = this.props
    if (!step) {
      return <div>Loading...</div>
    }

    return (
      <div ref='stepContent'>
        <Header />
        <main>
          <form onSubmit={this.handleSubmit}>
            {this.stepComponent()}
          </form>
        </main>
        <div ref='moreContentHint' className='more-content-arrow' />
      </div>
    )
  }

  getChildContext() {
    const primaryColor = window.colorStyle.primary_color || 'rgb(102,72,162)'
    const secondaryColor = window.colorStyle.secondary_color || 'rgb(251,154,0)'
    return {primaryColor: primaryColor, secondaryColor: secondaryColor}
  }
}

const mapStateToProps = (state) => ({
  step: state.step.current,
  errorMessage: state.step.errorMessage,
  respondentId: window.respondentId,
  token: window.token
})

Step.childContextTypes = {
  primaryColor: PropTypes.string,
  secondaryColor: PropTypes.string
}

export default connect(mapStateToProps)(Step)
