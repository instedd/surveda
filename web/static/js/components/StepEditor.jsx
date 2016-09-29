import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import * as actions from '../actions/questionnaireEditor'
import Card from '../components/Card'

class StepEditor extends Component {
  deselectStep(event) {
    event.preventDefault()

    const { dispatch } = this.props
    dispatch(actions.deselectStep())
  }

  render() {
    const { step } = this.props

    return (
      <Card>
        <ul className="collection">
          <li className="collection-item">
            <a href="#!" onClick={(event) => this.deselectStep(event)}>{step.title}</a>
          </li>
        </ul>
      </Card>
    )
  }
}

StepEditor.propTypes = {
  step: PropTypes.object.isRequired,
}

export default connect()(StepEditor);
