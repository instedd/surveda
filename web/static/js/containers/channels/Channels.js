import React, { Component } from 'react'
import { Link } from 'react-router'
import { connect } from 'react-redux'
import * as actions from '../../actions/channels'

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
        <a href='#' onClick={(e) => this.addChannel(e)}>Add channel</a>
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
      </div>
    )
  }
}

const mapStateToProps = (state) => ({
  channels: state.channels
})

export default connect(mapStateToProps)(Channels)
