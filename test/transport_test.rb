require File.expand_path(File.join(File.dirname(__FILE__), "test_helper"))

class TransportTest < Test::Unit::TestCase
  class Job
  end

  test "building http params with attachment" do
    raw = mail(:multipart)
    msg = Astrotrain::Message.parse(raw)
    params = Astrotrain::Transports::HttpPost.create_hash(msg, 'bar@example.com')

    assert_equal 'foo@example.com',    params[:to][0][:address]
    assert_equal 'rick@example.com',   params[:from][0][:address]
    assert_equal 'Rick Olson',         params[:from][0][:name]
    assert_equal msg.subject,          params[:subject]
    assert_equal msg.body,             params[:body]
    assert_equal msg.recipients.first, params[:emails]
    assert_equal 'bandit.jpg',         params[:attachments][0].filename
    assert_match 'image/jpeg',         params[:attachments][0].content_type
    assert_equal '<ddf0a08f0812091503x4696425eid0fa5910ad39bce1@mail.examle.com>', params[:headers]['message-id']
  end

  test "building http params without attachment" do
    raw = mail(:basic)
    msg = Astrotrain::Message.parse(raw)
    params = Astrotrain::Transports::HttpPost.create_hash(msg, 'bar@example.com')

    assert_equal 'processor@astrotrain.com', params[:to][0][:address]
    assert_equal 'Processor',                params[:to][0][:name]
    assert_equal 'user@example.com',         params[:from][0][:address]
    assert_equal 'Bob',                      params[:from][0][:name]
    assert_equal 'fred@example.com',         params[:cc][0][:address]
    assert_equal 'Fred',                     params[:cc][0][:name]
    assert_equal msg.subject,                params[:subject]
    assert_equal msg.body,                   params[:body]
    assert_equal msg.recipients.first,       params[:emails]
    assert !params.key?(:attachments)
  end

  test "queues email in resque" do
    queue = "astrotrain-test"
    klass = "TransportTest::Job"
    raw   = mail(:basic)
    msg   = Astrotrain::Message.parse(raw)
    Astrotrain.process(:resque, "#{queue}:#{klass}", msg)
    job = Resque.reserve(queue)
    assert_equal TransportTest::Job, job.payload_class
    payload = job.args[0]
    assert_equal 'processor@astrotrain.com', payload['to'][0]['address']
    assert_equal 'Processor',                payload['to'][0]['name']
    assert_equal 'user@example.com',         payload['from'][0]['address']
    assert_equal 'Bob',                      payload['from'][0]['name']
    assert_equal 'fred@example.com',         payload['cc'][0]['address']
    assert_equal 'Fred',                     payload['cc'][0]['name']
    assert_equal msg.subject,                payload['subject']
    assert_equal msg.body,                   payload['body']
    assert_equal msg.recipients.first,       payload['emails']
  end

  test "building resque params" do
    raw = mail(:basic)
    msg = Astrotrain::Message.parse(raw)
    params = Astrotrain::Transports::Resque.create_hash(msg, 'bar@example.com')

    assert_equal 'processor@astrotrain.com', params[:to][0][:address]
    assert_equal 'Processor',                params[:to][0][:name]
    assert_equal 'user@example.com',         params[:from][0][:address]
    assert_equal 'Bob',                      params[:from][0][:name]
    assert_equal 'fred@example.com',         params[:cc][0][:address]
    assert_equal 'Fred',                     params[:cc][0][:name]
    assert_equal msg.subject,                params[:subject]
    assert_equal msg.body,                   params[:body]
    assert_equal msg.recipients.first,       params[:emails]
    assert !params.key?(:attachments)
  end
end
