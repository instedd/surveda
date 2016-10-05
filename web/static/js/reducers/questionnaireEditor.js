import * as actions from '../actions/questionnaireEditor'

const defaultState = {
  steps: {
    ids: [],
    items: {},
    current: null
  }
}

export default (state = defaultState, action) => {
  switch (action.type) {
    case actions.SELECT_STEP:
      return {
        ...state,
        currentStepId: action.stepId
      }
    case actions.DESELECT_STEP:
      return {
        ...state,
        currentStepId: null
      }
    case actions.INITIALIZE_EDITOR:
      var stepsItems = {}
      action.questionnaire.steps.map((step) =>{
        var responses = {}
        if(step.choices){
          responses['items'] = step.choices.map((choice) =>{
            var responseItem = {}
            responseItem["response"] = choice.value
            return responseItem
          })
        }
        // The id isn't in the proposed model, but it's necessary for the view
        stepsItems[step.id] = {title: step.title, responses: responses, id: step.id}
      })
      return {
        ...state,
        questionnaire: {
          id: action.questionnaire.id,
          name: action.questionnaire.name
        },
        steps: {
          ids: action.questionnaire.steps.map((step) =>{
            return step.id
          }),
          items: stepsItems
        }
      }
    default:
      return state
  }
}
