import React, { Component, PropTypes } from 'react'
import { translate, Trans } from 'react-i18next'
import { Input } from 'react-materialize'
import { connect } from 'react-redux'
import * as actions from '../../actions/folder'

class CreateFolderForm extends Component<any> {
  state = { name: '' }
  static propTypes = {
    t: PropTypes.func,
    onCreate: PropTypes.func,
    onChangeName: PropTypes.func,
    projectId: PropTypes.number
  }

  onChangeName(e){
    console.log(e.target.value)
    this.props.onChangeName(e.target.value)
    this.setState({ name: e.target.value })
  }

  onSubmit () {
    const { dispatch, projectId, onCreate } = this.props
    const { name } = this.state
    dispatch(actions.createFolder(projectId, name))
      .then(() => onCreate())
  }

  render () {
    const { t, loading } = this.props
    const { name } = this.state

    return (
      <form onSubmit={e => this.onSubmit(e)}>
        <p>
          <Trans>
            Please write the name of the folder you want to create
          </Trans>
        </p>
        <Input disabled={loading} placeholder={t('Name')} value={name} onChange={e => this.onChangeName(e)}/>
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
    loading: state.folder.loading
  }
}

export default translate()(connect(mapStateToProps)(CreateFolderForm))