// @flow
import React, { Component, PropTypes } from 'react'
import { translate } from 'react-i18next'
import { InputWithLabel } from '../ui'

type State = {
  minRelevantSteps: ?number,
  ignoredValues: string
};

class PartialRelevantEditor extends Component<any, State> {
  constructor(props) {
    super(props)
    this.state = this.stateFromProps(props)
  }

  stateFromProps(props) {
    const { minRelevantSteps, ignoredValues } = this.props
    return {
      minRelevantSteps,
      ignoredValues
    }
  }

  handleMinRelevantStepsChange(changed) {
    if (changed) {
      const parsed = parseInt(changed)
      if (parsed > 0) {
        this.setState({ minRelevantSteps: parsed })
      }
    } else {
      this.setState({ minRelevantSteps: null })
    }
  }

  handleIgnoredValuesChange(changed) {
    this.setState({ ignoredValues: changed })
  }

  render() {
    const { readOnly, changeMinRelevantSteps, changeIgnoredValues, t } = this.props
    const { minRelevantSteps, ignoredValues } = this.state

    return <div>
      <InputWithLabel id='partial_relevant_min_relevant_steps' value={minRelevantSteps} label={t('Min Relevant Steps')}>
        <input
          type='number'
          value={minRelevantSteps}
          disabled={readOnly}
          onChange={e => this.handleMinRelevantStepsChange(e.target.value)}
          onBlur={() => changeMinRelevantSteps(minRelevantSteps)}
        />
      </InputWithLabel>
      <InputWithLabel id='partial_relevant_ignored_values' value={ignoredValues} label={t('Ignored Values')}>
        <input
          type='text'
          value={ignoredValues}
          disabled={readOnly}
          onChange={e => this.handleIgnoredValuesChange(e.target.value)}
          onBlur={() => changeIgnoredValues(ignoredValues)}
        />
      </InputWithLabel>
    </div>
  }
}

PartialRelevantEditor.propTypes = {
  t: PropTypes.func.isRequired,
  readOnly: PropTypes.bool.isRequired,
  changeMinRelevantSteps: PropTypes.func.isRequired,
  changeIgnoredValues: PropTypes.func.isRequired,
  minRelevantSteps: PropTypes.number.isRequired,
  ignoredValues: PropTypes.string.isRequired
}

export default translate()(PartialRelevantEditor)
