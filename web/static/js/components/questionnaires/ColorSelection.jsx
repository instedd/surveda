import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { Card, InputWithLabel } from '../ui'
import * as actions from '../../actions/questionnaire'

class ColorSelection extends Component {
  constructor(props) {
    super(props)
    const primaryColor = props.colorStyles && props.colorStyles.primaryColor ? props.colorStyles.primaryColor : ''
    const secondaryColor = props.colorStyles && props.colorStyles.secondaryColor ? props.colorStyles.secondaryColor : ''
    this.state = {primaryColor: primaryColor, secondaryColor: secondaryColor}
  }

  onBlur(text, mode) {
    const { dispatch } = this.props
    if (mode == 'primary') {
      dispatch(actions.setPrimaryColor(this.state.primaryColor))
    } else {
      dispatch(actions.setSecondaryColor(this.state.secondaryColor))
    }
  }

  onChange(e, mode) {
    e.preventDefault()

    if (mode == 'primary') {
      this.setState({
        primaryColor: e.target.value
      })
    } else {
      this.setState({
        secondaryColor: e.target.value
      })
    }
  }

  render() {
    const valuePrimary = this.state.primaryColor
    const colorRegex = /^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/
    const primary = colorRegex.test(valuePrimary) ? valuePrimary : '#000000'
    const valueSecondary = this.state.secondaryColor
    const secondary = colorRegex.test(valueSecondary) ? valueSecondary : '#000000'
    return (
      <div className='row'>
        <Card className='z-depth-0'>
          <ul className='collection collection-card dark'>
            <li className='collection-item'>
              <div className='row'>
                <svg style={{width: '70px', height: '70px'}}>
                  <circle className='a' cx='29' cy='29' r='29' fill={primary} />
                </svg>
                <svg style={{width: '70px', height: '70px'}}>
                  <circle className='a' cx='29' cy='29' r='29' fill={secondary} />
                </svg>
                <div className='col input-field s12'>
                  <InputWithLabel id='primaryColorInput' value={valuePrimary} label='Primary color' errors={[]} >
                    <input
                      type='text'
                      disabled={false}
                      onChange={e => this.onChange(e, 'primary')}
                      onBlur={e => this.onBlur(e, 'primary')}
                    />
                  </InputWithLabel>
                </div>
                <div className='col input-field s12'>
                  <InputWithLabel id='secondaryColorInput' value={valueSecondary} label='Secondary color' errors={[]} >
                    <input
                      type='text'
                      disabled={false}
                      onChange={e => this.onChange(e, 'secondary')}
                      onBlur={e => this.onBlur(e, 'secondary')}
                    />
                  </InputWithLabel>
                </div>
              </div>
            </li>
          </ul>
        </Card>
      </div>
    )
  }
}

ColorSelection.propTypes = {
  dispatch: PropTypes.any,
  colorStyles: PropTypes.object
}

const mapStateToProps = (state) => {
  return {
    questionnaire: state.questionnaire.data,
    colorStyles: state.questionnaire.data.settings.mobileWebColorStyle
  }
}

export default connect(mapStateToProps)(ColorSelection)
