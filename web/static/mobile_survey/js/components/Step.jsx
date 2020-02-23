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
import IntroStep from './steps/IntroStep'

type Props = {
  dispatch: PropTypes.func.isRequired,
  respondentId: any,
  token: string,
  step: PropTypes.object.isRequired,
  progress: number,
  errorMessage: ?string,
  introMessage: string,
}

type State = {
  userConsent: boolean
}

class Step extends Component<Props, State> {
  handleSubmit: PropTypes.func.isRequired
  hideMoreContentHint: PropTypes.func.isRequired

  constructor(props) {
    super(props)

    this.handleSubmit = this.handleSubmit.bind(this)
    this.hideMoreContentHint = this.hideMoreContentHint.bind(this)
    this.state = { userConsent: false }
  }

  userConsented() {
    this.setState({userConsent: true})
    this.fetchStep()
  }

  componentDidMount() {
    window.addEventListener('scroll', this.hideMoreContentHint)

    // This is so that when the user switches between tabs,
    // in case there are multiple tabs open they refresh
    // to the current step and so there's no way to submit
    // an answer for a previous question
    window.onfocus = () => {
      if (this.state.userConsent) this.fetchStep()
    }
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
    const documentElement = document.documentElement
    if (!documentElement) return false
    const viewportHeight = documentElement.clientHeight
    const contentHeight = this.refs.stepContent.offsetHeight
    return contentHeight > viewportHeight
  }

  stepComponent(userConsent) {
    const { step, progress, errorMessage, introMessage } = this.props

    if (userConsent) {
      switch (step.type) {
        case 'multiple-choice':
          return <MultipleChoiceStep ref='step' step={step} onClick={value => this.handleValue(value)} />
        case 'numeric':
          return <NumericStep ref='step' step={step} errorMessage={errorMessage} onRefusal={value => this.handleValue(value)} />
        case 'explanation':
          return <ExplanationStep ref='step' step={step} progress={progress} />
        case 'language-selection':
          return <LanguageSelectionStep ref='step' step={step} onClick={value => this.handleValue(value)} />
        case 'end':
          return <EndStep ref='step' step={step} />
        default:
          throw new Error(`Unknown step type: ${step.type}`)
      }
    }
    else {
      return <IntroStep introMessage={introMessage} onClick={value => this.userConsented()} />
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
    const { userConsent } = this.state

    const isLoading = userConsent && !step

    if (isLoading) {
      return <div>Loading...</div>
    }

    return (
      <div ref='stepContent'>
        <Header />
        <main>
          <form onSubmit={this.handleSubmit}>
            { this.stepComponent(userConsent) }
          </form>
        </main>
        <div ref='moreContentHint' className='more-content-arrow'>
          <svg fill='#000000' height='100' viewBox='0 0 60 60' width='100' xmlns='http://www.w3.org/2000/svg'>
            <path d='M0 0h24v24H0V0z' fill='none' />
            <path d='M20 12l-1.41-1.41L13 16.17V4h-2v12.17l-5.58-5.59L4 12l8 8 8-8z' fill={this.primaryColor()} />
          </svg>
        </div>
      </div>
    )
  }

  primaryColor() {
    return window.colorStyle && window.colorStyle.primary_color ? window.colorStyle.primary_color : 'rgb(102,72,162)'
  }

  secondaryColor() {
    return window.colorStyle && window.colorStyle.secondary_color ? window.colorStyle.secondary_color : 'rgb(251,154,0)'
  }

  getChildContext() {
    return {primaryColor: this.primaryColor(), secondaryColor: this.secondaryColor()}
  }
}

const mapStateToProps = (state) => ({
  step: state.step.current,
  progress: state.step.progress,
  errorMessage: state.step.errorMessage,
  respondentId: window.respondentId,
  token: window.token,
  introMessage: window.introMessage
})

Step.childContextTypes = {
  primaryColor: PropTypes.string,
  secondaryColor: PropTypes.string
}

export default connect(mapStateToProps)(Step)
