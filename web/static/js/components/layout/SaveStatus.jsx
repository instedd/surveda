import React, { PropTypes, Component } from 'react'
import { connect } from 'react-redux'
import TimeAgo from 'react-timeago'
import { withRouter } from 'react-router'

class SaveStatus extends Component {
  static propTypes = {
    saveStatus: PropTypes.any,
    routes: PropTypes.any
  }

  render() {
    const { saveStatus, routes } = this.props

    let show = false

    for (var i = routes.length - 1; i >= 0; i--) {
      if (routes[i].showSavingStatus) {
        show = true
        break
      }
    }

    if (show && saveStatus && (saveStatus.saving || saveStatus.updatedAt)) {
      if (saveStatus.saving) {
        return (
          <div className='right grey-text'>Saving...</div>
        )
      } else {
        return (
          <div className='right grey-text'>Last saved <TimeAgo minPeriod='10' date={saveStatus.updatedAt + '+0000'} /></div>
        )
      }
    } else {
      return (<div />)
    }
  }
}
const mapStateToProps = (state, ownProps) => ({
  saveStatus: state.saveStatus || {}
})

export default withRouter(connect(mapStateToProps)(SaveStatus))
