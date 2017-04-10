import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import * as actions from '../actions/step'
import MultipleChoiceStep from './steps/MultipleChoiceStep'
import NumericStep from './steps/NumericStep'
import ExplanationStep from './steps/ExplanationStep'
import LanguageSelectionStep from './steps/LanguageSelectionStep'

class Step extends Component {
  constructor(props) {
    super(props)

    this.handleSubmit = this.handleSubmit.bind(this)
  }

  componentDidMount() {
    const { dispatch } = this.props
    actions.fetchStep(dispatch)
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

    const { step } = this.props
    const value = this.refs.step.getValue()

    actions.sendReply(step.id, value)
  }

  handleValue(value) {
    const { step } = this.props
    actions.sendReply(step.id, value)
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

Step.propTypes = {
  dispatch: PropTypes.any,
  step: PropTypes.object
}

const mapStateToProps = (state) => ({
  step: state.step.current
})

export default connect(mapStateToProps)(Step)

