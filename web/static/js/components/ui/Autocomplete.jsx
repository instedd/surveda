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
  constructor(props) {
    super(props)
    this.clickingAutocomplete = false
    this.hidden = false
  }

  hide() {
    this.hidden = true
    $(this.refs.dropdown).hide()
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
    const { getInput, getData, onSelect, showOnClick } = this.props
    let input = getInput()
    let dropdown = this.refs.dropdown

    if (showOnClick) {
      $(input).click(() => $(dropdown).show())
    }

    $(input).materialize_autocomplete({
      limit: 100,
      cacheable: false,
      multiple: {
        enable: false
      },
      dropdown: {
        el: dropdown,
        itemTemplate: '<li class="ac-item" style="color: black !important" data-id="<%= item.id %>" data-text=\'<%= item.text %>\'><%= item.text %></li>'
      },
      onSelect: (item) => {
        this.clickingAutocomplete = false
        onSelect(item)
      },
      getData: (value, callback) => {
        this.hidden = false
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
  className: PropTypes.string
}
