import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import * as actions from '../../actions/questionnaireEditor'
import Card from '../Card'
import StepMultipleChoiceEditor from './StepMultipleChoiceEditor'
import StepNumericEditor from './StepNumericEditor'

class StepEditor extends Component {
  constructor(props) {
    super(props)

    this.state = this.stateFromProps(props)
  }

  stepTitleChange(e) {
    e.preventDefault()
    this.setState({stepTitle: e.target.value})
  }

  stepTitleSubmit(e) {
    e.preventDefault()
    const { dispatch } = this.props
    dispatch(actions.changeStepTitle(e.target.value))
  }

  stepPromptSmsChange(e) {
    e.preventDefault()
    this.setState({stepPromptSms: e.target.value})
  }

  stepPromptSmsSubmit(e) {
    e.preventDefault()
    const { dispatch } = this.props
    dispatch(actions.changeStepPromptSms(e.target.value))
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
    return {
      stepTitle: step.title,
      stepPromptSms: step.prompt.sms
    }
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
      <Card key={step.id}>
        <ul className='collection'>
          <li className='collection-item'>
            <div className='row'>
              <div className='col s10'>
                <input
                  placeholder='Untitled question'
                  type='text'
                  value={this.state.stepTitle}
                  onChange={e => this.stepTitleChange(e)}
                  onBlur={e => this.stepTitleSubmit(e)}
                  autoFocus />
              </div>
              <div>
                <a href='#!'
                  className='col s1'
                  onClick={e => this.deselectStep(e)}>
                  <i className='material-icons'>expand_less</i>
                </a>
              </div>
            </div>
          </li>
          <li className='collection-item'>
            <div className='section'>
              <div className='row'>
                <h5>Prompt</h5>
                <input
                  placeholder='SMS message'
                  type='text'
                  value={this.state.stepPromptSms}
                  onChange={e => this.stepPromptSmsChange(e)}
                  onBlur={e => this.stepPromptSmsSubmit(e)}
                  />
              </div>
            </div>
          </li>
          <li className='collection-item'>
            <div className='section'>
              <div className='row'>
                {editor}
              </div>
            </div>
          </li>
          <li className='collection-item'>
            <div className='row'>
              <a href='#!'
                onClick={(e) => this.delete(e)}>
                DELETE
              </a>
            </div>
          </li>
        </ul>
      </Card>
    )
  }
}

StepEditor.propTypes = {
  dispatch: PropTypes.func,
  step: PropTypes.object.isRequired
}

export default connect()(StepEditor)
