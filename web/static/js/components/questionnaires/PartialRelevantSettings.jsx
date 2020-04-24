// @flow
import React, { Component } from 'react'
import Draft from './Draft'
import { translate } from 'react-i18next'
import { Card } from '../ui'

type Props = {
  t: Function,
  readOnly: boolean,
  changeMinRelevantSteps: Function,
  changeIgnoredValues: Function,
  minRelevantSteps: number,
  ignoredValues: string,
  errorsByPath: Object
}

class PartialRelevantSettings extends Component<Props> {
  handleMinRelevantStepsOnBlur(changed) {
    const { changeMinRelevantSteps } = this.props
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
    const { minRelevantSteps, readOnly, t } = this.props

    return <Draft
      id='partial_relevant_min_relevant_steps'
      value={(minRelevantSteps || '').toString()}
      label={t('Min Relevant Steps')}
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
      errors={this.ignoredValuesErrors()}
      readOnly={readOnly}
      plainText
      onBlur={inputText => changeIgnoredValues(inputText || null)}
    />
  }

  render() {
    return (
      <div className='row' ref='self'>
        <Card className='z-depth-0'>
          <ul className='collection collection-card dark'>
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
