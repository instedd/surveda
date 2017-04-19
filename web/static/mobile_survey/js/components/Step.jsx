// @flow
import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import * as actions from '../actions/step'
import MultipleChoiceStep from './steps/MultipleChoiceStep'
import NumericStep from './steps/NumericStep'
import ExplanationStep from './steps/ExplanationStep'
import LanguageSelectionStep from './steps/LanguageSelectionStep'

class Step extends Component {
  handleSubmit: PropTypes.func.isRequired
  props: {
    dispatch: PropTypes.func.isRequired,
    respondentId: any,
    step: PropTypes.object.isRequired
  }

  constructor(props) {
    super(props)

    this.handleSubmit = this.handleSubmit.bind(this)
  }

  componentDidMount() {
    const { dispatch, respondentId } = this.props

    actions.fetchStep(dispatch, respondentId)
  }

  stepComponent(step) {
    switch (step.type) {
      case 'multiple-choice':
        return <MultipleChoiceStep ref='step' step={step} onClick={value => this.handleValue(value)} />
      case 'numeric':
        return <NumericStep ref='step' step={step} />
      case 'explanation':
        return <ExplanationStep ref='step' step={step} />
      case 'language-selection':
        return <LanguageSelectionStep ref='step' step={step} onClick={value => this.handleValue(value)} />
      default:
        throw new Error(`Unknown step type: ${step.type}`)
    }
  }

  handleSubmit(event) {
    event.preventDefault()
    this.handleValue(this.refs.step.getValue())
  }

  handleValue(value) {
    const { dispatch, respondentId } = this.props
    actions.sendReply(dispatch, respondentId, value)
      .then(() => this.refs.step.clearValue())
  }

  render() {
    const { step } = this.props
    if (!step) {
      return <div>Loading...</div>
    }

    return (
      <div>
        <main>
          <form onSubmit={this.handleSubmit}>
            {this.stepComponent(step)}
          </form>
        </main>
      </div>
    )
  }
}

const mapStateToProps = (state) => ({
  step: state.step.current,
  respondentId: window.respondentId
})

export default connect(mapStateToProps)(Step)
