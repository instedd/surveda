// @flow
import React, { Component } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import { Dropdown, DropdownItem } from '../ui'
import * as questionnaireActions from '../../actions/questionnaire'

type Props = {
  stepType: string,
  readOnly: boolean,
  quotaCompletedSteps?: boolean,
  stepId: any,
  questionnaireActions: any
};

class StepTypeSelector extends Component {
  props: Props

  changeStepType(type) {
    this.props.questionnaireActions.changeStepType(this.props.stepId, type)
  }

  render() {
    const { stepType, readOnly, quotaCompletedSteps } = this.props

    const label = (() => {
      switch (stepType) {
        case 'multiple-choice':
          return <i className='material-icons'>list</i>
        case 'numeric':
          return <i className='material-icons sharp'>dialpad</i>
        case 'explanation':
          return <i className='material-icons sharp'>chat_bubble_outline</i>
        case 'flag':
          return <i className='material-icons sharp'>flag</i>
        default:
          throw new Error(`unknown step type: ${stepType}`)
      }
    })()

    return (<div className='left'>
      <Dropdown className='step-mode' readOnly={readOnly} label={label} constrainWidth={false} dataBelowOrigin={false}>
        <DropdownItem>
          <a onClick={e => this.changeStepType('multiple-choice')}>
            <i className='material-icons left'>list</i>
            Multiple choice
            {stepType == 'multiple-choice' ? <i className='material-icons right'>done</i> : ''}
          </a>
        </DropdownItem>
        <DropdownItem>
          <a onClick={e => this.changeStepType('numeric')}>
            <i className='material-icons left sharp'>dialpad</i>
            Numeric
            {stepType == 'numeric' ? <i className='material-icons right'>done</i> : ''}
          </a>
        </DropdownItem>
        <DropdownItem>
          <a onClick={e => this.changeStepType('explanation')}>
            <i className='material-icons left sharp'>chat_bubble_outline</i>
            Explanation
            {stepType == 'explanation' ? <i className='material-icons right'>done</i> : ''}
          </a>
        </DropdownItem>
        { quotaCompletedSteps
        ? null
        : <DropdownItem>
          <a onClick={e => this.changeStepType('flag')}>
            <i className='material-icons left sharp'>flag</i>
            Flag
            {stepType == 'flag' ? <i className='material-icons right'>done</i> : ''}
          </a>
        </DropdownItem> }
      </Dropdown>
    </div>
    )
  }
}

const mapDispatchToProps = (dispatch) => ({
  questionnaireActions: bindActionCreators(questionnaireActions, dispatch)
})

export default connect(null, mapDispatchToProps)(StepTypeSelector)
