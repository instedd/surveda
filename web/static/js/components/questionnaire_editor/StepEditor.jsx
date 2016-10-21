import React, { Component, PropTypes } from 'react'
import { bindActionCreators } from 'redux'
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
    this.props.actions.changeStepTitle(e.target.value)
  }

  stepPromptSmsChange(e) {
    e.preventDefault()
    this.setState({stepPromptSms: e.target.value})
  }

  stepPromptSmsSubmit(e) {
    e.preventDefault()
    this.props.actions.changeStepPromptSms(e.target.value)
  }

  stepStoreChange(e) {
    e.preventDefault()
    this.setState({stepStore: e.target.value})
  }

  stepStoreSubmit(e) {
    e.preventDefault()
    this.props.actions.changeStepStore(e.target.value)
  }

  deselectStep(e) {
    e.preventDefault()
    this.props.actions.deselectStep()
  }

  editTitle(e) {
    e.preventDefault()
    this.props.actions.editTitle()
  }

  delete(e) {
    e.preventDefault()
    this.props.actions.deleteStep()
  }

  componentWillReceiveProps(newProps) {
    this.setState(this.stateFromProps(newProps))
  }

  stateFromProps(props) {
    const { step } = props
    return {
      stepTitle: step.title,
      stepPromptSms: step.prompt.sms,
      stepStore: step.store || ''
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
          <li className='collection-item input-field header'>
            <i className='material-icons prefix'>mode_edit</i>
            <input
              placeholder='Untitled question'
              type='text'
              value={this.state.stepTitle}
              onChange={e => this.stepTitleChange(e)}
              onBlur={e => this.stepTitleSubmit(e)}
              className='editable-field'
              autoFocus />
            <a href='#!'
              className='right collapse'
              onClick={e => this.deselectStep(e)}>
              <i className='material-icons'>expand_less</i>
            </a>
          </li>
          <li className='collection-item'>
            <div className='row'>
              <div className='col s12 input-field'>
                <h5>Question Prompt</h5>
                <input
                  type='text'
                  placeholder='SMS message'
                  is length='140'
                  value={this.state.stepPromptSms}
                  onChange={e => this.stepPromptSmsChange(e)}
                  onBlur={e => this.stepPromptSmsSubmit(e)}
                  ref={ref => $(ref).characterCounter()}
                    />
              </div>
            </div>
          </li>
          <li className='collection-item'>
            <div className='row'>
              <div className='col s12'>
                {editor}
              </div>
            </div>
          </li>
          <li className='collection-item'>
            <div className='row'>
              <div className='col s4'>
                <p>Save this response as:</p>
              </div>
              <div className='col s8'>
                <input
                  type='text'
                  value={this.state.stepStore}
                  onChange={e => this.stepStoreChange(e)}
                  onBlur={e => this.stepStoreSubmit(e)}
                  />
              </div>
            </div>
          </li>
          <li className='collection-item'>
            <div className='row'>
              <a href='#!'
                className='right'
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
  actions: PropTypes.object.isRequired,
  step: PropTypes.object.isRequired
}

const mapDispatchToProps = (dispatch) => ({
  actions: bindActionCreators(actions, dispatch)
})

export default connect(null, mapDispatchToProps)(StepEditor)
