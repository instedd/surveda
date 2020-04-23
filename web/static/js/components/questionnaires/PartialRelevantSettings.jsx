// @flow
import React, { Component, PropTypes } from 'react'
import { translate } from 'react-i18next'
import { InputWithLabel } from '../ui'

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
      ignoredValues
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

  render() {
    const { readOnly, changeMinRelevantSteps, changeIgnoredValues, t } = this.props
    const { minRelevantSteps, ignoredValues } = this.state

    return <div>
      <InputWithLabel
        id='partial_relevant_min_relevant_steps'
        value={minRelevantSteps}
        label={t('Min Relevant Steps')}
        errors={this.minRelevantStepsErrors()}>
        <input
          type='text'
          onChange={e => this.handleMinRelevantStepsChange(e.target.value)}
          onBlur={() => changeMinRelevantSteps(parseInt(minRelevantSteps) || null)}
        />
      </InputWithLabel>
      <InputWithLabel id='partial_relevant_ignored_values' value={ignoredValues} label={t('Ignored Values')} readOnly={readOnly}>
        <input
          type='text'
          onChange={e => this.handleIgnoredValuesChange(e.target.value)}
          onBlur={() => changeIgnoredValues(ignoredValues)}
        />
      </InputWithLabel>
    </div>
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
