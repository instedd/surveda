import React, {PropTypes} from 'react'
import { Autocomplete } from '../ui'

import {
 Editor,
 ContentState,
 convertFromHTML,
 EditorState,
 RichUtils
} from 'draft-js'

import InlineStyleControls from './InlineStyleControls'
import {stateToHTML} from 'draft-js-export-html'

class Draft extends React.Component {
  constructor(props) {
    super(props)

    this.hasFocus = false
    this.autocompleteTimer = null

    this.state = this.stateFromProps(props)

    this.focus = () => this.refs.editor.focus()

    this.onFocus = (editorState) => {
      this.hasFocus = true
      this.redraw()

      if (this.refs.autocomplete) {
        this.refs.autocomplete.unhide()
      }
    }

    this.onChange = (editorState) => {
      this.setState({editorState})
      this.redraw()

      if (this.refs.hidden_input) {
        if (this.autocompleteTimer) {
          clearTimeout(this.autocompleteTimer)
          this.autocompleteTimer = null
        }

        const oldPlainText = this.getPlainText()
        const plainText = this.getPlainText(editorState)
        if (oldPlainText != plainText) {
          this.autocompleteTimer = setTimeout(() => {
            this.refs.hidden_input.value = plainText
            $(this.refs.hidden_input).trigger('input')
          }, 300)
        }
      }
    }

    this.onBlur = (editorState) => {
      this.hasFocus = false
      this.redraw()

      if (this.refs.autocomplete) {
        this.refs.autocomplete.hide()
      }

      props.onBlur(this.getText())
    }

    this.getText = () => {
      const plainText = this.getPlainText()
      if (plainText.trim().length == 0) {
        return ''
      } else {
        if (props.plainText) {
          return plainText
        } else {
          return stateToHTML(this.state.editorState.getCurrentContent(), {inlineStyles: {UNDERLINE: {element: 'u'}}})
        }
      }
    }

    this.getPlainText = (editorState = this.state.editorState) => {
      const content = editorState.getCurrentContent()
      return content.getPlainText('\n')
    }

    this.handleKeyCommand = (command) => this._handleKeyCommand(command)
    this.onTab = (e) => this._onTab(e)
    this.toggleInlineStyle = (style) => this._toggleInlineStyle(style)
  }

  _handleKeyCommand(command) {
    const {editorState} = this.state
    const newState = RichUtils.handleKeyCommand(editorState, command)
    if (newState) {
      this.onChange(newState)
      return true
    }
    return false
  }

  _onTab(e) {
    const maxDepth = 4
    this.onChange(RichUtils.onTab(e, this.state.editorState, maxDepth))
  }

  _toggleInlineStyle(inlineStyle) {
    this.onChange(
      RichUtils.toggleInlineStyle(
        this.state.editorState,
        inlineStyle
      )
    )
  }

  componentDidMount() {
    this.redraw()
  }

  redraw() {
    if (this.state.editorState.getCurrentContent().hasText()) {
      $(this.refs.label).addClass('text')
    } else {
      $(this.refs.label).removeClass('text')
    }

    if (this.hasFocus) {
      $(this.refs.label).addClass('focus')
    } else {
      $(this.refs.label).removeClass('focus')
    }
  }

  componentWillReceiveProps(newProps) {
    this.setState(this.stateFromProps(newProps))
  }

  stateFromProps(props) {
    const blocksFromHTML = convertFromHTML(props.value)
    const state = ContentState.createFromBlockArray(
      blocksFromHTML.contentBlocks,
      blocksFromHTML.entityMap
    )
    return {editorState: EditorState.createWithContent(state)}
  }

  render() {
    const { editorState } = this.state
    const { label, errors, readOnly } = this.props

    // If the user changes block type before entering any text, we can
    // either style the placeholder or hide it. Let's just hide it now.
    let className = 'RichEditor-editor'
    let contentState = editorState.getCurrentContent()
    if (!contentState.hasText()) {
      if (contentState.getBlockMap().first().getType() !== 'unstyled') {
        className += ' RichEditor-hidePlaceholder'
      }
    }

    let errorComponent = null
    if (errors) {
      const errorMessage = errors.join(', ')
      errorComponent = <div className='error'>{errorMessage}</div>
      className = `${className} invalid`
    }

    let autocompleteComponents = null
    if (this.props.autocomplete) {
      autocompleteComponents = [
        <input key='one' ref='hidden_input' type='hidden' />,
        <Autocomplete
          key='two'
          ref='autocomplete'
          getInput={() => this.refs.hidden_input}
          getData={(value, callback) => { console.log(value); this.props.autocompleteGetData(value, callback) }}
          onSelect={(item) => this.props.autocompleteOnSelect(item)}
          className='language-dropdown'
        />
      ]
    }

    return (
      <div className='RichEditor-root'>
        <div className={className} onClick={this.focus}>
          <label ref='label'>
            {label}
          </label>
          <Editor
            editorState={editorState}
            handleKeyCommand={this.handleKeyCommand}
            onChange={this.onChange}
            onFocus={this.onFocus}
            onBlur={this.onBlur}
            onTab={this.onTab}
            readOnly={readOnly}
            ref='editor'
            spellCheck={false}
          />
        </div>
        {errorComponent}
        {autocompleteComponents}
        <InlineStyleControls
          editorState={editorState}
          onToggle={this.toggleInlineStyle}
        />
      </div>
    )
  }
}

Draft.propTypes = {
  label: PropTypes.string,
  errors: PropTypes.any,
  onBlur: PropTypes.func,
  autocomplete: PropTypes.bool,
  autocompleteGetData: PropTypes.func,
  autocompleteOnSelect: PropTypes.func,
  value: PropTypes.string,
  readOnly: PropTypes.bool,
  plainText: PropTypes.bool
}

export default Draft
