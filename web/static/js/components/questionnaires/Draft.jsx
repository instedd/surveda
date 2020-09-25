import React, {PropTypes} from 'react'
import { Autocomplete } from '../ui'
import CharacterCounter from '../CharacterCounter'

import {
 Editor,
 ContentState,
 convertFromHTML,
 EditorState,
 RichUtils,
 getDefaultKeyBinding
} from 'draft-js'

import InlineStyleControls from './InlineStyleControls'
import {stateToHTML} from 'draft-js-export-html'

class Draft extends React.Component {
  static defaultProps = {
    // plainText defaults to false for backward compatibility
    plainText: false
  }

  constructor(props) {
    super(props)

    this.hasFocus = false
    this.autocompleteTimer = null

    this.state = this.stateFromProps(props)

    this.keyBindingFn = (e) => {
      if (e.keyCode === 13 /* `Enter` key */ && e.nativeEvent.shiftKey) {
        return 'split'
      }
      return getDefaultKeyBinding(e)
    }

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
      // Prevent `onBlur` being fired when an autocomplete option is being clicked,
      // because we want the autocomplete to have precedence
      if (this.refs.autocomplete && this.refs.autocomplete.clickingAutocomplete) {
        return
      }

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

    if (command == 'split') {
      if (this.props.onSplit) {
        // The editor content is made of a list of content blocks,
        // and the selection info gives as the caret position at
        // a given block. We need to find that block and sum all
        // of the text of the previous blocks to know the *real*
        // caret position in the whole text.
        const selection = editorState.getSelection()
        const startKey = selection.getStartKey()
        const startOffset = selection.getStartOffset()
        const blocks = editorState.getCurrentContent().getBlocksAsArray()
        let caretIndex = startOffset
        for (let i = 0; i < blocks.length; i++) {
          const block = blocks[i]
          if (block.getKey() == startKey) {
            break
          }
          caretIndex += block.getText().length
        }

        this.props.onSplit(caretIndex)
      }
      return
    }

    // Disallow bold, italic, etc., when plain-text
    if (this.props.plainText) return

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
    let value = props.value

    // Ignore calls with the same value in case the user has changed the content already
    if (this.state && value == this.props.value) {
      return {}
    }

    // Because we use `convertFromHTML`, in the case of a plain text
    // we need to replace `\n` with `<br/>` so that newlines are preserved
    if (props.plainText) {
      value = value.replace(/\n/g, '<br/>')
    }

    const blocksFromHTML = convertFromHTML(value)
    const state = ContentState.createFromBlockArray(
      blocksFromHTML.contentBlocks,
      blocksFromHTML.entityMap
    )
    return {editorState: EditorState.createWithContent(state)}
  }

  render() {
    const { editorState } = this.state
    const { label, errors, readOnly, textBelow, plainText } = this.props

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
    if (errors && errors.length > 0) {
      const errorMessage = errors.join(', ')
      errorComponent = <div className='error'>{errorMessage}</div>
      className = `${className} invalid`
    }

    let textBelowComponent = null
    if (textBelow) {
      textBelowComponent =
        <div>
          <span className='draft-small-text-below'>
            {textBelow}
          </span>
        </div>
    }

    let autocompleteComponents = null
    if (this.props.autocomplete) {
      autocompleteComponents = [
        <input key='one' ref='hidden_input' type='hidden' />,
        <Autocomplete
          key='two'
          ref='autocomplete'
          getInput={() => this.refs.hidden_input}
          getData={(value, callback) => this.props.autocompleteGetData(value, callback)}
          onSelect={(item) => this.props.autocompleteOnSelect(item)}
          className='language-dropdown'
          plainText={plainText}
        />
      ]
    }

    let styleControls = null
    if (!this.props.plainText) {
      styleControls = (
        <InlineStyleControls
          editorState={editorState}
          onToggle={this.toggleInlineStyle}
        />
      )
    }

    let characterCounter = null
    if (this.props.characterCounter) {
      characterCounter = <CharacterCounter ref='characterCounter' text={this.getPlainText(editorState)} fixedLength={this.props.characterCounterFixedLength} />
    }

    return (
      <div className='RichEditor-root'
        draggable
        onDragStart={e => { e.stopPropagation(); e.preventDefault(); return false }}
        >
        <div className={className} onClick={this.focus}>
          <label ref='label'>
            {label}
          </label>
          <Editor
            editorState={editorState}
            handleKeyCommand={this.handleKeyCommand}
            keyBindingFn={this.keyBindingFn}
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
        {textBelowComponent}
        {characterCounter}
        {autocompleteComponents}
        {styleControls}
      </div>
    )
  }
}

Draft.propTypes = {
  label: PropTypes.string,
  errors: PropTypes.any,
  textBelow: PropTypes.any,
  onBlur: PropTypes.func,
  autocomplete: PropTypes.bool,
  autocompleteGetData: PropTypes.func,
  autocompleteOnSelect: PropTypes.func,
  onSplit: PropTypes.func,
  value: PropTypes.string,
  readOnly: PropTypes.bool,
  plainText: PropTypes.bool,
  characterCounter: PropTypes.bool,
  characterCounterFixedLength: PropTypes.number
}

export default Draft
