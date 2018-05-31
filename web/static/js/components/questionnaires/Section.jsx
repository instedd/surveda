import React, { Component } from 'react'

import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import * as questionnaireActions from '../../actions/questionnaire'
import * as uiActions from '../../actions/ui'

import { translate } from 'react-i18next'

type Props = {
  children: any,
  title: string,
  id: string,
  readOnly: boolean,
  questionnaireActions: any,
  uiActions: any,
  randomize: boolean
};

class Section extends Component {
  props: Props;

  toggleRandomize(id, checked) {
  }

  questionnaireAddStep(e, sectionId) {
    e.preventDefault()

    // Add the step then automatically expand it
    this.props.questionnaireActions.addStepToSectionWithCallback(sectionId).then(step => {
      this.props.uiActions.selectStep(step.id, true)
    })
  }

  addStepComponent() {
    const { readOnly, id } = this.props

    return (
      readOnly ? null
      : <div className='row'>
        <div className='col s12'>
          <a href='#!' className='btn-flat blue-text no-padd' onClick={e => this.questionnaireAddStep(e, id)}>Add Step to Section</a>
        </div>
      </div>)
  }

  render() {
    const { title, id, randomize } = this.props
    return (
      <div className='section-container'>
        <div className='section-container-header'>
          <div className='switch'>
            <label>
              <input type='checkbox' checked={randomize} onChange={() => this.toggleRandomize(id, randomize)} />
              <span className='lever' />
              Randomize
            </label>
          </div>
          <div className='section-number'>{title}</div>
          <a href='#' className='close-section'>
            <i className='material-icons'>close</i>
          </a>
        </div>
        {this.props.children}
        {this.addStepComponent()}
      </div>
    )
  }
}

const mapDispatchToProps = (dispatch) => ({
  questionnaireActions: bindActionCreators(questionnaireActions, dispatch),
  uiActions: bindActionCreators(uiActions, dispatch)
})

export default translate()(connect(null, mapDispatchToProps)(Section))
