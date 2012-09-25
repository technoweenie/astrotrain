## This is the rakegem gemspec template. Make sure you read and understand
## all of the comments. Some sections require modification, and others can
## be deleted if you don't need them. Once you understand the contents of
## this file, feel free to delete any comments that begin with two hash marks.
## You can find comprehensive Gem::Specification documentation, at
## http://docs.rubygems.org/read/chapter/20
Gem::Specification.new do |s|
  s.specification_version = 2 if s.respond_to? :specification_version=
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.rubygems_version = '1.3.5'

  ## Leave these as is they will be modified for you by the rake gemspec task.
  ## If your rubyforge_project name is different, then edit it and comment out
  ## the sub! line in the Rakefile
  s.name              = 'astrotrain'
  s.version           = '0.6.4'
  s.date              = '2012-09-25'
  s.rubyforge_project = 'astrotrain'

  ## Make sure your summary is short. The description may be as long
  ## as you like.
  s.summary     = "email => http post"
  s.description = s.summary

  ## List the primary authors. If there are a bunch of authors, it's probably
  ## better to set the email to an email list or something. If you don't have
  ## a custom homepage, consider using your GitHub URL or the like.
  s.authors  = ["Rick Olson"]
  s.email    = 'technoweenie@gmail.com'
  s.homepage = 'http://github.com/technoweenie/astrotrain'

  ## This gets added to the $LOAD_PATH so that 'lib/NAME.rb' can be required as
  ## require 'NAME.rb' or'/lib/NAME/file.rb' can be as require 'NAME/file.rb'
  s.require_paths = %w[lib]

  ## List your runtime dependencies here. Runtime dependencies are those
  ## that are needed for an end user to actually USE your code.
  s.add_dependency('utf8',            ["~> 0.1.8"])
  s.add_dependency('mail',            ["~> 2.4.0"])
  s.add_dependency('i18n',            ["~> 0.6.0"])
  s.add_dependency('faraday',         ["~> 0.8.4"])
  s.add_dependency('addressable',     ["~> 2.2.4"])
  s.add_dependency('charlock_holmes', ["~> 0.6.8"])

  ## List your development dependencies here. Development dependencies are
  ## those that are only needed during development
  s.add_development_dependency('resque')

  ## Leave this section as-is. It will be automatically generated from the
  ## contents of your Git repository via the gemspec task. DO NOT REMOVE
  ## THE MANIFEST COMMENTS, they are used as delimiters by the task.
  # = MANIFEST =
  s.files = %w[
    Gemfile
    LICENSE
    Rakefile
    astrotrain.gemspec
    lib/astrotrain.rb
    lib/astrotrain/attachment.rb
    lib/astrotrain/message.rb
    lib/astrotrain/transports/http_post.rb
    lib/astrotrain/transports/resque.rb
    test/fixtures/apple_multipart.txt
    test/fixtures/bad_ascii.txt
    test/fixtures/bad_content_type.txt
    test/fixtures/bad_email_format.txt
    test/fixtures/basic.txt
    test/fixtures/custom.txt
    test/fixtures/email_in_body.txt
    test/fixtures/fwd.txt
    test/fixtures/gb2312_encoding.txt
    test/fixtures/gb2312_encoding_invalid.txt
    test/fixtures/html.txt
    test/fixtures/html_multipart.txt
    test/fixtures/iso-8859-1.txt
    test/fixtures/mapped.txt
    test/fixtures/multipart.txt
    test/fixtures/multipart2.txt
    test/fixtures/multiple.txt
    test/fixtures/multiple_delivered_to.txt
    test/fixtures/multiple_with_body_recipients.txt
    test/fixtures/reply.txt
    test/fixtures/undisclosed.txt
    test/fixtures/utf-8.txt
    test/fixtures/utf8.txt
    test/message_test.rb
    test/test_helper.rb
    test/transport_test.rb
  ]
  # = MANIFEST =

  ## Test files will be grabbed from the file list. Make sure the path glob
  ## matches what you actually use.
  s.test_files = s.files.select { |path| path =~ /^test\/*._test\.rb/ }
end
