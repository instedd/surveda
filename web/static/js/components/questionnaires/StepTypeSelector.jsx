// @flow
import React, { Component } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import { Dropdown, DropdownItem } from '../ui'
import * as questionnaireActions from '../../actions/questionnaire'

type Props = {
  stepType: string,
  readOnly: boolean,
  stepId: any,
  questionnaireActions: any
};

class StepTypeSelector extends Component {
  props: Props

  changeStepType(type) {
    this.props.questionnaireActions.changeStepType(this.props.stepId, type)
  }

  render() {
    const { stepType, readOnly } = this.props
    return (<div className='left'>
      <Dropdown className='step-mode' readOnly={readOnly} label={stepType == 'multiple-choice' ? <i className='material-icons'>list</i> : stepType == 'numeric' ? <i className='material-icons sharp'>dialpad</i> : <i className='material-icons sharp'>chat_bubble_outline</i>} constrainWidth={false} dataBelowOrigin={false}>
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
      </Dropdown>
    </div>
    )
  }
}

const mapDispatchToProps = (dispatch) => ({
  questionnaireActions: bindActionCreators(questionnaireActions, dispatch)
})

const mapStateToProps = (state, ownProps) => {
  return {
    readOnly: state.project && state.project.data ? state.project.data.readOnly : true
  }
}

export default connect(mapStateToProps, mapDispatchToProps)(StepTypeSelector)
