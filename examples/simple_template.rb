#!/usr/bin/env ruby
require 'bundler/setup'
require 'cloudformation-ruby-dsl/cfntemplate'


extension = File.join(__dir__, "simple_template_extension.rb")

dsl = TemplateDSL.new({region: 'eu-west-1'}, [ extension ])
# equivalent to:
# 
# dsl = TemplateDSL.new({region: 'eu-west-1'})
# dsl.load_from_file(extension)


dsl.template do
  @stack_name = 'hello-bucket-example'

  value AWSTemplateFormatVersion: "2010-09-09"

  parameter 'Label',
            :Description => 'The label to apply to the bucket.',
            :Type => 'String',
            :Default => params['Label'],
            :UsePreviousValue => true

  resource "HelloBucket",
            :Type => 'AWS::S3::Bucket',
            :Properties => {
              :BucketName => ref('Label')
            }

  sns_topic "BucketUpdates"

end.excise_parameter_attributes!([:Immutable, :UsePreviousValue])

dsl.exec!