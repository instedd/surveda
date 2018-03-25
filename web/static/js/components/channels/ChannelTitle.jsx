import React, { PropTypes, Component } from 'react'
import { connect } from 'react-redux'
import { UntitledIfEmpty } from '../ui'
import { translate } from 'react-i18next'
import classNames from 'classnames/bind'

class ChannelTitle extends Component {
  static propTypes = {
    t: PropTypes.func,
    channel: PropTypes.object
  }

  render() {
    const { channel, t } = this.props
    if (channel == null) return null

    return <div className={classNames({'page-title': true, 'truncate': (channel.name && channel.name.trim() != '')})}>
      <UntitledIfEmpty text={channel.name} emptyText={t('Untitled channel')} />
    </div>
  }
}

const mapStateToProps = (state, ownProps) => {
  return {
    channel: state.channel.data
  }
}

export default translate()(connect(mapStateToProps)(ChannelTitle))
