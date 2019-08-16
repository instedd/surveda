import React, { Component, PropTypes } from 'react'
import { translate, Trans } from 'react-i18next'
import { Input } from 'react-materialize'
import { connect } from 'react-redux'
import * as actions from '../../actions/folder'

class FolderForm extends Component<any> {
  state = { name: '' }
  static propTypes = {
    t: PropTypes.func,
    errors: PropTypes.array,
    onChangeName: PropTypes.func,
    cta: PropTypes.string
  }

  onChangeName(e) {
    this.props.onChangeName(e.target.value)
    this.setState({ name: e.target.value })
  }

  onSubmit(e) {
    e.preventDefault()
    const { name } = this.state
  }

  render() {
    const { t, errors, cta } = this.props
    const { name } = this.state

    return (
      <form onSubmit={e => this.onSubmit(e)}>

        <p>
          <Trans>
            {cta}
          </Trans>
        </p>

        <ul className='red-text'>
          {(errors['name'] || []).map(error => <li>Name: {error}</li>)}
        </ul>
        <Input placeholder={t('Name')} value={name} onChange={e => this.onChangeName(e)} />
      </form>
    )
  }
}

FolderForm.defaultProps = {
  onChangeName: () => {}
}

const mapStateToProps = (state, ownProps) => {
  return {
    ...ownProps,
    errors: state.folder.errors || {}
  }
}

export default translate()(connect(mapStateToProps)(FolderForm))
