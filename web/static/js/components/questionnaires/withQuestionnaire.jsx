import React from "react"
import { connect } from "react-redux"

const withQuestionnaire = (ComponentClass) => (props: any) => {
  if (props.questionnaire) {
    return <ComponentClass {...props} />
  } else {
    return null
  }
}

const mapStateToProps = (state, ownProps) => ({
  questionnaire: state.questionnaire.data,
})

export default (ComponentClass) => connect(mapStateToProps)(withQuestionnaire(ComponentClass))
