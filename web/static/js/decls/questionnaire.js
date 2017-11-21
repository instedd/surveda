// @flow
export type Questionnaire = {
  id: number,
  name: string,
  steps: Step[],
  quotaCompletedSteps: ?(Step[]),
  modes: string[],
  languages: string[],
  defaultLanguage: string,
  activeLanguage: string,
  activeMode: ?string,
  settings: Settings,
  projectId: number,
  valid: ?boolean
};

export type Settings = {
  errorMessage: LocalizedPrompt,
  mobileWebSmsMessage: ?string,
  mobileWebSurveyIsOverMessage: ?string,
  mobileWebColorStyle?: ColorStylePrompt,
  title: {[lang: string]: string},
  surveyAlreadyTakenMessage: {[lang: string]: string},
  thankYouMessage?: LocalizedPrompt,
};

export type ChoiceErrors = {
  value: string[],
  sms: string[],
  ivr: string[]
};

export type AudioPrompt = {
    audioSource: 'tts' | 'upload',
    text: string,
    audioId?: ?string
};

export type Prompt = {
  sms?: string,
  ivr?: AudioPrompt,
  mobileweb?: string
};

export type ColorStylePrompt = {
  primaryColor?: string,
  secondaryColor?: string
};

export type LocalizedPrompt = { [lang: string]: Prompt };

export type MultipleChoiceStep = BaseStep & StoreStep & MultilingualStep & {
  type: 'multiple-choice',
  choices: Choice[]
};

export type LanguageSelectionStep = BaseStep & StoreStep & {
  type: 'language-selection',
  languageChoices: string[],
  prompt: Prompt
};

export type ExplanationStep = BaseStep & MultilingualStep & {
  type: 'explanation',
  skipLogic: ?string
};

export type FlagStep = BaseStep & {
  type: 'flag',
  disposition: 'completed' | 'interim partial' | 'ineligible',
  skipLogic: ?string
};

export type NumericStep = BaseStep & StoreStep & MultilingualStep & {
  type: 'numeric',
  minValue: ?number,
  maxValue: ?number,
  rangesDelimiters: ?string,
  ranges: Range[],
  refusal: ?Refusal
};

export type Range = {
  from: ?number,
  to: ?number,
  skipLogic: ?string
};

export type BaseChoice = {
  skipLogic: ?string,
  responses: {
    ivr?: string[],
    sms?: {
      [lang: string]: string[]
    },
    mobileweb?: {
      [lang: string]: ?string
    }
  }
};

export type Choice = BaseChoice & {
  value: string
};

export type Refusal = BaseChoice & {
  enabled: boolean
};

export type Step = LanguageSelectionStep | MultipleChoiceStep | NumericStep | ExplanationStep | FlagStep;
export type BaseStep = {
  id: string,
  title: string
};

export type StoreStep = {
  store: string
};

export type MultilingualStep = {
  prompt: LocalizedPrompt
};

export type SkipOption = {
  id: string,
  title: string,
  enabled: boolean
};

export type Translation = {
  text: string,
  language: string
};

export type AutocompleteItem = {
  id: string,
  text: string,
  translations: Translation[]
};
