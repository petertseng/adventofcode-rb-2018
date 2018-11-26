require_relative '../adventofcode-common/test'

test_and_exit { |daypad|
  scripts = Dir.glob("#{__dir__}/#{daypad}_*.rb")
  next if scripts.empty?
  raise "Need exactly one script not #{scripts}" if scripts.size != 1
  "ruby #{scripts[0]}"
}
