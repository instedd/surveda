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
    errors: PropTypes.object,
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

  exampleUsingDigits(pattern, digits) {
    let digitIndex = 0
    const example = Array(pattern.length)
    for (let i = 0; i < pattern.length; i++) {
      if (pattern[i] == 'X') {
        example[i] = digits[digitIndex]
        digitIndex++
      } else {
        example[i] = pattern[i]
      }
    }
    return example.join('')
  }

  computeDigitsForExample(numberOfXs) {
    const digits = Array(numberOfXs)
    for (let i = 0; i < numberOfXs; i++) {
      // (i+5)*7 % 10 computes a digit between 0-9 in an (arbitrary) deterministic way
      digits[i] = (i + 5) * 7 % 10
    }
    return digits
  }

  render() {
    const { input, output } = this.state
    const { errors } = this.props

    // Compute digits optimistically
    const inputXsCount = (input.match(/X/g) || []).length
    const outputXsCount = (output.match(/X/g) || []).length
    // Same digits must be used for both input and output patterns, so they're stored in a var
    const digits = this.computeDigitsForExample(Math.max(inputXsCount, outputXsCount))

    let inputPattern
    if (errors && errors['input']) {
      inputPattern = (<div className='col s5'>
        <label className='label-error'>{this.props.t('Input')}</label>
        <input
          type='text'
          value={input}
          onChange={e => this.inputPatternChange(e, e.target.value)}
          onBlur={e => this.inputPatternSubmit(e, e.target.value)}
          className='invalid'
        />
        <span className={'error'}>{errors['input'][0]}</span>
      </div>)
    } else {
      inputPattern = (<div className='col s5'>
        <label className='grey-text'>{this.props.t('Input')}</label>
        <input
          type='text'
          value={input}
          onChange={e => this.inputPatternChange(e, e.target.value)}
          onBlur={e => this.inputPatternSubmit(e, e.target.value)}
        />
        <span className='small-text-bellow'>{'Input sample: ' + this.exampleUsingDigits(input, digits)}</span>
      </div>)
    }

    let outputPattern
    if (errors && errors['output']) {
      outputPattern = (<div className='col s5'>
        <label className='label-error'>{this.props.t('Output')}</label>
        <input
          type='text'
          value={output}
          onChange={e => this.outputPatternChange(e, e.target.value)}
          onBlur={e => this.outputPatternSubmit(e, e.target.value)}
          className='invalid'
        />
        <span className='error'>{errors['output'][0]}</span>
      </div>)
    } else {
      outputPattern = (<div className='col s5'>
        <label className='grey-text'>{this.props.t('Output')}</label>
        <input
          type='text'
          value={output}
          onChange={e => this.outputPatternChange(e, e.target.value)}
          onBlur={e => this.outputPatternSubmit(e, e.target.value)}
        />
        <span className='small-text-bellow'>{'Output sample: ' + this.exampleUsingDigits(output, digits)}</span>
      </div>)
    }

    return (
      <div className='row channel-pattern'>
        <div className='col s1 bottom-align'>
          <a onClick={() => this.removePattern()} className='grey-text text-lighten-1'>
            <i className='material-icons v-middle'>clear</i>
          </a>
        </div>
        {inputPattern}
        <div className='col s1 valign-wrapper'>
          <i className='material-icons grey-text text-lighten-1'>arrow_forward</i>
        </div>
        {outputPattern}
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
    patterns: PropTypes.array,
    errorsByPath: PropTypes.object.isRequired
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
    const { t, patterns, actions, errorsByPath } = this.props
    if (!patterns) {
      return <div>{t('Loading...')}</div>
    }

    return (
      <div className='white'>
        <div className='row'>
          <div className='col s12 m8 push-m2'>
            <h4>{t('Apply patterns for numbers cleanup')}</h4>
            <p className='flow-text'>
              {t('Use different expressions in order to standardize the source phone number.')}
            </p>
            {
              patterns.map((p, index) => {
                return <Pattern key={`${index}-${p.input}-${p.output}`} index={index} input={p.input} output={p.output} actions={actions} t={t} errors={errorsByPath[index]} />
              })
            }
            <div className='col s12'>
              <a href='#!' className='btn-flat blue-text no-padd n-case' onClick={e => this.addPattern(e)}>
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
    patterns: patterns,
    errorsByPath: state.channel.errorsByPath
  }
}

const mapDispatchToProps = (dispatch) => ({
  actions: bindActionCreators(actions, dispatch)
})

export default translate()(connect(mapStateToProps, mapDispatchToProps)(ChannelPatterns))
