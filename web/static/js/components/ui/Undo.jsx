// @flow
import React, { Component } from "react"
import { withRouter } from "react-router"
import { bindActionCreators } from "redux"
import { connect } from "react-redux"
import { last } from "lodash"
import classNames from "classnames"

type Props = {
  state: ?DataStoreWithUndo<Object>,
  actions: any,
}

export class Undo extends Component<Props> {
  onUndoClick() {
    const { actions } = this.props
    actions.undo()
  }

  onRedoClick() {
    const { actions } = this.props
    actions.redo()
  }

  render() {
    const { state } = this.props

    if (!state) return null

    return (
      <span className="undo-buttons right">
        <i
          className={classNames("material-icons", {
            disabled: state.undo.length == 0,
          })}
          onClick={() => this.onUndoClick()}
        >
          undo
        </i>
        <i
          className={classNames("material-icons", {
            disabled: state.redo.length == 0,
          })}
          onClick={() => this.onRedoClick()}
        >
          redo
        </i>
      </span>
    )
  }
}

const mapStateToProps = (state, ownProps) => {
  const { routes } = ownProps
  const lastRoute = last(routes)

  if (lastRoute.undo) {
    return {
      state: lastRoute.undo.state(state),
    }
  } else {
    return {}
  }
}

const mapDispatchToProps = (dispatch, ownProps) => {
  const { routes } = ownProps
  const lastRoute = last(routes)

  if (lastRoute.undo) {
    return {
      actions: bindActionCreators(lastRoute.undo.actions, dispatch),
    }
  } else {
    return {}
  }
}

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(Undo))
