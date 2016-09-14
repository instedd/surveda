defmodule Ask.DummySteps do
  defmacro __using__(_) do
    quote do
      @dummy_steps [
        %{
          "id": "17141bea-a81c-4227-bdda-f5f69188b0e7",
          "type": "multiple-choice",
          "title": "Do you smoke?",
          "store": "Smokes",
          "choices": [
            %{
              "value": "Yes",
              "responses": ["Yes", "Y", "1"]
            },
            %{
              "value": "No",
              "responses": ["No", "N", "1"]
            }
          ]
        },
        %{
          "id": "b6588daa-cd81-40b1-8cac-ff2e72a15c15",
          "type": "multiple-choice",
          "title": "Do you exercise?",
          "store": "Exercises",
          "choices": [
            %{
              "value": "Yes",
              "responses": ["Yes", "Y", "1"]
            },
            %{
              "value": "No",
              "responses": ["No", "N", "1"]
            }
          ]
        }
      ]
    end
  end
end
