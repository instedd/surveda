import React, { PropTypes, Component } from 'react'
import { connect } from 'react-redux'
import { withRouter } from 'react-router'
import ProjectsList from './ProjectsList'
import * as actions from '../../actions/channel'
import * as projectsActions from '../../actions/projects'
import * as routes from '../../routes'
import { translate } from 'react-i18next'

class ChannelEdit extends Component {
  static propTypes = {
    t: PropTypes.func,
    dispatch: PropTypes.func,
    channelId: PropTypes.any.isRequired,
    router: PropTypes.object.isRequired,
    channel: PropTypes.object,
    projects: PropTypes.object
  }

  componentWillMount() {
    const { dispatch, channelId } = this.props

    if (channelId) {
      dispatch(actions.fetchChannelIfNeeded(channelId))
      dispatch(projectsActions.fetchProjects())
    }
  }

  componentDidUpdate() {
    const { channel, router } = this.props
    if (channel && channel.state && channel.state != 'not_ready' && channel.state != 'ready') {
      router.replace(routes.channel(channel.id))
    }
  }

  onCancelClick() {
    const { router } = this.props
    return () => router.push(routes.channels)
  }

  onConfirmClick() {
    const { router, dispatch } = this.props
    return () => {
      router.push(routes.channels)
      dispatch(actions.updateChannel())
    }
  }

  render() {
    const { channel, t, projects } = this.props

    if (!channel || !projects) {
      return <div>{t('Loading...')}</div>
    }

    return (
      <div className='white'>
        <div className='row'>
          <div className='col s12 m6 push-m3'>
            <h4>{t('Share this channel on different projects')}</h4>
            <p className='flow-text'>
              {t('Every user with permissions to execute surveys will be able to use your channel')}
            </p>
            <ProjectsList selectedProjects={channel.projects} />
          </div>
        </div>
        <div className='row'>
          <div className='col s12 m6 push-m3'>
            <a href='#!' className='btn blue right' onClick={this.onConfirmClick()}>{t('Update')}</a>
            <a href='#!' onClick={this.onCancelClick()} className='btn-flat right'>{t('Cancel')}</a>
          </div>
        </div>
      </div>
    )
  }
}

const mapStateToProps = (state, ownProps) => ({
  channelId: ownProps.params.channelId,
  projects: state.projects.items,
  channel: state.channel.data
})

export default translate()(withRouter(connect(mapStateToProps)(ChannelEdit)))
