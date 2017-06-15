#!/usr/bin/env ruby
require 'hockeyver'
require 'json'

# -------
# Constants
# -------

SOURCE_FILE="target_information.json"

# -------
# Helpers
# -------

def colorize(text, color_code)
  "\e[#{color_code}m#{text}\e[0m"
end
def red(text); colorize(text, 31); end
def green(text); colorize(text, 32); end
def yellow(text); colorize(text, 33); end
def bold(text); "\e[1m#{text}\e[22m" end

class Version < Array
  def initialize s
    super(s.split('.').map { |e| e.to_i })
  end
  def < x
    (self <=> x) < 0
  end
  def > x
    (self <=> x) > 0
  end
  def == x
    (self <=> x) == 0
  end
  def >= x
    (self <=> x) >= 0
  end
end

# -------
# Main
# -------

puts bold "Starting Hockey versions verification"

# Safety checks
raise red "Can't find #{SOURCE_FILE}." unless File.exist? SOURCE_FILE

# Read settings
file = File.read SOURCE_FILE
target_information = JSON.parse file

valid = true

# Parse Hockey versions
target_information.each_pair { |key, val|

  # Get numbers from hockey
  buildnumber = HockeyVer.parse_hockey_version val["hockey_app_id"], '$HOCKEY_TOKEN'

  hockey_version = buildnumber["version"]
  hockey_build = buildnumber["build"].to_i

  xcode_version = val["version"]
  xcode_build = val["build"].to_i

  # Compare, make sure that build is always higher and version is at least higher or equal
  unless (Version.new(xcode_version) >= Version.new(hockey_version)) && (xcode_build > hockey_build)
    valid = false
    puts yellow "|- #{key}: Xcode version #{xcode_version} (#{xcode_build}) is lower or equal than the one on Hockey #{hockey_version} (#{hockey_build})."
  end
}

# Check if we can continue
raise red "Can't continue with build, as version and build numbers must be higher than the ones on Hockey." unless valid

# All done
puts green "|- All version and build numbers are correct."
