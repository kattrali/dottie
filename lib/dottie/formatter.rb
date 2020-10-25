require_relative "colour"

module Dottie
  class Formatter
    def test_result(test_case, result)
      if result.success?
        "#{colour("✔").green} #{test_case.test}"
      elsif result.skipped?
        "#{colour("-").cyan} #{test_case.test}"
      else
        <<~TEXT
          #{colour("✖").red} #{test_case.test}
          #{colour("Expected output:").bold}
          #{test_case.expect}
          #{colour("Actual output:").bold}
          #{test_case.result}
        TEXT
      end
    end

    def suite_result(results)
      total = results.count
      skips = results.count(&:skipped?)
      failures = results.count(&:failed?)
      plural = ->(count) { count == 1 ? "test" : "tests" }

      output = "\n#{colour("Ran #{total} #{plural.(total)}!").bold}\n"

      if skips > 0
        output << colour("#{skips} skipped #{plural.(skips)}").cyan.to_s << "\n"
      end

      if failures > 0
        output << colour("#{failures} failed #{plural.(failures)}").red.to_s << "\n"
      end

      output << "\n"

      if failures == 0
        output << colour("SUCCESS").green.bold.to_s
      else
        output << colour("FAIL").red.bold.to_s
      end
    end

    private

    def colour(*args); Dottie::Colour.new(*args) end
  end
end