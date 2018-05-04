// @flow
import React, { Component } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import { Autocomplete } from '../ui'
import * as questionnaireActions from '../../actions/questionnaire'
import * as api from '../../api.js'
import propsAreEqual from '../../propsAreEqual'
import map from 'lodash/map'
import { translate } from 'react-i18next'

type Props = {
  t: Function,
  step: StoreStep & BaseStep,
  questionnaireActions: any,
  errorPath: string,
  errorsByPath: ErrorsByPath,
  project: any,
  readOnly: boolean
};

type State = {
  stepStore: string
};

class StepStoreVariable extends Component<Props, State> {
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
    if (propsAreEqual(this.props, newProps)) return

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
    const { errorPath, errorsByPath, t } = this.props
    let errors = errorsByPath[`${errorPath}.store`]

    let dataError = null
    let className = 'autocomplete'
    if (errors && errors.length > 0) {
      className += ' validate invalid'
      dataError = map(errors, (error) => t(...error)).join(', ')
    }

    return (<li className='collection-item' key='variable_name'>
      <div className='row'>
        <div className='col s12'>
          {t('Variable name:')}
          <div className='input-field inline min-width'>
            <input
              type='text'
              disabled={this.props.readOnly}
              value={this.state.stepStore}
              onChange={e => this.stepStoreChange(e, e.target.value)}
              onBlur={e => this.stepStoreSubmit(e, e.target.value)}
              autoComplete='off'
              className={className}
              draggable
              onDragStart={e => { e.stopPropagation(); e.preventDefault(); return false }}
              ref='varInput'
            />
            <label data-error={dataError} />
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

export default translate()(connect(mapStateToProps, mapDispatchToProps)(StepStoreVariable))
