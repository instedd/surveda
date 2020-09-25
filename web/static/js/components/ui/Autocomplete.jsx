import React, { Component, PropTypes } from 'react'
import 'materialize-autocomplete'

/**
 * Autocomplete component.
 *
 * The component should be placed right after the input that will
 * trigger the autocomplete. The following properties must be set:
 *
 * - getInput: a function() that returns the input that will trigger
 *             the autcompletion (usually got with `ref`)
 * - getData: a function(value, callback) to get the autocomplete suggestions
 * - onSelect: a function(item) invoked when an autocomplete suggestion is selected
 * - className: optional class name
 *
 * The component that uses this Autocomplete component should save it
 * in a ref. You can invoke hide() to hide the autocomplete popup (usually
 * done in the onBlur event of the input).
 *
 * This component also keeps track of a boolean, clickingAutocomplete,
 * that turns true when the user is clicking on an autocomplete suggestion.
 * This is useful to use on the onBlur even of the input to distinguish
 * between the user leaving the input and the user clicking on a suggestion:
 * in the former case one would, for example, submit the input's value to redux,
 * while in the latter one would do nothing.
 */
export class Autocomplete extends Component {
  static defaultProps = {
    // plainText defaults to true for backward compatibility
    plainText: true
  }

  constructor(props) {
    super(props)
    this.clickingAutocomplete = false
    this.hidden = false
  }

  hide() {
    this.hidden = true
    $(this.refs.dropdown).hide()
  }

  unhide() {
    this.hidden = false
  }

  render() {
    const { className } = this.props

    return (
      <ul className={`autocomplete-content dropdown-content ${className}`}
        ref='dropdown'
        onMouseDown={(e) => { this.clickingAutocomplete = true }}
        style={{display: 'none'}}
        />
    )
  }

  componentDidMount() {
    this.setupAutocomplete()
  }

  componentDidUpdate() {
    this.setupAutocomplete()
  }

  setupAutocomplete() {
    const { getInput, getData, onSelect, showOnClick, plainText } = this.props
    let input = getInput()
    let dropdown = this.refs.dropdown

    if (showOnClick) {
      $(input).click(() => $(dropdown).show())
    }

    const liInnerText = plainText
      ? `$("<div/>").text(item.text).html().replace("\u001E", "<br/>")`
      : `item.text`

    $(input).materialize_autocomplete({
      limit: 100,
      cacheable: false,
      multiple: {
        enable: false
      },
      dropdown: {
        el: dropdown,
        // We replace \u001E with <br/> so messages split into several pieces
        // are shown in separate lines. Maybe this Autocomplete component shouldn't
        // be aware of this detail, but this unicode character shouldn't appear
        // in texts other than because of splitted message, so this is safe
        // and much easier than escaping it everywhere (plus it's hard to do because
        // a newline will show as a blank space, but here we want a <br/>)
        itemTemplate: `<li class="ac-item black-text" data-id="<%= item.id %>" data-text='<%= $("<div/>").text(item.text).html() %>'><%= ${liInnerText} %></li>`
      },
      onSelect: (item) => {
        this.clickingAutocomplete = false
        onSelect(item)
      },
      getData: (value, callback) => {
        getData(value, (v, c) => {
          if (this.hidden) return
          callback(v, c)
        })
      }
    })
  }
}

Autocomplete.propTypes = {
  getInput: PropTypes.func.isRequired,
  getData: PropTypes.func.isRequired,
  onSelect: PropTypes.func.isRequired,
  showOnClick: PropTypes.bool,
  className: PropTypes.string,
  plainText: PropTypes.bool
}
