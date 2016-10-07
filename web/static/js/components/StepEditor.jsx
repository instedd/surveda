import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import * as actions from '../actions/questionnaireEditor'
import Card from '../components/Card'

class StepEditor extends Component {
  deselectStep (e) {
    e.preventDefault()
    this.props.dispatch(actions.deselectStep())
  }

  editTitle (e) {
    e.preventDefault()
    this.props.dispatch(actions.editTitle())
  }

  delete (e) {
    e.preventDefault()
    this.props.dispatch(actions.deleteStep())
  }

  render () {
    const { step } = this.props

    return (
      <Card key={step.title}>
        <ul className='collection'>
          <li className='collection-item'>
            <div className='row'>
              <RenderTitle step={step} />
              <div>
                <a href='#!'
                  className='col s1'
                  onClick={(e) => this.deselectStep(e)}>
                  Deselect
                </a>
              </div>
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

const RenderTitle = ({step}) => {
  return (
    <div className='col s10'>
      <input
        placeholder='Untitled question'
        id='question_title'
        type='text'
        defaultValue={step.title}
        autoFocus />
    </div>
  )
}

export default connect()(StepEditor)
