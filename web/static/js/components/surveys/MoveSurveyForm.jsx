import React, { Component, PropTypes } from 'react'
import { translate, Trans } from 'react-i18next'
import { connect } from 'react-redux'
import { Input } from 'react-materialize'

class MoveSurveyForm extends Component<any> {
  static propTypes = {
    t: PropTypes.func,
    onCreate: PropTypes.func,
    onChangeName: PropTypes.func,
    projectId: PropTypes.number,
    defaultFolderId: PropTypes.number,
    onChangeFolderId: PropTypes.func,
    loading: PropTypes.boolean,
    errors: PropTypes.array,
    folders: PropTypes.array
  }

  constructor(props) {
    super(props)

    this.state = {
      folderId: props.defaultFolderId || ''
    }
  }

  onChangeFolderId(e) {
    this.props.onChangeFolderId(e.target.value)
    this.setState({ folderId: e.target.value })
  }

  render() {
    const { t, folders } = this.props
    const { folderId } = this.state

    return (
      <form>
        <p>
          <Trans>
            Please select the name of the folder you want to move to
          </Trans>
        </p>

        <Input type='select' value={folderId} onChange={e => this.onChangeFolderId(e)}>
          {[{name: t('No folder'), id: ''}, ...folders].map(({name, id}) => {
            return (
              <option key={`folder-${id}-${name}`} value={id}>
                {name}
              </option>
            )
          })}
        </Input>
      </form>
    )
  }
}

MoveSurveyForm.defaultProps = {
  onCreate: () => {},
  onChangeFolderId: () => {}
}

const mapStateToProps = (state, ownProps) => {
  return {
    ...ownProps,
    loading: state.folders.loading,
    errors: state.folders.errors || {},
    folders: Object.values(state.folders.items)
  }
}

export default translate()(connect(mapStateToProps)(MoveSurveyForm))
