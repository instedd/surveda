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
  props: {
    dispatch: PropTypes.func.isRequired,
    respondentId: any,
    step: PropTypes.object.isRequired,
    errorMessage: ?string
  }

  constructor(props) {
    super(props)

    this.handleSubmit = this.handleSubmit.bind(this)
  }

  componentDidMount() {
    this.fetchStep()

    // This is so that when the user switches between tabs,
    // in case there are multiple tabs open they refresh
    // to the current step and so there's no way to submit
    // an answer for a previous question
    window.onfocus = () => this.fetchStep()
  }

  fetchStep() {
    const { dispatch, respondentId } = this.props
    actions.fetchStep(dispatch, respondentId)
  }

  stepComponent() {
    const { step, errorMessage } = this.props

    switch (step.type) {
      case 'multiple-choice':
        return <MultipleChoiceStep ref='step' step={step} onClick={value => this.handleValue(value)} />
      case 'numeric':
        return <NumericStep ref='step' step={step} errorMessage={errorMessage} />
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
    const { dispatch, step, respondentId } = this.props
    actions.sendReply(dispatch, respondentId, step.id, value)
      .then(() => this.refs.step.clearValue())
  }

  render() {
    const { step } = this.props
    if (!step) {
      return <div>Loading...</div>
    }

    return (
      <div>
        <Header />
        <main>
          <form onSubmit={this.handleSubmit}>
            {this.stepComponent()}
          </form>
        </main>
      </div>
    )
  }
}

const mapStateToProps = (state) => ({
  step: state.step.current,
  errorMessage: state.step.errorMessage,
  respondentId: window.respondentId
})

export default connect(mapStateToProps)(Step)
