import React, { Component, PropTypes } from 'react'
import { translate, Trans } from 'react-i18next'
import { Input } from 'react-materialize'
import { connect } from 'react-redux'
import * as actions from '../../actions/folder'

class CreateFolderForm extends Component<any> {
  state = { name: '' }
  static propTypes = {
    t: PropTypes.func,
    dispatch: PropTypes.func,
    loading: PropTypes.boolean,
    errors: PropTypes.array,
    onCreate: PropTypes.func,
    onChangeName: PropTypes.func,
    projectId: PropTypes.number
  }

  onChangeName(e) {
    this.props.onChangeName(e.target.value)
    this.setState({ name: e.target.value })
  }

  onSubmit(e) {
    e.preventDefault()

    const { dispatch, projectId, onCreate } = this.props
    const { name } = this.state
    dispatch(actions.createFolder(projectId, name))
      .then(res => {
        if (res.errors) return
        onCreate()
      })
  }

  render() {
    const { t, loading, errors } = this.props
    const { name } = this.state

    return (
      <form onSubmit={e => this.onSubmit(e)}>

        <p>
          <Trans>
            Please write the name of the folder you want to create
          </Trans>
        </p>

        <ul className='red-text'>
          {(errors['name'] || []).map(error => <li>Name: {error}</li>)}
        </ul>
        <Input disabled={loading} placeholder={t('Name')} value={name} onChange={e => this.onChangeName(e)} />
      </form>
    )
  }
}

CreateFolderForm.defaultProps = {
  onCreate: () => {},
  onChangeName: () => {}
}

const mapStateToProps = (state, ownProps) => {
  return {
    ...ownProps,
    loading: state.folder.loading,
    errors: state.folder.errors || {}
  }
}

export default translate()(connect(mapStateToProps)(CreateFolderForm))
