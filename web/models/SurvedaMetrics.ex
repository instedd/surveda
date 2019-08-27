defmodule Ask.SurvedaMetrics do
    use Prometheus.Metric
    def setup() do
        Counter.declare(
          name: :surveda_survey_poll,
          help: "Surveda survey poll",
          labels: [:survey_id]
        )

        Counter.declare(
          name: :surveda_broker_respondent_start,
          help: "Surveda broker respondent start",
          labels: [:survey_id]
        )

        Counter.declare(
          name: :surveda_verboice_enqueue,
          help: "Surveda verboice enqueue",
          labels: [:response_status]
        )

        Counter.declare(
          name: :surveda_verboice_status_callback,
          help: "Surveda verboice status callback",
          labels: [:call_status]
        )

        Counter.declare(
          name: :surveda_nuntium_enqueue,
          help: "Surveda nuntium enqueue",
          labels: [:response_status]
        )

        Counter.declare(
          name: :surveda_nuntium_status_callback,
          help: "Surveda nuntium status callback",
          labels: [:status]
        )

        Counter.declare(
          name: :surveda_nuntium_incoming,
          help: "Surveda nuntium incoming",
        )

    end

    def increment_counter_with_label(counter_name, labels) do
      Counter.inc(
        name: counter_name,
        labels: labels
      )
    end

    def increment_counter(counter_name) do
      Counter.inc(
        name: counter_name
      )
    end
end
