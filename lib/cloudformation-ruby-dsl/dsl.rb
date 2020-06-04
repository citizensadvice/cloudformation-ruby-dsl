require "json"

############################ Utility functions

# Formats a template as JSON
def generate_template(template)
  generate_json template, !template.nopretty
end

def generate_json(data, pretty = true)
  # Raw formatting
  return JSON.generate(data) unless pretty

  # Pretty formatting
  JSON.pretty_generate(data)
end

############################# Generic DSL

class JsonObjectDSL
  def initialize
    @dict = {}
  end

  def value(values)
    @dict.update(values)
  end

  def default(key, value)
    @dict[key] ||= value
  end

  def to_json(*args)
    @dict.to_json(*args)
  end

  def print
    puts JSON.pretty_generate(self)
  end
end

############################# CloudFormation DSL

# Main entry point
def raw_template(options = {}, &block)
  TemplateDSL.new(options).template(&block)
end

class TemplateParameter < String
  attr_accessor :default, :use_previous_value

  def initialize(string)
    super string.to_s
  end
end

# Core interpreter for the DSL
class TemplateDSL < JsonObjectDSL
  attr_reader :parameters,
              :parameter_cli,
              :nopretty,
              :stack_name,
              :s3_bucket

  def initialize(options, *extensions)
    @parameters  = options.fetch(:parameters, {})
    @interactive = options.fetch(:interactive, false)
    @stack_name  = options[:stack_name]
    @nopretty    = options.fetch(:nopretty, false)
    @s3_bucket   = options.fetch(:s3_bucket, nil)
    super()
    load_extensions(*extensions)
  end

  def exec!
    cfn(self)
  end

  def template(&block)
    instance_eval &block if block_given?
    self
  end

  def parameter(name, options)
    default(:Parameters, {})[name] = options

    @parameters[name] ||= if @interactive
                            TemplateParameter.new(_get_parameter_from_cli(name, options))
                          else
                            TemplateParameter.new("")
                          end

    # set various param options
    @parameters[name].default = options[:Default]
    @parameters[name].use_previous_value = options[:UsePreviousValue]
  end

  # Find parameters where the specified attribute is true then remove the attribute from the cfn template.
  def excise_parameter_attributes!(attributes)
    marked_parameters = {}
    @dict.fetch(:Parameters, {}).each do |param, options|
      attributes.each do |attribute|
        marked_parameters[attribute] ||= []
        marked_parameters[attribute] << param if options.delete(attribute.to_sym) || options.delete(attribute.to_s)
      end
    end
    marked_parameters
  end

  def mapping(name, options)
    # if options is a string and a valid file then the script will process the external file.
    default(:Mappings, {})[name] = \
      if options.is_a?(Hash); options
      elsif options.is_a?(String); load_from_file(options)["Mappings"][name]
      else; raise("Options for mapping #{name} is neither a string or a hash.  Error!")
    end
  end

  def load_extensions(*extensions)
    extensions.each { |e| load_from_file(e) }
  end

  def load_from_file(filename)
    file = File.open(filename)

    begin
      # Figure out what the file extension is and process accordingly.
      contents = case File.extname(filename)
                 when ".rb" then eval(file.read, nil, filename)
                 when ".json" then JSON.load(file)
                 when ".yaml" then YAML.load(file)
                 else; raise("Do not recognize extension of #{filename}.")
      end
    ensure
      file.close
    end
    contents
  end

  # Find tags where the specified attribute is true then remove this attribute.
  def get_tag_attribute(tags, attribute)
    marked_tags = []
    tags.each do |tag, options|
      marked_tags << tag if options.delete(attribute.to_sym) || options.delete(attribute.to_s)
    end
    marked_tags
  end

  def excise_tags!
    tags = @dict.fetch(:Tags, {})
    @dict.delete(:Tags)
    tags
  end

  def tag(tag, *args)
    if (tag.is_a?(String) || tag.is_a?(Symbol)) && !args.empty?
      default(:Tags, {})[tag.to_s] = args[0]
    # For backward-compatibility, transform `tag_name=>value` format to `tag_name, :Value=>value, :Immutable=>true`
    # Tags declared this way remain immutable and won't be updated.
    elsif tag.is_a?(Hash) && tag.size == 1 && args.empty?
      warn "WARNING: #{tag} tag declaration format is deprecated and will be removed in a future version. Please use resource-like style instead."
      tag.each do |name, value|
        default(:Tags, {})[name.to_s] = { Value: value, Immutable: true }
      end
    else
      warn "Error: #{tag} tag validation error. Please verify tag's declaration format."
      exit(false)
    end
  end

  def metadata(name, options)
    default(:Metadata, {})[name] = options
  end

  def condition(name, options)
    default(:Conditions, {})[name] = options
  end

  def resource(name, options)
    default(:Resources, {})[name] = options
  end

  def output(name, options)
    default(:Outputs, {})[name] = options
  end

  def find_in_map(map, key, name)
    # Eagerly evaluate mappings when all keys are known at template expansion time
    if map.is_a?(String) && key.is_a?(String) && name.is_a?(String)
      # We don't know whether the map was built with string keys or symbol keys.  Try both.
      def get(map, key)
        map[key] || map.fetch(key.to_sym)
      end
      get(get(@dict.fetch(:Mappings).fetch(map), key), name)
    else
      { 'Fn::FindInMap': [map, key, name] }
    end
  end

  private

  def _get_parameter_from_cli(name, options)
    # basic request
    param_request = "Parameter '#{name}' (#{options[:Type]})"

    # add description to request
    param_request += "\nDescription: #{options[:Description]}" if options.has_key?(:Description)

    # add validation to the request

    # allowed pattern
    param_request += "\nAllowed Pattern: /#{options[:AllowedPattern]}/" if options.has_key?(:AllowedPattern)

    # allowed values
    param_request += "\nAllowed Values: #{options[:AllowedValues].join(', ')}" if options.has_key?(:AllowedValues)

    # min/max length
    if options.has_key?(:MinLength) || options.has_key?(:MaxLength)
      min_length = "-infinity"
      max_length = "+infinity"
      min_length = options[:MinLength] if options.has_key?(:MinLength)
      max_length = options[:MaxLength] if options.has_key?(:MaxLength)
      param_request += "\nValid Length: #{min_length} < string < #{max_length}"
    end

    # min/max value
    if options.has_key?(:MinValue) || options.has_key?(:MaxValue)
      min_value = "-infinity"
      max_value = "+infinity"
      min_value = options[:MinValue] if options.has_key?(:MinValue)
      max_value = options[:MaxValue] if options.has_key?(:MaxValue)
      param_request += "\nValid Number: #{min_value} < number < #{max_value}"
    end

    # add default to request
    param_request += "\nLeave value empty for default: #{options[:Default]}" if options.has_key?(:Default) && !options[:Default].nil?

    param_request += "\nValue: "

    # request the param
    $stdout.puts "===================="
    $stdout.print param_request
    input = $stdin.gets.chomp

    if input.nil? || input.empty?
      options[:Default]
    else
      input
    end
  end
end

def base64(value)
  { 'Fn::Base64': value }
end

def find_in_map(map, key, name)
  { 'Fn::FindInMap': [map, key, name] }
end

def get_att(resource, attribute)
  { 'Fn::GetAtt': [resource, attribute] }
end

def get_azs(region = "")
  { 'Fn::GetAZs': region }
end

def import_value(value)
  { 'Fn::ImportValue': value }
end

def aws_region
  ref("AWS::Region")
end

# There are two valid forms of Fn::Sub, with a map and without.
def sub(sub_string, var_map = {})
  if var_map.empty?
    { 'Fn::Sub': sub_string }
  else
    { 'Fn::Sub': [sub_string, var_map] }
  end
end

def join(delim, *list)
  case list.length
  when 0 then ""
  else join_list(delim, list)
  end
end

# Variant of join that matches the native CFN syntax.
def join_list(delim, list)
  if list.length == 1
    { 'Fn::Join': [delim, list[0]] }
  else
    { 'Fn::Join': [delim, list] }
  end
end

def equal(one, two)
  { 'Fn::Equals': [one, two] }
end

def fn_not(condition)
  { 'Fn::Not': [condition] }
end

def fn_or(*condition_list)
  case condition_list.length
  when 0..1 then raise "fn_or needs at least 2 items."
  when 2..10 then { 'Fn::Or': condition_list }
  else raise "fn_or needs a list of 2-10 items that evaluate to true/false."
  end
end

def fn_and(*condition_list)
  case condition_list.length
  when 0..1 then raise "fn_and needs at least 2 items."
  when 2..10 then { 'Fn::And': condition_list }
  else raise "fn_and needs a list of 2-10 items that evaluate to true/false."
  end
end

def fn_if(cond, if_true, if_false)
  { 'Fn::If': [cond, if_true, if_false] }
end

def not_equal(one, two)
  fn_not(equal(one, two))
end

def select(index, list)
  { 'Fn::Select': [index, list] }
end

def split(delimiter, source_str)
  { 'Fn::Split': [delimiter, source_str] }
end

def ref(name)
  { Ref: name }
end

def aws_account_id
  ref("AWS::AccountId")
end

def aws_notification_arns
  ref("AWS::NotificationARNs")
end

def aws_no_value
  ref("AWS::NoValue")
end

def aws_stack_id
  ref("AWS::StackId")
end

def aws_stack_name
  ref("AWS::StackName")
end

# deprecated, for backward compatibility
def no_value
  warn_deprecated("no_value()", "aws_no_value()")
  aws_no_value
end

# Read the specified file and return its value as a string literal
def file(filename)
  File.read(File.absolute_path(filename, File.dirname($PROGRAM_NAME)))
end

# Interpolates a string like "NAME={{ref('Service')}}" and returns a CloudFormation "Fn::Join"
# operation to collect the results.  Anything between {{ and }} is interpreted as a Ruby expression
# and eval'd.  This is especially useful with Ruby "here" documents.
# Local variables may also be exposed to the string via the `locals` hash.
def interpolate(string, _locals = {})
  list = []
  while string.length > 0
    head, match, string = string.partition(/\{\{.*?\}\}/)
    list << head if head.length > 0
    list << eval(match[2..-3], nil, "interpolated string") if match.length > 0
  end

  # Split out strings in an array by newline, for visibility
  list = list.flat_map { |value| value.is_a?(String) ? value.lines.to_a : value }
  join("", *list)
end

def join_interpolate(_delim, string)
  warn "join_interpolate(delim,string) has been deprecated; use interpolate(string) instead"
  interpolate(string)
end

# Combines the provided ERB template with optional parameters
def erb_template(filename, params = {})
  erb = ERB.new(file(filename), trim_mode: "-")
  erb.filename = filename
  erb.result_with_hash(params: params)
end

def warn_deprecated(old, new)
  warn "Warning: '#{old}' has been deprecated.  Please update your template to use '#{new}' instead."
end
