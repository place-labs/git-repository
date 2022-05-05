module OpenTelemetry::Instrumentation
  class GitClient < OpenTelemetry::Instrumentation::Instrument
  end
end

struct GitClient::Commmands
  trace("run_git") do
    OpenTelemetry.trace.in_span("GitClient #{command}") do |span|
      span["path"] = path
      previous_def
    end
  end
end
