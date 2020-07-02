// @flow
import React, { Component } from 'react'
import { translate } from 'react-i18next'

type Props = {
  t: Function,
  inputValue: string,
  onChange: Function,
  onApplyFilter: Function
}

type State = {
  inputValue: string
}

class RespondentsFilter extends Component<Props, State> {
  _timeoutId = null

  constructor(props) {
    super(props)
    this.state = {
      inputValue: props.inputValue
    }
  }

  onInputChange = (event) => {
    const { onChange } = this.props
    const inputValue = event.target.value
    this.setState({ inputValue: inputValue })
    onChange(inputValue)
    this.applyFilter({ debounced: true })
  }

  onInputKeyPress = (event) => {
    if (event.key === 'Enter') this.applyFilter()
  }

  applyFilter = ({ debounced } = { debounced: false }) => {
    const { onApplyFilter } = this.props
    if (this._timeoutId != null) {
      clearTimeout(this._timeoutId)
      this._timeoutId = null
    }
    if (debounced) {
      this._timeoutId = setTimeout(() => {
        this._timeoutId = null
        onApplyFilter()
      }, 500)
    } else {
      onApplyFilter()
    }
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
          onKeyPress={this.onInputKeyPress}
        />
        <i className='material-icons grey-text'>search</i>
        <span className='small-text-bellow'>
          {t('Filter using the following format')}:&nbsp;
          <em>disposition:completed since:2020-06-20</em>.&nbsp;
          <a
            href='https://github.com/instedd/surveda/wiki/How-to-filter-respondents'
            target='_blank'
          >
            {t('View advanced search syntax')}
          </a>
        </span>
      </div>
    )
  }
}

export default translate()(RespondentsFilter)
