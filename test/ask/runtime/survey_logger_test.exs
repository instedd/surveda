defmodule SurveyLoggerTest do
    use ExUnit.Case
    use Ask.Model
    alias Ask.Runtime.SurveyLogger
    alias Ask.{Repo, SurveyLogEntry}

    describe "SurveyLogger" do

        # Test that the public API sends the right message to the mailbox
        test "log should send log message" do
            logger_pid = start_logger()
            timestamp = DateTime.utc_now()

            SurveyLogger.log(
                1,
                "sms",
                2,
                "1234",
                3,
                "queued",
                :contact,
                "Enqueueing call",
                timestamp
            )
            assert_logger_received(logger_pid, {:log, 1, "sms", 2, "1234", 3, "queued", :contact, "Enqueueing call", timestamp})
        end
        
        # Test that the side-effect of processing a :log message is the expected one
        test "logging registers entry on db" do
            start_logger()
            timestamp = DateTime.utc_now()
            
            SurveyLogger.handle_cast({:log, 1, "sms", 2, "1234", 3, "queued", :contact, "Enqueueing call", timestamp}, nil)

            entry = Repo.one!(from s in SurveyLogEntry, where: s.respondent_id == 2, order_by: [desc: s.id], limit: 1)
            assert entry.survey_id == 1
            assert entry.mode == "SMS" # normalized mode
            assert entry.respondent_hashed_number == "1234"
            assert entry.channel_id == 3
            assert entry.disposition == "queued"
            assert entry.action_type == "contact"
            assert entry.action_data == "Enqueueing call"
            assert entry.timestamp == DateTime.truncate(timestamp, :second)
        end
    end

    def start_logger() do
        {:ok, logger_pid} = SurveyLogger.start_link()
        :erlang.trace(logger_pid, true, [:receive])
        logger_pid
    end

    def assert_logger_received(logger_pid, message) do
        assert_receive {
            :trace, 
            ^logger_pid, 
            :receive,
            {:"$gen_cast", ^message}
        }
    end

end
