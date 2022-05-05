module OpenTelemetry::Instrumentation
  class GitRepository < OpenTelemetry::Instrumentation::Instrument
  end
end

struct GitRepository::Commmands
  trace("run_git") do
    OpenTelemetry.trace.in_span("GitRepository #{command}") do |span|
      span["path"] = path
      previous_def
    end
  end
end
