#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Adds ios/Runner/PrivacyInfo.xcprivacy to the Runner target's "Copy Bundle
# Resources" build phase. Idempotent — safe to run on every CI build.
# Run AFTER copying ci/PrivacyInfo.xcprivacy into ios/Runner/.

require "xcodeproj"

PROJECT_PATH = "ios/Runner.xcodeproj"
RESOURCE_NAME = "PrivacyInfo.xcprivacy"

project = Xcodeproj::Project.open(PROJECT_PATH)

target = project.targets.find { |t| t.name == "Runner" }
abort("Runner target not found in #{PROJECT_PATH}") unless target

group = project.main_group["Runner"]
abort("Runner group not found in #{PROJECT_PATH}") unless group

already_present = group.files.any? { |f| f.display_name == RESOURCE_NAME } ||
                  target.resources_build_phase.files.any? { |f| f.display_name == RESOURCE_NAME }

if already_present
  puts "#{RESOURCE_NAME} already referenced; nothing to do."
else
  ref = group.new_reference(RESOURCE_NAME)
  target.add_resources([ref])
  project.save
  puts "Added #{RESOURCE_NAME} to the Runner target's resources."
end
