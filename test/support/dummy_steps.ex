defmodule Ask.DummySteps do
  defmacro __using__(_) do
    quote do
      @dummy_steps [
        %{
          "id" => "17141bea-a81c-4227-bdda-f5f69188b0e7",
          "type" => "multiple-choice",
          "title" => "Do you smoke?",
          "prompt" => %{
            "sms" => "Do you smoke? Press 1 for YES, 2 for NO",
          },
          "store" => "Smokes",
          "choices" => [
            %{
              "value" => "Yes",
              "responses" => ["Yes", "Y", "1"]
            },
            %{
              "value" => "No",
              "responses" => ["No", "N", "1"]
            }
          ]
        },
        %{
          "id" => "b6588daa-cd81-40b1-8cac-ff2e72a15c15",
          "type" => "multiple-choice",
          "title" => "Do you exercise?",
          "prompt" => %{
            "sms" => "Do you exercise? Press 1 for YES, 2 for NO",
          },
          "store" => "Exercises",
          "choices" => [
            %{
              "value" => "Yes",
              "responses" => ["Yes", "Y", "1"]
            },
            %{
              "value" => "No",
              "responses" => ["No", "N", "1"]
            }
          ]
        },
        %{
          "id" => "c6588daa-cd81-40b1-8cac-ff2e72a15c15",
          "type" => "numeric",
          "title" => "Which is the second perfect number?",
          "prompt" => %{
            "sms" => "Which is the second perfect number??"
          },
          "store" => "Perfect Number",
        }
      ]

      @skip_logic [
        %{
          "id" => "aaa",
          "type" => "multiple-choice",
          "title" => "Do you smoke?",
          "prompt" => %{
            "sms" => "Do you smoke? Press 1 for YES, 2 for NO, 3 for MAYBE, 4 for SOMETIMES, 5 for ALWAYS",
          },
          "store" => "Smokes",
          "choices" => [
            %{
              "value" => "Yes",
              "responses" => ["Yes", "Y", "1"],
              "skip_logic" => "end"
            },
            %{
              "value" => "No",
              "responses" => ["No", "N", "2"],
              "skip_logic" => nil
            },
            %{
              "value" => "Maybe",
              "responses" => ["Maybe", "M", "3"],
            },
            %{
              "value" => "Sometimes",
              "responses" => ["Sometimes", "S", "4"],
              "skip_logic" => "ccc"
            },
            %{
              "value" => "ALWAYS",
              "responses" => ["Always", "A", "5"],
              "skip_logic" => "undefined_id"
            }
          ]
        },
        %{
          "id" => "bbb",
          "type" => "multiple-choice",
          "title" => "Do you exercise?",
          "prompt" => %{
            "sms" => "Do you exercise? Press 1 for YES, 2 for NO",
          },
          "store" => "Exercises",
          "choices" => [
            %{
              "value" => "Yes",
              "responses" => ["Yes", "Y", "1"],
              "skip_logic" => "aaa"
            },
            %{
              "value" => "No",
              "responses" => ["No", "N", "1"]
            }
          ]
        },
        %{
          "id" => "ccc",
          "type" => "multiple-choice",
          "title" => "Is this questionnaire refreshing?",
          "prompt" => %{
            "sms" => "Is this questionnaire refreshing? Press 1 for YES, 2 for NO, 3 for MAYBE",
          },
          "store" => "Refresh",
          "choices" => [
            %{
              "value" => "Yes",
              "responses" => ["Yes", "Y", "1"]
            },
            %{
              "value" => "No",
              "responses" => ["No", "N", "1"]
            }
          ]
        }
      ]
    end
  end
end
