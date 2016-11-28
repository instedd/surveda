export type Questionnaire = {
  name: string,
  steps: Step[],
  modes: string[],
  languages: string[]
};

export type LanguagePrompt = {
  sms: string,
  ivr: {
    audioSource: 'tts',
    text: string
  }
};

export type Prompt = { [lang: string]: LanguagePrompt };

export type MultipleChoiceStep = {
  id: string,
  type: 'multiple-choice',
  title: string,
  store: string,
  prompt: Prompt,
  choices: Choice[]
};

declare type Choice = {
  value: string,
  skipLogic: ?string,
  responses: { [lang: string]: {
    sms: string[],
    ivr: string[]
  }}
};

declare type Step = MultipleChoiceStep;
