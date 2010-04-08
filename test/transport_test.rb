require File.expand_path(File.join(File.dirname(__FILE__), "test_helper"))

class TransportTest < Test::Unit::TestCase
  test "building http params" do
    raw = mail(:multipart)
    msg = Astrotrain::Message.parse(raw)
    params = Astrotrain::Transports::HttpPost.create_hash(msg, 'bar@example.com')

    assert_equal 'bar@example.com',    params[:to]
    assert_equal msg.subject,          params[:subject]
    assert_equal msg.sender,           params[:from]
    assert_equal msg.body,             params[:body]
    assert_equal msg.recipients.first, params[:emails]
    assert_equal 'bandit.jpg',         params[:attachments][0].filename
    assert_match 'image/jpeg',         params[:attachments][0].content_type
    assert_equal '<ddf0a08f0812091503x4696425eid0fa5910ad39bce1@mail.examle.com>', params[:headers]['message-id']
  end
end