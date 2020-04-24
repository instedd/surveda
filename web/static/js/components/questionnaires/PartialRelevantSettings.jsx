// @flow
import React, { Component, PropTypes } from 'react'
import Draft from './Draft'
import { translate } from 'react-i18next'
import { Card } from '../ui'

type State = {
  minRelevantSteps: string,
  ignoredValues: string
};

class PartialRelevantSettings extends Component<any, State> {
  constructor(props) {
    super(props)
    this.state = this.stateFromProps(props)
  }

  stateFromProps(props) {
    const { minRelevantSteps, ignoredValues } = this.props
    return {
      minRelevantSteps: minRelevantSteps || '',
      ignoredValues: ignoredValues  || ''
    }
  }

  handleMinRelevantStepsChange(changed) {
    if (changed) {
      const onlyNumbers = /^\d+$/.test(changed)
      if (onlyNumbers) {
        const parsed = parseInt(changed)
        if (parsed > 0) {
          this.setState({ minRelevantSteps: parsed.toString() })
        }
      }
    } else {
      this.setState({ minRelevantSteps: '' })
    }
  }

  handleIgnoredValuesChange(changed) {
    this.setState({ ignoredValues: changed })
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
    const { readOnly, changeMinRelevantSteps, t } = this.props
    const { minRelevantSteps } = this.state

    return <Draft
      id='partial_relevant_min_relevant_steps'
      value={minRelevantSteps}
      label={t('Min Relevant Steps')}
      errors={this.minRelevantStepsErrors()}
      readOnly={readOnly}
      plainText
      onBlur={() => changeMinRelevantSteps(parseInt(minRelevantSteps) || null)}
      onChange={e => this.handleMinRelevantStepsChange(e.target.value)}
    />
  }

  ignoredRelevantValuesComponent() {
    const { readOnly, changeIgnoredValues, t } = this.props
    const { ignoredValues } = this.state

    return <Draft
      id='partial_relevant_ignored_values'
      value={ignoredValues}
      label={t('Ignored Values')}
      errors={this.ignoredValuesErrors()}
      readOnly={readOnly}
      plainText
      onBlur={() => changeIgnoredValues(parseInt(ignoredValues) || null)}
      onChange={e => this.handleIgnoredValuesChange(e.target.value)}
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

PartialRelevantSettings.propTypes = {
  t: PropTypes.func.isRequired,
  readOnly: PropTypes.bool.isRequired,
  changeMinRelevantSteps: PropTypes.func.isRequired,
  changeIgnoredValues: PropTypes.func.isRequired,
  minRelevantSteps: PropTypes.string,
  ignoredValues: PropTypes.string,
  errorsByPath: PropTypes.object
}

export default translate()(PartialRelevantSettings)
