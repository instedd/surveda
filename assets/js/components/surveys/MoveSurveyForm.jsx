import React, { Component, PropTypes } from "react"
import { translate, Trans } from "react-i18next"
import { connect } from "react-redux"
import { Input } from "react-materialize"
import { fetchFolders } from "actions/folders"

class MoveSurveyForm extends Component<any> {
  static propTypes = {
    t: PropTypes.func,
    dispatch: PropTypes.func,
    onCreate: PropTypes.func,
    onChangeName: PropTypes.func,
    projectId: PropTypes.number,
    defaultFolderId: PropTypes.number,
    onChangeFolderId: PropTypes.func,
    loading: PropTypes.bool,
    errors: PropTypes.object,
    folders: PropTypes.array,
  }

  constructor(props) {
    super(props)

    this.state = {
      folderId: props.defaultFolderId || "",
    }
  }

  componentDidMount() {
    const { dispatch, folders, projectId } = this.props
    if (!folders) {
      dispatch(fetchFolders(projectId))
    }
  }

  onChangeFolderId(e) {
    this.props.onChangeFolderId(e.target.value)
    this.setState({ folderId: e.target.value })
  }

  render() {
    const { t, folders, loading } = this.props
    const { folderId } = this.state

    if (loading) {
      return <div>{t("Loading...")}</div>
    }

    return (
      <form>
        <p>
          <Trans>Please select the name of the folder you want to move to</Trans>
        </p>

        <Input type="select" value={folderId} onChange={(e) => this.onChangeFolderId(e)}>
          {[{ name: t("No folder"), id: "" }, ...folders].map(({ name, id }) => {
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
  onChangeFolderId: () => {},
}

const mapStateToProps = (state, ownProps) => {
  let folders = state.folders.items
  let loading = state.folders.loading

  if (folders) {
    folders = Object.values(folders)
  } else {
    loading = true
  }

  return {
    ...ownProps,
    loading: loading,
    errors: state.folders.errors || {},
    folders: folders,
  }
}

export default translate()(connect(mapStateToProps)(MoveSurveyForm))
