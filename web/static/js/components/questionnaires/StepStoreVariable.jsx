// @flow
import React, { Component } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import { Autocomplete } from '../ui'
import * as questionnaireActions from '../../actions/questionnaire'
import * as api from '../../api.js'

type Props = {
  step: StoreStep & BaseStep,
  questionnaireActions: any,
  project: any,
};

type State = {
  stepStore: string
};

class StepStoreVariable extends Component {
  props: Props
  state: State

  constructor(props) {
    super(props)
    this.state = this.stateFromProps(props)
  }

  stepStoreChange(e, value) {
    if (this.refs.autocomplete.clickingAutocomplete) return
    if (e) e.preventDefault()
    this.setState({stepStore: value})
  }

  stepStoreSubmit(e, value) {
    if (this.refs.autocomplete.clickingAutocomplete) return
    this.refs.autocomplete.hide()

    if (e) e.preventDefault()
    const { step } = this.props
    this.props.questionnaireActions.changeStepStore(step.id, value)
  }

  componentWillReceiveProps(newProps) {
    this.setState(this.stateFromProps(newProps))
  }

  stateFromProps(props) {
    const { step } = props

    return {
      stepStore: step.store || ''
    }
  }

  autocompleteGetData(value, callback) {
    const { project } = this.props

    api.autocompleteVars(project.id, value)
    .then(response => {
      callback(value, response.map(x => ({id: x, text: x})))
    })
  }

  autocmpleteOnSelect(item) {
    this.stepStoreChange(null, item.text)
    this.stepStoreSubmit(null, item.text)
  }

  render() {
    return (<li className='collection-item' key='variable_name'>
      <div className='row'>
        <div className='col s12'>
          Variable name:
          <div className='input-field inline'>
            <input
              type='text'
              value={this.state.stepStore}
              onChange={e => this.stepStoreChange(e, e.target.value)}
              onBlur={e => this.stepStoreSubmit(e, e.target.value)}
              autoComplete='off'
              className='autocomplete'
              ref='varInput'
            />
            <Autocomplete
              getInput={() => this.refs.varInput}
              getData={(value, callback) => this.autocompleteGetData(value, callback)}
              onSelect={(item) => this.autocmpleteOnSelect(item)}
              ref='autocomplete'
              className='var-dropdown'
              />
          </div>
        </div>
      </div>
    </li>
    )
  }

}

const mapStateToProps = (state, ownProps) => ({
  project: state.project.data
})

const mapDispatchToProps = (dispatch) => ({
  questionnaireActions: bindActionCreators(questionnaireActions, dispatch)
})

export default connect(mapStateToProps, mapDispatchToProps)(StepStoreVariable)
