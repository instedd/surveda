import React, { Component } from 'react'
import { Link } from 'react-router'
import { connect } from 'react-redux'
import * as actions from '../../actions/channels'
import { Tooltip } from '../../components/Tooltip'

class Channels extends Component {
  componentDidMount() {
    const { dispatch } = this.props;
    dispatch(actions.fetchChannels());
  }

  addChannel(event) {
    event.preventDefault()
    const { dispatch } = this.props
    dispatch(actions.createNuntiumChannel()).then(x => console.log(x))
  }

  render() {
    const { channels } = this.props

    return (
      <div>
        <Tooltip text="Add channel">
          <a className="btn-floating btn-large waves-effect waves-light green right mtop" href='#' onClick={(e) => this.addChannel(e)}>
            <i className="material-icons">add</i>
          </a>
        </Tooltip>
        <table className="ncdtable">
          <thead>
            <tr>
              <th>Name</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            { Object.keys(channels).map(id =>
              <tr key={id}>{channels[id].name}</tr>
            )}
          </tbody>
        </table>
      </div>
    )
  }
}

const mapStateToProps = (state) => ({
  channels: state.channels
})

export default connect(mapStateToProps)(Channels)
