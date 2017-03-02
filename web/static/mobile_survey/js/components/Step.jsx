import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import * as actions from '../actions/step'
import * as api from '../api'
import MultipleChoiceStep from './steps/MultipleChoiceStep'
import NumericStep from './steps/NumericStep'
import ExplanationStep from './steps/ExplanationStep'
import LanguageSelectionStep from './steps/LanguageSelectionStep'

class Step extends Component {
  componentDidMount() {
    const { dispatch } = this.props

    api.fetchStep().then(response => {
      response.json().then(json => {
        dispatch(actions.receiveStep(json.step))
      })
    })
  }

  stepComponent(step) {
    switch (step.type) {
      case 'multiple-choice':
        return <MultipleChoiceStep step={step} />
      case 'numeric':
        return <NumericStep step={step} />
      case 'explanation':
        return <ExplanationStep step={step} />
      case 'language-selection':
        return <LanguageSelectionStep step={step} />
      default:
        throw new Error(`Unknown step type: ${step.type}`)
    }
  }

  render() {
    const { step } = this.props
    if (!step) {
      return <div>Loading...</div>
    }

    return (
      <form>
        {this.stepComponent(step)}
      </form>
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

