import React, { Component, PropTypes } from 'react'
import { bindActionCreators } from 'redux'
import { connect } from 'react-redux'
import * as actions from '../actions/channels'
import { AddButton, EmptyPage, CardTable } from './ui'

class ChannelIndex extends Component {
  componentDidMount() {
    this.props.actions.fetchChannels()
  }

  addChannel(event) {
    event.preventDefault()
    this.props.actions.createNuntiumChannel()
  }

  render() {
    const { channels } = this.props
    const title = `${Object.keys(channels).length} ${(Object.keys(channels).length == 1) ? ' channel' : ' channels'}`

    return (
      <div>
        <AddButton text='Add channel' onClick={(e) => this.addChannel(e)} />
        { (Object.keys(channels).length == 0)
        ? <EmptyPage icon='assignment' title='You have no channels on this project' onClick={(e) => this.addChannel(e)} />
        : (
          <CardTable title={title} highlight>
            <thead>
              <tr>
                <th>Name</th>
              </tr>
            </thead>
            <tbody>
              { Object.keys(channels).map(id =>
                <tr key={id}>
                  <td>{channels[id].name}</td>
                </tr>
              )}
            </tbody>
          </CardTable>
          )
        }
      </div>
    )
  }
}

ChannelIndex.propTypes = {
  actions: PropTypes.object.isRequired,
  channels: PropTypes.object
}

const mapStateToProps = (state) => ({
  channels: state.channels
})

const mapDispatchToProps = (dispatch) => ({
  actions: bindActionCreators(actions, dispatch)
})

export default connect(mapStateToProps, mapDispatchToProps)(ChannelIndex)
