require_relative "result"

module Dottie
  class TestCase
    attr_reader :test
    attr_reader :result

    def initialize(
      directory:,
      test:,
      file:,
      expect: nil,
      expectf: nil,
      skipif: nil,
      env: {}
    )
      raise "Invalid test case; no expect/expectf given!" unless expect || expectf

      @directory = directory
      @test = test
      @file = file
      @expect = expect
      @expectf = expectf
      @skipif = skipif
      @env = env
    end

    def run(runner)
      return Result.skipped(self) if should_skip?(runner)

      @result = runner.run(@file, @directory, @env)

      return Result.success(self) if success?

      Result.failure(self)
    end

    def expected
      case
      when @expect then @expect
      when @expectf then @expectf
      else raise "Invalid test case; no expect/expectf given!"
      end
    end

    private

    def success?
      case
      when @expect then @expect == @result
      when @expectf then expectf_matches?
      else false
      end
    end

    def should_skip?(runner)
      return false if @skipif.nil?

      output = runner.run(@skipif, @directory)

      output.downcase.start_with?("skip")
    end

    ##
    # Supported PHPT format specifiers:
    #   %d: an unsigned integer
    #   %i: a signed integer
    #   %f: a float
    #   %c: a single character
    #   %s: one or more of anything until a newline
    #   %S: zero or more of anything until a newline
    #   %a: one or more of anything including newlines
    #   %A: zero or more of anything including newlines
    #   %w: zero or more whitespace characters
    #   %x: one or more hexadecimal character (a-f, A-F, 0-9)
    #
    # Unsupported PHPT format specifiers:
    #   %r...%r: a regular expression
    def expectf_matches?
      raise "No expectf given but expectf_matches? called??" unless @expectf

      regex_string = Regexp.quote(@expectf.dup)
      regex_string.gsub!(/([^%])?%d/, '\1\d+')
      regex_string.gsub!(/([^%])?%i/, '\1[-+]?\d+')
      regex_string.gsub!(/([^%])?%f/, '\1\d+.\d+')
      regex_string.gsub!(/([^%])?%c/, '\1.')
      regex_string.gsub!(/([^%])?%s/, '\1.+')
      regex_string.gsub!(/([^%])?%S/, '\1.*')
      regex_string.gsub!(/([^%])?%a/, '\1(.|\R)+?')
      regex_string.gsub!(/([^%])?%A/, '\1(.|\R)*?')
      regex_string.gsub!(/([^%])?%w/, '\1\s')
      regex_string.gsub!(/([^%])?%x/, '\1[a-fA-F0-9]+')
      regex_string.gsub!("%%", "%")

      regex = Regexp.new('\A' << regex_string << '\z')

      regex.match?(@result)
    end
  end
end
