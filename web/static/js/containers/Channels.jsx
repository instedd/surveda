import React, { Component } from 'react'
import { connect } from 'react-redux'
import * as actions from '../actions/channels'
import AddButton from '../components/AddButton'
import EmptyPage from '../components/EmptyPage'

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
        <AddButton text="Add channel" onClick={(e) => this.addChannel(e)} />
        { (Object.keys(channels).length == 0) ?
          <EmptyPage icon='assignment' title='You have no channels on this project' onClick={(e) => this.addChannel(e)} />
        :
          <div className="row">
            <div className="col s12">
              <div className="card">
                <div className="card-table">
                  <table>
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
              </div>
            </div>
          </div>
        }
      </div>
    )
  }
}

const mapStateToProps = (state) => ({
  channels: state.channels
})

export default connect(mapStateToProps)(Channels)
