// @flow
export type Questionnaire = {
  name: string,
  steps: Step[],
  modes: string[],
  languages: string[],
  defaultLanguage: string,
  activeLanguage: string,
  quotaCompletedMsg: ?Prompt,
  errorMsg: ?Prompt,
};

export type QuizErrors = {
  [path: string]: string[]
}

export type MetaQuestionnaire = {
  data: Questionnaire,
  errors: QuizErrors
}

export type AudioPrompt = {
    audioSource: 'tts' | 'upload',
    text: string,
    audioId?: ?string
};

export type LanguagePrompt = {
  sms?: string,
  ivr?: AudioPrompt,
};

export type Prompt = { [lang: string]: LanguagePrompt };

export type MultipleChoiceStep = BaseStep & MultilingualStep & {
  type: 'multiple-choice',
  choices: Choice[]
};

export type LanguageSelectionStep = BaseStep & {
  type: 'language-selection',
  languageChoices: (?string)[],
  prompt: LanguagePrompt
};

export type NumericStep = BaseStep & MultilingualStep & {
  type: 'numeric',
  minValue: ?number,
  maxValue: ?number,
  rangesDelimiters: ?string,
  ranges: Range[],
};

export type Range = {
  from: ?number,
  to: ?number,
  skipLogic: ?string
};

export type Choice = {
  value: string,
  skipLogic: ?string,
  responses: {
    ivr?: string[],
    sms?: {
      [lang: string]: string[]
    }
  }
};

export type Step = LanguageSelectionStep | MultipleChoiceStep | NumericStep;
export type BaseStep = {
  id: string,
  title: string,
  store: string,
};

export type MultilingualStep = {
  prompt: Prompt
}

export type SkipOption = {
  id: string,
  title: string,
  enabled: boolean
};
