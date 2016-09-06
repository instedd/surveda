import React, { Component } from 'react'
import { connect } from 'react-redux'
import * as actions from '../../actions/channels'

class Channels extends Component {
  componentDidMount() {
    const { dispatch } = this.props;
    dispatch(actions.fetchChannels());
  }

  render() {
    const { channels } = this.props

    return (
      <table style={{width: '300px'}}>
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
    )
  }
}

const mapStateToProps = (state, ownProps) => {
  return {
    channels: state.channels
  }
}

export default connect(mapStateToProps)(Channels)
