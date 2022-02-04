import React, { Component, PropTypes } from 'react'
import { translate } from 'react-i18next'
import { Input } from 'react-materialize'
import { connect } from 'react-redux'

class FolderForm extends Component<any> {
  state = { name: '' }
  static propTypes = {
    t: PropTypes.func,
    error: PropTypes.string,
    onChangeName: PropTypes.func,
    cta: PropTypes.string
  }

  onChangeName(e) {
    this.props.onChangeName(e.target.value)
    this.setState({ name: e.target.value })
  }

  onSubmit(e) {
    e.preventDefault()
  }

  render() {
    const { t, error, cta } = this.props
    const { name } = this.state

    return (
      <form onSubmit={e => this.onSubmit(e)}>

        <p>
          {cta}
        </p>

        <Input className='folder-input' placeholder={t('Name')} value={name} onChange={e => this.onChangeName(e)} error={error} />
        <div className='error'>
          {error}
        </div>
      </form>
    )
  }
}

FolderForm.defaultProps = {
  onChangeName: () => {}
}

const mapStateToProps = (state, ownProps) => {
  let error

  if (ownProps.id) {
    error = state.folders.items[ownProps.id] && state.folders.items[ownProps.id].error
  } else {
    error = state.folders.error
  }

  return {
    ...ownProps,
    error: error
  }
}

export default translate()(connect(mapStateToProps)(FolderForm))
