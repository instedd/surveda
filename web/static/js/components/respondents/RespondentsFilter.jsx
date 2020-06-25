// @flow
import React, { Component } from 'react'
import { translate } from 'react-i18next'
import AwesomeDebouncePromise from 'awesome-debounce-promise'

type Props = {
  t: Function,
  inputValue: string,
  onChange: Function,
  debounceMilliseconds: ?number,
  onApplyFilter: Function
}

type State = {
  inputValue: string,
  applyFilterDebounced: Function
}

class RespondentsFilter extends Component<Props, State> {
  constructor(props) {
    super(props)
    this.state = {
      inputValue: props.inputValue,
      applyFilterDebounced: AwesomeDebouncePromise(
        props.onApplyFilter,
        props.debounceMilliseconds || 2000
      )
    }
  }

  onInputChange = (event) => {
    const { onChange } = this.props
    const { applyFilterDebounced } = this.state
    const inputValue = event.target.value
    this.setState({ inputValue: inputValue })
    onChange(inputValue)
    applyFilterDebounced()
  }

  render = () => {
    const { t } = this.props
    const { inputValue } = this.state

    return (
      <div className='input-field'>
        <input
          value={inputValue}
          type='search'
          className='search-input'
          onChange={this.onInputChange}
        />
        <i className='material-icons grey-text'>search</i>
        <span className='small-text-bellow'>
          {t('Filter using the following format')}:&nbsp;
          <em>{t('disposition:completed since:2020-06-20')}</em>.&nbsp;
          <a
            href='https://github.com/instedd/surveda/wiki/How-to-filter-respondents'
            target='_blank'
          >
          View advanced search syntax
          </a>
        </span>
      </div>
    )
  }
}

export default translate()(RespondentsFilter)
