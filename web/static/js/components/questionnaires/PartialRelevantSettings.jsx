// @flow
import React, { Component } from 'react'
import Draft from './Draft'
import { translate } from 'react-i18next'
import { Card } from '../ui'

type State = {
  minRelevantSteps: ?number,
  minRelevantStepsKey: number
}

type Props = {
  t: Function,
  readOnly: boolean,
  changeMinRelevantSteps: Function,
  changeIgnoredValues: Function,
  minRelevantSteps: number,
  ignoredValues: string,
  errorsByPath: Object,
  relevantStepsQuantity: number
}

class PartialRelevantSettings extends Component<Props, State> {

  constructor(props) {
    super(props)
    this.state = this.stateFromProps(props)
  }

  stateFromProps(props) {
    const { minRelevantSteps } = props
    return {
      minRelevantSteps,
      minRelevantStepsKey: 0
    }
  }

  handleMinRelevantStepsOnBlur(changed) {
    const { changeMinRelevantSteps } = this.props
    const { minRelevantSteps, minRelevantStepsKey } = this.state
    let nextValue = null
    if (changed) {
      const onlyNumbers = /^\d+$/.test(changed)
      if (onlyNumbers) {
        const parsed = parseInt(changed)
        if (parsed > 0) {
          nextValue = parsed
        }
      }
    }
    if (!minRelevantSteps && !nextValue) {
      this.setState({ minRelevantSteps: nextValue, minRelevantStepsKey: minRelevantStepsKey + 1 })
    }
    changeMinRelevantSteps(nextValue)
  }

  errorsByPath(path) {
    return this.props.errorsByPath[path]
  }

  minRelevantStepsErrors() {
    return this.errorsByPath('partialRelevant.minRelevantSteps')
  }

  ignoredValuesErrors() {
    return this.errorsByPath('partialRelevant.ignoredValuesErrors')
  }

  hasErrors() {
    return !!this.minRelevantStepsErrors() ||
      !!this.ignoredValuesErrors()
  }

  minRelevantStepsComponent() {
    const { readOnly, t } = this.props
    const { minRelevantSteps, minRelevantStepsKey } = this.state

    return <Draft
      id='partial_relevant_min_relevant_steps'
      key={minRelevantStepsKey}
      value={(minRelevantSteps || '').toString()}
      label={t('Min Relevant Steps')}
      textBelow={`out of ${this.props.relevantStepsQuantity} relevant questions selected`}
      errors={this.minRelevantStepsErrors()}
      readOnly={readOnly}
      plainText
      onBlur={inputText => this.handleMinRelevantStepsOnBlur(inputText)}
    />
  }

  ignoredRelevantValuesComponent() {
    const { readOnly, ignoredValues, changeIgnoredValues, t } = this.props

    return <Draft
      id='partial_relevant_ignored_values'
      value={ignoredValues || ''}
      label={t('Ignored Values')}
      textBelow='Refused, Skip, etc.'
      errors={this.ignoredValuesErrors()}
      readOnly={readOnly}
      plainText
      onBlur={inputText => changeIgnoredValues(inputText)}
    />
  }

  render() {
    return (
      <div className='row' ref='self'>
        <Card className='z-depth-0'>
          <ul className='collection collection-card dark partial-relevant'>
            <li className='collection-item header'>
              <div className='row'>
                <div className='col s12'>
                  <i className='material-icons left'>build</i>
                  <a className='page-title truncate'>
                    <span>{this.props.t('Partial relevant settings')}</span>
                  </a>
                </div>
              </div>
            </li>
            <li className='collection-item'>
              {this.minRelevantStepsComponent()}
            </li>
            <li className='collection-item'>
              {this.ignoredRelevantValuesComponent()}
            </li>
          </ul>
        </Card>
      </div>
    )
  }
}

export default translate()(PartialRelevantSettings)
