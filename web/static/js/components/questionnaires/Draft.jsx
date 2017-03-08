import React, {PropTypes} from 'react'
// import {Editor, EditorState, RichUtils} from 'draft-js'
import {
 Editor,
 EditorState,
 RichUtils
} from 'draft-js'

import BlockStyleControls from './BlockStyleControls'
import InlineStyleControls from './InlineStyleControls'
import {stateToHTML} from 'draft-js-export-html'

class Draft extends React.Component {
  constructor(props) {
    super(props)

    this.state = {editorState: EditorState.createEmpty()}
    console.log(props.onChange)

    this.focus = () => this.refs.editor.focus()
    this.onChange = (editorState) => {
      this.setState({editorState})
      props.onChange(stateToHTML(editorState.getCurrentContent()))
    }

    this.handleKeyCommand = (command) => this._handleKeyCommand(command)
    this.onTab = (e) => this._onTab(e)
    this.toggleBlockType = (type) => this._toggleBlockType(type)
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

  _toggleBlockType(blockType) {
    this.onChange(
      RichUtils.toggleBlockType(
        this.state.editorState,
        blockType
      )
    )
  }

  _toggleInlineStyle(inlineStyle) {
    this.onChange(
      RichUtils.toggleInlineStyle(
        this.state.editorState,
        inlineStyle
      )
    )
  }

  getBlockStyle(block) {
    switch (block.getType()) {
      case 'blockquote': return 'RichEditor-blockquote'
      default: return null
    }
  }

  render() {
    const {editorState} = this.state

    // Custom overrides for "code" style.
    const styleMap = {
      CODE: {
        backgroundColor: 'rgba(0, 0, 0, 0.05)',
        fontFamily: '"Inconsolata", "Menlo", "Consolas", monospace',
        fontSize: 16,
        padding: 2
      }
    }

    // If the user changes block type before entering any text, we can
    // either style the placeholder or hide it. Let's just hide it now.
    let className = 'RichEditor-editor'
    let contentState = editorState.getCurrentContent()
    console.log(stateToHTML(contentState))
    if (!contentState.hasText()) {
      if (contentState.getBlockMap().first().getType() !== 'unstyled') {
        className += ' RichEditor-hidePlaceholder'
      }
    }

    return (
      <div className='RichEditor-root'>
        <BlockStyleControls
          editorState={editorState}
          onToggle={this.toggleBlockType}
        />
        <InlineStyleControls
          editorState={editorState}
          onToggle={this.toggleInlineStyle}
        />
        <div className={className} onClick={this.focus}>
          <Editor
            blockStyleFn={(block) => this.getBlockStyle(block)}
            customStyleMap={styleMap}
            editorState={editorState}
            handleKeyCommand={this.handleKeyCommand}
            onChange={this.onChange}
            onTab={this.onTab}
            placeholder='Tell a story...'
            ref='editor'
            spellCheck
          />
        </div>
      </div>
    )
  }
}

Draft.propTypes = {
  onChange: PropTypes.func
}

export default Draft
