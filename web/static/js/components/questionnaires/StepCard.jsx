import React, { Component, PropTypes } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import * as questionnaireActions from '../../actions/questionnaire'
import { EditableTitleLabel, Card } from '../ui'

class StepCard extends Component {

  stepTitleSubmit(value) {
    const { stepId } = this.props
    this.props.questionnaireActions.changeStepTitle(stepId, value)
  }

  render() {
    const { onCollapse, stepId, children, icon, stepTitle, readOnly } = this.props

    return (
      <Card key={stepId}>
        <ul className='collection collection-card' id={`step-id-${stepId}`}>
          <li className='collection-item input-field header'>
            <div className='row'>
              <div className='col s12'>
                {icon}
                <EditableTitleLabel className='editable-field' title={stepTitle} readOnly={readOnly} entityName='question' onSubmit={value => this.stepTitleSubmit(value)} />
                <a href='#!'
                  className='collapse right'
                  onClick={e => {
                    e.preventDefault()
                    onCollapse()
                  }}>
                  <i className='material-icons'>expand_less</i>
                </a>
              </div>
            </div>
          </li>
          {children}
        </ul>
      </Card>
    )
  }
}

StepCard.propTypes = {
  icon: PropTypes.object.isRequired,
  stepTitle: PropTypes.string.isRequired,
  stepId: PropTypes.any.isRequired,
  children: PropTypes.node,
  onCollapse: PropTypes.func.isRequired,
  questionnaireActions: PropTypes.any,
  readOnly: PropTypes.bool
}

const mapDispatchToProps = (dispatch) => ({
  questionnaireActions: bindActionCreators(questionnaireActions, dispatch)
})

export default connect(null, mapDispatchToProps)(StepCard)
