import React, { PropTypes, Component } from 'react'
import { connect } from 'react-redux'
import { translate } from 'react-i18next'
import { bindActionCreators } from 'redux'
import * as routes from '../../routes'
import * as actions from '../../actions/channel'

class Pattern extends Component {
  static propTypes = {
    input: PropTypes.string.isRequired,
    output: PropTypes.string.isRequired,
    index: PropTypes.number.isRequired,
    actions: PropTypes.object.isRequired,
    t: PropTypes.func
  }

  constructor(props) {
    super(props)
    this.state = {input: props.input, output: props.output}
  }

  inputPatternChange(e, value) {
    if (e) e.preventDefault()
    this.setState({input: value})
  }

  inputPatternSubmit(e, value) {
    const { index, actions } = this.props
    if (e) e.preventDefault()
    actions.changeInputPattern(index, value)
  }

  outputPatternChange(e, value) {
    if (e) e.preventDefault()
    this.setState({output: value})
  }

  outputPatternSubmit(e, value) {
    const { index, actions } = this.props
    if (e) e.preventDefault()
    actions.changeOutputPattern(index, value)
  }

  removePattern() {
    const { index, actions } = this.props
    actions.removePattern(index)
  }

  render() {
    const { input, output } = this.state
    return (
      <div className='row'>
        <div className='col s1'>
          <a onClick={() => this.removePattern()} style={{'cursor': 'pointer'}}>
            <i className='material-icons v-middle'>clear</i>
          </a>
        </div>
        <div className='col s5'>
          <label>{this.props.t('Input')}</label>
          <input
            type='text'
            value={input}
            onChange={e => this.inputPatternChange(e, e.target.value)}
            onBlur={e => this.inputPatternSubmit(e, e.target.value)}
          />
          <span>{this.props.t('Input example')}</span>
        </div>
        <div className='col s1'>
          <i className='material-icons v-middle'>arrow_forward</i>
        </div>
        <div className='col s5'>
          <label>{this.props.t('Output')}</label>
          <input
            type='text'
            value={output}
            onChange={e => this.outputPatternChange(e, e.target.value)}
            onBlur={e => this.outputPatternSubmit(e, e.target.value)}
          />
          <span>{this.props.t('Output example')}</span>
        </div>
      </div>
    )
  }
}

class ChannelPatterns extends Component {
  static propTypes = {
    t: PropTypes.func,
    channelId: PropTypes.string.isRequired,
    actions: PropTypes.object.isRequired,
    router: PropTypes.object.isRequired,
    patterns: PropTypes.array
  }

  componentWillMount() {
    const { channelId, actions } = this.props

    if (channelId) {
      actions.fetchChannelIfNeeded(channelId)
    }
  }

  addPattern(e) {
    this.props.actions.addPattern()
  }

  onCancelClick() {
    const { router } = this.props
    return () => router.push(routes.channels)
  }

  onConfirmClick() {
    const { router, actions } = this.props
    return () => {
      router.push(routes.channels)
      actions.updateChannel()
    }
  }

  render() {
    const { t, patterns, actions } = this.props
    if (!patterns) {
      return <div>{t('Loading...')}</div>
    }

    return (
      <div className='white'>
        <div className='row'>
          <div className='col s12 m6 push-m3'>
            <h4>{t('Apply patterns for numbers cleanup')}</h4>
            <p className='flow-text'>
              {t('Use different expressions in order to standardize the source phone number.')}
            </p>
            {
              patterns.map((p, index) =>
                <Pattern key={`${index}-${p.input}-${p.output}`} index={index} input={p.input} output={p.output} actions={actions} t={t} />
              )
            }
            <div className='col s12'>
              <a href='#!' className='btn-flat blue-text no-padd' onClick={e => this.addPattern(e)}>
                <i className='material-icons v-middle blue-text left'>add</i>
                {t('Add Pattern')}
              </a>
            </div>
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

const mapStateToProps = (state, ownProps) => {
  const patterns = state.channel.data ? state.channel.data.patterns : null
  return {
    channelId: ownProps.params.channelId,
    patterns: patterns
  }
}

const mapDispatchToProps = (dispatch) => ({
  actions: bindActionCreators(actions, dispatch)
})

export default translate()(connect(mapStateToProps, mapDispatchToProps)(ChannelPatterns))
