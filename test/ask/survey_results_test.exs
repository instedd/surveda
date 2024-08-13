defmodule Ask.SurveyResultsTest do
  use Ask.DataCase

  alias Ask.SurveyResults

  test "generates empty interactions file" do
    survey = insert(:survey)
    assert {:noreply, _, _} = SurveyResults.handle_cast({:interactions, survey.id, nil}, nil)
    path = SurveyResults.file_path(survey, :interactions)
    assert "ID,Respondent ID,Mode,Channel,Disposition,Action Type,Action Data,Timestamp\r\n" == File.read!(path)
  end
end
