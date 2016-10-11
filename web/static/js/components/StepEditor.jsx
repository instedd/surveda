import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import * as actions from '../actions/questionnaireEditor'
import Card from './Card'
import StepMultipleChoiceEditor from './StepMultipleChoiceEditor'
import StepNumericEditor from './StepNumericEditor'
import { isEqual } from 'underscore'

class StepEditor extends Component {
  constructor(props) {
    super(props)

    this.state = this.stateFromProps(props)

    this.stepTitleChange = this.stepTitleChange.bind(this)
    this.stepTitleSubmit = this.stepTitleSubmit.bind(this)
  }

  stepTitleChange(e) {
    e.preventDefault
    this.setState({stepTitle: e.target.value})
  }

  stepTitleSubmit(e) {
    e.preventDefault()
    const { dispatch } = this.props
    dispatch(actions.changeStepTitle(e.target.value))
  }

  deselectStep(e) {
    e.preventDefault()
    this.props.dispatch(actions.deselectStep())
  }

  editTitle(e) {
    e.preventDefault()
    this.props.dispatch(actions.editTitle())
  }

  delete(e) {
    e.preventDefault()
    this.props.dispatch(actions.deleteStep())
  }

  componentWillReceiveProps(newProps) {
    this.setState(this.stateFromProps(newProps))
  }

  stateFromProps(props) {
    const { step } = props
    return {stepTitle: step.title}
  }

  shouldComponentUpdate(nextProps, nextState) {
    return !isEqual(this.state, nextState)
  }

  render() {
    const { step } = this.props

    let editor
    if (step.type === 'multiple-choice') {
      editor = <StepMultipleChoiceEditor step={step} />
    } else if (step.type === 'numeric') {
      editor = <StepNumericEditor step={step} />
    } else {
      throw new Error(`unknown step type: ${step.type}`)
    }

    return (
      <Card key={step.title}>
        <ul className='collection'>
          <li className='collection-item'>
            <div className='row'>
              <div className='col s10'>
                <input
                  placeholder='Untitled question'
                  type='text'
                  value={this.state.stepTitle}
                  onChange={this.stepTitleChange}
                  onBlur={this.stepTitleSubmit}
                  autoFocus />
              </div>
              <div>
                <a href='#!'
                  className='col s1'
                  onClick={(e) => this.deselectStep(e)}>
                  Deselect
                </a>
              </div>
            </div>
            <div className='row'>
              {editor}
            </div>
            <div className='row'>
              <a href='#!'
                onClick={(e) => this.delete(e)}>
                Delete
              </a>
            </div>
          </li>
        </ul>
      </Card>
    )
  }
}

StepEditor.propTypes = {
  step: PropTypes.object.isRequired
}

export default connect()(StepEditor)
